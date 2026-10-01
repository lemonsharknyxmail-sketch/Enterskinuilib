
local LIBRARY_FOLDER = "Robloxui"

local function Warn(Message)
	if warn then
		warn("[EnterSkin] " .. Message)
	else
		print("[EnterSkin] " .. Message)
	end
end

local function FileNameOnly(Path)
	return tostring(Path or ""):match("[^/\\]+$") or tostring(Path or "")
end

if getgenv().EnterSkin and type(getgenv().EnterSkin.Unload) == "function" then
	pcall(function()
		getgenv().EnterSkin:Unload()
	end)
end

if getgenv().Library and type(getgenv().Library.Unload) == "function" then
	pcall(function()
		getgenv().Library:Unload()
	end)
end

local Library = (function()

	local HasList = type(listfiles) == "function"
	local HasRead = type(readfile) == "function"

	if not HasList or not HasRead then
		Warn("this executor has no readfile/listfiles, cannot load from a folder")
		return nil
	end

	local Compile = loadstring or load

	if type(Compile) ~= "function" then
		Warn("no loadstring/load available in this executor")
		return nil
	end

	local ok, entries = pcall(listfiles, LIBRARY_FOLDER)

	if not ok or type(entries) ~= "table" then
		Warn("folder '" .. LIBRARY_FOLDER .. "' could not be read (does it exist?)")

		if type(makefolder) == "function" then
			pcall(makefolder, LIBRARY_FOLDER)
			Warn("created it - put the library .lua in there and re-run this file")
		end

		return nil
	end

	local candidates = { }
	local seen = { }

	local function AddCandidate(Path)
		if not Path or Path == "" then
			return
		end

		Path = tostring(Path):gsub("\\", "/")

		if seen[Path] then
			return
		end

		seen[Path] = true

		candidates[#candidates + 1] = Path
	end

	for _, entry in ipairs(entries) do
		local name = FileNameOnly(entry)

		if name:match("%.lua$") and not name:lower():match("^example") then
			AddCandidate(entry)
			AddCandidate(LIBRARY_FOLDER .. "/" .. name)
		end
	end

	if #candidates == 0 then
		Warn("no .lua files found in '" .. LIBRARY_FOLDER .. "' (saw "
			.. #entries .. " entr" .. (#entries == 1 and "y" or "ies") .. ")")
		return nil
	end

	local failures = { }

	for _, path in ipairs(candidates) do
		local okRead, source = pcall(readfile, path)

		if okRead and type(source) == "string" and #source > 0 then
			local okLoad, chunk = pcall(Compile, source, "@" .. path)

			if okLoad and type(chunk) == "function" then
				local okRun, result = pcall(chunk)

				if okRun and getgenv().EnterSkin then
					return getgenv().EnterSkin
				end

				if okRun and type(result) == "table" and result.Window then
					return result
				end

				failures[#failures + 1] = path .. " -> " .. tostring(result):sub(1, 120)
			else
				failures[#failures + 1] = path .. " -> " .. tostring(chunk):sub(1, 120)
			end
		else
			failures[#failures + 1] = path .. " -> unreadable"
		end
	end

	Warn("found " .. #candidates .. " candidate(s) but none could be loaded:")
	for _, failure in ipairs(failures) do
		Warn("  " .. failure)
	end

	return nil
end)()

if not Library then
	return
end

local Window = Library:Create({
	Name = "EnterSkin",
	MenuKeybind = "RightControl",
	Open = true,
	Watermark = false,
	KeybindList = false,
	Settings = false,
	Blur = true,
	BlurSize = 24
})

local Watermark = Library:Watermark(Window.Name)
local KeybindList = Library:KeybindList()

local CenterSpinner = Library:CenterSpinner({ Visible = true })

local MobileButton = Library:MobileButton({
	Window = Window,
	Position = "MiddleLeft",
	SnapToEdge = true
})

Library:Notification("Loaded", "EnterSkin example is ready.", 5, "Success")

do
	local Page = Window:Page({ Name = "Main", Columns = 2 })

	do
		local Section = Page:Section({ Name = "Animated Text & FX", Side = 1 })

		Section:AnimatedText({
			Name = "Typewriter Text",
			Texts = {
				"EnterSkin v2.0 - Premium Luau UI Library",
				"Typewriter, Rainbow & Gradient Animations",
				"Custom Discord & Image Backgrounds",
				"UI Lock & Edge-Snapping Mobile Dock"
			},
			Type = "Typing",
			Speed = 1
		})

		Section:AnimatedText({
			Name = "Rainbow Chroma",
			Text = "Rainbow Chromatic Flowing Text",
			Type = "Rainbow",
			Speed = 1.2
		})

		Section:AnimatedText({
			Name = "Aurora Gradient",
			Text = "Cyber Aurora Shifting Gradient",
			Type = "Gradient",
			Speed = 1.4
		})
	end

	do
		local Section = Page:Section({ Name = "Booleans", Side = 1 })

		Section:Toggle({ Name = "Toggle", Flag = "Main_Toggle", Default = true })
		Section:Checkbox({ Name = "Checkbox", Flag = "Main_Checkbox", Default = true })
		Section:Segmented({ Name = "Segmented", Flag = "Main_Segmented", Items = { "One", "Two", "Three" }, Default = "Two" })
		Section:RadioList({ Name = "Radio list", Flag = "Main_Radio", Items = { "First", "Second", "Third" }, Default = "Second" })
	end

	do
		local Section = Page:Section({ Name = "Numbers", Side = 2 })

		Section:Slider({ Name = "Slider", Flag = "Main_Slider", Min = 0, Max = 100, Default = 50, Suffix = "%" })
		Section:RangeSlider({ Name = "Range slider", Flag = "Main_Range", Min = 0, Max = 100, Default = { Low = 25, High = 75 } })
		Section:NumberInput({ Name = "Number input", Flag = "Main_Number", Min = 0, Max = 100, Default = 25, Step = 5 })
	end

	do
		local Section = Page:Section({ Name = "Choices", Side = 1 })

		Section:Dropdown({ Name = "Dropdown", Flag = "Main_Dropdown", Items = { "Alpha", "Bravo", "Charlie" }, Default = "Bravo" })
		Section:Dropdown({ Name = "Searchable", Flag = "Main_DropdownSearch", Search = true, Items = { "Assault", "Sniper", "Shotgun", "SMG" }, Default = "Sniper" })
		Section:ToggleDropdown({ Name = "Multi select", Flag = "Main_Multi", Items = { "Head", "Torso", "Arms" }, Multi = true })
	end

	do
		local Section = Page:Section({ Name = "Text", Side = 2 })

		Section:Textbox({ Name = "Textbox", Flag = "Main_Textbox", Placeholder = "type here.." })
		Section:MultilineTextbox({ Name = "Multiline", Flag = "Main_Multiline", Placeholder = "multiple\nlines.." })
		Section:Label("Colour picker", "Left"):Colorpicker({ Name = "Colour picker", Flag = "Main_Colour", Default = Color3.fromRGB(59, 130, 246) })
		Section:Label("Keybind", "Left"):Keybind({ Name = "Keybind", Flag = "Main_Keybind", Default = Enum.KeyCode.End, Mode = "Toggle" })
	end

	do
		local Section = Page:Section({ Name = "Buttons", Side = 1 })

		Section:Button({ Name = "Button" }):Add("Click me", function() end, false)

		Section:HoldButton({
			Name = "Hold button",
			Duration = 1.5
		})
	end

	do
		local Section = Page:Section({ Name = "Display", Side = 2 })

		Section:Progress({ Name = "Progress", Flag = "Main_Progress", Max = 100, Default = 60, Suffix = "%" })
		Section:Listbox({
			Name = "Listbox",
			Flag = "Main_List",
			Rows = 4,
			Items = { "Player one", "Player two", "Player three", "Player four", "Player five" }
		})
	end

	do
		local Section = Page:Section({ Name = "Accordion", Side = 1 })

		local Accordion = Section:Accordion({ Name = "Open me", Default = true })

		Accordion:Toggle({ Name = "Inside", Flag = "Main_Acc_Toggle", Default = true })
		Accordion:Slider({ Name = "Also inside", Flag = "Main_Acc_Slider", Min = 0, Max = 100, Default = 40 })
	end

	do
		local Section = Page:Section({ Name = "Group", Side = 2 })

		local Group = Section:Group({ Name = "Grouped", Flag = "Main_Group", Default = true })

		Group:Checkbox({ Name = "Inside group", Flag = "Main_Group_Checkbox", Default = true })
		Group:Toggle({ Name = "Also inside", Flag = "Main_Group_Toggle", Default = false })
	end

	do
		local Section = Page:Section({ Name = "About", Side = 2 })

		Section:Label("One of every element, laid out as a plain gallery.", "Left")
	end

	do
		local Section = Page:CollapsibleSection({ Name = "Collapsible", Side = 1 })

		Section:Toggle({ Name = "Hidden until opened", Flag = "Main_Coll_Toggle" })
	end

	do
		local Sphere = Instance.new("Part")
		Sphere.Name = "Preview"
		Sphere.Shape = Enum.PartType.Ball
		Sphere.Size = Vector3.new(2, 2, 2)
		Sphere.Material = Enum.Material.SmoothPlastic
		Sphere.Color = Color3.fromRGB(59, 130, 246)
		Sphere.Anchored = true
		Sphere.Transparency = 1
		Sphere.CanCollide = false
		Sphere.Parent = workspace

		Page:ViewportSection({ Name = "Viewport", Side = 2, Part = Sphere })

		Sphere:Destroy()
	end
end

Library:CreateSettingsPage(Window, Watermark, KeybindList)

do
	local Pages = Window.Pages
	local SettingsPage

	for _, Page in ipairs(Pages) do
		if Page.Name == "Settings" then
			SettingsPage = Page
		end
	end

	if SettingsPage then
		local Section = SettingsPage:Section({ Name = "Mobile button", Side = 1 })

		Section:Dropdown({
			Name = "Position",
			Flag = "MobileButtonPosition",
			Default = "MiddleLeft",
			Search = true,
			Items = { "TopLeft", "TopRight", "MiddleLeft", "Center", "MiddleRight", "BottomLeft", "BottomRight" },
			Callback = function(Value)
				MobileButton:SetPosition(Value)
			end
		})

		Section:Toggle({
			Name = "Locked",
			Flag = "MobileButtonLocked",
			Default = false,
			Callback = function(Value)
				MobileButton:SetLocked(Value)
			end
		})

		Section:Toggle({
			Name = "Visible",
			Flag = "MobileButtonVisible",
			Default = true,
			Callback = function(Value)
				MobileButton:SetVisible(Value)
			end
		})

		Section:Toggle({
			Name = "Snap to edge",
			Flag = "MobileButtonSnap",
			Default = true,
			Callback = function(Value)
				MobileButton:SetSnapToEdge(Value)
			end
		})
	end
end
