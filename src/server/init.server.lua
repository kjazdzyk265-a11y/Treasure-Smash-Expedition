local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldService = require(script.Parent.WorldService)
local SmashService = require(script.Parent.SmashService)
local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)

WorldService.Build()
SmashService.Start()
ProgressionService.Start()
DataService.StartAutosave()

local function setupPlayer(player: Player)
    local loaded = DataService.Load(player)

    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = loaded.Coins
    coins.Parent = stats

    local power = Instance.new("IntValue")
    power.Name = "Power"
    power.Value = loaded.Power
    power.Parent = stats

    local upgradesFolder = Instance.new("Folder")
    upgradesFolder.Name = "Upgrades"
    upgradesFolder.Parent = player

    for name, cfg in pairs(Upgrades) do
        if type(cfg) == "table" and cfg.MaxLevel then
            local value = Instance.new("IntValue")
            value.Name = name
            value.Value = loaded.Upgrades[name] or 0
            value.Parent = upgradesFolder
        end
    end

    player:SetAttribute("ToolIndex", loaded.ToolIndex)
    ProgressionService.ApplyDerivedStats(player)
end

for _, player in Players:GetPlayers() do
    setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(DataService.Save)

game:BindToClose(function()
    for _, player in Players:GetPlayers() do
        DataService.Save(player)
    end
end)

print("[TreasureSmash] Progression vertical slice started")
