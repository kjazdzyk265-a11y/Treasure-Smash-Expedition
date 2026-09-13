local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Tools = require(ReplicatedStorage.Shared.Tools)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local smashRemote = remotes:WaitForChild("SmashRequest")
local feedbackRemote = remotes:WaitForChild("SmashFeedback")
local purchaseToolRemote = remotes:WaitForChild("PurchaseTool")
local purchaseUpgradeRemote = remotes:WaitForChild("PurchaseUpgrade")
local progressionFeedback = remotes:WaitForChild("ProgressionFeedback")
local backpackFeedback = remotes:WaitForChild("BackpackFeedback")

local gui=Instance.new("ScreenGui"); gui.Name="TreasureSmashHUD"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local function style(o,r) o.BorderSizePixel=0; local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 14); c.Parent=o; local s=Instance.new("UIStroke"); s.Thickness=4; s.Color=Color3.new(); s.Parent=o end
local function label(parent,text,size,pos,bg)
    local x=Instance.new("TextLabel"); x.Size=size; x.Position=pos; x.BackgroundTransparency=bg and 0 or 1; if bg then x.BackgroundColor3=bg end; x.TextColor3=Color3.new(1,1,1); x.TextStrokeTransparency=0; x.TextScaled=true; x.Font=Enum.Font.GothamBlack; x.Text=text; x.Parent=parent; if bg then style(x) end; return x
end
local function fmt(v) if v>=1e9 then return string.format("%.1fB",v/1e9) elseif v>=1e6 then return string.format("%.1fM",v/1e6) elseif v>=1e3 then return string.format("%.1fK",v/1e3) end return tostring(math.floor(v)) end

local coins=label(gui,"COINS  0",UDim2.fromOffset(220,54),UDim2.new(.5,-110,1,-72),Color3.fromRGB(255,193,36))
local backpack=label(gui,"BACKPACK  0/20",UDim2.fromOffset(245,48),UDim2.new(.5,-122,1,-126),Color3.fromRGB(64,157,232))
local power=label(gui,"POWER  1",UDim2.fromOffset(220,48),UDim2.new(.5,-110,0,18),Color3.fromRGB(70,176,255))
local toolLabel=label(gui,"WOODEN HAMMER",UDim2.fromOffset(350,38),UDim2.new(.5,-175,0,74))
local hint=label(gui,"SMASH → FILL BACKPACK → SELL → UPGRADE",UDim2.fromOffset(470,38),UDim2.new(.5,-235,0,116))

local shopButton=Instance.new("TextButton"); shopButton.Size=UDim2.fromOffset(145,58); shopButton.Position=UDim2.fromOffset(20,95); shopButton.BackgroundColor3=Color3.fromRGB(74,220,105); shopButton.Text="SHOP"; shopButton.TextScaled=true; shopButton.Font=Enum.Font.GothamBlack; shopButton.TextColor3=Color3.new(1,1,1); shopButton.TextStrokeTransparency=0; shopButton.Parent=gui; style(shopButton)
local panel=Instance.new("Frame"); panel.Size=UDim2.fromOffset(430,520); panel.Position=UDim2.new(0,20,.5,-235); panel.BackgroundColor3=Color3.fromRGB(38,45,68); panel.Visible=false; panel.Parent=gui; style(panel,18)
label(panel,"TOOLS & UPGRADES",UDim2.new(1,-70,0,58),UDim2.fromOffset(20,8))
local close=Instance.new("TextButton"); close.Size=UDim2.fromOffset(48,48); close.Position=UDim2.new(1,-58,0,10); close.BackgroundColor3=Color3.fromRGB(239,78,78); close.Text="X"; close.TextScaled=true; close.Font=Enum.Font.GothamBlack; close.TextColor3=Color3.new(1,1,1); close.Parent=panel; style(close,12)
local nextToolInfo=label(panel,"",UDim2.new(1,-30,0,64),UDim2.fromOffset(15,78))
local buyTool=Instance.new("TextButton"); buyTool.Size=UDim2.new(1,-30,0,58); buyTool.Position=UDim2.fromOffset(15,146); buyTool.BackgroundColor3=Color3.fromRGB(255,187,47); buyTool.Text="BUY NEXT TOOL"; buyTool.TextScaled=true; buyTool.Font=Enum.Font.GothamBlack; buyTool.TextColor3=Color3.new(1,1,1); buyTool.Parent=panel; style(buyTool,12)
local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-30,0,250); scroll.Position=UDim2.fromOffset(15,250); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(); scroll.Parent=panel; local list=Instance.new("UIListLayout"); list.Padding=UDim.new(0,8); list.Parent=scroll
local upgradeButtons={}; for _,name in ipairs({"Damage","AttackSpeed","Range","MovementSpeed","Luck","CritChance","CoinGain","BackpackSlots","PetSlots"}) do local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-8,0,50); b.BackgroundColor3=Color3.fromRGB(98,92,230); b.TextColor3=Color3.new(1,1,1); b.TextScaled=true; b.Font=Enum.Font.GothamBold; b.Parent=scroll; style(b,10); upgradeButtons[name]=b; b.Activated:Connect(function() purchaseUpgradeRemote:FireServer(name) end) end
local toast=label(gui,"",UDim2.fromOffset(380,64),UDim2.new(.5,-190,.34,0),Color3.fromRGB(42,50,70)); toast.Visible=false; toast.ZIndex=20

