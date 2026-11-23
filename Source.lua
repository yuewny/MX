local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

local C3 = Color3.fromRGB
local Touch = UIS.TouchEnabled
local RH = Touch and 38 or 32
local AX, AY, AXY = Enum.AutomaticSize.X, Enum.AutomaticSize.Y, Enum.AutomaticSize.XY
local LEFT, CENTER, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
local FONT = { Reg = Enum.Font.BuilderSans, Med = Enum.Font.BuilderSansMedium, Bold = Enum.Font.BuilderSansBold, Mono = Enum.Font.Code }

local genv = (getgenv and getgenv()) or _G
if genv.MXUI and type(genv.MXUI.Destroy) == "function" then
	pcall(function() genv.MXUI:Destroy() end)
end

local MX = {
	Version = "1.0.0",
	Flags = {},
	Options = {},
	Themes = {},
	ThemeOrder = {},
	ThemeName = "Mono",
	ThemeSweep = false,
	TextScale = 1,
	LogoId = 105865788976884,
	WelcomeImage = 113267102798729,
	ConfigFolder = "MXUI",
	Glass = false,
	UserScale = 1,
	Scale = 1,
	NotifyEnabled = true,
	Windows = {},
	Binds = {},
	SavedColors = {},
	Icons = {},
	Dead = false,
}
genv.MXUI = MX

local Conns = {}
local function Conn(sig, fn)
	local c = sig:Connect(fn)
	Conns[#Conns + 1] = c
	return c
end

local function New(class, props, parent)
	local o = Instance.new(class)
	if props then
		for k, v in pairs(props) do o[k] = v end
	end
	if parent then o.Parent = parent end
	return o
end

local function TS(n) return math.floor(n * MX.TextScale + 0.5) end

local Active = setmetatable({}, { __mode = "k" })
local function Tween(o, props, t, style, dir)
	t = t or 0.12
	local st = Active[o]
	if not st then st = {} Active[o] = st end
	for k in pairs(props) do
		local old = st[k]
		if old then old:Cancel() end
	end
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	for k in pairs(props) do st[k] = tw end
	tw:Play()
	return tw
end

local function Lum(c) return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B end

local function Snap(v, inc, min)
	if inc and inc > 0 then v = math.floor((v - (min or 0)) / inc + 0.5) * inc + (min or 0) end
	return tonumber(string.format("%.6f", v)) or v
end
local function Dec(inc)
	local d = tostring(inc or 1):match("%.(%d+)")
	return d and #d or 0
end
local function Fmt(v, inc) return string.format("%." .. Dec(inc) .. "f", v) end

local function Copy(text)
	local f = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if f then return pcall(f, tostring(text)) end
	return false
end

local FS = {}
function FS.ok()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfolder) == "function" and type(makefolder) == "function"
end
local function EnsureFolder(p)
	if not FS.ok() then return end
	local path = ""
	for seg in tostring(p):gmatch("[^/\\]+") do
		path = path == "" and seg or path .. "/" .. seg
		if not isfolder(path) then pcall(makefolder, path) end
	end
end

MX._pending = {}
MX._ignore = {}
setmetatable(MX.Options, {
	__newindex = function(t, k, v)
		rawset(t, k, v)
		local p = MX._pending[k]
		if p ~= nil and type(v) == "table" and v.Deserialize then
			MX._pending[k] = nil
			task.defer(function()
				if MX.Options[k] == v then pcall(v.Deserialize, v, p) end
			end)
		end
	end,
})

local Theme = {}
local Reg, GlassReg = {}, {}
MX.Theme = Theme

function MX._NormalizeTheme(d)
	local function ok(v) return typeof(v) == "Color3" end
	d = type(d) == "table" and d or {}
	if not ok(d.Window) then d.Window = ok(d.Panel) and d.Panel or (ok(d.Card) and d.Card or C3(14, 14, 18)) end
	if not ok(d.Panel) then d.Panel = d.Window end
	if not ok(d.Card) then d.Card = d.Panel end
	if not ok(d.Accent) then d.Accent = C3(236, 60, 84) end
	local light = Lum(d.Card) > 0.5
	if not ok(d.Text) then d.Text = light and C3(20, 22, 30) or C3(240, 240, 246) end
	if not ok(d.Side) then d.Side = d.Window:Lerp(C3(0, 0, 0), light and 0.05 or 0.3) end
	if not ok(d.Element) then d.Element = d.Card:Lerp(d.Text, 0.08) end
	if not ok(d.Hover) then d.Hover = d.Element:Lerp(d.Text, 0.1) end
	if not ok(d.Border) then d.Border = d.Card:Lerp(d.Text, light and 0.3 or 0.38) end
	if not ok(d.Sub) then d.Sub = d.Text:Lerp(d.Card, 0.45) end
	if not ok(d.Off) then d.Off = d.Element:Lerp(d.Text, 0.12) end
	if not ok(d.OnAccent) then d.OnAccent = Lum(d.Accent) > 0.62 and C3(20, 20, 24) or C3(255, 255, 255) end
	if not ok(d.Success) then d.Success = C3(86, 214, 140) end
	if not ok(d.Warning) then d.Warning = C3(245, 180, 66) end
	if not ok(d.Danger) then d.Danger = C3(236, 80, 90) end
	return d
end

