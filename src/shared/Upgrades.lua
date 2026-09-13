local Upgrades = {
    Damage = {BaseCost = 80, Growth = 1.55, MaxLevel = 50, PerLevel = 0.10},
    AttackSpeed = {BaseCost = 120, Growth = 1.65, MaxLevel = 30, PerLevel = 0.025},
    Range = {BaseCost = 100, Growth = 1.60, MaxLevel = 25, PerLevel = 0.75},
    MovementSpeed = {BaseCost = 150, Growth = 1.70, MaxLevel = 20, PerLevel = 0.75},
    Luck = {BaseCost = 220, Growth = 1.75, MaxLevel = 25, PerLevel = 0.02},
    CritChance = {BaseCost = 300, Growth = 1.85, MaxLevel = 20, PerLevel = 0.005},
    CoinGain = {BaseCost = 180, Growth = 1.70, MaxLevel = 40, PerLevel = 0.08},
    BackpackSlots = {BaseCost = 250, Growth = 1.80, MaxLevel = 25, PerLevel = 5},
    PetSlots = {BaseCost = 5000, Growth = 3.00, MaxLevel = 5, PerLevel = 1},
}

function Upgrades.GetCost(name: string, level: number): number?
    local cfg = Upgrades[name]
    if type(cfg) ~= "table" or not cfg.BaseCost then return nil end
    return math.floor(cfg.BaseCost * (cfg.Growth ^ level) + 0.5)
end

return Upgrades
