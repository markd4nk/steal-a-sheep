--!strict
-- The two Robux sheep for their product icons (art/store/make_product_icons.py), as the store card shows them
-- (MenuParts.ShowSheep: the same turn, lens and light, the camera closer), with the game's studs. Run with execute_luau in a playtest's
-- Client after setting FAMILY and BACKGROUND, then screen_capture: it covers the screen in BACKGROUND (a TEMP_ gui) with
-- the sheep's view in the middle and returns the view's box in pixels. Capture it on "Black" and on "White", and
-- art/store/cut_out_sheep.py takes the sheep out with its transparency. "None" removes the gui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FAMILY = "GoldenFleece"
local BACKGROUND = "Black"
local SIDE = 310 -- the view's side in points (Studio's capture doubles it); smaller than the window's height
-- How far the camera stands, by the model's size: the store card's 1.7 left the sheep small, this fills the view.
local DISTANCE = 1.22

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("TEMP_IconRender")
if old then
	old:Destroy()
end
if BACKGROUND == "None" then
	return "removed TEMP_IconRender"
end
local colour = if BACKGROUND == "White" then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)

local gui = Instance.new("ScreenGui")
gui.Name = "TEMP_IconRender"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.ResetOnSpawn = false
local cover = Instance.new("Frame")
cover.Size = UDim2.fromScale(1, 1)
cover.BackgroundColor3 = colour
cover.BorderSizePixel = 0
cover.Parent = gui
local view = Instance.new("ViewportFrame")
view.AnchorPoint = Vector2.new(0.5, 0.5)
view.Position = UDim2.fromScale(0.5, 0.5)
view.Size = UDim2.fromOffset(SIDE, SIDE)
view.BackgroundColor3 = colour
view.BorderSizePixel = 0
-- The store card's light (Screens/Store, sheepArt).
view.Ambient = Color3.fromRGB(200, 200, 200)
view.LightColor = Color3.fromRGB(255, 255, 255)
view.Parent = cover

local looks = ReplicatedStorage:WaitForChild("SheepLooks")
local model = (looks:WaitForChild(FAMILY) :: Model):Clone()
model:PivotTo(CFrame.Angles(0, math.rad(-35), 0))
local world = Instance.new("WorldModel")
model.Parent = world
world.Parent = view
local cframe, extents = model:GetBoundingBox()
local camera = Instance.new("Camera")
camera.FieldOfView = 30
local distance = extents.Magnitude * DISTANCE + 0.5
camera.CFrame = CFrame.lookAt(cframe.Position + Vector3.new(0, extents.Y * 0.2, -distance), cframe.Position)
camera.Parent = view
view.CurrentCamera = camera
gui.Parent = playerGui

task.wait(0.5)
local at, size = view.AbsolutePosition, view.AbsoluteSize
return `{FAMILY} on {BACKGROUND}: view at {math.round(at.X)},{math.round(at.Y)} size {math.round(size.X)}x{math.round(size.Y)}`
