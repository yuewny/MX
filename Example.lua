getgenv().MX_NOTIFY_URL = "https://raw.githubusercontent.com/yuewny/MX/main/Notify.lua"
local MX = loadstring(game:HttpGet("https://raw.githubusercontent.com/yuewny/MX/main/Source.lua"))()

local C = Color3.fromRGB
MX:AddThemes({
	Doir = { Window = C(10, 8, 9), Side = C(5, 4, 5), Panel = C(8, 6, 7), Card = C(14, 10, 12), Element = C(23, 17, 20), Hover = C(36, 26, 31), Border = C(104, 97, 101), Accent = C(4, 0, 255), Text = C(250, 240, 245), Sub = C(150, 125, 136), Off = C(44, 32, 38) },
	Gecko = { Window = C(25, 27, 28), Side = C(19, 21, 21), Panel = C(30, 32, 33), Card = C(36, 39, 40), Element = C(48, 52, 53), Hover = C(62, 67, 68), Border = C(115, 118, 119), Accent = C(203, 244, 85), Text = C(245, 246, 247), Sub = C(139, 170, 179), Off = C(70, 72, 73), OnAccent = C(24, 29, 12) },
})

MX:AddTranslations("Indonesia", {
	["Labels and Progress"] = "Label dan Progres", ["Notifications"] = "Notifikasi",
	["Run Progress"] = "Jalankan Progres", ["Elements"] = "Elemen", ["Locked Toggle"] = "Toggle Terkunci",
})

MX:SetChangelog({
	{ Version = "1.2", Date = "21 Nov 2026", Title = "Big update", Entries = {
		{ "Auto Farm tab", "up", "Farm 1-3 with delay sliders" },
		{ "Fly", "up" },
		{ "Noclip", "up" },
		{ "Old teleport menu", "down" },
		{ "Slider tap on mobile", "fix" },
	} },
	{ Version = "1.1", Date = "10 Nov 2026", Entries = { Fly = "up", ["Speed hack"] = "down" } },
	{ Version = "1.0", Date = "01 Nov 2026", Entries = { "+ First release", "+ Config system" } },
})

local function demo(title, text)
	MX:Info(title, text or "Example only, nothing happens.", 2)
end

local Window = MX:CreateWindow({
	Title = "MX HUB",
	SubTitle = "MX UI v" .. MX.Version,
	Size = Vector2.new(720, 460),
	TabWidth = 170,
	Theme = "Obsidian",
	MobileButton = "Auto",
	Effect = "Stars",
	Home = true,
	Settings = true,
})

Window:AddCategory("Features")
local Elements = Window:AddTab({ Title = "Elements", Icon = "sliders-horizontal", Badge = "NEW" })
local AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "zap" })

local FarmBox = AutoFarm:AddGroupbox({ Title = "Farm", Icon = "play", Side = "Left" })
for i = 1, 3 do
	FarmBox:AddToggle({ Title = "Farm " .. i, Description = "Auto farm area " .. i, Flag = "farm" .. i, Callback = function(v) demo("Farm " .. i, tostring(v)) end })
	FarmBox:AddSlider({ Title = "Delay", Flag = "farm" .. i .. "_delay", Min = 0, Max = 5, Default = 0.5, Increment = 0.1, Suffix = "s", Depends = "farm" .. i })
	if i < 3 then FarmBox:AddDivider() end
end

