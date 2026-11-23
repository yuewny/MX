return function(ctx)
    local ExtraCard, localPlayer = ctx.ExtraCard, ctx.localPlayer

    local HEADLESS_HEAD = 134082579
    local KORBLOX_LEG = 139607718

    local original
    local busy = false
    local enabled = {head = false, right = false, left = false}

    local function humanoid()
        local char = localPlayer.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    local function refresh()
        if busy then
            return
        end
        busy = true
        task.spawn(function()
            pcall(function()
                local hum = humanoid()
                if not hum then
                    return
                end
                if not original then
                    original = hum:GetAppliedDescription()
                end
                local desc = hum:GetAppliedDescription()
                desc.Head = enabled.head and HEADLESS_HEAD or original.Head
                desc.RightLeg = enabled.right and KORBLOX_LEG or original.RightLeg
                desc.LeftLeg = enabled.left and KORBLOX_LEG or original.LeftLeg
                hum:ApplyDescription(desc)
            end)
            busy = false
        end)
    end

    localPlayer.CharacterAdded:Connect(function()
        original = nil
        task.wait(2)
        if enabled.head or enabled.right or enabled.left then
            refresh()
        end
    end)

    ExtraCard:AddToggle("Headless", false, function(on)
        enabled.head = on
        refresh()
    end, {Flag = "AvatarHeadless"})

    ExtraCard:AddToggle("Korblox Kanan", false, function(on)
        enabled.right = on
        refresh()
    end, {Flag = "AvatarKorbloxRight"})

    ExtraCard:AddToggle("Korblox Kiri", false, function(on)
        enabled.left = on
        refresh()
    end, {Flag = "AvatarKorbloxLeft"})
end
