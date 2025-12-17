-- Shop JSON dump (minimal fields): dump once on start; then ticker every second; when timer increases dump all items
local lp = game:GetService("Players").LocalPlayer
local root = lp.PlayerGui:WaitForChild("BuyScreenGui")
	:WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("ImageLabel"):WaitForChild("Frame")

local frame2 = root:WaitForChild("MainFrame"):WaitForChild("Frame"):WaitForChild("ScrollingFrame"):WaitForChild("Frame")
local timeLbl = root:WaitForChild("HeadFrame"):WaitForChild("TimeTextLabel")

local HttpService = game:GetService("HttpService")

local function t(obj, name)
	local o = obj and obj:FindFirstChild(name, true)
	return (o and o:IsA("TextLabel")) and o.Text or nil
end

local function toSec(s)
	local m, ss = tostring(s or ""):gsub("%s+",""):match("^(%d+):(%d%d)$")
	return m and (tonumber(m) * 60 + tonumber(ss)) or nil
end

local function getMaterialFrames()
	local list = {}
	for _, ch in ipairs(frame2:GetChildren()) do
		local n = ch.Name:match("^Material(%d+)Frame$")
		if n then table.insert(list, {idx = tonumber(n), frame = ch}) end
	end
	table.sort(list, function(a,b) return a.idx < b.idx end)
	return list
end

local function parseQty(text)
	text = tostring(text or "")
	local n = text:match("[Xx]%s*(%d+)")
	if n then return tonumber(n) end
	n = text:match("(%d+)")
	return tonumber(n) or 0
end

local function parseGold(text)
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

local function dumpShopJsonMinimal()
	local mats = getMaterialFrames()
	print(("=== SHOP JSON | materials:%d | timer:%s ==="):format(#mats, timeLbl.Text))

	local used = {}

	for _, it in ipairs(mats) do
		local mf = it.frame
		local main = mf:FindFirstChild("Frame")
		local buy  = mf:FindFirstChild("BuyInFrame")

		local keyName = t(main, "HeadTextLabel") or mf.Name

		-- чтобы ключи не повторялись
		local outKey = keyName
		if used[outKey] then
			outKey = outKey .. "_" .. tostring(it.idx)
		end
		used[outKey] = true

		local rareText = t(main, "RareTextLabel") or "N/A"
		local stockText = t(main, "NumTextLabel") or "N/A"
		local qty = parseQty(stockText)

		local goldText = t(main, "CostTextLabel") or t(buy, "CostTextLabel") or "N/A"
		local gold = parseGold(goldText)

		local data = {
			idx = it.idx,
			rarity = rareText,

			stockText = stockText,
			qty = qty,

			goldText = goldText,
			gold = gold,
		}

		local one = {}
		one[outKey] = data
		print(HttpService:JSONEncode(one))
	end

	print("=== SHOP JSON END ===")
end

-- ✅ Первый дамп сразу при запуске
dumpShopJsonMinimal()

-- ticker + restock detection (timer increased)
local prevSec
task.spawn(function()
	while true do
		local tt = timeLbl.Text
		print("TICKER:", tt)

		local cur = toSec(tt)
		if cur and prevSec and cur > prevSec then
			print(("TIMER INCREASED: %d -> %d (dump shop json)"):format(prevSec, cur))
			dumpShopJsonMinimal()
		end
		prevSec = cur
		task.wait(1)
	end
end)