function MX:AddThemes(t)
	local names = {}
	for name in pairs(t) do names[#names + 1] = name end
	table.sort(names)
	for _, name in ipairs(names) do
		local d = MX._NormalizeTheme(t[name])
		t[name] = d
		if not MX.Themes[name] then table.insert(MX.ThemeOrder, name) end
		MX.Themes[name] = d
	end
end

MX:AddThemes({
	["Obsidian"] = { Window = C3(14, 14, 18), Side = C3(9, 9, 12), Panel = C3(18, 18, 23), Card = C3(23, 23, 30), Element = C3(32, 32, 41), Hover = C3(44, 44, 57), Border = C3(58, 58, 72), Accent = C3(236, 60, 84), Text = C3(240, 240, 246), Sub = C3(150, 152, 170), Off = C3(52, 52, 64) },
	["Frost"] = { Window = C3(242, 243, 247), Side = C3(231, 233, 240), Panel = C3(247, 248, 251), Card = C3(255, 255, 255), Element = C3(238, 240, 246), Hover = C3(226, 229, 239), Border = C3(203, 207, 220), Accent = C3(220, 50, 75), Text = C3(20, 22, 30), Sub = C3(104, 110, 130), Off = C3(205, 209, 222) },
	["Violet"] = { Window = C3(14, 11, 20), Side = C3(9, 7, 14), Panel = C3(19, 15, 27), Card = C3(25, 20, 35), Element = C3(35, 28, 49), Hover = C3(48, 39, 67), Border = C3(72, 60, 96), Accent = C3(150, 96, 240), Text = C3(242, 238, 250), Sub = C3(156, 142, 180), Off = C3(58, 49, 78) },
	["Ocean"] = { Window = C3(10, 18, 26), Side = C3(7, 13, 19), Panel = C3(13, 23, 33), Card = C3(17, 30, 43), Element = C3(24, 41, 58), Hover = C3(33, 55, 77), Border = C3(52, 78, 104), Accent = C3(40, 190, 230), Text = C3(236, 244, 250), Sub = C3(130, 156, 178), Off = C3(40, 60, 82) },
	["Sunset"] = { Window = C3(22, 13, 14), Side = C3(15, 8, 9), Panel = C3(27, 16, 17), Card = C3(34, 21, 22), Element = C3(47, 30, 31), Hover = C3(63, 41, 42), Border = C3(92, 62, 62), Accent = C3(255, 128, 64), Text = C3(252, 242, 238), Sub = C3(186, 150, 142), Off = C3(70, 48, 48) },

	Rose = { Window = C3(28, 18, 22), Side = C3(22, 14, 18), Panel = C3(32, 21, 26), Card = C3(38, 25, 31), Element = C3(50, 33, 41), Hover = C3(64, 44, 54), Accent = C3(255, 120, 170), Text = C3(252, 238, 244), Sub = C3(176, 140, 154), Off = C3(82, 58, 70) },
	Crimson = { Window = C3(19, 19, 19), Side = C3(14, 14, 14), Panel = C3(17, 17, 17), Card = C3(13, 13, 13), Element = C3(27, 27, 27), Hover = C3(38, 38, 38), Accent = C3(255, 24, 24), Text = C3(240, 240, 240), Sub = C3(112, 112, 112), Off = C3(34, 34, 34) },
	Onyx = { Window = C3(10, 10, 10), Side = C3(5, 5, 5), Panel = C3(8, 8, 8), Card = C3(14, 14, 14), Element = C3(22, 22, 22), Hover = C3(34, 34, 34), Accent = C3(255, 255, 255), Text = C3(245, 245, 245), Sub = C3(140, 140, 140), Off = C3(42, 42, 42), OnAccent = C3(10, 10, 10) },
	Dark = { Window = C3(24, 24, 26), Side = C3(19, 19, 21), Panel = C3(28, 28, 31), Card = C3(33, 33, 37), Element = C3(42, 42, 47), Hover = C3(54, 54, 60), Accent = C3(96, 205, 255), Text = C3(240, 240, 244), Sub = C3(140, 142, 152), Off = C3(70, 70, 80) },
	Darker = { Window = C3(12, 12, 14), Side = C3(8, 8, 10), Panel = C3(15, 15, 18), Card = C3(20, 20, 24), Element = C3(28, 28, 33), Hover = C3(38, 38, 44), Accent = C3(96, 205, 255), Text = C3(240, 240, 244), Sub = C3(130, 132, 144), Off = C3(48, 48, 58) },
	Light = { Window = C3(243, 243, 246), Side = C3(234, 234, 239), Panel = C3(247, 247, 250), Card = C3(255, 255, 255), Element = C3(240, 240, 244), Hover = C3(228, 228, 234), Accent = C3(0, 120, 212), Text = C3(24, 24, 28), Sub = C3(100, 102, 112), Off = C3(205, 205, 214) },
	Aqua = { Window = C3(14, 24, 26), Side = C3(11, 19, 21), Panel = C3(16, 28, 31), Card = C3(20, 35, 39), Element = C3(26, 46, 50), Hover = C3(34, 60, 65), Accent = C3(60, 220, 200), Text = C3(232, 250, 248), Sub = C3(120, 160, 158), Off = C3(44, 74, 78) },
	Lagoon = { Window = C3(8, 20, 30), Side = C3(5, 15, 23), Panel = C3(10, 25, 37), Card = C3(13, 31, 45), Element = C3(19, 43, 61), Hover = C3(27, 58, 80), Accent = C3(34, 230, 222), Text = C3(225, 248, 252), Sub = C3(110, 160, 175), Off = C3(30, 60, 78), OnAccent = C3(4, 24, 30) },
	Amethyst = { Window = C3(22, 18, 30), Side = C3(17, 14, 24), Panel = C3(25, 20, 36), Card = C3(30, 25, 43), Element = C3(40, 33, 57), Hover = C3(52, 44, 73), Accent = C3(176, 120, 255), Text = C3(242, 238, 252), Sub = C3(150, 140, 176), Off = C3(62, 52, 88) },
	Emerald = { Window = C3(14, 24, 19), Side = C3(10, 18, 14), Panel = C3(17, 29, 23), Card = C3(21, 36, 28), Element = C3(28, 47, 37), Hover = C3(37, 62, 49), Accent = C3(52, 211, 153), Text = C3(232, 250, 242), Sub = C3(122, 163, 145), Off = C3(40, 66, 54) },
	Toxic = { Window = C3(12, 18, 10), Side = C3(8, 13, 7), Panel = C3(14, 21, 12), Card = C3(18, 27, 15), Element = C3(25, 38, 21), Hover = C3(34, 52, 29), Accent = C3(166, 255, 0), Text = C3(236, 250, 225), Sub = C3(130, 160, 110), Off = C3(38, 58, 32), OnAccent = C3(10, 18, 0) },
	Noir = { Window = C3(10, 8, 9), Side = C3(5, 4, 5), Panel = C3(8, 6, 7), Card = C3(14, 10, 12), Element = C3(23, 17, 20), Hover = C3(36, 26, 31), Accent = C3(255, 92, 150), Text = C3(250, 240, 245), Sub = C3(150, 125, 136), Off = C3(44, 32, 38) },
	["Mono"] = { Window = C3(12, 12, 12), Side = C3(7, 7, 7), Panel = C3(16, 16, 16), Card = C3(22, 22, 22), Element = C3(31, 31, 31), Hover = C3(43, 43, 43), Border = C3(64, 64, 64), Accent = C3(235, 235, 235), Text = C3(245, 245, 245), Sub = C3(140, 140, 140), Off = C3(50, 50, 50) },
})
do
	local order = { "Mono", "Obsidian", "Frost", "Violet", "Ocean", "Sunset", "Rose", "Crimson", "Onyx", "Dark", "Darker", "Light", "Aqua", "Lagoon", "Amethyst", "Toxic", "Noir" }
	table.insert(order, "Emerald")
	MX.ThemeOrder = order
	for k, v in pairs(MX.Themes) do Theme[k] = nil end
	for k, v in pairs(MX.Themes["Mono"]) do Theme[k] = v end
end

local Gui
local function ProtectParent(g)
	if gethui then
		local ok = pcall(function() g.Parent = gethui() end)
		if ok and g.Parent then return end
	end
	if syn and syn.protect_gui then pcall(syn.protect_gui, g) end
	local ok = pcall(function() g.Parent = CoreGui end)
	if not ok or not g.Parent then g.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

Gui = New("ScreenGui", {
	Name = "MX_" .. HttpService:GenerateGUID(false):sub(1, 8),
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 1000,
	IgnoreGuiInset = true,
})
pcall(function() Gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
ProtectParent(Gui)
MX.Gui = Gui

local function Layer(z, name)
	return New("Frame", { Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z }, Gui)
end
local WinLayer, FloatLayer, Overlay, TipLayer = Layer(1, "Windows"), Layer(5, "Floating"), Layer(40, "Overlay"), Layer(80, "Tips")
Overlay.Visible = false
Overlay.Active = true

local ScaleObjs = {}
local function Scaled(o)
	local u = New("UIScale", { Scale = MX.Scale }, o)
	ScaleObjs[#ScaleObjs + 1] = u
	return u
end
function MX:_ApplyScale(s)
	MX.Scale = s
	for i = #ScaleObjs, 1, -1 do
		local u = ScaleObjs[i]
		if u.Parent then u.Scale = s else table.remove(ScaleObjs, i) end
	end
end

local PruneAt = 600
local function Bind(o, map)
	for p, t in pairs(map) do
		o[p] = Theme[t]
		Reg[#Reg + 1] = { o = o, p = p, t = t }
	end
	if #Reg > PruneAt then
		local w = 0
		for i = 1, #Reg do
			local e = Reg[i]
			if e.o:IsDescendantOf(Gui) then
				w += 1
				Reg[w] = e
			end
		end
		for i = #Reg, w + 1, -1 do Reg[i] = nil end
		PruneAt = math.max(600, w * 2)
	end
end
local function GlassOn(o, a)
	GlassReg[#GlassReg + 1] = { o = o, a = a }
	if MX.Glass then o.BackgroundTransparency = a end
end

local function Box(parent, props, tok, rad, stroke)
	props = props or {}
	props.BorderSizePixel = 0
	if tok == nil and props.BackgroundTransparency == nil then props.BackgroundTransparency = 1 end
	local f = New("Frame", props, parent)
	if tok then Bind(f, { BackgroundColor3 = tok }) end
	if rad then New("UICorner", { CornerRadius = UDim.new(0, rad) }, f) end
	local st
	if stroke then
		st = New("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
		Bind(st, { Color = stroke })
	end
	return f, st
end

MX.Lang = { Current = "English", List = { "English", "Indonesia" }, Dict = {}, Codes = { English = "en", Indonesia = "id" }, Listeners = {} }
local TrReg, TrKeys, TrPrune, TrQueued = {}, {}, 500, false
function MX:T(key)
	local d = MX.Lang.Dict[MX.Lang.Current]
	local v = d and d[key]
	return v or key
end
local function Tr(o, key, prop)
	local e = { o = o, p = prop or "Text", k = key }
	TrReg[#TrReg + 1] = e
	if key ~= "" then TrKeys[key] = true end
	o[e.p] = MX:T(key)
	if #TrReg > TrPrune then
		local w = 0
		for i = 1, #TrReg do
			local x = TrReg[i]
			if x.o.Parent and x.o:IsDescendantOf(Gui) then
				w += 1
				TrReg[w] = x
			end
		end
		for i = #TrReg, w + 1, -1 do TrReg[i] = nil end
		TrPrune = math.max(500, w * 2)
	end
	if MX.Lang.Current ~= "English" and key ~= "" and not TrQueued then
		local d = MX.Lang.Dict[MX.Lang.Current]
		if not (d and d[key]) then
			TrQueued = true
			task.delay(1.2, function()
				TrQueued = false
				MX:_TranslateMissing(MX.Lang.Current)
			end)
		end
	end
	return e
end
local function TrSet(e, key)
	e.k = key
	if key ~= "" then TrKeys[key] = true end
	e.o[e.p] = MX:T(key)
end

local function Lbl(parent, props, tok)
	props = props or {}
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	if props.Font == nil then props.Font = FONT.Med end
	props.TextSize = TS(props.TextSize or 14)
	if props.TextXAlignment == nil then props.TextXAlignment = LEFT end
	if props.Text == nil then props.Text = "" end
	local tr = props.Tr
	props.Tr = nil
	local l = New("TextLabel", props, parent)
	if tok ~= false then Bind(l, { TextColor3 = tok or "Text" }) end
	if tr then return l, Tr(l, props.Text) end
	return l
end

local function Hit(parent, z)
	return New("TextButton", { BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = z or 2 }, parent)
end

local function List(parent, pad, dir, ha, va)
	return New("UIListLayout", {
		Padding = UDim.new(0, pad or 0),
		FillDirection = dir or Enum.FillDirection.Vertical,
		HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
		VerticalAlignment = va or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, parent)
end

local function Pad(parent, t, r, b, l)
	return New("UIPadding", { PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0) }, parent)
end

local function Hover(btn, target, normal, over)
	local ps
	local function press(on)
		if not target.Parent then return end
		if not ps then ps = target:FindFirstChild("_ps") or New("UIScale", { Name = "_ps" }, target) end
		Tween(ps, { Scale = on and 0.985 or 1 }, on and 0.07 or 0.14)
		if on then
			task.delay(0.9, function()
				if ps and ps.Parent and ps.Scale ~= 1 then Tween(ps, { Scale = 1 }, 0.14) end
			end)
		end
	end
	btn.InputBegan:Connect(function(i)
		local t = i.UserInputType
		if t == Enum.UserInputType.Touch then Tween(target, { BackgroundColor3 = Theme[over] }, 0.08) end
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then press(true) end
	end)
	btn.InputEnded:Connect(function(i)
		local t = i.UserInputType
		if t == Enum.UserInputType.Touch then Tween(target, { BackgroundColor3 = Theme[normal] }, 0.16) end
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then press(false) end
	end)
	btn.MouseEnter:Connect(function() Tween(target, { BackgroundColor3 = Theme[over] }, 0.1) end)
	btn.MouseLeave:Connect(function()
		Tween(target, { BackgroundColor3 = Theme[normal] }, 0.14)
		press(false)
	end)
end

function MX:ScrollLock(on)
	for _, w in ipairs(MX.Windows) do
		for _, p in ipairs(w.Pages or {}) do
			if p.Parent then p.ScrollingEnabled = not on end
		end
	end
end

local PtrD = GuiService:GetGuiInset()
local function Inset() return GuiService:GetGuiInset() end
local function TopInset()
	local t = GuiService:GetGuiInset().Y
	local ok, r = pcall(function() return GuiService.TopbarInset.Height end)
	if ok and type(r) == "number" and r > t then t = r end
	return t
end
local function ToGui(raw) return raw end
local function GuiPos(i)
	return Vector2.new(i.Position.X, i.Position.Y) + PtrD
end
Conn(UIS.InputChanged, function(i)
	if i.UserInputType == Enum.UserInputType.MouseMovement then
		PtrD = UIS:GetMouseLocation() - Vector2.new(i.Position.X, i.Position.Y)
	end
end)

local function Tap(hit, fn)
	local act, sp, sf, sc0, peak, mv
	local last = -1
	local function reset()
		if mv then
			mv:Disconnect()
			mv = nil
		end
		act, sp, sf, sc0, peak = nil, nil, nil, nil, nil
	end
	hit.InputBegan:Connect(function(i)
		local t = i.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
		if mv then mv:Disconnect() end
		act = i
		peak = 0
		sp = Vector2.new(i.Position.X, i.Position.Y)
		sf = hit.Parent
		while sf and not sf:IsA("ScrollingFrame") do sf = sf.Parent end
		sc0 = sf and sf.CanvasPosition or nil
		mv = UIS.InputChanged:Connect(function(c)
			if not act then return end
			if c == act or (act.UserInputType == Enum.UserInputType.MouseButton1 and c.UserInputType == Enum.UserInputType.MouseMovement) then
				local d = (Vector2.new(c.Position.X, c.Position.Y) - sp).Magnitude
				if d > peak then peak = d end
			end
		end)
	end)
	hit.InputEnded:Connect(function(i)
		if i ~= act then return end
		local d = (Vector2.new(i.Position.X, i.Position.Y) - sp).Magnitude
		if d > peak then peak = d end
		if mv then
			mv:Disconnect()
			mv = nil
		end
	end)
	hit.Activated:Connect(function()
		local lim = act and act.UserInputType == Enum.UserInputType.Touch and 14 or 8
		local blocked = (sf ~= nil and sc0 ~= nil and (sf.CanvasPosition - sc0).Magnitude > 4) or (peak ~= nil and peak > lim)
		reset()
		if blocked then return end
		local n = os.clock()
		if n - last < 0.08 then return end
		last = n
		fn()
	end)
end

local function Drag(handle, o)
	handle.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
		do
			local ins = Inset()
			if ins.Y > 0 then
				local p = Vector2.new(input.Position.X, input.Position.Y)
				local ap, as = handle.AbsolutePosition, handle.AbsoluteSize
				local function inside(v) return v.X >= ap.X and v.X <= ap.X + as.X and v.Y >= ap.Y and v.Y <= ap.Y + as.Y end
				local a, b = inside(p), inside(p + ins)
				if a and not b then PtrD = Vector2.zero elseif b and not a then PtrD = ins end
			end
		end
		if o.Begin and o.Begin(input) == false then return end
		local originG = GuiPos(input)
		if o.Lock then MX:ScrollLock(true) end
		local cm, ce
		local function stop()
			if cm then cm:Disconnect() cm = nil end
			if ce then ce:Disconnect() ce = nil end
			if o.Lock then MX:ScrollLock(false) end
			if o.End then o.End() end
		end
		cm = UIS.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement or i == input then
				o.Move(GuiPos(i), originG)
			end
		end)
		ce = UIS.InputEnded:Connect(function(i)
			if i == input or (t == Enum.UserInputType.MouseButton1 and i.UserInputType == t) then stop() end
		end)
		o.Move(originG, originG)
	end)
end

local IconLib = (function()
return {
	assets = {
		["lucide-accessibility"] = "rbxassetid://10709751939",
		["lucide-activity"] = "rbxassetid://10709752035",
		["lucide-air-vent"] = "rbxassetid://10709752131",
		["lucide-airplay"] = "rbxassetid://10709752254",
		["lucide-alarm-check"] = "rbxassetid://10709752405",
		["lucide-alarm-clock"] = "rbxassetid://10709752630",
		["lucide-alarm-clock-off"] = "rbxassetid://10709752508",
		["lucide-alarm-minus"] = "rbxassetid://10709752732",
		["lucide-alarm-plus"] = "rbxassetid://10709752825",
		["lucide-album"] = "rbxassetid://10709752906",
		["lucide-alert-circle"] = "rbxassetid://10709752996",
		["lucide-alert-octagon"] = "rbxassetid://10709753064",
		["lucide-alert-triangle"] = "rbxassetid://10709753149",
		["lucide-align-center"] = "rbxassetid://10709753570",
		["lucide-align-center-horizontal"] = "rbxassetid://10709753272",
		["lucide-align-center-vertical"] = "rbxassetid://10709753421",
		["lucide-align-end-horizontal"] = "rbxassetid://10709753692",
		["lucide-align-end-vertical"] = "rbxassetid://10709753808",
		["lucide-align-horizontal-distribute-center"] = "rbxassetid://10747779791",
		["lucide-align-horizontal-distribute-end"] = "rbxassetid://10747784534",
		["lucide-align-horizontal-distribute-start"] = "rbxassetid://10709754118",
		["lucide-align-horizontal-justify-center"] = "rbxassetid://10709754204",
		["lucide-align-horizontal-justify-end"] = "rbxassetid://10709754317",
		["lucide-align-horizontal-justify-start"] = "rbxassetid://10709754436",
		["lucide-align-horizontal-space-around"] = "rbxassetid://10709754590",
		["lucide-align-horizontal-space-between"] = "rbxassetid://10709754749",
		["lucide-align-justify"] = "rbxassetid://10709759610",
		["lucide-align-left"] = "rbxassetid://10709759764",
		["lucide-align-right"] = "rbxassetid://10709759895",
		["lucide-align-start-horizontal"] = "rbxassetid://10709760051",
		["lucide-align-start-vertical"] = "rbxassetid://10709760244",
		["lucide-align-vertical-distribute-center"] = "rbxassetid://10709760351",
		["lucide-align-vertical-distribute-end"] = "rbxassetid://10709760434",
		["lucide-align-vertical-distribute-start"] = "rbxassetid://10709760612",
		["lucide-align-vertical-justify-center"] = "rbxassetid://10709760814",
		["lucide-align-vertical-justify-end"] = "rbxassetid://10709761003",
		["lucide-align-vertical-justify-start"] = "rbxassetid://10709761176",
		["lucide-align-vertical-space-around"] = "rbxassetid://10709761324",
		["lucide-align-vertical-space-between"] = "rbxassetid://10709761434",
		["lucide-anchor"] = "rbxassetid://10709761530",
		["lucide-angry"] = "rbxassetid://10709761629",
		["lucide-annoyed"] = "rbxassetid://10709761722",
		["lucide-aperture"] = "rbxassetid://10709761813",
		["lucide-apple"] = "rbxassetid://10709761889",
		["lucide-archive"] = "rbxassetid://10709762233",
		["lucide-archive-restore"] = "rbxassetid://10709762058",
		["lucide-armchair"] = "rbxassetid://10709762327",
		["lucide-arrow-big-down"] = "rbxassetid://10747796644",
		["lucide-arrow-big-left"] = "rbxassetid://10709762574",
		["lucide-arrow-big-right"] = "rbxassetid://10709762727",
		["lucide-arrow-big-up"] = "rbxassetid://10709762879",
		["lucide-arrow-down"] = "rbxassetid://10709767827",
		["lucide-arrow-down-circle"] = "rbxassetid://10709763034",
		["lucide-arrow-down-left"] = "rbxassetid://10709767656",
		["lucide-arrow-down-right"] = "rbxassetid://10709767750",
		["lucide-arrow-left"] = "rbxassetid://10709768114",
		["lucide-arrow-left-circle"] = "rbxassetid://10709767936",
		["lucide-arrow-left-right"] = "rbxassetid://10709768019",
		["lucide-arrow-right"] = "rbxassetid://10709768347",
		["lucide-arrow-right-circle"] = "rbxassetid://10709768226",
		["lucide-arrow-up"] = "rbxassetid://10709768939",
		["lucide-arrow-up-circle"] = "rbxassetid://10709768432",
		["lucide-arrow-up-down"] = "rbxassetid://10709768538",
		["lucide-arrow-up-left"] = "rbxassetid://10709768661",
		["lucide-arrow-up-right"] = "rbxassetid://10709768787",
		["lucide-asterisk"] = "rbxassetid://10709769095",
		["lucide-at-sign"] = "rbxassetid://10709769286",
		["lucide-award"] = "rbxassetid://10709769406",
		["lucide-axe"] = "rbxassetid://10709769508",
		["lucide-axis-3d"] = "rbxassetid://10709769598",
		["lucide-baby"] = "rbxassetid://10709769732",
		["lucide-backpack"] = "rbxassetid://10709769841",
		["lucide-baggage-claim"] = "rbxassetid://10709769935",
		["lucide-banana"] = "rbxassetid://10709770005",
		["lucide-banknote"] = "rbxassetid://10709770178",
		["lucide-bar-chart"] = "rbxassetid://10709773755",
		["lucide-bar-chart-2"] = "rbxassetid://10709770317",
		["lucide-bar-chart-3"] = "rbxassetid://10709770431",
		["lucide-bar-chart-4"] = "rbxassetid://10709770560",
		["lucide-bar-chart-horizontal"] = "rbxassetid://10709773669",
		["lucide-barcode"] = "rbxassetid://10747360675",
		["lucide-baseline"] = "rbxassetid://10709773863",
		["lucide-bath"] = "rbxassetid://10709773963",
		["lucide-battery"] = "rbxassetid://10709774640",
		["lucide-battery-charging"] = "rbxassetid://10709774068",
		["lucide-battery-full"] = "rbxassetid://10709774206",
		["lucide-battery-low"] = "rbxassetid://10709774370",
		["lucide-battery-medium"] = "rbxassetid://10709774513",
		["lucide-beaker"] = "rbxassetid://10709774756",
		["lucide-bed"] = "rbxassetid://10709775036",
		["lucide-bed-double"] = "rbxassetid://10709774864",
		["lucide-bed-single"] = "rbxassetid://10709774968",
		["lucide-beer"] = "rbxassetid://10709775167",
		["lucide-bell"] = "rbxassetid://10709775704",
		["lucide-bell-minus"] = "rbxassetid://10709775241",
		["lucide-bell-off"] = "rbxassetid://10709775320",
		["lucide-bell-plus"] = "rbxassetid://10709775448",
		["lucide-bell-ring"] = "rbxassetid://10709775560",
		["lucide-bike"] = "rbxassetid://10709775894",
		["lucide-binary"] = "rbxassetid://10709776050",
		["lucide-bitcoin"] = "rbxassetid://10709776126",
		["lucide-bluetooth"] = "rbxassetid://10709776655",
		["lucide-bluetooth-connected"] = "rbxassetid://10709776240",
		["lucide-bluetooth-off"] = "rbxassetid://10709776344",
		["lucide-bluetooth-searching"] = "rbxassetid://10709776501",
		["lucide-bold"] = "rbxassetid://10747813908",
		["lucide-bomb"] = "rbxassetid://10709781460",
		["lucide-bone"] = "rbxassetid://10709781605",
		["lucide-book"] = "rbxassetid://10709781824",
		["lucide-book-open"] = "rbxassetid://10709781717",
		["lucide-bookmark"] = "rbxassetid://10709782154",
		["lucide-bookmark-minus"] = "rbxassetid://10709781919",
		["lucide-bookmark-plus"] = "rbxassetid://10709782044",
		["lucide-bot"] = "rbxassetid://10709782230",
		["lucide-box"] = "rbxassetid://10709782497",
		["lucide-box-select"] = "rbxassetid://10709782342",
		["lucide-boxes"] = "rbxassetid://10709782582",
		["lucide-briefcase"] = "rbxassetid://10709782662",
		["lucide-brush"] = "rbxassetid://10709782758",
		["lucide-bug"] = "rbxassetid://10709782845",
		["lucide-building"] = "rbxassetid://10709783051",
		["lucide-building-2"] = "rbxassetid://10709782939",
		["lucide-bus"] = "rbxassetid://10709783137",
		["lucide-cake"] = "rbxassetid://10709783217",
		["lucide-calculator"] = "rbxassetid://10709783311",
		["lucide-calendar"] = "rbxassetid://10709789505",
		["lucide-calendar-check"] = "rbxassetid://10709783474",
		["lucide-calendar-check-2"] = "rbxassetid://10709783392",
		["lucide-calendar-clock"] = "rbxassetid://10709783577",
		["lucide-calendar-days"] = "rbxassetid://10709783673",
		["lucide-calendar-heart"] = "rbxassetid://10709783835",
		["lucide-calendar-minus"] = "rbxassetid://10709783959",
		["lucide-calendar-off"] = "rbxassetid://10709788784",
		["lucide-calendar-plus"] = "rbxassetid://10709788937",
		["lucide-calendar-range"] = "rbxassetid://10709789053",
		["lucide-calendar-search"] = "rbxassetid://10709789200",
		["lucide-calendar-x"] = "rbxassetid://10709789407",
		["lucide-calendar-x-2"] = "rbxassetid://10709789329",
		["lucide-camera"] = "rbxassetid://10709789686",
		["lucide-camera-off"] = "rbxassetid://10747822677",
		["lucide-car"] = "rbxassetid://10709789810",
		["lucide-carrot"] = "rbxassetid://10709789960",
		["lucide-cast"] = "rbxassetid://10709790097",
		["lucide-charge"] = "rbxassetid://10709790202",
		["lucide-check"] = "rbxassetid://10709790644",
		["lucide-check-circle"] = "rbxassetid://10709790387",
		["lucide-check-circle-2"] = "rbxassetid://10709790298",
		["lucide-check-square"] = "rbxassetid://10709790537",
		["lucide-chef-hat"] = "rbxassetid://10709790757",
		["lucide-cherry"] = "rbxassetid://10709790875",
		["lucide-chevron-down"] = "rbxassetid://10709790948",
		["lucide-chevron-first"] = "rbxassetid://10709791015",
		["lucide-chevron-last"] = "rbxassetid://10709791130",
		["lucide-chevron-left"] = "rbxassetid://10709791281",
		["lucide-chevron-right"] = "rbxassetid://10709791437",
		["lucide-chevron-up"] = "rbxassetid://10709791523",
		["lucide-chevrons-down"] = "rbxassetid://10709796864",
		["lucide-chevrons-down-up"] = "rbxassetid://10709791632",
		["lucide-chevrons-left"] = "rbxassetid://10709797151",
		["lucide-chevrons-left-right"] = "rbxassetid://10709797006",
		["lucide-chevrons-right"] = "rbxassetid://10709797382",
		["lucide-chevrons-right-left"] = "rbxassetid://10709797274",
		["lucide-chevrons-up"] = "rbxassetid://10709797622",
		["lucide-chevrons-up-down"] = "rbxassetid://10709797508",
		["lucide-chrome"] = "rbxassetid://10709797725",
		["lucide-circle"] = "rbxassetid://10709798174",
		["lucide-circle-dot"] = "rbxassetid://10709797837",
		["lucide-circle-ellipsis"] = "rbxassetid://10709797985",
		["lucide-circle-slashed"] = "rbxassetid://10709798100",
		["lucide-citrus"] = "rbxassetid://10709798276",
		["lucide-clapperboard"] = "rbxassetid://10709798350",
		["lucide-clipboard"] = "rbxassetid://10709799288",
		["lucide-clipboard-check"] = "rbxassetid://10709798443",
		["lucide-clipboard-copy"] = "rbxassetid://10709798574",
		["lucide-clipboard-edit"] = "rbxassetid://10709798682",
		["lucide-clipboard-list"] = "rbxassetid://10709798792",
		["lucide-clipboard-signature"] = "rbxassetid://10709798890",
		["lucide-clipboard-type"] = "rbxassetid://10709798999",
		["lucide-clipboard-x"] = "rbxassetid://10709799124",
		["lucide-clock"] = "rbxassetid://10709805144",
		["lucide-clock-1"] = "rbxassetid://10709799535",
		["lucide-clock-10"] = "rbxassetid://10709799718",
		["lucide-clock-11"] = "rbxassetid://10709799818",
		["lucide-clock-12"] = "rbxassetid://10709799962",
		["lucide-clock-2"] = "rbxassetid://10709803876",
		["lucide-clock-3"] = "rbxassetid://10709803989",
		["lucide-clock-4"] = "rbxassetid://10709804164",
		["lucide-clock-5"] = "rbxassetid://10709804291",
		["lucide-clock-6"] = "rbxassetid://10709804435",
		["lucide-clock-7"] = "rbxassetid://10709804599",
		["lucide-clock-8"] = "rbxassetid://10709804784",
		["lucide-clock-9"] = "rbxassetid://10709804996",
		["lucide-cloud"] = "rbxassetid://10709806740",
		["lucide-cloud-cog"] = "rbxassetid://10709805262",
		["lucide-cloud-drizzle"] = "rbxassetid://10709805371",
		["lucide-cloud-fog"] = "rbxassetid://10709805477",
		["lucide-cloud-hail"] = "rbxassetid://10709805596",
		["lucide-cloud-lightning"] = "rbxassetid://10709805727",
		["lucide-cloud-moon"] = "rbxassetid://10709805942",
		["lucide-cloud-moon-rain"] = "rbxassetid://10709805838",
		["lucide-cloud-off"] = "rbxassetid://10709806060",
		["lucide-cloud-rain"] = "rbxassetid://10709806277",
		["lucide-cloud-rain-wind"] = "rbxassetid://10709806166",
		["lucide-cloud-snow"] = "rbxassetid://10709806374",
		["lucide-cloud-sun"] = "rbxassetid://10709806631",
		["lucide-cloud-sun-rain"] = "rbxassetid://10709806475",
		["lucide-cloudy"] = "rbxassetid://10709806859",
		["lucide-clover"] = "rbxassetid://10709806995",
		["lucide-code"] = "rbxassetid://10709810463",
		["lucide-code-2"] = "rbxassetid://10709807111",
		["lucide-codepen"] = "rbxassetid://10709810534",
		["lucide-codesandbox"] = "rbxassetid://10709810676",
		["lucide-coffee"] = "rbxassetid://10709810814",
		["lucide-cog"] = "rbxassetid://10709810948",
		["lucide-coins"] = "rbxassetid://10709811110",
		["lucide-columns"] = "rbxassetid://10709811261",
		["lucide-command"] = "rbxassetid://10709811365",
		["lucide-compass"] = "rbxassetid://10709811445",
		["lucide-component"] = "rbxassetid://10709811595",
		["lucide-concierge-bell"] = "rbxassetid://10709811706",
		["lucide-connection"] = "rbxassetid://10747361219",
		["lucide-contact"] = "rbxassetid://10709811834",
		["lucide-contrast"] = "rbxassetid://10709811939",
		["lucide-cookie"] = "rbxassetid://10709812067",
		["lucide-copy"] = "rbxassetid://10709812159",
		["lucide-copyleft"] = "rbxassetid://10709812251",
		["lucide-copyright"] = "rbxassetid://10709812311",
		["lucide-corner-down-left"] = "rbxassetid://10709812396",
		["lucide-corner-down-right"] = "rbxassetid://10709812485",
		["lucide-corner-left-down"] = "rbxassetid://10709812632",
		["lucide-corner-left-up"] = "rbxassetid://10709812784",
		["lucide-corner-right-down"] = "rbxassetid://10709812939",
		["lucide-corner-right-up"] = "rbxassetid://10709813094",
		["lucide-corner-up-left"] = "rbxassetid://10709813185",
		["lucide-corner-up-right"] = "rbxassetid://10709813281",
		["lucide-cpu"] = "rbxassetid://10709813383",
		["lucide-croissant"] = "rbxassetid://10709818125",
		["lucide-crop"] = "rbxassetid://10709818245",
		["lucide-cross"] = "rbxassetid://10709818399",
		["lucide-crosshair"] = "rbxassetid://10709818534",
		["lucide-crown"] = "rbxassetid://10709818626",
		["lucide-cup-soda"] = "rbxassetid://10709818763",
		["lucide-curly-braces"] = "rbxassetid://10709818847",
		["lucide-currency"] = "rbxassetid://10709818931",
		["lucide-database"] = "rbxassetid://10709818996",
		["lucide-delete"] = "rbxassetid://10709819059",
		["lucide-diamond"] = "rbxassetid://10709819149",
		["lucide-dice-1"] = "rbxassetid://10709819266",
		["lucide-dice-2"] = "rbxassetid://10709819361",
		["lucide-dice-3"] = "rbxassetid://10709819508",
		["lucide-dice-4"] = "rbxassetid://10709819670",
		["lucide-dice-5"] = "rbxassetid://10709819801",
		["lucide-dice-6"] = "rbxassetid://10709819896",
		["lucide-dices"] = "rbxassetid://10723343321",
		["lucide-diff"] = "rbxassetid://10723343416",
		["lucide-disc"] = "rbxassetid://10723343537",
		["lucide-divide"] = "rbxassetid://10723343805",
		["lucide-divide-circle"] = "rbxassetid://10723343636",
		["lucide-divide-square"] = "rbxassetid://10723343737",
		["lucide-dollar-sign"] = "rbxassetid://10723343958",
		["lucide-download"] = "rbxassetid://10723344270",
		["lucide-download-cloud"] = "rbxassetid://10723344088",
		["lucide-droplet"] = "rbxassetid://10723344432",
		["lucide-droplets"] = "rbxassetid://10734883356",
		["lucide-drumstick"] = "rbxassetid://10723344737",
		["lucide-edit"] = "rbxassetid://10734883598",
		["lucide-edit-2"] = "rbxassetid://10723344885",
		["lucide-edit-3"] = "rbxassetid://10723345088",
		["lucide-egg"] = "rbxassetid://10723345518",
		["lucide-egg-fried"] = "rbxassetid://10723345347",
		["lucide-electricity"] = "rbxassetid://10723345749",
		["lucide-electricity-off"] = "rbxassetid://10723345643",
		["lucide-equal"] = "rbxassetid://10723345990",
		["lucide-equal-not"] = "rbxassetid://10723345866",
		["lucide-eraser"] = "rbxassetid://10723346158",
		["lucide-euro"] = "rbxassetid://10723346372",
		["lucide-expand"] = "rbxassetid://10723346553",
		["lucide-external-link"] = "rbxassetid://10723346684",
		["lucide-eye"] = "rbxassetid://10723346959",
		["lucide-eye-off"] = "rbxassetid://10723346871",
		["lucide-factory"] = "rbxassetid://10723347051",
		["lucide-fan"] = "rbxassetid://10723354359",
		["lucide-fast-forward"] = "rbxassetid://10723354521",
		["lucide-feather"] = "rbxassetid://10723354671",
		["lucide-figma"] = "rbxassetid://10723354801",
		["lucide-file"] = "rbxassetid://10723374641",
		["lucide-file-archive"] = "rbxassetid://10723354921",
		["lucide-file-audio"] = "rbxassetid://10723355148",
		["lucide-file-audio-2"] = "rbxassetid://10723355026",
		["lucide-file-axis-3d"] = "rbxassetid://10723355272",
		["lucide-file-badge"] = "rbxassetid://10723355622",
		["lucide-file-badge-2"] = "rbxassetid://10723355451",
		["lucide-file-bar-chart"] = "rbxassetid://10723355887",
		["lucide-file-bar-chart-2"] = "rbxassetid://10723355746",
		["lucide-file-box"] = "rbxassetid://10723355989",
		["lucide-file-check"] = "rbxassetid://10723356210",
		["lucide-file-check-2"] = "rbxassetid://10723356100",
		["lucide-file-clock"] = "rbxassetid://10723356329",
		["lucide-file-code"] = "rbxassetid://10723356507",
		["lucide-file-cog"] = "rbxassetid://10723356830",
		["lucide-file-cog-2"] = "rbxassetid://10723356676",
		["lucide-file-diff"] = "rbxassetid://10723357039",
		["lucide-file-digit"] = "rbxassetid://10723357151",
		["lucide-file-down"] = "rbxassetid://10723357322",
		["lucide-file-edit"] = "rbxassetid://10723357495",
		["lucide-file-heart"] = "rbxassetid://10723357637",
		["lucide-file-image"] = "rbxassetid://10723357790",
		["lucide-file-input"] = "rbxassetid://10723357933",
		["lucide-file-json"] = "rbxassetid://10723364435",
		["lucide-file-json-2"] = "rbxassetid://10723364361",
		["lucide-file-key"] = "rbxassetid://10723364605",
		["lucide-file-key-2"] = "rbxassetid://10723364515",
		["lucide-file-line-chart"] = "rbxassetid://10723364725",
		["lucide-file-lock"] = "rbxassetid://10723364957",
		["lucide-file-lock-2"] = "rbxassetid://10723364861",
		["lucide-file-minus"] = "rbxassetid://10723365254",
		["lucide-file-minus-2"] = "rbxassetid://10723365086",
		["lucide-file-output"] = "rbxassetid://10723365457",
		["lucide-file-pie-chart"] = "rbxassetid://10723365598",
		["lucide-file-plus"] = "rbxassetid://10723365877",
		["lucide-file-plus-2"] = "rbxassetid://10723365766",
		["lucide-file-question"] = "rbxassetid://10723365987",
		["lucide-file-scan"] = "rbxassetid://10723366167",
		["lucide-file-search"] = "rbxassetid://10723366550",
		["lucide-file-search-2"] = "rbxassetid://10723366340",
		["lucide-file-signature"] = "rbxassetid://10723366741",
		["lucide-file-spreadsheet"] = "rbxassetid://10723366962",
		["lucide-file-symlink"] = "rbxassetid://10723367098",
		["lucide-file-terminal"] = "rbxassetid://10723367244",
		["lucide-file-text"] = "rbxassetid://10723367380",
		["lucide-file-type"] = "rbxassetid://10723367606",
		["lucide-file-type-2"] = "rbxassetid://10723367509",
		["lucide-file-up"] = "rbxassetid://10723367734",
		["lucide-file-video"] = "rbxassetid://10723373884",
		["lucide-file-video-2"] = "rbxassetid://10723367834",
		["lucide-file-volume"] = "rbxassetid://10723374172",
		["lucide-file-volume-2"] = "rbxassetid://10723374030",
		["lucide-file-warning"] = "rbxassetid://10723374276",
		["lucide-file-x"] = "rbxassetid://10723374544",
		["lucide-file-x-2"] = "rbxassetid://10723374378",
		["lucide-files"] = "rbxassetid://10723374759",
		["lucide-film"] = "rbxassetid://10723374981",
		["lucide-filter"] = "rbxassetid://10723375128",
		["lucide-fingerprint"] = "rbxassetid://10723375250",
		["lucide-flag"] = "rbxassetid://10723375890",
		["lucide-flag-off"] = "rbxassetid://10723375443",
		["lucide-flag-triangle-left"] = "rbxassetid://10723375608",
		["lucide-flag-triangle-right"] = "rbxassetid://10723375727",
		["lucide-flame"] = "rbxassetid://10723376114",
		["lucide-flashlight"] = "rbxassetid://10723376471",
		["lucide-flashlight-off"] = "rbxassetid://10723376365",
		["lucide-flask-conical"] = "rbxassetid://10734883986",
		["lucide-flask-round"] = "rbxassetid://10723376614",
		["lucide-flip-horizontal"] = "rbxassetid://10723376884",
		["lucide-flip-horizontal-2"] = "rbxassetid://10723376745",
		["lucide-flip-vertical"] = "rbxassetid://10723377138",
		["lucide-flip-vertical-2"] = "rbxassetid://10723377026",
		["lucide-flower"] = "rbxassetid://10747830374",
		["lucide-flower-2"] = "rbxassetid://10723377305",
		["lucide-focus"] = "rbxassetid://10723377537",
		["lucide-folder"] = "rbxassetid://10723387563",
		["lucide-folder-archive"] = "rbxassetid://10723384478",
		["lucide-folder-check"] = "rbxassetid://10723384605",
		["lucide-folder-clock"] = "rbxassetid://10723384731",
		["lucide-folder-closed"] = "rbxassetid://10723384893",
		["lucide-folder-cog"] = "rbxassetid://10723385213",
		["lucide-folder-cog-2"] = "rbxassetid://10723385036",
		["lucide-folder-down"] = "rbxassetid://10723385338",
		["lucide-folder-edit"] = "rbxassetid://10723385445",
		["lucide-folder-heart"] = "rbxassetid://10723385545",
		["lucide-folder-input"] = "rbxassetid://10723385721",
		["lucide-folder-key"] = "rbxassetid://10723385848",
		["lucide-folder-lock"] = "rbxassetid://10723386005",
		["lucide-folder-minus"] = "rbxassetid://10723386127",
		["lucide-folder-open"] = "rbxassetid://10723386277",
		["lucide-folder-output"] = "rbxassetid://10723386386",
		["lucide-folder-plus"] = "rbxassetid://10723386531",
		["lucide-folder-search"] = "rbxassetid://10723386787",
		["lucide-folder-search-2"] = "rbxassetid://10723386674",
		["lucide-folder-symlink"] = "rbxassetid://10723386930",
		["lucide-folder-tree"] = "rbxassetid://10723387085",
		["lucide-folder-up"] = "rbxassetid://10723387265",
		["lucide-folder-x"] = "rbxassetid://10723387448",
		["lucide-folders"] = "rbxassetid://10723387721",
		["lucide-form-input"] = "rbxassetid://10723387841",
		["lucide-forward"] = "rbxassetid://10723388016",
		["lucide-frame"] = "rbxassetid://10723394389",
		["lucide-framer"] = "rbxassetid://10723394565",
		["lucide-frown"] = "rbxassetid://10723394681",
		["lucide-fuel"] = "rbxassetid://10723394846",
		["lucide-function-square"] = "rbxassetid://10723395041",
		["lucide-gamepad"] = "rbxassetid://10723395457",
		["lucide-gamepad-2"] = "rbxassetid://10723395215",
		["lucide-gauge"] = "rbxassetid://10723395708",
		["lucide-gavel"] = "rbxassetid://10723395896",
		["lucide-gem"] = "rbxassetid://10723396000",
		["lucide-ghost"] = "rbxassetid://10723396107",
		["lucide-gift"] = "rbxassetid://10723396402",
		["lucide-gift-card"] = "rbxassetid://10723396225",
		["lucide-git-branch"] = "rbxassetid://10723396676",
		["lucide-git-branch-plus"] = "rbxassetid://10723396542",
		["lucide-git-commit"] = "rbxassetid://10723396812",
		["lucide-git-compare"] = "rbxassetid://10723396954",
		["lucide-git-fork"] = "rbxassetid://10723397049",
		["lucide-git-merge"] = "rbxassetid://10723397165",
		["lucide-git-pull-request"] = "rbxassetid://10723397431",
		["lucide-git-pull-request-closed"] = "rbxassetid://10723397268",
		["lucide-git-pull-request-draft"] = "rbxassetid://10734884302",
		["lucide-glass"] = "rbxassetid://10723397788",
		["lucide-glass-2"] = "rbxassetid://10723397529",
		["lucide-glass-water"] = "rbxassetid://10723397678",
		["lucide-glasses"] = "rbxassetid://10723397895",
		["lucide-globe"] = "rbxassetid://10723404337",
		["lucide-globe-2"] = "rbxassetid://10723398002",
		["lucide-grab"] = "rbxassetid://10723404472",
		["lucide-graduation-cap"] = "rbxassetid://10723404691",
		["lucide-grape"] = "rbxassetid://10723404822",
		["lucide-grid"] = "rbxassetid://10723404936",
		["lucide-grip-horizontal"] = "rbxassetid://10723405089",
		["lucide-grip-vertical"] = "rbxassetid://10723405236",
		["lucide-hammer"] = "rbxassetid://10723405360",
		["lucide-hand"] = "rbxassetid://10723405649",
		["lucide-hand-metal"] = "rbxassetid://10723405508",
		["lucide-hard-drive"] = "rbxassetid://10723405749",
		["lucide-hard-hat"] = "rbxassetid://10723405859",
		["lucide-hash"] = "rbxassetid://10723405975",
		["lucide-haze"] = "rbxassetid://10723406078",
		["lucide-headphones"] = "rbxassetid://10723406165",
		["lucide-heart"] = "rbxassetid://10723406885",
		["lucide-heart-crack"] = "rbxassetid://10723406299",
		["lucide-heart-handshake"] = "rbxassetid://10723406480",
		["lucide-heart-off"] = "rbxassetid://10723406662",
		["lucide-heart-pulse"] = "rbxassetid://10723406795",
		["lucide-help-circle"] = "rbxassetid://10723406988",
		["lucide-hexagon"] = "rbxassetid://10723407092",
		["lucide-highlighter"] = "rbxassetid://10723407192",
		["lucide-history"] = "rbxassetid://10723407335",
		["lucide-home"] = "rbxassetid://10723407389",
		["lucide-hourglass"] = "rbxassetid://10723407498",
		["lucide-ice-cream"] = "rbxassetid://10723414308",
		["lucide-image"] = "rbxassetid://10723415040",
		["lucide-image-minus"] = "rbxassetid://10723414487",
		["lucide-image-off"] = "rbxassetid://10723414677",
		["lucide-image-plus"] = "rbxassetid://10723414827",
		["lucide-import"] = "rbxassetid://10723415205",
		["lucide-inbox"] = "rbxassetid://10723415335",
		["lucide-indent"] = "rbxassetid://10723415494",
		["lucide-indian-rupee"] = "rbxassetid://10723415642",
		["lucide-infinity"] = "rbxassetid://10723415766",
		["lucide-info"] = "rbxassetid://10723415903",
		["lucide-inspect"] = "rbxassetid://10723416057",
		["lucide-italic"] = "rbxassetid://10723416195",
		["lucide-japanese-yen"] = "rbxassetid://10723416363",
		["lucide-joystick"] = "rbxassetid://10723416527",
		["lucide-key"] = "rbxassetid://10723416652",
		["lucide-keyboard"] = "rbxassetid://10723416765",
		["lucide-lamp"] = "rbxassetid://10723417513",
		["lucide-lamp-ceiling"] = "rbxassetid://10723416922",
		["lucide-lamp-desk"] = "rbxassetid://10723417016",
		["lucide-lamp-floor"] = "rbxassetid://10723417131",
		["lucide-lamp-wall-down"] = "rbxassetid://10723417240",
		["lucide-lamp-wall-up"] = "rbxassetid://10723417356",
		["lucide-landmark"] = "rbxassetid://10723417608",
		["lucide-languages"] = "rbxassetid://10723417703",
		["lucide-laptop"] = "rbxassetid://10723423881",
		["lucide-laptop-2"] = "rbxassetid://10723417797",
		["lucide-lasso"] = "rbxassetid://10723424235",
		["lucide-lasso-select"] = "rbxassetid://10723424058",
		["lucide-laugh"] = "rbxassetid://10723424372",
		["lucide-layers"] = "rbxassetid://10723424505",
		["lucide-layout"] = "rbxassetid://10723425376",
		["lucide-layout-dashboard"] = "rbxassetid://10723424646",
		["lucide-layout-grid"] = "rbxassetid://10723424838",
		["lucide-layout-list"] = "rbxassetid://10723424963",
		["lucide-layout-template"] = "rbxassetid://10723425187",
		["lucide-leaf"] = "rbxassetid://10723425539",
		["lucide-library"] = "rbxassetid://10723425615",
		["lucide-life-buoy"] = "rbxassetid://10723425685",
		["lucide-lightbulb"] = "rbxassetid://10723425852",
		["lucide-lightbulb-off"] = "rbxassetid://10723425762",
		["lucide-line-chart"] = "rbxassetid://10723426393",
		["lucide-link"] = "rbxassetid://10723426722",
		["lucide-link-2"] = "rbxassetid://10723426595",
		["lucide-link-2-off"] = "rbxassetid://10723426513",
		["lucide-list"] = "rbxassetid://10723433811",
		["lucide-list-checks"] = "rbxassetid://10734884548",
		["lucide-list-end"] = "rbxassetid://10723426886",
		["lucide-list-minus"] = "rbxassetid://10723426986",
		["lucide-list-music"] = "rbxassetid://10723427081",
		["lucide-list-ordered"] = "rbxassetid://10723427199",
		["lucide-list-plus"] = "rbxassetid://10723427334",
		["lucide-list-start"] = "rbxassetid://10723427494",
		["lucide-list-video"] = "rbxassetid://10723427619",
		["lucide-list-x"] = "rbxassetid://10723433655",
		["lucide-loader"] = "rbxassetid://10723434070",
		["lucide-loader-2"] = "rbxassetid://10723433935",
		["lucide-locate"] = "rbxassetid://10723434557",
		["lucide-locate-fixed"] = "rbxassetid://10723434236",
		["lucide-locate-off"] = "rbxassetid://10723434379",
		["lucide-lock"] = "rbxassetid://10723434711",
		["lucide-log-in"] = "rbxassetid://10723434830",
		["lucide-log-out"] = "rbxassetid://10723434906",
		["lucide-luggage"] = "rbxassetid://10723434993",
		["lucide-magnet"] = "rbxassetid://10723435069",
		["lucide-mail"] = "rbxassetid://10734885430",
		["lucide-mail-check"] = "rbxassetid://10723435182",
		["lucide-mail-minus"] = "rbxassetid://10723435261",
		["lucide-mail-open"] = "rbxassetid://10723435342",
		["lucide-mail-plus"] = "rbxassetid://10723435443",
		["lucide-mail-question"] = "rbxassetid://10723435515",
		["lucide-mail-search"] = "rbxassetid://10734884739",
		["lucide-mail-warning"] = "rbxassetid://10734885015",
		["lucide-mail-x"] = "rbxassetid://10734885247",
		["lucide-mails"] = "rbxassetid://10734885614",
		["lucide-map"] = "rbxassetid://10734886202",
		["lucide-map-pin"] = "rbxassetid://10734886004",
		["lucide-map-pin-off"] = "rbxassetid://10734885803",
		["lucide-maximize"] = "rbxassetid://10734886735",
		["lucide-maximize-2"] = "rbxassetid://10734886496",
		["lucide-medal"] = "rbxassetid://10734887072",
		["lucide-megaphone"] = "rbxassetid://10734887454",
		["lucide-megaphone-off"] = "rbxassetid://10734887311",
		["lucide-meh"] = "rbxassetid://10734887603",
		["lucide-menu"] = "rbxassetid://10734887784",
		["lucide-message-circle"] = "rbxassetid://10734888000",
		["lucide-message-square"] = "rbxassetid://10734888228",
		["lucide-mic"] = "rbxassetid://10734888864",
		["lucide-mic-2"] = "rbxassetid://10734888430",
		["lucide-mic-off"] = "rbxassetid://10734888646",
		["lucide-microscope"] = "rbxassetid://10734889106",
		["lucide-microwave"] = "rbxassetid://10734895076",
		["lucide-milestone"] = "rbxassetid://10734895310",
		["lucide-minimize"] = "rbxassetid://10734895698",
		["lucide-minimize-2"] = "rbxassetid://10734895530",
		["lucide-minus"] = "rbxassetid://10734896206",
		["lucide-minus-circle"] = "rbxassetid://10734895856",
		["lucide-minus-square"] = "rbxassetid://10734896029",
		["lucide-monitor"] = "rbxassetid://10734896881",
		["lucide-monitor-off"] = "rbxassetid://10734896360",
		["lucide-monitor-speaker"] = "rbxassetid://10734896512",
		["lucide-moon"] = "rbxassetid://10734897102",
		["lucide-more-horizontal"] = "rbxassetid://10734897250",
		["lucide-more-vertical"] = "rbxassetid://10734897387",
		["lucide-mountain"] = "rbxassetid://10734897956",
		["lucide-mountain-snow"] = "rbxassetid://10734897665",
		["lucide-mouse"] = "rbxassetid://10734898592",
		["lucide-mouse-pointer"] = "rbxassetid://10734898476",
		["lucide-mouse-pointer-2"] = "rbxassetid://10734898194",
		["lucide-mouse-pointer-click"] = "rbxassetid://10734898355",
		["lucide-move"] = "rbxassetid://10734900011",
		["lucide-move-3d"] = "rbxassetid://10734898756",
		["lucide-move-diagonal"] = "rbxassetid://10734899164",
		["lucide-move-diagonal-2"] = "rbxassetid://10734898934",
		["lucide-move-horizontal"] = "rbxassetid://10734899414",
		["lucide-move-vertical"] = "rbxassetid://10734899821",
		["lucide-music"] = "rbxassetid://10734905958",
		["lucide-music-2"] = "rbxassetid://10734900215",
		["lucide-music-3"] = "rbxassetid://10734905665",
		["lucide-music-4"] = "rbxassetid://10734905823",
		["lucide-navigation"] = "rbxassetid://10734906744",
		["lucide-navigation-2"] = "rbxassetid://10734906332",
		["lucide-navigation-2-off"] = "rbxassetid://10734906144",
		["lucide-navigation-off"] = "rbxassetid://10734906580",
		["lucide-network"] = "rbxassetid://10734906975",
		["lucide-newspaper"] = "rbxassetid://10734907168",
		["lucide-octagon"] = "rbxassetid://10734907361",
		["lucide-option"] = "rbxassetid://10734907649",
		["lucide-outdent"] = "rbxassetid://10734907933",
		["lucide-package"] = "rbxassetid://10734909540",
		["lucide-package-2"] = "rbxassetid://10734908151",
		["lucide-package-check"] = "rbxassetid://10734908384",
		["lucide-package-minus"] = "rbxassetid://10734908626",
		["lucide-package-open"] = "rbxassetid://10734908793",
		["lucide-package-plus"] = "rbxassetid://10734909016",
		["lucide-package-search"] = "rbxassetid://10734909196",
		["lucide-package-x"] = "rbxassetid://10734909375",
		["lucide-paint-bucket"] = "rbxassetid://10734909847",
		["lucide-paintbrush"] = "rbxassetid://10734910187",
		["lucide-paintbrush-2"] = "rbxassetid://10734910030",
		["lucide-palette"] = "rbxassetid://10734910430",
		["lucide-palmtree"] = "rbxassetid://10734910680",
		["lucide-paperclip"] = "rbxassetid://10734910927",
		["lucide-party-popper"] = "rbxassetid://10734918735",
		["lucide-pause"] = "rbxassetid://10734919336",
		["lucide-pause-circle"] = "rbxassetid://10735024209",
		["lucide-pause-octagon"] = "rbxassetid://10734919143",
		["lucide-pen-tool"] = "rbxassetid://10734919503",
		["lucide-pencil"] = "rbxassetid://10734919691",
		["lucide-percent"] = "rbxassetid://10734919919",
		["lucide-person-standing"] = "rbxassetid://10734920149",
		["lucide-phone"] = "rbxassetid://10734921524",
		["lucide-phone-call"] = "rbxassetid://10734920305",
		["lucide-phone-forwarded"] = "rbxassetid://10734920508",
		["lucide-phone-incoming"] = "rbxassetid://10734920694",
		["lucide-phone-missed"] = "rbxassetid://10734920845",
		["lucide-phone-off"] = "rbxassetid://10734921077",
		["lucide-phone-outgoing"] = "rbxassetid://10734921288",
		["lucide-pie-chart"] = "rbxassetid://10734921727",
		["lucide-piggy-bank"] = "rbxassetid://10734921935",
		["lucide-pin"] = "rbxassetid://10734922324",
		["lucide-pin-off"] = "rbxassetid://10734922180",
		["lucide-pipette"] = "rbxassetid://10734922497",
		["lucide-pizza"] = "rbxassetid://10734922774",
		["lucide-plane"] = "rbxassetid://10734922971",
		["lucide-play"] = "rbxassetid://10734923549",
		["lucide-play-circle"] = "rbxassetid://10734923214",
		["lucide-plus"] = "rbxassetid://10734924532",
		["lucide-plus-circle"] = "rbxassetid://10734923868",
		["lucide-plus-square"] = "rbxassetid://10734924219",
		["lucide-podcast"] = "rbxassetid://10734929553",
		["lucide-pointer"] = "rbxassetid://10734929723",
		["lucide-pound-sterling"] = "rbxassetid://10734929981",
		["lucide-power"] = "rbxassetid://10734930466",
		["lucide-power-off"] = "rbxassetid://10734930257",
		["lucide-printer"] = "rbxassetid://10734930632",
		["lucide-puzzle"] = "rbxassetid://10734930886",
		["lucide-quote"] = "rbxassetid://10734931234",
		["lucide-radio"] = "rbxassetid://10734931596",
		["lucide-radio-receiver"] = "rbxassetid://10734931402",
		["lucide-rectangle-horizontal"] = "rbxassetid://10734931777",
		["lucide-rectangle-vertical"] = "rbxassetid://10734932081",
		["lucide-recycle"] = "rbxassetid://10734932295",
		["lucide-redo"] = "rbxassetid://10734932822",
		["lucide-redo-2"] = "rbxassetid://10734932586",
		["lucide-refresh-ccw"] = "rbxassetid://10734933056",
		["lucide-refresh-cw"] = "rbxassetid://10734933222",
		["lucide-refrigerator"] = "rbxassetid://10734933465",
		["lucide-regex"] = "rbxassetid://10734933655",
		["lucide-repeat"] = "rbxassetid://10734933966",
		["lucide-repeat-1"] = "rbxassetid://10734933826",
		["lucide-reply"] = "rbxassetid://10734934252",
		["lucide-reply-all"] = "rbxassetid://10734934132",
		["lucide-rewind"] = "rbxassetid://10734934347",
		["lucide-rocket"] = "rbxassetid://10734934585",
		["lucide-rocking-chair"] = "rbxassetid://10734939942",
		["lucide-rotate-3d"] = "rbxassetid://10734940107",
		["lucide-rotate-ccw"] = "rbxassetid://10734940376",
		["lucide-rotate-cw"] = "rbxassetid://10734940654",
		["lucide-rss"] = "rbxassetid://10734940825",
		["lucide-ruler"] = "rbxassetid://10734941018",
		["lucide-russian-ruble"] = "rbxassetid://10734941199",
		["lucide-sailboat"] = "rbxassetid://10734941354",
		["lucide-save"] = "rbxassetid://10734941499",
		["lucide-scale"] = "rbxassetid://10734941912",
		["lucide-scale-3d"] = "rbxassetid://10734941739",
		["lucide-scaling"] = "rbxassetid://10734942072",
		["lucide-scan"] = "rbxassetid://10734942565",
		["lucide-scan-face"] = "rbxassetid://10734942198",
		["lucide-scan-line"] = "rbxassetid://10734942351",
		["lucide-scissors"] = "rbxassetid://10734942778",
		["lucide-screen-share"] = "rbxassetid://10734943193",
		["lucide-screen-share-off"] = "rbxassetid://10734942967",
		["lucide-scroll"] = "rbxassetid://10734943448",
		["lucide-search"] = "rbxassetid://10734943674",
		["lucide-send"] = "rbxassetid://10734943902",
		["lucide-separator-horizontal"] = "rbxassetid://10734944115",
		["lucide-separator-vertical"] = "rbxassetid://10734944326",
		["lucide-server"] = "rbxassetid://10734949856",
		["lucide-server-cog"] = "rbxassetid://10734944444",
		["lucide-server-crash"] = "rbxassetid://10734944554",
		["lucide-server-off"] = "rbxassetid://10734944668",
		["lucide-settings"] = "rbxassetid://10734950309",
		["lucide-settings-2"] = "rbxassetid://10734950020",
		["lucide-share"] = "rbxassetid://10734950813",
		["lucide-share-2"] = "rbxassetid://10734950553",
		["lucide-sheet"] = "rbxassetid://10734951038",
		["lucide-shield"] = "rbxassetid://10734951847",
		["lucide-shield-alert"] = "rbxassetid://10734951173",
		["lucide-shield-check"] = "rbxassetid://10734951367",
		["lucide-shield-close"] = "rbxassetid://10734951535",
		["lucide-shield-off"] = "rbxassetid://10734951684",
		["lucide-shirt"] = "rbxassetid://10734952036",
		["lucide-shopping-bag"] = "rbxassetid://10734952273",
		["lucide-shopping-cart"] = "rbxassetid://10734952479",
		["lucide-shovel"] = "rbxassetid://10734952773",
		["lucide-shower-head"] = "rbxassetid://10734952942",
		["lucide-shrink"] = "rbxassetid://10734953073",
		["lucide-shrub"] = "rbxassetid://10734953241",
		["lucide-shuffle"] = "rbxassetid://10734953451",
		["lucide-sidebar"] = "rbxassetid://10734954301",
		["lucide-sidebar-close"] = "rbxassetid://10734953715",
		["lucide-sidebar-open"] = "rbxassetid://10734954000",
		["lucide-sigma"] = "rbxassetid://10734954538",
		["lucide-signal"] = "rbxassetid://10734961133",
		["lucide-signal-high"] = "rbxassetid://10734954807",
		["lucide-signal-low"] = "rbxassetid://10734955080",
		["lucide-signal-medium"] = "rbxassetid://10734955336",
		["lucide-signal-zero"] = "rbxassetid://10734960878",
		["lucide-siren"] = "rbxassetid://10734961284",
		["lucide-skip-back"] = "rbxassetid://10734961526",
		["lucide-skip-forward"] = "rbxassetid://10734961809",
		["lucide-skull"] = "rbxassetid://10734962068",
		["lucide-slack"] = "rbxassetid://10734962339",
		["lucide-slash"] = "rbxassetid://10734962600",
		["lucide-slice"] = "rbxassetid://10734963024",
		["lucide-sliders"] = "rbxassetid://10734963400",
		["lucide-sliders-horizontal"] = "rbxassetid://10734963191",
		["lucide-smartphone"] = "rbxassetid://10734963940",
		["lucide-smartphone-charging"] = "rbxassetid://10734963671",
		["lucide-smile"] = "rbxassetid://10734964441",
		["lucide-smile-plus"] = "rbxassetid://10734964188",
		["lucide-snowflake"] = "rbxassetid://10734964600",
		["lucide-sofa"] = "rbxassetid://10734964852",
		["lucide-sort-asc"] = "rbxassetid://10734965115",
		["lucide-sort-desc"] = "rbxassetid://10734965287",
		["lucide-speaker"] = "rbxassetid://10734965419",
		["lucide-sprout"] = "rbxassetid://10734965572",
		["lucide-square"] = "rbxassetid://10734965702",
		["lucide-star"] = "rbxassetid://10734966248",
		["lucide-star-half"] = "rbxassetid://10734965897",
		["lucide-star-off"] = "rbxassetid://10734966097",
		["lucide-stethoscope"] = "rbxassetid://10734966384",
		["lucide-sticker"] = "rbxassetid://10734972234",
		["lucide-sticky-note"] = "rbxassetid://10734972463",
		["lucide-stop-circle"] = "rbxassetid://10734972621",
		["lucide-stretch-horizontal"] = "rbxassetid://10734972862",
		["lucide-stretch-vertical"] = "rbxassetid://10734973130",
		["lucide-strikethrough"] = "rbxassetid://10734973290",
		["lucide-subscript"] = "rbxassetid://10734973457",
		["lucide-sun"] = "rbxassetid://10734974297",
		["lucide-sun-dim"] = "rbxassetid://10734973645",
		["lucide-sun-medium"] = "rbxassetid://10734973778",
		["lucide-sun-moon"] = "rbxassetid://10734973999",
		["lucide-sun-snow"] = "rbxassetid://10734974130",
		["lucide-sunrise"] = "rbxassetid://10734974522",
		["lucide-sunset"] = "rbxassetid://10734974689",
		["lucide-superscript"] = "rbxassetid://10734974850",
		["lucide-swiss-franc"] = "rbxassetid://10734975024",
		["lucide-switch-camera"] = "rbxassetid://10734975214",
		["lucide-sword"] = "rbxassetid://10734975486",
		["lucide-swords"] = "rbxassetid://10734975692",
		["lucide-syringe"] = "rbxassetid://10734975932",
		["lucide-table"] = "rbxassetid://10734976230",
		["lucide-table-2"] = "rbxassetid://10734976097",
		["lucide-tablet"] = "rbxassetid://10734976394",
		["lucide-tag"] = "rbxassetid://10734976528",
		["lucide-tags"] = "rbxassetid://10734976739",
		["lucide-target"] = "rbxassetid://10734977012",
		["lucide-tent"] = "rbxassetid://10734981750",
		["lucide-terminal"] = "rbxassetid://10734982144",
		["lucide-terminal-square"] = "rbxassetid://10734981995",
		["lucide-text-cursor"] = "rbxassetid://10734982395",
		["lucide-text-cursor-input"] = "rbxassetid://10734982297",
		["lucide-thermometer"] = "rbxassetid://10734983134",
		["lucide-thermometer-snowflake"] = "rbxassetid://10734982571",
		["lucide-thermometer-sun"] = "rbxassetid://10734982771",
		["lucide-thumbs-down"] = "rbxassetid://10734983359",
		["lucide-thumbs-up"] = "rbxassetid://10734983629",
		["lucide-ticket"] = "rbxassetid://10734983868",
		["lucide-timer"] = "rbxassetid://10734984606",
		["lucide-timer-off"] = "rbxassetid://10734984138",
		["lucide-timer-reset"] = "rbxassetid://10734984355",
		["lucide-toggle-left"] = "rbxassetid://10734984834",
		["lucide-toggle-right"] = "rbxassetid://10734985040",
		["lucide-tornado"] = "rbxassetid://10734985247",
		["lucide-toy-brick"] = "rbxassetid://10747361919",
		["lucide-train"] = "rbxassetid://10747362105",
		["lucide-trash"] = "rbxassetid://10747362393",
		["lucide-trash-2"] = "rbxassetid://10747362241",
		["lucide-tree-deciduous"] = "rbxassetid://10747362534",
		["lucide-tree-pine"] = "rbxassetid://10747362748",
		["lucide-trees"] = "rbxassetid://10747363016",
		["lucide-trending-down"] = "rbxassetid://10747363205",
		["lucide-trending-up"] = "rbxassetid://10747363465",
		["lucide-triangle"] = "rbxassetid://10747363621",
		["lucide-trophy"] = "rbxassetid://10747363809",
		["lucide-truck"] = "rbxassetid://10747364031",
		["lucide-tv"] = "rbxassetid://10747364593",
		["lucide-tv-2"] = "rbxassetid://10747364302",
		["lucide-type"] = "rbxassetid://10747364761",
		["lucide-umbrella"] = "rbxassetid://10747364971",
		["lucide-underline"] = "rbxassetid://10747365191",
		["lucide-undo"] = "rbxassetid://10747365484",
		["lucide-undo-2"] = "rbxassetid://10747365359",
		["lucide-unlink"] = "rbxassetid://10747365771",
		["lucide-unlink-2"] = "rbxassetid://10747397871",
		["lucide-unlock"] = "rbxassetid://10747366027",
		["lucide-upload"] = "rbxassetid://10747366434",
		["lucide-upload-cloud"] = "rbxassetid://10747366266",
		["lucide-usb"] = "rbxassetid://10747366606",
		["lucide-user"] = "rbxassetid://10747373176",
		["lucide-user-check"] = "rbxassetid://10747371901",
		["lucide-user-cog"] = "rbxassetid://10747372167",
		["lucide-user-minus"] = "rbxassetid://10747372346",
		["lucide-user-plus"] = "rbxassetid://10747372702",
		["lucide-user-x"] = "rbxassetid://10747372992",
		["lucide-users"] = "rbxassetid://10747373426",
		["lucide-utensils"] = "rbxassetid://10747373821",
		["lucide-utensils-crossed"] = "rbxassetid://10747373629",
		["lucide-venetian-mask"] = "rbxassetid://10747374003",
		["lucide-verified"] = "rbxassetid://10747374131",
		["lucide-vibrate"] = "rbxassetid://10747374489",
		["lucide-vibrate-off"] = "rbxassetid://10747374269",
		["lucide-video"] = "rbxassetid://10747374938",
		["lucide-video-off"] = "rbxassetid://10747374721",
		["lucide-view"] = "rbxassetid://10747375132",
		["lucide-voicemail"] = "rbxassetid://10747375281",
		["lucide-volume"] = "rbxassetid://10747376008",
		["lucide-volume-1"] = "rbxassetid://10747375450",
		["lucide-volume-2"] = "rbxassetid://10747375679",
		["lucide-volume-x"] = "rbxassetid://10747375880",
		["lucide-wallet"] = "rbxassetid://10747376205",
		["lucide-wand"] = "rbxassetid://10747376565",
		["lucide-wand-2"] = "rbxassetid://10747376349",
		["lucide-watch"] = "rbxassetid://10747376722",
		["lucide-waves"] = "rbxassetid://10747376931",
		["lucide-webcam"] = "rbxassetid://10747381992",
		["lucide-wifi"] = "rbxassetid://10747382504",
		["lucide-wifi-off"] = "rbxassetid://10747382268",
		["lucide-wind"] = "rbxassetid://10747382750",
		["lucide-wrap-text"] = "rbxassetid://10747383065",
		["lucide-wrench"] = "rbxassetid://10747383470",
		["lucide-x"] = "rbxassetid://10747384394",
		["lucide-x-circle"] = "rbxassetid://10747383819",
		["lucide-x-octagon"] = "rbxassetid://10747384037",
		["lucide-x-square"] = "rbxassetid://10747384217",
		["lucide-zoom-in"] = "rbxassetid://10747384552",
		["lucide-zoom-out"] = "rbxassetid://10747384679",
	},
}

end)()
local IconAssets = IconLib.assets
local IconQueue, IconQueued, IconPre = {}, {}, {}
local function QueueIcon(id)
	if IconPre[id] or IconQueued[id] then return end
	IconQueued[id] = true
	IconQueue[#IconQueue + 1] = id
	if #IconQueue == 1 then
		task.defer(function()
			local batch = IconQueue
			IconQueue = {}
			pcall(function() game:GetService("ContentProvider"):PreloadAsync(batch) end)
			for _, v in ipairs(batch) do IconPre[v] = true IconQueued[v] = nil end
		end)
	end
end
function MX:GetIcon(name)
	if type(name) == "number" then return "rbxassetid://" .. name end
	if type(name) ~= "string" then return nil end
	local v = MX.Icons[name]
	if v then return type(v) == "number" and ("rbxassetid://" .. v) or v end
	local id = IconAssets["lucide-" .. name] or IconAssets[name]
	if id then QueueIcon(id) end
	return id
end
local Glyphs = {
	["check-circle"] = "✔", ["x-circle"] = "✖", ["chevron-down"] = "▾", ["chevron-right"] = "›", ["chevron-up"] = "▴",
	home = "⌂", star = "★", settings = "⚙", user = "☺", users = "☺", eye = "◉", ["eye-off"] = "◎", crosshair = "⊕", target = "◎",
	sword = "⚔", swords = "⚔", shield = "◈", bell = "♪", info = "ⓘ", layers = "❖", folder = "▤", sliders = "☰", ["sliders-horizontal"] = "☰",
	list = "☰", ["list-checks"] = "☰", keyboard = "⌨", palette = "◐", power = "⏻", lock = "⚿", unlock = "⚿", zap = "ϟ", flame = "♨",
	heart = "♥", play = "▶", pause = "‖", check = "✔", x = "✖", plus = "✚", minus = "━", search = "⌕", globe = "◍", map = "⌖",
	wrench = "✎", code = "‹›", bug = "✱", box = "▣", tag = "⚑", flag = "⚑", clock = "◔", cloud = "☁", sun = "☀", moon = "☾", music = "♫",
	["mouse-pointer-click"] = "➤", ["toggle-right"] = "◖", ["alert-triangle"] = "⚠", ["chevrons-down"] = "⇩", loader = "◌", activity = "∿",
	fingerprint = "◉", type = "T", ["move-horizontal"] = "↔", message = "✉", ["message-square"] = "✉", menu = "☰", mx = "MX",
}

local ImgCache, ImgN = {}, 0
function MX:ResolveImage(src)
	if typeof(src) == "Instance" then
		if src:IsA("Decal") or src:IsA("Texture") then return src.Texture end
		if src:IsA("ImageLabel") or src:IsA("ImageButton") then return src.Image end
		return nil
	end
	if type(src) == "table" then
		local function thumb(kind, id, px)
			id = tonumber(id)
			if not id then return nil end
			return string.format("rbxthumb://type=%s&id=%d&w=%d&h=%d", kind, id, px, px)
		end
		if src.Decal then
			local id = tonumber(src.Decal)
			if not id then return nil end
			local key = "decal:" .. id
			if ImgCache[key] then return ImgCache[key] end
			if src.Convert ~= false then
				local ok, obj = pcall(function() return game:GetObjects("rbxassetid://" .. id)[1] end)
				if ok and obj then
					local tex
					if obj:IsA("Decal") or obj:IsA("Texture") then
						tex = obj.Texture
					elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
						tex = obj.Image
					end
					pcall(function() obj:Destroy() end)
					if tex and tex ~= "" then
						ImgCache[key] = tex
						return tex
					end
				end
			end
			return thumb("Asset", id, 420)
		end
		if src.Asset then return thumb("Asset", src.Asset, 420) end
		if src.Avatar ~= nil then
			local kind = ({ Head = "AvatarHeadShot", Bust = "AvatarBust", Full = "Avatar" })[src.Type or "Head"] or "AvatarHeadShot"
			return thumb(kind, tonumber(src.Avatar) or LocalPlayer.UserId, kind == "Avatar" and 352 or 150)
		end
		if src.Game ~= nil then return thumb("GameIcon", tonumber(src.Game) or game.GameId, 256) end
		if src.Group then return thumb("GroupIcon", src.Group, 150) end
		if src.Badge then return thumb("BadgeIcon", src.Badge, 150) end
		if src.Gamepass then return thumb("GamePass", src.Gamepass, 150) end
		return nil
	end
	if type(src) == "number" then return "rbxassetid://" .. src end
	if type(src) ~= "string" then return nil end
	if src:match("^%d+$") then return "rbxassetid://" .. src end
	if not src:find("^https?://") then return src end
	if ImgCache[src] then return ImgCache[src] end
	if not (FS.ok() and getcustomasset) then return nil end
	local ok, data = pcall(function() return game:HttpGet(src) end)
	if not ok or not data or #data < 16 then return nil end
	EnsureFolder(MX.ConfigFolder)
	EnsureFolder(MX.ConfigFolder .. "/cache")
	ImgN += 1
	local path = MX.ConfigFolder .. "/cache/" .. HttpService:GenerateGUID(false):sub(1, 8) .. ImgN .. ".png"
	local w = pcall(writefile, path, data)
	if not w then return nil end
	local ok2, asset = pcall(getcustomasset, path)
	if ok2 then ImgCache[src] = asset return asset end
	return nil
end

function MX:AddIcons(t)
	for k, v in pairs(t) do MX.Icons[k] = v end
end

local function MakeIcon(parent, icon, size, tok)
	if icon == nil or icon == false then return nil end
	local id
	if type(icon) == "number" then
		id = "rbxassetid://" .. icon
	elseif type(icon) == "string" then
		if icon:find("^rbxassetid://") or icon:find("^rbxasset://") or icon:find("^rbxthumb://") then id = icon
		elseif icon:match("^%d+$") then id = "rbxassetid://" .. icon
		elseif icon:find("^https?://") then id = false
		else
			id = MX:GetIcon(icon)
		end
	elseif type(icon) == "table" or typeof(icon) == "Instance" then
		id = false
	end
	if id ~= nil then
		local img = New("ImageLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromOffset(size, size), Image = id or "", ScaleType = Enum.ScaleType.Fit }, parent)
		if tok ~= false then Bind(img, { ImageColor3 = tok or "Sub" }) end
		if id == false then
			task.spawn(function()
				local r = MX:ResolveImage(icon)
				if r and img.Parent then img.Image = r end
			end)
		end
		return img
	end
	local g = Glyphs[icon] or (type(icon) == "string" and icon:sub(1, 1):upper()) or "?"
	if tok == nil then tok = "Sub" end
	return Lbl(parent, { Text = g, Size = UDim2.fromOffset(size, size), TextSize = size - 3, TextXAlignment = CENTER, Font = FONT.Bold }, tok)
end

local BadgeCols = { NEW = "Accent", BETA = "Warning", HOT = "Danger", FIXED = "Success", PREMIUM = "Warning" }
local function MakeBadge(parent, badge, order)
	local text, col = badge, nil
	if type(badge) == "table" then text, col = badge.Text, badge.Color end
	text = tostring(text)
	local tok = BadgeCols[text:upper()]
	local b = New("TextLabel", {
		BackgroundTransparency = 0.82, BorderSizePixel = 0, Text = text:upper(), Font = FONT.Bold, TextSize = TS(10),
		AutomaticSize = AX, Size = UDim2.new(0, 0, 0, 16), LayoutOrder = order or 5, TextXAlignment = CENTER,
	}, parent)
	New("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
	Pad(b, 0, 5, 0, 5)
	if col then
		b.BackgroundColor3 = col
		b.TextColor3 = col
	else
		Bind(b, { BackgroundColor3 = tok or "Accent", TextColor3 = tok or "Accent" })
	end
	return b
end

MX.Icons.mx = MX.LogoId
QueueIcon("rbxassetid://" .. MX.LogoId)
QueueIcon("rbxassetid://" .. MX.WelcomeImage)
local function MXLogo(parent, size)
	local holder = New("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromOffset(size, size) }, parent)
	local img = New("ImageLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Image = "rbxassetid://" .. MX.LogoId, ScaleType = Enum.ScaleType.Fit }, holder)
	return holder, img
end

local Tip, TipText
do
	Tip = Box(TipLayer, { Size = UDim2.new(0, 0, 0, 0), AutomaticSize = AXY, Visible = false, ZIndex = 2 }, "Card", 5, "Border")
	Scaled(Tip)
	Pad(Tip, 5, 8, 5, 8)
	TipText = Lbl(Tip, { Size = UDim2.new(0, 0, 0, 0), AutomaticSize = AXY, TextSize = 12, TextWrapped = false })
end
function MX:Tip(o, text)
	if Touch then return end
	local function move()
		local m = ToGui(UIS:GetMouseLocation()) - TipLayer.AbsolutePosition
		local sc = MX.Scale
		local x, y = m.X + 14, m.Y + 16
		local tw, th = Tip.AbsoluteSize.X, Tip.AbsoluteSize.Y
		local vp = TipLayer.AbsoluteSize
		if x + tw > vp.X - 4 then x = math.max(4, m.X - tw - 10) end
		if y + th > vp.Y - 4 then y = math.max(4, m.Y - th - 10) end
		Tip.Position = UDim2.fromOffset(x / sc, y / sc)
	end
	o.MouseEnter:Connect(function()
		local t = type(text) == "function" and text() or text
		if not t or t == "" then return end
		TipText.Text = t
		Tip.Visible = true
		move()
	end)
	o.MouseMoved:Connect(function() if Tip.Visible then move() end end)
	o.MouseLeave:Connect(function() Tip.Visible = false end)
end

local PopStack = {}
function MX:ClosePopup()
	local p = table.remove(PopStack)
	if not p then return end
	if p.conn then p.conn:Disconnect() end
	p.frame.Visible = false
	if p.destroy then p.frame:Destroy() end
	if p.onClose then pcall(p.onClose) end
	if #PopStack == 0 then Overlay.Visible = false end
end
function MX:CloseAllPopups()
	while #PopStack > 0 do MX:ClosePopup() end
end
local function PlacePopup(p)
	local f, a = p.frame, p.anchor
	if not a.Parent or not a:IsDescendantOf(Gui) then
		MX:ClosePopup()
		return
	end
	local ab = a.AbsolutePosition - Overlay.AbsolutePosition
	local as = a.AbsoluteSize
	local sz, vp = f.AbsoluteSize, Overlay.AbsoluteSize
	local x, y = ab.X, ab.Y + as.Y + 4
	if p.placement == "RightBottom" or p.placement == "Right" then
		x = ab.X + as.X + 6
		if x + sz.X > vp.X - 6 then x = ab.X - sz.X - 6 end
		y = p.placement == "RightBottom" and (ab.Y + as.Y - sz.Y) or ab.Y
		if y + sz.Y > vp.Y - 6 then y = vp.Y - sz.Y - 6 end
		if y < 6 then y = 6 end
		if x < 6 then x = 6 end
		f.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
		return
	end
	if p.alignRight then x = ab.X + as.X - sz.X end
	if x + sz.X > vp.X - 6 then x = vp.X - sz.X - 6 end
	if x < 6 then x = 6 end
	if y + sz.Y > vp.Y - 6 then
		local above = ab.Y - sz.Y - 4
		if above >= 6 then y = above else y = math.max(6, vp.Y - sz.Y - 6) end
	end
	f.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
end
function MX:ShowPopup(f, anchor, opts)
	opts = opts or {}
	for i = #PopStack, 1, -1 do
		if PopStack[i].frame == f then
			local old = table.remove(PopStack, i)
			if old.conn then old.conn:Disconnect() end
		end
	end
	local p = { frame = f, anchor = anchor, onClose = opts.OnClose, destroy = opts.Destroy, alignRight = opts.AlignRight, placement = opts.Placement }
	PopStack[#PopStack + 1] = p
	f.ZIndex = 10 + #PopStack
	f.AnchorPoint = Vector2.zero
	f.Visible = true
	Overlay.Visible = true
	PlacePopup(p)
	p.conn = RunService.RenderStepped:Connect(function()
		if not MX.Dead and f.Visible then PlacePopup(p) end
	end)
end
Overlay.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then MX:ClosePopup() end
end)

local function NewPopupFrame(w, h)
	local f = Box(Overlay, { Size = UDim2.new(0, w, 0, h or 0), Active = true, Visible = false }, "Card", 8, "Border")
	if not h then f.AutomaticSize = AY end
	Scaled(f)
	return f
end

local function KeyLabel(k)
	if not k then return "None" end
	if k == Enum.UserInputType.MouseButton2 then return "M2" end
	if k == Enum.UserInputType.MouseButton3 then return "M3" end
	local n = k.Name
	local map = { LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl", LeftAlt = "LAlt", RightAlt = "RAlt", Return = "Enter", Backspace = "Bksp", Space = "Space", Insert = "Ins", Delete = "Del", Escape = "Esc", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0" }
	return map[n] or n
end

local function KeyEncode(k, mode)
	if not k and not mode then return false end
	local t = { m = mode }
	if k then
		t.k = (k.EnumType == Enum.KeyCode) and "KeyCode" or "UserInputType"
		t.n = k.Name
	end
	return t
end
local function KeyDecode(v)
	if type(v) ~= "table" then return nil, nil end
	local key
	if v.k and v.n then
		local ok, r = pcall(function() return Enum[v.k][v.n] end)
		key = ok and r or nil
	end
	return key, v.m
end

MX.Listening = false
function MX:Listen(cb)
	if MX.Listening then return end
	MX.Listening = true
	local c
	c = UIS.InputBegan:Connect(function(input)
		local t = input.UserInputType
		local result, ok = nil, false
		if t == Enum.UserInputType.Keyboard then
			ok = true
			result = input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode or nil
		elseif t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3 then
			ok = true
			result = t
		elseif t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			ok = true
			result = false
		end
		if not ok then return end
		c:Disconnect()
		task.delay(0.08, function() MX.Listening = false end)
		cb(result)
	end)
end

local function MakeBind(name, mode, key, fire, active)
	local b = { Name = name, Mode = mode, Key = key, Fire = fire, GetActive = active, Held = false }
	function b:Trigger()
		if self.Mode == "Hold" then
			self.Held = not self.Held
			pcall(self.Fire, self.Held)
		else
			pcall(self.Fire, true)
		end
	end
	function b:Remove()
		local i = table.find(MX.Binds, self)
		if i then table.remove(MX.Binds, i) end
		MX:_KeyListRefresh()
	end
	table.insert(MX.Binds, b)
	return b
end

local MenuKeys = { Enum.KeyCode.Insert, Enum.KeyCode.RightShift }
MX.MenuKeyCode = Enum.KeyCode.RightShift
function MX:SetMenuKey(k)
	MenuKeys = { Enum.KeyCode.Insert }
	if k and k ~= Enum.KeyCode.Insert then table.insert(MenuKeys, k) end
	MX.MenuKeyCode = k
end
function MX:_SetMenuKeys(t)
	MenuKeys = t
	MX.MenuKeyCode = t[2] or t[1]
end

local function KeyMatch(input, key)
	if not key then return false end
	if key.EnumType == Enum.KeyCode then return input.KeyCode == key end
	return input.UserInputType == key
end

Conn(UIS.InputBegan, function(input, gp)
	if MX.Listening or MX.Dead then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and not UIS:GetFocusedTextBox() then
		for _, k in ipairs(MenuKeys) do
			if input.KeyCode == k then
				local w = MX.Window
				if w then w:Toggle() end
				return
			end
		end
		if input.KeyCode == Enum.KeyCode.Escape and #PopStack > 0 then MX:ClosePopup() return end
	end
	if UIS:GetFocusedTextBox() then return end
	for _, b in ipairs(MX.Binds) do
		if b.Key and KeyMatch(input, b.Key) and not (gp and b.Key.EnumType == Enum.UserInputType) then
			if b.Mode == "Hold" then b.Held = true end
			pcall(b.Fire, true)
		end
	end
end)
Conn(UIS.InputEnded, function(input)
	if MX.Listening or MX.Dead then return end
	for _, b in ipairs(MX.Binds) do
		if b.Key and b.Mode == "Hold" and KeyMatch(input, b.Key) then
			b.Held = false
			pcall(b.Fire, false)
		end
	end
end)

local FpsNow = 60
do
	local frames, t0 = 0, os.clock()
	Conn(RunService.RenderStepped, function()
		frames += 1
		local n = os.clock()
		if n - t0 >= 0.5 then
			FpsNow = math.floor(frames / (n - t0) + 0.5)
			frames, t0 = 0, n
		end
	end)
end
local function PingNow()
	local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
	return ok and math.floor(v + 0.5) or 0
end
local function FpsColor(v) return v >= 50 and Theme.Success or (v >= 30 and Theme.Warning or Theme.Danger) end
local function PingColor(v) return v <= 90 and Theme.Success or (v <= 160 and Theme.Warning or Theme.Danger) end
local function Hex(c) return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end

local NoteTypes = { Info = "Accent", Success = "Success", Warning = "Warning", Error = "Danger" }
local NoteIcon = { Info = "info", Success = "check-circle", Warning = "alert-triangle", Error = "x-circle" }

MX.NotifyUrl = "https://raw.githubusercontent.com/yuewny/MX/main/Notify.lua"
MX._notifyQueue = {}

function MX._NotifyStub()
	return { Update = function() end, Dismiss = function() end }
end

function MX:_SyncNotifyTheme()
	local p = MX._notify
	if p and type(p.SetTheme) == "function" then
		pcall(p.SetTheme, p, { Card = Theme.Card, Border = Theme.Border, Text = Theme.Text, Sub = Theme.Sub, Info = Theme.Accent, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Danger, OnAccent = Theme.OnAccent })
	end
end

function MX:_FlushNotify()
	local p = MX._notify
	local q = MX._notifyQueue
	MX._notifyQueue = {}
	for _, item in ipairs(q) do
		if p and not item.dead then
			local ok, real = pcall(p.Send, p, item.opts)
			if ok then item.real = real end
		end
	end
end

function MX:_EnsureNotify()
	if MX._notify or MX._notifyLoading or MX._notifyFailed or MX.Dead then return end
	local prov = MX.NotifyProvider
	if type(prov) == "table" and type(prov.Send) == "function" then
		MX._notify = prov
		MX:_SyncNotifyTheme()
		MX:_FlushNotify()
		return
	end
	if type(MX.NotifyUrl) ~= "string" or MX.NotifyUrl == "" then
		MX._notifyFailed = true
		MX._notifyQueue = {}
		return
	end
	MX._notifyLoading = true
	task.spawn(function()
		local ok, lib = pcall(function()
			local body = game:HttpGet(MX.NotifyUrl)
			local fn, err = loadstring(body)
			if not fn then error(err, 0) end
			return fn()
		end)
		MX._notifyLoading = false
		if MX.Dead then
			if ok and type(lib) == "table" and type(lib.Destroy) == "function" then pcall(lib.Destroy, lib) end
			return
		end
		if ok and type(lib) == "table" and type(lib.Send) == "function" then
			MX._notify = lib
			MX:_SyncNotifyTheme()
			MX:_FlushNotify()
		else
			MX._notifyFailed = true
			MX._notifyQueue = {}
			warn("[MX] Notify module could not be loaded from " .. tostring(MX.NotifyUrl) .. ": " .. tostring(lib))
		end
	end)
end

function MX:SetNotifyUrl(url)
	MX.NotifyUrl = url
	MX._notifyFailed = false
	if MX._notify and type(MX._notify.Destroy) == "function" then pcall(MX._notify.Destroy, MX._notify) end
	MX._notify = nil
	MX:_EnsureNotify()
end

function MX:SetNotificationsHidden(hidden)
	MX.NotifyEnabled = not hidden
	if hidden then
		MX._notifyQueue = {}
		if MX._notify and type(MX._notify.ClearAll) == "function" then pcall(MX._notify.ClearAll, MX._notify) end
	end
end

function MX:Notify(o)
	if MX.Dead or MX.NotifyEnabled == false then return MX._NotifyStub() end
	o = type(o) == "table" and o or { Title = tostring(o) }
	local p = MX._notify
	if p then
		local ok, real = pcall(p.Send, p, o)
		if ok and type(real) == "table" then return real end
		return MX._NotifyStub()
	end
	MX:_EnsureNotify()
	if MX._notifyFailed then return MX._NotifyStub() end
	local item = { opts = o }
	MX._notifyQueue[#MX._notifyQueue + 1] = item
	return {
		Dismiss = function()
			item.dead = true
			if item.real and item.real.Dismiss then pcall(item.real.Dismiss) end
		end,
		Update = function(n)
			if item.real and item.real.Update then pcall(item.real.Update, n) end
		end,
	}
end

for _, k in ipairs({ "Info", "Success", "Warning", "Error" }) do
	MX[k] = function(self, title, content, dur)
		return self:Notify({ Type = k, Title = title, Content = content, Duration = dur })
	end
end

local function CleanName(n) return (tostring(n or ""):gsub("[\\/:*?\"<>|]", ""):match("^%s*(.-)%s*$")) end

function MX:SaveConfig(name)
	name = CleanName(name)
	if not FS.ok() or name == "" then return false end
	EnsureFolder(MX.ConfigFolder)
	local okE, text = pcall(function() return HttpService:JSONEncode(MX:_Collect()) end)
	if not okE then return false end
	local ok = pcall(writefile, MX.ConfigFolder .. "/" .. name .. ".json", text)
	return ok
end
function MX:LoadConfig(name)
	name = CleanName(name)
	if not FS.ok() or name == "" then return false end
	local path = MX.ConfigFolder .. "/" .. name .. ".json"
	if not (isfile and isfile(path)) then return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok or type(data) ~= "table" then return false end
	MX:_Apply(data)
	MX.LoadedConfig = name
	MX._lastSnap = nil
	return true
end
function MX:ListConfigs()
	local out = {}
	if not FS.ok() or not listfiles then return out end
	EnsureFolder(MX.ConfigFolder)
	local ok, files = pcall(listfiles, MX.ConfigFolder)
	if not ok then return out end
	for _, f in ipairs(files) do
		local n = tostring(f):match("([^/\\]+)%.json$")
		if n then out[#out + 1] = n end
	end
	table.sort(out)
	return out
end
function MX:DeleteConfig(name)
	name = CleanName(name)
	if not (delfile and isfile) then return false end
	local p = MX.ConfigFolder .. "/" .. name .. ".json"
	if isfile(p) then return pcall(delfile, p) end
	return false
end
function MX:UniqueConfigName(base)
	local ex = {}
	for _, n in ipairs(MX:ListConfigs()) do ex[n] = true end
	if not ex[base] then return base end
	local i = 1
	while ex[base .. " (" .. i .. ")"] do i += 1 end
	return base .. " (" .. i .. ")"
end

function MX:SetGlass(v)
	MX.Glass = v and true or false
	for i = #GlassReg, 1, -1 do
		local e = GlassReg[i]
		if e.o.Parent then Tween(e.o, { BackgroundTransparency = MX.Glass and e.a or 0 }, 0.25) else table.remove(GlassReg, i) end
	end
	if MX.Options.glass and MX.Options.glass.Value ~= MX.Glass then MX.Options.glass:Set(MX.Glass, true) end
end
function MX:GetGlass() return MX.Glass end

MX.ThemeListeners = {}
local function Watch(inst, fn)
	table.insert(MX.ThemeListeners, function(n)
		if not inst:IsDescendantOf(Gui) then return false end
		fn(n)
		return true
	end)
end

function MX:SetTheme(name, instant, keepOverride)
	local def = MX.Themes[name]
	if not def then return end
	def = MX._NormalizeTheme(def)
	MX.Themes[name] = def
	if not keepOverride then MX.AccentOverride = nil end
	if MX.AccentOverride then
		local c = {}
		for k, v in pairs(def) do c[k] = v end
		c.Accent = MX.AccentOverride
		c.OnAccent = Lum(c.Accent) > 0.62 and C3(20, 20, 24) or C3(255, 255, 255)
		def = c
	end
	MX.ThemeName = name
	local win = MX.Window
	local sweep = MX.ThemeSweep and not instant and win and win.Open
	local wx, ww = 0, 1
	if sweep then wx, ww = win.Main.AbsolutePosition.X, math.max(1, win.Main.AbsoluteSize.X) end
	local buckets = {}
	for i = #Reg, 1, -1 do
		local e = Reg[i]
		if not e.o:IsDescendantOf(Gui) then
			table.remove(Reg, i)
		else
			local b = 0
			if sweep then
				local g = e.o
				while g and not g:IsA("GuiObject") do g = g.Parent end
				if g then b = math.clamp(math.floor((g.AbsolutePosition.X - wx) / ww * 7 + 0.5), 0, 7) end
			end
			buckets[b] = buckets[b] or {}
			table.insert(buckets[b], e)
		end
	end
	for k, v in pairs(def) do Theme[k] = v end
	local function apply(list)
		for _, e in ipairs(list) do
			local v = def[e.t]
			if v ~= nil and e.o.Parent then
				local st = Active[e.o]
				if st and st[e.p] then
					st[e.p]:Cancel()
					st[e.p] = nil
				end
				pcall(function()
					if sweep then Tween(e.o, { [e.p] = v }, 0.2) else e.o[e.p] = v end
				end)
			end
		end
	end
	for b = 0, 7 do
		if buckets[b] then
			if b == 0 or not sweep then apply(buckets[b]) else task.delay(b * 0.045, function() apply(buckets[b]) end) end
		end
	end
	if MX.Options.theme and MX.Options.theme.Value ~= name then MX.Options.theme:Set(name, true) end
	if MX.Options.accent and not keepOverride then MX.Options.accent:Set(def.Accent, true) end
	for i = #MX.ThemeListeners, 1, -1 do
		local ok, alive = pcall(MX.ThemeListeners[i], name)
		if ok and alive == false then table.remove(MX.ThemeListeners, i) end
	end
	if MX.Watermark and MX.Watermark.Items then
		for _, it in ipairs(MX.Watermark.Items) do pcall(it.Update, it) end
	end
	pcall(function() MX:_KeyListRefresh() end)
	MX:_SyncNotifyTheme()
end

local LangCatalog = {
	{ "Afrikaans", "af" },
	{ "Albanian", "sq" },
	{ "Amharic", "am" },
	{ "Arabic", "ar" },
	{ "Armenian", "hy" },
	{ "Azerbaijani", "az" },
	{ "Basque", "eu" },
	{ "Belarusian", "be" },
	{ "Bengali", "bn" },
	{ "Bosnian", "bs" },
	{ "Bulgarian", "bg" },
	{ "Burmese", "my" },
	{ "Catalan", "ca" },
	{ "Cebuano", "ceb" },
	{ "Chinese", "zh-CN" },
	{ "Chinese (Traditional)", "zh-TW" },
	{ "Corsican", "co" },
	{ "Croatian", "hr" },
	{ "Czech", "cs" },
	{ "Danish", "da" },
	{ "Dutch", "nl" },
	{ "Esperanto", "eo" },
	{ "Estonian", "et" },
	{ "Filipino", "tl" },
	{ "Finnish", "fi" },
	{ "French", "fr" },
	{ "Frisian", "fy" },
	{ "Galician", "gl" },
	{ "Georgian", "ka" },
	{ "German", "de" },
	{ "Greek", "el" },
	{ "Gujarati", "gu" },
	{ "Haitian Creole", "ht" },
	{ "Hausa", "ha" },
	{ "Hawaiian", "haw" },
	{ "Hebrew", "iw" },
	{ "Hindi", "hi" },
	{ "Hmong", "hmn" },
	{ "Hungarian", "hu" },
	{ "Icelandic", "is" },
	{ "Igbo", "ig" },
	{ "Irish", "ga" },
	{ "Italian", "it" },
	{ "Japanese", "ja" },
	{ "Javanese", "jw" },
	{ "Kannada", "kn" },
	{ "Kazakh", "kk" },
	{ "Khmer", "km" },
	{ "Korean", "ko" },
	{ "Kurdish", "ku" },
	{ "Kyrgyz", "ky" },
	{ "Lao", "lo" },
	{ "Latin", "la" },
	{ "Latvian", "lv" },
	{ "Lithuanian", "lt" },
	{ "Luxembourgish", "lb" },
	{ "Macedonian", "mk" },
	{ "Malagasy", "mg" },
	{ "Malay", "ms" },
	{ "Malayalam", "ml" },
	{ "Maltese", "mt" },
	{ "Maori", "mi" },
	{ "Marathi", "mr" },
	{ "Mongolian", "mn" },
	{ "Nepali", "ne" },
	{ "Norwegian", "no" },
	{ "Nyanja", "ny" },
	{ "Pashto", "ps" },
	{ "Persian", "fa" },
	{ "Polish", "pl" },
	{ "Portuguese", "pt" },
	{ "Punjabi", "pa" },
	{ "Romanian", "ro" },
	{ "Russian", "ru" },
	{ "Samoan", "sm" },
	{ "Scots Gaelic", "gd" },
	{ "Serbian", "sr" },
	{ "Sesotho", "st" },
	{ "Shona", "sn" },
	{ "Sindhi", "sd" },
	{ "Sinhala", "si" },
	{ "Slovak", "sk" },
	{ "Slovenian", "sl" },
	{ "Somali", "so" },
	{ "Spanish", "es" },
	{ "Sundanese", "su" },
	{ "Swahili", "sw" },
	{ "Swedish", "sv" },
	{ "Tajik", "tg" },
	{ "Tamil", "ta" },
	{ "Telugu", "te" },
	{ "Thai", "th" },
	{ "Turkish", "tr" },
	{ "Ukrainian", "uk" },
	{ "Urdu", "ur" },
	{ "Uzbek", "uz" },
	{ "Vietnamese", "vi" },
	{ "Welsh", "cy" },
	{ "Xhosa", "xh" },
	{ "Yiddish", "yi" },
	{ "Yoruba", "yo" },
	{ "Zulu", "zu" },
}

local LangID = {
	["Search..."] = "Cari...",
	["Search"] = "Cari",
	["options"] = "opsi",
	["Select All"] = "Pilih Semua",
	["Deselect All"] = "Batal Semua",
	["Create Language"] = "Buat Bahasa",
	["New Language"] = "Bahasa Baru",
	["Quick Settings"] = "Pengaturan Cepat",
	["Glass"] = "Kaca",
	["See-through window"] = "Jendela transparan",
	["Watermark"] = "Watermark",
	["Keybind List"] = "Daftar Keybind",
	["Mobile Button"] = "Tombol Mobile",
	["Lock UI"] = "Kunci UI",
	["Stops windows and buttons from being moved"] = "Mencegah jendela dan tombol dipindahkan",
	["Copied"] = "Tersalin",
	["Language"] = "Bahasa",
	["Menu Scale"] = "Skala Menu",
	["Theme"] = "Tema",
	["Menu Key"] = "Tombol Menu",
	["Unload"] = "Tutup Script",
	["Auto"] = "Otomatis",
	["Settings"] = "Pengaturan",
	["Preset"] = "Preset",
	["Accent"] = "Aksen",
	["Custom Themes"] = "Tema Kustom",
	["Create"] = "Buat",
	["Delete"] = "Hapus",
	["Effects"] = "Efek",
	["Effect"] = "Efek",
	["Animation behind the menu"] = "Animasi di belakang menu",
	["Intensity"] = "Intensitas",
	["Colors of the whole UI"] = "Warna seluruh UI",
	["Configs"] = "Config",
	["Config Name:"] = "Nama Config:",
	["Type config name here..."] = "Ketik nama config di sini...",
	["Save"] = "Simpan",
	["Load"] = "Muat",
	["Refresh"] = "Segarkan",
	["Auto Load Config"] = "Muat Config Otomatis",
	["Loads the selected config on launch"] = "Memuat config terpilih saat dijalankan",
	["Auto Save"] = "Simpan Otomatis",
	["Saves the loaded config when something changes"] = "Menyimpan config yang dimuat saat ada perubahan",
	["Rename"] = "Ganti Nama",
	["Reset"] = "Reset",
	["Autoload mode"] = "Mode muat otomatis",
	["All accounts"] = "Semua akun",
	["This account"] = "Akun ini",
	["Copy code"] = "Salin kode",
	["Import"] = "Impor",
	["paste a config code..."] = "tempel kode config...",
	["no configs yet"] = "belum ada config",
	["saved"] = "tersimpan",
	["loaded"] = "dimuat",
	["auto"] = "otomatis",
	["none"] = "tidak ada",
	["more"] = "lainnya",
	["share"] = "bagikan",
	["no themes"] = "belum ada tema",
	["theme name"] = "nama tema",
	["Unload Script?"] = "Tutup Script?",
	["Stay"] = "Tetap",
	["Cancel"] = "Batal",
	["OK"] = "OK",
	["The UI closes completely. Run the script again to bring it back."] = "UI ditutup sepenuhnya. Jalankan script lagi untuk memunculkannya kembali.",
	["Rebind"] = "Atur Ulang",
	["Toggle"] = "Toggle",
	["Hold"] = "Tahan",
	["Press"] = "Tekan",
	["Clear Key"] = "Hapus Tombol",
	["Locked"] = "Terkunci",
	["Select language"] = "Pilih bahasa",
	["Keybinds"] = "Keybind",
	["Hold to delete"] = "Tahan untuk menghapus",
	["Hold to reset"] = "Tahan untuk reset",
	["Reset every option to its default"] = "Kembalikan semua opsi ke bawaan",
	["Delete selected config"] = "Hapus config terpilih",
	["Select a config first."] = "Pilih config dulu.",
	["Config"] = "Config",
	["Custom Theme"] = "Tema Kustom",
	["Saved"] = "Tersimpan",
	["Loaded"] = "Dimuat",
	["Theme Name"] = "Nama Tema",
	["Create Theme"] = "Buat Tema",
	["Delete Theme"] = "Hapus Tema",
	["Name"] = "Nama",
	["Home"] = "Beranda",
	["Language added"] = "Bahasa ditambahkan",
}

MX.Lang.Dict.Indonesia = LangID
for _, l in ipairs(LangCatalog) do MX.Lang.Codes[l[1]] = l[2] end
MX.AutoTranslate = true

local function ReadJson(path)
	if not (FS.ok() and isfile and isfile(path)) then return nil end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	return ok and data or nil
end
local function WriteJson(path, data)
	if not FS.ok() then return false end
	EnsureFolder(MX.ConfigFolder)
	return pcall(writefile, path, HttpService:JSONEncode(data))
end
local function CleanName(n) return (tostring(n or ""):gsub("[\\/:*?\"<>|]", ""):match("^%s*(.-)%s*$")) end

local function SaveLangState()
	WriteJson(MX.ConfigFolder .. "/language.json", { current = MX.Lang.Current, list = MX.Lang.List })
end
local function SaveLangDict(name)
	local d = MX.Lang.Dict[name]
	if not d then return end
	local out = {}
	for k, v in pairs(d) do
		if (name ~= "Indonesia" or LangID[k] == nil) and type(v) == "string" then out[k] = v end
	end
	WriteJson(MX.ConfigFolder .. "/lang_" .. CleanName(name) .. ".json", out)
end
local function LoadLangDict(name)
	local d = MX.Lang.Dict[name]
	if not d then
		d = {}
		MX.Lang.Dict[name] = d
	end
	local cached = ReadJson(MX.ConfigFolder .. "/lang_" .. CleanName(name) .. ".json")
	if cached then
		for k, v in pairs(cached) do
			if d[k] == nil and type(v) == "string" then d[k] = v end
		end
	end
	return d
end

function MX:GetLanguages() return MX.Lang.List end
function MX:GetLanguage() return MX.Lang.Current end
function MX:AvailableLanguages()
	local out = {}
	for _, l in ipairs(LangCatalog) do
		if not table.find(MX.Lang.List, l[1]) then out[#out + 1] = l[1] end
	end
	return out
end
function MX:AddTranslations(lang, dict)
	local d = MX.Lang.Dict[lang]
	if not d then
		d = {}
		MX.Lang.Dict[lang] = d
	end
	for k, v in pairs(dict) do d[k] = v end
	if not table.find(MX.Lang.List, lang) then table.insert(MX.Lang.List, lang) end
	if MX.Lang.Current == lang then MX:_ApplyLang() end
end
function MX:AddLanguage(name, code)
	if code then MX.Lang.Codes[name] = code end
	if not table.find(MX.Lang.List, name) then table.insert(MX.Lang.List, name) end
	SaveLangState()
end
function MX:_ApplyLang()
	for i = #TrReg, 1, -1 do
		local e = TrReg[i]
		if e.o.Parent and e.o:IsDescendantOf(Gui) then
			e.o[e.p] = MX:T(e.k)
		else
			table.remove(TrReg, i)
		end
	end
	for _, f in ipairs(MX.Lang.Listeners) do pcall(f, MX.Lang.Current) end
end

local function Translate(code, texts)
	local function single(text)
		local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=" .. code .. "&dt=t&q=" .. HttpService:UrlEncode(text)
		local ok, body = pcall(function() return game:HttpGet(url) end)
		if not ok or type(body) ~= "string" then return nil end
		local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
		if not ok2 or type(data) ~= "table" or type(data[1]) ~= "table" then return nil end
		local out = ""
		for _, seg in ipairs(data[1]) do
			if type(seg) == "table" and type(seg[1]) == "string" then out ..= seg[1] end
		end
		return out
	end
	local clean = {}
	for i, t in ipairs(texts) do clean[i] = (t:gsub("[\r\n]+", " ")) end
	local joined = single(table.concat(clean, "\n"))
	if joined then
		local lines = string.split(joined, "\n")
		if #lines == #texts + 1 and lines[#lines] == "" then table.remove(lines) end
		if #lines == #texts then
			for i, l in ipairs(lines) do lines[i] = l:match("^%s*(.-)%s*$") end
			return lines
		end
	end
	local out = {}
	for i, t in ipairs(clean) do
		local r = single(t)
		if not r then return #out > 0 and out or nil end
		out[i] = r:match("^%s*(.-)%s*$")
	end
	return out
end
MX._Translate = Translate

local LangRun = 0
local LangWarned = false
function MX:_TranslateMissing(name)
	local code = MX.Lang.Codes[name]
	if not code or name == "English" or not MX.AutoTranslate then return end
	local d = LoadLangDict(name)
	local missing = {}
	for k in pairs(TrKeys) do
		if d[k] == nil then missing[#missing + 1] = k end
	end
	if #missing == 0 then return end
	table.sort(missing)
	LangRun += 1
	local my = LangRun
	task.spawn(function()
		local i = 1
		local failed = false
		while i <= #missing and MX.Lang.Current == name and my == LangRun and not MX.Dead do
			local batch, chars = {}, 0
			while i <= #missing and #batch < 30 and chars < 1200 do
				batch[#batch + 1] = missing[i]
				chars += #missing[i]
				i += 1
			end
			local res = Translate(code, batch)
			if not res then
				failed = true
				break
			end
			for j, k in ipairs(batch) do
				if res[j] and res[j] ~= "" then d[k] = res[j] else d[k] = k end
			end
			MX:_ApplyLang()
			task.wait(0.15)
		end
		SaveLangDict(name)
		if failed and not LangWarned then
			LangWarned = true
			MX:Notify({ Type = "Warning", Title = "Translation", Content = "Online translation is not reachable. Built-in texts still work.", Duration = 4 })
		end
	end)
end

function MX:SetLanguage(name)
	if not table.find(MX.Lang.List, name) then return false end
	MX.Lang.Current = name
	LoadLangDict(name)
	MX:_ApplyLang()
	SaveLangState()
	if name ~= "English" then MX:_TranslateMissing(name) end
	return true
end

do
	local st = ReadJson(MX.ConfigFolder .. "/language.json")
	if st and type(st.list) == "table" then
		for _, n in ipairs(st.list) do
			if type(n) == "string" and MX.Lang.Codes[n] and not table.find(MX.Lang.List, n) then table.insert(MX.Lang.List, n) end
		end
		if type(st.current) == "string" and table.find(MX.Lang.List, st.current) then
			MX.Lang.Current = st.current
			LoadLangDict(st.current)
		end
	end
end

MX.CustomThemes = {}
MX.CustomListeners = {}
local function EncTheme(def)
	local t = {}
	for k, v in pairs(def) do
		if typeof(v) == "Color3" then t[k] = { v.R, v.G, v.B } end
	end
	return t
end
local function DecTheme(t)
	local d = {}
	for k, v in pairs(t) do
		if type(v) == "table" and #v == 3 then d[k] = Color3.new(v[1], v[2], v[3]) end
	end
	return d
end
function MX:GetCustomThemes()
	local out = {}
	for n in pairs(MX.CustomThemes) do out[#out + 1] = n end
	table.sort(out)
	return out
end
function MX:_SaveThemes()
	local out = {}
	for n in pairs(MX.CustomThemes) do out[n] = EncTheme(MX.Themes[n]) end
	WriteJson(MX.ConfigFolder .. "/themes.json", out)
	for _, f in ipairs(MX.CustomListeners) do pcall(f) end
end
function MX:LoadCustomThemes()
	local data = ReadJson(MX.ConfigFolder .. "/themes.json")
	if not data then return end
	for n, t in pairs(data) do
		local d = DecTheme(t)
		if d.Accent and d.Text and (d.Window or d.Card) then
			d = MX._NormalizeTheme(d)
			MX.Themes[n] = d
			MX.CustomThemes[n] = true
		end
	end
	for _, f in ipairs(MX.CustomListeners) do pcall(f) end
end
function MX:CreateTheme(name)
	name = CleanName(name)
	if name == "" then return nil end
	if MX.Themes[name] and not MX.CustomThemes[name] then name = name .. " Custom" end
	local def = {}
	for k, v in pairs(MX.Theme) do def[k] = v end
	MX.Themes[name] = def
	MX.CustomThemes[name] = true
	MX:_SaveThemes()
	return name
end
function MX:DeleteTheme(name)
	if not MX.CustomThemes[name] then return false end
	MX.CustomThemes[name] = nil
	MX.Themes[name] = nil
	MX:_SaveThemes()
	if MX.ThemeName == name then MX:SetTheme("Mono") end
	return true
end
function MX:SetAccent(c)
	MX.AccentOverride = c
	MX:SetTheme(MX.ThemeName, true, true)
end
MX:LoadCustomThemes()

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64enc(data)
	local out = {}
	for i = 1, #data, 3 do
		local a, b, c = data:byte(i, i + 2)
		local n = a * 65536 + (b or 0) * 256 + (c or 0)
		local c1, c2, c3, c4 = math.floor(n / 262144) % 64, math.floor(n / 4096) % 64, math.floor(n / 64) % 64, n % 64
		out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1) .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
	end
	return table.concat(out)
end
local function b64dec(s)
	s = s:gsub("[^%w%+/=]", "")
	local rev = {}
	for i = 1, 64 do rev[B64:sub(i, i)] = i - 1 end
	local out = {}
	for i = 1, #s, 4 do
		local c1, c2, c3, c4 = s:sub(i, i), s:sub(i + 1, i + 1), s:sub(i + 2, i + 2), s:sub(i + 3, i + 3)
		local n = (rev[c1] or 0) * 262144 + (rev[c2] or 0) * 4096 + (rev[c3] or 0) * 64 + (rev[c4] or 0)
		out[#out + 1] = string.char(math.floor(n / 65536) % 256)
		if c3 ~= "=" and c3 ~= "" then out[#out + 1] = string.char(math.floor(n / 256) % 256) end
		if c4 ~= "=" and c4 ~= "" then out[#out + 1] = string.char(n % 256) end
	end
	return table.concat(out)
end
MX._b64enc, MX._b64dec = b64enc, b64dec

function MX:SetIgnoreFlags(list)
	for _, f in ipairs(list or {}) do MX._ignore[f] = true end
end
function MX:_Collect()
	local data = {}
	for flag, v in pairs(MX._pending) do data[flag] = v end
	for flag in pairs(MX._ignore) do data[flag] = nil end
	for flag, obj in pairs(MX.Options) do
		if flag:sub(1, 1) ~= "_" and not MX._ignore[flag] and obj.Serialize then
			local ok, v = pcall(obj.Serialize, obj)
			if ok then data[flag] = v end
		end
	end
	return data
end
function MX:_Apply(data)
	MX._pending = {}
	local rank = { Dropdown = 1, MultiSelect = 1, Slider = 2, NumberInput = 2, Textbox = 3, ColorPicker = 4, Keybind = 5, Toggle = 6 }
	local queue = {}
	for flag, v in pairs(data) do
		if not MX._ignore[flag] then
			local obj = MX.Options[flag]
			if obj and obj.Deserialize then
				queue[#queue + 1] = { flag = flag, obj = obj, v = v, rank = rank[obj.Type] or 0 }
			elseif obj == nil then
				MX._pending[flag] = v
			end
		end
	end
	table.sort(queue, function(a, b)
		if a.rank ~= b.rank then return a.rank < b.rank end
		return a.flag < b.flag
	end)
	for _, q in ipairs(queue) do pcall(q.obj.Deserialize, q.obj, q.v) end
end
function MX:_Snapshot()
	local data = MX:_Collect()
	local keys = {}
	for k in pairs(data) do keys[#keys + 1] = k end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do parts[#parts + 1] = k .. "=" .. HttpService:JSONEncode({ data[k] }) end
	return table.concat(parts, ";")
end
function MX:ExportConfig(name)
	local data
	if name and name ~= "" then
		data = ReadJson(MX.ConfigFolder .. "/" .. CleanName(name) .. ".json")
	end
	data = data or MX:_Collect()
	return "MXCFG1:" .. b64enc(HttpService:JSONEncode(data))
end
function MX:ImportConfig(code, name)
	code = tostring(code or ""):gsub("%s", "")
	local body = code:match("^MXCFG1:(.+)$")
	if not body then return nil, "invalid code" end
	local ok, data = pcall(function() return HttpService:JSONDecode(b64dec(body)) end)
	if not ok or type(data) ~= "table" then return nil, "invalid code" end
	name = MX:UniqueConfigName(CleanName(name) ~= "" and CleanName(name) or "imported")
	if not WriteJson(MX.ConfigFolder .. "/" .. name .. ".json", data) then return nil, "could not write" end
	return name
end
function MX:RenameConfig(old, new)
	old, new = CleanName(old), CleanName(new)
	if old == "" or new == "" or old == new then return false end
	local data = ReadJson(MX.ConfigFolder .. "/" .. old .. ".json")
	if not data then return false end
	if not WriteJson(MX.ConfigFolder .. "/" .. new .. ".json", data) then return false end
	MX:DeleteConfig(old)
	if MX.LoadedConfig == old then MX.LoadedConfig = new end
	if MX:GetAutoLoad() == old then MX:SetAutoLoad(new) end
	return true
end
function MX:ResetOptions()
	local data = {}
	for flag, obj in pairs(MX.Options) do
		if flag:sub(1, 1) ~= "_" and obj._def ~= nil and obj.Deserialize then data[flag] = obj._def end
	end
	MX:_Apply(data)
end

MX.AutoSave = false
MX.LoadedConfig = nil
do
	local p = MX.ConfigFolder .. "/autosave.txt"
	if FS.ok() and isfile and isfile(p) then
		local ok, s = pcall(readfile, p)
		MX.AutoSave = ok and s == "1"
	end
end
function MX:SetAutoSave(v)
	MX.AutoSave = v and true or false
	if FS.ok() then
		EnsureFolder(MX.ConfigFolder)
		pcall(writefile, MX.ConfigFolder .. "/autosave.txt", MX.AutoSave and "1" or "0")
	end
	MX._lastSnap = nil
end
function MX:_AutoSaveTick()
	if not MX.AutoSave or not MX.LoadedConfig then
		MX._lastSnap = nil
		return
	end
	local snap = MX:_Snapshot()
	if MX._lastSnap ~= nil and snap ~= MX._lastSnap then MX:SaveConfig(MX.LoadedConfig) end
	MX._lastSnap = snap
end
task.spawn(function()
	while not MX.Dead do
		task.wait(2.5)
		MX:_AutoSaveTick()
	end
end)

MX.AutoMode = "All accounts"
do
	local p = MX.ConfigFolder .. "/autoload_mode.txt"
	if FS.ok() and isfile and isfile(p) then
		local ok, s = pcall(readfile, p)
		if ok and (s == "This account" or s == "All accounts") then MX.AutoMode = s end
	end
end
local function AutoPath(account)
	return MX.ConfigFolder .. (account and ("/autoload_" .. LocalPlayer.UserId .. ".txt") or "/autoload.txt")
end
function MX:SetAutoMode(m)
	MX.AutoMode = m == "This account" and m or "All accounts"
	if FS.ok() then
		EnsureFolder(MX.ConfigFolder)
		pcall(writefile, MX.ConfigFolder .. "/autoload_mode.txt", MX.AutoMode)
	end
end
function MX:SetAutoLoad(name)
	if not FS.ok() then return end
	EnsureFolder(MX.ConfigFolder)
	pcall(writefile, AutoPath(MX.AutoMode == "This account"), name or "")
end
function MX:GetAutoLoad()
	if not (FS.ok() and isfile) then return nil end
	for _, acc in ipairs({ true, false }) do
		local p = AutoPath(acc)
		if isfile(p) then
			local ok, s = pcall(readfile, p)
			if ok and s ~= "" then return s end
		end
	end
	return nil
end
function MX:LoadAutoConfig()
	local n = MX:GetAutoLoad()
	if n then return MX:LoadConfig(n) end
	return false
end


local Container = {}
local ContainerMT = { __index = Container }
local ListPopup

function Container:_Order()
	self._n = (self._n or 0) + 1
	return self._n
end
function Container:_Reg(title, row)
	local w = self.Win
	if w and not self.NoIndex and title and title ~= "" then
		w.Index[#w.Index + 1] = { title = title, row = row, cont = self }
	end
end
function Container:_Child(content)
	return setmetatable({ Content = content, Win = self.Win, Owner = self.Owner, SecObj = self.SecObj, SecTitle = self.SecTitle, NoIndex = self.NoIndex, Up = self }, ContainerMT)
end

local function MakeRow(self, o, ctlW)
	local hasDesc = o.Description ~= nil and o.Description ~= ""
	local row = Box(self.Content, { Size = UDim2.new(1, 0, 0, RH), LayoutOrder = self:_Order() }, "Element", 6)
	if hasDesc then row.AutomaticSize = AY end
	local info = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -(ctlW + 20), hasDesc and 0 or 1, 0), ClipsDescendants = true }, row)
	if hasDesc then
		info.AutomaticSize = AY
		Pad(info, 8, 0, 8, 0)
		List(info, 2)
	else
		List(info, 2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	end
	local ctl = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0, ctlW, 1, 0), ZIndex = 3 }, row)
	List(ctl, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
	return row, ctl, info
end

local function IsPremium(o)
	return o.Premium or (o.Locked and tostring(o.LockedReason or ""):lower():find("premium") ~= nil)
end

local function Titles(info, o)
	local th = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TS(14) + 4), LayoutOrder = 1 }, info)
	List(th, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	local t = Lbl(th, { Text = tostring(o.Title or o.Name or ""), AutomaticSize = AX, Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 1, Tr = true })
	if o.Badge then MakeBadge(th, o.Badge, 2) end
	if IsPremium(o) then MakeBadge(th, "PREMIUM", 3) end
	local d
	if o.Description and o.Description ~= "" then
		d = Lbl(info, { Text = tostring(o.Description), TextSize = 12, Font = FONT.Reg, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Tr = true }, "Sub")
	end
	return t, d
end

local function Stacked(self, o)
	local row = Box(self.Content, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = self:_Order() }, "Element", 6)
	Pad(row, 8, 10, 8, 10)
	List(row, 6)
	return row
end

local function Flagged(o, obj)
	if o.Flag then
		MX.Options[o.Flag] = obj
		MX.Flags[o.Flag] = obj:Get()
		if obj.Serialize then
			local ok, v = pcall(obj.Serialize, obj)
			if ok then obj._def = v end
		end
	end
end

local function Lockable(obj, row, o)
	local cover = Box(row, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.5, ZIndex = 8, Visible = false, Active = true }, "Window", 6)
	obj.Locked = false
	obj.LockedReason = o.LockedReason
	function obj:SetLocked(v, r)
		self.Locked = v and true or false
		if r ~= nil then self.LockedReason = r end
		cover.Visible = self.Locked
	end
	function obj:IsLocked() return self.Locked end
	function obj:SetLockedReason(r) self.LockedReason = r end
	MX:Tip(cover, function() return obj.LockedReason end)
	cover.InputBegan:Connect(function(i)
		if (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) and obj.LockedReason then
			MX:Notify({ Type = "Warning", Title = "Locked", Content = obj.LockedReason, Duration = 2 })
		end
	end)
	if o.Locked then obj:SetLocked(true) end
end

local function Finish(self, o, obj, row)
	Lockable(obj, row, o)
	Flagged(o, obj)
	self:_Reg(o.Title or o.Name, row)
	MX._Depend(row, o)
	obj.Row = row
	return obj
end

function Container:AddParagraph(o)
	o = o or {}
	local row = Stacked(self, {})
	local t, te = Lbl(row, { Text = tostring(o.Title or ""), Font = FONT.Bold, TextSize = 14, Size = UDim2.new(1, 0, 0, TS(14) + 4), LayoutOrder = 1, Tr = true })
	local c, ce = Lbl(row, { Text = tostring(o.Content or ""), Font = FONT.Reg, TextSize = 13, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Tr = true }, "Sub")
	local obj = {}
	function obj:Set(title, content)
		if title then TrSet(te, tostring(title)) end
		if content then TrSet(ce, tostring(content)) end
	end
	self:_Reg(o.Title, row)
	MX._Depend(row, o)
	return obj
end

function Container:AddCopyField(o)
	o = o or {}
	local row, ctl, info = MakeRow(self, o, 70)
	Titles(info, o)
	local b = Box(ctl, { Size = UDim2.new(0, 64, 0, Touch and 28 or 24) }, "Accent", 5)
	Lbl(b, { Text = o.ButtonText or "Copy", Size = UDim2.fromScale(1, 1), TextSize = 13, TextXAlignment = CENTER }, "OnAccent")
	local h = Hit(b, 4)
	Tap(h, function()
		local ok = Copy(o.Value or "")
		MX:Notify({ Type = ok and "Success" or "Warning", Title = ok and "Copied" or "Not Supported", Content = ok and tostring(o.Value) or "Your executor has no clipboard.", Duration = 2 })
	end)
	self:_Reg(o.Title, row)
	MX._Depend(row, o)
	local obj = {}
	function obj:SetVisible(v) row.Visible = v end
	return obj
end

local function Spinner(parent, order)
	local sp = Box(parent, { Size = UDim2.fromOffset(14, 14), Visible = false, LayoutOrder = order or 0 }, nil, 7)
	local st = New("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, sp)
	Bind(st, { Color = "Accent" })
	local g = New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(1, 1) }) }, st)
	local tw
	return sp, function(on)
		sp.Visible = on
		if tw then tw:Cancel() tw = nil end
		if on then
			g.Rotation = 0
			tw = TweenService:Create(g, TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })
			tw:Play()
		end
	end
end

function Container:AddButton(o, cb)
	if type(o) == "string" then o = { Title = o, Callback = type(cb) == "function" and cb or nil } end
	local row, ctl, info = MakeRow(self, o, 24)
	Titles(info, o)
	local chev = MakeIcon(ctl, "chevron-right", 14, "Sub")
	chev.LayoutOrder = 2
	local _, spin = Spinner(ctl, 1)
	local fill = Box(row, { Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 0.7, Visible = false, ZIndex = 1 }, "Accent", 6)
	local hit = Hit(row, 2)
	local obj = { Type = "Button", Loading = false, _auto = false }
	local dur = (type(o.Hold) == "number" and o.Hold) or o.HoldTime or (o.Hold and 1.2) or nil
	local function flash()
		Tween(row, { BackgroundColor3 = Theme.Danger }, 0.1)
		task.delay(0.35, function()
			if row.Parent then Tween(row, { BackgroundColor3 = Theme.Element }, 0.25) end
		end)
	end
	function obj:SetLoading(v)
		self.Loading = v and true or false
		spin(self.Loading)
		chev.Visible = not self.Loading
	end
	function obj:IsLoading() return self.Loading end
	local function fire()
		if obj.Loading or obj.Locked then return end
		local done = false
		task.spawn(function()
			local ok, err = pcall(o.Callback or function() end)
			done = true
			if not ok then
				warn("[MX] " .. tostring(err))
				flash()
			end
			if obj._auto then
				obj._auto = false
				obj:SetLoading(false)
			end
		end)
		task.delay(0.15, function()
			if not done and not obj.Loading then
				obj._auto = true
				obj:SetLoading(true)
			end
		end)
	end
	Hover(hit, row, "Element", "Hover")
	if dur then
		local holding = false
		hit.InputBegan:Connect(function(i)
			if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and not obj.Loading and not obj.Locked then
				holding = true
				fill.Visible = true
				local t0 = os.clock()
				task.spawn(function()
					while holding do
						local p = math.clamp((os.clock() - t0) / dur, 0, 1)
						fill.Size = UDim2.new(p, 0, 1, 0)
						if p >= 1 then
							holding = false
							fire()
							break
						end
						RunService.Heartbeat:Wait()
					end
					Tween(fill, { Size = UDim2.new(0, 0, 1, 0) }, 0.2)
					task.delay(0.22, function() fill.Visible = false end)
				end)
			end
		end)
		hit.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then holding = false end
		end)
		hit.MouseLeave:Connect(function() holding = false end)
	else
		Tap(hit, fire)
	end
	if o.Loading then obj:SetLoading(true) end
	Lockable(obj, row, o)
	self:_Reg(o.Title, row)
	MX._Depend(row, o)
	obj.Row = row
	return obj
end

local function KeyCap(parent, key, onSet, order, modeApi)
	local b = Box(parent, { Size = UDim2.new(0, 0, 0, 22), AutomaticSize = AX, LayoutOrder = order or 1 }, "Card", 5, "Border")
	Pad(b, 0, 6, 0, 6)
	local l = Lbl(b, { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, TextSize = 11, Font = FONT.Mono, TextXAlignment = CENTER }, "Sub")
	local h = Hit(b, 4)
	local cap = { Key = key }
	local function paint() l.Text = "[" .. KeyLabel(cap.Key) .. "]" end
	function cap:Set(k)
		self.Key = k
		paint()
	end
	local function listen()
		if MX.Listening then return end
		l.Text = "[...]"
		l.TextColor3 = Theme.Accent
		MX:Listen(function(r)
			l.TextColor3 = Theme.Sub
			if r == false then paint() return end
			cap.Key = r
			paint()
			onSet(r)
		end)
	end
	local function menu()
		local vals = {}
		if UIS.KeyboardEnabled then table.insert(vals, "Rebind") end
		if modeApi then
			for _, m in ipairs(modeApi.Modes) do table.insert(vals, m) end
		end
		table.insert(vals, "Clear Key")
		ListPopup(b, {
			Values = vals, Search = false, Width = 120,
			IsSel = function(v) return modeApi ~= nil and modeApi.Get() == v end,
			OnPick = function(v)
				if v == "Rebind" then
					task.defer(listen)
				elseif v == "Clear Key" then
					cap.Key = nil
					paint()
					onSet(nil)
				else
					modeApi.Set(v)
					paint()
				end
			end,
		})
	end
	Tap(h, function()
		if UIS.KeyboardEnabled then listen() else menu() end
	end)
	h.MouseButton2Click:Connect(menu)
	MX:Tip(h, "Click: set key   Right click: mode")
	paint()
	return b, cap
end

local function NewColorPicker(o)
	local c = o.Default or C3(255, 255, 255)
	local h, s, v = c:ToHSV()
	local cp = { Type = "ColorPicker", H = h, S = s, V = v, A = o.DefaultAlpha or 1, Rainbow = false, Speed = o.RainbowSpeed or 0.25, Watchers = {}, Title = o.Title, NoRainbow = o.NoRainbow }
	function cp:Get() return Color3.fromHSV(self.H, self.S, self.V) end
	function cp:GetAlpha() return self.A end
	function cp:GetRainbow() return self.Rainbow end
	function cp:_Fire(silent)
		local col = self:Get()
		if o.Flag then
			MX.Flags[o.Flag] = col
			MX.Flags[o.Flag .. "_alpha"] = self.A
			MX.Flags[o.Flag .. "_rainbow"] = self.Rainbow
		end
		for _, w in ipairs(self.Watchers) do w() end
		if not silent and o.Callback then MX._Run(o.Callback, col, self.A) end
	end
	function cp:Set(color, silent)
		self.H, self.S, self.V = color:ToHSV()
		self:_Fire(silent)
	end
	function cp:SetAlpha(a, silent)
		self.A = math.clamp(a, 0, 1)
		self:_Fire(silent)
	end
	function cp:SetRainbow(b, silent)
		b = b and true or false
		if self.Rainbow == b then return end
		self.Rainbow = b
		if self._rb then self._rb:Disconnect() self._rb = nil end
		if b then
			self._rb = Conn(RunService.Heartbeat, function(dt)
				self.H = (self.H + dt * self.Speed) % 1
				self:_Fire()
			end)
		end
		self:_Fire(silent)
		if not silent and o.RainbowCallback then MX._Run(o.RainbowCallback, b) end
	end
	function cp:Serialize()
		return { r = self.H, s = self.S, v = self.V, a = self.A, rb = self.Rainbow }
	end
	function cp:Deserialize(d)
		if type(d) ~= "table" then return end
		self.H, self.S, self.V = d.r or self.H, d.s or self.S, d.v or self.V
		self.A = d.a or self.A
		self:SetRainbow(d.rb, true)
		self:_Fire()
	end
	if o.Flag then
		MX.Options[o.Flag] = cp
		MX.Flags[o.Flag] = cp:Get()
		MX.Flags[o.Flag .. "_alpha"] = cp.A
		MX.Flags[o.Flag .. "_rainbow"] = false
	end
	if o.Rainbow then cp:SetRainbow(true, true) end
	cp._def = cp:Serialize()
	return cp
end

local RainbowSeq = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C3(255, 0, 0)), ColorSequenceKeypoint.new(1 / 6, C3(255, 255, 0)), ColorSequenceKeypoint.new(2 / 6, C3(0, 255, 0)),
	ColorSequenceKeypoint.new(3 / 6, C3(0, 255, 255)), ColorSequenceKeypoint.new(4 / 6, C3(0, 0, 255)), ColorSequenceKeypoint.new(5 / 6, C3(255, 0, 255)), ColorSequenceKeypoint.new(1, C3(255, 0, 0)),
})

local function BuildPicker(cp)
	local f = NewPopupFrame(226, nil)
	Pad(f, 10, 10, 10, 10)
	List(f, 8)
	Lbl(f, { Text = tostring(cp.Title or "Color"), Font = FONT.Bold, TextSize = 13, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1 })
	local sv = New("Frame", { Size = UDim2.new(1, 0, 0, 120), BorderSizePixel = 0, LayoutOrder = 2, ClipsDescendants = true }, f)
	New("UICorner", { CornerRadius = UDim.new(0, 5) }, sv)
	local wh = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C3(255, 255, 255), BorderSizePixel = 0 }, sv)
	New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, wh)
	local bl = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C3(0, 0, 0), BorderSizePixel = 0 }, sv)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, bl)
	local cur = New("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 4 }, sv)
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, cur)
	New("UIStroke", { Thickness = 2, Color = C3(255, 255, 255) }, cur)
	local hue = New("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = C3(255, 255, 255), BorderSizePixel = 0, LayoutOrder = 3 }, f)
	New("UICorner", { CornerRadius = UDim.new(0, 5) }, hue)
	New("UIGradient", { Color = RainbowSeq }, hue)
	local hcur = New("Frame", { Size = UDim2.new(0, 4, 1, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C3(255, 255, 255), BorderSizePixel = 0, ZIndex = 4 }, hue)
	New("UICorner", { CornerRadius = UDim.new(0, 2) }, hcur)
	New("UIStroke", { Thickness = 1, Color = C3(0, 0, 0), Transparency = 0.5 }, hcur)
	local alpha = Box(f, { Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 4, ClipsDescendants = true }, "Element", 5)
	local acol = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, alpha)
	New("UIGradient", { Transparency = NumberSequence.new(1, 0) }, acol)
	local acur = New("Frame", { Size = UDim2.new(0, 4, 1, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C3(255, 255, 255), BorderSizePixel = 0, ZIndex = 4 }, alpha)
	New("UICorner", { CornerRadius = UDim.new(0, 2) }, acur)
	New("UIStroke", { Thickness = 1, Color = C3(0, 0, 0), Transparency = 0.5 }, acur)
	local hr = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 5 }, f)
	List(hr, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	local hb = Box(hr, { Size = UDim2.new(0, 84, 1, 0), LayoutOrder = 1 }, "Element", 5)
	local hex = New("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0), Text = "", ClearTextOnFocus = false, Font = FONT.Mono, TextSize = TS(12), TextXAlignment = LEFT }, hb)
	Bind(hex, { TextColor3 = "Text" })
	local rl = Lbl(hr, { Text = "Rainbow", Size = UDim2.new(0, 54, 1, 0), TextSize = 12, LayoutOrder = 2 }, "Sub")
	local rt = Box(hr, { Size = UDim2.fromOffset(32, 18), LayoutOrder = 3 }, "Off", 9)
	local rk = New("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = C3(255, 255, 255), BorderSizePixel = 0 }, rt)
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, rk)
	local rh = Hit(rt, 3)
	if cp.NoRainbow then
		rl.Visible = false
		rt.Visible = false
	end
	local sh = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = 6 }, f)
	local sl = New("UIListLayout", { Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Horizontal, Wraps = true, SortOrder = Enum.SortOrder.LayoutOrder }, sh)
	local function refresh()
		local col = cp:Get()
		sv.BackgroundColor3 = Color3.fromHSV(cp.H, 1, 1)
		cur.Position = UDim2.new(cp.S, 0, 1 - cp.V, 0)
		hcur.Position = UDim2.new(cp.H, 0, 0.5, 0)
		acol.BackgroundColor3 = col
		acur.Position = UDim2.new(cp.A, 0, 0.5, 0)
		if not hex:IsFocused() then hex.Text = Hex(col):upper() end
		rt.BackgroundColor3 = cp.Rainbow and Theme.Accent or Theme.Off
		Tween(rk, { Position = cp.Rainbow and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6) }, 0.12)
	end
	table.insert(cp.Watchers, refresh)
	Watch(f, function() refresh() end)
	local function pointer(frame, pos)
		local ap, as = frame.AbsolutePosition, frame.AbsoluteSize
		return math.clamp((pos.X - ap.X) / math.max(as.X, 1), 0, 1), math.clamp((pos.Y - ap.Y) / math.max(as.Y, 1), 0, 1)
	end
	Drag(sv, { Move = function(pos)
		local x, y = pointer(sv, pos)
		cp.S, cp.V = x, 1 - y
		cp:_Fire()
	end })
	Drag(hue, { Move = function(pos)
		if cp.Rainbow then cp:SetRainbow(false) end
		cp.H = (pointer(hue, pos))
		cp:_Fire()
	end })
	Drag(alpha, { Move = function(pos)
		cp.A = (pointer(alpha, pos))
		cp:_Fire()
	end })
	hex.FocusLost:Connect(function()
		local t = hex.Text:gsub("#", "")
		if #t == 6 and t:match("^%x+$") then
			cp:Set(C3(tonumber(t:sub(1, 2), 16), tonumber(t:sub(3, 4), 16), tonumber(t:sub(5, 6), 16)))
		end
		refresh()
	end)
	Tap(rh, function() cp:SetRainbow(not cp.Rainbow) end)
	local function rebuildSaved()
		for _, ch in ipairs(sh:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local add = Box(sh, { Size = UDim2.fromOffset(20, 20), LayoutOrder = 0 }, "Element", 4, "Border")
		Lbl(add, { Text = "+", Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextSize = 14, Font = FONT.Bold }, "Sub")
		local ah = Hit(add, 3)
		Tap(ah, function()
			table.insert(MX.SavedColors, cp:Get())
			rebuildSaved()
		end)
		for i, col in ipairs(MX.SavedColors) do
			local sw = Box(sh, { Size = UDim2.fromOffset(20, 20), LayoutOrder = i, BackgroundTransparency = 0 }, nil, 4, "Border")
			sw.BackgroundColor3 = col
			local b = Hit(sw, 3)
			local t0
			b.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton2 then
					table.remove(MX.SavedColors, i)
					rebuildSaved()
				elseif inp.UserInputType == Enum.UserInputType.Touch then
					t0 = os.clock()
				end
			end)
			b.InputEnded:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.Touch and t0 and os.clock() - t0 > 0.5 then
					table.remove(MX.SavedColors, i)
					rebuildSaved()
					t0 = nil
				end
			end)
			Tap(b, function()
				if t0 and os.clock() - t0 > 0.5 then return end
				if cp.Rainbow then cp:SetRainbow(false) end
				cp:Set(col)
			end)
		end
	end
	rebuildSaved()
	refresh()
	return f, rebuildSaved
