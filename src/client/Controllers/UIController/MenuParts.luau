--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Config.Theme)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Motion = require(script.Parent.Motion)

-- Pieces the menus share, from Shear a Sheep's menu builders (studio/BuildMenus.luau): the card grid in a well, the
-- picked thing's detail beside it (a 3D look at the sheep in place of its picture sheet), and the confirm card.
local MenuParts = {}

local Color = Theme.Color
local Fleece = Theme.Fleece

MenuParts.GridWidth = 462 -- four cards and their gaps, and the well's margins

function MenuParts.Pages(window: Frame): Frame
	return window:FindFirstChild("Pages") :: Frame
end

-- A well of cards four to a row (List, a ScrollingFrame; CardTemplate a hidden UIKit.SheepCard).
function MenuParts.CardGrid(page: Frame, width: number?): Frame
	local well = UIKit.Well(page, "GridWell", UDim2.new(0, width or MenuParts.GridWidth, 1, 0))
	well.ClipsDescendants = true
	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.fromScale(1, 1)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.ScrollBarImageColor3 = Color.Snow
	list.ScrollBarImageTransparency = 0.5
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	list.Selectable = false
	list.ZIndex = 2
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(Fleece.Card.X, Fleece.Card.Y)
	grid.CellPadding = UDim2.fromOffset(Fleece.CardGap, 14)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = list
	UIKit.Padding(list, 14, 6, 14, 20)
	list.Parent = well
	local template = UIKit.SheepCard(list, "CardTemplate")
	template.Visible = false
	-- The card's picture becomes a sheep token.
	local face = template:FindFirstChild("Face") :: Frame
	local picture = face:FindFirstChild("Picture")
	if picture then
		picture:Destroy()
	end
	local token = UIKit.Token(face, 74, "Token")
	token.AnchorPoint = Vector2.new(0.5, 0)
	token.Position = UDim2.new(0.5, 0, 0, 6)
	token.ZIndex = 2
	return well
end

-- The detail beside the grid: Card (Stage with a ViewportFrame, NameLabel, Chips: RarityChip, RankChip, RateChip),
-- Info (lines of text), and Buttons. Returns the detail tile.
function MenuParts.Detail(page: Frame, leftWidth: number): Frame
	local detail = UIKit.Tile(page, "Detail", UDim2.new(1, -(leftWidth + Fleece.Inset - 2), 1, -4))
	detail.AnchorPoint = Vector2.new(1, 0)
	detail.Position = UDim2.fromScale(1, 0)
	UIKit.Padding(detail, 9, 9, 15, 10)
	UIKit.List(detail, false, 6, Enum.HorizontalAlignment.Center)
	local card = UIKit.Frame(detail, "Card", UDim2.new(1, 0, 0, 150))
	card.LayoutOrder = 1
	-- On a short screen (a phone held sideways) the picture gives up height so the buttons under it stay in the menu.
	local shrink = Instance.new("UIFlexItem")
	shrink.FlexMode = Enum.UIFlexMode.Shrink
	shrink.Parent = card
	local stage = UIKit.Stage(card, "Stage", UDim2.fromScale(1, 1), 10)
	local view = Instance.new("ViewportFrame")
	view.Name = "View"
	view.BackgroundTransparency = 1
	view.Size = UDim2.fromScale(1, 1)
	view.ZIndex = 3
	view.Ambient = Color3.fromRGB(200, 200, 200)
	view.LightColor = Color3.fromRGB(255, 255, 255)
	view.Parent = stage
	local name = UIKit.Text(card, "NameLabel", "", 22, Color.Snow, UDim2.new(1, -16, 0, 26), {
		Stroke = Color.Line,
		Fit = true,
	})
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.Position = UDim2.new(0.5, 0, 1, -7)
	name.ZIndex = 4
	local chips = UIKit.Frame(card, "Chips", UDim2.fromOffset(0, 24))
	chips.AutomaticSize = Enum.AutomaticSize.X
	chips.Position = UDim2.fromOffset(-7, -10)
	chips.ZIndex = 5
	UIKit.List(chips, true, 4)
	UIKit.RarityChip(chips, "RarityChip")
	local rank = UIKit.RarityChip(chips, "RankChip")
	rank.LayoutOrder = 1
	rank.Visible = false
	local rate = UIKit.DarkChip(chips, "RateChip", Theme.Icons.HudCash, "RateLabel")
	rate.LayoutOrder = 2
	rate.BackgroundTransparency = 0
	rate.BackgroundColor3 = Fleece.Tile.Base
	local rateLabel = rate:FindFirstChild("RateLabel") :: TextLabel
	rateLabel.TextColor3 = Color.Lime
	local info = UIKit.Frame(detail, "Info", UDim2.new(1, 0, 0, 0))
	info.LayoutOrder = 2
	info.AutomaticSize = Enum.AutomaticSize.Y
	UIKit.List(info, false, 2, Enum.HorizontalAlignment.Center)
	for index = 1, 3 do
		UIKit.Text(info, `Line{index}`, "", 16, Fleece.Muted, UDim2.new(1, 0, 0, 20), {
			Font = Theme.Font.TextHeavy,
			Fit = true,
			Order = index,
		})
	end
	local bar = UIKit.Bar(info, "Bar", UDim2.new(1, -20, 0, 8))
	bar.LayoutOrder = 4
	bar.Visible = false
	local buttons = UIKit.Frame(detail, "Buttons", UDim2.new(1, 0, 0, Theme.ButtonHeight.Standard + Theme.Lip.Button))
	buttons.LayoutOrder = 3
	UIKit.List(buttons, true, 8)
	return detail
