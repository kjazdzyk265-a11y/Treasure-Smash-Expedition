local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateRemote = remotes:WaitForChild("MeteorState")
local feedbackRemote = remotes:WaitForChild("MeteorFeedback")

local gui = Instance.new("ScreenGui")
gui.Name = "MeteorUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(430, 92); frame.AnchorPoint = Vector2.new(0.5, 0); frame.Position = UDim2.new(0.5, 0, 0, 220); frame.BackgroundColor3 = Color3.fromRGB(51, 34, 31); frame.Visible = false; frame.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 16); corner.Parent = frame
local stroke = Instance.new("UIStroke"); stroke.Thickness = 4; stroke.Color = Color3.new(); stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 38); title.Position = UDim2.fromOffset(12, 6); title.BackgroundTransparency = 1; title.Text = "GIANT METEOR EVENT"; title.TextColor3 = Color3.fromRGB(255, 135, 59); title.TextStrokeTransparency = 0; title.TextScaled = true; title.Font = Enum.Font.GothamBlack; title.Parent = frame

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -28, 0, 24); barBg.Position = UDim2.fromOffset(14, 49); barBg.BackgroundColor3 = Color3.fromRGB(22, 22, 26); barBg.Parent = frame
local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(1,0); bgCorner.Parent = barBg
local fill = Instance.new("Frame"); fill.Size = UDim2.fromScale(1,1); fill.BackgroundColor3 = Color3.fromRGB(255, 95, 36); fill.Parent = barBg
local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(1,0); fillCorner.Parent = fill
local hpText = Instance.new("TextLabel"); hpText.Size = UDim2.fromScale(1,1); hpText.BackgroundTransparency = 1; hpText.TextColor3 = Color3.new(1,1,1); hpText.TextStrokeTransparency = 0; hpText.TextScaled = true; hpText.Font = Enum.Font.GothamBlack; hpText.Parent = barBg

local toast = Instance.new("TextLabel")
toast.Size = UDim2.fromOffset(440, 78); toast.AnchorPoint = Vector2.new(0.5,0.5); toast.Position = UDim2.new(0.5,0,0.28,0); toast.BackgroundColor3 = Color3.fromRGB(74, 46, 36); toast.TextColor3 = Color3.new(1,1,1); toast.TextStrokeTransparency = 0; toast.TextScaled = true; toast.TextWrapped = true; toast.Font = Enum.Font.GothamBlack; toast.Visible = false; toast.ZIndex = 40; toast.Parent = gui
local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,14); tc.Parent = toast
local ts = Instance.new("UIStroke"); ts.Thickness = 4; ts.Color = Color3.new(); ts.Parent = toast

local function showToast(text)
    toast.Text = text; toast.Visible = true; toast.TextTransparency = 0; toast.BackgroundTransparency = 0
    task.delay(1.8, function()
        if not toast.Parent then return end
        local tween = TweenService:Create(toast, TweenInfo.new(0.25), {TextTransparency = 1, BackgroundTransparency = 1})
        tween:Play(); tween.Completed:Wait(); toast.Visible = false
    end)
end

stateRemote.OnClientEvent:Connect(function(state, health, maxHealth)
    if state == "STARTED" then
        frame.Visible = true
        showToast("GLOBAL EVENT!\nSMASH THE GIANT METEOR")
    elseif state == "DEFEATED" then
        hpText.Text = "METEOR DESTROYED!"; fill.Size = UDim2.fromScale(0,1); task.delay(2.5, function() frame.Visible = false end); return
    end
    if frame.Visible and tonumber(maxHealth) and maxHealth > 0 then
        local ratio = math.clamp((tonumber(health) or 0) / maxHealth, 0, 1)
        TweenService:Create(fill, TweenInfo.new(0.12), {Size = UDim2.fromScale(ratio, 1)}):Play()
        hpText.Text = string.format("%d / %d HP", math.floor(tonumber(health) or 0), math.floor(maxHealth))
    end
end)

feedbackRemote.OnClientEvent:Connect(function(kind, gems, share, tokens)
    if kind == "REWARD" then
        showToast(string.format("METEOR REWARD  +%d GEMS  +%d TOKENS\nCONTRIBUTION %.1f%%", tonumber(gems) or 0, tonumber(tokens) or 0, (tonumber(share) or 0) * 100))
    end
end)
