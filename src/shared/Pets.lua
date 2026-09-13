local Pets = {}

local rarityOrder = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Secret"}
local zones = {
    {"Leaf Pup", "Meadow Bunny", "Farm Chick", "Acorn Fox", "Windmill Owl", "Golden Calf"},
    {"Bolt Dog", "Traffic Cat", "Crane Crow", "Steel Rhino", "Neon Raccoon", "Vault Golem"},
    {"Pebble Bat", "Crystal Mole", "Glow Lizard", "Gem Spider", "Prism Ram", "Cathedral Wisp"},
    {"Coal Cub", "Ember Fox", "Furnace Hound", "Molten Boar", "Forge Drake", "Core Phoenix"},
    {"Cloud Pup", "Temple Hawk", "Marble Lion", "Golden Griffin", "Sky Serpent", "Colossus Spirit"},
    {"Shadow Slime", "Void Bat", "Obelisk Hound", "Abyss Dragon", "Crown Reaper", "Void Sovereign"},
}

local basePower = {1.15, 1.35, 1.7, 2.2, 3.0, 4.5}
for zoneIndex, names in ipairs(zones) do
    for slot, name in ipairs(names) do
        local id = string.format("Z%dP%d", zoneIndex, slot)
        Pets[id] = {
            Id = id,
            Name = name,
            Zone = zoneIndex,
            Rarity = rarityOrder[slot],
            Power = basePower[slot] * (1 + (zoneIndex - 1) * 0.7),
        }
    end
end

Pets.RarityOrder = rarityOrder
Pets.VariantMultiplier = {Normal = 1, Shiny = 2, Rainbow = 5}
Pets.VariantNext = {Normal = "Shiny", Shiny = "Rainbow"}

function Pets.Get(id: string)
    return Pets[id]
end

function Pets.GetEffectivePower(id: string, variant: string?): number
    local pet = Pets[id]
    if type(pet) ~= "table" or not pet.Power then return 0 end
    return pet.Power * (Pets.VariantMultiplier[variant or "Normal"] or 1)
end

return Pets
