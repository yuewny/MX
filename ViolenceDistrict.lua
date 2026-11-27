if type(getgenv) ~= "function" then
	getgenv = function()
		return _G
	end
end

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local MX_BUILD = (function()
	local SCRIPT_VERSION = "v2.3"
	local GAME_NAME = "Violence District"
	local GAME_KEY = "ViolenceDistrict"

	local function createFeatureAPI(namespace)
		local env = getgenv()
		local previous = env[namespace]
		if previous ~= nil and type(previous) == "table" and type(previous.Unload) == "function" then
			pcall(previous.Unload)
		end
		local API = { State = {}, Unloaded = false }
		local cleanup = {}
		function API.Track(dispose)
			if API.Unloaded then
				pcall(dispose)
			else
				table.insert(cleanup, dispose)
			end
			return dispose
		end
		function API.Unload()
			if API.Unloaded then
				return
			end
			API.Unloaded = true
			for index = #cleanup, 1, -1 do
				local dispose = table.remove(cleanup, index)
				pcall(dispose)
			end
			table.clear(API.State)
			if env[namespace] == API then
				env[namespace] = nil
			end
		end
		env[namespace] = API
		return API
	end

	local API = createFeatureAPI("MXHUB_" .. GAME_KEY)

	local LIB_URL = "https://raw.githubusercontent.com/yuewny/MX/main/Source.lua"

	local function isLibrary(value)
		return type(value) == "table"
			and type(value.CreateWindow) == "function"
			and type(value.Destroy) == "function"
			and type(value.LoadAutoConfig) == "function"
	end

	local function fetchLibrary()
		local reason = "tidak ada respon"
		for attempt = 1, 3 do
			local fetchOk, body = pcall(function()
				return game:HttpGet(LIB_URL, true)
			end)
			if not fetchOk or type(body) ~= "string" then
				reason = "HttpGet gagal: " .. tostring(body)
			elseif #body < 50000 then
				reason = "file lib terlalu kecil (" .. #body .. " byte): " .. body:sub(1, 80)
			else
				local chunk, compileError = loadstring(body)
				if type(chunk) ~= "function" then
					reason = "lib gagal di-compile: " .. tostring(compileError)
				else
					local runOk, library = pcall(chunk)
					if runOk and isLibrary(library) then
						return library
					end
					reason = runOk and "lib tidak punya CreateWindow/Destroy/LoadAutoConfig" or ("lib error: " .. tostring(library))
				end
			end
			task.wait(0.5 * attempt)
		end
		return nil, reason
	end

	local Library, failure = fetchLibrary()
	if not isLibrary(Library) then
		error("MX HUB UI library gagal dimuat dari " .. LIB_URL .. "\n" .. tostring(failure), 0)
	end

	Library.NotifyEnabled = false
	pcall(function()
		Library:SetNotificationsHidden(true)
	end)

	local originalDestroy = Library.Destroy
	Library.Destroy = function(self, ...)
		task.defer(API.Unload)
		return originalDestroy(self, ...)
	end
	API.Track(function()
		pcall(function()
			originalDestroy(Library)
		end)
	end)

	Library:SetChangelog({
		{ Version = "2.3", Entries = {
			{ "Melee Aimbot", "up" },
			{ "Silent Aim Cure", "up" },
			{ "Silent Aim Butcher", "up" },
			{ "Silent Aim Flashlight", "up" },
			{ "Spear Tracker", "up" },
			{ "Auto Parry", "up" },
			{ "TOF", "up" },
			{ "No Slowdown Survivor", "up" },
			{ "Killer ESP", "up" },
			{ "Emote", "up" },
			{ "Silent Aim TOF", "fix" },
			{ "Silent Aim Veil", "fix" },
			{ "Skill Check Generator", "fix" },
			{ "Self Heal", "down" },
			{ "Fake Parry", "down" },
			{ "Auto Attack", "down" },
			{ "Reach Assist", "down" },
			{ "Hook & Generators", "down" },
			{ "Unlimited Vault", "down" },
			{ "Flowstate No CD", "down" },
			{ "Anti Slow Vault", "down" },
			{ "Perk Info", "down" },
			{ "Invisible", "down" },
			{ "Fake Clone", "down" },
			{ "Fake Lag", "down" },
			{ "Headless", "down" },
			{ "Korblox", "down" },
		} },
	})

	local Window = Library:CreateWindow({
		Title = "MX HUB",
		SubTitle = GAME_NAME .. " " .. SCRIPT_VERSION,
		Size = Vector2.new(720, 460),
		TabWidth = 170,
		Theme = "Mono",
		MobileButton = "Auto",
		Effect = "Stars",
		Home = true,
		Settings = { Category = "Misc" },
	})

	local NOOP = function() end
	local TAB_ICONS = { Main = "layout-grid", Survivor = "user", Killer = "skull", Visual = "eye", Trap = "alert-triangle", Teleport = "map-pin" }
	local TAB_CATEGORY = { Main = "General", Survivor = "Roles", Killer = "Roles", Trap = "Tools", Visual = "Tools", Teleport = "Tools" }
	local SKIP_TITLES = { ["Menu Keybind"] = true, ["Transparency Toggle"] = true, ["Lock GUI"] = true, ["Watermark"] = true }
	local flagUsed = {}
	local autoFlag = 0
	local lastCategory = nil
	local allSections = {}

	local function validIcon(name)
		if type(name) == "string" then
			local ok, found = pcall(function()
				return Library:GetIcon(name)
			end)
			if ok and found then
				return name
			end
		end
		return "box"
	end

	local function uniqueFlag(flag)
		if flag == nil then
			return nil
		end
		flag = tostring(flag)
		if flagUsed[flag] then
			autoFlag = autoFlag + 1
			flag = flag .. "_" .. autoFlag
		end
		flagUsed[flag] = true
		return flag
	end

	local function safe(cb, ...)
		if type(cb) ~= "function" then
			return
		end
		local ok, err = pcall(cb, ...)
		if not ok then
			warn("[MXHUB] " .. tostring(err))
		end
	end

	local Handle = {}
	Handle.__index = function(self, key)
		local v = rawget(Handle, key)
		if v ~= nil then
			return v
		end
		if type(key) == "string" and key:match("^%u") then
			return NOOP
		end
		return nil
	end
	local function arg(self, a, b)
		if a == self then
			return b
		end
		return a
	end
	function Handle.SetValue(self, a, b, c)
		local v = arg(self, a, b)
		if self.Kind == "Paragraph" then
			local first, second = a, b
			if a == self then
				first, second = b, c
			end
			if second == nil then
				first, second = nil, first
			end
			if self.Element then
				pcall(function()
					self.Element:Set(first, second)
				end)
			end
			return
		end
		self.Value = v
		if self.Element then
			pcall(function()
				self.Element:Set(v)
			end)
		end
	end
	Handle.Set = Handle.SetValue
	function Handle.GetValue(self)
		return self.Value
	end
	Handle.Get = Handle.GetValue
	local function setOptions(self, a, b)
		local list = arg(self, a, b)
		if self.Element and type(list) == "table" then
			pcall(function()
				self.Element:Refresh(list)
			end)
		end
	end
	Handle.Refresh = setOptions
	Handle.SetValues = setOptions
	Handle.SetOptions = setOptions
	function Handle.Destroy(self)
		local row = self.Element and self.Element.Row
		if row then
			pcall(function()
				row:Destroy()
			end)
		end
	end
	function Handle.SetVisible(self, a, b)
		local v = arg(self, a, b)
		local row = self.Element and self.Element.Row
		if row then
			pcall(function()
				row.Visible = v and true or false
			end)
		end
	end

	local Section = {}
	Section.__index = function(self, key)
		local v = rawget(Section, key)
		if v ~= nil then
			return v
		end
		if type(key) == "string" and key:match("^%u") then
			return NOOP
		end
		return nil
	end

	function Section:_gb()
		if self.hidden or self.tab.hidden then
			return nil
		end
		if not self.box then
			local opts = { Title = self.name, Icon = validIcon(self.icon), Side = "Auto" }
			local ok, box = pcall(function()
				return self.tab.real:AddSection(opts)
			end)
			if not ok then
				warn("[MXHUB] section " .. tostring(self.name) .. ": " .. tostring(box))
			end
			self.box = ok and box or nil
		end
		return self.box
	end

	local function build(self, method, cfg, value, kind)
		local h = setmetatable({ Value = value, Kind = kind, Section = self }, Handle)
		local box = self:_gb()
		if not box then
			return h
		end
		local ok, el = pcall(function()
			return box[method](box, cfg)
		end)
		if not ok and cfg.Flag ~= nil then
			cfg.Flag = nil
			ok, el = pcall(function()
				return box[method](box, cfg)
			end)
		end
		if ok then
			h.Element = el
			self.count = (self.count or 0) + 1
		else
			warn("[MXHUB] " .. tostring(cfg.Title) .. ": " .. tostring(el))
		end
		return h
	end

	function Section:AddToggle(title, default, cb, o)
		if SKIP_TITLES[title] then
			return setmetatable({ Value = default }, Handle)
		end
		o = o or {}
		local h
		h = build(self, "AddToggle", {
			Title = title,
			Default = default == true,
			Flag = uniqueFlag(o.Flag),
			Callback = function(v)
				if h then
					h.Value = v
				end
				safe(cb, v)
			end,
		}, default == true, "Toggle")
		h.Value = default == true
		h.Title = title
		return h
	end

	function Section:AddCheckbox(title, default, cb, o)
		if SKIP_TITLES[title] then
			return setmetatable({ Value = default }, Handle)
		end
		o = o or {}
		local h
		h = build(self, "AddToggle", {
			Title = title,
			Default = default == true,
			Flag = uniqueFlag(o.Flag),
			Callback = function(v)
				if h then
					h.Value = v
				end
				safe(cb, v)
			end,
		}, default == true, "Toggle")
		h.Value = default == true
		h.Title = title
		return h
	end

	function Section:AddSlider(title, min, max, default, cb, o)
		o = o or {}
		local h
		h = build(self, "AddSlider", {
			Title = title,
			Min = min,
			Max = max,
			Increment = o.Increment or ((min % 1 ~= 0 or max % 1 ~= 0 or (default or 0) % 1 ~= 0) and 0.1 or 1),
			Default = default,
			Flag = uniqueFlag(o.Flag),
			Callback = function(v)
				if h then
					h.Value = v
				end
				safe(cb, v)
			end,
		}, default, "Slider")
		h.Value = default
		return h
	end

	function Section:AddButton(title, cb)
		return build(self, "AddButton", {
			Title = title,
			Callback = function()
				safe(cb)
			end,
		}, nil, "Button")
	end

	function Section:AddDropdown(title, options, multi, cb, o)
		o = o or {}
		options = options or {}
		local start = o.Default
		if start == nil then
			start = (not multi) and options[1] or nil
		end
		local h
		h = build(self, "AddDropdown", {
			Title = title,
			Values = options,
			Multi = multi == true,
			Default = start,
			Flag = uniqueFlag(o.Flag),
			Callback = function(v)
				if h then
					h.Value = v
				end
				safe(cb, v)
			end,
		}, start, "Dropdown")
		h.Value = start
		return h
	end

	function Section:AddTextbox(title, placeholder, cb, o)
		o = o or {}
		local h
		h = build(self, "AddTextbox", {
			Title = title,
			Placeholder = placeholder or "",
			Default = "",
			Flag = uniqueFlag(o.Flag),
			Callback = function(text)
				if h then
					h.Value = text
				end
				safe(cb, text)
			end,
		}, "", "Input")
		return h
	end

	function Section:AddKeybind()
		return setmetatable({}, Handle)
	end
	function Section:AddColorPicker()
		return setmetatable({}, Handle)
	end
	function Handle.AddKeyPicker()
		return setmetatable({}, Handle)
	end
	function Handle.AddColorPicker(self)
		return self
	end

	function Section:AddParagraph(cfg)
		cfg = cfg or {}
		return build(self, "AddParagraph", {
			Title = cfg.Title or cfg.Name or "",
			Content = cfg.Content or cfg.Desc or cfg.Text or "",
		}, nil, "Paragraph")
	end
	Section.AddCard = Section.AddParagraph
	function Section:AddConfigManager()
		return setmetatable({}, Handle)
	end

	local Page = {}
	Page.__index = Page
	function Page:CreateSection(name, icon)
		local sec = setmetatable({ name = name, icon = icon, tab = self.tab, count = 0 }, Section)
		allSections[#allSections + 1] = sec
		sec:_gb()
		return sec
	end

	local Tab = {}
	Tab.__index = Tab
	function Tab:CreatePage()
		return setmetatable({ tab = self }, Page)
	end

	local Lib = { Scheme = {} }
	function Lib:Notify() end
	Lib.SetWatermark = NOOP
	function Lib:CreateWindow()
		local win = {}
		function win:CreateTab(name)
			if name == "Settings" then
				return setmetatable({ hidden = true }, Tab)
			end
			local category = TAB_CATEGORY[name]
			if category and category ~= lastCategory then
				lastCategory = category
				pcall(function()
					Window:AddCategory(category)
				end)
			end
			local real = Window:AddTab({ Title = name, Icon = validIcon(TAB_ICONS[name]) })
			return setmetatable({ real = real }, Tab)
		end
		return setmetatable(win, {
			__index = function(_, key)
				if type(key) == "string" and key:match("^%u") then
					return NOOP
				end
				return nil
			end,
		})
	end
	function Lib.Autoload()
		for _, sec in ipairs(allSections) do
			if sec.box and (sec.count or 0) == 0 then
				pcall(function()
					sec.box.Frame.Visible = false
				end)
			end
		end
		pcall(function()
			Library:LoadAutoConfig()
		end)
	end
	Lib.Window = { Gui = Library.Gui, Raw = Window }
	Lib.API = API
	Lib.Ui = setmetatable({ Assets = { Logo = "rbxassetid://105865788976884" } }, { __index = Library })
	return Lib
end)

local lib = MX_BUILD()

local function MXTrack(connection)
    pcall(lib.API.Track, function()
        pcall(function()
            connection:Disconnect()
        end)
    end)
    return connection
end
getgenv().MXHUB_Track = MXTrack

local MX = {}
do
    local BASE = "https://raw.githubusercontent.com/yuewny/MX/main/VD/"
    local FOLDER = "MXHUB/VD"
    local NAMES = {"AssistFree", "AutoDisarm", "Emote", "Heal", "KillerAbilities", "KillerESP", "Perks", "Pumpkin", "ToF", "SpearPreview", "Tracker", "TrapESP"}
    local results, pending = {}, {}
    local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    if canFile and type(makefolder) == "function" and type(isfolder) == "function" then
        pcall(function()
            if not isfolder("MXHUB") then
                makefolder("MXHUB")
            end
            if not isfolder(FOLDER) then
                makefolder(FOLDER)
            end
        end)
    end

    local function fetch(name)
        local path = FOLDER .. "/" .. name .. ".lua"
        local ok, src = pcall(function()
            return game:HttpGet(BASE .. name .. ".lua", true)
        end)
        if ok and type(src) == "string" and #src > 0 and not src:find("^404") then
            if canFile then
                pcall(writefile, path, src)
            end
            return src
        end
        if canFile then
            local okFile, exists = pcall(isfile, path)
            if okFile and exists then
                local okRead, cached = pcall(readfile, path)
                if okRead and type(cached) == "string" and #cached > 0 then
                    return cached
                end
            end
        end
        return nil
    end

    for _, name in ipairs(NAMES) do
        pending[name] = true
        task.spawn(function()
            results[name] = fetch(name) or false
            pending[name] = nil
        end)
    end

    function MX.run(name, ctx)
        local waited = os.clock()
        while pending[name] and os.clock() - waited < 25 do
            task.wait()
        end
        local src = results[name]
        if not src then
            warn("[MXHUB] modul " .. name .. " tidak bisa dimuat")
            return false
        end
        local fn, err = loadstring(src, "=" .. name)
        if not fn then
            warn("[MXHUB] modul " .. name .. " gagal dikompilasi: " .. tostring(err))
            return false
        end
        local okRun, mod = pcall(fn)
        if not okRun or type(mod) ~= "function" then
            warn("[MXHUB] modul " .. name .. " tidak valid")
            return false
        end
        local okMod, modErr = pcall(mod, ctx)
        if not okMod then
            warn("[MXHUB] modul " .. name .. " error: " .. tostring(modErr))
        end
        return okMod
    end
end
local v, Players, localPlayer, RunService, UserInputService, VirtualInputManager, ReplicatedStorage, CoreGui, playerGui, currentCamera, CollectionService, HttpService, tbl, tbl2, tbl3, flag, tbl4, fn, fn2, fn3
local fn4, fn5, fn6, fn7

do
    lib.Scheme.AccentColor = Color3.fromRGB(255, 255, 255)
    lib.Scheme.BackgroundColor = Color3.fromRGB(10, 10, 12)
    lib.Scheme.MainColor = Color3.fromRGB(16, 16, 18)
    lib.Scheme.OutlineColor = Color3.fromRGB(255, 255, 255)
    lib.Scheme.FontColor = Color3.fromRGB(235, 235, 240)
    lib.Scheme.SubTextColor = Color3.fromRGB(140, 140, 150)
    lib.Scheme.HoverColor = Color3.fromRGB(22, 22, 26)

    v = lib:CreateWindow({
        Title = "MX HUB",
        Subtitle = "Violence District",
        SubtitleColor = Color3.fromRGB(190, 140, 255),
        LogoSize = 32,
        SphereText = false,
        SphereWords = "ZX",
        SphereIconSize = 38,
        Watermark = true,
        WatermarkText = "MX HUB",
    })

    Players = game:GetService("Players")
    localPlayer = Players.LocalPlayer
    RunService = game:GetService("RunService")
    UserInputService = game:GetService("UserInputService")
    VirtualInputManager = game:GetService("VirtualInputManager")
    local GuiService = game:GetService("GuiService")
    ReplicatedStorage = game:GetService("ReplicatedStorage")
    CoreGui = game:GetService("CoreGui")
    playerGui = localPlayer:WaitForChild("PlayerGui")
    currentCamera = workspace.CurrentCamera
    CollectionService = game:GetService("CollectionService")
    HttpService = game:GetService("HttpService")
    game:GetService("TeleportService")
    local TweenService = game:GetService("TweenService")
    _G.MX = {}
    _G.MX.AntiBlindEnabled = false
    _G.MX.GotBlindedRemote = nil
    _G.MX.NoSlowdownEnabled = false
    _G.MX.InfiniteLungeEnabled = false

    _G.MX.Net = (function()
        local N = {ids = {}, active = {}}
        local function remote(...)
            local r = ReplicatedStorage:FindFirstChild("Remotes")
            for _, name in ipairs({...}) do
                r = r and r:FindFirstChild(name)
            end
            return r
        end
        local function guid()
            return HttpService:GenerateGUID(false)
        end
        local function character()
            return localPlayer.Character
        end
        local function store(kind, point)
            N.ids[kind] = N.ids[kind] or setmetatable({}, {__mode = "k"})
            return N.ids[kind]
        end
        local function fire(r, ...)
            if not r then
                return false
            end
            local args = table.pack(...)
            return pcall(function()
                r:FireServer(table.unpack(args, 1, args.n))
            end)
        end

        local function sync(stateAttr, idAttr, on, id)
            local char = character()
            local script = char and char:FindFirstChild("CheckInterractable")
            if not script then
                return
            end
            pcall(function()
                if on then
                    script:SetAttribute(idAttr, id)
                end
                script:SetAttribute(stateAttr, on)
            end)
        end

        function N.repair(point, on)
            if not point then
                return false
            end
            local ids = store("repair", point)
            if on then
                if not ids[point] or not N.active[point] then
                    ids[point] = guid()
                end
                N.active[point] = true
            else
                ids[point] = ids[point] or guid()
                N.active[point] = nil
            end
            sync("isRepairing", "RepairRequestId", on == true, ids[point])
            return fire(remote("Generator", "RepairEvent"), point, on == true, nil, ids[point], character())
        end

        function N.heal(target, on)
            if not target then
                return false
            end
            local ids = store("heal", target)
            if on then
                if not ids[target] or not N.active[target] then
                    ids[target] = guid()
                end
                N.active[target] = true
            else
                ids[target] = ids[target] or guid()
                N.active[target] = nil
            end
            sync("isHealing", "HealRequestId", on == true, ids[target])
            return fire(remote("Healing", "HealEvent"), target, on == true, ids[target], character())
        end

        function N.drop(point)
            local char = character()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not point or not hrp then
                return false
            end
            return fire(remote("Pallet", "PalletDropEvent"), point, hrp.Position, hum and hum.MoveDirection or Vector3.zero, guid(), char)
        end

        function N.vault(point, sprint, tier)
            if not point then
                return false
            end
            local id = guid()
            store("vault", point)[point] = id
            return fire(remote("Window", "VaultEvent"), point, sprint == true, id, character(), tier or "fast")
        end
        function N.vaultDone(point)
            if not point then
                return false
            end
            local ids = store("vault", point)
            return fire(remote("Window", "VaultCompleteEvent"), point, false, ids[point] or guid(), character())
        end

        function N.slide(point, sprint)
            if not point then
                return false
            end
            local id = guid()
            store("slide", point)[point] = id
            return fire(remote("Pallet", "PalletSlideEvent"), point, sprint == true, id, character())
        end
        function N.slideDone(point)
            if not point then
                return false
            end
            local ids = store("slide", point)
            return fire(remote("Pallet", "PalletSlideCompleteEvent"), point, ids[point] or guid(), character())
        end

        function N.unhook(point)
            if not point then
                return false
            end
            return fire(remote("Carry", "UnHookEvent"), point, character())
        end

        return N
    end)()

    local tbl5 = {
        ["122812055447896"] = "Veil lunge",
        ["133963973694098"] = "Mayers Basic",
        ["117042998468241"] = "Mayers lunge",
        ["135002183282873"] = "cure lunge",
        ["121216847022485"] = "cure Basic",
        ["132817836308238"] = "Jeff Basic",
        ["129784271201071"] = "Jeff lunge",
        ["82666958311998"] = "Jeff Frenzy",
        ["78432063483146"] = "Abyssal Basic",
        ["118907603246885"] = "Abyssal lunge",
        ["139369275981139"] = "Jason Basic",
        ["110355011987939"] = "Jason lunge",
        ["111920872708571"] = "Masked Basic",
        ["105374834496520"] = "Masked lunge",
        ["138720291317243"] = "Masked Tony",
        ["106871536134254"] = "Masked Alex",
        ["130593238885843"] = "Masked Cobra",
        ["115244153053858"] = "Masked Cobra lunge",
        ["74968262036854"] = "Hidden Basic",
        ["113255068724446"] = "Hidden lunge",
        ["98163597193511"] = "Hidden S1",
        ["80411309607666"] = "Abyssal S1",

        ["101636125032002"] = "Abyssal Basic",
        ["77081789642514"] = "Abyssal Basic 2",
        ["125430111937587"] = "Abyssal lunge",
        ["83333467665074"] = "Butcher Basic",
        ["127417297154354"] = "Butcher lunge",
        ["75618342544502"] = "Jason Basic",
        ["79310600168078"] = "Jason Frenzy",
        ["93902163029544"] = "Jason lunge",
        ["104540716539347"] = "Jason Frenzy lunge",
        ["117070354890871"] = "Masked Alex lunge",
        ["113691709436161"] = "Slasher Basic",
        ["129626174716003"] = "Slasher lunge",
        ["81963230963908"] = "Veil Basic",
        ["84926129581106"] = "Veil lunge",
        ["100014992013740"] = "Abyssal S1",
    }

    local CROUCH_DODGE = {["80411309607666"] = true, ["100014992013740"] = true}

    _G.MX.ParryConfig = {
        AutoParry = false,
        ParrySafety = false,
        ParryAggressive = false,
        ParryCircle = true,
        ParryRadius = 15,
        ParryFace = 0.35,
        AutoCrouch = false,
        Ignored_Skills = {},
    }

    _G.MX.AttachedParry = {}

    if not _G.MX.State then
        _G.MX.State = {}
    end

    _G.MX.State.ParryCooldown = false
    _G.MX.State.ParryCooldownTime = 60
    _G.MX.State.AutoParryAdornment = nil
    _G.MX.State.ParryCooldownThread = nil
    _G.MX.AutoParryCustom = {Gui = nil, IsActive = false, GuiVisible = false}
    local ox = _G.MX
    local parryHUD = _G.MX.ParryHUD
    local v3 = parryHUD

    if not parryHUD then
        local tbl6 = {}
        v3 = tbl6
        tbl6.gradients = {}
        tbl6.icon = nil
        tbl6.rescanConn = nil
        tbl6.cachedIconColor = nil
    end

    ox.ParryHUD = v3
    ParryHUD = _G.MX.ParryHUD

    IsDowned = function(arg)
        if not arg then
            return false
        end
        local flag2 = arg:GetAttribute("Knocked") == true or arg:GetAttribute("IsHooked") == true
        return flag2
    end

    IsKiller = function(arg)
        local flag2 = arg and arg.Team and arg.Team.Name == "Killer"
        return flag2
    end

    TriggerCrouch = function()
        pcall(function()
            local playerGui2 = localPlayer:FindFirstChild("PlayerGui")

            for match in string.gmatch("Survivor-mob.Controls.crouch.icon", "[^%.]+") do
                if playerGui2 then
                    playerGui2 = playerGui2:FindFirstChild(match)
                end
            end

            if playerGui2 and playerGui2:IsA("GuiObject") and playerGui2.Visible and playerGui2.Parent and playerGui2.Parent:IsA("GuiButton") then
                local parent = playerGui2.Parent

                if UserInputService.TouchEnabled and type(firesignal) == "function" then
                    firesignal(parent.MouseButton1Click)
                    task.wait(1.4)
                    firesignal(parent.MouseButton1Click)
                else
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                    task.wait(1.4)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                end
            else
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                task.wait(1.4)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
            end
        end)
    end

    IsSafeToParry = function(arg)
        if not _G.MX.ParryConfig.ParrySafety then
            return true
        end

        if not arg then
            return false
        end
        local checkInterractable = arg:FindFirstChild("CheckInterractable")

        if checkInterractable then
            if checkInterractable:GetAttribute("isVaulting") == true then
                return false
            end

            if checkInterractable:GetAttribute("isRepairing") == true then
                return false
            end

            if checkInterractable:GetAttribute("isUnhooking") == true then
                return false
            end

            if checkInterractable:GetAttribute("isHealing") == true then
                return false
            end

            if checkInterractable:GetAttribute("isSliding") == true then
                return false
            end
        end

        return true
    end

    tapMobileParryButton = function()
        local playerGui2 = localPlayer:FindFirstChild("PlayerGui")
        if not playerGui2 then
            return
        end
        local survivorMob = playerGui2:FindFirstChild("Survivor-mob")
        local guiMob = survivorMob and survivorMob:FindFirstChild("Controls") and survivorMob.Controls:FindFirstChild("Gui-mob")

        if guiMob and guiMob.Visible then
            if firesignal then
                pcall(function()
                    firesignal(guiMob.MouseButton1Down)
                    task.wait(0.01)
                    firesignal(guiMob.MouseButton1Up)
                end)
            end
        else
            pcall(function()
                if not mouse2click then
                    if mouse2press and mouse2release then
                        mouse2press()
                        task.wait(0.01)
                        mouse2release()
                        return
                    end

                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                    task.wait(0.01)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    return
                end

                mouse2click()
            end)
        end
    end

    local PARRY_ANIMATIONS = {
        Default = "rbxassetid://109133187196613",
        StopWatch = "rbxassetid://81793464499285",
        Enten = "rbxassetid://127096285501517",
        BloodShield = "rbxassetid://75939529748815",
        Fih = "rbxassetid://123307242865945",
        Feedbacker = "rbxassetid://126894569253341",
    }

    local function resolveParryAnimation(character)
        local tool = character:FindFirstChild("Parrying Dagger")
        local own = tool and tool:FindFirstChildWhichIsA("Animation", true)
        if own then
            return own
        end
        local skin = localPlayer:GetAttribute("EquippedSkin_Parrying_Dagger")
        local items = ReplicatedStorage:FindFirstChild("Items")
        local folder = items and items:FindFirstChild("Parrying_Dagger")
        local skins = folder and folder:FindFirstChild("Skins")
        local skinFolder = skins and type(skin) == "string" and skins:FindFirstChild(skin)
        local stored = (skinFolder and skinFolder:FindFirstChildWhichIsA("Animation", true)) or (folder and folder:FindFirstChildWhichIsA("Animation", true))
        if stored then
            return stored
        end
        local animation = Instance.new("Animation")
        animation.AnimationId = PARRY_ANIMATIONS[type(skin) == "string" and skin or "Default"] or PARRY_ANIMATIONS.Default
        return animation
    end

    local parryClient, parryClientScan = nil, 0
    local function findParryClient()
        local character = localPlayer.Character
        if parryClient and parryClient.character == character and parryClient.parryEvent and parryClient.parryEvent.Parent then
            return parryClient
        end
        parryClient = nil
        if type(getgc) ~= "function" or os.clock() - parryClientScan < 2.5 then
            return nil
        end
        parryClientScan = os.clock()
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" and rawget(obj, "parryEvent") ~= nil and rawget(obj, "isParryOnCooldown") ~= nil
                and rawget(obj, "player") == localPlayer and rawget(obj, "character") == character then
                parryClient = obj
                return obj
            end
        end
        return nil
    end

    local function parryAllowed(character)
        if not character or localPlayer:GetAttribute("IsDead") then
            return false
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health < humanoid.MaxHealth * 0.5 then
            return false
        end
        if character:GetAttribute("Trapped") or character:GetAttribute("IsCarried") or character:GetAttribute("IsHooked") then
            return false
        end
        if CollectionService:HasTag(character, "Silenced") then
            return false
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and CollectionService:HasTag(root, "doing action") then
            return false
        end
        local busy = character:FindFirstChild("CheckInterractable")
        if busy then
            for _, name in ipairs({"isVaulting", "isSliding", "isDroppingPallet", "isRepairing", "isHealing", "isUnhooking", "isExiting"}) do
                if busy:GetAttribute(name) then
                    return false
                end
            end
        end
        local tool = character:FindFirstChild("Parrying Dagger")
        return tool ~= nil
    end

    local function attackByName(name)
        name = string.lower(tostring(name or ""))
        if string.find(name, "vm", -2, true) then
            return nil
        end
        if string.find(name, "^attack") and not string.find(name, "done", 1, true) then
            return name
        end
        for _, word in ipairs({"swing", "slash", "stab", "strike", "chop", "lunge"}) do
            if string.find(name, word, 1, true) and not string.find(name, "idle", 1, true) and not string.find(name, "wall", 1, true)
                and not string.find(name, "stun", 1, true) then
                return name
            end
        end
        if string.find(name, "lungehold", 1, true) then
            return name
        end
        return nil
    end

    local faceToken = 0
    local function faceKiller(root)
        if not root then
            return
        end
        _G.MX.State.ParryFaceTarget = root
        _G.MX.State.ParryFaceAt = os.clock()
        faceToken += 1
        local token = faceToken
        local function apply()
            local char = localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and root.Parent then
                local goal = Vector3.new(root.Position.X, hrp.Position.Y, root.Position.Z)
                if (goal - hrp.Position).Magnitude > 0.3 then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, goal)
                end
            end
        end
        apply()
        task.spawn(function()
            local t0 = os.clock()
            while token == faceToken and os.clock() - t0 < 0.8 do
                RunService.Heartbeat:Wait()
                apply()
            end
        end)
    end

    local function patchParryClient(client)
        if client._mxhubFace then
            return
        end
        client._mxhubFace = true
        local original = client._faceLookDirection
        client._faceLookDirection = function(self, ...)
            local root = _G.MX.State.ParryFaceTarget
            if root and root.Parent and os.clock() - (_G.MX.State.ParryFaceAt or 0) < 1 and self.rootPart and self.rootPart.Parent then
                self.faceToken = (self.faceToken or 0) + 1
                local token, started, lock = self.faceToken, tick(), self.lockDuration or 0.6
                local conn
                conn = MXTrack(RunService.Heartbeat:Connect(function()
                    if self.faceToken ~= token or tick() - started > lock or not (self.rootPart and self.rootPart.Parent and root.Parent) then
                        conn:Disconnect()
                        return
                    end
                    local p = self.rootPart.Position
                    local g = Vector3.new(root.Position.X, p.Y, root.Position.Z)
                    if (g - p).Magnitude > 0.3 then
                        self.rootPart.CFrame = CFrame.lookAt(p, g)
                    end
                end))
                return
            end
            return original(self, ...)
        end
    end

    _G.MX.ParryReach = function(myRoot, killerRoot)
        local radius = _G.MX.ParryConfig.ParryRadius
        local ok, extra = pcall(function()
            local toMe = myRoot.Position - killerRoot.Position
            if toMe.Magnitude < 0.1 then
                return 0
            end
            local closing = killerRoot.AssemblyLinearVelocity:Dot(toMe.Unit) - myRoot.AssemblyLinearVelocity:Dot(toMe.Unit)
            local lead = 0.04 + math.clamp(_G.MX.VeilPing or 0, 0, 0.3) * 0.5
            return math.clamp(closing, 0, 70) * lead
        end)
        return radius + (ok and extra or 0)
    end

    ExecuteParry = function(killerRoot)
        if _G.MX.State.ParryCooldown then
            return false
        end

        local now = os.clock()
        if _G.MX.State.LastParryFire and now - _G.MX.State.LastParryFire < 0.15 then
            return true
        end

        pcall(faceKiller, killerRoot)
        local client = findParryClient()
        if client then
            pcall(patchParryClient, client)
            if not client:CanUse() then
                return false
            end
            _G.MX.State.LastParryFire = now
            task.spawn(client.Parry, client)
            return true
        end

        local character = localPlayer.Character
        if not parryAllowed(character) then
            return false
        end
        _G.MX.State.LastParryFire = now
        task.spawn(function()
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            local function playing()
                local n = 0
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if track.Priority == Enum.AnimationPriority.Action or track.Priority == Enum.AnimationPriority.Action2 or track.Priority == Enum.AnimationPriority.Action3 or track.Priority == Enum.AnimationPriority.Action4 then
                            n += 1
                        end
                    end
                end
                return n
            end
            local before = playing()
            local sent = false
            if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
                tapMobileParryButton()
                sent = true
            else
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    sent = true
                end)
            end
            task.wait(0.12)
            if sent and (playing() > before or not parryAllowed(character)) then
                return
            end
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local items = remotes and remotes:FindFirstChild("Items")
            local parryingDagger = items and items:FindFirstChild("Parrying Dagger")
            local parry = parryingDagger and parryingDagger:FindFirstChild("parry")
            if parry and character and character.Parent then
                pcall(function()
                    parry:FireServer(character)
                end)
                local anim = resolveParryAnimation(character)
                if anim and animator then
                    pcall(function()
                        for _, playingTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                            if playingTrack.Animation and playingTrack.Animation.AnimationId == anim.AnimationId then
                                playingTrack:Stop(0)
                            end
                        end
                        local track = animator:LoadAnimation(anim)
                        track.Priority = Enum.AnimationPriority.Action
                        track:Play()
                        task.delay(0.8, function()
                            if track.IsPlaying then
                                track:Stop(0.15)
                            end
                        end)
                    end)
                end
            end
        end)
        return true
    end

    ParryHUD.Scan = function()
        local playerGui2 = localPlayer:FindFirstChild("PlayerGui")
        if not playerGui2 then
            return false
        end
        table.clear(ParryHUD.gradients)
        ParryHUD.icon = nil

        for i, v4 in ipairs({"Survivor", "Survivor-con"}) do
            local v5 = playerGui2:FindFirstChild(v4)

            if v5 then
                local gen = v5:FindFirstChild("Gen")
                local itemFrame = gen and gen:FindFirstChild("ItemFrame")

                if itemFrame then
                    local gui = itemFrame:FindFirstChild("Gui")
                    local bar = gui and gui:FindFirstChild("Bar")
                    local uiGradient = bar and bar:FindFirstChild("UIGradient")

                    if uiGradient then
                        table.insert(ParryHUD.gradients, uiGradient)
                    end

                    local icon = itemFrame:FindFirstChild("icon")

                    if icon then
                        ParryHUD.icon = icon
                    end
                end
            end
        end

        local survivorMob = playerGui2:FindFirstChild("Survivor-mob")
        local controls = survivorMob and survivorMob:FindFirstChild("Controls")

        if controls then
            for i, child in ipairs(controls:GetChildren()) do
                if child:IsA("ImageButton") and child.Name == "Gui-mob" then
                    local bar = child:FindFirstChild("Bar")
                    local uiGradient = bar and bar:FindFirstChild("UIGradient")

                    if uiGradient then
                        table.insert(ParryHUD.gradients, uiGradient)
                    end
                end
            end
        end

        local flag2 = #ParryHUD.gradients > 0 or ParryHUD.icon ~= nil
        return flag2
    end

    ParryHUD.SetColor = function(cachedIconColor)
        if #ParryHUD.gradients == 0 and not ParryHUD.icon then
            ParryHUD.Scan()
        end

        ParryHUD.cachedIconColor = cachedIconColor

        for i, gradient in ipairs(ParryHUD.gradients) do
            if gradient and gradient.Parent and gradient.Parent.Parent then
                local icon = gradient.Parent.Parent:FindFirstChild("icon")

                if icon then
                    icon.ImageColor3 = cachedIconColor
                end

                local gui = gradient.Parent.Parent:FindFirstChild("Gui")

                if gui then
                    gui.ImageColor3 = cachedIconColor
                end
            end
        end

        if ParryHUD.icon then
            ParryHUD.icon.ImageColor3 = cachedIconColor
        end
    end

    ParryHUD.Tween = function(arg)
        if #ParryHUD.gradients == 0 then
            ParryHUD.Scan()
        end

        for i, gradient in ipairs(ParryHUD.gradients) do
            if gradient and gradient.Parent then
                gradient.Offset = Vector2.new(0, 0.75)
                local tween = TweenService:Create(gradient, TweenInfo.new(arg, Enum.EasingStyle.Linear), {Offset = Vector2.new(0, 0.25)})
                tween:Play()

                MXTrack(tween.Completed:Connect(function()
                    if not _G.MX.State.ParryCooldown then
                        ParryHUD.SetColor(Color3.fromRGB(255, 255, 255))
                    end
                end))
            end
        end
    end

    ParryHUD.Reset = function()
        ParryHUD.SetColor(Color3.fromRGB(255, 255, 255))

        for i, gradient in ipairs(ParryHUD.gradients) do
            if gradient and gradient.Parent then
                gradient.Offset = Vector2.new(0, 0.25)
            end
        end
    end

    ParryHUD.SetupWatcher = function()
        if ParryHUD.rescanConn then
            ParryHUD.rescanConn:Disconnect()
        end

        local playerGui2 = localPlayer:FindFirstChild("PlayerGui")
        if not playerGui2 then
            return
        end

        ParryHUD.rescanConn = MXTrack(playerGui2.ChildAdded:Connect(function(child)
            local name = child.Name

            if name == "Survivor" or name == "Survivor-con" or name == "Survivor-mob" then
                task.wait(0.3)
                ParryHUD.Scan()

                if _G.MX.State.ParryCooldown and ParryHUD.cachedIconColor then
                    ParryHUD.SetColor(ParryHUD.cachedIconColor)
                end
            end
        end))

        task.spawn(function()
            local n = 0

            while n < 10 and not ParryHUD.Scan() do
                task.wait(0.5)
                n = n + 0.5
            end
        end)
    end

    ParryHUD.SetupWatcher()

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        ParryHUD.Scan()

        if _G.MX.State.ParryCooldown and ParryHUD.cachedIconColor then
            ParryHUD.SetColor(ParryHUD.cachedIconColor)
        end
    end))

    ListenToParryResult = function()
        task.spawn(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
            local parryingDagger = remotes and remotes:WaitForChild("Items", 5):WaitForChild("Parrying Dagger", 5)
            local parryResult = parryingDagger and parryingDagger:WaitForChild("parryResult", 5)

            if parryResult then
                MXTrack(parryResult.OnClientEvent:Connect(function(arg, arg2)
                    local num = tonumber(arg2)
                    local n = num or (arg == true and 90 or 60)
                    _G.MX.State.ParryCooldown = true

                    if _G.MX.State.ParryCooldownThread then
                        task.cancel(_G.MX.State.ParryCooldownThread)
                    end

                    ParryHUD.SetColor(Color3.fromRGB(77, 77, 77))
                    ParryHUD.Tween(n)

                    _G.MX.State.ParryCooldownThread = task.delay(n, function()
                        _G.MX.State.ParryCooldown = false
                        ParryHUD.SetColor(Color3.fromRGB(255, 255, 255))
                    end)
                end))
            end
        end)
    end

    ListenToParryResult()

    AttachParrySensor = function(arg)
        if not arg or _G.MX.AttachedParry[arg] then
            return
        end
        _G.MX.AttachedParry[arg] = true
        local humanoid = arg:WaitForChild("Humanoid", 5)
        if not humanoid then
            return
        end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        local animator2 = animator or humanoid:WaitForChild("Animator", 5)
        if not animator2 then
            return
        end

        MXTrack(humanoid.ChildAdded:Connect(function(child)
            if child:IsA("Animator") then
                _G.MX.AttachedParry[arg] = nil
                AttachParrySensor(arg)
            end
        end))

        MXTrack(arg.AncestryChanged:Connect(function(child, parent)
            if not parent then
                _G.MX.AttachedParry[arg] = nil
            end
        end))

        MXTrack(animator2.AnimationPlayed:Connect(function(arg2)
            local animation = arg2.Animation
            local animationId = animation and arg2.Animation.AnimationId or ""
            local match = animationId:match("%d+")
            local v4 = tbl5[match] or attackByName(arg2.Name)
            if not v4 then
                return
            end

            if CROUCH_DODGE[match] and _G.MX.ParryConfig.AutoCrouch then
                local character = localPlayer.Character
                if IsDowned(character) then
                    return
                end
                local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                local humanoidRootPart2 = arg:FindFirstChild("HumanoidRootPart")

                if humanoidRootPart and humanoidRootPart2 and (humanoidRootPart.Position - humanoidRootPart2.Position).Magnitude <= 40 then
                    TriggerCrouch()
                end

                return
            end

            if not _G.MX.ParryConfig.AutoParry then
                return
            end

            if _G.MX.State.ParryCooldown then
                return
            end

            if _G.MX.ParryConfig.Ignored_Skills and _G.MX.ParryConfig.Ignored_Skills[v4] then
                return
            end
            local character = localPlayer.Character
            if IsDowned(character) or not IsSafeToParry(character) then
                return
            end
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            local humanoidRootPart2 = arg:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart or not humanoidRootPart2 then
                return
            end
            local magnitude = (humanoidRootPart.Position - humanoidRootPart2.Position).Magnitude
            local parryFace = _G.MX.ParryConfig.ParryFace

            if parryFace < 0.2 then
                parryFace = 0.35
            end

            if _G.MX.ParryConfig.ParryAggressive then
                if _G.MX.ParryReach(humanoidRootPart, humanoidRootPart2) < magnitude then
                    return
                end

                local function fn12()
                    if _G.MX.State.ParryCooldown or IsDowned(character) then
                        return true
                    end

                    if not humanoidRootPart or not humanoidRootPart2 or not humanoidRootPart.Parent or not humanoidRootPart2.Parent then
                        return true
                    end

                    if (humanoidRootPart.Position - humanoidRootPart2.Position).Magnitude > _G.MX.ParryReach(humanoidRootPart, humanoidRootPart2) then
                        return false
                    end
                    return ExecuteParry(humanoidRootPart2)
                end

                if fn12() then
                    return
                end
                local connection = nil
                local now = os.clock()

                connection = MXTrack(RunService.Heartbeat:Connect(function()
                    if (os.clock() - now >= 0.85 or fn12()) and connection then
                        connection:Disconnect()
                    end
                end))
            else
                local n = _G.MX.ParryReach(humanoidRootPart, humanoidRootPart2)

                if magnitude <= n and ExecuteParry(humanoidRootPart2) then
                    return
                end
                local now = os.clock()
                local connection = nil

                connection = MXTrack(RunService.Heartbeat:Connect(function()
                    if os.clock() - now < 0.6 and not _G.MX.State.ParryCooldown and humanoidRootPart and humanoidRootPart2 and humanoidRootPart.Parent and humanoidRootPart2.Parent and not IsDowned(character) then
                        if (humanoidRootPart.Position - humanoidRootPart2.Position).Magnitude <= _G.MX.ParryReach(humanoidRootPart, humanoidRootPart2) and ExecuteParry(humanoidRootPart2) then
                            if connection then
                                connection:Disconnect()
                            end
                        end

                        return
                    end

                    if connection then
                        connection:Disconnect()
                    end
                end))
            end
        end))
    end

    TryAttachParry = function(arg)
        if arg ~= localPlayer and IsKiller(arg) and arg.Character then
            AttachParrySensor(arg.Character)
        end
    end

    SetupPlayerParry = function(arg)
        if arg == localPlayer then
            return
        end

        MXTrack(arg.CharacterAdded:Connect(function()
            TryAttachParry(arg)
        end))

        MXTrack(arg:GetPropertyChangedSignal("Team"):Connect(function()
            TryAttachParry(arg)
        end))

        if arg.Character then
            TryAttachParry(arg)
        end
    end

    for i, player in ipairs(Players:GetPlayers()) do
        SetupPlayerParry(player)
    end

    Players.PlayerAdded:Connect(SetupPlayerParry)

    UpdateCustomParryGUI = function(arg)
        if not _G.MX.AutoParryCustom.Gui then
            return
        end
        local frame = _G.MX.AutoParryCustom.Gui:FindFirstChild("Frame")
        if not frame then
            return
        end
        local actionButton = frame:FindFirstChild("ActionButton")
        local uiStroke = frame:FindFirstChild("UIStroke")

        if arg then
            if actionButton then
                actionButton.Text = "PARRY [ON]"
                actionButton.TextColor3 = Color3.fromRGB(180, 255, 180)
                actionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            end

            if uiStroke then
                uiStroke.Color = Color3.fromRGB(100, 200, 100)
            end
        else
            if actionButton then
                actionButton.Text = "PARRY [OFF]"
                actionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                actionButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            end

            if uiStroke then
                uiStroke.Color = Color3.fromRGB(90, 90, 95)
            end
        end
    end

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        task.wait(1)

        if _G.MX.AutoParryCustom.GuiVisible and _G.MX.AutoParryCustom.Gui then
            _G.MX.AutoParryCustom.Gui.Enabled = true
            UpdateCustomParryGUI(_G.MX.ParryConfig.AutoParry)
        end
    end))

    _G.MX.NoFall = {Enabled = false}
    _G.MX.NextKiller = {Enabled = false, IndicatorGui = nil}

    _G.MX.CounterParry = {
        Enabled = false,
        Distance = 15,
        Interval = 0.3,
        AnimId = "rbxassetid://117042998468241",
        Thread = nil,
        Track = nil,
    }

    _G.MX.Crosshair = {
        Enabled = false,
        Size = 8,
        Thickness = 2,
        Color = Color3.fromRGB(255, 255, 255),
        Style = "Dot",
        OffsetX = 0,
        OffsetY = 0,
    }

    _G.MX.Spectator = {Enabled = false, Gui = nil, Label = nil}

    _G.MX.Moonwalk = {
        Enabled = false,
        GuiVisible = false,
        Gui = nil,
        IsActive = false,
    }

    _G.MX.CrosshairGui = nil
    _G.MX.CrosshairElements = {}
    _G.MX.CrosshairCreated = false
    _G.MX.LastCrosshairStyle = nil
    local ox2 = _G.MX
    local config = _G.MX.Config
    local config2 = config or {}
    ox2.Config = config2
    _G.MX.Config.Surv_PerfectVault = false
    _G.MX.autoVaultEnabled = false
    _G.MX.autoPalletSlideEnabled = false
    _G.MX.lastActionTime = 0
    _G.MX.COOLDOWN = 1.5
    _G.MX.StreamerMode = {Enabled = false, SpooferConns = {}}
    _G.MX.InfinityZoom = {Enabled = false}
    _G.MX.StretchRes = {Enabled = false, Amount = 0.67, Conn = nil}
    _G.MX.CameraFOV = {Enabled = false, Value = 90, Connection = nil}
    _G.MX.Auto = {SkillCheck = false, AntiTrap = false, SkillCheckMode = "Legit", TrapMode = "Perfect"}
    _G.MX.MapPredict = {Enabled = false}
    _G.MX.KillerPerks = {Enabled = false, Gui = nil, Minimized = false}

    _G.MX.Stun = {
        Enabled = false,
        Data = {},
    }

    _G.MX.ScriptAlive = true
    local ox3 = _G.MX
    local state = _G.MX.State
    local state2 = state or {}
    ox3.State = state2
    _G.MX.State.busy = false
    _G.MX.State.RandomMode_IsNormal = false
    _G.MX.Connections = {SkillHeartbeat = nil}
    _G.MX.Speed = {Enabled = false, Value = 0.1, Connection = nil, Loop = nil}
    _G.MX.AutoRun = {PC = false, Mobile = false, MobileThread = nil}

    tbl = {
        Generators = {},
        Hooks = {},
        Gates = {},
        Pallets = {},
        Windows = {},
    }

    tbl2 = {Enabled = false, Conn = nil}

    if not _G.MX.State then
        _G.MX.State = {}
    end

    _G.MX.State.ThirdPersonConn = nil

    tbl3 = {
        ["Left Arm"] = true,
        ["Right Arm"] = true,
        LeftHand = true,
        RightHand = true,
        LeftLowerArm = true,
        RightLowerArm = true,
        LeftUpperArm = true,
        RightUpperArm = true,
    }

    _G.MX.FakePerks = {
        QuickRecoveryEnabled = false,
        PerfectLandingEnabled = false,
        FlowstateEnabled = false,
        FakeAdrenalineRush = false,
        PerkCooldown = 0,
        boostActive = false,
        perfectLandingBoostActive = false,
        fsOnCooldown = false,
        lastQRTime = 0,
        lastPLTime = 0,
        lastFSTime = 0,
        qrConnection = nil,
        plConnection = nil,
        fsConnection = nil,
        fsAnimConnection = nil,
        adrenalineOn = false,
        adrenalineConns = {},
        lastARTime = 0,
    }


    _G.MX.FullBright = false
    _G.MX.NoFog = false
    _G.MX.NoShadow = false
    _G.MX.TimeOfDayValue = 14

    _G.MX.LowGFX = {
        Enabled = false,
        Textures = true,
        VisualEffects = true,
        Particles = true,
        Parts = true,
        Sky = true,
        Saved = {},
    }

    _G.MX.AimConfig = {
        Aim_SilentVeilV2 = false,
        Veil_ShowFOV = true,
        SpearSmart_enable = true,
        Veil_FOV = 150,
        SPEAR_Speed = 180,
        SPEAR_Gravity = 98.1,
        SPEAR_AuraSpeed = 180,
        SPEAR_AuraGravity = 98.1,
        SPEAR_MaxDist = 1e9,
        Veil_LeadMultiplier = 1,
        AIM_TargetPart = "Torso",
        Pistol_BlockKnocked = false,
        LockAim = false,
        Flash_Silent = false,
        Flash_YOffset = 1.5,
    }

    _G.MX.isKillerAimbotHolding = false
    _G.MX.lockedKillerAimbotTarget = nil
    _G.MX.killerAimbotHighlight = nil

    _G.MX.Config = {
        SpearSmart_enable = true,
        Killer_Aimbot_Enabled = false,
        Killer_Aimbot_MaxDist = 12,
        Killer_Aimbot_BestSmooth = true,
    }

    local flag2 = false
    local flag3 = false
    flag = false

    _G.MX.ESPConfig = {
        Master = false,
        Player = false,
        Killer = false,
        Outline = false,
        Name = false,
        Distance = false,
        KillerWarn = false,
        ItemIcon = false,
        Generator = false,
        GeneratorName = true,
        Pallet = false,
        Hook = false,
        Gate = false,
        Window = false,
        SCP = false,
        HookCount = false,
        Status = false,
        MaxDistance = 1000,
    }

    _G.MX.ESPColors = {
        Player = Color3.fromRGB(60, 255, 90),
        Killer = Color3.fromRGB(255, 40, 40),
        Generator = Color3.fromRGB(255, 225, 0),
        GeneratorDone = Color3.fromRGB(0, 255, 190),
        Pallet = Color3.fromRGB(255, 120, 0),
        Hook = Color3.fromRGB(255, 90, 200),
        Gate = Color3.fromRGB(255, 255, 255),
        Window = Color3.fromRGB(0, 190, 255),
        SCP = Color3.fromRGB(170, 70, 255),
        Injured = Color3.fromRGB(255, 190, 70),
        Downed = Color3.fromRGB(255, 60, 120),
        Hooked = Color3.fromRGB(190, 150, 255),
    }

    tbl4 = {
        Generators = {},
        Windows = {},
        Pallets = {},
        Hooks = {},
        Gates = {},
        SCPs = {},
    }

    GetRole = function()
        if not localPlayer.Team then
            return "Unknown"
        end
        local name = localPlayer.Team.Name
        if name == "Killer" then
            return "Killer"
        end

        if name == "Survivors" then
            return "Survivor"
        end
        return "Spectator"
    end

    GetDistance = function(arg)
        local character = localPlayer.Character
        local humanoidRootPart = character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return math.huge
        end
        return (arg - humanoidRootPart.Position).Magnitude
    end

    fn = function(arg, arg2)
        if arg and type(arg.SetValue) == "function" then
            pcall(function()
                arg:SetValue(arg2)
            end)
        end
    end

    ClearCrosshair = function()
        if _G.MX.CrosshairGui then
            _G.MX.CrosshairGui:Destroy()
            _G.MX.CrosshairGui = nil
        end

        _G.MX.CrosshairElements = {}
        _G.MX.CrosshairCreated = false
        _G.MX.LastCrosshairStyle = nil
    end

    DrawCrosshair = function()
        if not _G.MX.Crosshair.Enabled then
            if _G.MX.CrosshairGui then
                _G.MX.CrosshairGui.Enabled = false
            end

            return
        end

        if _G.MX.CrosshairGui then
            _G.MX.CrosshairGui.Enabled = true
        end

        if _G.MX.LastCrosshairStyle ~= _G.MX.Crosshair.Style or not _G.MX.CrosshairGui then
            ClearCrosshair()
            _G.MX.LastCrosshairStyle = _G.MX.Crosshair.Style
        end

        if not _G.MX.CrosshairCreated then
            _G.MX.CrosshairCreated = true
            _G.MX.CrosshairGui = Instance.new("ScreenGui")
            _G.MX.CrosshairGui.Name = "CrosshairUI"
            _G.MX.CrosshairGui.IgnoreGuiInset = true
            _G.MX.CrosshairGui.ResetOnSpawn = false
            _G.MX.CrosshairGui.DisplayOrder = 999
            _G.MX.CrosshairGui.Parent = CoreGui

            local function createFrame(size, position)
                local frame = Instance.new("Frame")
                frame.BackgroundColor3 = _G.MX.Crosshair.Color
                frame.BorderSizePixel = 0
                frame.AnchorPoint = Vector2.new(0.5, 0.5)
                frame.Size = size
                frame.Position = position
                frame.Parent = _G.MX.CrosshairGui
                return frame
            end

            local udim2 = UDim2.new(0.5, _G.MX.Crosshair.OffsetX, 0.5, _G.MX.Crosshair.OffsetY)

            if _G.MX.Crosshair.Style == "Plus" then
                _G.MX.CrosshairElements[1] = createFrame(UDim2.new(0, _G.MX.Crosshair.Size * 2, 0, _G.MX.Crosshair.Thickness), udim2)
                _G.MX.CrosshairElements[2] = createFrame(UDim2.new(0, _G.MX.Crosshair.Thickness, 0, _G.MX.Crosshair.Size * 2), udim2)
            elseif _G.MX.Crosshair.Style == "Dot" then
                local frame = Instance.new("Frame")
                frame.BackgroundColor3 = _G.MX.Crosshair.Color
                frame.BorderSizePixel = 0
                frame.AnchorPoint = Vector2.new(0.5, 0.5)
                frame.Size = UDim2.new(0, _G.MX.Crosshair.Size, 0, _G.MX.Crosshair.Size)
                frame.Position = udim2
                Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
                frame.Parent = _G.MX.CrosshairGui
                _G.MX.CrosshairElements[1] = frame
            elseif _G.MX.Crosshair.Style == "Circle" then
                local frame = Instance.new("Frame")
                frame.BackgroundTransparency = 1
                frame.BorderSizePixel = 0
                frame.AnchorPoint = Vector2.new(0.5, 0.5)
                frame.Size = UDim2.new(0, _G.MX.Crosshair.Size * 2, 0, _G.MX.Crosshair.Size * 2)
                frame.Position = udim2
                frame.Parent = _G.MX.CrosshairGui
                local uiStroke = Instance.new("UIStroke")
                uiStroke.Color = _G.MX.Crosshair.Color
                uiStroke.Thickness = _G.MX.Crosshair.Thickness
                uiStroke.Parent = frame
                Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
                _G.MX.CrosshairElements[1] = frame
            end
        end

        local udim2 = UDim2.new(0.5, _G.MX.Crosshair.OffsetX, 0.5, _G.MX.Crosshair.OffsetY)

        if _G.MX.Crosshair.Style == "Plus" then
            if _G.MX.CrosshairElements[1] then
                _G.MX.CrosshairElements[1].Size = UDim2.new(0, _G.MX.Crosshair.Size * 2, 0, _G.MX.Crosshair.Thickness)
                _G.MX.CrosshairElements[1].Position = udim2
                _G.MX.CrosshairElements[1].BackgroundColor3 = _G.MX.Crosshair.Color
            end

            if _G.MX.CrosshairElements[2] then
                _G.MX.CrosshairElements[2].Size = UDim2.new(0, _G.MX.Crosshair.Thickness, 0, _G.MX.Crosshair.Size * 2)
                _G.MX.CrosshairElements[2].Position = udim2
                _G.MX.CrosshairElements[2].BackgroundColor3 = _G.MX.Crosshair.Color
            end
        elseif _G.MX.Crosshair.Style == "Dot" then
            if _G.MX.CrosshairElements[1] then
                _G.MX.CrosshairElements[1].Size = UDim2.new(0, _G.MX.Crosshair.Size, 0, _G.MX.Crosshair.Size)
                _G.MX.CrosshairElements[1].Position = udim2
                _G.MX.CrosshairElements[1].BackgroundColor3 = _G.MX.Crosshair.Color
            end
        elseif _G.MX.Crosshair.Style == "Circle" and _G.MX.CrosshairElements[1] then
            _G.MX.CrosshairElements[1].Size = UDim2.new(0, _G.MX.Crosshair.Size * 2, 0, _G.MX.Crosshair.Size * 2)
            _G.MX.CrosshairElements[1].Position = udim2
            local uiStroke = _G.MX.CrosshairElements[1]:FindFirstChildOfClass("UIStroke")

            if uiStroke then
                uiStroke.Color = _G.MX.Crosshair.Color
                uiStroke.Thickness = _G.MX.Crosshair.Thickness
            end
        end
    end

    local n2 = 0

    fn2 = function(arg)
        if not arg and tick() - n2 < 2 then
            return
        end
        n2 = tick()
        local ntbl = {Generators = {}, Windows = {}, Pallets = {}, Hooks = {}, Gates = {}}
        local ntbl4 = {Generators = {}, Windows = {}, Pallets = {}, Hooks = {}, Gates = {}, SCPs = {}}
        local map = workspace:FindFirstChild("Map")
        local v4 = map or workspace
        local descendants = v4:GetDescendants()

        for i, descendant in ipairs(descendants) do
            if i % 1500 == 0 then
                task.wait()
            end

            if descendant:IsA("Model") then
                local v5 = string.lower(descendant.Name)

                if v5 == "generator" then
                    local generatorBody = descendant:FindFirstChild("GeneratorBody")
                    local basePart = generatorBody or descendant:FindFirstChildWhichIsA("BasePart")

                    if basePart then
                        local tbl6 = {model = descendant, part = basePart}
                        table.insert(ntbl.Generators, tbl6)
                        table.insert(ntbl4.Generators, tbl6)
                    end
                elseif v5 == "hook" and descendant:FindFirstChild("HookPoint") then
                    table.insert(ntbl.Hooks, descendant)
                    table.insert(ntbl4.Hooks, descendant)
                elseif v5 == "gate" and descendant:FindFirstChild("ExitLever") then
                    table.insert(ntbl.Gates, descendant)
                    table.insert(ntbl4.Gates, descendant)
                elseif v5 == "window" then
                    table.insert(ntbl.Windows, descendant)
                    table.insert(ntbl4.Windows, descendant)
                end
            elseif descendant:IsA("BasePart") and descendant.Name == "PrimaryPartPallet" then
                local parent = descendant.Parent

                if parent and not table.find(ntbl.Pallets, parent) then
                    table.insert(ntbl.Pallets, parent)
                    table.insert(ntbl4.Pallets, parent)
                end
            end
        end

        local descendants2 = workspace:GetDescendants()

        for i, v5 in ipairs(descendants2) do
            if i % 1500 == 0 then
                task.wait()
            end

            if v5:IsA("Model") and string.match(string.lower(v5.Name), "^scp") and not table.find(ntbl4.SCPs, v5) then
                table.insert(ntbl4.SCPs, v5)
            end
        end

        for _, tagged in ipairs(CollectionService:GetTagged("scp")) do
            local model = tagged:IsA("Model") and tagged or tagged:FindFirstAncestorOfClass("Model")
            if model and not table.find(ntbl4.SCPs, model) then
                table.insert(ntbl4.SCPs, model)
            end
        end
        for _, point in ipairs(CollectionService:GetTagged("VaultPoint")) do
            local model = point.Parent
            if model and model ~= workspace and model:IsDescendantOf(workspace) and not table.find(ntbl4.Windows, model) then
                local lname = string.lower(model.Name)
                if lname == "window" or lname:find("window") or lname:find("vault") then
                    table.insert(ntbl.Windows, model)
                    table.insert(ntbl4.Windows, model)
                end
            end
        end
        for _, point in ipairs(CollectionService:GetTagged("PalletPoint")) do
            local model = point.Parent
            if model and model ~= workspace and model:IsDescendantOf(workspace) and not table.find(ntbl4.Pallets, model) then
                table.insert(ntbl.Pallets, model)
                table.insert(ntbl4.Pallets, model)
            end
        end
        for _, model in ipairs(CollectionService:GetTagged("pallet")) do
            if model:IsA("Model") and model:IsDescendantOf(workspace) and not table.find(ntbl4.Pallets, model) then
                table.insert(ntbl.Pallets, model)
                table.insert(ntbl4.Pallets, model)
            end
        end
        for _, key in ipairs({"Generators", "Windows", "Pallets", "Hooks", "Gates"}) do
            table.clear(tbl[key])
            table.clear(tbl4[key])
            for _, item in ipairs(ntbl[key]) do table.insert(tbl[key], item) end
            for _, item in ipairs(ntbl4[key]) do table.insert(tbl4[key], item) end
        end
        table.clear(tbl4.SCPs)
        for _, item in ipairs(ntbl4.SCPs) do table.insert(tbl4.SCPs, item) end
    end

    fn3 = function(arg)
        if not arg then
            return
        end
        local character = localPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

        if humanoidRootPart then
            local vector = Vector3.new(0, 3, 0)

            if arg:IsA("BasePart") then
                humanoidRootPart.CFrame = arg.CFrame + vector
            elseif arg:IsA("Model") then
                local basePart = arg:FindFirstChildWhichIsA("BasePart")

                if basePart then
                    humanoidRootPart.CFrame = basePart.CFrame + vector
                end
            end

        end
    end

    ApplyFullBright = function()
        local Lighting = game:GetService("Lighting")
        if not Lighting then
            return
        end

        if _G.MX.FullBright then
            Lighting.Brightness = 2.8
            Lighting.ClockTime = _G.MX.TimeOfDayValue
            Lighting.FogEnd = 100000
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        end
    end

    ApplyNoFog = function()
        local Lighting = game:GetService("Lighting")
        if not Lighting then
            return
        end

        if _G.MX.NoFog then
            Lighting.FogStart = 0
            Lighting.FogEnd = 100000
            Lighting.FogColor = Color3.fromRGB(255, 255, 255)
            local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

            if atmosphere then
                atmosphere.Density = 0
                atmosphere.Offset = 0
                atmosphere.Glare = 0
                atmosphere.Haze = 0
            end
        end
    end

    ApplyNoShadow = function()
        local Lighting = game:GetService("Lighting")
        if not Lighting then
            return
        end
        local globalShadows

        if _G.MX.NoShadow then
            globalShadows = false
        else
            globalShadows = true
        end

        Lighting.GlobalShadows = globalShadows
    end

    ReapplyPerformance = function()
        ApplyFullBright()
        ApplyNoFog()
        ApplyNoShadow()
    end

    ReapplyPerformanceDelayed = function()
        task.spawn(function()
            ReapplyPerformance()
            task.wait(1.2)
            ReapplyPerformance()
            task.wait(2)
            ReapplyPerformance()
            task.wait(3)
            ReapplyPerformance()
        end)
    end

    StartLightingGuard = function()
        if _G.MX.LightingGuardConn then
            return
        end
        local n3 = 0

        _G.MX.LightingGuardConn = MXTrack(RunService.Heartbeat:Connect(function()
            if not _G.MX.FullBright and not _G.MX.NoFog and not _G.MX.NoShadow then
                return
            end
            local now = tick()
            if now - n3 < 0.4 then
                return
            end
            n3 = now
            ReapplyPerformance()
        end))
    end

    StopLightingGuard = function()
        if _G.MX.FullBright or _G.MX.NoFog or _G.MX.NoShadow then
            return
        end

        if _G.MX.LightingGuardConn then
            _G.MX.LightingGuardConn:Disconnect()
            _G.MX.LightingGuardConn = nil
        end
    end

    if not _G.MX.LightingChildConn then
        _G.MX.LightingChildConn = MXTrack(game:GetService("Lighting").ChildAdded:Connect(function(child)
            if not _G.MX.FullBright and not _G.MX.NoFog then
                return
            end

            task.defer(function()
                if child:IsA("Atmosphere") and _G.MX.NoFog then
                    child.Density = 0
                    child.Offset = 0
                    child.Glare = 0
                    child.Haze = 0
                end

                ReapplyPerformance()
            end)
        end))
    end

    local function fn16(arg, arg2, arg3)
        table.insert(_G.MX.LowGFX.Saved, {obj = arg, kind = arg2, extra = arg3})
    end

    local function isOurs(inst)
        local node = inst
        while node and node ~= workspace and node ~= game do
            if string.sub(node.Name, 1, 5) == "MXHUB" then
                return true
            end
            node = node.Parent
        end
        return false
    end

    local function inAvatar(inst)
        local model = inst:FindFirstAncestorWhichIsA("Model")
        while model and model ~= workspace do
            if model:FindFirstChildOfClass("Humanoid") then
                return true
            end
            local parent = model.Parent
            model = parent and parent:FindFirstAncestorWhichIsA("Model")
        end
        return false
    end

    LowGFX_ProcessOne = function(arg)
        if not _G.MX.LowGFX.Enabled or not arg then
            return
        end
        local lowGFX = _G.MX.LowGFX

        local isEffect = arg:IsA("ParticleEmitter") or arg:IsA("Smoke") or arg:IsA("Explosion") or arg:IsA("Sparkles") or arg:IsA("Fire")
            or arg:IsA("Trail") or arg:IsA("Beam") or arg:IsA("Light")

        if isEffect then
            if lowGFX.Particles and arg.Enabled ~= false and not isOurs(arg) then
                fn16(arg, "Particle", true)
                arg.Enabled = false
            end
            return
        end

        if arg:IsA("ForceField") then
            if arg.Visible then
                fn16(arg, "Visible", true)
                arg.Visible = false
            end
            return
        end

        if lowGFX.VisualEffects and (arg:IsA("BloomEffect") or arg:IsA("BlurEffect") or arg:IsA("DepthOfFieldEffect") or arg:IsA("SunRaysEffect") or arg:IsA("ColorCorrectionEffect")) and arg.Enabled ~= false then
            fn16(arg, "VFX", true)
            arg.Enabled = false
            return
        end

        if lowGFX.Sky and (arg:IsA("Sky") or arg:IsA("Atmosphere") or arg:IsA("Clouds")) then
            fn16(arg, "Detach", arg.Parent)
            arg.Parent = nil
            return
        end

        local isPart = arg:IsA("BasePart")
        local isSkin = arg:IsA("Decal") or arg:IsA("Texture") or arg:IsA("SpecialMesh") or arg:IsA("SurfaceAppearance")
        if not (isPart or isSkin) or isOurs(arg) or inAvatar(arg) then
            return
        end

        if lowGFX.Parts and isPart and arg.Material ~= Enum.Material.SmoothPlastic then
            fn16(arg, "Part", arg.Material)
            arg.Material = Enum.Material.SmoothPlastic
        end

        if lowGFX.Textures then
            if (arg:IsA("Decal") or arg:IsA("Texture")) and arg.Texture ~= "" then
                fn16(arg, "Texture", arg.Texture)
                arg.Texture = ""
            elseif arg:IsA("MeshPart") and arg.TextureID ~= "" then
                fn16(arg, "MeshTexture", arg.TextureID)
                arg.TextureID = ""
            elseif arg:IsA("SpecialMesh") and arg.TextureId ~= "" then
                fn16(arg, "MeshTexture", arg.TextureId)
                arg.TextureId = ""
            elseif arg:IsA("SurfaceAppearance") then
                fn16(arg, "Detach", arg.Parent)
                arg.Parent = nil
            end
        end

        if lowGFX.Parts and isPart and arg.CastShadow then
            fn16(arg, "Shadow", true)
            arg.CastShadow = false
        end
    end

    ApplyLowGFX = function()
        if not _G.MX.LowGFX.Enabled then
            return
        end
        local tbl6 = {workspace, game:GetService("Lighting")}
        local v4, v5, v6 = ipairs(tbl6)
        local v7 = v6
        local v8 = v4
        local v9 = v5

        while true do
            local v10, v11 = v8(v9, v7)
            if v10 == nil then
                break
            end
            local descendants = v11:GetDescendants()

            for i, descendant in ipairs(descendants) do
                if i % 250 == 0 then
                    task.wait()
                end

                LowGFX_ProcessOne(descendant)
            end

            v7 = v10
        end
    end

    RestoreLowGFX = function()
        for i, v4 in ipairs(_G.MX.LowGFX.Saved) do
            local obj = v4.obj

            if v4.kind == "Detach" then
                pcall(function()
                    obj.Parent = v4.extra
                end)
            elseif obj and obj.Parent then
                pcall(function()
                    if v4.kind == "Part" then
                        obj.Material = v4.extra
                    elseif v4.kind == "Texture" then
                        obj.Texture = v4.extra
                    elseif v4.kind == "MeshTexture" then
                        if obj:IsA("MeshPart") then
                            obj.TextureID = v4.extra
                        else
                            obj.TextureId = v4.extra
                        end
                    elseif v4.kind == "Shadow" then
                        obj.CastShadow = v4.extra
                    elseif v4.kind == "Visible" then
                        obj.Visible = v4.extra
                    else
                        obj.Enabled = v4.extra
                    end
                end)
            end
        end

        table.clear(_G.MX.LowGFX.Saved)
    end

    local skyDome, skyFollow, savedLighting

    local function setBlueSky(on)
        local lighting = game:GetService("Lighting")
        if skyFollow then
            skyFollow:Disconnect()
            skyFollow = nil
        end
        if skyDome then
            skyDome:Destroy()
            skyDome = nil
        end
        if on then
            savedLighting = savedLighting or {
                GlobalShadows = lighting.GlobalShadows,
                FogEnd = lighting.FogEnd,
                Ambient = lighting.Ambient,
                OutdoorAmbient = lighting.OutdoorAmbient,
                Brightness = lighting.Brightness,
            }
            lighting.GlobalShadows = false
            lighting.FogEnd = 1e9
            lighting.Ambient = Color3.fromRGB(170, 170, 170)
            lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
            lighting.Brightness = 2
            skyDome = Instance.new("Part")
            skyDome.Name = "MXHUB_SkyDome"
            skyDome.Anchored = true
            skyDome.CanCollide = false
            skyDome.CanTouch = false
            skyDome.CanQuery = false
            skyDome.CastShadow = false
            skyDome.Material = Enum.Material.Neon
            skyDome.Color = Color3.fromRGB(90, 185, 255)
            skyDome.Size = Vector3.new(1800, 1800, 1800)
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Sphere
            mesh.Scale = Vector3.new(-1, 1, 1)
            mesh.Parent = skyDome
            skyDome.Parent = workspace
            skyFollow = MXTrack(RunService.RenderStepped:Connect(function()
                local cam = workspace.CurrentCamera
                if cam and skyDome then
                    skyDome.CFrame = CFrame.new(cam.CFrame.Position)
                end
            end))
        elseif savedLighting then
            for key, value in pairs(savedLighting) do
                lighting[key] = value
            end
            savedLighting = nil
        end
    end

    ToggleLowGFX = function(enabled)
        _G.MX.LowGFX.Enabled = enabled
        setBlueSky(enabled)

        if enabled then
            task.spawn(ApplyLowGFX)

        else
            RestoreLowGFX()

        end
    end

    lib.API.Track(function()
        setBlueSky(false)
        RestoreLowGFX()
    end)

    if not _G.MX.LowGFX.StreamConn then
        _G.MX.LowGFX.StreamConn = MXTrack(workspace.DescendantAdded:Connect(function(descendant)
            if not _G.MX.LowGFX.Enabled then
                return
            end

            task.defer(function()
                LowGFX_ProcessOne(descendant)
            end)
        end))
    end

    CreateSpectatorUI = function()
        if _G.MX.Spectator.Gui then
            _G.MX.Spectator.Gui:Destroy()
            _G.MX.Spectator.Gui = nil
        end

        _G.MX.Spectator.Gui = Instance.new("ScreenGui")
        _G.MX.Spectator.Gui.Name = "SpectatorCounter"
        _G.MX.Spectator.Gui.ResetOnSpawn = false
        _G.MX.Spectator.Gui.Parent = localPlayer:WaitForChild("PlayerGui")
        local frame = Instance.new("Frame")
        frame.Name = "MainBox"
        frame.AnchorPoint = Vector2.new(0.5, 1)
        frame.Position = UDim2.new(0.5, 0, 0, -10)
        frame.Size = UDim2.new(0, 68, 0, 22)
        frame.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
        frame.BackgroundTransparency = 0.25
        frame.BorderSizePixel = 0
        frame.Parent = _G.MX.Spectator.Gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        local uiGradient = Instance.new("UIGradient")

        uiGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0.4),
            NumberSequenceKeypoint.new(1, 1),
        })

        uiGradient.Parent = frame
        local uiListLayout = Instance.new("UIListLayout", frame)
        uiListLayout.FillDirection = Enum.FillDirection.Horizontal
        uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        uiListLayout.Padding = UDim.new(0, 6)
        local imageLabel = Instance.new("ImageLabel", frame)
        imageLabel.Size = UDim2.new(0, 15, 0, 15)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = "rbxassetid://13321848320"
        imageLabel.ImageColor3 = Color3.fromRGB(225, 225, 225)
        _G.MX.Spectator.Label = Instance.new("TextLabel", frame)
        _G.MX.Spectator.Label.BackgroundTransparency = 1
        _G.MX.Spectator.Label.Font = Enum.Font.GothamMedium
        _G.MX.Spectator.Label.Text = "0"
        _G.MX.Spectator.Label.TextColor3 = Color3.fromRGB(240, 240, 240)
        _G.MX.Spectator.Label.TextSize = 13
        _G.MX.Spectator.Label.AutomaticSize = Enum.AutomaticSize.X
    end

    UpdateSpectatorCount = function()
        if not _G.MX.Spectator.Enabled or not _G.MX.Spectator.Label then
            return
        end
        local n3 = 0

        for i, player in ipairs(Players:GetPlayers()) do
            if player.Team and player.Team.Name == "Spectator" then
                n3 = n3 + 1
            end
        end

        _G.MX.Spectator.Label.Text = tostring(n3)
        local gui = _G.MX.Spectator.Gui
        local mainBox = gui and _G.MX.Spectator.Gui:FindFirstChild("MainBox")

        if mainBox then
            local udim2 = UDim2.new
            local n4 = n3 >= 10 and 8 or 0
            local n5 = 55 + n4
            local n6 = n3 >= 100 and 8 or 0
            mainBox.Size = udim2(0, n5 + n6, 0, 22)
        end
    end

    StartSpectatorInfo = function()
        if _G.MX.Spectator.Enabled then
            return
        end
        _G.MX.Spectator.Enabled = true
        CreateSpectatorUI()
        UpdateSpectatorCount()

        task.spawn(function()
            while _G.MX.Spectator.Enabled do
                UpdateSpectatorCount()
                task.wait(1.2)
            end
        end)

    end

    StopSpectatorInfo = function()
        _G.MX.Spectator.Enabled = false

        if _G.MX.Spectator.Gui then
            _G.MX.Spectator.Gui:Destroy()
            _G.MX.Spectator.Gui = nil
            _G.MX.Spectator.Label = nil
        end

    end

    fn4 = function(arg)
        if arg then
            StartSpectatorInfo()
        else
            StopSpectatorInfo()
        end
    end

    ScanMapESP = function(arg)
        fn2(arg)
    end

    ForceRefreshMap = function()
        fn2(true)

        if _G.MX.ESPConfig.Master then
            ClearAllESP()
            task.wait(0.1)
            UpdatePlayerESP()
            UpdateSCPESP()
            UpdateStaticESP()
        end
    end

    task.spawn(function()
        task.wait(2)
        ScanMapESP()
    end)

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        ScanMapESP()

        if _G.MX.ESPConfig.Master then
            task.spawn(function()
                task.wait(0.5)
                ClearAllESP()
                task.wait(0.2)
                UpdatePlayerESP()
                UpdateSCPESP()
                UpdateStaticESP()
            end)
        end
    end))

    MXTrack(workspace.ChildAdded:Connect(function(child)
        if child.Name == "Map" then
            task.wait(1)
            ScanMapESP(true)

            if _G.MX.ESPConfig.Master then
                pcall(UpdatePlayerESP)
                pcall(UpdateSCPESP)
                pcall(UpdateStaticESP)
            end

            ReapplyPerformanceDelayed()

            if _G.MX.LowGFX.Enabled then
                table.clear(_G.MX.LowGFX.Saved)
                task.wait(1.5)
                ApplyLowGFX()
                task.wait(2.5)

                if _G.MX.LowGFX.Enabled then
                    ApplyLowGFX()
                end
            end
        end
    end))

    task.spawn(function()
        while _G.MX.ScriptAlive do
            task.wait(40)

            if _G.MX.ESPConfig.Master then
                ScanMapESP()

                if _G.MX.ESPConfig.Master then
                    pcall(UpdateStaticESP)
                    pcall(UpdatePlayerESP)
                    pcall(UpdateSCPESP)
                end
            end
        end
    end)

    local function fn17()
        local playerGui2 = localPlayer:FindFirstChild("PlayerGui")
        if not playerGui2 then
            return nil
        end
        local survivorMob = playerGui2:FindFirstChild("Survivor-mob")
        if not survivorMob then
            return nil
        end
        local controls = survivorMob:FindFirstChild("Controls")
        if not controls then
            return nil
        end
        local sprint = controls:FindFirstChild("sprint")
        if not sprint then
            return nil
        end

        if sprint:IsA("GuiButton") then
            return sprint
        end
        local icon = sprint:FindFirstChild("icon")
        if icon and icon:IsA("GuiButton") then
            return icon
        end

        if icon and icon.Parent and icon.Parent:IsA("GuiButton") then
            return icon.Parent
        end

        if sprint.Parent and sprint.Parent:IsA("GuiButton") then
            return sprint.Parent
        end
        return sprint
    end

    local function fn18()
        local v4 = fn17()
        if not v4 then
            return false
        end

        pcall(function()
            if type(firesignal) == "function" then
                firesignal(v4.MouseButton1Click)
                firesignal(v4.MouseButton1Down)
                task.wait(0.04)
                firesignal(v4.MouseButton1Up)
            else
                local absolutePosition = v4.AbsolutePosition
                local absoluteSize = v4.AbsoluteSize
                local guiInset = GuiService:GetGuiInset()
                local n3 = absolutePosition.X + absoluteSize.X / 2 + guiInset.X
                local n4 = absolutePosition.Y + absoluteSize.Y / 2 + guiInset.Y
                VirtualInputManager:SendTouchEvent(9901, 0, n3, n4)
                task.wait(0.04)
                VirtualInputManager:SendTouchEvent(9901, 2, n3, n4)
            end
        end)

        return true
    end

    local function fn19()
        local character = localPlayer.Character
        if not character then
            return false
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return false
        end

        if humanoid.MoveDirection.Magnitude > 0.12 then
            return true
        end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

        if humanoidRootPart then
            local assemblyLinearVelocity = humanoidRootPart.AssemblyLinearVelocity
            if Vector3.new(assemblyLinearVelocity.X, 0, assemblyLinearVelocity.Z).Magnitude > 1.5 then
                return true
            end
        end

        return false
    end

    local function fn20()
        local character = localPlayer.Character
        if not character then
            return false
        end
        local flag4 = character:GetAttribute("Crouching") == true or character:GetAttribute("Crouchingserver") == true
        return flag4
    end

    local function fn21()
        local character = localPlayer.Character
        if not character then
            return false
        end
        local flag4 = character:GetAttribute("Sprinting") == true or character:GetAttribute("IsRunning") == true
        return flag4
    end

    fn5 = function()
        if _G.MX.AutoRun.MobileThread then
            return
        end

        _G.MX.AutoRun.MobileThread = task.spawn(function()
            local lastTap = -10
            local wantSince = nil
            while _G.MX.AutoRun.Mobile do
                local character = localPlayer.Character
                local blocked = character == nil
                    or character:GetAttribute("IsCarried") == true
                    or character:GetAttribute("Trapped") == true
                    or character:GetAttribute("Knocked") == true
                    or character:GetAttribute("IsHooked") == true
                    or character:GetAttribute("Immobile") == true
                    or character:GetAttribute("Crouching") == true
                    or character:GetAttribute("Crouchingserver") == true
                if not blocked and fn19() and not fn21() then
                    wantSince = wantSince or os.clock()
                    if os.clock() - wantSince >= 0.18 and os.clock() - lastTap >= 0.6 then
                        fn18()
                        lastTap = os.clock()
                        wantSince = nil
                    end
                else
                    wantSince = nil
                end
                task.wait(0.06)
            end

            _G.MX.AutoRun.MobileThread = nil
        end)
    end

    fn6 = function()
        _G.MX.AutoRun.Mobile = false

        if _G.MX.AutoRun.MobileThread then
            task.cancel(_G.MX.AutoRun.MobileThread)
            _G.MX.AutoRun.MobileThread = nil
        end

        if fn21() then
            fn18()
        end
    end

    task.spawn(function()
        while _G.MX.ScriptAlive do
            task.wait(0.1)
            if not _G.MX.ScriptAlive then
                break
            end

            if not UserInputService.TouchEnabled and tick() - _G.MX.lastActionTime >= _G.MX.COOLDOWN then
                local autoVaultEnabled = _G.MX.autoVaultEnabled
                local autoPalletSlideEnabled = _G.MX.autoPalletSlideEnabled

                if autoVaultEnabled or autoPalletSlideEnabled then
                    local pcprompts = playerGui:FindFirstChild("pcprompts")
                    local frame = pcprompts and pcprompts:FindFirstChild("Frame")

                    if frame then
                        local vaultPromptGui = frame:FindFirstChild("VaultPromptGui")
                        local palletSlidePromptGui = frame:FindFirstChild("PalletSlidePromptGui")
                        local visible = vaultPromptGui and vaultPromptGui.Visible
                        local visible2 = palletSlidePromptGui and palletSlidePromptGui.Visible

                        if autoVaultEnabled and visible or autoPalletSlideEnabled and visible2 then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                            task.wait(0.01)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                            _G.MX.lastActionTime = tick()
                        end
                    end
                end
            end
        end
    end)

    local function fn22()
        if not UserInputService.TouchEnabled then
            return
        end
        local survivorMob = playerGui:FindFirstChild("Survivor-mob")
        local survivorMob2 = survivorMob or playerGui:WaitForChild("Survivor-mob", 8)
        if not survivorMob2 then
            return
        end
        local controls = survivorMob2:FindFirstChild("Controls")
        local controls2 = controls or survivorMob2:WaitForChild("Controls", 5)
        local action = controls2

        if controls2 then
            local action2 = controls2:FindFirstChild("action")
            action = action2 or controls2:WaitForChild("action", 5)
        end

        if not action then
            return
        end

        local tbl6 = {
            vault = true,
            palletvault = true,
            palletslide = true,
            slide = true,
        }

        local function fn23(arg)
            if not arg:IsA("ImageLabel") and not arg:IsA("ImageButton") then
                return
            end
            local str = arg.Name:lower()
            if not tbl6[str] then
                return
            end

            MXTrack(arg:GetPropertyChangedSignal("Visible"):Connect(function()
                if not arg.Visible then
                    return
                end

                if tick() - _G.MX.lastActionTime < _G.MX.COOLDOWN then
                    return
                end
                local pos = str:find("vault")
                local flag4 = pos

                if pos then
                    if str:find("pallet") then
                        flag4 = false
                    else
                        flag4 = true
                    end
                end

                local pos2 = str:find("pallet")
                local pos3 = pos2 or str:find("slide")

                if flag4 and _G.MX.autoVaultEnabled or pos3 and _G.MX.autoPalletSlideEnabled then
                    pcall(function()
                        firesignal(action.MouseButton1Down)
                        task.wait(0.01)
                        firesignal(action.MouseButton1Up)
                    end)

                    _G.MX.lastActionTime = tick()
                end
            end))
        end

        for k, child in pairs(action:GetChildren()) do
            fn23(child)
        end

        MXTrack(action.ChildAdded:Connect(function(child)
            task.wait()
            fn23(child)
        end))
    end

    task.spawn(fn22)

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        fn22()
    end))

    playerGui.ChildAdded:Connect(function(child)
        if child.Name == "Survivor-mob" then
            task.wait(1)
            fn22()
        end
    end);

    (function()
        task.spawn(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
            local killerPerks = remotes and remotes:WaitForChild("KillerPerks", 5)
            local kingscourge = killerPerks and killerPerks:WaitForChild("kingscourge", 5)
            local kingScourgeStart = kingscourge and kingscourge:WaitForChild("KingScourgeStart", 5)

            if kingScourgeStart then
                MXTrack(kingScourgeStart.OnClientEvent:Connect(function()
                    if _G.MX.Auto.SkillCheckMode == "Random" then
                        _G.MX.State.RandomMode_IsNormal = true
                    end
                end))
            end
        end)
    end)()

    local function fn23()
        if not playerGui then
            return nil
        end
        local survivorMob = playerGui:FindFirstChild("Survivor-mob")
        if not survivorMob then
            return nil
        end
        local controls = survivorMob:FindFirstChild("Controls")
        if not controls then
            return nil
        end
        local action = controls:FindFirstChild("action")
        local check = action or controls:FindFirstChild("check")
        return check
    end

    local function fn24(signalFirst)
        local button = fn23()
        if signalFirst == false then
            button = nil
        end
        if button and button:IsA("GuiObject") then
            local fired = false
            if type(firesignal) == "function" then
                fired = pcall(firesignal, button.MouseButton1Down)
                pcall(firesignal, button.MouseButton1Up)
            end
            if not fired and type(getconnections) == "function" then
                local ok = pcall(function()
                    for _, connection in ipairs(getconnections(button.MouseButton1Down)) do
                        connection:Fire()
                    end
                end)
                fired = fired or ok
            end
            if fired then
                return true
            end
        end

        pcall(function()
            local raw = localPlayer:GetAttribute("kb_skillcheck")
            if typeof(raw) ~= "string" or raw == "" then
                raw = "Space"
            end
            local mouseIndex = raw:match("^MouseButton(%d)$")
            if mouseIndex then
                local mouseButton = tonumber(mouseIndex) - 1
                VirtualInputManager:SendMouseButtonEvent(0, 0, mouseButton, true, game, 0)
                task.wait(0.005)
                VirtualInputManager:SendMouseButtonEvent(0, 0, mouseButton, false, game, 0)
                return
            end
            local okKey, keyCode = pcall(function()
                return Enum.KeyCode[raw]
            end)
            if not okKey or not keyCode then
                keyCode = Enum.KeyCode.Space
            end
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.005)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)

        return true
    end

    fn7 = function()
        if _G.MX.Connections.SkillHeartbeat then
            _G.MX.Connections.SkillHeartbeat:Disconnect()
            _G.MX.Connections.SkillHeartbeat = nil
        end

        _G.MX.Connections.SkillHeartbeat = MXTrack(RunService.Heartbeat:Connect(function()
            local forced = os.clock() < (_G.MX.State.ForceSkillUntil or 0)
            if not (_G.MX.Auto.SkillCheck or forced) or _G.MX.State.busy then
                return
            end

            local ownChar = localPlayer.Character
            if ownChar and ownChar:GetAttribute("Trapped") == true then
                return
            end
            local skillCheckPromptGui = playerGui:FindFirstChild("SkillCheckPromptGui")
            if not skillCheckPromptGui then
                return
            end
            local check = skillCheckPromptGui:FindFirstChild("Check")
            if check then
                local trapGoal = check:FindFirstChild("TrapGoal")
                local trapPerfect = check:FindFirstChild("TrapPerfect")
                if (trapGoal and trapGoal.Visible) or (trapPerfect and trapPerfect.Visible) then
                    return
                end
            end

            if check and check.Visible then
                local line = check:FindFirstChild("Line")
                local goal = check:FindFirstChild("Goal")
                if not line or not goal then
                    return
                end
                local mode = _G.MX.Auto.SkillCheckMode
                local useNormal = mode == "Normal" or (mode == "Random" and _G.MX.State.RandomMode_IsNormal)
                local lo, hi = 102, 116
                if useNormal then
                    lo, hi = 116, 140
                end
                local center = (lo + hi) / 2

                local now = os.clock()
                local rot = line.Rotation % 360
                local goalRot = goal.Rotation % 360
                local st = _G.MX.State.SkillTrack
                if not st or st.check ~= check or math.abs(st.goal - goalRot) > 0.5 then
                    st = {check = check, goal = goalRot, last = nil, lastT = now, vel = 277, dt = 1 / 60, fired = false}
                    _G.MX.State.SkillTrack = st
                end
                if st.last then
                    local dt = now - st.lastT
                    local dRot = (rot - st.last) % 360
                    if dt > 0.0005 and dRot < 180 then
                        st.vel = st.vel * 0.6 + (dRot / dt) * 0.4
                        st.dt = st.dt * 0.7 + math.min(dt, 0.2) * 0.3
                    end
                end
                st.last, st.lastT = rot, now

                if not st.fired then
                    local rel = (rot - goalRot) % 360
                    local remaining = (goalRot + center - rot) % 360
                    local lead = st.dt * 1.5 + 0.01
                    local inWindow = rel >= lo and rel <= hi
                    local missedGreat = mode == "Legit" and rel > hi and rel <= 150
                    if inWindow or missedGreat or (remaining <= st.vel * lead and remaining < 90 and rel < center) then
                        st.fired = true
                        _G.MX.State.busy = true
                        task.spawn(function()
                            fn24()
                            task.wait(0.08)
                            _G.MX.State.busy = false
                        end)
                    end
                end
                return
            end

            _G.MX.State.RandomMode_IsNormal = false
            _G.MX.State.SkillTrack = nil
        end))
    end

    getTargetPartObject = function(arg)
        if _G.MX.AimConfig.AIM_TargetPart == "Head" then
            return arg:FindFirstChild("Head")
        end

        if _G.MX.AimConfig.AIM_TargetPart == "Root" or _G.MX.AimConfig.AIM_TargetPart == "HumanoidRootPart" then
            return arg:FindFirstChild("HumanoidRootPart")
        end
        local torso = arg:FindFirstChild("Torso")
        local upperTorso = torso or arg:FindFirstChild("UpperTorso") or arg:FindFirstChild("HumanoidRootPart")
        return upperTorso
    end

    getClosestSurvivor = function()
        local character = localPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return nil
        end
        local cfg = _G.MX.AimConfig
        local maxDist = math.huge
        local currentCamera2 = workspace.CurrentCamera
        local center = Vector2.new(currentCamera2.ViewportSize.X / 2, currentCamera2.ViewportSize.Y / 2)

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        local bestVisible, bestVisibleMag = nil, math.huge
        local bestAny, bestAnyMag = nil, math.huge

        local sticky = _G.MX.VeilSticky
        local stickyPart

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
                local character2 = player.Character
                local humanoid = character2:FindFirstChildOfClass("Humanoid")
                local part = getTargetPartObject(character2)

                if part then
                    rayParams.FilterDescendantsInstances = {character, character2}
                    local from0 = humanoidRootPart.Position
                    local candidates = {part}
                    for _, partName in ipairs({"Head", "Torso", "HumanoidRootPart", "Left Leg", "Right Leg"}) do
                        local extra = character2:FindFirstChild(partName)
                        if extra then
                            candidates[#candidates + 1] = extra
                        end
                    end
                    for _, candidate in ipairs(candidates) do
                        local h0 = workspace:Raycast(from0, candidate.Position - from0, rayParams)
                        if not (h0 and h0.Instance.CanCollide and h0.Instance.Transparency < 0.05) then
                            part = candidate
                            break
                        end
                    end
                end

                if humanoid and humanoid.Health > 0 and part and not character2:GetAttribute("Knocked") and not character2:GetAttribute("IsHooked") and (part.Position - humanoidRootPart.Position).Magnitude <= maxDist then
                    local screen, onScreen = currentCamera2:WorldToViewportPoint(part.Position)
                    local mag
                    if onScreen then
                        mag = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                    else
                        mag = 100000 + (part.Position - humanoidRootPart.Position).Magnitude
                    end

                    do
                        do
                            if sticky and sticky.char == character2 and os.clock() - sticky.t < 2 then
                                stickyPart = part
                            end

                            rayParams.FilterDescendantsInstances = {character, character2}
                            local from = humanoidRootPart.Position
                            local hit = workspace:Raycast(from, part.Position - from, rayParams)
                            local blocked = hit ~= nil and hit.Instance.CanCollide and hit.Instance.Transparency < 0.05

                            if not blocked and mag < bestVisibleMag then
                                bestVisible, bestVisibleMag = part, mag
                            end
                            if mag < bestAnyMag then
                                bestAny, bestAnyMag = part, mag
                            end
                        end
                    end
                end
            end
        end

        local picked = stickyPart or bestVisible or bestAny
        if picked then
            local m = picked:FindFirstAncestorOfClass("Model")
            _G.MX.VeilSticky = {char = m, t = (stickyPart and sticky) and sticky.t or os.clock()}
            if stickyPart and sticky then

                _G.MX.VeilSticky.t = os.clock()
            end
        end
        return picked
    end

    getBestKillerAimbotTarget = function()
        local v7 = nil
        local huge = math.huge
        local character = localPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return nil
        end

        for i, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local humanoidRootPart2 = player.Character:FindFirstChild("HumanoidRootPart")

                if humanoid and humanoid.Health > 0 and humanoidRootPart2 and not IsDowned(player.Character) then
                    local magnitude = (humanoidRootPart2.Position - humanoidRootPart.Position).Magnitude

                    if magnitude < huge and magnitude <= _G.MX.Config.Killer_Aimbot_MaxDist then
                        huge = magnitude
                        v7 = humanoidRootPart2
                    end
                end
            end
        end

        return v7
    end

    getKillerTargetForFlash = function()
        local v7 = nil
        local huge = math.huge
        local character = localPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return nil
        end

        for i, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Team and player.Team.Name == "Killer" and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local humanoidRootPart2 = player.Character:FindFirstChild("HumanoidRootPart")

                if humanoid and humanoid.Health > 0 and humanoidRootPart2 and not IsDowned(player.Character) then
                    local magnitude = (humanoidRootPart2.Position - humanoidRootPart.Position).Magnitude

                    if magnitude < huge then
                        huge = magnitude
                        v7 = humanoidRootPart2
                    end
                end
            end
        end

        return v7
    end

    setupSpearInterceptor = function()
        if flag3 then
            return
        end

        if not getrawmetatable or not setreadonly then
            return
        end
        local spearthrow = nil

        pcall(function()
            spearthrow = ReplicatedStorage.Remotes.Killers.Veil.Spearthrow
        end)

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local fall = remotes and ReplicatedStorage.Remotes:FindFirstChild("Mechanics") and ReplicatedStorage.Remotes.Mechanics:FindFirstChild("Fall")

        local function fn29(speed, grav, dist, height)
            local d = math.max(dist, 0.1)
            local v2 = speed * speed
            local disc = v2 * v2 - grav * (grav * d * d + 2 * height * v2)
            local angle
            if disc < 0 then
                angle = math.pi / 4
            else
                angle = math.atan((v2 - math.sqrt(disc)) / (grav * d))
            end
            return angle, d / (speed * math.cos(angle))
        end

        local SPEAR_MAX_SPEED, SPEAR_GRAV = 165, 98.1
        local chargeStart = {}
        local chargeOrder = {}

        local function noteCharge(seq, t)
            _G.MX.SpearCharge = os.clock()
            if seq ~= nil and typeof(t) == "number" then
                chargeStart[seq] = t
                table.insert(chargeOrder, seq)
                if #chargeOrder > 12 then
                    chargeStart[table.remove(chargeOrder, 1)] = nil
                end
            end
        end

        local velSamples = setmetatable({}, {__mode = "k"})
        MXTrack(RunService.Heartbeat:Connect(function()
            if not _G.MX.AimConfig.Aim_SilentVeilV2 then
                return
            end
            local now = os.clock()
            for _, pl in ipairs(Players:GetPlayers()) do
                local c = pl.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if r and pl ~= localPlayer then
                    local sm = velSamples[c]
                    if not sm then
                        velSamples[c] = {pos = r.Position, t = now, age = now, vel = Vector3.new(0, 0, 0)}
                    else
                        local dt = now - sm.t
                        if dt >= 0.05 then
                            local raw = (r.Position - sm.pos) / dt
                            local old = sm.vel
                            sm.vel = Vector3.new(old.X + (raw.X - old.X) * 0.6, 0, old.Z + (raw.Z - old.Z) * 0.6)
                            sm.pos = r.Position
                            sm.t = now
                            sm.age = now
                        end
                    end
                end
            end
        end))

        local function veilAimPayload(payload)
            if typeof(payload) ~= "table" or typeof(payload.Direction) ~= "Vector3" or typeof(payload.Origin) ~= "Vector3" then
                return nil
            end
            local targetPart = getClosestSurvivor()
            if not targetPart then
                return nil
            end
            local model = targetPart:FindFirstAncestorOfClass("Model")
            if not model then
                return nil
            end
            local origin = payload.Origin
            local grav = SPEAR_GRAV

            local speed = SPEAR_MAX_SPEED
            local started = chargeStart[payload.Sequence]
            if payload.SpeedOverride then
                speed = payload.SpeedOverride
            elseif started and typeof(payload.ReleasedAt) == "number" then
                speed = math.clamp((payload.ReleasedAt - started) * SPEAR_MAX_SPEED, 1, SPEAR_MAX_SPEED)
            end

            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart") or targetPart
            local vel = root:IsA("BasePart") and root.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
            if Vector3.new(vel.X, 0, vel.Z).Magnitude < 0.5 and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                vel = humanoid.MoveDirection * humanoid.WalkSpeed
            end
            local airborne = humanoid ~= nil and humanoid.FloorMaterial == Enum.Material.Air
            local flatVel = Vector3.new(vel.X, 0, vel.Z)
            local sample = velSamples[model]
            if sample and sample.vel and sample.age and os.clock() - sample.age < 0.3 then
                flatVel = Vector3.new(sample.vel.X, 0, sample.vel.Z)
            end
            local vy = airborne and vel.Y or 0
            local worldG = workspace.Gravity
            local renderedAt = model:GetAttribute("VeilRenderedAt")
            local compensated = typeof(renderedAt) == "number" and renderedAt == renderedAt
            local pingLead = compensated and 0 or math.clamp(_G.MX.VeilPing or 0, 0, 0.12) * 0.5
            local function applyViewDelay(out)
                if compensated and typeof(out) == "table" then
                    out.ViewDelay = math.clamp(workspace:GetServerTimeNow() - renderedAt, 0, 0.25)
                end
                return out
            end

            local everyone = {}
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Character then
                    table.insert(everyone, pl.Character)
                end
            end

            local function solid(hit)
                local inst = hit.Instance
                if inst.Name == "Plant" then
                    return false
                end
                return inst.Transparency < 0.05 or CollectionService:HasTag(inst, "TrueInvis")
            end

            local bodyParts = {}
            for _, name in ipairs({"Head", "Torso", "UpperTorso", "LowerTorso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
                local bp = model:FindFirstChild(name)
                if bp and bp:IsA("BasePart") then
                    table.insert(bodyParts, bp)
                end
            end

            local function boxFraction(rayOrigin, delta, cf, size)
                local o = cf:PointToObjectSpace(rayOrigin)
                local d = cf:VectorToObjectSpace(delta)
                local t0, t1 = 0, 1
                for _, axis in ipairs({"X", "Y", "Z"}) do
                    local oa, da, h = o[axis], d[axis], size[axis] * 0.5
                    if math.abs(da) < 1e-8 then
                        if oa < -h or oa > h then
                            return nil
                        end
                    else
                        local a, b = (-h - oa) / da, (h - oa) / da
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

            local function arcClear(startPos, dirUnit, flightT)
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = everyone
                local prev = startPos
                local limit = math.min(flightT + 0.35, 4)
                local steps = math.max(10, math.ceil(limit / 0.04))
                local pad = Vector3.new(0.3, 0.3, 0.3)
                for i = 1, steps do
                    local t = limit * i / steps
                    local pt = startPos + dirUnit * speed * t + Vector3.new(0, -0.5 * grav * t * t, 0)
                    local seg = pt - prev
                    local shift = flatVel * (t + pingLead)
                    if airborne then
                        local tp = t + pingLead
                        shift = shift + Vector3.new(0, vy * tp - 0.5 * worldG * tp * tp, 0)
                    end
                    local bestF
                    for _, bp in ipairs(bodyParts) do
                        local f = boxFraction(prev, seg, bp.CFrame + shift, bp.Size + pad)
                        if f and (not bestF or f < bestF) then
                            bestF = f
                        end
                    end
                    local hit = workspace:Raycast(prev, seg, rp)
                    local guard = 0
                    while hit and not solid(hit) and guard < 8 do
                        local l2 = rp.FilterDescendantsInstances
                        table.insert(l2, hit.Instance)
                        rp.FilterDescendantsInstances = l2
                        hit = workspace:Raycast(prev, seg, rp)
                        guard += 1
                    end
                    if hit and solid(hit) then
                        local wallF = hit.Distance / math.max(seg.Magnitude, 1e-6)
                        return bestF ~= nil and bestF <= wallF
                    end
                    if bestF then
                        return true
                    end
                    prev = pt
                end
                return false
            end

            local function plan(partPos)
                local dir = payload.Direction
                local lowDir, lowFlight, highDir, highFlight, startPos
                for _ = 1, 3 do
                    startPos = origin + dir * 3
                    local d = partPos - startPos
                    local angle, flight = fn29(speed, grav, Vector3.new(d.X, 0, d.Z).Magnitude, d.Y)
                    if flatVel.Magnitude > 0.5 or airborne then
                        for _ = 1, 6 do
                            local t = math.min(flight, 4) + pingLead
                            local aim = partPos + flatVel * t
                            if airborne then
                                aim = aim + Vector3.new(0, vy * t - 0.5 * worldG * t * t, 0)
                            end
                            d = aim - startPos
                            angle, flight = fn29(speed, grav, Vector3.new(d.X, 0, d.Z).Magnitude, d.Y)
                        end
                    end
                    local flat = Vector3.new(d.X, 0, d.Z)
                    if flat.Magnitude > 0.001 then
                        dir = flat.Unit * math.cos(angle) + Vector3.new(0, math.sin(angle), 0)
                        lowDir, lowFlight = dir, flight
                        local v2 = speed * speed
                        local dist = flat.Magnitude
                        local disc = v2 * v2 - grav * (grav * dist * dist + 2 * d.Y * v2)
                        if disc >= 0 then
                            local ha = math.atan((v2 + math.sqrt(disc)) / (grav * dist))
                            highDir = flat.Unit * math.cos(ha) + Vector3.new(0, math.sin(ha), 0)
                            highFlight = dist / (speed * math.cos(ha))
                        else
                            highDir, highFlight = nil, nil
                        end
                    else
                        dir = d.Unit
                        lowDir, lowFlight = dir, flight
                    end
                end
                return lowDir, lowFlight, highDir, highFlight, startPos
            end

            local points = {targetPart.Position}
            for _, name in ipairs({"Head", "HumanoidRootPart", "Torso", "UpperTorso", "Right Leg", "Left Leg", "Right Arm", "Left Arm"}) do
                local part = model:FindFirstChild(name)
                if part and part:IsA("BasePart") and part ~= targetPart then
                    table.insert(points, part.Position)
                end
            end

            local chosen, fallbackLow
            for index, point in ipairs(points) do
                local lowDir, lowFlight, highDir, highFlight, startPos = plan(point)
                if lowDir then
                    if index == 1 then
                        fallbackLow = lowDir
                    end
                    if lowFlight <= 4.0 and arcClear(startPos, lowDir.Unit, lowFlight) then
                        chosen = lowDir
                        break
                    end
                    if highDir and highFlight <= 4.0 and arcClear(startPos, highDir.Unit, highFlight) then
                        chosen = highDir
                        break
                    end
                end
            end

            if not chosen then
                local flatTo = Vector3.new(root.Position.X - origin.X, 0, root.Position.Z - origin.Z)
                if flatTo.Magnitude > 0.5 then
                    local yaw = flatTo.Unit
                    local hdist = flatTo.Magnitude
                    for _, deg in ipairs({0, 2, 4, 6, 8, 10, 12, 15, 18, 22, 26, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75}) do
                        local rad = math.rad(deg)
                        local cand = yaw * math.cos(rad) + Vector3.new(0, math.sin(rad), 0)
                        local flight = hdist / math.max(speed * math.cos(rad), 1)
                        if flight <= 4 and arcClear(origin + cand * 3, cand, flight) then
                            chosen = cand
                            break
                        end
                    end
                end
            end

            local dir = chosen or fallbackLow or payload.Direction
            local outOrigin = origin

            if (not chosen or (root.Position - origin).Magnitude > 60) and _G.MX.AimConfig.Veil_Direct then
                local bodyPos = (model:FindFirstChild("HumanoidRootPart") or targetPart).Position
                local ownRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                local toMe = ownRoot and Vector3.new(ownRoot.Position.X - bodyPos.X, 0, ownRoot.Position.Z - bodyPos.Z) or Vector3.new(0, 0, 1)
                toMe = toMe.Magnitude > 0.01 and toMe.Unit or Vector3.new(0, 0, 1)
                local side = Vector3.new(-toMe.Z, 0, toMe.X)
                local approaches = {
                    toMe * 4, side * 4, -side * 4, -toMe * 4,
                    toMe * 4 + Vector3.new(0, 3, 0), Vector3.new(0, 5, 0),
                    toMe * 7, side * 7, -side * 7, -toMe * 7,
                    Vector3.new(0, 9, 0), toMe * 3 + Vector3.new(0, 6, 0),
                }
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = {localPlayer.Character, model}
                for _, off in ipairs(approaches) do
                    local startPos = bodyPos + off
                    local hit = workspace:Raycast(startPos, bodyPos - startPos, rp)
                    local free = (not hit) or (not hit.Instance.CanCollide)
                    if free and not workspace:Raycast(bodyPos, off, rp) then
                        local aimDir = (bodyPos - startPos).Unit
                        local out = {}
                        for k, v in pairs(payload) do
                            out[k] = v
                        end
                        out.Direction = aimDir
                        out.Origin = startPos
                        return applyViewDelay(out)
                    end
                end
            end

            if not chosen then
                local position = targetPart.Position
                local function blocked(a, b)
                    local rp = RaycastParams.new()
                    rp.FilterType = Enum.RaycastFilterType.Exclude
                    local list = {localPlayer.Character, model}
                    for _ = 1, 8 do
                        rp.FilterDescendantsInstances = list
                        local hit = workspace:Raycast(a, b - a, rp)
                        if not hit then
                            return false
                        end
                        if solid(hit) then
                            return true
                        end
                        table.insert(list, hit.Instance)
                    end
                    return false
                end
                if blocked(origin, position) then
                    local ownRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local toMe = ownRoot and Vector3.new(ownRoot.Position.X - position.X, 0, ownRoot.Position.Z - position.Z) or Vector3.new(0, 0, 1)
                    toMe = toMe.Magnitude > 0.01 and toMe.Unit or Vector3.new(0, 0, 1)
                    local side = Vector3.new(-toMe.Z, 0, toMe.X)
                    local candidates = {
                        Vector3.new(0, 1, 0),
                        toMe * 0.9 + Vector3.new(0, 0.45, 0),
                        side * 0.9 + Vector3.new(0, 0.45, 0),
                        -side * 0.9 + Vector3.new(0, 0.45, 0),
                        -toMe * 0.9 + Vector3.new(0, 0.45, 0),
                    }
                    for _, c in ipairs(candidates) do
                        local point = position + c.Unit * 7
                        if not blocked(point, position) then
                            dir = (position - point).Unit
                            outOrigin = point - dir * 3
                            break
                        end
                    end
                end
            end

            local out = {}
            for k, v in pairs(payload) do
                out[k] = v
            end
            out.Direction = dir.Unit
            out.Origin = outOrigin
            return applyViewDelay(out)
        end

        _G.MX.PickSurvivor = function()
            local picked = getClosestSurvivor()
            return picked and picked:FindFirstAncestorOfClass("Model") or nil
        end

        _G.MX.SpearAim = function(origin, dir, speed)
            local ok, out = pcall(veilAimPayload, {Direction = dir, Origin = origin, SpeedOverride = speed})
            if ok and out then
                return out.Direction, out.Origin
            end
            return nil
        end

        _G.MX.VeilPing = 0
        local pingAlive = true
        task.spawn(function()
            while pingAlive do
                pcall(function()
                    _G.MX.VeilPing = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
                end)
                task.wait(1)
            end
        end)
        pcall(function()
            lib.API.Track(function()
                pingAlive = false
            end)
        end)

        local lastVeilReport = 0
        local function reportVeil(message)
            if os.clock() - lastVeilReport > 1 then
                lastVeilReport = os.clock()
                warn("[MXHUB] Silent Veil: " .. message)
            end
        end

        local v7 = getrawmetatable(game)
        setreadonly(v7, false)
        local hubEnv = getgenv()
        local namecall = hubEnv.MXHUB_BaseNamecall
        if type(namecall) ~= "function" then
            namecall = v7.__namecall
            hubEnv.MXHUB_BaseNamecall = namecall
        end

        local ownHook
        ownHook = newcclosure(function(arg, ...)
            local v8 = getnamecallmethod()
            local flag9 = v8 == "FireServer" or v8 == "fireServer" or v8 == "InvokeServer"

            if flag9 and not checkcaller() and typeof(arg) == "Instance" then
                local ka = _G.MX.KAim
                if ka and ka.flaskOn and ka.flaskRemote and arg == ka.flaskRemote and v8 == "FireServer" then
                    local ok, d1 = pcall(ka.flask, ...)
                    if ok and d1 then
                        local rest = table.pack(select(2, ...))
                        setnamecallmethod(v8)
                        return namecall(arg, d1, table.unpack(rest, 1, rest.n))
                    end
                end

                if ka and ka.chainOn and v8 == "FireServer" and arg.ClassName == "RemoteEvent" and arg.Name == "ChainThrow" and typeof((...)) == "Vector3" then
                    local okChain, newDir, chainTarget = pcall(ka.chain, (...))
                    if okChain and newDir then
                        local rest = table.pack(select(2, ...))
                        pcall(function()
                            local info = rest[2]
                            local renderedAt = chainTarget and chainTarget:GetAttribute("VeilRenderedAt")
                            if typeof(info) == "table" and typeof(renderedAt) == "number" and renderedAt == renderedAt then
                                local copy = {}
                                for k, v in pairs(info) do
                                    copy[k] = v
                                end
                                copy.ViewDelay = math.clamp(workspace:GetServerTimeNow() - renderedAt, 0, 0.25)
                                rest[2] = copy
                            end
                        end)
                        setnamecallmethod(v8)
                        return namecall(arg, newDir, table.unpack(rest, 1, rest.n))
                    end
                end

                if _G.MX.NoFall.Enabled and fall and arg == fall then
                    local tbl7 = {...}
                    tbl7[1] = 0
                    setnamecallmethod(v8)
                    return namecall(arg, unpack(tbl7))
                end

                if _G.MX.AntiBlindEnabled and _G.MX.GotBlindedRemote and arg == _G.MX.GotBlindedRemote and localPlayer.Team and localPlayer.Team.Name == "Killer" then
                    return nil
                end

                local tof = _G.MX.ToF
                if tof and v8 == "FireServer" and arg == tof.remote then
                    local ok, a1, a2, a3 = pcall(tof.onFire, ...)
                    if ok then
                        if a1 == false then
                            return nil
                        elseif a1 then
                            setnamecallmethod(v8)
                            return namecall(arg, a1, a2, a3)
                        end
                    end
                end

                if arg.Name == "SpearState" and v8 == "FireServer" then
                    local st, seq, tm = ...
                    if st == "charge" then
                        pcall(noteCharge, seq, tm)
                    else
                        _G.MX.SpearCharge = nil
                    end
                end

                if arg.ClassName == "RemoteEvent" and arg.Name == "Spearthrow" and typeof((...)) == "table" then
                    _G.MX.SpearCharge = nil
                    local payload = (...)
                    if _G.MX.AimConfig.Aim_SilentVeilV2 then
                        local okAim, newPayload = pcall(veilAimPayload, payload)
                        if okAim and newPayload and typeof(newPayload) == "table" and typeof(newPayload.Direction) == "Vector3" then
                            local okAng, ang = pcall(function()
                                return math.deg(math.acos(math.clamp(payload.Direction.Unit:Dot(newPayload.Direction.Unit), -1, 1)))
                            end)
                            local moved = (newPayload.Origin - payload.Origin).Magnitude > 0.01
                            if okAng and (moved or ang <= 85) then
                                pcall(reportVeil, string.format("arah diubah %.1f derajat, geser %d stud, titik awal %s", ang, math.floor((newPayload.Origin - payload.Origin).Magnitude + 0.5), moved and "dipindah" or "asli"))
                                payload = newPayload
                            else
                                pcall(reportVeil, "sudut terlalu besar, lemparan asli dipakai")
                            end
                        elseif okAim then
                            pcall(reportVeil, "tidak ada target survivor")
                        else
                            pcall(reportVeil, "error: " .. tostring(newPayload))
                        end
                    end
                    local tracker = _G.MX.Tracker
                    if tracker and tracker.spearOn then
                        pcall(function()
                            local speedNow = SPEAR_MAX_SPEED
                            local started = chargeStart[payload.Sequence]
                            if started and typeof(payload.ReleasedAt) == "number" then
                                speedNow = math.clamp((payload.ReleasedAt - started) * SPEAR_MAX_SPEED, 1, SPEAR_MAX_SPEED)
                            end
                            tracker.spear(payload.Origin, payload.Direction, speedNow)
                        end)
                    end
                    if payload ~= (...) then
                        setnamecallmethod(v8)
                        return namecall(arg, payload)
                    end
                end

                if arg.ClassName == "RemoteEvent" and arg.Name == "Spearthrow" and _G.MX.AimConfig.Aim_SilentVeilV2 and not flag2 and typeof((...)) ~= "table" then
                    local character = localPlayer.Character
                    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                    local v9 = character

                    if character then
                        local head = character:FindFirstChild("Head")
                        v9 = head or humanoidRootPart
                    end

                    local flag10 = character and character:GetAttribute("special") == true
                    local v10, v11

                    if flag10 then
                        local spearAuraSpeed = _G.MX.AimConfig.SPEAR_AuraSpeed
                        local n4 = spearAuraSpeed or 165
                        v10 = n4
                        local spearAuraGravity = _G.MX.AimConfig.SPEAR_AuraGravity
                        local n5 = spearAuraGravity or 96.5
                        v11 = n5
                    else
                        local spearSpeed = _G.MX.AimConfig.SPEAR_Speed
                        local n4 = spearSpeed or 165
                        v10 = n4
                        local spearGravity = _G.MX.AimConfig.SPEAR_Gravity
                        local n5 = spearGravity or 103
                        v11 = n5
                    end

                    local v12 = v10
                    local value = (select(3, ...))

                    if not (select(3, ...)) then
                        local spearSmartEnable = _G.MX.Config.SpearSmart_enable
                        value = spearSmartEnable and humanoidRootPart and humanoidRootPart.Position
                    end

                    if not value then
                        value = v9 and v9.Position
                    end

                    local v13 = value
                    local n4 = (...)
                    local v14 = getClosestSurvivor()

                    if v14 and v13 then
                        local isModel = v14:IsA("Model")
                        local humanoidRootPart2 = isModel and v14:FindFirstChild("HumanoidRootPart") or v14
                        local position = humanoidRootPart2.Position
                        local vector = Vector3.new(0, 0, 0)
                        local parent = v14.Parent
                        local humanoid = parent and v14.Parent:FindFirstChildOfClass("Humanoid")

                        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
                            vector = humanoid.MoveDirection * humanoid.WalkSpeed
                        elseif humanoidRootPart2:IsA("BasePart") then
                            vector = humanoidRootPart2.AssemblyLinearVelocity
                        end

                        local vector2 = Vector3.new(vector.X, 0, vector.Z)
                        local n5 = position - v13
                        local magnitude = n5.Magnitude
                        local magnitude2 = Vector3.new(n5.X, 0, n5.Z).Magnitude
                        local y = n5.Y

                        if magnitude > 0.1 then
                            local spearMaxDist = _G.MX.AimConfig.SPEAR_MaxDist
                            local n6 = spearMaxDist or 1000

                            if magnitude <= n6 then
                                local lead = _G.MX.AimConfig.Veil_LeadMultiplier or 1
                                local aim = position
                                local angle, flight = fn29(v10, v11, magnitude2, y)

                                if _G.MX.Config.SpearSmart_enable and vector2.Magnitude > 0.5 then
                                    for _ = 1, 4 do
                                        aim = position + vector2 * (math.min(flight, 4) * lead)
                                        local d = aim - v13
                                        angle, flight = fn29(v10, v11, Vector3.new(d.X, 0, d.Z).Magnitude, d.Y)
                                    end
                                end

                                local d = aim - v13
                                local flat = Vector3.new(d.X, 0, d.Z)

                                if flat.Magnitude > 0.001 then
                                    n4 = flat.Unit * math.cos(angle) + Vector3.new(0, math.sin(angle), 0)
                                else
                                    n4 = d.Unit
                                end
                            end
                        end
                    end

                    flag2 = true

                    pcall(function()
                        if spearthrow then
                            spearthrow:FireServer(n4, v12, v13)
                        else
                            arg:FireServer(n4, v12, v13)
                        end
                    end)

                    flag2 = false
                    return
                end
            end

            setnamecallmethod(v8)
            return namecall(arg, ...)
        end)

        v7.__namecall = ownHook
        pcall(function()
            lib.API.Track(function()
                pcall(function()
                    setreadonly(v7, false)
                    if v7.__namecall == ownHook then
                        v7.__namecall = namecall
                    end
                    setreadonly(v7, true)
                end)
            end)
        end)

        setreadonly(v7, true)
        flag3 = true
    end

    local function fn29()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local items = remotes and ReplicatedStorage.Remotes:FindFirstChild("Items")
        local flashlight = items and items:FindFirstChild("Flashlight")

        if flashlight then
            _G.MX.GotBlindedRemote = flashlight:FindFirstChild("GotBlinded")
        end
    end

    task.spawn(function()
        task.wait(1)
        fn29()
        setupSpearInterceptor()
    end)

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        fn29()
    end))
end

local tbl5, setNoFall, setNextKillerDisplay, setMapPrediction, setKillerPerksDisplay, setStunIndicator

do
    tbl5 = {}

    EnableInfiniteLunge = function()
        _G.MX.InfiniteLungeEnabled = true
        local character = localPlayer.Character

        if character then
            character:SetAttribute("lungeboost", 999)

            if _G.MX.InfLungeAttrConn then
                _G.MX.InfLungeAttrConn:Disconnect()
            end

            _G.MX.InfLungeAttrConn = MXTrack(character:GetAttributeChangedSignal("lungeboost"):Connect(function()
                if _G.MX.InfiniteLungeEnabled and character:GetAttribute("lungeboost") ~= 999 then
                    character:SetAttribute("lungeboost", 999)
                end
            end))
        end

    end

    DisableInfiniteLunge = function()
        _G.MX.InfiniteLungeEnabled = false

        if _G.MX.InfLungeAttrConn then
            _G.MX.InfLungeAttrConn:Disconnect()
            _G.MX.InfLungeAttrConn = nil
        end

        local character = localPlayer.Character

        if character then
            character:SetAttribute("lungeboost", 1)
        end

    end

    MXTrack(localPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.8)

        if _G.MX.InfiniteLungeEnabled and character then
            character:SetAttribute("lungeboost", 999)
        end
    end))

    StopCounterParry = function()
        _G.MX.CounterParry.Enabled = false

        if _G.MX.CounterParry.Thread then
            task.cancel(_G.MX.CounterParry.Thread)
            _G.MX.CounterParry.Thread = nil
        end

        if _G.MX.CounterParry.Track then
            pcall(function()
                _G.MX.CounterParry.Track:Stop()
            end)

            _G.MX.CounterParry.Track = nil
        end
    end

    StartCounterParry = function()
        if _G.MX.CounterParry.Thread then
            return
        end

        _G.MX.CounterParry.Thread = task.spawn(function()
            local character, humanoid, animator, humanoidRootPart, animation, ok, track, flag3, distance, v4, v5, v6, v7, v8, v9, character2, humanoidRootPart2, n
            n = 1

            while true do
                if n == 1 then
                    if _G.MX.CounterParry.Enabled and _G.MX.ScriptAlive then
                        n = 3
                    else
                        n = 2
                    end
                elseif n == 2 then
                    _G.MX.CounterParry.Thread = nil
                    return
                elseif n == 3 then
                    character = localPlayer.Character

                    if character and character.Parent and GetRole() == "Killer" then
                        n = 5
                    else
                        n = 4
                    end
                elseif n == 4 then
                    task.wait(0.4)
                    n = 1
                elseif n == 5 then
                    humanoid = character:FindFirstChildOfClass("Humanoid")
                    animator = humanoid

                    if humanoid then
                        n = 6
                    else
                        n = 7
                    end
                elseif n == 6 then
                    animator = humanoid:FindFirstChildOfClass("Animator")
                    n = 7
                elseif n == 7 then
                    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

                    if animator and humanoidRootPart then
                        n = 9
                    else
                        n = 8
                    end
                elseif n == 8 then
                    task.wait(0.3)
                    n = 1
                elseif n == 9 then
                    if _G.MX.CounterParry.Track and _G.MX.CounterParry.Track.Parent ~= nil then
                        n = 13
                    else
                        n = 10
                    end
                elseif n == 10 then
                    animation = Instance.new("Animation")
                    animation.AnimationId = _G.MX.CounterParry.AnimId

                    ok, track = pcall(function()
                        return animator:LoadAnimation(animation)
                    end)

                    if ok and track then
                        n = 12
                    else
                        n = 11
                    end
                elseif n == 11 then
                    task.wait(0.5)
                    n = 1
                elseif n == 12 then
                    _G.MX.CounterParry.Track = track
                    n = 13
                elseif n == 13 then
                    flag3 = false
                    distance = _G.MX.CounterParry.Distance
                    v4, v5, v6 = ipairs(Players:GetPlayers())
                    v7 = v6
                    n = 14
                elseif n == 14 then
                    v8, v9 = v4(v5, v7)

                    if v8 == nil then
                        n = 20
                    else
                        n = 15
                    end
                elseif n == 15 then
                    v7 = v8

                    if v9 ~= localPlayer and v9.Team and v9.Team.Name == "Survivors" then
                        n = 16
                    else
                        n = 14
                    end
                elseif n == 16 then
                    character2 = v9.Character
                    humanoidRootPart2 = character2

                    if character2 then
                        n = 17
                    else
                        n = 18
                    end
                elseif n == 17 then
                    humanoidRootPart2 = v9.Character:FindFirstChild("HumanoidRootPart")
                    n = 18
                elseif n == 18 then
                    if humanoidRootPart2 and (humanoidRootPart.Position - humanoidRootPart2.Position).Magnitude <= distance then
                        n = 19
                    else
                        n = 14
                    end
                elseif n == 19 then
                    flag3 = true
                    n = 20
                elseif n == 20 then
                    if flag3 and _G.MX.CounterParry.Track then
                        n = 21
                    else
                        n = 22
                    end
                elseif n == 21 then
                    pcall(function()
                        _G.MX.CounterParry.Track:Play()
                        _G.MX.CounterParry.Track:AdjustWeight(0)
                    end)

                    task.wait(0.05)

                    pcall(function()
                        _G.MX.CounterParry.Track:Stop()
                    end)

                    n = 22
                elseif n == 22 then
                    task.wait(_G.MX.CounterParry.Interval)
                    n = 1
                end
            end
        end)
    end

    ToggleCounterParry = function(arg)
        if arg then
            if GetRole() ~= "Killer" then

                _G.MX.CounterParry.Enabled = false

                if CounterParryToggle then
                    fn(CounterParryToggle, false)
                end

                return
            end

            _G.MX.CounterParry.Enabled = true
            StartCounterParry()

        else
            StopCounterParry()

        end
    end

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        _G.MX.CounterParry.Track = nil
        task.wait(1)

        if _G.MX.CounterParry.Enabled then
            StartCounterParry()
        end
    end))

    _G.MX.killerAimbotHighlight = Instance.new("Highlight")
    _G.MX.killerAimbotHighlight.Name = "KillerAimbotTarget"
    _G.MX.killerAimbotHighlight.FillColor = Color3.fromRGB(255, 0, 0)
    _G.MX.killerAimbotHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    _G.MX.killerAimbotHighlight.FillTransparency = 0.4
    _G.MX.killerAimbotHighlight.OutlineTransparency = 0.2

    StopMoonwalk = function()
        _G.MX.Moonwalk.Enabled = false
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.AutoRotate = true
        end
    end

    StartMoonwalk = function()
        local character = localPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoidRootPart or not humanoid then
            return
        end
        humanoid.AutoRotate = false
        _G.MX.Moonwalk.Enabled = true
    end

    UpdateMoonwalkGUI = function(arg)
        if not _G.MX.Moonwalk.Gui then
            return
        end
        local frame2 = _G.MX.Moonwalk.Gui:FindFirstChild("Frame")
        if not frame2 then
            return
        end
        local actionButton = frame2:FindFirstChild("ActionButton")
        local uiStroke3 = frame2:FindFirstChild("UIStroke")

        if arg then
            if actionButton then
                actionButton.Text = "MOON [ON]"
                actionButton.TextColor3 = Color3.fromRGB(180, 255, 180)
                actionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            end

            if uiStroke3 then
                uiStroke3.Color = Color3.fromRGB(100, 200, 100)
            end
        else
            if actionButton then
                actionButton.Text = "MOON [OFF]"
                actionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                actionButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            end

            if uiStroke3 then
                uiStroke3.Color = Color3.fromRGB(90, 90, 95)
            end
        end
    end

    ToggleMoonwalkStatus = function()
        if _G.MX.Moonwalk.Enabled then
            StopMoonwalk()
        else
            StartMoonwalk()
        end

        _G.MX.Moonwalk.IsActive = _G.MX.Moonwalk.Enabled
        UpdateMoonwalkGUI(_G.MX.Moonwalk.Enabled)

        if MoonwalkPCToggle then
            fn(MoonwalkPCToggle, _G.MX.Moonwalk.Enabled)
        end

    end

    CreateMoonwalkGUI = function()
        if _G.MX.Moonwalk.Gui then
            _G.MX.Moonwalk.Gui:Destroy()
        end

        local screenGui2 = Instance.new("ScreenGui")
        screenGui2.Name = "MoonwalkCustomGui"
        screenGui2.ResetOnSpawn = false
        screenGui2.IgnoreGuiInset = true
        screenGui2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui2.Parent = CoreGui
        screenGui2.Enabled = false
        _G.MX.Moonwalk.Gui = screenGui2
        _G.MX.Moonwalk.GuiVisible = false
        local frame2 = Instance.new("Frame", screenGui2)
        frame2.Name = "Frame"
        frame2.Size = UDim2.fromOffset(110, 36)
        frame2.Position = UDim2.fromScale(0.85, 0.45)
        frame2.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        frame2.BackgroundTransparency = 0.1
        frame2.Active = true
        frame2.BorderSizePixel = 0
        Instance.new("UICorner", frame2).CornerRadius = UDim.new(0, 8)
        local uiStroke3 = Instance.new("UIStroke", frame2)
        uiStroke3.Name = "UIStroke"
        uiStroke3.Color = Color3.fromRGB(90, 90, 95)
        uiStroke3.Thickness = 1.5
        uiStroke3.Transparency = 0.2
        local textButton = Instance.new("TextButton", frame2)
        textButton.Name = "ActionButton"
        textButton.Size = UDim2.new(1, 0, 1, 0)
        textButton.Text = "MOON [OFF]"
        textButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        textButton.Font = Enum.Font.GothamBold
        textButton.TextSize = 12
        textButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        textButton.BorderSizePixel = 0
        textButton.AutoButtonColor = false
        Instance.new("UICorner", textButton).CornerRadius = UDim.new(0, 8)
        local flag3 = false
        local flag4 = false
        local flag5 = false
        local position = nil
        local position2 = nil
        local thread = nil

        local function fn29(arg)
            if not flag3 or not flag5 or not position or not position2 then
                return
            end
            local n = arg.Position - position

            if not flag4 and (math.abs(n.X) > 18 or math.abs(n.Y) > 18) then
                flag4 = true
            end

            if flag4 then
                frame2.Position = UDim2.new(position2.X.Scale, position2.X.Offset + n.X, position2.Y.Scale, position2.Y.Offset + n.Y)
            end
        end

        MXTrack(textButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                flag3 = true
                flag4 = false
                flag5 = false
                position = input.Position
                position2 = frame2.Position

                if thread then
                    task.cancel(thread)
                end

                thread = task.delay(0.18, function()
                    if flag3 then
                        flag5 = true
                    end
                end)
            end
        end))

        MXTrack(textButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if thread then
                    task.cancel(thread)
                end

                if flag3 and not flag4 then
                    ToggleMoonwalkStatus()
                end

                flag3 = false
                flag4 = false
                flag5 = false
                position = nil
                position2 = nil
            end
        end))

        MXTrack(UserInputService.InputChanged:Connect(function(input)
            if flag3 and flag5 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                fn29(input)
            end
        end))

        if _G.MX.Moonwalk._statusConn then
            _G.MX.Moonwalk._statusConn:Disconnect()
        end

        _G.MX.Moonwalk._statusConn = MXTrack(RunService.Heartbeat:Connect(function()
            if _G.MX.Moonwalk.Gui and _G.MX.Moonwalk.Gui.Parent then
                if _G.MX.Moonwalk.IsActive ~= _G.MX.Moonwalk.Enabled then
                    _G.MX.Moonwalk.IsActive = _G.MX.Moonwalk.Enabled
                    UpdateMoonwalkGUI(_G.MX.Moonwalk.Enabled)
                end

                return
            end

            if _G.MX.Moonwalk._statusConn then
                _G.MX.Moonwalk._statusConn:Disconnect()
            end
        end))
    end

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        task.wait(1)

        if _G.MX.Moonwalk.Enabled then
            StartMoonwalk()
        end

        if _G.MX.Moonwalk.GuiVisible and _G.MX.Moonwalk.Gui then
            _G.MX.Moonwalk.Gui.Enabled = true
            UpdateMoonwalkGUI(_G.MX.Moonwalk.Enabled)
        end
    end))

    task.spawn(function()
        task.wait(1.5)
        CreateMoonwalkGUI()
    end)

    MXTrack(RunService.RenderStepped:Connect(function(deltaTime)
        if not _G.MX.Speed.Enabled and not _G.MX.Moonwalk.Enabled and not _G.MX.Crosshair.Enabled and not _G.MX.StretchRes.Enabled and (not _G.MX.Config.Killer_Aimbot_Enabled or not _G.MX.isKillerAimbotHolding) and not _G.MX.AimConfig.Aim_SilentVeilV2 and (not _G.MX.PistolHold or not _G.MX.AimConfig.Flash_Silent) then
            return
        end

        if _G.MX.Crosshair.Enabled then
            DrawCrosshair()
        end

        if _G.MX.Speed.Enabled then
            local character = localPlayer.Character

            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                if humanoid then
                    local moveDirection = humanoid.MoveDirection

                    if moveDirection.Magnitude > 0 then
                        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

                        if humanoidRootPart then
                            local n = (_G.MX.Speed.Value - 0.1) * 10

                            if n > 0 then
                                humanoidRootPart.CFrame = humanoidRootPart.CFrame + moveDirection * n * deltaTime
                            end
                        end
                    end
                end
            end
        end

        if _G.MX.Moonwalk.Enabled then
            local character = localPlayer.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local currentCamera2 = workspace.CurrentCamera

            if humanoidRootPart and humanoid and currentCamera2 then
                if humanoid.AutoRotate ~= false then
                    humanoid.AutoRotate = false
                end

                local vector = Vector3.new(currentCamera2.CFrame.LookVector.X, 0, currentCamera2.CFrame.LookVector.Z)
                local unit = vector
                local vector2 = Vector3.new(currentCamera2.CFrame.RightVector.X, 0, currentCamera2.CFrame.RightVector.Z)
                local unit2 = vector2

                if vector.Magnitude > 0.001 then
                    unit = vector.Unit
                end

                if vector2.Magnitude > 0.001 then
                    unit2 = vector2.Unit
                end

                local v5 = math.sin(tick() * 35)
                local n = CFrame.Angles(0, math.rad(30 * v5), 0) * unit
                humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + n)
                humanoid:Move(-unit * 1.2 + unit2 * (v5 * 1.05), false)
            end
        end

        if _G.MX.StretchRes.Enabled and currentCamera then
            currentCamera.CFrame = currentCamera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, _G.MX.StretchRes.Amount, 0, 0, 0, 1)
        end

        if _G.MX.PistolHold and _G.MX.AimConfig.Flash_Silent then
            local v5 = getKillerTargetForFlash()

            if v5 then
                local character = localPlayer.Character
                local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                local n = v5.Position + Vector3.new(0, _G.MX.AimConfig.Flash_YOffset, 0)
                local currentCamera2 = workspace.CurrentCamera
                currentCamera2.CFrame = currentCamera2.CFrame:Lerp(CFrame.lookAt(currentCamera2.CFrame.Position, n), 0.5)

                if humanoidRootPart then
                    local cframe = CFrame.lookAt(humanoidRootPart.Position, Vector3.new(n.X, humanoidRootPart.Position.Y, n.Z))
                    humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(cframe, 0.5)
                end
            end
        end

        if _G.MX.Config.Killer_Aimbot_Enabled and _G.MX.isKillerAimbotHolding then
            if GetRole() == "Killer" then
                if _G.MX.lockedKillerAimbotTarget then
                    local parent = _G.MX.lockedKillerAimbotTarget.Parent
                    local humanoid = parent and parent:FindFirstChild("Humanoid")

                    if not humanoid or humanoid.Health <= 0 or IsDowned(parent) then
                        _G.MX.lockedKillerAimbotTarget = getBestKillerAimbotTarget()
                    end

                    if _G.MX.lockedKillerAimbotTarget then
                        local position = _G.MX.lockedKillerAimbotTarget.Position
                        local v5 = GetDistance(position)

                        if _G.MX.Config.Killer_Aimbot_MaxDist < v5 then
                            _G.MX.lockedKillerAimbotTarget = getBestKillerAimbotTarget()
                        else
                            _G.MX.killerAimbotHighlight.Parent = parent

                            local alpha = _G.MX.Config.Killer_Aimbot_BestSmooth and (1 - math.exp(-deltaTime * 14)) or 1
                            local cframe = CFrame.new(currentCamera.CFrame.Position, position)
                            currentCamera.CFrame = currentCamera.CFrame:Lerp(cframe, alpha)
                            local character = localPlayer.Character
                            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

                            if humanoidRootPart then
                                local cframe2 = CFrame.new(humanoidRootPart.Position, Vector3.new(position.X, humanoidRootPart.Position.Y, position.Z))

                                local current = humanoidRootPart.CFrame
                                local turned = current:Lerp(cframe2, alpha)
                                humanoidRootPart.CFrame = CFrame.new(current.Position) * (turned - turned.Position)
                            end
                        end
                    end
                else
                    _G.MX.lockedKillerAimbotTarget = getBestKillerAimbotTarget()
                end
            end
        elseif _G.MX.killerAimbotHighlight then
            _G.MX.killerAimbotHighlight.Parent = nil
        end

    end))

    local n = 0

    MXTrack(RunService.Heartbeat:Connect(function()
        if _G.MX.ParryConfig.ParryCircle and _G.MX.ParryConfig.AutoParry then
            local character = localPlayer.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

            if humanoidRootPart then
                local ring = _G.MX.State.AutoParryAdornment
                if not ring or ring.Parent ~= humanoidRootPart then
                    if ring then ring:Destroy() end
                    if _G.MX.State.AutoParryGlow then _G.MX.State.AutoParryGlow:Destroy() end
                    ring = Instance.new("CylinderHandleAdornment")
                    ring.Name = "AutoParryCircleESP"
                    ring.Height = 0.04
                    ring.Transparency = 0.25
                    ring.Adornee = humanoidRootPart
                    ring.ZIndex = 2
                    ring.AlwaysOnTop = false
                    ring.Parent = humanoidRootPart
                    local glow = Instance.new("CylinderHandleAdornment")
                    glow.Name = "AutoParryCircleGlow"
                    glow.Height = 0.02
                    glow.Adornee = humanoidRootPart
                    glow.ZIndex = 1
                    glow.AlwaysOnTop = false
                    glow.Parent = humanoidRootPart
                    local fill = Instance.new("CylinderHandleAdornment")
                    fill.Name = "AutoParryCircleFill"
                    fill.Height = 0.01
                    fill.Adornee = humanoidRootPart
                    fill.ZIndex = 0
                    fill.AlwaysOnTop = false
                    fill.Parent = humanoidRootPart
                    _G.MX.State.AutoParryAdornment = ring
                    _G.MX.State.AutoParryGlow = glow
                    _G.MX.State.AutoParryFill = fill
                    _G.MX.State.AutoParryColor = Color3.fromRGB(255, 255, 255)
                end
                local glow, fill = _G.MX.State.AutoParryGlow, _G.MX.State.AutoParryFill

                local parryRadius = _G.MX.ParryConfig.ParryRadius
                local now = os.clock()
                local pulse = 0.5 + 0.5 * math.sin(now * 2.2)
                local target
                if _G.MX.State.ParryCooldown then
                    target = Color3.fromRGB(255, 150, 40)
                elseif _G.MX.ParryConfig.ParryAggressive then
                    target = Color3.fromRGB(255, 70, 90)
                else
                    target = Color3.fromRGB(120, 200, 255)
                end
                local col = _G.MX.State.AutoParryColor:Lerp(target, 0.12)
                _G.MX.State.AutoParryColor = col
                local base = CFrame.new(0, -3, 0) * CFrame.Angles(math.rad(90), 0, 0)
                ring.Radius = parryRadius
                ring.InnerRadius = math.max(0.1, parryRadius - 0.22)
                ring.CFrame = base
                ring.Color3 = col
                ring.Transparency = 0.18 + 0.12 * pulse
                glow.Radius = parryRadius + 0.55
                glow.InnerRadius = math.max(0.1, parryRadius - 0.55)
                glow.CFrame = base
                glow.Color3 = col
                glow.Transparency = 0.82 - 0.1 * pulse
                fill.Radius = parryRadius
                fill.InnerRadius = 0
                fill.CFrame = base
                fill.Color3 = col
                fill.Transparency = 0.94
            elseif _G.MX.State.AutoParryAdornment then
                for _, k in ipairs({"AutoParryAdornment", "AutoParryGlow", "AutoParryFill"}) do
                    if _G.MX.State[k] then _G.MX.State[k]:Destroy() _G.MX.State[k] = nil end
                end
            end
        elseif _G.MX.State.AutoParryAdornment then
            for _, k in ipairs({"AutoParryAdornment", "AutoParryGlow", "AutoParryFill"}) do
                if _G.MX.State[k] then _G.MX.State[k]:Destroy() _G.MX.State[k] = nil end
            end
        end

        if _G.MX.CameraFOV.Enabled then
            currentCamera.FieldOfView = _G.MX.CameraFOV.Value
        end

        if _G.MX.NoSlowdownEnabled then
            local character = localPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if humanoid and GetRole() == "Killer" and humanoid.WalkSpeed < 16 then
                humanoid.WalkSpeed = 16
            end
        end

        if _G.MX.SurvivorNoSlowdown and os.clock() < (_G.MX.SlowUntil or 0) then
            local character = localPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if humanoid and GetRole() ~= "Killer" and not character:GetAttribute("Trapped") and not character:GetAttribute("IsCarried") and not character:GetAttribute("Knocked") then
                local wanted = 10
                if character:GetAttribute("Crouching") == true then
                    wanted = 6
                elseif character:GetAttribute("Sprinting") == true then
                    wanted = 17
                end
                wanted = wanted * (tonumber(character:GetAttribute("walkboost")) or 1)
                if humanoid.WalkSpeed > 0 and humanoid.WalkSpeed < wanted then
                    humanoid.WalkSpeed = wanted
                end
            end
        end

        if _G.MX.ESPConfig.Master and tick() - n >= 0.25 then
            n = tick()
            UpdatePlayerESP()
            UpdateSCPESP()
            UpdateStaticESP()
        end
    end))

    local items = ReplicatedStorage:WaitForChild("Items", 5)

    extractAssetId = function(arg)
        return tostring(arg):match("%d+")
    end

    getItemIcon = function(arg)
        if not items then
            return nil
        end
        local v5 = items:FindFirstChild(arg)
        if not v5 then
            return nil
        end
        local v6 = nil

        pcall(function()
            local texture = v5.Texture
            local image = texture or v5.Image
            v6 = image
        end)

        if v6 and v6 ~= "" then
            local v7 = extractAssetId(v6)
            if v7 then
                return string.format("rbxthumb://type=Asset&id=%s&w=420&h=420", v7)
            end
        end

        return nil
    end

    _G.MX.Esp = {}
    do
        local Esp = _G.MX.Esp
        local TweenSvc = game:GetService("TweenService")
        local HL_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local state = setmetatable({}, {__mode = "k"})

        function Esp.styleHighlight(h, color)
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            local outlineOnly = _G.MX.ESPConfig.Outline
            local fillT = outlineOnly and 1 or 0.78
            local outT = outlineOnly and 0 or 0
            local key = string.format("%s|%s|%s", color:ToHex(), fillT, outT)
            if state[h] == key then
                return
            end
            if state[h] == nil then
                h.FillColor = color
                h.OutlineColor = color
                h.FillTransparency = 1
                h.OutlineTransparency = 1
            end
            state[h] = key
            TweenSvc:Create(h, HL_INFO, {
                FillColor = color,
                OutlineColor = color,
                FillTransparency = fillT,
                OutlineTransparency = outT,
            }):Play()
        end

        function Esp.fadeIn(gui)
            task.defer(function()
                if not gui or not gui.Parent then
                    return
                end
                for _, d in ipairs(gui:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        local base = d.TextTransparency
                        local baseStroke = d.TextStrokeTransparency
                        d.TextTransparency = 1
                        d.TextStrokeTransparency = 1
                        TweenSvc:Create(d, HL_INFO, {TextTransparency = base, TextStrokeTransparency = baseStroke}):Play()
                    elseif d:IsA("ImageLabel") then
                        local base = d.ImageTransparency
                        d.ImageTransparency = 1
                        TweenSvc:Create(d, HL_INFO, {ImageTransparency = base}):Play()
                    end
                end
            end)
        end

    end

    CreateModernESP = function(parent, name, arg)
        if not parent then
            return
        end
        local name2 = arg.name
        local str = name2 or ""
        local flag3 = str ~= ""
        local flag4 = name ~= "PE_Text"

        if not flag4 then
            if flag3 then
                flag4 = false
            else
                flag4 = true
            end
        end

        local str2 = flag4 and "single" or "multi"
        local infoRich = arg.infoRich
        local text = infoRich or ""

        if text == "" then
            local tbl6 = {}

            if arg.subtext and arg.subtext ~= "" then
                table.insert(tbl6, tostring(arg.subtext))
            end

            if arg.distance then
                table.insert(tbl6, tostring(arg.distance) .. "m")
            end

            text = table.concat(tbl6, " <font color=\"#888888\">·</font> ")
        end

        local v5 = parent:FindFirstChild(name)
        local v6 = v5

        if v5 and v5:GetAttribute("Layout") ~= str2 then
            v5:Destroy()
            v6 = nil
        end

        if not v6 then
            local billboardGui = Instance.new("BillboardGui")
            v6 = billboardGui
            billboardGui.Name = name
            billboardGui.AlwaysOnTop = true
            billboardGui:SetAttribute("Layout", str2)
            local udim2 = flag4 and UDim2.new(0, 220, 0, 22) or UDim2.new(0, 220, 0, 34)
            billboardGui.Size = udim2
            local vector = Vector3.new
            local offsetY = arg.offsetY
            local n2 = offsetY or 4
            billboardGui.StudsOffset = vector(0, n2, 0)
            billboardGui.Parent = parent
            _G.MX.Esp.fadeIn(billboardGui)
            local frame2 = Instance.new("Frame")
            frame2.Name = "Box"
            frame2.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
            frame2.BackgroundTransparency = 0.38
            frame2.AutomaticSize = Enum.AutomaticSize.XY
            frame2.Size = UDim2.new(0, 0, 0, 0)
            frame2.AnchorPoint = Vector2.new(0.5, 0.5)
            frame2.Position = UDim2.new(0.5, 0, 0.5, 0)
            frame2.Parent = billboardGui
            local pillCorner = Instance.new("UICorner")
            pillCorner.CornerRadius = UDim.new(0, 7)
            pillCorner.Parent = frame2
            local pillStroke = Instance.new("UIStroke")
            pillStroke.Name = "PillStroke"
            pillStroke.Color = Color3.fromRGB(255, 255, 255)
            pillStroke.Transparency = 0.82
            pillStroke.Thickness = 1
            pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            pillStroke.Parent = frame2
            local pillPad = Instance.new("UIPadding")
            pillPad.PaddingLeft = UDim.new(0, 8)
            pillPad.PaddingRight = UDim.new(0, 8)
            pillPad.PaddingTop = UDim.new(0, 3)
            pillPad.PaddingBottom = UDim.new(0, 3)
            pillPad.Parent = frame2

            if arg.noDistScale then
                billboardGui:SetAttribute("NoDistScale", true)
            else
                local uiScale = Instance.new("UIScale")
                uiScale.Name = "DistScale"
                uiScale.Scale = 1
                uiScale.Parent = frame2
            end

            if flag4 then
                local uiListLayout = Instance.new("UIListLayout", frame2)
                uiListLayout.FillDirection = Enum.FillDirection.Horizontal
                uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                uiListLayout.Padding = UDim.new(0, 4)
                local imageLabel = Instance.new("ImageLabel")
                imageLabel.Name = "Icon"
                imageLabel.BackgroundTransparency = 1
                imageLabel.Size = UDim2.new(0, 14, 0, 14)
                imageLabel.Visible = false
                imageLabel.Parent = frame2
                local textLabel = Instance.new("TextLabel")
                textLabel.Name = "Text"
                textLabel.BackgroundTransparency = 1
                textLabel.AutomaticSize = Enum.AutomaticSize.XY
                textLabel.Font = Enum.Font.GothamBold
                textLabel.TextSize = 13
                textLabel.TextWrapped = false
                textLabel.TextYAlignment = Enum.TextYAlignment.Center
                textLabel.RichText = true
                textLabel.TextStrokeTransparency = 0.35
                textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                textLabel.Parent = frame2
            else
                local uiListLayout = Instance.new("UIListLayout", frame2)
                uiListLayout.FillDirection = Enum.FillDirection.Vertical
                uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                uiListLayout.Padding = UDim.new(0, 0)
                local frame3 = Instance.new("Frame")
                frame3.Name = "Row1"
                frame3.BackgroundTransparency = 1
                frame3.AutomaticSize = Enum.AutomaticSize.XY
                frame3.Size = UDim2.new(0, 0, 0, 16)
                frame3.Parent = frame2
                local uiListLayout2 = Instance.new("UIListLayout", frame3)
                uiListLayout2.FillDirection = Enum.FillDirection.Horizontal
                uiListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
                uiListLayout2.VerticalAlignment = Enum.VerticalAlignment.Center
                uiListLayout2.Padding = UDim.new(0, 4)
                local imageLabel = Instance.new("ImageLabel")
                imageLabel.Name = "Icon"
                imageLabel.BackgroundTransparency = 1
                imageLabel.Size = UDim2.new(0, 14, 0, 14)
                imageLabel.Visible = false
                imageLabel.Parent = frame3
                local textLabel = Instance.new("TextLabel")
                textLabel.Name = "Name"
                textLabel.BackgroundTransparency = 1
                textLabel.AutomaticSize = Enum.AutomaticSize.XY
                textLabel.Font = Enum.Font.GothamBold
                textLabel.TextSize = 13
                textLabel.TextWrapped = false
                textLabel.TextYAlignment = Enum.TextYAlignment.Center
                textLabel.TextStrokeTransparency = 0.35
                textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                textLabel.Parent = frame3
                local textLabel2 = Instance.new("TextLabel")
                textLabel2.Name = "Info"
                textLabel2.BackgroundTransparency = 1
                textLabel2.AutomaticSize = Enum.AutomaticSize.XY
                textLabel2.Font = Enum.Font.GothamBold
                textLabel2.TextSize = 12
                textLabel2.TextWrapped = false
                textLabel2.TextYAlignment = Enum.TextYAlignment.Center
                textLabel2.RichText = true
                textLabel2.TextStrokeTransparency = 0.35
                textLabel2.TextStrokeColor3 = Color3.new(0, 0, 0)
                textLabel2.Parent = frame2
            end
        end

        local box = v6:FindFirstChild("Box")

        if flag4 then
            local text2 = box and box:FindFirstChild("Text")
            local icon = box and box:FindFirstChild("Icon")

            if text2 then
                local str3 = "#FFFFFF"

                if arg.color then
                    str3 = string.format("#%02X%02X%02X", math.floor(arg.color.R * 255), math.floor(arg.color.G * 255), math.floor(arg.color.B * 255))
                end

                local v7 = tostring
                local str4 = str or ""
                local str5 = v7(str4):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
                local text3 = ""

                if flag3 then
                    text3 = string.format("<font color=\"%s\">%s</font>", str3, str5)
                end

                if text ~= "" then
                    if text3 == "" then
                        text3 = text
                    elseif arg.noSeparator then
                        text3 = text3 .. " " .. text
                    else
                        text3 = text3 .. " <font color=\"#888888\">·</font> " .. text
                    end
                end

                text2.Text = text3
            end

            if icon then
                if arg.icon and arg.icon ~= "" then
                    icon.Image = arg.icon
                    icon.Visible = true
                else
                    icon.Visible = false
                end
            end
        else
            local row1 = box and box:FindFirstChild("Row1")
            local name3 = row1 and row1:FindFirstChild("Name")
            local icon = row1 and row1:FindFirstChild("Icon")
            local info = box and box:FindFirstChild("Info")

            if name3 then
                name3.Text = tostring(str):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
                local color = arg.color
                local color2 = color or Color3.new(1, 1, 1)
                name3.TextColor3 = color2
            end

            if icon then
                if arg.icon and arg.icon ~= "" then
                    icon.Image = arg.icon
                    icon.Visible = true
                else
                    icon.Visible = false
                end
            end

            if info then
                if text == "" then
                    info.Visible = false
                else
                    info.Visible = true
                    info.Text = text
                end
            end
        end
    end

    local function fn29()
        local team = localPlayer.Team
        local flag3 = team and localPlayer.Team.Name == "Survivors"
        return flag3
    end

    local function perkBoost(char, key, mult, secs, alive)
        local ok, SS = pcall(function() return require(game:GetService("ReplicatedStorage").Modules.SpeedService) end)
        if ok and type(SS) == "table" and SS.set then
            pcall(SS.set, char, key, mult)
            local t0 = tick()
            while alive() and tick() - t0 < secs and char and char.Parent do task.wait(0.1) end
            pcall(SS.clear, char, key)
        else
            local t0 = tick()
            while alive() and tick() - t0 < secs and char and char.Parent do
                char:SetAttribute("speedboost", mult)
                task.wait()
            end
            if char and char.Parent then char:SetAttribute("speedboost", 1) end
        end
    end

    local function fn30(arg)
        local humanoid = arg:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return false
        end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            return false
        end

        for i, v5 in ipairs(animator:GetPlayingAnimationTracks()) do
            if v5.Animation and string.find(tostring(v5.Animation.AnimationId), "126081405469607") then
                return true
            end
        end

        return false
    end

    local function fn31(arg)
        if not _G.MX.FakePerks.QuickRecoveryEnabled then
            return
        end

        if not fn29() then
            return
        end

        if _G.MX.FakePerks.boostActive then
            return
        end

        if tick() - _G.MX.FakePerks.lastQRTime < _G.MX.FakePerks.PerkCooldown then
            return
        end
        _G.MX.FakePerks.boostActive = true
        _G.MX.FakePerks.lastQRTime = tick()
        local now = tick()

        task.spawn(function()
            perkBoost(arg, "MXHUB_Perk1", 1.4, 3, function() return _G.MX.FakePerks.QuickRecoveryEnabled end)

            _G.MX.FakePerks.boostActive = false
        end)
    end

    local function fn32(arg)
        if _G.MX.FakePerks.qrConnection then
            _G.MX.FakePerks.qrConnection:Disconnect()
            _G.MX.FakePerks.qrConnection = nil
        end

        if not arg then
            return
        end

        _G.MX.FakePerks.qrConnection = MXTrack(arg:GetAttributeChangedSignal("isvaulting"):Connect(function()
            if arg:GetAttribute("isvaulting") == true then
                task.spawn(function()
                    task.wait(0.05)
                    local v5 = fn30(arg)
                    local v6 = v5

                    if not v5 then
                        task.wait(0.05)
                        v6 = fn30(arg)
                    end

                    if not v6 and arg:GetAttribute("isvaulting") == true then
                        fn31(arg)
                    end
                end)
            end
        end))
    end

    ToggleQuickRecovery = function(quickRecoveryEnabled)
        _G.MX.FakePerks.QuickRecoveryEnabled = quickRecoveryEnabled

        if quickRecoveryEnabled and localPlayer.Character then
            fn32(localPlayer.Character)
        elseif not quickRecoveryEnabled and _G.MX.FakePerks.qrConnection then
            _G.MX.FakePerks.qrConnection:Disconnect()
            _G.MX.FakePerks.qrConnection = nil
        end

    end

    local function fn33(arg)
        if not _G.MX.FakePerks.PerfectLandingEnabled then
            return
        end

        if not fn29() then
            return
        end

        if _G.MX.FakePerks.perfectLandingBoostActive then
            return
        end

        if tick() - _G.MX.FakePerks.lastPLTime < _G.MX.FakePerks.PerkCooldown then
            return
        end
        _G.MX.FakePerks.perfectLandingBoostActive = true
        _G.MX.FakePerks.lastPLTime = tick()
        local now = tick()

        task.spawn(function()
            perkBoost(arg, "MXHUB_Perk2", 1.4, 3, function() return _G.MX.FakePerks.perfectLandingBoostActive end)

            _G.MX.FakePerks.perfectLandingBoostActive = false
        end)
    end

    local function fn34(arg)
        if _G.MX.FakePerks.plConnection then
            _G.MX.FakePerks.plConnection:Disconnect()
            _G.MX.FakePerks.plConnection = nil
        end

        if not arg then
            return
        end

        _G.MX.FakePerks.plConnection = MXTrack(arg:GetAttributeChangedSignal("speedboost"):Connect(function()
            if not fn29() then
                return
            end

            if arg:GetAttribute("speedboost") == 0.625 then
                fn33(arg)
            end
        end))
    end

    TogglePerfectLanding = function(perfectLandingEnabled)
        _G.MX.FakePerks.PerfectLandingEnabled = perfectLandingEnabled

        if perfectLandingEnabled then
            if localPlayer.Character then
                fn34(localPlayer.Character)
            end
        else
            if _G.MX.FakePerks.plConnection then
                _G.MX.FakePerks.plConnection:Disconnect()
                _G.MX.FakePerks.plConnection = nil
            end

            if _G.MX.FakePerks.perfectLandingBoostActive and localPlayer.Character then
                localPlayer.Character:SetAttribute("speedboost", 1)
                _G.MX.FakePerks.perfectLandingBoostActive = false
            end
        end

    end

    local function fn35(arg)
        if _G.MX.FakePerks.fsConnection then
            _G.MX.FakePerks.fsConnection:Disconnect()
            _G.MX.FakePerks.fsConnection = nil
        end

        if _G.MX.FakePerks.fsAnimConnection then
            _G.MX.FakePerks.fsAnimConnection:Disconnect()
            _G.MX.FakePerks.fsAnimConnection = nil
        end

        if not arg then
            return
        end
        local humanoid = arg:WaitForChild("Humanoid", 3)
        if not humanoid then
            return
        end
        local animator = humanoid:WaitForChild("Animator", 3)
        if not animator then
            return
        end

        _G.MX.FakePerks.fsAnimConnection = MXTrack(animator.AnimationPlayed:Connect(function(arg2)
            if not arg2.Animation then
                return
            end

            if arg2.Animation.AnimationId ~= "rbxassetid://136962284480779" then
                return
            end
            local connection = nil

            connection = MXTrack(arg2.Stopped:Connect(function()
                if connection then
                    connection:Disconnect()
                end

                _G.MX.FakePerks.lastFSTime = tick()
                _G.MX.FakePerks.fsOnCooldown = true

                if arg and arg.Parent then
                    arg:SetAttribute("Flowstate", false)
                end

                task.delay(_G.MX.FakePerks.PerkCooldown, function()
                    _G.MX.FakePerks.fsOnCooldown = false

                    if _G.MX.FakePerks.FlowstateEnabled and arg and arg.Parent then
                        arg:SetAttribute("Flowstate", true)
                    end
                end)
            end))
        end))

        _G.MX.FakePerks.fsConnection = MXTrack(arg:GetAttributeChangedSignal("Flowstate"):Connect(function()
            if not _G.MX.FakePerks.FlowstateEnabled then
                return
            end

            if not fn29() then
                return
            end
            local attribute = arg:GetAttribute("Flowstate")

            if attribute == true then
                if _G.MX.FakePerks.fsOnCooldown or tick() - _G.MX.FakePerks.lastFSTime < _G.MX.FakePerks.PerkCooldown then
                    arg:SetAttribute("Flowstate", false)
                end
            elseif attribute == false and not _G.MX.FakePerks.fsOnCooldown then
                local n2 = tick() - _G.MX.FakePerks.lastFSTime

                if _G.MX.FakePerks.PerkCooldown <= n2 then
                    arg:SetAttribute("Flowstate", true)
                end
            end
        end))

        task.wait(0.5)

        if _G.MX.FakePerks.FlowstateEnabled and arg and arg.Parent then
            arg:SetAttribute("Flowstate", true)
        end
    end

    ToggleFlowstate = function(flowstateEnabled)
        _G.MX.FakePerks.FlowstateEnabled = flowstateEnabled

        if flowstateEnabled then
            if localPlayer.Character then
                fn35(localPlayer.Character)
            end
        else
            if _G.MX.FakePerks.fsConnection then
                _G.MX.FakePerks.fsConnection:Disconnect()
                _G.MX.FakePerks.fsConnection = nil
            end

            if _G.MX.FakePerks.fsAnimConnection then
                _G.MX.FakePerks.fsAnimConnection:Disconnect()
                _G.MX.FakePerks.fsAnimConnection = nil
            end

            if localPlayer.Character then
                localPlayer.Character:SetAttribute("Flowstate", false)
            end
        end

    end

    local function fn36()
        local adrenalineConns = _G.MX.FakePerks.adrenalineConns
        if not adrenalineConns then
            return
        end

        for i, adrenalineConn in ipairs(adrenalineConns) do
            pcall(function()
                adrenalineConn:Disconnect()
            end)
        end

        _G.MX.FakePerks.adrenalineConns = {}
    end

    local function fn37(arg)
        if not _G.MX.FakePerks.FakeAdrenalineRush then
            return
        end

        if not fn29() then
            return
        end

        if not arg or not arg.Parent then
            return
        end

        if _G.MX.FakePerks.boostActive then
            return
        end
        local now = tick()
        local lastARTime = _G.MX.FakePerks.lastARTime
        local n2 = lastARTime or 0
        if now - n2 < _G.MX.FakePerks.PerkCooldown then
            return
        end
        _G.MX.FakePerks.boostActive = true
        _G.MX.FakePerks.lastARTime = tick()

        task.spawn(function()
            perkBoost(arg, "MXHUB_Perk3", 1.4, 5, function() return _G.MX.FakePerks.FakeAdrenalineRush end)

            _G.MX.FakePerks.boostActive = false
        end)
    end

    local function fn38(arg)
        if not arg then
            return
        end
        local humanoid = arg:FindFirstChildOfClass("Humanoid")
        local humanoid2 = humanoid or arg:WaitForChild("Humanoid", 5)
        if not humanoid2 then
            return
        end
        local health = humanoid2.Health

        table.insert(_G.MX.FakePerks.adrenalineConns, humanoid2.HealthChanged:Connect(function(health2)
            if not _G.MX.FakePerks.FakeAdrenalineRush then
                return
            end

            if health2 < health and health2 <= 50 and health2 > 0 then
                fn37(arg)
            end

            health = health2
        end))
    end

    SetupFakeAdrenalineRush = function(arg)
        local fakePerks = _G.MX.FakePerks
        local fakeAdrenalineRush = arg == true
        fakePerks.FakeAdrenalineRush = fakeAdrenalineRush
        local fakePerks2 = _G.MX.FakePerks
        local adrenalineOn = arg == true
        fakePerks2.adrenalineOn = adrenalineOn
        fn36()

        if not arg then

            return
        end

        fn38(localPlayer.Character)

        table.insert(_G.MX.FakePerks.adrenalineConns, localPlayer.CharacterAdded:Connect(function(character)
            task.wait(0.3)

            if _G.MX.FakePerks.FakeAdrenalineRush then
                fn38(character)
            end
        end))

    end

    local function fn39(character)
        task.wait(0.5)

        if _G.MX.FakePerks.QuickRecoveryEnabled then
            fn32(character)
        end

        if _G.MX.FakePerks.PerfectLandingEnabled then
            fn34(character)
        end

        if _G.MX.FakePerks.FlowstateEnabled then
            fn35(character)
        end

        if _G.MX.FakePerks.FakeAdrenalineRush then
            fn38(character)
        end
    end

    if localPlayer.Character then
        fn39(localPlayer.Character)
    end

    localPlayer.CharacterAdded:Connect(fn39)

    local streamer = {
        tracked = {},
        origText = setmetatable({}, {__mode = "k"}),
        modText = setmetatable({}, {__mode = "k"}),
        origImage = setmetatable({}, {__mode = "k"}),
        origHum = setmetatable({}, {__mode = "k"}),
        roots = {},
        alias = {},
        count = 0,
        gen = 0,
    }
    local STREAM_LOGO = (lib.Ui.Assets and lib.Ui.Assets.Logo) or "rbxassetid://105865788976884"

    local function escapePattern(s)
        return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
    end

    local function aliasFor(plr)
        local a = streamer.alias[plr.UserId]
        if not a then
            if plr == localPlayer then
                a = "MXHUB"
            else
                streamer.count += 1
                a = "Player" .. streamer.count
            end
            streamer.alias[plr.UserId] = a
        end
        return a
    end

    local function scrub(text)
        if #text < 2 then
            return text
        end
        local out = text
        for _, plr in ipairs(Players:GetPlayers()) do
            local a = aliasFor(plr)
            local safeAlias = a:gsub("%%", "%%%%")
            for _, nm in ipairs({plr.DisplayName, plr.Name}) do
                if #nm >= 2 and out:find(nm, 1, true) then
                    out = (out:gsub(escapePattern(nm), safeAlias))
                end
            end
        end
        return out
    end

    local function hasAvatar(image)
        if image == "" or image == STREAM_LOGO then
            return false
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if image:find(tostring(plr.UserId), 1, true) then
                return true
            end
        end
        return false
    end

    local function trackInstance(inst)
        if streamer.tracked[inst] or not _G.MX.StreamerMode.Enabled then
            return
        end
        if lib.Window.Gui and inst:IsDescendantOf(lib.Window.Gui) then
            return
        end
        local apply
        local prop
        if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
            prop = "Text"
            apply = function()
                if not _G.MX.StreamerMode.Enabled then
                    return
                end
                local text = inst.Text
                if streamer.modText[inst] == text then
                    return
                end
                local clean = scrub(text)
                if clean ~= text then
                    streamer.origText[inst] = text
                    streamer.modText[inst] = clean
                    inst.Text = clean
                else
                    streamer.origText[inst] = nil
                    streamer.modText[inst] = nil
                end
            end
        elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
            prop = "Image"
            apply = function()
                if not _G.MX.StreamerMode.Enabled then
                    return
                end
                local image = inst.Image
                if hasAvatar(image) then
                    streamer.origImage[inst] = image
                    inst.Image = STREAM_LOGO
                end
            end
        else
            return
        end
        streamer.tracked[inst] = {conn = inst:GetPropertyChangedSignal(prop):Connect(apply), apply = apply}
        apply()
    end

    local function hideHumanoidName(character)
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local plr = character and Players:GetPlayerFromCharacter(character)
        if hum and plr and _G.MX.StreamerMode.Enabled then
            if streamer.origHum[hum] == nil then
                streamer.origHum[hum] = hum.DisplayName
            end
            hum.DisplayName = aliasFor(plr)
        end
    end

    local function scanRoot(root, billboardsOnly)
        local myGen = streamer.gen
        task.spawn(function()
            local n = 0
            for _, d in ipairs(root:GetDescendants()) do
                if streamer.gen ~= myGen or not _G.MX.StreamerMode.Enabled then
                    return
                end
                if not billboardsOnly or d:FindFirstAncestorWhichIsA("BillboardGui") or d:FindFirstAncestorWhichIsA("SurfaceGui") then
                    trackInstance(d)
                end
                n += 1
                if n % 120 == 0 then
                    RunService.Heartbeat:Wait()
                end
            end
        end)
        table.insert(streamer.roots, root.DescendantAdded:Connect(function(d)
            task.defer(function()
                if not billboardsOnly or d:FindFirstAncestorWhichIsA("BillboardGui") or d:FindFirstAncestorWhichIsA("SurfaceGui") then
                    trackInstance(d)
                end
            end)
        end))
    end

    local function watchCharacter(plr)
        local function onChar(character)
            if not _G.MX.StreamerMode.Enabled then
                return
            end
            hideHumanoidName(character)
            scanRoot(character, true)
        end
        if plr.Character then
            onChar(plr.Character)
        end
        table.insert(streamer.roots, plr.CharacterAdded:Connect(function(character)
            task.wait(0.3)
            onChar(character)
        end))
    end

    local function fn40()
        streamer.gen += 1
        scanRoot(playerGui, false)
        pcall(function()
            local coreGui = game:GetService("CoreGui")
            for _, child in ipairs(coreGui:GetChildren()) do
                if child ~= lib.Window.Gui then
                    scanRoot(child, false)
                end
            end
            table.insert(streamer.roots, coreGui.ChildAdded:Connect(function(child)
                if child ~= lib.Window.Gui then
                    task.defer(scanRoot, child, false)
                end
            end))
        end)
        for _, plr in ipairs(Players:GetPlayers()) do
            watchCharacter(plr)
        end
        table.insert(streamer.roots, Players.PlayerAdded:Connect(function(plr)
            task.defer(function()
                if not _G.MX.StreamerMode.Enabled then
                    return
                end
                watchCharacter(plr)
                for _, info in pairs(streamer.tracked) do
                    pcall(info.apply)
                end
            end)
        end))
    end

    local function fn41()
        streamer.gen += 1
        for _, conn in ipairs(streamer.roots) do
            conn:Disconnect()
        end
        table.clear(streamer.roots)
        for inst, info in pairs(streamer.tracked) do
            info.conn:Disconnect()
            streamer.tracked[inst] = nil
        end
        for inst, original in pairs(streamer.origText) do
            if inst.Parent and inst.Text == streamer.modText[inst] then
                inst.Text = original
            end
        end
        for inst, original in pairs(streamer.origImage) do
            if inst.Parent and inst.Image == STREAM_LOGO then
                inst.Image = original
            end
        end
        for hum, original in pairs(streamer.origHum) do
            if hum.Parent then
                hum.DisplayName = original
            end
        end
        table.clear(streamer.origText)
        table.clear(streamer.modText)
        table.clear(streamer.origImage)
        table.clear(streamer.origHum)
    end

    local function fn42(enabled)
        _G.MX.StreamerMode.Enabled = enabled
        fn41()
        if enabled then
            fn40()
        end
    end

    local tbl6 = {}

    UpdateHookData = function()
        for k, player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Team and player.Team.Name == "Survivors" then
                local attribute = player:GetAttribute("HookCount")
                local n2 = attribute or 0
                tbl6[player.Name] = n2
            end
        end
    end

    local tbl7 = {
        "rbxassetid://120434965879067",
        "rbxassetid://81511619438196",
        "rbxassetid://130571419892864",
    }

    CreateHookUICounter = function(parent, arg)
        if not parent then
            return
        end
        local num = tonumber(arg)
        local n2 = num or 0
        local v5 = n2
        local hookCounter = parent:FindFirstChild("MXHUB_HookCounter")
        local v6 = hookCounter

        if v5 <= 0 then
            if hookCounter then
                hookCounter:Destroy()
            end

            return
        end

        local v7 = tbl7[math.clamp(v5, 1, 3)]
        if not v7 then
            return
        end

        if not hookCounter then
            local imageLabel = Instance.new("ImageLabel")
            v6 = imageLabel
            imageLabel.Name = "MXHUB_HookCounter"
            imageLabel.BackgroundTransparency = 1
            local zIndex = parent.ZIndex
            local n3 = zIndex or 1
            imageLabel.ZIndex = n3 + 1
            imageLabel.Parent = parent
        end

        v6.Size = UDim2.new(0.509, 0, 0.51, 0)
        v6.Position = UDim2.new(0.91, 0, 0.18, 0)
        v6.AnchorPoint = Vector2.new(0.5, 0.5)
        v6.Image = v7
        v6.ScaleType = Enum.ScaleType.Fit
    end

    UpdateHookUICounter = function()
        if GetRole() == "Killer" then
            local playerGui2 = localPlayer:FindFirstChild("PlayerGui")
            if not playerGui2 then
                return
            end

            local function fn44(arg)
                if arg and type(arg) == "string" then
                    return tonumber(arg:match("id=(%d+)"))
                end
                return nil
            end

            local v5, v6, v7 = ipairs(playerGui2:GetChildren())
            local v8 = v7
            local v9 = v5
            local v10 = v6

            while true do
                local v11, v12 = v9(v10, v8)
                if v11 == nil then
                    break
                end
                v8 = v11

                if typeof(v12) == "Instance" then
                    local frame2 = v12:FindFirstChild("Frame")

                    if frame2 and frame2:IsA("Frame") then
                        for i, child in ipairs(frame2:GetChildren()) do
                            local imageLabel = child:FindFirstChild("ImageLabel")

                            if imageLabel then
                                local attribute = child:GetAttribute("UserId")
                                local v13 = attribute or fn44(imageLabel.Image)
                                local playerByUserId = v13 and Players:GetPlayerByUserId(tonumber(v13)) or nil

                                if playerByUserId and playerByUserId ~= localPlayer and playerByUserId.Team and playerByUserId.Team.Name == "Survivors" then
                                    local v14 = tbl6[playerByUserId.Name]
                                    local attribute2 = v14 or playerByUserId:GetAttribute("HookCount") or 0
                                    CreateHookUICounter(imageLabel, attribute2)
                                else
                                    local hookCounter = imageLabel:FindFirstChild("MXHUB_HookCounter")

                                    if hookCounter then
                                        hookCounter:Destroy()
                                    end
                                end
                            end
                        end

                        v8 = v11
                    end
                end
            end

            return
        end

        ClearHookUICounter()
    end

    ClearHookUICounter = function()
        local playerGui2 = localPlayer:FindFirstChild("PlayerGui")
        if not playerGui2 then
            return
        end
        local v5, v6, v7 = ipairs(playerGui2:GetChildren())
        local v8 = v7
        local v9 = v5
        local v10 = v6

        while true do
            local v11, v12 = v9(v10, v8)
            if v11 == nil then
                break
            end
            v8 = v11

            if typeof(v12) == "Instance" then
                local frame2 = v12:FindFirstChild("Frame")

                if frame2 and frame2:IsA("Frame") then
                    for i, child in ipairs(frame2:GetChildren()) do
                        local imageLabel = child:FindFirstChild("ImageLabel")
                        local hookCounter = imageLabel and imageLabel:FindFirstChild("MXHUB_HookCounter")

                        if hookCounter then
                            hookCounter:Destroy()
                        end
                    end

                    v8 = v11
                end
            end
        end
    end

    UpdateHookESP = function()
        if not _G.MX.ESPConfig.HookCount then
            ClearHookESP()
        end
    end

    ClearHookESP = function()
        local v5, v6, v7 = pairs(Players:GetPlayers())
        local v8 = v7
        local v9 = v5
        local v10 = v6

        while true do
            local v11, v12 = v9(v10, v8)
            if v11 == nil then
                break
            end
            v8 = v11

            if v12.Character then
                for k, child in pairs(v12.Character:GetChildren()) do
                    if string.match(child.Name, "^HookESP_") then
                        child:Destroy()
                    end
                end

                v8 = v11
            end
        end
    end

    ClearESP = function(arg)
        if arg == "Player" then
            for k, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    if player.Character:FindFirstChild("PEH") then
                        player.Character.PEH:Destroy()
                    end

                    if player.Character:FindFirstChild("PE_Text") then
                        player.Character.PE_Text:Destroy()
                    end
                end
            end
        elseif arg == "Killer" then
            for k, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    if player.Character:FindFirstChild("KEH") then
                        player.Character.KEH:Destroy()
                    end

                    if player.Character:FindFirstChild("KE_Text") then
                        player.Character.KE_Text:Destroy()
                    end
                end
            end
        elseif arg == "Generator" then
            for k, generator in pairs(tbl4.Generators) do
                if generator.model and generator.model.Parent and generator.model:FindFirstChild("GEH") then
                    generator.model.GEH:Destroy()
                end

                if generator.part and generator.part.Parent and generator.part:FindFirstChild("GE_Text") then
                    generator.part.GE_Text:Destroy()
                end
            end
        elseif arg == "Pallet" then
            for k, pallet in pairs(tbl4.Pallets) do
                if pallet and pallet.Parent then
                    local eh = pallet:FindFirstChild("PalletEH")
                    if eh then eh:Destroy() end
                    local t = pallet:FindFirstChild("PAL_Text", true)
                    if t then t:Destroy() end
                end
            end
        elseif arg == "Hook" then
            for k, hook in pairs(tbl4.Hooks) do
                if hook and hook.Parent and hook:FindFirstChild("HookEH") then
                    hook.HookEH:Destroy()
                end
            end
        elseif arg == "Window" then
            for k, window in pairs(tbl4.Windows) do
                if window and window.Parent then
                    local eh = window:FindFirstChild("WindowEH")
                    if eh then eh:Destroy() end
                    local t = window:FindFirstChild("WIN_Text", true)
                    if t then t:Destroy() end
                end
            end
        elseif arg == "Gate" then
            for k, gate in pairs(tbl4.Gates) do
                if gate and gate.Parent and gate:FindFirstChild("GateEH") then
                    gate.GateEH:Destroy()
                end
            end
        elseif arg == "SCP" then
            for k, scP in pairs(tbl4.SCPs) do
                if scP and scP.Parent and scP:FindFirstChild("SCPEH") then
                    scP.SCPEH:Destroy()
                end
            end
        end
    end

    ClearAllESP = function()
        ClearESP("Player")
        ClearESP("Killer")
        ClearESP("Generator")
        ClearESP("Pallet")
        ClearESP("Hook")
        ClearESP("Gate")
        ClearESP("SCP")
        ClearESP("Window")
        ClearHookESP()
    end

    GetSurvivorStatus = function(arg)
        if not arg then
            return nil, nil
        end

        if arg:GetAttribute("IsHooked") == true then
            return "HOOKED", _G.MX.ESPColors.Hooked
        end

        if arg:GetAttribute("Knocked") == true then
            return "DOWN", _G.MX.ESPColors.Downed
        end
        local humanoid = arg:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
            return "INJURED", _G.MX.ESPColors.Injured
        end
        return nil, nil
    end

    buildInfoRich = function(arg, arg2, arg3, arg4, arg5)
        local tbl8 = {}

        if arg and arg ~= "" then
            local str = "#FFFFFF"

            if arg == "INJURED" then
                str = "#FF8C00"
            elseif arg == "DOWN" then
                str = "#FF2828"
            elseif arg == "HOOKED" then
                str = "#F0F0FF"
            end

            table.insert(tbl8, string.format("<font color=\"%s\">%s</font>", str, arg))
        end

        if arg3 then
            table.insert(tbl8, string.format("<font color=\"#FFFFFF\">%dm</font>", arg3))
        end

        if not arg5 and arg4 and arg ~= "HOOKED" then
            local str = "#C8C8C8"

            if arg4 >= 3 then
                str = "#FF3232"
            elseif arg4 >= 2 then
                str = "#FFC832"
            end

            table.insert(tbl8, string.format("<font color=\"%s\">Hooked %d</font>", str, arg4))
        end

        return table.concat(tbl8, " <font color=\"#888888\">·</font> ")
    end

    UpdatePlayerESP = function()
        if not _G.MX.ESPConfig.Master then
            return
        end
        local character = localPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

        if _G.MX.ESPConfig.KillerWarn and humanoidRootPart and GetRole() == "Survivor" then
            local killerWarn = humanoidRootPart:FindFirstChild("KillerWarn")
            local v5 = killerWarn
            local huge = math.huge

            for k, player in pairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Team and player.Team.Name == "Killer" and player.Character then
                    local humanoidRootPart2 = player.Character:FindFirstChild("HumanoidRootPart")

                    if humanoidRootPart2 then
                        local magnitude = (humanoidRootPart2.Position - humanoidRootPart.Position).Magnitude

                        if magnitude < huge then
                            huge = magnitude
                        end
                    end
                end
            end

            if huge <= 80 then
                if not killerWarn then
                    local billboardGui = Instance.new("BillboardGui")
                    v5 = billboardGui
                    billboardGui.Name = "KillerWarn"
                    billboardGui.Size = UDim2.new(0, 30, 0, 30)
                    billboardGui.AlwaysOnTop = true
                    billboardGui.StudsOffset = Vector3.new(0, 4, 0)
                    billboardGui.Parent = humanoidRootPart
                    local textLabel = Instance.new("TextLabel")
                    textLabel.Name = "WarnText"
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.TextScaled = true
                    textLabel.TextStrokeTransparency = 0
                    textLabel.Font = Enum.Font.GothamBlack
                    textLabel.Parent = billboardGui
                end

                local warnText = v5:FindFirstChild("WarnText")

                if warnText then
                    if huge <= 40 then
                        warnText.Text = "!!"
                        warnText.TextColor3 = Color3.fromRGB(255, 0, 0)
                    else
                        warnText.Text = "!"
                        warnText.TextColor3 = Color3.fromRGB(255, 255, 0)
                    end
                end
            elseif killerWarn then
                killerWarn:Destroy()
            end
        else
            local killerWarn = humanoidRootPart and humanoidRootPart:FindFirstChild("KillerWarn")

            if killerWarn then
                killerWarn:Destroy()
            end
        end

        local v5, v6, v7 = pairs(Players:GetPlayers())
        local v8 = v7
        local v9 = v5
        local v10 = v6

        while true do
            local v11, v12 = v9(v10, v8)
            if v11 == nil then
                break
            end
            v8 = v11

            if v12 ~= localPlayer and v12.Character then
                local humanoidRootPart2 = v12.Character:FindFirstChild("HumanoidRootPart")

                if humanoidRootPart2 and _G.MX.ESPConfig.MaxDistance < (currentCamera.CFrame.Position - humanoidRootPart2.Position).Magnitude then
                    for i, v13 in ipairs({"PE_Text", "KE_Text", "PEH", "KEH"}) do
                        local v14 = v12.Character:FindFirstChild(v13)

                        if v14 then
                            v14:Destroy()
                        end
                    end

                    v8 = v11
                else
                    local team = v12.Team
                    local flag3 = team and v12.Team.Name == "Killer"
                    local killer

                    if flag3 then
                        killer = _G.MX.ESPConfig.Killer
                    else
                        local player = _G.MX.ESPConfig.Player
                        local hookCount = player or _G.MX.ESPConfig.HookCount
                        killer = hookCount
                    end

                    local str = flag3 and "KE_Text" or "PE_Text"
                    local name = flag3 and "KEH" or "PEH"
                    local killer2 = flag3 and _G.MX.ESPColors.Killer or _G.MX.ESPColors.Player
                    local v13 = nil
                    local v14 = nil

                    if not flag3 and _G.MX.ESPConfig.Status then
                        local v15, v16 = GetSurvivorStatus(v12.Character)

                        if v15 then
                            v13 = v15
                            v14 = v16
                        end
                    end

                    if killer then
                        local v15, v16, v17 = ipairs({"PE_Text", "KE_Text"})
                        local v18 = v9
                        local v19 = v10

                        for k, v20 in v15, v16, v17 do
                            if v20 ~= str then
                                local v21 = v12.Character:FindFirstChild(v20)

                                if v21 then
                                    v21:Destroy()
                                end
                            end
                        end

                        for i, v20 in ipairs({"PEH", "KEH"}) do
                            if v20 ~= name then
                                local v21 = v12.Character:FindFirstChild(v20)

                                if v21 then
                                    v21:Destroy()
                                end
                            end
                        end

                        v8 = v11
                        v9 = v18
                        v10 = v19

                        if flag3 then
                            for i, child in ipairs(v12.Character:GetChildren()) do
                                if string.match(child.Name, "^HookESP_") then
                                    child:Destroy()
                                end
                            end

                            v8 = v11
                            v9 = v18
                            v10 = v19
                        end

                        local humanoidRootPart3 = v12.Character:FindFirstChild("HumanoidRootPart")
                        local n2 = humanoidRootPart3 and math.floor(GetDistance(humanoidRootPart3.Position)) or nil
                        local v20 = v12.Character:FindFirstChild(name)
                        local v21 = v20

                        if not v20 then
                            local highlight2 = Instance.new("Highlight")
                            v21 = highlight2
                            highlight2.Name = name
                            highlight2.Parent = v12.Character
                        end

                        _G.MX.Esp.styleHighlight(v21, killer2)
                        local name2 = nil
                        local v22 = nil

                        if _G.MX.ESPConfig.Name then
                            name2 = v12.Name

                            if flag3 then
                                local attribute = v12:GetAttribute("SelectedKiller")

                                if not attribute then
                                    local selectedKiller = v12:FindFirstChild("SelectedKiller")

                                    if selectedKiller then
                                        pcall(function()
                                            attribute = selectedKiller.Value
                                        end)
                                    end
                                end

                                if attribute and tostring(attribute) ~= "" then
                                    name2 = tostring(attribute)
                                end
                            end

                            if _G.MX.ESPConfig.ItemIcon and not flag3 then
                                local attribute = v12:GetAttribute("EquippedItem")

                                if attribute and attribute ~= "" then
                                    v22 = getItemIcon(attribute)
                                end
                            end
                        end

                        local v23 = nil

                        if not flag3 and _G.MX.ESPConfig.HookCount then
                            local v24 = tbl6[v12.Name]
                            local attribute = v24 or v12:GetAttribute("HookCount") or 0
                            v23 = attribute
                        end

                        local v24 = buildInfoRich
                        local distance = _G.MX.ESPConfig.Distance
                        local v25 = distance and n2 or nil
                        local v26 = v24(v13, v14, v25, v23, flag3)

                        if not name2 and v26 == "" then
                            local v27 = v12.Character:FindFirstChild(str)

                            if v27 then
                                v27:Destroy()
                            end
                        else
                            local v27 = CreateModernESP
                            local character2 = v12.Character
                            local tbl8 = {}
                            local name3 = name2 or ""
                            tbl8.name = name3
                            tbl8.infoRich = v26
                            tbl8.color = killer2
                            tbl8.icon = v22
                            tbl8.offsetY = 4
                            v27(character2, str, tbl8)
                        end
                    else
                        local v15 = v12.Character:FindFirstChild(name)

                        if v15 then
                            v15:Destroy()
                        end

                        local v16 = v12.Character:FindFirstChild(str)

                        if v16 then
                            v16:Destroy()
                        end
                    end
                end
            end
        end
    end

    UpdateSCPESP = function()
        if not _G.MX.ESPConfig.Master then
            return
        end

        if _G.MX.ESPConfig.SCP then
            for i, scP in ipairs(tbl4.SCPs) do
                if scP and scP.Parent then
                    local humanoid = scP:FindFirstChildOfClass("Humanoid")
                    local humanoidRootPart = scP:FindFirstChild("HumanoidRootPart")
                    local torso = humanoidRootPart or scP:FindFirstChild("Torso") or scP.PrimaryPart

                    if torso and _G.MX.ESPConfig.MaxDistance < (currentCamera.CFrame.Position - torso.Position).Magnitude then
                        local scpeh = scP:FindFirstChild("SCPEH")

                        if scpeh then
                            scpeh:Destroy()
                        end
                    elseif torso and (not humanoid or (humanoid.Health > 0 and math.floor(humanoid.WalkSpeed) > 0 and math.floor(humanoid.WalkSpeed) ~= 16)) then
                        local scp = _G.MX.ESPColors.SCP
                        local scpeh = scP:FindFirstChild("SCPEH")
                        local v5 = scpeh

                        if not scpeh then
                            local highlight2 = Instance.new("Highlight")
                            v5 = highlight2
                            highlight2.Name = "SCPEH"
                            highlight2.Parent = scP
                        end

                        _G.MX.Esp.styleHighlight(v5, scp)
                    else
                        local scpeh = scP:FindFirstChild("SCPEH")

                        if scpeh then
                            scpeh:Destroy()
                        end
                    end
                end
            end
        else
            ClearESP("SCP")
        end
    end

    UpdateStaticESP = function()
        if not _G.MX.ESPConfig.Master then
            return
        end

        if _G.MX.ESPConfig.Generator then
            for k, generator in pairs(tbl4.Generators) do
                local model = generator.model

                if model and model.Parent then
                    local part = generator.part
                    local basePart = part or model:FindFirstChildWhichIsA("BasePart")

                    local finished = (tonumber(model:GetAttribute("RepairProgress")) or 0) >= 100
                    if finished or (basePart and _G.MX.ESPConfig.MaxDistance < (currentCamera.CFrame.Position - basePart.Position).Magnitude) then
                        local geh = model:FindFirstChild("GEH")

                        if geh then
                            geh:Destroy()
                        end

                        local geText = model:FindFirstChild("GE_Text") or (part and part:FindFirstChild("GE_Text")) or (basePart and basePart:FindFirstChild("GE_Text"))

                        if geText then
                            geText:Destroy()
                        end
                    else
                        local floor = math.floor
                        local attribute = model:GetAttribute("RepairProgress")
                        local n2 = attribute or 0
                        local v5 = floor(n2)
                        local n3 = math.clamp(v5 / 100, 0, 1)
                        local v6 = _G.MX.ESPColors.Generator:Lerp(_G.MX.ESPColors.GeneratorDone, n3)
                        local geh = model:FindFirstChild("GEH")
                        local v7 = geh

                        if not geh then
                            local highlight2 = Instance.new("Highlight")
                            v7 = highlight2
                            highlight2.Name = "GEH"
                            highlight2.Parent = model
                        end

                        _G.MX.Esp.styleHighlight(v7, v6)

                        if _G.MX.ESPConfig.GeneratorName then
                            local str

                            if v5 >= 100 then
                                str = "DONE"
                            else
                                str = string.format("%d%%", v5)
                            end

                            local generator2 = _G.MX.ESPColors.Generator
                            local part2 = generator.part
                            local v8 = part2 or model
                            local n4

                            if v8:IsA("BasePart") then
                                n4 = v8.Size.Y / 2 + 1
                            else
                                n4 = model:GetExtentsSize().Y / 2 + 1
                            end

                            CreateModernESP(v8, "GE_Text", {
                                name = "GEN",
                                infoRich = string.format("<font color=\"%s\">%s</font>", "#FF8000", str),
                                color = generator2,
                                icon = nil,
                                offsetY = n4,
                                noSeparator = true,
                                noDistScale = true,
                            })
                        else
                            local geText = model:FindFirstChild("GE_Text")

                            if geText then
                                geText:Destroy()
                            end
                        end
                    end
                end
            end
        end

        if _G.MX.ESPConfig.Pallet then
            for k, pallet in pairs(tbl4.Pallets) do
                if pallet and pallet.Parent then
                    local basePart = pallet:FindFirstChild("PrimaryPartPallet", true) or pallet:FindFirstChildWhichIsA("BasePart", true)
                    local palletEH = pallet:FindFirstChild("PalletEH")
                    local state = pallet:GetAttribute("PalletState")
                    local dist = basePart and (currentCamera.CFrame.Position - basePart.Position).Magnitude or math.huge

                    if not basePart or state == "Broken" or dist > _G.MX.ESPConfig.MaxDistance then
                        if palletEH then
                            palletEH:Destroy()
                        end
                        local oldText = basePart and basePart:FindFirstChild("PAL_Text")
                        if oldText then
                            oldText:Destroy()
                        end
                    else
                        if not palletEH then
                            palletEH = Instance.new("Highlight")
                            palletEH.Name = "PalletEH"
                            palletEH.Parent = pallet
                        end
                        palletEH.Adornee = pallet
                        local dropped = state == "Dropped"
                        local color = dropped and Color3.fromRGB(255, 70, 70) or _G.MX.ESPColors.Pallet
                        _G.MX.Esp.styleHighlight(palletEH, color)
                    end
                end
            end
        end

        if _G.MX.ESPConfig.Window then
            for i, window in ipairs(tbl4.Windows) do
                if window and window.Parent then
                    local basePart = window:FindFirstChild("Bottom") or window:FindFirstChildWhichIsA("BasePart", true)
                    local windowEH = window:FindFirstChild("WindowEH")
                    local dist = basePart and (currentCamera.CFrame.Position - basePart.Position).Magnitude or math.huge

                    if not basePart or dist > _G.MX.ESPConfig.MaxDistance then
                        if windowEH then
                            windowEH:Destroy()
                        end
                        local oldText = basePart and basePart:FindFirstChild("WIN_Text")
                        if oldText then
                            oldText:Destroy()
                        end
                    else
                        if windowEH and not windowEH:IsA("Highlight") then
                            windowEH:Destroy()
                            windowEH = nil
                        end
                        if not windowEH then
                            windowEH = Instance.new("Highlight")
                            windowEH.Name = "WindowEH"
                            windowEH.Parent = window
                        end
                        windowEH.Adornee = window
                        _G.MX.Esp.styleHighlight(windowEH, _G.MX.ESPColors.Window)
                    end
                end
            end
        end

        if _G.MX.ESPConfig.Hook then
            for i, hook in ipairs(tbl4.Hooks) do
                if hook and hook.Parent then
                    local hookPoint = hook:FindFirstChild("HookPoint")
                    local basePart = hookPoint or hook:FindFirstChildWhichIsA("BasePart")

                    if basePart and _G.MX.ESPConfig.MaxDistance < (currentCamera.CFrame.Position - basePart.Position).Magnitude then
                        local hookEH = hook:FindFirstChild("HookEH")

                        if hookEH then
                            hookEH:Destroy()
                        end
                    else
                        local hookEH = hook:FindFirstChild("HookEH")
                        local v5 = hookEH

                        if not hookEH then
                            local highlight2 = Instance.new("Highlight")
                            v5 = highlight2
                            highlight2.Name = "HookEH"
                            highlight2.Parent = hook
                        end

                        _G.MX.Esp.styleHighlight(v5, _G.MX.ESPColors.Hook)
                    end
                end
            end
        end

        if _G.MX.ESPConfig.Gate then
            for i, gate in ipairs(tbl4.Gates) do
                if gate and gate.Parent then
                    local basePart = gate:FindFirstChildWhichIsA("BasePart")

                    if basePart and _G.MX.ESPConfig.MaxDistance < (currentCamera.CFrame.Position - basePart.Position).Magnitude then
                        local gateEH = gate:FindFirstChild("GateEH")

                        if gateEH then
                            gateEH:Destroy()
                        end
                    else
                        local gateEH = gate:FindFirstChild("GateEH")
                        local v5 = gateEH

                        if not gateEH then
                            local highlight2 = Instance.new("Highlight")
                            v5 = highlight2
                            highlight2.Name = "GateEH"
                            highlight2.Parent = gate
                        end

                        v5.Adornee = gate
                        _G.MX.Esp.styleHighlight(v5, _G.MX.ESPColors.Gate)
                    end
                end
            end
        end
    end

    task.spawn(function()
        local currentCamera2, v5, v6, v7, v8, v9, v10, v11, v12, humanoidRootPart, magnitude, scale, n2, v13, v14, v15, v16, v17, v18, v19
        local v20, v21, box, distScale, v22, v23, v24, v25, v26, v27, model, basePart, magnitude2, scale2, n3, geText, box2, distScale2, n4
        n4 = 1

        while true do
            if n4 == 1 then
                if _G.MX.ScriptAlive then
                    n4 = 2
                else
                    n4 = 26
                end
            elseif n4 == 2 then
                task.wait(0.1)
                currentCamera2 = workspace.CurrentCamera

                if currentCamera2 then
                    n4 = 3
                else
                    n4 = 1
                end
            elseif n4 == 3 then
                v5, v6, v7 = ipairs(Players:GetPlayers())
                v8 = v7
                v9 = v5
                v10 = v6
                n4 = 4
            elseif n4 == 4 then
                v11, v12 = v9(v10, v8)

                if v11 == nil then
                    n4 = 16
                else
                    n4 = 5
                end
            elseif n4 == 5 then
                v8 = v11

                if v12 ~= localPlayer and v12.Character then
                    n4 = 6
                else
                    n4 = 4
                end
            elseif n4 == 6 then
                humanoidRootPart = v12.Character:FindFirstChild("HumanoidRootPart")

                if humanoidRootPart then
                    n4 = 7
                else
                    n4 = 4
                end
            elseif n4 == 7 then
                magnitude = (currentCamera2.CFrame.Position - humanoidRootPart.Position).Magnitude
                scale = math.clamp(40 / math.max(magnitude, 5), 0.8, 1)
                n2 = 4 + math.clamp((magnitude - 40) * 0.05, 0, 6)
                v13, v14, v15 = ipairs({"PE_Text", "KE_Text"})
                v16 = v9
                v17 = v10
                v18 = v15
                n4 = 8
            elseif n4 == 8 then
                v19, v20 = v13(v14, v18)

                if v19 == nil then
                    n4 = 15
                else
                    n4 = 9
                end
            elseif n4 == 9 then
                v18 = v19
                v21 = v12.Character:FindFirstChild(v20)

                if v21 and not v21:GetAttribute("NoDistScale") then
                    n4 = 10
                else
                    n4 = 8
                end
            elseif n4 == 10 then
                box = v21:FindFirstChild("Box")
                distScale = box

                if box then
                    n4 = 11
                else
                    n4 = 12
                end
            elseif n4 == 11 then
                distScale = box:FindFirstChild("DistScale")
                n4 = 12
            elseif n4 == 12 then
                if distScale then
                    n4 = 13
                else
                    n4 = 14
                end
            elseif n4 == 13 then
                distScale.Scale = distScale.Scale + (scale - distScale.Scale) * 0.35
                n4 = 14
            elseif n4 == 14 then
                v21.StudsOffset = v21.StudsOffset:Lerp(Vector3.new(0, n2, 0), 0.4)
                n4 = 8
            elseif n4 == 15 then
                v8 = v11
                v9 = v16
                v10 = v17
                n4 = 4
            elseif n4 == 16 then
                v22, v23, v24 = pairs(tbl4.Generators)
                v25 = v24
                n4 = 17
            elseif n4 == 17 then
                v26, v27 = v22(v23, v25)

                if v26 == nil then
                    n4 = 1
                else
                    n4 = 18
                end
            elseif n4 == 18 then
                v25 = v26
                model = v27.model

                if model and model.Parent then
                    n4 = 19
                else
                    n4 = 17
                end
            elseif n4 == 19 then
                basePart = model:FindFirstChildWhichIsA("BasePart")

                if basePart then
                    n4 = 20
                else
                    n4 = 17
                end
            elseif n4 == 20 then
                magnitude2 = (currentCamera2.CFrame.Position - basePart.Position).Magnitude
                scale2 = math.clamp(40 / math.max(magnitude2, 5), 0.8, 1)
                n3 = 4 + math.clamp((magnitude2 - 40) * 0.05, 0, 6)
                geText = model:FindFirstChild("GE_Text")

                if geText and not geText:GetAttribute("NoDistScale") then
                    n4 = 21
                else
                    n4 = 17
                end
            elseif n4 == 21 then
                box2 = geText:FindFirstChild("Box")
                distScale2 = box2

                if box2 then
                    n4 = 22
                else
                    n4 = 23
                end
            elseif n4 == 22 then
                distScale2 = box2:FindFirstChild("DistScale")
                n4 = 23
            elseif n4 == 23 then
                if distScale2 then
                    n4 = 24
                else
                    n4 = 25
                end
            elseif n4 == 24 then
                distScale2.Scale = distScale2.Scale + (scale2 - distScale2.Scale) * 0.35
                n4 = 25
            elseif n4 == 25 then
                geText.StudsOffset = Vector3.new(0, n3, 0)
                n4 = 17
            elseif n4 == 26 then
                return
            end
        end
    end)

    SetupHookDetection = function()
        for k, player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                MXTrack(player:GetAttributeChangedSignal("HookCount"):Connect(function()
                    local name = player.Name
                    local attribute = player:GetAttribute("HookCount")
                    local n2 = attribute or 0
                    tbl6[name] = n2

                    if _G.MX.ESPConfig.HookCount then
                        UpdateHookESP()
                        UpdateHookUICounter()
                    end
                end))
            end
        end
    end

    MXTrack(Players.PlayerAdded:Connect(function(player)
        MXTrack(player:GetAttributeChangedSignal("HookCount"):Connect(function()
            local name = player.Name
            local attribute = player:GetAttribute("HookCount")
            local n2 = attribute or 0
            tbl6[name] = n2

            if _G.MX.ESPConfig.HookCount then
                UpdateHookESP()
                UpdateHookUICounter()
            end
        end))
    end))

    task.spawn(function()
        task.wait(2)
        SetupHookDetection()
    end)

    local flag3 = false

    task.spawn(function()
        while _G.MX.ScriptAlive do
            task.wait(1)

            if _G.MX.ESPConfig.HookCount then
                flag3 = true
                UpdateHookData()
                UpdatePlayerESP()
                UpdateHookUICounter()
            elseif flag3 then
                ClearHookESP()
                ClearHookUICounter()
                UpdatePlayerESP()
                flag3 = false
            end
        end
    end)

    local function fn44(enabled)
        _G.MX.InfinityZoom.Enabled = enabled

        if enabled then
            localPlayer.CameraMaxZoomDistance = math.huge
            localPlayer.CameraMinZoomDistance = 0

        else
            localPlayer.CameraMaxZoomDistance = 12
            localPlayer.CameraMinZoomDistance = 0.5

        end
    end

    local function fn45(enabled)
        _G.MX.CameraFOV.Enabled = enabled

        if not enabled then
            currentCamera.FieldOfView = 70
        end

    end

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)

        if _G.MX.CameraFOV.Enabled then
            currentCamera.FieldOfView = _G.MX.CameraFOV.Value
        end
    end))

    MXTrack(workspace.ChildAdded:Connect(function(child)
        if child.Name == "Map" then
            task.wait(0.5)

            if _G.MX.CameraFOV.Enabled then
                currentCamera.FieldOfView = _G.MX.CameraFOV.Value
            end
        end
    end))

    ResetAllTransparency = function()
        local v5, v6, v7 = pairs(currentCamera:GetChildren())
        local v8 = v7
        local v9 = v5
        local v10 = v6

        while true do
            local v11, v12 = v9(v10, v8)
            if v11 == nil then
                break
            end
            v8 = v11

            if v12 ~= localPlayer.Character then
                for k, descendant in pairs(v12:GetDescendants()) do
                    if descendant:IsA("BasePart") or descendant:IsA("Decal") then
                        pcall(function()
                            descendant.LocalTransparencyModifier = 0
                            descendant.Transparency = 0
                        end)
                    end
                end

                v8 = v11
            end
        end
    end

    SetWorldTransparency = function(localTransparencyModifier)
        local v5, v6, v7 = pairs(currentCamera:GetChildren())
        local v8 = v7
        local v9 = v5
        local v10 = v6

        while true do
            local v11, v12 = v9(v10, v8)
            if v11 == nil then
                break
            end
            v8 = v11

            if v12 ~= localPlayer.Character then
                for k, descendant in pairs(v12:GetDescendants()) do
                    if descendant:IsA("BasePart") or descendant:IsA("Decal") then
                        pcall(function()
                            descendant.LocalTransparencyModifier = localTransparencyModifier
                            descendant.Transparency = localTransparencyModifier
                        end)
                    end
                end

                v8 = v11
            end
        end
    end

    SetCharacterTransparency = function(arg, localTransparencyModifier)
        if not arg then
            return
        end
        local v5, v6, v7 = pairs(arg:GetChildren())
        local v8 = v7
        local v9 = v5
        local v10 = v6

        while true do
            local v11, v12 = v9(v10, v8)
            if v11 == nil then
                break
            end
            v8 = v11

            if v12.Name == "Hat" then
                for k, descendant in pairs(v12:GetDescendants()) do
                    if descendant:IsA("BasePart") or descendant:IsA("Decal") then
                        pcall(function()
                            descendant.LocalTransparencyModifier = localTransparencyModifier
                            descendant.Transparency = localTransparencyModifier
                        end)
                    end
                end

                v8 = v11
            end

            if v12:IsA("BasePart") and tbl3[v12.Name] then
                pcall(function()
                    v12.LocalTransparencyModifier = localTransparencyModifier
                    v12.Transparency = localTransparencyModifier
                end)
            end

            if v12:IsA("Tool") or v12:IsA("Model") then
                local isBasePart = v12:IsA("BasePart")
                local descendants = isBasePart

                if isBasePart then
                    local tbl8 = {}
                    descendants = tbl8
                    tbl8[1] = v12
                end

                if not descendants then
                    descendants = v12:GetDescendants()
                end

                for k, descendant in pairs(descendants) do
                    if descendant:IsA("BasePart") or descendant:IsA("Decal") then
                        pcall(function()
                            descendant.LocalTransparencyModifier = localTransparencyModifier
                            descendant.Transparency = localTransparencyModifier
                        end)
                    end
                end
            end
        end
    end

    ResetCharacterTransparency = function(arg)
        if not localPlayer.Character then
            return
        end

        if arg then
            local v5, v6, v7 = pairs(localPlayer.Character:GetChildren())
            local v8 = v7
            local v9 = v5
            local v10 = v6

            while true do
                local v11, v12 = v9(v10, v8)
                if v11 == nil then
                    break
                end
                v8 = v11

                if v12.Name == "Hat" then
                    for k, descendant in pairs(v12:GetDescendants()) do
                        if descendant:IsA("BasePart") or descendant:IsA("Decal") then
                            pcall(function()
                                descendant.LocalTransparencyModifier = 1
                                descendant.Transparency = 1
                            end)
                        end
                    end

                    v8 = v11
                end

                if v12:IsA("BasePart") and tbl3[v12.Name] then
                    pcall(function()
                        v12.LocalTransparencyModifier = 1
                        v12.Transparency = 1
                    end)
                end

                if v12:IsA("Tool") or v12:IsA("Model") then
                    local isBasePart = v12:IsA("BasePart")
                    local descendants = isBasePart

                    if isBasePart then
                        local tbl8 = {}
                        descendants = tbl8
                        tbl8[1] = v12
                    end

                    if not descendants then
                        descendants = v12:GetDescendants()
                    end

                    for k, descendant in pairs(descendants) do
                        if descendant:IsA("BasePart") or descendant:IsA("Decal") then
                            pcall(function()
                                descendant.LocalTransparencyModifier = 1
                                descendant.Transparency = 1
                            end)
                        end
                    end
                end
            end
        else
            SetCharacterTransparency(localPlayer.Character, 0)
        end
    end

    local function fn51()
        pcall(function()
            localPlayer.CameraMode = Enum.CameraMode.Classic

            if _G.MX.InfinityZoom and _G.MX.InfinityZoom.Enabled then
                localPlayer.CameraMinZoomDistance = 0
                localPlayer.CameraMaxZoomDistance = math.huge
            else
                localPlayer.CameraMinZoomDistance = 0.5
                localPlayer.CameraMaxZoomDistance = 128
            end
        end)

        ResetAllTransparency()

        if localPlayer.Character then
            ResetCharacterTransparency(false)
        end
    end

    local function fn52(enabled)
        local team = localPlayer.Team
        local flag4 = team and localPlayer.Team.Name == "Killer"

        if enabled and not flag4 then
            tbl2.Enabled = false
            fn(ThirdPersonToggle, false)
            return
        end

        tbl2.Enabled = enabled

        if _G.MX.State.ThirdPersonConn then
            _G.MX.State.ThirdPersonConn:Disconnect()
            _G.MX.State.ThirdPersonConn = nil
        end

        if not enabled then
            fn51()
            return
        end

        local function apply()
            pcall(function()
                if localPlayer.CameraMode ~= Enum.CameraMode.Classic then
                    localPlayer.CameraMode = Enum.CameraMode.Classic
                end
                if localPlayer.CameraMinZoomDistance < 7 then
                    localPlayer.CameraMinZoomDistance = 7
                end
                if localPlayer.CameraMaxZoomDistance < 128 then
                    localPlayer.CameraMaxZoomDistance = 128
                end
                local char = localPlayer.Character
                local head = char and char:FindFirstChild("Head")
                if head and head.LocalTransparencyModifier ~= 0 then
                    SetCharacterTransparency(char, 0)
                end
            end)
        end

        apply()
        SetWorldTransparency(1)

        local acc = 0
        _G.MX.State.ThirdPersonConn = MXTrack(RunService.Heartbeat:Connect(function(dt)
            if not tbl2.Enabled then
                return
            end
            acc += dt
            if acc < 0.25 then
                return
            end
            acc = 0
            if localPlayer.Team and localPlayer.Team.Name == "Killer" then
                apply()
                return
            end
            tbl2.Enabled = false
            if _G.MX.State.ThirdPersonConn then
                _G.MX.State.ThirdPersonConn:Disconnect()
                _G.MX.State.ThirdPersonConn = nil
            end
            fn51()
            fn(ThirdPersonToggle, false)
        end))
    end

    MXTrack(localPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        local team = localPlayer.Team
        local name = team and localPlayer.Team.Name

        if name ~= "Killer" then
            if tbl2.Enabled then
                fn52(false)
                fn(ThirdPersonToggle, false)
            else
                fn51()
            end
        end
    end))

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        task.wait(0.8)

        if tbl2.Enabled and localPlayer.Team and localPlayer.Team.Name == "Killer" then
            localPlayer.CameraMode = Enum.CameraMode.Classic
            localPlayer.CameraMinZoomDistance = 7
            localPlayer.CameraMaxZoomDistance = 128
        else
            fn51()
        end
    end))

    setNoFall = function(enabled)
        _G.MX.NoFall.Enabled = enabled
    end



    SetupNextKillerIndicator = function()
        if _G.MX.NextKiller.IndicatorGui then
            _G.MX.NextKiller.IndicatorGui:Destroy()
        end

        _G.MX.NextKiller.IndicatorGui = Instance.new("ScreenGui")
        _G.MX.NextKiller.IndicatorGui.Name = "NextKillerIndicator"
        _G.MX.NextKiller.IndicatorGui.ResetOnSpawn = false
        _G.MX.NextKiller.IndicatorGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end

    StartNextKiller = function()
        if _G.MX.NextKiller.IndicatorGui then
            return
        end
        SetupNextKillerIndicator()

        task.spawn(function()
            while _G.MX.NextKiller.Enabled and _G.MX.NextKiller.IndicatorGui do
                local nextKillerDisplay = _G.MX.NextKiller.IndicatorGui:FindFirstChild("NextKillerDisplay")
                local v5 = nextKillerDisplay

                if not nextKillerDisplay then
                    local textLabel = Instance.new("TextLabel")
                    v5 = textLabel
                    textLabel.Name = "NextKillerDisplay"
                    textLabel.Size = UDim2.new(0, 150, 0, 22)
                    textLabel.Position = UDim2.new(0.5, 0, 0, 10)
                    textLabel.AnchorPoint = Vector2.new(0.5, 0)
                    textLabel.BackgroundTransparency = 0.15
                    textLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
                    textLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
                    textLabel.Font = Enum.Font.GothamMedium
                    textLabel.TextSize = 11
                    textLabel.RichText = true
                    textLabel.Parent = _G.MX.NextKiller.IndicatorGui
                    local uiCorner = Instance.new("UICorner")
                    uiCorner.CornerRadius = UDim.new(0, 6)
                    uiCorner.Parent = textLabel
                    local uiStroke3 = Instance.new("UIStroke")
                    uiStroke3.Thickness = 1
                    uiStroke3.Color = Color3.fromRGB(60, 60, 70)
                    uiStroke3.Transparency = 0.3
                    uiStroke3.Parent = textLabel
                end

                local players = Players:GetPlayers()

                table.sort(players, function(arg, arg2)
                    local attribute = arg:GetAttribute("AllowKiller")
                    local flag4 = attribute or false
                    local attribute2 = arg2:GetAttribute("AllowKiller")
                    local flag5 = attribute2 or false
                    if flag4 ~= flag5 then
                        return flag4
                    end
                    local attribute3 = arg:GetAttribute("KillerChance")
                    local n2 = attribute3 or 0
                    local attribute4 = arg2:GetAttribute("KillerChance")
                    local n3 = attribute4 or 0
                    local flag6 = n3 < n2
                    return flag6
                end)

                local v6 = players[1]

                if v6 then
                    local name = v6 == localPlayer and "<font color='#ff5555'>KAMU</font>" or v6.Name
                    v5.Text = "Next Killer: " .. name
                else
                    v5.Text = "Next Killer: <font color='#888888'>Waiting...</font>"
                end

                task.wait(1.5)
            end
        end)
    end

    StopNextKiller = function()
        if _G.MX.NextKiller.IndicatorGui then
            _G.MX.NextKiller.IndicatorGui:Destroy()
            _G.MX.NextKiller.IndicatorGui = nil
        end
    end

    setNextKillerDisplay = function(enabled)
        _G.MX.NextKiller.Enabled = enabled

        if enabled then
            StartNextKiller()

        else
            StopNextKiller()

        end
    end

    local function fn59()
        local mapPredictUI = CoreGui:FindFirstChild("MapPredictUI")

        if mapPredictUI then
            mapPredictUI:Destroy()
        end
    end

    local function createScreenGui()
        local mapPredictUI = CoreGui:FindFirstChild("MapPredictUI")
        if mapPredictUI then
            return mapPredictUI
        end
        local screenGui2 = Instance.new("ScreenGui")
        screenGui2.Name = "MapPredictUI"
        screenGui2.ResetOnSpawn = false
        screenGui2.IgnoreGuiInset = true
        screenGui2.Parent = CoreGui
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "NextMapDisplay"
        textLabel.Size = UDim2.new(0, 220, 0, 22)
        textLabel.Position = UDim2.new(0.5, 0, 0, 36)
        textLabel.AnchorPoint = Vector2.new(0.5, 0)
        textLabel.BackgroundTransparency = 0.15
        textLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        textLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
        textLabel.Font = Enum.Font.GothamMedium
        textLabel.TextSize = 11
        textLabel.RichText = true
        textLabel.Text = "Next Map: <font color='#888888'>Waiting...</font>"
        textLabel.Parent = screenGui2
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 6)
        uiCorner.Parent = textLabel
        local uiStroke3 = Instance.new("UIStroke")
        uiStroke3.Thickness = 1
        uiStroke3.Color = Color3.fromRGB(60, 60, 70)
        uiStroke3.Transparency = 0.3
        uiStroke3.Parent = textLabel
        return screenGui2
    end

    local function fn60()
        local map = workspace:FindFirstChild("Map")
        if not map then
            return nil
        end

        if map:FindFirstChild("random shakes") or map:FindFirstChild("SCP-173 Room") or map:FindFirstChild("SCP-205 Room") then
            return "Site 68"
        end

        if map:FindFirstChild("HooksMeat") then
            return "BLOODBATH! Club"
        end

        if map:FindFirstChild("Gate") and map.Gate:FindFirstChild("vfx") then
            return "Firelink Shrine"
        end

        if map:FindFirstChild("Bldg_Addon_RooftopUnit_A") or map:FindFirstChild("Rooftop") then
            return "Mercy Hospital Rooftop"
        end

        if map:FindFirstChild("White Armored Car") then
            return "Mount Massive Asylum"
        end

        if map:FindFirstChild("Dumbster") then
            return "The Bay Harbor"
        end

        if map:FindFirstChild("water pump") then
            return "Valdelobos Village"
        end

        if not map:FindFirstChild("LargeBoulder01") then
            return nil
        end
        return "Woodview Cabin"
    end

    setMapPrediction = function(enabled)
        _G.MX.MapPredict.Enabled = enabled

        if enabled then
            task.spawn(function()
                local v5 = nil
                local flag4 = false

                while _G.MX.MapPredict.Enabled do
                    local v6 = createScreenGui()
                    local nextMapDisplay = v6:FindFirstChild("NextMapDisplay")
                    local enabled2 = false

                    pcall(function()
                        local team = localPlayer.Team
                        local flag5 = team and localPlayer.Team.Name == "Spectator"
                        enabled2 = flag5
                    end)

                    v6.Enabled = enabled2

                    if enabled2 and nextMapDisplay then
                        local flag5 = workspace:FindFirstChild("Map") ~= nil
                        local nextMap = fn60()

                        if flag4 and not flag5 then
                            local nextMap2 = v5 or "Unknown"
                            nextMapDisplay.Text = "Next Map: " .. nextMap2
                        elseif flag5 and nextMap then
                            v5 = nextMap
                            nextMapDisplay.Text = "Next Map: " .. nextMap
                        elseif flag5 and not nextMap then
                            nextMapDisplay.Text = "Next Map: Unknown"
                        else
                            nextMapDisplay.Text = "Next Map: <font color='#888888'>Waiting...</font>"
                        end

                        flag4 = flag5
                    end

                    task.wait(0.5)
                end

                fn59()
            end)

        else
            fn59()

        end
    end

    local function fn61(arg)
        local v5 = tostring
        local str = arg or ""
        return v5(str):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    end

    local function fn62(arg)
        local v5 = tostring
        local str = arg or ""
        local match, v6 = v5(str):match("^(.+)%s+(%d+)$")
        if not match then
            return nil
        end
        local str2 = match:gsub("^%s+", ""):gsub("%s+$", "")
        if str2 == "" then
            return nil
        end

        if not ({
            head = true,
            torso = true,
            humanoid = true,
            humanoidrootpart = true,
            ["left arm"] = true,
            ["right arm"] = true,
            ["left leg"] = true,
            ["right leg"] = true,
        })[str2:lower()] then
            return str2, v6
        end

        return nil
    end

    local function fn63()
        for i, player in ipairs(Players:GetPlayers()) do
            local team = player.Team
            local name = team and player.Team.Name
            if name and name:lower():find("killer") then
                return player
            end
        end

        return nil
    end

    local function fn64(arg)
        if not arg then
            return {}
        end
        local character = arg.Character
        local v5 = character or workspace:FindFirstChild(arg.Name) or workspace:FindFirstChild(arg.DisplayName)
        if not v5 then
            return {}
        end
        local tbl8 = {}
        local tbl9 = {}

        for i, child in ipairs(v5:GetChildren()) do
            local v6, v7 = fn62(child.Name)

            if v6 and not tbl9[v6] then
                tbl9[v6] = true
                table.insert(tbl8, {Name = v6, Level = v7})
            end
        end

        table.sort(tbl8, function(arg2, arg3)
            local flag4 = tostring(arg2.Name) < tostring(arg3.Name)
            return flag4
        end)

        return tbl8
    end

    local function fn65()
        local v5 = fn63()
        local name = v5

        if v5 then
            local displayName = v5.DisplayName
            name = displayName or v5.Name
        end

        if not name then
            name = "Unknown"
        end

        local v6 = fn64(v5)
        local v7 = v6

        if #v6 == 0 then
            for i, player in ipairs(Players:GetPlayers()) do
                local v8 = fn64(player)

                if #v8 > 0 then
                    local displayName = player.DisplayName
                    local name2 = displayName or player.Name
                    name = name2
                    v7 = v8
                    break
                end
            end
        end

        local tbl8 = {
            "Killer Perks [<font color=\"rgb(255,80,80)\">" .. fn61(name) .. "</font>]",
        }

        if #v7 == 0 then
            table.insert(tbl8, "<font color=\"rgb(200,200,200)\">- Waiting for perk data...</font>")
        else
            for i = 1, math.min(#v7, 4) do
                local v8 = v7[i]
                local level = v8.Level
                local str = level and " lvl " .. tostring(v8.Level) or ""
                table.insert(tbl8, "<font color=\"rgb(200,200,200)\">- " .. fn61(v8.Name .. str) .. "</font>")
            end
        end

        return table.concat(tbl8, "\n"), #v7
    end

    local function fn66()
        if _G.MX.KillerPerks.Gui then
            pcall(function()
                _G.MX.KillerPerks.Gui:Destroy()
            end)

            _G.MX.KillerPerks.Gui = nil
        end

        if not _G.MX.KillerPerks.Enabled then
            return
        end
        local screenGui2 = Instance.new("ScreenGui")
        screenGui2.Name = "NEX_KillerPerksGui"
        screenGui2.ResetOnSpawn = false
        screenGui2.IgnoreGuiInset = true
        screenGui2.Parent = CoreGui
        local frame2 = Instance.new("Frame")
        frame2.Name = "Holder"
        frame2.Size = UDim2.new(0, 180, 0, 85)
        frame2.Position = UDim2.new(0.08, 0, 0.22, 0)
        frame2.BackgroundTransparency = 1
        frame2.Active = true
        frame2.Parent = screenGui2
        local frame3 = Instance.new("Frame")
        frame3.Name = "Panel"
        frame3.Size = UDim2.new(1, 0, 1, 0)
        frame3.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        frame3.BackgroundTransparency = 0.15
        frame3.BorderSizePixel = 0
        frame3.Parent = frame2
        Instance.new("UICorner", frame3).CornerRadius = UDim.new(0, 6)
        local uiStroke3 = Instance.new("UIStroke")
        uiStroke3.Color = Color3.fromRGB(60, 60, 70)
        uiStroke3.Thickness = 1
        uiStroke3.Transparency = 0.3
        uiStroke3.Parent = frame3
        local frame4 = Instance.new("Frame")
        frame4.Size = UDim2.new(1, 0, 0, 24)
        frame4.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        frame4.BorderSizePixel = 0
        frame4.Parent = frame3
        Instance.new("UICorner", frame4).CornerRadius = UDim.new(0, 6)
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -60, 1, 0)
        textLabel.Position = UDim2.new(0, 8, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamSemibold
        textLabel.Text = "Killer Perks Info"
        textLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
        textLabel.TextSize = 11
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = frame4

        local function createTextButton(text, arg, arg2)
            local textButton = Instance.new("TextButton")
            textButton.Size = UDim2.new(0, 26, 0, 16)
            textButton.Position = UDim2.new(1, arg, 0, 4)
            local color = arg2 or Color3.fromRGB(25, 25, 30)
            textButton.BackgroundColor3 = color
            textButton.BorderSizePixel = 0
            textButton.Font = Enum.Font.GothamMedium
            textButton.Text = text
            textButton.TextColor3 = Color3.fromRGB(200, 200, 210)
            textButton.TextSize = 9
            textButton.Parent = frame4
            Instance.new("UICorner", textButton).CornerRadius = UDim.new(0, 4)
            return textButton
        end

        local Minimize = createTextButton("Minimize", -54, Color3.fromRGB(30, 30, 40))
        local Close = createTextButton("Close", -28, Color3.fromRGB(40, 25, 25))
        local textLabel2 = Instance.new("TextLabel")
        textLabel2.Name = "KillerPerksText"
        textLabel2.Size = UDim2.new(1, -14, 1, -32)
        textLabel2.Position = UDim2.new(0, 8, 0, 28)
        textLabel2.BackgroundTransparency = 1
        textLabel2.Font = Enum.Font.GothamMedium
        textLabel2.RichText = true
        textLabel2.TextXAlignment = Enum.TextXAlignment.Left
        textLabel2.TextYAlignment = Enum.TextYAlignment.Top
        textLabel2.TextColor3 = Color3.fromRGB(220, 220, 230)
        textLabel2.TextSize = 11
        textLabel2.TextWrapped = false
        textLabel2.Parent = frame3

        MXTrack(Minimize.MouseButton1Click:Connect(function()
            local killerPerks = _G.MX.KillerPerks
            local minimized

            if _G.MX.KillerPerks.Minimized then
                minimized = false
            else
                minimized = true
            end

            killerPerks.Minimized = minimized
            local visible

            if _G.MX.KillerPerks.Minimized then
                visible = false
            else
                visible = true
            end

            textLabel2.Visible = visible
            local minimized2 = _G.MX.KillerPerks.Minimized
            local text = minimized2 and "Show" or "Minimize"
            Minimize.Text = text
            local minimized3 = _G.MX.KillerPerks.Minimized
            local udim2 = minimized3 and UDim2.new(0, 180, 0, 24) or UDim2.new(0, 180, 0, 85)
            frame2.Size = udim2
        end))

        MXTrack(Close.MouseButton1Click:Connect(function()
            _G.MX.KillerPerks.Enabled = false

            if _G.MX.KillerPerks.Gui then
                pcall(function()
                    _G.MX.KillerPerks.Gui:Destroy()
                end)

                _G.MX.KillerPerks.Gui = nil
            end

            if KillerPerksToggle then
                fn(KillerPerksToggle, false)
            end
        end))

        local flag4 = false
        local position = nil
        local position2 = nil

        MXTrack(frame2.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                flag4 = true
                position = input.Position
                position2 = frame2.Position

                MXTrack(input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        flag4 = false
                    end
                end))
            end
        end))

        MXTrack(UserInputService.InputChanged:Connect(function(input)
            if not flag4 or not position or not position2 then
                return
            end

            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local n2 = input.Position - position
            frame2.Position = UDim2.new(position2.X.Scale, position2.X.Offset + n2.X, position2.Y.Scale, position2.Y.Offset + n2.Y)
        end))

        screenGui2.Parent = CoreGui
        _G.MX.KillerPerks.Gui = screenGui2

        task.spawn(function()
            while _G.MX.KillerPerks.Enabled and _G.MX.KillerPerks.Gui do
                if not _G.MX.KillerPerks.Minimized then
                    local v5, v6 = fn65()
                    textLabel2.Text = v5
                    local n2 = math.max(2, math.min(v6 + 1, 5))
                    frame2.Size = UDim2.new(0, 180, 0, math.max(65, 28 + n2 * 15))
                end

                task.wait(1)
            end
        end)
    end

    setKillerPerksDisplay = function(enabled)
        _G.MX.KillerPerks.Enabled = enabled

        if enabled then
            fn66()

        else
            if _G.MX.KillerPerks.Gui then
                pcall(function()
                    _G.MX.KillerPerks.Gui:Destroy()
                end)

                _G.MX.KillerPerks.Gui = nil
            end

        end
    end

    local function fn67(arg)
        local humanoidRootPart = arg:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return nil
        end
        local stunRingUI = humanoidRootPart:FindFirstChild("StunRingUI")

        if stunRingUI then
            stunRingUI:Destroy()
        end

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "StunRingUI"
        billboardGui.Adornee = humanoidRootPart
        billboardGui.AlwaysOnTop = true
        billboardGui.Size = UDim2.new(0, 40, 0, 40)
        billboardGui.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
        billboardGui.ResetOnSpawn = false
        billboardGui.LightInfluence = 0
        billboardGui.Parent = humanoidRootPart
        local imageLabel = Instance.new("ImageLabel", billboardGui)
        imageLabel.Size = UDim2.new(1, 0, 1, 0)
        imageLabel.Position = UDim2.new(0, 0, 0, 0)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = "rbxassetid://129594563448607"
        imageLabel.ScaleType = Enum.ScaleType.Fit
        billboardGui.Enabled = false

        return billboardGui, task.spawn(function()
            local n2 = 0
            local currentCamera2 = workspace.CurrentCamera

            while billboardGui and billboardGui.Parent do
                if billboardGui.Enabled then
                    local rotation = (n2 + 6) % 360
                    n2 = rotation
                    imageLabel.Rotation = rotation
                    local n3 = math.clamp(math.floor(600 / (currentCamera2.CFrame.Position - humanoidRootPart.Position).Magnitude), 22, 44)
                    billboardGui.Size = UDim2.new(0, n3, 0, n3)
                end

                task.wait(0.1)
            end
        end)
    end

    local function fn68(arg)
        if not arg or _G.MX.Stun.Data[arg] then
            return
        end
        local v5, v6 = fn67(arg)
        if not v5 then
            return
        end

        local tbl8 = {
            stunRing = v5,
            stunSpinThread = v6,
            _stunTimer = nil,
            extraConns = {},
        }

        _G.MX.Stun.Data[arg] = tbl8

        local function fn69(arg2)
            if not tbl8.stunRing then
                return
            end
            tbl8.stunRing.Enabled = true

            if tbl8._stunTimer then
                task.cancel(tbl8._stunTimer)
            end

            tbl8._stunTimer = task.delay(arg2, function()
                if tbl8.stunRing then
                    tbl8.stunRing.Enabled = false
                end
            end)
        end

        local connection2 = MXTrack(arg:GetAttributeChangedSignal("IsStunned"):Connect(function()
            if arg:GetAttribute("IsStunned") == true then
                fn69(2.2)
            end
        end))

        local connection3 = MXTrack(arg:GetAttributeChangedSignal("Immobile"):Connect(function()
            if arg:GetAttribute("Immobile") == true then
                fn69(2.2)
            end
        end))

        table.insert(tbl8.extraConns, connection2)
        table.insert(tbl8.extraConns, connection3)
    end

    local function fn69(arg)
        local v5 = _G.MX.Stun.Data[arg]

        if v5 then
            if v5._stunTimer then
                task.cancel(v5._stunTimer)
            end

            if v5.stunSpinThread then
                task.cancel(v5.stunSpinThread)
            end

            if v5.stunRing then
                v5.stunRing:Destroy()
            end

            if v5.extraConns then
                for i, extraConn in ipairs(v5.extraConns) do
                    pcall(function()
                        extraConn:Disconnect()
                    end)
                end
            end

            _G.MX.Stun.Data[arg] = nil
        end
    end

    local function fn70()
        if not _G.MX.Stun.Enabled then
            return
        end

        for i, player in ipairs(Players:GetPlayers()) do
            if IsKiller(player) and player.Character then
                fn68(player.Character)
            end
        end
    end

    MXTrack(Players.PlayerAdded:Connect(function(player)
        if not _G.MX.Stun.Enabled then
            return
        end

        MXTrack(player.CharacterAdded:Connect(function(character)
            task.wait(0.5)

            if _G.MX.Stun.Enabled and IsKiller(player) then
                fn68(character)
            end
        end))

        task.wait(0.5)

        if _G.MX.Stun.Enabled and IsKiller(player) and player.Character then
            fn68(player.Character)
        end
    end))

    MXTrack(Players.PlayerAdded:Connect(function(player)
        MXTrack(player:GetPropertyChangedSignal("Team"):Connect(function()
            if not _G.MX.Stun.Enabled then
                return
            end
            task.wait(0.5)

            if IsKiller(player) and player.Character then
                fn69(player.Character)
                task.wait(0.1)
                fn68(player.Character)
            end
        end))
    end))

    MXTrack(Players.PlayerAdded:Connect(function(player)
        task.wait(0.5)

        if _G.MX.Stun.Enabled then
            fn70()
        end
    end))

    MXTrack(localPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)

        if _G.MX.Stun.Enabled then
            fn70()
        end
    end))

    task.spawn(function()
        local v5, v6, v7, v8, v9, v10, humanoidRootPart, n2
        n2 = 1

        while true do
            if n2 == 1 then
                if _G.MX.ScriptAlive then
                    n2 = 2
                else
                    n2 = 9
                end
            elseif n2 == 2 then
                task.wait(5)

                if _G.MX.ScriptAlive then
                    n2 = 3
                else
                    n2 = 9
                end
            elseif n2 == 3 then
                if _G.MX.Stun.Enabled then
                    n2 = 4
                else
                    n2 = 1
                end
            elseif n2 == 4 then
                v5, v6, v7 = ipairs(Players:GetPlayers())
                v8 = v7
                n2 = 5
            elseif n2 == 5 then
                v9, v10 = v5(v6, v8)

                if v9 == nil then
                    n2 = 1
                else
                    n2 = 6
                end
            elseif n2 == 6 then
                v8 = v9

                if IsKiller(v10) and v10.Character then
                    n2 = 7
                else
                    n2 = 5
                end
            elseif n2 == 7 then
                humanoidRootPart = v10.Character:FindFirstChild("HumanoidRootPart")

                if humanoidRootPart and not humanoidRootPart:FindFirstChild("StunRingUI") then
                    n2 = 8
                else
                    n2 = 5
                end
            elseif n2 == 8 then
                fn68(v10.Character)
                n2 = 5
            elseif n2 == 9 then
                return
            end
        end
    end)

    setStunIndicator = function(enabled)
        _G.MX.Stun.Enabled = enabled

        if enabled then
            for k in pairs(_G.MX.Stun.Data) do
                fn69(k)
            end

            _G.MX.Stun.Data = {}
            task.wait(0.5)
            fn70()

        else
            for k in pairs(_G.MX.Stun.Data) do
                fn69(k)
            end

            _G.MX.Stun.Data = {}

        end
    end

    local function buildSection(page, name, icon)
        local section = page:CreateSection(name, icon)

        pcall(function()
            section:_gb()
        end)
        return section
    end

    MainTab = v:CreateTab("Main", false, false)
    M_Page = MainTab:CreatePage("Main")
    SurvivorTab = v:CreateTab("Survivor", false, false)
    S_Page = SurvivorTab:CreatePage("Survivor")
    KillerTab = v:CreateTab("Killer", false, false)
    K_Page = KillerTab:CreatePage("Killer")
    local TrapPage = S_Page

    MovementCard = buildSection(M_Page, "Movement", "person-standing")
    CameraCard = buildSection(M_Page, "Camera Settings", "camera")
    StreamerCard = buildSection(M_Page, "Streamer Mode", "eye-off")
    UtilityCard = buildSection(M_Page, "Players Utility", "user-cog")
    PumpkinCard = buildSection(S_Page, "Pumpkin", "ghost")
    CrosshairBox = buildSection(M_Page, "Crosshair", "crosshair")

    GenCard = buildSection(S_Page, "Generator", "cpu")
    VaultCard = buildSection(S_Page, "Vault", "wind")
    AbilityCard = buildSection(S_Page, "Survivor Ability", "flame")
    FakePerksCard = buildSection(S_Page, "Fake Perks", "star")
    SurvivorHealCard = buildSection(S_Page, "Heal", "heart-pulse")
    PistolSection = buildSection(S_Page, "TOF", "target")

    KillerAimbotCard = buildSection(K_Page, "Melee Aimbot", "swords")
    VeilCard = buildSection(K_Page, "Silent Aim Killer", "scan-line")
    KillerAbilityCard = buildSection(K_Page, "Killer Ability", "flame")

    local v7 = MovementCard:AddToggle("Auto Run PC", false, function(pc)
        _G.MX.AutoRun.PC = pc

        if pc then
            task.spawn(function()
                while _G.MX.AutoRun.PC do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, localPlayer:GetMouse())
                    task.wait(0.1)
                end
            end)
        else
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, localPlayer:GetMouse())
        end
    end, {Flag = "AutoRunPc"})

    local v8 = MovementCard:AddToggle("Auto Run Mobile", false, function(mobile)
        _G.MX.AutoRun.Mobile = mobile

        if mobile then
            fn5()
        else
            fn6()
        end
    end, {Flag = "AutoRunMobile"})

    local v9 = MovementCard:AddToggle("Speed Boost", false, function(enabled)
        _G.MX.Speed.Enabled = enabled
    end, {Flag = "SpeedBoost"})

    do
        local slowEvents = {}
        local disabled = {}
        local function collectSlowEvents()
            local mech = ReplicatedStorage:FindFirstChild("Remotes")
            mech = mech and mech:FindFirstChild("Mechanics")
            if not mech then
                return
            end
            local serverSlow = mech:FindFirstChild("Slowserver")
            local localSlow = mech:FindFirstChild("Slow")
            slowEvents = {}
            if serverSlow and serverSlow:IsA("RemoteEvent") then
                slowEvents[#slowEvents + 1] = serverSlow.OnClientEvent
            end
            if localSlow and localSlow:IsA("BindableEvent") then
                slowEvents[#slowEvents + 1] = localSlow.Event
            end
        end

        local function setSlowHandlers(block)
            if type(getconnections) ~= "function" then
                return
            end
            for _, signal in ipairs(slowEvents) do
                local ok, list = pcall(getconnections, signal)
                if ok and type(list) == "table" then
                    for _, conn in ipairs(list) do
                        if block and not disabled[conn] then
                            if pcall(function() conn:Disable() end) then
                                disabled[conn] = true
                            end
                        elseif not block and disabled[conn] then
                            pcall(function() conn:Enable() end)
                            disabled[conn] = nil
                        end
                    end
                end
            end
        end

        local noteConns = {}
        local function watchSlow()
            for _, c in ipairs(noteConns) do
                pcall(function() c:Disconnect() end)
            end
            noteConns = {}
            collectSlowEvents()
            for _, signal in ipairs(slowEvents) do
                local okc, conn = pcall(function()
                    return signal:Connect(function(speed, duration)
                        if _G.MX.SurvivorNoSlowdown then
                            _G.MX.SlowUntil = os.clock() + (tonumber(duration) or 1) + 0.3
                        end
                    end)
                end)
                if okc and conn then
                    noteConns[#noteConns + 1] = conn
                end
            end
        end

        task.spawn(function()
            while not lib.API.Unloaded do
                if _G.MX.SurvivorNoSlowdown then
                    if #slowEvents == 0 then
                        watchSlow()
                    end
                    setSlowHandlers(true)
                end
                task.wait(1)
            end
        end)
        lib.API.Track(function()
            setSlowHandlers(false)
            for _, c in ipairs(noteConns) do
                pcall(function() c:Disconnect() end)
            end
        end)

        MovementCard:AddToggle("No Slowdown", false, function(on)
            _G.MX.SurvivorNoSlowdown = on
            if on then
                watchSlow()
                setSlowHandlers(true)
            else
                _G.MX.SlowUntil = 0
                setSlowHandlers(false)
            end
        end, {Flag = "SurvivorNoSlowdown"})
    end

    MovementCard:AddSlider("SpeedAmount", 0.1, 1.5, 0.1, function(value)
        _G.MX.Speed.Value = value
    end, {Increment = 0.1, Flag = "SpeedAmount"})


    local ExtraCard = buildSection(M_Page, "Emote", "smile")
    MX.run("Emote", {ExtraCard = ExtraCard, lib = lib, localPlayer = localPlayer})


    local v19 = CameraCard:AddToggle("Infinity Zoom Out", false, function(arg)
        fn44(arg)
    end, {Flag = "InfinityZoom"})

    local v20 = CameraCard:AddToggle("Camera FOV", false, function(arg)
        fn45(arg)
    end, {Flag = "CameraFov"})

    local v23 = StreamerCard:AddToggle("Streamer Mode", false, function(arg)
        fn42(arg)
    end, {Flag = "StreamerMode"})

    local v27 = UtilityCard:AddToggle("Moonwalk GUI", false, function(arg)
        if arg then
            if not _G.MX.Moonwalk.Gui then
                CreateMoonwalkGUI()
            end

            _G.MX.Moonwalk.Gui.Enabled = true
            _G.MX.Moonwalk.GuiVisible = true
            UpdateMoonwalkGUI(_G.MX.Moonwalk.Enabled)

        else
            if _G.MX.Moonwalk.Enabled then
                StopMoonwalk()

                if MoonwalkPCToggle then
                    fn(MoonwalkPCToggle, false)
                end
            end

            if _G.MX.Moonwalk.Gui then
                _G.MX.Moonwalk.Gui.Enabled = false
                _G.MX.Moonwalk.GuiVisible = false
            end

        end
    end, {Flag = "MoonwalkGui"})

    local v28 = UtilityCard:AddToggle("Moonwalk PC", false, function(arg)
        if arg then
            StartMoonwalk()
        else
            StopMoonwalk()
        end

        UpdateMoonwalkGUI(_G.MX.Moonwalk.Enabled)
    end, {Flag = "MoonwalkPC"})

    MoonwalkPCToggle = v28

    _G.MX.Act = {owner = nil, untilT = 0}
    function _G.MX.Act.try(name, secs)
        local A = _G.MX.Act
        if A.owner and A.owner ~= name and os.clock() < A.untilT then
            return false
        end
        A.owner, A.untilT = name, os.clock() + (secs or 30)
        return true
    end
    function _G.MX.Act.done(name)
        if _G.MX.Act.owner == name then
            _G.MX.Act.owner = nil
        end
    end

    _G.MX.Walker = (function()
        local PathfindingService = game:GetService("PathfindingService")
        local W = {}

        local function me()
            local char = localPlayer.Character
            return char, char and char:FindFirstChildOfClass("Humanoid"), char and char:FindFirstChild("HumanoidRootPart")
        end

        local function groundPoint(pos)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {localPlayer.Character}
            local hit = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -40, 0), params)
            return hit and hit.Position or pos
        end

        local pathFolder
        local function clearPath()
            if pathFolder then
                pathFolder:Destroy()
                pathFolder = nil
            end
        end
        local function drawPath(waypoints)
            clearPath()
            if _G.MX.PathVisual == false then return end
            pcall(function()
                pathFolder = Instance.new("Folder")
                pathFolder.Name = "MXHUB_Path"
                pathFolder.Parent = workspace
                local prev
                for i, wp in ipairs(waypoints) do
                    local pos = wp.Position + Vector3.new(0, 0.35, 0)
                    local isJump = wp.Action == Enum.PathWaypointAction.Jump
                    local dot = Instance.new("Part")
                    dot.Anchored, dot.CanCollide, dot.CanTouch, dot.CanQuery, dot.CastShadow = true, false, false, false, false
                    dot.Shape = Enum.PartType.Ball
                    dot.Material = Enum.Material.Neon
                    dot.Color = isJump and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(120, 200, 255)
                    dot.Size = Vector3.one * (isJump and 0.9 or 0.5)
                    dot.Transparency = 0.25
                    dot.Position = pos
                    dot.Parent = pathFolder
                    if prev then
                        local len = (pos - prev).Magnitude
                        if len > 0.05 then
                            local seg = Instance.new("Part")
                            seg.Anchored, seg.CanCollide, seg.CanTouch, seg.CanQuery, seg.CastShadow = true, false, false, false, false
                            seg.Material = Enum.Material.Neon
                            seg.Color = Color3.fromRGB(120, 200, 255)
                            seg.Transparency = 0.55
                            seg.Size = Vector3.new(0.14, 0.14, len)
                            seg.CFrame = CFrame.lookAt((pos + prev) / 2, pos)
                            seg.Parent = pathFolder
                        end
                    end
                    prev = pos
                end
            end)
        end
        lib.API.Track(clearPath)

        function W.walkTo(goal, opts)
            opts = opts or {}
            local stop = opts.stop or 3
            local timeout = opts.timeout or 45
            local active = opts.active or function()
                return true
            end
            local started = os.clock()
            local replans = 0
            local agent = {AgentRadius = 3, AgentHeight = 5.5, AgentCanJump = true, WaypointSpacing = 4}

            while os.clock() - started < timeout do
                local _, hum, root = me()
                if not (hum and root) or hum.Health <= 0 then
                    return false, "dead"
                end
                if not active() then
                    return false, "inactive"
                end
                if (root.Position - goal).Magnitude <= stop then
                    return true
                end

                local path = PathfindingService:CreatePath(agent)
                local okCompute = pcall(function()
                    path:ComputeAsync(root.Position, groundPoint(goal))
                end)
                if not okCompute or path.Status ~= Enum.PathStatus.Success then
                    replans += 1
                    if replans > 3 then
                        return false, "nopath"
                    end
                    task.wait(0.4)
                    continue
                end

                local blocked = false
                local currentWaypoint = 2
                local blockedConn = MXTrack(path.Blocked:Connect(function(blockedIndex)
                    if blockedIndex >= currentWaypoint then
                        blocked = true
                    end
                end))
                local waypoints = path:GetWaypoints()
                drawPath(waypoints)
                local arrived, stuck = false, false

                for i = 2, #waypoints do
                    currentWaypoint = i
                    local wp = waypoints[i]
                    if wp.Action == Enum.PathWaypointAction.Jump then
                        hum.Jump = true
                    end
                    hum:MoveTo(wp.Position)

                    local segStart = os.clock()
                    local lastPos, lastCheck = root.Position, os.clock()
                    while true do
                        task.wait(0.05)
                        local _, h2, r2 = me()
                        if not (h2 and r2) or h2.Health <= 0 or not active() or os.clock() - started > timeout then
                            blockedConn:Disconnect()
                            clearPath()
                            return false, "inactive"
                        end
                        if (r2.Position - goal).Magnitude <= stop then
                            arrived = true
                            break
                        end
                        local dx, dz = r2.Position.X - wp.Position.X, r2.Position.Z - wp.Position.Z
                        if math.sqrt(dx * dx + dz * dz) < 2.5 and math.abs(r2.Position.Y - wp.Position.Y) < 6 then
                            break
                        end
                        if blocked then
                            break
                        end
                        local now = os.clock()
                        if now - lastCheck >= 0.7 then
                            if (r2.Position - lastPos).Magnitude < 0.8 then
                                stuck = true
                                break
                            end
                            lastPos, lastCheck = r2.Position, now
                        end
                        if now - segStart > 4 then
                            stuck = true
                            break
                        end
                    end
                    if arrived or stuck or blocked then
                        break
                    end
                end
                blockedConn:Disconnect()
                clearPath()

                local _, hum2, root2 = me()
                if arrived or (root2 and (root2.Position - goal).Magnitude <= stop) then
                    if hum2 and root2 then
                        hum2:MoveTo(root2.Position)
                    end
                    return true
                end
                if stuck or blocked then
                    replans += 1
                    if stuck and hum2 then
                        hum2.Jump = true
                    end
                    if replans > 6 then
                        return false, "stuck"
                    end
                    task.wait(0.2)
                end
            end
            return false, "timeout"
        end

        function W.face(point)
            local _, hum, root = me()
            if not (hum and root) then
                return
            end
            local look = CFrame.lookAt(root.Position, Vector3.new(point.X, root.Position.Y, point.Z))
            hum.AutoRotate = false
            game:GetService("TweenService"):Create(root, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = look}):Play()
            task.delay(1.2, function()
                if hum.Parent then
                    hum.AutoRotate = true
                end
            end)
        end

        return W
    end)()