end

local function OpenPicker(cp, anchor)
	if not cp.Frame then
		cp.Frame, cp.Resaved = BuildPicker(cp)
	end
	cp.Resaved()
	MX:ShowPopup(cp.Frame, anchor, { AlignRight = true })
end

local function Swatch(parent, cp, order)
	local s = Box(parent, { Size = UDim2.fromOffset(20, 20), LayoutOrder = order or 1, BackgroundTransparency = 0 }, nil, 10, "Border")
	s.BackgroundColor3 = cp:Get()
	table.insert(cp.Watchers, function()
		if s.Parent then s.BackgroundColor3 = cp:Get() end
	end)
	local h = Hit(s, 4)
	Tap(h, function() OpenPicker(cp, s) end)
	return s
end

local function MakeMenu(title, width)
	local f = NewPopupFrame(width or 240, nil)
	Pad(f, 8, 8, 8, 8)
	List(f, 6)
	Lbl(f, { Text = tostring(title or ""), Font = FONT.Bold, TextSize = 13, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0, Tr = true })
	local sc = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y, LayoutOrder = 1 }, f)
	Bind(sc, { ScrollBarImageColor3 = "Sub" })
	List(sc, 5)
	local c = setmetatable({ Content = sc, NoIndex = true, Scroll = sc }, ContainerMT)
	return c, f
