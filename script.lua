local lp = game:GetService("Players").LocalPlayer
local timeLbl = lp.PlayerGui.BuyScreenGui.Frame.Frame.ImageLabel.Frame.HeadFrame.TimeTextLabel
local frame2  = lp.PlayerGui.BuyScreenGui.Frame.Frame.ImageLabel.Frame.MainFrame.Frame.ScrollingFrame.Frame

local ROBUX_ID = {
	[1]=3454280304,[2]=3454280617,[3]=3454281079,[4]=3454281359,[5]=3454281756,
	[6]=3454282078,[7]=3454282560,[8]=3454282877,[9]=3454283278,[10]=3454283610,
	[11]=3454283904,[12]=3454284223,[13]=3454284591,[14]=3454284952,[15]=3476293958,
}

local function findText(root, names)
	for _, n in ipairs(names) do
		local o = root and root:FindFirstChild(n, true)
		if o and o:IsA("TextLabel") and o.Text ~= "" then return o.Text end
	end
end

local function firstTextLabelText(root)
	if not root then return nil end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") and d.Text ~= "" then return d.Text end
	end
end

local function stockFrom(text)
	local s = text and text:match("[Xx]%s*(%d+)")
	return s and tonumber(s) or nil
end

local function numFrom(text)
	local s = text and text:match("%d+")
	return s and tonumber(s) or nil
end

local function toSeconds(s)
	s = tostring(s or ""):gsub("%s+","")
	local m, sec = s:match("^(%d+):(%d%d)$")
	if not m then return nil end
	return tonumber(m) * 60 + tonumber(sec)
end

local function dumpShop()
	print("=== SHOP DEBUG (timer increased) ===")
	for i=1,15 do
		local mf = frame2:WaitForChild("Material"..i.."Frame")
		local main = mf:FindFirstChild("Frame")
		local buy  = mf:FindFirstChild("BuyInFrame")

		local name = findText(main, {"NameTextLabel","ItemNameTextLabel","TitleTextLabel","MaterialNameTextLabel","TextLabel"})
			or firstTextLabelText(mf)
			or ("Material "..i)

		local st = stockFrom(findText(main, {"NumTextLabel","StockTextLabel"}))
		local gold = numFrom(findText(buy, {"GoldPriceTextLabel","PriceTextLabel","GoldTextLabel","CostTextLabel"}))

		print(("[#%02d] %s | Stock:%s | Gold:%s | PID:%s"):format(
			i, name, st or "N/A", gold or "N/A", ROBUX_ID[i]
		))
	end
end

-- ticker + trigger on increase
local prevSec = nil

task.spawn(function()
	while true do
		local t = timeLbl.Text
		print("TICKER:", t)

		local curSec = toSeconds(t)
		if curSec and prevSec and curSec > prevSec then
			print(("TIMER INCREASED: %d -> %d"):format(prevSec, curSec))
			dumpShop()
		end

		prevSec = curSec
		task.wait(1)
	end
end)
