// The mock-ups' pieces for Steal a Sheep: Shear a Sheep's "Prize Fleece" components (its DESIGN/ui/fleece/fleece.js),
// this game's families and numbers (data.json, from `lune run DESIGN/ui/export-data.luau`), its sheep token as
// UIController/SheepIcon paints it, and phone and PC frames with this game's HUD behind the backdrop. Each function
// returns HTML for one piece, so a page is a composition of the same parts.

export const DATA = await (await fetch("/DESIGN/ui/data.json")).json();

// ---------------------------------------------------------------------------------------------------------------------
// Numbers, as Utils/Format writes them

const SUFFIXES = ["K", "M", "B", "T", "Qa"];

// Format.Short: three digits, rounded down (12345 -> "12.3K").
export function short(value) {
	const whole = Math.floor(Math.abs(value));
	if (whole < 1000) {
		return String(whole);
	}
	let index = 1;
	while (index < SUFFIXES.length && whole >= 1000 ** (index + 1)) {
		index += 1;
	}
	const unit = 1000 ** index;
	const decimals = whole < 10 * unit ? 2 : whole < 100 * unit ? 1 : 0;
	const scale = 10 ** decimals;
	const kept = Math.floor(whole / (unit / scale));
	let text = String(Math.floor(kept / scale));
	if (decimals > 0) {
		const fraction = String(kept % scale).padStart(decimals, "0").replace(/0+$/, "");
		if (fraction !== "") {
			text += "." + fraction;
		}
	}
	return text + SUFFIXES[index - 1];
}

// Format.Rate: tenths under 100, then like Short.
export function rate(value) {
	if (value >= 100) {
		return short(value);
	}
	const tenths = Math.floor(value * 10 + 1e-6);
	return tenths % 10 === 0 ? String(tenths / 10) : (tenths / 10).toFixed(1);
}

// ---------------------------------------------------------------------------------------------------------------------
// Art: gvesster's icon pack (render.mjs mounts it at /pack/), as the game uses it (Theme.Icons' Hud pictures)

const pack = (folder, stem) => `/pack/${folder}/256px/${stem} 256px.png`;
export const ICON = {
	cash: pack("Currency/Cash", "Green Cash 1st Outline"),
	cashPile: pack("Currency/Cash", "Green Cash 2nd Outline"),
	shoe: pack("Item/Shoe", "Red Shoe 1st Outline"),
	lock: pack("Item/Lock", "Lock 1st Outline"),
	check: pack("UI/Checkmark", "Checkmark 1st Outline"),
	warning: pack("UI/Warning", "Warning 1st Outline"),
	question: pack("UI/Question Mark", "Question Mark 1st Outline"),
	bag: pack("Main/Shopping Bag", "Golden Shopping Bag 1st Outline"),
	stats: pack("Main/Stats", "Stats 1st Outline"),
};

export function ico(name, size = 28, extra = "") {
	return `<img class="ico ${extra}" src="${ICON[name] ?? name}" style="width:${size}px;height:${size}px" alt="">`;
}

