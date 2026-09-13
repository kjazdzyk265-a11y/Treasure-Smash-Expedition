local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local tracked = {}

local function makeBar(model)
    if tracked[model] or not model.PrimaryPart then return end
    if model:GetAttribute("Boss") ~= true then return end
    local root = model.PrimaryPart
    local gui = Instance.new("BillboardGui")
    gui.Name = "BossWorldBar"
    gui.Size = UDim2.fromOffset(360,88)
    gui.StudsOffset = Vector3.new(0,13,0)
    gui.AlwaysOnTop = true
    gui.Adornee = root
    gui.Parent = root

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,42)
    title.BackgroundTransparency = 1
    title.Text = string.upper(model.Name)
    title.TextColor3 = Color3.fromRGB(255,231,81)
    title.TextStrokeTransparency = 0
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.Parent = gui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,-20,0,24)
    bg.Position = UDim2.fromOffset(10,48)
    bg.BackgroundColor3 = Color3.fromRGB(22,22,25)
    bg.BorderSizePixel = 0
    bg.Parent = gui
    local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(1,0); bgCorner.Parent = bg

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1,1)
    fill.BackgroundColor3 = Color3.fromRGB(235,72,62)
    fill.BorderSizePixel = 0
    fill.Parent = bg
    local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(1,0); fillCorner.Parent = fill

    local text = Instance.new("TextLabel")
    text.Name = "HPText"
    text.Size = UDim2.fromScale(1,1)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1,1,1)
    text.TextStrokeTransparency = 0
    text.TextScaled = true
    text.Font = Enum.Font.GothamBlack
    text.Parent = bg

    local highlight = Instance.new("Highlight")
    highlight.Name = "BossPhaseHighlight"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0.45
    highlight.OutlineColor = Color3.fromRGB(255,198,73)
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model

    local function refresh()
        if not model.Parent then return end
        local health = tonumber(model:GetAttribute("Health")) or 0
        local maxHealth = math.max(1,tonumber(model:GetAttribute("MaxHealth")) or 1)
        local ratio = math.clamp(health/maxHealth,0,1)
        TweenService:Create(fill,TweenInfo.new(0.10,Enum.EasingStyle.Quad),{Size=UDim2.fromScale(ratio,1)}):Play()
        text.Text = string.format("%d / %d",math.floor(health),math.floor(maxHealth))
        gui.Enabled = model:GetAttribute("Alive") == true
        if ratio <= 0.25 then
            fill.BackgroundColor3 = Color3.fromRGB(255,72,192)
            highlight.OutlineColor = Color3.fromRGB(255,72,192)
            highlight.FillTransparency = 0.84
        elseif ratio <= 0.50 then
            fill.BackgroundColor3 = Color3.fromRGB(255,129,48)
            highlight.OutlineColor = Color3.fromRGB(255,129,48)
            highlight.FillTransparency = 0.92
        else
            fill.BackgroundColor3 = Color3.fromRGB(235,72,62)
            highlight.FillTransparency = 1
        end
    end

    local conns = {
        model:GetAttributeChangedSignal("Health"):Connect(refresh),
        model:GetAttributeChangedSignal("MaxHealth"):Connect(refresh),
        model:GetAttributeChangedSignal("Alive"):Connect(refresh),
    }
    tracked[model] = {Gui=gui, Highlight=highlight, Connections=conns}
    refresh()
end

local function untrack(model)
    local state = tracked[model]
    if not state then return end
    for _, conn in ipairs(state.Connections) do conn:Disconnect() end
    if state.Gui then state.Gui:Destroy() end
    if state.Highlight then state.Highlight:Destroy() end
    tracked[model] = nil
end

for _, model in CollectionService:GetTagged("Breakable") do makeBar(model) end
CollectionService:GetInstanceAddedSignal("Breakable"):Connect(makeBar)
CollectionService:GetInstanceRemovedSignal("Breakable"):Connect(untrack)