local UtilBox = AutoFarm:AddGroupbox({ Title = "Utility", Icon = "wrench", Side = "Right" })
UtilBox:AddToggle({ Title = "Fly", Flag = "util_fly", Keybind = Enum.KeyCode.F, KeyMode = "Toggle", Callback = function(v) demo("Fly", tostring(v)) end })
UtilBox:AddSlider({ Title = "Fly Speed", Flag = "util_fly_speed", Min = 10, Max = 200, Default = 50, Depends = "util_fly" })
UtilBox:AddToggle({ Title = "Noclip", Flag = "util_noclip", Callback = function(v) demo("Noclip", tostring(v)) end })
UtilBox:AddToggle({ Title = "Infinite Jump", Flag = "util_infjump", Callback = function(v) demo("Infinite Jump", tostring(v)) end })
UtilBox:AddDropdown({ Title = "Skill Check Mode", Flag = "util_skill", Values = { "Legit", "Rage", "Perfect" }, Default = "Legit" })
UtilBox:AddToggle({ Title = "Auto Stomp Pumpkins (Generators)", Flag = "util_pumpkin", Callback = function(v) demo("Pumpkins", tostring(v)) end })
UtilBox:AddToggle({ Title = "Anti AFK", Flag = "util_afk", Default = true })
UtilBox:AddSlider({ Title = "WalkSpeed", Flag = "util_ws", Min = 16, Max = 120, Default = 16, Toggle = true, ToggleFlag = "util_ws_on" })

Window:AddCategory("Misc")

local Info = Elements:AddSection({ Title = "Labels and Progress", Icon = "activity" })
local Status = Info:AddLabel("Status: Idle")
local Bar = Info:AddProgress({ Title = "Progress", Default = 20 })
Info:AddButton({ Title = "Run Progress", Description = "Shows a spinner while it runs", Callback = function()
	for i = 0, 100, 5 do
		Bar:Set(i)
		Status:Set("Status: " .. i .. "%")
		task.wait(0.05)
	end
	MX:Success("Done", "Progress finished.")
end })

local Notes = Elements:AddSection({ Title = "Notifications", Icon = "bell", Collapsible = true })
Notes:AddButton({ Title = "Info", Callback = function() MX:Info("Info", "An info notification.") end })
Notes:AddButton({ Title = "Success", Callback = function() MX:Success("Saved", "Your settings were saved.") end })
Notes:AddButton({ Title = "Warning", Callback = function() MX:Warning("Careful", "Connection looks unstable.") end })
Notes:AddButton({ Title = "Error", Callback = function() MX:Error("Failed", "Could not reach the server.") end })
Notes:AddButton({ Title = "With Buttons", Callback = function()
	MX:Notify({ Type = "Info", Title = "Friend Request", Content = "Someone wants to add you.", Duration = 8, Buttons = {
		{ Text = "Accept", Primary = true, Callback = function() MX:Success("Accepted", "You are now friends.") end },
		{ Text = "Decline" },
	} })
end })

local Basic = Elements:AddSection({ Title = "Basic Toggles", Icon = "toggle-right" })
Basic:AddToggle("Simple Toggle", false, function(v) demo("Simple Toggle", tostring(v)) end)
Basic:AddToggle({ Title = "Checkbox Toggle", Description = "Tap anywhere on the row", Flag = "basic_check", Style = "Checkbox", Default = true, Callback = function(v) demo("Checkbox", tostring(v)) end })
Basic:AddToggle({ Title = "Switch Toggle", Flag = "basic_switch", Style = "Switch", Callback = function(v) demo("Switch", tostring(v)) end })

local Extras = Elements:AddSection({ Title = "Toggle Extras", Icon = "settings" })
Extras:AddToggle({ Title = "Boxes", Description = "Toggle with a color swatch", Flag = "boxes", Color = { Flag = "boxes_color", Default = C(255, 120, 170) } })
Extras:AddToggle({ Title = "Chams", Description = "Keybind and color together", Flag = "chams", Keybind = Enum.KeyCode.C, KeyMode = "Toggle", Color = { Flag = "chams_color", Default = C(96, 205, 255) } })
Extras:AddToggle({ Title = "Fly", Description = "Toggle mode, press X. Tap it in the keybind list on mobile", Flag = "fly", Keybind = Enum.KeyCode.X, KeyMode = "Toggle" })
Extras:AddToggle({ Title = "Sprint", Description = "Hold mode", Flag = "sprint", Keybind = Enum.KeyCode.LeftShift, KeyMode = "Hold" })

