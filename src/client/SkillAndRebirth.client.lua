local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local perfectCue = remotes:WaitForChild("PerfectCue")
local smashFeedback = remotes:WaitForChild("SmashFeedback")
local requestRebirth = remotes:WaitForChild("RequestRebirth")
local rebirthFeedback = remotes:WaitForChild("RebirthFeedback")

local gui = Instance.new("ScreenGui")
gui.Name = "SkillAndRebirthUI"
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

local perfectLabel = Instance.new("TextLabel")
perfectLabel.Size = UDim2.fromOffset(310, 76)
perfectLabel.AnchorPoint = Vector2.new(0.5, 0.5)
perfectLabel.Position = UDim2.new(0.5, 0, 0.56, 0)
perfectLabel.BackgroundColor3 = Color3.fromRGB(255, 214, 58)
perfectLabel.TextColor3 = Color3.new(1,1,1)
perfectLabel.TextStrokeTransparency = 0
perfectLabel.TextScaled = true
perfectLabel.Font = Enum.Font.GothamBlack
perfectLabel.Text = "PERFECT NOW!"
perfectLabel.Visible = false
perfectLabel.ZIndex = 50
perfectLabel.Parent = gui
style(perfectLabel, 18)

local comboLabel = Instance.new("TextLabel")
comboLabel.Size = UDim2.fromOffset(250, 54)
comboLabel.AnchorPoint = Vector2.new(0.5, 0)
comboLabel.Position = UDim2.new(0.5, 0, 0, 158)
comboLabel.BackgroundTransparency = 1
comboLabel.TextColor3 = Color3.fromRGB(255, 230, 70)
comboLabel.TextStrokeTransparency = 0
comboLabel.TextScaled = true
comboLabel.Font = Enum.Font.GothamBlack
comboLabel.Text = ""
comboLabel.Parent = gui

local rebirthButton = Instance.new("TextButton")
rebirthButton.Size = UDim2.fromOffset(190, 78)
rebirthButton.AnchorPoint = Vector2.new(1, 0)
rebirthButton.Position = UDim2.new(1, -18, 0, 92)
rebirthButton.BackgroundColor3 = Color3.fromRGB(176, 79, 255)
rebirthButton.TextColor3 = Color3.new(1,1,1)
rebirthButton.TextStrokeTransparency = 0
rebirthButton.TextScaled = true
rebirthButton.TextWrapped = true
rebirthButton.Font = Enum.Font.GothamBlack
rebirthButton.Text = "REBIRTH"
rebirthButton.Parent = gui
style(rebirthButton, 16)

local info = Instance.new("TextLabel")
info.Size = UDim2.fromOffset(260, 52)
info.AnchorPoint = Vector2.new(1, 0)
info.Position = UDim2.new(1, -18, 0, 174)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.new(1,1,1)
info.TextStrokeTransparency = 0
info.TextScaled = true
info.Font = Enum.Font.GothamBold
info.Text = ""
info.Parent = gui

local toast = Instance.new("TextLabel")
toast.Size = UDim2.fromOffset(420, 70)
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.new(0.5, 0, 0.3, 0)
toast.BackgroundColor3 = Color3.fromRGB(84, 55, 133)
toast.TextColor3 = Color3.new(1,1,1)
toast.TextStrokeTransparency = 0
toast.TextScaled = true
toast.TextWrapped = true
toast.Font = Enum.Font.GothamBlack
toast.Visible = false
toast.ZIndex = 60
toast.Parent = gui
style(toast, 16)

local function requirementFor(rebirths)
    return math.floor(750 * (1.85 ^ math.max(0, rebirths)) + 0.5)
end

local function refreshRebirth()
    local stats = player:FindFirstChild("leaderstats")
    if not stats then return end
    local gems = stats:FindFirstChild("Gems")
    local rebirths = stats:FindFirstChild("Rebirths")
    local count = rebirths and rebirths.Value or 0
    rebirthButton.Text = "REBIRTH\n" .. requirementFor(count) .. " POWER"
    info.Text = "GEMS " .. tostring(gems and gems.Value or 0) .. "  •  x" .. string.format("%.2f", 1 + count * 0.225)
end

task.spawn(function()
    local stats = player:WaitForChild("leaderstats")
    stats:WaitForChild("Gems"):GetPropertyChangedSignal("Value"):Connect(refreshRebirth)
    stats:WaitForChild("Rebirths"):GetPropertyChangedSignal("Value"):Connect(refreshRebirth)
    refreshRebirth()
end)

rebirthButton.Activated:Connect(function()
    requestRebirth:FireServer()
end)

local cueToken = 0
perfectCue.OnClientEvent:Connect(function(delaySeconds, windowSeconds)
    cueToken += 1
    local token = cueToken
    task.delay(math.max(0, tonumber(delaySeconds) or 0), function()
        if token ~= cueToken then return end
        perfectLabel.Visible = true
        perfectLabel.Size = UDim2.fromOffset(250, 62)
        TweenService:Create(perfectLabel, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(330, 82)}):Play()
        task.delay(math.max(0.1, tonumber(windowSeconds) or 0.17), function()
            if token == cueToken then perfectLabel.Visible = false end
        end)
    end)
end)

smashFeedback.OnClientEvent:Connect(function(_, _, critical, _, _, _, perfect, combo, comboMult)
    combo = tonumber(combo) or 1
    comboMult = tonumber(comboMult) or 1
    if combo >= 2 then
        comboLabel.Text = "COMBO " .. combo .. "  x" .. comboMult
        comboLabel.TextTransparency = 0
        TweenService:Create(comboLabel, TweenInfo.new(0.14), {TextTransparency = 0}):Play()
    else
        comboLabel.Text = ""
    end
    if perfect == true then
        perfectLabel.Text = critical and "PERFECT CRIT!" or "PERFECT SMASH!"
        perfectLabel.Visible = true
        task.delay(0.32, function() perfectLabel.Visible = false; perfectLabel.Text = "PERFECT NOW!" end)
    end
end)

rebirthFeedback.OnClientEvent:Connect(function(success, nextRequirement, message)
    toast.BackgroundColor3 = success and Color3.fromRGB(156, 74, 235) or Color3.fromRGB(211, 70, 70)
    toast.Text = tostring(message) .. "\nNEXT " .. tostring(nextRequirement) .. " POWER"
    toast.Visible = true
    toast.TextTransparency = 0
    task.delay(1.7, function()
        if not toast.Parent then return end
        local tween = TweenService:Create(toast, TweenInfo.new(0.25), {TextTransparency = 1, BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Wait()
        toast.Visible = false
        toast.BackgroundTransparency = 0
    end)
    refreshRebirth()
end)
