local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Pets = require(ReplicatedStorage.Shared.Pets)

local rootFolder = Instance.new("Folder")
rootFolder.Name = "ClientPetVisuals_" .. player.UserId
rootFolder.Parent = workspace

local visuals = {}
local phaseByUid = {}

local zoneColors = {
    [1] = {Color3.fromRGB(83,199,87), Color3.fromRGB(255,218,90)},
    [2] = {Color3.fromRGB(116,130,145), Color3.fromRGB(255,176,48)},
    [3] = {Color3.fromRGB(77,216,255), Color3.fromRGB(181,94,255)},
    [4] = {Color3.fromRGB(255,93,40), Color3.fromRGB(255,207,70)},
    [5] = {Color3.fromRGB(238,230,194), Color3.fromRGB(255,199,65)},
    [6] = {Color3.fromRGB(105,53,154), Color3.fromRGB(208,79,255)},
}

local rarityScale = {Common=0.90, Rare=0.95, Epic=1.00, Legendary=1.08, Mythic=1.16, Secret=1.28}

local function part(parent, name, size, color, material, localCf, kind)
    local p
    if kind == "Wedge" then p = Instance.new("WedgePart") else p = Instance.new("Part") end
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if kind == "Ball" and p:IsA("Part") then p.Shape = Enum.PartType.Ball end
    if kind == "Cylinder" and p:IsA("Part") then p.Shape = Enum.PartType.Cylinder end
    p:SetAttribute("LocalCFrame", localCf)
    p.Parent = parent
    return p
end

local function eye(parent, localCf, scale)
    return part(parent,"Eye",Vector3.new(0.22,0.28,0.12)*scale,Color3.fromRGB(20,20,25),Enum.Material.SmoothPlastic,localCf,"Ball")
end

local function classify(name)
    name = string.lower(name)
    if string.find(name,"bat") or string.find(name,"crow") or string.find(name,"hawk") or string.find(name,"owl") or string.find(name,"phoenix") or string.find(name,"griffin") then return "Winged" end
    if string.find(name,"dragon") or string.find(name,"drake") or string.find(name,"serpent") or string.find(name,"lizard") then return "Dragon" end
    if string.find(name,"golem") or string.find(name,"spirit") or string.find(name,"wisp") or string.find(name,"reaper") then return "Spirit" end
    if string.find(name,"slime") or string.find(name,"mole") or string.find(name,"spider") then return "Odd" end
    return "Beast"
end

local function addEars(model, scale, accent)
    for side = -1, 1, 2 do
        local ear = part(model,"Ear",Vector3.new(0.48,0.85,0.35)*scale,accent,Enum.Material.SmoothPlastic,CFrame.new(side*0.62*scale,0.88*scale,0)*CFrame.Angles(0,0,math.rad(side*-18)),"Wedge")
        ear:SetAttribute("Accent",true)
    end
end

local function addWings(model, scale, accent)
    for side = -1, 1, 2 do
        local wing = part(model,"Wing",Vector3.new(0.35,1.05,1.6)*scale,accent,Enum.Material.SmoothPlastic,CFrame.new(side*1.05*scale,0.10*scale,0.15*scale)*CFrame.Angles(0,math.rad(side*-25),math.rad(side*-28)),"Wedge")
        wing:SetAttribute("Accent",true)
    end
end

local function buildPet(uid, petValue)
    local cfg = Pets.Get(petValue.Value)
    if not cfg then return nil end
    local variant = petValue:GetAttribute("Variant") or "Normal"
    local colors = zoneColors[cfg.Zone] or zoneColors[1]
    local baseColor, accentColor = colors[1], colors[2]
    if variant == "Shiny" then
        baseColor = Color3.fromRGB(255,210,68)
        accentColor = Color3.fromRGB(255,247,176)
    end
    local scale = rarityScale[cfg.Rarity] or 1
    local model = Instance.new("Model")
    model.Name = cfg.Name .. "_" .. uid
    model:SetAttribute("PetUid",uid)
    model:SetAttribute("Variant",variant)
    model:SetAttribute("PetId",cfg.Id)
    model:SetAttribute("BaseHue",math.random())

    local body = part(model,"Body",Vector3.new(1.8,1.5,1.65)*scale,baseColor,Enum.Material.SmoothPlastic,CFrame.new())
    model.PrimaryPart = body
    local head = part(model,"Head",Vector3.new(1.45,1.28,1.22)*scale,baseColor,Enum.Material.SmoothPlastic,CFrame.new(0,0.35*scale,-1.05*scale))
    eye(model,CFrame.new(-0.32*scale,0.50*scale,-1.63*scale),scale)
    eye(model,CFrame.new(0.32*scale,0.50*scale,-1.63*scale),scale)

    local archetype = classify(cfg.Name)
    if archetype == "Winged" then
        addWings(model,scale,accentColor)
        local beak = part(model,"Beak",Vector3.new(0.42,0.32,0.55)*scale,accentColor,Enum.Material.SmoothPlastic,CFrame.new(0,0.24*scale,-1.78*scale),"Wedge")
        beak:SetAttribute("Accent",true)
    elseif archetype == "Dragon" then
        addWings(model,scale,accentColor)
        for i = -1, 1, 2 do
            local horn = part(model,"Horn",Vector3.new(0.28,0.65,0.28)*scale,accentColor,Enum.Material.Neon,CFrame.new(i*0.46*scale,1.04*scale,-1.08*scale)*CFrame.Angles(math.rad(-18),0,math.rad(i*14)))
            horn:SetAttribute("Accent",true)
        end
        part(model,"Tail",Vector3.new(0.45,0.45,1.55)*scale,baseColor,Enum.Material.SmoothPlastic,CFrame.new(0,-0.05*scale,1.35*scale)*CFrame.Angles(math.rad(12),0,0))
    elseif archetype == "Spirit" then
        local halo = part(model,"Halo",Vector3.new(0.22,1.6,1.6)*scale,accentColor,Enum.Material.Neon,CFrame.new(0,1.45*scale,-0.25*scale)*CFrame.Angles(0,0,math.rad(90)),"Cylinder")
        halo:SetAttribute("Accent",true)
        body.Material = Enum.Material.Neon; body.Transparency = 0.12
        head.Material = Enum.Material.Neon; head.Transparency = 0.12
    elseif archetype == "Odd" then
        for side = -1, 1, 2 do
            local limb = part(model,"Limb",Vector3.new(0.35,0.35,1.15)*scale,accentColor,Enum.Material.SmoothPlastic,CFrame.new(side*0.95*scale,-0.35*scale,0.2*scale)*CFrame.Angles(0,math.rad(side*30),0))
            limb:SetAttribute("Accent",true)
        end
    else
        addEars(model,scale,accentColor)
        local tail = part(model,"Tail",Vector3.new(0.38,0.38,1.15)*scale,accentColor,Enum.Material.SmoothPlastic,CFrame.new(0.62*scale,-0.05*scale,1.30*scale)*CFrame.Angles(math.rad(25),math.rad(-25),0))
        tail:SetAttribute("Accent",true)
    end

    if cfg.Rarity == "Mythic" or cfg.Rarity == "Secret" or variant ~= "Normal" then
        local light = Instance.new("PointLight")
        light.Color = accentColor
        light.Range = 7*scale
        light.Brightness = cfg.Rarity == "Secret" and 2.0 or 1.1
        light.Parent = body
    end

    if variant == "Rainbow" then
        for _, obj in model:GetChildren() do
            if obj:IsA("BasePart") and obj.Name ~= "Eye" then obj.Material = Enum.Material.Neon end
        end
    end

    model.Parent = rootFolder
    return model
