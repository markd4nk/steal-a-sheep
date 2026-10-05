@AGENTS.md

## Claude Code specifics

- Roblox Studio MCP tools appear only while Studio is open with **Assistant > Manage MCP Servers > Enable Studio
  as MCP server** turned on and this client connected. If they are missing, say so and continue with the
  static check; don't imitate a playtest.
- The desktop tools (`BRAIN/PATTERNS/desktop.md`) appear as `mcp__windows-computer-use__*` on machines set up with
  README step 8. Use them whenever they're the best way to do the work, without asking first: announce each
  takeover in one line, then go ahead. Keep each `act` call short and check which window it reached (desktop.md,
  Other sessions). Run commands with Bash, never through these tools' `process`.
- Run the scripts with `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1` when the shell
  isn't PowerShell.
