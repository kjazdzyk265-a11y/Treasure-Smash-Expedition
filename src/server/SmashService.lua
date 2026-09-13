local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Breakables = require(ReplicatedStorage.Shared.Breakables)
local Variants = require(ReplicatedStorage.Shared.BreakableVariants)
local Zones = require(ReplicatedStorage.Shared.Zones)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BackpackService = require(script.Parent.BackpackService)
local RetentionService = require(script.Parent.RetentionService)

local SmashService = {}
local lastSmash: {[Player]: number} = {}
local nextPerfectAt: {[Player]: number} = {}
local comboCount: {[Player]: number} = {}
local lastComboHit: {[Player]: number} = {}
local rng = Random.new()

local smashRemote = Remotes.GetOrCreate("SmashRequest")
local feedbackRemote = Remotes.GetOrCreate("SmashFeedback")
local bossRemote = Remotes.GetOrCreate("BossFeedback")
local perfectCueRemote = Remotes.GetOrCreate("PerfectCue")

local COMBO_TIMEOUT = 1.6

local function getRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getTargetModel(target)
    if not target then return nil end
    local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
    if model and model:GetAttribute("BreakableType") then return model end
    return nil
end

local function comboMultiplier(count)
    if count >= 25 then return 25 end
    if count >= 10 then return 10 end
    if count >= 5 then return 5 end
    if count >= 3 then return 3 end
    if count >= 2 then return 2 end
    return 1
end

local function advanceCombo(player, now)
    local previous = lastComboHit[player] or 0
    if now - previous <= COMBO_TIMEOUT then comboCount[player] = math.min(25, (comboCount[player] or 0) + 1) else comboCount[player] = 1 end
    lastComboHit[player] = now
    local count = comboCount[player]
    local mult = comboMultiplier(count)
    player:SetAttribute("ComboCount", count)
    player:SetAttribute("ComboMultiplier", mult)
    return count, mult
end

local function getPing(player)
    local ok, ping = pcall(function() return player:GetNetworkPing() end)
    if not ok or type(ping) ~= "number" then return 0.08 end
    return math.clamp(ping, 0, 0.35)
end

local function scheduleNextPerfect(player, now, cooldown)
    local center = now + cooldown + 0.10
    nextPerfectAt[player] = center
    local cueDelay = math.max(0.05, cooldown + 0.10 - getPing(player) * 0.5)
    perfectCueRemote:FireClient(player, cueDelay, GameConfig.PerfectWindow)
end

local function applyVariant(model, variantName)
    local cfg = Breakables[model:GetAttribute("BreakableType")]
    if not cfg then return end
    local variant = Variants.Get(variantName)
    local maxHealth = math.max(1, math.floor(cfg.MaxHealth * variant.Health + 0.5))
    local reward = math.max(1, math.floor(cfg.Reward * variant.Reward + 0.5))
    model:SetAttribute("Variant", variantName)
    model:SetAttribute("MaxHealth", maxHealth)
    model:SetAttribute("Health", maxHealth)
    model:SetAttribute("Reward", reward)
    if model.PrimaryPart and variant.Color then model.PrimaryPart.Color = variant.Color end
end

local function respawn(model)
    local cfg = Breakables[model:GetAttribute("BreakableType")]
    if not cfg then return end
    task.delay(cfg.Respawn, function()
        if not model.Parent then return end
        local variantName = model:GetAttribute("Boss") == true and "Normal" or Variants.Roll(rng)
        applyVariant(model, variantName)
        model:SetAttribute("Alive", true)
        for _, obj in model:GetDescendants() do
            if obj:IsA("BasePart") then
                obj.Transparency = (cfg.Material == "Crystal" or cfg.Material == "Magma" or cfg.Material == "Void") and 0.08 or 0
                obj.CanCollide = true
            end
        end
    end)
end

