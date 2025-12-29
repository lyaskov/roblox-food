-- LocalScript:
-- 1) Каждую секунду выводит TIMER_SECONDS (из Seed_Shop)
-- 2) Если таймер стал больше (скакнул вверх) -> выводит СТОК Seeds + Gear
--    (таймер учитываем только от seeds)

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")

-- ===== SEEDS UI
local seedShop = gui:WaitForChild("Seed_Shop")
local seedRoot = seedShop:WaitForChild("Frame")
local seedScrolling = seedRoot:WaitForChild("ScrollingFrame")
local timerObj = seedRoot:WaitForChild("Frame"):WaitForChild("Timer") -- Seed_Shop.Frame.Frame.Timer

-- ===== GEAR UI
local gearShop = gui:WaitForChild("Gear_Shop")
local gearRoot = gearShop:WaitForChild("Frame")
local gearScrolling = gearRoot:WaitForChild("ScrollingFrame")

-- ===== helpers
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

-- ===== SEEDS: Cost всегда Main_Frame.Cost_Text.TEXT.Text, Stock = Main_Frame.Stock_Text.Text
local function seedCost(main)
	local cost = main:FindFirstChild("Cost_Text")
	local txt = cost and cost:FindFirstChild("TEXT")
	return getText(txt)
end

local function seedStock(main)
	return getText(main:FindFirstChild("Stock_Text"))
end

local function dumpSeeds()
	print("=== SEED SHOP DUMP ===")
	for _, item in ipairs(seedScrolling:GetChildren()) do
		local main = item:FindFirstChild("Main_Frame")
		if main then
			local seedObj = main:FindFirstChild("Seed_Text")
			if seedObj and (seedObj:IsA("TextLabel") or seedObj:IsA("TextButton") or seedObj:IsA("TextBox")) then
				local seed  = seedObj.Text
				local cost  = seedCost(main)
				local stock = seedStock(main)
				print(string.format("[%s] Seed=%s | Cost=%s | Stock=%s", item.Name, seed, cost, stock))
			end
		end
	end
	print("=== SEED SHOP DUMP END ===")
end

-- ===== GEAR: Cost = Main_Frame.Cost_Text.Text (как ты сказал), Gear_Text.Text, Stock_Text.Text
local function dumpGear()
	print("=== GEAR SHOP DUMP ===")
	for _, item in ipairs(gearScrolling:GetChildren()) do
		local main = item:FindFirstChild("Main_Frame")
		if main then
			local gearObj = main:FindFirstChild("Gear_Text")
			if gearObj and (gearObj:IsA("TextLabel") or gearObj:IsA("TextButton") or gearObj:IsA("TextBox")) then
				local gear  = gearObj.Text
				local cost  = getText(main:FindFirstChild("Cost_Text"))   -- ВАЖНО: без .TEXT
				local stock = getText(main:FindFirstChild("Stock_Text"))
				print(string.format("[%s] Gear=%s | Cost=%s | Stock=%s", item.Name, gear, cost, stock))
			end
		end
	end
	print("=== GEAR SHOP DUMP END ===")
end

local function dumpAll()
	dumpSeeds()
	dumpGear()
end

-- допуск на лаги (если иногда прыгает на +1)
local JUMP_TOLERANCE = 1

local lastSec = nil

while true do
	local raw = getText(timerObj)
	local curSec = parseTimerSeconds(raw)

	local shouldDump = (lastSec ~= nil and curSec > lastSec + JUMP_TOLERANCE)

	if shouldDump then
		print(("TIMER_SECONDS = %d | RAW = %s | (STOCK UPDATE)"):format(curSec, raw))
		dumpAll()
	else
		print(("TIMER_SECONDS = %d | RAW = %s"):format(curSec, raw))
	end

	lastSec = curSec
	task.wait(1)
end
