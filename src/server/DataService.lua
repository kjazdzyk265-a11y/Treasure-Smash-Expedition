local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local store = DataStoreService:GetDataStore(GameConfig.DataStoreName)

local DataService = {}
local saving: {[Player]: boolean} = {}

local function key(player: Player): string
    return "player_" .. player.UserId
end

function DataService.Load(player: Player)
    local data
    local ok, err = pcall(function()
        data = store:GetAsync(key(player))
    end)
    if not ok then warn("[DataService] load failed", player.UserId, err) end
    data = type(data) == "table" and data or {}
    return {
        Coins = tonumber(data.Coins) or GameConfig.StarterCoins,
        Power = tonumber(data.Power) or 1,
    }
end

function DataService.Save(player: Player)
    if saving[player] then return end
    local stats = player:FindFirstChild("leaderstats")
    local coins = stats and stats:FindFirstChild("Coins")
    local power = stats and stats:FindFirstChild("Power")
    if not coins or not power then return end
    saving[player] = true
    local payload = {Coins = coins.Value, Power = power.Value, UpdatedAt = os.time()}
    local ok, err = pcall(function()
        store:UpdateAsync(key(player), function()
            return payload
        end)
    end)
    saving[player] = nil
    if not ok then warn("[DataService] save failed", player.UserId, err) end
end

function DataService.StartAutosave()
    task.spawn(function()
        while true do
            task.wait(GameConfig.AutosaveSeconds)
            for _, player in Players:GetPlayers() do
                task.spawn(DataService.Save, player)
            end
        end
    end)
end

return DataService