end

local function destroyVisual(uid)
    local model = visuals[uid]
    if model then model:Destroy() end
    visuals[uid] = nil
    phaseByUid[uid] = nil
end

local function refreshVisuals()
    local pets = player:FindFirstChild("Pets")
    local equipped = player:FindFirstChild("EquippedPets")
    if not pets or not equipped then return end
    local wanted = {}
    for _, slot in equipped:GetChildren() do
        local petValue = pets:FindFirstChild(slot.Name)
        if petValue and petValue:IsA("StringValue") then
            wanted[slot.Name] = true
            local current = visuals[slot.Name]
            local variant = petValue:GetAttribute("Variant") or "Normal"
            if not current or current:GetAttribute("PetId") ~= petValue.Value or current:GetAttribute("Variant") ~= variant then
                destroyVisual(slot.Name)
                visuals[slot.Name] = buildPet(slot.Name,petValue)
                phaseByUid[slot.Name] = math.random()*math.pi*2
            end
        end
    end
    local remove = {}
    for uid in pairs(visuals) do if not wanted[uid] then table.insert(remove,uid) end end
    for _, uid in ipairs(remove) do destroyVisual(uid) end
end

local function formation(index,count)
    if count <= 1 then return Vector3.new(0,2.3,5.2) end
    local row = math.floor((index-1)/4)
    local column = (index-1)%4
    local rowCount = math.min(4,count-row*4)
    local x = (column-(rowCount-1)/2)*3.0
    local z = 4.8+row*2.8
    return Vector3.new(x,2.1+(column%2)*0.25,z)
end

local function applyModelCFrame(model,targetCf,timeNow,variant)
    if not model.PrimaryPart then return end
    local uid = model:GetAttribute("PetUid")
    local bob = math.sin(timeNow*3.2+(phaseByUid[uid] or 0))*0.32
    local pivot = targetCf*CFrame.new(0,bob,0)*CFrame.Angles(0,math.sin(timeNow*1.5)*0.12,0)
    local partIndex = 0
    for _, obj in model:GetChildren() do
        if obj:IsA("BasePart") then
            partIndex += 1
            local localCf = obj:GetAttribute("LocalCFrame")
            if typeof(localCf) == "CFrame" then obj.CFrame = pivot*localCf end
            if variant == "Rainbow" and obj.Name ~= "Eye" then
                local hue = (timeNow*0.12+(model:GetAttribute("BaseHue") or 0)+partIndex*0.035)%1
                obj.Color = Color3.fromHSV(hue,0.75,1)
            end
        end
    end
end

local function bindFolders()
    task.spawn(function()
        local pets = player:WaitForChild("Pets")
        local equipped = player:WaitForChild("EquippedPets")
        pets.ChildAdded:Connect(refreshVisuals)
        pets.ChildRemoved:Connect(refreshVisuals)
        equipped.ChildAdded:Connect(refreshVisuals)
        equipped.ChildRemoved:Connect(refreshVisuals)
        refreshVisuals()
    end)
end

bindFolders()
RunService.RenderStepped:Connect(function()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local ordered = {}
    for uid, model in pairs(visuals) do if model and model.Parent then table.insert(ordered,uid) end end
    table.sort(ordered)
    local now = os.clock()
    for index, uid in ipairs(ordered) do
        local model = visuals[uid]
        local offset = formation(index,#ordered)
        applyModelCFrame(model,root.CFrame*CFrame.new(offset),now,model:GetAttribute("Variant") or "Normal")
    end
end)

player.AncestryChanged:Connect(function(_,parent)
    if not parent and rootFolder then rootFolder:Destroy() end
end)
