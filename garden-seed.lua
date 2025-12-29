-- LocalScript: таймер каждую секунду.
-- Если таймер стал БОЛЬШЕ, чем был (значит перезапустился/скакнул вверх) -> выводим сток.

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local gui = lp:WaitForChild("PlayerGui")
local seedShop = gui:WaitForChild("Seed_Shop")
local rootFrame = seedShop:WaitForChild("Frame")

local scrolling = rootFrame:WaitForChild("ScrollingFrame")
local timerObj = rootFrame:WaitForChild("Frame"):WaitForChild("Timer") -- Seed_Shop.Frame.Frame.Timer

local function getText(node)
	if node and (node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox")) then
		return node.Text
	end
	return ""
end

local function parseTimerSeconds(s)
	s = tostring(s or "")
	local m = tonumber(s:match("(%d+)%s*m")) or 0
	local sec = tonumber(s:match("(%d+)%s*s")) or 0
	return m * 60 + sec
end

-- Cost всегда: Main_Frame.Cost_Text.TEXT.Text
local function getCost(main)
	local cost = main:FindFirstChild("Cost_Text")
	local txt = cost and cost:FindFirstChild("TEXT")
	return getText(txt)
end

-- Stock всегда: Main_Frame.Stock_Text.Text
local function getStock(main)
	local stock = main:FindFirstChild("Stock_Text")
	return getText(stock)
end

local function dumpStock()
	print("=== SEED SHOP DUMP ===")
	for _, item in ipairs(scrolling:GetChildren()) do
		local main = item:FindFirstChild("Main_Frame")
		if main then
			local seedObj = main:FindFirstChild("Seed_Text")
			if seedObj and (seedObj:IsA("TextLabel") or seedObj:IsA("TextButton") or seedObj:IsA("TextBox")) then
				local seed  = seedObj.Text
				local cost  = getCost(main)
				local stock = getStock(main)
				print(string.format("[%s] Seed=%s | Cost=%s | Stock=%s", item.Name, seed, cost, stock))
			end
		end
	end
	print("=== SEED SHOP DUMP END ===")
end

-- если хочешь убрать ложные срабатывания из-за лагов на 1-2 сек, поставь 2 или 3
local JUMP_TOLERANCE = 1

local lastSec = nil
local lastRaw = ""

while true do
	local raw = getText(timerObj)
	local curSec = parseTimerSeconds(raw)

	-- Если таймер стал больше -> выводим сток
	if lastSec ~= nil and curSec > lastSec + JUMP_TOLERANCE then
		print(string.format(
			"=== TIMER JUMP: %ds -> %ds | '%s' -> '%s' ===",
			lastSec, curSec, lastRaw, raw
		))
		dumpStock()
	end

	lastSec = curSec
	lastRaw = raw

	task.wait(1)
end