local Sl = Elements:AddSection({ Title = "Sliders and Inputs", Icon = "sliders-horizontal" })
Sl:AddSlider({ Title = "Basic Slider", Flag = "sl1", Min = 0, Max = 100, Default = 50 })
Sl:AddSlider({ Title = "WalkSpeed", Flag = "ws", Min = 16, Max = 120, Default = 16, Toggle = true, ToggleFlag = "ws_on", ToggleCallback = function(v) demo("WalkSpeed", tostring(v)) end })
Sl:AddNumberInput({ Title = "Amount", Flag = "amount", Min = 0, Max = 500, Default = 25, Increment = 5, Suffix = " pcs" })
Sl:AddTextbox({ Title = "Textbox", Flag = "text", Placeholder = "Type something", Callback = function(t, enter) if enter then demo("Textbox", t) end end })

local Dr = Elements:AddSection({ Title = "Dropdowns", Icon = "list" })
Dr:AddDropdown({ Title = "Dropdown", Flag = "drop", Values = { "One", "Two", "Three" }, Default = "One" })
Dr:AddMultiSelect({ Title = "Targets", Flag = "targets", Values = { "Players", "NPCs", "Items", "Chests", "Bosses", "Pets", "Vehicles", "Portals" }, Default = { "Players" } })
Dr:AddDropdown({ Title = "With Search", Flag = "drop2", Values = { "Frankfurt", "Amsterdam", "London", "Paris", "Madrid", "Warsaw", "Stockholm", "Tokyo", "Jakarta" }, Default = "Jakarta" })
Dr:AddMultiSelect({ Title = "Multi Select", Flag = "multi", Values = { "Red", "Green", "Blue", "Yellow" }, Default = { "Red" } })
Dr:AddColorPicker({ Title = "Color Picker", Flag = "color", Default = C(255, 120, 170), DefaultAlpha = 1 })
Dr:AddKeybind({ Title = "Teleport", Flag = "tp", Default = Enum.KeyCode.V, Mode = "Press", Callback = function() demo("Teleport", "Key pressed") end })

local States = Elements:AddSection({ Title = "Hold, Locked, Loading", Icon = "lock" })
States:AddButton({ Title = "Hold To Reset", Hold = 1.5, Callback = function() MX:Success("Confirmed", "Reset.") end })
States:AddToggle({ Title = "Locked Toggle", Locked = true, LockedReason = "Premium only" })
States:AddButton({ Title = "Failing Callback", Description = "Flashes red", Callback = function() error("Something went wrong") end })
States:AddButton({ Title = "Dialog", Callback = function()
	Window:Dialog({ Title = "Are You Sure?", Content = "Only an example dialog.", Buttons = { { Title = "Confirm", Primary = true, Callback = function() MX:Success("Confirmed", "OK") end }, { Title = "Cancel" } } })
end })
States:AddButton({ Title = "Open Info Window", Callback = function()
	MX:AddWindow({ Title = "Server", Icon = "info", Width = 300, Height = 200, DestroyOnClose = true,
		Content = { "[green]Connected[/] as [b]{user}[/]", "FPS {fps}  Ping {ping}  Players {players}/{maxplayers}" },
		Rows = { { "Place", "{placeid}" }, { "Time", "{time}" } } })
end })

local Tabs = Elements:AddSection({ Title = "Inner Tabs", Icon = "layers", Side = "Full" })
local Inner = Tabs:AddTabs({ "First", "Second" })
Inner.Pages.First:AddToggle({ Title = "Toggle On First", Flag = "inner_t" })
Inner.Pages.Second:AddButton({ Title = "Back To First", Callback = function() Inner:Select("First") end })

local Show = Window:AddTab({ Title = "Showcase", Icon = "layers" })

local Pics = Show:AddSection({ Title = "Images", Icon = "layers" })
Pics:AddPicture({ Title = "Game Icon", Description = "Icon of the current game", Image = { Game = true }, Size = 64 })
Pics:AddPicture({ Title = "Your Avatar", Description = "Headshot", Image = { Avatar = true, Type = "Head" }, Size = 64, Shape = "Circle" })
Pics:AddPicture({ Title = "Decal ID", Description = "Any decal or image ID", Image = { Decal = 113267102798729 }, Size = 64 })
Pics:AddPicture({ Image = 113267102798729, Size = 96 })

