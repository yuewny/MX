return function(ctx)
local CollectionService, IsDowned, KillerAbilityCard, SilentCard, Players, ReplicatedStorage, UserInputService, localPlayer = ctx.CollectionService, ctx.IsDowned, ctx.KillerAbilityCard, ctx.SilentCard, ctx.Players, ctx.ReplicatedStorage, ctx.UserInputService, ctx.localPlayer
do
    local RS = game:GetService("RunService")

    local function killerRemote(group, name)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local killers = remotes and remotes:FindFirstChild("Killers")
        local folder = killers and killers:FindFirstChild(group)
        return folder and folder:FindFirstChild(name)
    end

    local function isKiller()
        return localPlayer.Team ~= nil and localPlayer.Team.Name == "Killer"
    end

    local function selectedKiller()
        local value = localPlayer:GetAttribute("SelectedKiller")
        if not value then
            local obj = localPlayer:FindFirstChild("SelectedKiller")
            if obj then
                pcall(function()
                    value = obj.Value
                end)
            end
        end
        local char = localPlayer.Character
        value = value or (char and char:GetAttribute("SelectedKiller")) or (char and char:GetAttribute("Killer"))
        return type(value) == "string" and string.lower(value) or nil
    end

    local function isKillerType(word)
        local name = selectedKiller()
        return isKiller() and (name == nil or string.find(name, word, 1, true) ~= nil)
    end

    local function survivorList()
        local out = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            local c = plr.Character
            if plr ~= localPlayer and c and plr.Team and plr.Team.Name == "Survivors" then
                out[#out + 1] = c
            end
        end
        for _, bot in ipairs(CollectionService:GetTagged("SurvivorBot")) do
            if bot:IsDescendantOf(workspace) then
                out[#out + 1] = bot
            end
        end
        return out
    end

    local function alive(c)
        local hum = c:FindFirstChildOfClass("Humanoid")
        local root = c:FindFirstChild("HumanoidRootPart")
        if not (hum and root) or hum.Health <= 0 then
            return nil
        end
        if c:GetAttribute("IsHooked") or c:GetAttribute("IsDead") or c:GetAttribute("Dead") then
            return nil
        end
        local okDown, down = pcall(IsDowned, c)
        if okDown and down then
            return nil
        end
        return root
    end

    local function lineClear(from, to, ignoreA, ignoreB)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {ignoreA, ignoreB}
        params.IgnoreWater = true
        local hit = workspace:Raycast(from, to - from, params)
        return hit == nil or hit.Instance.Transparency >= 0.5 or not hit.Instance.CanCollide
    end

    local function pickTarget(origin, maxDist, minDot, rootCharacter)
        local cam = workspace.CurrentCamera
        if not cam then
            return nil
        end
        local look = cam.CFrame.LookVector
        local best, bestRoot, bestScore = nil, nil, minDot
        for _, c in ipairs(survivorList()) do
            local root = alive(c)
            if root then
                local delta = root.Position - origin
                local dist = delta.Magnitude
                if dist <= maxDist and dist > 0.5 then
                    local dot = look:Dot(delta.Unit)
                    if dot >= bestScore and lineClear(origin, root.Position, rootCharacter, c) then
                        best, bestRoot, bestScore = c, root, dot
                    end
                end
            end
        end
        return best, bestRoot
    end

    local function velocityOf(root)
        local v = root.AssemblyLinearVelocity
        return Vector3.new(v.X, 0, v.Z)
    end

    local KA = {flaskOn = false, hiddenOn = false}
    _G.MX.KAim = KA

    local FLASK_SPEED, FLASK_GRAVITY, FLASK_UP, FLASK_TRAVEL = 95, 196.2, 0.35, 70
    pcall(function()
        local m = require(ReplicatedStorage.Modules.Killers.Cure.FlaskTrajectory)
        FLASK_SPEED = m.ThrowSpeed or FLASK_SPEED
        FLASK_GRAVITY = -(m.Gravity and m.Gravity.Y or -196.2)
        FLASK_UP = m.UpBias or FLASK_UP
        FLASK_TRAVEL = m.TravelSpeed or FLASK_TRAVEL
    end)

    function KA.flask(look, pos, id, stamp)
        local char = localPlayer.Character
        if not (char and typeof(look) == "Vector3" and typeof(pos) == "Vector3") then
            return nil
        end
        local reach = FLASK_SPEED * FLASK_SPEED / FLASK_GRAVITY
        local target, root = pickTarget(pos, reach - 2, 0.5, char)
        if not target then
            return nil
        end
        local aimPos = root.Position + Vector3.new(0, 0.5, 0)
        local flightTime = (aimPos - pos).Magnitude * 1.1 / FLASK_TRAVEL
        aimPos = aimPos + velocityOf(root) * flightTime
        local delta = aimPos - pos
        local flat = Vector3.new(delta.X, 0, delta.Z)
        local d, h = flat.Magnitude, delta.Y
        if d < 1 then
            return nil
        end
        local v2, g = FLASK_SPEED * FLASK_SPEED, FLASK_GRAVITY
        local disc = v2 * v2 - g * (g * d * d + 2 * h * v2)
        if disc < 0 then
            return nil
        end
        local tanTheta = (v2 - math.sqrt(disc)) / (g * d)
        local theta = math.atan(tanTheta)
        local launch = flat.Unit * math.cos(theta) + Vector3.new(0, math.sin(theta), 0)
        local lu = launch.Y * FLASK_UP
        local k = lu + math.sqrt(lu * lu + 1 - FLASK_UP * FLASK_UP)
        local newLook = launch * k - Vector3.new(0, FLASK_UP, 0)
        if newLook.Magnitude < 0.01 then
            return nil
        end
        return newLook.Unit, pos, id, stamp
    end

    task.spawn(function()
        KA.flaskRemote = killerRemote("Cure", "ThrowFlask")
        if not KA.flaskRemote then
            local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
            local killers = remotes and remotes:WaitForChild("Killers", 10)
            local cure = killers and killers:WaitForChild("Cure", 10)
            KA.flaskRemote = cure and cure:WaitForChild("ThrowFlask", 10)
        end
    end)

    SilentCard:AddToggle("Silent Flask (Cure)", false, function(on)
        KA.flaskOn = on
    end, {Flag = "SilentAimFlask"})

    local CHAIN_SPEED, CHAIN_RANGE, CHAIN_MIN_DOT = 140, 50, -0.2
    KA.chainOn = false
    local function canLatch(model)
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            return false
        end
        return not (model:GetAttribute("Knocked") or model:GetAttribute("IsHooked") or model:GetAttribute("IsCarried")
            or model:GetAttribute("IsCarrying") or model:GetAttribute("Trapped"))
    end
    function KA.chain(dir)
        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (hrp and typeof(dir) == "Vector3") then
            return nil
        end
        local head = char:FindFirstChild("Head")
        local origin = head and head.Position or hrp.Position
        local target, root = pickTarget(origin, CHAIN_RANGE, 0.35, char)
        if not target or not root or not canLatch(root.Parent) then
            return nil
        end
        local dist = (root.Position - origin).Magnitude
        if dist > CHAIN_RANGE then
            return nil
        end
        local hum = root.Parent:FindFirstChildOfClass("Humanoid")
        local vel
        if hum.MoveDirection.Magnitude > 0 then
            vel = hum.MoveDirection * hum.WalkSpeed
        else
            local v = velocityOf(root)
            vel = Vector3.new(v.X, 0, v.Z)
        end
        local aim = root.Position
        for _ = 1, 4 do
            aim = root.Position + vel * ((aim - origin).Magnitude / CHAIN_SPEED)
        end
        local delta = aim - origin
        if delta.Magnitude < 0.5 then
            return nil
        end
        local flat = Vector3.new(delta.X, 0, delta.Z)
        local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
        if flat.Magnitude > 0.2 and look.Magnitude > 0.001 and flat.Unit:Dot(look.Unit) < CHAIN_MIN_DOT then
            return nil
        end
        return delta.Unit
    end

    SilentCard:AddToggle("Silent Chain (Butcher)", false, function(on)
        KA.chainOn = on
    end, {Flag = "SilentAimChain"})

    local HL = {held = {}, releaseAt = 0, target = nil}
    local keybinds
    pcall(function()
        keybinds = require(ReplicatedStorage.Modules.Survivors.KeybindsConfig)
    end)
    local function isSkillInput(input)
        if not keybinds then
            return false
        end
        local ok, a1 = pcall(keybinds.matches, "ability1", input)
        local ok2, a2 = pcall(keybinds.matches, "ability2", input)
        return (ok and a1) or (ok2 and a2)
    end
    UserInputService.InputBegan:Connect(function(input)
        if isSkillInput(input) then
            HL.held[input] = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if HL.held[input] then
            HL.held[input] = nil
            HL.releaseAt = os.clock()
        end
    end)

    KillerAbilityCard:AddToggle("Aim Lock (The Hidden) - hold skill key", false, function(on)
        KA.hiddenOn = on
        HL.target = nil
    end, {Flag = "AimLockHidden"})

    RS.Heartbeat:Connect(function(dt)
        if not KA.hiddenOn then
            return
        end
        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (hrp and isKillerType("hidden")) then
            HL.target = nil
            return
        end
        local leaping = char:GetAttribute("ForensicsLaunch") == true or char:GetAttribute("LeapRecovering") == true
        local active = next(HL.held) ~= nil or leaping or os.clock() - HL.releaseAt < 0.9
        if not active then
            HL.target = nil
            return
        end

        local root = HL.target
        if not (root and root.Parent and alive(root.Parent) and (root.Position - hrp.Position).Magnitude < 90) then
            root = nil
            local bestDist = 70
            for _, c in ipairs(survivorList()) do
                local r = alive(c)
                if r then
                    local d = (r.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        root, bestDist = r, d
                    end
                end
            end
            HL.target = root
        end
        if not root then
            return
        end
        local lead = (root.Position - hrp.Position).Magnitude / 65
        local aimPos = root.Position + velocityOf(root) * math.min(lead, 0.5)
        local alpha = 1 - math.exp(-dt * 22)
        local cam = workspace.CurrentCamera
        if cam then
            cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, aimPos), alpha)
        end
        local goal = CFrame.lookAt(hrp.Position, Vector3.new(aimPos.X, hrp.Position.Y, aimPos.Z))
        local turned = hrp.CFrame:Lerp(goal, alpha)
        hrp.CFrame = CFrame.new(hrp.Position) * (turned - turned.Position)
    end)

    local S = {on = false, holding = false, started = nil, lastHold = 0}

    local function stalkerRemotes()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local killers = remotes and remotes:FindFirstChild("Killers")
        local folder = killers and killers:FindFirstChild("Stalker")
        if not folder then
            return nil
        end
        return folder:FindFirstChild("StartStalking"), folder:FindFirstChild("StopStalking"), folder:FindFirstChild("StalkHold")
    end

    local function clearLine(fromChar, toChar)
        local a = fromChar:FindFirstChild("HumanoidRootPart")
        local b = toChar:FindFirstChild("HumanoidRootPart")
        if not (a and b) then
            return false
        end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {fromChar, toChar}
        local origin, delta = a.Position, b.Position - a.Position
        for _ = 1, 10 do
            local hit = workspace:Raycast(origin, delta, params)
            if not hit then
                return true
            end
            if hit.Instance.Transparency < 0.99 or hit.Instance:HasTag("TrueInvis") then
                return false
            end
            local list = params.FilterDescendantsInstances
            list[#list + 1] = hit.Instance
            params.FilterDescendantsInstances = list
        end
        return false
    end

    local function bestTarget(char, hrp)
        local best, bestChar, bestDist = nil, nil, 100
        local function consider(handle, model)
            local root = model:FindFirstChild("HumanoidRootPart")
            local hum = model:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 and hum.Health / hum.MaxHealth > 0.5
                and not model:GetAttribute("IsHooked") and not model:GetAttribute("IsDead") then
                local d = (root.Position - hrp.Position).Magnitude
                if d <= bestDist and clearLine(char, model) then
                    best, bestChar, bestDist = handle, model, d
                end
            end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer and plr.Character and plr.Team and plr.Team.Name == "Survivors" then
                consider(plr, plr.Character)
            end
        end
        for _, bot in ipairs(CollectionService:GetTagged("SurvivorBot")) do
            if bot:IsDescendantOf(workspace) then
                consider(bot, bot)
            end
        end
        return best, bestChar
    end

    local function stopStalk(stop, hold)
        if S.started and stop then
            pcall(function()
                stop:FireServer()
            end)
        end
        if S.holding and hold then
            pcall(function()
                hold:FireServer(false)
            end)
        end
        S.started, S.holding = nil, false
    end

    task.spawn(function()
        while _G.MX.ScriptAlive do
            task.wait(0.15)
            local start, stop = stalkerRemotes()
            local char = localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local blocked = char and (char:GetAttribute("IsCarrying") or char:GetAttribute("IsStunned") or char:GetAttribute("Stage") == 2)
            local interact = char and char:FindFirstChild("CheckInterractable")
            if interact and interact:GetAttribute("action") then
                blocked = true
            end

            local isStalker = char ~= nil and char:GetAttribute("Stage") ~= nil and localPlayer.Team ~= nil and localPlayer.Team.Name == "Killer"
            if S.on and start and stop and hrp and isStalker and not blocked then
                pcall(function()
                    local handle = bestTarget(char, hrp)
                    if not handle then
                        if S.started then
                            stop:FireServer()
                            S.started = nil
                        end
                        return
                    end

                    if S.started ~= handle or os.clock() - S.lastHold >= 1.5 then
                        if S.started and S.started ~= handle then
                            stop:FireServer()
                        end
                        start:FireServer(handle)
                        S.started, S.lastHold = handle, os.clock()
                    end
                end)
            elseif S.started then
                pcall(function()
                    if stop then
                        stop:FireServer()
                    end
                end)
                S.started = nil
            end
        end
    end)

    KillerAbilityCard:AddToggle("Auto Stalk (Stalker)", false, function(on)
        S.on = on
        if not on then
            local _, stop = stalkerRemotes()
            stopStalk(stop, nil)
        end
    end, {Flag = "AutoStalk"})
end
end
