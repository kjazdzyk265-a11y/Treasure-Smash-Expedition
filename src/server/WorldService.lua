local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Breakables = require(ReplicatedStorage.Shared.Breakables)
local Variants = require(ReplicatedStorage.Shared.BreakableVariants)
local Zones = require(ReplicatedStorage.Shared.Zones)

local WorldService = {}
local rng = Random.new()

local materialMap = {Wood=Enum.Material.WoodPlanks, Stone=Enum.Material.Slate, Metal=Enum.Material.Metal, Crystal=Enum.Material.Glass, Magma=Enum.Material.Neon, Void=Enum.Material.Neon}
local colorMap = {Wood=Color3.fromRGB(151,96,52), Stone=Color3.fromRGB(104,111,123), Metal=Color3.fromRGB(75,86,99), Crystal=Color3.fromRGB(83,220,255), Magma=Color3.fromRGB(255,88,37), Void=Color3.fromRGB(151,62,255)}

local function part(parent,name,size,position,color,material)
    local p=Instance.new("Part")
    p.Name=name; p.Size=size; p.Position=position; p.Anchored=true; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Studs; p.BottomSurface=Enum.SurfaceType.Inlet; p.Parent=parent
    return p
end

local function ball(parent,name,size,position,color,material)
    local p=part(parent,name,size,position,color,material)
    p.Shape=Enum.PartType.Ball
    return p
end

local function label(adornee,text,color,offset)
    local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(260,64); gui.StudsOffset=offset or Vector3.new(0,5,0); gui.AlwaysOnTop=true; gui.Adornee=adornee; gui.Parent=adornee
    local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=text; t.TextScaled=true; t.Font=Enum.Font.GothamBlack; t.TextColor3=color; t.TextStrokeTransparency=0; t.Parent=gui
end

local function beam(parent,name,a,b,width,color,material)
    local delta=b-a
    local p=part(parent,name,Vector3.new(width,width,delta.Magnitude),(a+b)/2,color,material)
    p.CFrame=CFrame.lookAt((a+b)/2,b)
    return p
end

local function bossGeometry(model,root,cfg,scale)
    local color=colorMap[cfg.Material] or root.Color
    local accent=cfg.Material=="Crystal" and Color3.fromRGB(188,104,255) or cfg.Material=="Magma" and Color3.fromRGB(255,211,71) or cfg.Material=="Void" and Color3.fromRGB(229,80,255) or cfg.Material=="Metal" and Color3.fromRGB(255,188,56) or Color3.fromRGB(255,225,92)
    local material=materialMap[cfg.Material] or Enum.Material.SmoothPlastic
    root.Size=Vector3.new(8,9,7)*scale
    for side=-1,1,2 do
        local shoulder=part(model,"BossShoulder",Vector3.new(4,4,4)*scale,root.Position+Vector3.new(side*5.2*scale,1.8*scale,0),color,material); shoulder.CanCollide=false
        local arm=part(model,"BossArm",Vector3.new(2.5,7,2.5)*scale,root.Position+Vector3.new(side*6.2*scale,-2*scale,0),color,material); arm.CanCollide=false
        local spike=part(model,"BossSpike",Vector3.new(1.2,3.5,1.2)*scale,root.Position+Vector3.new(side*4.8*scale,5.2*scale,0),accent,Enum.Material.Neon); spike.CanCollide=false
    end
    local crown=part(model,"BossCrown",Vector3.new(5.5,1.2,5.5)*scale,root.Position+Vector3.new(0,5.4*scale,0),accent,Enum.Material.Neon); crown.CanCollide=false
    local core=part(model,"BossCore",Vector3.new(2.3,2.3,0.8)*scale,root.Position+Vector3.new(0,0,-3.9*scale),accent,Enum.Material.Neon); core.CanCollide=false
    local light=Instance.new("PointLight"); light.Color=accent; light.Range=22*scale; light.Brightness=2.2; light.Parent=core
end

