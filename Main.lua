local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

local oldGui = CoreGui:FindFirstChild("CoordinatesDisplay")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CoordinatesDisplay"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(190, 30)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 5)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -52, 1, 0)
label.Position = UDim2.fromOffset(5, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.Arcade
label.TextSize = 10
label.TextScaled = false
label.TextWrapped = false
label.TextTruncate = Enum.TextTruncate.AtEnd
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Center
label.Text = "X:0 Y:0 Z:0"
label.Parent = frame

local switch = Instance.new("TextButton")
switch.Size = UDim2.fromOffset(20, 22)
switch.Position = UDim2.new(1, -46, 0, 4)
switch.BackgroundTransparency = 1
switch.Text = "↻"
switch.TextColor3 = Color3.fromRGB(255, 255, 255)
switch.Font = Enum.Font.Arcade
switch.TextSize = 12
switch.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(20, 22)
close.Position = UDim2.new(1, -23, 0, 4)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 90, 90)
close.Font = Enum.Font.Arcade
close.TextSize = 12
close.Parent = frame

local mode = "Coordinates"
local frames = 0
local elapsed = 0
local currentFPS = 0
local currentPing = 0
local currentRAM = 0
local updateElapsed = 0
local connections = {}
local dragging = false
local dragStart
local startPosition
local destroyed = false

local function getPing()
    local success, result = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)

    return success and result or 0
end

local function getRAM()
    local success, result = pcall(function()
        return Stats:GetTotalMemoryUsageMb()
    end)

    if success then
        return result
    end

    return 0
end

local function isOverButton(position, button)
    local p = button.AbsolutePosition
    local s = button.AbsoluteSize

    return position.X >= p.X
        and position.X <= p.X + s.X
        and position.Y >= p.Y
        and position.Y <= p.Y + s.Y
end

table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    if destroyed then
        return
    end

    stroke.Color = Color3.fromHSV((os.clock() * 0.35) % 1, 1, 1)

    frames += 1
    elapsed += dt
    updateElapsed += dt

    if elapsed >= 0.5 then
        currentFPS = math.floor(frames / elapsed + 0.5)
        frames = 0
        elapsed = 0
    end

    if updateElapsed >= 1 then
        currentPing = math.floor(getPing() + 0.5)
        currentRAM = math.floor(getRAM() + 0.5)
        updateElapsed = 0
    end

    if mode == "Coordinates" then
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if root then
            local pos = root.Position
            label.Text = string.format("X:%d Y:%d Z:%d", pos.X, pos.Y, pos.Z)
        else
            label.Text = "X:-- Y:-- Z:--"
        end
    else
        label.Text = string.format(
            "Fps:%d Ram:%d Ping:%d",
            currentFPS,
            currentRAM,
            currentPing
        )
    end
end))

switch.Activated:Connect(function()
    if destroyed then
        return
    end

    mode = mode == "Coordinates" and "Performance" or "Coordinates"
end)

frame.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    if isOverButton(input.Position, close)
        or isOverButton(input.Position, switch) then
        return
    end

    dragging = true
    dragStart = input.Position
    startPosition = frame.Position
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    frame.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

close.Activated:Connect(function()
    destroyed = true
    dragging = false

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end

    gui:Destroy()
end)
