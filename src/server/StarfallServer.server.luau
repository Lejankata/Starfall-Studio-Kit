--!strict
-- Starfall Studio Kit / server-authoritative gathering game
-- Place this Script in ServerScriptService. Licensed under MIT.
-- This starter is not a cross-server transactional economy or trading framework.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local CONFIG = {
    DataStoreName = "StarfallStudioKit_v1",
    SaveEverySeconds = 75,
    DailyReward = 75,
    ActionCooldown = 0.18,
    GatherRadius = 13,
    CrystalsPerZone = 12,
    RespawnSeconds = 9,
}

local COLORS = {
    ink = Color3.fromRGB(19, 23, 42),
    violet = Color3.fromRGB(135, 105, 255),
    mint = Color3.fromRGB(84, 232, 180),
    amber = Color3.fromRGB(255, 198, 82),
    sky = Color3.fromRGB(83, 184, 255),
    dark = Color3.fromRGB(43, 54, 87),
}

local ZONES = {
    { id = "meadow", title = "Starlight Meadow", center = Vector3.new(0, 1, 88), color = COLORS.mint, yield = 3 },
    { id = "canyon", title = "Amber Canyon", center = Vector3.new(-91, 1, 95), color = COLORS.amber, yield = 6 },
    { id = "glade", title = "Moonlit Glade", center = Vector3.new(91, 1, 95), color = COLORS.violet, yield = 10 },
    { id = "frost", title = "Frostspire Peaks", center = Vector3.new(-91, 1, 194), color = COLORS.sky, yield = 16, price = 500 },
    { id = "nebula", title = "Nebula Gardens", center = Vector3.new(91, 1, 194), color = Color3.fromRGB(255, 113, 190), yield = 25, price = 1800 },
}

local UPGRADES = {
    pack = { title = "Bigger Backpack", base = 85, growth = 1.55, max = 8 },
    power = { title = "Crystal Power", base = 115, growth = 1.6, max = 7 },
    boots = { title = "Swift Boots", base = 70, growth = 1.65, max = 5 },
    market = { title = "Market Expert", base = 250, growth = 1.8, max = 5 },
}
local UPGRADE_ORDER = { "pack", "power", "boots", "market" }
local PETS = {
    wisp = { title = "Star Wisp", cost = 150, bonus = 2, color = COLORS.mint },
    fox = { title = "Comet Fox", cost = 450, bonus = 5, color = COLORS.amber },
    dragon = { title = "Nebula Dragon", cost = 1500, bonus = 10, color = COLORS.violet },
}
local PET_ORDER = { "wisp", "fox", "dragon" }
local QUESTS = {
    collector = { title = "Star Collector", target = 12, reward = 60, detail = "Collect 12 crystals" },
    merchant = { title = "Market Day", target = 60, reward = 100, detail = "Sell 60 energy" },
    builder = { title = "Growing Stronger", target = 2, reward = 120, detail = "Buy 2 upgrades" },
}
local QUEST_ORDER = { "collector", "merchant", "builder" }

type Session = {
    data: {[string]: any},
    ready: boolean,
    persist: boolean,
    dirty: boolean,
    saving: boolean,
    lastAction: number,
}
local sessions: {[Player]: Session} = {}

local function dayKey(): string
    return os.date("!%Y-%m-%d", os.time())
end

local function whole(value: any, fallback: number, maximum: number): number
    if typeof(value) ~= "number" or value ~= value then return fallback end
    return math.clamp(math.floor(value), 0, maximum)
end

local function freshData(): {[string]: any}
    return {
        coins = 0,
        energy = 0,
        collected = 0,
        sold = 0,
        upgrades = { pack = 0, power = 0, boots = 0, market = 0 },
        pets = { owned = {}, equipped = "" },
        unlocked = { frost = false, nebula = false },
        daily = { day = "", claimed = false },
        quests = { day = dayKey(), progress = { collector = 0, merchant = 0, builder = 0 }, claimed = {} },
    }
end

