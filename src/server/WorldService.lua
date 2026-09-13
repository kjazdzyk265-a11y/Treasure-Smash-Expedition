local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Breakables = require(ReplicatedStorage.Shared.Breakables)

local WorldService = {}

local function makePart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Studs
    part.BottomSurface = Enum.SurfaceType.Inlet
    part.Parent = parent
    return part
end

local function spawnBreakable(parent: Instance, kind: string, position: Vector3)
    local cfg = Breakables[kind]
    local model = Instance.new("Model")
    model.Name = kind
    model:SetAttribute("BreakableType", kind)
    model:SetAttribute("Health", cfg.MaxHealth)
    model:SetAttribute("MaxHealth", cfg.MaxHealth)
    model:SetAttribute("Reward", cfg.Reward)
    model:SetAttribute("Alive", true)

    local color = kind == "Rock" and Color3.fromRGB(112, 118, 126) or Color3.fromRGB(151, 96, 52)
    if kind == "IronSafe" then color = Color3.fromRGB(65, 78, 90) end
    if kind == "TreasureChest" then color = Color3.fromRGB(236, 165, 36) end
    local root = makePart(model, "Root", Vector3.new(5, 5, 5), position, color, kind == "Rock" and Enum.Material.Slate or Enum.Material.WoodPlanks)
    root:SetAttribute("BreakableRoot", true)
    model.PrimaryPart = root
    model.Parent = parent
    CollectionService:AddTag(model, "Breakable")
end

local function spawnEggStation(parent: Instance, position: Vector3)
    local model = Instance.new("Model")
    model.Name = "GreenEggStation"
    model.Parent = parent

    local pedestal = makePart(model, "Pedestal", Vector3.new(10, 2, 10), position, Color3.fromRGB(244, 218, 112), Enum.Material.SmoothPlastic)
    local egg = makePart(model, "Egg", Vector3.new(6, 8, 6), position + Vector3.new(0, 5, 0), Color3.fromRGB(132, 239, 112), Enum.Material.SmoothPlastic)
    egg.Shape = Enum.PartType.Ball
    egg.TopSurface = Enum.SurfaceType.Smooth
    egg.BottomSurface = Enum.SurfaceType.Smooth

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "HatchPrompt"
    prompt.ActionText = "Hatch • 120 Coins"
    prompt.ObjectText = "Green Valley Egg"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt:SetAttribute("EggId", "GreenEgg")
    prompt.Parent = pedestal
    CollectionService:AddTag(prompt, "EggPrompt")

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EggSign"
    billboard.Size = UDim2.fromOffset(250, 85)
    billboard.StudsOffset = Vector3.new(0, 8, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = egg
    billboard.Parent = egg

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = "GREEN EGG\n120 COINS"
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0
    text.TextScaled = true
    text.Font = Enum.Font.GothamBlack
    text.Parent = billboard
end

function WorldService.Build()
    if workspace:FindFirstChild("GeneratedWorld") then return end
    local world = Instance.new("Folder")
    world.Name = "GeneratedWorld"
    world.Parent = workspace

    local zone = Instance.new("Folder")
    zone.Name = "GreenValley"
    zone.Parent = world

    makePart(zone, "Ground", Vector3.new(170, 2, 150), Vector3.new(0, -1, 0), Color3.fromRGB(80, 190, 79), Enum.Material.Grass)
    makePart(zone, "Road", Vector3.new(18, 1, 125), Vector3.new(0, 0.05, 0), Color3.fromRGB(205, 177, 125), Enum.Material.Ground)

    for i = 1, 20 do
        local side = i % 2 == 0 and 1 or -1
        local z = -55 + i * 5.5
        local x = side * (18 + (i % 4) * 5)
        local kind = ({"Crate", "Barrel", "Rock", "Crate", "Rock"})[(i - 1) % 5 + 1]
        spawnBreakable(zone, kind, Vector3.new(x, 2.5, z))
    end

    spawnBreakable(zone, "IronSafe", Vector3.new(-28, 2.5, 48))
    spawnBreakable(zone, "TreasureChest", Vector3.new(0, 2.5, 62))

    for i = 1, 14 do
        local x = (i % 2 == 0 and -1 or 1) * (55 + (i % 3) * 7)
        local z = -58 + i * 9
        makePart(zone, "TreeTrunk", Vector3.new(3, 8, 3), Vector3.new(x, 4, z), Color3.fromRGB(105, 67, 36), Enum.Material.Wood)
        makePart(zone, "TreeCrown", Vector3.new(9, 8, 9), Vector3.new(x, 10, z), Color3.fromRGB(49, 147, 59), Enum.Material.Grass)
    end

    local sell = makePart(zone, "SellPad", Vector3.new(16, 1, 12), Vector3.new(-24, 0.6, -58), Color3.fromRGB(255, 214, 52), Enum.Material.Neon)
    sell:SetAttribute("SellPad", true)
    spawnEggStation(zone, Vector3.new(31, 1, -48))

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "GreenValleySpawn"
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.Position = Vector3.new(0, 1, -62)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Parent = zone
end

return WorldService
