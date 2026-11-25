return function(ctx)
local MXTrack = getgenv().MXHUB_Track or function(c) return c end
    local Players, ReplicatedStorage, RunService, localPlayer, lib = ctx.Players, ctx.ReplicatedStorage, ctx.RunService, ctx.localPlayer, ctx.lib

    local CORE = Color3.fromRGB(255, 150, 30)
    local HALO = Color3.fromRGB(255, 110, 0)
    local LIFE = 1.2

    local Tracker = {
        spearOn = true,
        bulletOn = true,
    }
    _G.MX.Tracker = Tracker

    local folder = Instance.new("Folder")
    folder.Name = "MXHUB_Tracker"
    folder.Parent = workspace

    local segments = {}
    local runs = {}
    local MAX_SEGMENTS = 600

    local function newPart(a, b, color, width, transparency, material)
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Material = material
        part.Color = color
        part.Transparency = transparency
        part.Size = Vector3.new(width, width, (b - a).Magnitude + 0.05)
        part.CFrame = CFrame.lookAt((a + b) / 2, b)
        part.Parent = folder
        return part
    end

    local function addSegment(a, b, width)
        if (b - a).Magnitude < 0.01 then
            return
        end
        table.insert(segments, {
            core = newPart(a, b, CORE, width, 0, Enum.Material.Neon),
            halo = newPart(a, b, HALO, width * 3.2, 0.62, Enum.Material.Neon),
            born = os.clock(),
        })
        while #segments > MAX_SEGMENTS do
            local old = table.remove(segments, 1)
            old.core:Destroy()
            old.halo:Destroy()
        end
    end

    local function worldHit(from, to, ignore)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local list = {folder}
        for _, instance in ipairs(ignore or {}) do
            table.insert(list, instance)
        end
        for _ = 1, 16 do
            params.FilterDescendantsInstances = list
            local hit = workspace:Raycast(from, to - from, params)
            if not hit then
                return nil
            end
            local inst = hit.Instance
            if inst.Transparency < 0.05 and inst.Name ~= "Plant" then
                return hit.Position
            end
            table.insert(list, inst)
        end
        return nil
    end

    local function launch(position, maxTime, width, stopOnHit)
        local started = os.clock()
        local last = position(0)
        local run = {}
        run.connection = MXTrack(RunService.Heartbeat:Connect(function()
            local t = os.clock() - started
            if t > maxTime then
                t = maxTime
            end
            local nextPoint = position(t)
            if nextPoint then
                local stopAt = stopOnHit and worldHit(last, nextPoint, {localPlayer.Character})
                if stopAt then
                    addSegment(last, stopAt, width)
                    run.connection:Disconnect()
                    runs[run] = nil
                    return
                end
                addSegment(last, nextPoint, width)
                last = nextPoint
            end
            if t >= maxTime then
                run.connection:Disconnect()
                runs[run] = nil
            end
        end))
        runs[run] = true
    end

    local fadeConnection = MXTrack(RunService.Heartbeat:Connect(function()
        local now = os.clock()
        local i = 1
        while i <= #segments do
            local seg = segments[i]
            local age = (now - seg.born) / LIFE
            if age >= 1 or not seg.core.Parent then
                seg.core:Destroy()
                seg.halo:Destroy()
                table.remove(segments, i)
            else
                local fade = age * age
                seg.core.Transparency = 0.05 + 0.95 * fade
                seg.halo.Transparency = 0.62 + 0.38 * fade
                i = i + 1
            end
        end
    end))

    local SPEAR_GRAVITY = Vector3.new(0, -98.1, 0)
    local SPEAR_OFFSET = 3
    local SPEAR_LIFE = 4
    pcall(function()
        local math3 = require(ReplicatedStorage.Modules.Killers.Veil.SpearMath)
        SPEAR_GRAVITY = math3.Gravity or SPEAR_GRAVITY
        SPEAR_OFFSET = math3.SpawnOffset or SPEAR_OFFSET
        SPEAR_LIFE = math3.MaxLife or SPEAR_LIFE
    end)

    function Tracker.spear(origin, direction, speed)
        if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
            return
        end
        local start = origin + direction.Unit * SPEAR_OFFSET
        local velocity = direction.Unit * speed
        launch(function(t)
            return start + velocity * t + SPEAR_GRAVITY * (0.5 * t * t)
        end, SPEAR_LIFE, 0.2, true)
    end

    function Tracker.bullet(from, to, speed)
        if typeof(from) ~= "Vector3" or typeof(to) ~= "Vector3" then
            return
        end
        local length = (to - from).Magnitude
        if length < 0.5 then
            return
        end
        local duration = length / math.max(tonumber(speed) or 800, 1)
        launch(function(t)
            return from:Lerp(to, math.min(t / math.max(duration, 0.001), 1))
        end, duration, 0.12, false)
    end

    task.spawn(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
        local items = remotes and remotes:WaitForChild("Items", 10)
        local tof = items and items:WaitForChild("Twist of Fate", 10)
        local visualize = tof and tof:WaitForChild("VisualizeBullet", 10)
        if visualize then
            MXTrack(visualize.OnClientEvent:Connect(function(from, to, speed)
                pcall(Tracker.bullet, from, to, speed)
            end))
        end
    end)

    lib.API.Track(function()
        fadeConnection:Disconnect()
        for run in pairs(runs) do
            pcall(function()
                run.connection:Disconnect()
            end)
        end
        folder:Destroy()
        _G.MX.Tracker = nil
    end)
end