local InnerBox = Show:AddSection({ Title = "Inner Tabs", Icon = "layers", Side = "Full" })
local Inner = InnerBox:AddTabs({ "Combat", "Visuals", "Misc" })
local Combat = Inner.Pages.Combat
Combat:AddToggle({ Title = "Aimbot", Flag = "inner_aim", Callback = function(v) demo("Aimbot", tostring(v)) end })
Combat:AddToggle({ Title = "Silent Aim", Flag = "inner_silent" })
Combat:AddSlider({ Title = "FOV", Flag = "inner_fov", Min = 10, Max = 360, Default = 90, Depends = "inner_aim" })
Combat:AddDropdown({ Title = "Target Part", Flag = "inner_part", Values = { "Head", "Torso", "Random" }, Default = "Head" })
Combat:AddKeybind({ Title = "Aim Key", Flag = "inner_key", Default = Enum.KeyCode.E, Mode = "Hold" })
local Visuals = Inner.Pages.Visuals
Visuals:AddToggle({ Title = "ESP", Flag = "inner_esp", Color = { Flag = "inner_esp_color", Default = C(255, 80, 80) } })
Visuals:AddMultiSelect({ Title = "ESP Targets", Flag = "inner_targets", Values = { "Players", "NPCs", "Items", "Chests" }, Default = { "Players" }, Depends = "inner_esp" })
Visuals:AddSlider({ Title = "Transparency", Flag = "inner_trans", Min = 0, Max = 100, Default = 40, Suffix = "%", Depends = "inner_esp" })
Visuals:AddColorPicker({ Title = "Accent Color", Flag = "inner_accent", Default = C(96, 205, 255) })
local Misc = Inner.Pages.Misc
Misc:AddTextbox({ Title = "Webhook", Flag = "inner_hook", Placeholder = "https://..." })
Misc:AddNumberInput({ Title = "Delay", Flag = "inner_delay", Min = 0, Max = 100, Default = 5, Increment = 1, Suffix = " s" })
Misc:AddButton({ Title = "Show Changelog", Callback = function() Window:OpenChangelog() end })
Misc:AddButton({ Title = "Switch To Combat", Callback = function() Inner:Select("Combat") end })

local Stats = Show:AddSection({ Title = "Live Stats", Icon = "activity" })
Stats:AddStat({ Title = "Players", Icon = "activity", Interval = 2, Value = function()
	local p = game:GetService("Players")
	return #p:GetPlayers() .. " / " .. p.MaxPlayers
end })
Stats:AddStat({ Title = "Server Time", Color = "Accent", Interval = 1, Value = function() return os.date("%H:%M:%S") end })
Stats:AddBanner({ Type = "Success", Title = "Version 1.0", Lines = { "[green]+[/] New elements", "[accent]~[/] Smoother UI" }, Dismissible = true })

local Dep = Show:AddSection({ Title = "Dependencies", Icon = "lock" })
Dep:AddToggle({ Title = "Enable Feature", Flag = "dep_on" })
Dep:AddSlider({ Title = "Range", Flag = "dep_range", Min = 10, Max = 360, Default = 90, Depends = "dep_on" })
Dep:AddDropdown({ Title = "Target", Flag = "dep_target", Values = { "Head", "Torso" }, Default = "Head", Depends = "dep_on" })
Dep:AddDivider("Players")
Dep:AddPlayerDropdown({ Title = "Player", Flag = "dep_player" })
Dep:AddLabel("[b]Rich[/] label with [accent]colors[/]")
Dep:AddLabel("Plain colored label", "Success")

local Grp = Show:AddSection({ Title = "Groupbox", Icon = "layers" })
local Combat = Grp:AddGroupbox({ Title = "Combat" })
Combat:AddToggle("Auto Attack", false, function(v) demo("Auto Attack", tostring(v)) end)
Combat:AddSlider({ Title = "Range", Min = 1, Max = 50, Default = 10 })

MX:LoadAutoConfig()
MX:Info("MX HUB", "Loaded. Tap the MX button or press INSERT.")
