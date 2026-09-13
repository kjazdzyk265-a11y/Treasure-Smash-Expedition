local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Tools = require(ReplicatedStorage.Shared.Tools)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local smashRemote = remotes:WaitForChild("SmashRequest") :: RemoteEvent
local feedbackRemote = remotes:WaitForChild("SmashFeedback") :: RemoteEvent
local purchaseToolRemote = remotes:WaitForChild("PurchaseTool") :: RemoteEvent
local purchaseUpgradeRemote = remotes:WaitForChild("PurchaseUpgrade") :: RemoteEvent
local progressionFeedback = remotes:WaitForChild("ProgressionFeedback") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "TreasureSmashHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local function styleBox(object: GuiObject, radius: number?)
    object.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 14)
    corner.Parent = object
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 4
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Parent = object
end

local function makeLabel(parent: Instance, text: string, size: UDim2, position: UDim2): TextLabel
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Text = text
    label.Parent = parent
    return label
end

local coins = Instance.new("TextLabel")
coins.Size = UDim2.fromOffset(220, 54)
coins.AnchorPoint = Vector2.new(0.5, 1)
coins.Position = UDim2.new(0.5, 0, 1, -18)
coins.BackgroundColor3 = Color3.fromRGB(255, 193, 36)
coins.TextColor3 = Color3.new(1, 1, 1)
coins.TextStrokeTransparency = 0
coins.TextScaled = true
coins.Font = Enum.Font.GothamBlack
coins.Text = "COINS  0"
coins.Parent = gui
styleBox(coins)

local power = Instance.new("TextLabel")
power.Size = UDim2.fromOffset(220, 48)
power.AnchorPoint = Vector2.new(0.5, 0)
power.Position = UDim2.new(0.5, 0, 0, 18)
power.BackgroundColor3 = Color3.fromRGB(70, 176, 255)
power.TextColor3 = Color3.new(1, 1, 1)
power.TextStrokeTransparency = 0
power.TextScaled = true
power.Font = Enum.Font.GothamBlack
power.Text = "POWER  1"
power.Parent = gui
styleBox(power)

local toolLabel = makeLabel(gui, "WOODEN HAMMER", UDim2.fromOffset(330, 38), UDim2.new(0.5, -165, 0, 74))

local hint = makeLabel(gui, "SMASH → COINS → UPGRADE → NEXT TOOL", UDim2.fromOffset(420, 38), UDim2.new(0.5, -210, 0, 116))

local shopButton = Instance.new("TextButton")
shopButton.Size = UDim2.fromOffset(145, 58)
shopButton.Position = UDim2.fromOffset(20, 95)
shopButton.BackgroundColor3 = Color3.fromRGB(74, 220, 105)
shopButton.TextColor3 = Color3.new(1, 1, 1)
shopButton.TextStrokeTransparency = 0
shopButton.TextScaled = true
shopButton.Font = Enum.Font.GothamBlack
shopButton.Text = "SHOP"
shopButton.Parent = gui
styleBox(shopButton)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 430, 0, 520)
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Position = UDim2.new(0, 20, 0.5, 25)
panel.BackgroundColor3 = Color3.fromRGB(38, 45, 68)
panel.Visible = false
panel.Parent = gui
styleBox(panel, 18)

local title = makeLabel(panel, "TOOLS & UPGRADES", UDim2.new(1, -70, 0, 58), UDim2.fromOffset(20, 8))
title.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(48, 48)
closeButton.Position = UDim2.new(1, -58, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(239, 78, 78)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextStrokeTransparency = 0
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBlack
closeButton.Text = "X"
closeButton.Parent = panel
styleBox(closeButton, 12)

local nextToolInfo = makeLabel(panel, "", UDim2.new(1, -30, 0, 64), UDim2.fromOffset(15, 78))
nextToolInfo.TextWrapped = true

local buyToolButton = Instance.new("TextButton")
buyToolButton.Size = UDim2.new(1, -30, 0, 58)
buyToolButton.Position = UDim2.fromOffset(15, 146)
buyToolButton.BackgroundColor3 = Color3.fromRGB(255, 187, 47)
buyToolButton.TextColor3 = Color3.new(1, 1, 1)
buyToolButton.TextStrokeTransparency = 0
buyToolButton.TextScaled = true
buyToolButton.Font = Enum.Font.GothamBlack
buyToolButton.Text = "BUY NEXT TOOL"
buyToolButton.Parent = panel
styleBox(buyToolButton, 12)

local upgradeTitle = makeLabel(panel, "UPGRADES", UDim2.new(1, -30, 0, 40), UDim2.fromOffset(15, 218))
upgradeTitle.TextXAlignment = Enum.TextXAlignment.Left

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -30, 0, 240)
scroll.Position = UDim2.fromOffset(15, 266)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 8
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = scroll

