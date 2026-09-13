local Players = game:GetService("Players")

local WorldService = require(script.Parent.WorldService)
local SmashService = require(script.Parent.SmashService)
local DataService = require(script.Parent.DataService)

WorldService.Build()
SmashService.Start()
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

print("[TreasureSmash] Server vertical slice started")
