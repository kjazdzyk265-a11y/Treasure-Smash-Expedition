local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Tools = require(ReplicatedStorage.Shared.Tools)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local smashFeedback = remotes:WaitForChild("SmashFeedback")

local currentModel: Model? = nil
local gripMotor: Motor6D? = nil
local swinging = false

local palettes = {
    {Color3.fromRGB(126,84,48), Color3.fromRGB(196,151,89), Enum.Material.Wood},
    {Color3.fromRGB(102,108,119), Color3.fromRGB(159,166,177), Enum.Material.Slate},
    {Color3.fromRGB(118,125,136), Color3.fromRGB(212,220,230), Enum.Material.Metal},
    {Color3.fromRGB(232,180,42), Color3.fromRGB(255,229,93), Enum.Material.Metal},
    {Color3.fromRGB(70,205,255), Color3.fromRGB(179,248,255), Enum.Material.Glass},
    {Color3.fromRGB(255,82,35), Color3.fromRGB(255,181,54), Enum.Material.Neon},
    {Color3.fromRGB(61,48,74), Color3.fromRGB(142,89,202), Enum.Material.Slate},
    {Color3.fromRGB(130,54,236), Color3.fromRGB(230,114,255), Enum.Material.Neon},
    {Color3.fromRGB(255,228,107), Color3.fromRGB(126,221,255), Enum.Material.Neon},
    {Color3.fromRGB(66,213,255), Color3.fromRGB(183,114,255), Enum.Material.Neon},
}

local function visualPart(parent, name, size, color, material, cf, kind)
    local p
    if kind == "Wedge" then p = Instance.new("WedgePart") else p = Instance.new("Part") end
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Massless = true
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if kind == "Ball" and p:IsA("Part") then p.Shape = Enum.PartType.Ball end
    if kind == "Cylinder" and p:IsA("Part") then p.Shape = Enum.PartType.Cylinder end
    p.CFrame = cf
    p.Parent = parent
    return p
end

local function weld(root, child)
    local w = Instance.new("WeldConstraint")
    w.Part0 = root
    w.Part1 = child
    w.Parent = root
end

local function addGlow(part, color, brightness)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = 8 + brightness * 2
    light.Parent = part
end

local function buildHammer(index)
    local tool = Tools[index]
    if not tool then return nil end
    local tier = math.clamp(math.ceil(index / 2), 1, #palettes)
    local palette = palettes[tier]
    local main, accent, material = palette[1], palette[2], palette[3]
    local scale = 1 + (index - 1) * 0.025

    local model = Instance.new("Model")
    model.Name = "ClientHammer_" .. tostring(index)

    local handle = visualPart(model, "Handle", Vector3.new(0.42,4.6,0.42)*scale, Color3.fromRGB(92,62,43), Enum.Material.Wood, CFrame.new())
    handle.Anchored = false
    model.PrimaryPart = handle

    local headSize = Vector3.new(2.5+(index%4)*0.22, 1.25+(index%3)*0.12, 1.35+(index%2)*0.22)*scale
    local head = visualPart(model, "Head", headSize, main, material, CFrame.new(0,2.0*scale,0))
    head.Anchored = false
    weld(handle, head)

    if index % 2 == 0 then
        local band = visualPart(model, "Band", Vector3.new(0.72,0.42,0.72)*scale, accent, Enum.Material.Metal, CFrame.new(0,1.15*scale,0))
        band.Anchored = false
        weld(handle, band)
    end

    if index >= 5 then
        for side = -1, 1, 2 do
            local spike = visualPart(model, "HeadSpike", Vector3.new(0.5,0.5,1.0)*scale, accent, material, CFrame.new(side*headSize.X*0.53,2.0*scale,0)*CFrame.Angles(0,0,math.rad(45*side)), "Wedge")
            spike.Anchored = false
            weld(handle, spike)
        end
    end

    if index >= 10 then
        local core = visualPart(model, "PowerCore", Vector3.new(0.68,0.68,0.68)*scale, accent, Enum.Material.Neon, CFrame.new(0,2.0*scale,headSize.Z*0.52), "Ball")
        core.Anchored = false
        weld(handle, core)
        addGlow(core, accent, 1.3 + index*0.04)
    end

    if index >= 15 then
        for side = -1, 1, 2 do
            local rune = visualPart(model, "Rune", Vector3.new(0.18,0.72,1.0)*scale, accent, Enum.Material.Neon, CFrame.new(side*headSize.X*0.30,2.0*scale,-headSize.Z*0.51))
            rune.Anchored = false
            weld(handle, rune)
        end
    end

    local a0 = Instance.new("Attachment")
    a0.Position = Vector3.new(-headSize.X*0.48,0,0)
    a0.Parent = head
    local a1 = Instance.new("Attachment")
    a1.Position = Vector3.new(headSize.X*0.48,0,0)
    a1.Parent = head
    local trail = Instance.new("Trail")
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime = 0.12 + math.min(0.16,index*0.006)
    trail.MinLength = 0.05
    trail.Color = ColorSequence.new(main,accent)
    trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.08), NumberSequenceKeypoint.new(1,1)})
    trail.Enabled = false
    trail.Parent = head

    model:SetAttribute("ToolIndex", index)
    return model
end

local function rightHand(character)
    return character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
end

local function equipVisual()
    if currentModel then currentModel:Destroy(); currentModel = nil end
    if gripMotor then gripMotor:Destroy(); gripMotor = nil end
    local character = player.Character
    if not character then return end
    local hand = rightHand(character)
    if not hand or not hand:IsA("BasePart") then return end

    local index = math.clamp(tonumber(player:GetAttribute("ToolIndex")) or 1, 1, #Tools)
    local model = buildHammer(index)
    if not model or not model.PrimaryPart then return end
    model.Parent = character

    local motor = Instance.new("Motor6D")
    motor.Name = "TreasureHammerGrip"
    motor.Part0 = hand
    motor.Part1 = model.PrimaryPart
    motor.C0 = CFrame.new(0,-1.7,-0.15) * CFrame.Angles(math.rad(8),0,math.rad(90))
    motor.Parent = hand
    model.PrimaryPart.CFrame = hand.CFrame * motor.C0

    currentModel = model
    gripMotor = motor
end

local function swing()
    local motor, model = gripMotor, currentModel
    if not motor or not model or swinging then return end
    swinging = true
    local trail = model:FindFirstChildWhichIsA("Trail", true)
    if trail then trail.Enabled = true end
    motor.Transform = CFrame.new()
    local wind = TweenService:Create(motor,TweenInfo.new(0.07,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transform=CFrame.Angles(math.rad(-28),0,math.rad(-25))})
    wind:Play(); wind.Completed:Wait()
    local hit = TweenService:Create(motor,TweenInfo.new(0.075,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Transform=CFrame.Angles(math.rad(62),0,math.rad(20))})
    hit:Play(); hit.Completed:Wait()
    local recover = TweenService:Create(motor,TweenInfo.new(0.12,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Transform=CFrame.new()})
    recover:Play(); recover.Completed:Wait()
    if trail then trail.Enabled = false end
    swinging = false
end

player:GetAttributeChangedSignal("ToolIndex"):Connect(equipVisual)
player.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid",8)
    task.wait(0.25)
    equipVisual()
end)
smashFeedback.OnClientEvent:Connect(function() task.spawn(swing) end)
if player.Character then task.defer(equipVisual) end
