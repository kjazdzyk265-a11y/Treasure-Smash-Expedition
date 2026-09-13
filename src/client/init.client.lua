local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local smashRemote = remotes:WaitForChild("SmashRequest") :: RemoteEvent
local feedbackRemote = remotes:WaitForChild("SmashFeedback") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "TreasureSmashHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local coins = Instance.new("TextLabel")
coins.Size = UDim2.fromOffset(220, 54)
coins.Position = UDim2.new(0.5, -110, 1, -72)
coins.BackgroundColor3 = Color3.fromRGB(255, 193, 36)
coins.BorderSizePixel = 0
coins.TextColor3 = Color3.new(1, 1, 1)
coins.TextStrokeTransparency = 0
coins.TextScaled = true
coins.Font = Enum.Font.GothamBlack
coins.Text = "COINS  0"
coins.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = coins
local stroke = Instance.new("UIStroke")
stroke.Thickness = 4
stroke.Color = Color3.new(0, 0, 0)
stroke.Parent = coins

local hint = Instance.new("TextLabel")
hint.Size = UDim2.fromOffset(360, 44)
hint.Position = UDim2.new(0.5, -180, 0, 24)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.new(1, 1, 1)
hint.TextStrokeTransparency = 0
hint.TextScaled = true
hint.Font = Enum.Font.GothamBlack
hint.Text = "SMASH OBJECTS → EARN COINS → GET STRONGER"
hint.Parent = gui

local function updateCoins()
    local stats = player:FindFirstChild("leaderstats")
    local value = stats and stats:FindFirstChild("Coins")
    if value then coins.Text = "COINS  " .. value.Value end
end

local function bindStats()
    local stats = player:WaitForChild("leaderstats")
    local value = stats:WaitForChild("Coins")
    updateCoins()
    value:GetPropertyChangedSignal("Value"):Connect(updateCoins)
end
task.spawn(bindStats)

local function raycastTarget(screenPos: Vector2): Instance?
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and {player.Character} or {}
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 150, params)
    return hit and hit.Instance or nil
end

local function requestSmash(screenPos: Vector2)
    local target = raycastTarget(screenPos)
    if target then smashRemote:FireServer(target) end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        requestSmash(UserInputService:GetMouseLocation())
    elseif input.UserInputType == Enum.UserInputType.Touch then
        requestSmash(Vector2.new(input.Position.X, input.Position.Y))
    end
end)

feedbackRemote.OnClientEvent:Connect(function(model, damage, critical)
    if typeof(model) ~= "Instance" or not model:IsA("Model") or not model.PrimaryPart then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(160, 70)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = model.PrimaryPart
    billboard.Parent = gui

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = critical and ("CRIT! -" .. math.floor(damage)) or ("-" .. math.floor(damage))
    text.TextColor3 = critical and Color3.fromRGB(255, 231, 65) or Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0
    text.TextScaled = true
    text.Font = Enum.Font.GothamBlack
    text.Parent = billboard

    TweenService:Create(billboard, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {StudsOffset = Vector3.new(0, 7, 0)}):Play()
    task.delay(0.48, function() billboard:Destroy() end)
end)
