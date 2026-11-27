return function(ctx)
local K_Page, ReplicatedStorage, S_Page, localPlayer = ctx.K_Page, ctx.ReplicatedStorage, ctx.S_Page, ctx.localPlayer
do
    local SLOTS = 3
    local SURVIVOR_PRESETS = {
        ["Gen Boost"] = {"Perfectionist Planning", "Group Project", "Enhanced Touch"},
        ["Looping"] = {"Quick Recovery", "Great Collapse", "Visual Learner"},
        ["Medic"] = {"Enhanced Touch", "Grab My Hand", "Against All Odds"},
    }
    local KILLER_PRESETS = {
        ["Anti Gen"] = {"Crackdown", "King's Scourge", "Buddha Shrine"},
        ["Fast Gameplay"] = {"Murderous Acrobatics", "Stage Fright", "Sloppy Mess"},
    }

    local function norm(text)
        return (tostring(text):lower():gsub("[^%w]", ""))
    end

    local function remote(folder, name)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local group = remotes and remotes:FindFirstChild(folder)
        return group and group:FindFirstChild(name)
    end

    local function invoke(rem, ...)
        if not rem then
            return nil
        end
        local ok, result = pcall(rem.InvokeServer, rem, ...)
        return ok and result or nil
    end

    local function wallet()
        return tonumber(localPlayer:GetAttribute("Screws")) or 0, tonumber(localPlayer:GetAttribute("Gears")) or 0
    end

    local function levels(data)
        local out = {}
        if type(data) == "table" then
            for name, value in pairs(data) do
                if type(name) == "string" then
                    local level = type(value) == "table" and (tonumber(value.level) or 1) or tonumber(value) or (value and 1 or 0)
                    out[name] = level
                end
            end
        end
        return out
    end

    local function realName(wanted, ...)
        local key = norm(wanted)
        for _, source in ipairs({...}) do
            if typeof(source) == "Instance" then
                for _, child in ipairs(source:GetChildren()) do
                    if norm(child.Name) == key then
                        return child.Name
                    end
                end
            elseif type(source) == "table" then
                for name in pairs(source) do
                    if type(name) == "string" and norm(name) == key then
                        return name
                    end
                end
            end
        end
        return nil
    end

    local function spend(ownedMap)

        local list = {}
        for name, level in pairs(ownedMap) do
            if level >= 1 then
                list[#list + 1] = name
            end
        end
        table.sort(list, function(a, b)
            if ownedMap[a] ~= ownedMap[b] then
                return ownedMap[a] > ownedMap[b]
            end
            return a < b
        end)
        return list
    end

    local function fillSlots(want, current, ownedMap, isAllowed)
        local used = {}
        for i = 1, SLOTS do
            if want[i] then
                used[want[i]] = true
            end
        end
        local alternatives = spend(ownedMap)
        for i = 1, SLOTS do
            if not want[i] then
                local keep = current[i]
                if keep and not used[keep] and (not isAllowed or isAllowed(keep)) then
                    want[i] = keep
                    used[keep] = true
                else
                    for _, name in ipairs(alternatives) do
                        if not used[name] and (not isAllowed or isAllowed(name)) then
                            want[i] = name
                            used[name] = true
                            break
                        end
                    end
                end
            end
        end
        return want
    end

    local Surv = {preset = "Gen Boost", buy = false, level = false, busy = false, noLevel = {}}

    local function survivorOwned()
        return levels(invoke(remote("Shop", "GetOwnedPerks")))
    end

    local function ensureSurvivorPerk(name, owned)
        local folder = ReplicatedStorage:FindFirstChild("Perks")
        local real = realName(name, owned, folder)
        if not real then
            return nil
        end
        if (owned[real] or 0) >= 1 then
            return real
        end
        local info = invoke(remote("Shop", "GetPerkInfo"), real)
        if type(info) == "table" and info.owned then
            owned[real] = tonumber(info.level) or 1
            return real
        end
        local buy = remote("Shop", "PurchasePerk")
        local _, gears = wallet()
        if buy and type(info) == "table" and tonumber(info.price) and gears >= tonumber(info.price) then
            buy:FireServer(real)
            task.wait(0.5)
            local after = invoke(remote("Shop", "GetPerkInfo"), real)
            if type(after) == "table" and after.owned then
                owned[real] = tonumber(after.level) or 1
                return real
            end
        end
        return nil
    end

    function Surv.buyPreset()
        local bought = 0
        local owned = survivorOwned()
        for _, name in ipairs(SURVIVOR_PRESETS[Surv.preset] or {}) do
            local real = realName(name, owned, ReplicatedStorage:FindFirstChild("Perks"))
            local had = real and (owned[real] or 0) >= 1
            if ensureSurvivorPerk(name, owned) and not had then
                bought += 1
            end
        end
        return bought
    end

    function Surv.equip()
        local owned = survivorOwned()
        local want = {}
        for i, name in ipairs(SURVIVOR_PRESETS[Surv.preset] or {}) do
            want[i] = ensureSurvivorPerk(name, owned)
        end
        local equipped = invoke(remote("Shop", "GetEquippedPerks"))
        local current = {}
        for i = 1, SLOTS do
            local entry = type(equipped) == "table" and equipped[i]
            current[i] = type(entry) == "table" and entry.name or nil
        end
        fillSlots(want, current, owned)
        local equip = remote("Shop", "EquipPerk")
        if not equip then
            return 0
        end
        local changed = 0
        for i = 1, SLOTS do
            if want[i] and current[i] ~= want[i] then
                equip:FireServer(want[i], i)
                changed += 1
                task.wait(0.35)
            end
        end
        return changed
    end

    function Surv.levelUp()
        local level = remote("Shop", "LevelUpPerk")
        if not level then
            return 0
        end
        local owned = survivorOwned()
        local order, seen = {}, {}
        for _, name in ipairs(SURVIVOR_PRESETS[Surv.preset] or {}) do
            local real = realName(name, owned)
            if real and not seen[real] then
                seen[real] = true
                order[#order + 1] = real
            end
        end
        for _, name in ipairs(spend(owned)) do
            if not seen[name] then
                seen[name] = true
                order[#order + 1] = name
            end
        end
        local count = 0
        for _, name in ipairs(order) do
            if not Surv.level then
                break
            end
            if (Surv.noLevel[name] or 0) < tick() then
                local screwsBefore = wallet()
                local before = owned[name]
                level:FireServer(name)
                task.wait(0.4)
                local info = invoke(remote("Shop", "GetPerkInfo"), name)
                local screwsAfter = wallet()
                if (type(info) == "table" and (tonumber(info.level) or 0) > (before or 0)) or screwsAfter < screwsBefore then
                    count += 1
                else
                    Surv.noLevel[name] = tick() + 120
                end
            end
        end
        return count
    end

    local Kill = {preset = "Anti Gen", buy = false, level = false, busy = false, noLevel = {}}

    local function selectedKiller()
        local result = invoke(remote("Shop", "GetSelectedKiller"))
        if type(result) == "table" then
            result = result.name or result.Name or result[1]
        end
        return type(result) == "string" and result ~= "" and result or nil
    end

    local function killerPool(killer)
        local killers = ReplicatedStorage:FindFirstChild("Killers")
        local folder = killers and killers:FindFirstChild(killer)
        return folder and folder:FindFirstChild("Perks")
    end

    local function killerUnlocked()
        return levels(invoke(remote("ShopKillers", "GetUnlockedPerks")))
    end

    local function ensureKillerPerk(name, killer, unlocked)
        local pool = killerPool(killer)
        local real = realName(name, pool or unlocked)
        if not real or (pool and not pool:FindFirstChild(real)) then
            return nil
        end
        if (unlocked[real] or 0) >= 1 then
            return real
        end
        local buy = remote("Shop", "PurchasePerk")
        local info = invoke(remote("Shop", "GetPerkInfo"), real)
        local _, gears = wallet()
        if buy and type(info) == "table" and not info.owned and tonumber(info.price) and gears >= tonumber(info.price) then
            buy:FireServer(real)
            task.wait(0.5)
            local fresh = killerUnlocked()
            if (fresh[real] or 0) >= 1 then
                unlocked[real] = fresh[real]
                return real
            end
        end
        return nil
    end

    function Kill.buyPreset()
        local killer = selectedKiller()
        if not killer then
            return 0
        end
        local bought = 0
        local unlocked = killerUnlocked()
        for _, name in ipairs(KILLER_PRESETS[Kill.preset] or {}) do
            local pool = killerPool(killer)
            local real = realName(name, pool or unlocked)
            local had = real and (unlocked[real] or 0) >= 1
            if ensureKillerPerk(name, killer, unlocked) and not had then
                bought += 1
            end
        end
        return bought
    end

    function Kill.equip()
        local killer = selectedKiller()
        local equip = remote("ShopKillers", "EquipPerk")
        if not (killer and equip) then
            return 0
        end
        local unlocked = killerUnlocked()
        local want = {}
        for i, name in ipairs(KILLER_PRESETS[Kill.preset] or {}) do
            want[i] = ensureKillerPerk(name, killer, unlocked)
        end
        local equipped = invoke(remote("ShopKillers", "GetEquippedKillerPerks"), killer)
        local current = {}
        for i = 1, SLOTS do
            local entry = type(equipped) == "table" and equipped["perk" .. i]
            current[i] = type(entry) == "table" and entry.name or nil
        end
        local pool = killerPool(killer)
        local usableOwned = {}
        for name, level in pairs(unlocked) do
            if not pool or pool:FindFirstChild(name) then
                usableOwned[name] = level
            end
        end
        fillSlots(want, current, usableOwned, function(name)
            return not pool or pool:FindFirstChild(name) ~= nil
        end)
        local changed = 0
        for i = 1, SLOTS do
            if want[i] and current[i] ~= want[i] then
                equip:FireServer(killer, want[i], "perk" .. i)
                changed += 1
                task.wait(0.35)
            end
        end
        return changed
    end

    function Kill.levelUp()
        local level = remote("Shop", "LevelUpPerk")
        local killer = selectedKiller()
        if not (level and killer) then
            return 0
        end
        local unlocked = killerUnlocked()
        local pool = killerPool(killer)
        local order, seen = {}, {}
        for _, name in ipairs(KILLER_PRESETS[Kill.preset] or {}) do
            local real = realName(name, unlocked)
            if real and not seen[real] then
                seen[real] = true
                order[#order + 1] = real
            end
        end
        for _, name in ipairs(spend(unlocked)) do
            if not seen[name] and (not pool or pool:FindFirstChild(name)) then
                seen[name] = true
                order[#order + 1] = name
            end
        end
        local count = 0
        for _, name in ipairs(order) do
            if not Kill.level then
                break
            end
            if (Kill.noLevel[name] or 0) < tick() then
                local screwsBefore = wallet()
                local before = unlocked[name] or 0
                level:FireServer(name)
                task.wait(0.4)
                local after = killerUnlocked()
                if (after[name] or 0) > before or wallet() < screwsBefore then
                    count += 1
                else
                    Kill.noLevel[name] = tick() + 120
                end
            end
        end
        return count
    end

    local function runLoop(side, tag, isMyRole)
        local lastKey
        while _G.MX.ScriptAlive do
            task.wait(3)
            if (side.buy or side.level) and not side.busy and isMyRole() then
                local screws, gears = wallet()
                local key = screws .. "/" .. gears .. "/" .. side.preset
                if key ~= lastKey then
                    lastKey = key
                    side.busy = true
                    local ok, err = pcall(function()
                        if side.buy and side.buyPreset() > 0 then
                            side.equip()
                        end
                        if side.level then
                            side.levelUp()
                        end
                    end)
                    if not ok then
                        warn("[MXHUB] " .. tag .. " perks: " .. tostring(err))
                    end
                    side.busy = false
                end
            end
        end
    end

    task.spawn(runLoop, Surv, "survivor", function()
        return true
    end)
    task.spawn(runLoop, Kill, "killer", function()
        return true
    end)

    local function option(value)
        if type(value) == "table" then
            return value[1]
        end
        return value
    end

    local function manual(side, label)
        return function()
            if side.busy then
                return
            end
            side.busy = true
            task.spawn(function()
                local ok, err = pcall(function()
                    side.buyPreset()
                    side.equip()
                end)
                if not ok then
                    warn("[MXHUB] " .. label .. " perks: " .. tostring(err))
                end
                side.busy = false
            end)
        end
    end

    local SP = S_Page:CreateSection("Perks", "award")
    SP:AddDropdown("Mode", {"Gen Boost", "Looping", "Medic"}, false, function(value)
        Surv.preset = option(value) or Surv.preset
    end, {Default = "Gen Boost", Flag = "SurvPerkPreset"})
    SP:AddToggle("Auto Buy Perks", false, function(on)
        Surv.buy = on
    end, {Flag = "SurvAutoBuyPerks"})
    SP:AddToggle("Auto Level Perks", false, function(on)
        Surv.level = on
    end, {Flag = "SurvAutoLevelPerks"})
    SP:AddButton("Equip Perk", manual(Surv, "survivor"))

    local KP = K_Page:CreateSection("Perks", "award")
    KP:AddDropdown("Mode", {"Anti Gen", "Fast Gameplay"}, false, function(value)
        Kill.preset = option(value) or Kill.preset
    end, {Default = "Anti Gen", Flag = "KillPerkPreset"})
    KP:AddToggle("Auto Buy Killer Perks", false, function(on)
        Kill.buy = on
    end, {Flag = "KillAutoBuyPerks"})
    KP:AddToggle("Auto Level Killer Perks", false, function(on)
        Kill.level = on
    end, {Flag = "KillAutoLevelPerks"})
    KP:AddButton("Equip Killer Perk", manual(Kill, "killer"))
end
end
