--!strict

export type Context = {
	Controllers: { [string]: any },
	-- Opens a screen; `options` reaches its Open.
	Open: (name: string, options: { [string]: any }?) -> (),
	Close: (name: string) -> (),
	-- A notice on whatever the player is looking at: the open menu's bottom edge, or the HUD. `cue` is a sound that
	-- plays when its words show.
	Notify: (message: string, kind: string, cue: string?) -> (),
}

export type Screen = {
	Modal: boolean,
	StartsOpen: boolean,
	Open: (self: Screen, options: { [string]: any }?) -> (),
	Close: (self: Screen) -> (),
	Destroy: (self: Screen) -> (),
	-- A menu that shows notices at its bottom edge while it's open ("Good", "Bad", "Rare"); the HUD queues them under
	-- its top row with their sound (`cue`).
	Notify: ((self: Screen, message: string, kind: string, cue: string?) -> ())?,
}

export type ScreenModule = {
	new: (context: Context, gui: ScreenGui) -> Screen,
	-- Makes the screen's ScreenGui with UIKit at runtime (every screen in this game: see DESIGN/DECISIONS.md).
	Build: ((playerGui: Instance) -> ScreenGui)?,
}

return {}
