local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.RetentionConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local RetentionService = {}
local claimRemote = Remotes.GetOrCreate("RetentionClaim")
local feedbackRemote = Remotes.GetOrCreate("RetentionFeedback")
local lastRequest = {}

local function getStats(player)
    local stats = player:FindFirstChild("leaderstats")
    return stats, stats and stats:FindFirstChild("Coins"), stats and stats:FindFirstChild("Gems")
end

local function getFolder(player, name)
    local folder = player:FindFirstChild(name)
    return folder and folder:IsA("Folder") and folder or nil
end

local function ensureValue(folder, name, className, default)
    local value = folder:FindFirstChild(name)
    if value then return value end
    value = Instance.new(className)
    value.Name = name
    value.Value = default
    value.Parent = folder
    return value
end

local function dayNumber()
    return math.floor(os.time() / 86400)
end

local function reward(player, rewardData)
    local _, coins, gems = getStats(player)
    if coins and rewardData.Coins then coins.Value += rewardData.Coins end
    if gems and rewardData.Gems then gems.Value += rewardData.Gems end
end

local function refreshSnapshot(player)
    local quests = getFolder(player, "QuestProgress")
    local achievements = getFolder(player, "Achievements")
    local claimedQuests = getFolder(player, "ClaimedQuests")
    if not quests or not achievements or not claimedQuests then return end

    local completed = 0
    for id, cfg in pairs(Config.Quests) do
        local progress = quests:FindFirstChild(id)
        local claimed = claimedQuests:FindFirstChild(id)
        if progress and progress.Value >= cfg.Goal and claimed and claimed.Value then completed += 1 end
    end
    player:SetAttribute("CompletedQuests", completed)
    player:SetAttribute("AchievementCount", #achievements:GetChildren())
end

local function setProgress(player, eventName, amount, absolute)
    local quests = getFolder(player, "QuestProgress")
    if quests then
        for id, cfg in pairs(Config.Quests) do
            if cfg.Event == eventName then
                local value = ensureValue(quests, id, "IntValue", 0)
                value.Value = absolute and math.max(value.Value, amount) or math.min(cfg.Goal, value.Value + amount)
            end
        end
    end

    local achievementProgress = getFolder(player, "AchievementProgress")
    local achievements = getFolder(player, "Achievements")
    if achievementProgress and achievements then
        for id, cfg in pairs(Config.Achievements) do
            if cfg.Event == eventName and not achievements:FindFirstChild(id) then
                local value = ensureValue(achievementProgress, id, "IntValue", 0)
                value.Value = absolute and math.max(value.Value, amount) or math.min(cfg.Goal, value.Value + amount)
                if value.Value >= cfg.Goal then
                    local unlocked = Instance.new("BoolValue")
                    unlocked.Name = id
                    unlocked.Value = true
                    unlocked.Parent = achievements
                    reward(player, cfg.RewardGems and {Gems = cfg.RewardGems} or {Coins = cfg.RewardCoins or 0})
                    feedbackRemote:FireClient(player, true, "ACHIEVEMENT", cfg.Name)
                end
            end
        end
    end
    refreshSnapshot(player)
end

function RetentionService.Record(player, eventName, amount)
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    setProgress(player, eventName, amount, false)
end

function RetentionService.RecordAbsolute(player, eventName, value)
    setProgress(player, eventName, math.max(0, math.floor(tonumber(value) or 0)), true)
end

function RetentionService.LoadPlayer(player, loaded)
    loaded = type(loaded) == "table" and loaded or {}
    local questFolder = Instance.new("Folder"); questFolder.Name = "QuestProgress"; questFolder.Parent = player
    local claimedFolder = Instance.new("Folder"); claimedFolder.Name = "ClaimedQuests"; claimedFolder.Parent = player
    local achievementProgress = Instance.new("Folder"); achievementProgress.Name = "AchievementProgress"; achievementProgress.Parent = player
    local achievements = Instance.new("Folder"); achievements.Name = "Achievements"; achievements.Parent = player

    for id in pairs(Config.Quests) do
        ensureValue(questFolder, id, "IntValue", math.max(0, math.floor(tonumber(loaded.Quests and loaded.Quests[id]) or 0)))
        ensureValue(claimedFolder, id, "BoolValue", loaded.ClaimedQuests and loaded.ClaimedQuests[id] == true)
    end
    for id in pairs(Config.Achievements) do
        ensureValue(achievementProgress, id, "IntValue", math.max(0, math.floor(tonumber(loaded.AchievementProgress and loaded.AchievementProgress[id]) or 0)))
        if loaded.Achievements and loaded.Achievements[id] == true then
            ensureValue(achievements, id, "BoolValue", true)
        end
    end

    player:SetAttribute("DailyLastDay", math.floor(tonumber(loaded.DailyLastDay) or -1))
    player:SetAttribute("DailyStreak", math.clamp(math.floor(tonumber(loaded.DailyStreak) or 0), 0, 7))
    player:SetAttribute("DailyReady", player:GetAttribute("DailyLastDay") ~= dayNumber())
    refreshSnapshot(player)

    player:GetAttributeChangedSignal("HighestZone"):Connect(function()
        RetentionService.RecordAbsolute(player, "HighestZone", player:GetAttribute("HighestZone") or 1)
    end)
    player:GetAttributeChangedSignal("Rebirths"):Connect(function()
        RetentionService.RecordAbsolute(player, "Rebirth", player:GetAttribute("Rebirths") or 0)
    end)
    RetentionService.RecordAbsolute(player, "HighestZone", player:GetAttribute("HighestZone") or 1)
    RetentionService.RecordAbsolute(player, "Rebirth", player:GetAttribute("Rebirths") or 0)
end

local function claimQuest(player, id)
    local cfg = Config.Quests[id]
    if not cfg then return end
    local quests = getFolder(player, "QuestProgress")
    local claimed = getFolder(player, "ClaimedQuests")
    local progress = quests and quests:FindFirstChild(id)
    local flag = claimed and claimed:FindFirstChild(id)
    if not progress or not flag or flag.Value or progress.Value < cfg.Goal then return end
    flag.Value = true
    reward(player, cfg)
    refreshSnapshot(player)
    feedbackRemote:FireClient(player, true, "QUEST COMPLETE", cfg.Name)
end

local function claimDaily(player)
    local today = dayNumber()
    local last = player:GetAttribute("DailyLastDay") or -1
    if last == today then return end
    local streak = player:GetAttribute("DailyStreak") or 0
    if last == today - 1 then streak = (streak % 7) + 1 else streak = 1 end
    player:SetAttribute("DailyLastDay", today)
    player:SetAttribute("DailyStreak", streak)
    player:SetAttribute("DailyReady", false)
    local rewardData = Config.DailyRewards[streak]
    reward(player, rewardData)
    feedbackRemote:FireClient(player, true, "DAILY DAY " .. streak, "REWARD CLAIMED")
end

function RetentionService.Start()
    claimRemote.OnServerEvent:Connect(function(player, action, id)
        local now = os.clock()
        if now - (lastRequest[player] or 0) < 0.25 then return end
        lastRequest[player] = now
        if action == "Quest" and typeof(id) == "string" then claimQuest(player, id)
        elseif action == "Daily" then claimDaily(player) end
    end)
    Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)
end

return RetentionService
