return function(ctx)
local ExtraCard, lib, localPlayer = ctx.ExtraCard, ctx.lib, ctx.localPlayer
    do
        local ExtraCard = ctx.ExtraCard
        local HttpSvc = game:GetService("HttpService")
        local cleanups = {}
        lib.API.Track(function()
            for _, f in ipairs(cleanups) do
                pcall(f)
            end
        end)
        local function animator()
            local char = localPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                return nil
            end
            local an = hum:FindFirstChildOfClass("Animator")
            if not an then
                an = Instance.new("Animator")
                an.Parent = hum
            end
            return an
        end

        local emoteTrack, emoteSound
        local emotes, emoteNames = {}, {}
        local function stopEmote()
            if emoteTrack then
                pcall(function()
                    emoteTrack:Stop()
                    emoteTrack:Destroy()
                end)
                emoteTrack = nil
            end
            if emoteSound then
                emoteSound:Destroy()
                emoteSound = nil
            end
        end
        local function playEmote(name)
            local data = emotes[name]
            if not data then
                return
            end
            stopEmote()
            local an = animator()
            local animNum = string.match(tostring(data.id), "%d+")
            if not an or not animNum then
                return
            end
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. animNum
            emoteTrack = an:LoadAnimation(anim)
            emoteTrack.Looped = true
            emoteTrack:Play()
            local soundNum = data.song and string.match(tostring(data.song), "%d+")
            local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if soundNum and root then
                emoteSound = Instance.new("Sound")
                emoteSound.SoundId = "rbxassetid://" .. soundNum
                emoteSound.Looped = true
                emoteSound.Parent = root
                emoteSound:Play()
            end
        end
        local selectedEmote
        local emoteDrop = ExtraCard:AddDropdown("Emote", {"(memuat...)"}, false, function(value)
            selectedEmote = value
        end)
        ExtraCard:AddButton("Play Emote", function()
            if selectedEmote then
                playEmote(selectedEmote)
            end
        end)
        ExtraCard:AddButton("Stop Emote", stopEmote)
        table.insert(cleanups, stopEmote)
        task.spawn(function()
            local ok, body = pcall(function()
                return game:HttpGet("https://pastebin.com/raw/DVUbsm3x")
            end)
            if not ok then
                return
            end
            local okJson, data = pcall(function()
                return HttpSvc:JSONDecode(body)
            end)
            if not okJson or type(data) ~= "table" then
                return
            end
            for _, v in pairs(data) do
                local nameLower = string.lower(tostring(v.name or ""))
                if v.id and tostring(v.id) ~= "" and tostring(v.id) ~= "0" and not nameLower:find("emotold") and not nameLower:find("modelold") then
                    local key = tostring(v.name or v.id)
                    if not emotes[key] then
                        emotes[key] = v
                        emoteNames[#emoteNames + 1] = key
                    end
                end
            end
            table.sort(emoteNames)
            if #emoteNames > 0 then
                emoteDrop:SetOptions(emoteNames)
            end
        end)

    end
end