MX.run("Pumpkin", {CollectionService = CollectionService, PumpkinCard = PumpkinCard, ReplicatedStorage = ReplicatedStorage, localPlayer = localPlayer})

    CrosshairBox:AddToggle("Enable Crosshair", false, function(enabled)
        _G.MX.Crosshair.Enabled = enabled

        if not enabled then
            ClearCrosshair()
        end

    end, {Flag = "Crosshair"})

    CrosshairBox:AddDropdown("Mode", {"Plus", "Dot", "Circle"}, false, function(style)
        _G.MX.Crosshair.Style = style
        ClearCrosshair()
        _G.MX.CrosshairCreated = false
    end, {Flag = "CrosshairStyle"})

    CrosshairBox:AddSlider("Size", 2, 30, 8, function(size)
        _G.MX.Crosshair.Size = size
    end, {Increment = 1, Flag = "CrosshairSize"})

    CrosshairBox:AddSlider("Thickness", 1, 5, 2, function(thickness)
        _G.MX.Crosshair.Thickness = thickness
    end, {Increment = 1, Flag = "CrosshairThickness"})

    CrosshairBox:AddSlider("Position X", -100, 100, 0, function(offsetX)
        _G.MX.Crosshair.OffsetX = offsetX
    end, {Increment = 1, Flag = "CrosshairX"})

    CrosshairBox:AddSlider("Position Y", -100, 100, 0, function(offsetY)
        _G.MX.Crosshair.OffsetY = offsetY
    end, {Increment = 1, Flag = "CrosshairY"})

    GenCard:AddToggle("Auto Skill Check", false, function(skillCheck)
        _G.MX.Auto.SkillCheck = skillCheck

        if skillCheck then
            fn7()
        elseif _G.MX.Connections.SkillHeartbeat then
            _G.MX.Connections.SkillHeartbeat:Disconnect()
            _G.MX.Connections.SkillHeartbeat = nil
        end
    end, {Flag = "AutoSkillCheck"})

    local v5 = VaultCard:AddToggle("Auto Vault", false, function(autoVaultEnabled)
        _G.MX.autoVaultEnabled = autoVaultEnabled
    end, {Flag = "AutoVault"})

    local v6 = VaultCard:AddToggle("Auto Pallet Slide", false, function(autoPalletSlideEnabled)
        _G.MX.autoPalletSlideEnabled = autoPalletSlideEnabled
    end, {Flag = "AutoPalletSlide"})

    local v13 = FakePerksCard:AddToggle("Quick Recovery", false, function(arg)
        ToggleQuickRecovery(arg)
    end, {Flag = "FakeQR"})

    local v14 = FakePerksCard:AddToggle("Perfect Landing", false, function(arg)
        TogglePerfectLanding(arg)
    end, {Flag = "FakePL"})

    local Flowstate = FakePerksCard:AddToggle("Flowstate", false, function(arg)
        ToggleFlowstate(arg)
    end, {Flag = "FakeFS"})

    FS_Toggle = Flowstate

    local v15 = FakePerksCard:AddToggle("Adrenaline Rush", false, function(arg)
        SetupFakeAdrenalineRush(arg)
    end, {Flag = "FakeAR"})

    local TrapBot = {token = 0, running = false, holding = false}

    TrapCard = TrapPage:CreateSection("Trap", "alert-triangle")


    pcall(function() TrapCard:_gb() end)

    task.spawn(function()
        local r = ReplicatedStorage:WaitForChild("Remotes", 15)
        local k = r and r:WaitForChild("Killers", 5)
        local b = k and k:WaitForChild("Butcher", 5)
        local ft = b and b:WaitForChild("FreeTrap", 5)
        if ft then
            MXTrack(ft.OnClientEvent:Connect(function(...)
                warn("[MXHUB] FreeTrap server ->", ...)
            end))
        end
    end)

    local function sendBind(attr, default, down)
        local raw = localPlayer:GetAttribute(attr)
        if typeof(raw) ~= "string" or raw == "" then
            raw = default
        end
        local mouse = raw:match("^MouseButton(%d)$")
        if mouse then
            local cam = workspace.CurrentCamera
            VirtualInputManager:SendMouseButtonEvent(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2, tonumber(mouse) - 1, down, game, 0)
            return
        end
        local okKey, keyCode = pcall(function()
            return Enum.KeyCode[raw]
        end)
        if okKey and keyCode then
            VirtualInputManager:SendKeyEvent(down, keyCode, false, game)
        end
    end

    local function isTrapped()
        local character = localPlayer.Character
        return character ~= nil and character:GetAttribute("Trapped") == true
    end

    local function freeingNow()
        local gui = playerGui:FindFirstChild("ProgressPromptGui")
        local frame = gui and gui:FindFirstChild("Frame")
        local label = frame and frame:FindFirstChild("TextLabel")
        return frame ~= nil and frame.Visible and label ~= nil and label.Text == "FREEING"
    end

    local function readCheck()
        local gui = playerGui:FindFirstChild("SkillCheckPromptGui")
        local check = gui and gui:FindFirstChild("Check")
        if not (check and check.Visible) then
            return nil
        end
        local line = check:FindFirstChild("Line")
        local perfectObj = check:FindFirstChild("TrapPerfect")
        local goalObj = check:FindFirstChild("TrapGoal")
        local obj
        local perfectOnly = false
        if perfectObj and perfectObj.Visible then
            obj, perfectOnly = perfectObj, true
        elseif goalObj and goalObj.Visible then
            obj = goalObj
        end
        if not (line and obj) then
            return nil
        end
        return line, obj, perfectOnly
    end

    local function tapSkillKey()
        task.spawn(function()
            sendBind("kb_skillcheck", "Space", true)
            RunService.Heartbeat:Wait()
            sendBind("kb_skillcheck", "Space", false)
        end)
    end

    local function runTrapBot()
        if TrapBot.running then
            return
        end
        TrapBot.running = true
        TrapBot.token += 1
        local token = TrapBot.token

        local function alive()
            return _G.MX.Auto.AntiTrap and TrapBot.token == token and isTrapped()
        end

        task.spawn(function()
            pcall(function()
                local clickhold = localPlayer:GetAttribute("clickhold") == true
                local lastTry = -10
                local lastFreeingSeen = -10
                local seenThisTry = false
                local prevRel, prevTime
                local cycleGoal, pressed, cycleMode

                while alive() do
                    local now = os.clock()

                    local freeing = freeingNow()
                    if freeing then
                        lastFreeingSeen = now
                        seenThisTry = true
                    elseif seenThisTry and TrapBot.holding and now - lastFreeingSeen > 0.4 then

                        sendBind("kb_interact", "MouseButton1", false)
                        TrapBot.holding = false
                        seenThisTry = false
                    end

                    local instantMode = _G.MX.Auto.TrapMode == "Instant"
                    if not freeing and now - lastTry > (instantMode and 0.8 or 1.6) and now - lastFreeingSeen > (instantMode and 1.5 or 3.0) then
                        lastTry = now
                        seenThisTry = false

                        task.wait(instantMode and 0 or 0.35)
                        if not alive() then
                            break
                        end
                        if TrapBot.holding then
                            sendBind("kb_interact", "MouseButton1", false)
                            TrapBot.holding = false
                        end
                        sendBind("kb_interact", "MouseButton1", true)
                        if clickhold then
                            task.wait(0.05)
                            sendBind("kb_interact", "MouseButton1", false)
                        else
                            TrapBot.holding = true
                        end
                    end

                    local line, obj, perfectOnly = readCheck()
                    if line then
                        local goalRot = obj.Rotation
                        if cycleGoal == nil or math.abs(goalRot - cycleGoal) > 0.5 then
                            cycleGoal, pressed, prevRel, prevTime = goalRot, false, nil, nil
                            local mode = _G.MX.Auto.TrapMode
                            if mode == "Random" then
                                mode = math.random() < 0.5 and "Perfect" or "Normal"
                            end
                            cycleMode = mode
                        end

                        local rel = (line.Rotation - goalRot) % 360
                        local perfectWanted = perfectOnly or cycleMode ~= "Normal"

                        if not pressed then

                            local from, to, centre = 96, 140, 109
                            if not perfectWanted then
                                from, to, centre = 119, 137, 128
                            end

                            if cycleMode == "Instant" or (rel >= from and rel <= to) then
                                line.Rotation = goalRot + centre
                                pressed = true
                                tapSkillKey()
                            end
                        end
                        prevRel, prevTime = rel, now
                    else
                        cycleGoal = nil
                    end

                    RunService.Heartbeat:Wait()
                end
            end)
            if TrapBot.holding then
                sendBind("kb_interact", "MouseButton1", false)
                TrapBot.holding = false
            end
            task.wait(0.6)
            TrapBot.running = false
        end)
    end

    task.spawn(function()
        while _G.MX.ScriptAlive do
            task.wait(_G.MX.Auto.TrapMode == "Instant" and 0.03 or 0.2)
            if _G.MX.Auto.AntiTrap and not TrapBot.running and isTrapped() then
                runTrapBot()
            end
        end
    end)

    TrapCard:AddToggle("Auto Skill Check", false, function(antiTrap)
        _G.MX.Auto.AntiTrap = antiTrap
        if not antiTrap then
            TrapBot.token += 1
        end
    end, {Flag = "AntiTrapSkillCheck"})

    TrapCard:AddDropdown("Mode", {"Perfect", "Normal", "Random", "Instant"}, false, function(mode)
        _G.MX.Auto.TrapMode = mode
    end, {Flag = "TrapCheckMode"})

