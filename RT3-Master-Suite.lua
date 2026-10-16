-- Restaurant Tycoon 3: Master Suite v11.4 (Stable Edition)
-- Base: v10.0 (Delivery, CurrencyDrops, RushHour, Farming, ScavengerHunt)
-- FIX v11.4 (AFK ALL DAY / กันหลุด):
--   [AFK-1] ต้นเหตุหลัก: สคริปต์ไม่มีระบบกัน AFK เลย -> Roblox เตะทิ้งเมื่อไม่มี input จริง ~20 นาที
--           แก้: VirtualUser:CaptureController + ClickButton2 (จำลอง input จริง) เมื่อ Idled ยิง
--           + เต้นเป็นระยะทุก 45 วิ (กันเคสที่ executor ไม่ยิง Idled)
--           + เต้นเฉพาะตอน "ไม่มีคนเล่น" (ไม่มี input > 100 วิ) -> ไม่กวนเวลานั่งเล่นเอง
--   [AFK-2] ต้นเหตุร่วม (นอกเกม): เครื่องเข้า sleep หลัง 15 นาที -> เน็ตหลุด -> เกมเด้ง
--           แก้ที่เครื่องแล้ว: powercfg standby/hibernate = 0 (ไม่ sleep ทั้ง AC/DC)
--   [AFK-3] Auto Rejoin: game.OnClose แก้ทับไม่ได้ (ตัวเกมตั้งไว้) -> ใช้วิธีบันทึกไฟล์แทน
--           เซฟ RT3_Self.lua (ตัวสคริปต์เอง) + RT3_Session.json (place/job/เวลา) ทุก 60 วิ
--           + สคริปต์คู่หู RT3-AutoRejoin.lua (วางใน auto-execute ของ executor)
--             จะพากลับเข้าห้องเดิมแล้วโหลด Master Suite ต่อให้อัตโนมัติ
--   [AFK-4] AutoRejoinURL: ถ้าอัปขึ้น GitHub แล้ว ใส่ URL ได้ -> โหลดต่ออัตโนมัติ
--   [AFK-5] Stats tab: โชว์ AFK Guard (จำนวนครั้งที่เต้น / idle / เซสชันยาวเท่าไร)
-- FIX v11.3 (SERVING / ทำเงินเร็วขึ้น):
--   [SV-1] แก้บั๊ก holdCap: GrabFood:GetPlayerHoldCapacity() ไม่ส่ง tycoon -> คืน 1
--          ที่จริงมี WaiterTray=3 / WaiterCart=4 -> ผู้เล่นถือของได้ถึง 4 จาน
--   [SV-2] ย้ายการหยิบอาหาร (AttemptGrab) ออกจาก main loop 20Hz -> background task
--          เดิมทุกครั้งที่หยิบ ลูปหลักค้างรอ server (ping) ทำให้เสิร์ฟช้าทั้งระบบ
--   [SV-3] หยิบให้เต็ม holdCap ในรอบเดียว + กันหยิบซ้อน (grabBusy) + แก้ closure จับ g/c ผิด
--   [SV-4] Watchdog กัน "มือตัน": ของที่ค้างในมือ > 8 วิ (server ไม่รับ TaskCompleted) -> ปล่อยอัตโนมัติ
--   [SV-5] ห้ามแย่งจานของไดรฟ์ทรู (ต้นเหตุ "Drive Thru สแปม"):
--          เดิมสคริปต์หยิบจานที่รถไดรฟ์ทรูกำลังรอ -> จานผูก TargetCarId -> แถบล่างเด้ง
--          "Serve ... (Drive Thru Order)" รัว ๆ และรถค้างที่ OrderMade
--          ตอนนี้: ข้ามจานที่รถต้องการ + ตรวจ TargetCarId แล้วคืนทันที + แบล็คกันหยิบซ้ำ 5 วิ
--          (ไม่ใช่ automation ไดรฟ์ทรู — เป็นการ "ไม่ไปกวน" ระบบรถเท่านั้น)
--          (วัดจริงในร้าน: ลูกค้าค้างรออาหาร 33.8 -> 16.7 คน เมื่อเปิดเสิร์ฟ = คิวเคลียร์เร็วขึ้น ~2 เท่า)
-- REMOVED v11.2 (Drive-Thru):
--   [DT-0] เอา Drive-Thru automation ออกทั้งหมด (พนักงานในร้านจัดการเอง)
--          ลบ: worker ไดรฟ์ทรู, รับออเดอร์, เสิร์ฟรถ, เก็บบิลรถ, เปิด/ปิดสถานะร้าน,
--              turbo รถ (CarMovementSequence), toggle/slider ที่เกี่ยวข้อง
-- FIX v11.1 (ประวัติ):
--   [DT-1] ย้ายงาน Drive-Thru ออกจาก main loop 20Hz -> worker แยก (0.15s)
--   [DT-2] กันยิง Serve ซ้ำต่อคัน + rate-limit รับออเดอร์/เก็บบิล
--   [DT-3] รองรับรถหลายออเดอร์ + หยิบ food เฉพาะที่ว่าง (ไม่ Taken)
--   [DT-4] ห้ามระบบ dine-in ยกเลิก food ของไดรฟ์ทรู
--   [DT-5] ปล่อย food ที่ค้างผูกกับรถที่จากไปแล้ว
-- NEW v11.0:
--   [1] Auto Calm Rude / Angry Customers  -> เดินบทสนทนา CustomerAngry อัตโนมัติจนจบ (CalmEnding)
--   [2] Robust Tip Jar  -> อ่าน Furniture ItemType.TipJar (attr Value) แล้วเก็บเฉพาะตอนมีเงินจริง
--   [3] Robust Table Bill / Tip -> event + sweep เก็บครบทุกโต๊ะ
--   [4] Stability -> safe-require, แยก sub-loop แบบ throttle, rate-limit remote, watchdog
--   [5] Many-customer safety -> sweep เก็บ group/order ที่ event ตกหล่น
-- Event-driven hooks throughout

if _G.AutoFarmRunning then
    _G.AutoFarmRunning = false
    task.wait(0.5)
end

-- 1. กู้คืน UI ของตัวเกม
task.spawn(function()
    local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    for _, name in ipairs({"BottomBar","Currency","ScreenWidgets","Apps","RadialButtons","Objectives"}) do
        local gui = pg:FindFirstChild(name)
        if gui and gui:IsA("ScreenGui") then gui.Enabled = true end
    end
end)

-- 2. เคลียร์ Rayfield ตัวเก่า
for _, container in ipairs({
    game.Players.LocalPlayer:FindFirstChild("PlayerGui"),
    typeof(gethui) == "function" and gethui(),
    game:GetService("CoreGui")
}) do
    if container then
        for _, c in ipairs(container:GetChildren()) do
            if c.Name == "Rayfield" then pcall(function() c:Destroy() end) end
        end
    end
end

-- 3. Global Settings
_G.RT3_Settings = {
    MasterAutoFarm   = true,
    AnywhereCook     = true,
    InstantCook      = true,
    AutoSeat         = true,
    AutoOrder        = true,
    AutoServe        = true,
    AutoBill         = true,
    AutoDishes       = true,
    AutoTips         = true,
    AutoCatchDine    = true,

    -- NEW v11.0 : Special (hot-headed) customers
    AutoRude         = true,       -- แก้ปัญหาลูกค้าหัวร้อน / Rude customer อัตโนมัติ
    RudeReply        = "Calm",     -- "Calm" = เลือกคำตอบที่ใจเย็นก่อน | "First" | "Last"
    RudeDebug        = false,      -- พิมพ์บทสนทนาลง console เพื่อปรับจูน

    NpcTurboWalk      = true,
    NpcWalkSpeed      = 75,
    NpcTimeMultiplier = 5,

    Infinite15xBoost   = true,
    AutoClaimOffline   = true,

    AutoDelivery       = true,
    AutoCollectDrops   = true,
    AutoRushHour       = true,
    AutoHarvest        = true,
    AutoScavenger      = true,

    -- Engine tuning (v11.0)
    TickRate           = 0.05,     -- main loop (20 Hz) : serve
    SlowTick           = 1.0,      -- slow loop (1 Hz)   : tips/bills/sweeps
    RemoteCooldown     = 0.85,     -- กันสแปม remote (วินาที)

    -- AFK Guardian (v11.4) : กันหลุดตอน AFK ทั้งวัน
    AntiAFK            = true,     -- จำลอง input กัน Roblox เตะทิ้ง idle 20 นาที
    AntiAFKInterval    = 45,       -- เต้นกัน idle ทุกกี่วินาที (วินาที)
    AutoRejoin         = true,     -- พยายามกลับเข้าห้องเดิมถ้าหลุด
    AutoRejoinURL      = "https://raw.githubusercontent.com/kritsadapaka-ux/rt3-master-suite/main/RT3-Master-Suite.lua",
                                   -- ^ URL ของ Master Suite เอง (ใช้เป็นแหล่งสำรองตอนกลับเข้าเกมใหม่)

    Friend_MasterFarm    = true,
    Friend_AutoSeat      = true,
    Friend_AutoOrder     = true,
    Friend_AutoCook      = true,
    Friend_AutoServe     = true,
    Friend_AutoBill      = true,
    Friend_AutoDishes    = true,
    Friend_AutoTips      = true,
    Friend_AutoCatchDine = true,
    Friend_AutoDelivery  = true,
    Friend_AutoRude      = true,
}

