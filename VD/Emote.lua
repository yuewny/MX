return function(ctx)
    local ExtraCard, lib, localPlayer = ctx.ExtraCard, ctx.lib, ctx.localPlayer
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")

    local EMOTE_LIST_URL = "https://pastebin.com/raw/DVUbsm3x"

    local emotes, names = {}, {}
    local track, sound, moveConn
    local selected
    local stopOnMove = true

    local function stopEmote()
        if moveConn then
            moveConn:Disconnect()
            moveConn = nil
        end
        if track then
            pcall(function()
                track:Stop(0.2)
                track:Destroy()
            end)
            track = nil
        end
        if sound then
            sound:Destroy()
            sound = nil
        end
    end

    local function assetId(value)
        return value ~= nil and string.match(tostring(value), "%d+") or nil
    end

    local function animator(hum)
        local an = hum:FindFirstChildOfClass("Animator")
        if not an then
            an = Instance.new("Animator")
            an.Parent = hum
        end
        return an
    end

    local function playEmote(name)
        local data = emotes[name]
        local char = localPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local animId = data and assetId(data.id)
        if not (hum and root and animId) or hum.Health <= 0 then
            return
        end
        stopEmote()

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. animId
        local ok, loaded = pcall(function()
            return animator(hum):LoadAnimation(anim)
        end)
        if not ok or not loaded then
            return
        end
        track = loaded
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = true
        track:Play(0.2)

        local songId = assetId(data.song)
        if songId then
            sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://" .. songId
            sound.Looped = true
            sound.Volume = 1
            sound.Parent = root
            sound:Play()
        end

        local origin = root.Position
        moveConn = RunService.Heartbeat:Connect(function()
            if not (track and track.IsPlaying) or hum.Health <= 0 then
                stopEmote()
            elseif stopOnMove and (hum.MoveDirection.Magnitude > 0.1 or (root.Position - origin).Magnitude > 6) then
                stopEmote()
            end
        end)
    end

    local dropdown = ExtraCard:AddDropdown("Emote", {"Loading..."}, false, function(value)
        selected = value
    end)

    ExtraCard:AddButton("Play", function()
        if selected and emotes[selected] then
            playEmote(selected)
        end
    end)
    ExtraCard:AddButton("Stop", stopEmote)
    ExtraCard:AddToggle("Stop On Move", true, function(on)
        stopOnMove = on
    end, {Flag = "EmoteStopOnMove"})

    lib.API.Track(stopEmote)
    localPlayer.CharacterAdded:Connect(stopEmote)

    task.spawn(function()
        local okGet, body = pcall(game.HttpGet, game, EMOTE_LIST_URL)
        if not okGet then
            return
        end
        local okJson, data = pcall(HttpService.JSONDecode, HttpService, body)
        if not okJson or type(data) ~= "table" then
            return
        end
        for _, entry in pairs(data) do
            local label = tostring(entry.name or entry.id or "")
            local lower = string.lower(label)
            local id = assetId(entry.id)
            if id and id ~= "0" and not lower:find("emotold") and not lower:find("modelold") and not emotes[label] then
                emotes[label] = entry
                names[#names + 1] = label
            end
        end
        table.sort(names)
        if #names > 0 and dropdown and dropdown.SetOptions then
            dropdown:SetOptions(names)
        end
    end)
end
