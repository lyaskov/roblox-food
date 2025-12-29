-- LocalScript:
-- SEEDS timer: Seed_Shop.Frame.Frame.Timer  ("New seeds in 3m 8s" / "New seeds in 13s")
-- GEAR  timer: берём тот же (seeds). При скачке вверх -> dump Seeds+Gear
-- PETS  timer: PetShop_UI.Frame.Frame.Timer ("Restock: 26m 57s")
-- При скачке вверх pet-таймера -> dump PetShop
-- Каждый тик: печатаем SEED_TIMER_SECONDS и PET_TIMER_SECONDS (если PetShop есть)

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")

-- ===================== helpers =====================
local function getText(node)
	if node and (node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox")) then
		return node.Text
	end
	return ""
end

local function parseMinutesSeconds(s)
	s = tostring(s or "")
	local m = tonumber(s:match("(%d+)%s*m")) or 0
	local sec = tonumber(s:match("(%d+)%s*s")) or 0
	return m * 60 + sec
end

local JUMP_TOLERANCE = 1 -- допуск на лаги (если прыгает на +1)

-- ===================== SEEDS UI =====================
local seedShop = gui:WaitForChild("Seed_Shop")
local seedRoot = seedShop:WaitForChild("Frame")
local seedScrolling = seedRoot:WaitForChild("ScrollingFrame")
local seedTimerObj = seedRoot:WaitForChild("Frame"):WaitForChild("Timer") -- Seed_Shop.Frame.Frame.Timer

-- ===================== GEAR UI ======================
local gearShop = gui:WaitForChild("Gear_Shop")
local gearRoot = gearShop:WaitForChild("Frame")
local gearScrolling = gearRoot:WaitForChild("ScrollingFrame")

-- ===================== PET UI =======================
local petUI = gui:WaitForChild("PetShop_UI")
local petRoot = petUI:WaitForChild("Frame")
local petScrolling = petRoot:WaitForChild("ScrollingFrame")
local petTimerObj = petRoot:WaitForChild("Frame"):WaitForChild("Timer") -- PetShop_UI.Frame.Frame.Timer

-- ===================== DUMPS =======================
-- SEEDS: Cost всегда Main_Frame.Cost_Text.TEXT.Text, Stock = Main_Frame.Stock_Text.Text
local function seedCost(main)
	local cost = main:FindFirstChild("Cost_Text")
	local txt = cost and cost:FindFirstChild("TEXT")
	return getText(txt)
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
				local stock = getText(main:FindFirstChild("Stock_Text"))
				print(string.format("[%s] Seed=%s | Cost=%s | Stock=%s", item.Name, seed, cost, stock))
			end
		end
	end
	print("=== SEED SHOP DUMP END ===")
end

-- GEAR: Cost = Main_Frame.Cost_Text.Text, Gear_Text.Text, Stock_Text.Text
local function dumpGear()
	print("=== GEAR SHOP DUMP ===")
	for _, item in ipairs(gearScrolling:GetChildren()) do
		local main = item:FindFirstChild("Main_Frame")
		if main then
			local gearObj = main:FindFirstChild("Gear_Text")
			if gearObj and (gearObj:IsA("TextLabel") or gearObj:IsA("TextButton") or gearObj:IsA("TextBox")) then
				local gear  = gearObj.Text
				local cost  = getText(main:FindFirstChild("Cost_Text")) -- ВАЖНО: без .TEXT
				local stock = getText(main:FindFirstChild("Stock_Text"))
				print(string.format("[%s] Gear=%s | Cost=%s | Stock=%s", item.Name, gear, cost, stock))
			end
		end
	end
	print("=== GEAR SHOP DUMP END ===")
end

local function dumpSeedsAndGear()
	dumpSeeds()
	dumpGear()
end

-- PET: ищем элементы в PetShop_UI.Frame.ScrollingFrame, у которых есть Main_Frame.Seed_Text
-- Price = Main_Frame.Cost_Text.Text
-- Name  = Main_Frame.Seed_Text.Text (да, название лежит в Seed_Text)
-- Stock = Main_Frame.Stock_Text.Text
local function dumpPetShop()
	print("=== PET SHOP DUMP ===")
	for _, item in ipairs(petScrolling:GetChildren()) do
		local main = item:FindFirstChild("Main_Frame")
		if main then
			local nameObj = main:FindFirstChild("Seed_Text")
			if nameObj and (nameObj:IsA("TextLabel") or nameObj:IsA("TextButton") or nameObj:IsA("TextBox")) then
				local name  = nameObj.Text
				local cost  = getText(main:FindFirstChild("Cost_Text"))
				local stock = getText(main:FindFirstChild("Stock_Text"))
				print(string.format("[%s] Pet=%s | Cost=%s | Stock=%s", item.Name, name, cost, stock))
			end
		end
	end
	print("=== PET SHOP DUMP END ===")
end

-- ===================== LOOP =======================
local lastSeedSec = nil
local lastSeedRaw = ""

local lastPetSec = nil
local lastPetRaw = ""

while true do
	-- --- SEEDS timer
	local seedRaw = getText(seedTimerObj) -- "New seeds in ..."
	local seedSec = parseMinutesSeconds(seedRaw)

	-- --- PET timer
	local petRaw = getText(petTimerObj) -- "Restock: 26m 57s"
	local petSec = parseMinutesSeconds(petRaw)

	-- Печатаем время каждый тик
	print(string.format(
		"SEED_TIMER=%ds | PET_TIMER=%ds | seedRaw='%s' | petRaw='%s'",
		seedSec, petSec, seedRaw, petRaw
	))

	-- Если seed timer скакнул вверх -> dump Seeds+Gear
	if lastSeedSec ~= nil and seedSec > lastSeedSec + JUMP_TOLERANCE then
		print(string.format("=== SEED TIMER JUMP: %ds -> %ds ===", lastSeedSec, seedSec))
		dumpSeedsAndGear()
	end

	-- Если pet timer скакнул вверх -> dump PetShop
	if lastPetSec ~= nil and petSec > lastPetSec + JUMP_TOLERANCE then
		print(string.format("=== PET TIMER JUMP: %ds -> %ds ===", lastPetSec, petSec))
		dumpPetShop()
	end

	lastSeedSec = seedSec
	lastSeedRaw = seedRaw

	lastPetSec = petSec
	lastPetRaw = petRaw

	task.wait(1)
end
