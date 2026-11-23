local env = getgenv and getgenv() or _G
local source = env.MX_SOURCE
if not source and isfile and isfile("Source.lua") then source = readfile("Source.lua") end
if not source then source = game:HttpGet(env.MX_SOURCE_URL or "https://raw.githubusercontent.com/yuewny/MX/main/Source.lua") end
assert(source, "Could not load Source.lua")
local MX = loadstring(source)()

local results = {}
local function check(name, fn)
	local ok, err = pcall(fn)
	if ok and err == "skip" then
		results[#results + 1] = { name = name, status = "SKIP" }
	elseif ok then
		results[#results + 1] = { name = name, status = "PASS" }
	else
		results[#results + 1] = { name = name, status = "FAIL", err = tostring(err) }
	end
end
local function eq(a, b, msg)
	if a ~= b then error((msg or "expected equal") .. ": got " .. tostring(a) .. ", wanted " .. tostring(b), 2) end
end
local function near(a, b, tol, msg)
	if math.abs(a - b) > (tol or 0.01) then error((msg or "expected near") .. ": got " .. tostring(a) .. ", wanted " .. tostring(b), 2) end
end

local Window = MX:CreateWindow({ Title = "MX Self Test", Size = Vector2.new(720, 460), Theme = "Obsidian", MobileButton = "Auto" })
local Tab = Window:AddTab({ Title = "Elements", Icon = "list" })
local Sec = Tab:AddSection({ Title = "Test Elements", Icon = "list", Side = "Left" })

check("library: core API is present", function()
	for _, name in ipairs({ "CreateWindow", "Notify", "SetTheme", "SaveConfig", "LoadConfig", "SetChangelog", "AddChangelog", "SetIgnoreFlags", "ResolveImage", "AddThemes", "SetLocked" }) do
		eq(type(MX[name]), "function", "MX." .. name)
	end
end)

check("window: built-in Home and Settings tabs", function()
	assert(Window.HomeTab, "Home tab missing")
	assert(Window._settingsTab, "Settings tab missing")
	eq(Window.Tabs[1], Window.HomeTab, "Home is first")
	eq(Window.Tabs[#Window.Tabs], Window._settingsTab, "Settings is last")
	assert(Window.Gear and Window.Gear.wm, "quick settings toggles missing")
end)

check("watermark and keybind list exist and can be shown", function()
	assert(MX.Watermark and MX.Watermark.Frame, "watermark missing")
	assert(MX.KeyList and MX.KeyList.Frame, "keybind list missing")
	MX.Watermark:SetVisible(true)
	eq(MX.Watermark.Frame.Visible, true, "watermark visible")
	MX.Watermark:SetVisible(false)
	eq(MX.Watermark.Frame.Visible, false, "watermark hidden")
	MX.KeyList:SetVisible(true)
	task.wait(0.5)
	eq(MX.KeyList.Frame.Visible, true, "keybind list visible even without binds")
	MX.KeyList:SetVisible(false)
	eq(MX.KeyList.Frame.Visible, false, "keybind list hidden")
	local gear = Window.Gear
	gear.wm:Set(false)
	gear.wm:Set(true)
	task.wait(0.2)
	eq(MX.Watermark.Frame.Visible, true, "gear watermark toggle")
	gear.kl:Set(false)
	gear.kl:Set(true)
	task.wait(0.5)
	eq(MX.KeyList.Frame.Visible, true, "gear keybind toggle")
end)

check("toggle: set, get, callback, serialize", function()
	local fired
	local t = Sec:AddToggle({ Title = "Toggle", Flag = "st_toggle", Callback = function(v) fired = v end })
	t:Set(true)
	eq(t.Value, true)
	eq(MX.Flags.st_toggle, true, "flag")
	task.wait(0.15)
	eq(fired, true, "callback")
	t:Set(false)
	eq(t.Value, false)
	t:Deserialize(true)
	eq(t:Serialize(), true)
	t:Toggle()
	eq(t.Value, false)
end)

check("toggle: positional form", function()
	local hit
	local t = Sec:AddToggle("Positional", true, function(v) hit = v end)
	eq(t.Value, true)
	t:Set(false)
	task.wait(0.15)
	eq(hit, false)
end)

check("toggle: tap on the row (firesignal)", function()
	if type(firesignal) ~= "function" then return "skip" end
	local t = Sec:AddToggle({ Title = "Tap Row", Flag = "st_tap" })
	local hit
	for _, c in ipairs(t.Row:GetChildren()) do
		if c:IsA("TextButton") and c.ZIndex == 2 then hit = c end
	end
	assert(hit, "row hit button not found")
	firesignal(hit.Activated)
	task.wait(0.2)
	eq(t.Value, true)
	task.wait(0.2)
	firesignal(hit.Activated)
	task.wait(0.2)
	eq(t.Value, false)
end)

check("slider: clamp and increment", function()
	local s = Sec:AddSlider({ Title = "Slider", Flag = "st_slider", Min = 0, Max = 100, Default = 10, Increment = 5 })
	eq(s.Value, 10)
	s:Set(52)
	eq(s.Value, 50)
	s:Set(500)
	eq(s.Value, 100)
	s:Set(-5)
	eq(s.Value, 0)
	s:Deserialize(35)
	eq(s.Value, 35)
end)

check("number input: clamp", function()
	local n = Sec:AddNumberInput({ Title = "Number", Flag = "st_number", Min = 0, Max = 50, Default = 5, Increment = 1 })
	n:Set(7)
	eq(n.Value, 7)
	n:Set(1000)
	eq(n.Value, 50)
end)

check("dropdown: set, refresh keeps valid choice", function()
	local d = Sec:AddDropdown({ Title = "Dropdown", Flag = "st_drop", Values = { "A", "B", "C" }, Default = "A" })
	eq(d.Value, "A")
	d:Set("B")
	eq(d.Value, "B")
	d:Refresh({ "B", "Z" })
	eq(d.Value, "B", "kept after refresh")
	d:Refresh({ "X" })
	eq(d.Value, nil, "cleared when missing")
end)

check("multiselect: set and refresh", function()
	local m = Sec:AddMultiSelect({ Title = "Multi", Flag = "st_multi", Values = { "A", "B", "C" }, Default = { "A" } })
	m:Set({ "A", "B" })
	eq(#m.Value, 2)
	m:Refresh({ "A" })
	eq(#m.Value, 1)
	eq(m.Value[1], "A")
end)

check("textbox: set", function()
	local tb = Sec:AddTextbox({ Title = "Textbox", Flag = "st_text", Placeholder = "..." })
	tb:Set("hello")
	eq(tb.Value, "hello")
end)

check("color picker: set and round trip", function()
	local cp = Sec:AddColorPicker({ Title = "Color", Flag = "st_color", Default = Color3.fromRGB(10, 20, 30) })
	cp:Set(Color3.fromRGB(200, 100, 50))
	local c = cp:Get()
	near(c.R, 200 / 255, 0.01, "R")
	near(c.G, 100 / 255, 0.01, "G")
	near(c.B, 50 / 255, 0.01, "B")
	local data = cp:Serialize()
	cp:Set(Color3.fromRGB(0, 0, 0))
	cp:Deserialize(data)
	near(cp:Get().R, 200 / 255, 0.01, "R after load")
	cp:SetRainbow(true)
	task.wait(0.2)
	cp:SetRainbow(false)
end)

check("keybind: default and round trip", function()
	local kb = Sec:AddKeybind({ Title = "Keybind", Flag = "st_key", Default = Enum.KeyCode.R })
	eq(kb.Key, Enum.KeyCode.R)
	local data = kb:Serialize()
	kb:Deserialize(data)
	eq(kb.Key, Enum.KeyCode.R)
end)

check("progress: set", function()
	local p = Sec:AddProgress({ Title = "Progress", Default = 10 })
	p:Set(50)
	eq(p.Value, 50)
end)

check("button: creates and accepts positional form", function()
	Sec:AddButton({ Title = "Button", Callback = function() end })
	Sec:AddButton("Positional Button", function() end)
end)

check("label, paragraph, divider, copy field", function()
	local l = Sec:AddLabel("[b]Rich[/] label [accent]colors[/]")
	l:Set("[green]changed[/]")
	Sec:AddLabel("Plain colored", "Success")
	Sec:AddParagraph({ Title = "Paragraph", Content = "Text" })
	Sec:AddDivider()
	Sec:AddDivider("Titled")
	Sec:AddCopyField({ Title = "Copy", Value = "value" })
end)

check("stat, banner, picture", function()
	local n = 0
	local st = Sec:AddStat({ Title = "Stat", Interval = 0.25, Value = function() n += 1 return "tick " .. n end })
	task.wait(0.7)
	assert(n >= 2, "stat did not refresh")
	st:Set("manual")
	eq(st:Get(), "manual")
	local b = Sec:AddBanner({ Type = "Warning", Title = "Banner", Lines = { "[green]+[/] one", "two" }, Dismissible = true })
	b:SetContent("changed")
	b:SetTitle("Changed")
	local pic = Sec:AddPicture({ Title = "Picture", Description = "d", Image = { Game = true }, Size = 48, Shape = "Circle" })
	pic:SetImage({ Avatar = true })
	pic:Set("New title", "New description")
end)

check("image: ResolveImage sources", function()
	eq(MX:ResolveImage(123), "rbxassetid://123")
	assert(MX:ResolveImage({ Avatar = true }):find("type=AvatarHeadShot", 1, true), "avatar")
	assert(MX:ResolveImage({ Asset = 5 }):find("type=Asset", 1, true), "asset")
	assert(MX:ResolveImage({ Game = true }):find("type=GameIcon", 1, true), "game")
	assert(MX:ResolveImage({ Group = 1 }):find("type=GroupIcon", 1, true), "group")
	local d = Instance.new("Decal")
	d.Texture = "rbxassetid://77"
	eq(MX:ResolveImage(d), "rbxassetid://77")
end)

check("depends: row follows another flag", function()
	local a = Sec:AddToggle({ Title = "Dep Source", Flag = "st_dep_a" })
	local b = Sec:AddSlider({ Title = "Dep Target", Flag = "st_dep_b", Min = 0, Max = 10, Depends = "st_dep_a" })
	task.wait(0.35)
	eq(b.Row.Visible, false, "hidden while off")
	a:Set(true)
	task.wait(0.35)
	eq(b.Row.Visible, true, "visible while on")
end)

check("groupbox and inner tabs", function()
	local g = Sec:AddGroupbox({ Title = "Group" })
	g:AddToggle("In group", false)
	local tabs = Sec:AddTabs({ "One", "Two" })
	tabs.Pages.One:AddToggle("In tab one", false)
	tabs.Pages.Two:AddButton("In tab two", function() end)
	tabs:Select("Two")
	eq(tabs.Current, "Two")
	tabs:Select("One")
	eq(tabs.Current, "One")
end)

check("player dropdown", function()
	local pd = Sec:AddPlayerDropdown({ Title = "Player", Flag = "st_player", IncludeSelf = true })
	assert(#pd.Values >= 1, "no players listed")
	pd:Set(game:GetService("Players").LocalPlayer.Name)
	eq(pd:GetPlayer(), game:GetService("Players").LocalPlayer)
end)

check("config: save and load round trip", function()
	if not (writefile and isfile and readfile) then return "skip" end
	local t = Sec:AddToggle({ Title = "Cfg Toggle", Flag = "st_cfg_t" })
	local s = Sec:AddSlider({ Title = "Cfg Slider", Flag = "st_cfg_s", Min = 0, Max = 100, Default = 0 })
	t:Set(true)
	s:Set(30)
	assert(MX:SaveConfig("__mx_selftest__"), "save failed")
	t:Set(false)
	s:Set(80)
	assert(MX:LoadConfig("__mx_selftest__"), "load failed")
	task.wait(0.3)
	eq(t.Value, true)
	eq(s.Value, 30)
	MX:DeleteConfig("__mx_selftest__")
end)

check("config: values for elements created later are kept", function()
	MX._pending.st_late = true
	local late = Sec:AddToggle({ Title = "Late", Flag = "st_late" })
	task.wait(0.3)
	eq(late.Value, true)
	MX._pending.st_ghost = 5
	eq(MX:_Collect().st_ghost, 5, "pending is saved back")
end)

check("config: ignored flags are not saved", function()
	MX:SetIgnoreFlags({ "st_ignored" })
	local t = Sec:AddToggle({ Title = "Ignored", Flag = "st_ignored" })
	t:Set(true)
	eq(MX:_Collect().st_ignored, nil)
end)

check("config: window geometry serializes", function()
	local g = MX.Options.window_geometry
	assert(g, "missing")
	local data = g:Serialize()
	eq(type(data.x), "number")
	eq(type(data.w), "number")
	g:Deserialize(data)
end)

check("themes: every theme applies with all tokens", function()
	local keep = MX.ThemeName
	local need = { "Window", "Side", "Panel", "Card", "Element", "Hover", "Border", "Accent", "Text", "Sub", "Off", "OnAccent", "Success", "Warning", "Danger" }
	for _, name in ipairs(MX.ThemeOrder) do
		MX:SetTheme(name, true)
		for _, k in ipairs(need) do
			eq(typeof(MX.Theme[k]), "Color3", name .. "." .. k)
		end
	end
	MX:SetTheme(keep, true)
end)

check("themes: incomplete custom theme is completed", function()
	local keep = MX.ThemeName
	MX:AddThemes({ __Partial = { Accent = Color3.new(1, 0, 0), Text = Color3.new(1, 1, 1), Card = Color3.fromRGB(25, 25, 30) } })
	MX:SetTheme("__Partial", true)
	eq(typeof(MX.Theme.Hover), "Color3")
	eq(typeof(MX.Theme.Window), "Color3")
	MX:SetTheme(keep, true)
end)

check("notifications: module loads from URL and shows banners", function()
	local t0 = os.clock()
	while not MX._notify and not MX._notifyFailed and os.clock() - t0 < 10 do task.wait(0.1) end
	assert(MX._notify, "notify module did not load from " .. tostring(MX.NotifyUrl))
	for _, kind in ipairs({ "Info", "Success", "Warning", "Error" }) do
		local h = MX:Notify({ Type = kind, Title = kind, Content = "test", Duration = 1 })
		eq(type(h.Dismiss), "function")
	end
	for i = 1, 8 do MX:Notify({ Type = "Info", Title = "Burst " .. i, Duration = 2 }) end
	task.wait(0.5)
	assert(MX._notify:ActiveCount() <= MX._notify.Config.MaxVisible, "too many banners: " .. MX._notify:ActiveCount())
	local h = MX:Notify({ Type = "Info", Title = "Update me", Duration = 0 })
	task.wait(0.2)
	h.Update({ Type = "Success", Title = "Updated" })
	h.Dismiss()
end)

check("callback errors are caught and reported", function()
	MX._lastErr = nil
	MX._Run(function() error("expected self-test error") end)
	task.wait(0.3)
	assert(MX._lastErr ~= nil, "error was not reported")
end)

check("dialog opens", function()
	Window:Dialog({ Title = "Dialog", Content = "test", Buttons = { { Title = "OK", Primary = true } } })
	local n = 0
	for _, c in ipairs(Window.Main:GetChildren()) do
		if c:IsA("TextButton") and c.ZIndex == 60 then
			n += 1
			c:Destroy()
		end
	end
	assert(n >= 1, "dialog overlay not found")
end)

check("changelog: parsing, window, close", function()
	local keep = MX.Changelog
	MX:SetChangelog({ { Version = "9.9", Date = "today", Title = "Test", Entries = {
		{ "Fly", "up" }, { "Noclip", "down" }, "~ Fix thing", { Speed = "up", Jump = "down" },
	} } })
	local e = MX.Changelog[1].Entries
	eq(#e, 5)
	eq(e[1].Kind, "Add")
	eq(e[2].Kind, "Remove")
	eq(e[3].Kind, "Fix")
	Window:OpenChangelog()
	assert(Window._cl and Window._cl.Parent, "panel missing")
	local foundVersion, foundStrike = false, false
	for _, d in ipairs(Window._cl:GetDescendants()) do
		if d:IsA("TextLabel") then
			if d.Text == "v9.9" then foundVersion = true end
			if d.Text == "<s>Noclip</s>" then foundStrike = true end
		end
	end
	assert(foundVersion, "version pill missing")
	assert(foundStrike, "removed entry is not struck through")
	Window:CloseChangelog()
	task.wait(0.3)
	eq(Window._cl, nil)
	MX:SetChangelog(keep)
end)

check("window: hide and show", function()
	Window:Toggle(false)
	task.wait(0.35)
	eq(Window.Main.Visible, false)
	Window:Toggle(true)
	task.wait(0.2)
	eq(Window.Main.Visible, true)
end)

check("window: scale changes gradually", function()
	Window:SetScale(1.2)
	task.wait(0.06)
	assert(MX.UserScale > 1 and MX.UserScale < 1.2, "jumped straight to " .. tostring(MX.UserScale))
	task.wait(1.6)
	near(MX.UserScale, 1.2, 0.01)
	Window:SetScale(1, true)
	eq(MX.UserScale, 1)
end)

check("effects: every effect starts", function()
	for _, name in ipairs(MX.EffectList) do
		Window:SetEffect(name)
		task.wait(0.1)
	end
	Window:SetEffect("None")
end)

local rt = Window:AddTab({ Title = "Results", Icon = "list-checks" })
local pass, fail, skip = 0, 0, 0
for _, r in ipairs(results) do
	if r.status == "PASS" then pass += 1 elseif r.status == "FAIL" then fail += 1 else skip += 1 end
end
local sum = rt:AddSection({ Title = "Summary", Icon = "list-checks", Side = "Left" })
sum:AddBanner({ Type = fail == 0 and "Success" or "Error", Title = fail == 0 and "All checks passed" or (fail .. " checks failed"), Content = pass .. " passed, " .. fail .. " failed, " .. skip .. " skipped" })
local list = rt:AddSection({ Title = "Checks", Icon = "list", Side = "Right" })
for _, r in ipairs(results) do
	local tag = r.status == "PASS" and "[green]PASS[/]" or (r.status == "FAIL" and "[red]FAIL[/]" or "[yellow]SKIP[/]")
	list:AddLabel(tag .. "  " .. r.name .. (r.err and ("\n" .. r.err) or ""))
end
print(("[MX self test] %d passed, %d failed, %d skipped"):format(pass, fail, skip))
for _, r in ipairs(results) do
	if r.status == "FAIL" then warn("[MX self test] FAIL " .. r.name .. ": " .. r.err) end
end
rt:Select()
MX:Notify({ Type = fail == 0 and "Success" or "Error", Title = "Self test", Content = pass .. " passed, " .. fail .. " failed, " .. skip .. " skipped", Duration = 6 })
