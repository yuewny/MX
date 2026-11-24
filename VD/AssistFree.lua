return function(ctx)
local CollectionService, Players, ReplicatedStorage, TrapCard, localPlayer = ctx.CollectionService, ctx.Players, ctx.ReplicatedStorage, ctx.TrapCard, ctx.localPlayer
    do
        local Help = {on = false, range = 15, busy = false, rejectedAt = 0, beganAt = 0, skip = {}}

        local function assistRemote()
            local r = ReplicatedStorage:FindFirstChild("Remotes")
            local k = r and r:FindFirstChild("Killers")
            local b = k and k:FindFirstChild("Butcher")
            return b and b:FindFirstChild("AssistFree")
        end

        task.spawn(function()
            local rem
            while _G.MX.ScriptAlive and not rem do
                rem = assistRemote()
                task.wait(0.5)
            end
            if rem then
                rem.OnClientEvent:Connect(function(msg, ...)
                    if msg == "rejected" then
                        Help.rejectedAt = os.clock()
                    elseif msg == "began" then
                        Help.beganAt = os.clock()
                    elseif msg ~= nil then

                        warn("[MXHUB] AssistFree server ->", msg, ...)
                    end
                end)
            end
        end)

        local function helperEligible()
            local char = localPlayer.Character
            if not char then
                return false
            end
            if char:GetAttribute("Trapped") or char:GetAttribute("Knocked") or char:GetAttribute("IsHooked") or char:GetAttribute("IsCarried") then
                return false
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                return false
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            return root ~= nil and not root:HasTag("doing action")
        end

        local function helperAlive()
            local char = localPlayer.Character
            if not char then
                return false
            end
            if char:GetAttribute("Trapped") or char:GetAttribute("Knocked") or char:GetAttribute("IsHooked") or char:GetAttribute("IsCarried") then
                return false
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            return hum ~= nil and hum.Health > 0
        end

        local function pickTarget()
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then
                return nil
            end
            local best, bestDist = nil, Help.range
            local candidates, seen = {}, {}
            local function addCandidate(model)
                if model and model ~= char and not seen[model] then
                    seen[model] = true
                    table.insert(candidates, model)
                end
            end
            for _, model in ipairs(CollectionService:GetTagged("Survivor")) do
                addCandidate(model)
            end

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Team and player.Team.Name == "Survivor" then
                    addCandidate(player.Character)
                end
            end
            for _, m in ipairs(candidates) do
                if m:GetAttribute("Trapped") == true and not m:GetAttribute("BeingRescued")
                    and (Help.skip[m] or 0) < os.clock() then
                    local r = m:FindFirstChild("HumanoidRootPart")
                    if r then
                        local d = (r.Position - root.Position).Magnitude
                        if d <= bestDist then
                            best, bestDist = m, d
                        end
                    end
                end
            end
            return best
        end

        local function helpOne(target)
            local rem = assistRemote()
            if not rem then
                return
            end

            local function stillValid()
                return Help.on and _G.MX.ScriptAlive and target.Parent ~= nil and target:GetAttribute("Trapped") == true
                    and helperAlive()
            end

            local function abort()
                rem:FireServer("cancel")
                Help.skip[target] = os.clock() + 3
            end

            local t0 = os.clock()
            rem:FireServer("begin", target)

            while os.clock() - t0 < 1.5 and Help.beganAt <= t0 and Help.rejectedAt <= t0 do
                task.wait(0.05)
            end
            if Help.rejectedAt > t0 or not stillValid() then
                abort()
                return
            end

            local startedAt = (Help.beganAt > t0) and Help.beganAt or t0
            local ok = true
            while os.clock() - startedAt < 7.1 do
                task.wait(0.1)
                if Help.rejectedAt > t0 or not stillValid() then
                    ok = false
                    break
                end
            end

            if ok then
                rem:FireServer("commit")
            else
                abort()
            end
        end

        task.spawn(function()
            while _G.MX.ScriptAlive do
                task.wait(0.3)
                if Help.on and not Help.busy and helperEligible()
                    and localPlayer.Team and localPlayer.Team.Name ~= "Killer" then
                    local target = pickTarget()
                    if target and _G.MX.Act.try("help", 90) then
                        Help.busy = true
                        pcall(helpOne, target)
                        Help.busy = false
                        _G.MX.Act.done("help")
                        task.wait(0.5)
                    end
                end
            end
        end)

        TrapCard:AddToggle("Auto Help Trap Team", false, function(v)
            Help.on = v
        end, {Flag = "AutoHelpTrapTeam"})

    end
end