MX.run("AutoDisarm", {CollectionService = CollectionService, GetRole = function(...) return GetRole(...) end, ReplicatedStorage = ReplicatedStorage, TrapCard = TrapCard, lib = lib, localPlayer = localPlayer})

    GenCard:AddDropdown("Mode", {"Legit", "Normal", "Random"}, false, function(skillCheckMode)
        _G.MX.Auto.SkillCheckMode = skillCheckMode
        _G.MX.State.RandomMode_IsNormal = false
    end, {Flag = "SkillCheckMode"})

MX.run("AssistFree", {CollectionService = CollectionService, Players = Players, ReplicatedStorage = ReplicatedStorage, TrapCard = TrapCard, localPlayer = localPlayer})

MX.run("TrapESP", {CollectionService = CollectionService, localPlayer = localPlayer})

MX.run("ToF", {CollectionService = CollectionService, CoreGui = CoreGui, IsDowned = function(...) return IsDowned(...) end, PistolSection = PistolSection, Players = Players, ReplicatedStorage = ReplicatedStorage, RunService = RunService, UserInputService = UserInputService, localPlayer = localPlayer, playerGui = playerGui})
MX.run("SpearPreview", {Card = VeilCard, CollectionService = CollectionService, Players = Players, RunService = RunService, localPlayer = localPlayer, lib = lib})
MX.run("Tracker", {lib = lib, Players = Players, ReplicatedStorage = ReplicatedStorage, RunService = RunService, localPlayer = localPlayer})
    AbilityCard:AddToggle("Auto Crouch", false, function(autoCrouch)
        _G.MX.ParryConfig.AutoCrouch = autoCrouch
    end, {Flag = "AutoCrouch"})