local function spawnBreakable(parent,kind,position,scale)
    local cfg=Breakables[kind]; if not cfg then return end
    local model=Instance.new("Model"); model.Name=kind; model:SetAttribute("BreakableType",kind); model:SetAttribute("Alive",true); model:SetAttribute("Boss",cfg.Boss==true); model:SetAttribute("Zone",cfg.Zone or 1)
    local s=scale or 1
    local root=part(model,"Root",Vector3.new(5,5,5)*s,position,colorMap[cfg.Material] or Color3.new(1,1,1),materialMap[cfg.Material] or Enum.Material.SmoothPlastic); model.PrimaryPart=root
    local variantName=cfg.Boss and "Normal" or Variants.Roll(rng); local variant=Variants.Get(variantName)
    model:SetAttribute("Variant",variantName); model:SetAttribute("MaxHealth",math.floor(cfg.MaxHealth*variant.Health+0.5)); model:SetAttribute("Health",model:GetAttribute("MaxHealth")); model:SetAttribute("Reward",math.floor(cfg.Reward*variant.Reward+0.5))
    if variant.Color then root.Color=variant.Color end
    if cfg.Material=="Crystal" or cfg.Material=="Magma" or cfg.Material=="Void" then root.Transparency=0.08 end
    if cfg.Boss then bossGeometry(model,root,cfg,s); label(root,string.upper(kind),Color3.fromRGB(255,230,85),Vector3.new(0,12,0)) elseif variantName~="Normal" then label(root,string.upper(variantName),variant.Color or Color3.new(1,1,1)) end
    model.Parent=parent; CollectionService:AddTag(model,"Breakable")
end

local function tree(parent,o,x,z)
    part(parent,"TreeTrunk",Vector3.new(3,9,3),o+Vector3.new(x,4.5,z),Color3.fromRGB(101,66,39),Enum.Material.Wood)
    ball(parent,"TreeCrown",Vector3.new(11,10,11),o+Vector3.new(x,12,z),Color3.fromRGB(53,157,64),Enum.Material.Grass)
end

local function buildGreen(parent,zone)
    local o=zone.Offset
    for _,xz in ipairs({{-68,-48},{-72,28},{68,-35},{72,35},{-58,58},{58,60}}) do tree(parent,o,xz[1],xz[2]) end
    local house=part(parent,"FarmHouse",Vector3.new(24,13,20),o+Vector3.new(-60,6.5,5),Color3.fromRGB(246,213,155),Enum.Material.WoodPlanks)
    part(parent,"HouseRoof",Vector3.new(28,3,24),house.Position+Vector3.new(0,8,0),Color3.fromRGB(174,62,48),Enum.Material.Brick)
    part(parent,"Barn",Vector3.new(28,15,22),o+Vector3.new(58,7.5,10),Color3.fromRGB(177,55,45),Enum.Material.WoodPlanks)
    for x=-80,80,16 do part(parent,"Fence",Vector3.new(12,3,1),o+Vector3.new(x,1.5,-50),Color3.fromRGB(181,122,68),Enum.Material.WoodPlanks) end
    local tower=part(parent,"WindmillTower",Vector3.new(8,28,8),o+Vector3.new(0,14,57),Color3.fromRGB(230,215,184),Enum.Material.Brick); label(tower,"WINDMILL",zone.Accent,Vector3.new(0,18,0))
    for angle=0,270,90 do local dir=Vector3.new(math.cos(math.rad(angle))*12,math.sin(math.rad(angle))*12,0); beam(parent,"WindmillBlade",tower.Position+Vector3.new(0,7,-5),tower.Position+Vector3.new(dir.X,7+dir.Y,-5),2,Color3.fromRGB(111,75,46),Enum.Material.WoodPlanks) end
end

