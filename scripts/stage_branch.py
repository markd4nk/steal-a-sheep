"""Stages this worktree's scripts in the shared Studio place for a playtest, and takes them out again, without Rojo or
the mouse. For when another session's Rojo serves the place, or Studio holds a peer's work (BRAIN/PATTERNS/sessions.md).
The place must hold --base's scripts (the main commit last synced into it); every script that differs from it here,
plus new ones, is swapped in, backed up first, and put back after.

    python scripts/stage_branch.py --base <commit> [--blank] [--dry-run]

It builds one model of the changed and new scripts with Rojo, copies it into the running Studio's content folder
(rbxasset://stage_branch/branch.rbxm; --dry-run skips the copy), and writes three Luau snippets to run with the
Studio MCP's execute_luau in Edit:
  1. stage_in.luau: checks every target still has --base's text (changes nothing otherwise), backs the scripts up in
     ServerStorage.StageBranch, swaps them in and adds the new ones. --blank also turns DebugBlankProfile on, so the
     playtest's save is a blank one in memory.
  Playtest (start_stop_play), stop it, then:
  2. stage_out.luau: puts every script back, deletes the added ones and the backup, clears DebugBlankProfile.
  3. stage_verify.luau: every script is --base's length again, and nothing staged or TEMP_ is left.
Delete the content folder's stage_branch copy afterwards (the script prints its path). Scripts deleted since --base
aren't handled: it lists them. Anything Studio-side the branch changes (a studio/ build script's output) is yours to
stage and restore.
"""

import argparse
import json
import os
import pathlib
import shutil
import subprocess

REPO = pathlib.Path(__file__).resolve().parents[1]
WORK = pathlib.Path(os.environ.get("TEMP", "/tmp")) / "stage_branch"
# Where default.project.json puts each folder (AGENTS.md, Layout).
ROOTS = {
    "src/client": "StarterPlayer/StarterPlayerScripts",
    "src/server": "ServerScriptService",
    "src/shared": "ReplicatedStorage",
    "tests": "ServerStorage/Tests",
}


def git(*args):
    return subprocess.run(["git", *args], cwd=REPO, capture_output=True, text=True, check=True).stdout


def rojo():
    found = shutil.which("rojo")
    if found:
        return found
    for name in ("rojo.exe", "rojo"):
        candidate = pathlib.Path.home() / ".rokit" / "bin" / name
        if candidate.exists():
            return str(candidate)
    raise SystemExit("rojo not found: install the tools with ./scripts/install.ps1")


def place_path(file):
    for prefix, root in ROOTS.items():
        if file.startswith(prefix + "/"):
            parts = file[len(prefix) + 1 :].split("/")
            stem = parts[-1]
            for suffix in (".server.luau", ".client.luau", ".luau"):
                if stem.endswith(suffix):
                    stem = stem[: -len(suffix)]
                    break
            parts = parts[:-1] if stem == "init" else parts[:-1] + [stem]
            return root + "/" + "/".join(parts)
    raise ValueError(file)


def studio_content():
    """The running Studio's content folder (its exe's version folder), else the newest installed one."""
    try:
        out = subprocess.run(
            [
                "powershell",
                "-NoProfile",
                "-Command",
                "(Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | Select-Object -First 1).Path",
            ],
            capture_output=True,
            text=True,
        ).stdout.strip()
    except OSError:
        out = ""
    if out:
        return pathlib.Path(out).parent / "content"
    versions = pathlib.Path(os.environ["LOCALAPPDATA"]) / "Roblox" / "Versions"
    installed = [v for v in versions.iterdir() if (v / "RobloxStudioBeta.exe").exists()]
    if not installed:
        raise SystemExit("Roblox Studio isn't installed")
    return max(installed, key=lambda v: v.stat().st_mtime) / "content"


FIND = """local function split(path)
	local parts = string.split(path, "/")
	local name = table.remove(parts)
	local node: Instance? = game
	for _, part in parts do
		node = if node == game then game:GetService(part) else node and node:FindFirstChild(part)
		if not node then
			return nil, name
		end
	end
	return node, name
end
local function len(source)
	return #(string.gsub(source, "\\r", ""))
end
-- The parent a new script goes in, making any folder on the way that the place doesn't have yet.
local function ensureParent(path)
	local parts = string.split(path, "/")
	local name = table.remove(parts)
	local node: Instance = game:GetService(table.remove(parts, 1) :: string)
	for _, part in parts do
		local child = node:FindFirstChild(part)
		if not child then
			child = Instance.new("Folder")
			child.Name = part
			child:SetAttribute("StageAdded", true)
			child.Parent = node
		end
		node = child
	end
	return node, name
end
"""

STAGE_IN = """local ServerStorage = game:GetService("ServerStorage")
if ServerStorage:FindFirstChild("StageBranch") then
	return "ServerStorage.StageBranch exists already: staged before? Run stage_out.luau first."
end
for _, path in ORDER do
	local parent, name = split(path)
	local want = BASE_LEN[path]
	local target = parent and parent:FindFirstChild(name)
	if want < 0 then
		if target then
			return "a new script already exists: " .. path
		end
	elseif not target then
		return "missing: " .. path
	elseif len(target.Source) ~= want then
		return "not --base's text: " .. path .. " (" .. len(target.Source) .. " vs " .. want .. ")"
	end
end
local branch = game:GetObjects("rbxasset://stage_branch/branch.rbxm")[1]
local stage = Instance.new("Folder")
stage.Name = "StageBranch"
stage.Parent = ServerStorage
for _, path in ORDER do
	local incoming = branch[path]
	if BASE_LEN[path] < 0 then
		local parent, name = ensureParent(path)
		local script = incoming:Clone()
		script.Name = name
		script:SetAttribute("StageAdded", true)
		script.Parent = parent
	else
		local parent, name = split(path)
		local target = parent:FindFirstChild(name)
		local saved = Instance.new("StringValue")
		saved.Name = path
		saved.Value = target.Source
		saved.Parent = stage
		target.Source = incoming.Source
	end
end
if BLANK then
	ServerStorage:SetAttribute("DebugBlankProfile", true)
end
return "staged " .. #ORDER .. " scripts"
"""

