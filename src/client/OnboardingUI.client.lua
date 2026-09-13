local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local smashFeedback = remotes:WaitForChild("SmashFeedback")

local gui = Instance.new("ScreenGui")
gui.Name = "OnboardingUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Size = UDim2.fromOffset(480, 108)
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.new(0.5, 0, 1, -150)
card.BackgroundColor3 = Color3.fromRGB(38, 45, 68)
card.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,18); corner.Parent = card
local stroke = Instance.new("UIStroke"); stroke.Thickness = 5; stroke.Color = Color3.new(); stroke.Parent = card

local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.fromOffset(72, 72)
arrow.Position = UDim2.fromOffset(10, 18)
arrow.BackgroundTransparency = 1
arrow.Text = "➜"
arrow.TextColor3 = Color3.fromRGB(255, 224, 68)
arrow.TextStrokeTransparency = 0
arrow.TextScaled = true
arrow.Font = Enum.Font.GothamBlack
arrow.Parent = card

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -98, 0, 42)
title.Position = UDim2.fromOffset(88, 10)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 224, 68)
title.TextStrokeTransparency = 0
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack
title.Parent = card

local body = Instance.new("TextLabel")
body.Size = UDim2.new(1, -98, 0, 48)
body.Position = UDim2.fromOffset(88, 52)
body.BackgroundTransparency = 1
body.TextColor3 = Color3.new(1,1,1)
body.TextStrokeTransparency = 0
body.TextScaled = true
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.Font = Enum.Font.GothamBold
body.Parent = card

local steps = {
    {"FIRST SMASH", "Click/tap a nearby object to smash it."},
    {"GET STRONGER", "Fill your backpack, SELL it, then buy any upgrade."},
    {"NEW HAMMER", "Save Coins and buy the Stone Mallet in SHOP."},
    {"FIRST PET", "Open the Green Egg and hatch your first pet."},
    {"RARE TREASURE", "Find and break a Golden, Crystal, Void or Secret object."},
    {"ZONE 2", "Beat the zone boss / unlock Construction City."},
}

local stage = 1
local sawSmash = false
local sawRare = false

local function anyUpgrade()
    local folder = player:FindFirstChild("Upgrades")
    if not folder then return false end
    for _, value in folder:GetChildren() do
        if value:IsA("IntValue") and value.Value > 0 then return true end
    end
    return false
end

local function petCount()
    local folder = player:FindFirstChild("Pets")
    return folder and #folder:GetChildren() or 0
end

local function computeStage()
    if (player:GetAttribute("HighestZone") or 1) >= 2 then return 7 end
    if not sawSmash then return 1 end
    if not anyUpgrade() and (player:GetAttribute("ToolIndex") or 1) < 2 then return 2 end
    if (player:GetAttribute("ToolIndex") or 1) < 2 then return 3 end
    if petCount() < 1 then return 4 end
    if not sawRare then return 5 end
    return 6
end

local function refresh()
    local nextStage = computeStage()
    if nextStage ~= stage then
        stage = nextStage
        card.Size = UDim2.fromOffset(430, 94)
        TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(480,108)}):Play()
    end
    if stage > #steps then
        title.Text = "EXPEDITION READY!"
        body.Text = "Onboarding complete — keep exploring, upgrading and rebirthing."
        arrow.Text = "✓"
        task.delay(3, function() if card.Parent then card.Visible = false end end)
        return
    end
    title.Text = steps[stage][1]
    body.Text = steps[stage][2]
    arrow.Text = stage == 4 and "↓" or (stage == 6 and "→" or "➜")
end

smashFeedback.OnClientEvent:Connect(function(_, _, _, _, _, variant)
    sawSmash = true
    if variant and variant ~= "Normal" then sawRare = true end
    refresh()
end)

local function bindUpgrades()
    task.spawn(function()
        local folder = player:WaitForChild("Upgrades")
        for _, value in folder:GetChildren() do
            if value:IsA("IntValue") then value:GetPropertyChangedSignal("Value"):Connect(refresh) end
        end
        folder.ChildAdded:Connect(function(value)
            if value:IsA("IntValue") then value:GetPropertyChangedSignal("Value"):Connect(refresh) end
        end)
        refresh()
    end)
end

local function bindPets()
    task.spawn(function()
        local folder = player:WaitForChild("Pets")
        folder.ChildAdded:Connect(refresh)
        folder.ChildRemoved:Connect(refresh)
        refresh()
    end)
end

bindUpgrades()
bindPets()
player:GetAttributeChangedSignal("ToolIndex"):Connect(refresh)
player:GetAttributeChangedSignal("HighestZone"):Connect(refresh)
refresh()