local function buildCity(parent,zone)
    local o=zone.Offset
    part(parent,"Road",Vector3.new(150,0.6,34),o+Vector3.new(0,0.2,10),Color3.fromRGB(55,58,64),Enum.Material.Asphalt)
    for i=1,6 do
        local side=i%2==0 and -1 or 1; local x=side*(56+(i%3)*10); local z=-55+i*18
        local h=22+(i%3)*12
        local b=part(parent,"HighRise",Vector3.new(22,h,20),o+Vector3.new(x,h/2,z),Color3.fromRGB(116,125,139),Enum.Material.Concrete)
        for y=5,h-4,7 do part(parent,"WindowStrip",Vector3.new(22.2,2,0.3),b.Position+Vector3.new(0,y-h/2,-10.1),Color3.fromRGB(101,207,255),Enum.Material.Neon) end
    end
    for i=-1,1 do part(parent,"Container",Vector3.new(20,8,8),o+Vector3.new(-55,4,48+i*9),i==0 and Color3.fromRGB(237,130,45) or Color3.fromRGB(64,135,196),Enum.Material.Metal) end
    local crane=part(parent,"CraneTower",Vector3.new(5,42,5),o+Vector3.new(40,21,55),Color3.fromRGB(255,187,51),Enum.Material.Metal); label(crane,"MEGA CRANE",zone.Accent,Vector3.new(0,25,0))
    beam(parent,"CraneBoom",o+Vector3.new(40,41,55),o+Vector3.new(-8,41,55),4,Color3.fromRGB(255,187,51),Enum.Material.Metal)
    part(parent,"CraneCable",Vector3.new(0.7,19,0.7),o+Vector3.new(0,31.5,55),Color3.fromRGB(45,45,48),Enum.Material.Metal)
end

local function crystalCluster(parent,o,x,z,scale)
    for i=-1,1 do local p=part(parent,"CrystalSpire",Vector3.new(3*scale,(11+math.abs(i)*5)*scale,3*scale),o+Vector3.new(x+i*4*scale,(11+math.abs(i)*5)*scale/2,z),i==0 and Color3.fromRGB(77,226,255) or Color3.fromRGB(177,91,255),Enum.Material.Neon); p.CFrame*=CFrame.Angles(0,0,math.rad(i*12)) end
end

local function buildCrystal(parent,zone)
    local o=zone.Offset
    for z=-65,65,18 do part(parent,"CanyonWall",Vector3.new(18,22+(math.abs(z)%12),14),o+Vector3.new(-82,11,z),Color3.fromRGB(55,57,77),Enum.Material.Slate); part(parent,"CanyonWall",Vector3.new(18,20+(math.abs(z)%15),14),o+Vector3.new(82,10,z),Color3.fromRGB(55,57,77),Enum.Material.Slate) end
    for _,xz in ipairs({{-58,-38},{56,-20},{-62,25},{60,38}}) do crystalCluster(parent,o,xz[1],xz[2],1) end
    local altar=part(parent,"CathedralAltar",Vector3.new(34,4,25),o+Vector3.new(0,2,58),Color3.fromRGB(82,85,115),Enum.Material.Slate); label(altar,"CRYSTAL CATHEDRAL",zone.Accent,Vector3.new(0,12,0))
    for x=-13,13,8 do part(parent,"CathedralPillar",Vector3.new(4,25,4),o+Vector3.new(x,12.5,58),Color3.fromRGB(153,101,230),Enum.Material.Glass) end
    beam(parent,"CrystalArch",o+Vector3.new(-18,25,58),o+Vector3.new(18,25,58),3,Color3.fromRGB(78,221,255),Enum.Material.Neon)
end

