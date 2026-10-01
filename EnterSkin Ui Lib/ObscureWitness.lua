-- Unload any previously loaded copy so re-running never stacks two UIs.
-- BOTH globals are unloaded: an old build exported both, and leaving one alive
-- would leave a zombie library competing for input and rendering.
-- `EnterSkin` is the library's former global name, referenced only for cleanup.
for _, Name in ipairs({ "Library", "EnterSkin" }) do
	local Previous = getgenv()[Name]
	if Previous and type(Previous.Unload) == "function" then
		pcall(function()
			Previous:Unload()
		end)
	end
	getgenv()[Name] = nil
end
local FS = { }

function FS.IsFolder(Path)
	local Ok, Result = pcall(isfolder, Path)
	return Ok and Result == true
end

function FS.IsFile(Path)
	local Ok, Result = pcall(isfile, Path)
	return Ok and Result == true
end

function FS.MakeFolder(Path)
	pcall(makefolder, Path)
end

function FS.List(Path)
	local Ok, Result = pcall(listfiles, Path)
	if not Ok or type(Result) ~= "table" then
		return { }
	end
	return Result
end

function FS.Read(Path)
	local Ok, Result = pcall(readfile, Path)
	if not Ok or type(Result) ~= "string" then
		return nil
	end
	return Result
end

function FS.Write(Path, Data)
	pcall(writefile, Path, Data)
end

function FS.Delete(Path)
	pcall(delfile, Path)
end

function FS.CustomAsset(Path)
	local Ok, Result = pcall(getcustomasset, Path)
	if not Ok or type(Result) ~= "string" then
		return ""
	end
	return Result
end

function FS.Move(From, To)
	pcall(movefile, From, To)
end

function FS.RemoveFolder(Path)
	pcall(delfolder, Path)
end

local function JoinPath(...)
	local Parts = { ... }
	for Index = 1, #Parts do
		Parts[Index] = tostring(Parts[Index] or ""):gsub("\\", "/")
	end
	return table.concat(Parts, "/")
end

local function FileNameOnly(Path)
	return tostring(Path or ""):match("[^/\\]+$") or tostring(Path or "")
end
local Brand = "EnterSkin"
local LegacyBrand = "eclipse"
local SubFolders = { "Assets", "Configs", "Themes" }
if FS.IsFolder(LegacyBrand) and not FS.IsFolder(Brand) then
	FS.MakeFolder(Brand)
	for Index, Sub in ipairs(SubFolders) do
		local LegacySub = JoinPath(LegacyBrand, Sub)
		if FS.IsFolder(LegacySub) then
			FS.MakeFolder(JoinPath(Brand, Sub))
			for Entry, FileName in ipairs(FS.List(LegacySub)) do
				local From = JoinPath(LegacySub, FileNameOnly(FileName))
				local To = JoinPath(Brand, Sub, FileNameOnly(FileName))
				if not FS.IsFile(To) then
					FS.Move(From, To)
				end
			end
		end
	end
	local LegacyAuto = JoinPath(LegacyBrand, "autoload.json")
	if FS.IsFile(LegacyAuto) and not FS.IsFile(JoinPath(Brand, "autoload.json")) then
		FS.Move(LegacyAuto, JoinPath(Brand, "autoload.json"))
	end
	FS.RemoveFolder(LegacyBrand)
end
if not FS.IsFolder(Brand) then
	FS.MakeFolder(Brand)
end
for Index, Sub in ipairs(SubFolders) do
	if not FS.IsFolder(JoinPath(Brand, Sub)) then
		FS.MakeFolder(JoinPath(Brand, Sub))
	end
end
local Library do
	local Workspace = game:GetService("Workspace")
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
	local TweenService = game:GetService("TweenService")
	local Stats = game:GetService("Stats")
	local gethui = (typeof(gethui) == "function" and gethui) or function()
		return CoreGui
	end
	local LocalPlayer = Players.LocalPlayer
	local Camera = Workspace.CurrentCamera
	local Mouse = LocalPlayer:GetMouse()
	local FromRGB = Color3.fromRGB
	local FromHSV = Color3.fromHSV
	local FromHex = Color3.fromHex
	local RGBSequence = ColorSequence.new
	local RGBSequenceKeypoint = ColorSequenceKeypoint.new
	local NumSequence = NumberSequence.new
	local NumSequenceKeypoint = NumberSequenceKeypoint.new
	local UDim2New = UDim2.new
	local UDimNew = UDim.new
	local Vector2New = Vector2.new
	local MathClamp = math.clamp
	local MathFloor = math.floor
	local MathAbs = math.abs
	local MathSin = math.sin
	local TableInsert = table.insert
	local TableFind = table.find
	local TableRemove = table.remove
	local TableConcat = table.concat
	local TableClone = table.clone
	local TableUnpack = table.unpack
	local StringFormat = string.format
	local StringFind = string.find
	local StringGSub = string.gsub
	local StringLower = string.lower
	local InstanceNew = Instance.new
	local MathMax = math.max
	local MathMin = math.min
	local MathCeil = math.ceil
	local MathRad = math.rad
	local Vector3New = Vector3.new
	local CFrameNew = CFrame.new
	local CFrameAngles = CFrame.Angles
	local RectNew = Rect.new
	local Tick = tick
	local Delay = task.delay
	local ToString = tostring
	local Type = type
	local TypeOf = typeof
	local Pairs = pairs
	local CloseCoroutine = coroutine.close
	local UIType = Enum.UserInputType
	local InputTypeMouseMovement = UIType.MouseMovement
	local InputTypeMouseButton1 = UIType.MouseButton1
	local InputTypeMouseWheel = UIType.MouseWheel
	local InputTypeTouch = UIType.Touch
	local TypesMove = { InputTypeMouseMovement, InputTypeTouch }
	local TypesClick = { InputTypeMouseButton1, InputTypeTouch }
	local TypesWheel = { InputTypeMouseWheel }
	local TypesClickOrMove = { InputTypeMouseButton1, InputTypeMouseMovement, InputTypeTouch }
	local InputTypeMouseButton2 = UIType.MouseButton2
	local IsMobile = false
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		IsMobile = true
	elseif not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		IsMobile = false
	elseif UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		IsMobile = false
	end
	Library = {
		Locked = false,
		Theme =  { },
		Themes = { },
		MenuKeybind = tostring(Enum.KeyCode.RightControl),
		Flags = { },
		Tween = {
			Time = 0.25,
			Style = Enum.EasingStyle.Quart,
			Direction = Enum.EasingDirection.Out
		},
		Folders = {
			Directory = Brand,
			Configs = Brand .. "/Configs",
			Assets = Brand .. "/Assets",
			Themes = Brand .. "/Themes"
		},
		Images = {
			["Saturation"] = {"Saturation.png", "https://github.com/sametexe001/images/blob/main/saturation.png?raw=true" },
			["Value"] = { "Value.png", "https://github.com/sametexe001/images/blob/main/value.png?raw=true" },
			["Hue"] = { "Hue.png", "https://github.com/sametexe001/images/blob/main/horizontalhue.png?raw=true" },
			["Checkers"] = { "Checkers.png", "https://github.com/sametexe001/images/blob/main/checkers.png?raw=true" },
		},
		Settings = {
			Blur = true,
			BlurSize = 24,
			CenterSpinner = true,
			CenterSpinnerSpeed = 1.8,
			CenterSpinnerSize = 260,
			CenterSpinnerLayer = "Behind UI",
			CenterSpinnerPosition = "Screen Center",
			CenterSpinnerImage = "Robloxui/white_mesh.mesh",
			PanelsTransparency = 0.35,
			WindowTransparency = 0.20,
			CenterSpinnerStyle = "3D",
			MaxNotifications = 6,
			NotificationPosition = "TopRight",
			NotificationDirection = "Vertical",
			NotificationOffsetX = 12,
			NotificationOffsetY = 12,
			NotificationWidth = 320,
			NotificationHeight = 70,
			NotificationGap = 12,
			Accent = nil,
			ShowFPS = false,
			PageTransitions = true,
		CustomCursor = true,
			AutoSave = true,
			ScrollBarThickness = 4
		},
		Pages = { },
		Sections = { },
		Windows = { },
		Connections = { },
		Threads = { },
		ThemeMap = { },
		ThemeItems = { },
		OpenFrames = { },
		PopupFrames = { },
		Elements = { },
		ElementOrder = { },
		CurrentPage = nil,
		SearchItems = { },
		ThemeColorpickers = { },
		SetFlags = { },
		UnnamedConnections = 0,
		UnnamedFlags = 0,
			Holder = nil,
			NotifHolder = nil,
			UnusedHolder = nil,
			Font = nil,
			KeyList = nil,
			FocusedWindow = nil,
			CurrentConfig = nil,
		BypassTweenGuard = false
	}
	Library.__index = Library
	local oldLibrary = Library
	local ConnectionCounter = 0
	Library.Sections.__index = Library.Sections
	Library.Pages.__index = Library.Pages
	local Keys = {
		["Unknown"]           = "Unknown",
		["Backspace"]         = "Back",
		["Tab"]               = "Tab",
		["Clear"]             = "Clear",
		["Return"]            = "Return",
		["Pause"]             = "Pause",
		["Escape"]            = "Escape",
		["Space"]             = "Space",
		["QuotedDouble"]      = '"',
		["Hash"]              = "#",
		["Dollar"]            = "$",
		["Percent"]           = "%",
		["Ampersand"]         = "&",
		["Quote"]             = "'",
		["LeftParenthesis"]   = "(",
		["RightParenthesis"]  = " )",
		["Asterisk"]          = "*",
		["Plus"]              = "+",
		["Comma"]             = ",",
		["Minus"]             = "-",
		["Period"]            = ".",
		["Slash"]             = "`",
		["Three"]             = "3",
		["Seven"]             = "7",
		["Eight"]             = "8",
		["Colon"]             = ":",
		["Semicolon"]         = ";",
		["LessThan"]          = "<",
		["GreaterThan"]       = ">",
		["Question"]          = "?",
		["Equals"]            = "=",
		["At"]                = "@",
		["LeftBracket"]       = "LeftBracket",
		["RightBracket"]      = "RightBracked",
		["BackSlash"]         = "BackSlash",
		["Caret"]             = "^",
		["Underscore"]        = "_",
		["Backquote"]         = "`",
		["LeftCurly"]         = "{",
		["Pipe"]              = "|",
		["RightCurly"]        = "}",
		["Tilde"]             = "~",
		["Delete"]            = "Delete",
		["End"]               = "End",
		["KeypadZero"]        = "Keypad0",
		["KeypadOne"]         = "Keypad1",
		["KeypadTwo"]         = "Keypad2",
		["KeypadThree"]       = "Keypad3",
		["KeypadFour"]        = "Keypad4",
		["KeypadFive"]        = "Keypad5",
		["KeypadSix"]         = "Keypad6",
		["KeypadSeven"]       = "Keypad7",
		["KeypadEight"]       = "Keypad8",
		["KeypadNine"]        = "Keypad9",
		["KeypadPeriod"]      = "KeypadP",
		["KeypadDivide"]      = "KeypadD",
		["KeypadMultiply"]    = "KeypadM",
		["KeypadMinus"]       = "KeypadM",
		["KeypadPlus"]        = "KeypadP",
		["KeypadEnter"]       = "KeypadE",
		["KeypadEquals"]      = "KeypadE",
		["Insert"]            = "Insert",
		["Home"]              = "Home",
		["PageUp"]            = "PageUp",
		["PageDown"]          = "PageDown",
		["RightShift"]        = "RightShift",
		["LeftShift"]         = "LeftShift",
		["RightControl"]      = "RightControl",
		["LeftControl"]       = "LeftControl",
		["LeftAlt"]           = "LeftAlt",
		["RightAlt"]          = "RightAlt"
	}
	local Themes = {
		["Default"] = {
			["Background"] = FromRGB(30, 33, 41),
			["Inline"] = FromRGB(40, 44, 54),
			["Border"] = FromRGB(66, 73, 88),
			["Shadow"] = FromRGB(10, 12, 18),
			["Text"] = FromRGB(240, 244, 252),
			["Inactive Text"] = FromRGB(158, 168, 186),
			["Accent"] = FromRGB(59, 130, 246),
			["Element"] = FromRGB(54, 60, 73),
			["Gradient"] = FromRGB(176, 188, 208)
		},
		["Halloween"] = {
			["Background"] = FromRGB(48, 24, 7),
			["Inline"] = FromRGB(34, 14, 8),
			["Border"] = FromRGB(79, 40, 16),
			["Shadow"] = FromRGB(255, 98, 0),
			["Text"] = FromRGB(195, 195, 195),
			["Inactive Text"] = FromRGB(116, 116, 116),
			["Accent"] = FromRGB(255, 98, 0),
			["Element"] = FromRGB(68, 28, 0),
			["Gradient"] = FromRGB(150, 150, 150)
		},
		["Aqua"] = {
			["Background"] = FromRGB(19, 21, 23),
			["Inline"] = FromRGB(31, 35, 39),
			["Border"] = FromRGB(48, 56, 63),
			["Shadow"] = FromRGB(0, 0, 0),
			["Text"] = FromRGB(245, 245, 245),
			["Inactive Text"] = FromRGB(185, 185, 185),
			["Accent"] = FromRGB(31, 106, 181),
			["Element"] = FromRGB(58, 66, 77),
			["Gradient"] = FromRGB(211, 211, 211)
		},
		["Onetap"] = {
			["Background"] = FromRGB(51, 51, 51),
			["Inline"] = FromRGB(30, 30, 30),
			["Border"] = FromRGB(0, 0, 0),
			["Shadow"] = FromRGB(0, 0, 0),
			["Text"] = FromRGB(255, 255, 255),
			["Inactive Text"] = FromRGB(185, 185, 185),
			["Accent"] = FromRGB(237, 170, 0),
			["Element"] = FromRGB(45, 45, 45),
			["Gradient"] = FromRGB(211, 211, 211)
		},
		["Bitchbot"] = {
			["Background"] = FromRGB(33, 33, 33),
			["Inline"] = FromRGB(14, 14, 14),
			["Border"] = FromRGB(0, 0, 0),
			["Shadow"] = FromRGB(0, 0, 0),
			["Text"] = FromRGB(255, 255, 255),
			["Inactive Text"] = FromRGB(185, 185, 185),
			["Accent"] = FromRGB(158, 79, 249),
			["Element"] = FromRGB(22, 20, 20),
			["Gradient"] = FromRGB(211, 211, 211)
		},
		["Gamesense"] = {
			["Background"] = FromRGB(22, 22, 22),
			["Inline"] = FromRGB(17, 17, 17),
			["Border"] = FromRGB(37, 37, 37),
			["Shadow"] = FromRGB(34, 34, 34),
			["Text"] = FromRGB(255, 255, 255),
			["Inactive Text"] = FromRGB(185, 185, 185),
			["Accent"] = FromRGB(211, 255, 53),
			["Element"] = FromRGB(53, 53, 53),
			["Gradient"] = FromRGB(156, 156, 156)
		},
		["EnterSkin"] = {
			["Background"] = FromRGB(30, 33, 41),
			["Inline"] = FromRGB(40, 44, 54),
			["Border"] = FromRGB(66, 73, 88),
			["Shadow"] = FromRGB(10, 12, 18),
			["Text"] = FromRGB(240, 244, 252),
			["Inactive Text"] = FromRGB(158, 168, 186),
			["Accent"] = FromRGB(59, 130, 246),
			["Element"] = FromRGB(54, 60, 73),
			["Gradient"] = FromRGB(176, 188, 208)
		},
		["Midnight"] = {
			["Background"] = FromRGB(9, 12, 20),
			["Inline"] = FromRGB(16, 21, 33),
			["Border"] = FromRGB(30, 38, 56),
			["Shadow"] = FromRGB(0, 0, 0),
			["Text"] = FromRGB(226, 232, 240),
			["Inactive Text"] = FromRGB(130, 145, 170),
			["Accent"] = FromRGB(56, 189, 248),
			["Element"] = FromRGB(24, 31, 46),
			["Gradient"] = FromRGB(170, 190, 215)
		},
		["Forest"] = {
			["Background"] = FromRGB(14, 20, 16),
			["Inline"] = FromRGB(22, 31, 25),
			["Border"] = FromRGB(40, 56, 45),
			["Shadow"] = FromRGB(0, 0, 0),
			["Text"] = FromRGB(236, 245, 238),
			["Inactive Text"] = FromRGB(140, 160, 145),
			["Accent"] = FromRGB(52, 211, 153),
			["Element"] = FromRGB(30, 44, 35),
			["Gradient"] = FromRGB(180, 205, 188)
		},
		["Crimson"] = {
			["Background"] = FromRGB(20, 13, 15),
			["Inline"] = FromRGB(31, 19, 22),
			["Border"] = FromRGB(58, 34, 40),
			["Shadow"] = FromRGB(0, 0, 0),
			["Text"] = FromRGB(248, 238, 240),
			["Inactive Text"] = FromRGB(165, 135, 142),
			["Accent"] = FromRGB(244, 63, 94),
			["Element"] = FromRGB(44, 27, 32),
			["Gradient"] = FromRGB(212, 180, 186)
		},
		["Solarized"] = {
			["Background"] = FromRGB(0, 43, 54),
			["Inline"] = FromRGB(7, 54, 66),
			["Border"] = FromRGB(88, 110, 117),
			["Shadow"] = FromRGB(0, 0, 0),
			["Text"] = FromRGB(238, 232, 213),
			["Inactive Text"] = FromRGB(131, 148, 150),
			["Accent"] = FromRGB(181, 137, 0),
			["Element"] = FromRGB(38, 60, 71),
			["Gradient"] = FromRGB(101, 123, 131)
		},
		["Monochrome"] = {
			["Background"] = FromRGB(18, 18, 18),
			["Inline"] = FromRGB(26, 26, 26),
			["Border"] = FromRGB(46, 46, 46),
			["Shadow"] = FromRGB(0, 0, 0),
			["Text"] = FromRGB(240, 240, 240),
			["Inactive Text"] = FromRGB(150, 150, 150),
			["Accent"] = FromRGB(240, 240, 240),
			["Element"] = FromRGB(36, 36, 36),
			["Gradient"] = FromRGB(190, 190, 190)
		},
		["Sakura"] = {
			["Background"] = FromRGB(24, 18, 24),
			["Inline"] = FromRGB(35, 26, 36),
			["Border"] = FromRGB(66, 48, 64),
			["Shadow"] = FromRGB(0, 0, 0),
			["Text"] = FromRGB(250, 240, 245),
			["Inactive Text"] = FromRGB(175, 148, 163),
			["Accent"] = FromRGB(244, 114, 182),
			["Element"] = FromRGB(50, 37, 51),
			["Gradient"] = FromRGB(214, 182, 200)
		}
	}
	Library.Theme = TableClone(Themes["Default"])
	Library.Themes = Themes
	for Index, Value in Library.Folders do
		if not FS.IsFolder(Value) then
			makefolder(Value)
		end
	end
	if not FS.IsFile(JoinPath(Library.Folders.Directory, "autoload.json")) then
		FS.Write(JoinPath(Library.Folders.Directory, "autoload.json"), "")
	end
	for Index, Value in Library.Images do
		local ImageData = Value
		local ImageName = ImageData[1]
		local ImageLink = ImageData[2]
		if not FS.IsFile(JoinPath(Library.Folders.Assets, ImageName)) then
			task.spawn(function()
				pcall(function()
					local Body = game:HttpGet(ImageLink)
					if Body and #Body > 0 then
						FS.Write(JoinPath(Library.Folders.Assets, ImageName), Body)
					end
				end)
			end)
		end
	end
	local Tween: any = { } do
		Tween.__index = Tween
		Tween.InfoCache = { }

		Tween.Info = function(self, Speed, Style, Direction)
			if Speed == nil and Style == nil and Direction == nil then
				local Default = Tween.DefaultInfo
				if not Default then
					Default = TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)
					Tween.DefaultInfo = Default
				end
				return Default
			end
			Speed = Speed or Library.Tween.Time
			Style = Style or Library.Tween.Style
			Direction = Direction or Library.Tween.Direction
			local Key = StringFormat("%s_%s_%s", ToString(Speed), ToString(Style), ToString(Direction))
			local Cached = Tween.InfoCache[Key]
			if Cached then
				return Cached
			end
			Cached = TweenInfo.new(Speed, Style, Direction)
			Tween.InfoCache[Key] = Cached
			return Cached
		end

		Tween.Create = function(self, Item, Info, Goal, IsRawItem)
			if TypeOf(Item) == "Instance" then
			elseif Type(Item) == "table" and Item.Instance then
				Item = Item.Instance
			end
			if not Item then
				return
			end
			Info = Info or Tween:Info()
			local NewTween = {
				Tween = TweenService:Create(Item, Info, Goal),
				Info = Info,
				Goal = Goal,
				Item = Item
			}
			NewTween.Tween:Play()
			setmetatable(NewTween, Tween)
			return NewTween
		end
		Tween.PropertyCache = { }

		Tween.GetProperty = function(self, Item)
			Item = Item or self.Item
			local ClassName = Item.ClassName
			local Cached = Tween.PropertyCache[ClassName]
			if Cached ~= nil then
				return Cached
			end
			local Result
			if Item:IsA("Frame") then
				Result = { "BackgroundTransparency" }
			elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
				Result = { "TextTransparency", "BackgroundTransparency" }
			elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
				Result = { "BackgroundTransparency", "ImageTransparency" }
			elseif Item:IsA("ScrollingFrame") then
				Result = { "BackgroundTransparency", "ScrollBarImageTransparency" }
			elseif Item:IsA("TextBox") then
				Result = { "TextTransparency", "BackgroundTransparency" }
			elseif Item:IsA("UIStroke") then
				Result = { "Transparency" }
			end
			Tween.PropertyCache[ClassName] = Result
			return Result
		end

		Tween.FadeItem = function(self, Item, Property, Visibility, Speed)
			Item = Item or self.Item
			local OldTransparency = Item[Property]
			local Target = Visibility and OldTransparency or 1
			if OldTransparency == Target and (Visibility or OldTransparency == 1) then
				Item[Property] = Target
				return nil
			end
			Item[Property] = Visibility and 1 or OldTransparency
			local NewTween = Tween:Create(Item, Tween:Info(Speed), {
				[Property] = Target
			}, true)
			Library:Once(NewTween.Tween.Completed, function()
				if not Visibility then
					task.wait()
					if Item.Parent then
						Item[Property] = OldTransparency
					end
				end
			end)
			return NewTween
		end

		Tween.Get = function(self)
			if not self.Tween then
				return
			end
			return self.Tween, self.Info, self.Goal
		end

		Tween.Pause = function(self)
			if not self.Tween then
				return
			end
			self.Tween:Pause()
		end

		Tween.Play = function(self)
			if not self.Tween then
				return
			end
			self.Tween:Play()
		end

		Tween.Clean = function(self)
			if not self.Tween then
				return
			end
			Tween:Pause()
			self = nil
		end
	end
	local RestoreQueue = { }
	local FadeStates = setmetatable({ }, { __mode = "k" })

	local function BuildFadeState(Instance)
		local Targets = { }
		local Count = 0

		local function Collect(Object)
			local Properties = Tween:GetProperty(Object)
			if Properties and not StringFind(Object.ClassName, "UI", 1, true) then
				Count += 1
				Targets[Count] = { Object = Object, Properties = Properties }
			end
		end
		Collect(Instance)
		for _, Descendant in ipairs(Instance:GetDescendants()) do
			Collect(Descendant)
		end
		local State = { Targets = Targets, Count = Count, Dirty = false }
		FadeStates[Instance] = State
		Instance.DescendantAdded:Connect(function()
			State.Dirty = true
		end)
		Instance.DescendantRemoving:Connect(function()
			State.Dirty = true
		end)
		return State
	end

	local function GetFadeState(Instance)
		local State = FadeStates[Instance]
		if State and State.Dirty then
			return BuildFadeState(Instance)
		end
		return State or BuildFadeState(Instance)
	end
	local GuiLists = setmetatable({ }, { __mode = "k" })

	local function BuildGuiList(Instance)
		local Objects = { }
		local Count = 0
		if Instance:IsA("GuiObject") then
			Count = 1
			Objects[1] = Instance
		end
		for _, Descendant in ipairs(Instance:GetDescendants()) do
			if Descendant:IsA("GuiObject") then
				Count += 1
				Objects[Count] = Descendant
			end
		end
		local State = { Objects = Objects, Count = Count, Set = { [Instance] = true } }
		for Index = 1, Count do
			State.Set[Objects[Index]] = true
		end
		GuiLists[Instance] = State
		Instance.DescendantAdded:Connect(function(Descendant)
			if not Descendant:IsA("GuiObject") then
				return
			end
			local Pending = Descendant
			while Pending and Pending ~= Instance do
				if Pending:IsA("GuiObject") then
					State.Set[Pending] = true
					State.Count += 1
					State.Objects[State.Count] = Pending
				end
				Pending = Pending.Parent
			end
		end)
		Instance.DescendantRemoving:Connect(function(Descendant)
			if not Descendant:IsA("GuiObject") then
				return
			end
			local Pending = Descendant
			while Pending and Pending ~= Instance do
				if Pending:IsA("GuiObject") and State.Set[Pending] then
					State.Set[Pending] = nil
					State.Dirty = true
				end
				Pending = Pending.Parent
			end
		end)
		return State
	end

	local function GetGuiList(Instance)
		local State = GuiLists[Instance]
		if State and State.Dirty then
			return BuildGuiList(Instance)
		end
		return State or BuildGuiList(Instance)
	end

	local function QueueRestore(Object, Property, Value, Delay)
		TableInsert(RestoreQueue, { Object = Object, Property = Property, Value = Value, At = Tick() + Delay })
	end

	Library.ProcessRestores = function(self)
		local Count = #RestoreQueue
		if Count == 0 then
			return
		end
		local Now = Tick()
		local Write = 0
		for Index = 1, Count do
			local Entry = RestoreQueue[Index]
			if Entry.At > Now then
				Write += 1
				RestoreQueue[Write] = Entry
			elseif Entry.Object and Entry.Object.Parent then
				Entry.Object[Entry.Property] = Entry.Value
			end
		end
		for Index = Write + 1, Count do
			RestoreQueue[Index] = nil
		end
	end

	Library.FadeHolder = function(self, Instance, Showing, Speed, TargetZIndex, Skip)
		if not Instance or not Instance.Parent then
			return nil
		end
		local State = GetFadeState(Instance)
		local Targets = State.Targets
		local Count = State.Count
		local WindowTop = Instance.AbsolutePosition.Y
		local WindowBottom = WindowTop + Instance.AbsoluteSize.Y
		local LastTween = nil
		local Animated = 0
		for Index = 1, Count do
			local Entry = Targets[Index]
			local Object = Entry.Object
			if Object and Object.Parent and not (Skip and Skip(Object)) then
				if TargetZIndex ~= nil then
					Object.ZIndex = TargetZIndex
				end
				local OnScreen = true
				if Object:IsA("GuiObject") then
					local Position = Object.AbsolutePosition
					local Size = Object.AbsoluteSize
					OnScreen = (Position.Y + Size.Y >= WindowTop) and (Position.Y <= WindowBottom)
				end
				if OnScreen and Animated < 80 then
					Animated += 1
					local Properties = Entry.Properties
					for PropertyIndex = 1, #Properties do
						local NewTween = Tween:FadeItem(Object, Properties[PropertyIndex], Showing, Speed)
						if NewTween then
							LastTween = NewTween
						end
					end
				else
					local Properties = Entry.Properties
					for PropertyIndex = 1, #Properties do
						local Property = Properties[PropertyIndex]
						local Old = Object[Property]
						if Showing then
							if Old == 1 then
								Object[Property] = 0
							end
						else
							if Old ~= 1 then
								Object[Property] = 1
								QueueRestore(Object, Property, Old, (Speed or 0.15) + 0.05)
							end
						end
					end
				end
			end
		end
		return LastTween
	end
	local Instances = { } do
		Instances.__index = Instances

		Instances.Create = function(self, Class, Properties)
			local Instance = InstanceNew(Class)
			local Parent = nil
			if Properties then
				for Property, Value in Pairs(Properties) do
					if Property == "Parent" then
						Parent = Value
					else
						Instance[Property] = Value
					end
				end
			end
			if Parent ~= nil then
				Instance.Parent = Parent
			end
			return setmetatable({
				Instance = Instance,
				Class = Class
			}, Instances)
		end

		Instances.Border = function(self)
			if not self.Instance then
				return
			end
			local Item = self.Instance
			local UIStroke = Instances:Create("UIStroke", {
				Parent = Item,
				Color = Library.Theme.Border,
				Thickness = 1,
				LineJoinMode = Enum.LineJoinMode.Miter
			})
			UIStroke:AddToTheme({Color = "Border"})
			return UIStroke
		end

		Instances.GetTooltip = function(self)
			if self.TooltipInstance then
				return self.TooltipInstance
			end
			local Items = { }
			Items["Tooltip"] = Instances:Create("Frame", {
				Parent = Library.Holder.Instance,
				Name = "\0",
				BackgroundColor3 = FromRGB(15, 12, 16),
				BorderSizePixel = 0,
				Position = UDim2New(0, 0, 0, 0),
				Size = UDim2New(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Visible = false,
				AutomaticSize = Enum.AutomaticSize.XY,
				ZIndex = 99
			}); Items["Tooltip"]:AddToTheme({BackgroundColor3 = "Background"})
			Items["Text"] = Instances:Create("TextLabel", {
				Parent = Items["Tooltip"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(255, 255, 255),
				BorderColor3 = FromRGB(0, 0, 0),
				Text = "",
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				Size = UDim2New(1, 0, 1, 0),
				ClipsDescendants = true,
				ZIndex = 99,
				TextTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 14,
				BackgroundColor3 = FromRGB(15, 12, 16)
			}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
			Instances:Create("UIPadding", {
				Parent = Items["Text"].Instance,
				Name = "\0",
				PaddingBottom = UDimNew(0, 8),
				PaddingLeft = UDimNew(0, 8),
				PaddingRight = UDimNew(0, 8),
				PaddingTop = UDimNew(0, 8),
			})
			Instances:Create("UICorner", {
				Parent = Items["Tooltip"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5)
			})
			Items["Tooltip"].Instance.MouseLeave:Connect(function()
				Library:HideTooltip()
			end)
			self.TooltipInstance = Items
			Library:AddFrameJob("Tooltip", function()
				if not Library.TooltipVisible then
					return
				end
				local Frame = Items["Tooltip"].Instance
				if not Frame or not Frame.Parent then
					Library.TooltipVisible = false
					return
				end
				local MouseLocation = Library:GetMouse()
				Frame.Position = UDim2New(0, MouseLocation.X, 0, MouseLocation.Y - 42)
			end)
			Library:AddFrameJob("Restores", function()
				Library:ProcessRestores()
			end)
			return Items
		end

		Library.ShowTooltip = function(self, Text)
			if not Text then
				return
			end
			local Items = Instances:GetTooltip()
			-- Writing .Text forces Roblox to re-measure the label, so only do it on change.
			local Label = Items["Text"].Instance
			Text = tostring(Text)
			if Label.Text ~= Text then
				Label.Text = Text
			end
			-- Skip the fade-in if it is already fully shown (rapid hover across elements).
			local Frame = Items["Tooltip"].Instance
			local AlreadyVisible = self.TooltipVisible and Frame.Visible and Frame.BackgroundTransparency <= 0
			self.TooltipVisible = true
			if not AlreadyVisible then
				Frame.Visible = true
				Frame.BackgroundTransparency = 1
				Label.TextTransparency = 1
				Items["Tooltip"]:Tween(nil, {BackgroundTransparency = 0})
				Items["Text"]:Tween(nil, {TextTransparency = 0})
			end
			local MouseLocation = Library:GetMouse()
			Frame.Position = UDim2New(0, MouseLocation.X, 0, MouseLocation.Y - 42)
		end

		Library.HideTooltip = function(self)
			self.TooltipVisible = false
			local Items = self.TooltipInstance
			if not Items or not Items["Tooltip"].Instance then return end
			local Frame = Items["Tooltip"].Instance
			-- Already hidden: skip the redundant tweens entirely.
			if not Frame.Visible and Frame.BackgroundTransparency >= 1 then
				return
			end
			Frame.Visible = false
			Frame.BackgroundTransparency = 1
			Items["Text"].Instance.TextTransparency = 1
		end
	Library.FrameJobs = { }
	Library.FrameHooked = false
	-- Cursor position is read by the tooltip, the custom cursor and every hit test.
	-- Cache it once per frame instead of paying an engine call (and a Vector2 alloc) each time.
	Library.MouseX = 0
	Library.MouseY = 0
	Library.MouseFrame = -1
	Library.GetMouse = function(self)
		local Frame = self.FrameCount or 0
		if self.MouseFrame ~= Frame then
			self.MouseFrame = Frame
			local P = UserInputService:GetMouseLocation()
			self.MouseX = P.X
			self.MouseY = P.Y
		end
		return Vector2New(self.MouseX, self.MouseY)
	end

	Library.InstallFrameHook = function(self)
		if self.FrameConnection then
			return
		end
		self.FrameHooked = true
		-- Keep the connection so Unload can actually detach it.
		self.FrameConnection = RunService.RenderStepped:Connect(function()
			if self.Unloaded then
				return
			end
			self.FrameCount = (self.FrameCount or 0) + 1
			self._FrameStart = Tick()
			local Current = self.FrameJobs
			for JobName, Job in Pairs(Current) do
				pcall(Job)
			end
			local JobTime = Tick() - self._FrameStart
			self.JobTime = (self.JobTime or 0) * 0.9 + JobTime * 0.1
		end)
	end

	Library.RemoveFrameHook = function(self)
		if self.FrameConnection then
			pcall(function()
				self.FrameConnection:Disconnect()
			end)
			self.FrameConnection = nil
		end
		self.FrameHooked = false
		self.FrameCount = 0
		self.JobTime = 0
	end

	-- Install now: the mouse cache and GetStats rely on FrameCount always advancing.
	Library.InstallFrameHook()
	Library.WarmupQueue = { }
	Library.WarmupQueued = { }
	Library.WarmContainers = { }
	Library.WarmContainersQueued = { }
	Library.WarmupDone = { }
	Library.WarmupRunning = false
	Library.WarmupPerFrame = 1

	local function WalkAndTouch(Instance, Depth)
		local Size = Instance.AbsoluteSize
		local Position = Instance.AbsolutePosition
		local Count = 1
		if Depth <= 0 then
			return Count
		end
		for _, Child in ipairs(Instance:GetChildren()) do
			if Child:IsA("GuiObject") then
				Count += WalkAndTouch(Child, Depth - 1)
			end
		end
		return Count
	end

	local function WarmOne(Page)
		if not Page or not Page.Items then
			return
		end
		local Frame = Page.Frame or (Page.Items["Page"] and Page.Items["Page"].Instance)
		if not Frame or not Frame.Parent then
			return
		end
		local WasVisible = Frame.Visible
		Frame.Visible = true
		WalkAndTouch(Frame, 12)
		Frame.Visible = WasVisible
		Page.WarmedVersion = Page.ContentVersion or 0
	end

	Library.WarmContainer = function(self, Instance)
		if not Instance or not Instance.Parent then
			return
		end
		local WasVisible = Instance.Visible
		Instance.Visible = true
		WalkAndTouch(Instance, 12)
		Instance.Visible = WasVisible
	end

	Library.QueueWarmContainer = function(self, Instance)
		if not Instance or not Instance.Parent or self.WarmupDisabled then
			return
		end
		self.WarmupIdle = 0
		if self.WarmContainersQueued[Instance] then
			return
		end
		self.WarmContainersQueued[Instance] = true
		TableInsert(self.WarmContainers, Instance)
		if not self.WarmupRunning then
			self.WarmupRunning = true
			self:AddFrameJob("Warmup", function()
				self:PumpWarmup()
			end)
		end
	end

	Library.PumpWarmup = function(self)
		local Queue = self.WarmupQueue
		local Containers = self.WarmContainers
		if #Queue == 0 and #Containers == 0 then
			return
		end
		if self.WarmupDisabled then
			table.clear(Queue)
			table.clear(self.WarmupQueued)
			table.clear(self.WarmContainers)
			table.clear(self.WarmContainersQueued)
			self.WarmupRunning = false
			return
		end
		if (self.WarmupIdle or 0) < 2 then
			self.WarmupIdle = (self.WarmupIdle or 0) + 1
			return
		end
		local Budget = self.WarmupPerFrame or 1
		for _ = 1, Budget do
			local Page = table.remove(Queue)
			if Page then
				self.WarmupDone[Page] = true
				self.WarmupQueued[Page] = nil
				pcall(WarmOne, Page)
			end
			local Container = table.remove(Containers)
			if Container then
				self.WarmContainersQueued[Container] = nil
				pcall(Library.WarmContainer, self, Container)
			end
			if not Page and not Container then
				break
			end
		end
		if #Queue == 0 and #Containers == 0 then
			self.WarmupRunning = false
		end
	end

	Library.QueueWarmup = function(self, Page)
		if not Page or self.WarmupDisabled then
			return
		end
		self.WarmupIdle = 0
		if self.WarmupQueued[Page] then
			return
		end
		self.WarmupQueued[Page] = true
		TableInsert(self.WarmupQueue, Page)
		if not self.WarmupRunning then
			self.WarmupRunning = true
			self:AddFrameJob("Warmup", function()
				self:PumpWarmup()
			end)
		end
	end

	Library.MarkWarmed = function(self, Page)
		return self.WarmupDone[Page] == true
	end

	Library.AddFrameJob = function(self, Name, Callback)
		if not Name or not Callback then
			return nil
		end
		self.FrameJobs[Name] = Callback
		self:InstallFrameHook()
		return { Name = Name }
	end

	Library.RemoveFrameJob = function(self, Name)
		if not Name then
			return
		end
		self.FrameJobs[Name] = nil
	end

	Library.RegisterPopup = function(self, Frame)
		if not Frame then
			return
		end
		TableInsert(Library.PopupFrames, Frame)
	end

	-- `Position` (the ScreenGui's coordinate space) and `AbsolutePosition` (screen
	-- space) are separated by the Roblox top inset on some executors even when
	-- IgnoreGuiInset is set: measured 58px on this client, which dropped every popup
	-- the inset height too high, on top of its own button. Measure the offset once
	-- from an already-laid-out child and cache it, instead of trusting either value.
	Library.GetScreenOffset = function(self)
		local Cached = self.ScreenOffset
		if Cached then
			return Cached.X, Cached.Y
		end
		local X, Y = 0, self.GuiInset or 0
		local Holder = self.Holder and self.Holder.Instance
		if Holder then
			for _, Child in ipairs(Holder:GetChildren()) do
				if Child:IsA("GuiObject") and Child.Visible
					and Child.AnchorPoint.Magnitude < 0.001
					and Child.AbsoluteSize.X > 0 and Child.AbsoluteSize.Y > 0 then
					X = Child.Position.X.Offset - Child.AbsolutePosition.X
					Y = Child.Position.Y.Offset - Child.AbsolutePosition.Y
					break
				end
			end
		end
		self.ScreenOffset = { X = X, Y = Y }
		return X, Y
	end

	-- Popups (dropdown lists, colorpicker, keybind) are parented to the full-screen
	-- Holder ScreenGui, so they must be placed in the popup's own coordinate space.
	-- Reading AbsolutePosition while the trigger button is still being built returns
	-- (0,0) (parent-last creation, no layout pass yet), which is what made popups
	-- spawn far away from their button. Always route through this instead.
	Library.PositionPopup = function(self, Popup, Target, XOffset, YOffset)
		if not Popup or not Popup.Parent or not Target then
			return false
		end
		-- Parent is usually a ScreenGui (no AbsolutePosition at all); only a GuiObject
		-- parent contributes an offset. Guard this or the popup never gets placed.
		local OriginX, OriginY = 0, 0
		local Parent = Popup.Parent
		if Parent:IsA("GuiObject") then
			local Origin = Parent.AbsolutePosition
			OriginX, OriginY = Origin.X, Origin.Y
		end
		-- Work out where the popup should sit in SCREEN space first, so the "does it
		-- fit" decision below is made against real pixels instead of Position units.
		local DesiredX = Target.AbsolutePosition.X + (XOffset or 0)
		local DesiredY = Target.AbsolutePosition.Y + (YOffset or 0)
		local Width, Height = Popup.AbsoluteSize.X, Popup.AbsoluteSize.Y
		local View = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
		if View and Height > 0 and (YOffset or 0) > 0 then
			-- Not enough room below: open upward instead of sliding onto the button.
			local TargetHeight = Target.AbsoluteSize.Y or 0
			local Gap = (YOffset or 0) - TargetHeight
			if DesiredY + Height > View.Y - 4 and Target.AbsolutePosition.Y - Gap - Height >= 4 then
				DesiredY = Target.AbsolutePosition.Y - Gap - Height
			end
		end
		-- `Position` lives in the ScreenGui's own coordinate space while
		-- `AbsolutePosition` is screen space, and on this executor the two are
		-- separated by the Roblox top inset (measured: 58px). Feeding an
		-- AbsolutePosition straight into Position therefore dropped every popup the
		-- inset height too high, on top of its own button. Convert instead.
		local OffsetX, OffsetY = Library:GetScreenOffset()
		local X = DesiredX - OriginX + OffsetX
		local Y = DesiredY - OriginY + OffsetY
		-- Position = AbsolutePosition + offset, so the viewport bounds convert with the
		-- offset ADDED. Subtracting it reserved the top inset twice, which is what
		-- dragged every popup 58px above where it belonged.
		if View and Width > 0 and Height > 0 then
			local MinX = 4 + OffsetX - OriginX
			local MaxX = View.X - 4 - Width + OffsetX - OriginX
			local MinY = 4 + OffsetY - OriginY
			local MaxY = View.Y - 4 - Height + OffsetY - OriginY
			if MaxX > MinX then X = MathClamp(X, MinX, MaxX) end
			if MaxY > MinY then Y = MathClamp(Y, MinY, MaxY) end
		end
		Popup.Position = UDim2New(0, X, 0, Y)
		return true, X, Y
	end

	Library.HideAllPopups = function(self)
		local Frames = Library.PopupFrames
		local Count = #Frames
		for Index = 1, Count do
			local Frame = Frames[Index]
			if Frame and Frame.Parent and Frame.Visible then
				Frame.Visible = false
			end
		end
	end

	Library.ClosePopups = function(self)
		self.TooltipVisible = false
		local Tooltip = self.TooltipInstance
		if Tooltip then
			local TooltipFrame = Tooltip["Tooltip"]
			local TooltipText = Tooltip["Text"]
			if TooltipFrame and TooltipFrame.Instance then
				TooltipFrame.Instance.Visible = false
				TooltipFrame.Instance.BackgroundTransparency = 1
			end
			if TooltipText and TooltipText.Instance then
				TooltipText.Instance.TextTransparency = 1
			end
		end
		local OpenFrames = self.OpenFrames
		if OpenFrames then
			local Dead = nil
			for obj in Pairs(OpenFrames) do
				if Type(obj) == "table" then
					local Items = obj.Items
					if Items then
						local OptionHolder = Items["OptionHolder"]
						local ColorpickerWindow = Items["ColorpickerWindow"]
						local KeybindWindow = Items["KeybindWindow"]
						if OptionHolder and OptionHolder.Instance then
							OptionHolder.Instance.Visible = false
						end
						if ColorpickerWindow and ColorpickerWindow.Instance then
							ColorpickerWindow.Instance.Visible = false
						end
						if KeybindWindow and KeybindWindow.Instance then
							KeybindWindow.Instance.Visible = false
						end
					end
					local Method = obj.SetOpen
					if Type(Method) ~= "function" then
						Method = obj.Toggle
					end
					if Type(Method) ~= "function" then
						Method = obj.Close
					end
					if Method then
						if not (Dead) then
							Dead = { }
						end
						TableInsert(Dead, { Object = obj, Method = Method })
					end
				end
			end
			if Dead then
				for Index = 1, #Dead do
					local Entry = Dead[Index]
					pcall(Entry.Method, Entry.Object, false, true)
					Entry.Object.IsOpen = false
				end
			end
			table.clear(OpenFrames)
		end
		self:HideAllPopups()
	end

		Instances.Tooltip = function(self, Text)
			if not self.Instance then
				return
			end
			if Text == nil then
				return
			end
			local Gui = self.Instance
			Library:Connect(Gui.MouseEnter, function()
				Library:ShowTooltip(Text)
			end)
			Library:Connect(Gui.MouseLeave, function()
				Library:HideTooltip()
			end)
		end

		Instances.FadeItem = function(self, Visibility, Speed)
			local Item = self.Instance
			if Visibility == true then
				Item.Visible = true
			end
			local Descendants = Item:GetDescendants()
			TableInsert(Descendants, Item)
			local Hidden = not Visibility
			for Index, Value in Descendants do
				local Properties = Tween:GetProperty(Value)
				if Properties then
					for _, Property in ipairs(Properties) do
						Tween:FadeItem(Value, Property, Hidden, Speed)
					end
				end
			end
		end

		Instances.AddToTheme = function(self, Properties)
			if not self.Instance then
				return
			end
			Library:AddToTheme(self, Properties)
		end

		Instances.ChangeItemTheme = function(self, Properties)
			if not self.Instance then
				return
			end
			Library:ChangeItemTheme(self, Properties)
		end

		Instances.Connect = function(self, Event, Callback, Name)
			if not self.Instance then
				return
			end
			local Ok, Signal = pcall(function()
				return self.Instance[Event]
			end)
			if not Ok or not Signal or type(Signal.Connect) ~= "function" then
				if Event == "MouseButton1Click" or Event == "MouseButton1Down" then
					local OkAct, ActSignal = pcall(function() return self.Instance.Activated end)
					if OkAct and ActSignal and type(ActSignal.Connect) == "function" then
						return Library:Connect(ActSignal, Callback, Name)
					end
				end
				return
			end
			return Library:Connect(Signal, Callback, Name)
		end

		Instances.Tween = function(self, Info, Goal)
			local Instance = self.Instance
			if not Instance then
				return
			end
			if Library.BypassTweenGuard then
				return Tween:Create(self, Info, Goal)
			end
			-- Visibility rarely changes within a frame, so memoize the parent-chain walk.
			local Frame = Library.FrameCount or 0
			if self.ShownFrame ~= Frame then
				self.ShownFrame = Frame
				self.Shown = Library:IsShown(Instance)
			end
			if self.Shown then
				return Tween:Create(self, Info, Goal)
			end
			-- Hidden: applying the goal directly is far cheaper than a real tween.
			-- One pcall for the whole goal instead of one closure per property.
			pcall(function()
				for Property, Value in Pairs(Goal) do
					Instance[Property] = Value
				end
			end)
			return nil
		end

		Instances.Disconnect = function(self, Name)
			if not self.Instance then
				return
			end
			return Library:Disconnect(Name)
		end

		Instances.Clean = function(self)
			local Instance = self.Instance
			if not Instance then
				return
			end
			Library:RemoveFromTheme(Instance)
			FadeStates[Instance] = nil
			GuiLists[Instance] = nil
			local ScrollList = Library.ScrollFrames
			for Index = #ScrollList, 1, -1 do
				if ScrollList[Index].Frame == Instance then
					table.remove(ScrollList, Index)
				end
			end
			Instance:Destroy()
			self.Instance = nil
		end

		Instances.MakeDraggable = function(self)
			if not self.Instance then
				return
			end
			local Gui = self.Instance
			local Dragging = false
			local DragStart
			local StartPosition
			local Set = function(Input)
				local DragDelta = Input.Position - DragStart
				self:Tween(Tween:Info(0.16), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
			end
			self:Connect("InputBegan", function(Input)
				if Library.Locked or self.Locked or Gui:GetAttribute("Locked") then
					return
				end
				if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
					Dragging = true
					DragStart = Input.Position
					StartPosition = Gui.Position
					Input.Changed:Connect(function()
						if Input.UserInputState == Enum.UserInputState.End then
							Dragging = false
						end
					end)
				end
			end)
			Library:On(UserInputService.InputChanged, function(Input)
				if Library.Locked or self.Locked or Gui:GetAttribute("Locked") then
					Dragging = false
					return
				end
				if Input.UserInputType == InputTypeMouseMovement or Input.UserInputType == InputTypeTouch then
					if Dragging then
						Set(Input)
					end
				end
			end, TypesMove)
			return Dragging
		end

		Instances.MakeResizeable = function(self, Minimum, Maximum)
			if not self.Instance then
				return
			end
			local Gui = self.Instance
			local Resizing = false
			local Start = UDim2New()
			local Delta = UDim2New()
			local ResizeMax = Gui.Parent.AbsoluteSize - Gui.AbsoluteSize
			local ResizeButton = Instances:Create("ImageButton", {
				Parent = Gui,
				Image = "rbxassetid://7368471234",
				AnchorPoint = Vector2New(1, 1),
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(0, 6, 0, 6),
				Position = UDim2New(1, -4, 1, -4),
				Name = "\0",
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				ZIndex = 5,
				AutoButtonColor = false,
				Visible = true,
			}); ResizeButton:AddToTheme({ImageColor3 = "Accent"})
			ResizeButton:Connect("InputBegan", function(Input)
				if Library.Locked then
					return
				end
				if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
					Resizing = true
					Start = Gui.Size - UDim2New(0, Input.Position.X, 0, Input.Position.Y)
					Input.Changed:Connect(function()
						if Input.UserInputState == Enum.UserInputState.End then
							Resizing = false
						end
					end)
				end
			end)
			Library:On(UserInputService.InputChanged, function(Input)
				if Input.UserInputType == InputTypeMouseMovement or Input.UserInputType == InputTypeTouch then
					if Resizing then
						ResizeMax = Maximum or Gui.Parent.AbsoluteSize - Gui.AbsoluteSize
						Delta = Start + UDim2New(0, Input.Position.X, 0, Input.Position.Y)
						Delta = UDim2New(0, math.clamp(Delta.X.Offset, Minimum.X, ResizeMax.X), 0, math.clamp(Delta.Y.Offset, Minimum.Y, ResizeMax.Y))
						Tween:Create(Gui, Tween:Info(0.17), {Size = Delta}, true)
					end
				end
			end, TypesMove)
			return Resizing
		end

		Instances.OnHover = function(self, Function)
			if not self.Instance then
				return
			end
			return Library:Connect(self.Instance.MouseEnter, Function)
		end

		Instances.OnHoverLeave = function(self, Function)
			if not self.Instance then
				return
			end
			return Library:Connect(self.Instance.MouseLeave, Function)
		end
	end
	local CustomFont = { } do

		function CustomFont:New(Name, Weight, Style, Data)
			local JsonPath = Library.Folders.Assets .. "/" .. Name .. ".json"
			local TtfPath = Library.Folders.Assets .. "/" .. Name .. ".ttf"
			if not FS.IsFile(TtfPath) and Data and Data.Url then
				pcall(function()
					local Body = game:HttpGet(Data.Url)
					if Body and #Body > 0 then
						FS.Write(TtfPath, Body)
					end
				end)
			end
			if not FS.IsFile(TtfPath) then
				return nil
			end
			local FontData = {
				name = Name,
				faces = { {
					name = "Regular",
					weight = Weight,
					style = Style,
					assetId = FS.CustomAsset(TtfPath)
				} }
			}
			pcall(function()
				FS.Write(JsonPath, HttpService:JSONEncode(FontData))
			end)
			return Font.new(FS.CustomAsset(JsonPath))
		end

		function CustomFont:Get(Name)
			local JsonPath = Library.Folders.Assets .. "/" .. Name .. ".json"
			if FS.IsFile(JsonPath) then
				return Font.new(FS.CustomAsset(JsonPath))
			end
			return nil
		end
		local Loaded
		pcall(function()
			Loaded = CustomFont:New("Inter", 200, "Regular", {
				Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/InterSemibold.ttf"
			})
		end)
		if not Loaded then
			pcall(function()
				Loaded = CustomFont:Get("Inter")
			end)
		end
		local FallbackFont
		pcall(function()
			FallbackFont = Font.fromEnum(Enum.Font.GothamMedium)
		end)
		if not FallbackFont then
			pcall(function()
				FallbackFont = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
			end)
		end
		Library.Font = Loaded or FallbackFont or Enum.Font.GothamMedium
	end
	Library.Holder = Instances:Create("ScreenGui", {
		Parent = gethui(),
		Name = "EnterSkinUI",
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = 120,
		ResetOnSpawn = false
	})
	Library.GuiInset = 0
	do
		local GuiService = game:GetService("GuiService")
		if GuiService and GuiService.GetGuiInset then
			local Success, TopInset = pcall(function()
				local TopLeft = GuiService:GetGuiInset()
				return TopLeft and TopLeft.Y or 0
			end)
			if Success and type(TopInset) == "number" then
				Library.GuiInset = TopInset
			end
		end
	end
	do
		local Lighting = game:GetService("Lighting")
		local Blur = Lighting:FindFirstChild("EnterSkin_Blur")
		if not Blur then
			Blur = Instance.new("BlurEffect")
			Blur.Name = "EnterSkin_Blur"
			Blur.Size = 0
			Blur.Enabled = false
			Blur.Parent = Lighting
		end
		Library.BlurEffect = Blur
	end
	Library.UnusedHolder = Instances:Create("ScreenGui", {
		Parent = gethui(),
		Name = "\0",
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		Enabled = false,
		ResetOnSpawn = false
	})
	Library.NotifHolder = Instances:Create("Frame", {
		Parent = Library.Holder.Instance,
		Name = "\0",
		BorderColor3 = FromRGB(0, 0, 0),
		AnchorPoint = Vector2New(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2New(1, -12, 0, 12),
		Size = UDim2New(0, 320, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = FromRGB(255, 255, 255)
	})
	Library.NotifItems = { }
	Library.NotifItems["Layout"] = Instances:Create("UIListLayout", {
		Parent = Library.NotifHolder.Instance,
		Name = "\0",
		Padding = UDimNew(0, 12),
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	Library.NotificationPositions = {
		["TopLeft"] = {X = 0, Y = 0},
		["TopCenter"] = {X = 0.5, Y = 0},
		["TopRight"] = {X = 1, Y = 0},
		["CenterLeft"] = {X = 0, Y = 0.5},
		["Center"] = {X = 0.5, Y = 0.5},
		["CenterRight"] = {X = 1, Y = 0.5},
		["BottomLeft"] = {X = 0, Y = 1},
		["BottomCenter"] = {X = 0.5, Y = 1},
		["BottomRight"] = {X = 1, Y = 1}
	}

	Library.ApplyNotificationLayout = function(self)
		local Anchor = Library.NotificationPositions[Library.Settings.NotificationPosition] or Library.NotificationPositions["TopRight"]
		local Horizontal = StringLower(tostring(Library.Settings.NotificationDirection)) == "horizontal"
		local Layout = Library.NotifItems["Layout"]

		local function Inward(AnchorValue, Margin)
			if AnchorValue == 0 then
				return Margin
			end
			if AnchorValue == 1 then
				return -Margin
			end
			return 0
		end
		local OffsetX = Inward(Anchor.X, Library.Settings.NotificationOffsetX)
		local OffsetY = Inward(Anchor.Y, Library.Settings.NotificationOffsetY)
		if Anchor.Y == 0 then
			OffsetY = OffsetY + Library.GuiInset
		end
		Library.NotifHolder.Instance.AnchorPoint = Vector2New(Anchor.X, Anchor.Y)
		Library.NotifHolder.Instance.Position = UDim2New(Anchor.X, OffsetX, Anchor.Y, OffsetY)
		if Horizontal then
			Library.NotifHolder.Instance.Size = UDim2New(0, 0, 0, Library.Settings.NotificationHeight)
			Library.NotifHolder.Instance.AutomaticSize = Enum.AutomaticSize.X
			Layout.FillDirection = Enum.FillDirection.Horizontal
			Layout.VerticalAlignment = Enum.VerticalAlignment.Center
		else
			Library.NotifHolder.Instance.Size = UDim2New(0, Library.Settings.NotificationWidth, 0, 0)
			Library.NotifHolder.Instance.AutomaticSize = Enum.AutomaticSize.Y
			Layout.FillDirection = Enum.FillDirection.Vertical
			Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		end
		Layout.Padding = UDimNew(0, Library.Settings.NotificationGap)
		for Index, Child in ipairs(Library.NotifHolder.Instance:GetChildren()) do
			if Child:IsA("GuiObject") then
				Child.Size = Horizontal
					and UDim2New(0, Library.Settings.NotificationWidth, 0, 0)
					or UDim2New(1, 0, 0, 0)
			end
		end
	end

	Library.SetNotificationLayout = function(self, Options)
		Options = Options or { }
		local Position = Options.Position or Options.position or Library.Settings.NotificationPosition
		if not Library.NotificationPositions[Position] then
			return false, 'Unknown notification position "' .. tostring(Position) .. '".'
		end
		Library.Settings.NotificationPosition = Position
		if Options.Direction or Options.direction then
			Library.Settings.NotificationDirection = Options.Direction or Options.direction
		end
		if Options.OffsetX or Options.offsetx then
			Library.Settings.NotificationOffsetX = Options.OffsetX or Options.offsetx
		end
		if Options.OffsetY or Options.offsety then
			Library.Settings.NotificationOffsetY = Options.OffsetY or Options.offsety
		end
		if Options.Width or Options.width then
			Library.Settings.NotificationWidth = MathClamp(Options.Width or Options.width, 120, 1200)
		end
		if Options.Height or Options.height then
			Library.Settings.NotificationHeight = MathClamp(Options.Height or Options.height, 20, 400)
		end
		if Options.Gap or Options.gap then
			Library.Settings.NotificationGap = MathClamp(Options.Gap or Options.gap, 0, 200)
		end
		if Options.Max or Options.max then
			Library.Settings.MaxNotifications = MathClamp(Options.Max or Options.max, 1, 50)
		end
		self:ApplyNotificationLayout()
		return true
	end

	Library.SetNotificationPosition = function(self, Position)
		return self:SetNotificationLayout({ Position = Position })
	end

	Library.Unload = function(self)
		for Index, Value in ipairs(self.Connections) do
			if Value.Connection then
				pcall(function()
					Value.Connection:Disconnect()
				end)
				Value.Connection = nil
			end
		end
		for Index, Value in ipairs(self.Threads) do
			pcall(CloseCoroutine, Value)
		end
		table.clear(self.Connections)
		table.clear(self.Threads)
		table.clear(self.InputLists)
		table.clear(self.FrameJobs)
		table.clear(self.ScrollFrames)
		table.clear(self.PopupFrames)
		table.clear(self.ThemeItems)
		table.clear(self.ThemeMap)
		table.clear(self.OpenFrames)
		table.clear(self.WarmupQueue)
		table.clear(self.WarmupQueued)
		table.clear(self.WarmupDone)
		table.clear(RestoreQueue)
		self.Unloaded = true
		self:RemoveFrameHook()
		self.ScrollHooked = false
		self.KeybindHooked = false
		self.ConnectionMap = nil
		if self.BlurEffect then
			pcall(function() self.BlurEffect:Destroy() end)
			self.BlurEffect = nil
		end
		if self.Holder then
			self.Holder:Clean()
		end
		Library = nil
		if getgenv().Library == oldLibrary then
			getgenv().Library = nil
		end
		UserInputService.MouseIconEnabled = true
	end

	Library.GetImage = function(self, Image)
		local ImageData = self.Images[Image]
		if not ImageData then
			return
		end
		return FS.CustomAsset(JoinPath(self.Folders.Assets, ImageData[1]))
	end

	Library.Round = function(self, Number, Float)
		Float = tonumber(Float)
		if not Float or Float <= 0 then
			return MathFloor(Number)
		end
		local Multiplier = 1 / Float
		return MathFloor(Number * Multiplier) / Multiplier
	end

	Library.Thread = function(self, Function)
		local NewThread = coroutine.create(Function)
		coroutine.wrap(function()
			coroutine.resume(NewThread)
		end)()
		TableInsert(self.Threads, NewThread)
		return NewThread
	end

	Library.SafeCall = function(self, Function, ...)
		local Arguements = { ... }
		local Success, Result = pcall(Function, TableUnpack(Arguements))
		if not Success then
			warn(Result)
			return false
		end
		return Success
	end

	Library.Once = function(self, Signal, Callback)
		if not Signal or not Callback then
			return
		end
		local Connection
		Connection = Signal:Connect(function(A, B, C)
			if Connection then
				Connection:Disconnect()
				Connection = nil
			end
			if B == nil and C == nil then
				if A == nil then
					pcall(Callback)
				else
					pcall(Callback, A)
				end
			else
				pcall(Callback, A, B, C)
			end
		end)
		return Connection
	end

	Library.GetStats = function(self)
		local InputCounts = { }
		for Signal, List in Pairs(self.InputLists) do
			local Name = Type(Signal) == "string" and Signal or "RBXScriptSignal"
			InputCounts[Name] = (InputCounts[Name] or 0) + #List
		end
		local PageCount = 0
		for _, Win in ipairs(self.Windows) do
			PageCount += #(Win.Pages or { })
		end
		local SectionCount = 0
		for _, Win in ipairs(self.Windows) do
			SectionCount += #(Win.Sections or { })
		end
		return {
			Windows = #self.Windows,
			Pages = PageCount,
			Sections = SectionCount,
			Elements = #self.ElementOrder,
			Connections = #self.Connections,
			Threads = #self.Threads,
			ThemeItems = #self.ThemeItems,
			PopupFrames = #self.PopupFrames,
			ScrollFrames = #self.ScrollFrames,
			FrameJobs = (function()
				local Count = 0
				for _ in Pairs(self.FrameJobs) do
					Count += 1
				end
				return Count
			end)(),
			WarmupPending = #self.WarmupQueue + #self.WarmContainers,
			WarmupDisabled = self.WarmupDisabled,
			TweenGuard = not self.BypassTweenGuard,
			InputHandlers = InputCounts,
			FrameCount = self.FrameCount or 0,
			FramesPerSecond = self.FPS or 0,
			FrameJobMs = (self.JobTime or 0) * 1000,
			FrameHooked = self.FrameHooked
		}
	end
	Library.InputLists = { }
	Library.InputHooked = { }

	local function Dispatch(Signal, Input)
		local List = Library.InputLists[Signal]
		if not List then
			return
		end
		local Count = #List
		if Count == 0 then
			return
		end
		local InputType = nil
		if Input ~= nil and TypeOf(Input) == "InputObject" then
			InputType = Input.UserInputType
		end
		local Dead = 0
		for Index = 1, Count do
			local Entry = List[Index]
			if not Entry.Active or Entry.Callback == nil then
				Dead += 1
				continue
			end
			if InputType ~= nil and Entry.Types ~= nil and not Entry.Types[InputType] then
				continue
			end
			if Input ~= nil then
				pcall(Entry.Callback, Input)
			else
				pcall(Entry.Callback)
			end
			if not Entry.Active or Entry.Callback == nil then
				Dead += 1
			end
		end
		if Dead > 0 then
			local Write = 0
			for Index = 1, Count do
				local Entry = List[Index]
				if Entry.Active and Entry.Callback ~= nil then
					Write += 1
					List[Write] = Entry
				end
			end
for Index = Write + 1, Count do
			List[Index] = nil
		end
	end
	end
	Library.ScrollFrames = { }
	Library.ScrollHooked = false
	local ScrollTweenInfo = Tween:Info(0.13)

	local function HitTest(Frame, X, Y)
		local Position = Frame.AbsolutePosition
		local Size = Frame.AbsoluteSize
		return X >= Position.X and X <= Position.X + Size.X and Y >= Position.Y and Y <= Position.Y + Size.Y
	end

	local function PumpScroll(Input)
		local List = Library.ScrollFrames
		local Count = #List
		if Count == 0 then
			return
		end
		local MousePosition = Library:GetMouse()
		local X = MousePosition.X
		local Y = MousePosition.Y
		local Steps = Input.Position.Z > 0 and -1 or 1
		for Index = Count, 1, -1 do
			local State = List[Index]
			local Frame = State.Frame
			if not Frame or not Frame.Parent then
				table.remove(List, Index)
			elseif not State.Debounce and Frame.Visible and HitTest(Frame, X, Y) then
				State.Debounce = true
				local MaxScroll
				if State.Kind == "List" then
					local Content = 0
					local Layout = State.Layout
					if Layout and Layout.Parent then
						Content = Layout.AbsoluteContentSize.Y
					else
						for _, Child in ipairs(Frame:GetChildren()) do
							if Child:IsA("GuiObject") then
								Content += Child.AbsoluteSize.Y
							end
						end
						Content += State.Gap
					end
					MaxScroll = MathMax(Content - Frame.AbsoluteSize.Y, 0)
					if MaxScroll <= 0 then
						State.Debounce = false
						State.Offset = 0
						Tween:Create(Frame, ScrollTweenInfo, {
							Position = UDim2New(Frame.Position.X.Scale, Frame.Position.X.Offset, Frame.Position.Y.Scale, State.BaseY)
						}, true)
						return
					end
					State.Offset = MathClamp((State.BaseY - Frame.Position.Y.Offset) + (Steps * State.RowSize), 0, MaxScroll)
					Tween:Create(Frame, ScrollTweenInfo, {
						Position = UDim2New(Frame.Position.X.Scale, Frame.Position.X.Offset, Frame.Position.Y.Scale, State.BaseY - State.Offset)
					}, true)
				else
					MaxScroll = Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteWindowSize.Y
					if MaxScroll > 0 then
						local Target = MathClamp(Frame.CanvasPosition.Y + (Steps * 60), 0, MaxScroll)
						Tween:Create(Frame, ScrollTweenInfo, { CanvasPosition = Vector2New(0, Target) }, true)
					end
				end
				Delay(0.05, function()
					State.Debounce = false
				end)
				return
			end
		end
	end

	local function EnsureScrollHook()
		if Library.ScrollHooked then
			return
		end
		Library.ScrollHooked = true
		Library:On(UserInputService.InputChanged, function(Input)
			if Input.UserInputType ~= InputTypeMouseWheel then
				return
			end
			PumpScroll(Input)
		end, TypesWheel)
	end

	-- ---------------------------------------------------------------------
	-- Keybind dispatch: ONE InputBegan + ONE InputEnded handler for the whole
	-- library, resolving the bound key with an O(1) lookup instead of letting
	-- every keybind register its own handler (2N dispatch entries per event).
	-- ---------------------------------------------------------------------
	Library.KeybindLookup = { }
	Library.KeybindFallback = { }
	Library.KeybindHooked = false

	-- All keybinds bound to one key (normally 1; duplicates are preserved so
	-- behaviour matches the old scan-every-keybind dispatch exactly).
	local function AllKeybindsFor(Input)
		local Map = Library.KeybindLookup
		local List = Map[Input.KeyCode]
		if not List then
			List = Map[Input.UserInputType]
		end
		if not List or #List == 0 then
			local Fallback = Library.KeybindFallback
			if #Fallback == 0 then
				return nil
			end
			local Key = tostring(Input.KeyCode)
			local Type_ = tostring(Input.UserInputType)
			List = { }
			for _, Keybind in Next, Fallback do
				if Keybind.Key == Key or Keybind.Key == Type_ then
					TableInsert(List, Keybind)
				end
			end
			if #List == 0 then
				return nil
			end
		end
		return List
	end

	local function BindIndexOf(List, Keybind)
		local n = #List
		for Index = 1, n do
			if List[Index] == Keybind then
				return Index
			end
		end
		return nil
	end

	Library.RegisterKeybind = function(self, Keybind)
		if not Keybind then
			return
		end
		if not Library.KeybindHooked then
			Library.KeybindHooked = true
			Library:On(UserInputService.InputBegan, function(Input)
				local List = AllKeybindsFor(Input)
				if not List then
					return
				end
				for Index = 1, #List do
					local Bind = List[Index]
					if Bind.Value == "None" then
						continue
					end
					if Bind.Mode == "Toggle" then
						Bind:Press()
					elseif Bind.Mode == "Hold" then
						Bind:Press(true)
					elseif Bind.Mode == "Always" then
						Bind:Press(true)
					end
				end
			end)
			Library:On(UserInputService.InputEnded, function(Input)
				local List = AllKeybindsFor(Input)
				if not List then
					return
				end
				for Index = 1, #List do
					local Bind = List[Index]
					if Bind.Value == "None" then
						continue
					end
					if Bind.Mode == "Hold" then
						Bind:Press(false)
					elseif Bind.Mode == "Always" then
						Bind:Press(true)
					end
				end
			end)
		end
		self:RefreshKeybind(Keybind)
	end

	-- Called whenever a keybind's bound key changes so the lookup stays correct.
	Library.RefreshKeybind = function(self, Keybind)
		if not Keybind then
			return
		end
		local Lookup = Library.KeybindLookup
		local Fallback = Library.KeybindFallback
		-- remove any previous registration for this keybind
		for Item, List in Pairs(Lookup) do
			local At = BindIndexOf(List, Keybind)
			if At then
				table.remove(List, At)
				if #List == 0 then
					Lookup[Item] = nil
				end
			end
		end
		local FallAt = BindIndexOf(Fallback, Keybind)
		if FallAt then
			table.remove(Fallback, FallAt)
		end
		-- re-register under the current key
		local Enum_ = Keybind.KeyEnum
		if Enum_ then
			local List = Lookup[Enum_]
			if not List then
				List = { }
				Lookup[Enum_] = List
			end
			TableInsert(List, Keybind)
		else
			TableInsert(Fallback, Keybind)
		end
	end

	Library.EnableListScroll = function(self, Frame, RowSize)
		if not Frame or Frame:GetAttribute("EnterSkinListScroll") then
			return
		end
		Frame:SetAttribute("EnterSkinListScroll", true)
		local State = {
			Frame = Frame,
			Kind = "List",
			BaseY = Frame.Position.Y.Offset,
			Layout = Frame:FindFirstChildOfClass("UIListLayout"),
			Gap = 0,
			RowSize = RowSize and RowSize.Offset or 40,
			Offset = 0,
			Debounce = false
		}
		TableInsert(Library.ScrollFrames, State)
		EnsureScrollHook()
		return State
	end

	Library.On = function(self, Signal, Callback, Types)
		if not Signal or not Callback then
			return
		end
		local List = Library.InputLists[Signal]
		if not List then
			List = { }
			Library.InputLists[Signal] = List
			if not Library.InputHooked[Signal] then
				Library.InputHooked[Signal] = true
				self:Connect(Signal, function(Input)
					Dispatch(Signal, Input)
				end)
			end
		end
		local Lookup = nil
		if Types ~= nil then
			if Type(Types) == "table" then
				Lookup = { }
				for _, Value in Pairs(Types) do
					Lookup[Value] = true
				end
			elseif Types ~= false then
				Lookup = { [Types] = true }
			end
		end
		local Entry = {
			Callback = Callback,
			Active = true,
			Types = Lookup
		}
		TableInsert(List, Entry)
		return Entry
	end

	Library.Off = function(self, Entry)
		if Type(Entry) == "table" then
			Entry.Active = false
			Entry.Callback = nil
			Entry.Types = nil
		end
	end

	Library.OffAll = function(self, Entries)
		if Type(Entries) ~= "table" then
			return
		end
		for Index = 1, #Entries do
			local Entry = Entries[Index]
			if Type(Entry) == "table" then
				Entry.Active = false
				Entry.Callback = nil
			end
		end
		table.clear(Entries)
	end

	Library.UpdateBlur = function(self, IsOpen)
		if not self.BlurEffect or not self.BlurEffect.Parent then
			return
		end
		local TargetBlur = (IsOpen and self.Settings.Blur ~= false) and (self.Settings.BlurSize or 24) or 0
		if TargetBlur > 0 then
			self.BlurEffect.Enabled = true
			TweenService:Create(self.BlurEffect, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = TargetBlur }):Play()
		else
			local T = TweenService:Create(self.BlurEffect, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 0 })
			T.Completed:Connect(function()
				if not (self.FocusedWindow and self.FocusedWindow.IsOpen) then
					self.BlurEffect.Size = 0
					self.BlurEffect.Enabled = false
				end
			end)
			T:Play()
		end
	end

	Library.SetBlur = function(self, Bool, Size)
		self.Settings.Blur = not not Bool
		if Size then
			self.Settings.BlurSize = tonumber(Size) or 24
		end
		if self.FocusedWindow then
			self:UpdateBlur(self.FocusedWindow.IsOpen)
		end
	end

	Library.SetLocked = function(self, Bool)
		self.Locked = not not Bool
		if self.ActiveMobileButton and self.ActiveMobileButton.SetLocked then
			self.ActiveMobileButton:SetLocked(self.Locked)
		end
		for _, Win in ipairs(self.Windows) do
			Win.Locked = self.Locked
		end
		if self.ActiveKeybindList then
			self.ActiveKeybindList.Locked = self.Locked
		end
		self:Notification(
			self.Locked and "UI Locked" or "UI Unlocked",
			self.Locked and "The UI is now locked in place. Dragging is disabled." or "The UI can now be dragged freely.",
			2.5,
			self.Locked and "Warning" or "Success"
		)
	end

	Library.Connect = function(self, Event, Callback, Name)
		if not Event or not Callback then
			return
		end
		ConnectionCounter += 1
		Name = Name or ("Connection" .. ConnectionCounter)
		local Success, Connection = pcall(Event.Connect, Event, Callback)
		local NewConnection = {
			Event = Event,
			Callback = Callback,
			Name = Name,
			Connection = Success and Connection or nil
		}
		TableInsert(self.Connections, NewConnection)
		self.ConnectionMap = self.ConnectionMap or { }
		self.ConnectionMap[Name] = NewConnection
		return NewConnection
	end

	Library.Disconnect = function(self, Name)
		local Map = self.ConnectionMap
		local Entry = Map and Map[Name]
		if not Entry then
			for Index, Connection in ipairs(self.Connections) do
				if Connection.Name == Name then
					Entry = Connection
					table.remove(self.Connections, Index)
					break
				end
			end
			return
		end
		Map[Name] = nil
		if Entry.Connection then
			pcall(function()
				Entry.Connection:Disconnect()
			end)
		end
		Entry.Connection = nil
		Entry.Callback = nil
		for Index, Connection in ipairs(self.Connections) do
			if Connection == Entry then
				table.remove(self.Connections, Index)
				break
			end
		end
	end
	local FlagSeed = math.random(100000, 999999)

	Library.NextFlag = function(self)
		self.UnnamedFlags = self.UnnamedFlags + 1
		return "flag_number_" .. self.UnnamedFlags .. "_" .. FlagSeed
	end

	Library.AddToTheme = function(self, Item, Properties)
		Item = Item.Instance or Item
		if not Item then
			return
		end
		local Existing = self.ThemeMap[Item]
		if Existing then
			Existing.Properties = Properties
		else
			Existing = {
				Item = Item,
				Properties = Properties,
				Index = #self.ThemeItems + 1
			}
			TableInsert(self.ThemeItems, Existing)
			self.ThemeMap[Item] = Existing
		end
		for Property, Value in Pairs(Properties) do
			if Type(Value) == "string" then
				Item[Property] = self.Theme[Value]
			elseif Type(Value) == "function" then
				Item[Property] = Value()
			end
		end
	end

	Library.RemoveFromTheme = function(self, Item)
		Item = Item.Instance or Item
		local Entry = Item and self.ThemeMap[Item]
		if not Entry then
			return
		end
		Entry.Properties = nil
		self.ThemeMap[Item] = nil
		local Items = self.ThemeItems
		local Last = #Items
		local Index = Entry.Index
		if Index and Items[Index] == Entry then
			Items[Index] = Items[Last]
			if Items[Index] then
				Items[Index].Index = Index
			end
			Items[Last] = nil
		end
	end

	Library.GetConfig = function(self)
		local Config = { }
		Library:SafeCall(function()
			for Index, Value in Library.Flags do
				if type(Value) == "table" and Value.Key then
					Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode}
				elseif type(Value) == "table" and Value.Color then
					Config[Index] = {Color = "#" .. Value.Color, Alpha = Value.Alpha}
				else
					Config[Index] = Value
				end
			end
		end)
		return HttpService:JSONEncode(Config)
	end

	Library.LoadConfig = function(self, Config)
		local DecodeSuccess, Decoded = pcall(function()
			return HttpService:JSONDecode(Config)
		end)
		if not DecodeSuccess then
			return false, "Config is not valid JSON."
		end
		local Success, Result = Library:SafeCall(function()
			for Index, Value in Decoded do
				local SetFunction = Library.SetFlags[Index]
				if not SetFunction then
					continue
				end
				if type(Value) == "table" and Value.Key then
					SetFunction(Value)
				elseif type(Value) == "table" and Value.Color then
					SetFunction(Value.Color, Value.Alpha)
				else
					SetFunction(Value)
				end
			end
		end)
		return Success, Result
	end

	Library.DeleteConfig = function(self, Config)
		if FS.IsFile(JoinPath(Library.Folders.Configs, Config)) then
			FS.Delete(JoinPath(Library.Folders.Configs, Config))
		end
	end

	Library.ConfigPath = function(self, Name)
		local SafeName = tostring(Name or "")
		if SafeName == "" then
			return nil
		end
		if not StringFind(SafeName, tostring(game.GameId), 1, true) then
			SafeName = SafeName .. tostring(game.GameId) .. ".json"
		end
		return Library.Folders.Configs .. "/" .. SafeName
	end

	Library.SaveConfig = function(self, Name, Silent)
		local Path = self:ConfigPath(Name)
		if not Path then
			return false, "No config name provided."
		end
		local Success, Error = Library:SafeCall(function()
			FS.Write(Path, Library:GetConfig())
		end)
		if Success then
			Library.CurrentConfig = tostring(Name)
			if not Silent then
				Library:Notification("Success!", "Succesfully saved config.", 5, "Success")
			end
		elseif not Silent then
			Library:Notification("Error!", "Failed to save config. Report this to the developers:\n" .. tostring(Error), 5, "Error")
		end
		return Success, Error
	end

	Library.AutoSave = function(self)
		if not Library.Settings.AutoSave or not Library.CurrentConfig then
			return
		end
		self:SaveConfig(Library.CurrentConfig, true)
	end

	Library.RenameConfig = function(self, OldName, NewName)
		local OldPath = self:ConfigPath(OldName)
		local NewPath = self:ConfigPath(NewName)
		if not OldPath or not NewPath then
			return false, "Both config names must be provided."
		end
		if OldPath == NewPath then
			return false, "New name matches the old name."
		end
		if not FS.IsFile(OldPath) then
			return false, "Config '" .. tostring(OldName) .. "' does not exist."
		end
		if FS.IsFile(NewPath) then
			return false, "Config '" .. tostring(NewName) .. "' already exists."
		end
		local Success, Error = Library:SafeCall(function()
			FS.Write(NewPath, FS.Read(OldPath))
			FS.Delete(OldPath)
		end)
		if not Success then
			return false, Error
		end
		if Library.CurrentConfig == tostring(OldName) then
			Library.CurrentConfig = tostring(NewName)
		end
		return true
	end

	Library.CopyToClipboard = function(self, Text)
		if not setclipboard then
			return false, "Clipboard is not available in this executor."
		end
		pcall(setclipboard, tostring(Text or ""))
		return true
	end

	Library.PasteFromClipboard = function(self)
		if not getclipboard then
			return nil, "Clipboard is not available in this executor."
		end
		local Ok, Value = pcall(getclipboard)
		return Ok and Value or nil
	end

	Library.RefreshConfigsList = function(self, Element)
		local CurrentList = {}
		local List = {}
		local ConfigFolderName = string.gsub(self.Folders.Configs, self.Folders.Directory .. "/", "")
		for Index, Value in ipairs(FS.List(self.Folders.Configs)) do
			local v = tostring(Value):gsub("\\", "/")
			local root = (self.Folders.Directory .. "/" .. ConfigFolderName .. "/")
			root = root:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
			local FileName = v:gsub("^" .. root, "")
			if not string.find(FileName, tostring(game.GameId), 1, true) then
				continue
			end
			local RealName = string.gsub(FileName, tostring(game.GameId), "")
			List[Index] = { Name = RealName, RealName = FileName }
		end
		local IsNew = #List ~= #CurrentList
		if not IsNew then
			for Index = 1, #List do
				if List[Index] ~= CurrentList[Index] then
					IsNew = true
					break
				end
			end
		end
		if IsNew then
			CurrentList = List
			Element:Clear()
			for _, Value in CurrentList do
				Element:Add(Value.Name)
			end
		end
	end

	Library.ChangeItemTheme = function(self, Item, Properties)
		Item = Item.Instance or Item
		local Entry = Item and self.ThemeMap[Item]
		if not Entry then
			return
		end
		Entry.Properties = Properties
	end

	local function SweepTheme(self, Keys)
		local Theme = self.Theme
		local Count = #Keys
		local KeySet = { }
		for Index = 1, Count do
			KeySet[Keys[Index]] = true
		end
		local Items = self.ThemeItems
		local Total = #Items
		for Index = 1, Total do
			local Item = Items[Index]
			local Properties = Item.Properties
			if Properties then
				for Property, Value in Pairs(Properties) do
					if Type(Value) == "string" then
						if KeySet[Value] then
							local Object = Item.Item
							if Object and Object.Parent then
								Object[Property] = Theme[Value]
							end
						end
					elseif Type(Value) == "function" then
						local Object = Item.Item
						if Object and Object.Parent then
							Object[Property] = Value()
						end
					end
				end
			end
		end
	end

	Library.ChangeTheme = function(self, Theme, Color)
		self.Theme[Theme] = Color
		SweepTheme(self, { Theme })
	end

	Library.ApplyTheme = function(self, ThemeTable)
		if Type(ThemeTable) ~= "table" then
			return false
		end
		local Keys = { }
		local Count = 0
		for Key, Color in Pairs(ThemeTable) do
			self.Theme[Key] = Color
			Count += 1
			Keys[Count] = Key
		end
		if Count > 0 then
			SweepTheme(self, Keys)
		end
		for Index = 1, Count do
			local Picker = Library.ThemeColorpickers[Keys[Index]]
			if Picker and Type(Picker.Set) == "function" then
				Library:SafeCall(function()
					Picker:Set(ThemeTable[Keys[Index]])
				end)
			end
		end
		return true
	end

	Library.GetTheme = function(self)
		local Config = { }
		Library:SafeCall(function()
			for Index, Value in Library.Flags do
				if type(Value) == "table" and Value.Color and StringFind(Index, "Theme") then
					Config[Index] = {Color = "#" .. Value.Color, Alpha = Value.Alpha}
				end
			end
		end)
		return HttpService:JSONEncode(Config)
	end

	Library.LoadTheme = function(self, Config)
		local Decoded = HttpService:JSONDecode(Config)
		local Success, Result = Library:SafeCall(function()
			for Index, Value in Decoded do
				local SetFunction = Library.SetFlags[Index]
				if not SetFunction then
					continue
				end
				if type(Value) == "table" and Value.Color and StringFind(Index, "Theme") then
					SetFunction(Value.Color, Value.Alpha)
				end
			end
		end)
		return Success, Result
	end

	Library.DeleteTheme = function(self, Config)
		if FS.IsFile(JoinPath(Library.Folders.Themes, Config)) then
			FS.Delete(JoinPath(Library.Folders.Themes, Config))
		end
	end

	Library.SaveTheme = function(self, Config)
		if FS.IsFile(JoinPath(Library.Folders.Themes, Config .. ".json")) then
			FS.Write(JoinPath(Library.Folders.Themes, Config .. ".json"), Library:GetTheme())
		end
	end

	Library.RefreshThemesList = function(self, Element)
		local CurrentList = {}
		local List = {}
		local ConfigFolderName = string.gsub(self.Folders.Themes, self.Folders.Directory .. "/", "")
		for Index, Value in ipairs(FS.List(self.Folders.Themes)) do
			local v = tostring(Value):gsub("\\", "/")
			local root = (self.Folders.Directory .. "/" .. ConfigFolderName .. "/")
			root = root:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
			local FileName = v:gsub("^" .. root, "")
			List[Index] = FileName
		end
		local IsNew = #List ~= #CurrentList
		if not IsNew then
			for Index = 1, #List do
				if List[Index] ~= CurrentList[Index] then
					IsNew = true
					break
				end
			end
		end
		if IsNew then
			CurrentList = List
			Element:Refresh(CurrentList)
		end
	end

	Library.QueueAutoFit = function(self, Callback, Key)
		if not Callback then
			return
		end
		if not self.AutoFitPending then
			self.AutoFitPending = { }
			self.AutoFitKeys = { }
			self:AddFrameJob("AutoFit", function()
				local Queue = self.AutoFitPending
				self.AutoFitPending = nil
				self.AutoFitKeys = nil
				if not Queue then
					return
				end
				for Index = 1, #Queue do
					pcall(Queue[Index])
				end
			end)
		end
		local Keys = self.AutoFitKeys
		if Key ~= nil and Keys then
			if Keys[Key] then
				return
			end
			Keys[Key] = true
		end
		TableInsert(self.AutoFitPending, Callback)
	end

	Library.IsShown = function(self, Instance)
		if not Instance then
			return false
		end
		local Root = self.Holder and self.Holder.Instance
		local Current = Instance
		while Current and Current ~= Root do
			if Current:IsA("GuiObject") and not Current.Visible then
				return false
			end
			Current = Current.Parent
		end
		return true
	end

	Library.IsMouseOverFrame = function(self, Frame, XOffset, YOffset, Input)
		local Instance = Frame
		if Type(Frame) == "table" then
			Instance = Frame.Instance
		end
		if not Instance then
			return false
		end
		-- Prefer the exact position of the input event when we have it: the cached
		-- cursor position can be a frame stale, which mis-detects "inside the popup".
		local MousePosition
		if Input and Input.Position then
			MousePosition = Input.Position
		else
			MousePosition = Library:GetMouse()
		end
		if XOffset or YOffset then
			MousePosition = Vector2New(MousePosition.X + (XOffset or 0), MousePosition.Y + (YOffset or 0))
		end
		local Position = Instance.AbsolutePosition
		local Size = Instance.AbsoluteSize
		return MousePosition.X >= Position.X and MousePosition.X <= Position.X + Size.X
			and MousePosition.Y >= Position.Y and MousePosition.Y <= Position.Y + Size.Y
	end

	Library.EnableSmoothScroll = function(self, ScrollFrame)
		if not ScrollFrame or ScrollFrame:GetAttribute("EnterSkinSmoothScroll") then
			return
		end
		ScrollFrame:SetAttribute("EnterSkinSmoothScroll", true)
		TableInsert(Library.ScrollFrames, {
			Frame = ScrollFrame,
			Kind = "Canvas",
			Offset = 0,
			Debounce = false
		})
		EnsureScrollHook()
	end

	Library.FindKeybindConflict = function(self, Key, ExceptFlag)
		if not Key then
			return nil
		end
		for Flag, Value in Library.Flags do
			if Flag ~= ExceptFlag and type(Value) == "table" and Value.Key ~= nil and Value.Mode ~= nil then
				if tostring(Value.Key) == tostring(Key) then
					return Flag
				end
			end
		end
		return nil
	end
	local Components: any = { } do

		Components.Toggle = function(Data)
			local Toggle = {
				Value = false,
				Flag = Data.Flag,
				Disabled = false,
				OnChanged = nil
			}
			local Items = { } do
				Items["Toggle"] = Instances:Create("TextButton", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "",
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2New(1, 0, 0, 20),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Toggle"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					TextTransparency = 0.4000000059604645,
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2New(0, 0, 0, 15),
					AnchorPoint = Vector2New(0, 0.5),
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Position = UDim2New(0, 0, 0.5, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Indicator"] = Instances:Create("Frame", {
					Parent = Items["Toggle"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(1, 0),
					Position = UDim2New(1, 0, 0, 0),
					Size = UDim2New(0, 40, 0, 20),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["Indicator"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["Indicator"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Instances:Create("UIGradient", {
					Parent = Items["Indicator"].Instance,
					Name = "\0",
					Rotation = 90,
					Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))}
				}):AddToTheme({Color = function()
					return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Gradient"])}
				end})
				Items["Circle"] = Instances:Create("Frame", {
					Parent = Items["Indicator"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					BackgroundTransparency = 0.4000000059604645,
					AnchorPoint = Vector2New(0, 0),
					Position = UDim2New(0, 3, 0, 3),
					Size = UDim2New(0, 14, 0, 14),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UICorner", {
					Parent = Items["Circle"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Items["SubElementsHolder"] = Instances:Create("Frame", {
					Parent = Items["Toggle"].Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2New(1, 0),
					Size = UDim2New(0, 0, 1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					Position = UDim2New(1, -46, 0, 0)
				})
				Instances:Create("UIListLayout", {
					Parent = Items["SubElementsHolder"].Instance,
					Name = "\0",
					Padding = UDimNew(0, 5),
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal
				})
			end
			local SwitchInfo = Tween.InfoCache["0.18_Quart_Out"] or Tween:Info(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			function Toggle:Set(Bool)
				if self.Disabled then
					return
				end
				self.Value = Bool
				Library.Flags[self.Flag] = self.Value
				local Shown = Library:IsShown(Items["Toggle"].Instance)
				if self.Value then
					Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
					if Shown then
						Items["Indicator"]:Tween(SwitchInfo, {BackgroundColor3 = Library.Theme.Accent})
						Items["Circle"]:Tween(SwitchInfo, {BackgroundTransparency = 0, Position = UDim2New(0, 23, 0, 3)})
						Items["Text"]:Tween(SwitchInfo, {TextTransparency = 0})
					else
						Items["Indicator"].Instance.BackgroundColor3 = Library.Theme.Accent
						Items["Circle"].Instance.BackgroundTransparency = 0
						Items["Circle"].Instance.Position = UDim2New(0, 23, 0, 3)
						Items["Text"].Instance.TextTransparency = 0
					end
				else
					Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Element"})
					if Shown then
						Items["Indicator"]:Tween(SwitchInfo, {BackgroundColor3 = Library.Theme.Element})
						Items["Circle"]:Tween(SwitchInfo, {BackgroundTransparency = 0.4, Position = UDim2New(0, 3, 0, 3)})
						Items["Text"]:Tween(SwitchInfo, {TextTransparency = 0.4})
					else
						Items["Indicator"].Instance.BackgroundColor3 = Library.Theme.Element
						Items["Circle"].Instance.BackgroundTransparency = 0.4
						Items["Circle"].Instance.Position = UDim2New(0, 3, 0, 3)
						Items["Text"].Instance.TextTransparency = 0.4
					end
				end
				if Data.Callback then
					Library:SafeCall(Data.Callback, self.Value)
				end
				if self.OnChanged then
					self.OnChanged(self.Value)
				end
			end
			function Toggle:SetText(Text)
				Text = tostring(Text)
				Items["Text"].Instance.Text = Text
			end
			function Toggle:SetVisible(Bool)
				Items["Toggle"].Instance.Visible = Bool
			end
			function Toggle:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["Indicator"]:Tween(nil, {BackgroundTransparency = 0.6})
					Items["Circle"]:Tween(nil, {BackgroundTransparency = 0.6})
				else
					if self.Value then
						Items["Text"]:Tween(nil, {TextTransparency = 0})
						Items["Circle"]:Tween(nil, {BackgroundTransparency = 0})
						Items["Indicator"]:Tween(nil, {BackgroundTransparency = 0})
					else
						Items["Text"]:Tween(nil, {TextTransparency = 0.4})
						Items["Circle"]:Tween(nil, {BackgroundTransparency = 0.4})
						Items["Indicator"]:Tween(nil, {BackgroundTransparency = 0})
					end
				end
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Toggle"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
	TableInsert(PageSearchData, SearchData)
			end
			Items["Toggle"]:Connect("MouseButton1Down", function()
				Toggle:Set(not Toggle.Value)
			end)
			if Data.Disabled then
				Toggle:SetDisabled(Data.Disabled)
			end
			Toggle:Set(Data.Default)
			Library.SetFlags[Toggle.Flag] = function(Value)
				Toggle:Set(Value)
			end
			return Toggle, Items
		end

		Components.Checkbox = function(Data)
			local Checkbox = {
				Value = false,
				Flag = Data.Flag,
				Disabled = false,
				OnChanged = nil
			}
			Library.Flags[Checkbox.Flag] = nil
			local Items = { } do
				Items["Checkbox"] = Instances:Create("TextButton", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "",
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2New(1, 0, 0, 20),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Checkbox"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					TextTransparency = 0.4000000059604645,
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2New(0, 0, 0, 15),
					AnchorPoint = Vector2New(0, 0.5),
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Position = UDim2New(0, 0, 0.5, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Indicator"] = Instances:Create("Frame", {
					Parent = Items["Checkbox"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(1, 0),
					Position = UDim2New(1, 0, 0, 0),
					Size = UDim2New(0, 20, 0, 20),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["Indicator"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["Indicator"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Instances:Create("UIGradient", {
					Parent = Items["Indicator"].Instance,
					Name = "\0",
					Rotation = 90,
					Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))}
				}):AddToTheme({Color = function()
					return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Gradient"])}
				end})
				Items["Check"] = Instances:Create("TextLabel", {
					Parent = Items["Indicator"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					Text = "\u{2713}",
					TextSize = 14,
					TextColor3 = FromRGB(255, 255, 255),
					TextTransparency = 1,
					Size = UDim2New(1, 0, 1, 0),
					AnchorPoint = Vector2New(0, 0),
					Position = UDim2New(0, 0, 0, -1),
					ZIndex = 3,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["SubElementsHolder"] = Instances:Create("Frame", {
					Parent = Items["Checkbox"].Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2New(1, 0),
					Size = UDim2New(0, 0, 1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					Position = UDim2New(1, -24, 0, 0)
				})
				Instances:Create("UIListLayout", {
					Parent = Items["SubElementsHolder"].Instance,
					Name = "\0",
					Padding = UDimNew(0, 5),
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal
				})
			end
			local CheckInfo = Tween.InfoCache["0.18_Quart_Out"] or Tween:Info(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			function Checkbox:Set(Bool)
				if self.Disabled then
					return
				end
				self.Value = Bool
				Library.Flags[self.Flag] = self.Value
				local Shown = Library:IsShown(Items["Checkbox"].Instance)
				if self.Value then
					Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
					if Shown then
						Items["Indicator"]:Tween(CheckInfo, {BackgroundColor3 = Library.Theme.Accent})
						Items["Check"]:Tween(CheckInfo, {TextTransparency = 0})
						Items["Text"]:Tween(CheckInfo, {TextTransparency = 0})
					else
						Items["Indicator"].Instance.BackgroundColor3 = Library.Theme.Accent
						Items["Check"].Instance.TextTransparency = 0
						Items["Text"].Instance.TextTransparency = 0
					end
				else
					Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Element"})
					if Shown then
						Items["Indicator"]:Tween(CheckInfo, {BackgroundColor3 = Library.Theme.Element})
						Items["Check"]:Tween(CheckInfo, {TextTransparency = 1})
						Items["Text"]:Tween(CheckInfo, {TextTransparency = 0.4})
					else
						Items["Indicator"].Instance.BackgroundColor3 = Library.Theme.Element
						Items["Check"].Instance.TextTransparency = 1
						Items["Text"].Instance.TextTransparency = 0.4
					end
				end
				if Data.Callback then
					Library:SafeCall(Data.Callback, self.Value)
				end
				if self.OnChanged then
					self.OnChanged(self.Value)
				end
			end
			function Checkbox:SetText(Text)
				Text = tostring(Text)
				Items["Text"].Instance.Text = Text
			end
			function Checkbox:SetVisible(Bool)
				Items["Toggle"].Instance.Visible = Bool
			end
			function Checkbox:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["Indicator"]:Tween(nil, {BackgroundTransparency = 0.6})
					Items["Check"]:Tween(nil, {ImageTransparency = 1})
				else
					if self.Value then
						Items["Text"]:Tween(nil, {TextTransparency = 0})
						Items["Indicator"]:Tween(nil, {BackgroundTransparency = 0})
						Items["Check"]:Tween(nil, {ImageTransparency = 0})
					else
						Items["Text"]:Tween(nil, {TextTransparency = 0.4})
						Items["Indicator"]:Tween(nil, {BackgroundTransparency = 0})
						Items["Check"]:Tween(nil, {ImageTransparency = 1})
					end
				end
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Checkbox"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
	TableInsert(PageSearchData, SearchData)
			end
			Items["Checkbox"]:Connect("MouseButton1Down", function()
				Checkbox:Set(not Checkbox.Value)
			end)
			if Data.Disabled then
				Checkbox:SetDisabled(Data.Disabled)
			end
			Checkbox:Set(Data.Default)
			Library.SetFlags[Checkbox.Flag] = function(Value)
				Checkbox:Set(Value)
			end
			return Checkbox, Items
		end

		Components.Button = function(Data)
			local Button = { }
			local Items = { } do
				Items["Button"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 25),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UIListLayout", {
					Parent = Items["Button"].Instance,
					Name = "\0",
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					Padding = UDimNew(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalFlex = Enum.UIFlexAlignment.Fill
				})
			end
			function Button:Add(Text, Callback, Disabled)
				local NewButton = {
					Disabled = false,
					OnPressed = nil
				}
				local SubItems = { } do
					SubItems["NewButton"] = Instances:Create("TextButton", {
						Parent = Items["Button"].Instance,
						Name = "\0",
						FontFace = Library.Font,
						TextColor3 = FromRGB(0, 0, 0),
						BorderColor3 = FromRGB(0, 0, 0),
						Text = "",
						AutoButtonColor = false,
						BorderSizePixel = 0,
						Size = UDim2New(0, 200, 0, 50),
						ZIndex = 2,
						TextSize = 14,
						BackgroundColor3 = FromRGB(36, 32, 39)
					}); SubItems["NewButton"]:AddToTheme({BackgroundColor3 = "Element"})
					Instances:Create("UICorner", {
						Parent = SubItems["NewButton"].Instance,
						Name = "\0",
						CornerRadius = UDimNew(0, 5)
					})
					Instances:Create("UIGradient", {
						Parent = SubItems["NewButton"].Instance,
						Name = "\0",
						Rotation = 90,
						Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))}
					}):AddToTheme({Color = function()
						return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Gradient"])}
					end})
					SubItems["Text"] = Instances:Create("TextLabel", {
						Parent = SubItems["NewButton"].Instance,
						Name = "\0",
						FontFace = Library.Font,
						TextColor3 = FromRGB(255, 255, 255),
						BorderColor3 = FromRGB(0, 0, 0),
						Text = Text,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2New(1, 0, 1, 0),
						ZIndex = 2,
						TextSize = 14,
						BackgroundColor3 = FromRGB(255, 255, 255)
					}); SubItems["Text"]:AddToTheme({TextColor3 = "Text"})
				end
				function NewButton:Press()
					if self.Disabled then
						return
					end
					SubItems["NewButton"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
					SubItems["NewButton"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})
					task.wait(0.1)
					SubItems["NewButton"]:ChangeItemTheme({BackgroundColor3 = "Element"})
					SubItems["NewButton"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
					if Callback then
						Library:SafeCall(Callback)
					end
					if self.OnPressed then
						self.OnPressed()
					end
				end
				function NewButton:SetText(Text)
					Text = tostring(Text)
					SubItems["Text"].Instance.Text = Text
				end
				function NewButton:SetVisible(Bool)
					SubItems["NewButton"].Instance.Visible = Bool
				end
				function NewButton:SetDisabled(Bool)
					self.Disabled = Bool
					if self.Disabled then
						SubItems["NewButton"]:Tween(nil, {BackgroundTransparency = 0.6})
						SubItems["Text"]:Tween(nil, {TextTransparency = 0.6})
					else
						SubItems["NewButton"]:Tween(nil, {BackgroundTransparency = 0})
						SubItems["Text"]:Tween(nil, {TextTransparency = 0})
					end
				end
				local SearchData = {
					Name = Text,
					Item = SubItems["NewButton"]
				}
				local PageSearchData = Library.SearchItems[Data.Page]
				if PageSearchData then
	TableInsert(PageSearchData, SearchData)
				end
				SubItems["NewButton"]:Connect("MouseButton1Down", function()
					NewButton:Press()
				end)
				if Disabled then
					NewButton:SetDisabled(Disabled)
				end
				return NewButton, SubItems
			end
			function Button:SetVisible(Bool)
				Items["Button"].Instance.Visible = Bool
			end
			return Button, Items
		end

		Components.Slider = function(Data)
			local Slider = {
				Value = 0,
				Flag = Data.Flag,
				Sliding = false,
				OnChanged = nil,
				Disabled = false
			}
			local Items = { } do
				Items["Slider"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 35),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Slider"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Size = UDim2New(0, 0, 0, 15),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["RealSlider"] = Instances:Create("TextButton", {
					Parent = Items["Slider"].Instance,
					AutoButtonColor = false,
					Text = "",
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0, 1),
					Position = UDim2New(0, 0, 1, 0),
					Size = UDim2New(1, 0, 0, 15),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["RealSlider"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["RealSlider"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Instances:Create("UIGradient", {
					Parent = Items["RealSlider"].Instance,
					Name = "\0",
					Rotation = 90,
					Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))}
				}):AddToTheme({Color = function()
					return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Gradient"])}
				end})
				Items["Accent"] = Instances:Create("Frame", {
					Parent = Items["RealSlider"].Instance,
					Name = "\0",
					Size = UDim2New(0.5, 0, 1, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(59, 130, 246)
				}); Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
				Instances:Create("UIGradient", {
					Parent = Items["Accent"].Instance,
					Name = "\0",
					Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(163, 163, 163))}
				})
				Instances:Create("UICorner", {
					Parent = Items["Accent"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Items["Drag"] = Instances:Create("Frame", {
					Parent = Items["Accent"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(1, 0.5),
					Position = UDim2New(1, 0, 0.5, 0),
					Size = UDim2New(0, 7, 1, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UICorner", {
					Parent = Items["Drag"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Items["Value"] = Instances:Create("TextLabel", {
					Parent = Items["Slider"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "50s",
					AutomaticSize = Enum.AutomaticSize.X,
					AnchorPoint = Vector2New(1, 0),
					Size = UDim2New(0, 0, 0, 15),
					BackgroundTransparency = 1,
					Position = UDim2New(1, 0, 0, 0),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Value"]:AddToTheme({TextColor3 = "Text"})
			end
			local function SnapValue(Value)
				Value = tonumber(Value)
				if not Value or Value ~= Value then
					Value = Data.Min
				end
				local Snapped = MathClamp(Value, Data.Min, Data.Max)
				if Data.Step and Data.Step > 0 then
					local Steps = MathFloor(((Snapped - Data.Min) / Data.Step) + 0.5)
					Snapped = Data.Min + (Steps * Data.Step)
				end
				return MathClamp(Library:Round(Snapped, Data.Decimals), Data.Min, Data.Max)
			end
			local function FormatValue(Value)
				if Data.Format then
					local FormatSuccess, FormatResult = pcall(StringFormat, Data.Format, Value)
					if FormatSuccess then
						return FormatResult
					end
				end
				return tostring(Value)
			end
			function Slider:Set(Value)
				if self.Disabled then
					return
				end
				self.Value = SnapValue(Value)
				Library.Flags[self.Flag] = self.Value
				local Goal = UDim2New((self.Value - Data.Min) / (Data.Max - Data.Min), 0, 1, 0)
				if self.Sliding then
					Items["Accent"].Instance.Size = Goal
				elseif Library:IsShown(Items["RealSlider"].Instance) then
					Items["Accent"]:Tween(Tween:Info(0.22), {Size = Goal})
				else
					Items["Accent"].Instance.Size = Goal
				end
				local Label = StringFormat("%s%s", FormatValue(self.Value), Data.Suffix)
				if Items["Value"].Instance.Text ~= Label then
					Items["Value"].Instance.Text = Label
				end
				if Data.Callback then
					Library:SafeCall(Data.Callback, self.Value)
				end
				if self.OnChanged then
					self.OnChanged(self.Value)
				end
			end
			function Slider:SetText(Text)
				Text = tostring(Text)
				Items["Text"].Instance.Text = Text
			end
			function Slider:SetMin(Value)
				Data.Min = Value
			end
			function Slider:SetMax(Value)
				Data.Max = Value
			end
			function Slider:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					for Index, Value in Items do
						if Value.Instance:IsA("Frame") and Value.Instance.BackgroundColor3 ~= FromRGB(255, 255, 255) then
							Value:Tween(nil, {BackgroundTransparency = 0.6})
						elseif Value.Instance:IsA("TextLabel") then
							Value:Tween(nil, {TextTransparency = 0.6})
						end
					end
				else
					for Index, Value in Items do
						if Value.Instance:IsA("Frame") then
							Value:Tween(nil, {BackgroundTransparency = 0})
						elseif Value.Instance:IsA("TextLabel") then
							Value:Tween(nil, {TextTransparency = 0})
						end
					end
				end
			end
			function Slider:SetVisible(Bool)
				Items["Slider"].Instance.Visible = Bool
			end
			function Slider:SetSuffix(Suffix)
				Suffix = tostring(Suffix)
				Data.Suffix = Suffix
			end
			function Slider:SetStep(Step)
				Data.Step = tonumber(Step) or 0
			end
			function Slider:SetFormat(Format)
				Data.Format = Format
				Slider:Set(self.Value)
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Slider"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
	TableInsert(PageSearchData, SearchData)
			end
			Items["RealSlider"]:Connect("InputBegan", function(Input)
				if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
					Slider.Sliding = true
					local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
					local Value = ((Data.Max - Data.Min) * SizeX) + Data.Min
					Slider:Set(Value)
					Input.Changed:Connect(function()
						if Input.UserInputState == Enum.UserInputState.End then
							Slider.Sliding = false
						end
					end)
				end
			end)
			Library:On(UserInputService.InputChanged, function(Input)
				if Input.UserInputType == InputTypeMouseMovement or Input.UserInputType == InputTypeTouch then
					if Slider.Sliding then
						local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
						local Value = ((Data.Max - Data.Min) * SizeX) + Data.Min
						Slider:Set(Value)
					end
				end
			end, TypesMove)
			if Data.Disabled then
				Slider:SetDisabled(Data.Disabled)
			end
			if Data.Default then
				Slider:Set(Data.Default)
			end
			Library.SetFlags[Slider.Flag] = function(Value)
				Slider:Set(Value)
			end
			return Slider, Items
		end

		Components.Dropdown = function(Data)
			local Dropdown: any = {
				Value = nil :: any,
				Flag = Data.Flag,
				IsOpen = false,
				Disabled = false,
				OnChanged = nil,
				Options = { }
			}
			local Items = { } do
				Items["Dropdown"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 25),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Dropdown"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					AnchorPoint = Vector2New(0, 0.5),
					Size = UDim2New(0, 0, 0, 15),
					BackgroundTransparency = 1,
					Position = UDim2New(0, 0, 0.5, 0),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["RealDropdown"] = Instances:Create("TextButton", {
					Parent = Items["Dropdown"].Instance,
					Text = "",
					AutoButtonColor = false,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(1, 0),
					Position = UDim2New(1, 0, 0, 0),
					Size = UDim2New(0, not IsMobile and 135 or 75, 0, 25),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["RealDropdown"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Instances:Create("UIGradient", {
					Parent = Items["RealDropdown"].Instance,
					Name = "\0",
					Rotation = 90,
					Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))}
				}):AddToTheme({Color = function()
					return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Gradient"])}
				end})
				Items["Value"] = Instances:Create("TextLabel", {
					Parent = Items["RealDropdown"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "--",
					TextTruncate = Enum.TextTruncate.AtEnd,
					Size = UDim2New(1, -25, 0, 15),
					AnchorPoint = Vector2New(0, 0.5),
					Position = UDim2New(0, 8, 0.5, 0),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Value"]:AddToTheme({TextColor3 = "Text"})
				Items["Icon"] = Instances:Create("ImageLabel", {
					Parent = Items["RealDropdown"].Instance,
					Name = "\0",
					ImageColor3 = FromRGB(59, 130, 246),
					ScaleType = Enum.ScaleType.Fit,
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(0, 25, 0, 25),
					AnchorPoint = Vector2New(1, 0.5),
					Image = "rbxassetid://96215562143920",
					BackgroundTransparency = 1,
					Position = UDim2New(1, -1, 0.5, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Icon"]:AddToTheme({ImageColor3 = "Accent"})
				Items["OptionHolder"] = Instances:Create("ScrollingFrame", {
					Parent = Library.Holder.Instance,
					Name = "\0",
					Visible = false,
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					AnchorPoint = Vector2New(0, 0),
					ZIndex = 12,
					BorderSizePixel = 0,
					CanvasSize = UDim2New(0, 0, 0, 0),
					ScrollBarImageColor3 = FromRGB(59, 130, 246),
					MidImage = "rbxassetid://128693616966482",
					BorderColor3 = FromRGB(0, 0, 0),
					ScrollBarThickness = 3,
					TopImage = "rbxassetid://128693616966482",
					Size = UDim2New(0, 135, 0, 125),
					BottomImage = "rbxassetid://128693616966482",
					Position = UDim2New(0, 0, 0, 30),
					BackgroundColor3 = FromRGB(15, 12, 16)
				}); Items["OptionHolder"]:AddToTheme({ScrollBarImageColor3 = "Accent", BackgroundColor3 = "Background"})
				Library:RegisterPopup(Items["OptionHolder"].Instance)
				Instances:Create("UICorner", {
					Parent = Items["OptionHolder"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 6)
				})
				Instances:Create("UIStroke", {
					Parent = Items["OptionHolder"].Instance,
					Name = "\0",
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = FromRGB(255, 255, 255)
				}):AddToTheme({ Color = "Border" })
				Instances:Create("UIPadding", {
					Parent = Items["OptionHolder"].Instance,
					Name = "\0",
					PaddingTop = UDimNew(0, 5),
					PaddingBottom = UDimNew(0, 8),
					PaddingRight = UDimNew(0, 5),
					PaddingLeft = UDimNew(0, 5)
				})
				Instances:Create("UIListLayout", {
					Parent = Items["OptionHolder"].Instance,
					Name = "\0",
					Padding = UDimNew(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder
				})
			end
			function Dropdown:Set(Option)
				if Data.Multi then
					if type(Option) ~= "table" then
						return
					end
					self.Value = Option
					Library.Flags[self.Flag] = Option
					for Index, Value in Option do
						local OptionData = self.Options[Value]
						if not OptionData then
							continue
						end
						OptionData.Selected = true
						OptionData:Toggle("Active")
					end
					local TextToDisplay = #self.Value == 0 and "--" or TableConcat(self.Value, ", ")
					Items["Value"].Instance.Text = TextToDisplay
				else
					local OptionData = self.Options[Option]
					if not OptionData then
						return
					end
					for Index, Value in self.Options do
						if Value ~= OptionData then
							Value.Selected = false
							Value:Toggle("Inactive")
						else
							Value.Selected = true
							Value:Toggle("Active")
						end
					end
					self.SelectedOption = OptionData
					self.Value = OptionData.Name
					Library.Flags[self.Flag] = OptionData.Name
					Items["Value"].Instance.Text = OptionData.Name
				end
				if Data.Callback then
					Library:SafeCall(Data.Callback, self.Value)
				end
				if self.OnChanged then
					self.OnChanged(self.Value)
				end
			end
			function Dropdown:Get()
				return self.Value
			end
				if Data.Search then
					Items["SearchHolder"] = Instances:Create("Frame", {
						Parent = Items["OptionHolder"].Instance,
						Name = "\0",
						BackgroundTransparency = 1,
						Size = UDim2New(1, 0, 0, 25),
						LayoutOrder = -1,
						ZIndex = 2,
						BorderSizePixel = 0,
						BackgroundColor3 = FromRGB(255, 255, 255)
					})
					Instances:Create("UIPadding", {
						Parent = Items["SearchHolder"].Instance,
						Name = "\0",
						PaddingBottom = UDimNew(0, 5)
					})
					Items["SearchBackground"] = Instances:Create("Frame", {
						Parent = Items["SearchHolder"].Instance,
						Name = "\0",
						Size = UDim2New(1, 0, 0, 20),
						AnchorPoint = Vector2New(0, 1),
						Position = UDim2New(0, 0, 1, -5),
						ZIndex = 2,
						BorderSizePixel = 0,
						BackgroundColor3 = FromRGB(36, 32, 39)
					}); Items["SearchBackground"]:AddToTheme({BackgroundColor3 = "Element"})
					Instances:Create("UICorner", {
						Parent = Items["SearchBackground"].Instance,
						Name = "\0",
						CornerRadius = UDimNew(0, 5)
					})
					Items["Search"] = Instances:Create("TextBox", {
						Parent = Items["SearchHolder"].Instance,
						Name = "\0",
						FontFace = Library.Font,
						Text = "",
						PlaceholderText = Data.SearchPlaceholder or "Search..",
						PlaceholderColor3 = FromRGB(185, 185, 185),
						TextSize = 14,
						TextColor3 = FromRGB(255, 255, 255),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Size = UDim2New(1, -16, 0, 20),
						Position = UDim2New(0, 8, 0, 0),
						BackgroundTransparency = 1,
						ClearTextOnFocus = false,
						CursorPosition = -1,
						ZIndex = 3,
						BorderSizePixel = 0,
						BackgroundColor3 = FromRGB(255, 255, 255)
					}); Items["Search"]:AddToTheme({TextColor3 = "Text", PlaceholderColor3 = "Inactive Text"})
			local function ApplyFilter(Query)
				local Filter = StringLower(tostring(Query or ""))
				-- Skip the whole pass when nothing changed (rapid typing / re-open).
				if Filter == Dropdown.FilterCache then
					return
				end
				Dropdown.FilterCache = Filter
				-- Only touch properties that actually change: every Visible/LayoutOrder
				-- write re-sorts the UIListLayout and relayouts the column.
				for Option, OptionData in Dropdown.Options do
					local Button = OptionData.Button.Instance
					local Matched = Filter == "" or StringFind(StringLower(tostring(Option)), Filter, 1, true) ~= nil
					if Button.Visible ~= Matched then
						Button.Visible = Matched
					end
					local Order = Matched and 0 or 1
					if Button.LayoutOrder ~= Order then
						Button.LayoutOrder = Order
					end
				end
			end
				end
function Dropdown:Add(Option, Icon)
			-- New option: the cached filter result no longer covers it.
			self.FilterCache = nil
			-- `IsLabelDropdown` renders rows as plain TextLabels (no button highlight).
			local OptionButton = Instances:Create(Data.IsLabelDropdown and "TextLabel" or "TextButton", {
				Parent = Items["OptionHolder"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(0, 0, 0),
				BorderColor3 = FromRGB(0, 0, 0),
				Text = "",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2New(1, 0, 0, 25),
				ZIndex = 2,
				TextSize = 14,
				BackgroundColor3 = FromRGB(22, 20, 24)
			}); OptionButton:AddToTheme({BackgroundColor3 = "Inline"})
			if not Data.IsLabelDropdown then
				OptionButton.Instance.AutoButtonColor = false
			end
				Instances:Create("UICorner", {
					Parent = OptionButton.Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				local OptionText = Instances:Create("TextLabel", {
					Parent = OptionButton.Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					TextTransparency = 0.4,
					Text = Option,
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(1, -15, 1, 0),
					Position = UDim2New(0, not Icon and 4 or 32, 0, 0),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); OptionText:AddToTheme({TextColor3 = "Text"})
				local OptionIndicator = Instances:Create("Frame", {
					Parent = OptionButton.Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(1, 0.5),
					Position = UDim2New(1, 0, 0.5, 0),
					Size = UDim2New(0, 18, 0, 18),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); OptionIndicator:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = OptionIndicator.Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Instances:Create("UIGradient", {
					Parent = OptionIndicator.Instance,
					Name = "\0",
					Rotation = 90,
					Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))}
				}):AddToTheme({Color = function()
					return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Gradient"])}
				end})
				local OptionCheck = Instances:Create("ImageLabel", {
					Parent = OptionIndicator.Instance,
					Name = "\0",
					ImageColor3 = FromRGB(0, 0, 0),
					ScaleType = Enum.ScaleType.Fit,
					ImageTransparency = 1,
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(1, -2, 1, -2),
					AnchorPoint = Vector2New(0.5, 0.5),
					Image = "rbxassetid://116339777575852",
					BackgroundTransparency = 1,
					Position = UDim2New(0.5, 0, 0.5, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				if Icon then
					local _OptionIcon = Instances:Create("ImageLabel", {
						Parent = OptionButton.Instance,
						Name = "\0",
						BorderColor3 = FromRGB(0, 0, 0),
						Size = UDim2New(0, 16, 0, 16),
						AnchorPoint = Vector2New(0, 0.5),
						Image = "rbxassetid://"..Icon,
						BackgroundTransparency = 1,
						Position = UDim2New(0, 8, 0.5, 0),
						ZIndex = 2,
						BorderSizePixel = 0,
						BackgroundColor3 = FromRGB(255, 255, 255)
					})
				end
				local OptionData = {
					Selected = false,
					Name = Option,
					Text = OptionText,
					Button = OptionButton,
					Indicator = OptionIndicator,
					CheckImage = OptionCheck
				}
				function OptionData:Toggle(State)
					if State == "Active" then
						OptionData.Text:Tween(nil, {TextTransparency = 0})
						OptionData.Indicator:ChangeItemTheme({BackgroundColor3 = "Accent"})
						OptionData.Indicator:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})
						OptionData.CheckImage:Tween(nil, {ImageTransparency = 0})
						OptionData.Button.Instance.BackgroundTransparency = 0.55
					else
						OptionData.Text:Tween(nil, {TextTransparency = 0.55})
						OptionData.Indicator:ChangeItemTheme({BackgroundColor3 = "Element"})
						OptionData.Indicator:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
						OptionData.CheckImage:Tween(nil, {ImageTransparency = 1})
						OptionData.Button.Instance.BackgroundTransparency = 1
					end
				end
				function OptionData:Set()
					if Dropdown.Disabled then
						return
					end
					self.Selected = not self.Selected
					if Data.Multi then
						local Index = TableFind(Dropdown.Value, self.Name)
						if Index then
							TableRemove(Dropdown.Value, Index)
						else
							TableInsert(Dropdown.Value, self.Name)
						end
						Library.Flags[Dropdown.Flag] = Dropdown.Value
						self:Toggle(Index and "Inactive" or "Active")
						local TextToDisplay = #Dropdown.Value == 0 and "--" or TableConcat(Dropdown.Value, ", ")
						Items["Value"].Instance.Text = TextToDisplay
					else
						if self.Selected then
						for Index, Value in Dropdown.Options do
								if Value ~= self then
									Value.Selected = false
									Value:Toggle("Inactive")
								end
							end
							self:Toggle("Active")
							Library.Flags[Dropdown.Flag] = self.Name
							Dropdown.SelectedOption = self
							Dropdown.Value = self.Name
							Items["Value"].Instance.Text = self.Name
						else
							self:Toggle("Inactive")
							Library.Flags[Dropdown.Flag] = nil
							Dropdown.SelectedOption = nil
							Dropdown.Value = nil
							Items["Value"].Instance.Text = "--"
						end
					end
					if Data.Callback then
						Library:SafeCall(Data.Callback, Dropdown.Value)
					end
					if Dropdown.OnChanged then
						Dropdown.OnChanged(Dropdown.Value)
					end
				end
				OptionData.Button:Connect("MouseButton1Down", function()
					OptionData:Set()
				end)
				if not Data.IsLabelDropdown then
					-- Rows are flat by default, so hovering needs its own feedback or the
					-- list reads as an undifferentiated block of text.
					OptionButton:Connect("MouseEnter", function()
						if OptionData.Selected then
							return
						end
						OptionButton.Instance.BackgroundTransparency = 0.8
					end)
					OptionButton:Connect("MouseLeave", function()
						if OptionData.Selected then
							return
						end
						OptionButton.Instance.BackgroundTransparency = 1
					end)
				end
				self.Options[Option] = OptionData
				return OptionData
			end
			function Dropdown:Remove(Option)
				if self.Options[Option] then
					self.Options[Option].Button:Clean()
					self.Options[Option] = nil
					self.FilterCache = nil
				end
			end
			function Dropdown:Clear()
				for Index, Value in self.Options do
					self:Remove(Value.Name)
				end
				self.FilterCache = nil
			end
			function Dropdown:Refresh(List)
				Dropdown:Clear()
				for Index, Value in List do
					Dropdown:Add(Value)
				end
				self.FilterCache = nil
			end
			function Dropdown:SetMulti(Bool)
				Data.Multi = Bool
			end
			function Dropdown:SetText(Text)
				Items["Text"].Instance.Text = Text
			end
			function Dropdown:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["RealDropdown"]:Tween(nil, {BackgroundTransparency = 0.6})
					Items["Value"]:Tween(nil, {TextTransparency = 0.6})
					Items["Icon"]:Tween(nil, {ImageTransparency = 0.6})
					self:SetOpen(false)
				else
					Items["Text"]:Tween(nil, {TextTransparency = 0})
					Items["RealDropdown"]:Tween(nil, {BackgroundTransparency = 0})
					Items["Value"]:Tween(nil, {TextTransparency = 0})
					Items["Icon"]:Tween(nil, {ImageTransparency = 0})
				end
			end
			local Debounce = false
			local DebounceUntil = 0
			local RenderStepped
			-- A stuck debounce permanently bricks a dropdown. Expire it automatically so
			-- a missed tween-completion (or any error mid-open) can never lock it shut.
			local function Debounced()
				if not Debounce then
					return false
				end
				if Tick() >= DebounceUntil then
					Debounce = false
					return false
				end
				return true
			end
			local function ScrollToSelected()
				if not Holder:IsA("ScrollingFrame") then
					return
				end
				local Selected = Dropdown.SelectedOption
				local Row = Selected and Selected.Button and Selected.Button.Instance
				if not Row or not Row.Parent then
					return
				end
				local RowHeight = Row.AbsoluteSize.Y
				if RowHeight <= 0 then
					return
				end
				local Offset = Row.AbsolutePosition.Y - Holder.AbsolutePosition.Y - 5
				local MaxScroll = Holder.AbsoluteCanvasSize.Y - Holder.AbsoluteSize.Y
				if Offset > 0 and MaxScroll > 0 then
					Holder.CanvasPosition = Vector2New(0, MathClamp(Offset, 0, MaxScroll))
				end
			end
			function Dropdown:SetOpen(Bool, Instant)
				local Holder = Items["OptionHolder"].Instance
				if not Holder or not Holder.Parent then
					Debounce = false
					return
				end
				if Instant then
					Debounce = false
					self.IsOpen = not not Bool
					if RenderStepped then
						Library:RemoveFrameJob(RenderStepped.Name)
						RenderStepped = nil
					end
					Items["Icon"]:Tween(nil, {Rotation = self.IsOpen and -90 or 0})
					if Holder.Parent then
						Holder.Visible = self.IsOpen
					end
					if not self.IsOpen and Library.OpenFrames[self] then
						Library.OpenFrames[self] = nil
					end
					return
				end
				if Debounced() then
					return
				end
				if self.IsOpen == (not not Bool) then
					return
				end
				self.IsOpen = not not Bool
				Debounce = true
				DebounceUntil = Tick() + 1.0
				if self.IsOpen then
					Items["OptionHolder"].Instance.Visible = true
				Items["Icon"]:Tween(nil, {Rotation = -90})
				if self.OnOpened then
					Library:SafeCall(self.OnOpened)
				end
				local RealBtn = Items["RealDropdown"].Instance
					local ButtonWidth = RealBtn.AbsoluteSize.X
					if ButtonWidth > 0 and ButtonWidth ~= Holder.Size.X.Offset then
						Holder.Size = UDim2New(0, ButtonWidth, 1, 0)
					end
					pcall(function() Library:PositionPopup(Holder, RealBtn, 0, 30) end)
					local Scrolled = false
					local LastX, LastY
					RenderStepped = Library:AddFrameJob(Dropdown, function()
						if not Dropdown.IsOpen or not Holder.Parent then
							return
						end
						if not Scrolled then
							Scrolled = true
							pcall(ScrollToSelected)
						end
						local X = RealBtn.AbsolutePosition.X
						local Y = RealBtn.AbsolutePosition.Y
						if X == LastX and Y == LastY then
							return
						end
						LastX, LastY = X, Y
						pcall(function() Library:PositionPopup(Holder, RealBtn, 0, 30) end)
					end)
					for Index, Value in Library.OpenFrames do
						if Value ~= self and Value.Options then
							Value:SetOpen(false)
						end
					end
					Library.OpenFrames[self] = self
				else
					Items["Icon"]:Tween(nil, {Rotation = 0})
					if Library.OpenFrames[self] then
						Library.OpenFrames[self] = nil
					end
					if RenderStepped then
						Library:RemoveFrameJob(RenderStepped.Name)
						RenderStepped = nil
					end
				end
				local NewTween = Library:FadeHolder(Items["OptionHolder"].Instance, self.IsOpen, Data.Window.FadeSpeed, self.IsOpen and 1000 or 0)
				local function Finish()
					Debounce = false
					if Items["OptionHolder"].Instance.Parent then
						Items["OptionHolder"].Instance.Visible = self.IsOpen
					end
				end
				if NewTween and NewTween.Tween then
					Library:Once(NewTween.Tween.Completed, Finish)
				else
					Finish()
				end
			end
			function Dropdown:SetVisible(Bool)
				Items["Dropdown"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Dropdown"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
	TableInsert(PageSearchData, SearchData)
			end
			Items["RealDropdown"]:Connect("MouseButton1Down", function()
				if not Dropdown.Disabled then
					Dropdown:SetOpen(not Dropdown.IsOpen)
				end
			end)
			Library:On(UserInputService.InputBegan, function(Input)
				if not Dropdown.IsOpen then
					return
				end
				if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
					if Library:IsMouseOverFrame(Items["OptionHolder"], nil, nil, Input) then
						return
					end
					-- The same click that opens the dropdown must never also close it.
					-- InputBegan and MouseButton1Down fire in an order that differs
					-- between executors, so the "not over the button" test below would
					-- otherwise see the popup-less click and slam it shut again.
					if Library:IsMouseOverFrame(Items["RealDropdown"], nil, nil, Input) then
						return
					end
					if Debounce then
						return
					end
					Dropdown:SetOpen(false)
				end
			end, TypesClick)
			if Data.Disabled then
				Dropdown:SetDisabled(Data.Disabled)
			end
			if Data.Default then
				Dropdown:Set(Data.Default)
			end
			if Items["Search"] then
				Library:Connect(Items["Search"].Instance:GetPropertyChangedSignal("Text"), function()
					ApplyFilter(Items["Search"].Instance.Text)
				end)
				Dropdown.OnOpened = function()
					Items["Search"].Instance.Text = ""
					ApplyFilter("")
				end
			end
			for Index, Value in Data.Items do
				Dropdown:Add(Value)
			end
			Library.SetFlags[Dropdown.Flag] = function(Value)
				Dropdown:Set(Value)
			end
			return Dropdown, Items
		end
Components.ToggleDropdown = Components.Dropdown

		Components.Textbox = function(Data)
			local Textbox = {
				Value = "",
				Flag = Data.Flag,
				OnChanged = nil,
				Disabled = false
			}
			local Items = { } do
				Items["Textbox"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 46),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Textbox"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Size = UDim2New(0, 0, 0, 15),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Background"] = Instances:Create("Frame", {
					Parent = Items["Textbox"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0, 1),
					Position = UDim2New(0, 0, 1, 0),
					Size = UDim2New(1, 0, 0, 25),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UIGradient", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					Rotation = 90,
					Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))}
				}):AddToTheme({Color = function()
					return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Gradient"])}
				end})
				Instances:Create("UICorner", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["Input"] = Instances:Create("TextBox", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextStrokeColor3 = FromRGB(255, 255, 255),
					PlaceholderColor3 = FromRGB(185, 185, 185),
					PlaceholderText = Data.Placeholder,
					TextSize = 14,
					Size = UDim2New(1, -16, 1, 0),
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					ClearTextOnFocus = false,
					Text = "",
					ZIndex = 2,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					CursorPosition = -1,
					Position = UDim2New(0, 8, 0, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Input"]:AddToTheme({TextColor3 = "Text", PlaceholderColor3 = "Inactive Text"})
			end
			function Textbox:Set(Value)
				if self.Disabled then
					return
				end
				Items["Input"].Instance.Text = Value
				Library.Flags[self.Flag] = Value
				if Data.Callback then
					Library:SafeCall(Data.Callback, Value)
				end
				if self.OnChanged then
					Library:SafeCall(self.OnChanged, Value)
				end
			end
			function Textbox:SetText(Text)
				Items["Input"].Instance.Text = Text
			end
			function Textbox:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["Background"]:Tween(nil, {BackgroundTransparency = 0.6})
					Items["Input"]:Tween(nil, {TextTransparency = 0.6})
				else
					Items["Text"]:Tween(nil, {TextTransparency = 0})
					Items["Background"]:Tween(nil, {BackgroundTransparency = 0})
					Items["Input"]:Tween(nil, {TextTransparency = 0})
				end
			end
			function Textbox:SetVisible(Bool)
				Items["Textbox"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Textbox"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
	TableInsert(PageSearchData, SearchData)
			end
			Items["Input"]:Connect("Focused", function()
				if Textbox.Disabled then
					return
				end
				Items["Input"]:ChangeItemTheme({TextColor3 = "Accent", PlaceholderColor3 = "Inactive Text"})
				Items["Input"]:Tween(nil, {TextColor3 = Library.Theme.Accent})
			end)
			Items["Input"]:Connect("FocusLost", function()
				if Textbox.Disabled then
					return
				end
				Items["Input"]:ChangeItemTheme({TextColor3 = "Text", PlaceholderColor3 = "Inactive Text"})
				Items["Input"]:Tween(nil, {TextColor3 = Library.Theme.Text})
				Textbox:Set(Items["Input"].Instance.Text)
			end)
			if Data.Disabled then
				Textbox:SetDisabled(Data.Disabled)
			end
			if Data.Default then
				Textbox:Set(Data.Default)
			end
			Library.SetFlags[Data.Flag] = function(Value)
				Textbox:Set(Value)
			end
			return Textbox, Items
		end

		Components.Colorpicker = function(Data)
			local Colorpicker = {
				IsOpen = false,
				Color = FromRGB(0, 0, 0),
				HexValue = "000000",
				Alpha = 0,
				Hue = 0,
				Saturation = 0,
				Value = 0,
				Flag = Data.Flag,
				Disabled = false,
				OnChanged = nil
			}
			local AnimationsDropdown
			local AnimationsDropdownItems
			local HSVTextbox
			local HSVTextboxItems
			Library.Flags[Colorpicker.Flag] = { }
			local Items = { } do
				Items["ColorpickerButton"] = Instances:Create("TextButton", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "",
					AutoButtonColor = false,
					AnchorPoint = Vector2New(1, 0),
					BorderSizePixel = 0,
					Position = UDim2New(1, 0, 0, 0),
					Size = UDim2New(0, 20, 0, 20),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 215, 160)
				})
				Instances:Create("UIGradient", {
					Parent = Items["ColorpickerButton"].Instance,
					Name = "\0",
					Rotation = 90,
					Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))}
				}):AddToTheme({Color = function()
					return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Gradient"])}
				end})
				Instances:Create("UICorner", {
					Parent = Items["ColorpickerButton"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["ColorpickerWindow"] = Instances:Create("Frame", {
					Parent = Library.Holder.Instance,
					Name = "\0",
					BackgroundTransparency = 0.30000001192092896,
					Position = UDim2New(0, 0, 0, 26),
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(0, 218, 0, 275),
					Visible = false,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(15, 12, 16)
				}); Items["ColorpickerWindow"]:AddToTheme({BackgroundColor3 = "Background"})
				Library:RegisterPopup(Items["ColorpickerWindow"].Instance)
				Items["ColorpickerWindow"]:MakeDraggable()
				Items["ColorpickerWindow"]:MakeResizeable(Vector2New(200, 200), Vector2New(9999, 9999))
				Instances:Create("UICorner", {
					Parent = Items["ColorpickerWindow"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["Hue"] = Instances:Create("ImageButton", {
					Parent = Items["ColorpickerWindow"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(1, -16, 0, 18),
					AutoButtonColor = false,
					AnchorPoint = Vector2New(0, 1),
					Image = Library:GetImage("Hue"),
					Position = UDim2New(0, 8, 1, -75),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UICorner", {
					Parent = Items["Hue"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["HueDragger"] = Instances:Create("Frame", {
					Parent = Items["Hue"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0, 0.5),
					Position = UDim2New(0, 12, 0.5, 0),
					Size = UDim2New(0, 2, 1, -10),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UIStroke", {
					Parent = Items["HueDragger"].Instance,
					Name = "\0",
					Thickness = 1.2000000476837158,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				})
				Instances:Create("UICorner", {
					Parent = Items["HueDragger"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Items["Alpha"] = Instances:Create("TextButton", {
					Parent = Items["ColorpickerWindow"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "",
					AutoButtonColor = false,
					AnchorPoint = Vector2New(1, 0),
					BorderSizePixel = 0,
					Position = UDim2New(1, -8, 0, 8),
					Size = UDim2New(0, 18, 1, -110),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 215, 160)
				})
				Instances:Create("UICorner", {
					Parent = Items["Alpha"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["AlphaDragger"] = Instances:Create("Frame", {
					Parent = Items["Alpha"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0.5, 0),
					Position = UDim2New(0.5, 0, 0, 3),
					Size = UDim2New(1, -10, 0, 2),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UIStroke", {
					Parent = Items["AlphaDragger"].Instance,
					Name = "\0",
					Thickness = 1.2000000476837158,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				})
				Instances:Create("UICorner", {
					Parent = Items["AlphaDragger"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Items["Checkers"] = Instances:Create("ImageLabel", {
					Parent = Items["Alpha"].Instance,
					Name = "\0",
					ScaleType = Enum.ScaleType.Tile,
					BorderColor3 = FromRGB(0, 0, 0),
					TileSize = UDim2New(0, 6, 0, 6),
					Image = Library:GetImage("Checkers"),
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 1, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UIGradient", {
					Parent = Items["Checkers"].Instance,
					Name = "\0",
					Rotation = 90,
					Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.37, 0.5), NumSequenceKeypoint(1, 0)}
				})
				Instances:Create("UICorner", {
					Parent = Items["Checkers"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["Palette"] = Instances:Create("TextButton", {
					Parent = Items["ColorpickerWindow"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
					Position = UDim2New(0, 9, 0, 8),
					Size = UDim2New(1, -44, 1, -110),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 215, 160)
				})
				Instances:Create("UICorner", {
					Parent = Items["Palette"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["Saturation"] = Instances:Create("ImageLabel", {
					Parent = Items["Palette"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					Image = Library:GetImage("Saturation"),
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 1, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UICorner", {
					Parent = Items["Saturation"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["Value"] = Instances:Create("ImageLabel", {
					Parent = Items["Palette"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(1, 2, 1, 0),
					Image = Library:GetImage("Value"),
					BackgroundTransparency = 1,
					Position = UDim2New(0, -1, 0, 0),
					ZIndex = 3,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UICorner", {
					Parent = Items["Value"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["PaletteDragger"] = Instances:Create("Frame", {
					Parent = Items["Palette"].Instance,
					Name = "\0",
					Size = UDim2New(0, 4, 0, 4),
					Position = UDim2New(0, 5, 0, 5),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UICorner", {
					Parent = Items["PaletteDragger"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Instances:Create("UIStroke", {
					Parent = Items["PaletteDragger"].Instance,
					Name = "\0",
					Thickness = 1.2000000476837158,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				})
				Items["Shadow"] = Instances:Create("ImageLabel", {
					Parent = Items["ColorpickerWindow"].Instance,
					Name = "\0",
					ImageColor3 = FromRGB(0, 0, 0),
					ImageTransparency = 0.5600000023841858,
					AnchorPoint = Vector2New(0.5, 0.5),
					Image = "rbxassetid://112971167999062",
					ZIndex = -1,
					BorderSizePixel = 0,
					SliceCenter = RectNew(Vector2New(112, 112), Vector2New(147, 147)),
					ScaleType = Enum.ScaleType.Slice,
					BorderColor3 = FromRGB(0, 0, 0),
					BackgroundTransparency = 1,
					Position = UDim2New(0.5, 0, 0.5, 0),
					SliceScale = 0.6000000238418579,
					Size = UDim2New(1, 55, 1, 55),
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Shadow"]:AddToTheme({ImageColor3 = "Shadow"})
				AnimationsDropdown, AnimationsDropdownItems = Components.Dropdown({
					Name = "Animations",
					Parent = Items["ColorpickerWindow"],
					Disabled = false,
					Window = Data.Window,
					Items = {"Rainbow", "Breathing"},
					Multi = true,
					Page = Data.Page,
					Flag = "AnimationsDropdown"..Colorpicker.Flag,
					ZIndex = 2,
				})
				AnimationsDropdownItems["Dropdown"].Instance.AnchorPoint = Vector2New(0, 1)
				AnimationsDropdownItems["Dropdown"].Instance.Position = UDim2New(0, 8, 1, -38)
				AnimationsDropdownItems["Dropdown"].Instance.Size = UDim2New(1, -16, 0, 25)
				AnimationsDropdownItems["OptionHolder"].Instance.Size = UDim2New(0, AnimationsDropdownItems["RealDropdown"].Instance.AbsoluteSize.X, 0, 68)
				HSVTextbox, HSVTextboxItems = Components.Textbox({
					Name = "",
					Flag = Library:NextFlag(),
					Parent = Items["ColorpickerWindow"],
					Page = Data.Page,
					Debounce = true,
					Placeholder = "Enter hex code",
					Disabled = false
				})
				HSVTextboxItems["Text"]:Clean()
				HSVTextboxItems["Background"].Instance.Parent = Items["ColorpickerWindow"].Instance
				HSVTextboxItems["Textbox"]:Clean()
				HSVTextboxItems["Background"].Instance.AnchorPoint = Vector2New(0, 1)
				HSVTextboxItems["Background"].Instance.Position = UDim2New(0, 8, 1, -8)
				HSVTextboxItems["Background"].Instance.Size = UDim2New(1, -16, 0, 25)
			end
			local OldColor = Colorpicker.Color
			local OldAlpha = Colorpicker.Alpha
			AnimationsDropdown.OnChanged = function(Value)
				if TableFind(Value, "Rainbow") then
					OldColor = Colorpicker.Color
					Library:Thread(function()
						while task.wait() do
							local RainbowHue = MathAbs(MathSin(tick() * 0.32))
							local Color = FromHSV(RainbowHue, 1, 1)
							Colorpicker:Set(Color, Colorpicker.Alpha)
							if not TableFind(Value, "Rainbow") then
								Colorpicker:Set(OldColor, Colorpicker.Alpha)
								break
							end
						end
					end)
				end
				if TableFind(Value, "Breathing") then
					Library:Thread(function()
						OldAlpha = Colorpicker.Alpha
						while task.wait() do
							local AlphaValue = MathAbs(MathSin(tick() * 0.8))
							Colorpicker:Set(Colorpicker.Color, AlphaValue)
							if not TableFind(Value, "Breathing") then
								Colorpicker:Set(Colorpicker.Color, OldAlpha)
								break
							end
						end
					end)
				end
			end
			HSVTextbox.OnChanged = function(Value)
				Colorpicker:Set(tostring(Value), Colorpicker.Alpha)
			end
			local Debounce = false
			local SlidingPallette = false
			local SlidingHue = false
			local SlidingAlpha = false
			function Colorpicker:SetOpen(Bool, Instant)
				if Debounce and not Instant then
					return
				end
				if not Instant and self.IsOpen == (not not Bool) then
					return
				end
				self.IsOpen = not not Bool
				if Instant then
					Debounce = false
					if Library.OpenFrames[self] then
						Library.OpenFrames[self] = nil
					end
					Items["ColorpickerWindow"].Instance.Visible = self.IsOpen
					return
				end
				Debounce = true
				if self.IsOpen then
					Items["ColorpickerWindow"].Instance.Visible = true
					Library:PositionPopup(Items["ColorpickerWindow"].Instance, Items["ColorpickerButton"].Instance, 50, 26)
					for Index, Value in Library.OpenFrames do
						if Value ~= self and Value.Hue then
							Value:SetOpen(false, true)
						end
					end
					Library.OpenFrames[self] = self
				else
					if Library.OpenFrames[self] then
						Library.OpenFrames[self] = nil
					end
				end
				local SkipPalette = function(Object)
					return Object:IsA("ImageLabel") and Object.Image == "rbxassetid://112971167999062"
				end
				local NewTween = Library:FadeHolder(Items["ColorpickerWindow"].Instance, self.IsOpen, Data.Window.FadeSpeed, self.IsOpen and 999 or 1, SkipPalette)
				Items["AlphaDragger"].Instance.ZIndex = self.IsOpen and 999 or 1
				Items["PaletteDragger"].Instance.ZIndex = self.IsOpen and 999 or 1
				local function Finish()
					Debounce = false
					Items["ColorpickerWindow"].Instance.Visible = self.IsOpen
				end
				if NewTween and NewTween.Tween then
					Library:Once(NewTween.Tween.Completed, Finish)
				else
					Finish()
				end
			end
			function Colorpicker:SlidePalette(Input)
				if not Input or not SlidingPallette then
					return
				end
				local ValueX = MathClamp(1 - (Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 1)
				local ValueY = MathClamp(1 - (Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 1)
				self.Saturation = ValueX
				self.Value = ValueY
				local SlideX = MathClamp((Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 0.98)
				local SlideY = MathClamp((Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 0.97)
				Items["PaletteDragger"]:Tween(Tween:Info(0.22), {Position = UDim2New(SlideX, 0, SlideY, 0)})
				self:Update()
			end
			function Colorpicker:SlideHue(Input)
				if not Input or not SlidingHue then
					return
				end
				local ValueX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 1)
				self.Hue = ValueX
				local SlideX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 0.99)
				Items["HueDragger"]:Tween(Tween:Info(0.22), {Position = UDim2New(SlideX, 0, 0.5, 0)})
				self:Update()
			end
			function Colorpicker:SlideAlpha(Input)
				if not Input or not SlidingAlpha then
					return
				end
				local ValueY = MathClamp((Input.Position.Y - Items["Alpha"].Instance.AbsolutePosition.Y) / Items["Alpha"].Instance.AbsoluteSize.Y, 0, 1)
				self.Alpha = ValueY
				local SlideY = MathClamp((Input.Position.Y - Items["Alpha"].Instance.AbsolutePosition.Y) / Items["Alpha"].Instance.AbsoluteSize.Y, 0, 0.99)
				Items["AlphaDragger"]:Tween(Tween:Info(0.22), {Position = UDim2New(0.5, 0, SlideY, 0)})
				self:Update(true)
			end
			function Colorpicker:Update(IsFromAlpha)
				local Hue, Saturation, Value = self.Hue, self.Saturation, self.Value
				local Color = FromHSV(Hue, Saturation, Value)
				self.Color = Color
				self.HexValue = Color:ToHex()
				Library.Flags[self.Flag] = {
					Alpha = self.Alpha,
					Color = self.HexValue
				}
				if self.Sliding then
					Items["ColorpickerButton"].Instance.BackgroundColor3 = Color
					Items["Palette"].Instance.BackgroundColor3 = FromHSV(Hue, 1, 1)
					if not IsFromAlpha then
						Items["Alpha"].Instance.BackgroundColor3 = Color
					end
					local Now = Tick()
					if Now - (self.LastTextUpdate or -1) >= 0.08 then
						self.LastTextUpdate = Now
						HSVTextboxItems["Input"].Instance.Text = "#" .. self.HexValue
					end
				else
					Items["ColorpickerButton"]:Tween(nil, {BackgroundColor3 = Color})
					Items["Palette"]:Tween(nil, {BackgroundColor3 = FromHSV(Hue, 1, 1)})
					HSVTextboxItems["Input"].Instance.Text = "#" .. self.HexValue
					if not IsFromAlpha then
						Items["Alpha"]:Tween(nil, {BackgroundColor3 = Color})
					end
				end
				if Data.Callback then
					Library:SafeCall(Data.Callback, Color, self.Alpha)
				end
				if Colorpicker.OnChanged then
					Colorpicker.OnChanged(Color, self.Alpha)
				end
			end
			function Colorpicker:Set(Color, Alpha)
				if type(Color) == "table" then
					Color = FromRGB(Color[1], Color[2], Color[3])
					Alpha = Color[4]
				elseif type(Color) == "string" then
					Color = FromHex(Color)
				end
				self.Hue, self.Saturation, self.Value = Color:ToHSV()
				self.Alpha = Alpha or 0
				local ColorPositionX = MathClamp(1 - self.Saturation, 0, 0.98)
				local ColorPositionY = MathClamp(1 - self.Value, 0, 0.97)
				local AlphaPositionY = MathClamp(self.Alpha, 0, 0.99)
				local HuePositionX = MathClamp(self.Hue, 0, 0.99)
				Items["PaletteDragger"]:Tween(Tween:Info(0.22), {Position = UDim2New(ColorPositionX, 0, ColorPositionY, 0)})
				Items["HueDragger"]:Tween(Tween:Info(0.22), {Position = UDim2New(HuePositionX, 0, 0.5, 0)})
				Items["AlphaDragger"]:Tween(Tween:Info(0.22), {Position = UDim2New(0.5, 0, AlphaPositionY, 0)})
				self:Update()
			end
			Items["ColorpickerButton"]:Connect("MouseButton1Down", function()
				Colorpicker:SetOpen(not Colorpicker.IsOpen)
			end)
			Items["Palette"]:Connect("InputBegan", function(Input)
				if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
					SlidingPallette = true
					Colorpicker.Sliding = true
					Colorpicker:SlidePalette(Input)
					Input.Changed:Connect(function()
						if Input.UserInputState == Enum.UserInputState.End then
							SlidingPallette = false
						Colorpicker.Sliding = false
						end
					end)
				end
			end)
			Library:On(UserInputService.InputBegan, function(Input)
				if not Colorpicker.IsOpen then
					return
				end
				if Input.UserInputType == InputTypeMouseButton1 then
					if Library:IsMouseOverFrame(AnimationsDropdownItems["OptionHolder"], nil, nil, Input) then
						return
					end
					if Library:IsMouseOverFrame(Items["ColorpickerWindow"], nil, nil, Input) then
						return
					end
					if Debounce then
						return
					end
					Colorpicker:SetOpen(false)
				end
			end, TypesClick)
			Items["Hue"]:Connect("InputBegan", function(Input)
				if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
					SlidingHue = true
					Colorpicker.Sliding = true
					Colorpicker:SlideHue(Input)
					Input.Changed:Connect(function()
						if Input.UserInputState == Enum.UserInputState.End then
							SlidingHue = false
						Colorpicker.Sliding = false
						end
					end)
				end
			end)
			Items["Alpha"]:Connect("InputBegan", function(Input)
				if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
					SlidingAlpha = true
					Colorpicker.Sliding = true
					Colorpicker:SlideAlpha(Input)
					Input.Changed:Connect(function()
						if Input.UserInputState == Enum.UserInputState.End then
							SlidingAlpha = false
						Colorpicker.Sliding = false
						end
					end)
				end
			end)
			Library:On(UserInputService.InputChanged, function(Input)
				if not (SlidingPallette or SlidingHue or SlidingAlpha) then
					return
				end
				if Input.UserInputType == InputTypeMouseMovement or Input.UserInputType == InputTypeTouch then
					if SlidingPallette then
						Colorpicker:SlidePalette(Input)
					end
					if SlidingHue then
						Colorpicker:SlideHue(Input)
					end
					if SlidingAlpha then
						Colorpicker:SlideAlpha(Input)
					end
				end
			end, TypesMove)
			if Data.Default then
				Colorpicker:Set(Data.Default, Data.Alpha)
			end
			Library.SetFlags[Colorpicker.Flag] = function(Value, Alpha)
				Colorpicker:Set(Value, Alpha)
			end
			return Colorpicker, Items
		end

		Components.Keybind = function(Data)
			local Keybind = {
				Flag = Data.Flag,
				IsOpen = false,
				Key = nil,
				Value = "",
				Mode = "",
				Toggled = false,
				Picking = false,
				OnChanged = nil
			}
			Library.Flags[Keybind.Flag] = { }
			local LastConflictWarning = 0
			local function WarnOnConflict(TextToDisplay)
				local Conflict = Library:FindKeybindConflict(Keybind.Key, Data.Flag)
				if not Conflict then
					return
				end
				if os.clock() - LastConflictWarning < 3 then
					return
				end
				LastConflictWarning = os.clock()
				Library:Notification("Keybind conflict", 'The key "' .. tostring(TextToDisplay) .. '" is already bound to "' .. tostring(Conflict) .. '".', 5, "Warning")
			end
			local CalculateCount
			local KeylistItem
			if Library.KeyList then
				KeylistItem = Library.KeyList:Add("", "", "")
			end
			local Items = { } do
				Items["KeyButton"] = Instances:Create("TextButton", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "None",
					Size = UDim2New(0, 0, 0, 20),
					AutoButtonColor = false,
					AnchorPoint = Vector2New(1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					Position = UDim2New(1, 0, 0, 0),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(15, 12, 16)
				}); Items["KeyButton"]:AddToTheme({TextColor3 = "Text", BackgroundColor3 = "Background"})
				CalculateCount = function(Index)
					local MaxButtonsAdded = 5
					local Column = Index % MaxButtonsAdded
					local Offset = Data.IsToggle and 44 or Data.IsCheckbox and 24 or 0
					local ButtonSize = Items["KeyButton"].Instance.AbsoluteSize
					local Spacing = -6
					local XPosition = (ButtonSize.X + Spacing) * Column - Spacing - ButtonSize.X
					Items["KeyButton"].Instance.Position = UDim2New(1, -XPosition - Offset, 0, 0)
				end
				CalculateCount(Data.Count)
				Instances:Create("UIPadding", {
					Parent = Items["KeyButton"].Instance,
					Name = "\0",
					PaddingRight = UDimNew(0, 5),
					PaddingLeft = UDimNew(0, 6)
				})
				Instances:Create("UICorner", {
					Parent = Items["KeyButton"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["KeybindWindow"] = Instances:Create("Frame", {
					Parent = Library.Holder.Instance,
					Name = "\0",
					Visible = false,
					Position = UDim2New(0, 0, 0, 25),
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(0, 90, 0, 90),
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(15, 12, 16)
				}); Items["KeybindWindow"]:AddToTheme({BackgroundColor3 = "Background"})
				Library:RegisterPopup(Items["KeybindWindow"].Instance)
				Instances:Create("UICorner", {
					Parent = Items["KeybindWindow"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["Shadow"] = Instances:Create("ImageLabel", {
					Parent = Items["KeybindWindow"].Instance,
					Name = "\0",
					ImageColor3 = FromRGB(0, 0, 0),
					ImageTransparency = 0.5600000023841858,
					AnchorPoint = Vector2New(0.5, 0.5),
					Image = "rbxassetid://112971167999062",
					ZIndex = -1,
					BorderSizePixel = 0,
					SliceCenter = RectNew(Vector2New(112, 112), Vector2New(147, 147)),
					ScaleType = Enum.ScaleType.Slice,
					BorderColor3 = FromRGB(0, 0, 0),
					BackgroundTransparency = 1,
					Position = UDim2New(0.5, 0, 0.5, 0),
					SliceScale = 0.6000000238418579,
					Size = UDim2New(1, 55, 1, 55),
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Shadow"]:AddToTheme({ImageColor3 = "Shadow"})
				Items["Toggle"] = Instances:Create("TextButton", {
					Parent = Items["KeybindWindow"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
					Position = UDim2New(0, 8, 0, 8),
					Size = UDim2New(1, -16, 0, 25),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(22, 20, 24)
				}); Items["Toggle"]:AddToTheme({BackgroundColor3 = "Inline"})
				Instances:Create("UICorner", {
					Parent = Items["Toggle"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["ToggleText"] = Instances:Create("TextLabel", {
					Parent = Items["Toggle"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "Toggle",
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Position = UDim2New(0, 8, 0, 0),
					Size = UDim2New(1, -15, 1, 0),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["ToggleText"]:AddToTheme({TextColor3 = "Text"})
				Items["Hold"] = Instances:Create("TextButton", {
					Parent = Items["KeybindWindow"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Position = UDim2New(0, 8, 0, 33),
					Size = UDim2New(1, -16, 0, 25),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(22, 20, 24)
				}); Items["Hold"]:AddToTheme({BackgroundColor3 = "Inline"})
				Instances:Create("UICorner", {
					Parent = Items["Hold"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["HoldText"] = Instances:Create("TextLabel", {
					Parent = Items["Hold"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					TextTransparency = 0.4000000059604645,
					Text = "Hold",
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(1, -15, 1, 0),
					BackgroundTransparency = 1,
					Position = UDim2New(0, 4, 0, 0),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["HoldText"]:AddToTheme({TextColor3 = "Text"})
				Items["Always"] = Instances:Create("TextButton", {
					Parent = Items["KeybindWindow"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Position = UDim2New(0, 8, 0, 58),
					Size = UDim2New(1, -16, 0, 25),
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(22, 20, 24)
				}); Items["Always"]:AddToTheme({BackgroundColor3 = "Inline"})
				Instances:Create("UICorner", {
					Parent = Items["Always"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["AlwaysText"] = Instances:Create("TextLabel", {
					Parent = Items["Always"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					TextTransparency = 0.4000000059604645,
					Text = "Always",
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(1, -15, 1, 0),
					BackgroundTransparency = 1,
					Position = UDim2New(0, 4, 0, 0),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["AlwaysText"]:AddToTheme({TextColor3 = "Text"})
			end
			local Modes = {
				["Toggle"] = {Items["Toggle"], Items["ToggleText"]},
				["Hold"] = {Items["Hold"], Items["HoldText"]},
				["Always"] = {Items["Always"], Items["AlwaysText"]}
			}
			local Update = function()
				if KeylistItem then
					KeylistItem:Set(Keybind.Value, Data.Name, Keybind.Mode)
					KeylistItem:SetStatus(Keybind.Toggled)
				end
			end
			local function ResolveKeyEnum(KeyString)
				if Type(KeyString) ~= "string" then
					return nil
				end
				local Name = KeyString:match("^Enum%.KeyCode%.(.+)$")
				if Name then
					return Enum.KeyCode[Name]
				end
				Name = KeyString:match("^Enum%.UserInputType%.(.+)$")
				if Name then
					return Enum.UserInputType[Name]
				end
				return nil
			end
			function Keybind:Set(Key)
				if StringFind(tostring(Key), "Enum") then
					self.Key = tostring(Key)
					self.KeyEnum = ResolveKeyEnum(self.Key)
					Library:RefreshKeybind(self)
					Key = Key.Name == "Backspace" and "None" or Key.Name
					local KeyString = Keys[self.Key] or StringGSub(Key, "Enum.", "") or "None"
					local TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"
					self.Value = TextToDisplay
					Items["KeyButton"].Instance.Text = TextToDisplay
					Library.Flags[Data.Flag] = {
						Mode = self.Mode,
						Key = self.Key,
						Toggled = self.Toggled
					}
					WarnOnConflict(TextToDisplay)
					if Data.Callback then
						Library:SafeCall(Data.Callback, self.Toggled)
					end
					if self.OnChanged then
						self.OnChanged(self.Toggled)
					end
					Update()
				elseif type(Key) == "table" then
					local RealKey = Key.Key == "Backspace" and "None" or Key.Key
					self.Key = tostring(Key.Key)
					self.KeyEnum = ResolveKeyEnum(self.Key)
					Library:RefreshKeybind(self)
					if Key.Mode then
						self.Mode = Key.Mode
						self:SetMode(Key.Mode)
					else
						self.Mode = "toggle"
						self:SetMode("toggle")
					end
					local KeyString = Keys[self.Key] or StringGSub(tostring(RealKey), "Enum.", "") or RealKey
					local TextToDisplay = KeyString and StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"
					TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "")
					self.Value = TextToDisplay
					Items["KeyButton"].Instance.Text = TextToDisplay
					WarnOnConflict(TextToDisplay)
					if Data.Callback then
						Library:SafeCall(Data.Callback, self.Toggled)
					end
					if self.OnChanged then
						self.OnChanged(self.Toggled, self.Value)
					end
					Update()
				elseif TableFind({"toggle", "hold", "always"}, Key) then
					self.Mode = Key
					self:SetMode(Keybind.Mode)
					if Data.Callback then
						Library:SafeCall(Data.Callback, self.Toggled)
					end
					if self.OnChanged then
						self.OnChanged(self.Toggled, self.Value)
					end
					Update()
				end
				Items["KeyButton"]:ChangeItemTheme({TextColor3 = "Text", BackgroundColor3 = "Background"})
				Items["KeyButton"]:Tween(nil, {TextColor3 = Library.Theme.Text})
				self.Picking = false
			end
			function Keybind:RefreshKey()
				self.KeyEnum = ResolveKeyEnum(self.Key)
				Library:RefreshKeybind(self)
			end
			function Keybind:SetMode(Mode)
				for Index, Value in Modes do
					if Index == Mode then
						Value[1]:Tween(nil, {BackgroundTransparency = 0})
						Value[2]:Tween(nil, {TextTransparency = 0})
					else
						Value[1]:Tween(nil, {BackgroundTransparency = 1})
						Value[2]:Tween(nil, {TextTransparency = 0.4})
					end
				end
				Library.Flags[Data.Flag] = {
					Mode = self.Mode,
					Key = self.Key,
					Toggled = self.Toggled
				}
				if Data.Callback then
					Library:SafeCall(Data.Callback, self.Toggled)
				end
				if self.OnChanged then
					self.OnChanged(self.Toggled, self.Value)
				end
				Update()
			end
			local Debounce = false
			function Keybind:SetOpen(Bool, Instant)
				if Instant then
					Debounce = false
					self.IsOpen = not not Bool
					if Items["KeybindWindow"].Instance.Parent then
						Items["KeybindWindow"].Instance.Visible = self.IsOpen
					end
					if not self.IsOpen and Library.OpenFrames[self] then
						Library.OpenFrames[self] = nil
					end
					return
				end
				if Debounce then
					return
				end
				if self.IsOpen == (not not Bool) then
					return
				end
				self.IsOpen = not not Bool
				Debounce = true
				if self.IsOpen then
					Items["KeybindWindow"].Instance.Visible = true
					Library:PositionPopup(Items["KeybindWindow"].Instance, Items["KeyButton"].Instance, 0, 25)
					for Index, Value in Library.OpenFrames do
						if Value ~= self and Value.Key then
							Value:SetOpen(false)
						end
					end
					Library.OpenFrames[self] = self
				else
					if Library.OpenFrames[self] then
						Library.OpenFrames[self] = nil
					end
				end
				local NewTween = Library:FadeHolder(Items["KeybindWindow"].Instance, self.IsOpen, Data.Window.FadeSpeed, self.IsOpen and 15 or 1)
				local function Finish()
					Debounce = false
					Items["KeybindWindow"].Instance.Visible = self.IsOpen
				end
				if NewTween and NewTween.Tween then
					Library:Once(NewTween.Tween.Completed, Finish)
				else
					Finish()
				end
			end
			function Keybind:Press(Bool)
				if self.Mode == "Toggle" then
					self.Toggled = not self.Toggled
				elseif self.Mode == "Hold" then
					self.Toggled = Bool
				elseif self.Mode == "Always" then
					self.Toggled = true
				end
				Library.Flags[Data.Flag] = {
					Mode = self.Mode,
					Key = self.Key,
					Toggled = self.Toggled
				}
				if Data.Callback then
					Library:SafeCall(Data.Callback, self.Toggled)
				end
				if self.OnChanged then
					self.OnChanged(self.Toggled, self.Value)
				end
				Update()
			end
			Items["KeyButton"]:Connect("MouseButton2Down", function()
				Keybind:SetOpen(not Keybind.IsOpen)
			end)
			Items["KeyButton"]:Connect("MouseButton1Click", function()
				if Keybind.Picking then
					return
				end
				Keybind.Picking = true
				Items["KeyButton"]:ChangeItemTheme({TextColor3 = "Accent", BackgroundColor3 = "Background"})
				Items["KeyButton"]:Tween(nil, {TextColor3 = Library.Theme.Accent})
				local InputBegan
				InputBegan = UserInputService.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.Keyboard then
						Keybind:Set(Input.KeyCode)
					else
						Keybind:Set(Input.UserInputType)
					end
					InputBegan:Disconnect()
					InputBegan = nil
				end)
			end)
			Items["Hold"]:Connect("MouseButton1Down", function()
				Keybind.Mode = "Hold"
				Keybind:SetMode("Hold")
			end)
			Items["Toggle"]:Connect("MouseButton1Down", function()
				Keybind.Mode = "Toggle"
				Keybind:SetMode("Toggle")
			end)
			Items["Always"]:Connect("MouseButton1Down", function()
				Keybind.Mode = "Always"
				Keybind:SetMode("Always")
			end)
			Library:RegisterKeybind(Keybind)
			if Data.Default then
				Keybind.Mode = Data.Mode or "Toggle"
				Keybind:SetMode(Keybind.Mode)
				Keybind:Set({Key = Data.Default, Mode = Data.Mode})
			end
			Library.SetFlags[Data.Flag] = function(Value)
				Keybind:Set(Value)
			end
			return Keybind, Items
		end

		Components.MultilineTextbox = function(Data)
			local Textbox = {
				Value = "",
				Flag = Data.Flag,
				OnChanged = nil,
				Disabled = false
			}
			local Items = { } do
				Items["Textbox"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 86),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Textbox"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Size = UDim2New(0, 0, 0, 15),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Background"] = Instances:Create("Frame", {
					Parent = Items["Textbox"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0, 1),
					Position = UDim2New(0, 0, 1, 0),
					Size = UDim2New(1, 0, 0, 60),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Instances:Create("UIStroke", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					Color = FromRGB(41, 37, 45),
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				}):AddToTheme({Color = "Border"})
				Items["Input"] = Instances:Create("TextBox", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextStrokeColor3 = FromRGB(255, 255, 255),
					PlaceholderColor3 = FromRGB(185, 185, 185),
					PlaceholderText = Data.Placeholder,
					TextSize = 14,
					Size = UDim2New(1, -16, 1, 0),
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					ClearTextOnFocus = false,
					Text = "",
					TextWrapped = true,
					MultiLine = true,
					ZIndex = 3,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					CursorPosition = -1,
					Position = UDim2New(0, 8, 0, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Input"]:AddToTheme({TextColor3 = "Text", PlaceholderColor3 = "Inactive Text"})
			end
			function Textbox:Set(Value)
				if self.Disabled then
					return
				end
				Value = tostring(Value or "")
				Items["Input"].Instance.Text = Value
				Library.Flags[self.Flag] = Value
				if Data.Callback then
					Library:SafeCall(Data.Callback, Value)
				end
				if self.OnChanged then
					Library:SafeCall(self.OnChanged, Value)
				end
			end
			function Textbox:GetValue()
				return Items["Input"].Instance.Text
			end
			function Textbox:SetText(Text)
				Items["Input"].Instance.Text = tostring(Text or "")
			end
			function Textbox:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["Background"]:Tween(nil, {BackgroundTransparency = 0.6})
					Items["Input"]:Tween(nil, {TextTransparency = 0.6})
				else
					Items["Text"]:Tween(nil, {TextTransparency = 0})
					Items["Background"]:Tween(nil, {BackgroundTransparency = 0})
					Items["Input"]:Tween(nil, {TextTransparency = 0})
				end
			end
			function Textbox:SetVisible(Bool)
				Items["Textbox"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Textbox"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			Items["Input"]:Connect("Focused", function()
				if Textbox.Disabled then
					return
				end
				Items["Input"]:ChangeItemTheme({TextColor3 = "Accent", PlaceholderColor3 = "Inactive Text"})
				Items["Input"]:Tween(nil, {TextColor3 = Library.Theme.Accent})
			end)
			Items["Input"]:Connect("FocusLost", function()
				if Textbox.Disabled then
					return
				end
				Items["Input"]:ChangeItemTheme({TextColor3 = "Text", PlaceholderColor3 = "Inactive Text"})
				Items["Input"]:Tween(nil, {TextColor3 = Library.Theme.Text})
				Textbox:Set(Items["Input"].Instance.Text)
			end)
			if Data.Disabled then
				Textbox:SetDisabled(Data.Disabled)
			end
			if Data.Default then
				Textbox:Set(Data.Default)
			end
			Library.SetFlags[Data.Flag] = function(Value)
				Textbox:Set(Value)
			end
			return Textbox, Items
		end

		Components.Segmented = function(Data)
			local OptionList = Data.Items or { }
			if #OptionList == 0 then
				return
			end
			local Segmented = {
				Value = OptionList[1],
				Flag = Data.Flag,
				OnChanged = nil,
				Disabled = false
			}
			local OptionItems = { }
			local OptionCount = #OptionList
			local OptionScale = 1 / OptionCount
			local Items = { } do
				Items["Segmented"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, Data.HideName and 25 or 40),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Segmented"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2New(0, 0, 0, 15),
					AnchorPoint = Vector2New(0, 0.5),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					Visible = not Data.HideName,
					Position = UDim2New(0, 0, 0, 0),
					BackgroundTransparency = 1,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Background"] = Instances:Create("Frame", {
					Parent = Items["Segmented"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0, 1),
					Position = UDim2New(0, 0, 1, 0),
					Size = UDim2New(1, 0, 0, 25),
					ZIndex = 2,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["Accent"] = Instances:Create("Frame", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					Size = UDim2New(OptionScale, -2, 1, 0),
					Position = UDim2New(0, 1, 0, 0),
					ZIndex = 3,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(59, 130, 246)
				}); Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
				Instances:Create("UICorner", {
					Parent = Items["Accent"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				for Index, Option in ipairs(OptionList) do
					OptionItems[Option] = Instances:Create("TextButton", {
						Parent = Items["Background"].Instance,
						Name = "\0",
						FontFace = Library.Font,
						Text = tostring(Option),
						AutoButtonColor = false,
						TextColor3 = FromRGB(255, 255, 255),
						BorderColor3 = FromRGB(0, 0, 0),
						Size = UDim2New(OptionScale, 0, 1, 0),
						Position = UDim2New((Index - 1) * OptionScale, 0, 0, 0),
						ZIndex = 4,
						BorderSizePixel = 0,
						TextSize = 14,
						BackgroundTransparency = 1,
						BackgroundColor3 = FromRGB(255, 255, 255)
					}); OptionItems[Option]:AddToTheme({TextColor3 = "Text"})
				end
			end
			local function Refresh(Value)
				local Index = TableFind(OptionList, Value) or 1
				for Option, OptionItem in OptionItems do
					OptionItem:ChangeItemTheme({TextColor3 = Option == Value and "Accent" or "Inactive Text"})
					OptionItem.Instance.TextTransparency = Option == Value and 0 or 0.4
				end
				Items["Accent"]:Tween(nil, {Position = UDim2New((Index - 1) * OptionScale, 1, 0, 0)})
			end
			function Segmented:Set(Value)
				if self.Disabled then
					return
				end
				if not TableFind(OptionList, Value) then
					return
				end
				self.Value = Value
				Library.Flags[self.Flag] = Value
				Refresh(Value)
				if Data.Callback then
					Library:SafeCall(Data.Callback, Value)
				end
				if self.OnChanged then
					Library:SafeCall(self.OnChanged, Value)
				end
			end
			function Segmented:GetValue()
				return self.Value
			end
			function Segmented:SetText(Text)
				Items["Text"].Instance.Text = tostring(Text)
			end
			function Segmented:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["Background"]:Tween(nil, {BackgroundTransparency = 0.6})
					Items["Accent"]:Tween(nil, {BackgroundTransparency = 0.6})
					for Option, OptionItem in OptionItems do
						OptionItem:Tween(nil, {TextTransparency = 0.6})
					end
				else
					Items["Text"]:Tween(nil, {TextTransparency = 0})
					Items["Background"]:Tween(nil, {BackgroundTransparency = 0})
					Items["Accent"]:Tween(nil, {BackgroundTransparency = 0})
					Refresh(self.Value)
				end
			end
			function Segmented:SetVisible(Bool)
				Items["Segmented"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Segmented"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			for Index, Option in ipairs(OptionList) do
				OptionItems[Option]:Connect("MouseButton1Down", function()
					if Segmented.Disabled then
						return
					end
					Segmented:Set(Option)
				end)
			end
			if Data.Disabled then
				Segmented:SetDisabled(Data.Disabled)
			end
			if Data.Default and TableFind(OptionList, Data.Default) then
				Segmented:Set(Data.Default)
			else
				Library.Flags[Segmented.Flag] = Segmented.Value
				Refresh(Segmented.Value)
			end
			Library.SetFlags[Data.Flag] = function(Value)
				Segmented:Set(Value)
			end
			return Segmented, Items
		end

		Components.HoldButton = function(Data)
			local HoldButton = {
				Flag = Data.Flag,
				OnChanged = nil,
				Disabled = false,
				Holding = false
			}
			local FillTween
			local Token = 0
			local Duration = Data.Duration or 1
			local Items = { } do
				Items["HoldButton"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 35),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Button"] = Instances:Create("TextButton", {
					Parent = Items["HoldButton"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					Text = Data.Name or "Hold",
					AutoButtonColor = false,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0, 1),
					Position = UDim2New(0, 0, 1, 0),
					Size = UDim2New(1, 0, 0, 25),
					ZIndex = 2,
					BorderSizePixel = 0,
					TextSize = 14,
					ClipsDescendants = true,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["Button"]:AddToTheme({BackgroundColor3 = "Element", TextColor3 = "Text"})
				Items["Fill"] = Instances:Create("Frame", {
					Parent = Items["Button"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(0, 0, 1, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(59, 130, 246)
				}); Items["Fill"]:AddToTheme({BackgroundColor3 = "Accent"})
				Instances:Create("UICorner", {
					Parent = Items["Button"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Button"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name or "Hold",
					Size = UDim2New(1, 0, 1, 0),
					BackgroundTransparency = 1,
					ZIndex = 3,
					BorderSizePixel = 0,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
			end
			local function Reset()
				HoldButton.Holding = false
				Token += 1
				if FillTween then
					FillTween:Cancel()
					FillTween = nil
				end
				Items["Fill"]:Tween(nil, {Size = UDim2New(0, 0, 1, 0)})
			end
			function HoldButton:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Reset()
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["Button"]:Tween(nil, {BackgroundTransparency = 0.6})
				else
					Items["Text"]:Tween(nil, {TextTransparency = 0})
					Items["Button"]:Tween(nil, {BackgroundTransparency = 0})
				end
			end
			function HoldButton:SetText(Text)
				Items["Text"].Instance.Text = tostring(Text)
				Items["Button"].Instance.Text = ""
			end
			function HoldButton:SetVisible(Bool)
				Items["HoldButton"].Instance.Visible = Bool
			end
			function HoldButton:SetDuration(NewDuration)
				Duration = NewDuration or 1
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["HoldButton"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			Items["Button"]:Connect("InputBegan", function(Input)
				if Input.UserInputType ~= InputTypeMouseButton1 and Input.UserInputType ~= InputTypeTouch then
					return
				end
				if HoldButton.Disabled or HoldButton.Holding then
					return
				end
				HoldButton.Holding = true
				Token += 1
				local CurrentToken = Token
				FillTween = TweenService:Create(Items["Fill"].Instance, Tween:Info(Duration), {Size = UDim2New(1, 0, 1, 0)})
				FillTween:Play()
				FillTween.Completed:Once(function(PlaybackState)
					if CurrentToken ~= Token then
						return
					end
					FillTween = nil
					if PlaybackState ~= Enum.PlaybackState.Completed then
						return
					end
					HoldButton.Holding = false
					Token += 1
					Items["Fill"]:Tween(nil, {Size = UDim2New(0, 0, 1, 0)})
					if Data.Callback then
						Library:SafeCall(Data.Callback)
					end
					if HoldButton.OnChanged then
						Library:SafeCall(HoldButton.OnChanged)
					end
				end)
			end)
			Items["Button"]:Connect("InputEnded", function(Input)
				if Input.UserInputType ~= InputTypeMouseButton1 and Input.UserInputType ~= InputTypeTouch then
					return
				end
				if HoldButton.Holding then
					Reset()
				end
			end)
			if Data.Disabled then
				HoldButton:SetDisabled(Data.Disabled)
			end
			return HoldButton, Items
		end

		Components.Accordion = function(Data)
			local Accordion = {
				Value = Data.Default or false,
				Flag = Data.Flag,
				OnChanged = nil,
				Disabled = false
			}
			local Items = { } do
				Items["Accordion"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					AutomaticSize = Enum.AutomaticSize.Y,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Header"] = Instances:Create("TextButton", {
					Parent = Items["Accordion"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					Text = "",
					AutoButtonColor = false,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(1, 0, 0, 25),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["Header"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["Header"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Header"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name or "Accordion",
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2New(0, 0, 0, 15),
					AnchorPoint = Vector2New(0, 0.5),
					Position = UDim2New(0, 8, 0.5, 0),
					BackgroundTransparency = 1,
					ZIndex = 3,
					BorderSizePixel = 0,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Indicator"] = Instances:Create("TextLabel", {
					Parent = Items["Header"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = ">",
					Size = UDim2New(0, 20, 1, 0),
					AnchorPoint = Vector2New(1, 0.5),
					Position = UDim2New(1, -8, 0.5, 0),
					BackgroundTransparency = 1,
					ZIndex = 3,
					BorderSizePixel = 0,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Indicator"]:AddToTheme({TextColor3 = "Inactive Text"})
				Items["Content"] = Instances:Create("Frame", {
					Parent = Items["Accordion"].Instance,
					Name = "\0",
					Size = UDim2New(1, 0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					Position = UDim2New(0, 0, 0, 25),
					BackgroundTransparency = 1,
					ZIndex = 2,
					AutomaticSize = Enum.AutomaticSize.Y,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UIListLayout", {
					Parent = Items["Content"].Instance,
					Name = "\0",
					Padding = UDimNew(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder
				})
				Instances:Create("UIPadding", {
					Parent = Items["Content"].Instance,
					Name = "\0",
					PaddingTop = UDimNew(0, 6),
					PaddingBottom = UDimNew(0, 0)
				})
			end
			local function Refresh(Value)
				Accordion.Value = Value
				Library.Flags[Accordion.Flag] = Value
				Items["Indicator"].Instance.Text = Value and "v" or ">"
				Items["Content"].Instance.Visible = Value
				if Accordion.OnChanged then
					Library:SafeCall(Accordion.OnChanged, Value)
				end
				if Data.Callback then
					Library:SafeCall(Data.Callback, Value)
				end
			end
			function Accordion:Set(Value)
				if self.Disabled then
					return
				end
				Refresh(not not Value)
			end
			function Accordion:Expand(Bool)
				if self.Disabled then
					return
				end
				if Bool == nil then
					Refresh(not Accordion.Value)
				else
					Refresh(not not Bool)
				end
			end
			function Accordion:Collapse()
				if self.Disabled then
					return
				end
				Refresh(false)
			end
			function Accordion:SetText(Text)
				Items["Text"].Instance.Text = tostring(Text)
			end
			function Accordion:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["Indicator"]:Tween(nil, {TextTransparency = 0.6})
					Items["Header"]:Tween(nil, {BackgroundTransparency = 0.6})
				else
					Items["Text"]:Tween(nil, {TextTransparency = 0})
					Items["Indicator"]:Tween(nil, {TextTransparency = 0})
					Items["Header"]:Tween(nil, {BackgroundTransparency = 0})
				end
			end
			function Accordion:SetVisible(Bool)
				Items["Accordion"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Accordion"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			Items["Header"]:Connect("MouseButton1Down", function()
				Accordion:Expand()
			end)
			Items["Content"].Instance.Visible = Accordion.Value
			Items["Indicator"].Instance.Text = Accordion.Value and "v" or ">"
			Library.Flags[Data.Flag] = Accordion.Value
			Library.QueueWarmContainer(Items["Content"].Instance)
			return Accordion, Items
		end

		Components.RangeSlider = function(Data)
			local RangeSlider = {
				Low = Data.Min or 0,
				High = Data.Max or 100,
				Flag = Data.Flag,
				Sliding = nil,
				OnChanged = nil,
				Disabled = false
			}
			local Items = { } do
				Items["RangeSlider"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 45),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["RangeSlider"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Size = UDim2New(0, 0, 0, 15),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Value"] = Instances:Create("TextLabel", {
					Parent = Items["RangeSlider"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "--",
					AutomaticSize = Enum.AutomaticSize.X,
					AnchorPoint = Vector2New(1, 0),
					Size = UDim2New(0, 0, 0, 15),
					BackgroundTransparency = 1,
					Position = UDim2New(1, 0, 0, 0),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Value"]:AddToTheme({TextColor3 = "Text"})
				Items["RealSlider"] = Instances:Create("TextButton", {
					Parent = Items["RangeSlider"].Instance,
					AutoButtonColor = false,
					Text = "",
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0, 1),
					Position = UDim2New(0, 0, 1, 0),
					Size = UDim2New(1, 0, 0, 15),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["RealSlider"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["RealSlider"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Instances:Create("UIGradient", {
					Parent = Items["RealSlider"].Instance,
					Name = "\0",
					Rotation = 90,
					Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(216, 216, 216))}
				}):AddToTheme({Color = function()
					return RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, Library.Theme["Gradient"])}
				end})
				Items["Accent"] = Instances:Create("Frame", {
					Parent = Items["RealSlider"].Instance,
					Name = "\0",
					Size = UDim2New(0.5, 0, 1, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(59, 130, 246)
				}); Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
				Instances:Create("UICorner", {
					Parent = Items["Accent"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				for Index, HandleName in ipairs({ "Low", "High" }) do
					Items[HandleName .. "Handle"] = Instances:Create("Frame", {
						Parent = Items["Accent"].Instance,
						Name = "\0",
						BorderColor3 = FromRGB(0, 0, 0),
						AnchorPoint = Vector2New(0.5, 0.5),
						Position = UDim2New(Index == 1 and 0 or 1, 0, 0.5, 0),
						Size = UDim2New(0, 10, 1, 6),
						ZIndex = 3,
						BorderSizePixel = 0,
						BackgroundColor3 = FromRGB(255, 255, 255)
					}); Items[HandleName .. "Handle"]:AddToTheme({BackgroundColor3 = "Text"})
					Instances:Create("UICorner", {
						Parent = Items[HandleName .. "Handle"].Instance,
						Name = "\0",
						CornerRadius = UDimNew(1, 0)
					})
				end
			end
			local function Snap(Value)
				local Snapped = MathClamp(Value, Data.Min, Data.Max)
				if Data.Step and Data.Step > 0 then
					local Steps = MathFloor(((Snapped - Data.Min) / Data.Step) + 0.5)
					Snapped = Data.Min + (Steps * Data.Step)
				end
				return MathClamp(Library:Round(Snapped, Data.Decimals), Data.Min, Data.Max)
			end
			local function RatioOf(Value)
				local Range = Data.Max - Data.Min
				if Range == 0 then
					return 0
				end
				return (Value - Data.Min) / Range
			end
			local function FormatValue(Value)
				if Data.Format then
					local FormatSuccess, FormatResult = pcall(StringFormat, Data.Format, Value)
					if FormatSuccess then
						return FormatResult
					end
				end
				return tostring(Value)
			end
			local function Refresh()
				local LowSize = RatioOf(RangeSlider.Low)
				local HighSize = RatioOf(RangeSlider.High)
				Items["Accent"].Instance.Size = UDim2New(MathMax(HighSize - LowSize, 0), 0, 1, 0)
				Items["Accent"].Instance.Position = UDim2New(LowSize, 0, 0, 0)
				local Label = StringFormat("%s - %s", FormatValue(RangeSlider.Low), FormatValue(RangeSlider.High))
				if Items["Value"].Instance.Text ~= Label then
					Items["Value"].Instance.Text = Label
				end
			end
			function RangeSlider:Set(Low, High)
				if self.Disabled then
					return
				end
				if type(Low) == "table" then
					Low, High = Low.Low or Low[1] or Data.Min, Low.High or Low[2] or Data.Max
				end
				Low = Snap(Low)
				High = Snap(High or Low)
				if Low > High then
					Low, High = High, Low
				end
				self.Low = Low
				self.High = High
				Library.Flags[self.Flag] = { Low = Low, High = High }
				Refresh()
				if Data.Callback then
					Library:SafeCall(Data.Callback, Low, High)
				end
				if self.OnChanged then
					Library:SafeCall(self.OnChanged, Low, High)
				end
			end
			function RangeSlider:Get()
				return self.Low, self.High
			end
			function RangeSlider:SetText(Text)
				Items["Text"].Instance.Text = tostring(Text)
			end
			function RangeSlider:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["Value"]:Tween(nil, {TextTransparency = 0.6})
					Items["RealSlider"]:Tween(nil, {BackgroundTransparency = 0.6})
					Items["Accent"]:Tween(nil, {BackgroundTransparency = 0.6})
				else
					Items["Text"]:Tween(nil, {TextTransparency = 0})
					Items["Value"]:Tween(nil, {TextTransparency = 0})
					Items["RealSlider"]:Tween(nil, {BackgroundTransparency = 0})
					Items["Accent"]:Tween(nil, {BackgroundTransparency = 0})
				end
			end
			function RangeSlider:SetVisible(Bool)
				Items["RangeSlider"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["RangeSlider"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			Items["RealSlider"]:Connect("InputBegan", function(Input)
				if Input.UserInputType ~= InputTypeMouseButton1 and Input.UserInputType ~= InputTypeTouch then
					return
				end
				if RangeSlider.Disabled then
					return
				end
				local Track = Items["RealSlider"].Instance
				local SizeX = MathClamp((Input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				local Target = Snap(Data.Min + ((Data.Max - Data.Min) * SizeX))
				if MathAbs(Target - RangeSlider.Low) <= MathAbs(Target - RangeSlider.High) then
					RangeSlider.Sliding = "Low"
				else
					RangeSlider.Sliding = "High"
				end
				RangeSlider:Set(Target, RangeSlider.High)
				RangeSlider:Set(RangeSlider.Low, Target)
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						RangeSlider.Sliding = nil
					end
				end)
			end)
			Library:On(UserInputService.InputChanged, function(Input)
				if not RangeSlider.Sliding or RangeSlider.Disabled then
					return
				end
				if Input.UserInputType ~= InputTypeMouseMovement and Input.UserInputType ~= InputTypeTouch then
					return
				end
				local Track = Items["RealSlider"].Instance
				local SizeX = MathClamp((Input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				local Target = Snap(Data.Min + ((Data.Max - Data.Min) * SizeX))
				if RangeSlider.Sliding == "Low" then
					RangeSlider:Set(Target, RangeSlider.High)
				else
					RangeSlider:Set(RangeSlider.Low, Target)
				end
			end, TypesMove)
			if Data.Disabled then
				RangeSlider:SetDisabled(Data.Disabled)
			end
			if Data.Default then
				RangeSlider:Set(Data.Default)
			else
				Library.Flags[Data.Flag] = { Low = RangeSlider.Low, High = RangeSlider.High }
				Refresh()
			end
			Library.SetFlags[Data.Flag] = function(Value)
				if type(Value) == "table" then
					RangeSlider:Set(Value.Low, Value.High)
				else
					RangeSlider:Set(Value)
				end
			end
			return RangeSlider, Items
		end

		Components.RadioList = function(Data)
			local OptionList = Data.Items or { }
			if #OptionList == 0 then
				return
			end
			local RadioList = {
				Value = OptionList[1],
				Flag = Data.Flag,
				OnChanged = nil,
				Disabled = false,
				Options = { }
			}
			local Items = { } do
				Items["RadioList"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, Data.HideName and (#OptionList * 28 + 6) or (25 + (#OptionList * 28))),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["RadioList"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Size = UDim2New(0, 0, 0, 15),
					AnchorPoint = Vector2New(0, 0.5),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					Visible = not Data.HideName,
					Position = UDim2New(0, 0, 0, 0),
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Options"] = Instances:Create("Frame", {
					Parent = Items["RadioList"].Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, #OptionList * 28),
					BorderColor3 = FromRGB(0, 0, 0),
					Position = UDim2New(0, 0, 0, Data.HideName and 0 or 25),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UIListLayout", {
					Parent = Items["Options"].Instance,
					Name = "\0",
					Padding = UDimNew(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder
				})
			end
			local function Refresh(Value)
				for Option, OptionData in RadioList.Options do
					OptionData.Selected = Option == Value
					OptionData.Button.Instance.BackgroundTransparency = Option == Value and 0 or 1
					OptionData.Circle.Instance.Size = UDim2New(0, Option == Value and 12 or 8, 0, Option == Value and 12 or 8)
				end
			end
			function RadioList:Set(Value)
				if self.Disabled then
					return
				end
				if not self.Options[Value] then
					return
				end
				self.Value = Value
				Library.Flags[self.Flag] = Value
				Refresh(Value)
				if Data.Callback then
					Library:SafeCall(Data.Callback, Value)
				end
				if self.OnChanged then
					Library:SafeCall(self.OnChanged, Value)
				end
			end
			function RadioList:Get()
				return self.Value
			end
			function RadioList:SetText(Text)
				Items["Text"].Instance.Text = tostring(Text)
			end
			function RadioList:SetDisabled(Bool)
				self.Disabled = Bool
				for Option, OptionData in self.Options do
					OptionData.Button.Instance.Active = not Bool
				end
			end
			function RadioList:SetVisible(Bool)
				Items["RadioList"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["RadioList"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			for Index, Option in ipairs(OptionList) do
				local OptionButton = Instances:Create("TextButton", {
					Parent = Items["Options"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					Text = "",
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2New(1, 0, 0, 22),
					ZIndex = 2,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); OptionButton:AddToTheme({BackgroundColor3 = "Inline"})
				Instances:Create("UICorner", {
					Parent = OptionButton.Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				local Circle = Instances:Create("Frame", {
					Parent = OptionButton.Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0, 0.5),
					Position = UDim2New(0, 5, 0.5, 0),
					Size = UDim2New(0, 8, 0, 8),
					ZIndex = 3,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Circle:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Circle.Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				local OptionText = Instances:Create("TextLabel", {
					Parent = OptionButton.Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = tostring(Option),
					Size = UDim2New(1, -25, 1, 0),
					Position = UDim2New(0, 20, 0, 0),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					BorderSizePixel = 0,
					ZIndex = 3,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); OptionText:AddToTheme({TextColor3 = "Text"})
				RadioList.Options[Option] = {
					Name = Option,
					Button = OptionButton,
					Circle = Circle,
					Text = OptionText,
					Selected = false
				}
				OptionButton:Connect("MouseButton1Down", function()
					if RadioList.Disabled then
						return
					end
					RadioList:Set(Option)
				end)
			end
			if Data.Disabled then
				RadioList:SetDisabled(Data.Disabled)
			end
			if Data.Default and RadioList.Options[Data.Default] then
				RadioList:Set(Data.Default)
			else
				Library.Flags[RadioList.Flag] = RadioList.Value
				Refresh(RadioList.Value)
			end
			Library.SetFlags[RadioList.Flag] = function(Value)
				RadioList:Set(Value)
			end
			return RadioList, Items
		end

		Components.NumberInput = function(Data)
			local NumberInput = {
				Value = Data.Default or Data.Min or 0,
				Flag = Data.Flag,
				OnChanged = nil,
				Disabled = false
			}
			local Min = Data.Min or 0
			local Max = Data.Max or 100
			local Step = Data.Step or 1
			local Decimals = Data.Decimals or 0
			local Items = { } do
				Items["NumberInput"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 35),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["NumberInput"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Size = UDim2New(0, 0, 0, 15),
					AnchorPoint = Vector2New(0, 0.5),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					Visible = not Data.HideName,
					Position = UDim2New(0, 0, 0.5, 0),
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Background"] = Instances:Create("Frame", {
					Parent = Items["NumberInput"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(1, 1),
					Position = UDim2New(1, 0, 1, 0),
					Size = UDim2New(0, 130, 0, 25),
					ZIndex = 2,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				local function CreateButton(AnchorX, Text, OffsetX)
					local Button = Instances:Create("TextButton", {
						Parent = Items["Background"].Instance,
						Name = "\0",
						FontFace = Library.Font,
						Text = Text,
						AutoButtonColor = false,
						TextColor3 = FromRGB(255, 255, 255),
						BorderColor3 = FromRGB(0, 0, 0),
						AnchorPoint = Vector2New(AnchorX, 0.5),
						Position = UDim2New(AnchorX, OffsetX, 0.5, 0),
						Size = UDim2New(0, 22, 1, 0),
						ZIndex = 3,
						BorderSizePixel = 0,
						TextSize = 16,
						BackgroundTransparency = 1,
						BackgroundColor3 = FromRGB(255, 255, 255)
					}); Button:AddToTheme({TextColor3 = "Text"})
					return Button
				end
				Items["Down"] = CreateButton(0, "-", 13)
				Items["Up"] = CreateButton(1, "+", -13)
				Items["Input"] = Instances:Create("TextBox", {
					Parent = Items["Background"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					PlaceholderColor3 = FromRGB(185, 185, 185),
					TextSize = 14,
					Size = UDim2New(1, -48, 1, 0),
					Position = UDim2New(0, 24, 0, 0),
					ClearTextOnFocus = false,
					Text = "",
					ZIndex = 3,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Center,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Input"]:AddToTheme({TextColor3 = "Text", PlaceholderColor3 = "Inactive Text"})
			end
			local function FormatValue(Value)
				if Data.Format then
					local FormatSuccess, FormatResult = pcall(StringFormat, Data.Format, Value)
					if FormatSuccess then
						return FormatResult
					end
				end
				return tostring(Value)
			end
			local function Refresh()
				Items["Input"].Instance.Text = FormatValue(NumberInput.Value)
			end
			function NumberInput:Set(Value)
				if self.Disabled then
					return
				end
				Value = tonumber(Value) or Min
				if Data.Wrap then
					if Value > Max then Value = Min end
					if Value < Min then Value = Max end
				else
					Value = MathClamp(Value, Min, Max)
				end
				self.Value = Library:Round(Value, Decimals)
				Library.Flags[self.Flag] = self.Value
				Refresh()
				if Data.Callback then
					Library:SafeCall(Data.Callback, self.Value)
				end
				if self.OnChanged then
					Library:SafeCall(self.OnChanged, self.Value)
				end
			end
			function NumberInput:Get()
				return self.Value
			end
			function NumberInput:Increment()
				self:Set(self.Value + Step)
			end
			function NumberInput:Decrement()
				self:Set(self.Value - Step)
			end
			function NumberInput:SetText(Text)
				Items["Text"].Instance.Text = tostring(Text)
			end
			function NumberInput:SetDisabled(Bool)
				self.Disabled = Bool
				if self.Disabled then
					Items["Text"]:Tween(nil, {TextTransparency = 0.6})
					Items["Background"]:Tween(nil, {BackgroundTransparency = 0.6})
					Items["Input"]:Tween(nil, {TextTransparency = 0.6})
					Items["Down"]:Tween(nil, {TextTransparency = 0.6})
					Items["Up"]:Tween(nil, {TextTransparency = 0.6})
				else
					Items["Text"]:Tween(nil, {TextTransparency = 0})
					Items["Background"]:Tween(nil, {BackgroundTransparency = 0})
					Items["Input"]:Tween(nil, {TextTransparency = 0})
					Items["Down"]:Tween(nil, {TextTransparency = 0})
					Items["Up"]:Tween(nil, {TextTransparency = 0})
				end
			end
			function NumberInput:SetVisible(Bool)
				Items["NumberInput"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["NumberInput"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			Items["Up"]:Connect("MouseButton1Down", function()
				if NumberInput.Disabled then
					return
				end
				NumberInput:Increment()
			end)
			Items["Down"]:Connect("MouseButton1Down", function()
				if NumberInput.Disabled then
					return
				end
				NumberInput:Decrement()
			end)
			Items["Input"]:Connect("FocusLost", function()
				if NumberInput.Disabled then
					return
				end
				NumberInput:Set(Items["Input"].Instance.Text)
			end)
			if Data.Disabled then
				NumberInput:SetDisabled(Data.Disabled)
			end
			NumberInput:Set(NumberInput.Value)
			Library.SetFlags[Data.Flag] = function(Value)
				NumberInput:Set(Value)
			end
			return NumberInput, Items
		end

		Components.Progress = function(Data)
			local Progress = {
				Value = Data.Default or 0,
				Flag = Data.Flag,
				Max = Data.Max or 100,
				OnChanged = nil
			}
			local Items = { } do
				Items["Progress"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 35),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Progress"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Size = UDim2New(0, 0, 0, 15),
					AnchorPoint = Vector2New(0, 0.5),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					Visible = not Data.HideName,
					Position = UDim2New(0, 0, 0, 0),
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Value"] = Instances:Create("TextLabel", {
					Parent = Items["Progress"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = "--",
					AutomaticSize = Enum.AutomaticSize.X,
					AnchorPoint = Vector2New(1, 0),
					Size = UDim2New(0, 0, 0, 15),
					Position = UDim2New(1, 0, 0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Value"]:AddToTheme({TextColor3 = "Text"})
				Items["Track"] = Instances:Create("Frame", {
					Parent = Items["Progress"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					AnchorPoint = Vector2New(0, 1),
					Position = UDim2New(0, 0, 1, 0),
					Size = UDim2New(1, 0, 0, 8),
					ZIndex = 2,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					BackgroundColor3 = FromRGB(36, 32, 39)
				}); Items["Track"]:AddToTheme({BackgroundColor3 = "Element"})
				Instances:Create("UICorner", {
					Parent = Items["Track"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
				Items["Fill"] = Instances:Create("Frame", {
					Parent = Items["Track"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					Size = UDim2New(0, 0, 1, 0),
					ZIndex = 3,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(59, 130, 246)
				}); Items["Fill"]:AddToTheme({BackgroundColor3 = "Accent"})
				Instances:Create("UICorner", {
					Parent = Items["Fill"].Instance,
					Name = "\0",
					CornerRadius = UDimNew(1, 0)
				})
			end
			local function Refresh()
				local Ratio = 0
				if Progress.Max ~= 0 then
					Ratio = MathClamp(Progress.Value / Progress.Max, 0, 1)
				end
				Items["Fill"].Instance.Size = UDim2New(Ratio, 0, 1, 0)
				Items["Value"].Instance.Text = StringFormat("%s%s / %s%s", Data.Prefix or "", tostring(Progress.Value), tostring(Progress.Max), Data.Suffix or "")
			end
			function Progress:Set(Value)
				Value = tonumber(Value) or 0
				self.Value = Value
				Library.Flags[self.Flag] = Value
				Refresh()
				if Data.Callback then
					Library:SafeCall(Data.Callback, Value)
				end
				if self.OnChanged then
					Library:SafeCall(self.OnChanged, Value)
				end
			end
			function Progress:Get()
				return self.Value
			end
			function Progress:SetMax(Value)
				self.Max = tonumber(Value) or 100
				Refresh()
			end
			function Progress:SetText(Text)
				Items["Text"].Instance.Text = tostring(Text)
			end
			function Progress:SetVisible(Bool)
				Items["Progress"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Progress"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			Library.Flags[Data.Flag] = Progress.Value
			Refresh()
			Library.SetFlags[Data.Flag] = function(Value)
				Progress:Set(Value)
			end
			return Progress, Items
		end

		Components.Listbox = function(Data)
			local Listbox = {
				Value = nil,
				Flag = Data.Flag,
				OnChanged = nil,
				Multi = Data.Multi or false,
				Selected = { },
				Rows = { },
				Order = { }
			}
			local Items = { } do
				Items["Listbox"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, (Data.Rows or 4) * 26 + 25),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					AutomaticSize = Enum.AutomaticSize.None,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Listbox"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = Data.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Size = UDim2New(0, 0, 0, 15),
					BorderSizePixel = 0,
					ZIndex = 2,
					TextSize = 14,
					Position = UDim2New(0, 0, 0, 0),
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
				Items["Holder"] = Instances:Create("ScrollingFrame", {
					Parent = Items["Listbox"].Instance,
					Name = "\0",
					Active = true,
					BackgroundTransparency = 1,
					BorderColor3 = FromRGB(0, 0, 0),
					Position = UDim2New(0, 0, 0, 25),
					Size = UDim2New(1, 0, 1, -25),
					ScrollBarImageColor3 = FromRGB(59, 130, 246),
					ScrollBarImageTransparency = 0.3,
					ScrollBarThickness = 3,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2New(0, 0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
				Instances:Create("UIListLayout", {
					Parent = Items["Holder"].Instance,
					Name = "\0",
					Padding = UDimNew(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder
				})
				Library:EnableSmoothScroll(Items["Holder"].Instance)
			end
			local function RefreshRow(Row)
				Row.Selected = not not Listbox.Selected[Row.Name]
				Row.Button.Instance.BackgroundTransparency = Row.Selected and 0 or 1
				Row.Text:Tween(nil, {TextTransparency = Row.Selected and 0 or 0.4})
			end
			local function PushFlags()
				if Listbox.Multi then
					local Values = { }
					for _, Name in pairs(Listbox.Selected) do
						TableInsert(Values, Name)
					end
					Library.Flags[Listbox.Flag] = Values
				else
					Library.Flags[Listbox.Flag] = Listbox.Value
				end
			end
			function Listbox:Add(Name, Icon)
				if self.Rows[Name] then
					return self.Rows[Name]
				end
				local Row = Instances:Create("TextButton", {
					Parent = Items["Holder"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					Text = "",
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2New(1, 0, 0, 22),
					ZIndex = 3,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Row:AddToTheme({BackgroundColor3 = "Inline"})
				Instances:Create("UICorner", {
					Parent = Row.Instance,
					Name = "\0",
					CornerRadius = UDimNew(0, 5)
				})
				local RowText = Instances:Create("TextLabel", {
					Parent = Row.Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = tostring(Name),
					Size = UDim2New(1, Icon and -32 or -12, 1, 0),
					Position = UDim2New(0, Icon and 26 or 6, 0, 0),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					BorderSizePixel = 0,
					ZIndex = 4,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); RowText:AddToTheme({TextColor3 = "Text"})
				if Icon then
					Instances:Create("ImageLabel", {
						Parent = Row.Instance,
						Name = "\0",
						BorderColor3 = FromRGB(0, 0, 0),
						Size = UDim2New(0, 16, 0, 16),
						AnchorPoint = Vector2New(0, 0.5),
						Image = "rbxassetid://" .. tostring(Icon),
						BackgroundTransparency = 1,
						Position = UDim2New(0, 6, 0.5, 0),
						ZIndex = 4,
						BorderSizePixel = 0,
						BackgroundColor3 = FromRGB(255, 255, 255)
					})
				end
				local RowData = {
					Name = Name,
					Button = Row,
					Text = RowText,
					Selected = false
				}
				self.Rows[Name] = RowData
				TableInsert(self.Order, Name)
				Row:Connect("MouseButton1Down", function()
					if Listbox.Multi then
						Listbox.Selected[Name] = not Listbox.Selected[Name]
						RefreshRow(RowData)
						PushFlags()
					else
						for Other, OtherRow in Listbox.Rows do
							Listbox.Selected[Other] = Other == Name
							RefreshRow(OtherRow)
						end
						Listbox.Value = Name
						PushFlags()
					end
					if Data.Callback then
						Library:SafeCall(Data.Callback, Listbox.Value, Listbox.Selected)
					end
					if Listbox.OnChanged then
						Library:SafeCall(Listbox.OnChanged, Listbox.Value, Listbox.Selected)
					end
				end)
				return RowData
			end
			function Listbox:Remove(Name)
				local Row = self.Rows[Name]
				if not Row then
					return
				end
				self.Selected[Name] = nil
				if self.Value == Name then
					self.Value = nil
				end
				Row.Button:Clean()
				self.Rows[Name] = nil
				local Position = TableFind(self.Order, Name)
				if Position then
					TableRemove(self.Order, Position)
				end
			end
			function Listbox:Clear()
				for Index = #self.Order, 1, -1 do
					self:Remove(self.Order[Index])
				end
			end
			function Listbox:Refresh(List)
				self:Clear()
				for Index, Value in ipairs(List or { }) do
					self:Add(Value)
				end
			end
			function Listbox:Set(Name)
				if self.Multi then
					if type(Name) == "table" then
						self.Selected = { }
						for Index, Value in ipairs(Name) do
							self.Selected[Value] = true
						end
					end
					for Option, Row in self.Rows do
						RefreshRow(Row)
					end
				else
					if type(Name) == "table" then
						Name = Name[1]
					end
					self.Value = Name
					for Option, Row in self.Rows do
						self.Selected[Option] = Option == Name
						RefreshRow(Row)
					end
				end
				PushFlags()
			end
			function Listbox:Get()
				if self.Multi then
					local Values = { }
					for _, Name in ipairs(self.Order) do
						if self.Selected[Name] then
							TableInsert(Values, Name)
						end
					end
					return Values
				end
				return self.Value
			end
			function Listbox:SetText(Text)
				Items["Text"].Instance.Text = tostring(Text)
			end
			function Listbox:SetVisible(Bool)
				Items["Listbox"].Instance.Visible = Bool
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Listbox"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			for Index, Value in ipairs(Data.Items or { }) do
				Listbox:Add(Value)
			end
			PushFlags()
			Library.SetFlags[Data.Flag] = function(Value)
				Listbox:Set(Value)
			end
			return Listbox, Items
		end

		Components.AnimatedText = function(Data)
			local TextList = Data.Texts or Data.texts or (Data.Text and { Data.Text }) or { Data.Name or "Animated Text" }
			local CurrentIndex = 1
			local AnimationType = Data.Type or Data.type or "Typing"
			local Speed = tonumber(Data.Speed or Data.speed or 1) or 1
			local Alignment = Data.Alignment or Data.alignment or "Left"
			local AnimatedText = {
				Name = TextList[1],
				Type = AnimationType,
				Speed = Speed,
				Alignment = Alignment,
				Running = true,
				Flag = Data.Flag or Library:NextFlag()
			}
			local Items = { } do
				Items["Holder"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BorderSizePixel = 0,
					ZIndex = 2
				})
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["Holder"].Instance,
					Name = "\0",
					FontFace = Data.Font or Library.Font,
					TextColor3 = Data.Color or FromRGB(240, 244, 252),
					Text = TextList[1] or "",
					TextSize = Data.TextSize or 13,
					TextXAlignment = Enum.TextXAlignment[Alignment] or Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					AutomaticSize = Enum.AutomaticSize.Y,
					TextWrapped = true,
					RichText = true,
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 0),
					BorderSizePixel = 0,
					ZIndex = 2
				})
				if not Data.Color then
					Items["Text"]:AddToTheme({ TextColor3 = "Text" })
				end
				Items["Gradient"] = Instances:Create("UIGradient", {
					Parent = Items["Text"].Instance,
					Enabled = (AnimationType == "Gradient" or AnimationType == "Rainbow"),
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, FromRGB(59, 130, 246)),
						ColorSequenceKeypoint.new(0.5, FromRGB(240, 244, 252)),
						ColorSequenceKeypoint.new(1, FromRGB(59, 130, 246))
					})
				})
			end
			local TypingThread
			local function StartTyping()
				if TypingThread then
					pcall(task.cancel, TypingThread)
					TypingThread = nil
				end
				TypingThread = task.spawn(function()
					while AnimatedText.Running and AnimatedText.Type == "Typing" do
						local TargetPhrase = tostring(TextList[CurrentIndex] or "")
						for i = 1, #TargetPhrase do
							if not AnimatedText.Running or AnimatedText.Type ~= "Typing" then break end
							Items["Text"].Instance.Text = string.sub(TargetPhrase, 1, i) .. '<font color="#3b82f6">|</font>'
							task.wait(0.05 / math.max(0.2, AnimatedText.Speed))
						end
						for _ = 1, 4 do
							if not AnimatedText.Running or AnimatedText.Type ~= "Typing" then break end
							Items["Text"].Instance.Text = TargetPhrase .. '<font color="#3b82f6">|</font>'
							task.wait(0.25 / math.max(0.2, AnimatedText.Speed))
							Items["Text"].Instance.Text = TargetPhrase .. '<font transparency="1">|</font>'
							task.wait(0.25 / math.max(0.2, AnimatedText.Speed))
						end
						if #TextList > 1 or Data.Loop ~= false then
							for i = #TargetPhrase, 0, -1 do
								if not AnimatedText.Running or AnimatedText.Type ~= "Typing" then break end
								Items["Text"].Instance.Text = string.sub(TargetPhrase, 1, i) .. '<font color="#3b82f6">|</font>'
								task.wait(0.025 / math.max(0.2, AnimatedText.Speed))
							end
							task.wait(0.2 / math.max(0.2, AnimatedText.Speed))
							CurrentIndex = (CurrentIndex % #TextList) + 1
						else
							Items["Text"].Instance.Text = TargetPhrase
							break
						end
					end
				end)
				table.insert(Library.Threads, TypingThread)
			end
			local RenderConnection
			local GlitchChars = { "#", "$", "%", "&", "*", "@", "?", "!", "<", ">", "/", "~" }
			RenderConnection = RunService.RenderStepped:Connect(function()
				if not AnimatedText.Running or not Items["Text"].Instance or not Items["Text"].Instance.Parent then
					if RenderConnection then
						RenderConnection:Disconnect()
						RenderConnection = nil
					end
					return
				end
				local Now = tick()
				if AnimatedText.Type == "Rainbow" then
					Items["Gradient"].Instance.Enabled = false
					local Hue = (Now * 0.2 * AnimatedText.Speed) % 1
					Items["Text"].Instance.TextColor3 = Color3.fromHSV(Hue, 0.75, 1)
				elseif AnimatedText.Type == "Gradient" then
					Items["Gradient"].Instance.Enabled = true
					local Offset = (Now * 0.4 * AnimatedText.Speed) % 2 - 1
					Items["Gradient"].Instance.Offset = Vector2.new(Offset, 0)
					Items["Gradient"].Instance.Rotation = (Now * 25 * AnimatedText.Speed) % 360
				elseif AnimatedText.Type == "Pulse" then
					Items["Gradient"].Instance.Enabled = false
					local Alpha = (math.sin(Now * 3.5 * AnimatedText.Speed) + 1) / 2
					local Accent = Library.Theme.Accent or FromRGB(59, 130, 246)
					local TextCol = Library.Theme.Text or FromRGB(240, 244, 252)
					Items["Text"].Instance.TextColor3 = TextCol:Lerp(Accent, Alpha)
				elseif AnimatedText.Type == "Glitch" then
					Items["Gradient"].Instance.Enabled = false
					local Base = TextList[CurrentIndex] or ""
					local Glitched = Base
					if math.random(1, 25) == 1 then
						local Len = #Base
						if Len > 0 then
							local Pos = math.random(1, Len)
							Glitched = string.sub(Base, 1, Pos - 1) .. GlitchChars[math.random(1, #GlitchChars)] .. string.sub(Base, Pos + 1)
						end
					end
					if Items["Text"].Instance.Text ~= Glitched then
						Items["Text"].Instance.Text = Glitched
					end
				end
			end)
			table.insert(Library.Connections, { Connection = RenderConnection, Name = "AnimatedText_" .. AnimatedText.Flag })
			if AnimationType == "Typing" then
				StartTyping()
			end
			function AnimatedText:SetText(NewText)
				TextList = { tostring(NewText or "") }
				CurrentIndex = 1
				if AnimatedText.Type == "Typing" then
					StartTyping()
				else
					Items["Text"].Instance.Text = tostring(NewText or "")
				end
			end
			function AnimatedText:SetTexts(NewList)
				if type(NewList) == "table" and #NewList > 0 then
					TextList = NewList
					CurrentIndex = 1
					if AnimatedText.Type == "Typing" then
					StartTyping()
					end
				end
			end
			function AnimatedText:SetType(NewType)
				AnimatedText.Type = NewType
				if NewType == "Typing" then
					StartTyping()
				else
					if TypingThread then
						pcall(task.cancel, TypingThread)
						TypingThread = nil
					end
					Items["Text"].Instance.Text = TextList[CurrentIndex] or ""
				end
			end
			function AnimatedText:SetSpeed(NewSpeed)
				AnimatedText.Speed = tonumber(NewSpeed) or 1
			end
			function AnimatedText:Destroy()
				AnimatedText.Running = false
				if TypingThread then
					pcall(task.cancel, TypingThread)
					TypingThread = nil
				end
				if RenderConnection then
					RenderConnection:Disconnect()
					RenderConnection = nil
				end
				Items["Holder"]:Clean()
			end
			return AnimatedText, Items
		end

		Components.Group = function(Data)
			local Group = {
				Flag = Data.Flag,
				Visible = true,
				Disabled = false
			}
			local Children = { }
			local Items = { } do
				Items["Group"] = Instances:Create("Frame", {
					Parent = Data.Parent.Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, 0, 0, 0),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					AutomaticSize = Enum.AutomaticSize.Y,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UIListLayout", {
					Parent = Items["Group"].Instance,
					Name = "\0",
					Padding = UDimNew(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder
				})
			end
			function Group:SetVisible(Bool)
				self.Visible = not not Bool
				Items["Group"].Instance.Visible = self.Visible
				Library.Flags[self.Flag] = self.Visible
				if Data.Callback then
					Library:SafeCall(Data.Callback, self.Visible)
				end
				if self.OnChanged then
					Library:SafeCall(self.OnChanged, self.Visible)
				end
			end
			function Group:SetDisabled(Bool)
				self.Disabled = Bool
				Items["Group"].Instance.Active = not Bool
			end
			function Group:Add(Element, Key)
				TableInsert(Children, Key or Element)
			end
			local SearchData = {
				Name = Data.Name,
				Item = Items["Group"]
			}
			local PageSearchData = Library.SearchItems[Data.Page]
			if PageSearchData then
				TableInsert(PageSearchData, SearchData)
			end
			Library.Flags[Data.Flag] = Group.Visible
			if Data.Default ~= nil then
				Group:SetVisible(Data.Default)
			end
			return Group, Items
		end
	end
	Library.ApplyNotificationLayout()
	Library.NotificationTypes = {
		["Info"] = {
			Name = "Info",
			Color = FromRGB(96, 165, 250),
			Icon = "i"
		},
		["Success"] = {
			Name = "Success",
			Color = FromRGB(74, 222, 128),
			Icon = "\u{2713}"
		},
		["Warning"] = {
			Name = "Warning",
			Color = FromRGB(250, 204, 21),
			Icon = "!"
		},
		["Error"] = {
			Name = "Error",
			Color = FromRGB(248, 113, 113),
			Icon = "\u{2715}"
		}
	}

	Library.Notification = function(self, Text, Description, Duration, Type)
		Duration = MathMax(Duration or 3, 0.1)
		local TypeData = Library.NotificationTypes[StringLower(Type or "Info")] or Library.NotificationTypes["Info"]
		local Notification = {
			Type = TypeData.Name,
			Closed = false
		}
		local Items = { } do
			Items["Notification"] = Instances:Create("Frame", {
				Parent = Library.NotifHolder.Instance,
				Name = "Notification",
				BackgroundTransparency = 0.06,
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = FromRGB(16, 16, 16),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Size = UDim2New(1, 0, 0, 0)
			}); Items["Notification"]:AddToTheme({BackgroundColor3 = "Background"})
			Instances:Create("UICorner", {
				Parent = Items["Notification"].Instance,
				CornerRadius = UDimNew(0, 8)
			})
			Items["Stroke"] = Instances:Create("UIStroke", {
				Parent = Items["Notification"].Instance,
				Color = FromRGB(41, 37, 45),
				Thickness = 1,
				Transparency = 0.4
			}); Items["Stroke"]:AddToTheme({Color = "Border"})
			Items["AccentBar"] = Instances:Create("Frame", {
				Parent = Items["Notification"].Instance,
				BackgroundColor3 = TypeData.Color,
				AnchorPoint = Vector2New(0, 0.5),
				Position = UDim2New(0, 0, 0.5, 0),
				Size = UDim2New(0, 4, 1, 0),
				BorderSizePixel = 0,
				BackgroundTransparency = 0.25
			})
			Instances:Create("UICorner", {
				Parent = Items["AccentBar"].Instance,
				CornerRadius = UDimNew(1, 0)
			})
			Items["IconBackground"] = Instances:Create("Frame", {
				Parent = Items["Notification"].Instance,
				BackgroundColor3 = TypeData.Color,
				BorderSizePixel = 0,
				Size = UDim2New(0, 22, 0, 22),
				Position = UDim2New(0, 16, 0, 12)
			})
			Instances:Create("UICorner", {
				Parent = Items["IconBackground"].Instance,
				CornerRadius = UDimNew(1, 0)
			})
			Items["Icon"] = Instances:Create("TextLabel", {
				Parent = Items["IconBackground"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				Text = TypeData.Icon,
				TextColor3 = FromRGB(16, 16, 16),
				BorderSizePixel = 0,
				Size = UDim2New(1, 0, 1, 0),
				BackgroundTransparency = 1,
				TextSize = 14,
				TextTransparency = 0.25
			})
			Items["Content"] = Instances:Create("Frame", {
				Parent = Items["Notification"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				Size = UDim2New(1, -62, 0, 0),
				Position = UDim2New(0, 46, 0, 10),
				AutomaticSize = Enum.AutomaticSize.Y,
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Instances:Create("UIListLayout", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder
			})
			Instances:Create("UIPadding", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				PaddingBottom = UDimNew(0, 10)
			})
			Items["Title"] = Instances:Create("TextLabel", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				Text = Text,
				TextColor3 = FromRGB(199, 199, 203),
				TextSize = 16,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				BackgroundTransparency = 1,
				Size = UDim2New(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Title"]:AddToTheme({TextColor3 = "Text"})
			Items["Description"] = Instances:Create("TextLabel", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				Text = Description,
				TextColor3 = FromRGB(180, 180, 185),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				Visible = Description ~= nil and Description ~= "",
				Size = UDim2New(1, 0, 0, 0),
				LayoutOrder = 2,
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Description"]:AddToTheme({TextColor3 = "Inactive Text"})
			Items["Duration"] = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				BorderSizePixel = 0,
				Size = UDim2New(1, 0, 0, 3),
				LayoutOrder = 3,
				ZIndex = 2,
				BackgroundColor3 = FromRGB(44, 38, 44)
			}); Items["Duration"]:AddToTheme({BackgroundColor3 = "Inline"})
			Items["Accent"] = Instances:Create("Frame", {
				Parent = Items["Duration"].Instance,
				BackgroundColor3 = TypeData.Color,
				BorderSizePixel = 0,
				Size = UDim2New(1, 0, 1, 0)
			})
			Instances:Create("UICorner", {
				Parent = Items["Accent"].Instance
			})
			Instances:Create("UIPadding", {
				Parent = Items["Notification"].Instance,
				Name = "\0",
				PaddingBottom = UDimNew(0, 10)
			})
		end
		Items["Accent"]:Tween(
			Tween:Info(Duration),
			{Size = UDim2New(0, 0, 1, 0)}
		)

		function Notification:Close()
			if self.Closed then
				return
			end
			self.Closed = true
			Tween:Create(Items["Notification"].Instance, Tween:Info(0.25), {BackgroundTransparency = 1}, true)
			for _, Child in ipairs(Items["Notification"].Instance:GetDescendants()) do
				if Child:IsA("TextLabel") or Child:IsA("TextBox") then
					Tween:Create(Child, Tween:Info(0.2), { TextTransparency = 1 }, true)
				elseif Child:IsA("ImageLabel") or Child:IsA("ImageButton") then
					Tween:Create(Child, Tween:Info(0.2), { ImageTransparency = 1 }, true)
				elseif Child:IsA("Frame") then
					Tween:Create(Child, Tween:Info(0.2), { BackgroundTransparency = 1 }, true)
				elseif Child:IsA("UIStroke") then
					Tween:Create(Child, Tween:Info(0.2), { Transparency = 1 }, true)
				end
			end
			task.wait(0.25)
			Items["Notification"]:Clean()
		end

		function Notification:SetText(NewText)
			Items["Title"].Instance.Text = tostring(NewText or "")
		end

		function Notification:SetDescription(NewDescription)
			Items["Description"].Instance.Text = tostring(NewDescription or "")
			Items["Description"].Instance.Visible = NewDescription ~= nil and NewDescription ~= ""
		end
		Library:Connect(Items["Notification"].Instance.InputBegan, function(Input)
			if Input.UserInputType == InputTypeMouseButton1
			or Input.UserInputType == InputTypeTouch then
				Notification:Close()
			end
		end)
		do
			local MaxStacked = Library.Settings and Library.Settings.MaxNotifications or 6
			local Children = Library.NotifHolder.Instance:GetChildren()
			if #Children > MaxStacked then
				for Index = 1, (#Children - MaxStacked) do
					local Oldest = Children[Index]
					if Oldest ~= Items["Notification"].Instance then
						Oldest:Destroy()
					end
				end
			end
		end
		task.delay(Duration, function()
			Notification:Close()
		end)
		return Notification
	end

	Library.Success = function(self, Text, Description, Duration)
		return self:Notification(Text, Description, Duration, "Success")
	end

	Library.Warning = function(self, Text, Description, Duration)
		return self:Notification(Text, Description, Duration, "Warning")
	end

	Library.Error = function(self, Text, Description, Duration)
		return self:Notification(Text, Description, Duration, "Error")
	end

	Library.Info = function(self, Text, Description, Duration)
		return self:Notification(Text, Description, Duration, "Info")
	end

	Library.CenterSpinner = function(self, Properties)
		Properties = Properties or { }
		if self.ActiveCenterSpinner then
			return self.ActiveCenterSpinner
		end
		local SpinnerType   = Properties.Type  or "Builtin"
		local Asset         = Properties.Asset or ""
		local Speed         = Properties.Speed or Library.Settings.CenterSpinnerSpeed or 1.2
		local Size          = Properties.Size  or Library.Settings.CenterSpinnerSize  or 300
		local Tilt          = Properties.Tilt  or 18
		local Opacity       = Properties.Opacity or 1.0
		local Transparency  = 1 - Opacity
		local Layer         = Properties.Layer or Library.Settings.CenterSpinnerLayer or "Behind UI"
		local PositionMode  = Properties.PositionMode or Library.Settings.CenterSpinnerPosition or "Screen Center"
		local Floating      = (Properties.Floating == nil) and true or (Properties.Floating ~= false)
		local ModelColor
		if Properties.Color then
			ModelColor = Properties.Color
		else
			ModelColor = FromRGB(245, 245, 255)
		end
		local BuiltinMesh = "Robloxui/logo_v3.mesh"
		for _, mp in ipairs({
			"Robloxui/logo_v3.mesh",
			"Robloxui/logo_v2.mesh",
			"Robloxui/logo_tri.mesh",
			JoinPath(Library.Folders.Directory, "logo_v3.mesh"),
			JoinPath(Library.Folders.Directory, "logo_v2.mesh"),
			JoinPath(Library.Folders.Directory, "logo_tri.mesh"),
			"logo_v3.mesh",
			"logo_v2.mesh",
			"logo_tri.mesh",
		}) do
			if FS.IsFile(mp) then
				BuiltinMesh = mp
				break
			end
		end
		local CenterSpinner = {
			Visible      = Properties.Visible ~= false,
			Type         = SpinnerType,
			Asset        = Asset,
			Size         = Size,
			Speed        = Speed,
			Tilt         = Tilt,
			Layer        = Layer,
			PositionMode = PositionMode,
			Transparency = Transparency,
			Color        = ModelColor,
			Floating     = Floating,
		}
		self.ActiveCenterSpinner = CenterSpinner
		local Items = { } do
			local TargetZ = (Layer == "Above UI" and 2000 or 10)
			local SpinnerGui = Instance.new("ScreenGui")
			SpinnerGui.Name            = "EnterSkin_CenterSpinner"
			SpinnerGui.ResetOnSpawn    = false
			SpinnerGui.IgnoreGuiInset  = true
			SpinnerGui.DisplayOrder    = TargetZ
			SpinnerGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
			SpinnerGui.Enabled         = false
			SpinnerGui.Parent          = gethui and gethui() or game:GetService("CoreGui")
			Items["SpinnerGui"] = SpinnerGui
			local Holder = Instance.new("Frame")
			Holder.Name                = "Holder"
			Holder.AnchorPoint         = Vector2New(0.5, 0.5)
			Holder.Position            = UDim2New(0.5, 0, 0.5, 0)
			Holder.Size                = UDim2New(0, Size, 0, Size)
			Holder.BackgroundTransparency = 1
			Holder.ZIndex              = TargetZ
			Holder.Parent              = SpinnerGui
			Items["Holder"] = { Instance = Holder }
			if SpinnerType == "Image" then
				local Img = Instance.new("ImageLabel")
				Img.Name               = "SpinnerImage"
				Img.Size               = UDim2New(1, 0, 1, 0)
				Img.Position           = UDim2New(0, 0, 0, 0)
				Img.AnchorPoint        = Vector2New(0.5, 0.5)
				Img.BackgroundTransparency = 1
				Img.ImageTransparency  = Transparency
				Img.ZIndex             = TargetZ + 1
				Img.ScaleType          = Enum.ScaleType.Fit
				local raw = tostring(Asset or "")
				if raw:match("^%d+$") then
					Img.Image = "rbxassetid://" .. raw
				elseif raw ~= "" then
					Img.Image = raw
				else
					Img.Image = "rbxassetid://6031280882"
				end
				Img.Parent = Holder
				Items["Image"] = Img
			else
				local VPF = Instance.new("ViewportFrame")
				VPF.Name               = "ModelViewport"
				VPF.Size               = UDim2New(1, 0, 1, 0)
				VPF.Position           = UDim2New(0, 0, 0, 0)
				VPF.BackgroundTransparency = 1
				VPF.LightColor         = FromRGB(255, 255, 255)
				VPF.LightDirection     = Vector3.new(-0.8, -1.8, -1.2)
				VPF.Ambient            = FromRGB(120, 120, 140)
				VPF.ZIndex             = TargetZ + 1
				VPF.Parent             = Holder
				Items["Viewport"] = VPF
				local Cam = Instance.new("Camera")
				Cam.CameraType  = Enum.CameraType.Scriptable
				Cam.FieldOfView = 55
				Cam.CFrame      = CFrame.new(Vector3.new(0, 0.2, 5.2), Vector3.new(0, 0.2, 0))
				Cam.Parent      = VPF
				VPF.CurrentCamera = Cam
				Items["Camera"] = Cam
				local Part = Instance.new("Part")
				Part.Name         = "CenterModelPart"
				Part.Size         = Vector3.new(2, 2, 2)
				Part.Color        = ModelColor
				Part.Material     = Enum.Material.SmoothPlastic
				Part.Anchored     = true
				Part.CanCollide   = false
				Part.CastShadow   = false
				Part.CFrame       = CFrame.new(0, 0, 0)
				Part.Transparency = Transparency
				Part.Parent       = VPF
				Items["Part"] = Part
				local Mesh = Instance.new("SpecialMesh")
				Mesh.MeshType = Enum.MeshType.FileMesh
				Mesh.Scale    = Vector3.new(1.9, 1.9, 1.9)
				Mesh.Parent   = Part
				Items["SpecialMesh"] = Mesh
				local function ResolveMesh(raw)
					raw = tostring(raw or "")
					local paths = { raw, "Robloxui/" .. raw, JoinPath(Library.Folders.Directory, raw), JoinPath(Library.Folders.Assets, raw) }
					for _, p in ipairs(paths) do
						if p ~= "" and FS.IsFile(p) then
							return FS.CustomAsset(p)
						end
					end
					if raw:match("^%d+$") then return "rbxassetid://" .. raw end
					if raw:match("^rbxasset") or raw:match("^rbxcustomasset") then return raw end
					return ""
				end
				local meshSrc = (SpinnerType == "Mesh" and Asset ~= "") and Asset or BuiltinMesh
				Mesh.MeshId = ResolveMesh(meshSrc)
			end
		end

		local function SetTransparency(t)
			if Items["Part"]  then Items["Part"].Transparency  = t end
			if Items["Image"] then Items["Image"].ImageTransparency = t end
		end

		local function SetColor(col)
			if Items["Part"] then Items["Part"].Color = col end
		end

		local function Reattach()
			if not Items["SpinnerGui"] then return end
			if Items["SpinnerGui"].Parent then return end
			-- gethui() can hand back a container that later gets cleared (and returns nil on
			-- some executors). Re-parent instead of leaving the spinner permanently dead.
			local Target = nil
			pcall(function()
				Target = gethui and gethui() or nil
			end)
			if not Target then
				pcall(function()
					Target = game:GetService("CoreGui")
				end)
			end
			if Target then
				pcall(function()
					Items["SpinnerGui"].Parent = Target
				end)
			end
		end

		local function UpdateState(IsOpen)
			Reattach()
			if not Items["SpinnerGui"] or not Items["SpinnerGui"].Parent then return end
			if IsOpen and CenterSpinner.Visible then
				Items["SpinnerGui"].Enabled = true
				SetTransparency(CenterSpinner.Transparency)
			else
				Items["SpinnerGui"].Enabled = false
			end
		end

		self.UpdateCenterSpinner = function(_, IsOpen)
			UpdateState(IsOpen)
		end

		self.ReattachCenterSpinner = function()
			Reattach()
			return (Items["SpinnerGui"] and Items["SpinnerGui"].Parent) ~= nil
		end
		local CurrentAngle = 0
		local RenderSteppedRetry = 0
		local RenderConnection
		RenderConnection = RunService.RenderStepped:Connect(function(Delta)
			if not Items["SpinnerGui"] then
				if RenderConnection then
					RenderConnection:Disconnect()
					RenderConnection = nil
				end
				return
			end
			if not Items["SpinnerGui"].Parent then
				-- Parent went missing: try to recover instead of disconnecting forever.
				RenderSteppedRetry += 1
				if RenderSteppedRetry % 30 == 0 then
					Reattach()
					if Items["SpinnerGui"].Parent then
						RenderSteppedRetry = 0
					end
				end
				return
			end
			if not Items["SpinnerGui"].Enabled then return end
			local holder = Items["Holder"]
			if not holder then return end
			local Now = tick()
			Delta = Delta or 0.016
			if CenterSpinner.PositionMode == "Window Center" then
				local win = Library.FocusedWindow or (Library.Windows and Library.Windows[1])
				if win and win.Items and win.Items["MainFrame"] then
					local mf = win.Items["MainFrame"].Instance or win.Items["MainFrame"]
					if mf and mf.AbsolutePosition then
						local cp = mf.AbsolutePosition + (mf.AbsoluteSize / 2)
						holder.Position = UDim2New(0, cp.X, 0, cp.Y)
					else
						holder.Position = UDim2New(0.5, 0, 0.5, 0)
					end
				else
					holder.Position = UDim2New(0.5, 0, 0.5, 0)
				end
			else
				holder.Position = UDim2New(0.5, 0, 0.5, 0)
			end
			if CenterSpinner.Floating then
				local Bob = math.sin(Now * 1.8) * 3
				holder.Position = holder.Position + UDim2New(0, 0, 0, Bob)
			end
			CurrentAngle = (CurrentAngle + Delta * CenterSpinner.Speed * 48) % 360
			if Items["Part"] then
				Items["Part"].CFrame = CFrame.Angles(
					math.rad(CenterSpinner.Tilt or 18),
					math.rad(CurrentAngle),
					0
				)
			elseif Items["Image"] then
				holder.Rotation = CurrentAngle * 0.6
			end
		end)
		table.insert(self.Connections, { Connection = RenderConnection, Name = "CenterSpinnerRender" })

		function CenterSpinner:SetVisible(Bool)
			CenterSpinner.Visible = not not Bool
			local IsOpen = false
			if Library.FocusedWindow and Library.FocusedWindow.IsOpen then IsOpen = true
			elseif Library.Windows and Library.Windows[1] and Library.Windows[1].IsOpen then IsOpen = true end
			UpdateState(IsOpen)
		end

		function CenterSpinner:SetMesh(Value)
			CenterSpinner.Asset = Value
			if Items["SpecialMesh"] then
				local function Resolve(raw)
					raw = tostring(raw or "")
					local paths = { raw, "Robloxui/" .. raw, JoinPath(Library.Folders.Directory, raw) }
					for _, p in ipairs(paths) do
						if p ~= "" and FS.IsFile(p) then
							return FS.CustomAsset(p)
						end
					end
					if raw:match("^%d+$") then return "rbxassetid://" .. raw end
					if raw:match("^rbxasset") or raw:match("^rbxcustomasset") then return raw end
					return ""
				end
				Items["SpecialMesh"].MeshId = Resolve(Value)
			end
			if Items["Image"] and Value ~= "" then
				local raw = tostring(Value)
				Items["Image"].Image = raw:match("^%d+$") and ("rbxassetid://" .. raw) or raw
			end
		end

		function CenterSpinner:SetSpeed(Speed)
			CenterSpinner.Speed = tonumber(Speed) or 1.2
		end

		function CenterSpinner:SetSize(Size)
			CenterSpinner.Size = tonumber(Size) or 300
			Items["Holder"].Instance.Size = UDim2New(0, CenterSpinner.Size, 0, CenterSpinner.Size)
			if Items["SpecialMesh"] then
				local S = CenterSpinner.Size / 158
				Items["SpecialMesh"].Scale = Vector3.new(S, S, S)
			end
		end

		function CenterSpinner:SetTilt(Tilt)
			CenterSpinner.Tilt = tonumber(Tilt) or 18
		end

		function CenterSpinner:SetColor(Color)
			CenterSpinner.Color = Color
			SetColor(Color)
		end

		function CenterSpinner:SetLayer(Layer)
			CenterSpinner.Layer = Layer
			local TargetZ = (Layer == "Behind UI" and 1 or 2000)
			Items["SpinnerGui"].DisplayOrder = TargetZ
			Items["Holder"].Instance.ZIndex  = TargetZ
			if Items["Viewport"] then Items["Viewport"].ZIndex = TargetZ + 1 end
		end

		function CenterSpinner:SetPositionMode(Mode)
			CenterSpinner.PositionMode = Mode
		end

		function CenterSpinner:SetTransparency(Num)
			CenterSpinner.Transparency = tonumber(Num) or 0
			if Items["SpinnerGui"].Enabled then SetTransparency(CenterSpinner.Transparency) end
		end
		local anyOpen = false
		if self.FocusedWindow and self.FocusedWindow.IsOpen then anyOpen = true
		elseif self.Windows and self.Windows[1] and self.Windows[1].IsOpen then anyOpen = true end
		if anyOpen then UpdateState(true) end
		return CenterSpinner, Items
	end

	Library.KeybindList = function(self)
		local KeybindList = { Visible = true }
		self.KeyList = KeybindList
		self.ActiveKeybindList = KeybindList
		local Items = { } do
			Items["KeybindList"] = Instances:Create("Frame", {
				Parent = Library.Holder.Instance,
				Name = "EnterSkin_KeybindList",
				BackgroundTransparency = 0.15,
				Position = UDim2New(0, 16, 0.72, 0),
				BorderColor3 = FromRGB(0, 0, 0),
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = FromRGB(30, 33, 41),
				ZIndex = 40
			}); Items["KeybindList"]:AddToTheme({BackgroundColor3 = "Inline"})
			Items["KeybindList"]:MakeDraggable()
			Instances:Create("UICorner", {
				Parent = Items["KeybindList"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 8)
			})
			Items["Stroke"] = Instances:Create("UIStroke", {
				Parent = Items["KeybindList"].Instance,
				Name = "\0",
				Color = FromRGB(66, 73, 88),
				Thickness = 1,
				Transparency = 0.35
			}); Items["Stroke"]:AddToTheme({Color = "Border"})
			Items["TopAccent"] = Instances:Create("Frame", {
				Parent = Items["KeybindList"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 2),
				Position = UDim2New(0, 0, 0, 0),
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(59, 130, 246),
				ZIndex = 41
			}); Items["TopAccent"]:AddToTheme({BackgroundColor3 = "Accent"})
			Instances:Create("UICorner", {
				Parent = Items["TopAccent"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 8)
			})
			Items["Wrapper"] = Instances:Create("Frame", {
				Parent = Items["KeybindList"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				Size = UDim2New(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BorderSizePixel = 0,
				ZIndex = 42
			})
			Instances:Create("UIPadding", {
				Parent = Items["Wrapper"].Instance,
				Name = "\0",
				PaddingTop = UDimNew(0, 8),
				PaddingBottom = UDimNew(0, 8),
				PaddingRight = UDimNew(0, 10),
				PaddingLeft = UDimNew(0, 10)
			})
			Instances:Create("UIListLayout", {
				Parent = Items["Wrapper"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder
			})
			Items["Header"] = Instances:Create("Frame", {
				Parent = Items["Wrapper"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				Size = UDim2New(0, 0, 0, 16),
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = 1,
				ZIndex = 42,
				BorderSizePixel = 0
			})
			Instances:Create("UIListLayout", {
				Parent = Items["Header"].Instance,
				Name = "\0",
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDimNew(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder
			})
			Items["Dot"] = Instances:Create("Frame", {
				Parent = Items["Header"].Instance,
				Name = "\0",
				Size = UDim2New(0, 6, 0, 6),
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(59, 130, 246),
				LayoutOrder = 1,
				ZIndex = 43
			}); Items["Dot"]:AddToTheme({BackgroundColor3 = "Accent"})
			Instances:Create("UICorner", {
				Parent = Items["Dot"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(1, 0)
			})
			Items["Title"] = Instances:Create("TextLabel", {
				Parent = Items["Header"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(240, 244, 252),
				Text = "Keybinds",
				BackgroundTransparency = 1,
				Size = UDim2New(0, 0, 1, 0),
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.X,
				TextSize = 13,
				LayoutOrder = 2,
				ZIndex = 43,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Title"]:AddToTheme({TextColor3 = "Text"})
			Items["Content"] = Instances:Create("Frame", {
				Parent = Items["Wrapper"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2New(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 2,
				ZIndex = 42
			})
			Instances:Create("UIListLayout", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder
			})
		end

		function KeybindList:Add(Key, Name, Mode)
			Key = tostring(Key or "")
			Name = tostring(Name or "")
			Mode = tostring(Mode or "")
			local RowFrame = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				Size = UDim2New(0, 0, 0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				BorderSizePixel = 0,
				Visible = Key ~= "" and Key ~= "None",
				ZIndex = 43
			})
			Instances:Create("UIListLayout", {
				Parent = RowFrame.Instance,
				Name = "\0",
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDimNew(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder
			})
			local KeyBadge = Instances:Create("Frame", {
				Parent = RowFrame.Instance,
				Name = "\0",
				BackgroundColor3 = FromRGB(40, 44, 54),
				BorderSizePixel = 0,
				Size = UDim2New(0, 0, 0, 16),
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = 1,
				ZIndex = 44
			}); KeyBadge:AddToTheme({BackgroundColor3 = "Element"})
			Instances:Create("UICorner", {
				Parent = KeyBadge.Instance,
				CornerRadius = UDimNew(0, 4)
			})
			Instances:Create("UIPadding", {
				Parent = KeyBadge.Instance,
				PaddingLeft = UDimNew(0, 5),
				PaddingRight = UDimNew(0, 5)
			})
			local KeyLabel = Instances:Create("TextLabel", {
				Parent = KeyBadge.Instance,
				FontFace = Library.Font,
				TextColor3 = FromRGB(59, 130, 246),
				Text = Key ~= "" and Key or "None",
				BackgroundTransparency = 1,
				Size = UDim2New(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				TextSize = 11,
				ZIndex = 45
			}); KeyLabel:AddToTheme({TextColor3 = "Accent"})
			local NameLabel = Instances:Create("TextLabel", {
				Parent = RowFrame.Instance,
				FontFace = Library.Font,
				TextColor3 = FromRGB(240, 244, 252),
				Text = Name,
				BackgroundTransparency = 1,
				Size = UDim2New(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				TextSize = 12,
				LayoutOrder = 2,
				ZIndex = 44
			}); NameLabel:AddToTheme({TextColor3 = "Text"})
			local ModeLabel = Instances:Create("TextLabel", {
				Parent = RowFrame.Instance,
				FontFace = Library.Font,
				TextColor3 = FromRGB(158, 168, 186),
				Text = Mode ~= "" and ("[" .. Mode .. "]") or "",
				BackgroundTransparency = 1,
				Size = UDim2New(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				TextSize = 11,
				LayoutOrder = 3,
				ZIndex = 44
			}); ModeLabel:AddToTheme({TextColor3 = "Inactive Text"})
			local Entry = {
				Row = RowFrame,
				Key = KeyLabel,
				Name = NameLabel,
				Mode = ModeLabel,
				Badge = KeyBadge,
				Instance = RowFrame.Instance
			}
			function Entry:Set(NewKey, NewName, NewMode)
				NewKey = tostring(NewKey or "")
				NewName = tostring(NewName or "")
				NewMode = tostring(NewMode or "")
				KeyLabel.Instance.Text = NewKey ~= "" and NewKey or "None"
				NameLabel.Instance.Text = NewName
				ModeLabel.Instance.Text = NewMode ~= "" and ("[" .. NewMode .. "]") or ""
				RowFrame.Instance.Visible = NewKey ~= "" and NewKey ~= "None"
			end
			function Entry:SetStatus(Bool)
				if Bool then
					NameLabel:Tween(nil, {TextColor3 = Library.Theme.Accent})
					KeyBadge:Tween(nil, {BackgroundColor3 = Library.Theme.Inline})
				else
					NameLabel:Tween(nil, {TextColor3 = Library.Theme.Text})
					KeyBadge:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
				end
			end
			return Entry
		end

		function KeybindList:SetVisible(Bool)
			KeybindList.Visible = not not Bool
			Items["KeybindList"].Instance.Visible = KeybindList.Visible
		end
		return KeybindList
	end

	Library.Watermark = function(self, Name, Properties)
		Properties = Properties or { }
		local ShowServer = Properties.ShowServer
		if ShowServer == nil then ShowServer = true end
		local ShowUser = Properties.ShowUser
		if ShowUser == nil then ShowUser = true end
		local ShowGame = Properties.ShowGame
		if ShowGame == nil then ShowGame = true end
		local ShowStats = Properties.ShowStats
		if ShowStats == nil then ShowStats = true end
		local ShowDividers = Properties.ShowDividers
		if ShowDividers == nil then ShowDividers = true end
		local ShowTime = Properties.ShowTime
		if ShowTime == nil then ShowTime = true end
		local PositionName = Properties.Position or "TopLeft"
		local Anchor = Vector2New(0, 0)
		local InitialPos = UDim2New(0, 16, 0, 12 + Library.GuiInset)
		if PositionName == "TopCenter" then
			Anchor = Vector2New(0.5, 0)
			InitialPos = UDim2New(0.5, 0, 0, 12 + Library.GuiInset)
		elseif PositionName == "TopRight" then
			Anchor = Vector2New(1, 0)
			InitialPos = UDim2New(1, -16, 0, 12 + Library.GuiInset)
		elseif PositionName == "BottomLeft" then
			Anchor = Vector2New(0, 1)
			InitialPos = UDim2New(0, 16, 1, -16)
		elseif PositionName == "BottomRight" then
			Anchor = Vector2New(1, 1)
			InitialPos = UDim2New(1, -16, 1, -16)
		elseif typeof(Properties.Position) == "UDim2" then
			InitialPos = Properties.Position
		end
		local _Player = Players.LocalPlayer
		local Watermark = {
			Name = Name or "EnterSkin",
			ShowServer = ShowServer,
			ShowUser = ShowUser,
			ShowGame = ShowGame,
			ShowStats = ShowStats,
			ShowDividers = ShowDividers,
			ShowTime = ShowTime,
			Position = PositionName,
			Visible = true
		}
		self.ActiveWatermark = Watermark
		local Items = { } do
			Items["Watermark"] = Instances:Create("Frame", {
				Parent = Library.Holder.Instance,
				Name = "EnterSkin_Watermark",
				BorderColor3 = FromRGB(0, 0, 0),
				AnchorPoint = Anchor,
				Position = InitialPos,
				Size = UDim2New(0, 0, 0, 28),
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 0.12,
				BackgroundColor3 = FromRGB(30, 33, 41),
				ZIndex = 50
			}); Items["Watermark"]:AddToTheme({BackgroundColor3 = "Inline"})
			Items["Watermark"]:MakeDraggable()
			Instances:Create("UICorner", {
				Parent = Items["Watermark"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 8)
			})
			Items["Stroke"] = Instances:Create("UIStroke", {
				Parent = Items["Watermark"].Instance,
				Name = "\0",
				Color = FromRGB(66, 73, 88),
				Thickness = 1,
				Transparency = 0.35
			}); Items["Stroke"]:AddToTheme({Color = "Border"})
			Instances:Create("UIPadding", {
				Parent = Items["Watermark"].Instance,
				Name = "\0",
				PaddingTop = UDimNew(0, 5),
				PaddingBottom = UDimNew(0, 5),
				PaddingLeft = UDimNew(0, 8),
				PaddingRight = UDimNew(0, 10)
			})
			Items["Content"] = Instances:Create("Frame", {
				Parent = Items["Watermark"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				Size = UDim2New(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				ZIndex = 51,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Items["ListLayout"] = Instances:Create("UIListLayout", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center
			})
			Items["Accent"] = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(0, 3, 0, 12),
				LayoutOrder = 1,
				ZIndex = 52,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(59, 130, 246)
			}); Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
			Instances:Create("UICorner", {
				Parent = Items["Accent"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(1, 0)
			})
		end
		local _ServerId = game.JobId
		local GameName = tostring(game.Name or "")
		if GameName == "" then
			GameName = "Place " .. tostring(game.PlaceId)
		end

		local function ShortId(Job)
			if type(Job) ~= "string" or Job == "" then
				return "local"
			end
			return #Job > 8 and Job:sub(1, 8) or Job
		end

		local function Truncate(Text, Max)
			Text = tostring(Text or "?")
			if #Text > Max then
				return Text:sub(1, Max - 1) .. "\u{2026}"
			end
			return Text
		end
		local Rendered = { }
		local Dividers = { }
		local OrderCounter = 2

		local function CreateDivider()
			local Div = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Size = UDim2New(0, 1, 0, 12),
				BorderSizePixel = 0,
				BackgroundTransparency = 0.55,
				LayoutOrder = OrderCounter,
				ZIndex = 52,
				Visible = ShowDividers,
				BackgroundColor3 = FromRGB(66, 73, 88)
			}); Div:AddToTheme({BackgroundColor3 = "Border"})
			Dividers[#Dividers + 1] = Div
			OrderCounter += 1
			return Div
		end
		do
			local NameLabel = Instances:Create("TextLabel", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(240, 244, 252),
				Text = tostring(Watermark.Name),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				ZIndex = 52,
				TextSize = 13,
				LayoutOrder = OrderCounter,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); NameLabel:AddToTheme({TextColor3 = "Text"})
			Rendered["Name"] = { Frame = NameLabel, Text = NameLabel }
			OrderCounter += 1
		end

		local function CreateSection(Key, Text, ColorKey, Visible)
			local Div = CreateDivider()
			local Label = Instances:Create("TextLabel", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = ColorKey == "Text" and FromRGB(240, 244, 252) or FromRGB(158, 168, 186),
				Text = Text,
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				ZIndex = 52,
				TextSize = 12,
				Visible = Visible,
				LayoutOrder = OrderCounter,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Label:AddToTheme({TextColor3 = ColorKey or "Inactive Text"})
			Rendered[Key] = { Frame = Label, Text = Label, Divider = Div }
			OrderCounter += 1
			return Label
		end
		CreateSection("Username", Truncate(Player and Player.Name or "User", 18), "Text", ShowUser)
		CreateSection("Game", Truncate(GameName, 22), "Inactive Text", ShowGame)
		CreateSection("Server", "srv: " .. ShortId(ServerId), "Inactive Text", ShowServer)
		do
			local Div = CreateDivider()
			local StatsFrame = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2New(0, 0, 0, 0),
				Visible = ShowStats,
				LayoutOrder = OrderCounter,
				ZIndex = 52,
				BorderSizePixel = 0
			})
			Instances:Create("UIListLayout", {
				Parent = StatsFrame.Instance,
				Padding = UDimNew(0, 5),
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder
			})
			local FpsLabel = Instances:Create("TextLabel", {
				Parent = StatsFrame.Instance,
				FontFace = Library.Font,
				TextColor3 = FromRGB(110, 231, 183),
				Text = "60 fps",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				TextSize = 12,
				LayoutOrder = 1,
				ZIndex = 52
			})
			local DotLabel = Instances:Create("TextLabel", {
				Parent = StatsFrame.Instance,
				FontFace = Library.Font,
				TextColor3 = FromRGB(158, 168, 186),
				Text = "\u{00B7}",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				TextSize = 12,
				LayoutOrder = 2,
				ZIndex = 52
			}); DotLabel:AddToTheme({TextColor3 = "Inactive Text"})
			local PingLabel = Instances:Create("TextLabel", {
				Parent = StatsFrame.Instance,
				FontFace = Library.Font,
				TextColor3 = FromRGB(110, 231, 183),
				Text = "0 ms",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				TextSize = 12,
				LayoutOrder = 3,
				ZIndex = 52
			})
			Rendered["Stats"] = {
				Frame = StatsFrame,
				Fps = FpsLabel,
				Ping = PingLabel,
				Divider = Div
			}
			OrderCounter += 1
		end
		CreateSection("Time", os.date("%X"), "Inactive Text", ShowTime)

		local function UpdateDividers()
			for _, Div in ipairs(Dividers) do
				Div.Instance.Visible = false
			end
			if not Watermark.ShowDividers then
				return
			end
			local Keys = { "Username", "Game", "Server", "Stats", "Time" }
			for _, Key in ipairs(Keys) do
				local Entry = Rendered[Key]
				if Entry and Entry.Frame.Instance.Visible and Entry.Divider then
					Entry.Divider.Instance.Visible = true
				end
			end
		end
		UpdateDividers()
		local Frametimer = tick()
		local FramesPerSecond = 60
		Library:AddFrameJob("Watermark", function()
			local Now = Tick()
			if Now - Frametimer < 0.5 then
				return
			end
			local Count = Library.FrameCount or 0
			Library.FrameCount = 0
			FramesPerSecond = MathFloor(Count / (Now - Frametimer))
			Frametimer = Now
			Library.FPS = FramesPerSecond
			if Watermark.ShowStats and Rendered["Stats"] then
				local Ping = 0
				pcall(function()
					Ping = MathFloor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				end)
				local FpsColor = FramesPerSecond >= 50 and FromRGB(110, 231, 183) or (FramesPerSecond >= 30 and FromRGB(251, 191, 36) or FromRGB(248, 113, 113))
				local PingColor = Ping <= 60 and FromRGB(110, 231, 183) or (Ping <= 120 and FromRGB(251, 191, 36) or FromRGB(248, 113, 113))
				Rendered["Stats"].Fps.Instance.Text = StringFormat("%s fps", tostring(FramesPerSecond))
				Rendered["Stats"].Fps.Instance.TextColor3 = FpsColor
				Rendered["Stats"].Ping.Instance.Text = StringFormat("%s ms", tostring(Ping))
				Rendered["Stats"].Ping.Instance.TextColor3 = PingColor
			end
			if Watermark.ShowTime and Rendered["Time"] then
				Rendered["Time"].Text.Instance.Text = os.date("%X")
			end
		end)

		function Watermark:SetVisible(Bool)
			Watermark.Visible = not not Bool
			Items["Watermark"].Instance.Visible = Watermark.Visible
		end

		function Watermark:SetName(NewName)
			Watermark.Name = tostring(NewName or "")
			if Rendered["Name"] then
				Rendered["Name"].Text.Instance.Text = Watermark.Name
			end
		end

		function Watermark:SetOption(Option, Value)
			Value = Value and true or false
			Watermark[Option] = Value
			if Option == "ShowDividers" then
				UpdateDividers()
				return Watermark
			end
			local FunctionKeys = {
				ShowServer = "Server",
				ShowUser = "Username",
				ShowGame = "Game",
				ShowStats = "Stats",
				ShowTime = "Time"
			}
			local Key = FunctionKeys[Option]
			if Key and Rendered[Key] then
				Rendered[Key].Frame.Instance.Visible = Value
				UpdateDividers()
			end
			return Watermark
		end

		function Watermark:SetPosition(NewPosition)
			Watermark.Position = NewPosition
			local TopOffset = 12 + Library.GuiInset
			if NewPosition == "TopLeft" then
				Items["Watermark"].Instance.AnchorPoint = Vector2New(0, 0)
				Items["Watermark"]:Tween(Tween:Info(0.2), {Position = UDim2New(0, 16, 0, TopOffset)})
			elseif NewPosition == "TopCenter" then
				Items["Watermark"].Instance.AnchorPoint = Vector2New(0.5, 0)
				Items["Watermark"]:Tween(Tween:Info(0.2), {Position = UDim2New(0.5, 0, 0, TopOffset)})
			elseif NewPosition == "TopRight" then
				Items["Watermark"].Instance.AnchorPoint = Vector2New(1, 0)
				Items["Watermark"]:Tween(Tween:Info(0.2), {Position = UDim2New(1, -16, 0, TopOffset)})
			elseif NewPosition == "BottomLeft" then
				Items["Watermark"].Instance.AnchorPoint = Vector2New(0, 1)
				Items["Watermark"]:Tween(Tween:Info(0.2), {Position = UDim2New(0, 16, 1, -16)})
			elseif NewPosition == "BottomRight" then
				Items["Watermark"].Instance.AnchorPoint = Vector2New(1, 1)
				Items["Watermark"]:Tween(Tween:Info(0.2), {Position = UDim2New(1, -16, 1, -16)})
			elseif typeof(NewPosition) == "UDim2" then
				Items["Watermark"]:Tween(Tween:Info(0.2), {Position = NewPosition})
			end
		end

		function Watermark:GetOptions()
			return { "ShowServer", "ShowUser", "ShowGame", "ShowStats", "ShowTime", "ShowDividers" }
		end
		return Watermark
	end
	Library.MobilePositions = {
		["TopLeft"] = {X = 0, Y = 0},
		["TopRight"] = {X = 1, Y = 0},
		["MiddleLeft"] = {X = 0, Y = 0.35},
		["Center"] = {X = 0.5, Y = 0.5},
		["MiddleRight"] = {X = 1, Y = 0.5},
		["BottomLeft"] = {X = 0, Y = 1},
		["BottomRight"] = {X = 1, Y = 1}
	}

	Library.MobileButton = function(self, Properties)
		Properties = Properties or { }
		local PositionName = Properties.Position or Properties.position or "MiddleLeft"
		local Anchor = Library.MobilePositions[PositionName] or Library.MobilePositions["MiddleLeft"]
		local Target = Properties.Window or Properties.window or Library.FocusedWindow
		local Width = Properties.Width or Properties.width or 118
		local Height = Properties.Height or Properties.height or 78
		local OffsetX = Properties.OffsetX or Properties.offsetx or 14
		local OffsetY = Properties.OffsetY or Properties.offsety or 0
		local SnapToEdge = Properties.SnapToEdge
		if SnapToEdge == nil then SnapToEdge = true end
		local MobileButton = {
			Target = Target,
			Position = PositionName,
			Locked = Properties.Locked or Properties.locked or false,
			Visible = Properties.Visible ~= false,
			OffsetX = OffsetX,
			OffsetY = OffsetY,
			Width = Width,
			Height = Height,
			SnapToEdge = SnapToEdge,
			Notify = Properties.Notify ~= false
		}
		self.ActiveMobileButton = MobileButton
		local Items = { } do
			local InitialX = Anchor.X == 0 and OffsetX or (Anchor.X == 1 and -OffsetX or 0)
			local InitialY = OffsetY + (Anchor.Y == 0 and Library.GuiInset + 10 or (Anchor.Y == 1 and -10 or 0))
			Items["Holder"] = Instances:Create("Frame", {
				Parent = Library.Holder.Instance,
				Name = "EnterSkin_MobileButton",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2New(Anchor.X, Anchor.Y),
				Position = UDim2New(Anchor.X, InitialX, Anchor.Y, InitialY),
				Size = UDim2New(0, Width, 0, Height),
				ZIndex = 150,
				BorderSizePixel = 0,
				Visible = MobileButton.Visible
			})
			Items["Shadow"] = Instances:Create("ImageLabel", {
				Parent = Items["Holder"].Instance,
				Name = "\0",
				Image = "rbxassetid://112971167999062",
				ImageColor3 = FromRGB(0, 0, 0),
				ImageTransparency = 0.45,
				AnchorPoint = Vector2New(0.5, 0.5),
				Position = UDim2New(0.5, 0, 0.5, 2),
				Size = UDim2New(1, 22, 1, 22),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = RectNew(Vector2New(112, 112), Vector2New(147, 147)),
				SliceScale = 0.5,
				BackgroundTransparency = 1,
				ZIndex = 149,
				BorderSizePixel = 0
			}); Items["Shadow"]:AddToTheme({ImageColor3 = "Shadow"})
			Items["Panel"] = Instances:Create("Frame", {
				Parent = Items["Holder"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0.5, 0.5),
				Position = UDim2New(0.5, 0, 0.5, 0),
				Size = UDim2New(1, 0, 1, 0),
				BackgroundColor3 = FromRGB(24, 27, 34),
				BackgroundTransparency = 0.1,
				BorderSizePixel = 0,
				ZIndex = 151
			}); Items["Panel"]:AddToTheme({BackgroundColor3 = "Inline"})
			Instances:Create("UICorner", {
				Parent = Items["Panel"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 12)
			})
			Items["Stroke"] = Instances:Create("UIStroke", {
				Parent = Items["Panel"].Instance,
				Name = "\0",
				Color = FromRGB(66, 73, 88),
				Thickness = 1.4,
				Transparency = 0.25
			}); Items["Stroke"]:AddToTheme({Color = "Border"})
			Items["Grip"] = Instances:Create("Frame", {
				Parent = Items["Panel"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0.5, 0),
				Position = UDim2New(0.5, 0, 0, 5),
				Size = UDim2New(0, 26, 0, 3),
				BackgroundColor3 = FromRGB(80, 88, 105),
				BorderSizePixel = 0,
				ZIndex = 152
			}); Items["Grip"]:AddToTheme({BackgroundColor3 = "Border"})
			Instances:Create("UICorner", {
				Parent = Items["Grip"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(1, 0)
			})
			Items["Content"] = Instances:Create("Frame", {
				Parent = Items["Panel"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				Position = UDim2New(0, 6, 0, 12),
				Size = UDim2New(1, -12, 1, -16),
				ZIndex = 152,
				BorderSizePixel = 0
			})
			Instances:Create("UIListLayout", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDimNew(0, 4)
			})
			Items["ToggleButton"] = Instances:Create("TextButton", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 27),
				BackgroundColor3 = FromRGB(34, 38, 48),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				ZIndex = 153,
				LayoutOrder = 1
			}); Items["ToggleButton"]:AddToTheme({BackgroundColor3 = "Element"})
			Instances:Create("UICorner", {
				Parent = Items["ToggleButton"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 7)
			})
			Items["ToggleStroke"] = Instances:Create("UIStroke", {
				Parent = Items["ToggleButton"].Instance,
				Name = "\0",
				Color = FromRGB(55, 62, 75),
				Thickness = 1,
				Transparency = 0.4
			}); Items["ToggleStroke"]:AddToTheme({Color = "Border"})
			Items["ToggleIcon"] = Instances:Create("ImageLabel", {
				Parent = Items["ToggleButton"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0, 0.5),
				Position = UDim2New(0, 7, 0.5, 0),
				Size = UDim2New(0, 14, 0, 14),
				BackgroundTransparency = 1,
				Image = "rbxassetid://10723346959",
				ImageColor3 = FromRGB(59, 130, 246),
				ZIndex = 154,
				BorderSizePixel = 0
			}); Items["ToggleIcon"]:AddToTheme({ImageColor3 = "Accent"})
			Items["ToggleLabel"] = Instances:Create("TextLabel", {
				Parent = Items["ToggleButton"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0, 0.5),
				Position = UDim2New(0, 26, 0.5, 0),
				Size = UDim2New(1, -50, 1, 0),
				BackgroundTransparency = 1,
				FontFace = Library.Font,
				Text = "Toggle UI",
				TextSize = 12,
				TextColor3 = FromRGB(240, 244, 252),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 154,
				BorderSizePixel = 0
			}); Items["ToggleLabel"]:AddToTheme({TextColor3 = "Text"})
			Items["ToggleDot"] = Instances:Create("Frame", {
				Parent = Items["ToggleButton"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(1, 0.5),
				Position = UDim2New(1, -7, 0.5, 0),
				Size = UDim2New(0, 7, 0, 7),
				BackgroundColor3 = FromRGB(59, 130, 246),
				ZIndex = 154,
				BorderSizePixel = 0
			}); Items["ToggleDot"]:AddToTheme({BackgroundColor3 = "Accent"})
			Instances:Create("UICorner", {
				Parent = Items["ToggleDot"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(1, 0)
			})
			Items["LockButton"] = Instances:Create("TextButton", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 27),
				BackgroundColor3 = FromRGB(34, 38, 48),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				ZIndex = 153,
				LayoutOrder = 2
			}); Items["LockButton"]:AddToTheme({BackgroundColor3 = "Element"})
			Instances:Create("UICorner", {
				Parent = Items["LockButton"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 7)
			})
			Items["LockStroke"] = Instances:Create("UIStroke", {
				Parent = Items["LockButton"].Instance,
				Name = "\0",
				Color = FromRGB(55, 62, 75),
				Thickness = 1,
				Transparency = 0.4
			}); Items["LockStroke"]:AddToTheme({Color = "Border"})
			Items["LockIcon"] = Instances:Create("ImageLabel", {
				Parent = Items["LockButton"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0, 0.5),
				Position = UDim2New(0, 7, 0.5, 0),
				Size = UDim2New(0, 14, 0, 14),
				BackgroundTransparency = 1,
				Image = "rbxassetid://10734950309",
				ImageColor3 = FromRGB(200, 206, 218),
				ZIndex = 154,
				BorderSizePixel = 0
			}); Items["LockIcon"]:AddToTheme({ImageColor3 = "Text"})
			Items["LockLabel"] = Instances:Create("TextLabel", {
				Parent = Items["LockButton"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(0, 0.5),
				Position = UDim2New(0, 26, 0.5, 0),
				Size = UDim2New(1, -50, 1, 0),
				BackgroundTransparency = 1,
				FontFace = Library.Font,
				Text = "Lock UI",
				TextSize = 12,
				TextColor3 = FromRGB(240, 244, 252),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 154,
				BorderSizePixel = 0
			}); Items["LockLabel"]:AddToTheme({TextColor3 = "Text"})
			Items["LockDot"] = Instances:Create("Frame", {
				Parent = Items["LockButton"].Instance,
				Name = "\0",
				AnchorPoint = Vector2New(1, 0.5),
				Position = UDim2New(1, -7, 0.5, 0),
				Size = UDim2New(0, 7, 0, 7),
				BackgroundColor3 = FromRGB(54, 60, 73),
				ZIndex = 154,
				BorderSizePixel = 0
			}); Items["LockDot"]:AddToTheme({BackgroundColor3 = "Element"})
			Instances:Create("UICorner", {
				Parent = Items["LockDot"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(1, 0)
			})
		end

		local function Refresh()
			local CurTarget = MobileButton.Target or Library.FocusedWindow
			local IsOpen = CurTarget and CurTarget.IsOpen or false
			if IsOpen then
				Items["ToggleDot"]:ChangeItemTheme({ BackgroundColor3 = "Accent" })
				Items["ToggleDot"]:Tween(Tween:Info(0.2), { BackgroundColor3 = Library.Theme.Accent })
				Items["ToggleIcon"]:Tween(Tween:Info(0.2), { ImageColor3 = Library.Theme.Accent })
			else
				Items["ToggleDot"]:ChangeItemTheme({ BackgroundColor3 = "Element" })
				Items["ToggleDot"]:Tween(Tween:Info(0.2), { BackgroundColor3 = Library.Theme.Element })
				Items["ToggleIcon"]:Tween(Tween:Info(0.2), { ImageColor3 = Library.Theme.Text })
			end
			CurTarget = MobileButton.Target or Library.FocusedWindow
			local IsWindowLocked = (CurTarget and CurTarget.Locked) or Library.Locked
			if IsWindowLocked then
				Items["LockDot"]:ChangeItemTheme({ BackgroundColor3 = "Accent" })
				Items["LockDot"]:Tween(Tween:Info(0.2), { BackgroundColor3 = Library.Theme.Accent })
				Items["LockIcon"]:Tween(Tween:Info(0.2), { ImageColor3 = Library.Theme.Accent })
				Items["LockIcon"].Instance.Image = "rbxassetid://10734950309"
				Items["LockLabel"].Instance.Text = "UI Locked"
			else
				Items["LockDot"]:ChangeItemTheme({ BackgroundColor3 = "Element" })
				Items["LockDot"]:Tween(Tween:Info(0.2), { BackgroundColor3 = Library.Theme.Element })
				Items["LockIcon"]:Tween(Tween:Info(0.2), { ImageColor3 = Library.Theme.Text })
				Items["LockIcon"].Instance.Image = "rbxassetid://10734950020"
				Items["LockLabel"].Instance.Text = "Lock UI"
			end
		end

		local function TriggerToggle()
			local CurTarget = MobileButton.Target or Library.FocusedWindow
			if not CurTarget or not CurTarget.SetOpen then
				Library:Notification("Mobile Button", "No window is bound to this button.", 3, "Warning")
				return
			end
			CurTarget:SetOpen(not CurTarget.IsOpen)
			Refresh()
			if MobileButton.Notify then
				Library:Notification(
					"UI " .. (CurTarget.IsOpen and "Shown" or "Hidden"),
					tostring(CurTarget.Name) .. " is now " .. (CurTarget.IsOpen and "open" or "closed") .. ".",
					2,
					CurTarget.IsOpen and "Success" or "Info"
				)
			end
		end

		local function TriggerLock()
			local CurTarget = MobileButton.Target or Library.FocusedWindow
			if CurTarget and CurTarget.SetLocked then
				CurTarget:SetLocked(not CurTarget.Locked)
			else
				Library:SetLocked(not Library.Locked)
			end
			Refresh()
		end
		Items["ToggleButton"]:Connect("MouseButton1Click", TriggerToggle)
		Items["LockButton"]:Connect("MouseButton1Click", TriggerLock)
		Items["ToggleButton"]:Connect("InputBegan", function(Input)
			if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
				Items["ToggleButton"]:Tween(Tween:Info(0.1), { BackgroundTransparency = 0.05 })
			end
		end)
		Items["ToggleButton"]:Connect("InputEnded", function(Input)
			if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
				Items["ToggleButton"]:Tween(Tween:Info(0.15), { BackgroundTransparency = 0.2 })
			end
		end)
		Items["LockButton"]:Connect("InputBegan", function(Input)
			if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
				Items["LockButton"]:Tween(Tween:Info(0.1), { BackgroundTransparency = 0.05 })
			end
		end)
		Items["LockButton"]:Connect("InputEnded", function(Input)
			if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
				Items["LockButton"]:Tween(Tween:Info(0.15), { BackgroundTransparency = 0.2 })
			end
		end)
		local PointerDown = false
		local IsDragging = false
		local DragStartPos
		local _StartHolderPos

		local function OnDragBegan(Input)
			if Input.UserInputType ~= InputTypeMouseButton1
			and Input.UserInputType ~= InputTypeTouch then
				return
			end
			PointerDown = true
			IsDragging = false
			DragStartPos = Input.Position
			_StartHolderPos = Items["Holder"].Instance.Position
			Items["Stroke"]:Tween(Tween:Info(0.12), { Color = Library.Theme.Accent, Transparency = 0 })
		end
		Library:Connect(Items["Grip"].Instance.InputBegan, OnDragBegan)
		Library:Connect(Items["Panel"].Instance.InputBegan, function(Input)
			if not PointerDown then
				OnDragBegan(Input)
			end
		end)
		Library:On(UserInputService.InputChanged, function(Input)
			if not PointerDown then
				return
			end
			if Input.UserInputType ~= InputTypeMouseMovement
			and Input.UserInputType ~= InputTypeTouch then
				return
			end
			local Delta = Input.Position - DragStartPos
			local Dist = Vector2New(Delta.X, Delta.Y).Magnitude
			if Dist > 6 then
				if not IsDragging then
					IsDragging = true
					Items["Panel"]:Tween(Tween:Info(0.15), { BackgroundTransparency = 0.02 })
				end
				local View = Workspace.CurrentCamera.ViewportSize
				local TargetX = MathClamp(Input.Position.X - Width / 2, 8, MathMax(View.X - Width - 8, 8))
				local TargetY = MathClamp(Input.Position.Y - Height / 2, Library.GuiInset + 8, MathMax(View.Y - Height - 8, Library.GuiInset + 8))
				Items["Holder"].Instance.AnchorPoint = Vector2New(0, 0)
				Items["Holder"].Instance.Position = UDim2New(0, TargetX, 0, TargetY)
			end
		end, TypesMove)
		Library:On(UserInputService.InputEnded, function(Input)
			if not PointerDown then
				return
			end
			if Input.UserInputType ~= InputTypeMouseButton1
			and Input.UserInputType ~= InputTypeTouch then
				return
			end
			PointerDown = false
			Items["Stroke"]:Tween(Tween:Info(0.2), { Color = Library.Theme.Border, Transparency = 0.25 })
			Items["Panel"]:Tween(Tween:Info(0.15), { BackgroundTransparency = 0.1 })
			if IsDragging then
				IsDragging = false
				if MobileButton.SnapToEdge then
					local View = Workspace.CurrentCamera.ViewportSize
					local AbsPos = Items["Holder"].Instance.AbsolutePosition
					local CenterX = AbsPos.X + Width / 2
					local SnapX = (CenterX < View.X / 2) and MobileButton.OffsetX or (View.X - Width - MobileButton.OffsetX)
					local SnapY = MathClamp(AbsPos.Y, Library.GuiInset + 10, MathMax(View.Y - Height - 14, Library.GuiInset + 10))
					Items["Holder"]:Tween(Tween:Info(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2New(0, SnapX, 0, SnapY)
					})
				end
			end
		end, TypesClick)

		function MobileButton:SetPosition(NewPosition)
			local NewAnchor = Library.MobilePositions[NewPosition]
			if not NewAnchor then
				return false
			end
			MobileButton.Position = NewPosition
			Items["Holder"].Instance.AnchorPoint = Vector2New(NewAnchor.X, NewAnchor.Y)
			local TargetX = NewAnchor.X == 0 and MobileButton.OffsetX or (NewAnchor.X == 1 and -MobileButton.OffsetX or 0)
			local TargetY = MobileButton.OffsetY + (NewAnchor.Y == 0 and Library.GuiInset + 10 or (NewAnchor.Y == 1 and -10 or 0))
			Items["Holder"]:Tween(Tween:Info(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2New(NewAnchor.X, TargetX, NewAnchor.Y, TargetY)
			})
			return true
		end

		function MobileButton:SetLocked(Bool)
			MobileButton.Locked = not not Bool
			Library.Locked = MobileButton.Locked
			Refresh()
		end

		function MobileButton:SetWindow(Window)
			MobileButton.Target = Window
			Refresh()
		end

		function MobileButton:SetVisible(Bool)
			MobileButton.Visible = not not Bool
			Items["Holder"].Instance.Visible = MobileButton.Visible
		end

		function MobileButton:SetSnapToEdge(Bool)
			MobileButton.SnapToEdge = not not Bool
		end

		function MobileButton:Toggle()
			TriggerToggle()
		end
		MobileButton.Refresh = Refresh
		Refresh()
		return MobileButton, Items
	end
	local FOCUS_BAND = 20

	Library.Window = function(self, Properties)
		Properties = Properties or { }
		local Window = {
			Name = Properties.Name or Properties.name or Brand,
			Size = Properties.Size or Properties.size or (not IsMobile and UDim2New(0, 770, 0, 526) or UDim2New(0, 526, 0, 350)),
			FadeSpeed = Properties.FadeSpeed or Properties.fadespeed or 0.25,
			BackgroundIcon = Properties.BackgroundIcon or Properties.backgroundicon or "",
			PanelsTransparency = Properties.PanelsTransparency or Properties.panelstransparency or Library.Settings.PanelsTransparency or 0.35,
			WindowTransparency = Properties.WindowTransparency or Properties.windowtransparency or Library.Settings.WindowTransparency or 0.20,
			Sections = { },
			TabGroups = { },
			PanelFrames = { },
			Pages = { },
			IsOpen = false,
			Items = { }
		}
		local Items = { } do
			Items["MainFrame"] = Instances:Create("Frame", {
				Parent = (Library.Holder and Library.Holder.Instance) or nil,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				AnchorPoint = Vector2New(0, 0),
				BackgroundTransparency = Window.WindowTransparency,
				Position = UDim2New(0, Camera.ViewportSize.X / 3.5, 0, Camera.ViewportSize.Y / 3.5),
				Size = Window.Size,
				ClipsDescendants = true,
				Visible = true,
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(15, 12, 16)
			}); Items["MainFrame"]:AddToTheme({BackgroundColor3 = "Background"})
			Items["MainFrame"]:MakeDraggable()
			Items["MainFrame"]:MakeResizeable(Vector2New(Window.Size.X.Offset, Window.Size.Y.Offset), Vector2New(9999, 9999))
			Items["ImageBackground"] = Instances:Create("ImageLabel", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				Image = Window.BackgroundIcon or "",
				BackgroundTransparency = 1,
				ImageTransparency = 0.35,
				ScaleType = Enum.ScaleType.Crop,
				Size = UDim2New(1, 0, 1, 0),
				BorderSizePixel = 0,
				ZIndex = 1,
				BackgroundColor3 = FromRGB(15, 12, 16)
			})
			Items["BackgroundAurora"] = Instances:Create("Frame", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				BackgroundTransparency = 0.85,
				Size = UDim2New(1, 0, 1, 0),
				ZIndex = 1,
				BorderSizePixel = 0,
				Visible = false,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Instances:Create("UICorner", {
				Parent = Items["BackgroundAurora"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5)
			})
			Items["AuroraGradient"] = Instances:Create("UIGradient", {
				Parent = Items["BackgroundAurora"].Instance,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, FromRGB(59, 130, 246)),
					ColorSequenceKeypoint.new(0.5, FromRGB(168, 85, 247)),
					ColorSequenceKeypoint.new(1, FromRGB(236, 72, 153))
				}),
				Rotation = 45
			})
			Instances:Create("UICorner", {
				Parent = Items["ImageBackground"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5)
			})
			Instances:Create("UICorner", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5)
			})
			Items["Shadow"] = Instances:Create("ImageLabel", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				ImageColor3 = FromRGB(0, 0, 0),
				ImageTransparency = 0.5600000023841858,
				AnchorPoint = Vector2New(0.5, 0.5),
				Image = "rbxassetid://112971167999062",
				ZIndex = -1,
				BorderSizePixel = 0,
				SliceCenter = RectNew(Vector2New(112, 112), Vector2New(147, 147)),
				ScaleType = Enum.ScaleType.Slice,
				BorderColor3 = FromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				Position = UDim2New(0.5, 0, 0.5, 0),
				SliceScale = 0.6000000238418579,
				Size = UDim2New(1, 55, 1, 55),
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Shadow"]:AddToTheme({ImageColor3 = "Shadow"})
			Items["Title"] = Instances:Create("TextLabel", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(255, 255, 255),
				BorderColor3 = FromRGB(0, 0, 0),
				Text = Window.Name,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2New(0, 0, 0, 15),
				BackgroundTransparency = 1,
				Position = UDim2New(0, 9, 0, 8),
				BorderSizePixel = 0,
				ZIndex = 2,
				TextSize = 14,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Title"]:AddToTheme({TextColor3 = "Text"})
			Items["Pages"] = Instances:Create("Frame", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				Position = UDim2New(0, 0, 0, 36),
				Size = not IsMobile and UDim2New(0, 220, 1, -38) or UDim2New(0, 152, 1, -38),
				ClipsDescendants = false,
				Active = false,
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Library:EnableListScroll(Items["Pages"].Instance, UDimNew(0, 43))
			Instances:Create("UIPadding", {
				Parent = Items["Pages"].Instance,
				Name = "\0",
				PaddingRight = UDimNew(0, 8),
				PaddingLeft = UDimNew(0, 8),
				PaddingTop = UDimNew(0, 6),
				PaddingBottom = UDimNew(0, 6)
			})
			Instances:Create("UIListLayout", {
				Parent = Items["Pages"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder
			})
			Items["Content"] = Instances:Create("Frame", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				Position = not IsMobile and UDim2New(0, 225, 0, 30) or UDim2New(0, 163, 0, 30),
				Size = not IsMobile and UDim2New(1, -233, 1, -38) or UDim2New(1, -171, 1, -38),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Items["MinimizeButton"] = Instances:Create("ImageButton", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(0, 17, 0, 17),
				AutoButtonColor = false,
				AnchorPoint = Vector2New(1, 0),
				Image = "rbxassetid://94817928404736",
				Position = UDim2New(1, -27, 0, 3),
				BackgroundTransparency = 1,
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Instances:Create("Frame", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				Size = UDim2New(0, 1, 1, 0),
				Position = not IsMobile and UDim2New(0, 220, 0, 0) or UDim2New(0, 152, 0, 0),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(41, 37, 45)
			}):AddToTheme({BackgroundColor3 = "Border"})
			Items["CloseButton"] = Instances:Create("ImageButton", {
				Parent = Items["MainFrame"].Instance,
				Name = "\0",
				ScaleType = Enum.ScaleType.Fit,
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(0, 17, 0, 17),
				AutoButtonColor = false,
				AnchorPoint = Vector2New(1, 0),
				Image = "rbxassetid://76001605964586",
				BackgroundTransparency = 1,
				Position = UDim2New(1, -8, 0, 8),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Items["Search"] = Instances:Create("Frame", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Size = UDim2New(1, 0, 0, 35),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(22, 20, 24)
			}); Items["Search"]:AddToTheme({BackgroundColor3 = "Inline"})
			Instances:Create("UICorner", {
				Parent = Items["Search"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5)
			})
			Items["Icon"] = Instances:Create("ImageLabel", {
				Parent = Items["Search"].Instance,
				Name = "\0",
				ScaleType = Enum.ScaleType.Fit,
				ImageTransparency = 0.4000000059604645,
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(0, 20, 0, 20),
				AnchorPoint = Vector2New(0, 0.5),
				Image = "rbxassetid://71924825350727",
				BackgroundTransparency = 1,
				Position = UDim2New(0, 8, 0.5, 0),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Items["Input"] = Instances:Create("TextBox", {
				Parent = Items["Search"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				AnchorPoint = Vector2New(0, 0.5),
				PlaceholderColor3 = FromRGB(185, 185, 185),
				PlaceholderText = "Search..",
				TextSize = 14,
				Size = UDim2New(1, -43, 0, 15),
				TextColor3 = FromRGB(255, 255, 255),
				BorderColor3 = FromRGB(0, 0, 0),
				Text = "",
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,
				Position = UDim2New(0, 35, 0.5, 0),
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Input"]:AddToTheme({TextColor3 = "Text", PlaceholderColor3 = "Inactive Text"})
			Items["Cursor"] = Instances:Create("Frame", {
				Parent = Library.Holder.Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				Position = UDim2New(0, 0, 0, 0),
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(0, 16, 0, 16),
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(0, 0, 0)
			})
			Items["Image"] = Instances:Create("ImageLabel", {
				Parent = Items["Cursor"].Instance,
				Name = "\0",
				ImageColor3 = FromRGB(59, 130, 246),
				BorderColor3 = FromRGB(0, 0, 0),
				Image = "rbxassetid://132511743665753",
				BackgroundTransparency = 1,
				Size = UDim2New(0, 16, 0, 16),
				BorderSizePixel = 0,
				ZIndex = 10001,
				Rotation = -90,
				BackgroundColor3 = FromRGB(59, 130, 246)
			}); Items["Image"]:AddToTheme({ImageColor3 = "Accent"})
			if IsMobile then
				Items["Cursor"].Instance.Visible = false
				if not Library.ActiveMobileButton then
					Library:MobileButton({ Window = Window })
				end
			end
			Window.Items = Items
		end
		UserInputService.MouseIconEnabled = false
		local _Debounce = false

		function Window:SetLocked(Bool)
			self.Locked = not not Bool
			Items["MainFrame"].Instance:SetAttribute("Locked", self.Locked)
			if Library.ActiveMobileButton and Library.ActiveMobileButton.Refresh then
				Library.ActiveMobileButton:Refresh()
			end

		function Window:SetPanelsTransparency(Alpha)
			Alpha = math.clamp(tonumber(Alpha) or 0, 0, 1)
			self.PanelsTransparency = Alpha
			Library.Settings.PanelsTransparency = Alpha
			for _, Frame in ipairs(self.PanelFrames) do
				if Frame and Frame.Instance then
					Frame.Instance.BackgroundTransparency = Alpha
				end
			end
			for _, Section in ipairs(self.Sections) do
				if Section.Items and Section.Items["Section"] and Section.Items["Section"].Instance then
					Section.Items["Section"].Instance.BackgroundTransparency = Alpha
				end
			end
			for _, Group in ipairs(self.TabGroups) do
				for _, Btn in pairs(Group.StripButtons) do
					if Btn and Btn.Instance then
						Btn.Instance.BackgroundTransparency = Alpha
					end
				end
			end
			for _, Page in ipairs(self.Pages) do
				if Page.Items and Page.Items["Inactive"] and Page.Items["Inactive"].Instance then
					if Page.Active then
						Page.Items["Inactive"].Instance.BackgroundTransparency = Alpha
					end
				end
			end
		end

		function Window:SetWindowTransparency(Alpha)
			Alpha = math.clamp(tonumber(Alpha) or 0, 0, 1)
			self.WindowTransparency = Alpha
			Library.Settings.WindowTransparency = Alpha
			if self.Items and self.Items["MainFrame"] and self.Items["MainFrame"].Instance then
				self.Items["MainFrame"].Instance.BackgroundTransparency = Alpha
			end
		end
			Library:Notification(
				self.Locked and "UI Window Locked" or "UI Window Unlocked",
				self.Locked and "The UI window cannot be dragged." or "The UI window can now be dragged.",
				2.5,
				self.Locked and "Warning" or "Success"
			)
		end

		function Window:SetBackgroundTransparency(Value)
			Items["MainFrame"].Instance.BackgroundTransparency = Value
		end

		function Window:SetBackgroundImage(Value, Options)
			Options = Options or { }
			local Raw = tostring(Value or "")
			if Raw == "" or Raw == "nil" or Raw == "None" then
				Items["ImageBackground"].Instance.Image = ""
				Items["ImageBackground"].Instance.Visible = false
				self.BackgroundIcon = ""
				return
			end
			local AssetString = ""
			if Raw:match("^https?://") then
				local RequestFn = (syn and syn.request) or http_request or request or (http and http.request)
				if type(RequestFn) == "function" and type(writefile) == "function" then
					local Extension = Raw:match("%.(%w+)(%?.*)?$") or "png"
					if #Extension > 4 then Extension = "png" end
					local CleanHash = tostring(Raw:gsub("%W", ""):sub(-28))
					local SafeName = "bg_web_" .. CleanHash .. "." .. Extension
					local CachePath = JoinPath(Library.Folders.Assets, SafeName)
					if not FS.IsFile(CachePath) then
						local Success, Response = pcall(RequestFn, {
							Url = Raw,
							Method = "GET"
						})
						if Success and Response and (Response.StatusCode == 200 or Response.Status == 200) and Response.Body then
							FS.Write(CachePath, Response.Body)
						end
					end
					if FS.IsFile(CachePath) then
						AssetString = FS.CustomAsset(CachePath)
					else
						Library:Notification("Background", "Failed to download image from URL.", 3, "Error")
					end
				else
					Library:Notification("Background", "Executor lacks HTTP request API for web images.", 3, "Warning")
				end
			elseif FS.IsFile(Raw) or FS.IsFile(JoinPath(Library.Folders.Assets, Raw)) then
				local FullPath = FS.IsFile(Raw) and Raw or JoinPath(Library.Folders.Assets, Raw)
				AssetString = FS.CustomAsset(FullPath)
			elseif Raw:match("^rbxassetid://") or Raw:match("^rbxasset://") then
				AssetString = Raw
			elseif Raw:match("^%d+$") then
				AssetString = "rbxassetid://" .. Raw
			elseif Raw:match("%d+") then
				local Id = Raw:match("%d+")
				AssetString = "rbxassetid://" .. Id
			else
				AssetString = Raw
			end
			self.BackgroundIcon = AssetString
			Items["ImageBackground"].Instance.Image = AssetString
			Items["ImageBackground"].Instance.Visible = (AssetString ~= "")
			local Mode = Options.ScaleType or Options.scaletype
			if Mode and Enum.ScaleType[Mode] then
				Items["ImageBackground"].Instance.ScaleType = Enum.ScaleType[Mode]
			else
				Items["ImageBackground"].Instance.ScaleType = Enum.ScaleType.Crop
			end
			if Options.Transparency ~= nil then
				Items["ImageBackground"].Instance.ImageTransparency = Options.Transparency
			elseif Items["ImageBackground"].Instance.ImageTransparency == 1 then
				Items["ImageBackground"].Instance.ImageTransparency = 0.35
			end
			if Options.Color then
				Items["ImageBackground"].Instance.ImageColor3 = Options.Color
			end
		end

		function Window:SetBackgroundImageTransparency(Value)
			Items["ImageBackground"].Instance.ImageTransparency = Value
		end

		function Window:SetAnimatedAurora(Bool)
			Items["BackgroundAurora"].Instance.Visible = not not Bool
		end

		local function UpdateSearchFilter()
			local PageSearchData = Library.SearchItems[Library.CurrentPage]
			if not PageSearchData then
				return
			end
			local Text = Items["Input"].Instance.Text
			local SearchQuery = StringLower(Text)
			for Index, Value in PageSearchData do
				local Name = Value.Name
				local Element = Value.Item
				if Text == "" or StringFind(StringLower(Name), SearchQuery) then
					Element.Instance.Visible = true
				else
					Element.Instance.Visible = false
				end
			end
		end
		Items["Input"].Instance:GetPropertyChangedSignal("Text"):Connect(UpdateSearchFilter)
		local IsMinisize = false
		local IsOpen = false
		local OldSize = Items["MainFrame"].Instance.AbsoluteSize

		function Window:Minimize(Bool)
			Library:ClosePopups()
			IsMinisize = Bool
			if IsMinisize then
				Items["MainFrame"]:Tween(nil, {Size = UDim2New(0, OldSize.X, 0, 35)})
				Items["MainFrame"]:Tween(nil, {Size = UDim2New(0, 275, 0, 35)})
			else
				Items["MainFrame"]:Tween(nil, {Size = UDim2New(0, OldSize.X, 0, OldSize.Y)})
			end
		end

		function Window:SetOpen(Bool)
			if not Bool then
				Library:ClosePopups()
			end
			IsOpen = Bool
			self.IsOpen = Bool
			if IsOpen then
				Items["MainFrame"].Instance.Visible = true
			else
				Items["MainFrame"].Instance.Visible = false
				Library:AutoSave()
			end
			if Library.ActiveMobileButton and Library.ActiveMobileButton.Refresh then
				Library.ActiveMobileButton:Refresh()
			end
			local ShowCursor = Bool and not IsMobile and Library.Settings.CustomCursor ~= false
			if Items["Cursor"] and Items["Cursor"].Instance then
				Items["Cursor"].Instance.Visible = ShowCursor
			end
			UserInputService.MouseIconEnabled = not ShowCursor
			Library:UpdateBlur(Bool)
			if Library.UpdateCenterSpinner then
				Library:UpdateCenterSpinner(Bool)
			end
		end

		local function ApplyZOffset(Window, Delta)
			if not Delta or Delta == 0 then
				return
			end
			local MainFrame = Window.Items["MainFrame"].Instance
			Window.ZOffset += Delta
			MainFrame.ZIndex += Delta
			local State = GetGuiList(MainFrame)
			local Objects = State.Objects
			local Count = State.Count
			for Index = 1, Count do
				local Descendant = Objects[Index]
				if Descendant and Descendant.Parent then
					Descendant.ZIndex += Delta
				end
			end
		end

		function Window:Focus()
			if Library.FocusedWindow == self then
				return
			end
			Library.FocusedWindow = self
			if #Library.Windows > 1 then
				ApplyZOffset(self, ((self.Index - 1) * FOCUS_BAND) - self.ZOffset)
			end
			local ShowCursor = self.IsOpen and not IsMobile and Library.Settings.CustomCursor ~= false
			if Items["Cursor"] and Items["Cursor"].Instance then
				Items["Cursor"].Instance.Visible = ShowCursor
			end
			UserInputService.MouseIconEnabled = not ShowCursor
		end
		TableInsert(Library.Windows, Window)
		Window.Index = #Library.Windows
		Window.ZOffset = 0
		Library.FocusedWindow = Window
		Items["MainFrame"].Instance.InputBegan:Connect(function()
			Window:Focus()
		end)
		Library:On(UserInputService.InputBegan, function(Input)
			if tostring(Input.KeyCode) == Library.MenuKeybind or tostring(Input.UserInputType) == Library.MenuKeybind then
				if Library.FocusedWindow and Library.FocusedWindow ~= Window then
					return
				end
				local NewState = not Window.IsOpen
				Window:SetOpen(NewState)
				local ShowCursor = NewState and not IsMobile and Library.Settings.CustomCursor ~= false
				if Items["Cursor"] and Items["Cursor"].Instance then
					Items["Cursor"].Instance.Visible = ShowCursor
				end
				UserInputService.MouseIconEnabled = not ShowCursor
			end
		end)
		Library:AddFrameJob("WindowFX", function()
			if not IsMobile and Items["Cursor"] and Items["Cursor"].Instance and Window.IsOpen and Library.Settings.CustomCursor ~= false then
				local MouseLocation = Library:GetMouse()
				Items["Cursor"].Instance.Position = UDim2New(0, MouseLocation.X, 0, MouseLocation.Y)
			end
			local Aurora = Items["BackgroundAurora"]
			if Aurora and Aurora.Instance.Visible then
				Items["AuroraGradient"].Instance.Rotation = (Tick() * 30) % 360
			end
		end)
		Items["MinimizeButton"]:Connect("MouseButton1Down", function()
			Window:Minimize(not IsMinisize)
		end)
		Items["CloseButton"]:Connect("MouseButton1Down", function()
			Items["MainFrame"].Instance.Visible = false
			task.wait(0.1)
			Library:Unload()
		end)
		return setmetatable(Window, self)
	end

	Library.Page = function(self, Properties)
		Properties = Properties or { }
		local Page = {
			Window = self,
			Name = Properties.Name or Properties.name or "Page",
			Columns = Properties.Columns or Properties.columns or 2,
			Active = false,
			IsKeyPage = Properties.IsKeyPage or Properties.iskeypage or false,
			OnShown = { },
			Items = { },
			ColumnsData = { }
		}
		local Items = { } do
			Items["Inactive"] = Instances:Create("TextButton", {
				Parent = Page.Window.Items["Pages"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(0, 0, 0),
				BorderColor3 = FromRGB(0, 0, 0),
				Text = "",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				Size = UDim2New(1, 0, 0, 30),
				ClipsDescendants = false,
				ZIndex = 2,
				TextSize = 14,
				BackgroundColor3 = FromRGB(28, 25, 36)
			}); Items["Inactive"]:AddToTheme({BackgroundColor3 = "Inline"})
			Instances:Create("UICorner", {
				Parent = Items["Inactive"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 6)
			})
			local PageStroke = Instances:Create("UIStroke", {
				Parent = Items["Inactive"].Instance,
				Name = "\0",
				Thickness = 1,
				Color = FromRGB(48, 44, 58),
				Transparency = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			})
			Items["PageStroke"] = PageStroke
			Items["Liner"] = Instances:Create("Frame", {
				Parent = Items["Inactive"].Instance,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				AnchorPoint = Vector2New(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2New(0, 5, 0.5, 0),
				Size = UDim2New(0, 3, 0, 16),
				ZIndex = 3,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 174, 254)
			}); Items["Liner"]:AddToTheme({BackgroundColor3 = "Accent"})
			Instances:Create("UICorner", {
				Parent = Items["Liner"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(1, 0)
			})
			Items["Text"] = Instances:Create("TextLabel", {
				Parent = Items["Inactive"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(255, 255, 255),
				TextTransparency = 0.45,
				Text = Page.Name,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2New(0, 0, 0, 15),
				AnchorPoint = Vector2New(0, 0.5),
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				Position = UDim2New(0, 14, 0.5, 0),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				TextSize = 14,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
			Items["Inactive"]:Connect("MouseEnter", function()
				if not Page.Active then
					Items["Inactive"]:Tween(Tween:Info(0.12), { BackgroundTransparency = 0.45 })
					Items["Text"]:Tween(Tween:Info(0.12), { TextTransparency = 0.15 })
				end
			end)
			Items["Inactive"]:Connect("MouseLeave", function()
				if not Page.Active then
					Items["Inactive"]:Tween(Tween:Info(0.15), { BackgroundTransparency = 1 })
					Items["Text"]:Tween(Tween:Info(0.15), { TextTransparency = 0.45 })
				end
			end)
			Items["Page"] = Instances:Create("Frame", {
				Parent = Page.Window.Items["Content"].Instance,
				Name = "\0",
				Visible = false,
				BackgroundTransparency = 1,
				Size = UDim2New(1, 0, 1, 0),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			if not Page.IsKeyPage then
				Items["Columns"] = Instances:Create("Frame", {
					Parent = Items["Page"].Instance,
					Name = "\0",
					BorderColor3 = FromRGB(0, 0, 0),
					BackgroundTransparency = 1,
					Position = UDim2New(0, 0, 0, 43),
					Size = UDim2New(1, 0, 1, -43),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				Instances:Create("UIListLayout", {
					Parent = Items["Columns"].Instance,
					Name = "\0",
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					Padding = UDimNew(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalFlex = Enum.UIFlexAlignment.Fill
				})
				for Index = 1, Page.Columns do
					local NewColumn = Instances:Create("ScrollingFrame", {
						Parent = Items["Columns"].Instance,
						Name = "\0",
						ScrollBarImageColor3 = FromRGB(59, 130, 246),
						ScrollBarImageTransparency = 0.15,
						Active = true,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						ScrollBarThickness = Library.Settings.ScrollBarThickness,
						ScrollingDirection = Enum.ScrollingDirection.Y,
						BorderColor3 = FromRGB(0, 0, 0),
						BackgroundTransparency = 1,
						Size = UDim2New(0, 100, 0, 100),
						BackgroundColor3 = FromRGB(255, 255, 255),
						ZIndex = 2,
						BorderSizePixel = 0,
						CanvasSize = UDim2New(0, 0, 0, 0)
					}); NewColumn:AddToTheme({ScrollBarImageColor3 = "Accent"})
					Instances:Create("UIPadding", {
						Parent = NewColumn.Instance,
						Name = "\0",
						PaddingBottom = UDimNew(0, 8)
					})
					Instances:Create("UIListLayout", {
						Parent = NewColumn.Instance,
						Name = "\0",
						Padding = UDimNew(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
					Page.ColumnsData[Index] = NewColumn
					Library:EnableSmoothScroll(NewColumn.Instance)
				end
			else
				Items["Page"].Instance.Size = UDim2New(1, 0, 1, -43)
				Items["Page"].Instance.Position = UDim2New(0, 0, 0, 43)
				Instances:Create("UIListLayout", {
					Parent = Items["Page"].Instance,
					Name = "\0",
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDimNew(0, 15)
				})
			end
			Page.Items = Items
		end
		if not Page.IsKeyPage then
			Library.SearchItems[Page] = { }
		end
		Page.Frame = Items["Page"] and Items["Page"].Instance
		Page.BasePosition = Page.Frame and Page.Frame.Position or UDim2New(0, 0, 0, 43)
		Library.QueueWarmup(Page)
		local _Debounce = false

		function Page:Turn(Bool)
			if self.Turned and self.Active == Bool then
				return
			end
			self.Turned = true
			if Bool then
				Library:ClosePopups()
				-- Hard invariant: turning a page on always turns every sibling off,
				-- so two page bodies can never be visible at the same time.
				local Siblings = self.Window and self.Window.Pages
				if Siblings then
					for Index = 1, #Siblings do
						local Other = Siblings[Index]
						if Other ~= self and Other.Active then
							Other:Turn(false)
						end
					end
				end
			end
			self.Active = Bool
			if self.Active then
				local Frame = Page.Frame
				if not Frame.Visible then
					Frame.Visible = true
				end
				if (Page.WarmedVersion or -1) ~= (Page.ContentVersion or 0) then
					Library.QueueWarmup(Page)
				end
				Items["Liner"]:Tween(Tween:Info(0.18), {BackgroundTransparency = 0, Size = UDim2New(0, 3, 0, 18)})
				Items["Inactive"]:Tween(Tween:Info(0.18), {BackgroundTransparency = 0.15})
				if Items["PageStroke"] then
					Items["PageStroke"]:Tween(Tween:Info(0.18), {Color = FromRGB(48, 44, 58), Transparency = 0.7})
				end
				Items["Text"]:Tween(Tween:Info(0.18), {TextTransparency = 0, Position = UDim2New(0, 16, 0.5, 0)})
				Library.CurrentPage = Page
				for Index, Callback in ipairs(Page.OnShown) do
					Library:SafeCall(Callback)
				end
				local Base = Page.BasePosition
				if Library.Settings.PageTransitions and Page.Lightweight ~= false then
					Frame.Position = UDim2New(Base.X.Scale, Base.X.Offset + 10, Base.Y.Scale, Base.Y.Offset)
					Frame:Tween(nil, {Position = Base})
				elseif Frame.Position ~= Base then
					Frame.Position = Base
				end
			else
				Items["Liner"]:Tween(Tween:Info(0.18), {BackgroundTransparency = 1, Size = UDim2New(0, 3, 0, 4)})
				Items["Inactive"]:Tween(Tween:Info(0.18), {BackgroundTransparency = 1})
				if Items["PageStroke"] then
					Items["PageStroke"]:Tween(Tween:Info(0.18), {Transparency = 1})
				end
				Items["Text"]:Tween(Tween:Info(0.18), {TextTransparency = 0.45, Position = UDim2New(0, 14, 0.5, 0)})
				Page.Frame.Visible = false
			end
		end

		function Page:AddKey(Text, Key, GetKeyLink, Callback)
			if not self.IsKeyPage then
				return
			end
			local NewKey: any = {
				Text = Text,
				Key = Key,
				Success = false,
				Check = nil :: any,
				GetKey = nil :: any,
			}
			local InputTextbox, InputTextboxItems
			local Button, _CheckKeyButton, _GetKeyButton, ButtonItems
			function NewKey:Check()
				if InputTextboxItems and InputTextboxItems["Input"] and InputTextboxItems["Input"].Instance.Text == NewKey.Key then
					NewKey.Success = true
					Callback()
					return
				else
					NewKey.Success = false
					if InputTextbox then
						InputTextbox:SetText("Key is false.")
						task.wait(2)
						InputTextbox:SetText("Enter key here..")
					end
				end
			end
			function NewKey:GetKey()
				pcall(setclipboard, tostring(GetKeyLink))
				if InputTextbox then
					InputTextbox:SetText("Copied link to your clipboard!")
					task.wait(2)
					InputTextbox:SetText("Enter key here..")
				end
			end
			local SubItems = { } do
				SubItems["NewKey"] = Instances:Create("Frame", {
					Parent = Items["Page"].Instance,
					Name = "\0",
					BackgroundTransparency = 1,
					Size = UDim2New(1, -125, 0, 80),
					BorderColor3 = FromRGB(0, 0, 0),
					ZIndex = 2,
					BorderSizePixel = 0,
					BackgroundColor3 = FromRGB(255, 255, 255)
				})
				InputTextbox, InputTextboxItems = Components.Textbox({
					Name = "Enter key here..",
					Flag = Library:NextFlag(),
					Parent = SubItems["NewKey"],
					Page = self,
					Placeholder = "..",
					Disabled = false
				})
				Button, ButtonItems = Components.Button({
					Parent = SubItems["NewKey"],
					Page = self,
				})
				ButtonItems["Button"].Instance.AnchorPoint = Vector2New(0, 1)
				ButtonItems["Button"].Instance.Position = UDim2New(0, 0, 1, 0)
				_CheckKeyButton = Button:Add("Check key", function()
					NewKey:Check()
				end, false)
				_GetKeyButton = Button:Add("Get key", function()
					NewKey:GetKey()
				end, false)
			end
		end

		local function SelectThisPage()
			if Page.Active then
				return
			end
			for Index, Value in Page.Window.Pages do
				Value:Turn(Value == Page)
			end
		end
		Items["Inactive"]:Connect("MouseButton1Click", SelectThisPage)
		if #Page.Window.Pages == 0 then
			Page:Turn(true)
		end
		TableInsert(Page.Window.Pages, Page)
		return setmetatable(Page, Library.Pages)
	end

	Library.Pages.Turn = function(self, Bool)
		local TabItems = self.Items
		if not TabItems or not TabItems["Holder"] then
			return
		end
		Bool = not not Bool
		if self.Turned and self.Active == Bool then
			return
		end
		self.Turned = true
		if Bool then
			-- Hard invariant: only one subtab per group may ever be active.
			local Group = self.Group
			if Group and Group.Order and Group.Tabs then
				for Index = 1, #Group.Order do
					local Other = Group.Tabs[Group.Order[Index]]
					if Other and Other ~= self and Other.Active then
						Library.Pages.Turn(Other, false)
					end
				end
			end
			Group.Active = self.Name
		elseif self.Group and self.Group.Active == self.Name then
			self.Group.Active = nil
		end
		self.Active = Bool
		local Visible = self.Active
		if TabItems["Holder"].Instance then
			TabItems["Holder"].Instance.Visible = Visible
		end
		if TabItems["Button"] then
			TabItems["Button"]:Tween(Tween:Info(0.18), { BackgroundTransparency = Visible and 0.15 or 0.55, TextTransparency = Visible and 0 or 0.4 })
		end
		if TabItems["SubtabStroke"] then
			TabItems["SubtabStroke"]:Tween(Tween:Info(0.18), { Color = Visible and (Library.Theme.Accent or FromRGB(59, 130, 246)) or FromRGB(52, 48, 62), Transparency = Visible and 0.25 or 0.7 })
		end
		if TabItems["Indicator"] then
			TabItems["Indicator"]:Tween(Tween:Info(0.18), { BackgroundTransparency = Visible and 0 or 1, Size = Visible and UDim2New(0.6, 0, 0, 2) or UDim2New(0, 0, 0, 2) })
		end
	end

	Library.Pages.TabGroup = function(self, Properties)
		Properties = Properties or { }
		local TabNames = Properties.Items or Properties.items or { }
		if #TabNames == 0 then
			return
		end
		local TabGroup: any = {
			Window = self.Window,
			Page = self,
			Name = Properties.Name or Properties.name or "Tabs",
			Items = TabNames,
			Columns = Properties.Columns or Properties.columns or 2,
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			MinCellWidth = Properties.MinCellWidth or Properties.mincellwidth or 70,
			MaxCellWidth = Properties.MaxCellWidth or Properties.maxcellwidth or 160,
			CellHeight = Properties.CellHeight or Properties.cellheight or 30,
			Gap = Properties.Gap or Properties.gap or 6,
			Rows = 1,
			CellWidth = 120,
			Tabs = { },
			Order = { },
			Active = nil,
			StripItems = { },
			StripButtons = { },
			Turn = nil :: any,
		}
		local SearchOffset = 0
		if self.Window and self.Window.Items and self.Window.Items["Search"]
		and self.Window.Items["Search"].Instance then
			SearchOffset = self.Window.Items["Search"].Instance.Size.Y.Offset
		end
		local Items = { } do
			Items["TabGroup"] = Instances:Create("Frame", {
				Parent = self.Items["Page"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			if TabGroup.Name and TabGroup.Name ~= "" then
				Items["Text"] = Instances:Create("TextLabel", {
					Parent = Items["TabGroup"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = TabGroup.Name,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2New(0, 0, 0, 15),
					BackgroundTransparency = 1,
					Position = UDim2New(0, 0, 0, 4),
					BorderSizePixel = 0,
					ZIndex = 3,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
			end
			Items["Strip"] = Instances:Create("Frame", {
				Parent = Items["TabGroup"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(1, 0, 0, 30),
				Position = UDim2New(0, 0, 0, SearchOffset + (TabGroup.Name and TabGroup.Name ~= "" and 22 or 0)),
				ZIndex = 3,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Items["Grid"] = Instances:Create("UIGridLayout", {
				Parent = Items["Strip"].Instance,
				Name = "\0",
				CellSize = UDim2New(0, 120, 0, TabGroup.CellHeight),
				CellPadding = UDim2New(0, TabGroup.Gap, 0, TabGroup.Gap),
				SortOrder = Enum.SortOrder.LayoutOrder
			})
			Items["Holder"] = Instances:Create("Frame", {
				Parent = Items["TabGroup"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				BorderColor3 = FromRGB(0, 0, 0),
				Position = UDim2New(0, 0, 0, SearchOffset + (TabGroup.Name and TabGroup.Name ~= "" and 56 or 34)),
				Size = UDim2New(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
		end

		local function MakeColumns(Tab)
			Tab.ColumnsData = { }
			Instances:Create("UIListLayout", {
				Parent = Tab.Items["Holder"].Instance,
				Name = "\0",
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDimNew(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalFlex = Enum.UIFlexAlignment.Fill
			})
			for Index = 1, Tab.Columns do
				local NewColumn = Instances:Create("ScrollingFrame", {
					Parent = Tab.Items["Holder"].Instance,
					Name = "\0",
					ScrollBarImageColor3 = FromRGB(59, 130, 246),
					ScrollBarImageTransparency = 0.15,
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = Library.Settings.ScrollBarThickness,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					BorderColor3 = FromRGB(0, 0, 0),
					BackgroundTransparency = 1,
					Size = UDim2New(0, 100, 0, 100),
					BackgroundColor3 = FromRGB(255, 255, 255),
					ZIndex = 2,
					BorderSizePixel = 0,
					CanvasSize = UDim2New(0, 0, 0, 0)
				}); NewColumn:AddToTheme({ScrollBarImageColor3 = "Accent"})
				Instances:Create("UIPadding", {
					Parent = NewColumn.Instance,
					Name = "\0",
					PaddingBottom = UDimNew(0, 8)
				})
				Instances:Create("UIListLayout", {
					Parent = NewColumn.Instance,
					Name = "\0",
					Padding = UDimNew(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder
				})
				Tab.ColumnsData[Index] = NewColumn
				Library:EnableSmoothScroll(NewColumn.Instance)
			end
		end
		for Index, TabName in ipairs(TabNames) do
			local Tab = {
				Window = self.Window,
				Page = self,
				Group = TabGroup,
				Name = TabName,
				Columns = TabGroup.Columns,
				Active = false,
				Items = { }
			}
			local TabButton = Instances:Create("TextButton", {
				Parent = Items["Strip"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				Text = tostring(TabName),
				AutoButtonColor = false,
				TextColor3 = FromRGB(255, 255, 255),
				TextTransparency = 0.4,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(1, 0, 0, 30),
				BackgroundTransparency = 0.55,
				ZIndex = 4,
				BorderSizePixel = 0,
				TextSize = 14,
				BackgroundColor3 = FromRGB(24, 21, 30)
			}); TabButton:AddToTheme({BackgroundColor3 = "Inline"})
			Instances:Create("UICorner", {
				Parent = TabButton.Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 6)
			})
			local SubtabStroke = Instances:Create("UIStroke", {
				Parent = TabButton.Instance,
				Name = "\0",
				Thickness = 1,
				Color = FromRGB(52, 48, 62),
				Transparency = 0.7,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			})
			Tab.Items["SubtabStroke"] = SubtabStroke
			local Indicator = Instances:Create("Frame", {
				Parent = TabButton.Instance,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				AnchorPoint = Vector2New(0.5, 1),
				BackgroundTransparency = 1,
				Position = UDim2New(0.5, 0, 1, -2),
				Size = UDim2New(0.6, 0, 0, 2),
				ZIndex = 5,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 174, 254)
			}); Indicator:AddToTheme({BackgroundColor3 = "Accent"})
			Instances:Create("UICorner", {
				Parent = Indicator.Instance,
				Name = "\0",
				CornerRadius = UDimNew(1, 0)
			})
			TabButton:Connect("MouseEnter", function()
				if not Tab.Active then
					TabButton:Tween(Tween:Info(0.12), { BackgroundTransparency = 0.35, TextTransparency = 0.15 })
					SubtabStroke:Tween(Tween:Info(0.12), { Transparency = 0.4 })
				end
			end)
			TabButton:Connect("MouseLeave", function()
				if not Tab.Active then
					TabButton:Tween(Tween:Info(0.15), { BackgroundTransparency = 0.55, TextTransparency = 0.4 })
					SubtabStroke:Tween(Tween:Info(0.15), { Transparency = 0.7 })
				end
			end)
			Tab.Items["Holder"] = Instances:Create("Frame", {
				Parent = Items["Holder"].Instance,
				Name = "\0",
				Visible = false,
				BackgroundTransparency = 1,
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Tab.Items["Button"] = TabButton
			Tab.Items["Indicator"] = Indicator
			MakeColumns(Tab)
			TabGroup.Tabs[TabName] = Tab
			TabGroup.StripButtons[TabName] = TabButton
			TableInsert(TabGroup.Order, TabName)
			Library.SearchItems[Tab] = Library.SearchItems[Tab] or { }
			setmetatable(Tab, Library.Pages)
			TabButton:Connect("InputBegan", function(Input)
				if Input.UserInputType ~= InputTypeMouseButton1
				and Input.UserInputType ~= InputTypeTouch then
					return
				end
				TabGroup:Turn(TabName)
			end)
		end

		local function AutoFit()
			local Available = Items["TabGroup"].Instance.AbsoluteSize.X
			if Available <= 0 then
				return
			end
			local Count = #TabGroup.Order
			if Count == 0 then
				return
			end
			local Gap = TabGroup.Gap
			local MinCell = MathMax(TabGroup.MinCellWidth, 32)
			local MaxCell = MathMax(TabGroup.MaxCellWidth, MinCell)
			local Columns = MathMax(1, MathFloor((Available + Gap) / (MinCell + Gap)))
			Columns = MathMin(Columns, Count)
			local CellWidth = MathFloor((Available - (Gap * (Columns - 1))) / Columns)
			CellWidth = MathMin(CellWidth, MaxCell)
			CellWidth = MathMax(CellWidth, 24)
			local Rows = MathCeil(Count / Columns)
			if CellWidth == TabGroup.CellWidth and Rows == TabGroup.Rows then
				return
			end
			TabGroup.CellWidth = CellWidth
			TabGroup.Rows = Rows
			Items["Grid"].Instance.CellSize = UDim2New(0, CellWidth, 0, TabGroup.CellHeight)
			local StripHeight = (Rows * TabGroup.CellHeight) + ((Rows - 1) * Gap)
			Items["Strip"].Instance.Size = UDim2New(1, 0, 0, StripHeight)
			Items["Holder"].Instance.Position = UDim2New(0, 0, 0, (Items["Strip"].Instance.Position.Y.Offset + StripHeight) + Gap)
			local TextSize = MathClamp(MathFloor(CellWidth / 6.5), 9, 14)
			for Index, TabName in ipairs(TabGroup.Order) do
				local Button = TabGroup.StripButtons[TabName]
				if Button and Button.Instance then
					Button.Instance.TextSize = TextSize
				end
			end
		end
		TabGroup.AutoFit = AutoFit
		Library:Connect(Items["TabGroup"].Instance:GetPropertyChangedSignal("AbsoluteSize"), function()
			Library:QueueAutoFit(AutoFit, TabGroup)
		end)
		if self.OnShown then
			TableInsert(self.OnShown, function()
				Library:QueueAutoFit(AutoFit, TabGroup)
			end)
		end
		Library:QueueAutoFit(AutoFit, TabGroup)
		if Library.SearchItems[self] then
			TableInsert(Library.SearchItems[self], { Name = TabGroup.Name, Item = Items["TabGroup"] })
		end
		Library.Elements[TabGroup.Flag] = TabGroup

		TabGroup.Get = function(self)
			return self.Active
		end

		TabGroup.GetTab = function(self, TabName)
			return self.Tabs[TabName]
		end

		function TabGroup:Turn(TabName)
			if self.Active == TabName then
				return true
			end
			Library:ClosePopups()
			if not self.Tabs[TabName] then
				return false
			end
			for _, Name in ipairs(self.Order) do
				self.Tabs[Name]:Turn(Name == TabName)
			end
			self.Active = TabName
			Library.Flags[self.Flag] = TabName
			if self.Callback then
				Library:SafeCall(self.Callback, TabName)
			end
			return true
		end

		function TabGroup:SetVisible(Bool)
			Items["TabGroup"].Instance.Visible = not not Bool
		end
		local DefaultTab = Properties.Default or Properties.default or TabNames[1]
		TabGroup:Turn(DefaultTab)
		return TabGroup
	end

	Library.Pages.Section = function(self, Properties)
		Properties = Properties or { }
		local Section = {
			Window = self.Window,
			Page = self,
			Name = Properties.Name or Properties.name or "Section",
			Side = Properties.Side or Properties.side or 1,
			Collapsible = Properties.Collapsible or Properties.collapsible or false,
			Expanded = Properties.Expanded or Properties.expanded or true,
			Items = { }
		}
		local Items = { } do
			Items["Section"] = Instances:Create("Frame", {
				Parent = Section.Page.ColumnsData[Section.Side].Instance,
				Name = "\0",
				BorderSizePixel = 0,
				Size = UDim2New(1, 0, 0, 45),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = (Section.Window and Section.Window.PanelsTransparency) or 0.35,
				BackgroundColor3 = FromRGB(22, 20, 24)
			}); Items["Section"]:AddToTheme({BackgroundColor3 = "Inline"})
			if Section.Window and Section.Window.Sections then table.insert(Section.Window.Sections, Section) end
			Instances:Create("UICorner", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5)
			})
			Instances:Create("UIGradient", {
				Parent = Items["Section"].Instance,
				Name = "\0"
			})
			Instances:Create("UIPadding", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				PaddingBottom = UDimNew(0, 8)
			})
			Items["Header"] = Instances:Create("TextButton", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2New(1, 0, 0, 30),
				Position = UDim2New(0, 0, 0, 0),
				BorderSizePixel = 0,
				ZIndex = 3,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Items["Text"] = Instances:Create("TextLabel", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(255, 255, 255),
				BorderColor3 = FromRGB(0, 0, 0),
				Text = Section.Name,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2New(0, 0, 0, 15),
				BackgroundTransparency = 1,
				Position = UDim2New(0, 8, 0, 8),
				BorderSizePixel = 0,
				ZIndex = 4,
				TextSize = 14,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
			if Section.Collapsible then
				Items["Indicator"] = Instances:Create("TextLabel", {
					Parent = Items["Section"].Instance,
					Name = "\0",
					FontFace = Library.Font,
					TextColor3 = FromRGB(255, 255, 255),
					BorderColor3 = FromRGB(0, 0, 0),
					Text = ">",
					Size = UDim2New(0, 20, 0, 15),
					AnchorPoint = Vector2New(1, 0),
					Position = UDim2New(1, -8, 0, 8),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 4,
					TextSize = 14,
					BackgroundColor3 = FromRGB(255, 255, 255)
				}); Items["Indicator"]:AddToTheme({TextColor3 = "Inactive Text"})
			end
			Items["Liner"] = Instances:Create("Frame", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				Size = UDim2New(1, -16, 0, 1),
				Position = UDim2New(0, 8, 0, 28),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 4,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(41, 37, 45)
			}); Items["Liner"]:AddToTheme({BackgroundColor3 = "Border"})
			Items["Content"] = Instances:Create("Frame", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				Position = UDim2New(0, 8, 0, 38),
				Size = UDim2New(1, -16, 0, 0),
				ZIndex = 2,
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Instances:Create("UIListLayout", {
				Parent = Items["Content"].Instance,
				Name = "\0",
				Padding = UDimNew(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder
			})
			Section.Items = Items
		end
		setmetatable(Section, Library.Sections)
		if Section.Collapsible then
			Items["Header"]:Connect("MouseButton1Down", function()
				Section:SetExpanded(not Section.Expanded)
			end)
			Section:SetExpanded(Section.Expanded)
			Library.QueueWarmContainer(Items["Content"].Instance)
		end
		return Section
	end

	Library.Pages.CollapsibleSection = function(self, Properties)
		Properties = Properties or { }
		Properties.Collapsible = true
		return Library.Pages.Section(self, Properties)
	end

	Library.Pages.ImageSection = function(self, Properties)
		Properties = Properties or { }
		local Section = {
			Window = self.Window,
			Page = self,
			Name = Properties.Name or Properties.name or "ImageSection",
			Side = Properties.Side or Properties.side or 1,
			Images  = Properties.Images or Properties.images or {
				["Scary Cat"] = "115002736787206",
			},
			Items = { }
		}
		local Items = { } do
			Items["Section"] = Instances:Create("Frame", {
				Parent = Section.Page.ColumnsData[Section.Side].Instance,
				Name = "\0",
				BorderSizePixel = 0,
				Size = UDim2New(1, 0, 0, 45),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = FromRGB(22, 20, 24)
			}); Items["Section"]:AddToTheme({BackgroundColor3 = "Inline"})
			Instances:Create("UICorner", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5)
			})
			Instances:Create("UIGradient", {
				Parent = Items["Section"].Instance,
				Name = "\0"
			})
			Items["Text"] = Instances:Create("TextLabel", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(255, 255, 255),
				BorderColor3 = FromRGB(0, 0, 0),
				Text = Section.Name,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2New(0, 0, 0, 15),
				BackgroundTransparency = 1,
				Position = UDim2New(0, 8, 0, 8),
				BorderSizePixel = 0,
				ZIndex = 2,
				TextSize = 14,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
			Instances:Create("Frame", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				Size = UDim2New(1, -16, 0, 1),
				Position = UDim2New(0, 8, 0, 28),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(41, 37, 45)
			}):AddToTheme({BackgroundColor3 = "Border"})
			Instances:Create("UIPadding", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				PaddingBottom = UDimNew(0, 8)
			})
			Items["Image"] = Instances:Create("ImageLabel", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				ScaleType = Enum.ScaleType.Fit,
				BorderColor3 = FromRGB(0, 0, 0),
				Size = UDim2New(1, -16, 0, IsMobile and 179 or 279),
				Image = "",
				BackgroundTransparency = 1,
				Position = UDim2New(0, 8, 0, 35),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Section.Items = Items
		end
		local ImagesDropdown, ImagesDropdownItems = Components.Dropdown({
			Name = "Images",
			Parent = Items["Section"],
			Flag = "Images"..Section.Name,
			Items = { },
			Default = nil,
			Multi = false,
			Page = Section.Page,
			Window = Section.Window,
			IsLabelDropdown = false,
			Disabled = false
		})
		ImagesDropdownItems["Dropdown"].Instance.Position = UDim2New(0, 8, 0, Items["Image"].Instance.AbsoluteSize.Y + 46)
		ImagesDropdownItems["Dropdown"].Instance.Size = UDim2New(1, -16, 0, 25)
		for Index, Value in Section.Images do
			ImagesDropdown:Add(Index)
		end

		ImagesDropdown.OnChanged = function(Value)
			local ImageData = Section.Images[Value]
			if not ImageData or not tostring(ImageData):match("%d") then
				Items["Image"].Instance.Image = ""
				return
			end
			Items["Image"].Instance.Image = "rbxassetid://"..ImageData
		end
		return setmetatable(Section, Library.Sections)
	end

	Library.Pages.ViewportSection = function(self, Properties)
		Properties = Properties or { }
		local Section = {
			Window = self.Window,
			Page = self,
			Name = Properties.Name or Properties.name or "Section",
			Side = Properties.Side or Properties.side or 1,
			Part = Properties.Part or Properties.part or nil,
			Items = { }
		}
		local Items = { } do
			Items["Section"] = Instances:Create("TextButton", {
				Parent = Section.Page.ColumnsData[Section.Side].Instance,
				Name = "\0",
				AutoButtonColor = false,
				Text = "",
				BorderSizePixel = 0,
				Size = UDim2New(1, 0, 0, 45),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = FromRGB(22, 20, 24)
			}); Items["Section"]:AddToTheme({BackgroundColor3 = "Inline"})
			Instances:Create("UICorner", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				CornerRadius = UDimNew(0, 5)
			})
			Instances:Create("UIGradient", {
				Parent = Items["Section"].Instance,
				Name = "\0"
			})
			Items["Text"] = Instances:Create("TextLabel", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(255, 255, 255),
				BorderColor3 = FromRGB(0, 0, 0),
				Text = Section.Name,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2New(0, 0, 0, 15),
				BackgroundTransparency = 1,
				Position = UDim2New(0, 8, 0, 8),
				BorderSizePixel = 0,
				ZIndex = 2,
				TextSize = 14,
				BackgroundColor3 = FromRGB(255, 255, 255)
			}); Items["Text"]:AddToTheme({TextColor3 = "Text"})
			Instances:Create("Frame", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				Size = UDim2New(1, -16, 0, 1),
				Position = UDim2New(0, 8, 0, 28),
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(41, 37, 45)
			}):AddToTheme({BackgroundColor3 = "Border"})
			Instances:Create("UIPadding", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				PaddingBottom = UDimNew(0, 8)
			})
			Items["PartViewer"] = Instances:Create("ViewportFrame", {
				Parent = Items["Section"].Instance,
				Name = "\0",
				BorderColor3 = FromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				Position = UDim2New(0, 8, 0, 35),
				Size = UDim2New(1, -16, 0, 225),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
		end
		local ViewportCamera = InstanceNew("Camera")
		Items["PartViewer"].Instance.CurrentCamera = ViewportCamera
		if not (Section.Part and Section.Part:IsA("BasePart")) then
			Section.Part = InstanceNew("Part")
			Section.Part.Name = "ViewportPreview"
			Section.Part.Shape = Enum.PartType.Ball
			Section.Part.Size = Vector3New(2, 2, 2)
			Section.Part.Color = FromRGB(59, 130, 246)
			Section.Part.Material = Enum.Material.SmoothPlastic
		end
		local ClonedPart = Section.Part:Clone()
		ClonedPart.Anchored = true
		ClonedPart.Parent = Items["PartViewer"].Instance
		ClonedPart.Position = Vector3New(0, 5, 0)
		local Distance = MathMax(Section.Part.Size.X, Section.Part.Size.Y, Section.Part.Size.Z) * 3
		ViewportCamera.CFrame = CFrameNew(0, Distance * 0.5, Distance)
		local LastPosition
		local IsRotating = false
		local Sensitivity = 0.7
		Items["PartViewer"]:Connect("InputBegan", function(Input)
			if Input.UserInputType == InputTypeMouseButton1 or Input.UserInputType == InputTypeTouch then
				IsRotating = true
				LastPosition = Input.Position
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						IsRotating = false
						LastPosition = nil
					end
				end)
			end
		end)
		Items["PartViewer"]:Connect("InputChanged", function(Input)
			if Input.UserInputType == InputTypeMouseMovement or Input.UserInputType == InputTypeTouch then
				if not LastPosition then
					return
				end
				if not IsRotating then
					return
				end
				local Delta = Input.Position - LastPosition
				ClonedPart.CFrame = ClonedPart.CFrame * CFrameAngles(0, MathRad(-Delta.X * Sensitivity), 0)
				ClonedPart.CFrame = ClonedPart.CFrame * CFrameAngles(MathRad(Delta.Y * Sensitivity), 0, 0)
				LastPosition = Input.Position
			end
		end)
		return setmetatable(Section, Library.Sections)
	end

	Library.Sections.Toggle = function(self, Properties)
		Properties = Properties or { }
		local Toggle = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Toggle",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or false,
			Callback = Properties.Callback or Properties.callback or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil,
			Count = 0
		}
		local NewToggle, ToggleItems = Components.Toggle({
			Name = Toggle.Name,
			Parent = Toggle.Section.Items["Content"],
			Flag = Toggle.Flag,
			Default = Toggle.Default,
			Page = Toggle.Page,
			Section = Toggle.Section,
			OnChanged = Toggle.OnChanged,
			Callback = Toggle.Callback,
			Disabled = Toggle.Disabled
		})
		ToggleItems["Toggle"]:Tooltip(Toggle.Tooltip)

		function Toggle:Set(Bool)
			NewToggle:Set(Bool)
		end

		function Toggle:SetText(Text)
			NewToggle:SetText(Text)
		end

		function Toggle:SetDisabled(Bool)
			NewToggle:SetDisabled(Bool)
		end

		function Toggle:SetVisible(Bool)
			NewToggle:SetVisible(Bool)
		end

		function Toggle:OnChanged(Callback)
			NewToggle.OnChanged = Callback
			Callback(NewToggle.Value)
		end

		function Toggle:Colorpicker(Properties)
			Properties = Properties or { }
			local Colorpicker = {
				Window = self.Window,
				Page = self.Page,
				Section = self.Section,
				Name = Properties.Name or Properties.name or "Colorpicker",
				Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
				Alpha = Properties.Alpha or Properties.alpha or 0,
				Default = Properties.Default or Properties.default or Color3.fromRGB(255, 255, 255),
				Callback = Properties.Callback or Properties.callback or function() end,
				OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
				Disabled = Properties.Disabled or Properties.disabled or false
			}
			Toggle.Count += 1
			local NewColorpicker, _ColorpickerItems = Components.Colorpicker({
				Name = Colorpicker.Name,
				Count = Toggle.Count,
				Parent = ToggleItems["SubElementsHolder"],
				Flag = Colorpicker.Flag,
				Default = Colorpicker.Default,
				Alpha = Colorpicker.Alpha,
				Page = Colorpicker.Page,
				Section = Colorpicker.Section,
				OnChanged = Colorpicker.OnChanged,
				Window = Colorpicker.Window,
				IsToggle = true,
				Callback = Colorpicker.Callback,
				Disabled = Colorpicker.Disabled
			})
			return NewColorpicker
		end

		function Toggle:Keybind(Properties)
			Properties = Properties or { }
			local Keybind = {
				Window = self.Window,
				Page = self.Page,
				Section = self.Section,
				Name = Properties.Name or Properties.name or "Keybind",
				Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
				Default = Properties.Default or Properties.default or nil,
				Mode = Properties.Mode or Properties.mode or "Toggle",
				Callback = Properties.Callback or Properties.callback or function() end,
				OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			}
			Toggle.Count += 1
			local NewKeybind, _KeybindItems = Components.Keybind({
				Name = Keybind.Name,
				Count = Toggle.Count,
				Parent = ToggleItems["SubElementsHolder"],
				Flag = Keybind.Flag,
				Default = Keybind.Default,
				Mode = Keybind.Mode,
				IsToggle = true,
				Page = Keybind.Page,
				Section = Keybind.Section,
				OnChanged = Keybind.OnChanged,
				Window = Keybind.Window,
				Callback = Keybind.Callback
			})
			return NewKeybind
		end
		return Toggle
	end

	Library.Sections.Checkbox = function(self, Properties)
		Properties = Properties or { }
		local Checkbox = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Checkbox",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or false,
			Callback = Properties.Callback or Properties.callback or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil,
			Count = 0
		}
		local NewCheckbox, CheckboxItems = Components.Checkbox({
			Name = Checkbox.Name,
			Parent = Checkbox.Section.Items["Content"],
			Flag = Checkbox.Flag,
			Default = Checkbox.Default,
			Page = Checkbox.Page,
			Section = Checkbox.Section,
			OnChanged = Checkbox.OnChanged,
			Callback = Checkbox.Callback,
			Disabled = Checkbox.Disabled
		})
		CheckboxItems["Checkbox"]:Tooltip(Checkbox.Tooltip)

		function Checkbox:Set(Bool)
			NewCheckbox:Set(Bool)
		end

		function Checkbox:SetText(Text)
			NewCheckbox:SetText(Text)
		end

		function Checkbox:SetDisabled(Bool)
			NewCheckbox:SetDisabled(Bool)
		end

		function Checkbox:SetVisible(Bool)
			NewCheckbox:SetVisible(Bool)
		end

		function Checkbox:OnChanged(Callback)
			NewCheckbox.OnChanged = Callback
			Callback(NewCheckbox.Value)
		end

		function Checkbox:Colorpicker(Properties)
			Properties = Properties or { }
			local Colorpicker = {
				Window = self.Window,
				Page = self.Page,
				Section = self.Section,
				Name = Properties.Name or Properties.name or "Colorpicker",
				Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
				Alpha = Properties.Alpha or Properties.alpha or 0,
				Default = Properties.Default or Properties.default or Color3.fromRGB(255, 255, 255),
				Callback = Properties.Callback or Properties.callback or function() end,
				OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
				Disabled = Properties.Disabled or Properties.disabled or false
			}
			Checkbox.Count += 1
			local NewColorpicker, _ColorpickerItems = Components.Colorpicker({
				Name = Colorpicker.Name,
				Count = Checkbox.Count,
				Parent = CheckboxItems["SubElementsHolder"],
				Flag = Colorpicker.Flag,
				Default = Colorpicker.Default,
				Alpha = Colorpicker.Alpha,
				Page = Colorpicker.Page,
				Section = Colorpicker.Section,
				OnChanged = Colorpicker.OnChanged,
				Window = Colorpicker.Window,
				IsCheckbox = true,
				Callback = Colorpicker.Callback,
				Disabled = Colorpicker.Disabled
			})
			return NewColorpicker
		end

		function Checkbox:Keybind(Properties)
			Properties = Properties or { }
			local Keybind = {
				Window = self.Window,
				Page = self.Page,
				Section = self.Section,
				Name = Properties.Name or Properties.name or "Keybind",
				Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
				Default = Properties.Default or Properties.default or nil,
				Mode = Properties.Mode or Properties.mode or "Toggle",
				Callback = Properties.Callback or Properties.callback or function() end,
				OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			}
			Checkbox.Count += 1
			local NewKeybind, _KeybindItems = Components.Keybind({
				Name = Keybind.Name,
				Count = Checkbox.Count,
				Parent = CheckboxItems["SubElementsHolder"],
				Flag = Keybind.Flag,
				Default = Keybind.Default,
				Mode = Keybind.Mode,
				IsCheckbox = true,
				Page = Keybind.Page,
				Section = Keybind.Section,
				OnChanged = Keybind.OnChanged,
				Window = Keybind.Window,
				Callback = Keybind.Callback
			})
			return NewKeybind
		end
		return Checkbox, NewCheckbox
	end

	Library.Sections.Button = function(self, Properties)
		Properties = Properties or { }
		local Button = {
			Window = self.Window,
			Page = self.Page,
			Section = self
		}
		local NewButton, _ButtonItems = Components.Button({
			Parent = Button.Section.Items["Content"],
			Page = Button.Page,
		})

		function Button:Add(Text, Callback, Confirmation, Disabled, Tooltip)
			local _NewButton = {
				Text = Text,
				Callback = Callback,
				Confirmation = Confirmation,
				Disabled = Disabled
			}
			local NewAddedButton, NewAddedButtonItems = NewButton:Add(Text, Callback, Confirmation, Disabled)
			NewAddedButtonItems["NewButton"]:Tooltip(Tooltip)
			function _NewButton:SetText(Text)
				NewAddedButton:SetText(Text)
			end
			function _NewButton:SetVisible(Bool)
				NewAddedButton:SetVisible(Bool)
			end
			function _NewButton:SetDisabled(Bool)
				NewAddedButton:SetDisabled(Bool)
			end
			function _NewButton:OnPressed(Callback)
				NewAddedButton.OnPressed = Callback
				Callback()
			end
			function _NewButton:Add(Text, Callback, Confirmation, Disabled, Tooltip)
				return Button:Add(Text, Callback, Confirmation, Disabled, Tooltip)
			end
			return _NewButton
		end

		function Button:SetVisible(Bool)
			NewButton:SetVisible(Bool)
		end
		return Button
	end

	Library.Sections.Slider = function(self, Properties)
		Properties = Properties or { }
		local Slider = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Slider",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or 0,
			Min = Properties.Min or Properties.min or 0,
			Max = Properties.Max or Properties.max or 100,
			Decimals = Properties.Decimals or Properties.decimals or 1,
			Step = Properties.Step or Properties.step or 0,
			Format = Properties.Format or Properties.format or nil,
			Suffix = Properties.Suffix or Properties.suffix or "",
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewSlider, SliderItems = Components.Slider({
			Name = Slider.Name,
			Parent = Slider.Section.Items["Content"],
			Flag = Slider.Flag,
			Default = Slider.Default,
			Min = Slider.Min,
			Max = Slider.Max,
			Suffix = Slider.Suffix,
			Decimals = Slider.Decimals,
			Step = Slider.Step,
			Format = Slider.Format,
			Page = Slider.Page,
			Section = Slider.Section,
			OnChanged = Slider.OnChanged,
			Callback = Slider.Callback,
			Disabled = Slider.Disabled
		})
		SliderItems["Slider"]:Tooltip(Slider.Tooltip)

		function Slider:Set(Value)
			NewSlider:Set(Value)
		end

		function Slider:SetDisabled(Bool)
			NewSlider:SetDisabled(Bool)
		end

		function Slider:SetVisible(Bool)
			NewSlider:SetVisible(Bool)
		end

		function Slider:SetMin(Value)
			NewSlider:SetMin(Value)
		end

		function Slider:SetMax(Value)
			NewSlider:SetMax(Value)
		end

		function Slider:SetStep(Value)
			NewSlider:SetStep(Value)
		end

		function Slider:SetFormat(Value)
			NewSlider:SetFormat(Value)
		end

		function Slider:OnChanged(Callback)
			NewSlider.OnChanged = Callback
			Callback(NewSlider.Value)
		end

		function Slider:SetSuffix(Text)
			NewSlider:SetSuffix(Text)
		end

		function Slider:SetText(Text)
			NewSlider:SetText(Text)
		end
		return Slider
	end

	Library.Sections.Dropdown = function(self, Properties)
		Properties = Properties or { }
		local Dropdown = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Dropdown",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or nil,
			Items = Properties.Items or Properties.items or { },
			Callback = Properties.Callback or Properties.callback or function() end,
			Multi = Properties.Multi or Properties.multi or false,
			Search = Properties.Search or Properties.search or false,
			SearchPlaceholder = Properties.SearchPlaceholder or Properties.searchplaceholder or "Search..",
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			IsLabelDropdown = Properties.IsLabelDropdown or Properties.islabeldropdown or false,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewDropdown, DropdownItems = Components.Dropdown({
			Name = Dropdown.Name,
			Parent = Dropdown.Section.Items["Content"],
			Flag = Dropdown.Flag,
			Items = Dropdown.Items,
			Default = Dropdown.Default,
			Callback = Dropdown.Callback,
			Multi = Dropdown.Multi,
			Search = Dropdown.Search,
			SearchPlaceholder = Dropdown.SearchPlaceholder,
			Page = Dropdown.Page,
			Window = Dropdown.Window,
			IsLabelDropdown = Dropdown.IsLabelDropdown,
			OnChanged = Dropdown.OnChanged,
			Disabled = Dropdown.Disabled
		})
		DropdownItems["Dropdown"]:Tooltip(Dropdown.Tooltip)

		function Dropdown:Set(Items)
			NewDropdown:Set(Items)
		end

		function Dropdown:OnChanged(Callback)
			NewDropdown.OnChanged = Callback
			Callback(NewDropdown.Value)
		end

		function Dropdown:Remove(Option)
			NewDropdown:Remove(Option)
		end

		function Dropdown:Add(Option, Icon)
			NewDropdown:Add(Option, Icon)
		end

		function Dropdown:Clear()
			NewDropdown:Clear()
		end

		function Dropdown:SetDisabled(Bool)
			NewDropdown:SetDisabled(Bool)
		end

		function Dropdown:SetVisible(Bool)
			NewDropdown:SetVisible(Bool)
		end

		function Dropdown:Refresh(List)
			NewDropdown:Refresh(List)
		end

		function Dropdown:Get()
			return NewDropdown:Get()
		end

		function Dropdown:SetText(Text)
			NewDropdown:SetText(Text)
		end

		function Dropdown:SetMulti(Bool)
			NewDropdown:SetMulti(Bool)
		end
		return Dropdown
	end

	Library.Sections.ToggleDropdown = function(self, Properties)
		Properties = Properties or { }
		local Dropdown = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Dropdown",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or nil,
			Items = Properties.Items or Properties.items or { },
			Callback = Properties.Callback or Properties.callback or function() end,
			Multi = Properties.Multi or Properties.multi or false,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewDropdown, DropdownItems = Components.ToggleDropdown({
			Name = Dropdown.Name,
			Parent = Dropdown.Section.Items["Content"],
			Flag = Dropdown.Flag,
			Items = Dropdown.Items,
			Default = Dropdown.Default,
			Callback = Dropdown.Callback,
			Multi = Dropdown.Multi,
			Page = Dropdown.Page,
			Window = Dropdown.Window,
			OnChanged = Dropdown.OnChanged,
			Disabled = Dropdown.Disabled
		})
		DropdownItems["Dropdown"]:Tooltip(Dropdown.Tooltip)

		function Dropdown:Set(Items)
			NewDropdown:Set(Items)
		end

		function Dropdown:OnChanged(Callback)
			NewDropdown.OnChanged = Callback
			Callback(NewDropdown.Value)
		end

		function Dropdown:Remove(Option)
			NewDropdown:Remove(Option)
		end

		function Dropdown:Add(Option, Icon)
			NewDropdown:Add(Option, Icon)
		end

		function Dropdown:Clear()
			NewDropdown:Clear()
		end

		function Dropdown:SetDisabled(Bool)
			NewDropdown:SetDisabled(Bool)
		end

		function Dropdown:SetVisible(Bool)
			NewDropdown:SetVisible(Bool)
		end

		function Dropdown:Refresh(List)
			NewDropdown:Refresh(List)
		end

		function Dropdown:Get()
			return NewDropdown:Get()
		end

		function Dropdown:SetText(Text)
			NewDropdown:SetText(Text)
		end

		function Dropdown:SetMulti(Bool)
			NewDropdown:SetMulti(Bool)
		end
		return Dropdown
	end

	Library.Sections.AnimatedText = function(self, Properties)
		Properties = Properties or { }
		if type(Properties) == "string" then
			Properties = { Text = Properties }
		end
		local NewAnim, _AnimItems = Components.AnimatedText({
			Name = Properties.Name or Properties.Text or "Animated Text",
			Parent = self.Items["Content"],
			Text = Properties.Text,
			Texts = Properties.Texts or Properties.texts or Properties.Items,
			Type = Properties.Type or Properties.type or "Typing",
			Speed = Properties.Speed or Properties.speed or 1,
			Color = Properties.Color or Properties.color,
			Font = Properties.Font or Properties.font,
			TextSize = Properties.TextSize or Properties.textsize or 13,
			Alignment = Properties.Alignment or Properties.alignment or "Left",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag()
		})
		return NewAnim
	end

	Library.Sections.Label = function(self, Text, Alignment, Tooltip, Outline)
		local Label = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Text or "Label",
			Alignment = Alignment or "Left",
			Tooltip = Tooltip or nil,
			Count = 0
		}
		local Items = {} do
			Items["Label"] = Instances:Create("Frame", {
				Parent = Label.Section.Items["Content"].Instance,
				Name = "\0",
				BackgroundTransparency = 1,
				Size = UDim2New(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BorderColor3 = FromRGB(0, 0, 0),
				ZIndex = 2,
				BorderSizePixel = 0,
				BackgroundColor3 = FromRGB(255, 255, 255)
			})
			Items["Label"]:Tooltip(Label.Tooltip)
			Items["Text"] = Instances:Create("TextLabel", {
				Parent = Items["Label"].Instance,
				Name = "\0",
				FontFace = Library.Font,
				TextColor3 = FromRGB(255, 255, 255),
				BorderColor3 = FromRGB(0, 0, 0),
				Text = Label.Name,
				TextXAlignment = Enum.TextXAlignment[Label.Alignment],
				TextYAlignment = Enum.TextYAlignment.Top,
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				AnchorPoint = Vector2New(0, 0),
				Size = UDim2New(1, 0, 0, 0),
				RichText = true,
				BackgroundTransparency = 1,
				Position = UDim2New(0, 0, 0, 0),
				BorderSizePixel = 0,
				ZIndex = 2,
				TextSize = 14,
				BackgroundColor3 = FromRGB(255, 0, 255)
			})
			Items["Text"]:AddToTheme({ TextColor3 = "Text" })
			if Outline then
				Instances:Create("UIStroke", {
					Parent = Items["Text"].Instance,
					Name = "\0",
					ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
					LineJoinMode = Enum.LineJoinMode.Round,
					Color = FromRGB(0, 0, 0),
					Thickness = 1
				})
			end
		end

		function Label:Colorpicker(Properties)
			Properties = Properties or { }
			local Colorpicker = {
				Window = self.Window,
				Page = self.Page,
				Section = self.Section,
				Name = Properties.Name or Properties.name or "Colorpicker",
				Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
				Alpha = Properties.Alpha or Properties.alpha or 0,
				Default = Properties.Default or Properties.default or Color3.fromRGB(255, 255, 255),
				Callback = Properties.Callback or Properties.callback or function() end,
				OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
				Disabled = Properties.Disabled or Properties.disabled or false
			}
			Label.Count += 1
			local NewColorpicker, _ColorpickerItems = Components.Colorpicker({
				Name = Colorpicker.Name,
				Count = Label.Count,
				Parent = Items["Label"],
				Flag = Colorpicker.Flag,
				Default = Colorpicker.Default,
				Alpha = Colorpicker.Alpha,
				Page = Colorpicker.Page,
				Section = Colorpicker.Section,
				OnChanged = Colorpicker.OnChanged,
				Window = Colorpicker.Window,
				Callback = Colorpicker.Callback,
				Disabled = Colorpicker.Disabled
			})
			return NewColorpicker
		end

		function Label:Keybind(Properties)
			Properties = Properties or { }
			local Keybind = {
				Window = self.Window,
				Page = self.Page,
				Section = self.Section,
				Name = Properties.Name or Properties.name or "Keybind",
				Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
				Default = Properties.Default or Properties.default or nil,
				Mode = Properties.Mode or Properties.mode or "Toggle",
				Callback = Properties.Callback or Properties.callback or function() end,
				OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			}
			Label.Count += 1
			local NewKeybind, _KeybindItems = Components.Keybind({
				Name = Keybind.Name,
				Count = Label.Count,
				Parent = Items["Label"],
				Flag = Keybind.Flag,
				Default = Keybind.Default,
				Mode = Keybind.Mode,
				Page = Keybind.Page,
				Section = Keybind.Section,
				OnChanged = Keybind.OnChanged,
				Window = Keybind.Window,
				Callback = Keybind.Callback
			})
			return NewKeybind
		end

		function Label:SetText(Text)
			Text = tostring(Text)
			Items["Text"].Instance.Text = Text
		end

		function Label:SetTextColor(Color)
			Library:RemoveFromTheme(Items["Text"])
			task.wait(0.1)
			Items["Text"].Instance.TextColor3 = Color
		end
		local SearchData = {
			Name = Label.Name,
			Item = Items["Label"]
		}
		local PageSearchData = Library.SearchItems[Label.Page]
		if PageSearchData then
	TableInsert(PageSearchData, SearchData)
		end
		return Label
	end

	Library.Sections.Textbox = function(self, Properties)
		Properties = Properties or { }
		local Textbox = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Textbox",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or "",
			Placeholder = Properties.Placeholder or Properties.placeholder or "",
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewTextbox, TextboxItems = Components.Textbox({
			Name = Textbox.Name,
			Flag = Textbox.Flag,
			Default = Textbox.Default,
			Parent = Textbox.Section.Items["Content"],
			Placeholder = Textbox.Placeholder,
			Page = Textbox.Page,
			Section = Textbox.Section,
			OnChanged = Textbox.OnChanged,
			Window = Textbox.Window,
			Callback = Textbox.Callback,
			Disabled = Textbox.Disabled
		})
		TextboxItems["Textbox"]:Tooltip(Textbox.Tooltip)

		function Textbox:Set(Value)
			NewTextbox:Set(Value)
		end

		function Textbox:SetText(Text)
			NewTextbox:SetText(Text)
		end

		function Textbox:SetDisabled(Bool)
			NewTextbox:SetDisabled(Bool)
		end

		function Textbox:SetVisible(Bool)
			NewTextbox:SetVisible(Bool)
		end
		return Textbox
	end

	Library.Sections.MultilineTextbox = function(self, Properties)
		Properties = Properties or { }
		local Textbox = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Textbox",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or "",
			Placeholder = Properties.Placeholder or Properties.placeholder or "",
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewTextbox, TextboxItems = Components.MultilineTextbox({
			Name = Textbox.Name,
			Flag = Textbox.Flag,
			Default = Textbox.Default,
			Parent = Textbox.Section.Items["Content"],
			Placeholder = Textbox.Placeholder,
			Page = Textbox.Page,
			Section = Textbox.Section,
			OnChanged = Textbox.OnChanged,
			Window = Textbox.Window,
			Callback = Textbox.Callback,
			Disabled = Textbox.Disabled
		})
		TextboxItems["Textbox"]:Tooltip(Textbox.Tooltip)

		function Textbox:Set(Value)
			NewTextbox:Set(Value)
		end

		function Textbox:GetValue()
			return NewTextbox:GetValue()
		end

		function Textbox:SetText(Text)
			NewTextbox:SetText(Text)
		end

		function Textbox:SetDisabled(Bool)
			NewTextbox:SetDisabled(Bool)
		end

		function Textbox:SetVisible(Bool)
			NewTextbox:SetVisible(Bool)
		end
		return Textbox
	end

	Library.Sections.Segmented = function(self, Properties)
		Properties = Properties or { }
		local Options = Properties.Items or Properties.items or { }
		if #Options == 0 then
			return
		end
		local Segmented = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Segmented",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or Options[1],
			Items = Options,
			HideName = Properties.HideName or Properties.hidename or false,
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewSegmented, SegmentedItems = Components.Segmented({
			Name = Segmented.Name,
			Flag = Segmented.Flag,
			Default = Segmented.Default,
			Items = Segmented.Items,
			HideName = Segmented.HideName,
			Parent = Segmented.Section.Items["Content"],
			Page = Segmented.Page,
			Section = Segmented.Section,
			OnChanged = Segmented.OnChanged,
			Window = Segmented.Window,
			Callback = Segmented.Callback,
			Disabled = Segmented.Disabled
		})
		SegmentedItems["Segmented"]:Tooltip(Segmented.Tooltip)

		function Segmented:Set(Value)
			NewSegmented:Set(Value)
		end

		function Segmented:GetValue()
			return NewSegmented:GetValue()
		end

		function Segmented:SetText(Text)
			NewSegmented:SetText(Text)
		end

		function Segmented:SetDisabled(Bool)
			NewSegmented:SetDisabled(Bool)
		end

		function Segmented:SetVisible(Bool)
			NewSegmented:SetVisible(Bool)
		end
		return Segmented
	end

	Library.Sections.HoldButton = function(self, Properties)
		Properties = Properties or { }
		local HoldButton = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Hold",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Duration = Properties.Duration or Properties.duration or 1,
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewHoldButton, HoldButtonItems = Components.HoldButton({
			Name = HoldButton.Name,
			Flag = HoldButton.Flag,
			Duration = HoldButton.Duration,
			Parent = HoldButton.Section.Items["Content"],
			Page = HoldButton.Page,
			Section = HoldButton.Section,
			OnChanged = HoldButton.OnChanged,
			Window = HoldButton.Window,
			Callback = HoldButton.Callback,
			Disabled = HoldButton.Disabled
		})
		HoldButtonItems["HoldButton"]:Tooltip(HoldButton.Tooltip)

		function HoldButton:SetText(Text)
			NewHoldButton:SetText(Text)
		end

		function HoldButton:SetDuration(Value)
			NewHoldButton:SetDuration(Value)
		end

		function HoldButton:SetDisabled(Bool)
			NewHoldButton:SetDisabled(Bool)
		end

		function HoldButton:SetVisible(Bool)
			NewHoldButton:SetVisible(Bool)
		end
		return HoldButton
	end

	Library.Sections.Accordion = function(self, Properties)
		Properties = Properties or { }
		local Accordion = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Accordion",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or false,
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewAccordion, AccordionItems = Components.Accordion({
			Name = Accordion.Name,
			Flag = Accordion.Flag,
			Default = Accordion.Default,
			Parent = Accordion.Section.Items["Content"],
			Page = Accordion.Page,
			Section = Accordion.Section,
			OnChanged = Accordion.OnChanged,
			Window = Accordion.Window,
			Callback = Accordion.Callback,
			Disabled = Accordion.Disabled
		})
		AccordionItems["Header"]:Tooltip(Accordion.Tooltip)
		do
			local SubSection = {
				Window = self.Window,
				Page = self.Page,
				Section = self,
				Name = Accordion.Name,
				Flag = Accordion.Flag,
				Items = { Content = AccordionItems["Content"] }
			}
			setmetatable(SubSection, Library.Sections)
			local Delegated = {
				"Toggle", "Checkbox", "Button", "Slider", "Dropdown", "ToggleDropdown",
				"AnimatedText", "Label", "Textbox", "MultilineTextbox", "Segmented", "HoldButton", "Accordion",
				"RangeSlider", "RadioList", "NumberInput", "Progress", "Listbox", "Group"
			}
			for Index, Key in ipairs(Delegated) do
				local Method = Library.Sections[Key]
				if Method then
					Accordion[Key] = function(_, ...)
						return Method(SubSection, ...)
					end
				end
			end
		end

		function Accordion:Set(Value)
			NewAccordion:Set(Value)
		end

		function Accordion:Expand(Bool)
			NewAccordion:Expand(Bool)
		end

		function Accordion:Collapse()
			NewAccordion:Collapse()
		end

		function Accordion:SetText(Text)
			NewAccordion:SetText(Text)
		end

		function Accordion:SetDisabled(Bool)
			NewAccordion:SetDisabled(Bool)
		end

		function Accordion:SetVisible(Bool)
			NewAccordion:SetVisible(Bool)
		end
		return Accordion
	end

	Library.Sections.RangeSlider = function(self, Properties)
		Properties = Properties or { }
		local RangeSlider = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Range",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or nil,
			Min = Properties.Min or Properties.min or 0,
			Max = Properties.Max or Properties.max or 100,
			Step = Properties.Step or Properties.step or 0,
			Decimals = Properties.Decimals or Properties.decimals or 0,
			Format = Properties.Format or Properties.format or nil,
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewRangeSlider, RangeSliderItems = Components.RangeSlider({
			Name = RangeSlider.Name,
			Parent = RangeSlider.Section.Items["Content"],
			Flag = RangeSlider.Flag,
			Default = RangeSlider.Default,
			Min = RangeSlider.Min,
			Max = RangeSlider.Max,
			Step = RangeSlider.Step,
			Decimals = RangeSlider.Decimals,
			Format = RangeSlider.Format,
			Page = RangeSlider.Page,
			Section = RangeSlider.Section,
			OnChanged = RangeSlider.OnChanged,
			Window = RangeSlider.Window,
			Callback = RangeSlider.Callback,
			Disabled = RangeSlider.Disabled
		})
		RangeSliderItems["RangeSlider"]:Tooltip(RangeSlider.Tooltip)

		function RangeSlider:Set(Low, High)
			NewRangeSlider:Set(Low, High)
		end

		function RangeSlider:Get()
			return NewRangeSlider:Get()
		end

		function RangeSlider:SetText(Text)
			NewRangeSlider:SetText(Text)
		end

		function RangeSlider:SetDisabled(Bool)
			NewRangeSlider:SetDisabled(Bool)
		end

		function RangeSlider:SetVisible(Bool)
			NewRangeSlider:SetVisible(Bool)
		end
		return RangeSlider
	end

	Library.Sections.RadioList = function(self, Properties)
		Properties = Properties or { }
		local Options = Properties.Items or Properties.items or { }
		if #Options == 0 then
			return
		end
		local RadioList = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Options",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or Options[1],
			Items = Options,
			HideName = Properties.HideName or Properties.hidename or false,
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewRadioList, RadioListItems = Components.RadioList({
			Name = RadioList.Name,
			Parent = RadioList.Section.Items["Content"],
			Flag = RadioList.Flag,
			Default = RadioList.Default,
			Items = RadioList.Items,
			HideName = RadioList.HideName,
			Page = RadioList.Page,
			Section = RadioList.Section,
			OnChanged = RadioList.OnChanged,
			Window = RadioList.Window,
			Callback = RadioList.Callback,
			Disabled = RadioList.Disabled
		})
		RadioListItems["RadioList"]:Tooltip(RadioList.Tooltip)

		function RadioList:Set(Value)
			NewRadioList:Set(Value)
		end

		function RadioList:Get()
			return NewRadioList:Get()
		end

		function RadioList:SetText(Text)
			NewRadioList:SetText(Text)
		end

		function RadioList:SetDisabled(Bool)
			NewRadioList:SetDisabled(Bool)
		end

		function RadioList:SetVisible(Bool)
			NewRadioList:SetVisible(Bool)
		end
		return RadioList
	end

	Library.Sections.NumberInput = function(self, Properties)
		Properties = Properties or { }
		local NumberInput = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Number",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or 0,
			Min = Properties.Min or Properties.min or 0,
			Max = Properties.Max or Properties.max or 100,
			Step = Properties.Step or Properties.step or 1,
			Decimals = Properties.Decimals or Properties.decimals or 0,
			Wrap = Properties.Wrap or Properties.wrap or false,
			Format = Properties.Format or Properties.format or nil,
			HideName = Properties.HideName or Properties.hidename or false,
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Disabled = Properties.Disabled or Properties.disabled or false,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewNumberInput, NumberInputItems = Components.NumberInput({
			Name = NumberInput.Name,
			Parent = NumberInput.Section.Items["Content"],
			Flag = NumberInput.Flag,
			Default = NumberInput.Default,
			Min = NumberInput.Min,
			Max = NumberInput.Max,
			Step = NumberInput.Step,
			Decimals = NumberInput.Decimals,
			Wrap = NumberInput.Wrap,
			Format = NumberInput.Format,
			HideName = NumberInput.HideName,
			Page = NumberInput.Page,
			Section = NumberInput.Section,
			OnChanged = NumberInput.OnChanged,
			Window = NumberInput.Window,
			Callback = NumberInput.Callback,
			Disabled = NumberInput.Disabled
		})
		NumberInputItems["NumberInput"]:Tooltip(NumberInput.Tooltip)

		function NumberInput:Set(Value)
			NewNumberInput:Set(Value)
		end

		function NumberInput:Get()
			return NewNumberInput:Get()
		end

		function NumberInput:Increment()
			NewNumberInput:Increment()
		end

		function NumberInput:Decrement()
			NewNumberInput:Decrement()
		end

		function NumberInput:SetText(Text)
			NewNumberInput:SetText(Text)
		end

		function NumberInput:SetDisabled(Bool)
			NewNumberInput:SetDisabled(Bool)
		end

		function NumberInput:SetVisible(Bool)
			NewNumberInput:SetVisible(Bool)
		end
		return NumberInput
	end

	Library.Sections.Progress = function(self, Properties)
		Properties = Properties or { }
		local Progress = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Progress",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or 0,
			Max = Properties.Max or Properties.max or 100,
			Prefix = Properties.Prefix or Properties.prefix or "",
			Suffix = Properties.Suffix or Properties.suffix or "",
			HideName = Properties.HideName or Properties.hidename or false,
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewProgress, ProgressItems = Components.Progress({
			Name = Progress.Name,
			Parent = Progress.Section.Items["Content"],
			Flag = Progress.Flag,
			Default = Progress.Default,
			Max = Progress.Max,
			Prefix = Progress.Prefix,
			Suffix = Progress.Suffix,
			HideName = Progress.HideName,
			Page = Progress.Page,
			Section = Progress.Section,
			OnChanged = Progress.OnChanged,
			Window = Progress.Window,
			Callback = Progress.Callback
		})
		ProgressItems["Progress"]:Tooltip(Progress.Tooltip)

		function Progress:Set(Value)
			NewProgress:Set(Value)
		end

		function Progress:Get()
			return NewProgress:Get()
		end

		function Progress:SetMax(Value)
			NewProgress:SetMax(Value)
		end

		function Progress:SetText(Text)
			NewProgress:SetText(Text)
		end

		function Progress:SetVisible(Bool)
			NewProgress:SetVisible(Bool)
		end
		return Progress
	end

	Library.Sections.Listbox = function(self, Properties)
		Properties = Properties or { }
		local Listbox = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "List",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or nil,
			Items = Properties.Items or Properties.items or { },
			Multi = Properties.Multi or Properties.multi or false,
			Rows = Properties.Rows or Properties.rows or 4,
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end,
			Tooltip = Properties.Tooltip or Properties.tooltip or nil
		}
		local NewListbox, ListboxItems = Components.Listbox({
			Name = Listbox.Name,
			Parent = Listbox.Section.Items["Content"],
			Flag = Listbox.Flag,
			Items = Listbox.Items,
			Multi = Listbox.Multi,
			Rows = Listbox.Rows,
			Page = Listbox.Page,
			Section = Listbox.Section,
			OnChanged = Listbox.OnChanged,
			Window = Listbox.Window,
			Callback = Listbox.Callback
		})
		ListboxItems["Listbox"]:Tooltip(Listbox.Tooltip)

		function Listbox:Add(Name, Icon)
			return NewListbox:Add(Name, Icon)
		end

		function Listbox:Remove(Name)
			NewListbox:Remove(Name)
		end

		function Listbox:Clear()
			NewListbox:Clear()
		end

		function Listbox:Refresh(List)
			NewListbox:Refresh(List)
		end

		function Listbox:Set(Name)
			NewListbox:Set(Name)
		end

		function Listbox:Get()
			return NewListbox:Get()
		end

		function Listbox:SetText(Text)
			NewListbox:SetText(Text)
		end

		function Listbox:SetVisible(Bool)
			NewListbox:SetVisible(Bool)
		end
		return Listbox
	end

	Library.Sections.SetExpanded = function(self, Bool)
		local SectionItems = self.Items
		if not SectionItems or not SectionItems["Content"] then
			return
		end
		self.Expanded = not not Bool
		local Visible = self.Expanded
		if SectionItems["Content"].Instance then
			SectionItems["Content"].Instance.Visible = Visible
		end
		if SectionItems["Liner"] and SectionItems["Liner"].Instance then
			SectionItems["Liner"].Instance.Visible = Visible
		end
		if SectionItems["Indicator"] and SectionItems["Indicator"].Instance then
			SectionItems["Indicator"].Instance.Text = Visible and "v" or ">"
		end
		if self.Callback then
			Library:SafeCall(self.Callback, Visible)
		end
	end

	Library.Sections.Expand = function(self, Bool)
		if Bool == nil then
			self:SetExpanded(true)
		else
			self:SetExpanded(Bool)
		end
	end

	Library.Sections.Collapse = function(self)
		self:SetExpanded(false)
	end

	Library.Sections.ToggleExpanded = function(self)
		self:SetExpanded(not self.Expanded)
	end

	Library.Sections.Group = function(self, Properties)
		Properties = Properties or { }
		local Group = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Properties.Name or Properties.name or "Group",
			Flag = Properties.Flag or Properties.flag or Library:NextFlag(),
			Default = Properties.Default or Properties.default or nil,
			Callback = Properties.Callback or Properties.callback or function() end,
			OnChanged = Properties.OnChanged or Properties.onchanged or function() end
		}
		local NewGroup, GroupItems = Components.Group({
			Name = Group.Name,
			Parent = Group.Section.Items["Content"],
			Flag = Group.Flag,
			Default = Group.Default,
			Page = Group.Page,
			Section = Group.Section,
			Callback = Group.Callback
		})
		local SubSection = {
			Window = self.Window,
			Page = self.Page,
			Section = self,
			Name = Group.Name,
			Flag = Group.Flag,
			Items = { Content = GroupItems["Group"] }
		}
		setmetatable(SubSection, Library.Sections)
		local Delegated = {
			"Toggle", "Checkbox", "Button", "Slider", "Dropdown", "ToggleDropdown",
			"Label", "Textbox", "MultilineTextbox", "Segmented", "HoldButton", "Accordion",
			"RangeSlider", "RadioList", "NumberInput", "Progress", "Listbox", "Group"
		}
		for Index, Key in ipairs(Delegated) do
			local Method = Library.Sections[Key]
			if Method then
				Group[Key] = function(_, ...)
					local Element = Method(SubSection, ...)
					NewGroup:Add(Element, Key)
					return Element
				end
			end
		end

		function Group:SetVisible(Bool)
			NewGroup:SetVisible(Bool)
			Group.Visible = NewGroup.Visible
		end

		function Group:SetDisabled(Bool)
			NewGroup:SetDisabled(Bool)
		end
		Group.Visible = NewGroup.Visible
		return Group
	end

	Library.CheckForAutoLoad = function(self)
		local Config = FS.Read(JoinPath(self.Folders.Directory, "autoload.json"))
		if not Config or Config == "" then
			return
		end
		local Success, _Error = Library:LoadConfig(Config)
		if Success then
			Library:Notification("Success!", "Succesfully autoloaded config.", 5)
			task.wait(0.3)
			Library:Thread(function()
				for Index, Value in Library.Theme do
					Library.Theme[Index] = Library.Flags["Theme" .. Index].Color
					Library:ChangeTheme(Index, Library.Flags["Theme" .. Index].Color)
				end
			end)
		else
			Library:Notification("Error!", "Failed to load config.", 5)
		end
	end

	Library.CreateSettingsPage = function(self, Window, Watermark, KeybindList)
		local SettingsPage = Window:Page({
			Name = "Settings",
			Columns = 2
		})
		do
			do
				do
					local ConfigsSection = SettingsPage:Section({Name = "Configs", Side = 2})
					local ConfigSelected
					local ConfigName
					do
						local ConfigsDropdown = ConfigsSection:Dropdown({
							Name = "Configs",
							Flag = "ConfigsList",
							Items = { },
							Multi = false,
							Callback = function(Value)
								ConfigSelected = Value
							end
						})
						ConfigsSection:Textbox({
							Name = "Name",
							Default = "",
							Flag = "ConfigName",
							Placeholder = "...",
							Callback = function(Value)
								ConfigName = Value
							end
						})
						local CreateDeleteButton = ConfigsSection:Button()
					CreateDeleteButton:Add("Create", function()
						if ConfigName and ConfigName ~= "" then
							local Success, Error = Library:SaveConfig(ConfigName)
							if Success then
								Library:RefreshConfigsList(ConfigsDropdown)
							else
								Library:Notification("Error!", "Failed to create config:\n" .. tostring(Error), 5, "Error")
							end
						else
							Library:Notification("Configs", "Type a name in the Name box first.", 3, "Warning")
						end
					end, false)
						CreateDeleteButton:Add("Delete", function()
							if ConfigSelected then
								local CurrentConfigName = string.gsub(ConfigSelected, ".json", "")
								CurrentConfigName ..= "" .. game.GameId .. ".json"
								Library:DeleteConfig(CurrentConfigName)
								Library:RefreshConfigsList(ConfigsDropdown)
							end
						end, false)
						local LoadSaveButton = ConfigsSection:Button()
						LoadSaveButton:Add("Load", function()
							if ConfigSelected then
								local CurrentConfigName = string.gsub(ConfigSelected, ".json", "")
								CurrentConfigName ..= "" .. game.GameId .. ".json"
								local Success, Result = Library:LoadConfig(FS.Read(JoinPath(Library.Folders.Configs, CurrentConfigName)) or "")
								if Success then
									Library:Notification("Success!", "Succesfully loaded config.", 5)
									task.wait(0.3)
									Library:Thread(function()
										for Index, Value in Library.Theme do
											Library.Theme[Index] = Library.Flags["Theme" .. Index].Color
											Library:ChangeTheme(Index, Library.Flags["Theme" .. Index].Color)
										end
									end)
								else
									Library:Notification("Error!", "Failed to load config. Report this to the developers:\n"..Result, 5)
								end
							end
						end, false)
					LoadSaveButton:Add("Save", function()
						if ConfigSelected then
							local CurrentConfigName = string.gsub(ConfigSelected, ".json", "")
							Library:SaveConfig(CurrentConfigName)
						else
							Library:Notification("Configs", "Select a config first.", 3, "Warning")
						end
					end, false)
					local RefreshlistButton = ConfigsSection:Button()
					RefreshlistButton:Add("Refresh", function()
						Library:RefreshConfigsList(ConfigsDropdown)
					end, false)
					local TransferButton = ConfigsSection:Button()
					TransferButton:Add("Rename", function()
						if not ConfigSelected then
							Library:Notification("Configs", "Select a config first.", 3, "Warning")
							return
						end
						if not ConfigName or ConfigName == "" then
							Library:Notification("Configs", "Type a new name in the Name box first.", 3, "Warning")
							return
						end
						local OldName = string.gsub(ConfigSelected, ".json", "")
						local Success, Error = Library:RenameConfig(OldName, ConfigName)
						if Success then
							Library:Notification("Success!", 'Renamed "' .. OldName .. '" to "' .. tostring(ConfigName) .. '".', 5, "Success")
							Library:RefreshConfigsList(ConfigsDropdown)
						else
							Library:Notification("Error!", "Failed to rename config:\n" .. tostring(Error), 5, "Error")
						end
					end, false)
					TransferButton:Add("Copy", function()
						if not ConfigSelected then
							Library:Notification("Configs", "Select a config first.", 3, "Warning")
							return
						end
						local Path = Library:ConfigPath(string.gsub(ConfigSelected, ".json", ""))
						if not FS.IsFile(Path) then
							Library:Notification("Error!", "Could not find that config.", 3, "Error")
							return
						end
						local Success, Error = Library:CopyToClipboard(FS.Read(Path) or "")
						if Success then
							Library:Notification("Success!", "Config copied to clipboard.", 5, "Success")
						else
							Library:Notification("Error!", tostring(Error), 5, "Error")
						end
					end, false)
					TransferButton:Add("Paste", function()
						local Data, Error = Library:PasteFromClipboard()
						if not Data or Data == "" then
							Library:Notification("Error!", tostring(Error or "Clipboard is empty."), 5, "Error")
							return
						end
						local Success, Result = Library:LoadConfig(Data)
						if Success then
							Library:Notification("Success!", "Config imported from clipboard.", 5, "Success")
							task.wait(0.3)
							Library:Thread(function()
								for Index in pairs(Library.Theme) do
									if Library.Flags["Theme" .. Index] and Library.Flags["Theme" .. Index].Color then
										Library.Theme[Index] = Library.Flags["Theme" .. Index].Color
										Library:ChangeTheme(Index, Library.Flags["Theme" .. Index].Color)
									end
								end
							end)
						else
							Library:Notification("Error!", "Failed to import config:\n" .. tostring(Result), 5, "Error")
						end
					end, false)
						local AutoloadButton = ConfigsSection:Button()
						AutoloadButton:Add("Set autoload", function()
							if ConfigSelected then
								local CurrentConfigName = string.gsub(ConfigSelected, ".json", "")
								CurrentConfigName ..= "" .. game.GameId .. ".json"
								FS.Write(JoinPath(Library.Folders.Directory, "autoload.json"), FS.Read(JoinPath(Library.Folders.Configs, CurrentConfigName)) or "")
								Library:Notification("Success!", "Succesfully set autoload.", 5)
							end
						end)
						AutoloadButton:Add("Clear autoload", function()
							FS.Write(JoinPath(Library.Folders.Directory, "autoload.json"), "")
						end)
					if Watermark then
						ConfigsSection:Toggle({
							Name = "Watermark",
							Flag = "WatermarkEnabled",
							Default = Watermark.Visible ~= false,
							Callback = function(Value)
								Watermark:SetVisible(Value)
							end
						})
						local WatermarkSection = SettingsPage:Section({Name = "Watermark options", Side = 1})
						WatermarkSection:Dropdown({
							Name = "Position",
							Flag = "WatermarkPosition",
							Default = Watermark.Position or "TopLeft",
							Items = { "TopLeft", "TopCenter", "TopRight", "BottomLeft", "BottomRight" },
							Callback = function(Value)
								Watermark:SetPosition(Value)
							end
						})
						local WatermarkToggles = {
							{ Key = "ShowStats", Name = "Show fps / ping" },
							{ Key = "ShowUser", Name = "Show username" },
							{ Key = "ShowGame", Name = "Show game name" },
							{ Key = "ShowServer", Name = "Show server id" },
							{ Key = "ShowTime", Name = "Show clock / time" },
							{ Key = "ShowDividers", Name = "Show dividers" }
						}
						for Index, Option in ipairs(WatermarkToggles) do
							WatermarkSection:Toggle({
								Name = Option.Name,
								Flag = "Watermark" .. Option.Key,
								Default = Watermark[Option.Key] ~= false,
								Callback = function(Value)
									Watermark:SetOption(Option.Key, Value)
								end
							})
						end
					end
					if KeybindList then
						ConfigsSection:Toggle({
							Name = "Keybind list",
							Flag = "Keybind list",
							Default = KeybindList.Visible ~= false,
							Callback = function(Value)
								KeybindList:SetVisible(Value)
							end
						})
					end
						Library:RefreshConfigsList(ConfigsDropdown)
					end
				end
				do
					local BgSection = SettingsPage:Section({Name = "Window Background & Glass", Side = 2})
					local BgPresets = {
						["None"] = "",
						["Cyberpunk Grid"] = "rbxassetid://10734975692",
						["Deep Space Nebula"] = "rbxassetid://132511743665753",
						["Anime Night Sky"] = "rbxassetid://6031075931"
					}
					local PresetList = { "None", "Cyberpunk Grid", "Deep Space Nebula", "Anime Night Sky" }
					BgSection:Dropdown({
						Name = "Wallpaper presets",
						Flag = "BgPreset",
						Items = PresetList,
						Default = "None",
						Callback = function(Value)
							local Asset = BgPresets[Value] or ""
							Window:SetBackgroundImage(Asset)
						end
					})
					local CustomBgInput = ""
					BgSection:Textbox({
						Name = "Image URL or Asset ID",
						Flag = "CustomBgInput",
						Default = "",
						Placeholder = "Discord link, URL, or ID..",
						Callback = function(Value)
							CustomBgInput = Value
						end
					})
					local BgBtn = BgSection:Button()
					BgBtn:Add("Apply Wallpaper", function()
						if CustomBgInput and CustomBgInput ~= "" then
							Window:SetBackgroundImage(CustomBgInput)
							Library:Notification("Background", "Applied custom background wallpaper.", 2.5, "Success")
						end
					end)
					BgBtn:Add("Clear", function()
						Window:SetBackgroundImage("")
						Library:Notification("Background", "Cleared background wallpaper.", 2, "Info")
					end)
					BgSection:Slider({
						Name = "Wallpaper opacity",
						Flag = "BgOpacity",
						Min = 0,
						Max = 100,
						Default = 40,
						Float = 0,
						Suffix = "%",
						Callback = function(Value)
							Window:SetBackgroundTransparency(1 - (Value / 100))
						end
					})
					BgSection:Slider({
						Name = "Panels & Sub-tabs opacity",
						Flag = "PanelsOpacity",
						Min = 0,
						Max = 100,
						Default = math.floor((1 - (Window.PanelsTransparency or 0.35)) * 100),
						Float = 0,
						Suffix = "%",
						Callback = function(Value)
							Window:SetPanelsTransparency(1 - (Value / 100))
						end
					})
					BgSection:Slider({
						Name = "Main window opacity",
						Flag = "MainWindowOpacity",
						Min = 0,
						Max = 100,
						Default = math.floor((1 - (Window.WindowTransparency or 0.20)) * 100),
						Float = 0,
						Suffix = "%",
						Callback = function(Value)
							Window:SetWindowTransparency(1 - (Value / 100))
						end
					})
					local GlassBtn = BgSection:Button()
					GlassBtn:Add("Glass Preset", function()
						Window:SetPanelsTransparency(0.65)
						Window:SetWindowTransparency(0.40)
						Library:Notification("Visuals", "Applied Frosted Glassmorphism preset.", 2.5, "Success")
					end)
					GlassBtn:Add("Opaque Preset", function()
						Window:SetPanelsTransparency(0)
						Window:SetWindowTransparency(0)
						Library:Notification("Visuals", "Applied Solid Opaque preset.", 2.5, "Info")
					end)
					BgSection:Dropdown({
						Name = "Fit mode",
						Flag = "BgFitMode",
						Items = { "Crop", "Stretch", "Fit" },
						Default = "Crop",
						Callback = function(Value)
							Window:SetBackgroundImage(Window.BackgroundIcon, { ScaleType = Value })
						end
					})
					BgSection:Toggle({
						Name = "Animated aurora glow",
						Flag = "BgAuroraGlow",
						Default = false,
						Callback = function(Value)
							Window:SetAnimatedAurora(Value)
						end
					})
				end
				do
					local VisualsSection = SettingsPage:Section({Name = "Visuals & Screen Effects", Side = 2})
					VisualsSection:Toggle({
						Name = "Background game blur",
						Flag = "SettingBlurEnabled",
						Default = Library.Settings.Blur ~= false,
						Callback = function(Value)
							Library:SetBlur(Value)
						end
					})
					VisualsSection:Slider({
						Name = "Blur intensity",
						Flag = "SettingBlurSize",
						Min = 0,
						Max = 56,
						Default = Library.Settings.BlurSize or 24,
						Float = 0,
						Callback = function(Value)
							Library:SetBlur(Library.Settings.Blur, Value)
						end
					})
					VisualsSection:Toggle({
						Name = "Center Spinner",
						Flag = "SettingCenterSpinner",
						Default = Library.Settings.CenterSpinner ~= false,
						Callback = function(Value)
							Library.Settings.CenterSpinner = Value
							if Value and not Library.ActiveCenterSpinner then
								Library:CenterSpinner({ Visible = true })
							elseif Library.ActiveCenterSpinner then
								Library.ActiveCenterSpinner:SetVisible(Value)
							end
						end
					})
					VisualsSection:Dropdown({
						Name = "Spinner type",
						Flag = "SettingSpinnerType",
						Items = { "Builtin Logo", "Custom Image", "Custom Mesh" },
						Default = "Builtin Logo",
						Callback = function(Value)
							Library.Settings.SpinnerType = Value
						end
					})
					local SpinnerAssetInput = ""
					VisualsSection:Textbox({
						Name = "Spinner asset (image / mesh ID or path)",
						Flag = "SettingSpinnerAsset",
						Default = "",
						Placeholder = "rbxassetid://... or file path",
						Callback = function(Value)
							SpinnerAssetInput = Value
						end
					})
					local AssetBtn = VisualsSection:Button()
					AssetBtn:Add("Apply spinner asset", function()
						local TypeSel = Library.Settings.SpinnerType or "Builtin Logo"
						if SpinnerAssetInput == "" and TypeSel == "Builtin Logo" then
							if Library.ActiveCenterSpinner then
								Library.ActiveCenterSpinner:SetMesh("")
							end
							Library:Notification("Spinner", "Using built-in logo.", 2, "Info")
							return
						end
						if SpinnerAssetInput ~= "" then
							if not Library.ActiveCenterSpinner then
								Library:CenterSpinner({ Visible = true, Asset = SpinnerAssetInput })
							else
								Library.ActiveCenterSpinner:SetMesh(SpinnerAssetInput)
								Library.ActiveCenterSpinner:SetVisible(true)
							end
							Library:Notification("Spinner", "Custom spinner applied!", 2.5, "Success")
						end
					end)
					VisualsSection:Dropdown({
						Name = "Model color",
						Flag = "SettingSpinnerColor",
						Items = { "White", "Accent Theme", "Cyan", "Red", "Gold" },
						Default = "White",
						Callback = function(Value)
							if not Library.ActiveCenterSpinner then return end
							if     Value == "White"        then Library.ActiveCenterSpinner:SetColor(FromRGB(245, 245, 255))
							elseif Value == "Accent Theme" then Library.ActiveCenterSpinner:SetColor(Library.Theme["Accent"])
							elseif Value == "Cyan"         then Library.ActiveCenterSpinner:SetColor(FromRGB(56,  189, 248))
							elseif Value == "Red"          then Library.ActiveCenterSpinner:SetColor(FromRGB(244,  63,  94))
							elseif Value == "Gold"         then Library.ActiveCenterSpinner:SetColor(FromRGB(251, 191,  36))
							end
						end
					})
					VisualsSection:Dropdown({
						Name = "Spinner position",
						Flag = "SettingSpinnerPosition",
						Items = { "Screen Center", "Window Center" },
						Default = Library.Settings.CenterSpinnerPosition or "Screen Center",
						Callback = function(Value)
							Library.Settings.CenterSpinnerPosition = Value
							if Library.ActiveCenterSpinner then Library.ActiveCenterSpinner:SetPositionMode(Value) end
						end
					})
					VisualsSection:Dropdown({
						Name = "Spinner layer",
						Flag = "SettingSpinnerLayer",
						Items = { "Above UI", "Behind UI" },
						Default = Library.Settings.CenterSpinnerLayer or "Behind UI",
						Callback = function(Value)
							Library.Settings.CenterSpinnerLayer = Value
							if Library.ActiveCenterSpinner then Library.ActiveCenterSpinner:SetLayer(Value) end
						end
					})
					VisualsSection:Slider({
						Name = "Spin speed",
						Flag = "SettingSpinnerSpeed",
						Min = 2, Max = 60, Default = math.floor((Library.Settings.CenterSpinnerSpeed or 1.2) * 10),
						Float = 0,
						Callback = function(Value)
							local Spd = Value / 10
							Library.Settings.CenterSpinnerSpeed = Spd
							if Library.ActiveCenterSpinner then Library.ActiveCenterSpinner:SetSpeed(Spd) end
						end
					})
					VisualsSection:Slider({
						Name = "Tilt angle",
						Flag = "SettingSpinnerTilt",
						Min = -45, Max = 60, Default = 18, Float = 0, Suffix = "°",
						Callback = function(Value)
							if Library.ActiveCenterSpinner then Library.ActiveCenterSpinner:SetTilt(Value) end
						end
					})
					VisualsSection:Slider({
						Name = "Size",
						Flag = "SettingSpinnerSize",
						Min = 100, Max = 500, Default = Library.Settings.CenterSpinnerSize or 300,
						Float = 0,
						Callback = function(Value)
							Library.Settings.CenterSpinnerSize = Value
							if Library.ActiveCenterSpinner then Library.ActiveCenterSpinner:SetSize(Value) end
						end
					})
					VisualsSection:Slider({
						Name = "Opacity",
						Flag = "SettingSpinnerOpacity",
						Min = 0, Max = 100, Default = 100, Float = 0, Suffix = "%",
						Callback = function(Value)
							if Library.ActiveCenterSpinner then Library.ActiveCenterSpinner:SetTransparency(1 - (Value / 100)) end
						end
					})
					end
				do
					local ThemeSection = SettingsPage:Section({Name = "Themes", Side = 1})
					local ThemeSelected
					local ThemeName
					do
						local PresetNames = { }
						for PresetName in pairs(Library.Themes) do
							TableInsert(PresetNames, PresetName)
						end
						table.sort(PresetNames)
						ThemeSection:Dropdown({
							Name = "Presets",
							Flag = "ThemePreset",
							Items = PresetNames,
							Default = "Default",
							Search = true,
							Callback = function(Value)
								local Preset = Library.Themes[Value]
								if not Preset then
									return
								end
								Library:ApplyTheme(Preset)
								Library:Notification("Theme", 'Applied "' .. tostring(Value) .. '".', 3, "Success")
							end
						})
						local ThemesDropdown = ThemeSection:Dropdown({
							Name = "Themes",
							Flag = "ThemesList",
							Items = { },
							Multi = false,
							Callback = function(Value)
								ThemeSelected = Value
							end
						})
						ThemeSection:Textbox({
							Name = "Name",
							Default = "",
							Flag = "ThemeName",
							Placeholder = "...",
							Callback = function(Value)
								ThemeName = Value
							end
						})
						local CreateDeleteButton = ThemeSection:Button()
						CreateDeleteButton:Add("Create", function()
							if ThemeName and ThemeName ~= "" then
								FS.Write(JoinPath(Library.Folders.Themes, ThemeName .. ".json"), Library:GetConfig())
								Library:RefreshConfigsList(ThemesDropdown)
							end
						end, false)
						CreateDeleteButton:Add("Delete", function()
							if ThemeSelected then
								Library:DeleteConfig(ThemeSelected)
								Library:RefreshConfigsList(ThemesDropdown)
							end
						end, false)
						local LoadSaveButton = ThemeSection:Button()
						LoadSaveButton:Add("Load", function()
							if ThemeSelected then
								local Success, Result = Library:LoadTheme(FS.Read(JoinPath(Library.Folders.Themes, ThemeSelected)) or "")
								if Success then
									Library:Notification("Success!", "Succesfully loaded theme.", 5)
									task.wait(0.3)
									Library:Thread(function()
										for Index, Value in Library.Theme do
											Library.Theme[Index] = Library.Flags["Theme" .. Index].Color
											Library:ChangeTheme(Index, Library.Flags["Theme" .. Index].Color)
										end
									end)
								else
									Library:Notification("Error!", "Failed to load theme. Report this to the developers:\n"..Result, 5)
								end
							end
						end, false)
						LoadSaveButton:Add("Save", function()
							if ThemeSelected then
								local Success, Error = Library:SafeCall(function()
									FS.Write(JoinPath(Library.Folders.Themes, ThemeSelected), Library:GetTheme())
								end)
								if not Success then
									Library:Notification("Error!", "Failed to save theme. Report this to the developers:\n"..Error, 5)
								else
									Library:Notification("Success!", "Succesfully saved theme.", 5)
								end
							end
						end, false)
						local RefreshlistButton = ThemeSection:Button()
						RefreshlistButton:Add("Refresh", function()
							Library:RefreshThemesList(ThemesDropdown)
						end, false)
						local ThemesPresetDropdown = ThemeSection:Dropdown({
							Name = "Themes Preset",
							Flag = "ThemesPresetList",
							Items = { },
							Multi = false,
							Callback = function(Value)
								local ThemeData = Library.Themes[Value]
								if not ThemeData then
									return
								end
								for Index, Value in Library.Theme do
									Library.Theme[Index] = ThemeData[Index]
									Library:ChangeTheme(Index, ThemeData[Index])
									Library.ThemeColorpickers[Index]:Set(ThemeData[Index])
								end
								task.wait(0.3)
								Library:Thread(function()
									for Index, Value in Library.Theme do
										Library.Theme[Index] = Library.Flags["Theme" .. Index].Color
										Library:ChangeTheme(Index, Library.Flags["Theme" .. Index].Color)
									end
								end)
							end
						})
						for Index, Value in Library.Themes do
							ThemesPresetDropdown:Add(Index)
						end
						Library:RefreshThemesList(ThemesDropdown)
					end
				end
				do
					local WindowsSection = SettingsPage:Section({Name = "Windows", Side = 1})
					local SelectedWindow
					local WindowsList
					local function GetWindowByName(Name)
						if not Name then
							return nil
						end
						for Index, Other in ipairs(Library.Windows) do
							if Other.Name == Name then
								return Other
							end
						end
						return nil
					end
					local function RefreshWindows()
						local Names = { }
						for Index, Other in ipairs(Library.Windows) do
							TableInsert(Names, Other.Name)
						end
						if #Names == 0 then
							TableInsert(Names, "None")
						end
						WindowsList:Refresh(Names)
					end
					WindowsList = WindowsSection:Dropdown({
						Name = "Windows",
						Flag = "WindowsList",
						Items = { },
						Search = true,
						Callback = function(Value)
							SelectedWindow = Value
						end
					})
					local WindowButton = WindowsSection:Button()
					WindowButton:Add("Focus", function()
						local Target = GetWindowByName(SelectedWindow)
						if Target then
							Target:Focus()
							Target:SetOpen(true)
						else
							Library:Notification("Windows", "Select a window first.", 2, "Warning")
						end
					end, false)
					WindowButton:Add("Close", function()
						local Target = GetWindowByName(SelectedWindow)
						if Target then
							Target:SetOpen(false)
						else
							Library:Notification("Windows", "Select a window first.", 2, "Warning")
						end
					end, false)
					WindowButton:Add("Refresh", function()
						RefreshWindows()
					end, false)
					RefreshWindows()
				end
				do
					local SettingsSection = SettingsPage:Section({Name = "Settings", Side = 2})
					do
						SettingsSection:Label("Menu keybind", "Left"):Keybind({
							Name = "Menu keybind",
							Flag = "Menu Keybind",
							Default = Enum.KeyCode.RightControl,
							Mode = "Toggle",
							Callback = function(Value)
								Library.MenuKeybind = Library.Flags["Menu Keybind"].Key
							end
						})
					SettingsSection:Slider({
						Name = "Background opacity",
						Min = 0,
						Max = 1,
						Default = 0.12,
						Decimals = 0.01,
						Flag = "Background opacity",
						Callback = function(Value)
							Window:SetBackgroundTransparency(Value)
						end
					})
						SettingsSection:Slider({
							Name = "Tween time",
							Min = 0,
							Max = 5,
							Default = 0.25,
							Decimals = 0.01,
							Flag = "Tween Time",
							Callback = function(Value)
								Library.Tween.Time = Value
							end
						})
						SettingsSection:Dropdown({
							Name = "Style",
							Flag = "TweenStyle",
							Default = "Cubic",
							Items = {"Linear", "Sine", "Quad", "Cubic", "Quart", "Quint", "Exponential", "Circular", "Back", "Elastic", "Bounce"},
							Callback = function(Value)
								Library.Tween.Style = Enum.EasingStyle[Value]
							end
						})
					SettingsSection:Dropdown({
						Name = "Direction",
						Flag = "TweenDirection",
						Default = "Out",
						Items = {"In", "Out", "InOut"},
						Callback = function(Value)
							Library.Tween.Direction = Enum.EasingDirection[Value]
						end
					})
					SettingsSection:Slider({
						Name = "Max notifications",
						Min = 1,
						Max = 12,
						Default = 6,
						Step = 1,
						Decimals = 0,
						Flag = "MaxNotifications",
						Callback = function(Value)
							Library.Settings.MaxNotifications = MathFloor(Value)
						end
					})
					SettingsSection:Label("Notification position", "Left")
					SettingsSection:Dropdown({
						Name = "Corner",
						Flag = "NotifPosition",
						Default = Library.Settings.NotificationPosition,
						Search = true,
						Items = {"TopLeft", "TopCenter", "TopRight", "CenterLeft", "Center", "CenterRight", "BottomLeft", "BottomCenter", "BottomRight"},
						Callback = function(Value)
							Library:SetNotificationPosition(Value)
						end
					})
					SettingsSection:Dropdown({
						Name = "Stack direction",
						Flag = "NotifDirection",
						Default = Library.Settings.NotificationDirection,
						Items = {"Vertical", "Horizontal"},
						Callback = function(Value)
							Library:SetNotificationLayout({ Direction = Value })
						end
					})
					SettingsSection:Slider({
						Name = "Edge margin X",
						Min = -400,
						Max = 400,
						Default = Library.Settings.NotificationOffsetX,
						Step = 1,
						Decimals = 0,
						Flag = "NotifOffsetX",
						Tooltip = "Inward from the anchored edge",
						Callback = function(Value)
							Library:SetNotificationLayout({ OffsetX = MathFloor(Value) })
						end
					})
					SettingsSection:Slider({
						Name = "Edge margin Y",
						Min = -400,
						Max = 400,
						Default = Library.Settings.NotificationOffsetY,
						Step = 1,
						Decimals = 0,
						Flag = "NotifOffsetY",
						Tooltip = "Inward from the anchored edge",
						Callback = function(Value)
							Library:SetNotificationLayout({ OffsetY = MathFloor(Value) })
						end
					})
					SettingsSection:Slider({
						Name = "Notification width",
						Min = 160,
						Max = 700,
						Default = Library.Settings.NotificationWidth,
						Step = 5,
						Decimals = 0,
						Flag = "NotifWidth",
						Callback = function(Value)
							Library:SetNotificationLayout({ Width = MathFloor(Value) })
						end
					})
					SettingsSection:Slider({
						Name = "Stack gap",
						Min = 0,
						Max = 60,
						Default = Library.Settings.NotificationGap,
						Step = 1,
						Decimals = 0,
						Flag = "NotifGap",
						Callback = function(Value)
							Library:SetNotificationLayout({ Gap = MathFloor(Value) })
						end
					})
					SettingsSection:Slider({
						Name = "Scrollbar thickness",
						Min = 0,
						Max = 10,
						Default = 4,
						Step = 1,
						Decimals = 0,
						Flag = "ScrollBarThickness",
						Callback = function(Value)
							Library.Settings.ScrollBarThickness = MathFloor(Value)
							for _, Descendant in ipairs(Library.Holder.Instance:GetDescendants()) do
								if Descendant:IsA("ScrollingFrame") then
									Descendant.ScrollBarThickness = Library.Settings.ScrollBarThickness
								end
							end
						end
					})
					SettingsSection:Toggle({
						Name = "Auto-save current config",
						Flag = "AutoSave",
						Default = true,
						Callback = function(Value)
							Library.Settings.AutoSave = Value
						end
					})
					SettingsSection:Toggle({
						Name = "Page transitions",
						Flag = "PageTransitions",
						Default = true,
						Callback = function(Value)
							Library.Settings.PageTransitions = Value
						end
					})
					SettingsSection:Toggle({
						Name = "Animate hidden elements",
						Flag = "BypassTweenGuard",
						Default = false,
						Callback = function(Value)
							Library.BypassTweenGuard = Value
						end
					})
					SettingsSection:Label("Off = skip tweening for elements on hidden tabs (faster)", "Left")
					SettingsSection:Toggle({
						Name = "Pre-warm tab layout",
						Flag = "WarmupPages",
						Default = true,
						Callback = function(Value)
							Library.WarmupDisabled = not Value
						end
					})
					SettingsSection:Slider({
						Name = "Warm-up tabs per frame",
						Flag = "WarmupPerFrame",
						Min = 1, Max = 8, Default = 1, Float = 0,
						Callback = function(Value)
							Library.WarmupPerFrame = Value
						end
					})
					SettingsSection:Label("Pre-warming removes the freeze when opening heavy tabs", "Left")
					end
				end
				do
					local ThemeSection = SettingsPage:Section({
						Name = "Theme",
						Side = 1
					})
					do
						for Index, Value in Library.Theme do
							Library.ThemeColorpickers[Index] = ThemeSection:Label(Index, "Left"):Colorpicker({Name = Index, Default = Value, Flag = "Theme"..Index, Callback = function(Value)
								Library.Theme[Index] = Value
								Library:ChangeTheme(Index, Value)
							end})
						end
					end
				end
			end
		end
	end
	do
		local SectionsMeta = { }
		for Key, Value in pairs(Library.Sections) do
			if type(Value) == "function" then
				SectionsMeta[Key] = Value
			end
		end
		for Key, Value in pairs(SectionsMeta) do
			Library.Sections[Key] = function(...)
				local Result = Value(...)
				local OwnerPage = self and self.Page
				if OwnerPage then
					OwnerPage.ContentVersion = (OwnerPage.ContentVersion or 0) + 1
				end
				if type(Result) == "table" and Result.Flag then
					if not Library.Elements[Result.Flag] then
						TableInsert(Library.ElementOrder, Result.Flag)
					end
					Library.Elements[Result.Flag] = Result
				end
				return Result
			end
		end
		local PagesMeta = { }
		for Key, Value in pairs(Library.Pages) do
			if type(Value) == "function" then
				PagesMeta[Key] = Value
			end
		end
		for Key, Value in pairs(PagesMeta) do
			Library.Pages[Key] = function(...)
				local Result = Value(...)
				if type(Result) == "table" and Result.Flag then
					if not Library.Elements[Result.Flag] then
						TableInsert(Library.ElementOrder, Result.Flag)
					end
					Library.Elements[Result.Flag] = Result
				end
				if Result and Result.Page then
					Result.Page.ContentVersion = (Result.Page.ContentVersion or 0) + 1
				end
				return Result
			end
		end
	end

	Library.Get = function(self, Flag)
		return self.Elements[Flag]
	end

	Library.Find = function(self, Name, Limit)
		local Matches = { }
		for Index, Flag in ipairs(Library.ElementOrder) do
			local Element = Library.Elements[Flag]
			if Element and type(Element.Name) == "string" then
				if StringFind(StringLower(Element.Name), StringLower(tostring(Name)), 1, true) then
					TableInsert(Matches, Element)
					if Limit and #Matches >= Limit then
						break
					end
				end
			end
		end
		return Matches
	end

	Library.Create = function(self, Options)
		Options = Options or { }
		if Options.MenuKeybind or Options.menukeybind then
			Library.MenuKeybind = tostring(Options.MenuKeybind or Options.menukeybind)
		end
		local Window = self:Window({
			Name = Options.Name or Options.name or "EnterSkin",
			Size = Options.Size or Options.size or nil,
			BackgroundIcon = Options.BackgroundIcon or Options.backgroundicon or nil
		})
		local Watermark
		local KeybindList
		if Options.Watermark ~= false then
			Watermark = self:Watermark(Options.WatermarkName or Options.watermarkname or Window.Name)
		end
		if Options.KeybindList ~= false then
			KeybindList = self:KeybindList()
		end
		if Options.Settings ~= false then
			self:CreateSettingsPage(Window, Watermark, KeybindList)
		end
		if Options.Blur ~= nil then
			self.Settings.Blur = not not Options.Blur
		end
		if Options.BlurSize then
			self.Settings.BlurSize = tonumber(Options.BlurSize) or 24
		end
		if Options.CenterSpinner == true then
			self:CenterSpinner(Options.CenterSpinnerOptions or { })
		end
		if Options.AutoLoad or Options.autoload then
			self:CheckForAutoLoad()
		end
		if Options.Open or Options.open then
			Window:SetOpen(true)
		end
		return Window
	end
end
getgenv().Library = Library
return Library