// Renders the mock-ups in DESIGN/ui/mockups to PNGs in DESIGN/ui/renders with headless Chrome or Edge, no npm packages
// (Shear a Sheep's DESIGN/ui/render.mjs, trimmed). It serves the repo over HTTP with the local Roblox install's fonts
// and textures and gvesster's icon pack mounted, so the mock-ups draw with Roblox's own Fredoka One and Builder Sans
// and the pack's own pictures. Each page is saved whole (the board) and every `.frame[data-id]` on it again on its
// own, at the frame's size and pixel density (`data-w`, `data-h`, `data-scale`), by reopening the page with
// `?solo=<id>`.
//
//   node DESIGN/ui/render.mjs              every page
//   node DESIGN/ui/render.mjs sell         pages whose file name starts with one of these
//   node DESIGN/ui/render.mjs --frames <page> <frame id> <seconds> [fps]
//                                          an animated frame as numbered PNGs (the page's window.renderAt(t) draws
//                                          each moment), to renders/<page>/<frame id>/, for ffmpeg
//   node DESIGN/ui/render.mjs --serve      only serves the repo, to open the mock-ups in a browser:
//                                          http://127.0.0.1:8741/DESIGN/ui/mockups/sell-stall.html
//
// The icon pack stays out of git (its licence lets a game use the icons, not pass them on): it's read from
// ~/Downloads/Free Icon Pack v3.1 (Basic)/Free Icon Pack v3.1 (Basic), or ICON_PACK. RENDER_PORT and
// RENDER_DEBUG_PORT move the ports when another session renders at the same time.

import { spawn } from "node:child_process";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "..", "..");
const MOCKUPS = path.join(HERE, "mockups");
const OUT = path.join(HERE, "renders");
const PORT = Number(process.env.RENDER_PORT) || 8741;
const DEBUG_PORT = Number(process.env.RENDER_DEBUG_PORT) || 9741;
const BOARD_HEIGHT = 1000; // first guess before a page is measured
const PACK =
	process.env.ICON_PACK ??
	path.join(os.homedir(), "Downloads", "Free Icon Pack v3.1 (Basic)", "Free Icon Pack v3.1 (Basic)");

const TYPES = {
	".html": "text/html; charset=utf-8",
	".css": "text/css; charset=utf-8",
	".js": "text/javascript; charset=utf-8",
	".mjs": "text/javascript; charset=utf-8",
	".svg": "image/svg+xml",
	".png": "image/png",
	".jpg": "image/jpeg",
	".jpeg": "image/jpeg",
	".ttf": "font/ttf",
	".otf": "font/otf",
	".json": "application/json",
};

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// The newest Roblox install's content folder (Studio and the player keep one per version).
function robloxContent() {
	const versions = path.join(process.env.LOCALAPPDATA ?? "", "Roblox", "Versions");
	let best = null;
	for (const name of fs.existsSync(versions) ? fs.readdirSync(versions) : []) {
		const content = path.join(versions, name, "content");
		const probe = path.join(content, "fonts", "FredokaOne-Regular.ttf");
		if (fs.existsSync(probe)) {
			const time = fs.statSync(probe).mtimeMs;
			if (!best || time > best.time) {
				best = { content, time };
			}
		}
	}
	return best ? best.content : null;
}

function serve(content) {
	const mounts = [
		["/rbxfonts/", content && path.join(content, "fonts")],
		["/rbxtextures/", content && path.join(content, "textures")],
		["/pack/", fs.existsSync(PACK) ? PACK : null],
		["/", ROOT],
	];
	const server = http.createServer((request, response) => {
		const url = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
		const mount = mounts.find(([prefix]) => url.startsWith(prefix));
		const dir = mount && mount[1];
		const file = dir ? path.resolve(dir, url.slice(mount[0].length)) : null;
		if (!file || !file.startsWith(path.resolve(dir))) {
			response.writeHead(404);
			response.end();
			return;
		}
		fs.readFile(file, (error, data) => {
			if (error) {
				response.writeHead(404);
				response.end();
				return;
			}
			response.writeHead(200, {
				"Content-Type": TYPES[path.extname(file).toLowerCase()] ?? "application/octet-stream",
				"Cache-Control": "no-store",
			});
			response.end(data);
		});
	});
	return new Promise((resolve) => server.listen(PORT, "127.0.0.1", () => resolve(server)));
}

