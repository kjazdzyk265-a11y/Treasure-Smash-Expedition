local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Pets = require(ReplicatedStorage.Shared.Pets)
local Eggs = require(ReplicatedStorage.Shared.EggConfig)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local hatchRemote = remotes:WaitForChild("HatchPet") :: RemoteEvent
local actionRemote = remotes:WaitForChild("PetAction") :: RemoteEvent
local fuseRemote = remotes:WaitForChild("FusePets") :: RemoteEvent
local feedbackRemote = remotes:WaitForChild("PetFeedback") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "PetUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function style(object: GuiObject, radius: number?)
    object.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = object
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 4
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Parent = object
end

local function button(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3): TextButton
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextStrokeTransparency = 0
    b.TextScaled = true
    b.Font = Enum.Font.GothamBlack
    b.Parent = parent
    style(b)
    return b
end

local openButton = button(gui, "PETS", UDim2.fromOffset(145, 58), UDim2.fromOffset(20, 165), Color3.fromRGB(245, 113, 203))
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 520, 0, 560)
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -20, 0.5, 20)
panel.BackgroundColor3 = Color3.fromRGB(40, 45, 70)
panel.Visible = false
panel.Parent = gui
style(panel, 18)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 0, 52)
title.Position = UDim2.fromOffset(18, 10)
title.BackgroundTransparency = 1
title.Text = "PETS & EGGS"
title.TextColor3 = Color3.new(1,1,1)
title.TextStrokeTransparency = 0
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local closeButton = button(panel, "X", UDim2.fromOffset(48,48), UDim2.new(1,-60,0,10), Color3.fromRGB(235,72,72))
local hatchButton = button(panel, "HATCH GREEN EGG • 120", UDim2.new(1,-36,0,58), UDim2.fromOffset(18,72), Color3.fromRGB(74,205,98))
local bestButton = button(panel, "EQUIP BEST", UDim2.new(0.48,-12,0,48), UDim2.fromOffset(18,140), Color3.fromRGB(72,160,240))

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(0.52,-16,0,48)
countLabel.Position = UDim2.new(0.48,12,0,140)
countLabel.BackgroundTransparency = 1
countLabel.TextColor3 = Color3.new(1,1,1)
countLabel.TextStrokeTransparency = 0
countLabel.TextScaled = true
countLabel.Font = Enum.Font.GothamBold
countLabel.Text = "0 / 3 EQUIPPED"
countLabel.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1,-36,0,245)
list.Position = UDim2.fromOffset(18,198)
list.BackgroundColor3 = Color3.fromRGB(30,34,54)
list.BorderSizePixel = 0
list.ScrollBarThickness = 8
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
style(list, 12)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,7)
layout.Parent = list

local selected: StringValue? = nil
local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1,-36,0,42)
selectedLabel.Position = UDim2.fromOffset(18,451)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "SELECT A PET"
selectedLabel.TextColor3 = Color3.new(1,1,1)
selectedLabel.TextStrokeTransparency = 0
selectedLabel.TextScaled = true
selectedLabel.Font = Enum.Font.GothamBold
selectedLabel.Parent = panel

local equipButton = button(panel, "EQUIP", UDim2.new(0.24,-8,0,48), UDim2.new(0,18,1,-58), Color3.fromRGB(74,176,255))
local lockButton = button(panel, "LOCK", UDim2.new(0.24,-8,0,48), UDim2.new(0.25,8,1,-58), Color3.fromRGB(244,174,62))
local deleteButton = button(panel, "DELETE", UDim2.new(0.24,-8,0,48), UDim2.new(0.5,0,1,-58), Color3.fromRGB(225,72,72))
local fuseButton = button(panel, "FUSE x5", UDim2.new(0.24,-8,0,48), UDim2.new(0.75,-8,1,-58), Color3.fromRGB(158,88,235))

local reveal = Instance.new("TextLabel")
reveal.Size = UDim2.fromOffset(420,170)
reveal.AnchorPoint = Vector2.new(0.5,0.5)
reveal.Position = UDim2.fromScale(0.5,0.42)
reveal.BackgroundColor3 = Color3.fromRGB(54,61,90)
reveal.TextColor3 = Color3.new(1,1,1)
reveal.TextStrokeTransparency = 0
reveal.TextScaled = true
reveal.TextWrapped = true
reveal.Font = Enum.Font.GothamBlack
reveal.Visible = false
reveal.ZIndex = 30
reveal.Parent = gui
style(reveal, 24)

local petsFolder = player:WaitForChild("Pets")
local equippedFolder = player:WaitForChild("EquippedPets")

