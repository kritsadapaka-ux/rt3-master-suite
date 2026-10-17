-- Restaurant Tycoon 3: Master Suite v11.5 (Fluent Edition)
-- UI: Fluent (github.com/dawid-scripts/Fluent) — เสถียรกว่า Rayfield, โหลดจาก GitHub releases
-- Patches: P1 engine restart | P2 billCooldown cleanup | P3 carFoodBlock by name | P4 rude step limit | P5 AFK pulse ไม่มีเงื่อนไข

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

-- 2. เคลียร์ UI เก่า (Rayfield / Fluent เก่า)
for _, container in ipairs({
    game.Players.LocalPlayer:FindFirstChild("PlayerGui"),
    typeof(gethui) == "function" and gethui(),
    game:GetService("CoreGui")
}) do
    if container then
        for _, c in ipairs(container:GetChildren()) do
            if c.Name == "Rayfield" or c.Name == "Fluent" then
                pcall(function() c:Destroy() end)
            end
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
    AutoRude         = true,
    RudeReply        = "Calm",
    RudeDebug        = false,
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
    TickRate           = 0.05,
    SlowTick           = 1.0,
    RemoteCooldown     = 0.85,
    AntiAFK            = true,
    AntiAFKInterval    = 45,
    AutoRejoin         = true,
    AutoRejoinURL      = "",
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

-- 4. Fluent UI (ASYNC — engine รันทันที ไม่รอ HTTP)
local Fluent
local function notify(title, content, dur)
    if Fluent then
        pcall(function()
            Fluent:Notify({ Title = title, Content = content, Duration = dur or 6 })
        end)
    end
end

-- paragraph labels — update ผ่าน closure
local _statsLines = {
    cash     = "Cash: Loading...",
    customer = "Customers: 0",
    food     = "Food Ready: 0",
    delivery = "Deliveries: 0",
    drops    = "Drops: 0",
    rush     = "Rush Hour: Inactive",
    rude     = "Rude Calmed: 0",
    engine   = "Engine: Booting...",
    afk      = "AFK Guard: Booting...",
    friend   = "Friend: Idle",
}
local _statsPara   -- Fluent paragraph element ref
local function updateStats()
    if not _statsPara then return end
    pcall(function()
        _statsPara:Set(
            "💵 " .. _statsLines.cash .. "\n" ..
            "👥 " .. _statsLines.customer .. "\n" ..
            "🍽 " .. _statsLines.food .. "\n" ..
            "🛵 " .. _statsLines.delivery .. "\n" ..
            "💰 " .. _statsLines.drops .. "\n" ..
            "⚡ " .. _statsLines.rush .. "\n" ..
            "😤 " .. _statsLines.rude .. "\n" ..
            "🔧 " .. _statsLines.engine .. "\n" ..
            "🛡 " .. _statsLines.afk .. "\n" ..
            "👫 " .. _statsLines.friend
        )
    end)
end

-- stub label interface (compat กับโค้ด engine ที่ call :Set())
local function makeLine(key)
    return { Set = function(_, v) _statsLines[key] = tostring(v); updateStats() end }
end
local CashLabel        = makeLine("cash")
local CustomerLabel    = makeLine("customer")
local FoodLabel        = makeLine("food")
local DeliveryLabel    = makeLine("delivery")
local DropsLabel       = makeLine("drops")
local RushLabel        = makeLine("rush")
local RudeLabel        = makeLine("rude")
local HealthLabel      = makeLine("engine")
local AFKLabel         = makeLine("afk")
local FriendStatsLabel = makeLine("friend")
local FriendInfoLabel  = makeLine("friend")