end

local v3 = AbilityCard:AddToggle("No Fall Damage", false, function(arg)
    setNoFall(arg)
end, {Flag = "NoFallDamage"})

MX.run("Heal", {CollectionService = CollectionService, Players = Players, ReplicatedStorage = ReplicatedStorage, SurvivorHealCard = SurvivorHealCard, localPlayer = localPlayer})

local v17 = KillerAimbotCard:AddToggle("Melee Aimbot", false, function(killerAimbotEnabled)
    _G.MX.Config.Killer_Aimbot_Enabled = killerAimbotEnabled

    if not killerAimbotEnabled and _G.MX.killerAimbotHighlight then
        _G.MX.killerAimbotHighlight.Parent = nil
    end

end)

_G.MX.AimConfig.Veil_Direct = true

local v19 = VeilCard:AddToggle("Silent Aim Veil", false, function(aimSilentVeilV2)
    _G.MX.AimConfig.Aim_SilentVeilV2 = aimSilentVeilV2
end)

local v21 = KillerAbilityCard:AddToggle("Anti Blind", false, function(antiBlindEnabled)
    _G.MX.AntiBlindEnabled = antiBlindEnabled
end, {Flag = "AntiBlind"})

local v22 = KillerAbilityCard:AddToggle("Anti Parry", false, function(arg)
    ToggleCounterParry(arg)
end)

