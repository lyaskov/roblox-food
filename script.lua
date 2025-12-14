local lp = game:GetService("Players").LocalPlayer
local root = lp.PlayerGui.BuyScreenGui.Frame.Frame.ImageLabel.Frame
local frame2 = root.MainFrame.Frame.ScrollingFrame.Frame
local timeLbl = root.HeadFrame.TimeTextLabel

local function findText(r, names)
	for _, n in ipairs(names) do
		local o = r and r:FindFirstChild(n, true)
		if o and o:IsA("TextLabel") and o.Text ~= "" then return o.Text end
	end
end
local function firstTxt(r)
	for _, d in ipairs((r and r:GetDescendants()) or {}) do
		if d:IsA("TextLabel") and d.Text ~= "" then return d.Text end
	end
end
local function getName(mf)
	local main = mf:FindFirstChild("Frame")
	return findText(main, {"NameTextLabel","ItemNameTextLabel","TitleTextLabel","MaterialNameTextLabel"})
		or firstTxt(mf)
		or mf.Name
end
local function stockFrom(t) local s=t and t:match("[Xx]%s*(%d+)") return s and tonumber(s) end
local function numFrom(t) local s=t and t:match("%d+") return s and tonumber(s) end
local function toSec(s)
	local m, ss = tostring(s or ""):gsub("%s+",""):match("^(%d+):(%d%d)$")
	return m and (tonumber(m)*60 + tonumber(ss)) or nil
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

local function dumpShop()
	local mats = getMaterialFrames()
	print(("=== SHOP | materials: %d ==="):format(#mats))
	for _, it in ipairs(mats) do
		local mf = it.frame
		local main = mf:FindFirstChild("Frame")
		local buy  = mf:FindFirstChild("BuyInFrame")
		local name = getName(mf)
		local st   = stockFrom(findText(main, {"NumTextLabel","StockTextLabel"}))
		local gold = numFrom(findText(buy, {"GoldPriceTextLabel","PriceTextLabel","GoldTextLabel","CostTextLabel"}))
		print(("[#%02d] %s | Stock:%s | Gold:%s"):format(it.idx, name, st or "N/A", gold or "N/A"))
	end
end

local prevSec = nil
task.spawn(function()
	while true do
		local t = timeLbl.Text
		print("TICKER:", t)

		local curSec = toSec(t)
		if curSec and prevSec and curSec > prevSec then
			print(("TIMER INCREASED: %d -> %d"):format(prevSec, curSec))
			dumpShop()
		end
		prevSec = curSec

		task.wait(1)
	end
end)