local function handleBossDefeat(player, model)
    local zone = math.clamp(tonumber(model:GetAttribute("Zone")) or 1, 1, #Zones)
    bossRemote:FireAllClients(zone, model.Name, player.Name)
    RetentionService.Record(player, "BossKill", 1)
    local highest = player:GetAttribute("HighestZone") or 1
    if zone == highest and zone < #Zones then player:SetAttribute("HighestZone", zone + 1) end
end

local function processSmash(player, target)
    local now = os.clock()
    local attackSpeed = math.max(0.1, tonumber(player:GetAttribute("AttackSpeed")) or 1)
    local cooldown = GameConfig.SmashCooldown / attackSpeed
    if now - (lastSmash[player] or 0) < cooldown then return end

    local root = getRoot(player)
    local model = getTargetModel(target)
    if not root or not model or model:GetAttribute("Alive") ~= true or not model.PrimaryPart then return end
    if (tonumber(model:GetAttribute("Zone")) or 1) > (player:GetAttribute("HighestZone") or 1) then return end
    local range = math.clamp(tonumber(player:GetAttribute("SmashRange")) or GameConfig.MaxSmashDistance, 8, 60)
    if (root.Position - model.PrimaryPart.Position).Magnitude > range then return end

    local health = model:GetAttribute("Health")
    if typeof(health) ~= "number" or health <= 0 then return end

    local perfect = false
    local perfectAt = nextPerfectAt[player]
    if perfectAt and math.abs(now - perfectAt) <= GameConfig.PerfectWindow * 0.5 then perfect = true end

    lastSmash[player] = now
    local combo, comboMult = advanceCombo(player, now)

    local damage = math.max(1, tonumber(player:GetAttribute("SmashDamage")) or GameConfig.StarterDamage)
    damage *= math.max(1, tonumber(player:GetAttribute("PetDamageMultiplier")) or 1)
    local critical = math.random() < math.clamp(tonumber(player:GetAttribute("CritChance")) or GameConfig.BaseCritChance, 0, 0.5)
    if critical then damage *= GameConfig.CritMultiplier end
    if perfect then
        damage *= GameConfig.PerfectMultiplier
        RetentionService.Record(player, "Perfect", 1)
    end

    local newHealth = math.max(0, health - damage)
    model:SetAttribute("Health", newHealth)
    feedbackRemote:FireClient(player, model, damage, critical, newHealth, model:GetAttribute("MaxHealth"), model:GetAttribute("Variant") or "Normal", perfect, combo, comboMult)
    scheduleNextPerfect(player, now, cooldown)

    if newHealth <= 0 then
        model:SetAttribute("Alive", false)
        RetentionService.Record(player, "SmashKill", 1)
        local reward = math.max(1, math.floor((model:GetAttribute("Reward") or 0) * comboMult + 0.5))
        BackpackService.AddLoot(player, reward)
        local stats = player:FindFirstChild("leaderstats")
        local power = stats and stats:FindFirstChild("Power")
        if power and power:IsA("IntValue") then
            power.Value += math.max(1, math.floor((tonumber(player:GetAttribute("TrainingMultiplier")) or 1) * comboMult + 0.5))
        end
        if model:GetAttribute("Boss") == true then handleBossDefeat(player, model) end
        for _, obj in model:GetDescendants() do
            if obj:IsA("BasePart") then obj.Transparency = 0.78; obj.CanCollide = false end
        end
        respawn(model)
    end
end

function SmashService.ResetPlayerState(player)
    lastSmash[player] = nil
    nextPerfectAt[player] = nil
    comboCount[player] = nil
    lastComboHit[player] = nil
    player:SetAttribute("ComboCount", 0)
    player:SetAttribute("ComboMultiplier", 1)
end

function SmashService.Start()
    smashRemote.OnServerEvent:Connect(function(player, target)
        if typeof(target) == "Instance" then processSmash(player, target) end
    end)
    Players.PlayerRemoving:Connect(SmashService.ResetPlayerState)
end

return SmashService
