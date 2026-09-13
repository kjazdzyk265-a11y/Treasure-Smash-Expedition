local EggConfig = {
    GreenEgg = {Name = "Green Valley Egg", Zone = 1, Price = 120, Pets = {"Z1P1","Z1P2","Z1P3","Z1P4","Z1P5","Z1P6"}},
    CityEgg = {Name = "Construction Egg", Zone = 2, Price = 850, Pets = {"Z2P1","Z2P2","Z2P3","Z2P4","Z2P5","Z2P6"}},
    CrystalEgg = {Name = "Crystal Egg", Zone = 3, Price = 5200, Pets = {"Z3P1","Z3P2","Z3P3","Z3P4","Z3P5","Z3P6"}},
    MagmaEgg = {Name = "Magma Egg", Zone = 4, Price = 32000, Pets = {"Z4P1","Z4P2","Z4P3","Z4P4","Z4P5","Z4P6"}},
    SkyEgg = {Name = "Sky Egg", Zone = 5, Price = 210000, Pets = {"Z5P1","Z5P2","Z5P3","Z5P4","Z5P5","Z5P6"}},
    VoidEgg = {Name = "Void Egg", Zone = 6, Price = 1500000, Pets = {"Z6P1","Z6P2","Z6P3","Z6P4","Z6P5","Z6P6"}},
}

EggConfig.Weights = {40, 28, 17, 9, 5, 1}

function EggConfig.Roll(eggId: string, random: Random): string?
    local egg = EggConfig[eggId]
    if type(egg) ~= "table" or not egg.Pets then return nil end
    local roll = random:NextNumber(0, 100)
    local cursor = 0
    for index, weight in ipairs(EggConfig.Weights) do
        cursor += weight
        if roll <= cursor then return egg.Pets[index] end
    end
    return egg.Pets[#egg.Pets]
end

return EggConfig
