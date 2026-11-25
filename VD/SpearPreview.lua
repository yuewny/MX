return function(ctx)
    local Card, RunService, Players, CollectionService, localPlayer, lib = ctx.Card, ctx.RunService, ctx.Players, ctx.CollectionService, ctx.localPlayer, ctx.lib

    local MAX_SPEED = 165
    local GRAVITY = 98.1
    local SPAWN_OFFSET = 3
    local MAX_LIFE = 4
    local SPEAR_LENGTH = 7.6
    local STEP = 0.04
    local MAX_RANGE = 260
    local BODY = {"Head", "Torso", "UpperTorso", "LowerTorso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

    local COLOR_FREE = Color3.fromRGB(255, 255, 255)
    local COLOR_HIT = Color3.fromRGB(70, 255, 120)
    local COLOR_WALL = Color3.fromRGB(255, 80, 80)
    local COLOR_TARGET = Color3.fromRGB(255, 210, 0)

    local Preview = {enabled = true}
    _G.MX.SpearPreview = Preview

    local function boxFraction(origin, delta, cf, size)
        local o = cf:PointToObjectSpace(origin)
        local d = cf:VectorToObjectSpace(delta)
        local t0, t1 = 0, 1
        for _, axis in ipairs({"X", "Y", "Z"}) do
            local oa, da, half = o[axis], d[axis], size[axis] * 0.5
            if math.abs(da) < 1e-8 then
                if oa < -half or oa > half then
                    return nil
                end
            else
                local a, b = (-half - oa) / da, (half - oa) / da
                if a > b then
                    a, b = b, a
                end
                t0 = math.max(t0, a)
                t1 = math.min(t1, b)
                if t1 < t0 then
                    return nil
                end
            end
        end
        return t0
    end

    local function survivors()
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if plr ~= localPlayer and char and plr.Team and plr.Team.Name == "Survivors" then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not char:GetAttribute("Knocked") and not char:GetAttribute("IsHooked") then
                    list[#list + 1] = char
                end
            end
        end
        return list
    end

    local function worldHit(from, to, filter)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local list = table.clone(filter)
        for _ = 1, 16 do
            params.FilterDescendantsInstances = list
            local hit = workspace:Raycast(from, to - from, params)
            if not hit then
                return nil
            end
            local inst = hit.Instance
            local ignored = inst.Name == "Plant" or (inst.Transparency >= 0.05 and not CollectionService:HasTag(inst, "TrueInvis"))
            if not ignored then
                return hit
            end
            table.insert(list, inst)
        end
        return nil
    end

    function Preview.simulate(origin, dir, speed, targets, everyone)
        local start = origin + dir * SPAWN_OFFSET
        local points = {start}
        local prev = start
        local steps = math.floor(MAX_LIFE / STEP)
        for i = 1, steps do
            local t = i * STEP
            local point = start + dir * (speed * t) + Vector3.new(0, -0.5 * GRAVITY * t * t, 0)
            local delta = point - prev
            local bestFraction, bestChar
            for _, char in ipairs(targets) do
                for _, name in ipairs(BODY) do
                    local part = char:FindFirstChild(name)
                    if part and part:IsA("BasePart") then
                        local f = boxFraction(prev, delta, part.CFrame, part.Size)
                        if f and (not bestFraction or f < bestFraction) then
                            bestFraction, bestChar = f, char
                        end
                    end
                end
            end
            local wall = worldHit(prev, point, everyone)
            local wallFraction = wall and wall.Distance / math.max(delta.Magnitude, 1e-6)
            if bestFraction and (not wallFraction or bestFraction <= wallFraction) then
                points[#points + 1] = prev + delta * bestFraction
                return points, "hit", bestChar
            end
            if wall then
                points[#points + 1] = wall.Position
                return points, "wall"
            end
            points[#points + 1] = point
            prev = point
        end
        return points, "air"
    end

    local folder = Instance.new("Folder")
    folder.Name = "MXHUB_SpearPreview"
    folder.Parent = workspace

    local function newPart(size, shape)
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        part.Size = size
        part.Transparency = 1
        if shape then
            part.Shape = shape
        end
        part.Parent = folder
        return part
    end

    local halo = newPart(Vector3.new(0.35, 0.35, 1))
    local core = newPart(Vector3.new(0.09, 0.09, 1))
    local targetGlow = Instance.new("Highlight")
    targetGlow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    targetGlow.FillTransparency = 0.55
    targetGlow.OutlineTransparency = 0
    targetGlow.Parent = folder
    local marker = newPart(Vector3.new(1.4, 1.4, 1.4), Enum.PartType.Ball)
    local hitbox = newPart(Vector3.new(0.7, 0.7, SPEAR_LENGTH))
    hitbox.Material = Enum.Material.ForceField

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(160, 36)
    gui.StudsOffset = Vector3.new(0, 2.5, 0)
    gui.AlwaysOnTop = true
    gui.Enabled = false
    gui.Parent = marker
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = gui

    local function hide()
        core.Transparency = 1
        halo.Transparency = 1
        targetGlow.Adornee = nil
        marker.Transparency = 1
        hitbox.Transparency = 1
        gui.Enabled = false
    end

    local lastPlan, lastPlanAt = nil, 0
    local lastPick, lastPickAt = nil, 0

    local function draw(tip, kind, char, origin, startPos, glowChar)
        local color = kind == "hit" and COLOR_HIT or COLOR_FREE
        local offset = tip - startPos
        local length = offset.Magnitude
        if length < 0.5 then
            hide()
            return
        end
        local heading = offset.Unit
        local middle = CFrame.lookAt((startPos + tip) / 2, tip)
        core.Size = Vector3.new(0.09, 0.09, length)
        core.CFrame = middle
        core.Color = color
        core.Transparency = 0.05
        halo.Size = Vector3.new(0.35, 0.35, length)
        halo.CFrame = middle
        halo.Color = color
        halo.Transparency = 0.8
        local pulse = 1.4 + 0.3 * math.sin(os.clock() * 8)
        marker.Size = Vector3.new(pulse, pulse, pulse)
        marker.Position = tip
        marker.Color = color
        marker.Transparency = 0.3
        hitbox.CFrame = CFrame.lookAt(tip - heading * (SPEAR_LENGTH / 2), tip)
        hitbox.Color = color
        hitbox.Transparency = 0.65
        local text = string.format("%d studs", math.floor((tip - origin).Magnitude + 0.5))
        if kind == "hit" and char then
            text = text .. "  |  " .. char.Name
        end
        label.Text = text
        gui.Enabled = true
        if glowChar then
            targetGlow.Adornee = glowChar
            local glow = COLOR_HIT
            targetGlow.FillColor = glow
            targetGlow.OutlineColor = glow
        else
            targetGlow.Adornee = nil
        end
    end

    local connection = RunService.RenderStepped:Connect(function()
        local startedAt = _G.MX.SpearCharge
        if not Preview.enabled or not startedAt or os.clock() - startedAt > 8 then
            hide()
            return
        end
        local char = localPlayer.Character
        local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
        local cam = workspace.CurrentCamera
        if not head or not cam then
            hide()
            return
        end
        local speed = MAX_SPEED
        local origin = head.Position
        local dir = cam.CFrame.LookVector
        local everyone = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                everyone[#everyone + 1] = plr.Character
            end
        end
        local list = survivors()
        local points, kind, hitChar = Preview.simulate(origin, dir, speed, list, everyone)
        local glowChar = hitChar
        if kind ~= "hit" and _G.MX.AimConfig.Aim_SilentVeilV2 and _G.MX.SpearAim then
            if os.clock() - lastPlanAt > 0.1 then
                lastPlanAt = os.clock()
                lastPlan = _G.MX.SpearAim(origin, dir, speed)
            end
            if lastPlan then
                local vPoints, vKind, vChar = Preview.simulate(origin, lastPlan, speed, list, everyone)
                if vKind == "hit" then
                    points, kind, hitChar, glowChar = vPoints, "hit", vChar, vChar
                end
            end
        end
        local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand") or char:FindFirstChild("Torso")
        local startPos = arm and arm.Position or origin
        local reach = math.clamp((points[#points] - origin):Dot(dir), 5, MAX_RANGE)
        draw(origin + dir * reach, kind, hitChar, origin, startPos, glowChar)
    end)

    Card:AddToggle("Highlight", true, function(on)
        Preview.enabled = on
        if not on then
            hide()
        end
    end, {Flag = "SpearPreview"})

    lib.API.Track(function()
        connection:Disconnect()
        folder:Destroy()
        _G.MX.SpearPreview = nil
    end)
end
