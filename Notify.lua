local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local env = (getgenv and getgenv()) or _G

if env.MXNotify and type(env.MXNotify.Destroy) == "function" then
	pcall(function() env.MXNotify:Destroy() end)
end

local Touch = UserInputService.TouchEnabled
local Mobile = Touch and not UserInputService.KeyboardEnabled
local C3 = Color3.fromRGB

local Notify = {
	Version = "3.0.0",
	Config = {
		Width = Mobile and 264 or 300,
		OffsetX = 12,
		OffsetY = 12,
		Spacing = 8,
		MaxVisible = 4,
		Duration = 4,
		Radius = 16,
		HoverPause = true,
		ShowTime = true,
		TimeText = "now",
	},
	Theme = {
		Card = C3(28, 28, 32),
		Element = C3(44, 44, 50),
		Border = C3(72, 72, 82),
		Text = C3(245, 245, 248),
		Sub = C3(160, 160, 172),
		Info = C3(10, 132, 255),
		Success = C3(48, 209, 88),
		Warning = C3(255, 159, 10),
		Error = C3(255, 69, 58),
		OnAccent = C3(255, 255, 255),
	},
	Types = { Info = true, Success = true, Warning = true, Error = true },
	Icons = {
		Info = "rbxassetid://10723415903",
		Success = "rbxassetid://10709790644",
		Warning = "rbxassetid://10709753149",
		Error = "rbxassetid://10747384394",
	},
}

local Bindings = {}
local Painters = {}
local Active = {}
local Count = 0
local Dead = false

