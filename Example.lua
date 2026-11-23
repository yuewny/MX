local MX = loadstring(game:HttpGet("https://raw.githubusercontent.com/yuewny/MX/main/Source.lua"))()

local C = Color3.fromRGB

MX:AddThemes({
	Doir = { Window = C(10, 8, 9), Side = C(5, 4, 5), Panel = C(8, 6, 7), Card = C(14, 10, 12), Element = C(23, 17, 20), Hover = C(36, 26, 31), Border = C(104, 97, 101), Accent = C(4, 0, 255), Text = C(250, 240, 245), Sub = C(150, 125, 136), Off = C(44, 32, 38) },
	Gecko = { Window = C(25, 27, 28), Side = C(19, 21, 21), Panel = C(30, 32, 33), Card = C(36, 39, 40), Element = C(48, 52, 53), Hover = C(62, 67, 68), Border = C(115, 118, 119), Accent = C(203, 244, 85), Text = C(245, 246, 247), Sub = C(139, 170, 179), Off = C(70, 72, 73), OnAccent = C(24, 29, 12) },
})

MX:AddTranslations("Indonesia", {
	["Notifications"] = "Notifikasi", ["Run Progress"] = "Jalankan Progres", ["Locked Toggle"] = "Toggle Terkunci",
})

MX:SetChangelog({
	{ Version = "1.2", Date = "21 Nov 2026", Title = "Big update", Entries = {
		{ "Auto Farm tab", "up", "Farm 1-3 with delay sliders" },
		{ "Fly", "up" },
		{ "Old teleport menu", "down" },
		{ "Slider tap on mobile", "fix" },
	} },
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

Window:AddCategory("Extras")
local Show = Window:AddTab({ Title = "Showcase", Icon = "layers" })

local Toggles = Elements:AddSection({ Title = "Toggles", Icon = "toggle-right" })
Toggles:AddToggle("Short Form", false, function(v) demo("Short Form", tostring(v)) end)
Toggles:AddToggle({ Title = "Checkbox", Description = "The default style. Tap anywhere on the row", Flag = "tg_check", Callback = function(v) demo("Checkbox", tostring(v)) end })
Toggles:AddToggle({ Title = "Starts On", Description = "Default = true runs the callback once on load", Flag = "tg_on", Default = true })
Toggles:AddToggle({ Title = "Switch", Description = "Style = \"Switch\" for a sliding knob", Flag = "tg_switch", Style = "Switch", Callback = function(v) demo("Switch", tostring(v)) end })
Toggles:AddToggle({ Title = "Locked", Locked = true, LockedReason = "Premium only" })

local Extras = Elements:AddSection({ Title = "Toggle Extras", Icon = "settings" })
Extras:AddToggle({ Title = "Boxes", Description = "With a color swatch", Flag = "ex_boxes", Color = { Flag = "ex_boxes_color", Default = C(255, 120, 170) } })
Extras:AddToggle({ Title = "Fly", Description = "Press X to toggle. Appears in the keybind list while on", Flag = "ex_fly", Keybind = Enum.KeyCode.X, KeyMode = "Toggle", Callback = function(v) demo("Fly", tostring(v)) end })
Extras:AddToggle({ Title = "Sprint", Description = "Hold LeftShift", Flag = "ex_sprint", Keybind = Enum.KeyCode.LeftShift, KeyMode = "Hold" })
Extras:AddToggle({ Title = "Chams", Description = "Keybind and color together", Flag = "ex_chams", Keybind = Enum.KeyCode.C, KeyMode = "Toggle", Color = { Flag = "ex_chams_color", Default = C(96, 205, 255) } })

local Inputs = Elements:AddSection({ Title = "Sliders and Inputs", Icon = "sliders-horizontal" })
Inputs:AddSlider({ Title = "Slider", Flag = "in_slider", Min = 0, Max = 100, Default = 50 })
Inputs:AddSlider({ Title = "WalkSpeed", Description = "A slider with its own toggle", Flag = "in_ws", Min = 16, Max = 120, Default = 16, Toggle = true, ToggleFlag = "in_ws_on", ToggleCallback = function(v) demo("WalkSpeed", tostring(v)) end })
Inputs:AddNumberInput({ Title = "Number Input", Flag = "in_amount", Min = 0, Max = 500, Default = 25, Increment = 5, Suffix = " pcs" })
Inputs:AddTextbox({ Title = "Textbox", Flag = "in_text", Placeholder = "Type something", Callback = function(t, enter) if enter then demo("Textbox", t) end end })
Inputs:AddKeybind({ Title = "Teleport", Flag = "in_tp", Default = Enum.KeyCode.V, Mode = "Press", Callback = function() demo("Teleport", "Key pressed") end })
Inputs:AddColorPicker({ Title = "Color Picker", Flag = "in_color", Default = C(255, 120, 170), DefaultAlpha = 1 })

local Lists = Elements:AddSection({ Title = "Dropdowns", Icon = "list" })
Lists:AddDropdown({ Title = "Dropdown", Flag = "dd_one", Values = { "One", "Two", "Three" }, Default = "One" })
Lists:AddDropdown({ Title = "With Search", Flag = "dd_search", Values = { "Frankfurt", "Amsterdam", "London", "Paris", "Madrid", "Warsaw", "Stockholm", "Tokyo", "Jakarta" }, Default = "Jakarta", Search = true })
Lists:AddDropdown({ Title = "Multi Select", Description = "Multi = true", Flag = "dd_multi", Values = { "Players", "NPCs", "Items", "Chests", "Bosses", "Pets" }, Default = { "Players" }, Multi = true })
Lists:AddPlayerDropdown({ Title = "Player", Flag = "dd_player" })

local Buttons = Elements:AddSection({ Title = "Buttons and Dialogs", Icon = "mouse-pointer" })
Buttons:AddButton({ Title = "Button", Callback = function() demo("Button", "Clicked") end })
Buttons:AddButton({ Title = "Hold To Reset", Description = "Hold for 1.5 seconds", Hold = 1.5, Callback = function() MX:Success("Confirmed", "Reset.") end })
Buttons:AddButton({ Title = "Failing Callback", Description = "Flashes red", Callback = function() error("Something went wrong") end })
Buttons:AddButton({ Title = "Dialog", Callback = function()
	Window:Dialog({ Title = "Are You Sure?", Content = "Only an example dialog.", Buttons = { { Title = "Confirm", Primary = true, Callback = function() MX:Success("Confirmed", "OK") end }, { Title = "Cancel" } } })
end })
Buttons:AddButton({ Title = "Open Info Window", Callback = function()
	MX:AddWindow({ Title = "Server", Icon = "info", Width = 300, Height = 200, DestroyOnClose = true,
		Content = { "[green]Connected[/] as [b]{user}[/]", "FPS {fps}  Ping {ping}  Players {players}/{maxplayers}" },
		Rows = { { "Place", "{placeid}" }, { "Time", "{time}" } } })
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
UtilBox:AddToggle({ Title = "Anti AFK", Flag = "util_afk", Default = true })

local Text = Show:AddSection({ Title = "Text", Icon = "layers" })
Text:AddLabel("[b]Rich[/] label with [accent]colors[/]")
Text:AddLabel("Plain colored label", "Success")
Text:AddParagraph({ Title = "Paragraph", Content = "A title with a few lines of wrapped text underneath." })
Text:AddDivider("Divider")
Text:AddCopyField({ Title = "Discord", Description = "Copies the value", Value = "discord.gg/example" })
Text:AddBanner({ Type = "Success", Title = "Version 1.0", Lines = { "[green]+[/] New elements", "[accent]~[/] Smoother UI" }, Dismissible = true })

local Live = Show:AddSection({ Title = "Live Stats", Icon = "activity" })
Live:AddStat({ Title = "Players", Icon = "activity", Interval = 2, Value = function()
	local p = game:GetService("Players")
	return #p:GetPlayers() .. " / " .. p.MaxPlayers
end })
Live:AddStat({ Title = "Server Time", Color = "Accent", Interval = 1, Value = function() return os.date("%H:%M:%S") end })
local Status = Live:AddLabel("Status: Idle")
local Bar = Live:AddProgress({ Title = "Progress", Default = 20 })
Live:AddButton({ Title = "Run Progress", Description = "Shows a spinner while it runs", Callback = function()
	for i = 0, 100, 5 do
		Bar:Set(i)
		Status:Set("Status: " .. i .. "%")
		task.wait(0.05)
	end
	MX:Success("Done", "Progress finished.")
end })

local Media = Show:AddSection({ Title = "Images", Icon = "layers" })
Media:AddImage({ Title = "Cover Image", Description = "Image with a title on top", Height = 110, Image = { Game = true } })
Media:AddPicture({ Title = "Game Icon", Description = "Icon of the current game", Image = { Game = true }, Size = 64 })
Media:AddPicture({ Title = "Your Avatar", Description = "Headshot", Image = { Avatar = true, Type = "Head" }, Size = 64, Shape = "Circle" })

local Logic = Show:AddSection({ Title = "Depends and Groupbox", Icon = "lock" })
Logic:AddToggle({ Title = "Enable Feature", Flag = "dep_on" })
Logic:AddSlider({ Title = "Range", Flag = "dep_range", Min = 10, Max = 360, Default = 90, Depends = "dep_on" })
local Group = Logic:AddGroupbox({ Title = "Combat" })
Group:AddToggle("Auto Attack", false, function(v) demo("Auto Attack", tostring(v)) end)
Group:AddSlider({ Title = "Range", Min = 1, Max = 50, Default = 10 })

MX:LoadAutoConfig()
MX:Info("MX HUB", "Loaded. Tap the MX button or press INSERT.")
