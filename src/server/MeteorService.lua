local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MeteorService = {}

local stateRemote = Remotes.GetOrCreate("MeteorState")
local feedbackRemote = Remotes.GetOrCreate("MeteorFeedback")
local activeMeteor: Model? = nil
local contributions: {[Player]: number} = {}
local totalDamage = 0
local maxHealth = 0
local started = false

local FIRST_DELAY = 180
local RESPAWN_DELAY = 600
local METEOR_HEALTH = 25000

local function label(root: BasePart)
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(320, 82)
    gui.StudsOffset = Vector3.new(0, 11, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = root
    gui.Parent = root
    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromScale(1, 0.55); title.BackgroundTransparency = 1; title.Text = "GLOBAL GIANT METEOR"; title.TextColor3 = Color3.fromRGB(255, 125, 54); title.TextStrokeTransparency = 0; title.TextScaled = true; title.Font = Enum.Font.GothamBlack; title.Parent = gui
    local hp = Instance.new("TextLabel")
    hp.Name = "HPText"; hp.Size = UDim2.fromScale(1, 0.45); hp.Position = UDim2.fromScale(0, 0.55); hp.BackgroundTransparency = 1; hp.TextColor3 = Color3.new(1,1,1); hp.TextStrokeTransparency = 0; hp.TextScaled = true; hp.Font = Enum.Font.GothamBold; hp.Parent = gui
end

local function updateLabel()
    if not activeMeteor or not activeMeteor.PrimaryPart then return end
    local board = activeMeteor.PrimaryPart:FindFirstChildOfClass("BillboardGui")
    local hp = board and board:FindFirstChild("HPText")
    if hp and hp:IsA("TextLabel") then hp.Text = string.format("%d / %d HP", math.max(0, math.floor(activeMeteor:GetAttribute("Health") or 0)), maxHealth) end
end

local function awardParticipants()
    for player, damage in pairs(contributions) do
        if player.Parent == Players and damage > 0 then
            local share = totalDamage > 0 and damage / totalDamage or 0
            local gems = share >= 0.35 and 5 or (share >= 0.15 and 3 or 1)
            local tokens = share >= 0.35 and 15 or (share >= 0.15 and 8 or 3)
            local stats = player:FindFirstChild("leaderstats")
            local gemValue = stats and stats:FindFirstChild("Gems")
            local tokenValue = stats and stats:FindFirstChild("EventTokens")
            if gemValue and gemValue:IsA("IntValue") then gemValue.Value += gems end
            if tokenValue and tokenValue:IsA("IntValue") then tokenValue.Value += tokens end
            feedbackRemote:FireClient(player, "REWARD", gems, share, tokens)
        end
    end
end

local function destroyMeteor()
    if not activeMeteor then return end
    local meteor = activeMeteor
    activeMeteor = nil
    awardParticipants()
    stateRemote:FireAllClients("DEFEATED", 0, maxHealth, 0)
    task.delay(1.5, function() if meteor.Parent then meteor:Destroy() end end)
end

function MeteorService.Spawn()
    if activeMeteor then return end
    local world = workspace:FindFirstChild("GeneratedWorld")
    if not world then return end
    contributions = {}; totalDamage = 0; maxHealth = METEOR_HEALTH * math.max(1, #Players:GetPlayers())
    local model = Instance.new("Model")
    model.Name = "GiantMeteor"; model:SetAttribute("EventMeteor", true); model:SetAttribute("Health", maxHealth); model:SetAttribute("MaxHealth", maxHealth); model:SetAttribute("Alive", true); model:SetAttribute("Zone", 1)
    local root = Instance.new("Part")
    root.Name = "MeteorCore"; root.Shape = Enum.PartType.Ball; root.Size = Vector3.new(24,24,24); root.Position = Vector3.new(0,13,18); root.Anchored = true; root.Material = Enum.Material.Slate; root.Color = Color3.fromRGB(69,45,39); root.TopSurface = Enum.SurfaceType.Studs; root.BottomSurface = Enum.SurfaceType.Inlet; root.Parent = model
    local glow = Instance.new("PointLight"); glow.Color = Color3.fromRGB(255,91,37); glow.Range = 35; glow.Brightness = 4; glow.Parent = root
    local fire = Instance.new("ParticleEmitter"); fire.Rate = 35; fire.Lifetime = NumberRange.new(0.4,0.9); fire.Speed = NumberRange.new(3,7); fire.SpreadAngle = Vector2.new(180,180); fire.Parent = root
    model.PrimaryPart = root; model.Parent = world; label(root); activeMeteor = model; updateLabel(); stateRemote:FireAllClients("STARTED", maxHealth, maxHealth, 0)
end

function MeteorService.IsMeteor(model: Model?): boolean
    return model ~= nil and model == activeMeteor and model:GetAttribute("EventMeteor") == true and model:GetAttribute("Alive") == true
end

function MeteorService.ApplyDamage(player: Player, model: Model, requestedDamage: number)
    if not MeteorService.IsMeteor(model) then return nil end
    local health = tonumber(model:GetAttribute("Health")) or 0
    if health <= 0 then return nil end
    local actual = math.min(health, math.max(0, requestedDamage))
    if actual <= 0 then return nil end
    contributions[player] = (contributions[player] or 0) + actual; totalDamage += actual
    local newHealth = health - actual
    model:SetAttribute("Health", newHealth); updateLabel(); stateRemote:FireAllClients("DAMAGE", newHealth, maxHealth, totalDamage)
    if newHealth <= 0 then model:SetAttribute("Alive", false); destroyMeteor() end
    return newHealth, actual
end

function MeteorService.Start()
    if started then return end
    started = true
    task.spawn(function()
        task.wait(FIRST_DELAY)
        while true do
            MeteorService.Spawn()
            while activeMeteor do task.wait(1) end
            task.wait(RESPAWN_DELAY)
        end
    end)
    Players.PlayerRemoving:Connect(function(player) contributions[player] = nil end)
end

return MeteorService
