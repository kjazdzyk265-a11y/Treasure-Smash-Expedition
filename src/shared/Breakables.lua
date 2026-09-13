local entries = {}
local function add(name, hp, reward, material, respawn, zone, boss)
    entries[name] = {MaxHealth = hp, Reward = reward, Material = material, Respawn = respawn, Zone = zone, Boss = boss == true}
end

-- Green Valley
add("Crate", 20, 6, "Wood", 6, 1); add("Barrel", 28, 9, "Wood", 7, 1); add("FencePost", 34, 11, "Wood", 7, 1); add("FarmRock", 45, 14, "Stone", 9, 1); add("IronSafe", 90, 30, "Metal", 14, 1); add("TreasureChest", 140, 55, "Wood", 20, 1); add("RuinedStatue", 180, 68, "Stone", 22, 1); add("AncientGate", 1200, 700, "Stone", 45, 1, true)
-- Construction City
add("Pallet", 240, 82, "Wood", 10, 2); add("ConcreteBlock", 320, 108, "Stone", 11, 2); add("RoadBarrier", 400, 138, "Metal", 12, 2); add("SteelCrate", 520, 175, "Metal", 13, 2); add("ContainerDoor", 700, 235, "Metal", 15, 2); add("ConstructionSafe", 920, 315, "Metal", 17, 2); add("CraneWeight", 1200, 410, "Metal", 20, 2); add("MegaSafe", 7200, 4300, "Metal", 55, 2, true)
-- Crystal Caverns
add("CaveRock", 1500, 510, "Stone", 12, 3); add("BlueCrystal", 1900, 650, "Crystal", 14, 3); add("AmethystCluster", 2400, 820, "Crystal", 15, 3); add("FossilSlab", 3000, 1010, "Stone", 16, 3); add("CrystalChest", 3800, 1290, "Crystal", 18, 3); add("PrismPillar", 4800, 1620, "Crystal", 20, 3); add("CathedralShard", 6200, 2100, "Crystal", 23, 3); add("CrystalTitan", 36000, 22000, "Crystal", 65, 3, true)
-- Magma Forge
add("BasaltRock", 7600, 2600, "Magma", 14, 4); add("IronPipe", 9400, 3150, "Metal", 15, 4); add("SmelterCrate", 11800, 3950, "Metal", 17, 4); add("LavaCore", 15000, 5100, "Magma", 19, 4); add("ForgeAnvil", 19000, 6500, "Metal", 21, 4); add("MoltenVault", 24000, 8300, "Magma", 23, 4); add("ObsidianSlab", 31000, 10800, "Stone", 26, 4); add("ForgeCore", 180000, 115000, "Magma", 75, 4, true)
-- Sky Ruins
add("CloudStone", 39000, 13800, "Stone", 16, 5); add("GoldenUrn", 50000, 17600, "Metal", 17, 5); add("TempleColumn", 64000, 22600, "Stone", 19, 5); add("SkyRelic", 82000, 29200, "Metal", 21, 5); add("AngelStatue", 105000, 37500, "Stone", 23, 5); add("SunChest", 136000, 49000, "Metal", 25, 5); add("AncientDoor", 175000, 63000, "Stone", 28, 5); add("SkyColossus", 980000, 680000, "Stone", 85, 5, true)
-- Void Kingdom
add("VoidRock", 220000, 82000, "Void", 18, 6); add("DarkObelisk", 285000, 108000, "Void", 20, 6); add("CursedChest", 370000, 142000, "Void", 22, 6); add("VoidStatue", 480000, 186000, "Void", 24, 6); add("ShadowCrystal", 625000, 245000, "Void", 27, 6); add("RoyalSarcophagus", 820000, 325000, "Void", 30, 6); add("VoidCrown", 1080000, 435000, "Void", 34, 6); add("VoidHeart", 5800000, 4200000, "Void", 100, 6, true)
-- rare/special variants (50+ total)
add("GoldenCrate", 120, 120, "Metal", 30, 1); add("GoldenSafe", 1400, 1100, "Metal", 35, 2); add("CrystalMeteor", 9000, 9000, "Crystal", 45, 3); add("MoltenIdol", 42000, 42000, "Magma", 50, 4); add("CelestialRelic", 220000, 240000, "Crystal", 60, 5); add("SecretObelisk", 1600000, 2200000, "Void", 90, 6)

return entries
