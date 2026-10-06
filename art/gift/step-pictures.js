// The free gift's two step pictures (Screens/Gift): Roblox's game page in its dark theme, the Play button and the
// Favorite / thumbs row under it, vote counts hidden, the other buttons faded, and the one to tap glowing (green for
// the like, gold for the favorite) with a hand tapping it. Writes build/gift-art/step-like.png and step-fav.png at 4x
// (912 x 376). Run it with the Playwright MCP: browser_run_code_unsafe with filename "art/gift/step-pictures.js".
// Any game's page works: only its buttons show. Upload the results (TESTING.md, uploading pictures) and put the new
// ids in Screens/Gift.
async (page) => {
	const GAME = 'https://www.roblox.com/games/126884695634066/Grow-a-Garden';
	const browser = page.context().browser();
	const context = await browser.newContext({ viewport: { width: 1400, height: 900 }, deviceScaleFactor: 4 });
	const p = await context.newPage();
	await p.goto(GAME, { waitUntil: 'networkidle' });
	await p.evaluate(() => {
		document.body.classList.remove('light-theme');
		document.body.classList.add('dark-theme');
		const style = document.createElement('style');
		style.textContent = `
			.vote-numbers { visibility: hidden; }
			.gift-ring { position: absolute; border-radius: 50%; pointer-events: none; z-index: 50; }
			.gift-hand { position: absolute; font-size: 40px; line-height: 1; z-index: 60;
				filter: drop-shadow(0 3px 3px rgba(0,0,0,.6)); font-family: 'Segoe UI Emoji'; }
		`;
		document.head.appendChild(style);
	});
	await p.waitForTimeout(800);
	const box = await p.evaluate(() => {
		const b = document.querySelector('.game-buttons-container').getBoundingClientRect();
		return [b.x, b.y, b.width, b.height];
	});
	const shoot = async (which) => {
		await p.evaluate((which) => {
			document.querySelectorAll('.gift-ring, .gift-hand').forEach((e) => e.remove());
			const q = (s) => document.querySelector(s);
			const favIcon = q('#game-favorite-icon');
			const favLabel = q('#game-favorite-icon-label');
			const upIcon = q('.upvote .icon-like');
			const downIcon = q('.downvote .icon-dislike');
			for (const e of [q('.btn-common-play-game-lg'), favIcon, favLabel, upIcon, downIcon, q('.vote-details')]) {
				e.style.opacity = '';
				e.style.filter = '';
			}
			const dim = (e) => { e.style.opacity = '0.3'; };
			dim(q('.btn-common-play-game-lg'));
			dim(downIcon);
			dim(q('.vote-details'));
			if (which === 'like') { dim(favIcon); dim(favLabel); } else { dim(upIcon); }
			const target = which === 'like' ? upIcon : favIcon;
			const color = which === 'like' ? '#34d27b' : '#ffc928';
			// The page's icons are white sprites: these filters turn them green or gold.
			const tint = which === 'like'
				? 'brightness(0) saturate(100%) invert(68%) sepia(56%) saturate(560%) hue-rotate(88deg) brightness(102%)'
				: 'brightness(0) saturate(100%) invert(80%) sepia(62%) saturate(1200%) hue-rotate(358deg) brightness(104%)';
			target.style.filter = tint + ` drop-shadow(0 0 6px ${color})`;
			const b = target.getBoundingClientRect();
			const cx = b.x + b.width / 2 + window.scrollX;
			const cy = b.y + b.height / 2 + window.scrollY;
			const ring = (d, w, alpha) => {
				const r = document.createElement('div');
				r.className = 'gift-ring';
				r.style.cssText += `left:${cx - d / 2}px;top:${cy - d / 2}px;width:${d}px;height:${d}px;` +
					`border:${w}px solid ${color};opacity:${alpha};box-shadow:0 0 12px ${color}, inset 0 0 8px ${color}55;`;
				document.body.appendChild(r);
			};
			ring(44, 2.5, 1);
			ring(60, 1.5, 0.4);
			const hand = document.createElement('div');
			hand.className = 'gift-hand';
			hand.textContent = '👆';
			hand.style.transform = 'rotate(-28deg)';
			hand.style.left = (cx + 6) + 'px';
			hand.style.top = (cy - 2) + 'px';
			document.body.appendChild(hand);
		}, which);
		await p.waitForTimeout(300);
		// From just under the Play button's middle to under the hand.
		await p.screenshot({
			path: `build/gift-art/step-${which}.png`,
			clip: { x: box[0] - 8, y: box[1] + 44, width: 228, height: 94 },
		});
	};
	await shoot('like');
	await shoot('fav');
	await context.close();
	return 'build/gift-art/step-like.png, step-fav.png';
}