end

-- A ViewportFrame showing a family's sheep (ReplicatedStorage.SheepLooks, SheepService) at `scale`, turned a little.
function MenuParts.ShowSheep(view: ViewportFrame, family: string?, scale: number?)
	view:ClearAllChildren()
	local looks = ReplicatedStorage:FindFirstChild("SheepLooks")
	local look = if family and looks then looks:FindFirstChild(family) else nil
	if not look or not look:IsA("Model") then
		return
	end
	local model = look:Clone()
	local size = scale or 1
	if math.abs(size - 1) > 1e-3 then
		model:ScaleTo(size)
	end
	model:PivotTo(CFrame.Angles(0, math.rad(-35), 0))
	local world = Instance.new("WorldModel")
	model.Parent = world
	world.Parent = view
	local cframe, extents = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local distance = extents.Magnitude * 1.7 + 1
	camera.CFrame = CFrame.lookAt(cframe.Position + Vector3.new(0, extents.Y * 0.2, -distance), cframe.Position)
	camera.Parent = view
	view.CurrentCamera = camera
end

-- The menu's confirm card (UIKit.Confirm, built by MenuGui): shows it with its words and calls `onConfirm` on OK.
function MenuParts.Confirm(
	gui: ScreenGui,
	title: string,
	name: string,
	detail: string,
	okText: string,
	paintToken: ((token: Frame) -> ())?,
	onConfirm: () -> ()
)
	local root = gui:FindFirstChild("Root")
	local cover = root and root:FindFirstChild("Confirm")
	if not cover or not cover:IsA("Frame") then
		return
	end
	local dialog = cover:FindFirstChild("Dialog") :: Frame
	local titleLabel = dialog:FindFirstChild("TitleLabel", true)
	if titleLabel and titleLabel:IsA("TextLabel") then
		titleLabel.Text = title
	end
	local nameLabel = dialog:FindFirstChild("NameLabel", true) :: TextLabel
	local detailLabel = dialog:FindFirstChild("DetailLabel", true) :: TextLabel
	nameLabel.Text = name
	detailLabel.Text = detail
	local stage = dialog:FindFirstChild("Stage", true)
	local token = stage and stage:FindFirstChild("Token")
	if stage and stage:IsA("GuiObject") then
		stage.Visible = paintToken ~= nil and token ~= nil
	end
	if paintToken and token and token:IsA("Frame") then
		paintToken(token)
	end
	local okButton = dialog:FindFirstChild("ConfirmButton", true) :: TextButton
	local cancelButton = dialog:FindFirstChild("CancelButton", true) :: TextButton
	local okLabel = okButton:FindFirstChild("Label", true)
	if okLabel and okLabel:IsA("TextLabel") then
		okLabel.Text = okText
	end
	local connections: { RBXScriptConnection } = {}
	local function hide()
		for _, connection in connections do
			connection:Disconnect()
		end
		cover.Visible = false
	end
	table.insert(
		connections,
		okButton.Activated:Connect(function()
			hide()
			onConfirm()
		end)
	)
	table.insert(connections, cancelButton.Activated:Connect(hide))
	cover.Visible = true
	Motion.PopIn(dialog, cover:FindFirstChild("Backdrop") :: GuiObject?)
end

function MenuParts.HideConfirm(gui: ScreenGui)
	local root = gui:FindFirstChild("Root")
	local cover = root and root:FindFirstChild("Confirm")
	if cover and cover:IsA("GuiObject") then
		cover.Visible = false
	end
end

-- A card cloned from the grid's template.
function MenuParts.NewCard(list: ScrollingFrame, name: string, order: number): TextButton
	local template = list:FindFirstChild("CardTemplate") :: TextButton
	local card = template:Clone()
	card.Name = name
	card.LayoutOrder = order
	card.Visible = true
	card.Parent = list
	return card
end

-- Highlights the picked card (its Selected rings).
function MenuParts.Select(list: ScrollingFrame, picked: Instance?)
	for _, card in list:GetChildren() do
		if card:IsA("TextButton") and card.Name ~= "CardTemplate" then
			local face = card:FindFirstChild("Face")
			for _, name in { "Selected", "SelectedRing" } do
				local ring = face and face:FindFirstChild(name)
				if ring and ring:IsA("UIStroke") then
					ring.Enabled = card == picked
				end
			end
		end
	end
end

return table.freeze(MenuParts)
