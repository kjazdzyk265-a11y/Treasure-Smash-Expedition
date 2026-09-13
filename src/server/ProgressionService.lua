local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tools = require(ReplicatedStorage.Shared.Tools)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ProgressionService = {}

local purchaseToolRemote = Remotes.GetOrCreate("PurchaseTool")
local purchaseUpgradeRemote = Remotes.GetOrCreate("PurchaseUpgrade")
local progressionFeedback = Remotes.GetOrCreate("ProgressionFeedback")

local function getCoins(player: Player): IntValue?
    local stats = player:FindFirstChild("leaderstats")
    local coins = stats and stats:FindFirstChild("Coins")
    return coins and coins:IsA("IntValue") and coins or nil
end

local function getUpgradeFolder(player: Player): Folder?
    local folder = player:FindFirstChild("Upgrades")
    return folder and folder:IsA("Folder") and folder or nil
end

function ProgressionService.ApplyDerivedStats(player: Player)
    local toolIndex = math.clamp(player:GetAttribute("ToolIndex") or 1, 1, #Tools)
    local tool = Tools[toolIndex]
    local upgrades = getUpgradeFolder(player)

    local function level(name: string): number
        local value = upgrades and upgrades:FindFirstChild(name)
        return value and value:IsA("IntValue") and value.Value or 0
    end

    local damageMultiplier = 1 + level("Damage") * Upgrades.Damage.PerLevel
    local attackMultiplier = 1 + level("AttackSpeed") * Upgrades.AttackSpeed.PerLevel
    local rangeBonus = level("Range") * Upgrades.Range.PerLevel
    local critBonus = level("CritChance") * Upgrades.CritChance.PerLevel
    local coinMultiplier = 1 + level("CoinGain") * Upgrades.CoinGain.PerLevel

    player:SetAttribute("ToolName", tool.Name)
    player:SetAttribute("SmashDamage", tool.Damage * damageMultiplier)
    player:SetAttribute("AttackSpeed", tool.AttackSpeed * attackMultiplier)
    player:SetAttribute("SmashRange", 24 + rangeBonus)
    player:SetAttribute("CritChance", 0.08 + critBonus)
    player:SetAttribute("CoinMultiplier", coinMultiplier)
    player:SetAttribute("TrainingMultiplier", tool.TrainingMultiplier)
end

local function purchaseTool(player: Player)
    local current = math.clamp(player:GetAttribute("ToolIndex") or 1, 1, #Tools)
    local nextIndex = current + 1
    local nextTool = Tools[nextIndex]
    if not nextTool then
        progressionFeedback:FireClient(player, false, "MAX TOOL")
        return
    end

    local coins = getCoins(player)
    if not coins or coins.Value < nextTool.Price then
        progressionFeedback:FireClient(player, false, "NEED " .. nextTool.Price .. " COINS")
        return
    end

    coins.Value -= nextTool.Price
    player:SetAttribute("ToolIndex", nextIndex)
    ProgressionService.ApplyDerivedStats(player)
    progressionFeedback:FireClient(player, true, "UNLOCKED " .. nextTool.Name)
end

local function purchaseUpgrade(player: Player, name: any)
    if typeof(name) ~= "string" then return end
    local cfg = Upgrades[name]
    if type(cfg) ~= "table" or not cfg.BaseCost then return end

    local folder = getUpgradeFolder(player)
    local value = folder and folder:FindFirstChild(name)
    local coins = getCoins(player)
    if not value or not value:IsA("IntValue") or not coins then return end
    if value.Value >= cfg.MaxLevel then
        progressionFeedback:FireClient(player, false, name .. " MAX")
        return
    end

    local cost = Upgrades.GetCost(name, value.Value)
    if not cost or coins.Value < cost then
        progressionFeedback:FireClient(player, false, "NEED " .. tostring(cost) .. " COINS")
        return
    end

    coins.Value -= cost
    value.Value += 1
    ProgressionService.ApplyDerivedStats(player)
    progressionFeedback:FireClient(player, true, name .. " LV." .. value.Value)
end

function ProgressionService.Start()
    purchaseToolRemote.OnServerEvent:Connect(function(player)
        purchaseTool(player)
    end)
    purchaseUpgradeRemote.OnServerEvent:Connect(function(player, name)
        purchaseUpgrade(player, name)
    end)
end

return ProgressionService