end

local function ShowMenu(menu, frame, anchor, placement)
	local ab = anchor.AbsolutePosition - Overlay.AbsolutePosition
	local as, vp = anchor.AbsoluteSize, Overlay.AbsoluteSize
	local below = vp.Y - (ab.Y + as.Y + 4) - 10
	local above = ab.Y - 4 - 10
	local avail = below >= 240 and below or math.max(below, above)
	local maxH = math.max(100, avail / MX.Scale - 56)
	local sc = menu.Scroll
	sc.AutomaticSize = AY
	sc.Size = UDim2.new(1, 0, 0, 0)
	MX:ShowPopup(frame, anchor, { AlignRight = placement == nil, Placement = placement })
	task.spawn(function()
		RunService.RenderStepped:Wait()
		if not sc.Parent then return end
		local h = sc.AbsoluteSize.Y / MX.Scale
		sc.AutomaticSize = Enum.AutomaticSize.None
		sc.Size = UDim2.new(1, 0, 0, math.max(40, math.min(maxH, h)))
	end)
end

function Container:AddColorPicker(o)
	if type(o) == "string" then o = { Title = o } end
	local row, ctl, info = MakeRow(self, o, 40)
	Titles(info, o)
	local cp = NewColorPicker(o)
	cp.Title = o.Title or "Color"
	Swatch(ctl, cp, 1)
	Lockable(cp, row, o)
	cp.Row = row
	self:_Reg(o.Title, row)
	MX._Depend(row, o)
	return cp
end

function Container:AddToggle(o, def, cb)
	if type(o) == "string" then
		if type(def) == "function" then cb, def = def, nil end
		o = { Title = o, Default = def, Callback = cb }
	end
	local switch = o.Style == "Switch"
	local keyed = o.Keybind ~= nil or o.Bind == true
	local nExtra = o.Color and 1 or 0
	local ctlW = (switch and 40 or 22) + nExtra * 28 + (keyed and 52 or 0)
	local row, ctl, info = MakeRow(self, o, ctlW)
	Titles(info, o)
	local obj = { Type = "Toggle", Value = false }
	local track, knob, check, checkProp
	if switch then
		track = Box(ctl, { Size = UDim2.fromOffset(38, 20), LayoutOrder = 4 }, nil, 10)
		track.BackgroundTransparency = 0
		knob = New("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = C3(255, 255, 255), BorderSizePixel = 0 }, track)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
	else
		track = Box(ctl, { Size = UDim2.fromOffset(20, 20), LayoutOrder = 4 }, nil, 5)
		track.BackgroundTransparency = 0
		check = MakeIcon(track, "check", 14, "OnAccent")
		check.AnchorPoint = Vector2.new(0.5, 0.5)
		check.Position = UDim2.fromScale(0.5, 0.5)
		checkProp = check:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
		check[checkProp] = 1
	end
	local function stop(inst, prop)
		local st = Active[inst]
		if st and st[prop] then
			st[prop]:Cancel()
			st[prop] = nil
		end
	end
	local function paint(instant)
		local on = obj.Value
		local col = on and Theme.Accent or Theme.Off
		if instant then
			stop(track, "BackgroundColor3")
			track.BackgroundColor3 = col
		else
			Tween(track, { BackgroundColor3 = col }, 0.15)
		end
		if switch then
			local p = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
			if instant then
				stop(knob, "Position")
				knob.Position = p
			else
				Tween(knob, { Position = p }, 0.15)
			end
		else
			if instant then
				stop(check, checkProp)
				check[checkProp] = on and 0 or 1
			else
				Tween(check, { [checkProp] = on and 0 or 1 }, 0.12)
			end
		end
	end
	Watch(track, function() paint(true) end)
	local cb = o.Callback
	function obj:Get() return self.Value end
	function obj:Toggle() self:Set(not self.Value) end
	function obj:Set(v, silent)
		v = v and true or false
		if self.Value == v then return end
		self.Value = v
		paint(false)
		if o.Flag then MX.Flags[o.Flag] = v end
		if not silent and cb then MX._Run(cb, v) end
		MX:_KeyListRefresh()
		if MX._DepTick then MX._DepTick() end
	end
	function obj:Serialize() return self.Value end
	function obj:Deserialize(v) self:Set(v and true or false) end
	local hit = Hit(track, 4)
	hit.AnchorPoint = Vector2.new(0.5, 0.5)
	hit.Position = UDim2.fromScale(0.5, 0.5)
	hit.Size = UDim2.new(0, (switch and 38 or 20) + 10, 0, RH)
	local function flip()
		if not obj.Locked then obj:Set(not obj.Value) end
	end
	Tap(hit, flip)
	local rowHit = Hit(row, 2)
	Hover(rowHit, row, "Element", "Hover")
	Tap(rowHit, flip)
	if o.Color then
		local co = o.Color
		if typeof(co) == "Color3" then co = { Default = co } end
		co.Title = co.Title or o.Title or "Color"
		local cp = NewColorPicker(co)
		obj.ColorPicker = cp
		Swatch(ctl, cp, 1)
	end
	if keyed then
		local bind
		local _, cap = KeyCap(ctl, o.Keybind, function(k)
			bind.Key = k
			if o.Flag then MX.Flags[o.Flag .. "_key"] = k end
			MX:_KeyListRefresh()
		end, 3, {
			Modes = { "Toggle", "Hold", "Press" },
			Get = function() return bind.Mode end,
			Set = function(m)
				bind.Mode = m
				bind.Held = false
				MX:_KeyListRefresh()
			end,
		})
		bind = MakeBind(o.Title or o.Name or "Toggle", o.KeyMode or "Toggle", o.Keybind, function(down)
			if obj.Locked then return end
			local m = bind.Mode
			if m == "Toggle" then
				if down then obj:Set(not obj.Value) end
			elseif m == "Hold" then
				obj:Set(down)
			elseif down and cb then
				MX._Run(cb, true)
			end
		end, function() return obj.Value end)
		obj.Bind = bind
		function obj:SetKey(k)
			bind.Key = k
			cap:Set(k)
			MX:_KeyListRefresh()
		end
		function obj:GetKey() return bind.Key end
		function obj:SetMode(m)
			bind.Mode = m
			bind.Held = false
			MX:_KeyListRefresh()
		end
		function obj:GetMode() return bind.Mode end
		if o.Flag then
			MX.Flags[o.Flag .. "_key"] = o.Keybind
			MX.Options[o.Flag .. "_key"] = {
				Serialize = function() return KeyEncode(bind.Key, bind.Mode) end,
				Deserialize = function(_, v)
					local k, m = KeyDecode(v)
					obj:SetKey(k)
					if m then obj:SetMode(m) end
				end,
				Get = function() return bind.Key end,
			}
		end
	end
	if o.Default == true or o.Value == true or o.State == true then obj.Value = true end
	paint(true)
	local done = Finish(self, o, obj, row)
	if obj.Value and cb and o.FireDefault ~= false then task.defer(MX._Run, cb, true) end
	return done
end

local function Bar(parent, h)
	local kw = Touch and 18 or 14
	local wrap = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h or (Touch and 24 or 18)) }, parent)
	local track = Box(wrap, { Size = UDim2.new(1, -kw, 0, 6), Position = UDim2.new(0, kw / 2, 0.5, -3) }, "Off", 3)
	local fill = Box(track, { Size = UDim2.new(0, 0, 1, 0) }, "Accent", 3)
	return wrap, track, fill
