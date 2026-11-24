return function(ctx)
    local ExtraCard, localPlayer = ctx.ExtraCard, ctx.localPlayer

    local KORBLOX_LEG = 139607718
    local TAG = "MXAvatar"

    local enabled = {head = false, right = false, left = false}
    local original
    local guards = {}

    local function character()
        return localPlayer.Character
    end

    local function isR15(char)
        return char:FindFirstChild("UpperTorso") ~= nil
    end

    local function clearGuards()
        for _, c in ipairs(guards) do
            c:Disconnect()
        end
        guards = {}
    end

    local function setHeadHidden(char, hidden)
        local head = char:FindFirstChild("Head")
        if not head then
            return
        end
        local function apply()
            local want = hidden and 1 or 0
            if head.Transparency ~= want then
                head.Transparency = want
            end
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("Decal") and child.Transparency ~= want then
                    child.Transparency = want
                end
            end
        end
        apply()
        if hidden then
            table.insert(guards, head:GetPropertyChangedSignal("Transparency"):Connect(apply))
            table.insert(guards, head.ChildAdded:Connect(function()
                task.defer(apply)
            end))
        end
    end

    local function setLegMesh(char, bodyPart, on)
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("CharacterMesh") and child.BodyPart == bodyPart and child.Name == TAG then
                child:Destroy()
            end
        end
        if not on then
            return
        end
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("CharacterMesh") and child.BodyPart == bodyPart then
                child:Destroy()
            end
        end
        local mesh = Instance.new("CharacterMesh")
        mesh.Name = TAG
        mesh.BodyPart = bodyPart
        mesh.MeshId = KORBLOX_LEG
        mesh.OverlayTextureId = 0
        mesh.BaseTextureId = 0
        mesh.Parent = char
    end

    local function applyR15(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            return
        end
        if not original then
            original = hum:GetAppliedDescription()
        end
        local desc = hum:GetAppliedDescription()
        desc.RightLeg = enabled.right and KORBLOX_LEG or original.RightLeg
        desc.LeftLeg = enabled.left and KORBLOX_LEG or original.LeftLeg
        hum:ApplyDescription(desc)
    end

    local function refresh()
        local char = character()
        if not char then
            return
        end
        clearGuards()
        pcall(setHeadHidden, char, enabled.head)
        if isR15(char) then
            task.spawn(function()
                pcall(applyR15, char)
            end)
        else
            pcall(setLegMesh, char, Enum.BodyPart.RightLeg, enabled.right)
            pcall(setLegMesh, char, Enum.BodyPart.LeftLeg, enabled.left)
        end
    end

    localPlayer.CharacterAdded:Connect(function(char)
        original = nil
        clearGuards()
        char:WaitForChild("Humanoid", 10)
        task.wait(1.5)
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
