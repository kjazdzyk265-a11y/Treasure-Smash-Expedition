local Variants = {
    Normal = {Chance = 0.9575, Health = 1, Reward = 1, Color = nil},
    Golden = {Chance = 0.03, Health = 2.5, Reward = 4, Color = Color3.fromRGB(255, 205, 55)},
    Crystal = {Chance = 0.01, Health = 5, Reward = 10, Color = Color3.fromRGB(93, 239, 255)},
    Void = {Chance = 0.002, Health = 12, Reward = 35, Color = Color3.fromRGB(174, 74, 255)},
    Secret = {Chance = 0.0005, Health = 30, Reward = 120, Color = Color3.fromRGB(255, 90, 210)},
}

local order = {"Secret", "Void", "Crystal", "Golden"}

function Variants.Roll(rng: Random?): string
    rng = rng or Random.new()
    local value = rng:NextNumber()
    local cursor = 0
    for _, name in ipairs(order) do
        cursor += Variants[name].Chance
        if value <= cursor then return name end
    end
    return "Normal"
end

function Variants.Get(name: string)
    return Variants[name] or Variants.Normal
end

return Variants