-- 4. Rayfield UI (ASYNC + guarded: โหลด UI เบื้องหลัง, engine เริ่มทันทีไม่รอ HTTP)
local Rayfield, Window
local function stubLabel() return { Set = function() end } end
local CashLabel, CustomerLabel, FoodLabel, DeliveryLabel, DropsLabel, RushLabel, RudeLabel, HealthLabel, FriendStatsLabel, FriendInfoLabel =
    stubLabel(), stubLabel(), stubLabel(), stubLabel(), stubLabel(), stubLabel(), stubLabel(), stubLabel(), stubLabel(), stubLabel()
local function notify(title, content, dur)
    if Rayfield and Rayfield.Notify then
        pcall(function()
            Rayfield:Notify({ Title = title, Content = content, Duration = dur or 6, Image = 4483362458 })
        end)
    end
end

task.spawn(function()
local okUI, uiErr = pcall(function()
Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

Window = Rayfield:CreateWindow({
    Name = "Restaurant Tycoon 3 | Master Suite v11.4",
    LoadingTitle = "RT3 Suite v11.4",
    LoadingSubtitle = "Stable Edition",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

task.defer(function()
    local hui = typeof(gethui) == "function" and gethui()
    local rf = (hui and hui:FindFirstChild("Rayfield"))
        or game.Players.LocalPlayer.PlayerGui:FindFirstChild("Rayfield")
        or game:GetService("CoreGui"):FindFirstChild("Rayfield")
    if rf then
        rf.Parent = game.Players.LocalPlayer.PlayerGui
        rf.Enabled = true
        rf:GetPropertyChangedSignal("Enabled"):Connect(function()
            if not rf.Enabled then rf.Enabled = true end
        end)
    end
end)

local MainTab   = Window:CreateTab("My Restaurant",  4483362458)
local BoostTab  = Window:CreateTab("Speed & Boost",  4483362458)
local ExtraTab  = Window:CreateTab("Extra Systems",  4483362458)
local FriendTab = Window:CreateTab("Friend Farm",    4483362458)
local StatsTab  = Window:CreateTab("Stats",          4483362458)

-- MAIN TAB
MainTab:CreateToggle({ Name = "Master Auto Farm (My Restaurant)", CurrentValue = true, Flag = "MasterToggle",
    Callback = function(v) _G.RT3_Settings.MasterAutoFarm = v end })
MainTab:CreateSection("Seating & Orders")
MainTab:CreateToggle({ Name = "Native Auto Seat (Zero Latency)",   CurrentValue = true, Flag = "AutoSeat",
    Callback = function(v) _G.RT3_Settings.AutoSeat = v end })
MainTab:CreateToggle({ Name = "Instant Auto Order (Event Driven)", CurrentValue = true, Flag = "AutoOrder",
    Callback = function(v) _G.RT3_Settings.AutoOrder = v end })
MainTab:CreateSection("Cooking & Serving")
MainTab:CreateToggle({ Name = "Anywhere Cook (Free Movement)",     CurrentValue = true, Flag = "AnywhereCook",
    Callback = function(v) _G.RT3_Settings.AnywhereCook = v end })
MainTab:CreateToggle({ Name = "Instant Cook Bypass (0s)",          CurrentValue = true, Flag = "InstantCook",
    Callback = function(v) _G.RT3_Settings.InstantCook = v end })
MainTab:CreateToggle({ Name = "Smart Order Match & Serve",         CurrentValue = true, Flag = "AutoServe",
    Callback = function(v) _G.RT3_Settings.AutoServe = v end })
MainTab:CreateSection("Cleaning & Bills")
MainTab:CreateToggle({ Name = "Instant Bill Collector",            CurrentValue = true, Flag = "AutoBill",
    Callback = function(v) _G.RT3_Settings.AutoBill = v end })
MainTab:CreateToggle({ Name = "Instant Dish Cleaner",              CurrentValue = true, Flag = "AutoDishes",
    Callback = function(v) _G.RT3_Settings.AutoDishes = v end })
MainTab:CreateToggle({ Name = "Auto Collect Tip Jar (Value-Aware)", CurrentValue = true, Flag = "AutoTips",
    Callback = function(v) _G.RT3_Settings.AutoTips = v end })
MainTab:CreateToggle({ Name = "Auto Catch Dine & Dash",            CurrentValue = true, Flag = "AutoCatch",
    Callback = function(v) _G.RT3_Settings.AutoCatchDine = v end })
MainTab:CreateSection("Special Customers (NEW)")
MainTab:CreateToggle({ Name = "Auto Calm Rude / Angry Customers",  CurrentValue = true, Flag = "AutoRude",
    Callback = function(v) _G.RT3_Settings.AutoRude = v end })
MainTab:CreateToggle({ Name = "Rude Debug Log (console)",          CurrentValue = false, Flag = "RudeDebug",
    Callback = function(v) _G.RT3_Settings.RudeDebug = v end })

-- BOOST TAB
BoostTab:CreateSection("Passive Boosters")
BoostTab:CreateToggle({ Name = "Infinite +15% Cash Boost (No Ads)", CurrentValue = true, Flag = "AdBoost",
    Callback = function(v) _G.RT3_Settings.Infinite15xBoost = v end })
BoostTab:CreateToggle({ Name = "Auto Claim Offline Earnings",       CurrentValue = true, Flag = "Offline",
    Callback = function(v) _G.RT3_Settings.AutoClaimOffline = v end })
BoostTab:CreateSection("Engine Speed Tweaks")
BoostTab:CreateSlider({ Name = "Customer Sprint Speed", Range = {10,150}, Increment = 5,  CurrentValue = 75, Flag = "NpcSpd",
    Callback = function(v) _G.RT3_Settings.NpcWalkSpeed = v end })
BoostTab:CreateSlider({ Name = "Walk Frame Multiplier", Range = {1,10},   Increment = 1,  CurrentValue = 5,  Flag = "NpcMul",
    Callback = function(v) _G.RT3_Settings.NpcTimeMultiplier = v end })

-- EXTRA TAB
ExtraTab:CreateSection("Delivery System")
ExtraTab:CreateToggle({ Name = "Auto Delivery (Accept & Complete)", CurrentValue = true, Flag = "AutoDelivery",
    Callback = function(v) _G.RT3_Settings.AutoDelivery = v end })
ExtraTab:CreateSection("Economy")
ExtraTab:CreateToggle({ Name = "Auto Collect Currency Drops",       CurrentValue = true, Flag = "AutoDrops",
    Callback = function(v) _G.RT3_Settings.AutoCollectDrops = v end })
ExtraTab:CreateToggle({ Name = "Auto Activate Rush Hour",           CurrentValue = true, Flag = "AutoRush",
    Callback = function(v) _G.RT3_Settings.AutoRushHour = v end })
ExtraTab:CreateSection("Farm & Explore")
ExtraTab:CreateToggle({ Name = "Auto Harvest Farm Tiles",           CurrentValue = true, Flag = "AutoHarvest",
    Callback = function(v) _G.RT3_Settings.AutoHarvest = v end })
ExtraTab:CreateToggle({ Name = "Auto Collect Scavenger Hunt Items", CurrentValue = true, Flag = "AutoScav",
    Callback = function(v) _G.RT3_Settings.AutoScavenger = v end })

ExtraTab:CreateSection("AFK / กันหลุด (v11.4)")
ExtraTab:CreateToggle({ Name = "Anti-AFK (กันเตะ idle 20 นาที)", CurrentValue = true, Flag = "AntiAFK",
    Callback = function(v) _G.RT3_Settings.AntiAFK = v end })
ExtraTab:CreateSlider({ Name = "จังหวะเต้นกัน idle", Range = {20, 300}, Increment = 5, Suffix = " วิ",
    CurrentValue = 45, Flag = "AntiAFKInt",
    Callback = function(v) _G.RT3_Settings.AntiAFKInterval = v end })
ExtraTab:CreateToggle({ Name = "Auto Rejoin (หลุดแล้วกลับห้องเดิม)", CurrentValue = true, Flag = "AutoRejoin",
    Callback = function(v) _G.RT3_Settings.AutoRejoin = v end })
ExtraTab:CreateButton({ Name = "ทดสอบกัน AFK เดี๋ยวนี้", Callback = function()
    if _G.RT3_AFKPulse then _G.RT3_AFKPulse("manual") end
end })
ExtraTab:CreateInput({ Name = "AutoRejoinURL (ไม่บังคับ)", PlaceholderText = "raw URL ของสคริปต์ หลังอัป GitHub",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt) _G.RT3_Settings.AutoRejoinURL = tostring(txt) end })

-- FRIEND TAB
FriendTab:CreateToggle({ Name = "Help Friends (Master Toggle)", CurrentValue = true, Flag = "FriendMaster",
    Callback = function(v) _G.RT3_Settings.Friend_MasterFarm = v end })
FriendInfoLabel = FriendTab:CreateLabel("Detected Friends: Scanning...")
FriendTab:CreateSection("Friend Actions")
FriendTab:CreateToggle({ Name = "Auto Seat & Take Orders",          CurrentValue = true, Flag = "FriendSeatOrder",
    Callback = function(v) _G.RT3_Settings.Friend_AutoSeat = v; _G.RT3_Settings.Friend_AutoOrder = v end })
FriendTab:CreateToggle({ Name = "Auto Cook & Serve",                CurrentValue = true, Flag = "FriendCookServe",
    Callback = function(v) _G.RT3_Settings.Friend_AutoCook = v; _G.RT3_Settings.Friend_AutoServe = v end })
FriendTab:CreateToggle({ Name = "Auto Clear Dishes, Bills & Tips",  CurrentValue = true, Flag = "FriendClean",
    Callback = function(v) _G.RT3_Settings.Friend_AutoDishes = v; _G.RT3_Settings.Friend_AutoBill = v; _G.RT3_Settings.Friend_AutoTips = v end })
FriendTab:CreateToggle({ Name = "Auto Calm Rude (Friends)",         CurrentValue = true, Flag = "FriendRude",
    Callback = function(v) _G.RT3_Settings.Friend_AutoRude = v end })
FriendTab:CreateToggle({ Name = "Auto Delivery (Friends)",          CurrentValue = true, Flag = "FriendDelivery",
    Callback = function(v) _G.RT3_Settings.Friend_AutoDelivery = v end })

-- STATS TAB
CashLabel        = StatsTab:CreateLabel("Current Cash: Loading...")
CustomerLabel    = StatsTab:CreateLabel("My Customers: 0")
FoodLabel        = StatsTab:CreateLabel("Food Ready: 0")
DeliveryLabel    = StatsTab:CreateLabel("Deliveries: 0 active")
DropsLabel       = StatsTab:CreateLabel("Drops Collected: 0")
RushLabel        = StatsTab:CreateLabel("Rush Hour: Inactive")
RudeLabel        = StatsTab:CreateLabel("Rude Calmed: 0 | Active: 0")
HealthLabel      = StatsTab:CreateLabel("Engine: Booting...")
AFKLabel         = StatsTab:CreateLabel("AFK Guard: Booting...")
FriendStatsLabel = StatsTab:CreateLabel("Friend Status: Idle")
end) -- end of guarded UI
_G.RT3_UIError = (not okUI) and tostring(uiErr) or nil
if not okUI then
    warn("[RT3 v11] UI failed to build: " .. tostring(uiErr))
end
end) -- end of async UI task

-- ==========================================
-- 5. CORE LOGIC ENGINE (v11.0 Stable)
-- ==========================================
task.spawn(function()
  _G.RT3_BootStage = "boot"
  local _ok, _err = xpcall(function()
    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace         = game:GetService("Workspace")
    local LocalPlayer       = Players.LocalPlayer

    -- 5.1 SAFE REQUIRE (โมดูลตัวไหนพัง ตัวอื่นยังรันต่อได้)
    local _warned = {}
    local function req(label, getter)
        local ok, inst = pcall(getter)
        if not ok or inst == nil then
            if not _warned[label] then
                _warned[label] = true
                warn("[RT3 v11] get failed -> " .. label .. " : " .. tostring(inst))
            end
            return nil
        end
        local ok2, mod = pcall(require, inst)
        if ok2 and mod ~= nil then return mod end
        if not _warned[label] then
            _warned[label] = true
            warn("[RT3 v11] require failed -> " .. label .. " : " .. tostring(mod))
        end
        return nil
    end

    local PS = LocalPlayer:WaitForChild("PlayerScripts")
    local focusedTycoon   = req("FocusedTycoon",  function() return PS.Source.Systems.FocusedTycoon end)
    local Customers       = req("Customers",      function() return PS.Source.Systems.Restaurant.Customers end)
    local TakeOrder       = req("TakeOrder",      function() return PS.Source.Modules.Tasks.TakeOrder end)
    local GrabFood        = req("GrabFood",       function() return PS.Source.Systems.Restaurant.GrabFood end)
    local ServeFood       = req("ServeFood",      function() return PS.Source.Modules.Tasks.ServeFood end)
    local Cook            = req("Cook",           function() return PS.Source.Systems.Cook end)
    local CookingPrompts  = req("CookingPrompts", function() return PS.Source.Systems.Cook.CookingPrompts end)
    local CookingCamera   = req("CookingCamera",  function() return PS.Source.Systems.Cook.CookingCamera end)
    local Interactions    = req("Interactions",   function() return PS.Source.Systems.Restaurant.Interactions end)
    local Managers        = req("Managers",       function() return PS.Source.Systems.Managers end)
    local Delivery        = req("Delivery",       function() return PS.Source.Systems.Restaurant.Delivery end)
    -- v11.3: อ่านอย่างเดียว เพื่อ "ไม่ไปแย่งจานของไดรฟ์ทรู" (ไม่ใช่ automation)
    local DriveThru       = req("DriveThru",      function() return PS.Source.Systems.Restaurant.DriveThru end)
    local CurrencyDrops   = req("CurrencyDrops",  function() return PS.Source.Systems.Currency.CurrencyDrops end)
    local RushHour        = req("RushHour",       function() return PS.Source.Systems.RushHour end)
    local Farming         = req("Farming",        function() return PS.Source.Systems.Farming end)
    local ScavengerHunt   = req("ScavengerHunt",  function() return PS.Source.Systems.ScavengerHunt end)
    local PlayerData      = req("PlayerData",     function() return PS.Source.Systems.PlayerData end)

    local DummyWalkSequence   = req("DummyWalkSequence",   function() return ReplicatedStorage.Source.Modules.Objects.DummyWalkSequence end)
    local TaskEnum            = req("TaskEnum",            function() return ReplicatedStorage.Source.Enums.Restaurant.Task end)
    local CookReplication     = req("CookReplication",     function() return ReplicatedStorage.Source.Enums.Cook.CookReplication end)
    local CookUtility         = req("CookUtility",         function() return ReplicatedStorage.Source.Utility.Cook.CookUtility end)
    local ControlsUtility     = req("ControlsUtility",     function() return ReplicatedStorage.Source.Utility.Input.ControlsUtility end)
    local CustomerState       = req("CustomerState",       function() return ReplicatedStorage.Source.Enums.Restaurant.Customer.CustomerState end)
    local CustomerType        = req("CustomerType",        function() return ReplicatedStorage.Source.Enums.Restaurant.Customer.CustomerType end)
    local FurnitureUtility    = req("FurnitureUtility",    function() return ReplicatedStorage.Source.Utility.FurnitureUtility end)
    local ItemType            = req("ItemType",            function() return ReplicatedStorage.Source.Enums.Placement.ItemType end)

    local Events = ReplicatedStorage:WaitForChild("Events", 10) or ReplicatedStorage:FindFirstChild("Events")

    if not Customers or not focusedTycoon or not Events then
        notify("RT3 v11.0 : โหลดไม่สำเร็จ", "หาโมดูลหลัก (Customers/FocusedTycoon/Events) ไม่เจอ — เกมอาจอัปเดต", 8)
        return
    end
    _G.RT3_BootStage = "modules-ok"

    -- 5.2 HELPERS
    local function fireThrottled(key, interval, fn)
        _G.__RT3_LastFire = _G.__RT3_LastFire or {}
        local now = os.clock()
        local last = _G.__RT3_LastFire[key]
        if last and (now - last) < (interval or _G.RT3_Settings.RemoteCooldown) then return false end
        _G.__RT3_LastFire[key] = now
        local ok, err = pcall(fn)
        if not ok and _G.RT3_Settings.RudeDebug then
            warn("[RT3 v11] fire error " .. key .. " : " .. tostring(err))
        end
        return ok
    end

    local function isTargetTycoon(tycoon)
        if not tycoon then return false, false end
        if _G.RT3_Settings.MasterAutoFarm and tycoon == focusedTycoon:Get() then return true, false end
        if _G.RT3_Settings.Friend_MasterFarm and tycoon ~= focusedTycoon:Get() then
            if Managers and Managers:HasPermission(tycoon, Managers.PermissionLevel.Employee) then return true, true end
        end
        return false, false
    end

    local function hasManager(tycoon)
        if not Managers then return false end
        local ok, res = pcall(function() return Managers:HasPermission(tycoon, Managers.PermissionLevel.Manager) end)
        return ok and res
    end

    -- ==========================================
    -- 5.3 SPECIAL: RUDE / ANGRY CUSTOMER RESOLVER
    -- ==========================================
    -- เกมจริง: Rude customer -> state CustomerAngry -> ProximityPrompt -> GetRudeCustomerDialog(RemoteFunction)
    -- เราจะ "เดินบทสนทนา" แทนผู้เล่นจนจบ เพื่อให้จบด้วย CalmEnding แล้ว state หลุดออกจาก CustomerAngry
    local RUDE_CALM_KW = {
        "calm", "chill", "relax", "take it easy", "cool down",
        "sorry", "apolog", "sorry", "forgive", "my bad",
        "please", "pleas", "help", "kind", "nice", "polite",
        "free", "gift", "discount", "on the house", "compliment", "refund",
    }

    local function toArray(t)
        local a = {}
        if type(t) ~= "table" then return a end
        for _, v in ipairs(t) do a[#a + 1] = v end
        if #a == 0 then for _, v in pairs(t) do a[#a + 1] = v end end
        return a
    end

    local function responseText(r)
        if type(r) == "string" then return r end
        if type(r) == "table" then
            return tostring(r.Text or r.Response or r.Label or r.Name or "")
        end
        return tostring(r)
    end

    local function pickRudeResponse(list)
        if #list == 0 then return nil end
        local mode = _G.RT3_Settings.RudeReply or "Calm"
        if mode == "First" then return list[1] end
        if mode == "Last" then return list[#list] end
        -- "Calm" : เลือกคำตอบที่ใจเย็นก่อน, ถ้าไม่มีให้เอาอันแรก
        for _, r in ipairs(list) do
            local low = string.lower(responseText(r))
            for _, kw in ipairs(RUDE_CALM_KW) do
                if string.find(low, kw, 1, true) then return r end
            end
        end
        return list[1]
    end

    local activeRude = {}
    local rudeCalmed = 0
    local rudeEndings = {}
    local GetRudeDialog = Events.Restaurant
        and Events.Restaurant.Customers
        and Events.Restaurant.Customers:FindFirstChild("GetRudeCustomerDialog")

    local function resolveRude(tycoon, groupId, customerId)
        if not GetRudeDialog then return end
        if not hasManager(tycoon) then return end
        local key = tostring(tycoon) .. "|" .. tostring(groupId) .. "|" .. tostring(customerId)
        if activeRude[key] then return end
        activeRude[key] = true

        task.spawn(function()
            -- เก็บ prompt ที่เกมสร้างไว้ เพื่อไม่ให้ผู้เล่นกดซ้ำ (กัน dialog ซ้อน)
            pcall(function()
                local cData = Customers:GetCustomerData(tycoon, groupId, customerId)
                local dummy = cData and cData.Dummy
                local hrp = dummy and dummy:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local p = hrp:FindFirstChildOfClass("ProximityPrompt")
                    if p then p:Destroy() end
                end
            end)

            local choice = nil
            for step = 1, 24 do
                if not _G.RT3_Settings.AutoRude and not _G.RT3_Settings.Friend_AutoRude then break end
                local ok, texts, responses = pcall(function()
                    return GetRudeDialog:InvokeServer(tycoon, groupId, customerId, choice)
                end)
                if not ok then
                    if _G.RT3_Settings.RudeDebug then warn("[RT3 v11] rude invoke error: " .. tostring(texts)) end
                    break
                end
                if texts == nil then break end
                local list = toArray(responses)
                if #list == 0 then break end
                choice = pickRudeResponse(list)
                if choice == nil then break end
                if _G.RT3_Settings.RudeDebug then
                    print(("[RT3 v11] Rude step %d -> reply: %s"):format(step, responseText(choice)))
                end
                task.wait(0.12)
            end
            activeRude[key] = nil
        end)
    end

    -- ==========================================
    -- 5.4 ENGINE HOOKS (speed / cook) — guarded
    -- ==========================================
    if DummyWalkSequence then
        if not DummyWalkSequence._OrigUpdate then
            DummyWalkSequence._OrigUpdate = DummyWalkSequence.Update
            DummyWalkSequence.Update = function(self, dt)
                if _G.RT3_Settings.NpcTurboWalk then
                    self.Speed = _G.RT3_Settings.NpcWalkSpeed or 75
                    dt = dt * (_G.RT3_Settings.NpcTimeMultiplier or 5)
                end
                return DummyWalkSequence._OrigUpdate(self, dt)
            end
        end
        if not DummyWalkSequence._OrigNew then
            DummyWalkSequence._OrigNew = DummyWalkSequence.new
            DummyWalkSequence.new = function(dummy, path)
                local seq = DummyWalkSequence._OrigNew(dummy, path)
                if seq and _G.RT3_Settings.NpcTurboWalk then
                    seq.Speed = _G.RT3_Settings.NpcWalkSpeed or 75
                end
                return seq
            end
        end
    end

    if CookUtility and CookUtility.LockCharacterToModel and not CookUtility._OrigLock then
        CookUtility._OrigLock = CookUtility.LockCharacterToModel
        CookUtility.LockCharacterToModel = function(self, player, kitchenModel)
            if _G.RT3_Settings.AnywhereCook and player == LocalPlayer then return nil end
            return CookUtility._OrigLock(self, player, kitchenModel)
        end
    end
    if CookingCamera and CookingCamera.LockToStation and not CookingCamera._OrigLock then
        CookingCamera._OrigLock = CookingCamera.LockToStation
        CookingCamera.LockToStation = function(self, station)
            if _G.RT3_Settings.AnywhereCook then return nil end
            return CookingCamera._OrigLock(self, station)
        end
    end
    if ControlsUtility and ControlsUtility.Disable and not ControlsUtility._OrigDisable then
        ControlsUtility._OrigDisable = ControlsUtility.Disable
        ControlsUtility.Disable = function(...)
            if _G.RT3_Settings.AnywhereCook then return nil end
            return ControlsUtility._OrigDisable(...)
        end
    end

    local function fireInstantCook(kitchenModel, itemType)
        task.defer(function()
            pcall(function()
                Events.Cook.CookInputRequested:FireServer(CookReplication.Interact, kitchenModel, itemType)
                task.wait(0.01)
                Events.Cook.CookInputRequested:FireServer(CookReplication.CompleteTask, kitchenModel, itemType)
            end)
        end)
    end

    if Cook and Cook.OnPlayerDirectedToEquipment and not Cook._OrigDirected then
        Cook._OrigDirected = Cook.OnPlayerDirectedToEquipment
        Cook.OnPlayerDirectedToEquipment = function(self, kitchenModel, itemType, instructionKey, actionText)
            if not _G.RT3_Settings.AnywhereCook then
                pcall(Cook._OrigDirected, self, kitchenModel, itemType, instructionKey, actionText)
            else
                self.CurrentItemType = itemType
                self.CurrentKitchenModel = kitchenModel
            end
            if _G.RT3_Settings.InstantCook then fireInstantCook(kitchenModel, itemType) end
        end
    end

    if CookingPrompts and CookingPrompts.GetOrCreate and not CookingPrompts._OrigGetOrCreate then
        CookingPrompts._OrigGetOrCreate = CookingPrompts.GetOrCreate
        CookingPrompts.GetOrCreate = function(self, kitchenModel, itemType)
            local p = CookingPrompts._OrigGetOrCreate(self, kitchenModel, itemType)
            if _G.RT3_Settings.InstantCook then fireInstantCook(kitchenModel, itemType) end
            return p
        end
    end

    if Cook and Cook.EquipmentModules then
        for _, mod in pairs(Cook.EquipmentModules) do
            if mod.OnInteractionUpdated and not mod._OrigInteract then
                mod._OrigInteract = mod.OnInteractionUpdated
                mod.OnInteractionUpdated = function(self, player, tycoon, kitchenModel, equipmentName, isProgress, stepParams)
                    if not _G.RT3_Settings.AnywhereCook then
                        pcall(mod._OrigInteract, self, player, tycoon, kitchenModel, equipmentName, isProgress, stepParams)
                    end
                    if _G.RT3_Settings.InstantCook then
                        task.defer(function()
                            pcall(function()
                                if mod.TaskCompleted and stepParams then
                                    mod.TaskCompleted:Fire(player or LocalPlayer, tycoon or focusedTycoon:Get(), kitchenModel, equipmentName, stepParams)
                                end
                                Events.Cook.CookInputRequested:FireServer(CookReplication.CompleteTask, kitchenModel, equipmentName, stepParams)
                            end)
                        end)
                    end
                    return nil
                end
            end
        end
    end

    -- ==========================================
    -- 5.4b RE-RUN SAFETY: ตัด connection รอบก่อน (กัน event ซ้อน)
    -- ==========================================
    if _G.RT3_Conns then
        for _, c in ipairs(_G.RT3_Conns) do pcall(function() if c.Disconnect then c:Disconnect() end end) end
    end
    _G.RT3_Conns = {}
    local function on(sig, fn)
        if not sig then return nil end
        local conn = sig:Connect(fn)
        table.insert(_G.RT3_Conns, conn)
        return conn
    end

    -- ==========================================
    -- 5.5 EVENT: SEATING
    -- ==========================================
    if Customers.GroupStateChanged then
        on(Customers.GroupStateChanged, function(tycoon, groupId, oldState, newState)
            local valid, isFriend = isTargetTycoon(tycoon)
            if not valid then return end
            if (isFriend and _G.RT3_Settings.Friend_AutoSeat or _G.RT3_Settings.AutoSeat)
                and (newState == "Entered" or newState == "Entering") then
                Events.Restaurant.TaskCompleted:FireServer({ Name = TaskEnum.SendToTable, GroupId = groupId, Tycoon = tycoon })
            end
        end)
    end

    -- ==========================================
    -- 5.6 EVENT: ORDERS / DINE&DASH / RUDE
    -- ==========================================
    on(Customers.CustomerStateChanged, function(tycoon, groupId, customerId, oldState, newState)
        local valid, isFriend = isTargetTycoon(tycoon)
        if not valid then return end

        -- Auto Order
        if (isFriend and _G.RT3_Settings.Friend_AutoOrder or _G.RT3_Settings.AutoOrder)
            and newState == CustomerState.Ordering then
            pcall(function() TakeOrder:TakeOrder(tycoon, groupId, customerId) end)
        end

        -- Dine & Dash
        if (isFriend and _G.RT3_Settings.Friend_AutoCatchDine or _G.RT3_Settings.AutoCatchDine)
            and newState == CustomerState.DineAndDashing then
            pcall(function()
                Events.Restaurant.Customers.DineAndDashCaught:FireServer(tycoon, groupId, customerId)
            end)
        end

        -- Rude / Angry customer  >>> NEW v11.0
        if newState == CustomerState.CustomerAngry then
            if (isFriend and _G.RT3_Settings.Friend_AutoRude or _G.RT3_Settings.AutoRude) then
                resolveRude(tycoon, groupId, customerId)
            end
        elseif newState == CustomerState.CustomerAngry_CalmEnding then
            rudeCalmed = rudeCalmed + 1
        end
    end)

    -- ==========================================
    -- 5.8 EVENT: AUTO DELIVERY (Drive-Thru ปิดใช้งาน: พนักงานในร้านจัดการเอง)
    -- ==========================================
    local deliveryCount = 0
    if Delivery and Delivery.OrderStateChanged then
        on(Delivery.OrderStateChanged, function(orderId, newState)
            local myTycoon = focusedTycoon:Get()
            if not myTycoon then return end
            local enabled = _G.RT3_Settings.AutoDelivery
            if not enabled then return end
            local DS = Delivery.DeliveryState
            if DS and (newState == DS.Ringing or newState == "Ringing") then
                task.defer(function()
                    pcall(function()
                        Events.Restaurant.TaskCompleted:FireServer({
                            Name = TaskEnum.TakeDeliveryOrder,
                            DeliveryId = orderId,
                            Tycoon = myTycoon,
                            DeliveryAccepted = true,
                        })
                    end)
                end)
            elseif DS and (newState == DS.ReadyForPickup or newState == "ReadyForPickup") then
                task.defer(function()
                    pcall(function()
                        Events.Restaurant.TaskCompleted:FireServer({
                            Name = TaskEnum.DeliverOrder,
                            DeliveryId = orderId,
                            Tycoon = myTycoon,
                        })
                        deliveryCount = deliveryCount + 1
                    end)
                end)
            end
        end)
    end

    -- ==========================================
    -- 5.9 EVENT: CURRENCY DROPS
    -- ==========================================
    local totalDropsCollected = 0
    local function hookDropFolder(dropFolder)
        if not dropFolder or not CurrencyDrops then return end
        on(dropFolder.ChildAdded, function(drop)
            if not _G.RT3_Settings.AutoCollectDrops then return end
            task.defer(function()
                pcall(function()
                    local ok = false
                    if CurrencyDrops.ActiveDrops and (CurrencyDrops.ActiveDrops[drop] or CurrencyDrops.ActiveDrops[drop.Name]) then
                        CurrencyDrops:QueueCollectRemote(drop); ok = true
                    end
                    if not ok then
                        Events.Currency.PlayerCollectedDrops:FireServer({ drop })
                    end
                    totalDropsCollected = totalDropsCollected + 1
                end)
            end)
        end)
    end

    task.spawn(function()
        local df = Workspace:FindFirstChild("DropFolder")
        if df then hookDropFolder(df)
        else
            on(Workspace.ChildAdded, function(c)
                if c.Name == "DropFolder" then hookDropFolder(c) end
            end)
        end
    end)

    -- ==========================================
    -- 5.10 EVENT: SCAVENGER HUNT
    -- ==========================================
    if ScavengerHunt and not _G.RT3_ScavHooked then
        _G.RT3_ScavHooked = true
        local _origHuntStarted = ScavengerHunt.OnHuntStarted
        if _origHuntStarted then
            ScavengerHunt.OnHuntStarted = function(self, ...)
                local ok = pcall(_origHuntStarted, self, ...)
                task.defer(function()
                    if not _G.RT3_Settings.AutoScavenger then return end
                    task.wait(0.5)
                    for _, item in pairs(ScavengerHunt.Items or {}) do
                        pcall(function() ScavengerHunt:OnItemCollected(item) end)
                    end
                end)
                return ok
            end
        end
        task.defer(function()
            if _G.RT3_Settings.AutoScavenger then
                for _, item in pairs(ScavengerHunt.Items or {}) do
                    pcall(function() ScavengerHunt:OnItemCollected(item) end)
                end
            end
        end)
    end

    -- ==========================================
    -- 5.11 BILL / DISH  (event + sweep)
    -- ==========================================
    local hookedTycoons = {}
    local billCooldown = {}

    local function collectFurnitureItem(tycoon, descendant, furniture)
        if not furniture then return end
        local k = descendant.Name .. "|" .. tostring(furniture)
        local now = os.clock()
        if billCooldown[k] and (now - billCooldown[k]) < 1 then return end
        billCooldown[k] = now
        Events.Restaurant.TaskCompleted:FireServer({
            Name = (descendant.Name == "Bill") and TaskEnum.CollectBill or TaskEnum.CollectDishes,
            FurnitureModel = furniture,
            Tycoon = tycoon,
        })
    end

    local function hookTycoonItems(tycoon)
        if not tycoon or hookedTycoons[tycoon] then return end
        if not tycoon:FindFirstChild("Items") then return end
        hookedTycoons[tycoon] = true
        on(tycoon.Items.DescendantAdded, function(descendant)
            local valid, isFriend = isTargetTycoon(tycoon)
            if not valid then return end
            if descendant.Name == "Bill" and (isFriend and _G.RT3_Settings.Friend_AutoBill or _G.RT3_Settings.AutoBill) then
                collectFurnitureItem(tycoon, descendant, descendant:FindFirstAncestorOfClass("Model"))
            elseif descendant.Name == "Trash" and (isFriend and _G.RT3_Settings.Friend_AutoDishes or _G.RT3_Settings.AutoDishes) then
                collectFurnitureItem(tycoon, descendant, descendant:FindFirstAncestorOfClass("Model"))
            end
        end)
    end

    -- ==========================================
    -- 5.12 SERVING
    -- ==========================================
    local grabBusy = false   -- กันหยิบซ้อน (v11.3 background grab)
    local carFoodBlock = {}  -- จานของไดรฟ์ทรูที่ห้ามหยิบซ้ำ (v11.3)
    local lastHoldSig, lastHoldSince = nil, nil   -- watchdog: ของค้างในมือ (v11.3)
    local function processFoodServing(tycoon)
        if not GrabFood or not ServeFood or not Customers then return end
        local custFolder = tycoon:FindFirstChild("ClientCustomers")
        local foodFolder = tycoon:FindFirstChild("Objects") and tycoon.Objects:FindFirstChild("Food")
        if not custFolder or not foodFolder then return end

        -- FIX v11.3: ต้องส่ง tycoon ไม่งั้นฟังก์ชันคืน 1 (บั๊กเดิม)
        --   WaiterTray=3 / WaiterCart=4 -> ผู้เล่นถือได้สูงสุด 4 จาน (เสิร์ฟไวขึ้นหลายเท่า)
        local holdCap = GrabFood:GetPlayerHoldCapacity(tycoon) or 1
        if #GrabFood.Storage > 0 and GrabFood.Storage[1].Tycoon ~= tycoon then
            GrabFood:OnCancelPressed(); task.wait(0.01)
        end

        -- (A) เสิร์ฟจานที่ถืออยู่แล้วให้ลูกค้าที่รอ (task.spawn = ไม่บล็อกลูป)
        for _, g in ipairs(custFolder:GetChildren()) do
            for _, c in ipairs(g:GetChildren()) do
                if Customers:GetCustomerState(tycoon, g.Name, c.Name) == CustomerState.WaitingForDish then
                    local cData = Customers:GetCustomerData(tycoon, g.Name, c.Name)
                    local order = cData and cData.Order
                    local isKid = cData and (cData.CustomerType == CustomerType.Kid)
                    if order and GrabFood:IsHoldingFoodForNPC(order, isKid) then
                        task.spawn(ServeFood.CompleteForNPC, ServeFood, tycoon, g.Name, c.Name)
                    end
                end
            end
        end

        -- (B) หยิบอาหารเพิ่ม "แบบ background" (FIX v11.3)
        --   ปัญหาเดิม: GrabFood:AttemptGrab() ยิงแบบ synchronous ในลูป 20Hz
        --   -> ทุกครั้งที่หยิบ ลูปค้างรอ server (ping) ทำให้เสิร์ฟช้าลงทั้งระบบ
        --   และเมื่อ holdCap = 4 (WaiterCart) มันจะหยิบ 4 ครั้งติดกัน -> ลูปค้างหนักกว่าเดิม
        --   แก้: ย้ายไป task.spawn + ธง grabBusy แล้วหยิบให้เต็ม holdCap ในรอบเดียว
        if not grabBusy and #GrabFood.Storage < holdCap then
            grabBusy = true
            task.spawn(function()
                pcall(function()
                    local deadline = os.clock() + 1.2
                    while #GrabFood.Storage < holdCap and os.clock() < deadline do
                        -- (B0) FIX v11.3: จานที่ "รถไดรฟ์ทรู" กำลังรออยู่ = ห้ามหยิบ
                        --   ถ้าหยิบ จานจะผูก TargetCarId แล้วแถบล่างเด้ง "Serve ... (Drive Thru Order)" รัว ๆ
                        --   (ผู้ใช้เห็นเป็นไดรฟ์ทรูสแปม) + ทำให้รถค้างที่ OrderMade
                        local carWanted = {}
                        if DriveThru then
                            local cc = tycoon:FindFirstChild("ClientCars")
                            if cc then
                                for _, car in ipairs(cc:GetChildren()) do
                                    local okc, cd = pcall(function() return DriveThru:GetCarData(tycoon, car.Name) end)
                                    if okc and cd and type(cd.Orders) == "table" then
                                        for _, o in pairs(cd.Orders) do
                                            local key = tostring(o)
                                            carWanted[key] = (carWanted[key] or 0) + 1
                                        end
                                    end
                                end
                            end
                        end
                        -- สแกนอาหารว่างใหม่ทุกครั้ง (กันข้อมูลเก่า/ถูกแย่งไปแล้ว)
                        local cache = {}
                        for _, food in ipairs(foodFolder:GetChildren()) do
                            local bl = carFoodBlock[food]
                            if bl and os.clock() < bl then
                                bl = true
                            else
                                bl = false
                                carFoodBlock[food] = nil
                            end
                            if food.Parent and not bl and not food:GetAttribute("Taken") then
                                local n = food.Name
                                if carWanted[n] and carWanted[n] > 0 then
                                    carWanted[n] = carWanted[n] - 1   -- เว้นไว้ให้พนักงานไดรฟ์ทรู
                                else
                                    cache[n] = cache[n] or {}
                                    table.insert(cache[n], food)
                                end
                            end
                        end
                        local grabbed = false
                        for _, g in ipairs(custFolder:GetChildren()) do
                            if #GrabFood.Storage >= holdCap then break end
                            for _, c in ipairs(g:GetChildren()) do
                                if #GrabFood.Storage >= holdCap then break end
                                if Customers:GetCustomerState(tycoon, g.Name, c.Name) == CustomerState.WaitingForDish then
                                    local cData = Customers:GetCustomerData(tycoon, g.Name, c.Name)
                                    local order = cData and cData.Order
                                    local isKid = cData and (cData.CustomerType == CustomerType.Kid)
                                    if order and not GrabFood:IsHoldingFoodForNPC(order, isKid) then
                                        local list = cache[tostring(order)]
                                        local food = list and table.remove(list, 1)
                                        if food and food.Parent then
                                            -- FIX v11.3: เดิมเช็ค "~= false" ผิด (AttemptGrab คืน nil ทั้งตอนสำเร็จและตอนโดนปฏิเสธ)
                                            --   -> ตอนนี้ตรวจจาก Storage ว่าหยิบติดจริงไหม
                                            local before = #GrabFood.Storage
                                            GrabFood:AttemptGrab(tycoon, food)
                                            local entry = (#GrabFood.Storage > before) and GrabFood.Storage[#GrabFood.Storage] or nil
                                            if entry and entry.TargetCarId ~= nil then
                                                -- จานนี้เป็นของไดรฟ์ทรู -> คืนทันที + แบล็คกันหยิบซ้ำ
                                                GrabFood:OnCancelPressed()
                                                carFoodBlock[food] = os.clock() + 5
                                                task.wait(0.03)
                                            elseif entry then
                                                grabbed = true
                                                local gName, cName = g.Name, c.Name
                                                task.spawn(function()
                                                    task.wait(0.01)
                                                    ServeFood:CompleteForNPC(tycoon, gName, cName)
                                                end)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if not grabbed then break end
                    end
                end)
                grabBusy = false
            end)
        end

        -- (C) Watchdog กัน "มือตัน" (v11.3)
        --   CompleteForNPC ยิง TaskCompleted แล้ว server อาจไม่รับ (rate-limit / คู่หลุด)
        --   -> ของค้างในมือตลอดกาล = หยิบจานใหม่ไม่ได้ทั้งระบบ  (ยิ่งลูกค้าเยอะยิ่งตันหนัก)
        if #GrabFood.Storage > 0 then
            local now = os.clock()
            local sig = ""
            for _, it in ipairs(GrabFood.Storage) do sig = sig .. tostring(it.FoodKey) .. "," end
            if sig == lastHoldSig then
                lastHoldSince = lastHoldSince or now
                if now - lastHoldSince > 8 then
                    GrabFood:OnCancelPressed()
                    lastHoldSig, lastHoldSince = nil, nil
                    task.wait(0.01)
                end
            else
                lastHoldSig, lastHoldSince = sig, now
            end
        else
            lastHoldSig, lastHoldSince = nil, nil
        end

        -- กันยกเลิกผิด: ถ้ายังถือ food ที่มีลูกค้ารอรับอยู่ ห้าม OnCancelPressed
        if #GrabFood.Storage > 0 then
            local anyMatched = false
            for _, g in ipairs(custFolder:GetChildren()) do
                for _, c in ipairs(g:GetChildren()) do
                    if Customers:GetCustomerState(tycoon, g.Name, c.Name) == CustomerState.WaitingForDish then
                        local cData = Customers:GetCustomerData(tycoon, g.Name, c.Name)
                        if cData and GrabFood:IsHoldingFoodForNPC(cData.Order, cData.CustomerType == CustomerType.Kid) then
                            anyMatched = true; break
                        end
                    end
                end
                if anyMatched then break end
            end
            if not anyMatched then GrabFood:OnCancelPressed() end
        end
    end

    -- ==========================================
    -- 5.13 SLOW-CYCLE TASKS (tips / bills / sweeps)
    -- ==========================================
    -- เก็บกระปุกติป: ตรวจ Furniture ItemType.TipJar + attr Value > 0 ก่อนยิง (กันสแปม)
    local function collectTips(tycoon)
        if not FurnitureUtility or not ItemType then return end
        local items = tycoon:FindFirstChild("Items")
        local furn = items and items:FindFirstChild("Furniture")
        if not furn then return end
        local any = false
        for _, m in ipairs(furn:GetChildren()) do
            local target = m
            if not m:IsA("Model") then target = nil end
            if target then
                local ok, isJar = pcall(function() return FurnitureUtility:Is(target.Name, ItemType.TipJar) end)
                if ok and isJar then
                    local v = tonumber(target:GetAttribute("Value")) or 0
                    if v <= 0 then
                        -- ค้นหา child ที่เป็น jar จริง (บางทีชื่อ model ไม่ตรง)
                        for _, d in ipairs(target:GetDescendants()) do
                            if d:IsA("Model") then
                                local ok2, j2 = pcall(function() return FurnitureUtility:Is(d.Name, ItemType.TipJar) end)
                                if ok2 and j2 and (tonumber(d:GetAttribute("Value")) or 0) > 0 then any = true; break end
                            end
                        end
                    else
                        any = true
                    end
                end
            end
            if any then break end
        end
        if any then
            fireThrottled("tips|" .. tostring(tycoon), _G.RT3_Settings.RemoteCooldown, function()
                Events.Restaurant.TipsCollected:FireServer(tycoon)
            end)
        end
    end

    -- sweep เก็บ Bill/Trash ที่ตกค้าง (เช่น ของที่มีอยู่ก่อน hook)
    local function sweepBills(tycoon, isFriend)
        local items = tycoon:FindFirstChild("Items")
        if not items then return end
        local wantBill = isFriend and _G.RT3_Settings.Friend_AutoBill or _G.RT3_Settings.AutoBill
        local wantDish = isFriend and _G.RT3_Settings.Friend_AutoDishes or _G.RT3_Settings.AutoDishes
        if not (wantBill or wantDish) then return end
        for _, d in ipairs(items:GetDescendants()) do
            if (d.Name == "Bill" and wantBill) or (d.Name == "Trash" and wantDish) then
                collectFurnitureItem(tycoon, d, d:FindFirstAncestorOfClass("Model"))
            end
        end
    end

    -- sweep seat: กัน event ตกหล่นตอนลูกค้าเยอะ
    local function sweepSeat(tycoon, isFriend)
        if not Customers.GetGroupState then return end
        local enabled = isFriend and _G.RT3_Settings.Friend_AutoSeat or _G.RT3_Settings.AutoSeat
        if not enabled then return end
        local custFolder = tycoon:FindFirstChild("ClientCustomers")
        if not custFolder then return end
        for _, g in ipairs(custFolder:GetChildren()) do
            local ok, st = pcall(function() return Customers:GetGroupState(tycoon, g.Name) end)
            if ok and (st == "Entered" or st == "Entering") then
                fireThrottled("seat|" .. tostring(tycoon) .. "|" .. g.Name, 1.2, function()
                    Events.Restaurant.TaskCompleted:FireServer({ Name = TaskEnum.SendToTable, GroupId = g.Name, Tycoon = tycoon })
                end)
            end
        end
    end

    -- sweep order: ลูกค้าที่ค้าง Ordering
    local function sweepOrders(tycoon, isFriend)
        if not Customers then return end
        local enabled = isFriend and _G.RT3_Settings.Friend_AutoOrder or _G.RT3_Settings.AutoOrder
        if not enabled then return end
        local custFolder = tycoon:FindFirstChild("ClientCustomers")
        if not custFolder then return end
        for _, g in ipairs(custFolder:GetChildren()) do
            for _, c in ipairs(g:GetChildren()) do
                local ok, st = pcall(function() return Customers:GetCustomerState(tycoon, g.Name, c.Name) end)
                if ok and st == CustomerState.Ordering then
                    fireThrottled("order|" .. tostring(tycoon) .. "|" .. c.Name, 1.2, function()
                        TakeOrder:TakeOrder(tycoon, g.Name, c.Name)
                    end)
                end
            end
        end
    end

    local function runAutoHarvest()
        if not _G.RT3_Settings.AutoHarvest or not Farming then return end
        for _, tile in pairs(Farming.TrackedTiles or {}) do
            if typeof(tile) == "Instance" then
                pcall(function()
                    if Farming:GetState(tile) == Farming.States.Completed then
                        Farming:RequestHarvest(tile)
                    end
                end)
            end
        end
    end

    -- ==========================================
    -- 5.14 FRIEND TYCOON CACHE (สแกนไม่ถี่เกินไป)
    -- ==========================================
    local friendCache, friendCacheTime = {}, 0
    local function getPermittedFriendTycoons()
        local now = os.clock()
        if now - friendCacheTime < 1.5 then return friendCache end
        friendCacheTime = now
        local out = {}
        local tc = Workspace:FindFirstChild("Tycoons")
        if tc and Managers then
            for _, t in ipairs(tc:GetChildren()) do
                local owner = t:FindFirstChild("Player") and t.Player.Value
                if owner and owner ~= LocalPlayer then
                    local ok, perm = pcall(function() return Managers:HasPermission(t, Managers.PermissionLevel.Employee) end)
                    if ok and perm then
                        table.insert(out, t)
                        hookTycoonItems(t)
                    end
                end
            end
        end
        friendCache = out
        return out
    end

    -- ==========================================
    -- 5.15 PER-TYCOON CYCLE
    -- ==========================================
    local function runTycoonCycle(tycoon, isFriend)
        if not tycoon then return end
        hookTycoonItems(tycoon)
        local cooking = Cook and Cook.IsCooking
        local cfg = {
            Serve     = isFriend and _G.RT3_Settings.Friend_AutoServe     or _G.RT3_Settings.AutoServe,
            Tips      = isFriend and _G.RT3_Settings.Friend_AutoTips      or _G.RT3_Settings.AutoTips,
            Cook      = isFriend and _G.RT3_Settings.Friend_AutoCook      or _G.RT3_Settings.AnywhereCook,
        }
        if cfg.Serve and not cooking then processFoodServing(tycoon) end

        if cfg.Cook and Interactions and Interactions.PromptData and not cooking then
            local promptData = Interactions.PromptData[tycoon]
            if promptData and #GrabFood.Storage == 0 then
                for _, pInfo in pairs(promptData) do
                    if pInfo.Key == "Cook" then Interactions:Interact(tycoon, pInfo); break end
                end
            end
        end
    end

    -- ==========================================
    -- 5.16 MAIN LOOP (20 Hz) + SLOW TICK (1 Hz)
    -- ==========================================
    local adBoostTimer, offlineTimer, rushTimer, harvestTimer = 0, 0, 0, 0
    local nextSlow = os.clock() + (_G.RT3_Settings.SlowTick or 1)

    _G.RT3_BootStage = "loop-start"
    _G.RT3_EngineError = nil
    _G.AutoFarmRunning = true
    _G.RT3_EngineHeartbeat = os.clock()

    while _G.AutoFarmRunning do
        _G.RT3_EngineHeartbeat = os.clock()
        pcall(function()
            local myTycoon = focusedTycoon:Get()

            -- Unanchor
            if _G.RT3_Settings.AnywhereCook then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
            end

            -- Farm own
            if _G.RT3_Settings.MasterAutoFarm and myTycoon then
                runTycoonCycle(myTycoon, false)
            end

            -- Farm friends
            if _G.RT3_Settings.Friend_MasterFarm then
                local friendTycoons = getPermittedFriendTycoons()
                for _, ft in ipairs(friendTycoons) do
                    runTycoonCycle(ft, true)
                end
            end

            -- Slow tick (1 Hz)
            local now = os.clock()
            if now >= nextSlow then
                nextSlow = now + (_G.RT3_Settings.SlowTick or 1)

                local curCash = PlayerData and PlayerData:GetKey(PlayerData.DataStoreType.Restaurant, "Cash")
                if curCash then CashLabel:Set("Current Cash: $" .. tostring(curCash)) end

                if myTycoon and myTycoon:FindFirstChild("ClientCustomers") then
                    local count = 0
                    for _, g in ipairs(myTycoon.ClientCustomers:GetChildren()) do
                        count = count + #g:GetChildren()
                    end
                    CustomerLabel:Set("My Customers: " .. count)
                end

                local food = myTycoon and myTycoon:FindFirstChild("Objects") and myTycoon.Objects:FindFirstChild("Food")
                if food then FoodLabel:Set("Food Ready: " .. #food:GetChildren()) end

                if Delivery then
                    local orderList = Delivery:GetOrders(myTycoon) or {}
                    local orderCount = 0
                    for _ in pairs(orderList) do orderCount = orderCount + 1 end
                    DeliveryLabel:Set("Deliveries: " .. orderCount .. " active | Done: " .. deliveryCount)
                end
                DropsLabel:Set("Drops Collected: " .. totalDropsCollected)
                if RushHour then
                    RushLabel:Set("Rush Hour: " .. (RushHour:IsActive() and "ACTIVE (" .. tostring(RushHour.EventType) .. ")" or "Inactive"))
                end

                local rudeActive = 0
                for _ in pairs(activeRude) do rudeActive = rudeActive + 1 end
                RudeLabel:Set("Rude Calmed: " .. rudeCalmed .. " | Active: " .. rudeActive)

                local stall = os.clock() - (_G.RT3_EngineHeartbeat or 0)
                local A = _G.RT3_AFK or {}
                HealthLabel:Set("Engine: RUNNING (" .. string.format("%.2f", stall) .. "s) | Anti-AFK: "
                    .. tostring(A.pulses or 0) .. " เต้น / idle " .. tostring(A.idled or 0))
                if AFKLabel then
                    local idleFor = os.clock() - (A.lastInput or os.clock())
                    local up = math.floor(time())
                    AFKLabel:Set(string.format("AFK Guard: %s | เต้นล่าสุด: %s | ไม่มี input: %ds | เซสชัน: %dh %dm",
                        _G.RT3_Settings.AntiAFK and "ON" or "OFF",
                        tostring(A.lastReason or "-"), math.floor(idleFor),
                        math.floor(up / 3600), math.floor((up % 3600) / 60)))
                end

                -- per-tycoon slow work
                local function slowFor(tycoon, isFriend)
                    if not tycoon then return end
                    if (isFriend and _G.RT3_Settings.Friend_AutoTips or _G.RT3_Settings.AutoTips) then
                        collectTips(tycoon)
                    end
                    sweepBills(tycoon, isFriend)
                    sweepSeat(tycoon, isFriend)
                    sweepOrders(tycoon, isFriend)
                end
                slowFor(myTycoon, false)
                if _G.RT3_Settings.Friend_MasterFarm then
                    for _, ft in ipairs(getPermittedFriendTycoons()) do slowFor(ft, true) end
                end

                -- Friend label
                if _G.RT3_Settings.Friend_MasterFarm then
                    if #friendCache > 0 then
                        local names = {}
                        for _, ft in ipairs(friendCache) do
                            local owner = ft:FindFirstChild("Player") and ft.Player.Value
                            table.insert(names, owner and owner.Name or "Friend")
                        end
                        FriendInfoLabel:Set("Helping: " .. table.concat(names, ", "))
                        FriendStatsLabel:Set("Friend Status: Active (" .. #friendCache .. " Restaurants)")
                    else
                        FriendInfoLabel:Set("No Friends (Need Employee Role)")
                        FriendStatsLabel:Set("Friend Status: Waiting")
                    end
                end

                -- Harvest (10s)
                harvestTimer = harvestTimer + 1
                if harvestTimer >= 10 then
                    harvestTimer = 0
                    runAutoHarvest()
                end
            end

            -- Ad boost (~9min)
            adBoostTimer = adBoostTimer + 1
            if adBoostTimer >= 10800 or adBoostTimer == 1 then
                if _G.RT3_Settings.Infinite15xBoost then
                    pcall(function() Events.Shop.RewardedAdEvent:FireServer("ShortAdBoost") end)
                end
                adBoostTimer = 2
            end

            -- Offline earnings (15s)
            offlineTimer = offlineTimer + 1
            if offlineTimer >= 300 then
                offlineTimer = 0
                if _G.RT3_Settings.AutoClaimOffline then
                    pcall(function() Events.Upgrades.CollectOfflineEarningsRequested:FireServer() end)
                end
            end

            -- Rush Hour (30s)
            rushTimer = rushTimer + 1
            if rushTimer >= 600 then
                rushTimer = 0
                if _G.RT3_Settings.AutoRushHour and RushHour then
                    pcall(function()
                        if RushHour:CanStartNow() then
                            Events.RushHour.RushHourActivateRequested:FireServer()
                        end
                    end)
                end
            end
        end)
        task.wait(_G.RT3_Settings.TickRate or 0.05)
    end
  end, function(e)
    _G.RT3_EngineError = tostring(e) .. "\n" .. tostring(debug and debug.traceback and debug.traceback() or "")
    return _G.RT3_EngineError
  end)
  if not _ok then
    _G.RT3_EngineError = "RT3 v11 ENGINE ERROR: " .. tostring(_err)
    warn("[RT3 v11] ENGINE ERROR: " .. tostring(_err))
  end
end)

-- ==========================================
-- 6. AFK GUARDIAN (v11.4) : กันหลุดตอน AFK ทั้งวัน
--   สาเหตุหลุดที่เจอจริง:
--     (1) Roblox เตะเองเมื่อไม่มี input จริง ~20 นาที  <-- ตัวหลัก
--     (2) เครื่องเข้า sleep / เน็ตสะดุด / server ปิด
--   วิธีแก้:
--     - จำลอง input จริงผ่าน VirtualUser (CaptureController + ClickButton2)
--     - เต้นกัน idle เป็นระยะ "เฉพาะตอนไม่มีคนเล่น" (ไม่กวนเวลานั่งเล่นเอง)
--     - ผูก game.OnClose -> พยายามกลับเข้าห้องเดิม (place + job เดิม)
--     - ตั้ง AutoRejoinURL -> กลับเข้าเกมแล้วโหลดสคริปต์ต่ออัตโนมัติ
-- ==========================================
if not _G.RT3_AFKGuard then
_G.RT3_AFKGuard = true
_G.RT3_AFK = { pulses = 0, idled = 0, lastPulse = 0, lastInput = os.clock(), rejoins = 0, lastReason = "-" }

-- รู้ว่ามีคนเล่นจริงอยู่ไหม (ถ้าเล่นอยู่ ไม่ต้องเต้นกัน idle)
task.spawn(function()
    local UIS = game:GetService("UserInputService")
    local function mark() _G.RT3_AFK.lastInput = os.clock() end
    pcall(function() UIS.InputBegan:Connect(mark) end)
    pcall(function() UIS.InputChanged:Connect(mark) end)
end)

function _G.RT3_AFKPulse(reason)
    local vu
    pcall(function() vu = game:GetService("VirtualUser") end)
    if vu then
        pcall(function() vu:CaptureController() end)
        pcall(function() vu:ClickButton2(Vector2.new()) end)
    end
    -- ขยับเมาส์เบา ๆ ช่วยรีเซ็ต idle timer (ถ้า executor มีให้ใช้)
    if typeof(mousemoverel) == "function" then
        pcall(function() mousemoverel(3, 0) end)
        task.delay(0.08, function() pcall(function() mousemoverel(-3, 0) end) end)
    end
    local A = _G.RT3_AFK
    A.pulses = A.pulses + 1
    A.lastPulse = os.clock()
    A.lastReason = tostring(reason)
    return true
end

-- (1) เคสมาตรฐาน: Roblox ยิง Idled เมื่อไม่มี input ~20 นาที
pcall(function()
    LocalPlayer.Idled:Connect(function()
        _G.RT3_AFK.idled = _G.RT3_AFK.idled + 1
        if _G.RT3_Settings.AntiAFK then
            _G.RT3_AFKPulse("idled")
        end
    end)
end)

-- (2) เคส Idled ไม่ยิง: เต้นเองเป็นระยะ (เฉพาะตอนไม่มีคนเล่น)
task.spawn(function()
    while _G.RT3_AFKGuard do
        task.wait(_G.RT3_Settings.AntiAFKInterval or 45)
        local A = _G.RT3_AFK
        local idleFor = os.clock() - (A.lastInput or 0)
        if _G.RT3_Settings.AntiAFK and idleFor >= 100 then
            _G.RT3_AFKPulse("timer")
        end
    end
end)

-- (3) Auto Rejoin (v11.4)
--     หมายเหตุสำคัญ: game.OnClose ถูกตัวเกมตั้งไว้แล้ว -> แก้ทับไม่ได้ (ปิดการใช้งาน)
--     วิธีที่ได้ผลจริง: บันทึก "เซสชันล่าสุด" + ตัวสคริปต์ลงไฟล์
--     แล้วใช้สคริปต์คู่หู RT3-AutoRejoin.lua (วางในโฟลเดอร์ auto-execute ของ executor)
--     พากลับเข้าห้องเดิม + โหลด Master Suite ต่อให้อัตโนมัติ
if typeof(writefile) == "function" then
    task.spawn(function()
        local selfSrc
        pcall(function()
            local info = debug.getinfo(1, "S")
            local s = info and info.source
            if not s then return end
            if s:sub(1, 1) == "@" then
                -- โหลดจากไฟล์ (เช่น execute-file) -> อ่านไฟล์นั้นกลับ
                local p = s:sub(2)
                if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(p) then
                    selfSrc = readfile(p)
                end
            elseif s:sub(1, 1) ~= "=" and #s > 2000 then
                -- โหลดด้วย loadstring -> source คือตัวสคริปต์ทั้งก้อน
                selfSrc = s
            end
        end)
        if selfSrc then pcall(function() writefile("RT3_Self.lua", selfSrc) end) end

        while _G.RT3_AFKGuard do
            if _G.RT3_Settings.AutoRejoin then
                pcall(function()
                    writefile("RT3_Session.json", game:GetService("HttpService"):JSONEncode({
                        placeId   = game.PlaceId,
                        jobId     = game.JobId,
                        ts        = os.time(),
                        pulses    = _G.RT3_AFK.pulses,
                        version   = "v11.4",
                        url       = _G.RT3_Settings.AutoRejoinURL or "",
                    }))
                end)
            end
            task.wait(60)
        end
    end)
end

-- (4) ถ้าตั้ง AutoRejoinURL -> กลับเข้าเกมแล้วโหลดสคริปต์เดิมอัตโนมัติ
if _G.RT3_Settings.AutoRejoinURL ~= "" and typeof(queue_on_teleport) == "function" then
    pcall(function()
        queue_on_teleport('loadstring(game:HttpGet("' .. _G.RT3_Settings.AutoRejoinURL .. '"))()')
    end)
end
end

-- 6. WATCHDOG : เตือนถ้า engine ค้าง (ไม่ฆ่า thread ให้รันต่อได้)
if not _G.RT3_Watchdog then
_G.RT3_Watchdog = true
task.spawn(function()
    while true do
        task.wait(10)
        local hb = _G.RT3_EngineHeartbeat
        if _G.AutoFarmRunning and hb and (os.clock() - hb) > 20 then
            warn("[RT3 v11] Engine heartbeat stalled >20s")
        end
    end
end)
end

notify("RT3 Suite v11.4 Active", "AFK Guardian ONLINE! (กันเตะ idle + Auto Rejoin) | Serving Fix + Tip Jar + Stability", 6)