STAGE_OUT = """local ServerStorage = game:GetService("ServerStorage")
local stage = ServerStorage:FindFirstChild("StageBranch")
if not stage then
	return "nothing staged (no ServerStorage.StageBranch)"
end
for _, saved in stage:GetChildren() do
	local parent, name = split(saved.Name)
	local target = parent and parent:FindFirstChild(name)
	if target then
		target.Source = saved.Value
	end
end
local services = { "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterPlayer" }
for _, service in services do
	for _, item in game:GetService(service):GetDescendants() do
		if item.Parent and item:GetAttribute("StageAdded") then
			item:Destroy()
		end
	end
end
stage:Destroy()
ServerStorage:SetAttribute("DebugBlankProfile", nil)
return "restored"
"""

STAGE_VERIFY = """local bad = {}
for _, path in ORDER do
	local parent, name = split(path)
	local target = parent and parent:FindFirstChild(name)
	local want = BASE_LEN[path]
	if want < 0 then
		if target then
			table.insert(bad, "still added: " .. path)
		end
	elseif not target or len(target.Source) ~= want then
		table.insert(bad, path)
	end
end
local left = {}
for _, root in { workspace, game:GetService("ServerStorage"), game:GetService("ReplicatedStorage") } do
	for _, item in root:GetDescendants() do
		if string.sub(item.Name, 1, 5) == "TEMP_" or item.Name == "StageBranch" then
			table.insert(left, item:GetFullName())
		end
	end
end
local blank = game:GetService("ServerStorage"):GetAttribute("DebugBlankProfile")
return "differing: " .. (if #bad == 0 then "none" else table.concat(bad, ", "))
	.. "; left over: " .. (if #left == 0 then "none" else table.concat(left, ", "))
	.. "; DebugBlankProfile " .. tostring(blank)
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base", required=True, help="the commit whose scripts the place holds now")
    parser.add_argument("--blank", action="store_true", help="turn DebugBlankProfile on while staged")
    parser.add_argument("--dry-run", action="store_true", help="build and write the snippets, don't touch Studio's folder")
    args = parser.parse_args()

    changed, added, gone = [], [], []
    for line in git("diff", "--name-status", "--no-renames", args.base, "--", "src", "tests").splitlines():
        status, file = line.split("\t", 1)
        if file.endswith(".luau"):
            {"A": added, "D": gone}.get(status[0], changed).append(file)
    added += [f for f in git("ls-files", "--others", "--exclude-standard", "--", "src", "tests").split() if f.endswith(".luau")]
    if gone:
        print("Not handled, deleted since --base (remove them by hand and put them back after):", ", ".join(gone))
    if not changed and not added:
        raise SystemExit(f"No script differs from {args.base}.")

    if WORK.exists():
        shutil.rmtree(WORK)
    files = WORK / "files"
    files.mkdir(parents=True)
    tree = {"$className": "Folder"}
    base_len = {}
    for index, file in enumerate(changed + added):
        key = place_path(file)
        # The copy keeps the original's suffix, so Rojo builds the same script class.
        copy = files / f"{index:03d}_{pathlib.Path(file).name}"
        copy.write_bytes((REPO / file).read_bytes())
        tree[key] = {"$path": str(copy).replace("\\", "/")}
        if file in changed:
            old = subprocess.run(["git", "show", f"{args.base}:{file}"], cwd=REPO, capture_output=True, check=True).stdout
            base_len[key] = len(old.replace(b"\r", b""))
        else:
            base_len[key] = -1
    (WORK / "branch.project.json").write_text(json.dumps({"name": "Branch", "tree": tree}, indent=1))
    subprocess.run([rojo(), "build", str(WORK / "branch.project.json"), "-o", str(WORK / "branch.rbxm")], cwd=REPO, check=True)

    # New folder modules (init.luau) must exist before their children: shallow paths first.
    order = sorted(base_len, key=lambda key: (key.count("/"), key))
    header = "local BASE_LEN = {\n" + "".join(f'\t["{key}"] = {n},\n' for key, n in base_len.items()) + "}\n"
    header += "local ORDER = {\n" + "".join(f'\t"{key}",\n' for key in order) + "}\n"
    header += f"local BLANK = {'true' if args.blank else 'false'}\n" + FIND
    snippets = {"stage_in.luau": header + STAGE_IN, "stage_out.luau": FIND + STAGE_OUT, "stage_verify.luau": header + STAGE_VERIFY}
    for name, text in snippets.items():
        (WORK / name).write_text(text, encoding="utf-8")

    print(f"{len(changed)} changed and {len(added)} new scripts against {args.base}")
    if args.dry_run:
        print(f"Dry run: the model is {WORK / 'branch.rbxm'}, not copied into Studio")
    else:
        content = studio_content() / "stage_branch"
        content.mkdir(parents=True, exist_ok=True)
        shutil.copy(WORK / "branch.rbxm", content / "branch.rbxm")
        print(f"Model copied to {content} (delete that folder afterwards)")
    print(f"Snippets in {WORK}: " + ", ".join(snippets))


if __name__ == "__main__":
    main()
