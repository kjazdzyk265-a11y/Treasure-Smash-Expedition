local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local store = DataStoreService:GetDataStore(GameConfig.DataStoreName)

local DataService = {}
local saving: {[Player]: boolean} = {}

local function key(player: Player): string
    return "player_" .. player.UserId
end

local function sanitizeUpgrades(raw: any)
    local result = {}
    raw = type(raw) == "table" and raw or {}
    for name, cfg in pairs(Upgrades) do
        if type(cfg) == "table" and cfg.MaxLevel then
            result[name] = math.clamp(math.floor(tonumber(raw[name]) or 0), 0, cfg.MaxLevel)
        end
    end
    return result
end

function DataService.Load(player: Player)
    local data
    local ok, err = pcall(function()
        data = store:GetAsync(key(player))
    end)
    if not ok then warn("[DataService] load failed", player.UserId, err) end
    data = type(data) == "table" and data or {}
    return {
        Coins = math.max(0, math.floor(tonumber(data.Coins) or GameConfig.StarterCoins)),
        Power = math.max(1, math.floor(tonumber(data.Power) or 1)),
        ToolIndex = math.max(1, math.floor(tonumber(data.ToolIndex) or 1)),
        Upgrades = sanitizeUpgrades(data.Upgrades),
    }
end

function DataService.Save(player: Player)
    if saving[player] then return end
    local stats = player:FindFirstChild("leaderstats")
    local coins = stats and stats:FindFirstChild("Coins")
    local power = stats and stats:FindFirstChild("Power")
    if not coins or not power then return end

    local upgradesPayload = {}
    local folder = player:FindFirstChild("Upgrades")
    if folder then
        for _, child in folder:GetChildren() do
            if child:IsA("IntValue") then
                upgradesPayload[child.Name] = child.Value
            end
        end
    end

    saving[player] = true
    local payload = {
        Coins = coins.Value,
        Power = power.Value,
        ToolIndex = player:GetAttribute("ToolIndex") or 1,
        Upgrades = upgradesPayload,
        UpdatedAt = os.time(),
    }
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
