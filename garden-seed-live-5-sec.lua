-- LocalScript (StarterPlayerScripts)
-- Итог:
-- 1) Каждые 5 секунд печатаем "tick" (seed/pet таймеры), чтобы видно что скрипт живой
-- 2) Каждые 5 секунд делаем ДАМП ВСЕХ 3 БАТЧЕЙ:
--    - seed_5m
--    - gear_5m
--    - pet_30m
-- 3) При первом запуске делаем первый дамп через небольшую задержку, чтобы UI успел прогрузиться
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
local DUMP_EVERY_SEC = 5                -- <<< главное: дамп каждые 5 секунд
local PRINT_TICK_EVERY_SEC = 5          -- <<< тик тоже каждые 5 секунд
local STARTUP_DUMP_DELAY_SEC = 1.5      -- задержка перед самым первым дампом (UI должен заполниться)

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

local function isGuiItem(inst)
	-- чтобы не ловить UIListLayout/прочий мусор
	return inst and inst:IsA("Frame")
end

-- ===================== DUMPS =========================
-- SEEDS: Cost = Main_Frame.Cost_Text.TEXT.Text ; Stock = Main_Frame.Stock_Text.Text ; Name = Seed_Text.Text
local function dumpSeeds(batch_id)
	for _, item in ipairs(seedScrolling:GetChildren()) do
		if isGuiItem(item) then
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
						name = safeText(nameObj),
						cost = safeText(costTextNode),
						stock = safeText(main:FindFirstChild("Stock_Text")),
					})
				end
			end
		end
	end
end

-- GEAR: Cost = Main_Frame.Cost_Text.Text ; Name = Gear_Text.Text ; Stock = Main_Frame.Stock_Text.Text
local function dumpGear(batch_id)
	for _, item in ipairs(gearScrolling:GetChildren()) do
		if isGuiItem(item) then
			local main = item:FindFirstChild("Main_Frame")
			if main then
				local nameObj = main:FindFirstChild("Gear_Text")
				if nameObj and (nameObj:IsA("TextLabel") or nameObj:IsA("TextButton") or nameObj:IsA("TextBox")) then
					emit("ITEM", {
						batch_id = batch_id,
						shop = "gear",
						key = item.Name,
						name = safeText(nameObj),
						cost = safeText(main:FindFirstChild("Cost_Text")),
						stock = safeText(main:FindFirstChild("Stock_Text")),
					})
				end
			end
		end
	end
end

-- PET: Cost = Main_Frame.Cost_Text.Text ; Name = Main_Frame.Seed_Text.Text ; Stock = Main_Frame.Stock_Text.Text
local function dumpPet(batch_id)
	for _, item in ipairs(petScrolling:GetChildren()) do
		if isGuiItem(item) then
			local main = item:FindFirstChild("Main_Frame")
			if main then
				local nameObj = main:FindFirstChild("Seed_Text")
				-- FIX: раньше тут был "node" и из-за этого часть логики ломалась
				if nameObj and (nameObj:IsA("TextLabel") or nameObj:IsA("TextButton") or nameObj:IsA("TextBox")) then
					emit("ITEM", {
						batch_id = batch_id,
						shop = "pet",
						key = item.Name,
						name = safeText(nameObj),
						cost = safeText(main:FindFirstChild("Cost_Text")),
						stock = safeText(main:FindFirstChild("Stock_Text")),
					})
				end
			end
		end
	end
end

local function runBatch(kind, timer_raw, timer_sec, dumpFn)
	local batch_id = HttpService:GenerateGUID(false)

	emit("BATCH_START", {
		batch_id = batch_id,
		kind = kind,            -- seed_5m / gear_5m / pet_30m
		timer_raw = timer_raw,
		timer_sec = timer_sec,
	})

	dumpFn(batch_id)

	emit("BATCH_END", {
		batch_id = batch_id,
		kind = kind,
	})
end

-- ===================== DO FULL DUMP ==================
local function doFullDump()
	local seedRaw = safeText(seedTimerObj)
	local seedSec = parseSeconds(seedRaw)

	local petRaw = safeText(petTimerObj)
	local petSec = parseSeconds(petRaw)

	-- seed и gear используют один и тот же seed таймер (как было у тебя)
	runBatch("seed_5m", seedRaw, seedSec, dumpSeeds)
	runBatch("gear_5m", seedRaw, seedSec, dumpGear)
	runBatch("pet_30m",  petRaw,  petSec,  dumpPet)
end

-- ===================== STARTUP =======================
emit("EVT", { type = "startup", first_dump_in_sec = STARTUP_DUMP_DELAY_SEC })
task.wait(STARTUP_DUMP_DELAY_SEC)
doFullDump()

-- ===================== LOOP (EVERY 5 SEC) ============
local nextTickAt = os.clock()
local nextDumpAt = os.clock()

while true do
	local now = os.clock()

	-- tick раз в 5 секунд
	if now >= nextTickAt then
		local seedRaw = safeText(seedTimerObj)
		local seedSec = parseSeconds(seedRaw)
		local petRaw = safeText(petTimerObj)
		local petSec = parseSeconds(petRaw)

		emit("EVT", {
			type = "tick_5s",
			seed_sec = seedSec,
			seed_raw = seedRaw,
			pet_sec = petSec,
			pet_raw = petRaw,
		})

		nextTickAt = now + PRINT_TICK_EVERY_SEC
	end

	-- полный дамп раз в 5 секунд
	if now >= nextDumpAt then
		emit("EVT", { type = "dump_5s" })
		doFullDump()
		nextDumpAt = now + DUMP_EVERY_SEC
	end

	-- маленький sleep, чтобы не грузить клиент
	task.wait(0.2)
end
