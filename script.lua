-- Buy shop debug: print timer every second; when timer increases dump all items
local lp = game:GetService("Players").LocalPlayer
local root = lp.PlayerGui:WaitForChild("BuyScreenGui"):WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("ImageLabel"):WaitForChild("Frame")
local frame2 = root:WaitForChild("MainFrame"):WaitForChild("Frame"):WaitForChild("ScrollingFrame"):WaitForChild("Frame")
local timeLbl = root:WaitForChild("HeadFrame"):WaitForChild("TimeTextLabel")

local function t(obj, name)
	local o = obj and obj:FindFirstChild(name, true)
	return (o and o:IsA("TextLabel")) and o.Text or nil
end

local function img(obj, name)
	local o = obj and obj:FindFirstChild(name, true)
	return (o and o:IsA("ImageLabel")) and o.Image or nil
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

local function dumpShop()
	local mats = getMaterialFrames()
	print(("=== SHOP DUMP | materials:%d | timer:%s ==="):format(#mats, timeLbl.Text))

	for _, it in ipairs(mats) do
		local mf = it.frame
		local main = mf:FindFirstChild("Frame")
		local buy  = mf:FindFirstChild("BuyInFrame")

		local name   = t(main, "HeadTextLabel") or mf.Name
		local rarity = t(main, "RareTextLabel") or "N/A"
		local stock  = t(main, "NumTextLabel") or "N/A"

		local goldRaw = t(main, "CostTextLabel") or t(buy, "CostTextLabel") or "N/A"

		local robux, robux10 = "N/A", "N/A"
		if buy then
			local nums = {}
			for _, d in ipairs(buy:GetDescendants()) do
				if d:IsA("TextLabel") then
					local v = d.Text and d.Text:match("^%d+$")
					if v then table.insert(nums, tonumber(v)) end
				end
			end
			table.sort(nums)
			if #nums >= 1 then robux = tostring(nums[1]) end
			if #nums >= 2 then robux10 = tostring(nums[#nums]) end
		end

		local x10  = t(buy, "XTextLabel")
		local icon = img(main, "ImageLabel") or img(mf, "ImageLabel") or "N/A"

		print(("[#%02d] %s | %s | %s | Gold:%s | Robux:%s | Robux10:%s %s | Icon:%s"):format(
			it.idx, name, rarity, stock, goldRaw, robux, robux10, x10 and ("("..x10..")") or "", icon
		))
	end

	print("=== SHOP DUMP END ===")
end

-- ticker + restock detection (timer increased)
local prevSec
task.spawn(function()
	while true do
		local tt = timeLbl.Text
		print("TICKER:", tt)

		local cur = toSec(tt)
		if cur and prevSec and cur > prevSec then
			print(("TIMER INCREASED: %d -> %d (dump shop)"):format(prevSec, cur))
			dumpShop()
		end
		prevSec = cur
		task.wait(1)
	end
end)
