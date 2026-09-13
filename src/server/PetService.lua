local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pets = require(ReplicatedStorage.Shared.Pets)
local Eggs = require(ReplicatedStorage.Shared.EggConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local PetService = {}
local rng = Random.new()
local lastRequest: {[Player]: number} = {}

local hatchRemote = Remotes.GetOrCreate("HatchPet")
local actionRemote = Remotes.GetOrCreate("PetAction")
local fuseRemote = Remotes.GetOrCreate("FusePets")
local feedbackRemote = Remotes.GetOrCreate("PetFeedback")

local function getCoins(player: Player): IntValue?
    local stats = player:FindFirstChild("leaderstats")
    local coins = stats and stats:FindFirstChild("Coins")
    return coins and coins:IsA("IntValue") and coins or nil
end

local function getPetFolder(player: Player): Folder?
    local folder = player:FindFirstChild("Pets")
    return folder and folder:IsA("Folder") and folder or nil
end

local function getEquippedFolder(player: Player): Folder?
    local folder = player:FindFirstChild("EquippedPets")
    return folder and folder:IsA("Folder") and folder or nil
end

local function getIndexFolder(player: Player): Folder?
    local folder = player:FindFirstChild("PetIndex")
    return folder and folder:IsA("Folder") and folder or nil
end

local function getEquipLimit(player: Player): number
    local upgrades = player:FindFirstChild("Upgrades")
    local petSlots = upgrades and upgrades:FindFirstChild("PetSlots")
    local bonus = petSlots and petSlots:IsA("IntValue") and petSlots.Value or 0
    return math.clamp(3 + bonus, 3, 12)
end

local function markIndex(player: Player, petId: string)
    local folder = getIndexFolder(player)
    if not folder or folder:FindFirstChild(petId) then return end
    local value = Instance.new("BoolValue")
    value.Name = petId
    value.Value = true
    value.Parent = folder
end

local function createPet(player: Player, petId: string, variant: string?, uid: string?): StringValue?
    local cfg = Pets.Get(petId)
    local folder = getPetFolder(player)
    if not cfg or not folder then return nil end

    local value = Instance.new("StringValue")
    value.Name = uid or HttpService:GenerateGUID(false)
    value.Value = petId
    value:SetAttribute("Variant", variant or "Normal")
    value:SetAttribute("Locked", false)
    value:SetAttribute("Rarity", cfg.Rarity)
    value:SetAttribute("Power", Pets.GetEffectivePower(petId, variant or "Normal"))
    value.Parent = folder
    markIndex(player, petId)
    return value
end

local function removeEquippedUid(player: Player, uid: string)
    local equipped = getEquippedFolder(player)
    local slot = equipped and equipped:FindFirstChild(uid)
    if slot then slot:Destroy() end
end

function PetService.RefreshPower(player: Player)
    local pets = getPetFolder(player)
    local equipped = getEquippedFolder(player)
    if not pets or not equipped then return end

    local total = 0
    for _, slot in equipped:GetChildren() do
        local pet = pets:FindFirstChild(slot.Name)
        if pet and pet:IsA("StringValue") then
            total += Pets.GetEffectivePower(pet.Value, pet:GetAttribute("Variant"))
        else
            slot:Destroy()
        end
    end
    player:SetAttribute("EquippedPetCount", #equipped:GetChildren())
    player:SetAttribute("PetEquipLimit", getEquipLimit(player))
    player:SetAttribute("PetPower", total)
    player:SetAttribute("PetDamageMultiplier", 1 + total * 0.30)
end

local function equip(player: Player, uid: string)
    local pets = getPetFolder(player)
    local equipped = getEquippedFolder(player)
    if not pets or not equipped then return end
    local pet = pets:FindFirstChild(uid)
    if not pet or not pet:IsA("StringValue") then return end

    local existing = equipped:FindFirstChild(uid)
    if existing then
        existing:Destroy()
        PetService.RefreshPower(player)
        return
    end
    if #equipped:GetChildren() >= getEquipLimit(player) then
        feedbackRemote:FireClient(player, false, "PET SLOTS FULL")
        return
    end
    local slot = Instance.new("StringValue")
    slot.Name = uid
    slot.Value = pet.Value
    slot.Parent = equipped
    PetService.RefreshPower(player)
end

local function equipBest(player: Player)
    local pets = getPetFolder(player)
    local equipped = getEquippedFolder(player)
    if not pets or not equipped then return end
    equipped:ClearAllChildren()

    local candidates = {}
    for _, pet in pets:GetChildren() do
        if pet:IsA("StringValue") then
            table.insert(candidates, pet)
        end
    end
    table.sort(candidates, function(a, b)
        return Pets.GetEffectivePower(a.Value, a:GetAttribute("Variant")) > Pets.GetEffectivePower(b.Value, b:GetAttribute("Variant"))
    end)

    for index = 1, math.min(getEquipLimit(player), #candidates) do
        local pet = candidates[index]
        local slot = Instance.new("StringValue")
        slot.Name = pet.Name
        slot.Value = pet.Value
        slot.Parent = equipped
    end
    PetService.RefreshPower(player)
end

local function hatch(player: Player, eggId: any)
    if typeof(eggId) ~= "string" then return end
    local egg = Eggs[eggId]
    if type(egg) ~= "table" or not egg.Pets then return end
    local highestZone = math.clamp(tonumber(player:GetAttribute("HighestZone")) or 1, 1, 6)
    if egg.Zone > highestZone then
        feedbackRemote:FireClient(player, false, "ZONE LOCKED")
        return
    end
    local coins = getCoins(player)
    if not coins or coins.Value < egg.Price then
        feedbackRemote:FireClient(player, false, "NEED " .. tostring(egg.Price) .. " COINS")
        return
    end

    coins.Value -= egg.Price
    local petId = Eggs.Roll(eggId, rng)
    local value = petId and createPet(player, petId, "Normal") or nil
    if not value or not petId then return end
    local cfg = Pets.Get(petId)
    feedbackRemote:FireClient(player, true, "HATCH", value.Name, petId, cfg.Name, cfg.Rarity, cfg.Power)
end

local function fuse(player: Player, petId: any, variant: any)
    if typeof(petId) ~= "string" or typeof(variant) ~= "string" then return end
    local nextVariant = Pets.VariantNext[variant]
    if not nextVariant or not Pets.Get(petId) then return end
    local pets = getPetFolder(player)
    if not pets then return end

    local matches = {}
    for _, pet in pets:GetChildren() do
        if pet:IsA("StringValue") and pet.Value == petId and pet:GetAttribute("Variant") == variant and pet:GetAttribute("Locked") ~= true then
            table.insert(matches, pet)
            if #matches >= 5 then break end
        end
    end
    if #matches < 5 then
        feedbackRemote:FireClient(player, false, "NEED 5 MATCHING PETS")
        return
    end

    for _, pet in matches do
        removeEquippedUid(player, pet.Name)
        pet:Destroy()
    end
    local result = createPet(player, petId, nextVariant)
    PetService.RefreshPower(player)
    feedbackRemote:FireClient(player, true, "FUSED", result and result.Name or "", petId, Pets.Get(petId).Name, nextVariant, Pets.GetEffectivePower(petId, nextVariant))
end

local function petAction(player: Player, action: any, uid: any)
    if typeof(action) ~= "string" then return end
    if action == "EquipBest" then
        equipBest(player)
        feedbackRemote:FireClient(player, true, "EQUIPPED BEST")
        return
    end
    if typeof(uid) ~= "string" then return end
    local pets = getPetFolder(player)
    local pet = pets and pets:FindFirstChild(uid)
    if not pet or not pet:IsA("StringValue") then return end

    if action == "Equip" then
        equip(player, uid)
    elseif action == "Lock" then
        pet:SetAttribute("Locked", pet:GetAttribute("Locked") ~= true)
    elseif action == "Delete" and pet:GetAttribute("Locked") ~= true then
        removeEquippedUid(player, uid)
        pet:Destroy()
        PetService.RefreshPower(player)
    end
end

function PetService.LoadPlayer(player: Player, loadedPets: any, loadedEquipped: any, loadedIndex: any)
    local petsFolder = Instance.new("Folder")
    petsFolder.Name = "Pets"
    petsFolder.Parent = player
    local equippedFolder = Instance.new("Folder")
    equippedFolder.Name = "EquippedPets"
    equippedFolder.Parent = player
    local indexFolder = Instance.new("Folder")
    indexFolder.Name = "PetIndex"
    indexFolder.Parent = player

    if type(loadedIndex) == "table" then
        for petId, discovered in pairs(loadedIndex) do
            if discovered and Pets.Get(petId) then markIndex(player, petId) end
        end
    end
    if type(loadedPets) == "table" then
        for _, data in ipairs(loadedPets) do
            if type(data) == "table" and Pets.Get(data.Id) then
                local variant = Pets.VariantMultiplier[data.Variant] and data.Variant or "Normal"
                local pet = createPet(player, data.Id, variant, typeof(data.Uid) == "string" and data.Uid or nil)
                if pet then pet:SetAttribute("Locked", data.Locked == true) end
            end
        end
    end
    if type(loadedEquipped) == "table" then
        for _, uid in ipairs(loadedEquipped) do
            if typeof(uid) == "string" and petsFolder:FindFirstChild(uid) and #equippedFolder:GetChildren() < getEquipLimit(player) then
                local pet = petsFolder:FindFirstChild(uid) :: StringValue
                local slot = Instance.new("StringValue")
                slot.Name = uid
                slot.Value = pet.Value
                slot.Parent = equippedFolder
            end
        end
    end
    PetService.RefreshPower(player)
end

function PetService.Start()
    hatchRemote.OnServerEvent:Connect(function(player, eggId)
        local now = os.clock()
        if now - (lastRequest[player] or 0) < 0.25 then return end
        lastRequest[player] = now
        hatch(player, eggId)
    end)
    actionRemote.OnServerEvent:Connect(petAction)
    fuseRemote.OnServerEvent:Connect(fuse)
end

return PetService
