local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ProgressionService = require(script.Parent.ProgressionService)
local BackpackService = require(script.Parent.BackpackService)
local SmashService = require(script.Parent.SmashService)
local RetentionService = require(script.Parent.RetentionService)

local RebirthService = {}
local requestRemote = Remotes.GetOrCreate("RequestRebirth")
local feedbackRemote = Remotes.GetOrCreate("RebirthFeedback")
local lastRequest: {[Player]: number} = {}

local BASE_POWER = 750
local GROWTH = 1.85

function RebirthService.GetRequirement(rebirths)
    return math.floor(BASE_POWER * (GROWTH ^ math.max(0, rebirths)) + 0.5)
end

local function resetUpgrades(player)
    local folder = player:FindFirstChild("Upgrades")
    if not folder then return end
    for _, value in folder:GetChildren() do if value:IsA("IntValue") then value.Value = 0 end end
end

local function doRebirth(player)
    local now = os.clock()
    if now - (lastRequest[player] or 0) < 1 then return end
    lastRequest[player] = now

    local stats = player:FindFirstChild("leaderstats")
    local power = stats and stats:FindFirstChild("Power")
    local coins = stats and stats:FindFirstChild("Coins")
    local gems = stats and stats:FindFirstChild("Gems")
    local rebirthsValue = stats and stats:FindFirstChild("Rebirths")
    if not power or not coins or not gems or not rebirthsValue then return end

    local requirement = RebirthService.GetRequirement(rebirthsValue.Value)
    if power.Value < requirement or (player:GetAttribute("HighestZone") or 1) < 6 then
        feedbackRemote:FireClient(player, false, requirement, "REACH ZONE 6 + " .. requirement .. " POWER")
        return
    end

    local gemReward = 1 + math.floor(rebirthsValue.Value / 3)
    rebirthsValue.Value += 1
    gems.Value += gemReward
    player:SetAttribute("Rebirths", rebirthsValue.Value)
    RetentionService.RecordAbsolute(player, "Rebirth", rebirthsValue.Value)

    coins.Value = 0
    power.Value = 1
    player:SetAttribute("ToolIndex", 1)
    player:SetAttribute("HighestZone", 1)
    player:SetAttribute("CurrentZone", 1)
    player:SetAttribute("BackpackLoot", 0)
    resetUpgrades(player)
    ProgressionService.ApplyDerivedStats(player)
    BackpackService.Refresh(player)
    SmashService.ResetPlayerState(player)

    local spawn = workspace:FindFirstChild("GeneratedWorld") and workspace.GeneratedWorld:FindFirstChild("GreenValleySpawn")
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and spawn and spawn:IsA("BasePart") then root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0) end

    feedbackRemote:FireClient(player, true, RebirthService.GetRequirement(rebirthsValue.Value), "+" .. gemReward .. " GEMS • PERMANENT x" .. string.format("%.2f", 1 + rebirthsValue.Value * 0.225))
end

function RebirthService.Start()
    requestRemote.OnServerEvent:Connect(doRebirth)
    Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)
end

return RebirthService
