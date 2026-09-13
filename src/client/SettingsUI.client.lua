local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateRemote = remotes:WaitForChild("UpdateSetting")
local feedbackRemote = remotes:WaitForChild("SettingsFeedback")

local gui = Instance.new("ScreenGui")
gui.Name = "SettingsUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function style(object, radius)
    object.BorderSizePixel = 0
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius or 14); corner.Parent = object
    local stroke = Instance.new("UIStroke"); stroke.Thickness = 4; stroke.Color = Color3.new(0,0,0); stroke.Parent = object
end

local tokenLabel = Instance.new("TextLabel")
tokenLabel.Size = UDim2.fromOffset(190,46); tokenLabel.AnchorPoint = Vector2.new(1,0); tokenLabel.Position = UDim2.new(1,-18,0,18); tokenLabel.BackgroundColor3 = Color3.fromRGB(255,126,49); tokenLabel.TextColor3 = Color3.new(1,1,1); tokenLabel.TextStrokeTransparency = 0; tokenLabel.TextScaled = true; tokenLabel.Font = Enum.Font.GothamBlack; tokenLabel.Parent = gui; style(tokenLabel,12)

local open = Instance.new("TextButton")
open.Size = UDim2.fromOffset(150,54); open.AnchorPoint = Vector2.new(1,0); open.Position = UDim2.new(1,-18,0,72); open.BackgroundColor3 = Color3.fromRGB(73,84,116); open.Text = "SETTINGS"; open.TextColor3 = Color3.new(1,1,1); open.TextStrokeTransparency = 0; open.TextScaled = true; open.Font = Enum.Font.GothamBlack; open.Parent = gui; style(open,12)

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(360,360); panel.AnchorPoint = Vector2.new(1,0); panel.Position = UDim2.new(1,-18,0,136); panel.BackgroundColor3 = Color3.fromRGB(35,41,62); panel.Visible = false; panel.Parent = gui; style(panel,18)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-24,0,52); title.Position = UDim2.fromOffset(12,8); title.BackgroundTransparency = 1; title.Text = "SETTINGS"; title.TextColor3 = Color3.new(1,1,1); title.TextStrokeTransparency = 0; title.TextScaled = true; title.Font = Enum.Font.GothamBlack; title.Parent = panel

local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0,10); list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.VerticalAlignment = Enum.VerticalAlignment.Center; list.Parent = panel
local settings = {"PetVisuals","EventUI","OnboardingTips","LowVFX"}
local prettyNames = {PetVisuals="PET VISUALS", EventUI="EVENT UI", OnboardingTips="ONBOARDING TIPS", LowVFX="LOW VFX MODE"}
local buttons = {}

for _, name in ipairs(settings) do
    local b = Instance.new("TextButton")
    b.Name = name; b.Size = UDim2.new(1,-34,0,58); b.TextColor3 = Color3.new(1,1,1); b.TextStrokeTransparency = 0; b.TextScaled = true; b.Font = Enum.Font.GothamBlack; b.Parent = panel; style(b,12)
    buttons[name] = b
    b.Activated:Connect(function()
        local current = player:GetAttribute("Setting_" .. name)
        updateRemote:FireServer(name, current ~= true)
    end)
end

local function refresh()
    local stats = player:FindFirstChild("leaderstats")
    local tokens = stats and stats:FindFirstChild("EventTokens")
    tokenLabel.Text = "TOKENS  " .. tostring(tokens and tokens.Value or 0)
    for name, b in pairs(buttons) do
        local enabled = player:GetAttribute("Setting_" .. name)
        if enabled == nil then enabled = name ~= "LowVFX" end
        b.Text = prettyNames[name] .. "  " .. (enabled and "ON" or "OFF")
        b.BackgroundColor3 = enabled and Color3.fromRGB(65,171,97) or Color3.fromRGB(95,99,116)
    end
end

open.Activated:Connect(function()
    panel.Visible = not panel.Visible
    if panel.Visible then panel.Size = UDim2.fromOffset(330,330); TweenService:Create(panel,TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(360,360)}):Play() end
    refresh()
end)
feedbackRemote.OnClientEvent:Connect(refresh)
for _, name in ipairs(settings) do player:GetAttributeChangedSignal("Setting_" .. name):Connect(refresh) end

task.spawn(function()
    local stats = player:WaitForChild("leaderstats")
    stats:WaitForChild("EventTokens"):GetPropertyChangedSignal("Value"):Connect(refresh)
    refresh()
end)
