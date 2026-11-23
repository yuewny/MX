return function(ctx)
    local LagCard, lib, localPlayer, RunService = ctx.LagCard, ctx.lib, ctx.localPlayer, ctx.RunService

    local SELF_NAME, FOLLOW_NAME, STEP_NAME = "MXSelfView", "MXFollowClone", "MXCloneStep"

    local State = {clone = false, lag = false, offset = -4, lagMs = 300, followOffset = Vector3.zero}
    _G.MX.Invis = State

    local lagLast, lagState = 0, false
    local savedTransparency = {}
    local heartbeat

    function State.active()
        return State.clone or State.lag
    end

    local function flatLook(cf)
        local look = cf.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude < 0.001 then
            return Vector3.new(0, 0, -1)
        end
        return flat.Unit
    end

    function State.rewrite(...)
        local args = table.pack(...)
        if typeof(args[2]) ~= "CFrame" then
            return nil
        end
        local changed = false
        if State.clone then
            args[2] = args[2] + State.followOffset
            changed = true
        end
        if State.lag then
            local now = os.clock()
            if now - lagLast >= math.max(0.02, State.lagMs / 1000) then
                lagLast = now
                lagState = not lagState
            end
            if lagState then
                local cf = args[2]
                args[2] = CFrame.new(cf.Position - flatLook(cf) * math.random(3, 9)) * cf.Rotation
                changed = true
            end
        end
        return changed and args or nil
    end

    local function motorKey(motor)
        return (motor.Part0 and motor.Part0.Name or "?") .. ">" .. motor.Name .. ">" .. (motor.Part1 and motor.Part1.Name or "?")
    end

    local function destroyNamed(name)
        local object = workspace:FindFirstChild(name)
        if object then
            object:Destroy()
        end
    end

    local function buildClone(char, name)
        destroyNamed(name)
        local archivable = char.Archivable
        char.Archivable = true
        local clone = char:Clone()
        char.Archivable = archivable
        if not clone then
            return nil
        end
        clone.Name = name
        for _, descendant in ipairs(clone:GetDescendants()) do
            if descendant:IsA("LuaSourceContainer") or descendant:IsA("Highlight") or descendant:IsA("BillboardGui") or descendant:IsA("Animator") then
                descendant:Destroy()
            elseif descendant:IsA("BasePart") then
                descendant.CanCollide = false
                descendant.CanTouch = false
                descendant.CanQuery = false
                descendant.Massless = true
                descendant.Anchored = false
            end
        end
        local humanoid = clone:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            humanoid.PlatformStand = true
            humanoid.AutoRotate = false
            humanoid.WalkSpeed = 0
        end
        local root = clone:FindFirstChild("HumanoidRootPart")
        if root then
            root.Anchored = true
            root.Transparency = 1
            clone.PrimaryPart = root
        end
        clone.Parent = workspace
        return clone
    end

    local function syncMotors(real, clone)
        if not (real and clone and clone.Parent) then
            return
        end
        local map = {}
        for _, motor in ipairs(clone:GetDescendants()) do
            if motor:IsA("Motor6D") then
                map[motorKey(motor)] = motor
            end
        end
        for _, motor in ipairs(real:GetDescendants()) do
            if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
                local target = map[motorKey(motor)]
                if target then
                    target.C0, target.C1, target.Transform = motor.C0, motor.C1, motor.Transform
                end
            end
        end
    end

    local function hideReal(char)
        table.clear(savedTransparency)
        for _, descendant in ipairs(char:GetDescendants()) do
            if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
                savedTransparency[descendant] = descendant.Transparency
                descendant.Transparency = 1
            end
        end
    end

    local function showReal()
        for instance, transparency in pairs(savedTransparency) do
            if typeof(instance) == "Instance" and instance.Parent then
                instance.Transparency = transparency
            end
        end
        table.clear(savedTransparency)
    end

    local function stepOffset(dt)
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        local desired = flatLook(root.CFrame) * State.offset
        local alpha = 1 - math.exp(-1.8 * math.clamp(dt or 0.016, 0, 0.05))
        State.followOffset = State.followOffset:Lerp(desired, alpha)
    end

    local function startClone()
        local char = localPlayer.Character
        if not char then
            return
        end
        State.followOffset = Vector3.zero
        stepOffset(1)
        buildClone(char, SELF_NAME)
        buildClone(char, FOLLOW_NAME)
        hideReal(char)
        heartbeat = RunService.Heartbeat:Connect(function(dt)
            if State.clone then
                stepOffset(dt)
            end
        end)
        pcall(RunService.UnbindFromRenderStep, RunService, STEP_NAME)
        RunService:BindToRenderStep(STEP_NAME, Enum.RenderPriority.Last.Value, function()
            if not State.clone then
                return
            end
            local current = localPlayer.Character
            local root = current and current:FindFirstChild("HumanoidRootPart")
            if not root then
                return
            end
            local selfView = workspace:FindFirstChild(SELF_NAME)
            local selfRoot = selfView and selfView:FindFirstChild("HumanoidRootPart")
            if selfRoot then
                selfRoot.CFrame = root.CFrame
                syncMotors(current, selfView)
            end
            local follow = workspace:FindFirstChild(FOLLOW_NAME)
            local followRoot = follow and follow:FindFirstChild("HumanoidRootPart")
            if followRoot then
                followRoot.CFrame = root.CFrame + State.followOffset
                syncMotors(current, follow)
            end
        end)
    end

    local function stopClone()
        if heartbeat then
            heartbeat:Disconnect()
            heartbeat = nil
        end
        pcall(RunService.UnbindFromRenderStep, RunService, STEP_NAME)
        destroyNamed(SELF_NAME)
        destroyNamed(FOLLOW_NAME)
        showReal()
        State.followOffset = Vector3.zero
    end

    local function setClone(on)
        if on == State.clone then
            return
        end
        State.clone = on
        if on then
            startClone()
        else
            stopClone()
        end
    end

    local respawn = localPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if State.clone then
            State.clone = false
            setClone(true)
        end
    end)

    LagCard:AddToggle("Fake Clone", false, setClone, {Flag = "FakeClone"})
    LagCard:AddSlider("Clone Offset", -15, 15, -4, function(value)
        State.offset = value
    end, {Increment = 1, Flag = "FakeCloneOffset"})
    LagCard:AddToggle("Fake Lag", false, function(on)
        State.lag = on
        lagLast, lagState = 0, false
    end, {Flag = "FakeLag"})
    LagCard:AddSlider("Fake Lag Interval (ms)", 50, 1000, 300, function(value)
        State.lagMs = value
    end, {Increment = 10, Flag = "FakeLagMs"})

    lib.API.Track(function()
        State.lag = false
        setClone(false)
        respawn:Disconnect()
        _G.MX.Invis = nil
    end)
end
