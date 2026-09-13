local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldService = require(script.Parent.WorldService)
local SmashService = require(script.Parent.SmashService)
local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local PetService = require(script.Parent.PetService)
local ZoneService = require(script.Parent.ZoneService)
local BackpackService = require(script.Parent.BackpackService)
local RebirthService = require(script.Parent.RebirthService)
local RetentionService = require(script.Parent.RetentionService)
local MeteorService = require(script.Parent.MeteorService)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)

WorldService.Build()
SmashService.Start()
ProgressionService.Start()
PetService.Start()
ZoneService.Start()
BackpackService.Start()
RebirthService.Start()
RetentionService.Start()
MeteorService.Start()
DataService.StartAutosave()

local function setupPlayer(player: Player)
    local loaded = DataService.Load(player)
    local stats = Instance.new("Folder"); stats.Name = "leaderstats"; stats.Parent = player
    local coins = Instance.new("IntValue"); coins.Name = "Coins"; coins.Value = loaded.Coins; coins.Parent = stats
    local power = Instance.new("IntValue"); power.Name = "Power"; power.Value = loaded.Power; power.Parent = stats
    local gems = Instance.new("IntValue"); gems.Name = "Gems"; gems.Value = loaded.Gems; gems.Parent = stats
    local rebirths = Instance.new("IntValue"); rebirths.Name = "Rebirths"; rebirths.Value = loaded.Rebirths; rebirths.Parent = stats

    local upgradesFolder = Instance.new("Folder"); upgradesFolder.Name = "Upgrades"; upgradesFolder.Parent = player
    for name,cfg in pairs(Upgrades) do
        if type(cfg)=="table" and cfg.MaxLevel then
            local value=Instance.new("IntValue"); value.Name=name; value.Value=loaded.Upgrades[name] or 0; value.Parent=upgradesFolder
        end
    end

    player:SetAttribute("ToolIndex",loaded.ToolIndex)
    player:SetAttribute("HighestZone",loaded.HighestZone)
    player:SetAttribute("CurrentZone",1)
    player:SetAttribute("BackpackLoot",loaded.BackpackLoot or 0)
    player:SetAttribute("Rebirths", loaded.Rebirths)
    player:SetAttribute("ComboCount", 0)
    player:SetAttribute("ComboMultiplier", 1)
    ProgressionService.ApplyDerivedStats(player)
    BackpackService.Refresh(player)
    PetService.LoadPlayer(player,loaded.Pets,loaded.Equipped,loaded.PetIndex)
    RetentionService.LoadPlayer(player, loaded.Retention)

    player.CharacterAdded:Connect(function()
        task.wait()
        ProgressionService.ApplyDerivedStats(player)
    end)
end

for _,player in Players:GetPlayers() do task.spawn(setupPlayer,player) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(DataService.Save)

game:BindToClose(function()
    for _,player in Players:GetPlayers() do task.spawn(DataService.Save,player) end
    task.wait(2)
end)

print("[TreasureSmash] Core progression, meteor event, onboarding, retention, rebirth, backpack, pets and six-zone world started")