local function sanitize(input: any): {[string]: any}
    local result = freshData()
    if typeof(input) ~= "table" then return result end
    result.coins = whole(input.coins, 0, 1000000000)
    result.collected = whole(input.collected, 0, 1000000000)
    result.sold = whole(input.sold, 0, 1000000000)
    local upgrades = if typeof(input.upgrades) == "table" then input.upgrades else {}
    for key, def in pairs(UPGRADES) do
        result.upgrades[key] = whole(upgrades[key], 0, def.max)
    end
    local pets = if typeof(input.pets) == "table" then input.pets else {}
    local owned = if typeof(pets.owned) == "table" then pets.owned else {}
    for id in pairs(PETS) do
        result.pets.owned[id] = owned[id] == true
    end
    if typeof(pets.equipped) == "string" and PETS[pets.equipped] and result.pets.owned[pets.equipped] then
        result.pets.equipped = pets.equipped
    end
    local unlocked = if typeof(input.unlocked) == "table" then input.unlocked else {}
    result.unlocked.frost = unlocked.frost == true
    result.unlocked.nebula = unlocked.nebula == true
    result.energy = math.min(whole(input.energy, 0, 1000000), 30 + result.upgrades.pack * 20)
    if typeof(input.daily) == "table" and typeof(input.daily.day) == "string" then
        result.daily.day = input.daily.day
        result.daily.claimed = input.daily.claimed == true
    end
    if typeof(input.quests) == "table" and input.quests.day == dayKey() then
        result.quests.day = input.quests.day
        if typeof(input.quests.progress) == "table" then
            for id, quest in pairs(QUESTS) do
                result.quests.progress[id] = whole(input.quests.progress[id], 0, quest.target)
            end
        end
        if typeof(input.quests.claimed) == "table" then
            for id in pairs(QUESTS) do
                result.quests.claimed[id] = input.quests.claimed[id] == true
            end
        end
    end
    return result
end

local function copyForSave(data: {[string]: any}): {[string]: any}
    return {
        coins = data.coins,
        energy = data.energy,
        collected = data.collected,
        sold = data.sold,
        upgrades = table.clone(data.upgrades),
        pets = { owned = table.clone(data.pets.owned), equipped = data.pets.equipped },
        unlocked = table.clone(data.unlocked),
        daily = table.clone(data.daily),
        quests = {
            day = data.quests.day,
            progress = table.clone(data.quests.progress),
            claimed = table.clone(data.quests.claimed),
        },
    }
end

-- DataStore creation sometimes fails for an unpublished place. Gameplay stays playable.
local dataStore: GlobalDataStore? = nil
do
    local ok, result = pcall(function()
        return DataStoreService:GetDataStore(CONFIG.DataStoreName)
    end)
    if ok then
        dataStore = result
    else
        warn("[Starfall] DataStore unavailable; running in unsaved demo mode:", result)
    end
end

local network = ReplicatedStorage:FindFirstChild("StarfallNetwork")
if not network then
    network = Instance.new("RemoteEvent")
    network.Name = "StarfallNetwork"
    network.Parent = ReplicatedStorage
end
local remote = network :: RemoteEvent

local function energyCap(data: {[string]: any}): number
    return 30 + data.upgrades.pack * 20
end
local function upgradeCost(id: string, level: number): number
    local def = UPGRADES[id]
    return math.floor(def.base * (def.growth ^ level) + 0.5)
end

local function petBonus(data: {[string]: any}): number
    local id = data.pets.equipped
    return if PETS[id] then PETS[id].bonus else 0
end

local function sellPrice(data: {[string]: any}): number
    return 3 + data.upgrades.market
end

local function worldLevel(data: {[string]: any}): number
    return 3 + (if data.unlocked.frost then 1 else 0) + (if data.unlocked.nebula then 1 else 0)
end

local function resetQuestsIfNeeded(session: Session)
    local data = session.data
    if data.quests.day ~= dayKey() then
        data.quests = freshData().quests
        session.dirty = true
    end
end

local function questProgress(session: Session, id: string, amount: number)
    resetQuestsIfNeeded(session)
    local quest = QUESTS[id]
    session.data.quests.progress[id] = math.min(quest.target, session.data.quests.progress[id] + amount)
    session.dirty = true