end

local function Knob(parent)
	local k = New("Frame", { Size = UDim2.fromOffset(Touch and 18 or 14, Touch and 18 or 14), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C3(255, 255, 255), BorderSizePixel = 0, ZIndex = 3 }, parent)
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, k)
	New("UIStroke", { Thickness = 1, Color = C3(0, 0, 0), Transparency = 0.75 }, k)
	return k
end

local function ValueBox(parent, w)
	local tb = New("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(0, w or 80, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Text = "", ClearTextOnFocus = false, Font = FONT.Med, TextSize = TS(13), TextXAlignment = RIGHT }, parent)
	Bind(tb, { TextColor3 = "Sub" })
	return tb
end

function Container:AddSlider(o)
	if type(o) == "string" then o = { Title = o } end
	local min, max = o.Min or 0, o.Max or 100
	local inc = o.Increment or 1
	local row = Stacked(self, o)
	local top = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TS(14) + 4), LayoutOrder = 1 }, row)
	local left = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -86, 1, 0) }, top)
	List(left, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	local obj = { Type = "Slider", Value = math.clamp(Snap(o.Default or min, inc, min), min, max), ToggleValue = o.ToggleDefault or false }
	local swTrack, swKnob
	if o.Toggle then
		swTrack = Box(left, { Size = UDim2.fromOffset(28, 16), LayoutOrder = 0 }, nil, 8)
		swTrack.BackgroundTransparency = 0
		swKnob = New("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 3, 0.5, -5), BackgroundColor3 = C3(255, 255, 255), BorderSizePixel = 0 }, swTrack)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, swKnob)
		local sh = Hit(swTrack, 4)
		Tap(sh, function() if not obj.Locked then obj:SetToggle(not obj.ToggleValue) end end)
	end
	Lbl(left, { Text = tostring(o.Title or o.Name or ""), AutomaticSize = AX, Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 1, Tr = true })
	if o.Badge then MakeBadge(left, o.Badge, 2) end
	if IsPremium(o) then MakeBadge(left, "PREMIUM", 3) end
	local vb = ValueBox(top, 80)
	if o.Description and o.Description ~= "" then
		Lbl(row, { Text = tostring(o.Description), TextSize = 12, Font = FONT.Reg, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2 }, "Sub")
	end
	local wrap, track, fill = Bar(row, Touch and 36 or nil)
	wrap.LayoutOrder = 3
	if o.BarWidth then wrap.Size = UDim2.new(0, o.BarWidth, 0, wrap.Size.Y.Offset) end
	local knob = Knob(track)
	local function pct() return (obj.Value - min) / math.max(max - min, 1e-9) end
	local function paintToggle(instant)
		if not swTrack then return end
		local col = obj.ToggleValue and Theme.Accent or Theme.Off
		local p = obj.ToggleValue and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
		if instant then swTrack.BackgroundColor3 = col swKnob.Position = p else Tween(swTrack, { BackgroundColor3 = col }, 0.15) Tween(swKnob, { Position = p }, 0.15) end
	end
	local function paint()
		local p = pct()
		fill.Size = UDim2.new(p, 0, 1, 0)
		knob.Position = UDim2.new(p, 0, 0.5, 0)
		if not vb:IsFocused() then vb.Text = Fmt(obj.Value, inc) .. (o.Suffix or "") end
	end
	Watch(row, function() paintToggle(true) end)
	function obj:Get() return self.Value end
	function obj:Set(v, silent)
		v = math.clamp(Snap(tonumber(v) or self.Value, inc, min), min, max)
		local changed = v ~= self.Value
		self.Value = v
		paint()
		if o.Flag then MX.Flags[o.Flag] = v end
		if changed and not silent and o.Callback then MX._Run(o.Callback, v) end
	end
	function obj:SetToggle(v, silent)
		self.ToggleValue = v and true or false
		paintToggle(false)
		if o.ToggleFlag then MX.Flags[o.ToggleFlag] = self.ToggleValue end
		if not silent and o.ToggleCallback then MX._Run(o.ToggleCallback, self.ToggleValue) end
	end
	function obj:GetToggle() return self.ToggleValue end
	function obj:Serialize() return self.Value end
	function obj:Deserialize(v) self:Set(v, false) end
	local fine, startVal, startX, touchOff = nil, nil, nil, 0
	Drag(wrap, {
		Lock = true,
		Begin = function(i)
			if obj.Locked then return false end
			touchOff = 0
			if i.UserInputType == Enum.UserInputType.Touch then return false end
			if i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
				fine = o.FineFactor or 0.1
				startVal = obj.Value
				startX = i.Position.X
			else
				fine = nil
			end
		end,
		Move = function(pos)
			local w = math.max(track.AbsoluteSize.X, 1)
			if fine then
				obj:Set(startVal + (pos.X - startX) / w * (max - min) * fine)
			else
				obj:Set(min + math.clamp((pos.X + touchOff - track.AbsolutePosition.X) / w, 0, 1) * (max - min))
			end
		end,
	})
	wrap.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch or obj.Locked then return end
		local start = GuiPos(i)
		local c = knob.AbsolutePosition + knob.AbsoluteSize / 2
		local grab = math.abs(start.X - c.X) <= 28 and math.abs(start.Y - c.Y) <= 28
		local off = grab and (c.X - start.X) or 0
		local active, dead = false, false
		local cm, ce
		local function setFrom(x)
			local w = math.max(track.AbsoluteSize.X, 1)
			obj:Set(min + math.clamp((x + off - track.AbsolutePosition.X) / w, 0, 1) * (max - min))
		end
		local function done()
			if cm then
				cm:Disconnect()
				cm = nil
			end
			if ce then
				ce:Disconnect()
				ce = nil
			end
			if active then MX:ScrollLock(false) end
		end
		cm = UIS.InputChanged:Connect(function(c2)
			if c2 ~= i or dead then return end
			local p = GuiPos(c2)
			if not active then
				local dx, dy = math.abs(p.X - start.X), math.abs(p.Y - start.Y)
				if grab or (dx > 8 and dx > dy) then
					active = true
					MX:ScrollLock(true)
				elseif dy > 8 then
					dead = true
					return
				else
					return
				end
			end
			setFrom(p.X)
		end)
		ce = UIS.InputEnded:Connect(function(e)
			if e ~= i then return end
			if not active and not dead then
				local p = GuiPos(e)
				if (p - start).Magnitude <= 8 then setFrom(p.X) end
			end
			done()
		end)
	end)
	wrap.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton2 and not obj.Locked then obj:Set(o.Default or min) end
	end)
	vb.FocusLost:Connect(function()
		local n = tonumber(vb.Text:match("%-?%d+%.?%d*"))
		if n then obj:Set(n) end
		paint()
	end)
	if o.ToggleFlag then
		MX.Flags[o.ToggleFlag] = obj.ToggleValue
		MX.Options[o.ToggleFlag] = {
			Get = function() return obj.ToggleValue end,
			Serialize = function() return obj.ToggleValue end,
			Deserialize = function(_, v) obj:SetToggle(v and true or false) end,
		}
	end
	paint()
	paintToggle(true)
	return Finish(self, o, obj, row)
end

function Container:AddNumberInput(o)
	if type(o) == "string" then o = { Title = o } end
	local min, max = o.Min or 0, o.Max or 100
	local inc = o.Increment or 1
	local row, ctl, info = MakeRow(self, o, 170)
	Titles(info, o)
	local bh = Touch and 28 or 24
	local function sq(text, order)
		local b = Box(ctl, { Size = UDim2.fromOffset(bh, bh), LayoutOrder = order }, "Card", 5, "Border")
		Lbl(b, { Text = text, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextSize = 16, Font = FONT.Bold }, "Text")
		return b, Hit(b, 4)
	end
	local _, minus = sq("−", 1)
	local mid = Box(ctl, { Size = UDim2.new(0, 72, 0, bh), LayoutOrder = 2 }, "Card", 5, "Border")
	local tb = New("TextBox", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", ClearTextOnFocus = false, Font = FONT.Med, TextSize = TS(13), TextXAlignment = CENTER }, mid)
	Bind(tb, { TextColor3 = "Text" })
	local _, plus = sq("+", 3)
	local obj = { Type = "NumberInput", Value = o.Default or min }
	local function paint() if not tb:IsFocused() then tb.Text = Fmt(obj.Value, inc) .. (o.Suffix or "") end end
	function obj:Get() return self.Value end
	function obj:Set(v, silent)
		v = math.clamp(Snap(tonumber(v) or self.Value, inc, min), min, max)
		local changed = v ~= self.Value
		self.Value = v
		paint()
		if o.Flag then MX.Flags[o.Flag] = v end
		if changed and not silent and o.Callback then MX._Run(o.Callback, v) end
	end
	function obj:Serialize() return self.Value end
	function obj:Deserialize(v) self:Set(v) end
	local function repeater(btn, dir)
		btn.InputBegan:Connect(function(i)
			if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
			if obj.Locked then return end
			local held = true
			local conn
			local touch = i.UserInputType == Enum.UserInputType.Touch
			local origin = Vector2.new(i.Position.X, i.Position.Y)
			local step = function() obj:Set(obj.Value + dir * inc * (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 10 or 1)) end
			local stepped = false
			conn = UIS.InputEnded:Connect(function(e)
				if e == i or e.UserInputType == Enum.UserInputType.MouseButton1 then
					held = false
					conn:Disconnect()
					if touch and not stepped and (Vector2.new(e.Position.X, e.Position.Y) - origin).Magnitude < 14 then
						stepped = true
						step()
					end
				end
			end)
			task.spawn(function()
				if not touch then
					stepped = true
					step()
				end
				local t0 = os.clock()
				while held and os.clock() - t0 < 0.4 do task.wait() end
				while held do
					stepped = true
					step()
					task.wait(0.06)
				end
			end)
		end)
	end
	repeater(minus, -1)
	repeater(plus, 1)
	tb.FocusLost:Connect(function()
		local n = tonumber(tb.Text:match("%-?%d+%.?%d*"))
		if n then obj:Set(n) end
		paint()
	end)
	paint()
	return Finish(self, o, obj, row)
end

function ListPopup(anchor, cfg)
	local vals = cfg.Values
	local itemH = Touch and 36 or 30
	local showSearch = cfg.Search
	if showSearch == nil then showSearch = true end
	local rows = math.max(1, math.min(#vals, Touch and 5 or 6))
	local listH = rows * itemH + (rows - 1) * 2
	local w = math.max(cfg.Width or 160, cfg.Multi and 190 or 130)
	local h = 12 + listH + (showSearch and 36 or 0) + (cfg.Header and 34 or 0) + (cfg.Title and 22 or 0) + (cfg.Footer and (itemH + 6) or 0)
	local f = NewPopupFrame(w, h)
	Pad(f, 6, 6, 6, 6)
	List(f, 6)
	if cfg.Title then
		Lbl(f, { Text = cfg.Title, Size = UDim2.new(1, 0, 0, 16), TextSize = 11, Font = FONT.Bold, LayoutOrder = 0, Tr = true }, "Sub")
	end
	local paintAll
	local search
	if showSearch then
		local sb = Box(f, { Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1 }, "Element", 8)
		local si = MakeIcon(sb, "search", 14, "Sub")
		si.AnchorPoint = Vector2.new(0, 0.5)
		si.Position = UDim2.new(0, 10, 0.5, 0)
		search = New("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(1, -38, 1, 0), Position = UDim2.new(0, 32, 0, 0), PlaceholderText = MX:T("Search") .. " " .. #vals .. " " .. MX:T("options"), Text = "", ClearTextOnFocus = false, Font = FONT.Reg, TextSize = TS(13), TextXAlignment = LEFT }, sb)
		Bind(search, { TextColor3 = "Text", PlaceholderColor3 = "Sub" })
	end
	if cfg.Header then
		local hr = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 2 }, f)
		List(hr, 6, Enum.FillDirection.Horizontal)
		local function hb(text, all)
			local b = Box(hr, { Size = UDim2.new(0.5, -3, 1, 0), LayoutOrder = all and 1 or 2 }, "Element", 8)
			Lbl(b, { Text = text, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextSize = 12, Tr = true })
			local hh = Hit(b, 3)
			Hover(hh, b, "Element", "Hover")
			Tap(hh, function()
				cfg.OnAll(all)
				paintAll()
			end)
		end
		hb("Select All", true)
		hb("Deselect All", false)
	end
	local sc = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, listH), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y, LayoutOrder = 3 }, f)
	Bind(sc, { ScrollBarImageColor3 = "Sub" })
	List(sc, 2)
	local items = {}
	local openedAt = os.clock()
	function paintAll()
		for _, it in ipairs(items) do
			local on = cfg.IsSel(it.v)
			if cfg.Multi then
				it.circle.BackgroundTransparency = on and 0 or 1
				it.circle.BackgroundColor3 = Theme.Accent
				it.cs.Color = on and Theme.Accent or Theme.Sub
				it.c.Visible = on
			else
				it.t.TextColor3 = on and Theme.Accent or Theme.Text
				it.c.Visible = on
				it.b.BackgroundColor3 = Theme.Accent
				it.b.BackgroundTransparency = on and 0.88 or 1
			end
			it.on = on
		end
	end
	for i, v in ipairs(vals) do
		local b = New("Frame", { Size = UDim2.new(1, 0, 0, itemH), LayoutOrder = i, BackgroundTransparency = 1, BorderSizePixel = 0 }, sc)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
		local it = { v = v, b = b }
		if cfg.Multi then
			local circle = New("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 8, 0.5, -9), BackgroundTransparency = 1, BorderSizePixel = 0 }, b)
			New("UICorner", { CornerRadius = UDim.new(1, 0) }, circle)
			local cs = New("UIStroke", { Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Sub }, circle)
			local ck = MakeIcon(circle, "check", 12, "OnAccent")
			ck.AnchorPoint = Vector2.new(0.5, 0.5)
			ck.Position = UDim2.fromScale(0.5, 0.5)
			it.circle, it.cs, it.c = circle, cs, ck
			it.t = Lbl(b, { Text = tostring(v), Size = UDim2.new(1, -42, 1, 0), Position = UDim2.new(0, 34, 0, 0), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd })
		else
			it.t = Lbl(b, { Text = tostring(v), Size = UDim2.new(1, -36, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd }, false)
			local c = MakeIcon(b, "check", 14, "Accent")
			c.AnchorPoint = Vector2.new(1, 0.5)
			c.Position = UDim2.new(1, -10, 0.5, 0)
			it.c = c
		end
		local hh = Hit(b, 3)
		hh.MouseEnter:Connect(function()
			b.BackgroundColor3 = Theme.Hover
			b.BackgroundTransparency = 0.4
		end)
		hh.MouseLeave:Connect(function()
			if items[i] and items[i].on and not cfg.Multi then
				b.BackgroundColor3 = Theme.Accent
				b.BackgroundTransparency = 0.88
			else
				b.BackgroundTransparency = 1
			end
		end)
		Tap(hh, function()
			if os.clock() - openedAt < 0.25 then return end
			cfg.OnPick(v)
			paintAll()
			if not cfg.Multi then MX:ClosePopup() end
		end)
		items[#items + 1] = it
	end
	if #vals == 0 then
		Lbl(sc, { Text = "No entries", Size = UDim2.new(1, 0, 0, itemH), TextXAlignment = CENTER, TextSize = 13 }, "Sub")
	end
	paintAll()
	if search then
		search:GetPropertyChangedSignal("Text"):Connect(function()
			local q = search.Text:lower()
			for _, it in ipairs(items) do
				it.b.Visible = q == "" or tostring(it.v):lower():find(q, 1, true) ~= nil
			end
		end)
		search.FocusLost:Connect(function(enter)
			if not enter then return end
			for _, it in ipairs(items) do
				if it.b.Visible then
					cfg.OnPick(it.v)
					paintAll()
					if not cfg.Multi then MX:ClosePopup() end
					break
				end
			end
		end)
		if not Touch then task.defer(function() search:CaptureFocus() end) end
	end
	if cfg.Footer then
		local fr = Box(f, { Size = UDim2.new(1, 0, 0, itemH), LayoutOrder = 4 }, "Element", 6)
		local fi = MakeIcon(fr, cfg.Footer.Icon or "plus", 14, "Sub")
		fi.AnchorPoint = Vector2.new(0, 0.5)
		fi.Position = UDim2.new(0, 10, 0.5, 0)
		Lbl(fr, { Text = cfg.Footer.Text, Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -40, 1, 0), TextSize = 13, Tr = true })
		local fh = Hit(fr, 3)
		Hover(fh, fr, "Element", "Hover")
		Tap(fh, function() cfg.Footer.OnTap() end)
	end
	if cfg.Arrow then Tween(cfg.Arrow, { Rotation = 180 }, 0.12) end
	if cfg.Stroke then cfg.Stroke.Color = Theme.Accent end
	MX:ShowPopup(f, anchor, {
		Destroy = true,
		Placement = cfg.Placement,
		OnClose = function()
			if cfg.Arrow and cfg.Arrow.Parent then Tween(cfg.Arrow, { Rotation = 0 }, 0.12) end
			if cfg.Stroke and cfg.Stroke.Parent then cfg.Stroke.Color = Theme.Border end
		end,
	})
	return f
end

function Container:AddDropdown(o)
	if type(o) == "string" then o = { Title = o } end
	if o.Multi then return self:_MultiSelect(o) end
	local row, ctl, info = MakeRow(self, o, 152)
	Titles(info, o)
	local btn, bst = Box(ctl, { Size = UDim2.new(0, 146, 0, Touch and 28 or 24) }, "Card", 5, "Border")
	local txt = Lbl(btn, { Size = UDim2.new(1, -26, 1, 0), Position = UDim2.new(0, 8, 0, 0), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd })
	local darr = MakeIcon(btn, "chevron-down", 12, "Sub")
	darr.AnchorPoint = Vector2.new(1, 0.5)
	darr.Position = UDim2.new(1, -6, 0.5, 0)
	local hit = Hit(btn, 4)
	local obj = { Type = "Dropdown", Values = o.Values or {}, Value = nil }
	local function paint()
		txt.Text = obj.Value ~= nil and tostring(obj.Value) or (o.Placeholder or "Select")
	end
	function obj:Get() return self.Value end
	function obj:Set(v, silent)
		self.Value = v
		paint()
		if o.Flag then MX.Flags[o.Flag] = v end
		if not silent and o.Callback then MX._Run(o.Callback, v) end
	end
	function obj:Refresh(values)
		self.Values = values or {}
		if self.Value ~= nil and not table.find(self.Values, self.Value) then
			self.Value = nil
			if o.Flag then MX.Flags[o.Flag] = nil end
		end
		paint()
	end
	function obj:Serialize() return self.Value end
	function obj:Deserialize(v) if v ~= nil then self:Set(v) end end
	local function open()
		if obj.Locked then return end
		ListPopup(btn, {
			Values = obj.Values, Search = o.Search, Width = btn.AbsoluteSize.X / MX.Scale, Arrow = darr, Stroke = bst,
			IsSel = function(v) return obj.Value == v end,
			OnPick = function(v) obj:Set(v) end,
		})
	end
	Tap(hit, open)
	Hover(hit, btn, "Card", "Hover")
	local rowHit = Hit(row, 2)
	Hover(rowHit, row, "Element", "Hover")
	Tap(rowHit, open)
	if o.Default ~= nil then obj.Value = o.Default end
	paint()
	return Finish(self, o, obj, row)
end

function Container:_MultiSelect(o)
	if type(o) == "string" then o = { Title = o } end
	o.Multi = nil
	local row = Stacked(self, o)
	local th = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TS(14) + 4), LayoutOrder = 1 }, row)
	List(th, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	Lbl(th, { Text = tostring(o.Title or ""), AutomaticSize = AX, Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 1, Tr = true })
	if o.Badge then MakeBadge(th, o.Badge, 2) end
	if IsPremium(o) then MakeBadge(th, "PREMIUM", 3) end
	if o.Description and o.Description ~= "" then
		Lbl(row, { Text = tostring(o.Description), TextSize = 12, Font = FONT.Reg, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2 }, "Sub")
	end
	local field, fst = Box(row, { Size = UDim2.new(1, 0, 0, Touch and 32 or 28), LayoutOrder = 3 }, "Card", 6, "Border")
	local txt = Lbl(field, { Size = UDim2.new(1, -34, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd }, false)
	local arr = MakeIcon(field, "chevron-down", 12, "Sub")
	arr.AnchorPoint = Vector2.new(1, 0.5)
	arr.Position = UDim2.new(1, -10, 0.5, 0)
	local hit = Hit(field, 3)
	Hover(hit, field, "Card", "Hover")
	local obj = { Type = "MultiSelect", Values = o.Values or {}, Value = {} }
	local function paint()
		if #obj.Value == 0 then
			txt.Text = o.Placeholder or "None"
			txt.TextColor3 = Theme.Sub
		else
			local names = {}
			for _, v in ipairs(obj.Value) do names[#names + 1] = tostring(v) end
			txt.Text = table.concat(names, ", ")
			txt.TextColor3 = Theme.Text
		end
	end
	Watch(field, paint)
	function obj:Get() return self.Value end
	function obj:Set(v, silent)
		local list = {}
		for _, x in ipairs(type(v) == "table" and v or { v }) do
			if table.find(self.Values, x) and not table.find(list, x) then
				if not o.Limit or #list < o.Limit then table.insert(list, x) end
			end
		end
		self.Value = list
		paint()
		if o.Flag then MX.Flags[o.Flag] = list end
		if not silent and o.Callback then MX._Run(o.Callback, list) end
	end
	function obj:Refresh(values)
		self.Values = values or {}
		local keep = {}
		for _, x in ipairs(self.Value) do
			if table.find(self.Values, x) then keep[#keep + 1] = x end
		end
		self.Value = keep
		paint()
		if o.Flag then MX.Flags[o.Flag] = self.Value end
	end
	function obj:Serialize() return self.Value end
	function obj:Deserialize(v) self:Set(v) end
	Tap(hit, function()
		if obj.Locked then return end
		ListPopup(field, {
			Values = obj.Values, Multi = true, Header = true, Search = o.Search, Width = field.AbsoluteSize.X / MX.Scale, Arrow = arr, Stroke = fst,
			IsSel = function(v) return table.find(obj.Value, v) ~= nil end,
			OnPick = function(v)
				local list = table.clone(obj.Value)
				local i = table.find(list, v)
				if i then table.remove(list, i) else table.insert(list, v) end
				obj:Set(list)
			end,
			OnAll = function(all) obj:Set(all and table.clone(obj.Values) or {}) end,
		})
	end)
	if o.Default then obj:Set(o.Default, true) end
	paint()
	return Finish(self, o, obj, row)
end

function Container:AddTextbox(o)
	if type(o) == "string" then o = { Title = o } end
	local row, ctl, info = MakeRow(self, o, 152)
	Titles(info, o)
	local wrap = Box(ctl, { Size = UDim2.new(0, 146, 0, Touch and 28 or 24) }, "Card", 5, "Border")
	local tb = New("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0), Text = tostring(o.Default or ""), PlaceholderText = o.Placeholder or "", ClearTextOnFocus = false, Font = FONT.Reg, TextSize = TS(13), TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd }, wrap)
	Bind(tb, { TextColor3 = "Text", PlaceholderColor3 = "Sub" })
	local obj = { Type = "Textbox", Value = tb.Text }
	if o.Numeric then
		tb:GetPropertyChangedSignal("Text"):Connect(function()
			local t = (tb.Text:gsub("[^%d%.%-]", ""))
			if t ~= tb.Text then tb.Text = t end
		end)
	end
	function obj:Get() return self.Value end
	function obj:Set(s, silent)
		s = tostring(s or "")
		tb.Text = s
		self.Value = s
		if o.Flag then MX.Flags[o.Flag] = s end
		if not silent and o.Callback then MX._Run(o.Callback, s, false) end
	end
	function obj:Serialize() return self.Value end
	function obj:Deserialize(v) self:Set(v) end
	tb.FocusLost:Connect(function(enter)
		if obj.Locked then tb.Text = obj.Value return end
		obj.Value = tb.Text
		if o.Flag then MX.Flags[o.Flag] = tb.Text end
		if o.Callback and (not o.Finished or enter) then MX._Run(o.Callback, tb.Text, enter) end
	end)
	return Finish(self, o, obj, row)
end

function Container:AddKeybind(o)
	if type(o) == "string" then o = { Title = o } end
	local row, ctl, info = MakeRow(self, o, 80)
	Titles(info, o)
	local obj = { Type = "Keybind", Key = o.Default, State = false }
	local bind, cap
	local function setKey(k, silent)
		obj.Key = k
		if bind then bind.Key = k end
		if cap then cap:Set(k) end
		if o.Flag then MX.Flags[o.Flag] = k end
		if o.MenuKey and (k == nil or k.EnumType == Enum.KeyCode) then MX:SetMenuKey(k) end
		if not silent and o.ChangedCallback then MX._Run(o.ChangedCallback, k) end
		MX:_KeyListRefresh()
	end
	local _
	_, cap = KeyCap(ctl, o.Default, function(k) setKey(k) end, 1, (not o.MenuKey) and {
		Modes = { "Press", "Toggle", "Hold" },
		Get = function() return bind.Mode end,
		Set = function(m)
			bind.Mode = m
			bind.Held = false
			obj.State = false
			MX:_KeyListRefresh()
		end,
	} or nil)
	if not o.MenuKey then
		bind = MakeBind(o.Title or o.Name or "Keybind", o.Mode or "Press", o.Default, function(down)
			if obj.Locked then return end
			local m = bind.Mode
			if m == "Press" then
				if down and o.Callback then MX._Run(o.Callback, bind.Key) end
			elseif m == "Toggle" then
				if down then
					obj.State = not obj.State
					if o.Callback then MX._Run(o.Callback, obj.State) end
				end
			else
				obj.State = down
				if o.Callback then MX._Run(o.Callback, down) end
			end
			MX:_KeyListRefresh()
		end, function() return obj.State end)
	elseif o.Default then
		MX:SetMenuKey(o.Default)
	end
	function obj:Get() return self.Key end
	function obj:GetState() return self.State end
	function obj:Set(k) setKey(k) end
	function obj:SetMode(m) if bind then bind.Mode = m bind.Held = false MX:_KeyListRefresh() end end
	function obj:GetMode() return bind and bind.Mode or nil end
	function obj:Serialize() return KeyEncode(self.Key, bind and bind.Mode or nil) end
	function obj:Deserialize(v)
		local k, m = KeyDecode(v)
		setKey(k)
		if m and bind then bind.Mode = m end
	end
	return Finish(self, o, obj, row)
end

function Container:AddProgress(o)
	if type(o) == "string" then o = { Title = o } end
	local min, max = o.Min or 0, o.Max or 100
	local row = Stacked(self, o)
	local top = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TS(14) + 4), LayoutOrder = 1 }, row)
	local left = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -90, 1, 0) }, top)
	List(left, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	Lbl(left, { Text = tostring(o.Title or ""), AutomaticSize = AX, Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 1, Tr = true })
	if o.Badge then MakeBadge(left, o.Badge, 2) end
	if IsPremium(o) then MakeBadge(left, "PREMIUM", 3) end
	local vl = Lbl(top, { Size = UDim2.new(0, 90, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), TextXAlignment = RIGHT, TextSize = 13 }, "Sub")
	local _, _, fill = Bar(row, 8)
	fill.Parent.Parent.LayoutOrder = 2
	if o.Color then fill.BackgroundColor3 = o.Color end
	local obj = { Type = "Progress", Value = o.Default or min }
	function obj:Get() return self.Value end
	function obj:Set(v, silent)
		v = math.clamp(tonumber(v) or min, min, max)
		self.Value = v
		local p = (v - min) / math.max(max - min, 1e-9)
		if o.Smooth == false then fill.Size = UDim2.new(p, 0, 1, 0) else Tween(fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.25) end
		vl.Text = o.Suffix and (Fmt(v, 1) .. o.Suffix) or (math.floor(p * 100 + 0.5) .. "%")
		if o.Flag then MX.Flags[o.Flag] = v end
		if not silent and o.Callback then MX._Run(o.Callback, v) end
	end
	obj:Set(obj.Value, true)
	fill.Size = UDim2.new((obj.Value - min) / math.max(max - min, 1e-9), 0, 1, 0)
	self:_Reg(o.Title, row)
	if o.Flag then MX.Options[o.Flag] = obj MX.Flags[o.Flag] = obj.Value end
	MX._Depend(row, o)
	return obj
end

function Container:AddImage(o)
	o = o or {}
	local h = o.Height or 120
	local card = Box(self.Content, { Size = UDim2.new(1, 0, 0, h), LayoutOrder = self:_Order(), ClipsDescendants = true }, "Element", 8)
	local img = New("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = (o.Fit == "Fit" and Enum.ScaleType.Fit) or (o.Fit == "Stretch" and Enum.ScaleType.Stretch) or Enum.ScaleType.Crop, ZIndex = 1 }, card)
	local fade = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C3(0, 0, 0), BorderSizePixel = 0, ZIndex = 2 }, card)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.15) }, fade)
	local t = Lbl(card, { Text = tostring(o.Title or ""), Position = UDim2.new(0, 12, 1, -42), Size = UDim2.new(1, -24, 0, 18), Font = FONT.Bold, TextSize = 15, ZIndex = 3 }, false)
	t.TextColor3 = C3(255, 255, 255)
	local d = Lbl(card, { Text = tostring(o.Description or ""), Position = UDim2.new(0, 12, 1, -24), Size = UDim2.new(1, -24, 0, 16), Font = FONT.Reg, TextSize = 12, ZIndex = 3 }, false)
	d.TextColor3 = C3(215, 215, 225)
	local function sync()
		t.Visible = t.Text ~= ""
		d.Visible = d.Text ~= ""
		fade.Visible = t.Visible or d.Visible
	end
	sync()
	if o.Badge then
		local bw = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(1, -10, 0, 10), AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 0, 0, 16), AutomaticSize = AX, ZIndex = 4 }, card)
		MakeBadge(bw, o.Badge, 1)
	end
	local obj = {}
	function obj:SetImage(src)
		task.spawn(function()
			local r = MX:ResolveImage(src)
			if r and img.Parent then img.Image = r end
		end)
	end
	function obj:Set(title, desc)
		if title then t.Text = tostring(title) end
		if desc then d.Text = tostring(desc) end
		sync()
	end
	if o.Image then obj:SetImage(o.Image) end
	if o.Callback then
		local hit = Hit(card, 6)
		Tap(hit, function() MX._Run(o.Callback) end)
	end
	self:_Reg(o.Title, card)
	MX._Depend(card, o)
	return obj
end

local function HoldTap(hit, fill, secs, fn)
	local holding = false
	hit.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		if secs * (MX.HoldScale or 1) <= 0 then fn() return end
		holding = true
		fill.Visible = true
		local sf = hit.Parent
		while sf and not sf:IsA("ScrollingFrame") do sf = sf.Parent end
		local sc0 = sf and sf.CanvasPosition or nil
		local t0 = os.clock()
		task.spawn(function()
			while holding do
				if sf and sc0 and (sf.CanvasPosition - sc0).Magnitude > 4 then
					holding = false
					break
				end
				local p = math.clamp((os.clock() - t0) / (secs * (MX.HoldScale or 1)), 0, 1)
				fill.Size = UDim2.new(p, 0, 1, 0)
				if p >= 1 then
					holding = false
					fn()
					break
				end
				RunService.Heartbeat:Wait()
			end
			Tween(fill, { Size = UDim2.new(0, 0, 1, 0) }, 0.15)
			task.delay(0.17, function() fill.Visible = false end)
		end)
	end)
	hit.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then holding = false end
	end)
end

