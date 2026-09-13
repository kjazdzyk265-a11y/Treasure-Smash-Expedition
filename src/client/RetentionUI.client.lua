local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.RetentionConfig)
local Pets = require(ReplicatedStorage.Shared.Pets)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local claimRemote = remotes:WaitForChild("RetentionClaim")
local feedbackRemote = remotes:WaitForChild("RetentionFeedback")

local gui = Instance.new("ScreenGui")
gui.Name = "RetentionUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function style(object, radius)
    object.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 14)
    corner.Parent = object
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 4
    stroke.Color = Color3.new(0,0,0)
    stroke.Parent = object
end

local function text(parent, value, size, position)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = value
    label.TextColor3 = Color3.new(1,1,1)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = parent
    return label
end

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(150,56)
button.Position = UDim2.fromOffset(20,165)
button.BackgroundColor3 = Color3.fromRGB(255,117,73)
button.Text = "QUESTS"
button.TextColor3 = Color3.new(1,1,1)
button.TextStrokeTransparency = 0
button.TextScaled = true
button.Font = Enum.Font.GothamBlack
button.Parent = gui
style(button)

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(520,560)
panel.AnchorPoint = Vector2.new(0,0.5)
panel.Position = UDim2.new(0,20,0.5,35)
panel.BackgroundColor3 = Color3.fromRGB(34,39,61)
panel.Visible = false
panel.Parent = gui
style(panel,18)

text(panel,"EXPEDITION GOALS",UDim2.new(1,-80,0,55),UDim2.fromOffset(18,10))
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(46,46)
close.Position = UDim2.new(1,-58,0,12)
close.BackgroundColor3 = Color3.fromRGB(229,68,68)
close.Text = "X"
close.TextScaled = true
close.Font = Enum.Font.GothamBlack
close.TextColor3 = Color3.new(1,1,1)
close.Parent = panel
style(close,10)

local summary = text(panel,"",UDim2.new(1,-28,0,42),UDim2.fromOffset(14,65))
local daily = Instance.new("TextButton")
daily.Size = UDim2.new(1,-28,0,58)
daily.Position = UDim2.fromOffset(14,112)
daily.BackgroundColor3 = Color3.fromRGB(63,176,103)
daily.TextColor3 = Color3.new(1,1,1)
daily.TextStrokeTransparency = 0
daily.TextScaled = true
daily.Font = Enum.Font.GothamBlack
daily.Parent = panel
style(daily,12)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-28,0,360)
scroll.Position = UDim2.fromOffset(14,184)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ScrollBarThickness = 8
scroll.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,8)
layout.Parent = scroll

local questButtons = {}
local ordered = {"Smash25","Hatch3","ReachZone3","Perfect10","Boss2"}
for _, id in ipairs(ordered) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-8,0,64)
    b.BackgroundColor3 = Color3.fromRGB(87,91,174)
    b.TextColor3 = Color3.new(1,1,1)
    b.TextStrokeTransparency = 0
    b.TextScaled = true
    b.TextWrapped = true
    b.Font = Enum.Font.GothamBold
    b.Parent = scroll
    style(b,11)
    b.Activated:Connect(function() claimRemote:FireServer("Quest", id) end)
    questButtons[id] = b
end

local toast = text(gui,"",UDim2.fromOffset(400,66),UDim2.new(.5,-200,.28,0))
toast.BackgroundTransparency = 0
toast.BackgroundColor3 = Color3.fromRGB(53,58,83)
toast.Visible = false
toast.ZIndex = 40
style(toast,14)

local function rewardText(cfg)
    local parts = {}
    if cfg.RewardCoins then table.insert(parts, "+"..cfg.RewardCoins.." COINS") end
    if cfg.RewardGems then table.insert(parts, "+"..cfg.RewardGems.." GEMS") end
    return table.concat(parts, " • ")
end

local function refresh()
    local quests = player:FindFirstChild("QuestProgress")
    local claimed = player:FindFirstChild("ClaimedQuests")
    local index = player:FindFirstChild("PetIndex")
    local discovered = index and #index:GetChildren() or 0
    local achievements = player:GetAttribute("AchievementCount") or 0
    summary.Text = "INDEX "..discovered.."/"..#Pets.."  •  ACHIEVEMENTS "..achievements.."/6"
    local streak = player:GetAttribute("DailyStreak") or 0
    local ready = player:GetAttribute("DailyReady") == true
    daily.Text = ready and ("CLAIM DAILY REWARD • DAY "..((streak % 7)+1)) or ("DAILY CLAIMED • STREAK "..streak.."/7")
    daily.Active = ready
    daily.AutoButtonColor = ready
    daily.BackgroundColor3 = ready and Color3.fromRGB(63,176,103) or Color3.fromRGB(75,83,96)

    for id, b in pairs(questButtons) do
        local cfg = Config.Quests[id]
        local progressValue = quests and quests:FindFirstChild(id)
        local claimedValue = claimed and claimed:FindFirstChild(id)
        local progress = progressValue and progressValue.Value or 0
        local done = claimedValue and claimedValue.Value == true
        b.Text = string.upper(cfg.Name).."  "..math.min(progress,cfg.Goal).."/"..cfg.Goal.."\n"..(done and "CLAIMED" or (progress >= cfg.Goal and "CLAIM NOW" or rewardText(cfg)))
        b.BackgroundColor3 = done and Color3.fromRGB(71,128,83) or (progress >= cfg.Goal and Color3.fromRGB(255,177,54) or Color3.fromRGB(87,91,174))
        b.Active = not done and progress >= cfg.Goal
        b.AutoButtonColor = b.Active
    end
end

button.Activated:Connect(function() panel.Visible = not panel.Visible; refresh() end)
close.Activated:Connect(function() panel.Visible = false end)
daily.Activated:Connect(function() if player:GetAttribute("DailyReady") == true then claimRemote:FireServer("Daily") end end)

local function connectFolder(name)
    task.spawn(function()
        local folder = player:WaitForChild(name)
        folder.ChildAdded:Connect(refresh)
        folder.ChildRemoved:Connect(refresh)
        for _, child in folder:GetChildren() do
            if child:IsA("ValueBase") then child:GetPropertyChangedSignal("Value"):Connect(refresh) end
        end
        folder.ChildAdded:Connect(function(child)
            if child:IsA("ValueBase") then child:GetPropertyChangedSignal("Value"):Connect(refresh) end
        end)
        refresh()
    end)
end
connectFolder("QuestProgress")
connectFolder("ClaimedQuests")
connectFolder("PetIndex")
connectFolder("Achievements")
for _, attr in ipairs({"DailyStreak","DailyReady","AchievementCount","CompletedQuests"}) do player:GetAttributeChangedSignal(attr):Connect(refresh) end

feedbackRemote.OnClientEvent:Connect(function(success, title, message)
    toast.BackgroundColor3 = success and Color3.fromRGB(61,170,99) or Color3.fromRGB(211,70,70)
    toast.Text = tostring(title).."\n"..tostring(message or "")
    toast.Visible = true
    toast.TextTransparency = 0
    toast.BackgroundTransparency = 0
    task.delay(1.55,function()
        if not toast.Parent then return end
        local tween = TweenService:Create(toast,TweenInfo.new(.22),{TextTransparency=1,BackgroundTransparency=1})
        tween:Play(); tween.Completed:Wait(); toast.Visible=false
    end)
    refresh()
end)

refresh()
