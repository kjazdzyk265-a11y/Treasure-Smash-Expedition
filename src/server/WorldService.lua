local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Breakables = require(ReplicatedStorage.Shared.Breakables)
local Variants = require(ReplicatedStorage.Shared.BreakableVariants)
local Zones = require(ReplicatedStorage.Shared.Zones)

local WorldService = {}
local rng = Random.new()

local materialMap = {Wood=Enum.Material.WoodPlanks, Stone=Enum.Material.Slate, Metal=Enum.Material.Metal, Crystal=Enum.Material.Glass, Magma=Enum.Material.Neon, Void=Enum.Material.Neon}
local colorMap = {Wood=Color3.fromRGB(151,96,52), Stone=Color3.fromRGB(104,111,123), Metal=Color3.fromRGB(75,86,99), Crystal=Color3.fromRGB(83,220,255), Magma=Color3.fromRGB(255,88,37), Void=Color3.fromRGB(151,62,255)}

local function part(parent, name, size, position, color, material)
    local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=position; p.Anchored=true; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Studs; p.BottomSurface=Enum.SurfaceType.Inlet; p.Parent=parent; return p
end

local function label(adornee, text, color)
    local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(240,60); gui.StudsOffset=Vector3.new(0,5,0); gui.AlwaysOnTop=true; gui.Adornee=adornee; gui.Parent=adornee
    local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=text; t.TextScaled=true; t.Font=Enum.Font.GothamBlack; t.TextColor3=color; t.TextStrokeTransparency=0; t.Parent=gui
end

local function spawnBreakable(parent, kind, position, scale)
    local cfg=Breakables[kind]; if not cfg then return end
    local model=Instance.new("Model"); model.Name=kind; model:SetAttribute("BreakableType",kind); model:SetAttribute("Alive",true); model:SetAttribute("Boss",cfg.Boss==true); model:SetAttribute("Zone",cfg.Zone or 1)
    local s=scale or 1; local root=part(model,"Root",Vector3.new(5,5,5)*s,position,colorMap[cfg.Material] or Color3.new(1,1,1),materialMap[cfg.Material] or Enum.Material.SmoothPlastic); model.PrimaryPart=root
    local variantName=cfg.Boss and "Normal" or Variants.Roll(rng); local variant=Variants.Get(variantName)
    model:SetAttribute("Variant",variantName); model:SetAttribute("MaxHealth",math.floor(cfg.MaxHealth*variant.Health+0.5)); model:SetAttribute("Health",model:GetAttribute("MaxHealth")); model:SetAttribute("Reward",math.floor(cfg.Reward*variant.Reward+0.5))
    if variant.Color then root.Color=variant.Color end
    if cfg.Material=="Crystal" or cfg.Material=="Magma" or cfg.Material=="Void" then root.Transparency=0.08 end
    if cfg.Boss then label(root,string.upper(kind),Color3.fromRGB(255,230,85)) elseif variantName~="Normal" then label(root,string.upper(variantName),variant.Color or Color3.new(1,1,1)) end
    model.Parent=parent; CollectionService:AddTag(model,"Breakable")
end

local function buildLandmark(zoneFolder, zone)
    local o=zone.Offset; local base=part(zoneFolder,"LandmarkBase",Vector3.new(28,4,28),o+Vector3.new(0,2,55),zone.Accent,Enum.Material.SmoothPlastic); label(base,zone.Landmark,zone.Accent)
    for i=1,4 do local x=(i<=2 and -1 or 1)*9; local z=(i%2==0 and -1 or 1)*9; part(zoneFolder,"LandmarkColumn",Vector3.new(4,18+i*2,4),o+Vector3.new(x,11+i,z+55),zone.Accent,Enum.Material.SmoothPlastic) end
end

