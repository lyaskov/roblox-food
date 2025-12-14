local lp = game:GetService("Players").LocalPlayer
local frame2 = lp.PlayerGui.BuyScreenGui.Frame.Frame.ImageLabel.Frame.MainFrame.Frame.ScrollingFrame.Frame

local function isMaterialFrame(obj)
	return obj and obj.Name:match("^Material(%d+)Frame$") ~= nil
end

local function getMaterialFrames()
	local list = {}
	for _, ch in ipairs(frame2:GetChildren()) do
		local n = ch.Name:match("^Material(%d+)Frame$")
		if n then table.insert(list, {idx=tonumber(n), frame=ch}) end
	end
	table.sort(list, function(a,b) return a.idx < b.idx end)
	return list
end

local function dumpAttributes(obj)
	local attrs = obj:GetAttributes()
	for k,v in pairs(attrs) do
		print("    ATTR", obj.ClassName, obj.Name, k, "=", v)
	end
end

local function dumpValues(obj)
	if obj:IsA("ValueBase") then
		-- ValueBase: IntValue/BoolValue/StringValue/NumberValue/ObjectValue etc.
		local ok, v = pcall(function() return obj.Value end)
		if ok then print("    VAL", obj.ClassName, obj.Name, "=", v) end
	end
end

local function dumpMaterial(mf, maxLines)
	maxLines = maxLines or 220
	local lines = 0
	local function p(...)
		lines += 1
		if lines <= maxLines then print(...) end
	end

	p(("===== MATERIAL %s ====="):format(mf.Name))
	p("  Visible:", mf.Visible, "Class:", mf.ClassName)
	if mf:IsA("GuiObject") then
		p("  Pos:", tostring(mf.Position), "Size:", tostring(mf.Size))
	end
	dumpAttributes(mf)

	for _, d in ipairs(mf:GetDescendants()) do
		if lines >= maxLines then
			p("  ...TRUNCATED...")
			break
		end

		-- Attributes на каждом объекте (может быть шумно, но это “всё доступное”)
		dumpAttributes(d)

		-- ValueObjects
		if d:IsA("ValueBase") then
			dumpValues(d)
		end

		-- TextLabels
		if d:IsA("TextLabel") then
			p("    TEXT", d.Name, "=", d.Text)
		end

		-- ImageLabels / ImageButtons
		if d:IsA("ImageLabel") or d:IsA("ImageButton") then
			p("    IMG", d.ClassName, d.Name, "=", d.Image)
		end

		-- Buttons
		if d:IsA("TextButton") or d:IsA("ImageButton") then
			p("    BTN", d.ClassName, d.Name, "Visible:", d.Visible)
		end
	end
end

local mats = getMaterialFrames()
print(("=== FULL DUMP | materials: %d ==="):format(#mats))

-- Для теста можно начать с 1..2, потом увеличить
for _, it in ipairs(mats) do
	dumpMaterial(it.frame, 220) -- лимит строк на 1 material
end