local upgradeButtons: {[string]: TextButton} = {}
local orderedUpgrades = {"Damage", "AttackSpeed", "Range", "MovementSpeed", "Luck", "CritChance", "CoinGain", "BackpackSlots", "PetSlots"}
for _, name in orderedUpgrades do
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -8, 0, 52)
    button.BackgroundColor3 = Color3.fromRGB(98, 92, 230)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextStrokeTransparency = 0
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Text = name
    button.Parent = scroll
    styleBox(button, 10)
    upgradeButtons[name] = button
    button.Activated:Connect(function()
        purchaseUpgradeRemote:FireServer(name)
    end)
end

local toast = Instance.new("TextLabel")
toast.Size = UDim2.fromOffset(360, 60)
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.new(0.5, 0, 0.35, 0)
toast.BackgroundColor3 = Color3.fromRGB(42, 50, 70)
toast.BackgroundTransparency = 0.08
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextStrokeTransparency = 0
toast.TextScaled = true
toast.Font = Enum.Font.GothamBlack
toast.Visible = false
toast.ZIndex = 20
toast.Parent = gui
styleBox(toast, 14)

local function formatNumber(value: number): string
    if value >= 1e9 then return string.format("%.1fB", value / 1e9) end
    if value >= 1e6 then return string.format("%.1fM", value / 1e6) end
    if value >= 1e3 then return string.format("%.1fK", value / 1e3) end
    return tostring(math.floor(value))
end

local function refreshProgression()
    local toolIndex = math.clamp(player:GetAttribute("ToolIndex") or 1, 1, #Tools)
    local current = Tools[toolIndex]
    toolLabel.Text = string.upper(current.Name) .. "  •  DMG " .. formatNumber(player:GetAttribute("SmashDamage") or current.Damage)

    local nextTool = Tools[toolIndex + 1]
    if nextTool then
        nextToolInfo.Text = string.upper(nextTool.Name) .. "\nDMG " .. formatNumber(nextTool.Damage) .. "  •  COST " .. formatNumber(nextTool.Price)
        buyToolButton.Text = "BUY FOR " .. formatNumber(nextTool.Price)
        buyToolButton.Active = true
        buyToolButton.AutoButtonColor = true
    else
        nextToolInfo.Text = "MAX TOOL UNLOCKED"
        buyToolButton.Text = "MAX TOOL"
        buyToolButton.Active = false
        buyToolButton.AutoButtonColor = false
    end

    local folder = player:FindFirstChild("Upgrades")
    for name, button in pairs(upgradeButtons) do
        local levelValue = folder and folder:FindFirstChild(name)
        local level = levelValue and levelValue.Value or 0
        local cfg = Upgrades[name]
        local cost = Upgrades.GetCost(name, level)
        if level >= cfg.MaxLevel then
            button.Text = name .. "  LV." .. level .. "  MAX"
        else
            button.Text = name .. "  LV." .. level .. "  •  " .. formatNumber(cost or 0)
        end
    end
end

local function bindStats()
    local stats = player:WaitForChild("leaderstats")
    local coinsValue = stats:WaitForChild("Coins") :: IntValue
    local powerValue = stats:WaitForChild("Power") :: IntValue
    local function update()
        coins.Text = "COINS  " .. formatNumber(coinsValue.Value)
        power.Text = "POWER  " .. formatNumber(powerValue.Value)
        refreshProgression()
    end
    update()
    coinsValue:GetPropertyChangedSignal("Value"):Connect(update)
    powerValue:GetPropertyChangedSignal("Value"):Connect(update)

    local folder = player:WaitForChild("Upgrades")
    for _, child in folder:GetChildren() do
        if child:IsA("IntValue") then child:GetPropertyChangedSignal("Value"):Connect(refreshProgression) end
    end
end
task.spawn(bindStats)

player:GetAttributeChangedSignal("ToolIndex"):Connect(refreshProgression)
player:GetAttributeChangedSignal("SmashDamage"):Connect(refreshProgression)

shopButton.Activated:Connect(function()
    panel.Visible = not panel.Visible
    refreshProgression()
end)
closeButton.Activated:Connect(function()
    panel.Visible = false
end)
buyToolButton.Activated:Connect(function()
    purchaseToolRemote:FireServer()
end)

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
    if processed or panel.Visible then return end
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

progressionFeedback.OnClientEvent:Connect(function(success, message)
    toast.Text = tostring(message)
    toast.BackgroundColor3 = success and Color3.fromRGB(65, 188, 92) or Color3.fromRGB(220, 74, 74)
    toast.Visible = true
    toast.TextTransparency = 0
    toast.BackgroundTransparency = 0.08
    TweenService:Create(toast, TweenInfo.new(0.14), {Size = UDim2.fromOffset(390, 68)}):Play()
    task.delay(1.15, function()
        if not toast.Parent then return end
        local tween = TweenService:Create(toast, TweenInfo.new(0.25), {TextTransparency = 1, BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Wait()
        toast.Visible = false
        toast.Size = UDim2.fromOffset(360, 60)
    end)
end)

refreshProgression()
