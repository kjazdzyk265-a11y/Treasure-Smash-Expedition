local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Breakables = require(ReplicatedStorage.Shared.Breakables)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SmashService = {}
local lastSmash: {[Player]: number} = {}

local smashRemote = Remotes.GetOrCreate("SmashRequest")
local feedbackRemote = Remotes.GetOrCreate("SmashFeedback")

local function getRoot(player: Player): BasePart?
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getTargetModel(target: Instance?): Model?
    if not target then return nil end
    local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
    if model and model:GetAttribute("BreakableType") then return model end
    return nil
end

local function award(player: Player, baseCoins: number)
    local stats = player:FindFirstChild("leaderstats")
    local coins = stats and stats:FindFirstChild("Coins")
    local power = stats and stats:FindFirstChild("Power")
    local coinMultiplier = tonumber(player:GetAttribute("CoinMultiplier")) or 1
    local trainingMultiplier = tonumber(player:GetAttribute("TrainingMultiplier")) or 1
    if coins and coins:IsA("IntValue") then
        coins.Value += math.max(1, math.floor(baseCoins * coinMultiplier + 0.5))
    end
    if power and power:IsA("IntValue") then
        power.Value += math.max(1, math.floor(trainingMultiplier + 0.5))
    end
end

local function respawn(model: Model)
    local kind = model:GetAttribute("BreakableType")
    local cfg = Breakables[kind]
    if not cfg then return end
    task.delay(cfg.Respawn, function()
        if not model.Parent then return end
        model:SetAttribute("Health", cfg.MaxHealth)
        model:SetAttribute("Alive", true)
        for _, obj in model:GetDescendants() do
            if obj:IsA("BasePart") then
                obj.Transparency = 0
                obj.CanCollide = true
            end
        end
    end)
end

local function processSmash(player: Player, target: Instance?)
    local now = os.clock()
    local attackSpeed = math.max(0.1, tonumber(player:GetAttribute("AttackSpeed")) or 1)
    local cooldown = GameConfig.SmashCooldown / attackSpeed
    if now - (lastSmash[player] or 0) < cooldown then return end
    lastSmash[player] = now

    local root = getRoot(player)
    local model = getTargetModel(target)
    if not root or not model or model:GetAttribute("Alive") ~= true or not model.PrimaryPart then return end

    local range = math.clamp(tonumber(player:GetAttribute("SmashRange")) or GameConfig.MaxSmashDistance, 8, 60)
    if (root.Position - model.PrimaryPart.Position).Magnitude > range then return end

    local health = model:GetAttribute("Health")
    if typeof(health) ~= "number" or health <= 0 then return end

    local baseDamage = math.max(1, tonumber(player:GetAttribute("SmashDamage")) or GameConfig.StarterDamage)
    local petMultiplier = math.clamp(tonumber(player:GetAttribute("PetDamageMultiplier")) or 1, 1, 1000)
    local damage = baseDamage * petMultiplier
    local critChance = math.clamp(tonumber(player:GetAttribute("CritChance")) or GameConfig.BaseCritChance, 0, 0.5)
    local critical = math.random() < critChance
    if critical then damage *= GameConfig.CritMultiplier end

    local newHealth = math.max(0, health - damage)
    model:SetAttribute("Health", newHealth)
    feedbackRemote:FireClient(player, model, damage, critical, newHealth)

    if newHealth <= 0 then
        model:SetAttribute("Alive", false)
        award(player, model:GetAttribute("Reward") or 0)
        for _, obj in model:GetDescendants() do
            if obj:IsA("BasePart") then
                obj.Transparency = 0.78
                obj.CanCollide = false
            end
        end
        respawn(model)
    end
end

function SmashService.Start()
    smashRemote.OnServerEvent:Connect(function(player, target)
        if typeof(target) ~= "Instance" then return end
        processSmash(player, target)
    end)
    Players.PlayerRemoving:Connect(function(player)
        lastSmash[player] = nil
    end)
end

return SmashService
