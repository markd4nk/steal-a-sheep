--!strict

-- Each god's Roblox avatar (Avatar.Build): a dynamic head (the classic angry face), catalog accessories by asset id
-- (rigid: Hair, Hat, Face, Neck, Shoulder, Front, Back, Waist; layered clothing: Shirt, Pants, Jacket, Sweater,
-- Shorts, DressSkirt, TShirt, LeftShoe, RightShoe), classic clothing, and the symbol held in its fist (Props).
-- Skin is the tier's (Config/Olympus). A game may dress its NPCs in any catalog item without owning it; an item
-- Roblox removes just stops loading, so prefer Roblox's own items and established creators.

export type Item = { Id: number, Type: string }

export type Look = {
	Head: number,
	Accessories: { Item },
	Shirt: number?,
	Pants: number?,
	Torso: Color3?, -- the body's colour under the clothes when it isn't skin
	Legs: Color3?,
	Prop: string?,
	Raise: boolean?, -- holds the symbol overhead (the client lifts the arm)
}

local ANGRY = 90077016726721 -- "Classic Style Angry Face" (Lastinker), the user's pick

local Looks: { [string]: Look } = {
	Zeus = {
		Head = ANGRY,
		Accessories = {
			{ Id = 126795757748952, Type = "Hair" }, -- Greek Mythology God Hair White (U8DEV)
			{ Id = 76239336562150, Type = "Face" }, -- Greek Mythology God Beard Grey (U8DEV)
			{ Id = 10770304, Type = "Hat" }, -- Crown of Golden Laurels (Roblox)
			{ Id = 87233169181342, Type = "Back" }, -- Ancient Greece Greek God Robe (Manga Infinite)
		},
		Prop = "Bolt",
		Raise = true,
	},
}

return table.freeze(Looks)