end

local function sync(player: Player)
    local session = sessions[player]
    if not session or not session.ready then return end
    resetQuestsIfNeeded(session)
    local data = session.data
    local shop = {}
    for _, id in ipairs(UPGRADE_ORDER) do
        local def = UPGRADES[id]
        local level = data.upgrades[id]
        table.insert(shop, {
            id = id, title = def.title, level = level, max = def.max,
            cost = if level >= def.max then nil else upgradeCost(id, level),
        })
    end
    local quests = {}
    for _, id in ipairs(QUEST_ORDER) do
        local def = QUESTS[id]
        table.insert(quests, {
            id = id, title = def.title, detail = def.detail,
            progress = data.quests.progress[id], target = def.target,
            reward = def.reward, claimed = data.quests.claimed[id] == true,
        })
    end
    local petShop = {}
    for _, id in ipairs(PET_ORDER) do
        local pet = PETS[id]
        table.insert(petShop, {
            id = id, title = pet.title, bonus = pet.bonus, cost = pet.cost,
            owned = data.pets.owned[id] == true, equipped = data.pets.equipped == id,
        })
    end
    local worlds = {}
    for _, zone in ipairs(ZONES) do
        table.insert(worlds, {
            id = zone.id, title = zone.title, yield = zone.yield, price = zone.price,
            unlocked = zone.price == nil or data.unlocked[zone.id] == true,
        })
    end
    remote:FireClient(player, "Snapshot", {
        coins = data.coins,
        energy = data.energy,
        capacity = energyCap(data),
        collected = data.collected,
        sold = data.sold,
        sellPrice = sellPrice(data),
        equippedPet = data.pets.equipped,
        petBonus = petBonus(data),
        pets = petShop,
        worlds = worlds,
        currentWorlds = worldLevel(data),
        shop = shop,
        quests = quests,
        dailyClaimed = data.daily.day == dayKey() and data.daily.claimed,
        dailyReward = CONFIG.DailyReward,
        savingAvailable = session.persist,
    })
end

local function toast(player: Player, message: string)
    remote:FireClient(player, "Toast", message)
end

local function updateCoinsStat(player: Player, data: {[string]: any})
    local stats = player:FindFirstChild("leaderstats")
    local value = if stats then stats:FindFirstChild("Credits") else nil
    if value and value:IsA("IntValue") then value.Value = data.coins end
    local crystals = if stats then stats:FindFirstChild("Crystals") else nil
    if crystals and crystals:IsA("IntValue") then crystals.Value = data.collected end
    local worlds = if stats then stats:FindFirstChild("Worlds") else nil
    if worlds and worlds:IsA("IntValue") then worlds.Value = worldLevel(data) end
end

local function applySpeed(player: Player, data: {[string]: any})
    local char = player.Character
    local humanoid = if char then char:FindFirstChildOfClass("Humanoid") else nil
    if humanoid then humanoid.WalkSpeed = 16 + data.upgrades.boots * 2 end
end

local function save(player: Player): boolean
    local session = sessions[player]
    if not session or not session.ready or not session.persist or not session.dirty or session.saving or not dataStore then
        return true
    end
    session.saving = true
    local snapshot = copyForSave(session.data)
    local ok, err = pcall(function()
        dataStore:UpdateAsync("u_" .. player.UserId, function(_previous)
            return snapshot
        end)
    end)
    session.saving = false
    if not ok then
        warn("[Starfall] Save failed for", player.UserId, err)
        return false
    end
    -- If player data changed while saving, keep it marked as dirty.
    session.dirty = session.data.coins ~= snapshot.coins
        or session.data.energy ~= snapshot.energy
        or session.data.collected ~= snapshot.collected
        or session.data.sold ~= snapshot.sold
        or session.data.upgrades.pack ~= snapshot.upgrades.pack
        or session.data.upgrades.power ~= snapshot.upgrades.power
        or session.data.upgrades.boots ~= snapshot.upgrades.boots
        or session.data.upgrades.market ~= snapshot.upgrades.market
        or session.data.pets.equipped ~= snapshot.pets.equipped
        or session.data.unlocked.frost ~= snapshot.unlocked.frost
        or session.data.unlocked.nebula ~= snapshot.unlocked.nebula
        or session.data.daily.day ~= snapshot.daily.day
        or session.data.daily.claimed ~= snapshot.daily.claimed
        or session.data.quests.day ~= snapshot.quests.day
    if not session.dirty then
        for id in pairs(PETS) do
            if session.data.pets.owned[id] ~= snapshot.pets.owned[id] then
                session.dirty = true
                break
            end
        end
    end
    if not session.dirty then
        for id in pairs(QUESTS) do
            if session.data.quests.progress[id] ~= snapshot.quests.progress[id]
                or session.data.quests.claimed[id] ~= snapshot.quests.claimed[id] then
                session.dirty = true
                break
            end
        end
    end
    return true