CounterParryToggle = v22

local v23 = KillerAbilityCard:AddToggle("Infinite Lunge", false, function(arg)
    if arg then
        EnableInfiniteLunge()
    else
        DisableInfiniteLunge()
    end
end, {Flag = "InfiniteLunge"})

local v25 = KillerAbilityCard:AddToggle("No Slowdown Killer", false, function(noSlowdownEnabled)
    _G.MX.NoSlowdownEnabled = noSlowdownEnabled

    if noSlowdownEnabled then
        local character = localPlayer.Character

        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end

    else
    end
end, {Flag = "NoSlowdown"})

MX.run("Perks", {K_Page = K_Page, ReplicatedStorage = ReplicatedStorage, S_Page = S_Page, localPlayer = localPlayer})

do
    local PS = S_Page:CreateSection("Auto Parry", "swords")
    PS:AddToggle("Auto Parry", false, function(on)
        local cfg = _G.MX.ParryConfig
        cfg.AutoParry = on
        _G.MX.AutoParryCustom.IsActive = on
    end, {Flag = "AutoParry"})
    PS:AddToggle("Aggressive Mode", false, function(on)
        _G.MX.ParryConfig.ParryAggressive = on
    end, {Flag = "AutoParryAggressive"})
    PS:AddSlider("Parry Radius", 5, 25, 15, function(value)
        _G.MX.ParryConfig.ParryRadius = value
    end, {Increment = 1, Flag = "AutoParryRadius"})