local function refreshSelection()
    if not selected or not selected.Parent then
        selected = nil
        selectedLabel.Text = "SELECT A PET"
        return
    end
    local cfg = Pets.Get(selected.Value)
    local variant = selected:GetAttribute("Variant") or "Normal"
    selectedLabel.Text = string.upper(variant .. " " .. cfg.Name .. " • " .. cfg.Rarity)
    lockButton.Text = selected:GetAttribute("Locked") == true and "UNLOCK" or "LOCK"
    equipButton.Text = equippedFolder:FindFirstChild(selected.Name) and "UNEQUIP" or "EQUIP"
end

local function refreshList()
    for _, child in list:GetChildren() do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local entries = {}
    for _, pet in petsFolder:GetChildren() do
        if pet:IsA("StringValue") then table.insert(entries, pet) end
    end
    table.sort(entries, function(a,b)
        return Pets.GetEffectivePower(a.Value, a:GetAttribute("Variant")) > Pets.GetEffectivePower(b.Value, b:GetAttribute("Variant"))
    end)
    for _, pet in entries do
        local cfg = Pets.Get(pet.Value)
        local variant = pet:GetAttribute("Variant") or "Normal"
        local equipped = equippedFolder:FindFirstChild(pet.Name) ~= nil
        local text = string.format("%s%s %s  •  %.1fx  •  %s", equipped and "✓ " or "", variant ~= "Normal" and (variant .. " ") or "", cfg.Name, Pets.GetEffectivePower(pet.Value, variant), cfg.Rarity)
        local row = button(list, text, UDim2.new(1,-10,0,48), UDim2.new(), Color3.fromRGB(82,88,125))
        row.LayoutOrder = -math.floor(Pets.GetEffectivePower(pet.Value, variant) * 100)
        row.Activated:Connect(function()
            selected = pet
            refreshSelection()
        end)
    end
    countLabel.Text = string.format("%d / %d EQUIPPED", #equippedFolder:GetChildren(), player:GetAttribute("PetEquipLimit") or 3)
    refreshSelection()
end

openButton.Activated:Connect(function()
    panel.Visible = not panel.Visible
    refreshList()
end)
closeButton.Activated:Connect(function() panel.Visible = false end)
hatchButton.Activated:Connect(function() hatchRemote:FireServer("GreenEgg") end)
bestButton.Activated:Connect(function() actionRemote:FireServer("EquipBest") end)
equipButton.Activated:Connect(function() if selected then actionRemote:FireServer("Equip", selected.Name) end end)
lockButton.Activated:Connect(function() if selected then actionRemote:FireServer("Lock", selected.Name) end end)
deleteButton.Activated:Connect(function() if selected then actionRemote:FireServer("Delete", selected.Name) end end)
fuseButton.Activated:Connect(function()
    if selected then fuseRemote:FireServer(selected.Value, selected:GetAttribute("Variant") or "Normal") end
end)

petsFolder.ChildAdded:Connect(refreshList)
petsFolder.ChildRemoved:Connect(refreshList)
equippedFolder.ChildAdded:Connect(refreshList)
equippedFolder.ChildRemoved:Connect(refreshList)
player:GetAttributeChangedSignal("PetEquipLimit"):Connect(refreshList)

feedbackRemote.OnClientEvent:Connect(function(success, kind, uid, petId, petName, rarityOrVariant, power)
    if success and (kind == "HATCH" or kind == "FUSED") then
        reveal.Visible = true
        reveal.Size = UDim2.fromOffset(100,100)
        reveal.Text = kind == "HATCH" and "EGG..." or "FUSING..."
        TweenService:Create(reveal, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(420,170), Rotation = 8}):Play()
        task.wait(1.1)
        reveal.Rotation = -5
        task.wait(0.8)
        reveal.Rotation = 0
        local variant = kind == "FUSED" and tostring(rarityOrVariant) or "Normal"
        local cfg = Pets.Get(petId)
        reveal.Text = string.format("%s\n%s\n%s • %.1fx", kind == "HATCH" and "YOU HATCHED!" or "FUSION COMPLETE!", variant ~= "Normal" and (variant .. " " .. petName) or petName, cfg and cfg.Rarity or tostring(rarityOrVariant), tonumber(power) or 0)
        task.wait(1.1)
        reveal.Visible = false
    elseif not success then
        reveal.Visible = true
        reveal.Text = tostring(kind)
        reveal.Size = UDim2.fromOffset(360,100)
        task.delay(1.1, function() reveal.Visible = false end)
    end
    refreshList()
end)

refreshList()