end

local function loadPlayer(player: Player)
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player
    local credits = Instance.new("IntValue")
    credits.Name = "Credits"
    credits.Parent = stats
    local crystals = Instance.new("IntValue")
    crystals.Name = "Crystals"
    crystals.Parent = stats
    local worlds = Instance.new("IntValue")
    worlds.Name = "Worlds"
    worlds.Parent = stats

    local session: Session = {
        data = freshData(), ready = false, persist = false, dirty = false,
        saving = false, lastAction = -math.huge,
    }
    sessions[player] = session
    if dataStore then
        local ok, saved = pcall(function()
            return dataStore:GetAsync("u_" .. player.UserId)
        end)
        if ok then
            session.data = sanitize(saved)
            session.persist = true
        else
            warn("[Starfall] Load failed; refusing to overwrite saved data:", player.UserId, saved)
        end
    end
    if sessions[player] ~= session or not player.Parent then return end
    session.ready = true
    updateCoinsStat(player, session.data)
    player:SetAttribute("StarfallPet", session.data.pets.equipped)
    if player.Character then applySpeed(player, session.data) end
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then applySpeed(player, session.data) end
    end)
    sync(player)
end

local function claimDaily(player: Player)
    local session = sessions[player]
    if not session or not session.ready then return end
    if session.data.daily.day == dayKey() and session.data.daily.claimed then
        toast(player, "Daily reward already collected. Return tomorrow!")
        return
    end
    session.data.daily = { day = dayKey(), claimed = true }
    session.data.coins += CONFIG.DailyReward
    session.dirty = true
    updateCoinsStat(player, session.data)
    toast(player, "+" .. CONFIG.DailyReward .. " credits! Come back tomorrow.")
    sync(player)
end

local function sellEnergy(player: Player)
    local session = sessions[player]
    if not session or not session.ready then return end
    local amount = session.data.energy
    if amount <= 0 then
        toast(player, "Backpack empty. Collect crystals first!")
        return
    end
    session.data.energy = 0
    local earned = amount * sellPrice(session.data)
    session.data.coins += earned
    session.data.sold += amount
    questProgress(session, "merchant", amount)
    session.dirty = true
    updateCoinsStat(player, session.data)
    toast(player, "Sold " .. amount .. " energy for " .. earned .. " credits!")
    sync(player)
end

local function buyUpgrade(player: Player, id: string)
    local session = sessions[player]
    local def = UPGRADES[id]
    if not session or not session.ready or not def then return end
    local level = session.data.upgrades[id]
    if level >= def.max then
        toast(player, "Already at maximum level!")
        return
    end
    local price = upgradeCost(id, level)
    if session.data.coins < price then
        toast(player, "Not enough credits. Sell more energy!")
        return
    end
    session.data.coins -= price
    session.data.upgrades[id] += 1
    questProgress(session, "builder", 1)
    session.dirty = true
    updateCoinsStat(player, session.data)
    if id == "boots" then applySpeed(player, session.data) end
    toast(player, "Upgraded " .. def.title .. " to Lv. " .. (level + 1) .. "!")
    sync(player)
end