end

MX.run("KillerAbilities", {CollectionService = CollectionService, IsDowned = function(...) return IsDowned(...) end, KillerAbilityCard = KillerAbilityCard, SilentCard = VeilCard, Players = Players, ReplicatedStorage = ReplicatedStorage, UserInputService = UserInputService, localPlayer = localPlayer})

local Visual = v:CreateTab("Visual", false, false)
EspTab = Visual
local esp = EspTab:CreatePage("ESP")
EspPage = esp
local v35 = EspPage:CreateSection("ESP Settings", "focus")
EspMasterCard = v35

EspMasterCard:AddToggle("Enable ESP", false, function(master)
    _G.MX.ESPConfig.Master = master
    if _G.MX.KillerExtras then
        pcall(_G.MX.KillerExtras, master and _G.MX.ESPConfig.Killer)
    end

    if master then
        ForceRefreshMap()
    else
        ClearAllESP()
    end
end, {Flag = "EnableEspMaster"})

EspMasterCard:AddSlider("ESP Max Distance", 100, 5000, 1000, function(maxDistance)
    _G.MX.ESPConfig.MaxDistance = maxDistance
end, {Increment = 100, Flag = "EspMaxDistance"})

EspMasterCard:AddCheckbox("Player ESP", false, function(player)
    _G.MX.ESPConfig.Player = player

    if _G.MX.ESPConfig.Master then
        if player then
            ScanMapESP()
        else
            ClearESP("Player")
        end
    end
end, {Flag = "PlayerEsp"})

