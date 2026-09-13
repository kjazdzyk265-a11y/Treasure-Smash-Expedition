local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Pets = require(ReplicatedStorage.Shared.Pets)
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

local function sanitizePets(raw: any)
    local result = {}
    if type(raw) ~= "table" then return result end
    for _, data in ipairs(raw) do
        if type(data) == "table" and typeof(data.Id) == "string" and Pets.Get(data.Id) then
            local variant = Pets.VariantMultiplier[data.Variant] and data.Variant or "Normal"
            table.insert(result, {
                Uid = typeof(data.Uid) == "string" and data.Uid or nil,
                Id = data.Id,
                Variant = variant,
                Locked = data.Locked == true,
            })
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
        HighestZone = math.clamp(math.floor(tonumber(data.HighestZone) or 1), 1, 6),
        Upgrades = sanitizeUpgrades(data.Upgrades),
        Pets = sanitizePets(data.Pets),
        Equipped = type(data.Equipped) == "table" and data.Equipped or {},
        PetIndex = type(data.PetIndex) == "table" and data.PetIndex or {},
    }
end

function DataService.Save(player: Player)
    if saving[player] then return end
    local stats = player:FindFirstChild("leaderstats")
    local coins = stats and stats:FindFirstChild("Coins")
    local power = stats and stats:FindFirstChild("Power")
    if not coins or not power then return end

    local upgradesPayload = {}
    local upgrades = player:FindFirstChild("Upgrades")
    if upgrades then
        for _, child in upgrades:GetChildren() do
            if child:IsA("IntValue") then upgradesPayload[child.Name] = child.Value end
        end
    end

    local petsPayload = {}
    local petsFolder = player:FindFirstChild("Pets")
    if petsFolder then
        for _, pet in petsFolder:GetChildren() do
            if pet:IsA("StringValue") and Pets.Get(pet.Value) then
                table.insert(petsPayload, {
                    Uid = pet.Name,
                    Id = pet.Value,
                    Variant = pet:GetAttribute("Variant") or "Normal",
                    Locked = pet:GetAttribute("Locked") == true,
                })
            end
        end
    end

    local equippedPayload = {}
    local equippedFolder = player:FindFirstChild("EquippedPets")
    if equippedFolder then
        for _, slot in equippedFolder:GetChildren() do
            table.insert(equippedPayload, slot.Name)
        end
    end

    local indexPayload = {}
    local indexFolder = player:FindFirstChild("PetIndex")
    if indexFolder then
        for _, item in indexFolder:GetChildren() do
            indexPayload[item.Name] = true
        end
    end

    saving[player] = true
    local payload = {
        Coins = coins.Value,
        Power = power.Value,
        ToolIndex = player:GetAttribute("ToolIndex") or 1,
        HighestZone = player:GetAttribute("HighestZone") or 1,
        Upgrades = upgradesPayload,
        Pets = petsPayload,
        Equipped = equippedPayload,
        PetIndex = indexPayload,
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