task.spawn(function()
local okUI, uiErr = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

    local Window = Fluent:CreateWindow({
        Title    = "RT3 Master Suite",
        SubTitle = "v11.5 — All-Day AFK Edition",
        TabWidth = 155,
        Size     = UDim2.fromOffset(600, 480),
        Acrylic  = false,   -- false = ไม่มี blur = detect ยากขึ้น
        Theme    = "Dark",
        MinimizeKey = Enum.KeyCode.RightControl,
    })

    local Tabs = {
        Main    = Window:AddTab({ Title = "Restaurant",  Icon = "utensils" }),
        Boost   = Window:AddTab({ Title = "Speed",       Icon = "zap" }),
        Extra   = Window:AddTab({ Title = "Extra",       Icon = "package" }),
        Friend  = Window:AddTab({ Title = "Friends",     Icon = "users" }),
        Stats   = Window:AddTab({ Title = "Stats",       Icon = "bar-chart-2" }),
    }

    -- ======== RESTAURANT TAB ========
    Tabs.Main:AddToggle("MasterFarm", { Title = "Master Auto Farm", Description = "เปิด/ปิดทั้งหมด", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.MasterAutoFarm = v end)

    Tabs.Main:AddParagraph({ Title = "Seating & Orders", Content = "" })
    Tabs.Main:AddToggle("AutoSeat", { Title = "Auto Seat", Description = "จัดที่นั่งลูกค้าอัตโนมัติ", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoSeat = v end)
    Tabs.Main:AddToggle("AutoOrder", { Title = "Auto Order", Description = "รับออเดอร์อัตโนมัติ", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoOrder = v end)

    Tabs.Main:AddParagraph({ Title = "Cooking & Serving", Content = "" })
    Tabs.Main:AddToggle("AnywhereCook", { Title = "Anywhere Cook", Description = "ทำอาหารได้ทุกที่", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AnywhereCook = v end)
    Tabs.Main:AddToggle("InstantCook", { Title = "Instant Cook (0s)", Description = "ทำอาหารทันที", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.InstantCook = v end)
    Tabs.Main:AddToggle("AutoServe", { Title = "Auto Serve", Description = "เสิร์ฟอาหารอัตโนมัติ", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoServe = v end)

    Tabs.Main:AddParagraph({ Title = "Cleaning & Bills", Content = "" })
    Tabs.Main:AddToggle("AutoBill", { Title = "Auto Bill", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoBill = v end)
    Tabs.Main:AddToggle("AutoDishes", { Title = "Auto Dishes", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoDishes = v end)
    Tabs.Main:AddToggle("AutoTips", { Title = "Auto Tip Jar", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoTips = v end)
    Tabs.Main:AddToggle("AutoCatch", { Title = "Anti Dine & Dash", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoCatchDine = v end)

    Tabs.Main:AddParagraph({ Title = "Special Customers", Content = "" })
    Tabs.Main:AddToggle("AutoRude", { Title = "Auto Calm Rude Customers", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoRude = v end)
    Tabs.Main:AddToggle("RudeDebug", { Title = "Rude Debug (console)", Default = false })
        :OnChanged(function(v) _G.RT3_Settings.RudeDebug = v end)

    -- ======== SPEED TAB ========
    Tabs.Boost:AddParagraph({ Title = "Passive Boosters", Content = "" })
    Tabs.Boost:AddToggle("AdBoost", { Title = "Infinite +15% Cash Boost", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.Infinite15xBoost = v end)
    Tabs.Boost:AddToggle("OfflineEarn", { Title = "Auto Claim Offline Earnings", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoClaimOffline = v end)

    Tabs.Boost:AddParagraph({ Title = "NPC Speed", Content = "" })
    Tabs.Boost:AddSlider("NpcSpd", {
        Title = "Customer Walk Speed", Min = 10, Max = 150, Default = 75, Rounding = 0,
        Callback = function(v) _G.RT3_Settings.NpcWalkSpeed = v end
    })
    Tabs.Boost:AddSlider("NpcMul", {
        Title = "Walk Frame Multiplier", Min = 1, Max = 10, Default = 5, Rounding = 0,
        Callback = function(v) _G.RT3_Settings.NpcTimeMultiplier = v end
    })

    -- ======== EXTRA TAB ========
    Tabs.Extra:AddParagraph({ Title = "Delivery", Content = "" })
    Tabs.Extra:AddToggle("AutoDelivery", { Title = "Auto Delivery", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoDelivery = v end)

    Tabs.Extra:AddParagraph({ Title = "Economy", Content = "" })
    Tabs.Extra:AddToggle("AutoDrops", { Title = "Auto Collect Currency Drops", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoCollectDrops = v end)
    Tabs.Extra:AddToggle("AutoRush", { Title = "Auto Activate Rush Hour", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoRushHour = v end)

    Tabs.Extra:AddParagraph({ Title = "Farm", Content = "" })
    Tabs.Extra:AddToggle("AutoHarvest", { Title = "Auto Harvest", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoHarvest = v end)
    Tabs.Extra:AddToggle("AutoScav", { Title = "Auto Scavenger Hunt", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoScavenger = v end)

    Tabs.Extra:AddParagraph({ Title = "AFK / กันหลุด (v11.5)", Content = "" })
    Tabs.Extra:AddToggle("AntiAFK", { Title = "Anti-AFK", Description = "กันเตะ idle 20 นาที", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AntiAFK = v end)
    Tabs.Extra:AddSlider("AntiAFKInt", {
        Title = "AFK Pulse Interval (วิ)", Min = 20, Max = 300, Default = 45, Rounding = 0,
        Callback = function(v) _G.RT3_Settings.AntiAFKInterval = v end
    })
    Tabs.Extra:AddToggle("AutoRejoin", { Title = "Auto Rejoin", Description = "หลุดแล้วกลับห้องเดิม", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.AutoRejoin = v end)
    Tabs.Extra:AddButton({
        Title = "ทดสอบ AFK Pulse เดี๋ยวนี้",
        Description = "กด VirtualUser ทันที",
        Callback = function()
            if _G.RT3_AFKPulse then _G.RT3_AFKPulse("manual") end
        end
    })
    Tabs.Extra:AddInput("RejoinURL", {
        Title = "AutoRejoin URL",
        Description = "raw GitHub URL ของสคริปต์ (ไม่บังคับ)",
        Default = "",
        Numeric = false,
        Finished = false,
        Callback = function(v) _G.RT3_Settings.AutoRejoinURL = tostring(v) end
    })

    -- ======== FRIEND TAB ========
    Tabs.Friend:AddToggle("FriendMaster", { Title = "Help Friends (Master Toggle)", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.Friend_MasterFarm = v end)
    Tabs.Friend:AddParagraph({ Title = "Friend Actions", Content = "" })
    Tabs.Friend:AddToggle("FriendSeat", { Title = "Seat & Take Orders", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.Friend_AutoSeat = v; _G.RT3_Settings.Friend_AutoOrder = v end)
    Tabs.Friend:AddToggle("FriendCook", { Title = "Cook & Serve", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.Friend_AutoCook = v; _G.RT3_Settings.Friend_AutoServe = v end)
    Tabs.Friend:AddToggle("FriendClean", { Title = "Dishes, Bills & Tips", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.Friend_AutoDishes = v; _G.RT3_Settings.Friend_AutoBill = v; _G.RT3_Settings.Friend_AutoTips = v end)
    Tabs.Friend:AddToggle("FriendRude", { Title = "Calm Rude Customers", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.Friend_AutoRude = v end)
    Tabs.Friend:AddToggle("FriendDeliv", { Title = "Auto Delivery", Default = true })
        :OnChanged(function(v) _G.RT3_Settings.Friend_AutoDelivery = v end)

    -- ======== STATS TAB ========
    _statsPara = Tabs.Stats:AddParagraph({
        Title   = "Live Stats",
        Content = "กำลังโหลด...",
    })
    updateStats()
end)

if not okUI then
    _G.RT3_UIError = tostring(uiErr)
    warn("[RT3 v11] Fluent UI failed: " .. tostring(uiErr))
end
end) -- end async UI task

-- ==========================================
-- 5. ENGINE — spawnEngine() ให้ Watchdog restart ได้ [P1]
-- ==========================================
_G.RT3_EngineRestarts = _G.RT3_EngineRestarts or 0

local function spawnEngine()
task.spawn(function()
  _G.RT3_BootStage = "boot"
  _G.RT3_EngineAlive = true
  local _ok, _err = xpcall(function()
    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace         = game:GetService("Workspace")
    local LocalPlayer       = Players.LocalPlayer

    local _warned = {}
    local function req(label, getter)
        local ok, inst = pcall(getter)
        if not ok or inst == nil then
            if not _warned[label] then _warned[label] = true; warn("[RT3] get -> " .. label) end; return nil
        end
        local ok2, mod = pcall(require, inst)
        if ok2 and mod ~= nil then return mod end
        if not _warned[label] then _warned[label] = true; warn("[RT3] require -> " .. label) end; return nil
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
    local DriveThru       = req("DriveThru",      function() return PS.Source.Systems.Restaurant.DriveThru end)
    local CurrencyDrops   = req("CurrencyDrops",  function() return PS.Source.Systems.Currency.CurrencyDrops end)
    local RushHour        = req("RushHour",       function() return PS.Source.Systems.RushHour end)
    local Farming         = req("Farming",        function() return PS.Source.Systems.Farming end)
    local ScavengerHunt   = req("ScavengerHunt",  function() return PS.Source.Systems.ScavengerHunt end)
    local PlayerData      = req("PlayerData",     function() return PS.Source.Systems.PlayerData end)
    local DummyWalkSequence = req("DummyWalkSequence", function() return ReplicatedStorage.Source.Modules.Objects.DummyWalkSequence end)
    local TaskEnum          = req("TaskEnum",          function() return ReplicatedStorage.Source.Enums.Restaurant.Task end)
    local CookReplication   = req("CookReplication",   function() return ReplicatedStorage.Source.Enums.Cook.CookReplication end)
    local CookUtility       = req("CookUtility",       function() return ReplicatedStorage.Source.Utility.Cook.CookUtility end)
    local ControlsUtility   = req("ControlsUtility",   function() return ReplicatedStorage.Source.Utility.Input.ControlsUtility end)
    local CustomerState     = req("CustomerState",     function() return ReplicatedStorage.Source.Enums.Restaurant.Customer.CustomerState end)
    local CustomerType      = req("CustomerType",      function() return ReplicatedStorage.Source.Enums.Restaurant.Customer.CustomerType end)
    local FurnitureUtility  = req("FurnitureUtility",  function() return ReplicatedStorage.Source.Utility.FurnitureUtility end)
    local ItemType          = req("ItemType",          function() return ReplicatedStorage.Source.Enums.Placement.ItemType end)
    local Events = ReplicatedStorage:WaitForChild("Events", 10) or ReplicatedStorage:FindFirstChild("Events")

    if not Customers or not focusedTycoon or not Events then
        notify("RT3 v11.5", "โหลดโมดูลหลักไม่สำเร็จ — เกมอาจอัปเดต", 8); return
    end
    _G.RT3_BootStage = "modules-ok"

    local function fireThrottled(key, interval, fn)
        _G.__RT3_LastFire = _G.__RT3_LastFire or {}
        local now = os.clock()
        local last = _G.__RT3_LastFire[key]
        if last and (now - last) < (interval or _G.RT3_Settings.RemoteCooldown) then return false end
        _G.__RT3_LastFire[key] = now
        local ok, err = pcall(fn)
        if not ok and _G.RT3_Settings.RudeDebug then warn("[RT3] " .. key .. ": " .. tostring(err)) end
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

    -- RUDE RESOLVER
    local RUDE_CALM_KW = {"calm","chill","relax","take it easy","cool down","sorry","apolog","forgive","my bad","please","help","kind","nice","free","gift","discount","on the house","refund"}
    local function toArray(t) local a = {} if type(t)~="table" then return a end for _,v in ipairs(t) do a[#a+1]=v end if #a==0 then for _,v in pairs(t) do a[#a+1]=v end end return a end
    local function responseText(r) if type(r)=="string" then return r end if type(r)=="table" then return tostring(r.Text or r.Response or r.Label or r.Name or "") end return tostring(r) end
    local function pickRudeResponse(list)
        if #list == 0 then return nil end
        local mode = _G.RT3_Settings.RudeReply or "Calm"
        if mode == "First" then return list[1] end if mode == "Last" then return list[#list] end
        for _, r in ipairs(list) do local low = string.lower(responseText(r)); for _, kw in ipairs(RUDE_CALM_KW) do if string.find(low, kw, 1, true) then return r end end end
        return list[1]
    end

    local activeRude, rudeCalmed = {}, 0
    local GetRudeDialog = Events.Restaurant and Events.Restaurant.Customers and Events.Restaurant.Customers:FindFirstChild("GetRudeCustomerDialog")

    local function resolveRude(tycoon, groupId, customerId)
        if not GetRudeDialog or not hasManager(tycoon) then return end
        local key = tostring(tycoon).."|"..tostring(groupId).."|"..tostring(customerId)
        if activeRude[key] then return end; activeRude[key] = true
        task.spawn(function()
            pcall(function()
                local cData = Customers:GetCustomerData(tycoon, groupId, customerId)
                local hrp = cData and cData.Dummy and cData.Dummy:FindFirstChild("HumanoidRootPart")
                if hrp then local p = hrp:FindFirstChildOfClass("ProximityPrompt"); if p then p:Destroy() end end
            end)
            local choice = nil
            for step = 1, 10 do -- [P4]
                if not _G.RT3_Settings.AutoRude and not _G.RT3_Settings.Friend_AutoRude then break end
                local ok, texts, responses = pcall(function() return GetRudeDialog:InvokeServer(tycoon, groupId, customerId, choice) end)
                if not ok or texts == nil then break end
                local list = toArray(responses); if #list == 0 then break end
                choice = pickRudeResponse(list); if choice == nil then break end
                if _G.RT3_Settings.RudeDebug then print(("[RT3] Rude %d -> %s"):format(step, responseText(choice))) end
                task.wait(0.12)
            end
            activeRude[key] = nil
        end)
    end

    -- ENGINE HOOKS
    if DummyWalkSequence then
        if not DummyWalkSequence._OrigUpdate then
            DummyWalkSequence._OrigUpdate = DummyWalkSequence.Update
            DummyWalkSequence.Update = function(self, dt)
                if _G.RT3_Settings.NpcTurboWalk then self.Speed = _G.RT3_Settings.NpcWalkSpeed or 75; dt = dt * (_G.RT3_Settings.NpcTimeMultiplier or 5) end
                return DummyWalkSequence._OrigUpdate(self, dt)
            end
        end
        if not DummyWalkSequence._OrigNew then
            DummyWalkSequence._OrigNew = DummyWalkSequence.new
            DummyWalkSequence.new = function(dummy, path)
                local seq = DummyWalkSequence._OrigNew(dummy, path)
                if seq and _G.RT3_Settings.NpcTurboWalk then seq.Speed = _G.RT3_Settings.NpcWalkSpeed or 75 end
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
        CookingCamera.LockToStation = function(self, s) if _G.RT3_Settings.AnywhereCook then return nil end return CookingCamera._OrigLock(self, s) end
    end
    if ControlsUtility and ControlsUtility.Disable and not ControlsUtility._OrigDisable then
        ControlsUtility._OrigDisable = ControlsUtility.Disable
        ControlsUtility.Disable = function(...) if _G.RT3_Settings.AnywhereCook then return nil end return ControlsUtility._OrigDisable(...) end
    end
    local function fireInstantCook(kitchenModel, itemType)
        task.defer(function() pcall(function()
            Events.Cook.CookInputRequested:FireServer(CookReplication.Interact, kitchenModel, itemType)
            task.wait(0.01)
            Events.Cook.CookInputRequested:FireServer(CookReplication.CompleteTask, kitchenModel, itemType)
        end) end)
    end
    if Cook and Cook.OnPlayerDirectedToEquipment and not Cook._OrigDirected then
        Cook._OrigDirected = Cook.OnPlayerDirectedToEquipment
        Cook.OnPlayerDirectedToEquipment = function(self, kitchenModel, itemType, instructionKey, actionText)
            if not _G.RT3_Settings.AnywhereCook then pcall(Cook._OrigDirected, self, kitchenModel, itemType, instructionKey, actionText)
            else self.CurrentItemType = itemType; self.CurrentKitchenModel = kitchenModel end
            if _G.RT3_Settings.InstantCook then fireInstantCook(kitchenModel, itemType) end
        end
    end
    if CookingPrompts and CookingPrompts.GetOrCreate and not CookingPrompts._OrigGetOrCreate then
        CookingPrompts._OrigGetOrCreate = CookingPrompts.GetOrCreate
        CookingPrompts.GetOrCreate = function(self, kitchenModel, itemType)
            local p = CookingPrompts._OrigGetOrCreate(self, kitchenModel, itemType)
            if _G.RT3_Settings.InstantCook then fireInstantCook(kitchenModel, itemType) end; return p
        end
    end
    if Cook and Cook.EquipmentModules then
        for _, mod in pairs(Cook.EquipmentModules) do
            if mod.OnInteractionUpdated and not mod._OrigInteract then
                mod._OrigInteract = mod.OnInteractionUpdated
                mod.OnInteractionUpdated = function(self, player, tycoon, kitchenModel, equipmentName, isProgress, stepParams)
                    if not _G.RT3_Settings.AnywhereCook then pcall(mod._OrigInteract, self, player, tycoon, kitchenModel, equipmentName, isProgress, stepParams) end
                    if _G.RT3_Settings.InstantCook then task.defer(function() pcall(function()
                        if mod.TaskCompleted and stepParams then mod.TaskCompleted:Fire(player or LocalPlayer, tycoon or focusedTycoon:Get(), kitchenModel, equipmentName, stepParams) end
                        Events.Cook.CookInputRequested:FireServer(CookReplication.CompleteTask, kitchenModel, equipmentName, stepParams)
                    end) end) end
                    return nil
                end
            end
        end
    end

    -- RE-RUN SAFETY
    if _G.RT3_Conns then for _, c in ipairs(_G.RT3_Conns) do pcall(function() if c.Disconnect then c:Disconnect() end end) end end
    _G.RT3_Conns = {}
    local function on(sig, fn) if not sig then return nil end local conn = sig:Connect(fn); table.insert(_G.RT3_Conns, conn); return conn end

    -- SEATING
    if Customers.GroupStateChanged then
        on(Customers.GroupStateChanged, function(tycoon, groupId, oldState, newState)
            local valid, isFriend = isTargetTycoon(tycoon); if not valid then return end
            if (isFriend and _G.RT3_Settings.Friend_AutoSeat or _G.RT3_Settings.AutoSeat) and (newState == "Entered" or newState == "Entering") then
                Events.Restaurant.TaskCompleted:FireServer({ Name = TaskEnum.SendToTable, GroupId = groupId, Tycoon = tycoon })
            end
        end)
    end

    -- ORDERS / DINE&DASH / RUDE
    on(Customers.CustomerStateChanged, function(tycoon, groupId, customerId, oldState, newState)
        local valid, isFriend = isTargetTycoon(tycoon); if not valid then return end
        if (isFriend and _G.RT3_Settings.Friend_AutoOrder or _G.RT3_Settings.AutoOrder) and newState == CustomerState.Ordering then
            pcall(function() TakeOrder:TakeOrder(tycoon, groupId, customerId) end)
        end
        if (isFriend and _G.RT3_Settings.Friend_AutoCatchDine or _G.RT3_Settings.AutoCatchDine) and newState == CustomerState.DineAndDashing then
            pcall(function() Events.Restaurant.Customers.DineAndDashCaught:FireServer(tycoon, groupId, customerId) end)
        end
        if newState == CustomerState.CustomerAngry then
            if (isFriend and _G.RT3_Settings.Friend_AutoRude or _G.RT3_Settings.AutoRude) then resolveRude(tycoon, groupId, customerId) end
        elseif newState == CustomerState.CustomerAngry_CalmEnding then rudeCalmed = rudeCalmed + 1 end
    end)

    -- DELIVERY
    local deliveryCount = 0
    if Delivery and Delivery.OrderStateChanged then
        on(Delivery.OrderStateChanged, function(orderId, newState)
            local myTycoon = focusedTycoon:Get(); if not myTycoon or not _G.RT3_Settings.AutoDelivery then return end
            local DS = Delivery.DeliveryState
            if DS and (newState == DS.Ringing or newState == "Ringing") then
                task.defer(function() pcall(function() Events.Restaurant.TaskCompleted:FireServer({ Name = TaskEnum.TakeDeliveryOrder, DeliveryId = orderId, Tycoon = myTycoon, DeliveryAccepted = true }) end) end)
            elseif DS and (newState == DS.ReadyForPickup or newState == "ReadyForPickup") then
                task.defer(function() pcall(function() Events.Restaurant.TaskCompleted:FireServer({ Name = TaskEnum.DeliverOrder, DeliveryId = orderId, Tycoon = myTycoon }); deliveryCount = deliveryCount + 1 end) end)
            end
        end)
    end

    -- CURRENCY DROPS
    local totalDropsCollected = 0
    local function hookDropFolder(dropFolder)
        if not dropFolder or not CurrencyDrops then return end
        on(dropFolder.ChildAdded, function(drop)
            if not _G.RT3_Settings.AutoCollectDrops then return end
            task.defer(function() pcall(function()
                local ok = false
                if CurrencyDrops.ActiveDrops and (CurrencyDrops.ActiveDrops[drop] or CurrencyDrops.ActiveDrops[drop.Name]) then CurrencyDrops:QueueCollectRemote(drop); ok = true end
                if not ok then Events.Currency.PlayerCollectedDrops:FireServer({ drop }) end
                totalDropsCollected = totalDropsCollected + 1
            end) end)
        end)
    end
    task.spawn(function()
        local df = Workspace:FindFirstChild("DropFolder")
        if df then hookDropFolder(df) else on(Workspace.ChildAdded, function(c) if c.Name == "DropFolder" then hookDropFolder(c) end end) end
    end)

    -- SCAVENGER HUNT
    if ScavengerHunt and not _G.RT3_ScavHooked then
        _G.RT3_ScavHooked = true
        local _orig = ScavengerHunt.OnHuntStarted
        if _orig then
            ScavengerHunt.OnHuntStarted = function(self, ...)
                local ok = pcall(_orig, self, ...)
                task.defer(function() if not _G.RT3_Settings.AutoScavenger then return end task.wait(0.5); for _, item in pairs(ScavengerHunt.Items or {}) do pcall(function() ScavengerHunt:OnItemCollected(item) end) end end)
                return ok
            end
        end
        task.defer(function() if _G.RT3_Settings.AutoScavenger then for _, item in pairs(ScavengerHunt.Items or {}) do pcall(function() ScavengerHunt:OnItemCollected(item) end) end end end)
    end

    -- BILL / DISH [P2]
    local hookedTycoons = {}
    local billCooldown = {}
    local billCooldownLastClean = os.clock()

    local function collectFurnitureItem(tycoon, descendant, furniture)
        if not furniture then return end
        local k = descendant.Name .. "|" .. tostring(furniture)
        local now = os.clock()
        if now - billCooldownLastClean > 300 then -- [P2] cleanup ทุก 5 นาที
            billCooldownLastClean = now
            for key, t in pairs(billCooldown) do if now - t > 5 then billCooldown[key] = nil end end
        end
        if billCooldown[k] and (now - billCooldown[k]) < 1 then return end
        billCooldown[k] = now
        Events.Restaurant.TaskCompleted:FireServer({
            Name = (descendant.Name == "Bill") and TaskEnum.CollectBill or TaskEnum.CollectDishes,
            FurnitureModel = furniture, Tycoon = tycoon,
        })
    end

    local function hookTycoonItems(tycoon)
        if not tycoon or hookedTycoons[tycoon] or not tycoon:FindFirstChild("Items") then return end
        hookedTycoons[tycoon] = true
        on(tycoon.Items.DescendantAdded, function(descendant)
            local valid, isFriend = isTargetTycoon(tycoon); if not valid then return end
            if descendant.Name == "Bill" and (isFriend and _G.RT3_Settings.Friend_AutoBill or _G.RT3_Settings.AutoBill) then
                collectFurnitureItem(tycoon, descendant, descendant:FindFirstAncestorOfClass("Model"))
            elseif descendant.Name == "Trash" and (isFriend and _G.RT3_Settings.Friend_AutoDishes or _G.RT3_Settings.AutoDishes) then
                collectFurnitureItem(tycoon, descendant, descendant:FindFirstAncestorOfClass("Model"))
            end
        end)
    end

    -- SERVING [P3]
    local grabBusy = false
    local carFoodBlockByName = {}  -- [P3] name -> expireTime
    local lastHoldSig, lastHoldSince = nil, nil

    local function processFoodServing(tycoon)
        if not GrabFood or not ServeFood or not Customers then return end
        local custFolder = tycoon:FindFirstChild("ClientCustomers")
        local foodFolder = tycoon:FindFirstChild("Objects") and tycoon.Objects:FindFirstChild("Food")
        if not custFolder or not foodFolder then return end
        local holdCap = GrabFood:GetPlayerHoldCapacity(tycoon) or 1
        if #GrabFood.Storage > 0 and GrabFood.Storage[1].Tycoon ~= tycoon then GrabFood:OnCancelPressed(); task.wait(0.01) end

        for _, g in ipairs(custFolder:GetChildren()) do
            for _, c in ipairs(g:GetChildren()) do
                if Customers:GetCustomerState(tycoon, g.Name, c.Name) == CustomerState.WaitingForDish then
                    local cData = Customers:GetCustomerData(tycoon, g.Name, c.Name)
                    local order = cData and cData.Order
                    if order and GrabFood:IsHoldingFoodForNPC(order, cData.CustomerType == CustomerType.Kid) then
                        task.spawn(ServeFood.CompleteForNPC, ServeFood, tycoon, g.Name, c.Name)
                    end
                end
            end
        end

        if not grabBusy and #GrabFood.Storage < holdCap then
            grabBusy = true
            task.spawn(function()
                pcall(function()
                    local deadline = os.clock() + 1.2
                    while #GrabFood.Storage < holdCap and os.clock() < deadline do
                        local nowT = os.clock()
                        for n, exp in pairs(carFoodBlockByName) do if nowT >= exp then carFoodBlockByName[n] = nil end end -- [P3] cleanup
                        local carWanted = {}
                        if DriveThru then
                            local cc = tycoon:FindFirstChild("ClientCars")
                            if cc then for _, car in ipairs(cc:GetChildren()) do
                                local okc, cd = pcall(function() return DriveThru:GetCarData(tycoon, car.Name) end)
                                if okc and cd and type(cd.Orders) == "table" then for _, o in pairs(cd.Orders) do local k = tostring(o); carWanted[k] = (carWanted[k] or 0) + 1 end end
                            end end
                        end
                        local cache = {}
                        for _, food in ipairs(foodFolder:GetChildren()) do
                            local n = food.Name
                            if food.Parent and not (carFoodBlockByName[n] and nowT < carFoodBlockByName[n]) and not food:GetAttribute("Taken") then
                                if carWanted[n] and carWanted[n] > 0 then carWanted[n] = carWanted[n] - 1
                                else cache[n] = cache[n] or {}; table.insert(cache[n], food) end
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
                                    if order and not GrabFood:IsHoldingFoodForNPC(order, cData.CustomerType == CustomerType.Kid) then
                                        local food = cache[tostring(order)] and table.remove(cache[tostring(order)], 1)
                                        if food and food.Parent then
                                            local before = #GrabFood.Storage
                                            GrabFood:AttemptGrab(tycoon, food)
                                            local entry = (#GrabFood.Storage > before) and GrabFood.Storage[#GrabFood.Storage] or nil
                                            if entry and entry.TargetCarId ~= nil then
                                                GrabFood:OnCancelPressed(); carFoodBlockByName[food.Name] = os.clock() + 5; task.wait(0.03) -- [P3]
                                            elseif entry then
                                                grabbed = true
                                                local gN, cN = g.Name, c.Name
                                                task.spawn(function() task.wait(0.01); ServeFood:CompleteForNPC(tycoon, gN, cN) end)
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

        if #GrabFood.Storage > 0 then
            local now = os.clock(); local sig = ""
            for _, it in ipairs(GrabFood.Storage) do sig = sig .. tostring(it.FoodKey) .. "," end
            if sig == lastHoldSig then lastHoldSince = lastHoldSince or now; if now - lastHoldSince > 8 then GrabFood:OnCancelPressed(); lastHoldSig, lastHoldSince = nil, nil; task.wait(0.01) end
            else lastHoldSig, lastHoldSince = sig, now end
        else lastHoldSig, lastHoldSince = nil, nil end

        if #GrabFood.Storage > 0 then
            local any = false
            for _, g in ipairs(custFolder:GetChildren()) do
                for _, c in ipairs(g:GetChildren()) do
                    if Customers:GetCustomerState(tycoon, g.Name, c.Name) == CustomerState.WaitingForDish then
                        local cData = Customers:GetCustomerData(tycoon, g.Name, c.Name)
                        if cData and GrabFood:IsHoldingFoodForNPC(cData.Order, cData.CustomerType == CustomerType.Kid) then any = true; break end
                    end
                end; if any then break end
            end
            if not any then GrabFood:OnCancelPressed() end
        end
    end

    -- SLOW CYCLE
    local function collectTips(tycoon)
        if not FurnitureUtility or not ItemType then return end
        local furn = tycoon:FindFirstChild("Items") and tycoon.Items:FindFirstChild("Furniture"); if not furn then return end
        local any = false
        for _, m in ipairs(furn:GetChildren()) do
            if m:IsA("Model") then
                local ok, isJar = pcall(function() return FurnitureUtility:Is(m.Name, ItemType.TipJar) end)
                if ok and isJar then
                    if (tonumber(m:GetAttribute("Value")) or 0) > 0 then any = true
                    else for _, d in ipairs(m:GetDescendants()) do if d:IsA("Model") then local ok2,j2=pcall(function() return FurnitureUtility:Is(d.Name, ItemType.TipJar) end); if ok2 and j2 and (tonumber(d:GetAttribute("Value")) or 0)>0 then any=true; break end end end end
                end
            end; if any then break end
        end
        if any then fireThrottled("tips|"..tostring(tycoon), _G.RT3_Settings.RemoteCooldown, function() Events.Restaurant.TipsCollected:FireServer(tycoon) end) end
    end

    local function sweepBills(tycoon, isFriend)
        local items = tycoon:FindFirstChild("Items"); if not items then return end
        local wB = isFriend and _G.RT3_Settings.Friend_AutoBill or _G.RT3_Settings.AutoBill
        local wD = isFriend and _G.RT3_Settings.Friend_AutoDishes or _G.RT3_Settings.AutoDishes
        if not (wB or wD) then return end
        for _, d in ipairs(items:GetDescendants()) do
            if (d.Name=="Bill" and wB) or (d.Name=="Trash" and wD) then collectFurnitureItem(tycoon, d, d:FindFirstAncestorOfClass("Model")) end
        end
    end

    local function sweepSeat(tycoon, isFriend)
        if not Customers.GetGroupState or not (isFriend and _G.RT3_Settings.Friend_AutoSeat or _G.RT3_Settings.AutoSeat) then return end
        local cf = tycoon:FindFirstChild("ClientCustomers"); if not cf then return end
        for _, g in ipairs(cf:GetChildren()) do
            local ok, st = pcall(function() return Customers:GetGroupState(tycoon, g.Name) end)
            if ok and (st=="Entered" or st=="Entering") then
                fireThrottled("seat|"..tostring(tycoon).."|"..g.Name, 1.2, function() Events.Restaurant.TaskCompleted:FireServer({Name=TaskEnum.SendToTable, GroupId=g.Name, Tycoon=tycoon}) end)
            end
        end
    end

    local function sweepOrders(tycoon, isFriend)
        if not (isFriend and _G.RT3_Settings.Friend_AutoOrder or _G.RT3_Settings.AutoOrder) then return end
        local cf = tycoon:FindFirstChild("ClientCustomers"); if not cf then return end
        for _, g in ipairs(cf:GetChildren()) do for _, c in ipairs(g:GetChildren()) do
            local ok, st = pcall(function() return Customers:GetCustomerState(tycoon, g.Name, c.Name) end)
            if ok and st == CustomerState.Ordering then
                fireThrottled("order|"..tostring(tycoon).."|"..c.Name, 1.2, function() TakeOrder:TakeOrder(tycoon, g.Name, c.Name) end)
            end
        end end
    end

    local function runAutoHarvest()
        if not _G.RT3_Settings.AutoHarvest or not Farming then return end
        for _, tile in pairs(Farming.TrackedTiles or {}) do
            if typeof(tile)=="Instance" then pcall(function() if Farming:GetState(tile)==Farming.States.Completed then Farming:RequestHarvest(tile) end end) end
        end
    end

    local friendCache, friendCacheTime = {}, 0
    local function getPermittedFriendTycoons()
        local now = os.clock(); if now - friendCacheTime < 1.5 then return friendCache end
        friendCacheTime = now; local out = {}
        local tc = Workspace:FindFirstChild("Tycoons")
        if tc and Managers then for _, t in ipairs(tc:GetChildren()) do
            local owner = t:FindFirstChild("Player") and t.Player.Value
            if owner and owner ~= LocalPlayer then
                local ok, perm = pcall(function() return Managers:HasPermission(t, Managers.PermissionLevel.Employee) end)
                if ok and perm then table.insert(out, t); hookTycoonItems(t) end
            end
        end end
        friendCache = out; return out
    end

    local function runTycoonCycle(tycoon, isFriend)
        if not tycoon then return end; hookTycoonItems(tycoon)
        local cooking = Cook and Cook.IsCooking
        local srv = isFriend and _G.RT3_Settings.Friend_AutoServe or _G.RT3_Settings.AutoServe
        local ck  = isFriend and _G.RT3_Settings.Friend_AutoCook  or _G.RT3_Settings.AnywhereCook
        if srv and not cooking then processFoodServing(tycoon) end
        if ck and Interactions and Interactions.PromptData and not cooking then
            local pd = Interactions.PromptData[tycoon]
            if pd and #GrabFood.Storage == 0 then for _, pInfo in pairs(pd) do if pInfo.Key == "Cook" then Interactions:Interact(tycoon, pInfo); break end end end
        end
    end

    -- MAIN LOOP
    local adBoostTimer, offlineTimer, rushTimer, harvestTimer = 0, 0, 0, 0
    local nextSlow = os.clock() + (_G.RT3_Settings.SlowTick or 1)
    _G.RT3_BootStage = "loop-start"; _G.RT3_EngineError = nil; _G.AutoFarmRunning = true; _G.RT3_EngineHeartbeat = os.clock()

    while _G.AutoFarmRunning do
        _G.RT3_EngineHeartbeat = os.clock()
        pcall(function()
            local myTycoon = focusedTycoon:Get()
            if _G.RT3_Settings.AnywhereCook then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
            end
            if _G.RT3_Settings.MasterAutoFarm and myTycoon then runTycoonCycle(myTycoon, false) end
            if _G.RT3_Settings.Friend_MasterFarm then for _, ft in ipairs(getPermittedFriendTycoons()) do runTycoonCycle(ft, true) end end

            local now = os.clock()
            if now >= nextSlow then
                nextSlow = now + (_G.RT3_Settings.SlowTick or 1)
                local curCash = PlayerData and PlayerData:GetKey(PlayerData.DataStoreType.Restaurant, "Cash")
                if curCash then CashLabel:Set("Cash: $" .. tostring(curCash)) end
                if myTycoon and myTycoon:FindFirstChild("ClientCustomers") then
                    local cnt = 0; for _, g in ipairs(myTycoon.ClientCustomers:GetChildren()) do cnt = cnt + #g:GetChildren() end
                    CustomerLabel:Set("Customers: " .. cnt)
                end
                local food = myTycoon and myTycoon:FindFirstChild("Objects") and myTycoon.Objects:FindFirstChild("Food")
                if food then FoodLabel:Set("Food Ready: " .. #food:GetChildren()) end
                if Delivery then
                    local ol = Delivery:GetOrders(myTycoon) or {}; local oc = 0; for _ in pairs(ol) do oc = oc + 1 end
                    DeliveryLabel:Set("Deliveries: " .. oc .. " active | Done: " .. deliveryCount)
                end
                DropsLabel:Set("Drops Collected: " .. totalDropsCollected)
                if RushHour then RushLabel:Set("Rush Hour: " .. (RushHour:IsActive() and "ACTIVE" or "Inactive")) end
                local ra = 0; for _ in pairs(activeRude) do ra = ra + 1 end
                RudeLabel:Set("Rude Calmed: " .. rudeCalmed .. " | Active: " .. ra)
                HealthLabel:Set("Engine: RUNNING | Restarts: " .. tostring(_G.RT3_EngineRestarts))
                local A = _G.RT3_AFK or {}
                if AFKLabel then
                    local idleFor = os.clock() - (A.lastInput or os.clock())
                    local up = math.floor(time())
                    AFKLabel:Set(string.format("AFK: %s | Pulse: %d | Idle: %ds | Up: %dh%dm",
                        _G.RT3_Settings.AntiAFK and "ON" or "OFF", A.pulses or 0, math.floor(idleFor),
                        math.floor(up/3600), math.floor((up%3600)/60)))
                end
                if #friendCache > 0 then
                    local names = {}; for _, ft in ipairs(friendCache) do local o = ft:FindFirstChild("Player") and ft.Player.Value; table.insert(names, o and o.Name or "?") end
                    FriendInfoLabel:Set("Helping: " .. table.concat(names, ", "))
                else FriendInfoLabel:Set("Friends: none (need Employee role)") end

                local function slowFor(ty, isFriend)
                    if not ty then return end
                    if (isFriend and _G.RT3_Settings.Friend_AutoTips or _G.RT3_Settings.AutoTips) then collectTips(ty) end
                    sweepBills(ty, isFriend); sweepSeat(ty, isFriend); sweepOrders(ty, isFriend)
                end
                slowFor(myTycoon, false)
                if _G.RT3_Settings.Friend_MasterFarm then for _, ft in ipairs(getPermittedFriendTycoons()) do slowFor(ft, true) end end
                harvestTimer = harvestTimer + 1; if harvestTimer >= 10 then harvestTimer = 0; runAutoHarvest() end
            end

            adBoostTimer = adBoostTimer + 1
            if adBoostTimer >= 10800 or adBoostTimer == 1 then
                if _G.RT3_Settings.Infinite15xBoost then pcall(function() Events.Shop.RewardedAdEvent:FireServer("ShortAdBoost") end) end; adBoostTimer = 2
            end
            offlineTimer = offlineTimer + 1
            if offlineTimer >= 300 then offlineTimer = 0; if _G.RT3_Settings.AutoClaimOffline then pcall(function() Events.Upgrades.CollectOfflineEarningsRequested:FireServer() end) end end
            rushTimer = rushTimer + 1
            if rushTimer >= 600 then rushTimer = 0; if _G.RT3_Settings.AutoRushHour and RushHour then pcall(function() if RushHour:CanStartNow() then Events.RushHour.RushHourActivateRequested:FireServer() end end) end end
        end)
        task.wait(_G.RT3_Settings.TickRate or 0.05)
    end
  end, function(e) _G.RT3_EngineError = tostring(e); return _G.RT3_EngineError end)
  _G.RT3_EngineAlive = false
  if not _ok then warn("[RT3 v11] ENGINE ERROR: " .. tostring(_err)) end
end)
end

spawnEngine()

-- ==========================================
-- 6. AFK GUARDIAN (v11.5)
-- ==========================================
if not _G.RT3_AFKGuard then
_G.RT3_AFKGuard = true
_G.RT3_AFK = { pulses = 0, idled = 0, lastPulse = 0, lastInput = os.clock(), rejoins = 0, lastReason = "-" }

task.spawn(function()
    local UIS = game:GetService("UserInputService")
    local function mark() _G.RT3_AFK.lastInput = os.clock() end
    pcall(function() UIS.InputBegan:Connect(mark) end)
    pcall(function() UIS.InputChanged:Connect(mark) end)
end)

function _G.RT3_AFKPulse(reason)
    local vu; pcall(function() vu = game:GetService("VirtualUser") end)
    if vu then pcall(function() vu:CaptureController() end); pcall(function() vu:ClickButton2(Vector2.new()) end) end
    if typeof(mousemoverel) == "function" then
        pcall(function() mousemoverel(3, 0) end)
        task.delay(0.08, function() pcall(function() mousemoverel(-3, 0) end) end)
    end
    local A = _G.RT3_AFK; A.pulses = A.pulses + 1; A.lastPulse = os.clock(); A.lastReason = tostring(reason)
    return true
end

-- Idled event
pcall(function()
    local LP = game:GetService("Players").LocalPlayer
    LP.Idled:Connect(function()
        _G.RT3_AFK.idled = _G.RT3_AFK.idled + 1
        if _G.RT3_Settings.AntiAFK then _G.RT3_AFKPulse("idled") end
    end)
end)

-- [P5] timer pulse ทุก interval เสมอ ไม่มีเงื่อนไข idleFor
task.spawn(function()
    while _G.RT3_AFKGuard do
        task.wait(_G.RT3_Settings.AntiAFKInterval or 45)
        if _G.RT3_Settings.AntiAFK then _G.RT3_AFKPulse("timer") end
    end
end)

-- Auto Rejoin save
if typeof(writefile) == "function" then
    task.spawn(function()
        local selfSrc; pcall(function()
            local info = debug.getinfo(1, "S"); local s = info and info.source; if not s then return end
            if s:sub(1,1) == "@" then local p = s:sub(2); if typeof(isfile)=="function" and typeof(readfile)=="function" and isfile(p) then selfSrc = readfile(p) end
            elseif s:sub(1,1) ~= "=" and #s > 2000 then selfSrc = s end
        end)
        if selfSrc then pcall(function() writefile("RT3_Self.lua", selfSrc) end) end
        while _G.RT3_AFKGuard do
            if _G.RT3_Settings.AutoRejoin then
                pcall(function()
                    writefile("RT3_Session.json", game:GetService("HttpService"):JSONEncode({
                        placeId = game.PlaceId, jobId = game.JobId, ts = os.time(),
                        pulses = _G.RT3_AFK.pulses, version = "v11.5-fluent",
                        url = _G.RT3_Settings.AutoRejoinURL or "",
                    }))
                end)
            end
            task.wait(60)
        end
    end)
end

if _G.RT3_Settings.AutoRejoinURL ~= "" and typeof(queue_on_teleport) == "function" then
    pcall(function() queue_on_teleport('loadstring(game:HttpGet("' .. _G.RT3_Settings.AutoRejoinURL .. '"))()') end)
end
end

-- ==========================================
-- 7. WATCHDOG v11.5 [P1] — restart engine จริงถ้า stall >20s
-- ==========================================
if not _G.RT3_Watchdog then
_G.RT3_Watchdog = true
task.spawn(function()
    while true do
        task.wait(10)
        local hb = _G.RT3_EngineHeartbeat
        if _G.AutoFarmRunning and hb and (os.clock() - hb) > 20 then
            warn("[RT3 v11] Engine stalled — restarting")
            _G.AutoFarmRunning = false
            task.wait(1)
            _G.RT3_EngineRestarts = (_G.RT3_EngineRestarts or 0) + 1
            spawnEngine()
        end
    end
end)
end

notify("RT3 Suite v11.5 (Fluent)", "All-Day AFK | P1-P5 Patches Active | Engine Auto-Restart", 6)