EspMasterCard:AddCheckbox("Killer ESP", false, function(killer)
    _G.MX.ESPConfig.Killer = killer
    if _G.MX.KillerExtras then
        pcall(_G.MX.KillerExtras, killer and _G.MX.ESPConfig.Master)
    end

    if _G.MX.ESPConfig.Master then
        if killer then
            ScanMapESP()
        else
            ClearESP("Killer")
        end
    end
end, {Flag = "KillerEsp"})

EspMasterCard:AddCheckbox("ESP Name", false, function(name)
    _G.MX.ESPConfig.Name = name

    if _G.MX.ESPConfig.Master then
        ScanMapESP()
    else
        ClearAllESP()
    end
end, {Flag = "EspName"})

EspMasterCard:AddCheckbox("ESP Distance", false, function(distance)
    _G.MX.ESPConfig.Distance = distance

    if _G.MX.ESPConfig.Master then
        UpdatePlayerESP()
    end
end, {Flag = "EspDistancw"})

EspMasterCard:AddCheckbox("ESP Status", false, function(status)
    _G.MX.ESPConfig.Status = status

    if _G.MX.ESPConfig.Master then
        UpdatePlayerESP()
    end
end, {Flag = "EspStatus"})

EspMasterCard:AddCheckbox("ESP Item Icon", false, function(itemIcon)
    _G.MX.ESPConfig.ItemIcon = itemIcon

    if _G.MX.ESPConfig.Master then
        UpdatePlayerESP()
    end
end, {Flag = "EspItemIcon"})