local function buildForge(parent,zone)
    local o=zone.Offset
    for side=-1,1,2 do part(parent,"LavaCanal",Vector3.new(18,0.8,150),o+Vector3.new(side*70,0.2,0),Color3.fromRGB(255,72,24),Enum.Material.Neon) end
    for i=-1,1 do
        local x=i*48
        local furnace=part(parent,"Furnace",Vector3.new(24,20,20),o+Vector3.new(x,10,42),Color3.fromRGB(73,69,68),Enum.Material.Metal)
        local mouth=part(parent,"FurnaceMouth",Vector3.new(12,10,1),furnace.Position+Vector3.new(0,-2,-10.5),Color3.fromRGB(255,94,30),Enum.Material.Neon)
        local light=Instance.new("PointLight"); light.Color=mouth.Color; light.Range=18; light.Brightness=2; light.Parent=mouth
    end
    for side=-1,1,2 do local pipe=part(parent,"ForgePipe",Vector3.new(5,32,5),o+Vector3.new(side*62,16,-20),Color3.fromRGB(91,87,84),Enum.Material.Metal); beam(parent,"PipeBridge",pipe.Position+Vector3.new(0,14,0),o+Vector3.new(side*25,30,-20),4,pipe.Color,Enum.Material.Metal) end
    local forge=part(parent,"GrandForge",Vector3.new(38,6,32),o+Vector3.new(0,3,60),Color3.fromRGB(75,71,68),Enum.Material.Metal); label(forge,"GRAND FORGE",zone.Accent,Vector3.new(0,11,0))
end

local function buildSky(parent,zone)
    local o=zone.Offset
    for _,xz in ipairs({{-70,-55},{70,-48},{-73,28},{72,38},{-55,65},{55,67}}) do for i=1,3 do ball(parent,"Cloud",Vector3.new(18,8,14),o+Vector3.new(xz[1]+(i-2)*7,3,xz[2]),Color3.fromRGB(244,247,255),Enum.Material.SmoothPlastic) end end
    for side=-1,1,2 do part(parent,"SkyPlatform",Vector3.new(45,4,40),o+Vector3.new(side*57,4,20),Color3.fromRGB(224,217,192),Enum.Material.Marble); beam(parent,"SkyBridge",o+Vector3.new(side*20,5,20),o+Vector3.new(side*42,5,20),7,Color3.fromRGB(239,205,101),Enum.Material.Marble) end
    local temple=part(parent,"SunTemple",Vector3.new(44,5,36),o+Vector3.new(0,5,58),Color3.fromRGB(238,226,189),Enum.Material.Marble); label(temple,"SUN TEMPLE",zone.Accent,Vector3.new(0,13,0))
    for x=-16,16,8 do part(parent,"TempleColumn",Vector3.new(4,24,4),o+Vector3.new(x,17,58),Color3.fromRGB(246,238,211),Enum.Material.Marble) end
    ball(parent,"SunRelic",Vector3.new(9,9,9),o+Vector3.new(0,26,58),Color3.fromRGB(255,212,69),Enum.Material.Neon)
end

local function buildVoid(parent,zone)
    local o=zone.Offset
    for i=1,8 do local angle=(i/8)*math.pi*2; local x=math.cos(angle)*72; local z=math.sin(angle)*62; local ob=part(parent,"VoidObelisk",Vector3.new(5,24+(i%3)*5,5),o+Vector3.new(x,12,z),Color3.fromRGB(91,42,130),Enum.Material.Slate); part(parent,"ObeliskRune",Vector3.new(1.5,8,5.2),ob.Position+Vector3.new(0,2,-0.1),Color3.fromRGB(191,65,255),Enum.Material.Neon) end
    for step=1,5 do part(parent,"TempleStep",Vector3.new(50-step*4,2,8),o+Vector3.new(0,step,37+step*7),Color3.fromRGB(48,37,65),Enum.Material.Slate) end
    local temple=part(parent,"VoidTemple",Vector3.new(42,24,30),o+Vector3.new(0,17,72),Color3.fromRGB(45,34,62),Enum.Material.Slate); label(temple,"VOID TEMPLE",zone.Accent,Vector3.new(0,18,0))
    local portal=part(parent,"VoidPortal",Vector3.new(18,22,2),o+Vector3.new(0,17,56),Color3.fromRGB(185,60,255),Enum.Material.Neon); portal.Transparency=0.2
    part(parent,"FinalArena",Vector3.new(70,2,55),o+Vector3.new(0,1,50),Color3.fromRGB(54,42,70),Enum.Material.Slate)
