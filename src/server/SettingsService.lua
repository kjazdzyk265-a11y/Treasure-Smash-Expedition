local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SettingsService = {}
local updateRemote = Remotes.GetOrCreate("UpdateSetting")
local feedbackRemote = Remotes.GetOrCreate("SettingsFeedback")
local lastUpdate: {[Player]: number} = {}

local DEFAULTS = {
    PetVisuals = true,
    EventUI = true,
    OnboardingTips = true,
    LowVFX = false,
}

function SettingsService.LoadPlayer(player: Player, loaded: any)
    local folder = Instance.new("Folder")
    folder.Name = "Settings"
    folder.Parent = player
    loaded = type(loaded) == "table" and loaded or {}
    for name, default in pairs(DEFAULTS) do
        local value = Instance.new("BoolValue")
        value.Name = name
        value.Value = typeof(loaded[name]) == "boolean" and loaded[name] or default
        value.Parent = folder
        player:SetAttribute("Setting_" .. name, value.Value)
        value:GetPropertyChangedSignal("Value"):Connect(function()
            player:SetAttribute("Setting_" .. name, value.Value)
        end)
    end
end

local function update(player: Player, name: any, enabled: any)
    if typeof(name) ~= "string" or typeof(enabled) ~= "boolean" or DEFAULTS[name] == nil then return end
    local now = os.clock()
    if now - (lastUpdate[player] or 0) < 0.08 then return end
    lastUpdate[player] = now
    local folder = player:FindFirstChild("Settings")
    local value = folder and folder:FindFirstChild(name)
    if not value or not value:IsA("BoolValue") then return end
    value.Value = enabled
    feedbackRemote:FireClient(player, name, enabled)
end

function SettingsService.Start()
    updateRemote.OnServerEvent:Connect(update)
    Players.PlayerRemoving:Connect(function(player) lastUpdate[player] = nil end)
end

return SettingsService
