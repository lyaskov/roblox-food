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
	-- "X5 Stock" / "x10" / "X 5"
	local n = text:match("[Xx]%s*(%d+)")
	if n then return tonumber(n) end
	n = text:match("(%d+)")
	return tonumber(n) or 0
end

local function parseGold(text)
	-- входы типа: "10$", "1K$", "300K$", "2M$", "1B$", "100B$"
	text = tostring(text or "")
	text = text:gsub("%s+", ""):gsub("%$", ""):upper()

	-- вытаскиваем число (может быть с точкой) и суффикс K/M/B
	local num, suf = text:match("([%d%.]+)([KMB]?)")
	if not num then return 0 end

	local v = tonumber(num) or 0
	local mul = 1
	if suf == "K" then mul = 1e3
	elseif suf == "M" then mul = 1e6
	elseif suf == "B" then mul = 1e9
	end

	-- округлим до целого (на случай "1.5K$")
	return math.floor(v * mul + 0.5)
end

local function getItemInfo(mf)
	-- name: лучше брать NameValue (как у тебя Flour), а не HeadTextLabel
	local nameValue = findDesc(mf, "StringValue", "NameValue")
	local headLabel  = findDesc(mf, "TextLabel", "HeadTextLabel")
	local numLabel   = findDesc(mf, "TextLabel", "NumTextLabel")
	local costLabel  = findDesc(mf, "TextLabel", "CostTextLabel")

	local name = mf.Name
	if nameValue and tostring(nameValue.Value or "") ~= "" then
		name = tostring(nameValue.Value)
	elseif headLabel then
		name = tostring(headLabel.Text or mf.Name)
	end

	local qty = 0
	if numLabel then qty = parseQty(numLabel.Text) end

	local goldText = ""
	if costLabel then goldText = tostring(costLabel.Text or "") end
	local price = parseGold(goldText)

	return {
		name = name,
		price = price, -- ЧИСЛО (Gold)
		qty = qty,     -- ЧИСЛО
	}
end

local mats = getMaterialFrames()
local items = {}

for _, it in ipairs(mats) do
	table.insert(items, getItemInfo(it.frame))
end

print(("=== SHOP JSON | items:%d ==="):format(#items))
print(HttpService:JSONEncode(items))
print("=== SHOP JSON END ===")