local function buyPet(player: Player, id: string)
    local session = sessions[player]
    local pet = PETS[id]
    if not session or not session.ready or not pet then return end
    local data = session.data
    if data.pets.owned[id] then
        toast(player, "Pet already adopted. Select Equip instead!")
        return
    end
    if data.coins < pet.cost then
        toast(player, "Not enough credits for " .. pet.title)
        return
    end
    data.coins -= pet.cost
    data.pets.owned[id] = true
    if data.pets.equipped == "" then
        data.pets.equipped = id
        player:SetAttribute("StarfallPet", id)
    end
    session.dirty = true
    updateCoinsStat(player, data)
    toast(player, "Adopted " .. pet.title .. "! Open Pets to equip.")
    sync(player)
end

local function equipPet(player: Player, id: string)
    local session = sessions[player]
    if not session or not session.ready then return end
    local data = session.data
    if id ~= "none" and (not PETS[id] or not data.pets.owned[id]) then return end
    local chosen = if id == "none" then "" else id
    if data.pets.equipped == chosen then return end
    data.pets.equipped = chosen
    player:SetAttribute("StarfallPet", chosen)
    session.dirty = true
    toast(player, if chosen == "" then "Pet unequipped" else PETS[chosen].title .. " equipped!")
    sync(player)
end

local function unlockZone(player: Player, id: string)
    local session = sessions[player]
    if not session or not session.ready then return end
    local zone: any = nil
    for _, candidate in ipairs(ZONES) do
        if candidate.id == id then
            zone = candidate
            break
        end
    end
    if not zone or zone.price == nil then return end
    local data = session.data
    if data.unlocked[id] then
        toast(player, zone.title .. " is already unlocked!")
        return
    end
    if data.coins < zone.price then
        toast(player, "You need " .. zone.price .. " credits to unlock " .. zone.title)
        return
    end
    data.coins -= zone.price
    data.unlocked[id] = true
    session.dirty = true
    updateCoinsStat(player, data)
    toast(player, "New world unlocked: " .. zone.title .. "!")
    sync(player)
end

local function claimQuest(player: Player, id: string)
    local session = sessions[player]
    local def = QUESTS[id]
    if not session or not session.ready or not def then return end
    resetQuestsIfNeeded(session)
    local data = session.data
    if data.quests.claimed[id] then
        toast(player, "Already claimed today.")
        return
    end
    if data.quests.progress[id] < def.target then
        toast(player, "Quest not complete yet.")
        return
    end
    data.quests.claimed[id] = true
    data.coins += def.reward
    session.dirty = true
    updateCoinsStat(player, data)
    toast(player, "Quest complete! +" .. def.reward .. " credits")
    sync(player)
end

remote.OnServerEvent:Connect(function(player: Player, action: any, value: any)
    if typeof(action) ~= "string" or #action > 30 then return end
    local session = sessions[player]
    if not session or not session.ready then return end
    if action == "hello" then
        sync(player)
        return
    end
    -- Prevent malicious clients from spamming economy actions.
    local now = os.clock()
    if now - session.lastAction < CONFIG.ActionCooldown then return end
    session.lastAction = now
    if action == "daily" then
        claimDaily(player)
    elseif action == "buy" and typeof(value) == "string" and #value < 24 then
        buyUpgrade(player, value)
    elseif action == "quest" and typeof(value) == "string" and #value < 24 then
        claimQuest(player, value)
    elseif action == "petBuy" and typeof(value) == "string" and #value < 24 then
        buyPet(player, value)
    elseif action == "petEquip" and typeof(value) == "string" and #value < 24 then
        equipPet(player, value)
    elseif action == "worldBuy" and typeof(value) == "string" and #value < 24 then
        unlockZone(player, value)
    end
end)

-- All map geometry uses built-in Roblox parts; zero asset IDs or paid plugins.
local existing = workspace:FindFirstChild("StarfallWorld")
if existing then existing:Destroy() end
local world = Instance.new("Folder")
world.Name = "StarfallWorld"
world.Parent = workspace

