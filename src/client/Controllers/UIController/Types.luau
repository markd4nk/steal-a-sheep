--!strict

export type Context = {
	Controllers: { [string]: any },
	-- Opens a screen; `options` reaches its Open (the Flock menu's sell mode).
	Open: (name: string, options: { [string]: any }?) -> (),
	Close: (name: string) -> (),
	-- A notice on whatever the player is looking at: the open menu's bottom edge, or the HUD.
	Notify: (message: string, kind: string) -> (),
}

export type Screen = {
	Modal: boolean,
	StartsOpen: boolean,
	Open: (self: Screen, options: { [string]: any }?) -> (),
	Close: (self: Screen) -> (),
	Destroy: (self: Screen) -> (),
	-- A menu that shows notices at its bottom edge while it's open ("Good", "Bad", "Rare").
	Notify: ((self: Screen, message: string, kind: string) -> ())?,
}

export type ScreenModule = {
	new: (context: Context, gui: ScreenGui) -> Screen,
	-- Makes the screen's ScreenGui with UIKit at runtime (every screen in this game: see DESIGN/DECISIONS.md).
	Build: ((playerGui: Instance) -> ScreenGui)?,
}

return {}
