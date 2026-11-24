return function(ctx)
local CollectionService, CoreGui, IsDowned, PistolSection, Players, ReplicatedStorage, RunService, UserInputService, localPlayer, playerGui = ctx.CollectionService, ctx.CoreGui, ctx.IsDowned, ctx.PistolSection, ctx.Players, ctx.ReplicatedStorage, ctx.RunService, ctx.UserInputService, ctx.localPlayer, ctx.playerGui
local GetSCPs, clearLaser, createTargetSelectorUI, destroyTargetSelectorUI, doShoot, getGunObject, getTargetPosition, hookMobileButtons, isTargetVisible, setupMobileButton, startConnection, stopConnection, updateLaser
    local fire
    do
        local okFire, fireRemote = pcall(function()
            return ReplicatedStorage:WaitForChild("Remotes", 10):WaitForChild("Items", 10)["Twist of Fate"].Fire
        end)
        if okFire and fireRemote then
            fire = fireRemote
        else
            warn("[MXHUB] Twist of Fate remote not found; related features are disabled")
            fire = {FireServer = function() end}
        end
    end
    _G.MX.SilentShot = false
    local flag4 = false
    local flag5 = true
    local flag6 = false
    local flag7 = true
    local flag8 = false
    local connection2 = nil
    local part = nil
    local str = "Killer"
    UDim2.new(0.5, -120, 0, 110)
    local tbl8 = {}

    local tbl9 = {
        PredictionEfficiency = 0.9,
        LerpSmoothness = 0.45,
        EnableJitter = false,
        MaxJitterStuds = 0,
        ProjectileSpeed = 4000,
        MaxLead = 0.25,
        PingComp = true,
        AccelPredict = true,
        FOVDot = 0.5,
        SkipDowned = true,
        TargetBody = "Torso",
    }

    getGunObject = function()
        local character = localPlayer.Character
        if not character then
            return nil
        end
        local cg = tbl9.GunCache
        if cg and cg.Parent and cg:IsDescendantOf(character) then
            return cg
        end
        tbl9.GunCache = nil
        local twistOfFate = character:FindFirstChild("Twist of Fate", true)
        if not twistOfFate then
            return nil
        end
        local names = {"barrel", "smokepart", "muzzle", "gun", "emperorgun", "shoot", "handle"}
        local rank, found = math.huge, nil
        for _, d in ipairs(twistOfFate:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Model") then
                local lname = string.lower(d.Name)
                for i, want in ipairs(names) do
                    if i < rank and lname == want then
                        rank, found = i, d
                    end
                end
            end
        end
        if not found then
            local arm = twistOfFate:FindFirstChild("Right Arm")
            local gunLike = arm and (arm:FindFirstChild("gun") or arm:FindFirstChild("EmperorGun"))
            found = gunLike or twistOfFate.PrimaryPart or twistOfFate:FindFirstChildWhichIsA("BasePart", true)
        end
        if found then
            tbl9.GunCache = found
            return found
        end

        return twistOfFate
    end

    isTargetVisible = function(arg, arg2, arg3)
        local n2 = arg2 - arg
        local magnitude = n2.Magnitude
        if magnitude < 0.1 then
            return true
        end
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        local filterDescendantsInstances = {}
        local character = localPlayer.Character

        if character then
            table.insert(filterDescendantsInstances, character)
        end

        if arg3 and arg3 ~= character then
            table.insert(filterDescendantsInstances, arg3)
        end

        if part then
            table.insert(filterDescendantsInstances, part)
        end

        raycastParams.FilterDescendantsInstances = filterDescendantsInstances
        local flag9 = workspace:Raycast(arg, n2.Unit * magnitude, raycastParams) == nil
        return flag9
    end

    local tbl10 = {}
    local n2 = 0

    GetSCPs = function()
        if tick() - n2 < 1.5 then
            return tbl10
        end
        local tbl11 = {}
        local map = workspace:FindFirstChild("Map")

        if map then
            for k, descendant in pairs(map:GetDescendants()) do
                if descendant:IsA("Model") then
                    local attributes = descendant:GetAttributes()

                    if descendant:GetAttribute("CorpseCreated0492") or next(attributes) ~= nil then
                        local humanoidRootPart = descendant:FindFirstChild("HumanoidRootPart")

                        if humanoidRootPart then
                            table.insert(tbl11, humanoidRootPart)
                        end
                    end
                end
            end
        end

        tbl10 = tbl11
        n2 = tick()
        return tbl10
    end

    local StatsService = game:GetService("Stats")
    local function getPingSeconds()
        local ok, v = pcall(function()
            return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok and type(v) == "number" then
            return math.clamp(v / 1000, 0, 0.4)
        end
        return 0
    end

    local function fn71(arg)
        local humanoidRootPart = arg:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return Vector3.zero, Vector3.zero
        end
        local position = humanoidRootPart.Position
        local now = tick()
        local st = tbl8[arg]
        if st and now - st.time > 0.3 then
            st = nil
        end
        local vel, acc
        if st then
            local dt = now - st.time
            if dt < 0.004 then
                return st.vel, st.acc
            end
            local raw = (position - st.pos) / dt
            if raw.Magnitude > 150 then
                vel = humanoidRootPart.AssemblyLinearVelocity
                acc = Vector3.zero
            else
                vel = st.vel:Lerp(raw, tbl9.LerpSmoothness)
                acc = st.acc:Lerp((vel - st.vel) / dt, 0.15)
                if acc.Magnitude > 60 then
                    acc = acc.Unit * 60
                end
            end
        else
            vel = humanoidRootPart.AssemblyLinearVelocity
            acc = Vector3.zero
        end

        pcall(function()
            local hum = arg:FindFirstChildOfClass("Humanoid")
            if hum and hum.FloorMaterial ~= Enum.Material.Air then
                vel = Vector3.new(vel.X, 0, vel.Z)
                acc = Vector3.new(acc.X, 0, acc.Z)
            end
        end)
        tbl8[arg] = {pos = position, vel = vel, acc = acc, time = now}
        return vel, acc
    end

    local function fn72(arg, arg2, arg3, arg4)
        local speed = math.max(arg4 or tbl9.ProjectileSpeed or 500, 1)
        local position = arg2.Position
        if (position - arg).Magnitude < 8 then
            return position
        end
        local vel, acc = fn71(arg3)
        local eff = tbl9.PredictionEfficiency
        local extra = tbl9.PingComp and getPingSeconds() * 0.5 or 0
        local useAcc = tbl9.AccelPredict
        local t = (position - arg).Magnitude / speed
        local predicted = position
        for _ = 1, 4 do
            local lead = math.min(t + extra, tbl9.MaxLead)
            local offset = vel * lead
            if useAcc then
                offset = offset + acc * (0.5 * lead * lead)
            end
            predicted = position + offset * eff
            t = (predicted - arg).Magnitude / speed
        end
        if tbl9.EnableJitter then
            predicted = predicted + Vector3.new((math.random() - 0.5) * tbl9.MaxJitterStuds, (math.random() - 0.5) * (tbl9.MaxJitterStuds / 2), (math.random() - 0.5) * tbl9.MaxJitterStuds)
        end
        return predicted
    end

    getTargetPosition = function()
        local v34 = getGunObject()
        local character = localPlayer.Character
        if not v34 or not character then
            return nil, nil, nil, nil
        end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return nil, nil, nil, nil
        end
        local position = humanoidRootPart.Position
        local n3 = nil

        if character:GetAttribute("IsCarried") then
            n3 = character.HumanoidRootPart.Position + character.HumanoidRootPart.CFrame.LookVector * 2
        else
            pcall(function()
                local isBasePart = v34:IsA("BasePart")
                local position2 = isBasePart and v34.Position

                if not position2 then
                    local basePart = v34:FindFirstChildOfClass("BasePart")
                    position2 = basePart and v34:FindFirstChildOfClass("BasePart").Position
                end

                n3 = position2
            end)

            local vector = n3 or Vector3.new(position.X, position.Y + 1.5, position.Z)
            n3 = vector
        end

        local function fn73(arg, arg2)
            local position2 = arg.Position
            if flag7 and not isTargetVisible(n3, position2, arg2) then
                return nil, nil, nil, nil
            end
            local v35 = getGunObject()
            local position3 = n3

            pcall(function()
                if v35 and v35:IsA("BasePart") then
                    position3 = v35.Position
                elseif v35 then
                    local basePart = v35:FindFirstChildOfClass("BasePart")

                    if basePart then
                        position3 = basePart.Position
                    end
                end
            end)

            if (position2 - position3).Magnitude < 8 then
                return (position2 - position3).Unit, v35, position3, position2
            end

            if not flag5 then
                return (position2 - position3).Unit, v35, position3, position2
            end
            local v36 = fn72(position3, arg, arg2, tbl9.ProjectileSpeed)
            return (v36 - position3).Unit, v35, position3, v36
        end

        local cam = workspace.CurrentCamera
        local camPos, camLook = cam.CFrame.Position, cam.CFrame.LookVector
        local cands = {}
        local function skipDowned(model)
            if not (tbl9.SkipDowned and model) then
                return false
            end
            return IsDowned(model) or model:GetAttribute("IsCarried") == true
        end
        local function bodyPart(model)
            return model:FindFirstChild(tbl9.TargetBody or "Torso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
        end

        if str == "Killer" or str == "Survivors" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Team and player.Team.Name == str and player.Character then
                    local ch = player.Character
                    local body = bodyPart(ch)
                    local hum = ch:FindFirstChildOfClass("Humanoid")
                    if body and not (hum and hum.Health <= 0) and not (str == "Survivors" and skipDowned(ch)) then
                        local dir = body.Position - camPos
                        local dist = dir.Magnitude
                        local dot = dist > 0.01 and camLook:Dot(dir.Unit) or 1
                        if str == "Killer" then
                            table.insert(cands, {body, ch, (position - body.Position).Magnitude})
                        elseif dot > tbl9.FOVDot then

                            table.insert(cands, {body, ch, (1 - dot) * 200 + dist * 0.05})
                        end
                    end
                end
            end
        elseif str == "Zombie" then
            for _, p in ipairs(GetSCPs()) do
                if p and p.Parent then
                    local dir = p.Position - camPos
                    local dist = dir.Magnitude
                    local dot = dist > 0.01 and camLook:Dot(dir.Unit) or 1
                    if dot > tbl9.FOVDot then
                        table.insert(cands, {p, p.Parent, (1 - dot) * 200 + dist * 0.05})
                    end
                end
            end
        else
            return nil, nil, nil, nil
        end

        table.sort(cands, function(x, y)
            return x[3] < y[3]
        end)
        for _, c in ipairs(cands) do
            local r1, r2, r3, r4 = fn73(c[1], c[2])
            if r1 then
                return r1, r2, r3, r4
            end
        end
        return nil, nil, nil, nil
    end

    updateLaser = function(arg, arg2)
        if not part then
            part = Instance.new("Part")
            part.Name = "ToFLaser"
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CastShadow = false
            part.Material = Enum.Material.Neon
            local color = Color3.fromRGB(255, 50, 50)
            part.Color = color
            part.Parent = workspace
        end

        local vector = Vector3.new(0.05, 0.05, (arg2 - arg).Magnitude)
        part.Size = vector
        local cframe = CFrame.new((arg + arg2) / 2, arg2)
        part.CFrame = cframe
        part.Transparency = 0
    end

    clearLaser = function()
        if part then
            part:Destroy()
            part = nil
        end
    end

    local tbl11 = {}

    local function fn73()
        local attribute = localPlayer:GetAttribute("EquippedSkin_Twist_of_Fate")
        local str2 = attribute or ""
        if str2:find("AWP") or str2:find("Awp") or str2:find("awp") then
            return "rbxassetid://119691839016468"
        end

        if not str2:find("SCP") and not str2:find("3108") then
            return "rbxassetid://124735239320776"
        end
        return "rbxassetid://116394362601423"
    end

    local function fn74()
        for i, v34 in ipairs(tbl11) do
            v34:Disconnect()
        end

        tbl11 = {}
        local character = localPlayer.Character
        if not character then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            return
        end

        local function fn75()
            local attribute = character:GetAttribute("IsCarried")
            local attribute2 = attribute or character:GetAttribute("Knocked")
            return attribute2
        end

        local function fn76()
            local tbl12 = {}
            tbl12[fn73()] = true
            tbl12["rbxassetid://111824163160605"] = true
            tbl12["rbxassetid://72749744367268"] = true
            return tbl12
        end

        table.insert(tbl11, animator.AnimationPlayed:Connect(function(arg)
            if not fn75() then
                return
            end

            if not arg.Animation then
                return
            end

            local trackName = string.lower(tostring(arg.Name or arg.Animation.Name or ""))
            if fn76()[arg.Animation.AnimationId] or string.find(trackName, "aim", 1, true) or string.find(trackName, "tof", 1, true) or string.find(trackName, "twist", 1, true) then
                arg:Stop(0)
            end
        end))

        table.insert(tbl11, character:GetAttributeChangedSignal("IsCarried"):Connect(function()
            if not fn75() then
                return
            end
            local v34 = fn76()

            for i, v35 in ipairs(animator:GetPlayingAnimationTracks()) do
                if v35.Animation and v34[v35.Animation.AnimationId] then
                    v35:Stop(0)
                end
            end
        end))

        table.insert(tbl11, character:GetAttributeChangedSignal("Knocked"):Connect(function()
            if not fn75() then
                return
            end
            local v34 = fn76()

            for i, v35 in ipairs(animator:GetPlayingAnimationTracks()) do
                if v35.Animation and v34[v35.Animation.AnimationId] then
                    v35:Stop(0)
                end
            end
        end))
    end

    task.defer(fn74)

    localPlayer.CharacterAdded:Connect(function()
        task.defer(function()
            task.wait(0.25)
            fn74()
        end)
    end)

    doShoot = function()
        if not flag4 or not flag8 then
            return
        end
        local character = localPlayer.Character
        if character and _G.MX.AimConfig.Pistol_BlockKnocked and (IsDowned(character) or character:GetAttribute("IsCarried")) then
            return
        end
        if character then
            local hum = character:FindFirstChildOfClass("Humanoid")
            if CollectionService:HasTag(character, "Silenced") or localPlayer:GetAttribute("IsDead") or (hum and (hum.Health <= 0 or hum.Health < hum.MaxHealth * 0.5)) then
                return
            end
        end
        local v34, v35, v36, v37 = getTargetPosition()
        if not v34 or not v35 or not v37 or not v36 then
            return
        end
        local unit = (v37 - v36).Unit

        local item = v35
        if typeof(item) == "Instance" and character then
            while item.Parent and item.Parent ~= character do
                item = item.Parent
            end
            if item.Parent ~= character then
                item = character:FindFirstChild("Twist of Fate")
            end
        end
        if typeof(item) ~= "Instance" then
            return
        end
        v35 = item

        if v35:GetAttribute("tofState") == "cooldown" then
            return
        end
        local shots = v35:GetAttribute("shots")
        if (shots == nil and 3 or shots) <= 0 then
            return
        end
        if tick() - (_G.MX.LastToFShot or 0) < 0.65 then
            return
        end
        _G.MX.LastToFShot = tick()

        if not _G.MX.ToFStep then
            _G.MX.ToFStep = 3
            pcall(function()
                local tuning = require(ReplicatedStorage.Modules.Items.TwistOfFate.TwistoffateTuning)
                if type(tuning.STEPS) == "table" and #tuning.STEPS >= 1 then
                    _G.MX.ToFStep = #tuning.STEPS
                end
            end)
        end
        _G.MX.SilentShot = true
        pcall(function()
            fire:FireServer(v35, unit, _G.MX.ToFStep)
        end)
        _G.MX.SilentShot = false
    end

    startConnection = function()
        if connection2 then
            return
        end

        connection2 = RunService.Heartbeat:Connect(function()
            if flag8 and flag4 then
                local v34, v35, v36, v37 = getTargetPosition()

                if v34 and v35 and v37 then
                    pcall(function()
                        local character = localPlayer.Character
                        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

                        if humanoidRootPart and not character:GetAttribute("IsCarried") then
                            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, Vector3.new(v37.X, humanoidRootPart.Position.Y, v37.Z))
                        end
                    end)

                    if _G.MX.AimConfig.LockAim then
                        local cframe = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, v37)
                        workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(cframe, 0.15)
                    end

                    if flag6 and v36 and v37 then
                        updateLaser(v36, v37)
                    end
                elseif part then
                    part.Transparency = 1
                end
            elseif part then
                part.Transparency = 1
            end
        end)
    end

    stopConnection = function()
        if connection2 then
            connection2:Disconnect()
            connection2 = nil
        end

        clearLaser()
    end

    local udim2 = UDim2.new(0.5, -82, 0, 30)
    local v34 = nil
    local connection3 = nil

    local tbl12 = {
        {
            internal = "Killer",
            display = "Killer (K)",
            activeColor = Color3.fromRGB(180, 45, 45),
            activeTxt = Color3.fromRGB(255, 180, 180),
        },
        {
            internal = "Survivors",
            display = "Survivors (J)",
            activeColor = Color3.fromRGB(25, 80, 150),
            activeTxt = Color3.fromRGB(160, 210, 255),
        },
        {
            internal = "Zombie",
            display = "Zombie (L)",
            activeColor = Color3.fromRGB(120, 80, 10),
            activeTxt = Color3.fromRGB(255, 210, 100),
        },
    }

    createTargetSelectorUI = function()
        if not CoreGui then
            return
        end

        if v34 and v34.Parent then
            return
        end
        local toFTargetSelector = CoreGui:FindFirstChild("ToFTargetSelector")

        if toFTargetSelector then
            toFTargetSelector:Destroy()
        end

        local screenGui2 = Instance.new("ScreenGui")
        screenGui2.Name = "ToFTargetSelector"
        screenGui2.ResetOnSpawn = false
        screenGui2.IgnoreGuiInset = true
        screenGui2.Parent = CoreGui
        local frame2 = Instance.new("Frame")
        frame2.Name = "Main"
        frame2.Size = UDim2.new(0, 165, 0, 32)
        frame2.Position = udim2
        frame2.BackgroundTransparency = 1
        frame2.Active = true
        frame2.Parent = screenGui2
        local visible = false
        local textButton = Instance.new("TextButton")
        textButton.Size = UDim2.new(1, 0, 1, 0)
        textButton.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        textButton.BackgroundTransparency = 0.25
        textButton.BorderSizePixel = 0
        textButton.Font = Enum.Font.GothamBold
        textButton.TextSize = 11
        textButton.TextColor3 = Color3.fromRGB(240, 240, 240)
        textButton.Parent = frame2
        Instance.new("UICorner", textButton).CornerRadius = UDim.new(0, 8)
        local uiStroke3 = Instance.new("UIStroke", textButton)
        uiStroke3.Color = Color3.fromRGB(100, 100, 110)
        uiStroke3.Thickness = 1.2
        uiStroke3.Transparency = 0.3
        local frame3 = Instance.new("Frame")
        frame3.Size = UDim2.new(1, 0, 0, 0)
        frame3.Position = UDim2.new(0, 0, 1, 5)
        frame3.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        frame3.BackgroundTransparency = 0.25
        frame3.BorderSizePixel = 0
        frame3.ClipsDescendants = true
        frame3.Visible = false
        frame3.AutomaticSize = Enum.AutomaticSize.Y
        frame3.Parent = frame2
        Instance.new("UICorner", frame3).CornerRadius = UDim.new(0, 8)
        local uiStroke4 = Instance.new("UIStroke", frame3)
        uiStroke4.Color = Color3.fromRGB(80, 80, 90)
        uiStroke4.Thickness = 1.2
        uiStroke4.Transparency = 0.4
        local uiListLayout = Instance.new("UIListLayout", frame3)
        uiListLayout.FillDirection = Enum.FillDirection.Vertical
        uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        uiListLayout.Padding = UDim.new(0, 4)
        local uiPadding = Instance.new("UIPadding", frame3)
        uiPadding.PaddingTop = UDim.new(0, 4)
        uiPadding.PaddingBottom = UDim.new(0, 4)
        uiPadding.PaddingLeft = UDim.new(0, 4)
        uiPadding.PaddingRight = UDim.new(0, 4)
        local tbl13 = {}

        local function fn75()
            local str2 = "Unknown"

            for i, v35 in ipairs(tbl12) do
                if v35.internal == str then
                    str2 = v35.internal
                    break
                end
            end

            local v35 = visible
            local str3 = v35 and "v" or ">"
            textButton.Text = string.format("Target: %s   %s", str2, str3)
            frame3.Visible = visible

            for i, v36 in ipairs(tbl12) do
                local v37 = tbl13[v36.internal]

                if v37 then
                    if v36.internal == str then
                        v37.BackgroundColor3 = v36.activeColor
                        v37.TextColor3 = v36.activeTxt
                    else
                        v37.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                        v37.TextColor3 = Color3.fromRGB(150, 150, 150)
                    end
                end
            end
        end

        for i, v35 in ipairs(tbl12) do
            local textButton2 = Instance.new("TextButton")
            textButton2.Size = UDim2.new(1, 0, 0, 26)
            textButton2.BorderSizePixel = 0
            textButton2.Font = Enum.Font.GothamBold
            textButton2.TextSize = 10
            textButton2.Text = v35.display
            textButton2.LayoutOrder = i
            textButton2.Parent = frame3
            Instance.new("UICorner", textButton2).CornerRadius = UDim.new(0, 6)

            local function fn76()
                str = v35.internal
                visible = false
                fn75()
            end

            textButton2.MouseButton1Click:Connect(fn76)

            textButton2.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    fn76()
                end
            end)

            tbl13[v35.internal] = textButton2
        end

        fn75()
        local flag9 = false
        local flag10 = false
        local v35 = nil
        local position = nil
        local position2 = nil

        textButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                flag9 = true
                flag10 = false
                v35 = input
                position = input.Position
                position2 = frame2.Position
            end
        end)

        textButton.InputEnded:Connect(function(input)
            if input == v35 then
                flag9 = false

                if not flag10 then
                    local flag11

                    if visible then
                        flag11 = false
                    else
                        flag11 = true
                    end

                    visible = flag11
                    fn75()
                end

                v35 = nil
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not flag9 then
                return
            end
            local flag11 = false

            if input.UserInputType == Enum.UserInputType.Touch and input == v35 then
                flag11 = true
            elseif input.UserInputType == Enum.UserInputType.MouseMovement and v35.UserInputType == Enum.UserInputType.MouseButton1 then
                flag11 = true
            end

            if flag11 then
                local n3 = input.Position - position

                if math.abs(n3.X) > 4 or math.abs(n3.Y) > 4 then
                    flag10 = true
                end

                if flag10 then
                    local udim22 = UDim2.new(position2.X.Scale, position2.X.Offset + n3.X, position2.Y.Scale, position2.Y.Offset + n3.Y)
                    frame2.Position = udim22
                    udim2 = udim22
                end
            end
        end)

        if connection3 then
            connection3:Disconnect()
            connection3 = nil
        end

        connection3 = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not flag4 then
                return
            end

            if gameProcessed or input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            local str2 = nil

            if input.KeyCode == Enum.KeyCode.K then
                str2 = "Killer"
            elseif input.KeyCode == Enum.KeyCode.J then
                str2 = "Survivors"
            elseif input.KeyCode == Enum.KeyCode.L then
                str2 = "Zombie"
            end

            if str2 and str2 ~= str then
                str = str2
                fn75()
            end
        end)

        v34 = screenGui2
    end

    destroyTargetSelectorUI = function()
        if connection3 then
            connection3:Disconnect()
            connection3 = nil
        end

        if v34 then
            v34:Destroy()
            v34 = nil
        end
    end

    local ToF = {remote = fire, wallCheck = true, status = "ready", last = 0, blockedAt = 0, blockedMsg = ""}
    _G.MX.ToF = ToF

    local TOF_FULL = 3
    pcall(function()
        local tuning = require(ReplicatedStorage.Modules.Items.TwistOfFate.TwistoffateTuning)
        local last = tuning.STEPS[#tuning.STEPS]
        if last and type(last.at) == "number" and last.at > 0 then
            TOF_FULL = last.at
        end
    end)

    local function tofItem(char, obj)
        if typeof(obj) ~= "Instance" or not char or not obj:IsDescendantOf(char) then
            return nil
        end
        local item = obj
        while item.Parent and item.Parent ~= char do
            item = item.Parent
        end
        return item
    end

    local function tofMuzzle(char)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return nil
        end
        local from = hrp.Position + Vector3.new(0, 1.373, 0)
        local to = (hrp.CFrame * CFrame.new(0.7, 1.373, -2.5)).Position
        local delta = to - from
        if delta.Magnitude <= 0 then
            return to
        end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {char}
        params.IgnoreWater = true
        local hit = workspace:Raycast(from, delta, params)
        if hit then
            return hit.Position - delta.Unit * 0.5
        end
        return to
    end

    local function killerOf(inst)
        local model = inst and inst:FindFirstAncestorOfClass("Model")
        local plr = model and Players:GetPlayerFromCharacter(model)
        if plr and plr ~= localPlayer and plr.Team and plr.Team.Name == "Killer" then
            return model
        end
        return nil
    end

    local function tofClearHit(origin, dir)
        if typeof(dir) ~= "Vector3" or dir.Magnitude < 0.01 then
            return false
        end
        local mine = localPlayer.Character
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local list = {mine}
        for _ = 1, 12 do
            params.FilterDescendantsInstances = list
            local hit = workspace:Raycast(origin, dir.Unit * 1000, params)
            if not hit then
                return false
            end
            if killerOf(hit.Instance) then
                return true
            end
            if hit.Instance.Transparency <= 0.01 and hit.Instance.CanQuery then
                return false
            end
            table.insert(list, hit.Instance)
        end
        return false
    end

    local function invalidReason(char, obj)
        local item = tofItem(char, obj)
        if not item then
            return "not equipped"
        end
        if item:GetAttribute("tofState") == "cooldown" then
            return "cooldown"
        end
        local shots = item:GetAttribute("shots")
        if (shots == nil and 1 or shots) <= 0 then
            return "no shots"
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            return "dead"
        end
        if CollectionService:HasTag(char, "Silenced") or localPlayer:GetAttribute("IsDead") then
            return "silenced"
        end
        if char:GetAttribute("Trapped") or char:GetAttribute("IsHooked") or char:GetAttribute("IsCarried") then
            return "busy"
        end
        return nil
    end

    function ToF.onFire(obj, look)
        local char = localPlayer.Character
        if flag4 and flag8 then
            return false
        end
        if not ToF.wallCheck then
            return nil
        end
        local reason = invalidReason(char, obj)
        if not reason then
            local cam = workspace.CurrentCamera
            local origin = tofMuzzle(char) or (cam and cam.CFrame.Position)
            if not (origin and tofClearHit(origin, look)) then
                reason = "no target"
            end
        end
        if reason then
            ToF.status = "blocked: " .. reason
            ToF.blockedAt = os.clock()
            ToF.blockedMsg = reason
            return false
        end
        ToF.last = os.clock()
        ToF.status = "shot allowed"
        return nil
    end

    PistolSection:AddToggle("Silent Aim ToF", false, function(on)
        flag4 = on
        if on then
            createTargetSelectorUI()
            startConnection()
        else
            stopConnection()
            destroyTargetSelectorUI()
        end
    end, {Flag = "ToFSilentAim"})

    local function flashEquipped()
        local char = localPlayer.Character
        return char ~= nil and char:FindFirstChild("Flashlight") ~= nil
    end

    local function itemInput(input)
        local raw = localPlayer:GetAttribute("kb_item")
        if typeof(raw) ~= "string" or raw == "" then
            raw = "MouseButton2"
        end
        if raw:match("^MouseButton%d$") then
            return input.UserInputType.Name == raw
        end
        return input.KeyCode.Name == raw
    end

    PistolSection:AddToggle("Silent Aim Flashlight", false, function(on)
        _G.MX.AimConfig.Flash_Silent = on
    end, {Flag = "FlashSilentAim"})

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local flag9 = input.UserInputType == Enum.UserInputType.Touch
        if gameProcessed and not flag9 then
            return
        end

        if itemInput(input) then
            flag8 = true

            if _G.MX.AimConfig.Flash_Silent and flashEquipped() then
                _G.MX.PistolHold = true
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if itemInput(input) then
            if flag8 and flag4 and not flashEquipped() then
                doShoot()
            end
            flag8 = false
            _G.MX.PistolHold = false

            if part then
                part.Transparency = 1
            end
        end
    end)

    local connection4 = nil

    hookMobileButtons = function(arg)
        task.wait(0.5)
        local controls = arg:WaitForChild("Controls", 10)
        if not controls then
            return
        end
        local guiMob = controls:WaitForChild("Gui-mob", 5)
        if not guiMob then
            return
        end

        guiMob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                flag8 = true

                if _G.MX.AimConfig.Flash_Silent and flashEquipped() then
                    _G.MX.PistolHold = true
                end
            end
        end)

        guiMob.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                doShoot()
                flag8 = false
                _G.MX.PistolHold = false

                if part then
                    part.Transparency = 1
                end
            end
        end)
    end

    setupMobileButton = function()
        local playerGui2 = localPlayer:WaitForChild("PlayerGui", 10)
        if not playerGui2 then
            return
        end
        local survivorMob = playerGui2:FindFirstChild("Survivor-mob")

        if survivorMob then
            task.spawn(hookMobileButtons, survivorMob)
        end

        if connection4 then
            connection4:Disconnect()
            connection4 = nil
        end

        connection4 = playerGui2.ChildAdded:Connect(function(child)
            if child.Name == "Survivor-mob" then
                task.spawn(hookMobileButtons, child)
            end
        end)
    end

    setupMobileButton()

    localPlayer.CharacterAdded:Connect(function(character)
        clearLaser()
        tbl8 = {}
        tbl10 = {}
        n2 = 0
        flag8 = false
        character:WaitForChild("HumanoidRootPart", 5)
        setupMobileButton()

        if flag4 then
            stopConnection()
            task.wait(0.2)
            startConnection()
        end
    end)

    playerGui.ChildRemoved:Connect(function(child)
        if not flag4 then
            return
        end
        task.wait(0.5)
        if not flag4 then
            return
        end

        if child.Name == "ToFTargetSelector" then
        end
    end)

end