function Container:AddConfigManager(o)
	o = o or {}
	if not FS.ok() then
		self:AddLabel("Config saving is not supported by your executor.")
		return nil
	end
	local obj = {}
	local sel
	local names = {}
	local rows = {}
	local C = self.Content
	local function T(k) return MX:T(k) end
	local box = Box(C, { Size = UDim2.new(1, 0, 0, 140), LayoutOrder = self:_Order() }, "Element", 8, "Border")
	local empty = Lbl(box, { Text = "no configs yet", Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextSize = 13, Font = FONT.Reg, Tr = true }, "Sub")
	local sc = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4), CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y }, box)
	Bind(sc, { ScrollBarImageColor3 = "Sub" })
	List(sc, 2)
	local status = Lbl(C, { Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Font = FONT.Reg, LayoutOrder = self:_Order() }, "Sub")
	local function updateStatus()
		status.Text = string.format("%d %s  ·  %s: %s  ·  %s: %s", #names, T("saved"), T("loaded"), MX.LoadedConfig or T("none"), T("auto"), MX:GetAutoLoad() or T("none"))
	end
	local function paintRows()
		for _, r in ipairs(rows) do
			local on = r.name == sel
			r.frame.BackgroundColor3 = Theme.Accent
			r.frame.BackgroundTransparency = on and 0.85 or 1
			r.label.TextColor3 = on and Theme.Accent or Theme.Text
		end
	end
	Watch(box, paintRows)
	local function refresh()
		for _, c in ipairs(sc:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end
		rows = {}
		names = MX:ListConfigs()
		if sel and not table.find(names, sel) then sel = nil end
		empty.Visible = #names == 0
		for i, n in ipairs(names) do
			local f = New("Frame", { Size = UDim2.new(1, 0, 0, Touch and 32 or 26), LayoutOrder = i, BackgroundTransparency = 1, BorderSizePixel = 0 }, sc)
			New("UICorner", { CornerRadius = UDim.new(0, 6) }, f)
			local l = Lbl(f, { Text = n, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd }, false)
			local h = Hit(f, 3)
			Tap(h, function()
				sel = n
				paintRows()
			end)
			rows[#rows + 1] = { frame = f, label = l, name = n }
		end
		paintRows()
		updateStatus()
	end
	function obj:Refresh() refresh() end
	function obj:Select(n)
		sel = n
		paintRows()
	end
	function obj:GetSelected() return sel end
	table.insert(MX.Lang.Listeners, function()
		if box.Parent then updateStatus() end
	end)

	local function field(placeholderKey)
		local fb = Box(C, { Size = UDim2.new(1, 0, 0, Touch and 34 or 30), LayoutOrder = self:_Order() }, "Element", 7, "Border")
		local tb = New("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), Text = "", ClearTextOnFocus = false, Font = FONT.Reg, TextSize = TS(13), TextXAlignment = LEFT }, fb)
		Bind(tb, { TextColor3 = "Text", PlaceholderColor3 = "Sub" })
		Tr(tb, placeholderKey, "PlaceholderText")
		return tb
	end
	local function caption(key)
		return Lbl(C, { Text = key, Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Font = FONT.Med, LayoutOrder = self:_Order(), Tr = true }, "Text")
	end
	local function gridRow()
		local r = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Touch and 34 or 30), LayoutOrder = self:_Order() }, C)
		List(r, 6, Enum.FillDirection.Horizontal)
		return r
	end
	local function gbtn(parent, text, o2, fn)
		o2 = o2 or {}
		local b = Box(parent, { Size = o2.full and UDim2.new(1, 0, 1, 0) or UDim2.new(0.5, -3, 1, 0), ClipsDescendants = true }, "Element", 7, "Border")
		local fill = Box(b, { Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 0.75, Visible = false }, o2.red and "Danger" or "Accent", 7)
		fill.BackgroundTransparency = 0.75
		Lbl(b, { Text = text, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextSize = 13, Tr = true }, o2.red and "Danger" or "Text")
		local h = Hit(b, 3)
		if o2.hold then HoldTap(h, fill, o2.hold, fn) else
			Hover(h, b, "Element", "Hover")
			Tap(h, fn)
		end
		return b
	end
	local function note(kind, title, content)
		MX:Notify({ Type = kind, Title = title, Content = content, Duration = 2.2 })
	end

	caption("Config Name:")
	local nameBox = field("Type config name here...")
	local r1 = gridRow()
	gbtn(r1, "Save", nil, function()
		local n = CleanName(nameBox.Text)
		if n == "" then n = sel or MX.LoadedConfig or "" end
		if n == "" then note("Warning", "Config", "Select a config first.") return end
		if MX:SaveConfig(n) then
			sel = n
			MX.LoadedConfig = n
			refresh()
			note("Success", "Config", "Saved " .. n)
		else
			note("Error", "Config", "Could not save.")
		end
	end)
	gbtn(r1, "Load", nil, function()
		if not sel then note("Warning", "Config", "Select a config first.") return end
		if MX:LoadConfig(sel) then
			updateStatus()
			note("Success", "Config", "Loaded " .. sel)
		else
			note("Error", "Config", "Could not load.")
		end
	end)
	local r2 = gridRow()
	gbtn(r2, "Delete", { red = true, hold = 1 }, function()
		if not sel then note("Warning", "Config", "Select a config first.") return end
		local n = sel
		MX:DeleteConfig(n)
		if MX.LoadedConfig == n then MX.LoadedConfig = nil end
		if MX:GetAutoLoad() == n then MX:SetAutoLoad(nil) end
		sel = nil
		refresh()
		note("Info", "Config", "Deleted " .. n)
	end)
	gbtn(r2, "Refresh", nil, function() refresh() end)

	local autoT
	autoT = self:AddToggle({ Title = "Auto Load Config", Style = "Switch", FireDefault = false, Flag = "_cfg_auto", Default = MX:GetAutoLoad() ~= nil, Callback = function(v)
		if v then
			if not sel then
				autoT:Set(false, true)
				note("Warning", "Config", "Select a config first.")
				return
			end
			MX:SetAutoLoad(sel)
		else
			MX:SetAutoLoad(nil)
		end
		updateStatus()
	end })
	self:AddToggle({ Title = "Auto Save", Style = "Switch", FireDefault = false, Flag = "_cfg_autosave", Default = MX.AutoSave, Callback = function(v)
		if v and not MX.LoadedConfig and sel then MX.LoadedConfig = sel end
		MX:SetAutoSave(v)
		updateStatus()
	end })

	Lbl(C, { Text = "more", Size = UDim2.new(1, 0, 0, 16), TextXAlignment = CENTER, TextSize = 11, Font = FONT.Med, LayoutOrder = self:_Order(), Tr = true }, "Sub")
	local r3 = gridRow()
	gbtn(r3, "Rename", nil, function()
		local n = CleanName(nameBox.Text)
		if not sel or n == "" then note("Warning", "Config", "Select a config first.") return end
		if MX:RenameConfig(sel, n) then
			sel = n
			refresh()
			note("Success", "Config", "Renamed to " .. n)
		else
			note("Error", "Config", "Could not rename.")
		end
	end)
	gbtn(r3, "Reset", { red = true, hold = 1 }, function()
		MX:ResetOptions()
		note("Info", "Config", "Reset every option to its default")
	end)
	self:AddDropdown({ Title = "Autoload mode", Values = { "All accounts", "This account" }, Default = MX.AutoMode, Search = false, Callback = function(v)
		MX:SetAutoMode(v)
		local cur = MX:GetAutoLoad()
		if cur then MX:SetAutoLoad(cur) end
		updateStatus()
	end })

	Lbl(C, { Text = "share", Size = UDim2.new(1, 0, 0, 16), TextXAlignment = CENTER, TextSize = 11, Font = FONT.Med, LayoutOrder = self:_Order(), Tr = true }, "Sub")
	local r4 = gridRow()
	gbtn(r4, "Copy code", { full = true }, function()
		local code = MX:ExportConfig(sel)
		local ok = Copy(code)
		note(ok and "Success" or "Warning", ok and "Copied" or "Not Supported", ok and "Config code copied" or "Your executor has no clipboard.")
	end)
	local importBox = field("paste a config code...")
	local r5 = gridRow()
	gbtn(r5, "Import", { full = true }, function()
		local n, err = MX:ImportConfig(importBox.Text, nameBox.Text)
		if n then
			sel = n
			importBox.Text = ""
			refresh()
			note("Success", "Config", "Imported " .. n)
		else
			note("Error", "Config", err or "invalid code")
		end
	end)
	refresh()
	return obj
end

local function RevealChain(c)
	if c.Up then RevealChain(c.Up) end
	if c.Reveal then c.Reveal() end
end

local Section = {}
local SectionMT = {
	__index = function(t, k)
		local v = rawget(Section, k)
		if v ~= nil then return v end
		return Container[k]
	end,
}

local function NewSection(parent, base, o)
	if type(o) == "string" then o = { Title = o } end
	o = o or {}
	local title = tostring(o.Title or o.Name or "")
	local headless = o.NoHeader or title == ""
	if o.Collapsible == nil and not headless then o.Collapsible = true end
	local card = Box(parent, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = base.order or 0, ClipsDescendants = true }, "Card", 8, "Border")
	GlassOn(card, 0.35)
	List(card, 0)
	local sec = setmetatable({ Frame = card, Win = base.Win, Owner = base.Owner, NoIndex = base.NoIndex, SecTitle = title, Up = base.Up, Collapsed = false, ToggleValue = o.Default and true or false }, SectionMT)
	sec.SecObj = sec
	sec.Reveal = function() if sec.Collapsed then sec:SetCollapsed(true == false) end end
	local HH = Touch and 38 or 32
	local header = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, headless and 6 or HH), LayoutOrder = 0 }, card)
	local body = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = 1 }, card)
	Pad(body, 0, 8, 8, 8)
	List(body, 5)
	sec.Content = body
	local arrow, swTrack, swKnob
	if not headless then
		local left = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0) }, header)
		List(left, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
		if o.Icon then
			local ic = MakeIcon(left, o.Icon, 18, "Accent")
			if ic then ic.LayoutOrder = 1 end
		end
		sec.TitleLabel, sec.TitleEntry = Lbl(left, { Text = title, Font = FONT.Bold, TextSize = 14, AutomaticSize = AX, Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 2, Tr = true })
		if o.Badge then MakeBadge(left, o.Badge, 3) end
		local right = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0, 70, 1, 0), ZIndex = 4 }, header)
		List(right, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
		if o.Collapsible then
			local cb = Box(right, { Size = UDim2.fromOffset(22, 22), LayoutOrder = 2 }, "Element", 6)
			arrow = MakeIcon(cb, "chevron-down", 12, "Sub")
			arrow.AnchorPoint = Vector2.new(0.5, 0.5)
			arrow.Position = UDim2.fromScale(0.5, 0.5)
			local function flip() sec:SetCollapsed(not sec.Collapsed) end
			Tap(Hit(header, 2), flip)
			local cbHit = Hit(cb, 5)
			cbHit.AnchorPoint = Vector2.new(0.5, 0.5)
			cbHit.Position = UDim2.fromScale(0.5, 0.5)
			cbHit.Size = UDim2.fromOffset(38, HH)
			Tap(cbHit, flip)
		end
		if o.Toggle then
			swTrack = Box(right, { Size = UDim2.fromOffset(34, 18), LayoutOrder = 1, BackgroundTransparency = 0 }, nil, 9)
			swKnob = New("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = C3(255, 255, 255), BorderSizePixel = 0 }, swTrack)
			New("UICorner", { CornerRadius = UDim.new(1, 0) }, swKnob)
			local sh = Hit(swTrack, 5)
			Tap(sh, function() sec:SetToggle(not sec.ToggleValue) end)
		end
		local line = Box(header, { Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 1, -1), BackgroundTransparency = 0.5 }, "Border")
	end
	local dim
	if o.Toggle and o.Dim then
		dim = Box(header, { Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 4000), ZIndex = 6, Active = true, Visible = false, BackgroundTransparency = 0.5 }, "Card")
	end
	local function paintToggle(instant)
		if not swTrack then return end
		local on = sec.ToggleValue
		local col = on and Theme.Accent or Theme.Off
		local p = on and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
		if instant then swTrack.BackgroundColor3 = col swKnob.Position = p else Tween(swTrack, { BackgroundColor3 = col }, 0.15) Tween(swKnob, { Position = p }, 0.15) end
		if dim then dim.Visible = not on end
	end
	if swTrack then Watch(swTrack, function() paintToggle(true) end) end
	function sec:SetToggle(v, silent)
		self.ToggleValue = v and true or false
		paintToggle(false)
		if o.Flag then MX.Flags[o.Flag] = self.ToggleValue end
		if not silent and o.Callback then MX._Run(o.Callback, self.ToggleValue) end
	end
	function sec:Get() return self.ToggleValue end
	function sec:Set(v, silent) self:SetToggle(v, silent) end
	function sec:Serialize() return self.ToggleValue end
	function sec:Deserialize(v) self:SetToggle(v and true or false) end
	function sec:SetCollapsed(v)
		v = v and true or false
		if self.Collapsed == v and self._ct then return end
		self.Collapsed = v
		self._ct = (self._ct or 0) + 1
		local id = self._ct
		if arrow then Tween(arrow, { Rotation = v and -90 or 0 }, 0.15) end
		local function settle(open)
			if self._ct ~= id then return end
			body.AutomaticSize = AY
			body.Size = UDim2.new(1, 0, 0, 0)
			body.ClipsDescendants = false
			body.Visible = open
		end
		if v then
			local h = body.AbsoluteSize.Y / MX.Scale
			if body.Visible and h > 4 then
				body.ClipsDescendants = true
				body.AutomaticSize = Enum.AutomaticSize.None
				body.Size = UDim2.new(1, 0, 0, h)
				Tween(body, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)
				task.delay(0.2, function() settle(false) end)
			else
				settle(false)
			end
		else
			body.Visible = true
			task.spawn(function()
				RunService.RenderStepped:Wait()
				if self._ct ~= id then return end
				local h = body.AbsoluteSize.Y / MX.Scale
				if h > 4 then
					body.ClipsDescendants = true
					body.AutomaticSize = Enum.AutomaticSize.None
					body.Size = UDim2.new(1, 0, 0, 0)
					Tween(body, { Size = UDim2.new(1, 0, 0, h) }, 0.18)
					task.delay(0.2, function() settle(true) end)
				else
					settle(true)
				end
			end)
		end
		if o.CollapseKey then MX.Flags[o.CollapseKey] = self.Collapsed end
		if o.OnCollapse then MX._Run(o.OnCollapse, self.Collapsed) end
	end
	function sec:Collapse() self:SetCollapsed(true) end
	function sec:Expand() self:SetCollapsed(false) end
	function sec:ToggleCollapsed() self:SetCollapsed(not self.Collapsed) end
	function sec:IsCollapsed() return self.Collapsed end
	function sec:SetTitle(t)
		if self.TitleEntry then TrSet(self.TitleEntry, tostring(t)) end
	end
	function sec:SetVisible(v) card.Visible = v end
	function sec:Destroy() card:Destroy() end
	if o.Collapsible then
		local key = o.CollapseFlag or ("section:" .. tostring(base.Owner and base.Owner.Title or "") .. ":" .. title)
		o.CollapseKey = key
		MX.Options[key] = {
			Get = function() return sec.Collapsed end,
			Serialize = function() return sec.Collapsed end,
			Deserialize = function(_, v) sec:SetCollapsed(v and true or false) end,
		}
		if o.Collapsed then sec:SetCollapsed(true) end
	end
	if o.Toggle and o.Flag then
		MX.Options[o.Flag] = sec
		MX.Flags[o.Flag] = sec.ToggleValue
	end
	paintToggle(true)
	return sec
end

function Container:AddSection(o)
	local sec = NewSection(self.Content, { Win = self.Win, Owner = self.Owner, NoIndex = self.NoIndex, Up = self, order = self:_Order() }, o)
	return sec
end

local Page = {}
Page.__index = function(t, k)
	local v = rawget(Page, k)
	if v ~= nil then return v end
	if type(k) == "string" and k:sub(1, 3) == "Add" and k ~= "AddSection" and Container[k] then
		return function(self, ...) return Container[k](self:_Auto(), ...) end
	end
	return nil
end

local function InitPage(obj, win, name)
	obj.Win = win
	local sc = New("ScrollingFrame", {
		Name = tostring(name), BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AY, ScrollBarThickness = Touch and 5 or 3, ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false, ElasticBehavior = Enum.ElasticBehavior.Never,
	}, win.PageHost)
	Bind(sc, { ScrollBarImageColor3 = "Sub" })
	local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY }, sc)
	List(holder, 8)
	Pad(holder, 8, 8, 10, 8)
	obj.Frame, obj.Holder = sc, holder
	obj.Stash = New("Frame", { Visible = false, Size = UDim2.new(), BackgroundTransparency = 1 }, sc)
	obj.Items, obj.Bands = {}, {}
	table.insert(win.Pages, sc)
end

function Page:_Queue()
	if self._q then return end
	self._q = true
	task.defer(function()
		self._q = false
		if self.Frame.Parent then self:Reflow() end
	end)
end

function Page:Reflow()
	local cols = self.Win.Cols or 2
	for _, it in ipairs(self.Items) do it.sec.Frame.Parent = self.Stash end
	for _, b in ipairs(self.Bands) do b:Destroy() end
	self.Bands = {}
	local order, band, L, R, left = 0, nil, nil, nil, true
	local function newBand(full)
		order += 1
		band = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = order }, self.Holder)
		table.insert(self.Bands, band)
		if full or cols == 1 then
			L = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY }, band)
			List(L, 8)
			R = L
		else
			L = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = AY }, band)
			R = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -4, 0, 0), Position = UDim2.new(0.5, 4, 0, 0), AutomaticSize = AY }, band)
			List(L, 8)
			List(R, 8)
		end
		left = true
	end
	for i, it in ipairs(self.Items) do
		if it.side == "Full" then
			newBand(true)
			it.sec.Frame.LayoutOrder = i
			it.sec.Frame.Parent = L
			band = nil
		else
			if not band then newBand(false) end
			local target
			if cols == 1 then target = L
			elseif it.side == "Left" then target = L
			elseif it.side == "Right" then target = R
			else
				target = left and L or R
				left = not left
			end
			it.sec.Frame.LayoutOrder = i
			it.sec.Frame.Parent = target
		end
	end
end

function Page:AddSection(o)
	if type(o) == "string" then o = { Title = o } end
	o = o or {}
	local sec = NewSection(self.Stash, { Win = self.Win, Owner = self.Owner or self, order = 0 }, o)
	local item = { sec = sec, side = o.Side or "Auto" }
	if o.First then table.insert(self.Items, 1, item) else table.insert(self.Items, item) end
	self:_Queue()
	return sec
end

function Page:AddGroupbox(o)
	if type(o) == "string" then o = { Title = o } end
	return self:AddSection(o)
end

function Page:_Auto()
	if not self.Auto then
		self.Auto = self:AddSection({ NoHeader = true, Side = "Full", First = true })
	end
	return self.Auto
end

local Tab = {}
local function inherit(cls)
	return { __index = function(t, k)
		local v = rawget(cls, k)
		if v ~= nil then return v end
		return Page.__index(t, k)
	end }
end
local TabMT = inherit(Tab)

function Tab:Select(view)
	self.Win:_ShowTab(self, view)
end
local Window = {}
local WindowMT = { __index = Window }

function Window:_SideOrder()
	self._so = (self._so or 0) + 1
	return self._so
end

function Window:AddCategory(name, order)
	if self._miscHolder and tostring(name):lower() == self._miscName:lower() and order == nil then
		self._miscHolder.Visible = false
	end
	local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = order or self:_SideOrder() }, self.SideList)
	local l = Lbl(holder, { Text = tostring(name):upper(), Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -10, 1, -4), TextSize = 11, Font = FONT.Bold }, "Sub")
	local line = Box(holder, { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 0.5, 0), Visible = false }, "Border")
	table.insert(self.Cats, { l = l, line = line })
	l.Visible = not self.Collapsed
	line.Visible = self.Collapsed
	return holder
end

function Tab:_Style()
	local sel = self.Win.Selected == self
	self.Btn.BackgroundColor3 = Theme.Hover
	Tween(self.Btn, { BackgroundTransparency = sel and 0 or 1 }, 0.15)
	Tween(self.Ind, { BackgroundTransparency = sel and 0 or 1 }, 0.15)
	Tween(self.Label, { TextColor3 = sel and Theme.Text or Theme.Sub }, 0.15)
	local ic = self.IconObj
	if ic then
		local c = sel and Theme.Accent or Theme.Sub
		Tween(ic, { [ic:IsA("ImageLabel") and "ImageColor3" or "TextColor3"] = c }, 0.15)
	end
end

function Window:AddTab(a, b)
	local o = type(a) == "table" and a or { Title = a, Icon = b }
	local tab = setmetatable({ Title = o.Title or o.Name or "Tab", Icon = o.Icon, Badge = o.Badge, Views = {}, Win = self }, TabMT)
	InitPage(tab, self, tab.Title)
	tab.Owner = tab
	tab.Views[1] = tab
	tab.View = tab
	local btn = Box(self.SideList, { Size = UDim2.new(1, 0, 0, Touch and 38 or 32), LayoutOrder = self:_SideOrder() }, nil, 7)
	btn.BackgroundTransparency = 1
	tab.Btn = btn
	tab.Ind = Box(btn, { Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundTransparency = 1 }, "Accent", 2)
	tab.Ind.BackgroundTransparency = 1
	tab.IconObj = MakeIcon(btn, o.Icon or "box", 16, false)
	if tab.IconObj then
		tab.IconObj.AnchorPoint = Vector2.new(0.5, 0.5)
		tab.IconObj.Position = UDim2.new(0, 20, 0.5, 0)
		tab.IconObj.ZIndex = 2
	end
	tab.Label = Lbl(btn, { Text = tab.Title, Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(1, -44, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, TextSize = 13, Tr = true }, false)
	if o.Badge then
		local bh = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 0, 0, 16), AutomaticSize = AX }, btn)
		tab.BadgeObj = MakeBadge(bh, o.Badge, 1)
	end
	local hit = Hit(btn, 3)
	hit.MouseEnter:Connect(function()
		if self.Selected ~= tab then btn.BackgroundColor3 = Theme.Hover btn.BackgroundTransparency = 0.55 end
	end)
	hit.MouseLeave:Connect(function()
		if self.Selected ~= tab then btn.BackgroundTransparency = 1 end
	end)
	Tap(hit, function() tab:Select() end)
	MX:Tip(hit, function() return self.Collapsed and tab.Title or nil end)
	Watch(btn, function() tab:_Style() end)
	table.insert(self.Tabs, tab)
	local st = self._settingsTab
	if st and st ~= tab then
		for i, t in ipairs(self.Tabs) do
			if t == st then
				table.remove(self.Tabs, i)
				break
			end
		end
		table.insert(self.Tabs, st)
	end
	self:_ApplySide()
	tab:_Style()
	if self.Selected == nil and not o.NoAutoSelect then tab:Select() end
	return tab
end

function Window:SelectTab(i)
	local t = self.Tabs[i]
	if t then t:Select() end
end

function Window:_ShowTab(tab, view)
	local prev = self.Selected
	self.Selected = tab
	if view then tab.View = view end
	if prev and prev ~= tab then
		for _, v in ipairs(prev.Views) do v.Frame.Visible = false end
		prev:_Style()
	end
	for _, v in ipairs(tab.Views) do v.Frame.Visible = v == tab.View end
	tab:_Style()
	tab.View:Reflow()
	MX:CloseAllPopups()
end

function Window:_ApplySide()
	local col = self.Collapsed
	for _, t in ipairs(self.Tabs) do
		t.Label.Visible = not col
		if t.BadgeObj then t.BadgeObj.Parent.Visible = not col end
		if t.IconObj then t.IconObj.Position = col and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 20, 0.5, 0) end
	end
	for _, c in ipairs(self.Cats) do
		c.l.Visible = not col
		c.line.Visible = col
	end
	if self.ProfileName then self.ProfileName.Visible = not col end
	if self.ProfileArrow then self.ProfileArrow.Visible = not col end
	if self.ProfileAvatar then self.ProfileAvatar.Position = col and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 28, 0.5, 0) end
end

function Window:_SideW(w)
	return self.Collapsed and self.CollapsedWidth or math.min(self.TabWidth, math.floor(w * 0.3))
end

