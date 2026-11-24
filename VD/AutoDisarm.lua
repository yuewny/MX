return function(ctx)
local CollectionService, GetRole, ReplicatedStorage, TrapCard, lib, localPlayer = ctx.CollectionService, ctx.GetRole, ctx.ReplicatedStorage, ctx.TrapCard, ctx.lib, ctx.localPlayer
    do
        local Disarm = {on = false, token = 0, busy = false, cache = {}, cacheAt = 0}

        local function holderOf(inst)
            return inst:FindFirstAncestor("BearTrap") or inst
        end

        local function trapPosition(holder)
            if holder:IsA("Model") then
                return holder:GetPivot().Position
            elseif holder:IsA("BasePart") then
                return holder.Position
            end
            local part = holder:FindFirstChildWhichIsA("BasePart", true)
            return part and part.Position or nil
        end

        local function collectTraps()
            if os.clock() < Disarm.cacheAt then
                return Disarm.cache
            end
            Disarm.cacheAt = os.clock() + 1.5
            local list, seen = {}, {}
            local function add(inst)
                local holder = holderOf(inst)
                if holder and not seen[holder] and holder:IsDescendantOf(workspace) then
                    seen[holder] = true
                    list[#list + 1] = holder
                end
            end
            for _, inst in ipairs(CollectionService:GetTagged("BearTrap")) do
                add(inst)
            end
            local map = workspace:FindFirstChild("Map")
            if map then
                for _, d in ipairs(map:GetDescendants()) do
                    if d.Name == "BearTrap" and (d:IsA("Model") or d:IsA("BasePart")) then
                        add(d)
                    end
                end
            end
            Disarm.cache = list
            return list
        end

        local function disarmRemote()
            local r = ReplicatedStorage:FindFirstChild("Remotes")
            local k = r and r:FindFirstChild("Killers")
            local b = k and k:FindFirstChild("Butcher")
            return b and b:FindFirstChild("DisarmTrap")
        end

        local function nearestArmed(root)
            local best, bestDist = nil, 5
            for _, holder in ipairs(collectTraps()) do
                if holder.Parent and holder:GetAttribute("Armed") == true then
                    local pos = trapPosition(holder)
                    if pos then
                        local dist = (root.Position - pos).Magnitude
                        if dist < bestDist then
                            best, bestDist = holder, dist
                        end
                    end
                end
            end
            return best
        end

        local function disarmLoop(token)
            while Disarm.on and Disarm.token == token and not lib.API.Unloaded do
                task.wait(0.3)
                if not Disarm.busy and GetRole() == "Survivor" then
                    pcall(function()
                        local char = localPlayer.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        local remote = disarmRemote()
                        if not (root and remote) then
                            return
                        end
                        local trap = nearestArmed(root)
                        if not trap then
                            return
                        end
                        Disarm.busy = true
                        remote:FireServer("begin", trap)
                        local until_ = os.clock() + 5
                        while os.clock() < until_ and Disarm.on and Disarm.token == token and not lib.API.Unloaded do
                            task.wait(0.1)
                        end
                        if Disarm.on and Disarm.token == token then
                            remote:FireServer("commit")
                        end
                        task.wait(1.5)
                        Disarm.busy = false
                    end)
                    Disarm.busy = false
                end
            end
        end

        TrapCard:AddToggle("Auto Disarm Trap", false, function(on)
            Disarm.on = on
            Disarm.token += 1
            if on then
                task.spawn(disarmLoop, Disarm.token)
            end
        end, {Flag = "AutoDisarmTrap"})
        lib.API.Track(function()
            Disarm.on = false
            Disarm.token += 1
        end)
    end
end