local function buildDecor(zoneFolder, zone)
    local o=zone.Offset
    for i=1,14 do
        local side=i%2==0 and -1 or 1; local x=side*(55+(i%3)*7); local z=-66+i*9
        if zone.Id==1 then part(zoneFolder,"TreeTrunk",Vector3.new(3,8,3),o+Vector3.new(x,4,z),Color3.fromRGB(102,67,39),Enum.Material.Wood); part(zoneFolder,"TreeCrown",Vector3.new(10,9,10),o+Vector3.new(x,11,z),Color3.fromRGB(49,153,61),Enum.Material.Grass)
        elseif zone.Id==2 then part(zoneFolder,"Building",Vector3.new(18,18+(i%4)*7,18),o+Vector3.new(x,9,z),Color3.fromRGB(125,132,142),Enum.Material.Concrete)
        elseif zone.Id==3 then part(zoneFolder,"CrystalDecor",Vector3.new(4,14+(i%4)*3,4),o+Vector3.new(x,7,z),zone.Accent,Enum.Material.Neon)
        elseif zone.Id==4 then part(zoneFolder,"ForgePipe",Vector3.new(5,14,5),o+Vector3.new(x,7,z),Color3.fromRGB(89,84,80),Enum.Material.Metal)
        elseif zone.Id==5 then part(zoneFolder,"RuinColumn",Vector3.new(5,16+(i%3)*4,5),o+Vector3.new(x,8,z),Color3.fromRGB(238,225,181),Enum.Material.Marble)
        else part(zoneFolder,"VoidObelisk",Vector3.new(5,18+(i%4)*3,5),o+Vector3.new(x,9,z),zone.Accent,Enum.Material.Neon) end
    end
end

local function buildZone(world, zone)
    local folder=Instance.new("Folder"); folder.Name=zone.Name:gsub(" ",""); folder:SetAttribute("ZoneId",zone.Id); folder.Parent=world
    part(folder,"Ground",zone.Size,zone.Offset+Vector3.new(0,-1,0),zone.Ground,zone.Id==1 and Enum.Material.Grass or Enum.Material.SmoothPlastic)
    part(folder,"MainPath",Vector3.new(24,1,150),zone.Offset+Vector3.new(0,0.05,0),zone.Accent,Enum.Material.SmoothPlastic); buildDecor(folder,zone); buildLandmark(folder,zone)
    for i=1,28 do local side=i%2==0 and 1 or -1; local z=-62+(i%14)*9; local x=side*(20+((i*7)%4)*8); spawnBreakable(folder,zone.Breakables[(i-1)%#zone.Breakables+1],zone.Offset+Vector3.new(x,2.5,z)) end
    spawnBreakable(folder,zone.Boss,zone.Offset+Vector3.new(0,7,70),2.8)
    local egg=part(folder,"EggStation",Vector3.new(10,8,10),zone.Offset+Vector3.new(-28,4,-68),zone.Accent,Enum.Material.Neon); egg:SetAttribute("EggId",zone.Egg); label(egg,"EGG",Color3.new(1,1,1)); local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Open Egg"; prompt.ObjectText=zone.Name.." Egg"; prompt.MaxActivationDistance=12; prompt.Parent=egg
    local shop=part(folder,"UpgradeStation",Vector3.new(12,6,12),zone.Offset+Vector3.new(28,3,-68),Color3.fromRGB(74,220,105),Enum.Material.Neon); label(shop,"UPGRADES",Color3.new(1,1,1))
    local sell=part(folder,"SellPad",Vector3.new(16,1,12),zone.Offset+Vector3.new(-48,0.6,-68),Color3.fromRGB(255,210,55),Enum.Material.Neon); sell:SetAttribute("SellPad",true); label(sell,"SELL",Color3.new(1,1,1))
    local checkpoint=part(folder,"Checkpoint",Vector3.new(14,1,14),zone.Offset+Vector3.new(0,0.6,-70),zone.Accent,Enum.Material.Neon); checkpoint:SetAttribute("ZoneId",zone.Id)
    if zone.Id<#Zones then local gate=part(folder,"Gate",Vector3.new(6,18,40),zone.Offset+Vector3.new(95,9,0),zone.Accent,Enum.Material.Neon); gate:SetAttribute("UnlockZone",zone.Id+1); gate:SetAttribute("UnlockCost",Zones[zone.Id+1].UnlockCost); label(gate,"ZONE "..(zone.Id+1),Color3.new(1,1,1)) end
end

function WorldService.Build()
    local old=workspace:FindFirstChild("GeneratedWorld"); if old then old:Destroy() end
    local world=Instance.new("Folder"); world.Name="GeneratedWorld"; world.Parent=workspace
    for _,zone in ipairs(Zones) do buildZone(world,zone) end
    local spawn=Instance.new("SpawnLocation"); spawn.Name="GreenValleySpawn"; spawn.Size=Vector3.new(10,1,10); spawn.Position=Vector3.new(0,1,-78); spawn.Anchored=true; spawn.Neutral=true; spawn.Parent=world
end

return WorldService
