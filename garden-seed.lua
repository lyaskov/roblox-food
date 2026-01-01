-- LocalScript (StarterPlayerScripts)
-- Машиночитаемый вывод для Django, но теперь ДВА отдельных периода:
--   - seed_5m (по seed timer jump)
--   - gear_5m (по seed timer jump, но отдельный batch)
--   - pet_30m (по pet timer jump)
--
-- Формат:
--   PVB|EVT|{json}
--   PVB|BATCH_START|{json}
--   PVB|ITEM|{json}
--   PVB|BATCH_END|{json}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")

-- ===================== НАСТРОЙКИ =====================
local DEVICE_TAG = "emulator-5554"      -- метка (можешь оставить пустой)
local JUMP_TOLERANCE = 1                -- если таймер вырос больше чем на это -> считаем restock
local PRINT_TIMERS_EVERY_SECOND = false -- для отладки (шумит в logcat)

-- ===================== UI PATHS =======================
-- SEED
local seedShop = gui:WaitForChild("Seed_Shop")
local seedRoot = seedShop:WaitForChild("Frame")
local seedScrolling = seedRoot:WaitForChild("ScrollingFrame")
local seedTimerObj = seedRoot:WaitForChild("Frame"):WaitForChild("Timer") -- Seed_Shop.Frame.Frame.Timer

-- GEAR
local gearShop = gui:WaitForChild("Gear_Shop")
local gearRoot = gearShop:WaitForChild("Frame")
local gearScrolling = gearRoot:WaitForChild("ScrollingFrame")

-- PET
local petUI = gui:WaitForChild("PetShop_UI")
local petRoot = petUI:WaitForChild("Frame")
local petScrolling = petRoot:WaitForChild("ScrollingFrame")
local petTimerObj = petRoot:WaitForChild("Frame"):WaitForChild("Timer") -- PetShop_UI.Frame.Frame.Timer

