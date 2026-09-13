local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local BackpackService = {}
local feedback = Remotes.GetOrCreate("BackpackFeedback")
local touched = {}

local function getUpgradeLevel(player, name)
    local folder = player:FindFirstChild("Upgrades")
    local value = folder and folder:FindFirstChild(name)
    return value and value:IsA("IntValue") and value.Value or 0
end

function BackpackService.GetCapacity(player)
    return GameConfig.StarterBackpack + getUpgradeLevel(player, "BackpackSlots") * Upgrades.BackpackSlots.PerLevel
end

function BackpackService.Refresh(player)
    local capacity = BackpackService.GetCapacity(player)
    local loot = math.clamp(math.floor(tonumber(player:GetAttribute("BackpackLoot")) or 0), 0, capacity)
    player:SetAttribute("BackpackCapacity", capacity)
    player:SetAttribute("BackpackLoot", loot)
end

function BackpackService.AddLoot(player, amount)
    BackpackService.Refresh(player)
    local capacity = player:GetAttribute("BackpackCapacity") or GameConfig.StarterBackpack
    local current = player:GetAttribute("BackpackLoot") or 0
    local added = math.clamp(math.floor(amount + 0.5), 0, math.max(0, capacity - current))
    player:SetAttribute("BackpackLoot", current + added)
    if added < amount then feedback:FireClient(player, false, "BACKPACK FULL") end
    return added
end

function BackpackService.Sell(player)
    local loot = math.max(0, math.floor(tonumber(player:GetAttribute("BackpackLoot")) or 0))
    if loot <= 0 then return end
    local stats = player:FindFirstChild("leaderstats")
    local coins = stats and stats:FindFirstChild("Coins")
    if not coins or not coins:IsA("IntValue") then return end
    local multiplier = math.max(1, tonumber(player:GetAttribute("CoinMultiplier")) or 1)
    local payout = math.max(1, math.floor(loot * multiplier + 0.5))
    player:SetAttribute("BackpackLoot", 0)
    coins.Value += payout
    feedback:FireClient(player, true, "SOLD +" .. payout .. " COINS")
end

function BackpackService.Start()
    local world = workspace:WaitForChild("GeneratedWorld")
    for _, obj in world:GetDescendants() do
        if obj:IsA("BasePart") and obj:GetAttribute("SellPad") == true then
            obj.Touched:Connect(function(hit)
                local character = hit:FindFirstAncestorOfClass("Model")
                local player = character and Players:GetPlayerFromCharacter(character)
                if not player then return end
                local now = os.clock()
                if now - (touched[player] or 0) < 1 then return end
                touched[player] = now
                BackpackService.Sell(player)
            end)
        end
    end
    Players.PlayerRemoving:Connect(function(player) touched[player] = nil end)
end

return BackpackService