function findChrome() {
	const candidates = [
		process.env.CHROME,
		"C:/Program Files/Google/Chrome/Application/chrome.exe",
		"C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
		"C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
		"C:/Program Files/Microsoft/Edge/Application/msedge.exe",
	];
	const found = candidates.find((candidate) => candidate && fs.existsSync(candidate));
	if (!found) {
		throw new Error("No Chrome or Edge found; set CHROME to its path");
	}
	return found;
}

async function launch() {
	const profile = fs.mkdtempSync(path.join(os.tmpdir(), "ui-render-"));
	const chrome = spawn(
		findChrome(),
		[
			"--headless=new",
			"--disable-gpu",
			"--hide-scrollbars",
			"--mute-audio",
			"--no-first-run",
			"--no-default-browser-check",
			"--force-color-profile=srgb",
			`--remote-debugging-port=${DEBUG_PORT}`,
			`--user-data-dir=${profile}`,
			"about:blank",
		],
		{ stdio: "ignore" },
	);
	for (let attempt = 0; attempt < 100; attempt++) {
		try {
			const targets = await (await fetch(`http://127.0.0.1:${DEBUG_PORT}/json/list`)).json();
			const page = targets.find((target) => target.type === "page");
			if (page) {
				return { chrome, profile, socketUrl: page.webSocketDebuggerUrl };
			}
		} catch {
			// not listening yet
		}
		await sleep(100);
	}
	chrome.kill();
	throw new Error("Chrome didn't open its debugging port");
}

// A minimal Chrome DevTools Protocol client over Node's built-in WebSocket.
function connect(url) {
	const socket = new WebSocket(url);
	let nextId = 0;
	const pending = new Map();
	const waiters = [];
	socket.onmessage = (event) => {
		const message = JSON.parse(event.data);
		if (message.id) {
			const request = pending.get(message.id);
			pending.delete(message.id);
			if (message.error) {
				request.reject(new Error(`${request.method}: ${message.error.message}`));
			} else {
				request.resolve(message.result);
			}
			return;
		}
		for (const waiter of [...waiters]) {
			if (waiter.method === message.method) {
				waiters.splice(waiters.indexOf(waiter), 1);
				waiter.resolve(message.params);
			}
		}
	};
	const ready = new Promise((resolve, reject) => {
		socket.onopen = resolve;
		socket.onerror = reject;
	});
	return {
		ready,
		send(method, params = {}) {
			return new Promise((resolve, reject) => {
				const id = ++nextId;
				pending.set(id, { resolve, reject, method });
				socket.send(JSON.stringify({ id, method, params }));
			});
		},
		once(method) {
			return new Promise((resolve) => waiters.push({ method, resolve }));
		},
		close() {
			socket.close();
		},
	};
}

// Waits for the page's own build (kit.js clears data-pending), fonts, images and two frames of layout, then reports
// the page's size and its frames.
const SETTLE = `(async () => {
	await new Promise((done) => {
		const check = () => (document.body.hasAttribute("data-pending") ? setTimeout(check, 25) : done());
		check();
	});
	await document.fonts.ready;
	await Promise.all([...document.images].map((image) =>
		image.complete ? null : new Promise((done) => { image.onload = image.onerror = done; })));
	await new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done)));
	return JSON.stringify({
		width: document.documentElement.scrollWidth,
		height: document.documentElement.scrollHeight,
		boardWidth: Number(document.body.dataset.width || 0),
		missingFonts: [...document.fonts].filter((font) => font.status === "error").map((font) => font.family),
		missingImages: [...document.images].filter((image) => image.naturalWidth === 0).map((image) => image.src),
		frames: [...document.querySelectorAll(".frame[data-id]")].map((frame) => ({
			id: frame.dataset.id,
			width: Number(frame.dataset.w),
			height: Number(frame.dataset.h),
			scale: Number(frame.dataset.scale || 1),
		})),
	});
})()`;

async function open(cdp, url, width, height, scale) {
	await cdp.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: scale, mobile: false });
	const loaded = cdp.once("Page.loadEventFired");
	await cdp.send("Page.navigate", { url });
	await loaded;
	const result = await cdp.send("Runtime.evaluate", { expression: SETTLE, awaitPromise: true, returnByValue: true });
	return JSON.parse(result.result.value);
}

async function capture(cdp, file) {
	const { data } = await cdp.send("Page.captureScreenshot", { format: "png" });
	fs.mkdirSync(path.dirname(file), { recursive: true });
	fs.writeFileSync(file, Buffer.from(data, "base64"));
}