-- ===================== HELPERS =======================
local function safeText(node)
	if node and (node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox")) then
		return node.Text
	end
	return ""
end

-- Подходит для:
-- "New seeds in 3m 8s" / "New seeds in 13s"
-- "Restock: 26m 57s" / "Restock: 13s"
local function parseSeconds(raw)
	raw = tostring(raw or "")
	local m = tonumber(raw:match("(%d+)%s*m")) or 0
	local s = tonumber(raw:match("(%d+)%s*s")) or 0
	return m * 60 + s
end

local function emit(kind, payload)
	payload = payload or {}
	payload.ts = os.time()      -- unix seconds
	payload.device = DEVICE_TAG
	local ok, json = pcall(function() return HttpService:JSONEncode(payload) end)
	if not ok then json = '{"error":"json_encode_failed"}' end
	print(("PVB|%s|%s"):format(kind, json))
end

-- ===================== DUMPS =========================
-- SEEDS: Cost = Main_Frame.Cost_Text.TEXT.Text ; Stock = Main_Frame.Stock_Text.Text ; Name = Seed_Text.Text
local function dumpSeeds(batch_id)
	for _, item in ipairs(seedScrolling:GetChildren()) do
		local main = item:FindFirstChild("Main_Frame")
		if main then
			local nameObj = main:FindFirstChild("Seed_Text")
			if nameObj and (nameObj:IsA("TextLabel") or nameObj:IsA("TextButton") or nameObj:IsA("TextBox")) then
				local costNode = main:FindFirstChild("Cost_Text")
				local costTextNode = costNode and costNode:FindFirstChild("TEXT")

				emit("ITEM", {
					batch_id = batch_id,
					shop = "seed",
					key = item.Name,
					name = nameObj.Text,
					cost = safeText(costTextNode),                      -- Cost_Text.TEXT.Text
					stock = safeText(main:FindFirstChild("Stock_Text")), -- Stock_Text.Text
				})
			end
		end
	end
end

-- GEAR: Cost = Main_Frame.Cost_Text.Text ; Name = Gear_Text.Text ; Stock = Main_Frame.Stock_Text.Text
local function dumpGear(batch_id)
	for _, item in ipairs(gearScrolling:GetChildren()) do
		local main = item:FindFirstChild("Main_Frame")
		if main then
			local nameObj = main:FindFirstChild("Gear_Text")
			if nameObj and (nameObj:IsA("TextLabel") or nameObj:IsA("TextButton") or nameObj:IsA("TextBox")) then
				emit("ITEM", {
					batch_id = batch_id,
					shop = "gear",
					key = item.Name,
					name = nameObj.Text,
					cost = safeText(main:FindFirstChild("Cost_Text")),     -- Cost_Text.Text (без .TEXT)
					stock = safeText(main:FindFirstChild("Stock_Text")),
				})
			end
		end
	end
end

-- PET: Cost = Main_Frame.Cost_Text.Text ; Name = Main_Frame.Seed_Text.Text ; Stock = Main_Frame.Stock_Text.Text
local function dumpPet(batch_id)
	for _, item in ipairs(petScrolling:GetChildren()) do
		local main = item:FindFirstChild("Main_Frame")
		if main then
			local nameObj = main:FindFirstChild("Seed_Text")
			if nameObj and (nameObj:IsA("TextLabel") or nameObj:IsA("TextButton") or nameObj:IsA("TextBox")) then
				emit("ITEM", {
					batch_id = batch_id,
					shop = "pet",
					key = item.Name,
					name = nameObj.Text,
					cost = safeText(main:FindFirstChild("Cost_Text")),
					stock = safeText(main:FindFirstChild("Stock_Text")),
				})
			end
		end
	end
end

local function runBatch(kind, timer_raw, timer_sec, prev_sec, dumpFn)
	local batch_id = HttpService:GenerateGUID(false)

	emit("BATCH_START", {
		batch_id = batch_id,
		kind = kind,            -- "seed_5m" / "gear_5m" / "pet_30m"
		timer_raw = timer_raw,
		timer_sec = timer_sec,
		prev_sec = prev_sec,
	})

	dumpFn(batch_id)

	emit("BATCH_END", {
		batch_id = batch_id,
		kind = kind,
	})
end

-- ===================== LOOP ==========================
local lastSeedSec = nil
local lastPetSec = nil

while true do
	local seedRaw = safeText(seedTimerObj)
	local seedSec = parseSeconds(seedRaw)

	local petRaw = safeText(petTimerObj)
	local petSec = parseSeconds(petRaw)

	if PRINT_TIMERS_EVERY_SECOND then
		emit("EVT", {
			type = "tick",
			seed_sec = seedSec, seed_raw = seedRaw,
			pet_sec = petSec,   pet_raw = petRaw,
		})
	end

	-- SEED TIMER JUMP => запускаем ДВА независимых батча: seed_5m и gear_5m
	if lastSeedSec ~= nil and seedSec > (lastSeedSec + JUMP_TOLERANCE) then
		emit("EVT", {
			type = "seed_timer_jump",
			from_sec = lastSeedSec,
			to_sec = seedSec,
			raw = seedRaw,
		})

		runBatch("seed_5m", seedRaw, seedSec, lastSeedSec, dumpSeeds)
		runBatch("gear_5m", seedRaw, seedSec, lastSeedSec, dumpGear)
	end

	-- PET TIMER JUMP => pet_30m
	if lastPetSec ~= nil and petSec > (lastPetSec + JUMP_TOLERANCE) then
		emit("EVT", {
			type = "pet_timer_jump",
			from_sec = lastPetSec,
			to_sec = petSec,
			raw = petRaw,
		})

		runBatch("pet_30m", petRaw, petSec, lastPetSec, dumpPet)
	end

	lastSeedSec = seedSec
	lastPetSec = petSec

	task.wait(1)
end