function Window:_Layout(instant)
	local w = self.W or self.BaseW
	local side = self:_SideW(w)
	self.SideW = side
	local info = TweenInfo.new(instant and 0 or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local hh = self.HH
	TweenService:Create(self.Sidebar, info, { Size = UDim2.new(0, side, 1, -hh) }):Play()
	TweenService:Create(self.Content, info, { Position = UDim2.new(0, side, 0, hh), Size = UDim2.new(1, -side, 1, -hh) }):Play()
	self:_ApplySide()
	if self.TitleLabel then self.TitleLabel.Visible = w >= 520 end
	if self.SearchWrap then self.SearchWrap.Size = UDim2.new(0, w >= 640 and self.SearchWidth or (w >= 480 and 110 or 76), 0, Touch and 30 or 26) end
end

function Window:_Clamp()
	local vp = self.VP
	if not vp then return end
	local s = MX.Scale
	local mx = math.max(0, (vp.X - self.W * s) / 2)
	local my = math.max(0, (vp.Y - self.H * s) / 2)
	local p = self.Main.Position
	self.Main.Position = UDim2.new(0.5, math.clamp(p.X.Offset, -mx, mx), 0.5, math.clamp(p.Y.Offset, -my, my))
end

function Window:_Fit()
	local vp = Gui.AbsoluteSize
	local cam = workspace.CurrentCamera
	if (vp.X < 80 or vp.Y < 80) and cam then vp = cam.ViewportSize end
	self.VP = vp
	local top = TopInset()
	local s = MX.UserScale
	if Touch then s = s * (vp.Y < 460 and 0.85 or 0.95) end
	MX:_ApplyScale(s)
	local maxW, maxH = (vp.X - 8) / s, (vp.Y - top - 6) / s
	local w = math.max(math.min(self.MinW, maxW), math.min(self.BaseW, maxW))
	local h = math.max(math.min(self.MinH, maxH), math.min(self.BaseH, maxH))
	self.W, self.H = w, h
	self.Main.Size = UDim2.fromOffset(w, h)
	if self.AutoCollapse and not self._userCollapsed then self.Collapsed = w < 520 end
	local cols = (w - self:_SideW(w)) >= 500 and 2 or 1
	if cols ~= self.Cols then
		self.Cols = cols
		for _, t in ipairs(self.Tabs) do
			for _, v in ipairs(t.Views) do v:Reflow() end
		end
	end
	self:_Layout(true)
	self:_Clamp()
end

function Window:SetScale(s, instant)
	self._scaleTarget = math.clamp(tonumber(s) or MX.UserScale, 0.5, 1.6)
	if instant or math.abs(MX.UserScale - self._scaleTarget) < 0.001 then
		if self._scaleConn then
			self._scaleConn:Disconnect()
			self._scaleConn = nil
		end
		MX.UserScale = self._scaleTarget
		self:_Fit()
		return
	end
	if self._scaleConn then return end
	self._scaleConn = RunService.Heartbeat:Connect(function(dt)
		if MX.Dead then
			self._scaleConn:Disconnect()
			self._scaleConn = nil
			return
		end
		local tgt = self._scaleTarget
		local nxt = MX.UserScale + (tgt - MX.UserScale) * math.min(1, dt * 7)
		if MX.Dead or math.abs(tgt - nxt) < 0.002 then nxt = tgt end
		MX.UserScale = nxt
		self:_Fit()
		if nxt == tgt and self._scaleConn then
			self._scaleConn:Disconnect()
			self._scaleConn = nil
		end
	end)
end
function Window:SetSidebar(v)
	self.Collapsed = v and true or false
	self._userCollapsed = true
	self:_Layout()
end
function Window:ToggleSidebar() self:SetSidebar(not self.Collapsed) end
function Window:IsSidebarCollapsed() return self.Collapsed end

function Window:Toggle(state)
	if state == nil then state = not self.Open end
	state = state and true or false
	if state == self.Open and (not state or self.Main.Visible) then return end
	self.Open = state
	self._tg = (self._tg or 0) + 1
	local id = self._tg
	pcall(function() MX:CloseAllPopups() end)
	Tip.Visible = false
	if state then
		self.Main.Visible = true
		self.ScaleObj.Scale = MX.Scale * 0.97
		Tween(self.ScaleObj, { Scale = MX.Scale }, 0.1)
	else
		Tween(self.ScaleObj, { Scale = MX.Scale * 0.97 }, 0.08)
		task.delay(0.1, function()
			if self._tg == id and not self.Open then self.Main.Visible = false end
		end)
	end
	self:_UpdateMobileBtn()
end
function Window:IsOpen() return self.Open end
function Window:Show() self:Toggle(true) end
function Window:Hide() self:Toggle(false) end
function Window:SetTitle(t) if self.TitleLabel then self.TitleLabel.Text = tostring(t) end end
function Window:SetSubTitle(t) if self.SubLabel then self.SubLabel.Text = tostring(t) end end
function Window:FocusSearch() if self.SearchBox then self.SearchBox:CaptureFocus() end end

function Window:Dialog(o)
	o = o or {}
	local dim = New("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = C3(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 60, BorderSizePixel = 0 }, self.Main)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, dim)
	Tween(dim, { BackgroundTransparency = 0.45 }, 0.15)
	local card = Box(dim, { Size = UDim2.new(0, math.min(340, (self.W or 400) - 40), 0, 0), AutomaticSize = AY, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 61 }, "Card", 10, "Border")
	Pad(card, 14, 14, 14, 14)
	List(card, 8)
	Lbl(card, { Text = tostring(o.Title or "Dialog"), Font = FONT.Bold, TextSize = 16, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1, Tr = true })
	Lbl(card, { Text = tostring(o.Content or ""), Font = FONT.Reg, TextSize = 13, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Tr = true }, "Sub")
	local br = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Touch and 38 or 32), LayoutOrder = 3 }, card)
	local btns = o.Buttons or { { Title = "OK", Primary = true } }
	List(br, 6, Enum.FillDirection.Horizontal)
	local closed = false
	local function close()
		closed = true
		Tween(dim, { BackgroundTransparency = 1 }, 0.12)
		task.delay(0.12, function() dim:Destroy() end)
	end
	for _, b in ipairs(btns) do
		local bb = Box(br, { Size = UDim2.new(1 / #btns, -6 * (#btns - 1) / #btns, 1, 0) }, b.Primary and "Accent" or "Element", 6)
		Lbl(bb, { Text = tostring(b.Title or b.Text or "OK"), Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextSize = 13, Tr = true }, b.Primary and "OnAccent" or "Text")
		local h = Hit(bb, 3)
		Tap(h, function()
			if closed then return end
			close()
			if b.Callback then MX._Run(b.Callback) end
		end)
	end
end
function MX:Dialog(o) if MX.Window then MX.Window:Dialog(o) end end

local function rnd(a, b) return a + math.random() * (b - a) end
local function fxFrame(layer, round)
	local f = New("Frame", { BorderSizePixel = 0, ZIndex = 1 }, layer)
	if round then New("UICorner", { CornerRadius = UDim.new(1, 0) }, f) end
	return f
end

local FXDefs = {}
FXDefs.Snow = {
	count = 30,
	make = function(layer) return { f = fxFrame(layer, true) } end,
	reset = function(p, w, h, init)
		local sz = rnd(3, 6)
		p.f.Size = UDim2.fromOffset(sz, sz)
		p.f.BackgroundColor3 = Theme.Text
		p.f.BackgroundTransparency = rnd(0.45, 0.8)
		p.x, p.y = rnd(0, w), init and rnd(0, h) or -8
		p.vy, p.vx, p.ph, p.t = rnd(22, 55), rnd(-8, 8), rnd(0, 6.28), 0
	end,
	step = function(p, dt, w, h)
		p.t += dt
		p.y += p.vy * dt
		p.x += (p.vx + math.sin(p.t * 1.3 + p.ph) * 14) * dt
		if p.y > h + 8 or p.x < -10 or p.x > w + 10 then FXDefs.Snow.reset(p, w, h, false) end
		p.f.Position = UDim2.fromOffset(p.x, p.y)
	end,
}
FXDefs.Rain = {
	count = 36,
	make = function(layer)
		local f = fxFrame(layer, false)
		f.Rotation = 12
		return { f = f }
	end,
	reset = function(p, w, h, init)
		p.f.Size = UDim2.fromOffset(1.5, rnd(10, 18))
		p.f.BackgroundColor3 = Theme.Sub
		p.f.BackgroundTransparency = rnd(0.5, 0.75)
		p.x, p.y = rnd(-20, w), init and rnd(0, h) or rnd(-40, -8)
		p.vy = rnd(380, 560)
	end,
	step = function(p, dt, w, h)
		p.y += p.vy * dt
		p.x += p.vy * 0.21 * dt
		if p.y > h + 10 or p.x > w + 20 then FXDefs.Rain.reset(p, w, h, false) end
		p.f.Position = UDim2.fromOffset(p.x, p.y)
	end,
}
local EMBER = { C3(255, 190, 70), C3(255, 130, 40), C3(255, 80, 30) }
FXDefs.Fire = {
	count = 34,
	make = function(layer) return { f = fxFrame(layer, true) } end,
	reset = function(p, w, h, init)
		p.base = rnd(2, 5)
		p.col = EMBER[math.random(1, #EMBER)]
		p.x, p.y = rnd(0, w), init and rnd(0, h) or h + 6
		p.vy, p.vx, p.ph = -rnd(35, 95), rnd(-14, 14), rnd(0, 6.28)
		p.life = rnd(1.6, 3.2)
		p.age = init and rnd(0, p.life) or 0
	end,
	step = function(p, dt, w, h)
		p.age += dt
		p.y += p.vy * dt
		p.x += (p.vx + math.sin(p.age * 5 + p.ph) * 10) * dt
		local k = p.age / p.life
		if k >= 1 or p.y < -8 then FXDefs.Fire.reset(p, w, h, false) k = 0 end
		local sz = math.max(1, p.base * (1 - k * 0.6))
		p.f.Size = UDim2.fromOffset(sz, sz)
		p.f.BackgroundColor3 = p.col
		p.f.BackgroundTransparency = 0.3 + 0.7 * k
		p.f.Position = UDim2.fromOffset(p.x, p.y)
	end,
}
local PETAL = { C3(255, 160, 190), C3(255, 200, 215), C3(255, 235, 240) }
FXDefs.Petals = {
	count = 22,
	make = function(layer) return { f = fxFrame(layer, true) } end,
	reset = function(p, w, h, init)
		p.f.Size = UDim2.fromOffset(rnd(6, 9), rnd(4, 6))
		p.f.BackgroundColor3 = PETAL[math.random(1, #PETAL)]
		p.f.BackgroundTransparency = rnd(0.3, 0.6)
		p.x, p.y = rnd(0, w), init and rnd(0, h) or -8
		p.vy, p.vx, p.ph, p.t = rnd(25, 55), rnd(8, 26), rnd(0, 6.28), 0
		p.rot, p.rv = rnd(0, 360), rnd(-120, 120)
	end,
	step = function(p, dt, w, h)
		p.t += dt
		p.y += p.vy * dt
		p.x += (p.vx + math.sin(p.t * 1.6 + p.ph) * 16) * dt
		p.rot += p.rv * dt
		if p.y > h + 10 or p.x > w + 14 then FXDefs.Petals.reset(p, w, h, false) end
		p.f.Rotation = p.rot
		p.f.Position = UDim2.fromOffset(p.x, p.y)
	end,
}
FXDefs.Stars = {
	count = 3,
	make = function(layer)
		local f = fxFrame(layer, false)
		f.Rotation = 25
		f.Visible = false
		New("UIGradient", { Transparency = NumberSequence.new(1, 0) }, f)
		return { f = f }
	end,
	reset = function(p, w, h, init)
		p.active = false
		p.f.Visible = false
		p.wait = init and rnd(0, 3) or rnd(1.5, 4)
	end,
	step = function(p, dt, w, h)
		if not p.active then
			p.wait -= dt
			if p.wait <= 0 then
				p.active = true
				p.age, p.life = 0, rnd(0.8, 1.3)
				p.x, p.y = rnd(0, w * 0.8), rnd(-10, h * 0.4)
				p.vx = rnd(240, 320)
				p.f.Size = UDim2.fromOffset(rnd(50, 80), 2)
				p.f.BackgroundColor3 = Theme.Accent
				p.f.Visible = true
			end
			return
		end
		p.age += dt
		p.x += p.vx * dt
		p.y += p.vx * 0.466 * dt
		p.f.BackgroundTransparency = 0.2 + 0.8 * (p.age / p.life)
		p.f.Position = UDim2.fromOffset(p.x, p.y)
		if p.age >= p.life then FXDefs.Stars.reset(p, w, h, false) end
	end,
}
MX.EffectList = { "None", "Stars", "Snow", "Rain", "Fire", "Petals" }

function Window:_FXStop()
	if self.FXConn then
		self.FXConn:Disconnect()
		self.FXConn = nil
	end
	if self.FXParts then
		for _, p in ipairs(self.FXParts) do p.f:Destroy() end
		self.FXParts = nil
	end
end

function Window:SetEffect(name)
	if name == nil or name == false or name == "Off" then name = "None" end
	self:_FXStop()
	self.Effect = name
	local def = FXDefs[name]
	if not def then
		self.FX.Visible = false
		if MX.Options.effect and MX.Options.effect.Value ~= "None" then MX.Options.effect:Set("None", true) end
		return
	end
	self.FX.Visible = true
	local sz = self.FX.AbsoluteSize / MX.Scale
	local w, h = math.max(sz.X, 200), math.max(sz.Y, 200)
	local n = math.max(1, math.floor(def.count * (Touch and 0.6 or 1) * (self.FXScale or 1) + 0.5))
	self.FXParts = {}
	for i = 1, n do
		local p = def.make(self.FX)
		def.reset(p, w, h, true)
		self.FXParts[i] = p
	end
	local slow = 0
	self.FXConn = RunService.Heartbeat:Connect(function(dt)
		if MX.Dead or not self.Open or not self.Main.Visible or not self.FXParts then
			slow = 0
			return
		end
		if MX.AutoPerformance ~= false then
			if dt > 0.04 then slow += dt else slow = math.max(0, slow - dt * 2) end
			if slow > 2.5 and (self.FXScale or 1) > 0.35 then
				slow = 0
				self.FXScale = math.max(0.35, (self.FXScale or 1) * 0.5)
				task.defer(function()
					if MX.Dead then return end
					self:SetEffect(self.Effect)
					if not MX._perfNote then
						MX._perfNote = true
						MX:Info("Performance", "Effects were reduced to keep the UI smooth.", 3)
					end
				end)
				return
			end
		end
		dt = math.min(dt, 0.05)
		local s = self.FX.AbsoluteSize / MX.Scale
		for _, p in ipairs(self.FXParts) do def.step(p, dt, s.X, s.Y) end
	end)
	if MX.Options.effect and MX.Options.effect.Value ~= name then MX.Options.effect:Set(name, true) end
end
function Window:GetEffect() return self.Effect or "None" end
function Window:_Goto(e)
	local c = e.cont
	if c.Owner then c.Owner:Select() end
	RevealChain(c)
	task.spawn(function()
		task.wait()
		task.wait()
		local page = c.Owner and c.Owner.Frame
		if page and e.row.Parent then
			local y = e.row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 30
			page.CanvasPosition = Vector2.new(0, math.max(0, y))
		end
		if e.row:IsA("Frame") and e.row.BackgroundTransparency < 1 then
			Tween(e.row, { BackgroundColor3 = Theme.Accent }, 0.15)
			task.delay(0.6, function()
				if e.row.Parent then Tween(e.row, { BackgroundColor3 = Theme.Element }, 0.3) end
			end)
		end
	end)
end

local function PaletteButton(parent, icon, order, size, tok)
	local b = Box(parent, { Size = UDim2.fromOffset(size, size), LayoutOrder = order }, "Element", 6)
	local ic = MakeIcon(b, icon, 16, tok == nil and "Sub" or tok)
	ic.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.Position = UDim2.fromScale(0.5, 0.5)
	local h = Hit(b, 3)
	Hover(h, b, "Element", "Hover")
	return b, h, ic
end

MX.Locked = false
MX.LockListeners = {}
function MX:SetLocked(v)
	MX.Locked = v and true or false
	for _, f in ipairs(MX.LockListeners) do pcall(f, MX.Locked) end
	local o = MX.Options.ui_locked
	if o and o.Value ~= MX.Locked then o:Set(MX.Locked, true) end
end
function MX:GetLocked() return MX.Locked end

function Window:OpenProfile()
	if not self.Profile then return end
	self.Profile.refresh()
	MX:ShowPopup(self.Profile.frame, self.ProfileCard, { Placement = "RightBottom" })
end

function Window:_BuildProfile()
	local win = self
	if not win.ProfileCard then return end
	local f = NewPopupFrame(250, nil)
	Pad(f, 8, 8, 8, 8)
	List(f, 3)
	local values = {}
	local function refresh()
		for _, e in ipairs(values) do e[1].Text = e[2]() end
		if win.ProfileAvatar and win.Profile and win.Profile.avatar then win.Profile.avatar.Image = win.ProfileAvatar.Image end
	end
	local hd = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 1 }, f)
	local av = New("ImageLabel", { Size = UDim2.fromOffset(34, 34), Position = UDim2.new(0, 6, 0.5, -17), BackgroundTransparency = 0, BorderSizePixel = 0, Image = win.ProfileAvatar and win.ProfileAvatar.Image or "" }, hd)
	Bind(av, { BackgroundColor3 = "Element" })
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
	Lbl(hd, { Text = LocalPlayer.DisplayName, Position = UDim2.new(0, 50, 0, 6), Size = UDim2.new(1, -56, 0, 18), TextSize = 14, Font = FONT.Bold, TextTruncate = Enum.TextTruncate.AtEnd })
	Lbl(hd, { Text = "@" .. LocalPlayer.Name, Position = UDim2.new(0, 50, 0, 24), Size = UDim2.new(1, -56, 0, 14), TextSize = 11, Font = FONT.Reg, TextTruncate = Enum.TextTruncate.AtEnd }, "Sub")
	Box(f, { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 2, BackgroundTransparency = 0.5 }, "Border")
	local order = 2
	local function prow(icon, key, valueFn, onTap, red)
		order += 1
		local r = New("Frame", { Size = UDim2.new(1, 0, 0, Touch and 38 or 34), LayoutOrder = order, BackgroundTransparency = 1, BorderSizePixel = 0 }, f)
		New("UICorner", { CornerRadius = UDim.new(0, 7) }, r)
		local ic = MakeIcon(r, icon, 16, red and "Danger" or "Sub")
		ic.AnchorPoint = Vector2.new(0, 0.5)
		ic.Position = UDim2.new(0, 10, 0.5, 0)
		Lbl(r, { Text = key, Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(0.5, -36, 1, 0), TextSize = 13, Tr = true }, red and "Danger" or "Text")
		if valueFn then
			local v = Lbl(r, { Text = valueFn(), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 0, 0), Size = UDim2.new(0.5, -30, 1, 0), TextXAlignment = RIGHT, TextSize = 12, Font = FONT.Reg, TextTruncate = Enum.TextTruncate.AtEnd }, "Sub")
			values[#values + 1] = { v, valueFn }
			local ch = MakeIcon(r, "chevron-right", 12, "Sub")
			ch.AnchorPoint = Vector2.new(1, 0.5)
			ch.Position = UDim2.new(1, -10, 0.5, 0)
		end
		local h = Hit(r, 3)
		h.MouseEnter:Connect(function()
			r.BackgroundColor3 = Theme.Hover
			r.BackgroundTransparency = 0.5
		end)
		h.MouseLeave:Connect(function() r.BackgroundTransparency = 1 end)
		Tap(h, function() onTap(r) end)
		return r
	end

	local function openNew(anchor)
		ListPopup(anchor, {
			Title = "New Language", Values = MX:AvailableLanguages(), Search = true, Width = 210, Placement = "Right",
			IsSel = function() return false end,
			OnPick = function(v)
				MX:AddLanguage(v)
				MX:SetLanguage(v)
				MX:Notify({ Type = "Success", Title = "Language added", Content = v, Duration = 2 })
				MX:ClosePopup()
			end,
		})
	end
	local function openLanguage(r)
		local lf
		lf = ListPopup(r, {
			Values = MX.Lang.List, Search = true, Width = 200, Placement = "Right",
			IsSel = function(v) return v == MX.Lang.Current end,
			OnPick = function(v) MX:SetLanguage(v) end,
			Footer = { Text = "Create Language", Icon = "plus", OnTap = function() openNew(lf) end },
		})
	end
	local function allThemes()
		local out = {}
		for _, n in ipairs(MX.ThemeOrder) do out[#out + 1] = n end
		for _, n in ipairs(MX:GetCustomThemes()) do out[#out + 1] = n end
		return out
	end
	local keyRow
	prow("globe", "Language", function() return MX.Lang.Current end, openLanguage)
	prow("palette", "Theme", function() return MX.ThemeName end, function(r)
		ListPopup(r, {
			Values = allThemes(), Search = true, Width = 200, Placement = "Right",
			IsSel = function(v) return v == MX.ThemeName end,
			OnPick = function(v) MX:SetTheme(v) end,
		})
	end)
	keyRow = prow("keyboard", "Menu Key", function() return "[" .. KeyLabel(MX.MenuKeyCode) .. "]" end, function()
		if MX.Listening then return end
		for _, e in ipairs(values) do
			if e[2] and e[3] == "key" then e[1].Text = "[...]" end
		end
		MX:Listen(function(r)
			if r == false then refresh() return end
			if r == nil or r.EnumType == Enum.KeyCode then MX:SetMenuKey(r) end
			refresh()
		end)
	end)
	values[#values][3] = "key"
	if not UIS.KeyboardEnabled then keyRow.Visible = false end
	order += 1
	Box(f, { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = order, BackgroundTransparency = 0.5 }, "Border")
	prow("power", "Unload", nil, function()
		MX:CloseAllPopups()
		win:Dialog({ Title = "Unload Script?", Content = "The UI closes completely. Run the script again to bring it back.", Buttons = { { Title = "Unload", Primary = true, Callback = function() MX:Destroy() end }, { Title = "Stay" } } })
	end, true)

	MX.Options.menu_key = {
		Get = function() return MX.MenuKeyCode end,
		Serialize = function() return KeyEncode(MX.MenuKeyCode) end,
		Deserialize = function(_, v)
			local k = KeyDecode(v)
			MX:SetMenuKey(k)
			refresh()
		end,
	}
	table.insert(MX.Lang.Listeners, refresh)
	Watch(f, refresh)
	win.Profile = { frame = f, refresh = refresh, avatar = av }
end

local function RoundBox(frame, tok, a, side)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, frame)
	local top = Box(frame, { Size = UDim2.new(1, 0, 0, 14), ZIndex = 0 }, tok)
	GlassOn(top, a)
	local edge
	if side == "left" then
		edge = Box(frame, { Size = UDim2.new(0, 14, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), ZIndex = 0 }, tok)
	else
		edge = Box(frame, { Size = UDim2.new(0, 14, 1, 0), ZIndex = 0 }, tok)
	end
	GlassOn(edge, a)
end

function MX:CreateWindow(o)
	o = o or {}
	if o.TextScale then MX.TextScale = o.TextScale end
	local win = setmetatable({ Tabs = {}, Pages = {}, Index = {}, Cats = {}, Open = true, Cols = 2, ClosedByUser = false }, WindowMT)
	table.insert(MX.Windows, win)
	MX.Window = win
	win.BaseW = (o.Size and o.Size.X) or 720
	win.BaseH = (o.Size and o.Size.Y) or 460
	win.MinW = (o.MinSize and o.MinSize.X) or 300
	win.MinH = (o.MinSize and o.MinSize.Y) or 240
	win.TabWidth = o.TabWidth or 170
	win.CollapsedWidth = o.CollapsedWidth or 56
	win.Collapsed = o.Collapsed or false
	win.AutoCollapse = o.Collapsed == nil
	win.SearchWidth = o.SearchWidth or 160
	win.TitleText = o.Title or "MX HUB"
	win.HH = Touch and 42 or 38
	if o.Theme and MX.Themes[o.Theme] then MX:SetTheme(o.Theme, true) end
	if o.Glass then MX:SetGlass(true) end
	if o.ToggleKeys then MX:_SetMenuKeys(o.ToggleKeys) elseif o.ToggleKey then MX:_SetMenuKeys({ Enum.KeyCode.Insert, o.ToggleKey }) end

	local main = Box(WinLayer, { Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, TopInset() / 2), Size = UDim2.fromOffset(win.BaseW, win.BaseH), ClipsDescendants = true }, "Window", 10, "Border")
	GlassOn(main, 0.15)
	win.Main = main
	win.ScaleObj = Scaled(main)
	local HH = win.HH

	local header = Box(main, { Size = UDim2.new(1, 0, 0, HH), ZIndex = 3 }, "Panel", 10)
	GlassOn(header, 0.2)
	local hfill = Box(header, { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12) }, "Panel")
	GlassOn(hfill, 0.2)
	local hline = Box(header, { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1) }, "Border")
	hline.BackgroundTransparency = 0.5
	local hl = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, Position = UDim2.new(0, 8, 0, 0), ZIndex = 4 }, header)
	List(hl, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	local bsz = Touch and 32 or 28
	if o.Collapsible ~= false then
		local cb, ch = PaletteButton(hl, "menu", 1, bsz)
		Tap(ch, function() win:ToggleSidebar() end)
	end
	local logo = MXLogo(hl, 24)
	logo.LayoutOrder = 2
	win.TitleLabel = Lbl(hl, { Text = tostring(o.Title or "MX HUB"), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, Font = FONT.Bold, TextSize = 15, LayoutOrder = 3 })
	local hr = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, ZIndex = 4 }, header)
	List(hr, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

	if o.Search ~= false then
		local sw = Box(hr, { Size = UDim2.new(0, win.SearchWidth, 0, Touch and 32 or 28), LayoutOrder = 1 }, "Element", 6)
		win.SearchWrap = sw
		local sb = New("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 8, 0, 0), Text = "", PlaceholderText = "Search...", ClearTextOnFocus = false, Font = FONT.Reg, TextSize = TS(13), TextXAlignment = LEFT }, sw)
		Bind(sb, { TextColor3 = "Text", PlaceholderColor3 = "Sub" })
		win.SearchBox = sb
		Tr(sb, "Search...", "PlaceholderText")
		local res = Box(main, { Size = UDim2.new(0, 280, 0, 0), AutomaticSize = AY, Visible = false, ZIndex = 30, Active = true }, "Card", 8, "Border")
		Pad(res, 4, 4, 4, 4)
		List(res, 2)
		local function refresh()
			for _, c in ipairs(res:GetChildren()) do
				if c:IsA("GuiObject") then c:Destroy() end
			end
			local q = sb.Text:lower()
			if q == "" then res.Visible = false return end
			local n = 0
			for _, e in ipairs(win.Index) do
				if e.row.Parent and tostring(e.title):lower():find(q, 1, true) then
					n += 1
					if n > 8 then break end
					local it = Box(res, { Size = UDim2.new(1, 0, 0, 36), LayoutOrder = n }, nil, 5)
					it.BackgroundTransparency = 1
					Lbl(it, { Text = tostring(e.title), Position = UDim2.new(0, 8, 0, 2), Size = UDim2.new(1, -16, 0, 17), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd })
					local path = (e.cont.Owner and e.cont.Owner.Title or "") .. (e.cont.SecTitle and e.cont.SecTitle ~= "" and (" > " .. e.cont.SecTitle) or "")
					Lbl(it, { Text = path, Position = UDim2.new(0, 8, 0, 19), Size = UDim2.new(1, -16, 0, 14), TextSize = 11, Font = FONT.Reg, TextTruncate = Enum.TextTruncate.AtEnd }, "Sub")
					local h = Hit(it, 3)
					h.MouseEnter:Connect(function() it.BackgroundColor3 = Theme.Hover it.BackgroundTransparency = 0.3 end)
					h.MouseLeave:Connect(function() it.BackgroundTransparency = 1 end)
					Tap(h, function()
						res.Visible = false
						sb.Text = ""
						win:_Goto(e)
					end)
				end
			end
			if n == 0 then
				Lbl(res, { Text = "No results", Size = UDim2.new(1, 0, 0, 30), TextXAlignment = CENTER, TextSize = 13 }, "Sub")
			end
			local ap = sw.AbsolutePosition - main.AbsolutePosition
			local s = MX.Scale
			res.Position = UDim2.fromOffset(math.max(6, math.min(ap.X / s + sw.AbsoluteSize.X / s - 280, win.W - 286)), (ap.Y + sw.AbsoluteSize.Y) / s + 6)
			res.Visible = true
		end
		sb:GetPropertyChangedSignal("Text"):Connect(refresh)
		sb.FocusLost:Connect(function() task.delay(0.6, function() if not sb:IsFocused() then res.Visible = false end end) end)
		sb.Focused:Connect(refresh)
		Conn(UIS.InputBegan, function(i)
			if i.KeyCode == Enum.KeyCode.Slash and not UIS:GetFocusedTextBox() and win.Open then
				task.defer(function()
					sb:CaptureFocus()
					task.wait()
					if sb.Text:sub(-1) == "/" then sb.Text = sb.Text:sub(1, -2) end
				end)
			end
		end)
	end

	win:_BuildChangelogButton(hr, bsz)
	local lb, lh, lic = PaletteButton(hr, "unlock", 3, bsz, false)
	local function paintLock()
		local id = MX:GetIcon(MX.Locked and "lock" or "unlock")
		if lic:IsA("ImageLabel") then
			if id then lic.Image = id end
			lic.ImageColor3 = MX.Locked and Theme.Accent or Theme.Sub
		else
			lic.TextColor3 = MX.Locked and Theme.Accent or Theme.Sub
		end
	end
	paintLock()
	table.insert(MX.LockListeners, paintLock)
	Watch(lb, paintLock)
	MX:Tip(lh, function() return MX.Locked and "Unlock UI" or "Lock UI" end)
	Tap(lh, function()
		MX:SetLocked(not MX.Locked)
	end)
	local gb, gh = PaletteButton(hr, "settings", 4, bsz)
	local gearMenu, gearFrame = MakeMenu("Quick Settings", 240)
	local gr = {}
	win.Gear = gr
	gr.glass = gearMenu:AddToggle({ Title = "Glass", Flag = "glass", Style = "Switch", Callback = function(v) MX:SetGlass(v) end })
	gr.wm = gearMenu:AddToggle({ Title = "Watermark", Flag = "watermark", Style = "Switch", Default = o.Watermark ~= false, Callback = function(v)
		if v then MX:EnsureWatermark(win.TitleText) end
		if MX.Watermark then MX.Watermark:SetVisible(v) end
	end })
	gr.kl = gearMenu:AddToggle({ Title = "Keybind List", Flag = "keybind_list", Style = "Switch", Callback = function(v)
		if v then MX:EnsureKeyList() end
		if MX.KeyList then MX.KeyList:SetVisible(v) end
	end })
	gr.mob = gearMenu:AddToggle({ Title = "Mobile Button", Flag = "mobile_button", Style = "Switch", Callback = function(v) win:SetMobileButton(v) end })
	gr.lock = gearMenu:AddToggle({ Title = "Lock UI", Flag = "ui_locked", Style = "Switch", Callback = function(v) MX:SetLocked(v) end })
	gr.notif = gearMenu:AddToggle({ Title = "Hide Notifications", Flag = "hide_notifications", Style = "Switch", Callback = function(v) MX:SetNotificationsHidden(v) end })
	Tap(gh, function()
		gr.glass:Set(MX.Glass, true)
		gr.wm:Set(MX.Watermark ~= nil and MX.Watermark.Visible or false, true)
		gr.kl:Set(MX.KeyList ~= nil and MX.KeyList.Visible or false, true)
		gr.mob:Set(win.MobileBtn ~= nil, true)
		gr.lock:Set(MX.Locked, true)
		gr.notif:Set(MX.NotifyEnabled == false, true)
		ShowMenu(gearMenu, gearFrame, gb)
	end)
	local mb, mh = PaletteButton(hr, "minus", 5, bsz)
	Tap(mh, function() win:Toggle(false) end)
	local xb, xh = PaletteButton(hr, "x", 6, bsz)
	Tap(xh, function()
		win:Dialog({ Title = "Unload MX?", Content = "The UI closes completely. Run the script again to bring it back.", Buttons = { { Title = "Unload", Primary = true, Callback = function() MX:Destroy() end }, { Title = "Stay" } } })
	end)

	local startPos
	Drag(header, {
		Begin = function()
			if MX.Locked then return false end
			startPos = main.Position
		end,
		Move = function(pos, origin)
			local d = pos - origin
			local vp, s = win.VP or Gui.AbsoluteSize, MX.Scale
			local mx = math.max(0, (vp.X - win.W * s) / 2)
			local my = math.max(0, (vp.Y - win.H * s) / 2)
			main.Position = UDim2.new(0.5, math.clamp(startPos.X.Offset + d.X, -mx, mx), 0.5, math.clamp(startPos.Y.Offset + d.Y, -my, my))
		end,
	})

	local sidebar = Box(main, { Position = UDim2.new(0, 0, 0, HH), Size = UDim2.new(0, win.TabWidth, 1, -HH), ClipsDescendants = true }, "Side")
	GlassOn(sidebar, 0.3)
	RoundBox(sidebar, "Side", 0.3, "left")
	Box(sidebar, { Size = UDim2.new(0, 1, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), BackgroundTransparency = 0.5, ZIndex = 2 }, "Border")
	win.Sidebar = sidebar
	local profileH = o.Profile ~= false and 52 or 0
	local sl = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -profileH), CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y }, sidebar)
	List(sl, 2)
	Pad(sl, 8, 6, 8, 6)
	win.SideList = sl
	table.insert(win.Pages, sl)
	if profileH > 0 then
		local pf = Box(sidebar, { Size = UDim2.new(1, 0, 0, profileH), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0) }, "Panel")
		GlassOn(pf, 0.4)
		Box(pf, { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 0.5 }, "Border")
		local av = New("ImageLabel", { Size = UDim2.fromOffset(32, 32), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 28, 0.5, 0), BackgroundTransparency = 0, BorderSizePixel = 0, Image = "" }, pf)
		Bind(av, { BackgroundColor3 = "Element" })
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
		task.spawn(function()
			local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
			if ok and av.Parent then
				av.Image = img
				if win.Profile and win.Profile.avatar then win.Profile.avatar.Image = img end
			end
		end)
		local nf = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 52, 0, 0), Size = UDim2.new(1, -84, 1, 0) }, pf)
		List(nf, 0, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
		Lbl(nf, { Text = LocalPlayer.DisplayName, Size = UDim2.new(1, 0, 0, 16), TextSize = 13, Font = FONT.Bold, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1 })
		Lbl(nf, { Text = "@" .. LocalPlayer.Name, Size = UDim2.new(1, 0, 0, 14), TextSize = 11, Font = FONT.Reg, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 2 }, "Sub")
		local arrow = MakeIcon(pf, "chevron-right", 14, "Sub")
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -12, 0.5, 0)
		local ph = Hit(pf, 4)
		Hover(ph, pf, "Panel", "Hover")
		Tap(ph, function() win:OpenProfile() end)
		win.ProfileName, win.ProfileAvatar, win.ProfileArrow, win.ProfileCard = nf, av, arrow, pf
	end

	local content = Box(main, { Position = UDim2.new(0, win.TabWidth, 0, HH), Size = UDim2.new(1, -win.TabWidth, 1, -HH), ClipsDescendants = true }, "Panel")
	GlassOn(content, 0.25)
	RoundBox(content, "Panel", 0.25, "right")
	win.Content = content
	local fx = New("Frame", { Name = "FX", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, ZIndex = 3, Visible = false }, content)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, fx)
	win.FX = fx
	win.PageHost = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, content)

	if o.Resizable ~= false then
		local grip = New("TextButton", { Text = "◢", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(Touch and 28 or 20, Touch and 28 or 20), AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Font = FONT.Bold, TextSize = 11, ZIndex = 5 }, main)
		Bind(grip, { TextColor3 = "Sub" })
		local sw0, sh0
		Drag(grip, {
			Begin = function()
				if MX.Locked then return false end
				win.BaseW, win.BaseH = win.W, win.H
				sw0, sh0 = win.W, win.H
			end,
			Move = function(pos, origin)
				local d = (pos - origin) / MX.Scale
				win.BaseW = math.max(win.MinW, sw0 + d.X)
				win.BaseH = math.max(win.MinH, sh0 + d.Y)
				win:_Fit()
			end,
		})
	end

	Conn(Gui:GetPropertyChangedSignal("AbsoluteSize"), function() win:_Fit() end)
	local cam = workspace.CurrentCamera
	if cam then Conn(cam:GetPropertyChangedSignal("ViewportSize"), function() win:_Fit() end) end
	win:_Fit()
	task.spawn(function()
		for _ = 1, 8 do
			RunService.RenderStepped:Wait()
			if MX.Dead or not win.Main.Parent then return end
			win:_Fit()
		end
	end)
	win:SetEffect(o.Effect or (o.Stars and "Stars") or "None")
	MX.Options.window_geometry = {
		Type = "Window",
		Serialize = function()
			local p = main.Position
			return { x = math.floor(p.X.Offset + 0.5), y = math.floor(p.Y.Offset + 0.5), w = math.floor(win.BaseW + 0.5), h = math.floor(win.BaseH + 0.5) }
		end,
		Deserialize = function(_, v)
			if type(v) ~= "table" then return end
			if tonumber(v.w) and tonumber(v.h) then
				win.BaseW = math.max(win.MinW, tonumber(v.w))
				win.BaseH = math.max(win.MinH, tonumber(v.h))
			end
			if tonumber(v.x) and tonumber(v.y) then main.Position = UDim2.new(0.5, tonumber(v.x), 0.5, tonumber(v.y)) end
			win:_Fit()
		end,
	}

	local mbOpt = o.MobileButton
	if mbOpt == nil then mbOpt = "Auto" end
	if mbOpt == true or type(mbOpt) == "table" or (mbOpt == "Auto" and Touch) then
		win:SetMobileButton(true, type(mbOpt) == "table" and mbOpt or nil)
	end
	if o.Watermark ~= false and not MX.Watermark then MX:EnsureWatermark(win.TitleText) end
	if o.KeybindList ~= false and not MX.KeyList then MX:EnsureKeyList() end
	if o.Home ~= false then win:_BuildHome(type(o.Home) == "table" and o.Home or nil) end
	if o.Settings ~= false then win:AddSettingsTab(type(o.Settings) == "table" and o.Settings or nil) end
	if not win.Selected and win.Tabs[1] then win.Tabs[1]:Select() end
	win:_BuildProfile()
	win:_ApplySide()
	return win
end

function Window:_UpdateMobileBtn()
	local b = self.MobileBtn
	if b then b.Visible = (self.MobileOpts == nil or self.MobileOpts.HideWhenOpen ~= true) or not self.Open end
end

function Window:SetMobileButton(on, opts)
	if self.MobileBtn then
		self.MobileBtn:Destroy()
		self.MobileBtn = nil
	end
	if self._mbConns then
		for _, c in ipairs(self._mbConns) do c:Disconnect() end
		self._mbConns = nil
	end
	if not on then return end
	opts = opts or self.MobileOpts or {}
	self.MobileOpts = opts
	local size = opts.Size or 46
	local btn = New("Frame", {
		Name = "MXToggle", Size = UDim2.fromOffset(size, size), BorderSizePixel = 0, ZIndex = 70,
		Position = opts.Position or UDim2.new(0, 20, 0, 100),
	}, Gui)
	Bind(btn, { BackgroundColor3 = "Card" })
	New("UICorner", { CornerRadius = UDim.new(0, 12) }, btn)
	local st = New("UIStroke", { Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, btn)
	Bind(st, { Color = "Accent" })
	local logo = MXLogo(btn, math.floor(size * 0.66))
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.Position = UDim2.fromScale(0.5, 0.5)
	local hit = Hit(btn, 5)
	self.MobileBtn = btn
	local dragging, moved, dragstart, startpos, draginput = false, false, nil, nil, nil
	local function clampButton()
		local bounds = Gui.AbsoluteSize
		if bounds.X <= 0 or bounds.Y <= 0 then return end
		local p = btn.Position
		local x = math.clamp(p.X.Scale * bounds.X + p.X.Offset, 0, math.max(0, bounds.X - size))
		local y = math.clamp(p.Y.Scale * bounds.Y + p.Y.Offset, 0, math.max(0, bounds.Y - size))
		btn.Position = UDim2.fromOffset(x, y)
	end
	self._mbConns = {
		Conn(Gui:GetPropertyChangedSignal("AbsoluteSize"), clampButton),
		Conn(UIS.InputChanged, function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or (input.UserInputType == Enum.UserInputType.Touch and input == draginput) then
				local delta = input.Position - dragstart
				if not moved and delta.Magnitude < 14 then return end
				moved = true
				btn.Position = UDim2.new(startpos.X.Scale, startpos.X.Offset + delta.X, startpos.Y.Scale, startpos.Y.Offset + delta.Y)
				clampButton()
			end
		end),
		Conn(UIS.InputEnded, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == draginput) then dragging = false end
		end),
	}
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			moved = false
			if MX.Locked or opts.Draggable == false then return end
			dragging = true
			dragstart = input.Position
			startpos = btn.Position
			draginput = input
		end
	end)
	Tap(hit, function()
		if moved then return end
		self:Toggle()
	end)
	task.defer(clampButton)
	self:_UpdateMobileBtn()
end

function MX:Destroy()
	if MX.Dead then return end
	if MX.AutoSave and MX.LoadedConfig then pcall(function() MX:SaveConfig(MX.LoadedConfig) end) end
	MX.Dead = true
	for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
	if MX._notify and type(MX._notify.Destroy) == "function" then pcall(MX._notify.Destroy, MX._notify) end
	if Gui then Gui:Destroy() end
	if genv.MXUI == MX then genv.MXUI = nil end
end

function MX:_KeyListRefresh()
	if MX.KeyList then MX.KeyList:Refresh() end
end

local Corners = {
	TopRight = { Vector2.new(1, 0), 1, 0, -1, 1 }, TopLeft = { Vector2.new(0, 0), 0, 0, 1, 1 },
	BottomRight = { Vector2.new(1, 1), 1, 1, -1, -1 }, BottomLeft = { Vector2.new(0, 1), 0, 1, 1, -1 },
}
local function Place(frame, corner, margin)
	local c = Corners[corner] or Corners.TopRight
	frame.AnchorPoint = c[1]
	frame.Position = UDim2.new(c[2], c[4] * margin, c[3], c[5] * margin)
end

function MX:_Clamp(frame, pos)
	pos = pos or frame.Position
	local layer = frame.Parent
	if not layer then return pos end
	local ls, fs, ap = layer.AbsoluteSize, frame.AbsoluteSize, frame.AnchorPoint
	local function axis(scale, offset, size, anchor, total)
		local lo = anchor * size - scale * total
		local hi = total - size + anchor * size - scale * total
		return math.clamp(offset, lo, math.max(lo, hi))
	end
	return UDim2.new(pos.X.Scale, axis(pos.X.Scale, pos.X.Offset, fs.X, ap.X, ls.X), pos.Y.Scale, axis(pos.Y.Scale, pos.Y.Offset, fs.Y, ap.Y, ls.Y))
end

function MX:CreateWatermark(o)
	o = o or {}
	if MX.Watermark then MX.Watermark:Destroy() end
	local wm = { Visible = o.Visible ~= false, Items = {} }
	local frame = Box(FloatLayer, { Size = UDim2.new(0, 0, 0, 28), AutomaticSize = AX, Visible = wm.Visible }, "Card", 7, "Border")
	GlassOn(frame, 0.2)
	Scaled(frame)
	Place(frame, o.Position or "TopRight", o.Margin or 10)
	Pad(frame, 0, 10, 0, 6)
	List(frame, 10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	local logo = MXLogo(frame, 18)
	logo.LayoutOrder = 0
	local titleLbl
	if o.Title ~= false then
		titleLbl = Lbl(frame, { Text = tostring(o.Title or "MX HUB"), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, Font = FONT.Bold, TextSize = 13, LayoutOrder = 1 })
	end
	Drag(frame, {
		Begin = function()
			if MX.Locked then return false end
			wm._sp = frame.Position
		end,
		Move = function(pos, origin)
			local d = pos - origin
			local p = wm._sp
			frame.Position = MX:_Clamp(frame, UDim2.new(p.X.Scale, p.X.Offset + d.X, p.Y.Scale, p.Y.Offset + d.Y))
		end,
	})
	function wm:Add(name, value, key)
		key = key or name
		if key then
			for _, it in ipairs(self.Items) do
				if it.Key == key then
					it.Value = value
					it.Name = name
					it:Update()
					return it
				end
			end
		end
		local item = { Name = name, Value = value, Key = key }
		local l = Lbl(frame, { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, TextSize = 12, RichText = true, LayoutOrder = 10 + #self.Items }, "Text")
		item.Label = l
		function item:Update()
			local v = self.Value
			if type(v) == "function" then
				local ok, r = pcall(v)
				v = ok and r or "?"
			end
			local nm = self.Name and ('<font color="' .. Hex(Theme.Sub) .. '">' .. tostring(self.Name) .. "</font> ") or ""
			l.Text = nm .. tostring(v)
		end
		function item:Set(v) self.Value = v self:Update() end
		function item:SetName(n) self.Name = n self:Update() end
		function item:SetVisible(v) l.Visible = v end
		function item:Remove()
			l:Destroy()
			local i = table.find(wm.Items, self)
			if i then table.remove(wm.Items, i) end
		end
		item:Update()
		table.insert(self.Items, item)
		return item
	end
	function wm:AddFPS()
		return self:Add("FPS", function() return string.format('<font color="%s">%d</font>', Hex(FpsColor(FpsNow)), FpsNow) end)
	end
	function wm:AddPing()
		return self:Add("Ping", function()
			local p = PingNow()
			return string.format('<font color="%s">%dms</font>', Hex(PingColor(p)), p)
		end)
	end
	function wm:AddTime() return self:Add(nil, function() return os.date("%H:%M:%S") end, "time") end
	function wm:AddPlayer() return self:Add(nil, function() return LocalPlayer.DisplayName end, "player") end
	function wm:AddFlag(name, flag)
		return self:Add(name, function() local v = MX.Flags[flag] return type(v) == "boolean" and (v and "On" or "Off") or tostring(v) end)
	end
	function wm:SetTitle(t) if titleLbl then titleLbl.Text = tostring(t) end end
	function wm:SetPosition(c) Place(frame, c, o.Margin or 10) frame.Position = MX:_Clamp(frame) end
	function wm:SetVisible(v) self.Visible = v and true or false frame.Visible = self.Visible end
	function wm:Toggle() self:SetVisible(not self.Visible) end
	function wm:Destroy()
		self.Dead = true
		frame:Destroy()
		if MX.Watermark == self then MX.Watermark = nil end
	end
	if o.Items then
		for _, it in ipairs(o.Items) do wm:Add(it[1], it[2]) end
	elseif o.Defaults ~= false then
		wm:AddFPS()
		wm:AddPing()
	end
	task.spawn(function()
		while not wm.Dead and not MX.Dead do
			if wm.Visible then
				for _, it in ipairs(wm.Items) do it:Update() end
				frame.Position = MX:_Clamp(frame)
			end
			task.wait(o.Interval or 0.5)
		end
	end)
	wm.Frame = frame
	MX.Watermark = wm
	return wm
end

function MX:CreateKeybindList(o)
	o = o or {}
	if MX.KeyList then MX.KeyList:Destroy() end
	local kl = { Visible = o.Visible == true, Key = o.Key or Enum.KeyCode.K }
	local frame = Box(FloatLayer, { Size = UDim2.new(0, 170, 0, 0), AutomaticSize = AY, Visible = false }, "Card", 7, "Border")
	GlassOn(frame, 0.2)
	Scaled(frame)
	local pos = o.Position or "Left"
	if pos == "Left" then
		frame.AnchorPoint = Vector2.new(0, 0.5)
		frame.Position = UDim2.new(0, o.Margin or 10, 0.5, 0)
	else
		Place(frame, pos, o.Margin or 10)
	end
	Pad(frame, 6, 8, 8, 8)
	List(frame, 3)
	local head = Box(frame, { Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0 })
	Lbl(head, { Text = "MX  Keybinds", Size = UDim2.fromScale(1, 1), Font = FONT.Bold, TextSize = 12 }, "Accent")
	Drag(head, {
		Begin = function()
			if MX.Locked then return false end
			kl._sp = frame.Position
		end,
		Move = function(p, origin)
			local d = p - origin
			local s = kl._sp
			frame.Position = MX:_Clamp(frame, UDim2.new(s.X.Scale, s.X.Offset + d.X, s.Y.Scale, s.Y.Offset + d.Y))
		end,
	})
	function kl:Refresh()
		local act = {}
		for _, b in ipairs(MX.Binds) do
			if b.Key and b.GetActive and b.GetActive() then act[#act + 1] = b end
		end
		frame.Visible = self.Visible
		local parts = {}
		for _, b in ipairs(act) do parts[#parts + 1] = tostring(b.Name) .. "|" .. KeyLabel(b.Key) .. "|" .. tostring(b.Mode) end
		local sig = table.concat(parts, ";") .. MX.ThemeName .. tostring(Theme.Accent)
		if sig == self._sig then return end
		self._sig = sig
		self.Count = #act
		for _, c in ipairs(frame:GetChildren()) do
			if c:IsA("GuiObject") and c ~= head then c:Destroy() end
		end
		for n, b in ipairs(act) do
			local r = Box(frame, { Size = UDim2.new(1, 0, 0, Touch and 28 or 20), LayoutOrder = n })
			local dot = Box(r, { Size = UDim2.fromOffset(6, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundTransparency = 0 }, nil, 3)
			dot.BackgroundColor3 = Theme.Accent
			Lbl(r, { Text = tostring(b.Name), Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -72, 1, 0), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd }, "Text")
			Lbl(r, { Text = "[" .. KeyLabel(b.Key) .. "] " .. string.sub(b.Mode or "", 1, 1), Position = UDim2.new(1, -60, 0, 0), Size = UDim2.new(0, 60, 1, 0), TextSize = 11, TextXAlignment = RIGHT, Font = FONT.Mono }, "Sub")
			if Touch then Tap(Hit(r, 3), function() b:Trigger() end) end
		end
		if #act == 0 then
			local r = Box(frame, { Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1 })
			Lbl(r, { Text = "No active keybinds", Size = UDim2.fromScale(1, 1), TextSize = 11 }, "Sub")
		end
		task.defer(function()
			if frame.Parent then frame.Position = MX:_Clamp(frame) end
		end)
	end
	function kl:SetKey(k) self.Key = k end
	function kl:SetVisible(v)
		self.Visible = v and true or false
		frame.Visible = self.Visible
		if self.Visible then self:Refresh() end
	end
	function kl:Toggle() self:SetVisible(not self.Visible) end
	function kl:Destroy()
		self._c:Disconnect()
		frame:Destroy()
		if MX.KeyList == self then MX.KeyList = nil end
	end
	kl._c = Conn(UIS.InputBegan, function(i)
		if i.KeyCode == kl.Key and not UIS:GetFocusedTextBox() and not MX.Listening then kl:Toggle() end
	end)
	kl.Frame = frame
	MX.KeyList = kl
	kl:Refresh()
	task.spawn(function()
		while not MX.Dead and kl._c.Connected do
			if kl.Visible then kl:Refresh() end
			task.wait(0.4)
		end
	end)
	return kl
end

local TagColors = { red = "#ff5a5a", green = "#5ae08a", blue = "#5aa0ff", yellow = "#ffd95a", orange = "#ffa04a", purple = "#b080ff", pink = "#ff80c0", cyan = "#5ae0e0", white = "#ffffff", gray = "#9a9aa8" }
local function Rich(s)
	s = tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	local stack = {}
	s = s:gsub("%[(/?)([%w#]*)%]", function(slash, name)
		if slash == "/" then
			local t = table.remove(stack)
			if t then return "</" .. t .. ">" end
			return nil
		end
		if name == "b" or name == "i" then
			table.insert(stack, name)
			return "<" .. name .. ">"
		end
		local col = TagColors[name]
		if name == "accent" then col = Hex(Theme.Accent) elseif name == "sub" then col = Hex(Theme.Sub) elseif name == "text" then col = Hex(Theme.Text) end
		if not col and name:match("^#%x%x%x%x%x%x$") then col = name end
		if col then
			table.insert(stack, "font")
			return '<font color="' .. col .. '">'
		end
		return nil
	end)
	for i = #stack, 1, -1 do s = s .. "</" .. stack[i] .. ">" end
	return s
end

local WinN = 0
function MX:AddWindow(o)
	o = o or {}
	WinN += 1
	local w = o.Width or (o.Size and o.Size.X) or 300
	local h = o.Height or (o.Size and o.Size.Y) or 180
	w, h = math.max(w, 140), math.max(h, 90)
	local minW, minH = w, h
	local maxW, maxH = o.MaxWidth or math.max(w * 2.2, 560), o.MaxHeight or math.max(h * 2.6, 460)
	local f = Box(FloatLayer, { Size = UDim2.fromOffset(w, h), ClipsDescendants = true, ZIndex = WinN }, "Window", 8, "Border")
	Scaled(f)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	if typeof(o.Position) == "UDim2" then f.Position = o.Position
	elseif typeof(o.Position) == "Vector2" then f.Position = UDim2.fromOffset(o.Position.X, o.Position.Y)
	else f.Position = UDim2.new(0.5, 24 * (WinN % 8), 0.5, 24 * (WinN % 8)) end
	local head = Box(f, { Size = UDim2.new(1, 0, 0, 30), ZIndex = 3 }, "Panel", 8)
	Box(head, { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8) }, "Panel")
	local hl = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -40, 1, 0) }, head)
	List(hl, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	if o.Icon then
		local ic = MakeIcon(hl, o.Icon, 16, "Accent")
		if ic then ic.LayoutOrder = 1 end
	end
	local titleLbl = Lbl(hl, { Text = tostring(o.Title or "Window"), Size = UDim2.new(1, -24, 1, 0), Font = FONT.Bold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 2 })
	local handle
	local H = {}
	local vars = {}
	for k, v in pairs(o.Variables or {}) do vars[k] = v end
	if o.Closable ~= false then
		local xb = MakeIcon(head, "x", 12, "Sub")
		xb.AnchorPoint = Vector2.new(1, 0.5)
		xb.Position = UDim2.new(1, -10, 0.5, 0)
		xb.ZIndex = 5
		local xh = Hit(head, 4)
		xh.Size = UDim2.fromOffset(32, 30)
		xh.AnchorPoint = Vector2.new(1, 0)
		xh.Position = UDim2.new(1, 0, 0, 0)
		Tap(xh, function()
			if o.OnClose then MX._Run(o.OnClose, handle) end
			if o.DestroyOnClose then handle:Destroy() else f.Visible = false end
		end)
	end
	local sc = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 1, -30), CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y }, f)
	Bind(sc, { ScrollBarImageColor3 = "Sub" })
	local cont = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY }, sc)
	Pad(cont, 8, 8, 8, 8)
	List(cont, 6)
	local startPos
	Drag(head, {
		Begin = function()
			WinN += 1
			f.ZIndex = WinN
			if MX.Locked then return false end
			startPos = f.Position
		end,
		Move = function(pos, origin)
			if o.Draggable == false then return end
			local d = pos - origin
			f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end,
	})
	local live = {}
	local function subst(text)
		text = tostring(text)
		local map = {
			fps = FpsNow, ping = PingNow(), players = #Players:GetPlayers(), maxplayers = Players.MaxPlayers, time = os.date("%H:%M:%S"), date = os.date("%Y-%m-%d"),
			user = LocalPlayer.DisplayName, username = LocalPlayer.Name, placeid = game.PlaceId,
		}
		return (text:gsub("{(%w+)}", function(k)
			local v = vars[k]
			if v ~= nil then
				if type(v) == "function" then
					local ok, r = pcall(v)
					return ok and tostring(r) or "?"
				end
				return tostring(v)
			end
			if map[k] ~= nil then return tostring(map[k]) end
			return nil
		end))
	end
	local function track(label, raw)
		local e = { l = label, raw = raw }
		function e:Update() self.l.Text = Rich(subst(self.raw)) end
		e:Update()
		table.insert(live, e)
		return e
	end
	local textLines = {}
	if o.Content then
		if type(o.Content) == "table" then textLines = table.clone(o.Content) else textLines = { tostring(o.Content) } end
	end
	local textLbl = Lbl(cont, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextSize = o.TextSize or 13, Font = FONT.Reg, RichText = true, LayoutOrder = 0, Visible = #textLines > 0 })
	local textE = track(textLbl, table.concat(textLines, "\n"))
	local rowsFrame = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = 1 }, cont)
	List(rowsFrame, 4)
	local rows = {}
	handle = setmetatable({ Content = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = 2 }, cont), NoIndex = true, Frame = f }, {
		__index = function(t, k)
			local v = rawget(H, k)
			if v ~= nil then return v end
			return Container[k]
		end,
	})
	List(handle.Content, 6)
	local function mkRow(name, value)
		local r = Box(rowsFrame, { Size = UDim2.new(1, 0, 0, 22), LayoutOrder = #rows + 1 }, "Element", 5)
		local n = Lbl(r, { Text = tostring(name), Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0.5, -8, 1, 0), TextSize = 12, Font = FONT.Reg }, "Sub")
		local v = Lbl(r, { Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -8, 1, 0), TextSize = 12, TextXAlignment = RIGHT, RichText = true })
		local e = track(v, value)
		local rowObj = { Name = name, Frame = r, E = e }
		function rowObj:Set(x) e.raw = tostring(x) e:Update() end
		function rowObj:Get() return e.raw end
		function rowObj:SetName(x) n.Text = tostring(x) self.Name = x end
		function rowObj:SetVisible(x) r.Visible = x end
		function rowObj:Destroy()
			r:Destroy()
			local i = table.find(live, e)
			if i then table.remove(live, i) end
			local j = table.find(rows, self)
			if j then table.remove(rows, j) end
		end
		table.insert(rows, rowObj)
		return rowObj
	end
	for _, r in ipairs(o.Rows or {}) do mkRow(r[1], r[2]) end
	function H:SetTitle(t) titleLbl.Text = tostring(t) end
	function H:SetContent(t)
		textLines = type(t) == "table" and table.clone(t) or { tostring(t) }
		textE.raw = table.concat(textLines, "\n")
		textLbl.Visible = true
		textE:Update()
	end
	function H:Append(t)
		table.insert(textLines, tostring(t))
		textE.raw = table.concat(textLines, "\n")
		textLbl.Visible = true
		textE:Update()
	end
	function H:GetContent() return table.concat(textLines, "\n") end
	function H:AddRow(name, value) return mkRow(name, value) end
	function H:GetRow(name)
		for _, r in ipairs(rows) do if r.Name == name then return r end end
	end
	function H:SetRow(name, value)
		local r = self:GetRow(name) or mkRow(name, value)
		r:Set(value)
		return r
	end
	function H:RemoveRow(name)
		local r = self:GetRow(name)
		if r then r:Destroy() end
	end
	function H:AddLabel(text)
		local l = Lbl(self.Content, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextSize = 12, Font = FONT.Reg, RichText = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = self:_Order() }, "Sub")
		local e = track(l, text)
		local obj = {}
		function obj:Set(t) e.raw = tostring(t) e:Update() end
		function obj:Get() return e.raw end
		function obj:SetVisible(v) l.Visible = v end
		return obj
	end
	function H:SetVariable(k, v)
		vars[k] = v
		for _, e in ipairs(live) do e:Update() end
	end
	function H:SetSize(a, b)
		if typeof(a) == "Vector2" then a, b = a.X, a.Y end
		b = b or h
		w, h = math.clamp(a, minW, maxW), math.clamp(b, minH, maxH)
		f.Size = UDim2.fromOffset(w, h)
	end
	function H:GetSize() return Vector2.new(w, h) end
	function H:SetLimits(mn, mx)
		minW, minH, maxW, maxH = mn.X, mn.Y, mx.X, mx.Y
	end
	function H:SetPosition(p)
		if typeof(p) == "Vector2" then p = UDim2.fromOffset(p.X, p.Y) end
		f.Position = p
	end
	function H:Toggle(v)
		if v == nil then v = not f.Visible end
		f.Visible = v
	end
	function H:Show() f.Visible = true end
	function H:Hide() f.Visible = false end
	function H:Destroy()
		handle.Dead = true
		f:Destroy()
	end
	if o.Resizable ~= false then
		local grip = New("TextButton", { Text = "◢", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Font = FONT.Bold, TextSize = 10, ZIndex = 8 }, f)
		Bind(grip, { TextColor3 = "Sub" })
		local sw, sh
		Drag(grip, {
			Begin = function()
				if MX.Locked then return false end
				sw, sh = w, h
			end,
			Move = function(pos, origin)
				local d = (pos - origin) / MX.Scale
				H.SetSize(handle, sw + d.X, sh + d.Y)
			end,
		})
	end
	if o.Visible == false then f.Visible = false end
	task.spawn(function()
		while not handle.Dead and not MX.Dead do
			if f.Visible then
				for _, e in ipairs(live) do e:Update() end
			end
			task.wait(0.3)
		end
	end)
	return handle