// The sheep token's drawing (Shear a Sheep's icons.svg, the source of the token layers), and the fleece sparkle.
const SPRITE = `<svg width="0" height="0" style="position:absolute">
<symbol id="token" viewBox="0 0 48 48">
	<g stroke="var(--ink)" stroke-width="2.5" stroke-linejoin="round">
		<rect x="15.5" y="33" width="6" height="11" rx="3" fill="var(--legs,#EED8B6)"/>
		<rect x="26.5" y="33" width="6" height="11" rx="3" fill="var(--legs,#EED8B6)"/>
	</g>
	<g fill="var(--ink)" stroke="var(--ink)" stroke-width="5">
		<circle cx="24" cy="22" r="11.5"/><circle cx="24" cy="11" r="7"/><circle cx="31.8" cy="14.2" r="7"/>
		<circle cx="35" cy="22" r="7"/><circle cx="31.8" cy="29.8" r="7"/><circle cx="24" cy="33" r="7"/>
		<circle cx="16.2" cy="29.8" r="7"/><circle cx="13" cy="22" r="7"/><circle cx="16.2" cy="14.2" r="7"/>
	</g>
	<g fill="var(--wool,#F8F8F2)">
		<circle cx="24" cy="22" r="11.5"/><circle cx="24" cy="11" r="7"/><circle cx="31.8" cy="14.2" r="7"/>
		<circle cx="35" cy="22" r="7"/><circle cx="31.8" cy="29.8" r="7"/><circle cx="24" cy="33" r="7"/>
		<circle cx="16.2" cy="29.8" r="7"/><circle cx="13" cy="22" r="7"/><circle cx="16.2" cy="14.2" r="7"/>
	</g>
	<path d="M19.5 9.5c1.6-1.8 4.2-2.4 6.3-1.6M8.9 18.2c.5-1.9 1.8-3.3 3.4-3.9" fill="none" stroke="#FFFFFF" stroke-opacity=".7" stroke-width="2" stroke-linecap="round" opacity="var(--shine,1)"/>
	<g fill="var(--spots,none)">
		<circle cx="14.6" cy="15.2" r="3.3"/><circle cx="34.6" cy="27.2" r="3.4"/><circle cx="31" cy="11.6" r="2.4"/><circle cx="12.4" cy="27.6" r="2.2"/>
	</g>
	<g opacity="var(--horns,0)" fill="none" stroke-linecap="round">
		<path d="M18 17.5c-3.8-4.6-10.6-2.6-9.6 2.4.6 2.9 4 3.4 5.2 1.4" stroke="var(--ink)" stroke-width="7"/>
		<path d="M30 17.5c3.8-4.6 10.6-2.6 9.6 2.4-.6 2.9-4 3.4-5.2 1.4" stroke="var(--ink)" stroke-width="7"/>
		<path d="M18 17.5c-3.8-4.6-10.6-2.6-9.6 2.4.6 2.9 4 3.4 5.2 1.4" stroke="var(--horn,#EEDEBE)" stroke-width="3.2"/>
		<path d="M30 17.5c3.8-4.6 10.6-2.6 9.6 2.4-.6 2.9-4 3.4-5.2 1.4" stroke="var(--horn,#EEDEBE)" stroke-width="3.2"/>
	</g>
	<g stroke="var(--ink)" stroke-width="2.5" stroke-linejoin="round" fill="var(--face,#EED8B6)">
		<ellipse cx="13.2" cy="21.6" rx="5.6" ry="3.1" transform="rotate(-24 13.2 21.6)"/>
		<ellipse cx="34.8" cy="21.6" rx="5.6" ry="3.1" transform="rotate(24 34.8 21.6)"/>
		<path d="M24 17.5c5.5 0 8 4 8 9.3 0 5.7-3.4 9.7-8 9.7s-8-4-8-9.7c0-5.3 2.5-9.3 8-9.3z"/>
	</g>
	<g fill="var(--ink)" stroke="var(--ink)" stroke-width="5">
		<circle cx="20" cy="17.8" r="4"/><circle cx="24" cy="15.6" r="4.6"/><circle cx="28" cy="17.8" r="4"/>
	</g>
	<g fill="var(--wool,#F8F8F2)">
		<circle cx="20" cy="17.8" r="4"/><circle cx="24" cy="15.6" r="4.6"/><circle cx="28" cy="17.8" r="4"/>
	</g>
	<g>
		<ellipse cx="18.8" cy="30.4" rx="1.9" ry="1.1" fill="#F29C98" opacity="var(--blush,.75)"/>
		<ellipse cx="29.2" cy="30.4" rx="1.9" ry="1.1" fill="#F29C98" opacity="var(--blush,.75)"/>
		<circle cx="20.4" cy="26.4" r="2.5" fill="#F7FAFF"/><circle cx="27.6" cy="26.4" r="2.5" fill="#F7FAFF"/>
		<circle cx="20.8" cy="26.8" r="1.6" fill="var(--ink)"/><circle cx="27.2" cy="26.8" r="1.6" fill="var(--ink)"/>
		<path d="M22 31.6q2 1.5 4 0" fill="none" stroke="var(--mouth,var(--ink))" stroke-width="1.8" stroke-linecap="round"/>
	</g>
</symbol>
<symbol id="sparkle" viewBox="0 0 32 32">
	<path d="M16 3c.9 6.8 2.8 8.8 10 10-7.2 1.2-9.1 3.2-10 10-.9-6.8-2.8-8.8-10-10 7.2-1.2 9.1-3.2 10-10z" fill="var(--c1,#FFBE21)" stroke="var(--ink)" stroke-width="2.2" stroke-linejoin="round"/>
	<path d="M25.5 21.5c.4 2.6 1.1 3.3 3.8 3.8-2.7.5-3.4 1.2-3.8 3.8-.4-2.6-1.1-3.3-3.8-3.8 2.7-.5 3.4-1.2 3.8-3.8z" fill="var(--c1,#FFBE21)" stroke="var(--ink)" stroke-width="1.6" stroke-linejoin="round"/>
</symbol>
</svg>`;

