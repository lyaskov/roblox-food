local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer
local frame2 = lp.PlayerGui.BuyScreenGui.Frame.Frame.ImageLabel.Frame.MainFrame.Frame.ScrollingFrame.Frame

local function getMaterialFrames()
	local list = {}
	for _, ch in ipairs(frame2:GetChildren()) do
		local n = ch.Name:match("^Material(%d+)Frame$")
		if n then table.insert(list, {idx=tonumber(n), frame=ch}) end
	end
	table.sort(list, function(a,b) return a.idx < b.idx end)
	return list
end

local function findDesc(root, className, name)
	for _, d in ipairs(root:GetDescendants()) do
		if d.ClassName == className and d.Name == name then
			return d
		end
	end
	return nil
end

local function parseQty(text)
	text = tostring(text or "")
	local n = text:match("[Xx]%s*(%d+)")
	if n then return tonumber(n) end
	n = text:match("(%d+)")
	return tonumber(n) or 0
end

local function parseGold(text)
	-- "10$", "1K$", "300K$", "2M$", "1B$", "100B$"
	text = tostring(text or "")
	text = text:gsub("%s+", ""):gsub("%$", ""):upper()
	local num, suf = text:match("([%d%.]+)([KMB]?)")
	if not num then return 0 end
	local v = tonumber(num) or 0
	local mul = 1
	if suf == "K" then mul = 1e3
	elseif suf == "M" then mul = 1e6
	elseif suf == "B" then mul = 1e9
	end
	return math.floor(v * mul + 0.5)
end

local function parseInt(text)
	text = tostring(text or "")
	local n = text:match("(%d+)")
	return tonumber(n) or 0
end

local function getButtonPrice(mf, buttonName)
	local btn = findDesc(mf, "ImageButton", buttonName)
	if not btn then return nil end
	for _, d in ipairs(btn:GetDescendants()) do
		if d:IsA("TextLabel") then
			local v = parseInt(d.Text)
			if v > 0 then return v end
		end
	end
	return nil
end

local function buildItem(mf, idx)
	local headLabel = findDesc(mf, "TextLabel", "HeadTextLabel")
	local numLabel  = findDesc(mf, "TextLabel", "NumTextLabel")
	local costLabel = findDesc(mf, "TextLabel", "CostTextLabel")
	local rareLabel = findDesc(mf, "TextLabel", "RareTextLabel")
	local xLabel    = findDesc(mf, "TextLabel", "XTextLabel")

	local keyName = ""
	if headLabel then keyName = tostring(headLabel.Text or "") end
	if keyName == "" then keyName = mf.Name end

	local stockText = numLabel and tostring(numLabel.Text or "") or ""
	local goldText  = costLabel and tostring(costLabel.Text or "") or ""
	local rareText  = rareLabel and tostring(rareLabel.Text or "") or ""
	local xText     = xLabel and tostring(xLabel.Text or "") or ""

	local qty = parseQty(stockText)
	local gold = parseGold(goldText)

	local robux = getButtonPrice(mf, "BuyRobuxImageButton") or 0
	local robux10 = getButtonPrice(mf, "Buy10RobuxImageButton") or 0
	local packMult = parseQty(xText)

	return keyName, {
		idx = idx,
		rarity = rareText,

		stockText = stockText,
		qty = qty,

		goldText = goldText,
		gold = gold,
	}
end

local mats = getMaterialFrames()
print(("=== SHOP JSON LINES | materials:%d ==="):format(#mats))

local used = {}
for _, it in ipairs(mats) do
	local key, data = buildItem(it.frame, it.idx)

	-- чтобы ключи не повторялись
	local outKey = key
	if used[outKey] then
		outKey = outKey .. "_" .. tostring(it.idx)
		data.displayName = outKey
	end
	used[outKey] = true

	-- одна строка = один товар.
	local one = {}
	one[outKey] = data
	print(HttpService:JSONEncode(one))
end

print("=== SHOP JSON LINES END ===")