local function makePart(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material, parent: Instance?, shape: Enum.PartType?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.Position = position
    part.Color = color
    part.Material = material
    part.CanCollide = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    if shape then part.Shape = shape end
    part.Parent = parent or world
    return part
end

local function label(part: BasePart, title: string, subtitle: string)
    local bill = Instance.new("BillboardGui")
    bill.Name = "FloatingLabel"
    bill.Size = UDim2.fromOffset(270, 78)
    bill.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
    bill.AlwaysOnTop = true
    bill.MaxDistance = 150
    bill.Parent = part
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = COLORS.ink
    bg.BackgroundTransparency = 0.15
    bg.Parent = bill
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = bg
    for i, spec in ipairs({ {title, 0, 15, 25}, {subtitle, 36, 11, 18} }) do
        local text = Instance.new("TextLabel")
        text.Name = if i == 1 then "Title" else "Subtitle"
        text.BackgroundTransparency = 1
        text.Position = UDim2.new(0, 8, 0, spec[2])
        text.Size = UDim2.new(1, -16, 0, spec[4])
        text.Font = if i == 1 then Enum.Font.GothamBold else Enum.Font.Gotham
        text.Text = spec[1]
        text.TextSize = spec[3]
        text.TextColor3 = if i == 1 then Color3.new(1, 1, 1) else Color3.fromRGB(186, 200, 230)
        text.Parent = bg
    end
end

local function kiosk(name: string, position: Vector3, color: Color3, action: string, subtitle: string, callback: (Player) -> ())
    makePart(name .. " Platform", Vector3.new(17, 1, 13), position + Vector3.new(0, -1.2, 0), COLORS.dark, Enum.Material.SmoothPlastic, world)
    local pedestal = makePart(name, Vector3.new(7, 5, 5), position + Vector3.new(0, 1.8, 0), color, Enum.Material.SmoothPlastic, world)
    local cap = makePart(name .. " Glow", Vector3.new(7.25, 0.5, 5.25), pedestal.Position + Vector3.new(0, 2.6, 0), color, Enum.Material.Neon, world)
    cap.CanCollide = false
    label(pedestal, name, subtitle)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = action
    prompt.ObjectText = name
    prompt.MaxActivationDistance = 11
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.Parent = pedestal
    prompt.Triggered:Connect(function(player)
        local character = player.Character
        local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
        if not root or not root:IsA("BasePart") or (root.Position - pedestal.Position).Magnitude > 13 then return end
        callback(player)
    end)
end

local function openPanel(player: Player, panel: string)
    remote:FireClient(player, "Open", panel)
end

local floor = makePart("Town Square", Vector3.new(70, 1, 70), Vector3.new(0, -0.55, 0), COLORS.ink, Enum.Material.Slate, world)
floor.Transparency = 0.08
makePart("Welcome Beacon", Vector3.new(4, 16, 4), Vector3.new(0, 7, -30), COLORS.violet, Enum.Material.Neon, world)

-- Walkways, lamps, and landmarks give the generated map a consistent style.
local function walkway(from: Vector3, to: Vector3, color: Color3)
    local diff = to - from
    local mid = (from + to) / 2
    local path = makePart("Lit Walkway", Vector3.new(11, 0.4, diff.Magnitude), Vector3.new(mid.X, -0.19, mid.Z), COLORS.dark, Enum.Material.Slate, world)
    path.CFrame = CFrame.lookAt(path.Position, Vector3.new(to.X, -0.19, to.Z))
    for side = -1, 1, 2 do
        local strip = makePart("Walkway Edge", Vector3.new(0.35, 0.45, diff.Magnitude), path.Position, color, Enum.Material.Neon, world)
        strip.CFrame = path.CFrame * CFrame.new(side * 5, 0.12, 0)
        strip.CanCollide = false
    end
end
walkway(Vector3.new(0, 0, 31), Vector3.new(0, 0, 66), COLORS.mint)
walkway(Vector3.new(-25, 0, 25), Vector3.new(-91, 0, 73), COLORS.amber)
walkway(Vector3.new(25, 0, 25), Vector3.new(91, 0, 73), COLORS.violet)
walkway(Vector3.new(-91, 0, 117), Vector3.new(-91, 0, 170), COLORS.sky)
walkway(Vector3.new(91, 0, 117), Vector3.new(91, 0, 170), COLORS.violet)

for i = 1, 14 do
    local angle = i * 2 * math.pi / 14
    local p = Vector3.new(math.cos(angle) * 31, 0, math.sin(angle) * 31)
    makePart("Town Lantern", Vector3.new(1.2, 8, 1.2), p + Vector3.new(0, 3.5, 0), COLORS.dark, Enum.Material.Metal, world)
    local bulb = makePart("Lantern Light", Vector3.new(2.5, 2.5, 2.5), p + Vector3.new(0, 8, 0), COLORS.mint, Enum.Material.Neon, world, Enum.PartType.Ball)
    bulb.CanCollide = false
    local glow = Instance.new("PointLight")
    glow.Brightness = 1
    glow.Range = 19
    glow.Color = COLORS.mint
    glow.Parent = bulb
end

kiosk("SELL ENERGY", Vector3.new(0, 1, 25), COLORS.mint, "Sell backpack", "3+ credits per energy", sellEnergy)
kiosk("UPGRADE SHOP", Vector3.new(-24, 1, 9), COLORS.sky, "Browse shop", "Four upgrade tracks", function(p) openPanel(p, "Shop") end)
kiosk("DAILY REWARD", Vector3.new(24, 1, 9), COLORS.amber, "Claim reward", "+75 credits every UTC day", claimDaily)
kiosk("QUEST BOARD", Vector3.new(0, 1, -25), COLORS.violet, "View quests", "3 daily challenges", function(p) openPanel(p, "Quests") end)
kiosk("PET SANCTUARY", Vector3.new(-25, 1, -14), COLORS.amber, "Adopt a pet", "Three collectible companions", function(p) openPanel(p, "Pets") end)
kiosk("WORLD PORTAL", Vector3.new(25, 1, -14), COLORS.sky, "See worlds", "Unlock two new regions", function(p) openPanel(p, "Worlds") end)

for _, zone in ipairs(ZONES) do
    local folder = Instance.new("Folder")
    folder.Name = zone.title
    folder.Parent = world
    local platform = makePart(zone.title .. " Floor", Vector3.new(52, 1, 52), zone.center + Vector3.new(0, -1.55, 0), COLORS.dark, Enum.Material.Slate, folder)
    platform.Color = zone.color:Lerp(COLORS.dark, 0.8)
    local arch = makePart("Zone Sign", Vector3.new(4, 9, 4), zone.center + Vector3.new(0, 3, -21), zone.color, Enum.Material.SmoothPlastic, folder)
    label(arch, zone.title, "Base yield: " .. zone.yield .. " energy" .. (if zone.price then " | Unlock " .. zone.price else ""))
    if zone.price then
        local gateway = makePart("World Access", Vector3.new(7, 5, 4), zone.center + Vector3.new(0, 1.8, -28), zone.color, Enum.Material.Neon, folder)
        label(gateway, "ACCESS " .. zone.title, "Unlock: " .. zone.price .. " credits")
        local access = Instance.new("ProximityPrompt")
        access.ActionText = "Unlock world"
        access.ObjectText = zone.title
        access.MaxActivationDistance = 11
        access.RequiresLineOfSight = false
        access.Parent = gateway
        access.Triggered:Connect(function(player)
            local character = player.Character
            local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
            if not root or not root:IsA("BasePart") or (root.Position - gateway.Position).Magnitude > 13 then return end
            unlockZone(player, zone.id)
        end)
    end
    for treeIndex = 1, 6 do
        local angle = (treeIndex - 1) * math.pi / 3
        local spot = zone.center + Vector3.new(math.cos(angle) * 32, 0, math.sin(angle) * 32)
        makePart("Tree Trunk", Vector3.new(2.2, 10, 2.2), spot + Vector3.new(0, 4.2, 0), COLORS.dark, Enum.Material.Wood, folder)
        local crown = makePart("Glowing Canopy", Vector3.new(9, 9, 9), spot + Vector3.new(0, 10, 0), zone.color, Enum.Material.SmoothPlastic, folder, Enum.PartType.Ball)
        crown.Transparency = 0.18
        local accent = makePart("Canopy Star", Vector3.new(3, 3, 3), spot + Vector3.new(0, 13, 0), zone.color, Enum.Material.Neon, folder, Enum.PartType.Ball)
        accent.CanCollide = false
    end

    for index = 1, CONFIG.CrystalsPerZone do
        local angle = 2 * math.pi * ((index - 1) / CONFIG.CrystalsPerZone)
        local radius = if index % 2 == 0 then 14 else 20
        local position = zone.center + Vector3.new(math.cos(angle) * radius, 1.2, math.sin(angle) * radius)
        local crystal = makePart("Crystal_" .. index, Vector3.new(3.2, 3.2, 3.2), position, zone.color, Enum.Material.Neon, folder, Enum.PartType.Ball)
        crystal.CanCollide = false
        local light = Instance.new("PointLight")
        light.Color = zone.color
        light.Range = 12
        light.Brightness = 1.3
        light.Parent = crystal
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "Gather"
        prompt.ObjectText = zone.title
        prompt.ActionText = "Gather crystal"
        prompt.MaxActivationDistance = 11
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        prompt.Parent = crystal
        local available = true
        prompt.Triggered:Connect(function(player: Player)
            if not available then return end
            local session = sessions[player]
            if not session or not session.ready then return end
            local char = player.Character
            local root = if char then char:FindFirstChild("HumanoidRootPart") else nil
            if not root or not root:IsA("BasePart") or (root.Position - crystal.Position).Magnitude > CONFIG.GatherRadius then return end
            local data = session.data
            if zone.price and not data.unlocked[zone.id] then
                toast(player, "Unlock " .. zone.title .. " in the Worlds menu first!")
                return
            end
            local free = energyCap(data) - data.energy
            if free <= 0 then
                toast(player, "Backpack full! Sell energy in Town Square.")
                return
            end
            -- Availability is checked and changed without yielding.
            available = false
            prompt.Enabled = false
            crystal.Transparency = 1
            light.Enabled = false
            local earned = math.min(free, zone.yield + data.upgrades.power + petBonus(data))
            data.energy += earned
            data.collected += 1
            updateCoinsStat(player, data)
            questProgress(session, "collector", 1)
            session.dirty = true
            sync(player)
            task.delay(CONFIG.RespawnSeconds, function()
                if not crystal.Parent then return end
                available = true
                crystal.Transparency = 0
                light.Enabled = true
                prompt.Enabled = true
            end)
        end)
    end
end

Lighting.ClockTime = 17.5
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(95, 100, 140)
Lighting.OutdoorAmbient = Color3.fromRGB(80, 95, 138)
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.22
atmosphere.Haze = 0.7
atmosphere.Color = Color3.fromRGB(190, 205, 255)
atmosphere.Decay = Color3.fromRGB(90, 85, 140)
atmosphere.Parent = Lighting
local bloom = Lighting:FindFirstChild("StarfallBloom") or Instance.new("BloomEffect")
bloom.Name = "StarfallBloom"
bloom.Intensity = 0.34
bloom.Size = 22
bloom.Threshold = 1.3
bloom.Parent = Lighting

Players.PlayerAdded:Connect(loadPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(loadPlayer, player)
end
Players.PlayerRemoving:Connect(function(player)
    local session = sessions[player]
    if session then
        local start = os.clock()
        while session.saving and os.clock() - start < 8 do task.wait(0.1) end
        save(player)
        sessions[player] = nil
    end
end)

task.spawn(function()
    while true do
        task.wait(CONFIG.SaveEverySeconds)
        for player in pairs(sessions) do task.spawn(save, player) end
    end
end)

game:BindToClose(function()
    local pending = 0
    for player in pairs(sessions) do
        pending += 1
        task.spawn(function()
            local s = sessions[player]
            local start = os.clock()
            while s and s.saving and os.clock() - start < 7 do task.wait(0.1) end
            save(player)
            pending -= 1
        end)
    end
    local start = os.clock()
    while pending > 0 and os.clock() - start < 25 do task.wait(0.1) end
end)

print("[Starfall] v2 worlds, pets, upgrades, leaderstats, quests, and pickups initialized.")