local function protect(gui)
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then
			gui.Parent = h
			return
		end
	end
	if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
	local ok = pcall(function() gui.Parent = CoreGui end)
	if not ok then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function bind(obj, prop, key)
	obj[prop] = Notify.Theme[key]
	Bindings[#Bindings + 1] = { o = obj, p = prop, k = key }
end

local function tween(o, props, t, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local Gui = new("ScreenGui", {
	Name = "MXNotify",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 2147483000,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(function() Gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
protect(Gui)

local Holder = new("Frame", {
	Name = "Holder",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(Notify.Config.Width, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Position = UDim2.fromOffset(Notify.Config.OffsetX, Notify.Config.OffsetY),
}, Gui)
new("UIListLayout", {
	Padding = UDim.new(0, Notify.Config.Spacing),
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Top,
}, Holder)

local function typeColor(kind)
	return Notify.Theme[kind] or Notify.Theme.Info
end

local function iconFor(icon, kind)
	if type(icon) == "number" then return "rbxassetid://" .. icon end
	if type(icon) == "string" and icon ~= "" then return icon end
	return Notify.Icons[kind]
end

local function uiScale()
	local sc = Gui:FindFirstChild("Scale")
	return sc and sc.Scale or 1
end

function Notify:Send(o)
	o = type(o) == "table" and o or { Title = tostring(o) }
	if Dead then return { Dismiss = function() end, Update = function() end } end
	Count += 1
	local cfg = self.Config
	local kind = self.Types[o.Type] and o.Type or "Info"
	local closed, hovering, holding = false, false, false
	local elapsed = 0
	local duration = tonumber(o.Duration)
	if duration == nil then duration = cfg.Duration end
	local timer, dragConn

	local wrap = new("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = Count,
	}, Holder)

	local card = new("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(0, -18),
		GroupTransparency = 1,
		BorderSizePixel = 0,
	}, wrap)
	bind(card, "BackgroundColor3", "Card")
	card.BackgroundTransparency = 0.04
	new("UICorner", { CornerRadius = UDim.new(0, cfg.Radius) }, card)
	local stroke = new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.5 }, card)
	bind(stroke, "Color", "Border")

	local tap = new("TextButton", {
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
	}, card)

	local inner = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, card)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 11),
		PaddingBottom = UDim.new(0, 11),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, inner)
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, inner)

	local top = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	}, inner)

	local badge = new("Frame", { Size = UDim2.fromOffset(34, 34), BorderSizePixel = 0 }, top)
	badge.BackgroundColor3 = typeColor(kind)
	new("UICorner", { CornerRadius = UDim.new(0, 9) }, badge)
	local glyph = new("ImageLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(20, 20),
		Image = iconFor(o.Icon, kind),
		ImageColor3 = C3(255, 255, 255),
	}, badge)

	local textCol = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(44, 0),
		Size = UDim2.new(1, -44, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, top)
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, textCol)

	local title = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, cfg.ShowTime and -40 or 0, 0, 17),
		Font = Enum.Font.GothamBold,
		TextSize = Mobile and 14 or 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = tostring(o.Title or kind),
		LayoutOrder = 1,
	}, textCol)
	bind(title, "TextColor3", "Text")

	local content = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		TextSize = Mobile and 13 or 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = tostring(o.Content or ""),
		Visible = o.Content ~= nil and tostring(o.Content) ~= "",
		LayoutOrder = 2,
	}, textCol)
	bind(content, "TextColor3", "Sub")

	local sub = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = tostring(o.SubContent or ""),
		Visible = o.SubContent ~= nil and tostring(o.SubContent) ~= "",
		LayoutOrder = 3,
	}, textCol)
	bind(sub, "TextColor3", "Sub")

	if cfg.ShowTime then
		local stamp = new("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 1),
			Size = UDim2.fromOffset(36, 14),
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = tostring(o.Time or cfg.TimeText),
		}, top)
		bind(stamp, "TextColor3", "Sub")
	end

	local primaryButtons = {}
	if type(o.Buttons) == "table" and #o.Buttons > 0 then
		local sep = new("Frame", { BorderSizePixel = 0, BackgroundTransparency = 0.55, Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 2 }, inner)
		bind(sep, "BackgroundColor3", "Border")
		local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Touch and 30 or 26), LayoutOrder = 3 }, inner)
		local n = #o.Buttons
		for i, b in ipairs(o.Buttons) do
			local btn = new("TextButton", {
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Size = UDim2.new(1 / n, 0, 1, 0),
				Position = UDim2.new((i - 1) / n, 0, 0, 0),
				Font = b.Primary and Enum.Font.GothamBold or Enum.Font.GothamMedium,
				TextSize = 13,
				Text = tostring(b.Text or b.Title or "OK"),
				ZIndex = 3,
			}, row)
			if b.Primary then
				btn.TextColor3 = typeColor(kind)
				primaryButtons[#primaryButtons + 1] = btn
			else
				bind(btn, "TextColor3", "Text")
			end
			if i > 1 then
				local line = new("Frame", { BorderSizePixel = 0, BackgroundTransparency = 0.55, Size = UDim2.new(0, 1, 0.6, 0), Position = UDim2.new(0, 0, 0.2, 0) }, btn)
				bind(line, "BackgroundColor3", "Border")
			end
			btn.Activated:Connect(function()
				if closed then return end
				local dismissNow = Painters[wrap] and Painters[wrap].dismiss
				if dismissNow then dismissNow() end
				if b.Callback then task.spawn(b.Callback) end
			end)
		end
	end

	local function dismiss()
		if closed then return end
		closed = true
		if timer then timer:Disconnect() end
		if dragConn then dragConn:Disconnect() end
		Painters[wrap] = nil
		for i, rec in ipairs(Active) do
			if rec.wrap == wrap then
				table.remove(Active, i)
				break
			end
		end
		tween(card, { GroupTransparency = 1, Position = UDim2.fromOffset(0, -14) }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.22, function()
			if not wrap.Parent then return end
			local h = wrap.AbsoluteSize.Y / uiScale()
			wrap.AutomaticSize = Enum.AutomaticSize.None
			wrap.ClipsDescendants = true
			wrap.Size = UDim2.new(1, 0, 0, h)
			tween(wrap, { Size = UDim2.new(1, 0, 0, 0) }, 0.16, Enum.EasingStyle.Quad)
			task.delay(0.18, function() wrap:Destroy() end)
		end)
	end

	Painters[wrap] = {
		dismiss = dismiss,
		paint = function()
			local c = typeColor(kind)
			badge.BackgroundColor3 = c
			for _, b in ipairs(primaryButtons) do b.TextColor3 = c end
		end,
	}

	if self.Config.HoverPause and not Touch then
		tap.MouseEnter:Connect(function() hovering = true end)
		tap.MouseLeave:Connect(function() hovering = false end)
	end

	local down, startPos
	local function release(i)
		local same = i == down or (down and down.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1)
		if not same then return end
		local d = (Vector2.new(i.Position.X, i.Position.Y) - startPos) / uiScale()
		down = nil
		holding = false
		if dragConn then
			dragConn:Disconnect()
			dragConn = nil
		end
		if closed then return end
		if o.Swipe ~= false and (d.Y < -28 or d.X < -60) then
			dismiss()
		elseif d.Magnitude < 8 then
			dismiss()
			if o.Callback then task.spawn(o.Callback) end
		else
			tween(card, { Position = UDim2.fromOffset(0, 0) }, 0.25)
		end
	end
	tap.InputBegan:Connect(function(i)
		local t = i.UserInputType
		if closed or (t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1) then return end
		down = i
		startPos = Vector2.new(i.Position.X, i.Position.Y)
		holding = true
		if dragConn then dragConn:Disconnect() end
		dragConn = UserInputService.InputChanged:Connect(function(c)
			if closed or not down then return end
			if c ~= down and not (down.UserInputType == Enum.UserInputType.MouseButton1 and c.UserInputType == Enum.UserInputType.MouseMovement) then return end
			local d = (Vector2.new(c.Position.X, c.Position.Y) - startPos) / uiScale()
			if o.Swipe ~= false then card.Position = UDim2.fromOffset(math.min(0, d.X), math.min(0, d.Y)) end
		end)
	end)
	tap.InputEnded:Connect(release)

	while #Active >= self.Config.MaxVisible do
		local oldest = table.remove(Active, 1)
		local p = oldest and Painters[oldest.wrap]
		if p then p.dismiss() end
	end
	Active[#Active + 1] = { wrap = wrap }

	tween(card, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.42, Enum.EasingStyle.Quint)

	if duration > 0 then
		timer = RunService.Heartbeat:Connect(function(dt)
			if closed or hovering or holding then return end
			elapsed += dt
			if elapsed >= duration then dismiss() end
		end)
	end

	local handle = { Dismiss = dismiss }
	function handle.Update(n)
		if closed or type(n) ~= "table" then return end
		if n.Type and Notify.Types[n.Type] then
			kind = n.Type
			badge.BackgroundColor3 = typeColor(kind)
			glyph.Image = iconFor(n.Icon, kind)
		end
		if n.Title then title.Text = tostring(n.Title) end
		if n.Content then
			content.Text = tostring(n.Content)
			content.Visible = tostring(n.Content) ~= ""
		end
		if n.SubContent then
			sub.Text = tostring(n.SubContent)
			sub.Visible = tostring(n.SubContent) ~= ""
		end
	end
	return handle
end

for kind in pairs(Notify.Types) do
	Notify[kind] = function(self, title, content, duration)
		return self:Send({ Type = kind, Title = title, Content = content, Duration = duration })
	end
end

function Notify:SetTheme(t)
	if type(t) ~= "table" then return end
	for k, v in pairs(t) do
		if typeof(v) == "Color3" then self.Theme[k] = v end
	end
	local alive = {}
	for _, b in ipairs(Bindings) do
		if b.o and b.o.Parent then
			b.o[b.p] = self.Theme[b.k]
			alive[#alive + 1] = b
		end
	end
	Bindings = alive
	for _, p in pairs(Painters) do p.paint() end
end

function Notify:SetPosition(x, y)
	self.Config.OffsetX = x or self.Config.OffsetX
	self.Config.OffsetY = y or self.Config.OffsetY
	Holder.Position = UDim2.fromOffset(self.Config.OffsetX, self.Config.OffsetY)
end

function Notify:SetScale(s)
	local sc = Gui:FindFirstChild("Scale") or new("UIScale", { Name = "Scale" }, Gui)
	sc.Scale = math.clamp(tonumber(s) or 1, 0.6, 1.6)
end

function Notify:ActiveCount()
	return #Active
end

function Notify:ClearAll()
	for _, rec in ipairs(Active) do
		if rec.wrap and rec.wrap.Parent then rec.wrap:Destroy() end
	end
	table.clear(Active)
	table.clear(Painters)
end

function Notify:Destroy()
	Dead = true
	self:ClearAll()
	if Gui then Gui:Destroy() end
	if env.MXNotify == self then env.MXNotify = nil end
end

env.MXNotify = Notify

return Notify
