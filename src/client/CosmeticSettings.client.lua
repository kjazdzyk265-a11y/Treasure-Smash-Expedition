local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function applyLowVfx()
    local low = player:GetAttribute("Setting_LowVFX") == true
    for _, obj in workspace:GetDescendants() do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = not low
        elseif obj:IsA("PointLight") and obj.Parent and obj.Parent:IsDescendantOf(workspace) then
            obj.Enabled = not low
        end
    end
end

local function applyPetVisibility()
    local folder = workspace:FindFirstChild("ClientPetVisuals_" .. player.UserId)
    if not folder then return end
    local visible = player:GetAttribute("Setting_PetVisuals") ~= false
    local low = player:GetAttribute("Setting_LowVFX") == true
    for _, obj in folder:GetDescendants() do
        if obj:IsA("BasePart") then obj.LocalTransparencyModifier = visible and 0 or 1 end
        if obj:IsA("Light") then obj.Enabled = visible and not low end
    end
end

local function applyGuiVisibility()
    local meteor = playerGui:FindFirstChild("MeteorUI")
    if meteor and meteor:IsA("ScreenGui") then meteor.Enabled = player:GetAttribute("Setting_EventUI") ~= false end
    local onboarding = playerGui:FindFirstChild("OnboardingUI")
    if onboarding and onboarding:IsA("ScreenGui") then onboarding.Enabled = player:GetAttribute("Setting_OnboardingTips") ~= false end
end

local function applyAll()
    applyLowVfx()
    applyPetVisibility()
    applyGuiVisibility()
end

for _, name in ipairs({"PetVisuals","EventUI","OnboardingTips","LowVFX"}) do
    player:GetAttributeChangedSignal("Setting_" .. name):Connect(applyAll)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "ClientPetVisuals_" .. player.UserId then task.defer(applyPetVisibility) end
end)
workspace.DescendantAdded:Connect(function(obj)
    if player:GetAttribute("Setting_LowVFX") == true and (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("PointLight")) then obj.Enabled = false end
end)
playerGui.ChildAdded:Connect(function(child)
    if child.Name == "MeteorUI" or child.Name == "OnboardingUI" then task.defer(applyGuiVisibility) end
end)

task.defer(applyAll)
