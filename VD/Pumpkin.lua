return function(ctx)
local CollectionService, PumpkinCard, ReplicatedStorage, localPlayer = ctx.CollectionService, ctx.PumpkinCard, ctx.ReplicatedStorage, ctx.localPlayer
    do
        local PumpCard = PumpkinCard
        local P = {farm = false, esp = false, cooldown = {}, fails = {}}
        local esp = {}
        local clearPathMarkers
        local candidates = {}

        local function pumpkinFolder()
            local map = workspace:FindFirstChild("Map")
            return map and map:FindFirstChild("Pumpkins")
        end
        local function hitbox(pumpkin)
            local hb = pumpkin:FindFirstChild("HB", true)
            if hb and hb:IsA("BasePart") and hb:IsDescendantOf(workspace) then
                return hb
            end
            return nil
        end
        local function crushRemote()
            local r = ReplicatedStorage:FindFirstChild("Remotes")
            local e = r and r:FindFirstChild("Events")
            local h = e and e:FindFirstChild("Halloween")
            return h and h:FindFirstChild("Crush")
        end

        local function addCandidate(part)
            if part and part:IsA("BasePart") then
                candidates[part] = true
            end
        end
        local function rescan()
            for part in pairs(candidates) do
                if not part.Parent or not part:IsDescendantOf(workspace) then
                    candidates[part] = nil
                end
            end
            for _, part in ipairs(CollectionService:GetTagged("pumpkin")) do
                addCandidate(part)
            end
            local folder = pumpkinFolder()
            if folder then
                for _, pumpkin in ipairs(folder:GetChildren()) do
                    addCandidate(hitbox(pumpkin))
                end
            end
        end
        CollectionService:GetInstanceAddedSignal("pumpkin"):Connect(addCandidate)
        CollectionService:GetInstanceRemovedSignal("pumpkin"):Connect(function(part)
            candidates[part] = nil
        end)
        rescan()

        PumpCard:AddToggle("Auto Stomp Pumpkins", false, function(v)
            P.farm = v
            if v then
                rescan()
            else
                clearPathMarkers()
            end
        end, {Flag = "PumpkinFarm"})

        _G.MX.SetPumpkinESP = function(v)
            P.esp = v
        end
        if _G.MX.WantPumpkinESP then
            P.esp = true
        end

        local function busyChar(char, hrp)
            return char:GetAttribute("Trapped") or char:GetAttribute("Knocked") or char:GetAttribute("IsHooked")
                or char:GetAttribute("IsCarried") or hrp:HasTag("doing action")
        end

        local function usable(part, now)
            return part.Parent ~= nil and part:IsDescendantOf(workspace)
                and not (part.Parent and CollectionService:HasTag(part.Parent, "Blocked"))
                and not CollectionService:HasTag(part, "doing action")
                and (P.cooldown[part] or 0) < now
        end

        local function nearestList(origin, limit)
            local now = tick()
            local list = {}
            for part in pairs(candidates) do
                if usable(part, now) then
                    list[#list + 1] = {part = part, dist = (part.Position - origin).Magnitude}
                end
            end
            table.sort(list, function(a, b)
                return a.dist < b.dist
            end)
            for i = #list, limit + 1, -1 do
                list[i] = nil
            end
            return list
        end

        local PathfindingService = game:GetService("PathfindingService")
        local function pathLength(from, goal)
            local path = PathfindingService:CreatePath({AgentRadius = 3, AgentHeight = 5.5, AgentCanJump = true, WaypointSpacing = 4})
            local ok = pcall(function()
                path:ComputeAsync(from, goal)
            end)
            if not ok or path.Status ~= Enum.PathStatus.Success then
                return nil
            end
            local total, prev = 0, from
            for _, wp in ipairs(path:GetWaypoints()) do
                total += (wp.Position - prev).Magnitude
                prev = wp.Position
            end
            return total, path:GetWaypoints()
        end

        local pathMarkers = {}
        clearPathMarkers = function()
            for i = #pathMarkers, 1, -1 do
                pcall(function() pathMarkers[i]:Destroy() end)
                pathMarkers[i] = nil
            end
        end
        local function showPathMarkers(waypoints)
            clearPathMarkers()
            if type(waypoints) ~= "table" then return end
            local cumulative, previous = 0, nil
            for index, waypoint in ipairs(waypoints) do
                local position = waypoint.Position
                if previous then cumulative += (position - previous).Magnitude end
                previous = position
                if index > 1 then
                    local marker = Instance.new("Part")
                    marker.Name = "MXHUBPumpkinPathNode"
                    marker.Shape = Enum.PartType.Ball
                    marker.Size = Vector3.new(0.42, 0.42, 0.42)
                    marker.Anchored = true
                    marker.CanCollide = false
                    marker.CanTouch = false
                    marker.CanQuery = false
                    marker.CastShadow = false
                    marker.Material = Enum.Material.Neon
                    marker.Color = Color3.fromRGB(255, 255, 255)
                    marker.Position = position + Vector3.new(0, 0.35, 0)
                    marker.Parent = workspace
                    local tag = Instance.new("BillboardGui")
                    tag.Name = "Distance"
                    tag.Size = UDim2.fromOffset(90, 22)
                    tag.StudsOffset = Vector3.new(0, 0.8, 0)
                    tag.AlwaysOnTop = true
                    tag.Adornee = marker
                    tag.Parent = marker
                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.fromScale(1, 1)
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 11
                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    label.TextStrokeTransparency = 0.25
                    label.Text = string.format("%.0f studs", cumulative)
                    label.Parent = tag
                    pathMarkers[#pathMarkers + 1] = marker
                end
            end
        end

        task.spawn(function()
            local lastScan = 0
            while _G.MX.ScriptAlive do
                if not P.farm then
                    task.wait(0.3)
                    continue
                end
                if os.clock() - lastScan > 3 then
                    lastScan = os.clock()
                    rescan()
                end
                local worked = false
                pcall(function()
                    local char = localPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local crush = crushRemote()
                    if not (hrp and hum and hum.Health > 0 and crush) or busyChar(char, hrp) then
                        return
                    end
                    local near = nearestList(hrp.Position, 15)
                    if #near == 0 then
                        return
                    end
                    if not _G.MX.Act.try("pumpkin", 90) then
                        return
                    end

                    local target, bestPath, bestWaypoints
                    for _, entry in ipairs(near) do
                        if not entry.part or not entry.part.Parent or not usable(entry.part, tick()) then
                            continue
                        end
                        if entry.dist <= 4 then
                            target, bestPath = entry.part, entry.dist
                            bestWaypoints = nil
                            break
                        end

                        local len, waypoints = pathLength(hrp.Position, entry.part.Position)
                        if len and waypoints and #waypoints > 0 then

                            local detourLimit = math.max(entry.dist * 3.5, entry.dist + 28)
                            if len <= detourLimit then
                                target, bestPath, bestWaypoints = entry.part, len, waypoints
                                break
                            end
                            P.fails[entry.part] = (P.fails[entry.part] or 0) + 1
                            P.cooldown[entry.part] = tick() + math.min(3 * P.fails[entry.part], 18)
                        else

                            P.fails[entry.part] = (P.fails[entry.part] or 0) + 1
                            P.cooldown[entry.part] = tick() + math.min(3 * P.fails[entry.part], 18)
                        end
                    end
                    if not target or not usable(target, tick()) then
                        return
                    end
                    worked = true

                    local function active()
                        local c = localPlayer.Character
                        local r = c and c:FindFirstChild("HumanoidRootPart")
                        return P.farm and _G.MX.ScriptAlive and target.Parent ~= nil and r ~= nil and not busyChar(c, r)
                            and not CollectionService:HasTag(target, "doing action")
                    end

                    if (hrp.Position - target.Position).Magnitude > 3.4 then
                        local limit = math.clamp(bestPath / math.max(hum.WalkSpeed, 8) * 2.2 + 6, 8, 60)
                        showPathMarkers(bestWaypoints)
                        local ok = _G.MX.Walker.walkTo(target.Position, {stop = 3.2, timeout = limit, active = active})
                        clearPathMarkers()
                        if not ok then
                            P.fails[target] = (P.fails[target] or 0) + 1
                            P.cooldown[target] = tick() + math.min(5 * P.fails[target], 30)
                            return
                        end
                    end
                    if target.Parent and active() and (hrp.Position - target.Position).Magnitude <= 4 then
                        _G.MX.Walker.face(target.Position)
                        task.wait(0.1)
                        crush:FireServer(target)
                        P.cooldown[target] = tick() + 3
                        P.fails[target] = nil

                        local t0 = tick()
                        while target.Parent and tick() - t0 < 0.9 and P.farm do
                            task.wait(0.05)
                        end
                    end
                end)
                clearPathMarkers()
                _G.MX.Act.done("pumpkin")

                task.wait(worked and 0.02 or 0.4)
            end
        end)

        local function clearEsp(pumpkin)
            local e = esp[pumpkin]
            if e then
                pcall(function()
                    e.hl:Destroy()
                end)
                pcall(function()
                    e.gui:Destroy()
                end)
                esp[pumpkin] = nil
            end
        end

        task.spawn(function()
            while _G.MX.ScriptAlive do
                task.wait(0.5)
                pcall(function()
                    local folder = pumpkinFolder()
                    if not P.esp or not folder then
                        for pumpkin in pairs(esp) do
                            clearEsp(pumpkin)
                        end
                        return
                    end
                    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    for pumpkin in pairs(esp) do
                        if not pumpkin.Parent or not hitbox(pumpkin) then
                            clearEsp(pumpkin)
                        end
                    end
                    for _, pumpkin in ipairs(folder:GetChildren()) do
                        local hb = hitbox(pumpkin)
                        if hb then
                            local e = esp[pumpkin]
                            if not e then
                                local hl = Instance.new("Highlight")
                                hl.FillColor = Color3.fromRGB(255, 140, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.45
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Adornee = pumpkin
                                hl.Parent = pumpkin
                                local gui = Instance.new("BillboardGui")
                                gui.Size = UDim2.fromOffset(110, 22)
                                gui.StudsOffset = Vector3.new(0, 3, 0)
                                gui.AlwaysOnTop = true
                                gui.Adornee = hb
                                gui.Parent = hb
                                local label = Instance.new("TextLabel")
                                label.Size = UDim2.fromScale(1, 1)
                                label.BackgroundTransparency = 1
                                label.TextColor3 = Color3.fromRGB(255, 170, 40)
                                label.TextStrokeTransparency = 0.4
                                label.Font = Enum.Font.GothamBold
                                label.TextSize = 13
                                label.Parent = gui
                                e = {hl = hl, gui = gui, label = label}
                                esp[pumpkin] = e
                            end
                            if hrp then
                                e.label.Text = string.format("Pumpkin [%d]", (hb.Position - hrp.Position).Magnitude)
                            end
                        end
                    end
                end)
            end
        end)
    end
end
