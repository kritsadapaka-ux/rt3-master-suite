--[[
    ==========================================================================
    RT3 AutoRejoin  (สคริปต์คู่หูของ  Restaurant Tycoon 3: Master Suite v11.4)
    ==========================================================================
    ไว้แก้ปัญหา "AFK แล้วหลุด"

    วิธีใช้ (ทำครั้งเดียว):
      1) วางไฟล์นี้ไว้ในโฟลเดอร์ "auto-execute" ของ executor
         (Delta / MuMu / Codex ส่วนใหญ่มีโฟลเดอร์ชื่อ autoexec หรือ workspace)
         ถ้าหาไม่เจอ: เข้าเกมแล้วกด Execute ไฟล์นี้เองครั้งเดียวก็ได้
      2) ใน Master Suite แท็บ Extra Systems -> เปิด "Auto Rejoin" (เปิดไว้ให้แล้ว)

    Master Suite จะเซฟไว้ให้ 2 ไฟล์:
      - RT3_Self.lua      = ตัวสคริปต์ Master Suite (ถ้า executor อ่าน source ได้)
      - RT3_Session.json  = ห้องล่าสุด (placeId / jobId / เวลา / url)

    ทำงานยังไง:
      1) เข้า Restaurant Tycoon 3 แล้วถ้ายังไม่มีสคริปต์รัน -> โหลด Master Suite ให้
      2) ถ้าเพิ่งหลุดแล้วกลับเข้ามาใหม่ (ไม่เกิน 10 นาที) คนละห้อง -> Teleport กลับห้องเดิมก่อน
      3) แหล่งที่มาของสคริปต์ (ไล่ตามลำดับ):
         RT3_Self.lua  ->  url ใน RT3_Session.json  ->  URL_FALLBACK ด้านล่าง
    ==========================================================================
]]

local RT3_PLACE    = 119048529960596   -- Restaurant Tycoon 3
local PAIR_WINDOW  = 600               -- วินาที: ถือว่าเซสชันยัง "สด" (10 นาที)
local URL_FALLBACK = ""                -- (ไม่บังคับ) raw URL ของสคริปต์

-- ไม่ใช่ RT3 / มีสคริปต์รันอยู่แล้ว -> ไม่ต้องทำอะไร
if game.PlaceId ~= RT3_PLACE then return end
if _G.AutoFarmRunning then return end

local HttpService = game:GetService("HttpService")

-- ------------------------------------------------------------------
-- 1) อ่านเซสชันล่าสุด
-- ------------------------------------------------------------------
local session
if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile("RT3_Session.json") then
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile("RT3_Session.json")) end)
    if ok and type(data) == "table" then session = data end
end

-- ------------------------------------------------------------------
-- 2) กลับเข้าห้องเดิม ถ้าเพิ่งหลุดมา
-- ------------------------------------------------------------------
local needRejoin = false
if session and session.jobId and session.placeId == game.PlaceId and session.jobId ~= game.JobId then
    local age = os.time() - (tonumber(session.ts) or 0)
    if age >= 0 and age <= PAIR_WINDOW then
        needRejoin = true
    end
end

if needRejoin then
    pcall(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(
            session.placeId, session.jobId, game.Players.LocalPlayer)
    end)
    task.wait(3)
end

-- ------------------------------------------------------------------
-- 3) โหลด Master Suite
-- ------------------------------------------------------------------
local loaded = false

-- 3.1 จากไฟล์ที่ Master Suite เซฟไว้ให้
if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile("RT3_Self.lua") then
    loaded = pcall(function()
        loadstring(readfile("RT3_Self.lua"))()
    end)
end

-- 3.2 จาก URL (ในเซสชัน หรือ URL_FALLBACK)
if not loaded then
    local url = (session and tostring(session.url or "") ~= "" and tostring(session.url)) or URL_FALLBACK
    if url and url ~= "" then
        loaded = pcall(function()
            loadstring(game:HttpGet(url))()
        end)
    end
end