EspMasterCard:AddCheckbox("ESP Killer Warn", false, function(killerWarn)
    _G.MX.ESPConfig.KillerWarn = killerWarn

    if not killerWarn then
        local character = localPlayer.Character
        local humanoidRootPart = character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

        if humanoidRootPart and humanoidRootPart:FindFirstChild("KillerWarn") then
            humanoidRootPart.KillerWarn:Destroy()
        end
    end
end, {Flag = "KillerWarn"})

EspMasterCard:AddCheckbox("ESP Outline Mode", false, function(outline)
    _G.MX.ESPConfig.Outline = outline
end, {Flag = "EspOutlineMode"})

EspMasterCard:AddCheckbox("ESP Hook Count", false, function(hookCount)
    _G.MX.ESPConfig.HookCount = hookCount

    if hookCount then
        UpdateHookData()
        UpdatePlayerESP()
        UpdateHookUICounter()
    else
        ClearHookESP()
        ClearHookUICounter()
        UpdatePlayerESP()
    end
end, {Flag = "EspHookCount"})

MX.run("KillerESP", {EspMasterCard = EspMasterCard, Players = Players, RunService = RunService, lib = lib, localPlayer = localPlayer})
local v46 = EspPage:CreateSection("World Effects", "flashlight")
PerfCard = v46

PerfCard:AddToggle("Full Bright", false, function(fullBright)
    _G.MX.FullBright = fullBright
    local Lighting = game:GetService("Lighting")
    if not Lighting then
        return
    end

    if fullBright then
        StartLightingGuard()
        ReapplyPerformanceDelayed()
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        StopLightingGuard()

    end
end, {Flag = "FullBright"})

PerfCard:AddSlider("Time Of Day", 0, 24, 14, function(timeOfDayValue)
    _G.MX.TimeOfDayValue = timeOfDayValue

    if _G.MX.FullBright then
        local Lighting = game:GetService("Lighting")

        if Lighting then
            Lighting.ClockTime = timeOfDayValue
        end
    end
end, {Increment = 1, Flag = "TimeOfDay"})

PerfCard:AddToggle("No Fog", false, function(noFog)
    _G.MX.NoFog = noFog

    if noFog then
        StartLightingGuard()
        ApplyNoFog()

    else
        local Lighting = game:GetService("Lighting")

        if Lighting then
            Lighting.FogStart = 0
            Lighting.FogEnd = 1000
            local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

            if atmosphere then
                atmosphere.Density = 0.35
            end
        end

        StopLightingGuard()
    end
end, {Flag = "NoFog"})

PerfCard:AddToggle("No Shadow", false, function(noShadow)
    _G.MX.NoShadow = noShadow

    if noShadow then
        StartLightingGuard()
        ApplyNoShadow()

    else
        ApplyNoShadow()
        StopLightingGuard()

    end
end, {Flag = "NoShadow"})

PerfCard:AddToggle("Low Graphics", false, function(arg)
    ToggleLowGFX(arg)
end, {Flag = "RemoveTexture"})

local v51 = EspPage:CreateSection("Map ESP", "map")
MapCard = v51

local function RefreshStaticESP(needScan)
    task.spawn(function()
        if needScan or #tbl4.Generators == 0 then
            pcall(ScanMapESP, true)
        end
        if _G.MX.ESPConfig.Master then
            pcall(UpdateStaticESP)
        end
    end)
end

MapCard:AddCheckbox("Generator ESP", false, function(generator)
    _G.MX.ESPConfig.Generator = generator

    if _G.MX.ESPConfig.Master then
        if generator then
            RefreshStaticESP()
        else
            ClearESP("Generator")
        end
    end
end, {Flag = "GeneratorEsp"})

MapCard:AddCheckbox("Generator Info", true, function(generatorName)
    _G.MX.ESPConfig.GeneratorName = generatorName

    if _G.MX.ESPConfig.Master then
        RefreshStaticESP()
    end
end, {Flag = "GeneratorName"})

MapCard:AddCheckbox("Pallet ESP", false, function(pallet)
    _G.MX.ESPConfig.Pallet = pallet

    if _G.MX.ESPConfig.Master then
        if pallet then
            RefreshStaticESP()
        else
            ClearESP("Pallet")
        end
    end
end, {Flag = "EspPallet"})

MapCard:AddCheckbox("Window ESP", false, function(window)
    _G.MX.ESPConfig.Window = window

    if _G.MX.ESPConfig.Master then
        if window then
            RefreshStaticESP()
        else
            ClearESP("Window")
        end
    end
end, {Flag = "EspWindow"})

MapCard:AddCheckbox("Hook ESP", false, function(hook)
    _G.MX.ESPConfig.Hook = hook

    if _G.MX.ESPConfig.Master then
        if hook then
            RefreshStaticESP()
        else
            ClearESP("Hook")
        end
    end
end, {Flag = "HookEsp"})

MapCard:AddCheckbox("Gate ESP", false, function(gate)
    _G.MX.ESPConfig.Gate = gate

    if _G.MX.ESPConfig.Master then
        if gate then
            RefreshStaticESP()
        else
            ClearESP("Gate")
        end
    end
end, {Flag = "GateEsp"})

MapCard:AddCheckbox("SCP ESP", false, function(scp)
    _G.MX.ESPConfig.SCP = scp

    if _G.MX.ESPConfig.Master then
        if scp then
            RefreshStaticESP()
        else
            ClearESP("SCP")
        end
    end
end, {Flag = "EspScp"})

MapCard:AddCheckbox("Pumpkin ESP", false, function(on)
    _G.MX.WantPumpkinESP = on
    if _G.MX.SetPumpkinESP then
        _G.MX.SetPumpkinESP(on)
    end
end, {Flag = "PumpkinESP"})

MapCard:AddCheckbox("Trap ESP", false, function(on)
    _G.MX.WantTrapESP = on
    if _G.MX.SetTrapESP then
        _G.MX.SetTrapESP(on)
    end
end, {Flag = "TrapEsp"})

MapCard:AddButton("Refresh Map", function()
    ForceRefreshMap()
end)

local Information = EspPage:CreateSection("Information", "info")
NextKillerCard = Information

NextKillerCard:AddToggle("Next Killer Display", false, function(arg)
    setNextKillerDisplay(arg)
end, {Flag = "NextKillerDisplay"})

NextKillerCard:AddToggle("Next Map Prediction", false, function(arg)
    setMapPrediction(arg)
end, {Flag = "NextMapPredict"})

local v61 = NextKillerCard:AddToggle("Killer Perks Display", false, function(arg)
    setKillerPerksDisplay(arg)
end, {Flag = "KillerPerkDisplay"})

KillerPerksToggle = v61

NextKillerCard:AddToggle("Killer Stun Indicator", false, function(arg)
    setStunIndicator(arg)
end, {Flag = "KillerStunIndicator"})

NextKillerCard:AddToggle("Spectator info", false, function(arg)
    fn4(arg)
end, {Flag = "SpectatorInfo"})

local Settings = v:CreateTab("Settings", false, false)
SettingsTab = Settings
local Settings2 = SettingsTab:CreatePage("Settings")
S_Page1 = Settings2
local v68 = S_Page1:CreateSection("UI Config", "sliders-vertical")
AppearanceCard = v68

AppearanceCard:AddKeybind("Menu Keybind", "RightShift", function(arg)
    v:SetMenuKey(arg)
end, {Flag = "MenuKeybing"})

AppearanceCard:AddToggle("Transparency Toggle", false, function(arg)
    local setTransparency = v.SetTransparency
    local n = arg and 0.2 or 0
    setTransparency(v, n)
end, {Flag = "ToggleTransparancy"})

AppearanceCard:AddToggle("Lock GUI", false, function(arg)
    v:SetLocked(arg)
end, {Flag = "LockGui"})

AppearanceCard:AddToggle("Watermark", true, function(arg)
    lib:SetWatermark({Enabled = arg})
end, {Flag = "Watermark"})

local Config = S_Page1:CreateSection("Config", "sliders-vertical")
SavesCard = Config
SavesCard:AddConfigManager("MXHUB/Configs")

task.spawn(function()
    task.wait(2)
    fn2()
end)

MXTrack(localPlayer.CharacterAdded:Connect(function()
    _G.MX.State.busy = false
    _G.MX.State.RandomMode_IsNormal = false

    if _G.MX.Auto.SkillCheck then
        task.wait(1)
        fn7()
    end
end))

MXTrack(localPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)

    if _G.MX.NoSlowdownEnabled then
        local character = localPlayer.Character

        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end
    end
end))

local v69 = nil

MXTrack(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local flag2 = input.UserInputType == Enum.UserInputType.Touch
    local v70 = GetRole()

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if gameProcessed then
            return
        end

        if v70 == "Killer" and _G.MX.Config.Killer_Aimbot_Enabled then
            _G.MX.lockedKillerAimbotTarget = getBestKillerAimbotTarget()

            if _G.MX.lockedKillerAimbotTarget then
                _G.MX.isKillerAimbotHolding = true
            end
        end
    end

    if flag2 and v70 == "Killer" and _G.MX.Config.Killer_Aimbot_Enabled then
        local playerGui2 = localPlayer:FindFirstChild("PlayerGui")
        local v71 = nil

        if playerGui2 then
            for k, child in pairs(playerGui2:GetChildren()) do
                if string.sub(child.Name, -4) == "-mob" and child.Name ~= "Survivor-mob" then
                    v71 = child
                    break
                end
            end
        end

        local attack = v71 and v71:FindFirstChild("Controls") and v71.Controls:FindFirstChild("attack")

        if attack and attack.Visible then
            local position = input.Position
            local absolutePosition = attack.AbsolutePosition
            local absoluteSize = attack.AbsoluteSize

            if absolutePosition.X <= position.X and position.X <= absolutePosition.X + absoluteSize.X and absolutePosition.Y <= position.Y and position.Y <= absolutePosition.Y + absoluteSize.Y then
                _G.MX.lockedKillerAimbotTarget = getBestKillerAimbotTarget()

                if _G.MX.lockedKillerAimbotTarget then
                    _G.MX.isKillerAimbotHolding = true
                    v69 = input
                end
            end
        end
    end
end))

MXTrack(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        _G.MX.isKillerAimbotHolding = false
        _G.MX.lockedKillerAimbotTarget = nil

        if _G.MX.killerAimbotHighlight then
            _G.MX.killerAimbotHighlight.Parent = nil
        end
    end

    if input.UserInputType == Enum.UserInputType.Touch and input == v69 then
        _G.MX.isKillerAimbotHolding = false
        _G.MX.lockedKillerAimbotTarget = nil
        v69 = nil

        if _G.MX.killerAimbotHighlight then
            _G.MX.killerAimbotHighlight.Parent = nil
        end
    end
end))

MXTrack(localPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    ReapplyPerformanceDelayed()
end))

MXTrack(workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        task.wait(1)
        ReapplyPerformanceDelayed()
    end
end))

task.spawn(function()
    task.wait(2)
    ReapplyPerformanceDelayed()
end)

pcall(lib.Autoload)
