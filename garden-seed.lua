-- LocalScript (StarterPlayerScripts)
-- Итог: batch_id оставляем.
-- Каждую секунду печатаем таймеры (seed + pet) в logcat, чтобы ты видел что скрипт живой.
-- При прыжке seed-таймера: отдельные батчи seed_5m и gear_5m (С ЗАДЕРЖКОЙ 2с)
-- При прыжке pet-таймера: батч pet_30m (С ЗАДЕРЖКОЙ 2с)
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
local DEVICE_TAG = "emulator-5554"
local JUMP_TOLERANCE = 1
local PRINT_TIMERS_EVERY_SECOND = true
local AFTER_JUMP_DELAY_SEC = 2 -- <<< задержка после jump перед дампом

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

local function parseSeconds(raw)
	raw = tostring(raw or "")
	local m = tonumber(raw:match("(%d+)%s*m")) or 0
	local s = tonumber(raw:match("(%d+)%s*s")) or 0
	return m * 60 + s
end

local function emit(kind, payload)
	payload = payload or {}
	payload.ts = os.time()
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
					cost = safeText(costTextNode),
					stock = safeText(main:FindFirstChild("Stock_Text")),
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
					cost = safeText(main:FindFirstChild("Cost_Text")),
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
		kind = kind,            -- seed_5m / gear_5m / pet_30m
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

-- ===================== ASYNC "WAIT THEN DUMP" =====================
-- Отдельная блокировка по kind, чтобы seed_5m / gear_5m / pet_30m не мешали друг другу
local pendingByKind = {}

local function scheduleAfterDelay(kind, prev_sec, timerObj, dumpFn, jumpRaw, jumpToSec)
	if pendingByKind[kind] then
		emit("EVT", { type = "skip_schedule_already_pending", kind = kind })
		return
	end

	pendingByKind[kind] = true

	emit("EVT", {
		type = "scheduled_after_jump",
		kind = kind,
		wait_sec = AFTER_JUMP_DELAY_SEC,
		from_sec = prev_sec,
		jump_raw = jumpRaw,
		jump_to_sec = jumpToSec,
	})

	task.spawn(function()
		task.wait(AFTER_JUMP_DELAY_SEC)

		-- перечитываем таймер ПОСЛЕ ожидания (UI уже должен успеть обновить список)
		local raw2 = safeText(timerObj)
		local sec2 = parseSeconds(raw2)

		emit("EVT", {
			type = "dump_after_wait",
			kind = kind,
			timer_raw = raw2,
			timer_sec = sec2,
		})

		runBatch(kind, raw2, sec2, prev_sec, dumpFn)

		pendingByKind[kind] = false
	end)
end

-- ===================== LOOP ==========================
local lastSeedSec = nil
local lastPetSec = nil

while true do
	local seedRaw = safeText(seedTimerObj)
	local seedSec = parseSeconds(seedRaw)

	local petRaw = safeText(petTimerObj)
	local petSec = parseSeconds(petRaw)

	-- каждую секунду печатаем таймеры (скрипт живой)
	if PRINT_TIMERS_EVERY_SECOND then
		emit("EVT", {
			type = "tick",
			seed_sec = seedSec,
			seed_raw = seedRaw,
			pet_sec = petSec,
			pet_raw = petRaw,
		})
	end

	-- seed jump => 2 батча (каждый с задержкой 2с)
	if lastSeedSec ~= nil and seedSec > (lastSeedSec + JUMP_TOLERANCE) then
		emit("EVT", {
			type = "seed_timer_jump",
			from_sec = lastSeedSec,
			to_sec = seedSec,
			raw = seedRaw,
		})

		scheduleAfterDelay("seed_5m", lastSeedSec, seedTimerObj, dumpSeeds, seedRaw, seedSec)
		scheduleAfterDelay("gear_5m", lastSeedSec, seedTimerObj, dumpGear, seedRaw, seedSec)
	end

	-- pet jump => 1 батч (с задержкой 2с)
	if lastPetSec ~= nil and petSec > (lastPetSec + JUMP_TOLERANCE) then
		emit("EVT", {
			type = "pet_timer_jump",
			from_sec = lastPetSec,
			to_sec = petSec,
			raw = petRaw,
		})

		scheduleAfterDelay("pet_30m", lastPetSec, petTimerObj, dumpPet, petRaw, petSec)
	end

	lastSeedSec = seedSec
	lastPetSec = petSec

	task.wait(1)
end
