return function(ctx)
local CollectionService, localPlayer = ctx.CollectionService, ctx.localPlayer
    do

        xpcall(function()
            local T = {on = false, items = {}}

            local function clear(model)
                local e = T.items[model]
                if e then
                    pcall(function() e.hl:Destroy() end)
                    pcall(function() e.gui:Destroy() end)
                    T.items[model] = nil
                end
            end

            _G.MX.SetTrapESP = function(state)
                T.on = state
                if not state then
                    for model in pairs(T.items) do
                        clear(model)
                    end
                end
            end
            if _G.MX.WantTrapESP then
                _G.MX.SetTrapESP(true)
            end

            local scanCache, scanAt = {}, 0
            local function trapModels()
                local list, seenModels = {}, {}
                local function add(m)
                    if m and not seenModels[m] and m:IsDescendantOf(workspace) then

                        if m:IsA("BasePart") then
                            local owner = m:FindFirstAncestor("BearTrap")
                            if owner and seenModels[owner] then
                                return
                            end
                        end
                        seenModels[m] = true
                        table.insert(list, m)
                    end
                end
                for _, m in ipairs(CollectionService:GetTagged("BearTrap")) do
                    add(m)
                end
                local map = workspace:FindFirstChild("Map")
                if map then
                    if os.clock() >= scanAt then
                        scanAt = os.clock() + 3
                        scanCache = {}
                        for _, d in ipairs(map:GetDescendants()) do
                            if d.Name == "BearTrap" and d:FindFirstChild("Cube", true) then

                                for _, inner in ipairs(d:GetDescendants()) do
                                    if inner.Name == "Cube" and inner:IsA("BasePart") then
                                        table.insert(scanCache, inner)
                                    end
                                end
                            elseif d.Name == "BearTrap" then
                                if d:IsA("Folder") then
                                    local found = false
                                    for _, inner in ipairs(d:GetDescendants()) do
                                        if inner:IsA("Model") then
                                            found = true
                                            table.insert(scanCache, inner)
                                        end
                                    end
                                    if not found then
                                        for _, inner in ipairs(d:GetChildren()) do
                                            if inner:IsA("BasePart") then
                                                table.insert(scanCache, inner)
                                            end
                                        end
                                    end
                                elseif d:IsA("Model") or d:IsA("BasePart") then
                                    table.insert(scanCache, d)
                                end
                            end
                        end
                    end
                    for _, m in ipairs(scanCache) do
                        add(m)
                    end
                end
                return list
            end

            task.spawn(function()
                while _G.MX.ScriptAlive do
                    task.wait(0.4)
                    pcall(function()
                        if not T.on then
                            return
                        end
                        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local seen = {}
                        for _, model in ipairs(trapModels()) do
                            local part = model:IsA("BasePart") and model
                                or model:FindFirstChild("hitbox") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                            if part then
                                seen[model] = true
                                local holder = model
                                if model:GetAttribute("Armed") == nil then
                                    holder = model:FindFirstAncestor("BearTrap") or model
                                end
                                local armed = holder:GetAttribute("Armed") ~= false and holder:GetAttribute("Triggered") ~= true
                                local color = armed and Color3.fromRGB(60, 110, 255) or Color3.fromRGB(150, 150, 150)
                                local e = T.items[model]
                                if not e or not e.hl.Parent or not e.gui.Parent then
                                    clear(model)
                                    local hl = Instance.new("Highlight")
                                    hl.FillTransparency = 0.5
                                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    hl.Adornee = model
                                    hl.Parent = model
                                    local gui = Instance.new("BillboardGui")
                                    gui.Size = UDim2.fromOffset(120, 26)
                                    gui.StudsOffset = Vector3.new(0, 3, 0)
                                    gui.AlwaysOnTop = true
                                    gui.Adornee = part
                                    gui.Parent = part
                                    local label = Instance.new("TextLabel")
                                    label.Size = UDim2.fromScale(1, 1)
                                    label.BackgroundTransparency = 1
                                    label.Font = Enum.Font.GothamBold
                                    label.TextSize = 13
                                    label.TextStrokeTransparency = 0.4
                                    label.Parent = gui
                                    e = {hl = hl, gui = gui, label = label}
                                    T.items[model] = e
                                end
                                e.hl.FillColor = color
                                e.hl.OutlineColor = color
                                e.label.TextColor3 = color
                                local dist = root and math.floor((part.Position - root.Position).Magnitude) or 0
                                e.label.Text = string.format("⚠ %s [%d]", armed and "Trap" or "Trap (off)", dist)
                            end
                        end
                        for model in pairs(T.items) do
                            if not seen[model] then
                                clear(model)
                            end
                        end
                    end)
                end
                for model in pairs(T.items) do
                    clear(model)
                end
            end)
        end, function(err)
            warn("[MXHUB] ESP Trap failed to build: " .. tostring(err))
        end)

    end
end
