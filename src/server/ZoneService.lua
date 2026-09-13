local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Zones = require(ReplicatedStorage.Shared.Zones)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ZoneService = {}
local feedback = Remotes.GetOrCreate("ZoneFeedback")
local lastTouch = {}

local function getCoins(player)
    local stats=player:FindFirstChild("leaderstats"); local coins=stats and stats:FindFirstChild("Coins")
    return coins and coins:IsA("IntValue") and coins or nil
end

local function teleportToZone(player, zoneId)
    local zone=Zones[zoneId]; local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if zone and root then root.CFrame=CFrame.new(zone.Offset+Vector3.new(0,4,-60)) end
end

function ZoneService.Unlock(player, zoneId, free)
    zoneId=math.clamp(math.floor(tonumber(zoneId) or 1),1,#Zones)
    local highest=math.clamp(player:GetAttribute("HighestZone") or 1,1,#Zones)
    if zoneId<=highest then teleportToZone(player,zoneId); return true end
    if zoneId~=highest+1 then return false end
    local cost=Zones[zoneId].UnlockCost or 0
    local coins=getCoins(player)
    if not free then
        if not coins or coins.Value<cost then feedback:FireClient(player,false,"NEED "..cost.." COINS"); return false end
        coins.Value-=cost
    end
    player:SetAttribute("HighestZone",zoneId)
    feedback:FireClient(player,true,"UNLOCKED "..Zones[zoneId].Name)
    teleportToZone(player,zoneId)
    return true
end

local function bindPart(obj)
    if not obj:IsA("BasePart") then return end
    local unlock=obj:GetAttribute("UnlockZone")
    local checkpoint=obj:GetAttribute("ZoneId")
    if unlock then
        obj.Touched:Connect(function(hit)
            local player=Players:GetPlayerFromCharacter(hit.Parent); if not player then return end
            local now=os.clock(); if now-(lastTouch[player] or 0)<1 then return end; lastTouch[player]=now
            ZoneService.Unlock(player,unlock,false)
        end)
    elseif checkpoint and obj.Name=="Checkpoint" then
        obj.Touched:Connect(function(hit)
            local player=Players:GetPlayerFromCharacter(hit.Parent); if player and checkpoint<=(player:GetAttribute("HighestZone") or 1) then player:SetAttribute("CurrentZone",checkpoint) end
        end)
    end
end

function ZoneService.Start()
    local world=workspace:WaitForChild("GeneratedWorld")
    for _,obj in world:GetDescendants() do bindPart(obj) end
end

return ZoneService
