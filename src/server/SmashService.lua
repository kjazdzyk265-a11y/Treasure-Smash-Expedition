local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Breakables = require(ReplicatedStorage.Shared.Breakables)
local Variants = require(ReplicatedStorage.Shared.BreakableVariants)
local Zones = require(ReplicatedStorage.Shared.Zones)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BackpackService = require(script.Parent.BackpackService)

local SmashService = {}
local lastSmash: {[Player]: number} = {}
local rng = Random.new()

local smashRemote = Remotes.GetOrCreate("SmashRequest")
local feedbackRemote = Remotes.GetOrCreate("SmashFeedback")
local bossRemote = Remotes.GetOrCreate("BossFeedback")

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
    local highest = player:GetAttribute("HighestZone") or 1
    if zone == highest and zone < #Zones then player:SetAttribute("HighestZone", zone + 1) end
end

local function processSmash(player, target)
    local now = os.clock()
    local attackSpeed = math.max(0.1, tonumber(player:GetAttribute("AttackSpeed")) or 1)
    if now - (lastSmash[player] or 0) < GameConfig.SmashCooldown / attackSpeed then return end
    lastSmash[player] = now

    local root = getRoot(player)
    local model = getTargetModel(target)
    if not root or not model or model:GetAttribute("Alive") ~= true or not model.PrimaryPart then return end
    if (tonumber(model:GetAttribute("Zone")) or 1) > (player:GetAttribute("HighestZone") or 1) then return end
    local range = math.clamp(tonumber(player:GetAttribute("SmashRange")) or GameConfig.MaxSmashDistance, 8, 60)
    if (root.Position - model.PrimaryPart.Position).Magnitude > range then return end

    local health = model:GetAttribute("Health")
    if typeof(health) ~= "number" or health <= 0 then return end
    local damage = math.max(1, tonumber(player:GetAttribute("SmashDamage")) or GameConfig.StarterDamage)
    damage *= math.max(1, tonumber(player:GetAttribute("PetDamageMultiplier")) or 1)
    local critical = math.random() < math.clamp(tonumber(player:GetAttribute("CritChance")) or GameConfig.BaseCritChance, 0, 0.5)
    if critical then damage *= GameConfig.CritMultiplier end

    local newHealth = math.max(0, health - damage)
    model:SetAttribute("Health", newHealth)
    feedbackRemote:FireClient(player, model, damage, critical, newHealth, model:GetAttribute("MaxHealth"), model:GetAttribute("Variant") or "Normal")

    if newHealth <= 0 then
        model:SetAttribute("Alive", false)
        local reward = model:GetAttribute("Reward") or 0
        BackpackService.AddLoot(player, reward)
        local stats = player:FindFirstChild("leaderstats")
        local power = stats and stats:FindFirstChild("Power")
        if power and power:IsA("IntValue") then
            power.Value += math.max(1, math.floor((tonumber(player:GetAttribute("TrainingMultiplier")) or 1) + 0.5))
        end
        if model:GetAttribute("Boss") == true then handleBossDefeat(player, model) end
        for _, obj in model:GetDescendants() do
            if obj:IsA("BasePart") then obj.Transparency = 0.78; obj.CanCollide = false end
        end
        respawn(model)
    end
end

function SmashService.Start()
    smashRemote.OnServerEvent:Connect(function(player, target)
        if typeof(target) == "Instance" then processSmash(player, target) end
    end)
    Players.PlayerRemoving:Connect(function(player) lastSmash[player] = nil end)
end

return SmashService