async function renderPage(cdp, file) {
	const name = path.basename(file, ".html");
	const url = `http://127.0.0.1:${PORT}/${path.relative(ROOT, file).split(path.sep).join("/")}`;
	let info = await open(cdp, url, 1600, BOARD_HEIGHT, 1);
	const width = info.boardWidth || info.width;
	info = await open(cdp, url, width, BOARD_HEIGHT, 1);
	await cdp.send("Emulation.setDeviceMetricsOverride", { width, height: info.height, deviceScaleFactor: 1, mobile: false });
	await sleep(150);
	await capture(cdp, path.join(OUT, `${name}.png`));
	if (info.missingFonts.length > 0) {
		console.warn(`  ${name}: fonts failed to load: ${[...new Set(info.missingFonts)].join(", ")}`);
	}
	if (info.missingImages.length > 0) {
		console.warn(`  ${name}: images failed to load: ${[...new Set(info.missingImages)].join(", ")}`);
	}
	console.log(`  ${name}.png  ${width}x${info.height}`);
	for (const frame of info.frames) {
		await open(cdp, `${url}?solo=${encodeURIComponent(frame.id)}`, frame.width, frame.height, frame.scale);
		await capture(cdp, path.join(OUT, name, `${frame.id}.png`));
	}
	if (info.frames.length > 0) {
		console.log(`  ${name}/  ${info.frames.length} frames`);
	}
}

// An animated frame as numbered PNGs: the page's window.renderAt(t) draws the moment t seconds in, for every frame of
// `seconds` at `fps`, into renders/<page>/<id>/ (ffmpeg makes the video from them).
async function renderFrames(cdp, page, id, seconds, fps) {
	const url = `http://127.0.0.1:${PORT}/DESIGN/ui/mockups/${page}.html?solo=${encodeURIComponent(id)}`;
	const probe = await open(cdp, url, 1600, 1000, 1);
	const frame = probe.frames.find((entry) => entry.id === id) ?? { width: probe.width, height: probe.height, scale: 1 };
	await open(cdp, url, frame.width, frame.height, frame.scale);
	const out = path.join(OUT, page, id);
	fs.rmSync(out, { recursive: true, force: true });
	const count = Math.round(seconds * fps);
	for (let index = 0; index <= count; index++) {
		await cdp.send("Runtime.evaluate", {
			expression: `(async () => { await window.renderAt(${index / fps}); await new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done))); })()`,
			awaitPromise: true,
		});
		await capture(cdp, path.join(out, `frame_${String(index).padStart(4, "0")}.png`));
	}
	console.log(`  ${page}/${id}/  ${count + 1} frames at ${fps} fps`);
}

async function withBrowser(run) {
	const content = robloxContent();
	if (!content) {
		console.warn("No Roblox install found: the fonts fall back to the system's");
	}
	if (!fs.existsSync(PACK)) {
		console.warn(`No icon pack at ${PACK}: its pictures won't show (set ICON_PACK)`);
	}
	const server = await serve(content);
	const { chrome, profile, socketUrl } = await launch();
	const cdp = connect(socketUrl);
	try {
		await cdp.ready;
		await cdp.send("Page.enable");
		await run(cdp);
	} finally {
		cdp.close();
		chrome.kill();
		server.close();
		await sleep(300);
		fs.rmSync(profile, { recursive: true, force: true, maxRetries: 5 });
	}
}

async function main() {
	const args = process.argv.slice(2);
	if (args[0] === "--serve") {
		await serve(robloxContent());
		console.log(`Serving on http://127.0.0.1:${PORT}/DESIGN/ui/mockups/ (Ctrl+C to stop)`);
		return;
	}
	if (args[0] === "--frames") {
		const [, page, id, seconds, fps] = args;
		await withBrowser((cdp) => renderFrames(cdp, page, id, Number(seconds), Number(fps || 30)));
		return;
	}
	const pages = fs
		.readdirSync(MOCKUPS)
		.filter((file) => file.endsWith(".html"))
		.filter((file) => args.length === 0 || args.some((filter) => file.startsWith(filter)))
		.map((file) => path.join(MOCKUPS, file));
	if (pages.length === 0) {
		throw new Error(`No mock-ups match ${args.join(", ")}`);
	}
	await withBrowser(async (cdp) => {
		for (const page of pages) {
			await renderPage(cdp, page);
		}
	});
}

main().catch((error) => {
	console.error(error);
	process.exit(1);
});
