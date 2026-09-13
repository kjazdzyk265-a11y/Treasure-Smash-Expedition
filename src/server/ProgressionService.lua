local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tools = require(ReplicatedStorage.Shared.Tools)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ProgressionService = {}

local purchaseToolRemote = Remotes.GetOrCreate("PurchaseTool")
local purchaseUpgradeRemote = Remotes.GetOrCreate("PurchaseUpgrade")
local progressionFeedback = Remotes.GetOrCreate("ProgressionFeedback")
local lastPurchase: {[Player]: number} = {}

local function getCoins(player: Player): IntValue?
    local stats = player:FindFirstChild("leaderstats")
    local coins = stats and stats:FindFirstChild("Coins")
    return coins and coins:IsA("IntValue") and coins or nil
end

local function getUpgradeFolder(player: Player): Folder?
    local folder = player:FindFirstChild("Upgrades")
    return folder and folder:IsA("Folder") and folder or nil
end

local function getLevel(player, name)
    local folder = getUpgradeFolder(player)
    local value = folder and folder:FindFirstChild(name)
    return value and value:IsA("IntValue") and value.Value or 0
end

local function applyMovement(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = tonumber(player:GetAttribute("MovementSpeed")) or 16
    end
end

function ProgressionService.ApplyDerivedStats(player: Player)
    local toolIndex = math.clamp(player:GetAttribute("ToolIndex") or 1, 1, #Tools)
    local tool = Tools[toolIndex]
    local rebirths = math.max(0, tonumber(player:GetAttribute("Rebirths")) or 0)
    local rebirthMultiplier = 1 + rebirths * 0.225

    local damageMultiplier = (1 + getLevel(player, "Damage") * Upgrades.Damage.PerLevel) * rebirthMultiplier
    local attackMultiplier = 1 + getLevel(player, "AttackSpeed") * Upgrades.AttackSpeed.PerLevel
    local rangeBonus = getLevel(player, "Range") * Upgrades.Range.PerLevel
    local critBonus = getLevel(player, "CritChance") * Upgrades.CritChance.PerLevel
    local coinMultiplier = (1 + getLevel(player, "CoinGain") * Upgrades.CoinGain.PerLevel) * rebirthMultiplier
    local movementSpeed = 16 + getLevel(player, "MovementSpeed") * Upgrades.MovementSpeed.PerLevel

    player:SetAttribute("ToolName", tool.Name)
    player:SetAttribute("SmashDamage", tool.Damage * damageMultiplier)
    player:SetAttribute("AttackSpeed", tool.AttackSpeed * attackMultiplier)
    player:SetAttribute("SmashRange", 24 + rangeBonus)
    player:SetAttribute("CritChance", 0.08 + critBonus)
    player:SetAttribute("CoinMultiplier", coinMultiplier)
    player:SetAttribute("TrainingMultiplier", tool.TrainingMultiplier * rebirthMultiplier)
    player:SetAttribute("MovementSpeed", movementSpeed)
    player:SetAttribute("LuckMultiplier", 1 + getLevel(player, "Luck") * Upgrades.Luck.PerLevel)
    player:SetAttribute("RebirthMultiplier", rebirthMultiplier)
    applyMovement(player)
end

local function rateLimited(player)
    local now = os.clock()
    if now - (lastPurchase[player] or 0) < 0.15 then return true end
    lastPurchase[player] = now
    return false
end

local function purchaseTool(player: Player)
    if rateLimited(player) then return end
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
    if rateLimited(player) or typeof(name) ~= "string" then return end
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
    purchaseToolRemote.OnServerEvent:Connect(purchaseTool)
    purchaseUpgradeRemote.OnServerEvent:Connect(purchaseUpgrade)
    Players.PlayerRemoving:Connect(function(player) lastPurchase[player] = nil end)
end

return ProgressionService
