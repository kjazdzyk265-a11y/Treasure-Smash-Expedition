local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Pets = require(ReplicatedStorage.Shared.Pets)

local DataService = {}
local saving: {[Player]: boolean} = {}
local store = nil
local dataStoreAvailable = false

local storeOk, storeOrError = pcall(function()
    return DataStoreService:GetDataStore(GameConfig.DataStoreName)
end)
if storeOk then
    store = storeOrError
    dataStoreAvailable = true
else
    warn("[DataService] DataStore unavailable; running with temporary session data:", storeOrError)
end

local function key(player: Player): string
    return "player_" .. player.UserId
end

local function sanitizeUpgrades(raw: any)
    local result = {}
    raw = type(raw) == "table" and raw or {}
    for name, cfg in pairs(Upgrades) do
        if type(cfg) == "table" and cfg.MaxLevel then result[name] = math.clamp(math.floor(tonumber(raw[name]) or 0), 0, cfg.MaxLevel) end
    end
    return result
end

local function sanitizePets(raw: any)
    local result = {}
    if type(raw) ~= "table" then return result end
    for _, data in ipairs(raw) do
        if type(data) == "table" and typeof(data.Id) == "string" and Pets.Get(data.Id) then
            local variant = Pets.VariantMultiplier[data.Variant] and data.Variant or "Normal"
            table.insert(result, {Uid = typeof(data.Uid) == "string" and data.Uid or nil, Id = data.Id, Variant = variant, Locked = data.Locked == true})
        end
    end
    return result
end

local function safeTable(raw)
    return type(raw) == "table" and raw or {}
end

function DataService.Load(player: Player)
    local data
    if dataStoreAvailable and store then
        local ok, err = pcall(function() data = store:GetAsync(key(player)) end)
        if not ok then warn("[DataService] load failed", player.UserId, err) end
    end
    data = type(data) == "table" and data or {}
    return {
        Coins = math.max(0, math.floor(tonumber(data.Coins) or GameConfig.StarterCoins)),
        Power = math.max(1, math.floor(tonumber(data.Power) or 1)),
        Gems = math.max(0, math.floor(tonumber(data.Gems) or 0)),
        EventTokens = math.max(0, math.floor(tonumber(data.EventTokens) or 0)),
        Rebirths = math.max(0, math.floor(tonumber(data.Rebirths) or 0)),
        ToolIndex = math.max(1, math.floor(tonumber(data.ToolIndex) or 1)),
        HighestZone = math.clamp(math.floor(tonumber(data.HighestZone) or 1), 1, 6),
        BackpackLoot = math.max(0, math.floor(tonumber(data.BackpackLoot) or 0)),
        Upgrades = sanitizeUpgrades(data.Upgrades),
        Pets = sanitizePets(data.Pets),
        Equipped = safeTable(data.Equipped),
        PetIndex = safeTable(data.PetIndex),
        Settings = safeTable(data.Settings),
        Retention = {
            Quests = safeTable(data.QuestProgress),
            ClaimedQuests = safeTable(data.ClaimedQuests),
            AchievementProgress = safeTable(data.AchievementProgress),
            Achievements = safeTable(data.Achievements),
            DailyLastDay = math.floor(tonumber(data.DailyLastDay) or -1),
            DailyStreak = math.clamp(math.floor(tonumber(data.DailyStreak) or 0), 0, 7),
        },
    }
end

local function folderValues(player, folderName)
    local payload = {}
    local folder = player:FindFirstChild(folderName)
    if not folder then return payload end
    for _, child in folder:GetChildren() do
        if child:IsA("IntValue") or child:IsA("BoolValue") or child:IsA("StringValue") then payload[child.Name] = child.Value end
    end
    return payload
end

function DataService.Save(player: Player)
    if not dataStoreAvailable or not store then return end
    if saving[player] then return end
    local stats = player:FindFirstChild("leaderstats")
    local coins = stats and stats:FindFirstChild("Coins")
    local power = stats and stats:FindFirstChild("Power")
    local gems = stats and stats:FindFirstChild("Gems")
    local eventTokens = stats and stats:FindFirstChild("EventTokens")
    local rebirths = stats and stats:FindFirstChild("Rebirths")
    if not coins or not power or not gems or not eventTokens or not rebirths then return end

    local petsPayload = {}
    local petsFolder = player:FindFirstChild("Pets")
    if petsFolder then
        for _, pet in petsFolder:GetChildren() do
            if pet:IsA("StringValue") and Pets.Get(pet.Value) then
                table.insert(petsPayload, {Uid=pet.Name, Id=pet.Value, Variant=pet:GetAttribute("Variant") or "Normal", Locked=pet:GetAttribute("Locked")==true})
            end
        end
    end

    local equippedPayload = {}
    local equippedFolder = player:FindFirstChild("EquippedPets")
    if equippedFolder then for _, slot in equippedFolder:GetChildren() do table.insert(equippedPayload, slot.Name) end end
    local indexPayload = {}
    local indexFolder = player:FindFirstChild("PetIndex")
    if indexFolder then for _, item in indexFolder:GetChildren() do indexPayload[item.Name] = true end end

    saving[player] = true
    local payload = {
        Coins = coins.Value,
        Power = power.Value,
        Gems = gems.Value,
        EventTokens = eventTokens.Value,
        Rebirths = rebirths.Value,
        ToolIndex = player:GetAttribute("ToolIndex") or 1,
        HighestZone = player:GetAttribute("HighestZone") or 1,
        BackpackLoot = player:GetAttribute("BackpackLoot") or 0,
        Upgrades = folderValues(player, "Upgrades"),
        Pets = petsPayload,
        Equipped = equippedPayload,
        PetIndex = indexPayload,
        Settings = folderValues(player, "Settings"),
        QuestProgress = folderValues(player, "QuestProgress"),
        ClaimedQuests = folderValues(player, "ClaimedQuests"),
        AchievementProgress = folderValues(player, "AchievementProgress"),
        Achievements = folderValues(player, "Achievements"),
        DailyLastDay = player:GetAttribute("DailyLastDay") or -1,
        DailyStreak = player:GetAttribute("DailyStreak") or 0,
        UpdatedAt = os.time(),
    }
    local ok, err = pcall(function() store:UpdateAsync(key(player), function() return payload end) end)
    saving[player] = nil
    if not ok then warn("[DataService] save failed", player.UserId, err) end
end

function DataService.StartAutosave()
    task.spawn(function()
        while true do
            task.wait(GameConfig.AutosaveSeconds)
            if dataStoreAvailable then
                for _, player in Players:GetPlayers() do task.spawn(DataService.Save, player) end
            end
        end
    end)
end

return DataService
