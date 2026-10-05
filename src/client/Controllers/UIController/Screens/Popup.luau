--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Utils.Format)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Motion = require(script.Parent.Parent.Motion)
local Types = require(script.Parent.Parent.Types)

-- Moments over everything: the big celebration (a lamb's adult size, a merge) and the welcome-back card with the coins
-- earned while away (Shear a Sheep's celebration and pop-up card).
local Popup = {}

function Popup.Build(playerGui: Instance): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "Popup"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 12
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local root = UIKit.Root(gui)
	local celebration = UIKit.Celebration(root, "Celebration", "PopLabel")
	celebration.Position = UDim2.fromScale(0.5, 0.42)
	local card, body = UIKit.PopCard(root, "AwayCard", {
		Width = Theme.Fleece.Small,
		Title = "Welcome back!",
		Accent = "Daily",
		Badge = Theme.Icons.HudCash,
		Gap = 10,
	})
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Visible = false
	UIKit.Text(body, "CoinsLabel", "", 30, Theme.Color.Lime, UDim2.new(1, 0, 0, 36), {
		Stroke = Theme.Color.Line,
		Order = 1,
	})
	UIKit.Text(body, "DetailLabel", "", 18, Theme.Fleece.Muted, UDim2.new(1, 0, 0, 24), {
		Font = Theme.Font.TextHeavy,
		Order = 2,
	})
	local ok = UIKit.Button(body, "OkButton", "Buy", 160, Theme.ButtonHeight.Standard, "Collect")
	ok.LayoutOrder = 3
	UIKit.LightText(card)
	gui.Parent = playerGui
	return gui
end

function Popup.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local root = gui:FindFirstChild("Root") :: Frame
	local celebration = root:FindFirstChild("Celebration") :: Frame
	local popLabel = celebration:FindFirstChild("PopLabel") :: TextLabel
	local lineLabel = celebration:FindFirstChild("LineLabel") :: TextLabel
	local burst = celebration:FindFirstChild("Burst") :: ImageLabel
	local card = root:FindFirstChild("AwayCard") :: Frame
	local coinsLabel = card:FindFirstChild("CoinsLabel", true) :: TextLabel
	local detailLabel = card:FindFirstChild("DetailLabel", true) :: TextLabel
	local okButton = card:FindFirstChild("OkButton", true) :: TextButton
	local sound = context.Controllers.SoundController
	local stateController = context.Controllers.StateController

	local function celebrate(title: string, line: string)
		popLabel.Text = title
		lineLabel.Text = line
		lineLabel.Visible = line ~= ""
		Motion.Celebrate(celebration, { popLabel, lineLabel }, burst)
	end

	trove:Add(Remotes.Reveal:Connect(function(name: string, size: string)
		sound:Play(if size == "Giant" then "RevealFanfare" elseif size == "Large" then "Reveal" else "StepDone")
		celebrate(if size == "Standard" then "Grown up!" else `{string.upper(size)}!`, name)
	end))
	trove:Add(stateController.Offline:Connect(function(coins: number, matured: number)
		coinsLabel.Text = `+{Format.Short(coins)} coins`
		detailLabel.Text = if matured > 0
			then `{matured} lambs grew up while you were away`
			else "Your flock kept earning"
		card.Visible = true
		Motion.PopIn(card, nil)
		sound:Play("RevealCoins")
	end))
	trove:Connect(okButton.Activated, function()
		Motion.PopOut(card, nil, function()
			card.Visible = false
		end)
	end)

	local screen = {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Clean()
			gui:Destroy()
		end,
		Celebrate = function(_self: any, title: string, line: string)
			celebrate(title, line)
		end,
	}
	return screen :: any
end

return Popup