function isDark(hex) {
	const n = parseInt(hex.slice(1), 16);
	return (((n >> 16) & 255) * 0.299 + ((n >> 8) & 255) * 0.587 + (n & 255) * 0.114) / 255 < 0.45;
}

// A family's token as SheepIcon.Paint draws it: a Royal fleece's wool gold, a Rare or Royal one with sparkles.
export function token(family, { size = 74, rarity = 1, extra = "", style = "" } = {}) {
	const look = DATA.Families[family];
	const painted = rarity >= 3 || look.Rainbow;
	const wool = rarity >= 3 ? DATA.GoldWool : look.Wool;
	const vars = [`--wool:${wool}`, `--face:${look.Face}`, `--legs:${look.Legs}`];
	if (look.Spots && !painted) {
		vars.push(`--spots:${look.Spots}`);
	}
	if (look.Horn) {
		vars.push("--horns:1", `--horn:${look.Horn}`);
	}
	if (isDark(look.Face)) {
		vars.push("--mouth:#D8C8C2", "--blush:0");
	}
	if (painted || isDark(wool)) {
		vars.push("--shine:.55");
	}
	let sparkles = "";
	if (rarity >= 2) {
		const color = rarity >= 3 ? "#ffc428" : "#96d2ff";
		const spark = (left, top, share) =>
			`<svg class="spark" style="left:${left}%;top:${top}%;width:${size * share}px;height:${size * share}px;--c1:${color}"><use href="#sparkle"/></svg>`;
		sparkles = spark(-6, -4, 0.34) + spark(74, 8, 0.26);
	}
	return `<span class="token ${extra}" style="width:${size}px;height:${size}px;${vars.join(";")};${style}"><svg viewBox="0 0 48 48"><use href="#token"/></svg>${sparkles}</span>`;
}

// The card colour for a fleece (SheepIcon.RarityLook).
export const rarityLook = (rarity) => (rarity >= 3 ? "legendary" : rarity === 2 ? "rare" : "common");

// ---------------------------------------------------------------------------------------------------------------------
// Components (Prize Fleece)

export const ol = (text, width = 5) => `<span class="ol" style="--sw:${width}px">${text}</span>`;
export const lbl = (text) => `<span class="lbl">${text}</span>`;

const X_SVG = `<svg viewBox="0 0 26 26"><path d="M6 6l14 14M20 6L6 20" stroke="#12131a" stroke-width="9" stroke-linecap="round"/><path d="M6 6l14 14M20 6L6 20" stroke="#fff" stroke-width="4.5" stroke-linecap="round"/></svg>`;

export const closeButton = () => `<div class="close">${X_SVG}</div>`;

export const ACCENT = {
	sell: ["#8af06a", "#3cbf35", "#227d20"],
	shop: ["#6cc4ff", "#2f8ff0", "#1b5fb0"],
	confirm: ["#6cc4ff", "#2f8ff0", "#1b5fb0"],
	warning: ["#ff8a7a", "#e8463c", "#9e1d17"],
	daily: ["#ffe066", "#ffb31a", "#b06f00"],
};

export function accentVars(name) {
	const [hi, base, lo] = ACCENT[name];
	return `--a-hi:${hi};--a:${base};--a-lo:${lo}`;
}

// A panel: its size (h "auto" grows with its body), accent, the header's badge picture and title, what sits on the
// header's right before the close, and the body.
export function panel({ w, h, accent, badge, title, chips = "", body, extra = "", style = "" }) {
	const height = h === "auto" ? "" : `--h:${h}px;`;
	return `<div class="panel ${h === "auto" ? "auto" : ""} ${extra}" style="--w:${w}px;${height}${accentVars(accent)};${style}">
		<div class="hdr">
			${badge ? ico(badge, 88, "badge") : ""}
			<div class="title ol">${title}</div>
			<div class="spacer"></div>
			${chips}
			${closeButton()}
		</div>
		<div class="pbody">${body}</div>
	</div>`;
}

export const hchip = (icon, text, extra = "") => `<div class="hchip ${extra}">${icon}${ol(text, 5)}</div>`;

// A button. kind: buy, action, danger, soft, short, off. size: sm, hero, wide.
export function btn(kind, content, { size = "", state = "", style = "" } = {}) {
	return `<div class="btn ${kind} ${size} ${state}" style="${style}">${content}</div>`;
}