end
function Window:AddWindow(o) return MX:AddWindow(o) end

function MX._Run(fn, ...)
	if type(fn) ~= "function" then return end
	task.spawn(function(...)
		local ok, err = xpcall(fn, function(e) return tostring(e) .. "\n" .. debug.traceback() end, ...)
		if ok then return end
		warn("[MX] " .. tostring(err))
		local now = os.clock()
		if MX.ShowErrors ~= false and not MX.Dead and now - (MX._lastErr or -10) > 2 then
			MX._lastErr = now
			local msg = tostring(err):match("^[^\n]*") or "error"
			MX:Notify({ Type = "Error", Title = "Script Error", Content = msg:sub(1, 140), Duration = 4 })
		end
	end, ...)
end

MX._deps = {}
function MX._DepTick()
	for i = #MX._deps, 1, -1 do
		local d = MX._deps[i]
		if not d.row.Parent then
			table.remove(MX._deps, i)
		else
			local ok, vis = pcall(d.check)
			if ok and d.row.Visible ~= vis then d.row.Visible = vis end
		end
	end
end
function MX._Depend(row, o)
	local d = type(o) == "table" and (o.Depends or o.DependsOn) or nil
	if d == nil or not row then return end
	local flag, want = d, true
	if type(d) == "table" then
		flag = d.Flag or d[1]
		if d.Value ~= nil then want = d.Value elseif d[2] ~= nil then want = d[2] end
	end
	local function check()
		local v = MX.Flags[flag]
		if type(want) == "function" then return want(v) and true or false end
		if want == true then return v ~= nil and v ~= false and not (type(v) == "table" and #v == 0) end
		if want == false then return not v end
		if type(v) == "table" and type(want) == "string" then return table.find(v, want) ~= nil end
		return v == want
	end
	table.insert(MX._deps, { row = row, check = check })
	row.Visible = check()
	if not MX._depLoop then
		MX._depLoop = true
		task.spawn(function()
			while not MX.Dead do
				MX._DepTick()
				task.wait(0.12)
			end
		end)
	end
end

function Container:AddLabel(o, color)
	local text = o
	if type(o) == "table" then text, color = o.Title or o.Text or o.Content, o.Color or color end
	text = tostring(text or "")
	local rich = (type(o) == "table" and o.Rich == true) or text:find("%[/%]") ~= nil
	local fixed = typeof(color) == "Color3"
	local tok = fixed and false or (type(color) == "string" and color or "Sub")
	local l, e = Lbl(self.Content, { Text = rich and Rich(text) or text, RichText = rich, Font = FONT.Reg, TextSize = 13, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = self:_Order(), Tr = not rich }, tok)
	if fixed then l.TextColor3 = color end
	local obj = {}
	function obj:Set(t)
		if rich then l.Text = Rich(tostring(t)) else TrSet(e, tostring(t)) end
	end
	function obj:Get() return l.Text end
	function obj:SetVisible(v) l.Visible = v end
	MX._Depend(l, type(o) == "table" and o or nil)
	return obj
end

function Container:AddDivider(o)
	if type(o) == "string" then o = { Title = o } end
	o = o or {}
	local f
	if o.Title and o.Title ~= "" then
		f = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = self:_Order() }, self.Content)
		local line = Box(f, { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0) }, "Border")
		line.BackgroundTransparency = 0.4
		local tag = Box(f, { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, Position = UDim2.new(0, 8, 0, 0) }, "Card")
		Pad(tag, 0, 6, 0, 6)
		Lbl(tag, { Text = tostring(o.Title), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, TextSize = 11, Font = FONT.Bold, Tr = true }, "Sub")
	else
		f = Box(self.Content, { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = self:_Order() }, "Border")
		f.BackgroundTransparency = 0.4
	end
	MX._Depend(f, o)
	local obj = {}
	function obj:SetVisible(v) f.Visible = v end
	return obj
end

function Container:AddPicture(o)
	if type(o) ~= "table" then o = { Image = o } end
	local size = o.Size or 72
	local circle = o.Shape == "Circle"
	local row = Box(self.Content, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = self:_Order() }, "Element", 6)
	Pad(row, 10, 10, 10, 10)
	local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size) }, row)
	local hasDesc = o.Description ~= nil and o.Description ~= ""
	local hasText = (o.Title ~= nil and o.Title ~= "") or hasDesc
	local alignLeft = o.Align == "Left" or hasText
	List(holder, 12, Enum.FillDirection.Horizontal, alignLeft and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local radius = circle and size or 8
	local frame = Box(holder, { Size = UDim2.fromOffset(size, size), LayoutOrder = 1 }, "Card", radius, "Border")
	local img = New("ImageLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ScaleType = o.Fit == "Fit" and Enum.ScaleType.Fit or Enum.ScaleType.Crop }, frame)
	New("UICorner", { CornerRadius = UDim.new(0, radius) }, img)
	local tl, te, dl, de
	if hasText then
		local txt = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -(size + 12), 0, 0), AutomaticSize = AY, LayoutOrder = 2 }, holder)
		List(txt, 2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
		tl, te = Lbl(txt, { Text = tostring(o.Title or ""), Size = UDim2.new(1, 0, 0, TS(14) + 4), Font = FONT.Bold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1, Tr = true })
		dl, de = Lbl(txt, { Text = tostring(o.Description or ""), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextSize = 12, Font = FONT.Reg, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Visible = hasDesc, Tr = true }, "Sub")
	end
	local obj = {}
	local token = 0
	function obj:SetImage(src)
		token += 1
		local mine = token
		task.spawn(function()
			local r = MX:ResolveImage(src)
			if r and mine == token and img.Parent then img.Image = r end
		end)
	end
	function obj:Set(title, desc)
		if te and title ~= nil then TrSet(te, tostring(title)) end
		if de and desc ~= nil then
			TrSet(de, tostring(desc))
			dl.Visible = tostring(desc) ~= ""
		end
	end
	function obj:SetVisible(v) row.Visible = v end
	if o.Image ~= nil then obj:SetImage(o.Image) end
	if o.Callback then
		local ph = Hit(row, 5)
		Hover(ph, row, "Element", "Hover")
		Tap(ph, function() MX._Run(o.Callback) end)
	end
	self:_Reg(o.Title, row)
	MX._Depend(row, o)
	return obj
end

function Container:AddStat(o)
	if type(o) ~= "table" then o = { Title = o } end
	local row = Box(self.Content, { Size = UDim2.new(1, 0, 0, Touch and 64 or 58), LayoutOrder = self:_Order() }, "Element", 6)
	local left = 12
	if o.Icon then
		local ic = MakeIcon(row, o.Icon, 20, "Accent")
		if ic then
			ic.AnchorPoint = Vector2.new(0, 0.5)
			ic.Position = UDim2.new(0, 12, 0.5, 0)
			left = 44
		end
	end
	Lbl(row, { Text = tostring(o.Title or ""), Position = UDim2.new(0, left, 0, 8), Size = UDim2.new(1, -left - 12, 0, 14), TextSize = 12, Font = FONT.Reg, Tr = true }, "Sub")
	local fixed = typeof(o.Color) == "Color3"
	local val = Lbl(row, { Position = UDim2.new(0, left, 0, 24), Size = UDim2.new(1, -left - 12, 0, 26), TextSize = 20, Font = FONT.Bold, RichText = true, TextTruncate = Enum.TextTruncate.AtEnd }, fixed and false or (type(o.Color) == "string" and o.Color or "Text"))
	if fixed then val.TextColor3 = o.Color end
	local obj = {}
	function obj:Set(v)
		self.Value = v
		val.Text = Rich(tostring(v == nil and "-" or v))
	end
	function obj:Get() return self.Value end
	function obj:SetVisible(v) row.Visible = v end
	local src = o.Value
	if type(src) == "function" then
		local function pull()
			local ok, r = pcall(src)
			obj:Set(ok and r or "?")
		end
		pull()
		task.spawn(function()
			while row.Parent and not MX.Dead do
				task.wait(math.max(o.Interval or 1, 0.25))
				pull()
			end
		end)
	else
		obj:Set(src)
	end
	if o.Callback then Tap(Hit(row, 3), function() MX._Run(o.Callback, obj.Value) end) end
	self:_Reg(o.Title, row)
	MX._Depend(row, o)
	return obj
end

function Container:AddBanner(o)
	if type(o) ~= "table" then o = { Content = o } end
	local kind = NoteTypes[o.Type] and o.Type or "Info"
	local tokc = NoteTypes[kind]
	local row = Box(self.Content, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = self:_Order() }, "Element", 6)
	local bar = New("Frame", { BorderSizePixel = 0, Position = UDim2.new(0, 5, 0, 6), Size = UDim2.new(0, 3, 1, -12) }, row)
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	Bind(bar, { BackgroundColor3 = tokc })
	local body = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -8, 0, 0), AutomaticSize = AY }, row)
	Pad(body, 8, 10, 8, 10)
	List(body, 4)
	local head = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TS(16)), LayoutOrder = 1 }, body)
	local gl = MakeIcon(head, o.Icon or NoteIcon[kind], 16, tokc)
	if gl then
		gl.AnchorPoint = Vector2.new(0, 0.5)
		gl.Position = UDim2.new(0, 0, 0.5, 0)
	end
	local dismissible = o.Dismissible == true
	local _, te = Lbl(head, { Text = tostring(o.Title or kind), Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, dismissible and -48 or -22, 1, 0), Font = FONT.Bold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, Tr = true })
	local text = o.Content or o.Lines
	if type(text) == "table" then text = table.concat(text, "\n") end
	local content = Lbl(body, { Text = Rich(text or ""), RichText = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextSize = 13, Font = FONT.Reg, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Visible = text ~= nil and text ~= "" }, "Sub")
	if dismissible then
		local x = MakeIcon(head, "x", 12, "Sub")
		if x then
			x.AnchorPoint = Vector2.new(1, 0.5)
			x.Position = UDim2.new(1, 0, 0.5, 0)
		end
		local xh = Hit(head, 4)
		xh.AnchorPoint = Vector2.new(1, 0.5)
		xh.Position = UDim2.new(1, 8, 0.5, 0)
		xh.Size = UDim2.fromOffset(36, 30)
		Tap(xh, function()
			row.Visible = false
			if o.OnDismiss then MX._Run(o.OnDismiss) end
		end)
	elseif o.Callback then
		Tap(Hit(row, 2), function() MX._Run(o.Callback) end)
	end
	local obj = {}
	function obj:SetTitle(t) TrSet(te, tostring(t)) end
	function obj:SetContent(t)
		if type(t) == "table" then t = table.concat(t, "\n") end
		content.Text = Rich(t or "")
		content.Visible = t ~= nil and t ~= ""
	end
	function obj:SetVisible(v) row.Visible = v end
	self:_Reg(o.Title, row)
	MX._Depend(row, o)
	return obj
end

function Container:AddGroupbox(o)
	if type(o) == "string" then o = { Title = o } end
	o = o or {}
	local box = Box(self.Content, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = self:_Order() }, "Panel", 8)
	Pad(box, 8, 8, 8, 8)
	List(box, 6)
	if o.Title and o.Title ~= "" then
		local head = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0 }, box)
		Box(head, { Size = UDim2.fromOffset(3, 12), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, "Accent", 2)
		local left = 10
		if o.Icon then
			local ic = MakeIcon(head, o.Icon, 14, "Accent")
			if ic then
				ic.AnchorPoint = Vector2.new(0, 0.5)
				ic.Position = UDim2.new(0, 10, 0.5, 0)
				left = 30
			end
		end
		Lbl(head, { Text = tostring(o.Title), Position = UDim2.new(0, left, 0, 0), Size = UDim2.new(1, -left, 1, 0), Font = FONT.Bold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Tr = true })
		local ln = Box(box, { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 1 }, "Border")
		ln.BackgroundTransparency = 0.5
	end
	local content = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = 2 }, box)
	List(content, 6)
	local child = self:_Child(content)
	function child:SetVisible(v) box.Visible = v end
	MX._Depend(box, o)
	return child
end

function Container:AddPlayerDropdown(o)
	o = o or {}
	local function names()
		local t = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if o.IncludeSelf or p ~= LocalPlayer then t[#t + 1] = p.Name end
		end
		table.sort(t, function(a, b) return a:lower() < b:lower() end)
		return t
	end
	local dd = self:AddDropdown({
		Title = o.Title or "Player", Description = o.Description, Flag = o.Flag, Values = names(), Search = true,
		Placeholder = o.Placeholder or "Select player", Callback = o.Callback, Depends = o.Depends, Badge = o.Badge,
	})
	local function refresh() dd:Refresh(names()) end
	Conn(Players.PlayerAdded, refresh)
	Conn(Players.PlayerRemoving, function() task.defer(refresh) end)
	function dd:GetPlayer() return self.Value and Players:FindFirstChild(self.Value) or nil end
	dd.RefreshPlayers = refresh
	return dd
end


MX.Changelog = {}
MX._clListeners = {}

do
	local kinds = {
		up = "Add", add = "Add", new = "Add", added = "Add", ["+"] = "Add",
		down = "Remove", remove = "Remove", removed = "Remove", delete = "Remove", deleted = "Remove", ["-"] = "Remove",
		fix = "Fix", fixed = "Fix", change = "Fix", changed = "Fix", update = "Fix", updated = "Fix", ["~"] = "Fix",
	}
	local style = {
		Add = { tok = "Success", sym = "+" },
		Remove = { tok = "Danger", sym = "-" },
		Fix = { tok = "Warning", sym = "~" },
	}
	local function esc(t)
		return (tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end
	local function norm(e)
		local text, kind, note
		if type(e) == "string" then
			local p, rest = e:match("^%s*([%+%-~])%s+(.+)$")
			if p then
				kind, text = kinds[p], rest
			else
				kind, text = "Add", e
			end
		elseif type(e) == "table" then
			text = e.Text or e.Title or e[1]
			kind = kinds[tostring(e.Type or e.Kind or e[2] or "up"):lower()] or "Add"
			note = e.Note or e.Description or e[3]
		end
		if text == nil then return nil end
		return { Text = tostring(text), Kind = kind or "Add", Note = note ~= nil and tostring(note) or nil }
	end
	local function expand(list)
		local out = {}
		if type(list) ~= "table" then return out end
		if list[1] == nil then list = { list } end
		for _, e in ipairs(list) do
			if type(e) == "table" and e[1] == nil and e.Text == nil and e.Title == nil then
				local keys = {}
				for k in pairs(e) do keys[#keys + 1] = tostring(k) end
				table.sort(keys)
				for _, k in ipairs(keys) do
					local n = norm({ k, e[k] })
					if n then out[#out + 1] = n end
				end
			else
				local n = norm(e)
				if n then out[#out + 1] = n end
			end
		end
		return out
	end
	local function build(e)
		e = type(e) == "table" and e or {}
		return {
			Version = tostring(e.Version or e.Name or "1.0"),
			Date = e.Date and tostring(e.Date) or nil,
			Title = e.Title and tostring(e.Title) or nil,
			Entries = expand(e.Entries or e.Changes or e.List),
		}
	end
	function MX:_ChangelogChanged()
		for _, f in ipairs(MX._clListeners) do pcall(f) end
	end
	function MX:SetChangelog(list)
		MX.Changelog = {}
		for _, e in ipairs(list or {}) do MX.Changelog[#MX.Changelog + 1] = build(e) end
		MX:_ChangelogChanged()
	end
	function MX:AddChangelog(e)
		table.insert(MX.Changelog, 1, build(e))
		MX:_ChangelogChanged()
	end
	function MX:GetChangelog() return MX.Changelog end

	MX.Options.changelog_seen = {
		Type = "Changelog",
		Serialize = function() return MX._clSeen end,
		Deserialize = function(_, v)
			MX._clSeen = v ~= nil and tostring(v) or nil
			MX:_ChangelogChanged()
		end,
	}

	function Window:_BuildChangelogButton(hr, bsz)
		local b, h = PaletteButton(hr, "history", 2, bsz)
		self.ChangelogBtn = b
		local dot = New("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -3, 0, 3), BorderSizePixel = 0, ZIndex = 6 }, b)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		Bind(dot, { BackgroundColor3 = "Danger" })
		local function refresh()
			local latest = MX.Changelog[1]
			b.Visible = true
			dot.Visible = latest ~= nil and MX._clSeen ~= latest.Version
		end
		table.insert(MX._clListeners, refresh)
		refresh()
		MX:Tip(h, "Changelog")
		Tap(h, function() self:OpenChangelog() end)
	end

	function Window:CloseChangelog()
		local dim = self._cl
		self._cl = nil
		if dim and dim.Parent then
			Tween(dim, { BackgroundTransparency = 1 }, 0.12)
			task.delay(0.12, function() if dim.Parent then dim:Destroy() end end)
		end
	end

	function Window:OpenChangelog()
		if self._cl and self._cl.Parent then return end
		local list = MX.Changelog
		local latest = list[1]
		MX:CloseAllPopups()
		if latest then
			MX._clSeen = latest.Version
			MX:_ChangelogChanged()
		end
		local dim = New("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = C3(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 60, BorderSizePixel = 0 }, self.Main)
		New("UICorner", { CornerRadius = UDim.new(0, 10) }, dim)
		Tween(dim, { BackgroundTransparency = 0.45 }, 0.15)
		self._cl = dim
		Tap(dim, function() self:CloseChangelog() end)
		local pw = math.min(440, (self.W or 480) - 32)
		local ph = math.min(400, (self.H or 420) - 40)
		local panel = Box(dim, { Size = UDim2.fromOffset(pw, ph), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 61, Active = true }, "Card", 10, "Border")
		local head = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46) }, panel)
		local hic = MakeIcon(head, "history", 18, "Accent")
		hic.AnchorPoint = Vector2.new(0, 0.5)
		hic.Position = UDim2.new(0, 14, 0.5, 0)
		Lbl(head, { Text = "Changelog", Position = UDim2.new(0, 42, 0, 7), Size = UDim2.new(1, -96, 0, 18), Font = FONT.Bold, TextSize = 16, Tr = true })
		Lbl(head, { Text = latest and ("Latest version " .. latest.Version) or "", Position = UDim2.new(0, 42, 0, 26), Size = UDim2.new(1, -96, 0, 14), Font = FONT.Reg, TextSize = 11 }, "Sub")
		local xb = Box(head, { Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) }, "Element", 6)
		local xi = MakeIcon(xb, "x", 14, "Sub")
		xi.AnchorPoint = Vector2.new(0.5, 0.5)
		xi.Position = UDim2.fromScale(0.5, 0.5)
		local xh = Hit(xb, 3)
		Hover(xh, xb, "Element", "Hover")
		Tap(xh, function() self:CloseChangelog() end)
		local line = Box(panel, { Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 0, 46) }, "Border")
		line.BackgroundTransparency = 0.5
		local sc = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 52), Size = UDim2.new(1, 0, 1, -58), CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollBarThickness = Touch and 4 or 3, ScrollingDirection = Enum.ScrollingDirection.Y }, panel)
		Pad(sc, 4, 14, 8, 14)
		List(sc, 8)
		if #list == 0 then
			Lbl(sc, { Text = "No changelog yet", Size = UDim2.new(1, 0, 0, 40), TextXAlignment = CENTER, TextSize = 13, Tr = true }, "Sub")
		end
		for idx, v in ipairs(list) do
			local card = Box(sc, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = idx }, "Element", 8)
			List(card, 0)
			local hd = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Touch and 44 or 38), LayoutOrder = 1 }, card)
			local info = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -140, 1, 0) }, hd)
			List(info, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
			local pill = Box(info, { Size = UDim2.new(0, 0, 0, 20), AutomaticSize = AX, LayoutOrder = 1 }, "Accent", 10)
			Pad(pill, 0, 8, 0, 8)
			Lbl(pill, { Text = "v" .. v.Version, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, Font = FONT.Bold, TextSize = 12 }, "OnAccent")
			if v.Title then
				Lbl(info, { Text = v.Title, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, Font = FONT.Bold, TextSize = 13, LayoutOrder = 2 })
			end
			if v.Date then
				Lbl(info, { Text = v.Date, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, Font = FONT.Reg, TextSize = 11, LayoutOrder = 3 }, "Sub")
			end
			local counts = { Add = 0, Remove = 0, Fix = 0 }
			for _, e in ipairs(v.Entries) do counts[e.Kind] += 1 end
			local chips = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0.5, 0), Size = UDim2.new(0, 0, 0, 20), AutomaticSize = AX }, hd)
			List(chips, 4, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
			for ci, kind in ipairs({ "Add", "Remove", "Fix" }) do
				if counts[kind] > 0 then
					local st = style[kind]
					local chip = Box(chips, { Size = UDim2.new(0, 0, 0, 18), AutomaticSize = AX, LayoutOrder = ci }, st.tok, 5)
					chip.BackgroundTransparency = 0.82
					Pad(chip, 0, 6, 0, 6)
					Lbl(chip, { Text = st.sym .. counts[kind], Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, Font = FONT.Bold, TextSize = 11 }, st.tok)
				end
			end
			local arrow = MakeIcon(hd, "chevron-down", 14, "Sub")
			arrow.AnchorPoint = Vector2.new(1, 0.5)
			arrow.Position = UDim2.new(1, -12, 0.5, 0)
			local body = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = 2 }, card)
			Pad(body, 2, 10, 10, 10)
			List(body, 6)
			for j, e in ipairs(v.Entries) do
				local st = style[e.Kind]
				local row = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = j }, body)
				local badge = Box(row, { Size = UDim2.fromOffset(20, 20) }, st.tok, 5)
				badge.BackgroundTransparency = 0.8
				Lbl(badge, { Text = st.sym, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, Font = FONT.Bold, TextSize = 14 }, st.tok)
				local col = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -28, 0, 0), AutomaticSize = AY }, row)
				List(col, 1)
				Lbl(col, { Text = e.Kind == "Remove" and ("<s>" .. esc(e.Text) .. "</s>") or esc(e.Text), RichText = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Font = FONT.Reg, TextSize = 13, LayoutOrder = 1 }, e.Kind == "Remove" and "Sub" or "Text")
				if e.Note then
					Lbl(col, { Text = e.Note, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Font = FONT.Reg, TextSize = 11, LayoutOrder = 2 }, "Sub")
				end
			end
			local expanded = idx == 1
			body.Visible = expanded
			arrow.Rotation = expanded and 0 or -90
			local hh = Hit(hd, 2)
			Hover(hh, card, "Element", "Hover")
			Tap(hh, function()
				expanded = not expanded
				body.Visible = expanded
				Tween(arrow, { Rotation = expanded and 0 or -90 }, 0.15)
			end)
		end
	end
end


function MX:Rejoin()
	local TS = game:GetService("TeleportService")
	MX:Info("Rejoin", "Rejoining...", 3)
	local ok, err = pcall(function()
		if #Players:GetPlayers() <= 1 or game.JobId == "" then
			TS:Teleport(game.PlaceId, LocalPlayer)
		else
			TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end
	end)
	if not ok then MX:Error("Rejoin failed", tostring(err), 4) end
end

function MX:ServerHop()
	if MX._hopping then return end
	MX._hopping = true
	task.delay(6, function() MX._hopping = false end)
	MX:Info("Server Hop", "Searching for another server...", 3)
	task.spawn(function()
		local TS = game:GetService("TeleportService")
		local target
		local cursor
		for _ = 1, 5 do
			if MX.Dead then return end
			local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
			if cursor then url = url .. "&cursor=" .. cursor end
			local okGet, body = pcall(function() return game:HttpGet(url) end)
			if not okGet then break end
			local okJson, data = pcall(function() return HttpService:JSONDecode(body) end)
			if not okJson or type(data) ~= "table" or type(data.data) ~= "table" then break end
			local pool = {}
			for _, sv in ipairs(data.data) do
				if sv.id ~= game.JobId and tonumber(sv.playing) and tonumber(sv.maxPlayers) and sv.playing < sv.maxPlayers then
					pool[#pool + 1] = sv
				end
			end
			if #pool > 0 then
				target = pool[math.random(#pool)]
				break
			end
			cursor = data.nextPageCursor
			if type(cursor) ~= "string" then break end
		end
		if target then
			local ok, err = pcall(function() TS:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer) end)
			if not ok then MX:Error("Server Hop failed", tostring(err), 4) end
		else
			local ok = pcall(function() TS:Teleport(game.PlaceId, LocalPlayer) end)
			if ok then
				MX:Info("Server Hop", "No server list, joining a new server", 3)
			else
				MX:Error("Server Hop failed", "No server found", 4)
			end
		end
	end)
end

function Container:AddGameCard(o)
	o = type(o) == "table" and o or {}
	local card = Box(self.Content, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, LayoutOrder = self:_Order() }, "Element", 8)
	Pad(card, 10, 10, 10, 10)
	List(card, 8)

	local head = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = 1 }, card)
	local iconBox = Box(head, { Size = UDim2.fromOffset(56, 56) }, "Card", 10, "Border")
	local icon = New("ImageLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop }, iconBox)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, icon)
	local nameLbl = Lbl(head, { Text = tostring(o.Title or game.Name), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 68, 0.5, 0), Size = UDim2.new(1, -68, 0, 24), Font = FONT.Bold, TextSize = 17, TextTruncate = Enum.TextTruncate.AtEnd }, "Text")

	task.spawn(function()
		local r = MX:ResolveImage(o.Image or { Game = true })
		if r and icon.Parent then icon.Image = r end
	end)
	if o.Title == nil then
		task.spawn(function()
			local ok, pi = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
			if ok and type(pi) == "table" and pi.Name and nameLbl.Parent then nameLbl.Text = tostring(pi.Name) end
		end)
	end

	local stats = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), LayoutOrder = 2 }, card)
	local vals = {}
	for i, n in ipairs({ "FPS", "Session", "Ping" }) do
		local t = Box(stats, { Size = UDim2.new(1 / 3, -6, 1, 0), Position = UDim2.new((i - 1) / 3, (i - 1) * 3, 0, 0) }, "Card", 8)
		Lbl(t, { Text = n, Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 14), TextSize = 11, Font = FONT.Reg, Tr = true }, "Sub")
		vals[i] = Lbl(t, { Position = UDim2.new(0, 10, 0, 21), Size = UDim2.new(1, -20, 0, 22), TextSize = 16, Font = FONT.Bold, RichText = true, TextTruncate = Enum.TextTruncate.AtEnd }, "Text")
	end

	local btns = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Touch and 40 or 34), LayoutOrder = 3 }, card)
	local function button(i, ico, text, fn)
		local b = Box(btns, { Size = UDim2.new(1 / 3, -6, 1, 0), Position = UDim2.new((i - 1) / 3, (i - 1) * 3, 0, 0) }, "Card", 8, "Border")
		local inner = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, b)
		List(inner, 5, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
		local ic = MakeIcon(inner, ico, 14, "Accent")
		if ic then ic.LayoutOrder = 1 end
		Lbl(inner, { Text = text, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, TextSize = 12, Font = FONT.Med, LayoutOrder = 2, Tr = true }, "Text")
		local hit = Hit(b, 3)
		Hover(hit, b, "Card", "Hover")
		Tap(hit, fn)
	end
	button(1, "copy", "Copy Job ID", function()
		if game.JobId == "" then
			MX:Warning("Job ID", "Not available in Studio", 2)
		elseif Copy(game.JobId) then
			MX:Success("Copied", "Job ID " .. game.JobId, 2)
		else
			MX:Error("Copy failed", "Clipboard is not supported", 3)
		end
	end)
	button(2, "refresh-cw", "Rejoin", function() MX:Rejoin() end)
	button(3, "shuffle", "Server Hop", function() MX:ServerHop() end)

	local function refresh()
		vals[1].Text = string.format('<font color="%s">%d</font>', Hex(FpsColor(FpsNow)), FpsNow)
		local t = math.floor(time())
		vals[2].Text = string.format("%02d:%02d:%02d", math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
		local p = PingNow()
		vals[3].Text = string.format('<font color="%s">%d ms</font>', Hex(PingColor(p)), p)
	end
	refresh()
	task.spawn(function()
		while card.Parent and not MX.Dead do
			task.wait(0.5)
			refresh()
		end
	end)

	local obj = {}
	function obj:SetVisible(v) card.Visible = v end
	self:_Reg(o.Title or "Game", card)
	MX._Depend(card, o)
	return obj
end

function MX:EnsureWatermark(title)
	if MX.Watermark then return MX.Watermark end
	local w = MX:CreateWatermark({ Title = title or (MX.Window and MX.Window.TitleText) or "MX HUB" })
	w:AddFPS()
	w:AddPing()
	w:AddTime()
	return w
end

function MX:EnsureKeyList()
	if MX.KeyList then return MX.KeyList end
	return MX:CreateKeybindList({ Visible = false })
end

function Window:_BuildHome(h)
	h = type(h) == "table" and h or {}
	if h.Category ~= false then self:AddCategory(h.Category or "Dashboard") end
	local tab = self:AddTab({ Title = h.Title or "Home", Icon = h.Icon or "home" })
	self.HomeTab = tab

	local banner = tab:AddSection({ NoHeader = true, Side = "Full" })
	banner:AddImage({ Height = h.ImageHeight or 110, Image = h.Image or MX.WelcomeImage })

	local gc = tab:AddSection({ NoHeader = true, Side = "Full" })
	gc:AddGameCard({ Title = h.GameTitle, Image = h.GameImage })
	return tab
end

function Window:AddSettingsTab(o)
	if self._settingsTab then return self._settingsTab end
	o = o or {}
	self._miscName = o.Category or "Misc"
	self._miscHolder = self:AddCategory(self._miscName, 999999)
	local tab = self:AddTab({ Title = o.Title or "Settings", Icon = "settings", NoAutoSelect = true })
	tab.Btn.LayoutOrder = 1000000
	local theme = tab:AddSection({ Title = "Theme", Icon = "palette", Side = "Left" })
	theme:AddDropdown({ Title = "Preset", Flag = "theme", Values = MX.ThemeOrder, Default = MX.ThemeName, Callback = function(n) MX:SetTheme(n) end })
	theme:AddColorPicker({ Title = "Accent", Flag = "accent", Default = MX.Theme.Accent, NoRainbow = true, Callback = function(c) MX:SetAccent(c) end })
	theme:AddDropdown({ Title = "Effect", Flag = "effect", Values = MX.EffectList, Default = self:GetEffect(), Search = false, Callback = function(n) self:SetEffect(n) end })
	local nameT = theme:AddTextbox({ Title = "Theme Name", Placeholder = "theme name", Flag = "_theme_name" })
	local custom
	theme:AddButton({ Title = "Create Theme", Callback = function()
		local n = MX:CreateTheme(nameT:Get())
		if n then
			nameT:Set("", true)
			MX:Notify({ Type = "Success", Title = "Theme", Content = n, Duration = 2 })
			if custom then custom:Set(n, true) end
		else
			MX:Notify({ Type = "Warning", Title = "Theme", Content = "Theme Name", Duration = 2 })
		end
	end })
	custom = theme:AddDropdown({ Title = "Custom Themes", Values = MX:GetCustomThemes(), Placeholder = "no themes", Flag = "_theme_custom", Callback = function(n) MX:SetTheme(n) end })
	theme:AddButton({ Title = "Delete Theme", Hold = 1, Callback = function()
		local n = custom:Get()
		if n then MX:DeleteTheme(n) end
	end })
	table.insert(MX.CustomListeners, function() custom:Refresh(MX:GetCustomThemes()) end)
	local cfg = tab:AddSection({ Title = "Configs", Icon = "folder", Side = "Right" })
	cfg:AddConfigManager()
	self._settingsTab = tab
	return tab
end


MX.WindowClass = Window
MX.ContainerClass = Container
return MX
