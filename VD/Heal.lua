return function(ctx)
local CollectionService, Players, ReplicatedStorage, SurvivorHealCard, localPlayer = ctx.CollectionService, ctx.Players, ctx.ReplicatedStorage, ctx.SurvivorHealCard, ctx.localPlayer
do
    local HealCard = SurvivorHealCard
    local H = {team = false, range = 15, bandage = false}

    local function healCandidate(myRoot)
        local best, bestDist = nil, H.range
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr ~= localPlayer and plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 and root:GetAttribute("CanGetHealed") == true
                and not char:GetAttribute("IsHooked") and not char:GetAttribute("IsCarried") then
                local d = (root.Position - myRoot.Position).Magnitude
                if d <= bestDist then
                    best, bestDist = root, d
                end
            end
        end
        return best
    end

    HealCard:AddToggle("Heal Team", false, function(v)
        H.team = v
    end, {Flag = "HealTeam"})

    task.spawn(function()
        while _G.MX.ScriptAlive do
            task.wait(0.25)
            if H.team and localPlayer.Team and localPlayer.Team.Name ~= "Killer" then
                pcall(function()
                    local char = localPlayer.Character
                    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                    local myHum = char and char:FindFirstChildOfClass("Humanoid")
                    if not (myRoot and myHum and myHum.Health > 0) or char:GetAttribute("Trapped") or char:GetAttribute("IsHooked")
                        or char:GetAttribute("IsCarried") then
                        return
                    end
                    local target = healCandidate(myRoot)
                    if not target or not _G.MX.Act.try("heal", 30) then
                        return
                    end
                    _G.MX.Net.heal(target, true)
                    local t0 = os.clock()
                    while H.team and _G.MX.ScriptAlive and os.clock() - t0 < 25 do
                        task.wait(0.2)
                        _G.MX.State.ForceSkillUntil = os.clock() + 2
                        local r = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not (r and target.Parent) or target:GetAttribute("CanGetHealed") ~= true
                            or (target.Position - r.Position).Magnitude > H.range + 5 then
                            break
                        end
                    end
                    _G.MX.Net.heal(target, false)
                    task.wait(0.3)
                end)
                _G.MX.Act.done("heal")
            end
        end
    end)

    local function bandageTool()
        local char = localPlayer.Character
        local backpack = localPlayer:FindFirstChildOfClass("Backpack")
        return (char and char:FindFirstChild("Bandage")) or (backpack and backpack:FindFirstChild("Bandage"))
    end

    HealCard:AddToggle("Infinite Bandage", false, function(v)
        H.bandage = v
    end, {Flag = "InfiniteBandage"})

    local bandageId = 1000
    task.spawn(function()
        local fire
        while _G.MX.ScriptAlive do
            task.wait(0.3)
            if H.bandage and localPlayer.Team and localPlayer.Team.Name ~= "Killer" then
                pcall(function()
                    local char = localPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local tool = bandageTool()
                    if not fire or not fire.Parent then
                        local r = ReplicatedStorage:FindFirstChild("Remotes")
                        local items = r and r:FindFirstChild("Items")
                        local bandage = items and items:FindFirstChild("Bandage")
                        fire = bandage and bandage:FindFirstChild("Fire")
                    end
                    if not (hum and tool and fire) or hum.Health <= 0 or hum.Health >= hum.MaxHealth
                        or char:GetAttribute("IsCarried") or char:GetAttribute("IsHooked") or char:GetAttribute("Trapped")
                        or CollectionService:HasTag(char, "Antiheal") or CollectionService:HasTag(char, "Silenced") then
                        return
                    end
                    bandageId += 1
                    local id = bandageId
                    fire:FireServer(true, tool, id)
                    local t0 = os.clock()
                    while H.bandage and os.clock() - t0 < 6 and hum.Health > 0 and hum.Health < hum.MaxHealth
                        and not char:GetAttribute("IsCarried") do
                        task.wait(0.15)
                    end
                    fire:FireServer(false, tool, id)
                    task.wait(0.2)
                end)
            end
        end
    end)
end
end
