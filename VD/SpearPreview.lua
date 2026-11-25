return function(ctx)
local MXTrack = getgenv().MXHUB_Track or function(c) return c end
    local Card, RunService, Players, CollectionService, localPlayer, lib = ctx.Card, ctx.RunService, ctx.Players, ctx.CollectionService, ctx.localPlayer, ctx.lib

    local MAX_SPEED = 165
    local MAX_RANGE = 260
    local GRAVITY = 98.1
    local SPAWN_OFFSET = 3
    local MAX_LIFE = 4
    local SPEAR_LENGTH = 7.6
    local STEP = 0.04
    local BODY = {"Head", "Torso", "UpperTorso", "LowerTorso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

    local COLOR_FREE = Color3.fromRGB(255, 255, 255)

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

    local base = newPart(Vector3.new(0.1, 0.1, 0.1))
    local att0 = Instance.new("Attachment")
    att0.Parent = base
    local att1 = Instance.new("Attachment")
    att1.Parent = base
    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Width0 = 0.12
    beam.Width1 = 0.12
    beam.Color = ColorSequence.new(COLOR_FREE)
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.Transparency = NumberSequence.new(0.1)
    beam.Enabled = false
    beam.Parent = base

    local marker = newPart(Vector3.new(1.2, 1.2, 1.2), Enum.PartType.Ball)
    marker.Color = COLOR_FREE

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(120, 28)
    gui.StudsOffset = Vector3.new(0, 2, 0)
    gui.AlwaysOnTop = true
    gui.Enabled = false
    gui.Parent = marker
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = COLOR_FREE
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = gui

    local function hide()
        beam.Enabled = false
        marker.Transparency = 1
        gui.Enabled = false
    end

    local connection = MXTrack(RunService.RenderStepped:Connect(function()
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
        local origin = head.Position
        local dir = cam.CFrame.LookVector
        local everyone = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                everyone[#everyone + 1] = plr.Character
            end
        end
        local points = Preview.simulate(origin, dir, MAX_SPEED, survivors(), everyone)
        local reach = math.clamp((points[#points] - origin):Dot(dir), 6, MAX_RANGE)
        local startPos = origin + dir * SPAWN_OFFSET - cam.CFrame.UpVector * 0.5
        local tip = origin + dir * reach
        att0.WorldPosition = startPos
        att1.WorldPosition = tip
        beam.Enabled = true
        marker.Position = tip
        marker.Transparency = 0.3
        label.Text = string.format("%d studs", math.floor(reach + 0.5))
        gui.Enabled = true
    end))

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