export const cashLabel = (amount, icon = 30) => `${ico("cash", icon)}${lbl(short(amount))}`;

// ---------------------------------------------------------------------------------------------------------------------
// Frames

const WORLD = {
	plots: "/DESIGN/ui/assets/world-plots.jpg",
};

function topbar() {
	const logo = `<svg viewBox="0 0 24 24"><path d="M7.2 3.4l13.4 3.8-3.8 13.4L3.4 16.8z" stroke-width="2.4"/></svg>`;
	const menu = `<svg viewBox="0 0 24 24"><path d="M4 7h16M4 12h16M4 17h16"/></svg>`;
	const chat = `<svg viewBox="0 0 24 24"><path d="M5 5.5h14a1.5 1.5 0 0 1 1.5 1.5v8a1.5 1.5 0 0 1-1.5 1.5h-7l-4.5 3.5v-3.5H5A1.5 1.5 0 0 1 3.5 15V7A1.5 1.5 0 0 1 5 5.5z"/></svg>`;
	return `<div class="rbx"><span>${logo}</span><span>${menu}${chat}</span></div>`;
}

// This game's HUD at the top right (Hud.luau): Climbing with its shoe, then the coins with the bills.
function hud(coins, climb, scale) {
	return `<div class="sas-hud" style="transform:scale(${scale});transform-origin:top right">
		<div class="stat">${ico("shoe", 52)}<div class="stack">${ol(short(climb), 7)}<small>${ol("CLIMBING", 4)}</small></div></div>
		<div class="stat">${ico("cash", 52)}<div class="stack cash">${ol(short(coins), 7)}</div></div>
	</div>`;
}

// A pop-up over a menu: the menu dimmed behind it, the pop-up centred on the screen.
const overlay = (over, u) => (over ? `<div class="dim"></div><div class="stage" style="--u:${u};--cy:50%">${over}</div>` : "");

// A phone held sideways: 844 x 390 at UIScale 1, saved at 2x. Panels sit under Roblox's buttons (44 pt).
export function phoneFrame(id, content, { coins = 0, climb = 0, world = "plots", u = 1, cy = "calc(50% + 21px)", over } = {}) {
	return `<div class="frame phone" data-id="${id}" data-w="844" data-h="390" data-scale="2" style="width:844px;height:390px">
		<img class="world" src="${WORLD[world]}" alt="">
		${hud(coins, climb, 0.62)}
		${topbar()}
		<div class="backdrop"></div>
		<div class="stage" style="--u:${u};--cy:${cy}">${content}</div>
		${overlay(over, u)}
	</div>`;
}

// A PC screen: 1600 x 900 at UIScale 1.31 (1 + (900 - 390) x 0.0006), saved at 1.2x (1920 x 1080).
export function pcFrame(id, content, { coins = 0, climb = 0, world = "plots", u = 1.306, cy = "50%", over } = {}) {
	return `<div class="frame pc" data-id="${id}" data-w="1600" data-h="900" data-scale="1.2" style="width:1600px;height:900px">
		<img class="world" src="${WORLD[world]}" alt="">
		${hud(coins, climb, 1)}
		${topbar()}
		<div class="backdrop"></div>
		<div class="stage" style="--u:${u};--cy:${cy}">${content}</div>
		${overlay(over, u)}
	</div>`;
}

export function shot(frame, caption) {
	return `<figure class="shot">${frame}${caption ? `<figcaption>${caption}</figcaption>` : ""}</figure>`;
}

// ---------------------------------------------------------------------------------------------------------------------

// Shrinks a one-line label until it fits its box (TextScaled with a UITextSizeConstraint in Roblox).
export function fitText(root = document) {
	for (const element of root.querySelectorAll(".fit")) {
		let size = parseFloat(getComputedStyle(element).fontSize);
		while (element.scrollWidth > element.clientWidth + 0.5 && size > 10) {
			size -= 0.5;
			element.style.fontSize = `${size}px`;
		}
	}
}

// Builds the page, then keeps the board or strips it to one frame (render.mjs opens ?solo=<id> for each).
export async function boot(build) {
	document.body.dataset.width = "1896";
	document.body.insertAdjacentHTML("afterbegin", SPRITE);
	await build();
	await document.fonts.ready;
	fitText();
	const solo = new URLSearchParams(location.search).get("solo");
	if (solo) {
		const frame = document.querySelector(`.frame[data-id="${solo}"]`);
		document.body.className = "solo";
		document.body.replaceChildren(document.querySelector("svg"), frame);
	}
	document.body.removeAttribute("data-pending");
}
