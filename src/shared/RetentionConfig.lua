local Retention = {}

Retention.Quests = {
    Smash25 = {Name = "Smash Starter", Event = "SmashKill", Goal = 25, RewardCoins = 350},
    Hatch3 = {Name = "Pet Collector", Event = "Hatch", Goal = 3, RewardCoins = 500},
    ReachZone3 = {Name = "Deep Expedition", Event = "HighestZone", Goal = 3, RewardGems = 1},
    Perfect10 = {Name = "Perfect Rhythm", Event = "Perfect", Goal = 10, RewardCoins = 900},
    Boss2 = {Name = "Boss Breaker", Event = "BossKill", Goal = 2, RewardGems = 1},
}

Retention.Achievements = {
    FirstSmash = {Name = "First Treasure", Event = "SmashKill", Goal = 1, RewardGems = 1},
    HundredSmashes = {Name = "Demolition Crew", Event = "SmashKill", Goal = 100, RewardGems = 2},
    TenHatches = {Name = "Hatchling Hunter", Event = "Hatch", Goal = 10, RewardGems = 2},
    ZoneSix = {Name = "Void Explorer", Event = "HighestZone", Goal = 6, RewardGems = 4},
    FirstRebirth = {Name = "Again, Stronger", Event = "Rebirth", Goal = 1, RewardGems = 3},
    FiftyPerfects = {Name = "Perfect Machine", Event = "Perfect", Goal = 50, RewardGems = 5},
}

Retention.DailyRewards = {
    {Coins = 400},
    {Coins = 700},
    {Coins = 1200},
    {Gems = 1},
    {Coins = 2200},
    {Gems = 2},
    {Gems = 4, Coins = 3500},
}

return Retention