end

local identityBuilders={buildGreen,buildCity,buildCrystal,buildForge,buildSky,buildVoid}

local function buildZone(world,zone)
    local folder=Instance.new("Folder"); folder.Name=zone.Name:gsub(" ",""); folder:SetAttribute("ZoneId",zone.Id); folder.Parent=world
    part(folder,"Ground",zone.Size,zone.Offset+Vector3.new(0,-1,0),zone.Ground,zone.Id==1 and Enum.Material.Grass or Enum.Material.SmoothPlastic)
    part(folder,"MainPath",Vector3.new(24,1,150),zone.Offset+Vector3.new(0,0.05,0),zone.Accent,Enum.Material.SmoothPlastic)
    identityBuilders[zone.Id](folder,zone)
    for i=1,28 do local side=i%2==0 and 1 or -1; local z=-62+(i%14)*9; local x=side*(20+((i*7)%4)*8); spawnBreakable(folder,zone.Breakables[(i-1)%#zone.Breakables+1],zone.Offset+Vector3.new(x,2.5,z)) end
    spawnBreakable(folder,zone.Boss,zone.Offset+Vector3.new(0,7,70),2.8)

    local egg=part(folder,"EggStation",Vector3.new(10,8,10),zone.Offset+Vector3.new(-28,4,-68),zone.Accent,Enum.Material.Neon); egg:SetAttribute("EggId",zone.Egg); label(egg,"EGG",Color3.new(1,1,1))
    local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Open Egg"; prompt.ObjectText=zone.Name.." Egg"; prompt.MaxActivationDistance=12; prompt.HoldDuration=0; prompt:SetAttribute("EggId",zone.Egg); prompt.Parent=egg; CollectionService:AddTag(prompt,"EggPrompt")
    local shop=part(folder,"UpgradeStation",Vector3.new(12,6,12),zone.Offset+Vector3.new(28,3,-68),Color3.fromRGB(74,220,105),Enum.Material.Neon); label(shop,"UPGRADES",Color3.new(1,1,1))
    local sell=part(folder,"SellPad",Vector3.new(16,1,12),zone.Offset+Vector3.new(-48,0.6,-68),Color3.fromRGB(255,210,55),Enum.Material.Neon); sell:SetAttribute("SellPad",true); label(sell,"SELL",Color3.new(1,1,1))
    local checkpoint=part(folder,"Checkpoint",Vector3.new(14,1,14),zone.Offset+Vector3.new(0,0.6,-70),zone.Accent,Enum.Material.Neon); checkpoint:SetAttribute("ZoneId",zone.Id); label(checkpoint,"CHECKPOINT",Color3.new(1,1,1),Vector3.new(0,3,0))
    if zone.Id<#Zones then local gate=part(folder,"Gate",Vector3.new(6,18,40),zone.Offset+Vector3.new(95,9,0),zone.Accent,Enum.Material.Neon); gate:SetAttribute("UnlockZone",zone.Id+1); gate:SetAttribute("UnlockCost",Zones[zone.Id+1].UnlockCost); label(gate,"ZONE "..(zone.Id+1),Color3.new(1,1,1),Vector3.new(0,12,0)) end
end

function WorldService.Build()
    local old=workspace:FindFirstChild("GeneratedWorld"); if old then old:Destroy() end
    local world=Instance.new("Folder"); world.Name="GeneratedWorld"; world.Parent=workspace
    for _,zone in ipairs(Zones) do buildZone(world,zone) end
    local spawn=Instance.new("SpawnLocation"); spawn.Name="GreenValleySpawn"; spawn.Size=Vector3.new(10,1,10); spawn.Position=Vector3.new(0,1,-78); spawn.Anchored=true; spawn.Neutral=true; spawn.Parent=world
end

return WorldService