local function refresh()
    local stats=player:FindFirstChild("leaderstats"); local c=stats and stats:FindFirstChild("Coins"); local p=stats and stats:FindFirstChild("Power")
    if c then coins.Text="COINS  "..fmt(c.Value) end; if p then power.Text="POWER  "..fmt(p.Value) end
    backpack.Text="BACKPACK  "..fmt(player:GetAttribute("BackpackLoot") or 0).."/"..fmt(player:GetAttribute("BackpackCapacity") or 20)
    local toolIndex=math.clamp(player:GetAttribute("ToolIndex") or 1,1,#Tools); local tool=Tools[toolIndex]; toolLabel.Text=string.upper(tool.Name).."  •  DMG "..fmt(player:GetAttribute("SmashDamage") or tool.Damage)
    local nextTool=Tools[toolIndex+1]; if nextTool then nextToolInfo.Text=string.upper(nextTool.Name).."  DMG "..fmt(nextTool.Damage).."  COST "..fmt(nextTool.Price); buyTool.Text="BUY FOR "..fmt(nextTool.Price); buyTool.Active=true else nextToolInfo.Text="MAX TOOL"; buyTool.Text="MAX TOOL"; buyTool.Active=false end
    local folder=player:FindFirstChild("Upgrades"); for name,b in pairs(upgradeButtons) do local v=folder and folder:FindFirstChild(name); local lv=v and v.Value or 0; local cfg=Upgrades[name]; local cost=Upgrades.GetCost(name,lv); b.Text=lv>=cfg.MaxLevel and (name.." LV."..lv.." MAX") or (name.." LV."..lv.." • "..fmt(cost or 0)) end
end

task.spawn(function() local stats=player:WaitForChild("leaderstats"); stats:WaitForChild("Coins"):GetPropertyChangedSignal("Value"):Connect(refresh); stats:WaitForChild("Power"):GetPropertyChangedSignal("Value"):Connect(refresh); local upgrades=player:WaitForChild("Upgrades"); for _,v in upgrades:GetChildren() do if v:IsA("IntValue") then v:GetPropertyChangedSignal("Value"):Connect(refresh) end end; refresh() end)
for _,a in ipairs({"ToolIndex","SmashDamage","BackpackLoot","BackpackCapacity"}) do player:GetAttributeChangedSignal(a):Connect(refresh) end
shopButton.Activated:Connect(function() panel.Visible=not panel.Visible; refresh() end); close.Activated:Connect(function() panel.Visible=false end); buyTool.Activated:Connect(function() purchaseToolRemote:FireServer() end)

local function raycastTarget(pos)
    local camera=workspace.CurrentCamera; if not camera then return nil end
    local ray=camera:ViewportPointToRay(pos.X,pos.Y); local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances=player.Character and {player.Character} or {}
    local hit=workspace:Raycast(ray.Origin,ray.Direction*180,params); return hit and hit.Instance or nil
end
UserInputService.InputBegan:Connect(function(input,processed) if processed or panel.Visible then return end; if input.UserInputType==Enum.UserInputType.MouseButton1 then local t=raycastTarget(UserInputService:GetMouseLocation()); if t then smashRemote:FireServer(t) end elseif input.UserInputType==Enum.UserInputType.Touch then local t=raycastTarget(Vector2.new(input.Position.X,input.Position.Y)); if t then smashRemote:FireServer(t) end end end)

local hpBars={}
local function hpBar(model,maxHealth)
    local guiBar=hpBars[model]; if guiBar and guiBar.Parent then return guiBar end
    guiBar=Instance.new("BillboardGui"); guiBar.Size=UDim2.fromOffset(180,44); guiBar.StudsOffset=Vector3.new(0,5.8,0); guiBar.AlwaysOnTop=true; guiBar.Adornee=model.PrimaryPart; guiBar.Parent=gui
    local back=Instance.new("Frame"); back.Size=UDim2.new(1,0,0,14); back.Position=UDim2.new(0,0,1,-16); back.BackgroundColor3=Color3.fromRGB(35,35,40); back.Parent=guiBar; style(back,7)
    local fill=Instance.new("Frame"); fill.Name="Fill"; fill.Size=UDim2.fromScale(1,1); fill.BackgroundColor3=Color3.fromRGB(79,224,91); fill.Parent=back; local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=fill
    hpBars[model]=guiBar; model.AncestryChanged:Connect(function(_,parent) if not parent and guiBar then guiBar:Destroy(); hpBars[model]=nil end end); return guiBar
end

local function impact(model,damage,critical,newHealth,maxHealth,variant)
    if not model.PrimaryPart then return end
    local root=model.PrimaryPart
    local bar=hpBar(model,maxHealth or model:GetAttribute("MaxHealth") or 1); local fill=bar:FindFirstChildWhichIsA("Frame"):FindFirstChild("Fill"); fill.Size=UDim2.fromScale(math.clamp((newHealth or 0)/(maxHealth or 1),0,1),1)
    local d=Instance.new("BillboardGui"); d.Size=UDim2.fromOffset(180,72); d.StudsOffset=Vector3.new(0,4,0); d.AlwaysOnTop=true; d.Adornee=root; d.Parent=gui; local txt=label(d,critical and ("CRIT! -"..math.floor(damage)) or ("-"..math.floor(damage)),UDim2.fromScale(1,1),UDim2.new()); txt.TextColor3=critical and Color3.fromRGB(255,231,65) or Color3.new(1,1,1); TweenService:Create(d,TweenInfo.new(.38,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{StudsOffset=Vector3.new(0,7,0)}):Play(); task.delay(.42,function() d:Destroy() end)
    local h=Instance.new("Highlight"); h.FillTransparency=.55; h.OutlineTransparency=1; h.Parent=model; task.delay(.09,function() h:Destroy() end)
    local emitter=Instance.new("ParticleEmitter"); emitter.Rate=0; emitter.Lifetime=NumberRange.new(.15,.28); emitter.Speed=NumberRange.new(7,14); emitter.SpreadAngle=Vector2.new(180,180); emitter.Parent=root; emitter:Emit(variant~="Normal" and 18 or 10); task.delay(.4,function() emitter:Destroy() end)
    local camera=workspace.CurrentCamera; if camera then local original=camera.FieldOfView; camera.FieldOfView=original+2.4; TweenService:Create(camera,TweenInfo.new(.13),{FieldOfView=original}):Play() end
    local original=root.CFrame; root.CFrame=original*CFrame.Angles(0,0,math.rad(2)); task.delay(.05,function() if root.Parent then root.CFrame=original*CFrame.Angles(0,0,math.rad(-2)); task.wait(.05); if root.Parent then root.CFrame=original end end end)
end
feedbackRemote.OnClientEvent:Connect(impact)

local function showToast(success,message) toast.Text=tostring(message); toast.BackgroundColor3=success and Color3.fromRGB(65,188,92) or Color3.fromRGB(220,74,74); toast.Visible=true; toast.TextTransparency=0; task.delay(1.1,function() if toast.Parent then toast.Visible=false end end) end
progressionFeedback.OnClientEvent:Connect(showToast); backpackFeedback.OnClientEvent:Connect(showToast)
refresh()
