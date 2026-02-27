-- ================================================
-- SORCERER SCRIPTS - RAYFIELD UI v22
-- Auto Farm | Dump Boss | Dash No CD
-- Skills | Auto Awakening | Movement
-- Key System via GitHub
-- ================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")

print("[SorcererScript] Starting...")

local Player    = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")
local HRP       = Character:WaitForChild("HumanoidRootPart")

local function GetHRP()
    local char = Player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ================================================
-- KEY SYSTEM CONFIG
-- ================================================
local KEYS_URL    = "https://raw.githubusercontent.com/szdeath/sorcerertycoonkeys/refs/heads/main/Keys.txt"
local WORKINK_URL = "https://work.ink/2kRm/checkpoint-1"
local SAVE_FILE   = "sorcerer_key.txt"

-- ================================================
-- KEY SYSTEM FUNCTIONS
-- ================================================

local function FetchKeysFromGitHub()
    local ok, response = pcall(function()
        return game:HttpGet(KEYS_URL)
    end)
    if not ok or not response then return nil end
    local keys = {}
    for line in response:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and line:sub(1,1) ~= "#" and line:sub(1,2) ~= "--" then
            table.insert(keys, line)
        end
    end
    return keys
end

local function SaveKeyLocally(key)
    if not (writefile and isfile) then return end
    local data = { key=key, savedAt=os.time() }
    pcall(function() writefile(SAVE_FILE, HttpService:JSONEncode(data)) end)
end

local function LoadSavedKey()
    if not (readfile and isfile) then return nil end
    if not isfile(SAVE_FILE) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(SAVE_FILE)) end)
    if ok and type(data) == "table" then return data end
    return nil
end

local function DeleteSavedKey()
    if not (delfile and isfile) then return end
    if isfile(SAVE_FILE) then pcall(function() delfile(SAVE_FILE) end) end
end

local function ValidateKey(inputKey, keysData)
    if not keysData then return false end
    for _, k in ipairs(keysData) do
        if k == inputKey then return true end
    end
    return false
end

local function ValidateSavedKey(savedData, keysData)
    if not savedData or not savedData.key then return false end
    if not keysData then return false end
    for _, k in ipairs(keysData) do
        if k == savedData.key then return true end
    end
    return false
end

local function FormatTime(secs)
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    return string.format("%02dh %02dm %02ds", h, m, s)
end

-- ================================================
-- KEY SYSTEM UI  (English + Minimize + Close)
-- ================================================
local function ShowKeyUI(keysData, onSuccess)
    local old = Player.PlayerGui:FindFirstChild("SorcKeyUI")
    if old then old:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name              = "SorcKeyUI"
    ScreenGui.ResetOnSpawn      = false
    ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder      = 9999
    ScreenGui.Parent            = Player.PlayerGui

    -- Dark overlay
    local Overlay = Instance.new("Frame")
    Overlay.Size                    = UDim2.new(1,0,1,0)
    Overlay.BackgroundColor3        = Color3.fromRGB(0,0,0)
    Overlay.BackgroundTransparency  = 0.45
    Overlay.BorderSizePixel         = 0
    Overlay.ZIndex                  = 1
    Overlay.Parent                  = ScreenGui

    -- Main window
    local Main = Instance.new("Frame")
    Main.Size               = UDim2.new(0, 480, 0, 330)
    Main.Position           = UDim2.new(0.5, -240, 2, 0)
    Main.BackgroundColor3   = Color3.fromRGB(12, 12, 20)
    Main.BorderSizePixel    = 0
    Main.ZIndex             = 2
    Main.Parent             = ScreenGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

    local Stroke = Instance.new("UIStroke")
    Stroke.Color        = Color3.fromRGB(80, 120, 255)
    Stroke.Thickness    = 1.5
    Stroke.Transparency = 0.2
    Stroke.Parent       = Main

    -- Header
    local Header = Instance.new("Frame")
    Header.Size             = UDim2.new(1,0,0,68)
    Header.BackgroundColor3 = Color3.fromRGB(50, 80, 200)
    Header.BorderSizePixel  = 0
    Header.ZIndex           = 3
    Header.Parent           = Main
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size              = UDim2.new(1,0,0,14)
    HeaderFix.Position          = UDim2.new(0,0,1,-14)
    HeaderFix.BackgroundColor3  = Color3.fromRGB(50, 80, 200)
    HeaderFix.BorderSizePixel   = 0
    HeaderFix.ZIndex            = 3
    HeaderFix.Parent            = Header

    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40,70,220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100,60,220)),
    })
    UIGradient.Rotation = 90
    UIGradient.Parent   = Header

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size                  = UDim2.new(1,-80,1,0)
    Title.Position              = UDim2.new(0,15,0,0)
    Title.BackgroundTransparency= 1
    Title.Text                  = "🔑  Sorcerer Scripts  —  Key System"
    Title.TextColor3            = Color3.fromRGB(255,255,255)
    Title.TextScaled            = true
    Title.Font                  = Enum.Font.GothamBold
    Title.ZIndex                = 4
    Title.Parent                = Header

    -- ── MINIMIZE BUTTON ──────────────────────────────
    local BtnMin = Instance.new("TextButton")
    BtnMin.Size             = UDim2.new(0,30,0,30)
    BtnMin.Position         = UDim2.new(1,-74,0,19)
    BtnMin.BackgroundColor3 = Color3.fromRGB(40,40,70)
    BtnMin.BorderSizePixel  = 0
    BtnMin.Text             = "—"
    BtnMin.TextColor3       = Color3.fromRGB(200,200,255)
    BtnMin.TextSize         = 14
    BtnMin.Font             = Enum.Font.GothamBold
    BtnMin.ZIndex           = 5
    BtnMin.Parent           = Header
    Instance.new("UICorner", BtnMin).CornerRadius = UDim.new(0,6)

    -- ── CLOSE BUTTON ─────────────────────────────────
    local BtnClose = Instance.new("TextButton")
    BtnClose.Size               = UDim2.new(0,30,0,30)
    BtnClose.Position           = UDim2.new(1,-38,0,19)
    BtnClose.BackgroundColor3   = Color3.fromRGB(180,40,40)
    BtnClose.BorderSizePixel    = 0
    BtnClose.Text               = "✕"
    BtnClose.TextColor3         = Color3.fromRGB(255,255,255)
    BtnClose.TextSize           = 14
    BtnClose.Font               = Enum.Font.GothamBold
    BtnClose.ZIndex             = 5
    BtnClose.Parent             = Header
    Instance.new("UICorner", BtnClose).CornerRadius = UDim.new(0,6)

    -- Content frame (everything below header)
    local Content = Instance.new("Frame")
    Content.Size                    = UDim2.new(1,0,1,-68)
    Content.Position                = UDim2.new(0,0,0,68)
    Content.BackgroundTransparency  = 1
    Content.ZIndex                  = 3
    Content.Parent                  = Main

    -- Sub-title
    local Sub = Instance.new("TextLabel")
    Sub.Size                    = UDim2.new(1,0,0,22)
    Sub.Position                = UDim2.new(0,0,0,8)
    Sub.BackgroundTransparency  = 1
    Sub.Text                    = "Enter your key below to access the script"
    Sub.TextColor3              = Color3.fromRGB(160,160,200)
    Sub.TextSize                = 13
    Sub.Font                    = Enum.Font.Gotham
    Sub.ZIndex                  = 3
    Sub.Parent                  = Content

    -- (24H/LIFETIME badge removed)

    -- Input box
    local InputBG = Instance.new("Frame")
    InputBG.Size            = UDim2.new(1,-40,0,46)
    InputBG.Position        = UDim2.new(0,20,0,40)
    InputBG.BackgroundColor3= Color3.fromRGB(20,20,35)
    InputBG.BorderSizePixel = 0
    InputBG.ZIndex          = 3
    InputBG.Parent          = Content
    Instance.new("UICorner", InputBG).CornerRadius = UDim.new(0,10)

    local InputStroke = Instance.new("UIStroke")
    InputStroke.Color       = Color3.fromRGB(55,55,90)
    InputStroke.Thickness   = 1
    InputStroke.Parent      = InputBG

    local Input = Instance.new("TextBox")
    Input.Size                  = UDim2.new(1,-20,1,0)
    Input.Position              = UDim2.new(0,10,0,0)
    Input.BackgroundTransparency= 1
    Input.PlaceholderText       = "Paste your key here..."
    Input.PlaceholderColor3     = Color3.fromRGB(90,90,120)
    Input.Text                  = ""
    Input.TextColor3            = Color3.fromRGB(255,255,255)
    Input.TextSize              = 14
    Input.Font                  = Enum.Font.Code
    Input.ClearTextOnFocus      = false
    Input.ZIndex                = 4
    Input.Parent                = InputBG

    -- Status
    local Status = Instance.new("TextLabel")
    Status.Size                 = UDim2.new(1,-40,0,26)
    Status.Position             = UDim2.new(0,20,0,94)
    Status.BackgroundTransparency= 1
    Status.Text                 = ""
    Status.TextColor3           = Color3.fromRGB(255,100,100)
    Status.TextSize             = 13
    Status.Font                 = Enum.Font.Gotham
    Status.TextXAlignment       = Enum.TextXAlignment.Left
    Status.ZIndex               = 3
    Status.Parent               = Content

    -- Confirm button
    local BtnConfirm = Instance.new("TextButton")
    BtnConfirm.Size             = UDim2.new(0,195,0,44)
    BtnConfirm.Position         = UDim2.new(0,20,0,128)
    BtnConfirm.BackgroundColor3 = Color3.fromRGB(60,100,230)
    BtnConfirm.BorderSizePixel  = 0
    BtnConfirm.Text             = "✅  Confirm Key"
    BtnConfirm.TextColor3       = Color3.fromRGB(255,255,255)
    BtnConfirm.TextSize         = 14
    BtnConfirm.Font             = Enum.Font.GothamBold
    BtnConfirm.ZIndex           = 3
    BtnConfirm.Parent           = Content
    Instance.new("UICorner", BtnConfirm).CornerRadius = UDim.new(0,10)

    -- Get Key button
    local BtnGet = Instance.new("TextButton")
    BtnGet.Size             = UDim2.new(0,195,0,44)
    BtnGet.Position         = UDim2.new(0,265,0,128)
    BtnGet.BackgroundColor3 = Color3.fromRGB(18,18,32)
    BtnGet.BorderSizePixel  = 0
    BtnGet.Text             = "🌐  Get Key"
    BtnGet.TextColor3       = Color3.fromRGB(180,180,255)
    BtnGet.TextSize         = 14
    BtnGet.Font             = Enum.Font.GothamBold
    BtnGet.ZIndex           = 3
    BtnGet.Parent           = Content
    Instance.new("UICorner", BtnGet).CornerRadius = UDim.new(0,10)

    local BtnGetStroke = Instance.new("UIStroke")
    BtnGetStroke.Color      = Color3.fromRGB(60,100,230)
    BtnGetStroke.Thickness  = 1.2
    BtnGetStroke.Parent     = BtnGet

    -- Footer
    local Footer = Instance.new("TextLabel")
    Footer.Size                 = UDim2.new(1,0,0,22)
    Footer.Position             = UDim2.new(0,0,0,184)
    Footer.BackgroundTransparency= 1
    Footer.Text                 = "Made by Ikki  •  Keys provided via Work.ink"
    Footer.TextColor3           = Color3.fromRGB(70,70,100)
    Footer.TextSize             = 11
    Footer.Font                 = Enum.Font.Gotham
    Footer.ZIndex               = 3
    Footer.Parent               = Content

    -- Animate in
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5,-240,0.5,-165)
    }):Play()

    -- ── MINIMIZE logic ────────────────────────────────
    local minimized = false
    BtnMin.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 480, 0, 68)
            }):Play()
            Content.Visible = false
            BtnMin.Text = "▢"
        else
            Content.Visible = true
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 480, 0, 360)
            }):Play()
            BtnMin.Text = "—"
        end
    end)

    -- ── CLOSE logic ──────────────────────────────────
    BtnClose.MouseButton1Click:Connect(function()
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5,-240,-1.5,0)
        }):Play()
        task.wait(0.4)
        ScreenGui:Destroy()
    end)

    -- ── GET KEY logic ─────────────────────────────────
    BtnGet.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(WORKINK_URL)
            Status.TextColor3 = Color3.fromRGB(100,180,255)
            Status.Text = "🔗 Link copied! Paste it in your browser."
        else
            Status.TextColor3 = Color3.fromRGB(100,180,255)
            Status.Text = "🔗 Visit: " .. WORKINK_URL
        end
    end)

    -- ── CONFIRM logic ─────────────────────────────────
    BtnConfirm.MouseButton1Click:Connect(function()
        local key = Input.Text:gsub("%s+", "")
        if key == "" then
            Status.TextColor3 = Color3.fromRGB(255,100,100)
            Status.Text = "❌ Please enter a key!"
            return
        end

        Status.TextColor3 = Color3.fromRGB(180,180,255)
        Status.Text = "⏳ Verifying..."
        BtnConfirm.Text  = "Please wait..."
        BtnConfirm.Active = false

        task.spawn(function()
            local kd = keysData
            if not kd then kd = FetchKeysFromGitHub() end

            local valid = ValidateKey(key, kd)

            if valid then
                SaveKeyLocally(key)
                Status.TextColor3 = Color3.fromRGB(100,255,150)
                Status.Text = "✅ Valid key! Loading..."
                task.wait(1.2)
                TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Position = UDim2.new(0.5,-240,-1.5,0)
                }):Play()
                task.wait(0.5)
                ScreenGui:Destroy()
                onSuccess()
            else
                Status.TextColor3 = Color3.fromRGB(255,80,80)
                Status.Text = "❌ Wrong key or key expired!"
                BtnConfirm.Text  = "✅  Confirm Key"
                BtnConfirm.Active = true

                local orig = InputBG.BackgroundColor3
                TweenService:Create(InputBG, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(60,15,15)}):Play()
                task.wait(0.3)
                TweenService:Create(InputBG, TweenInfo.new(0.3), {BackgroundColor3 = orig}):Play()
            end
        end)
    end)
end

-- Post-login notification
local function ShowKeyNotification()
    local old = Player.PlayerGui:FindFirstChild("SorcKeyNotif")
    if old then old:Destroy() end

    local SG = Instance.new("ScreenGui")
    SG.Name = "SorcKeyNotif"; SG.ResetOnSpawn = false; SG.Parent = Player.PlayerGui

    local F = Instance.new("Frame")
    F.Size              = UDim2.new(0,340,0,52)
    F.Position          = UDim2.new(1,10,0,16)
    F.BackgroundColor3  = Color3.fromRGB(12,12,20)
    F.BorderSizePixel   = 0
    F.Parent            = SG
    Instance.new("UICorner", F).CornerRadius = UDim.new(0,10)

    local S = Instance.new("UIStroke")
    S.Color     = Color3.fromRGB(100,255,150)
    S.Thickness = 1.5
    S.Parent    = F

    local L = Instance.new("TextLabel")
    L.Size                  = UDim2.new(1,-16,1,0)
    L.Position              = UDim2.new(0,12,0,0)
    L.BackgroundTransparency= 1
    L.TextXAlignment        = Enum.TextXAlignment.Left
    L.TextColor3            = Color3.fromRGB(220,220,255)
    L.TextSize              = 13
    L.Font                  = Enum.Font.GothamBold
    L.Parent                = F
    L.Text                  = "✅ Key active — Sorcerer Scripts"

    TweenService:Create(F, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(1,-355,0,16)
    }):Play()

    task.delay(5, function()
        TweenService:Create(F, TweenInfo.new(0.3), {Position = UDim2.new(1,10,0,16)}):Play()
        task.wait(0.4)
        SG:Destroy()
    end)
end

-- ================================================
-- INITIALIZE KEY SYSTEM
-- ================================================
local KeySystemPassed = false

local function InitKeySystem(callback)
    local keysData = FetchKeysFromGitHub()

    local savedData = LoadSavedKey()
    if savedData then
        local valid = ValidateSavedKey(savedData, keysData)
        if valid then
            print("[KeySystem] Saved key valid.")
            KeySystemPassed = true
            ShowKeyNotification()
            callback()
            return
        else
            print("[KeySystem] Saved key invalid/expired.")
            DeleteSavedKey()
        end
    end

    ShowKeyUI(keysData, function()
        KeySystemPassed = true
        ShowKeyNotification()
        callback()
    end)
end

-- ================================================
-- EVERYTHING BELOW RUNS ONLY AFTER VALID KEY
-- ================================================
InitKeySystem(function()

print("[SorcererScript] Key OK")

-- ================================================
-- REMOTES
-- ================================================
local Assets  = ReplicatedStorage:WaitForChild("Assets")
local Remotes = Assets:WaitForChild("Remotes")

local function GetRemote(path)
    local obj = Remotes
    for _, key in ipairs(path) do
        obj = obj:FindFirstChild(key)
        if not obj then return nil end
    end
    return obj
end

local LimitBreakRemote  = GetRemote({"LimitBreaker",      "LimitBreak"})
local RebirthRemote     = GetRemote({"Tycoon",             "Rebirth"})
local SpeedRemote       = GetRemote({"Movements",          "Speed"})
local M1Remote          = GetRemote({"Skills",             "M1", "M1Attack"})
local SkillRemote       = GetRemote({"Skills",             "SKill"})
local AwakeningRemote   = GetRemote({"Skills",             "Awakening", "ActivateAwakening"})
local EquipTechRemote   = GetRemote({"InnateTechniques",   "EquipTechnique"})
local ClaimRemote       = GetRemote({"Tycoon", "Claim"})
local TycoonStateRemote = GetRemote({"Tycoon", "GetTycoonsState"})

-- ================================================
-- BOSS ZONES
-- ================================================
local BossZones = {}

local function CleanBossName(name)
    name = name:gsub("^[%d%.]+_", "")
    name = name:gsub("%s*%d+%s*$", "")
    name = name:gsub("^%s*", ""):gsub("%s*$", "")
    return name
end

pcall(function()
    local Map = workspace:WaitForChild("Map"):WaitForChild("Boss")
    for _, zone in ipairs(Map:GetChildren()) do
        local b = zone:FindFirstChild("Bosses")
        if b then table.insert(BossZones, b) end
    end
    Map.ChildAdded:Connect(function(zone)
        task.wait(0.5)
        local b = zone:FindFirstChild("Bosses")
        if b then
            for _, existing in ipairs(BossZones) do
                if existing == b then return end
            end
            table.insert(BossZones, b)
        end
    end)
end)

local function GetAnyBoss()
    for _, folder in ipairs(BossZones) do
        for _, boss in ipairs(folder:GetChildren()) do
            local hum = boss:FindFirstChildOfClass("Humanoid")
            local hrp = boss:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then return boss, hum, hrp end
        end
    end
    return nil, nil, nil
end

-- ================================================
-- STATE
-- ================================================
local State = {
    AutoFarm        = false,
    DumpBoss        = false,
    Flying          = false,
    Noclip          = false,
    InfJump         = false,
    SpeedHack       = false,
    AutoRebirth     = false,
    DashNoCD        = false,
    AutoAwakening   = false,
    AutoCollectYen  = false,
    AutoUpgrade     = false,
    AutoCollectDrops= false,
    GodMode         = false,
    KillAura        = false,
    KillAuraRange   = 60,
    ExtendHitbox    = false,
    HitboxSize      = 50000,
    FlySpeed        = 80,
    WalkSpeed       = 200,
    LastBossPos     = nil,
}

local BossDropFilter = { Yen=true, Energy=true, Fingers=true, Remains=true }

local YEN_PATTERNS     = {"Yen"}
local ENERGY_PATTERNS  = {"CursedEnergy","Cursed Energy","cursed_energy","CursedEnergie"}
local FINGERS_PATTERNS = {"CursedFingers","CursedFinger","Cursed Fingers","Cursed Finger"}

local function IsYen(name)
    for _, p in ipairs(YEN_PATTERNS)     do if string.find(name,p,1,true) then return true end end return false end
local function IsEnergy(name)
    for _, p in ipairs(ENERGY_PATTERNS)  do if string.find(name,p,1,true) then return true end end return false end
local function IsFingers(name)
    for _, p in ipairs(FINGERS_PATTERNS) do if string.find(name,p,1,true) then return true end end return false end
local function BossDropPassesFilter(itemName)
    if IsYen(itemName)     then return BossDropFilter.Yen end
    if IsEnergy(itemName)  then return BossDropFilter.Energy end
    if IsFingers(itemName) then return BossDropFilter.Fingers end
    return BossDropFilter.Remains
end

local godModeConns = {}
local lastDeathPos = nil

local function ApplyGodModeToChar(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid",5)
    if not hum then return end
    local hrp = char:WaitForChild("HumanoidRootPart",5)
    if not hrp then return end
    local conn = hum.Died:Connect(function()
        if not State.GodMode then return end
        lastDeathPos = hrp.CFrame
        task.wait(0.05)
        pcall(function() Player:LoadCharacter() end)
    end)
    table.insert(godModeConns, conn)
end

local function StartGodMode() State.GodMode = true; ApplyGodModeToChar(Character) end
local function StopGodMode()
    State.GodMode = false; lastDeathPos = nil
    for _, c in ipairs(godModeConns) do pcall(function() c:Disconnect() end) end
    godModeConns = {}
end

local FlyVelocity, FlyGyro
local farmThread       = nil
local CurrentFarmStatus= "Idle"

-- DASH NO COOLDOWN
local function ClearDashCD()
    if not Character then return end
    for _, fn in ipairs({"Cooldowns","Cooldown"}) do
        local f = Character:FindFirstChild(fn)
        if f then
            for _, obj in ipairs(f:GetChildren()) do
                local low = obj.Name:lower()
                if low:find("dash") or low:find("dodge") or low:find("roll") or low:find("blink") or low:find("movement") or low:find("move") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end
    for _, obj in ipairs(Character:GetDescendants()) do
        local ok, attrs = pcall(function() return obj:GetAttributes() end)
        if ok and type(attrs) == "table" then
            for k, v in pairs(attrs) do
                local low = k:lower()
                if low:find("dash") or low:find("dodge") or low:find("roll") or low:find("blink") then
                    if type(v) == "number" and v > 0 then pcall(function() obj:SetAttribute(k,0) end)
                    elseif type(v) == "boolean" and v then pcall(function() obj:SetAttribute(k,false) end) end
                end
            end
        end
        if obj:IsA("BoolValue") or obj:IsA("NumberValue") or obj:IsA("IntValue") then
            local low = obj.Name:lower()
            if low:find("dash") or low:find("dodge") or low:find("roll") or low:find("blink") then
                pcall(function() obj.Value = obj:IsA("BoolValue") and false or 0 end)
            end
        end
    end
end

local dashCDThread = nil
local function StartDashNoCD()
    State.DashNoCD = true
    if dashCDThread then return end
    dashCDThread = task.spawn(function()
        while State.DashNoCD do ClearDashCD(); task.wait(0.05) end
        dashCDThread = nil
    end)
end
local function StopDashNoCD() State.DashNoCD = false; dashCDThread = nil end

-- AUTO AWAKENING
local function GetPlayerHealth()
    local char = Player.Character
    if not char then return nil,nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil,nil end
    return hum.Health, hum.MaxHealth
end

local function FireAwakening()
    if Character then
        for _, fn in ipairs({"Cooldowns","Cooldown"}) do
            local f = Character:FindFirstChild(fn)
            if f then
                local awCD = f:FindFirstChild("AwakeningCooldown")
                if awCD then pcall(function() awCD:Destroy() end) end
            end
        end
    end
    if AwakeningRemote then pcall(function() AwakeningRemote:FireServer() end) end
end

local awakeningThread   = nil
local lastAwakeningTime = 0
local AWAKENING_COOLDOWN= 60

local function StartAutoAwakening()
    State.AutoAwakening = true
    if awakeningThread then return end
    awakeningThread = task.spawn(function()
        while State.AutoAwakening do
            local hp, maxHp = GetPlayerHealth()
            if hp and maxHp and maxHp > 0 then
                local pct = hp / maxHp
                local now = os.clock()
                if pct <= 0.20 and (now - lastAwakeningTime) >= AWAKENING_COOLDOWN then
                    lastAwakeningTime = now; FireAwakening()
                end
            end
            task.wait(0.5)
        end
        awakeningThread = nil
    end)
end
local function StopAutoAwakening() State.AutoAwakening = false; awakeningThread = nil end

-- BOSS SELECTION
local function GetSelectedBoss()
    local bossMap = workspace:FindFirstChild("Map")
    bossMap = bossMap and bossMap:FindFirstChild("Boss")
    if not bossMap then return nil,nil,nil end
    for _, zone in ipairs(bossMap:GetChildren()) do
        local bosses = zone:FindFirstChild("Bosses")
        if bosses then
            for _, boss in ipairs(bosses:GetChildren()) do
                local hum = boss:FindFirstChildOfClass("Humanoid")
                local hrp = boss:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then return boss,hum,hrp end
            end
        end
    end
    return nil,nil,nil
end

-- DUMP BOSS
local SHIBUYA_PORTAL_ENTRY  = Vector3.new(-861.687, 44.683, -480.250)
local SHIBUYA_PORTAL_EXIT   = Vector3.new(-1770.879, 62.717, -423.178)
local SHIBUYA_THRESHOLD_X   = -1200

local function IsInShibuya()
    local HRP = GetHRP()
    if not HRP then return false end
    return HRP.Position.X < SHIBUYA_THRESHOLD_X
end

local function StartDumpBoss()
    State.DumpBoss = true
    task.spawn(function()
        while State.DumpBoss do
            local boss, bossHum = GetSelectedBoss()
            if boss then
                pcall(function()
                    for _, p in ipairs(boss:GetDescendants()) do
                        if p:IsA("BasePart") then p.Anchored = true end
                        if p:IsA("Script") then p.Disabled = true end
                    end
                    if bossHum then bossHum.WalkSpeed = 0; bossHum.JumpPower = 0 end
                end)
            end
            task.wait(0.1)
        end
    end)
end

local function StopDumpBoss()
    State.DumpBoss = false
    local boss, bossHum = GetSelectedBoss()
    if boss then
        pcall(function()
            for _, p in ipairs(boss:GetDescendants()) do
                if p:IsA("BasePart") then p.Anchored = false end
                if p:IsA("Script") then p.Disabled = false end
            end
            if bossHum then bossHum.WalkSpeed = 16; bossHum.JumpPower = 50 end
        end)
    end
end

-- TYCOON
local TycoonNames = {
    "TycoonChoso","TycoonGojo","TycoonHanami","TycoonJogo","TycoonMaki",
    "TycoonMegumi","TycoonNanami","TycoonNobara","TycoonTodo","TycoonToge",
    "TycoonToji","TycoonYuji"
}
local CurrentTycoon     = nil
local TycoonParagraph   = nil

local function DetectMyTycoon()
    if TycoonStateRemote then
        local ok, result = pcall(function() return TycoonStateRemote:InvokeServer() end)
        if ok and type(result) == "table" then
            for charName, data in pairs(result) do
                if type(data) == "table" and data.claimed == true and data.ownerId == Player.UserId then
                    CurrentTycoon = "Tycoon" .. charName; return CurrentTycoon
                end
            end
        end
    end
    local folder = workspace:FindFirstChild("Map")
    folder = folder and folder:FindFirstChild("Tycoons")
    if folder then
        for _, name in ipairs(TycoonNames) do
            local t = folder:FindFirstChild(name)
            if t then
                local ov = t:FindFirstChild("Owner") or t:FindFirstChild("OwnerName")
                if ov then
                    if ov:IsA("StringValue") and ov.Value == Player.Name then CurrentTycoon = name; return name end
                    if ov:IsA("ObjectValue") and ov.Value == Player then CurrentTycoon = name; return name end
                end
                if t:GetAttribute("Owner") == Player.Name or t:GetAttribute("OwnerId") == Player.UserId then
                    CurrentTycoon = name; return name
                end
            end
        end
    end
    return nil
end

local lastDetectTime  = 0
local DETECT_COOLDOWN = 30
local function DetectMyTycoonIfNeeded()
    if CurrentTycoon then return end
    local now = os.clock()
    if now - lastDetectTime < DETECT_COOLDOWN then return end
    lastDetectTime = now; DetectMyTycoon()
end

local function HookClaimRemote()
    if not ClaimRemote then return end
    if not hookmetamethod or not getnamecallmethod then return end
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local ok, method = pcall(getnamecallmethod)
            if ok and method == "FireServer" and self == ClaimRemote then
                local args = {...}
                local charName = args[1]
                if type(charName) == "string" then
                    CurrentTycoon = "Tycoon" .. charName; lastDetectTime = os.clock()
                    task.defer(function()
                        if TycoonParagraph then
                            pcall(function() TycoonParagraph:Set({ Title="🏯 My Tycoon", Content=charName.." (auto)" }) end)
                        end
                    end)
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end

local tycoonBusy = false

-- AUTO COLLECT YEN
local function StartAutoCollectYen()
    State.AutoCollectYen = true
    task.spawn(function()
        while State.AutoCollectYen do
            if tycoonBusy then task.wait(0.5); continue end
            local HRP = GetHRP()
            if HRP then
                if not CurrentTycoon then DetectMyTycoonIfNeeded() end
                if CurrentTycoon then
                    local myTycoon = workspace:FindFirstChild("Map")
                    myTycoon = myTycoon and myTycoon:FindFirstChild("Tycoons")
                    myTycoon = myTycoon and myTycoon:FindFirstChild(CurrentTycoon)
                    if not myTycoon or not myTycoon.Parent then CurrentTycoon = nil; task.wait(2); continue end
                    local base = myTycoon:FindFirstChild("Base")
                    if base then
                        tycoonBusy = true
                        for _, folder in ipairs(base:GetChildren()) do
                            if not State.AutoCollectYen then break end
                            local col = folder:FindFirstChild("Collector")
                            if col and col:IsA("BasePart") and col.Parent and col:FindFirstChild("TouchInterest") then
                                pcall(function() firetouchinterest(HRP,col,0); task.wait(0.15); firetouchinterest(HRP,col,1) end)
                                task.wait(0.5)
                            end
                        end
                        tycoonBusy = false
                    end
                end
            end
            task.wait(2)
        end
    end)
end

-- ================================================
-- AUTO COLLECT BOSS DROPS  (works WITH Auto Farm)
-- ================================================
local DropZonePaths = {"Lac","Metro","Shibuya","WorldBoss"}

-- Helper: collect drops for a specific zone without teleporting away from boss
local function CollectZoneDropsInPlace(zoneName)
    local bossMap = workspace:FindFirstChild("Map")
    bossMap = bossMap and bossMap:FindFirstChild("Boss")
    local zone = bossMap and bossMap:FindFirstChild(zoneName)
    if not zone then return end
    local drops = zone:FindFirstChild("Drops")
    if not drops or #drops:GetChildren() == 0 then return end

    local currentHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not currentHRP then return end

    collectingDrops = true  -- pause farm teleport loop
    local savedCF = currentHRP.CFrame  -- remember position to return after collecting

    for _, item in ipairs(drops:GetChildren()) do
        if not item or not item.Parent then continue end
        if not BossDropPassesFilter(item.Name) then continue end
        currentHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not currentHRP then break end

        local part = item:IsA("BasePart") and item or item:FindFirstChildOfClass("BasePart")
        if not part or not part.Parent then continue end

        local prompt = item:FindFirstChild("Prompt")
        if not prompt then continue end

        pcall(function() prompt.MaxActivationDistance = math.huge; prompt.HoldDuration = 0 end)
        pcall(function() currentHRP.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0)) end)
        task.wait(0.1)
        if not item.Parent then continue end
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.05)
        pcall(function() firetouchinterest(currentHRP,part,0); task.wait(0.03); firetouchinterest(currentHRP,part,1) end)
        local t = 0
        while item.Parent and t < 0.3 do task.wait(0.05); t += 0.05 end
    end

    -- Return to saved position so Auto Farm isn't disrupted
    currentHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if currentHRP then pcall(function() currentHRP.CFrame = savedCF end) end
    collectingDrops = false  -- resume farm teleport loop
end

local dropCollectThread = nil
local collectingDrops = false  -- flag to pause farm teleport during drop collection

local function StartAutoCollectDrops()
    State.AutoCollectDrops = true
    if dropCollectThread then return end
    dropCollectThread = task.spawn(function()
        while State.AutoCollectDrops do
            -- Works regardless of whether Auto Farm is active
            local bossMap = workspace:FindFirstChild("Map")
            bossMap = bossMap and bossMap:FindFirstChild("Boss")
            if bossMap then
                for _, zoneName in ipairs(DropZonePaths) do
                    if not State.AutoCollectDrops then break end
                    local zone = bossMap:FindFirstChild(zoneName)
                    if not zone then continue end
                    local drops = zone:FindFirstChild("Drops")
                    if not drops or #drops:GetChildren() == 0 then continue end
                    -- Collect immediately when drops exist
                    CollectZoneDropsInPlace(zoneName)
                end
            end
            task.wait(1)
        end
        dropCollectThread = nil
    end)
end

local function StopAutoCollectDrops()
    State.AutoCollectDrops = false
    dropCollectThread = nil
end

-- AUTO UPGRADE TYCOON
local upgradeThread = nil
local function StartAutoUpgrade()
    State.AutoUpgrade = true
    upgradeThread = task.spawn(function()
        while State.AutoUpgrade do
            if tycoonBusy then task.wait(0.5); continue end
            if not CurrentTycoon then DetectMyTycoonIfNeeded() end
            local HRP = GetHRP()
            if CurrentTycoon and HRP then
                local myTycoon = workspace:FindFirstChild("Map")
                myTycoon = myTycoon and myTycoon:FindFirstChild("Tycoons")
                myTycoon = myTycoon and myTycoon:FindFirstChild(CurrentTycoon)
                if not myTycoon or not myTycoon.Parent then CurrentTycoon = nil; task.wait(2); continue end
                local purshases = myTycoon and myTycoon:FindFirstChild("Purshases")
                if purshases and purshases.Parent then
                    local pads = {}
                    for _, folder in ipairs(purshases:GetChildren()) do
                        if not folder.Parent then continue end
                        for _, btn in ipairs(folder:GetChildren()) do
                            if btn.Name:sub(1,7) == "Button_" then
                                local base = btn:FindFirstChild("base")
                                if base and base:IsA("BasePart") and base.Parent and base:FindFirstChild("TouchInterest") then
                                    table.insert(pads, base)
                                end
                            end
                        end
                    end
                    table.sort(pads, function(a,b)
                        local fa = tonumber(a.Parent.Name:match("Floor(%d+)")) or 0
                        local fb = tonumber(b.Parent.Name:match("Floor(%d+)")) or 0
                        if fa ~= fb then return fa < fb end
                        local na = tonumber(a.Parent.Name:match("_(%d+)$")) or 0
                        local nb = tonumber(b.Parent.Name:match("_(%d+)$")) or 0
                        return na < nb
                    end)
                    tycoonBusy = true
                    for _, pad in ipairs(pads) do
                        if not State.AutoUpgrade then break end
                        if not pad.Parent then continue end
                        pcall(function() firetouchinterest(HRP,pad,0); task.wait(0.15); firetouchinterest(HRP,pad,1) end)
                        task.wait(0.5)
                    end
                    tycoonBusy = false
                else
                    CurrentTycoon = nil; lastDetectTime = 0
                end
            end
            task.wait(3)
        end
        upgradeThread = nil
    end)
end
local function StopAutoUpgrade() State.AutoUpgrade = false; upgradeThread = nil end

-- SKILL SPAM
local function SpamSkills(boss, _, bossHRP)
    local backpack = Player:FindFirstChild("Backpack")
    if backpack and SkillRemote then
        for _, tool in ipairs(backpack:GetChildren()) do
            if not tool:IsA("Tool") then continue end
            local skillName = tool.Name
            local charName  = tool:GetAttribute("CharacterName") or tool:GetAttribute("Character") or tool:GetAttribute("Char")
            local skillType = tool:GetAttribute("SkillType") or tool:GetAttribute("Type") or tool:GetAttribute("ToolType")
            if charName and skillType then pcall(function() SkillRemote:FireServer(charName,skillName,skillType) end)
            elseif charName then pcall(function() SkillRemote:FireServer(charName,skillName) end)
            else pcall(function() SkillRemote:FireServer(skillName) end) end
        end
    end
    if M1Remote and bossHRP then pcall(function() M1Remote:FireServer(bossHRP) end) end
end

-- ZONE BOSS FARM
local ZoneOrder = {"Lac","Metro","Shibuya","WorldBoss"}

local function GetBossInZone(zoneName)
    local bossMap = workspace:FindFirstChild("Map")
    bossMap = bossMap and bossMap:FindFirstChild("Boss")
    local zone = bossMap and bossMap:FindFirstChild(zoneName)
    if not zone then return nil,nil,nil end
    local bosses = zone:FindFirstChild("Bosses")
    if not bosses then return nil,nil,nil end
    for _, boss in ipairs(bosses:GetChildren()) do
        local hum = boss:FindFirstChildOfClass("Humanoid")
        local hrp = boss:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and hrp then return boss,hum,hrp end
    end
    return nil,nil,nil
end

-- CollectZoneDrops used by explicit drop collection after boss death in farm loop
local function CollectZoneDrops(zoneName)
    CollectZoneDropsInPlace(zoneName)
end

-- KILL AURA
local ReportHitsRemote = GetRemote({"Skills","ReportHits"})
local AnimHitRemote    = GetRemote({"Skills","AnimationHit"})

local function GetNearbyCharacters(range)
    local char = Player.Character
    if not char then return {} end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    local results = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
            local tHum = p.Character:FindFirstChildOfClass("Humanoid")
            if tHRP and tHum and tHum.Health > 0 then
                if (tHRP.Position - hrp.Position).Magnitude <= range then table.insert(results, p.Character) end
            end
        end
    end
    local bossMap = workspace:FindFirstChild("Map")
    bossMap = bossMap and bossMap:FindFirstChild("Boss")
    if bossMap then
        for _, zone in ipairs(bossMap:GetChildren()) do
            local bosses = zone:FindFirstChild("Bosses")
            if bosses then
                for _, boss in ipairs(bosses:GetChildren()) do
                    local bHRP = boss:FindFirstChild("HumanoidRootPart")
                    local bHum = boss:FindFirstChildOfClass("Humanoid")
                    if bHRP and bHum and bHum.Health > 0 then
                        if (bHRP.Position - hrp.Position).Magnitude <= range then table.insert(results, boss) end
                    end
                end
            end
        end
    end
    local npcSpawns = workspace:FindFirstChild("Map")
    npcSpawns = npcSpawns and npcSpawns:FindFirstChild("NPCs")
    npcSpawns = npcSpawns and npcSpawns:FindFirstChild("Spawns")
    if npcSpawns then
        for _, spawn in ipairs(npcSpawns:GetChildren()) do
            local npcFolder = spawn:FindFirstChild("NPC")
            if npcFolder then
                for _, npc in ipairs(npcFolder:GetChildren()) do
                    local nHRP = npc:FindFirstChild("HumanoidRootPart")
                    local nHum = npc:FindFirstChildOfClass("Humanoid")
                    if nHRP and nHum and nHum.Health > 0 then
                        if (nHRP.Position - hrp.Position).Magnitude <= range then table.insert(results, npc) end
                    end
                end
            end
        end
    end
    return results
end

local function GetEquippedCharName()
    local backpack = Player:FindFirstChild("Backpack")
    local char = Player.Character
    for _, parent in ipairs({char, backpack}) do
        if parent then
            for _, tool in ipairs(parent:GetChildren()) do
                if tool:IsA("Tool") then
                    local n = tool:GetAttribute("CharacterName") or tool:GetAttribute("Character") or tool:GetAttribute("Char")
                    if n then return n end
                end
            end
        end
    end
    return nil
end

local function GetActiveCharName() return Player:GetAttribute("ActiveCharacter") end

local killAuraThread  = nil
local killAuraCombo   = 1
local killAuraMaxCombo= 5

local PreloadRemote = GetRemote({"Skills","PreloadAnimations"})
if PreloadRemote then
    PreloadRemote.OnClientEvent:Connect(function(animTable)
        if type(animTable) ~= "table" then return end
        local maxCombo = 0
        for k, _ in pairs(animTable) do
            if string.sub(k,1,3) == "M1_" then
                local n = tonumber(string.sub(k,4,4))
                if n and n > maxCombo then maxCombo = n end
            end
        end
        if maxCombo > 0 then killAuraMaxCombo = maxCombo end
    end)
end

local function StartKillAura()
    State.KillAura = true
    if killAuraThread then return end
    killAuraThread = task.spawn(function()
        while State.KillAura do
            pcall(function()
                if not SkillRemote then return end
                local charName = GetActiveCharName()
                if not charName then return end
                local char = Player.Character
                if not char then return end
                if char:GetAttribute("Attacking") or char:GetAttribute("Stunned") then return end
                local targets = GetNearbyCharacters(State.KillAuraRange)
                if #targets == 0 then return end
                SkillRemote:FireServer(charName, "M1_" .. killAuraCombo)
                killAuraCombo = killAuraCombo >= killAuraMaxCombo and 1 or killAuraCombo + 1
            end)
            task.wait(0.2)
        end
        killAuraThread = nil; killAuraCombo = 1
    end)
end
local function StopKillAura() State.KillAura = false; killAuraThread = nil; killAuraCombo = 1 end

-- EXTEND HITBOX
local extendHitboxConn = nil
local function StartExtendHitbox()
    State.ExtendHitbox = true
    if extendHitboxConn then return end
    local PlaySkillVFXRemote = GetRemote({"Skills","PlaySkillVFX"})
    if not PlaySkillVFXRemote or not ReportHitsRemote then return end
    extendHitboxConn = PlaySkillVFXRemote.OnClientEvent:Connect(function(attackId, marker)
        if not State.ExtendHitbox then return end
        if marker ~= "Hit" and marker ~= "Slash1" and marker ~= "Slash2" and marker ~= "Slash3" and marker ~= "Impact" then return end
        local targets = GetNearbyCharacters(State.HitboxSize)
        if #targets == 0 then return end
        local hitList = {}
        for _, char in ipairs(targets) do
            local p = Players:GetPlayerFromCharacter(char)
            table.insert(hitList, { characterName=char.Name, userId=p and p.UserId or nil })
        end
        pcall(function() ReportHitsRemote:FireServer(tostring(attackId).."_hit1", hitList) end)
    end)
end
local function StopExtendHitbox()
    State.ExtendHitbox = false
    if extendHitboxConn then extendHitboxConn:Disconnect(); extendHitboxConn = nil end
end

-- ================================================
-- AUTO FARM  (drop collection runs in parallel now)
-- ================================================
local function TeleportToBossHRP(bossHRP)
    if not bossHRP then return end
    if collectingDrops then return end  -- don't interrupt drop collection
    local hrp = GetHRP()
    if not hrp then return end
    if bossHRP.Position.X < SHIBUYA_THRESHOLD_X then
        if not IsInShibuya() then
            pcall(function() hrp.CFrame = CFrame.new(SHIBUYA_PORTAL_EXIT + Vector3.new(0,5,0)) end)
            task.wait(0.5)
            local freshHRP = GetHRP()
            if freshHRP then hrp = freshHRP end
        end
        pcall(function() hrp.CFrame = bossHRP.CFrame * CFrame.new(0,0,3) end)
    else
        pcall(function() hrp.CFrame = bossHRP.CFrame * CFrame.new(0,0,3) end)
    end
    task.wait(0.15)
end

local function StartFarm()
    if farmThread then return end
    State.AutoFarm = true
    State.ExtendHitbox = true
    State.HitboxSize   = 10000
    StartExtendHitbox()
    CurrentFarmStatus  = "Searching for boss..."
    farmThread = task.spawn(function()
        while State.AutoFarm do
            local foundZone = nil
            local boss, bossHum, bossHRP = nil,nil,nil
            for _, zoneName in ipairs(ZoneOrder) do
                local b, bh, bhrp = GetBossInZone(zoneName)
                if b then boss,bossHum,bossHRP = b,bh,bhrp; foundZone = zoneName; break end
            end
            if not boss then CurrentFarmStatus = "⏳ Waiting for a boss to spawn..."; task.wait(1); continue end

            local bossDisplayName = CleanBossName(boss.Name)
            CurrentFarmStatus = "🔀 Teleporting to: " .. bossDisplayName .. " [" .. foundZone .. "]"
            TeleportToBossHRP(bossHRP)

            if State.DumpBoss then
                pcall(function()
                    for _, p in ipairs(boss:GetDescendants()) do
                        if p:IsA("BasePart") then p.Anchored = true end
                        if p:IsA("Script") then p.Disabled = true end
                    end
                    if bossHum then bossHum.WalkSpeed = 0; bossHum.JumpPower = 0 end
                end)
            end

            CurrentFarmStatus = "🗡 Farming: " .. bossDisplayName .. " [" .. foundZone .. "]"
            local farmTick = 0
            while State.AutoFarm do
                if not boss or not boss.Parent then break end
                local currentHum = boss:FindFirstChildOfClass("Humanoid")
                if not currentHum or currentHum.Health <= 0 then break end
                State.LastBossPos = bossHRP.CFrame
                if not collectingDrops then
                    SpamSkills(boss, currentHum, bossHRP)
                    if State.DashNoCD then ClearDashCD() end
                    farmTick += 1
                    if farmTick % 30 == 0 then TeleportToBossHRP(bossHRP) end
                end
                task.wait(0.1)
            end

            if not State.AutoFarm then break end
            CurrentFarmStatus = "✅ Defeated: " .. bossDisplayName

            -- Drop collection is now handled by the parallel dropCollectThread.
            -- We still do a quick immediate pass here so drops from this kill are
            -- grabbed right away even if the periodic thread hasn't cycled yet.
            if State.AutoCollectDrops and foundZone then
                CurrentFarmStatus = "🎁 Collecting drops [" .. foundZone .. "]..."
                local bossMapC = workspace:FindFirstChild("Map")
                local dropsC   = bossMapC
                    and bossMapC:FindFirstChild("Boss")
                    and bossMapC:FindFirstChild("Boss"):FindFirstChild(foundZone)
                    and bossMapC:FindFirstChild("Boss"):FindFirstChild(foundZone):FindFirstChild("Drops")
                if dropsC then
                    local waited = 0
                    while #dropsC:GetChildren() == 0 and waited < 3 do task.wait(0.2); waited += 0.2 end
                end
                CollectZoneDropsInPlace(foundZone)
            end

            CurrentFarmStatus = "🔍 Looking for next boss..."
            task.wait(1)
        end
        CurrentFarmStatus = "Idle"
        StopExtendHitbox()
        farmThread = nil
    end)
end

local function StopFarm()
    State.AutoFarm = false; farmThread = nil; CurrentFarmStatus = "Idle"
    StopExtendHitbox(); StopAutoAwakening()
end

-- FLY
local function StartFly()
    Character = Player.Character
    if not Character then return end
    HRP      = Character:FindFirstChild("HumanoidRootPart")
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then Humanoid.PlatformStand = true end
    FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.MaxForce = Vector3.new(1e6,1e6,1e6)
    FlyVelocity.Velocity = Vector3.zero
    FlyVelocity.Parent   = HRP
    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
    FlyGyro.D = 100
    FlyGyro.Parent = HRP
    RunService:BindToRenderStep("SorcFly", Enum.RenderPriority.Input.Value, function()
        if not State.Flying or not HRP then return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        FlyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * State.FlySpeed or Vector3.zero
        FlyGyro.CFrame = cam.CFrame
    end)
end

local function StopFly()
    State.Flying = false
    RunService:UnbindFromRenderStep("SorcFly")
    if FlyVelocity then FlyVelocity:Destroy(); FlyVelocity = nil end
    if FlyGyro then FlyGyro:Destroy(); FlyGyro = nil end
    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

-- RUNTIME LOOPS
RunService.Stepped:Connect(function()
    if State.Noclip and Character then
        for _, p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    if State.SpeedHack and Humanoid and Humanoid.WalkSpeed ~= State.WalkSpeed then
        Humanoid.WalkSpeed = State.WalkSpeed
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfJump and Character then
        local hum = Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

task.spawn(function()
    while task.wait(5) do
        if State.AutoRebirth and RebirthRemote then pcall(function() RebirthRemote:FireServer() end) end
    end
end)

task.spawn(function()
    local playerGui = Player:WaitForChild("PlayerGui",10)
    if not playerGui then return end
    local function checkAndSuppress(gui)
        if not gui or not gui.Parent then return end
        task.wait(0.05)
        if not gui.Parent then return end
        for _, v in ipairs(gui:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("TextButton") then
                local t = v.Text:lower()
                if t:find("tycoon not complete") or t:find("not complete %(") then
                    pcall(function() gui:Destroy() end); return
                end
            end
        end
    end
    playerGui.ChildAdded:Connect(checkAndSuppress)
    pcall(function() game:GetService("CoreGui").ChildAdded:Connect(checkAndSuppress) end)
end)

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    HRP       = char:WaitForChild("HumanoidRootPart")
    State.Flying = false; State.Noclip = false
    if State.GodMode and lastDeathPos then
        task.spawn(function()
            for _ = 1, 8 do
                task.wait(0.1)
                local HRP = GetHRP()
                if HRP then pcall(function() HRP.CFrame = lastDeathPos end) end
            end
        end)
    elseif State.AutoFarm and State.LastBossPos then
        task.spawn(function()
            for _ = 1, 5 do
                task.wait(0.2)
                local _,_,freshHRP = GetAnyBoss()
                local HRP = GetHRP()
                if HRP then
                    HRP.CFrame = freshHRP and freshHRP.CFrame*CFrame.new(0,0,3) or State.LastBossPos*CFrame.new(0,0,3)
                end
            end
            if State.AutoFarm then StartFarm() end
        end)
    end
    if State.SpeedHack then
        task.wait(1.5)
        Humanoid.WalkSpeed = State.WalkSpeed
        if SpeedRemote then pcall(function() SpeedRemote:FireServer(State.WalkSpeed) end) end
    end
    if State.DashNoCD then task.wait(1); StartDashNoCD() end
    if State.AutoFarm  then task.wait(1); StartFarm()    end
    if State.GodMode then
        for _, c in ipairs(godModeConns) do pcall(function() c:Disconnect() end) end
        godModeConns = {}
        task.wait(0.5)
        ApplyGodModeToChar(char)
    end
end)

-- ANIM BYPASS
local function FireSkillWithAnimBypass(skillRemote, ...)
    local args = {...}
    local char = Player.Character
    if not char then pcall(function() skillRemote:FireServer(table.unpack(args)) end); return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    local savedStats = nil
    if hum then
        local stats = char:FindFirstChild("Stats")
        local baseSpeed = stats and stats:FindFirstChild("WalkspeedBase")
        savedStats = {
            walkSpeed = (baseSpeed and baseSpeed.Value) or (hum.WalkSpeed > 5 and hum.WalkSpeed or 16),
            jumpPower  = hum.JumpPower  > 0 and hum.JumpPower  or 50,
            jumpHeight = hum.JumpHeight > 0 and hum.JumpHeight or 7.2,
        }
    end
    local active = true
    local hbConn
    hbConn = RunService.Heartbeat:Connect(function()
        if not active then hbConn:Disconnect(); return end
        if not animator then return end
        pcall(function()
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Speed > 0 and track.Speed < 999 then track:AdjustSpeed(999) end
            end
        end)
        if hum then
            if hum.WalkSpeed <= 1 and savedStats then
                hum.WalkSpeed = savedStats.walkSpeed; hum.JumpPower = savedStats.jumpPower; hum.JumpHeight = savedStats.jumpHeight
            end
            if hum.PlatformStand then hum.PlatformStand = false end
        end
    end)
    pcall(function() skillRemote:FireServer(table.unpack(args)) end)
    task.delay(2, function()
        active = false
        pcall(function() hbConn:Disconnect() end)
        if animator then pcall(function() for _, track in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() track:Stop(0) end) end end) end
        if hum and savedStats then pcall(function() hum.WalkSpeed=savedStats.walkSpeed; hum.JumpPower=savedStats.jumpPower; hum.JumpHeight=savedStats.jumpHeight; hum.PlatformStand=false end) end
    end)
end

-- ZENON RAID
local RaidHPParagraph = nil
local RAID_PORTAL_BASE  = Vector3.new(-481.420, 52.603, -59.995)
local RAID_SPAWNER_POS  = Vector3.new(-102.16886901855469, -11.037002563476562, -86.8280029296875)
local RAID_FARM_POS     = Vector3.new(-102.16886901855469, -11.037002563476562 + 40, -86.8280029296875)
local raidFarmThread    = nil
local State_RaidFarm    = false

local RaidDropFilter = { Yen=true, CursedEnergy=true, CursedFinger=true, CharacterRemains=true }
local DROP_FOLDER_PATTERNS = {
    Yen={"Yen"}, CursedEnergy={"CursedEnergy","Cursed Energy","cursed_energy","CursedEnergie"},
    CursedFinger={"CursedFingers","CursedFinger","Cursed Fingers","Cursed Finger"},
    CharacterRemains={"CharacterRemains","Character Remains","CharacterRemain"},
}
local function ItemMatchesFilter(itemName)
    for filterKey, enabled in pairs(RaidDropFilter) do
        if not enabled then continue end
        local patterns = DROP_FOLDER_PATTERNS[filterKey]
        if patterns then for _, pat in ipairs(patterns) do if string.find(itemName,pat,1,true) then return true end end end
    end
    return false
end

local function CollectRaidDrops()
    local dropsFolder = workspace:FindFirstChild("Map")
    dropsFolder = dropsFolder and dropsFolder:FindFirstChild("Boss")
    dropsFolder = dropsFolder and dropsFolder:FindFirstChild("Main")
    dropsFolder = dropsFolder and dropsFolder:FindFirstChild("Drops")
    if not dropsFolder or #dropsFolder:GetChildren() == 0 then return end
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local savedPos = hrp.CFrame
    for _, item in ipairs(dropsFolder:GetChildren()) do
        if not item or not item.Parent then continue end
        if not ItemMatchesFilter(item.Name) then continue end
        hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then break end
        local part = item:IsA("BasePart") and item or item:FindFirstChildOfClass("BasePart")
        if not part or not part.Parent then continue end
        local prompt = item:FindFirstChild("Prompt")
        if not prompt then continue end
        pcall(function() prompt.MaxActivationDistance = math.huge; prompt.HoldDuration = 0 end)
        pcall(function() hrp.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0)) end)
        task.wait(0.1)
        if not item.Parent then continue end
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.05)
        pcall(function() firetouchinterest(hrp,part,0); task.wait(0.03); firetouchinterest(hrp,part,1) end)
        local t = 0
        while item.Parent and t < 0.3 do task.wait(0.05); t += 0.05 end
    end
    hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then pcall(function() hrp.CFrame = savedPos end) end
end

local function GetRaidBossAlive()
    local bossMap = workspace:FindFirstChild("Map")
    bossMap = bossMap and bossMap:FindFirstChild("Boss") and bossMap:FindFirstChild("Boss"):FindFirstChild("Main")
    local bosses = bossMap and bossMap:FindFirstChild("Bosses")
    if not bosses then return false end
    for _, boss in ipairs(bosses:GetChildren()) do
        local bHum = boss:FindFirstChildOfClass("Humanoid")
        if bHum and bHum.Health > 0 then return true end
    end
    return false
end

local function StartRaidAutoFarm()
    if raidFarmThread then return end
    State_RaidFarm = true
    State.DumpBoss = true; State.ExtendHitbox = true; State.HitboxSize = 50000
    StartExtendHitbox()
    raidFarmThread = task.spawn(function()
        local bodyPos = nil
        local function AttachBodyPos()
            if bodyPos then pcall(function() bodyPos:Destroy() end) end
            local currentHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not currentHRP then return end
            bodyPos = Instance.new("BodyPosition")
            bodyPos.MaxForce = Vector3.new(1e6,1e6,1e6); bodyPos.D = 500; bodyPos.P = 10000
            bodyPos.Position = RAID_FARM_POS; bodyPos.Parent = currentHRP
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
        local function DetachBodyPos()
            if bodyPos then pcall(function() bodyPos:Destroy() end); bodyPos = nil end
        end
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.CFrame = CFrame.new(RAID_FARM_POS) end) end
        task.wait(0.2); AttachBodyPos()
        local wasAlive = false
        while State_RaidFarm do
            pcall(function()
                local bossAlive = GetRaidBossAlive()
                local currentHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if currentHRP and (not bodyPos or not bodyPos.Parent) then
                    pcall(function() currentHRP.CFrame = CFrame.new(RAID_FARM_POS) end); task.wait(0.1); AttachBodyPos()
                end
                if bossAlive then
                    wasAlive = true
                    pcall(function()
                        local bossMain = workspace:FindFirstChild("Map")
                        bossMain = bossMain and bossMain:FindFirstChild("Boss") and bossMain:FindFirstChild("Boss"):FindFirstChild("Main")
                        local bosses = bossMain and bossMain:FindFirstChild("Bosses")
                        if bosses then
                            for _, boss in ipairs(bosses:GetChildren()) do
                                local bHum = boss:FindFirstChildOfClass("Humanoid")
                                if bHum and bHum.Health > 0 then
                                    local bHRP = boss:FindFirstChild("HumanoidRootPart")
                                    if bHRP then bHRP.CFrame = CFrame.new(RAID_SPAWNER_POS) end
                                    for _, p in ipairs(boss:GetDescendants()) do
                                        if p:IsA("BasePart") then p.Anchored = true end
                                        if p:IsA("Script") then p.Disabled = true end
                                    end
                                    bHum.WalkSpeed = 0; bHum.JumpPower = 0
                                    if CleanBossName(boss.Name):lower():find("maki") then
                                        _G._LastRaidBossWasMaki = true
                                    end
                                end
                            end
                        end
                    end)
                    local char = Player.Character
                    if char and not _G._RaidSkillPause then
                        if not char:GetAttribute("Attacking") and not char:GetAttribute("Stunned") then
                            local backpack = Player:FindFirstChild("Backpack")
                            if backpack and SkillRemote then
                                for _, tool in ipairs(backpack:GetChildren()) do
                                    if not tool:IsA("Tool") then continue end
                                    local charName  = tool:GetAttribute("CharacterName") or tool:GetAttribute("Character") or tool:GetAttribute("Char")
                                    local skillName = tool.Name
                                    local skillType = tool:GetAttribute("SkillType") or tool:GetAttribute("Type") or tool:GetAttribute("ToolType")
                                    if charName and skillType then pcall(function() SkillRemote:FireServer(charName,skillName,skillType) end)
                                    elseif charName then pcall(function() SkillRemote:FireServer(charName,skillName) end) end
                                end
                            end
                            if SkillRemote then
                                local activeChar = Player:GetAttribute("ActiveCharacter")
                                if activeChar then SkillRemote:FireServer(activeChar,"M1_"..killAuraCombo); killAuraCombo=(killAuraCombo%killAuraMaxCombo)+1 end
                                pcall(function() SkillRemote:FireServer("Gojo","Red") end)
                                pcall(function() SkillRemote:FireServer("Gojo","Lapse Blue") end)
                            end
                        end
                    end
                elseif wasAlive then
                    wasAlive = false; _G._RaidSkillPause = true
                    local makiWasLastBoss = _G._LastRaidBossWasMaki
                    _G._LastRaidBossWasMaki = false
                    DetachBodyPos(); task.wait(0.1)
                    local dropsFolder2 = workspace:FindFirstChild("Map")
                    dropsFolder2 = dropsFolder2 and dropsFolder2:FindFirstChild("Boss") and dropsFolder2:FindFirstChild("Boss"):FindFirstChild("Main") and dropsFolder2:FindFirstChild("Boss"):FindFirstChild("Main"):FindFirstChild("Drops")
                    if dropsFolder2 then
                        local waited = 0
                        while #dropsFolder2:GetChildren() == 0 and waited < 3 do task.wait(0.2); waited += 0.2 end
                    end
                    CollectRaidDrops()
                    if makiWasLastBoss then
                        Rayfield:Notify({ Title="✅ Raid Complete!", Content="Maki defeated. Raid Auto Farm disabled.", Duration=5 })
                        State_RaidFarm = false; return
                    end
                    local freshHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if freshHRP then pcall(function() freshHRP.CFrame = CFrame.new(RAID_FARM_POS) end) end
                    task.wait(0.2); AttachBodyPos(); _G._RaidSkillPause = false
                end
            end)
            task.wait(0.1)
        end
        DetachBodyPos(); raidFarmThread = nil
    end)
end

local function StopRaidAutoFarm()
    State_RaidFarm = false; raidFarmThread = nil; _G._RaidSkillPause = false
    State.DumpBoss = false; StopExtendHitbox()
end

-- ================================================
-- RAYFIELD UI
-- ================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
print("[SorcererScript] Rayfield loaded")

local Window = Rayfield:CreateWindow({
    Name            = "Sorcerer Tycoon Script",
    Icon            = 0,
    LoadingTitle    = "Made by Ikki",
    LoadingSubtitle = "v22",
    Theme           = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = { Enabled=true, FolderName="SorcererScripts", FileName="Config" },
    KeySystem = false,
})

-- LOGO
local IKKI_ASSET_ID = 79541805588283
local logoGui = Instance.new("ScreenGui")
logoGui.Name="IkkiLogoGui"; logoGui.ResetOnSpawn=false; logoGui.DisplayOrder=999
logoGui.IgnoreGuiInset=true; logoGui.Parent=Player.PlayerGui
local logo = Instance.new("ImageLabel")
logo.Size=UDim2.new(0,42,0,42); logo.Position=UDim2.new(0,14,0,14)
logo.BackgroundTransparency=1; logo.Image="rbxassetid://"..tostring(IKKI_ASSET_ID)
logo.ScaleType=Enum.ScaleType.Fit; logo.ZIndex=999; logo.Parent=logoGui
Instance.new("UICorner", logo).CornerRadius=UDim.new(1,0)

-- (key type badge removed)

-- ================================================
-- TAB: MAIN
-- ================================================
local FarmTab = Window:CreateTab("⚔ Main", 4483362458)

local MainStatusParagraph = FarmTab:CreateParagraph({ Title="🥷 Player Status", Content="Loading..." })
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            local char = Player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local barStr = "N/A"
            if hum then
                local pct    = math.floor((hum.Health/hum.MaxHealth)*100)
                local filled = math.floor(pct/5)
                barStr = string.format("[%s] %d%%  (%d/%d)", string.rep("█",filled)..string.rep("░",20-filled), pct, math.floor(hum.Health), math.floor(hum.MaxHealth))
            end
            local activeChar = Player:GetAttribute("ActiveCharacter")
            if not activeChar or activeChar == "" then activeChar = GetEquippedCharName() or "None" end
            MainStatusParagraph:Set({ Title="🥷 "..activeChar, Content="❤️ "..barStr })
        end)
    end
end)

local FarmStatusParagraph = FarmTab:CreateParagraph({ Title="⚔️ Farm Status", Content="Idle" })
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function() FarmStatusParagraph:Set({ Title="⚔️ Farm Status", Content=CurrentFarmStatus }) end)
    end
end)

FarmTab:CreateToggle({ Name="Auto Farm Boss", CurrentValue=false, Flag="AutoFarm",
    Callback=function(v)
        if v then if farmThread then State.AutoFarm=false; task.wait(0.2); farmThread=nil end; StartFarm()
        else StopFarm() end
    end })
FarmTab:CreateToggle({ Name="God Mode (Instant Respawn)", CurrentValue=false, Flag="GodMode",
    Callback=function(v) if v then StartGodMode() else StopGodMode() end end })
FarmTab:CreateToggle({ Name="Dump Boss", CurrentValue=false, Flag="DumpBoss",
    Callback=function(v) State.DumpBoss=v; if v then StartDumpBoss() else StopDumpBoss() end end })
FarmTab:CreateToggle({ Name="Auto Collect Yen", CurrentValue=false, Flag="AutoCollectYen",
    Callback=function(v) if v then StartAutoCollectYen() else State.AutoCollectYen=false end end })
FarmTab:CreateToggle({ Name="Auto Collect Boss Drops", CurrentValue=false, Flag="AutoCollectDrops",
    Callback=function(v)
        if v then StartAutoCollectDrops()
        else StopAutoCollectDrops() end
    end })
FarmTab:CreateDropdown({
    Name="Drop Filter", Options={"Yen","Cursed Energy","Cursed Fingers","Boss Remain"},
    CurrentOption={"Yen","Cursed Energy","Cursed Fingers","Boss Remain"}, MultipleOptions=true, Flag="BossDropFilterDropdown",
    Callback=function(selected)
        BossDropFilter.Yen=false; BossDropFilter.Energy=false; BossDropFilter.Fingers=false; BossDropFilter.Remains=false
        for _, v in ipairs(selected) do
            if v=="Yen"            then BossDropFilter.Yen=true end
            if v=="Cursed Energy"  then BossDropFilter.Energy=true end
            if v=="Cursed Fingers" then BossDropFilter.Fingers=true end
            if v=="Boss Remain"    then BossDropFilter.Remains=true end
        end
    end })
FarmTab:CreateToggle({ Name="Auto Upgrade Tycoon", CurrentValue=false, Flag="AutoUpgrade",
    Callback=function(v) if v then if not CurrentTycoon then DetectMyTycoonIfNeeded() end; StartAutoUpgrade() else StopAutoUpgrade() end end })
FarmTab:CreateToggle({ Name="Auto Rebirth", CurrentValue=false,
    Callback=function(v) State.AutoRebirth=v end })
FarmTab:CreateSection("⚔️ Combat")
FarmTab:CreateToggle({ Name="Kill Aura", CurrentValue=false, Flag="KillAura",
    Callback=function(v) if v then StartKillAura() else StopKillAura() end end })
FarmTab:CreateSlider({ Name="Kill Aura Range", Range={5,50000}, Increment=10, Suffix="studs", CurrentValue=60, Flag="KillAuraRange",
    Callback=function(v) State.KillAuraRange=v end })
FarmTab:CreateToggle({ Name="Extend Hitbox", CurrentValue=false, Flag="ExtendHitbox",
    Callback=function(v) if v then StartExtendHitbox() else StopExtendHitbox() end end })
FarmTab:CreateSlider({ Name="Hitbox Size", Range={10,50000}, Increment=10, Suffix="studs", CurrentValue=50000, Flag="HitboxSize",
    Callback=function(v) State.HitboxSize=v end })

-- ================================================
-- TAB: SKILLS
-- ================================================
local SkillTab = Window:CreateTab("⚡ Skills", 4483362458)
SkillTab:CreateParagraph({ Title="Domain Expansion", Content="Character Domain Expansion and Skill. You need to unlock all first." })
local domainExpansions = {
    {"Jogo","Coffin of the Iron Mountain"}, {"Gojo","Unlimited Void"}, {"Nanami","Overtime: Ratio Collapse"},
    {"Toji","Heavenly Restriction: Complete"}, {"Maki","Heavenly Restriction: Awakened"}, {"Megumi","Chimera Shadow Garden"},
    {"Yuji","Memory of Soul"}, {"Hanami","Garden of Earthly Delights"}, {"Choso","Flowing Red Scale: Crimson Binding"},
    {"Nobara","Resonance: Total Collapse"}, {"Toge","Cursed Speech: Obliterate"}, {"Todo","Boogie Woogie: Phantom Assault"},
}
for _, de in ipairs(domainExpansions) do
    local char, skill = de[1], de[2]
    SkillTab:CreateButton({ Name=char.." Domain Expansion", Callback=function()
        if SkillRemote then pcall(function() SkillRemote:FireServer(char,skill) end) end
        Rayfield:Notify({ Title=char, Content=skill, Duration=2 })
    end })
end
SkillTab:CreateParagraph({ Title="Innate Techniques", Content="Character Innate Techniques. You need to unlock all first." })
SkillTab:CreateButton({ Name="Cursed Barrier", Callback=function()
    if not EquipTechRemote or not SkillRemote then Rayfield:Notify({ Title="❌ Error", Content="Remote not found.", Duration=3 }); return end
    task.spawn(function()
        pcall(function() EquipTechRemote:FireServer("Reverse Cursed Technique",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Minor Reverse Flow",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Simple Domain",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Cursed Barrier",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Cursed Barrier",false) end); task.wait(0.01)
        pcall(function() SkillRemote:FireServer("Cursed Barrier","Cursed Barrier","InnateTechnique") end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Cursed Barrier",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Reverse Cursed Technique",false) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Simple Domain",false) end)
        Rayfield:Notify({ Title="Cursed Barrier", Content="Executed.", Duration=2 })
    end)
end })
SkillTab:CreateButton({ Name="Minor Reverse Flow", Callback=function()
    if not EquipTechRemote or not SkillRemote then Rayfield:Notify({ Title="❌ Error", Content="Remote not found.", Duration=3 }); return end
    task.spawn(function()
        pcall(function() EquipTechRemote:FireServer("Reverse Cursed Technique",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Minor Reverse Flow",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Simple Domain",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Cursed Barrier",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Minor Reverse Flow",false) end); task.wait(0.01)
        pcall(function() SkillRemote:FireServer("Minor Reverse Flow","Minor Reverse Flow","InnateTechnique") end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Minor Reverse Flow",true) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Reverse Cursed Technique",false) end); task.wait(0.01)
        pcall(function() EquipTechRemote:FireServer("Simple Domain",false) end)
        Rayfield:Notify({ Title="Minor Reverse Flow", Content="Executed.", Duration=2 })
    end)
end })
SkillTab:CreateButton({ Name="Gojo Mugen", Callback=function()
    if SkillRemote then pcall(function() SkillRemote:FireServer("Gojo","Infinity") end) end
    Rayfield:Notify({ Title="Gojo", Content="Infinity", Duration=2 })
end })
local animBypassSkills = {{"Gojo","Hollow Purple 200%"},{"Gojo","Red"},{"Gojo","Lapse Blue"},{"Jogo","Volcanic Armageddon"}}
for _, s in ipairs(animBypassSkills) do
    local char, skill = s[1], s[2]
    SkillTab:CreateButton({ Name=skill, Callback=function()
        if SkillRemote then FireSkillWithAnimBypass(SkillRemote,char,skill) end
        Rayfield:Notify({ Title=char, Content=skill, Duration=2 })
    end })
end

-- ================================================
-- TAB: MOVEMENT
-- ================================================
local MoveTab = Window:CreateTab("🏃 Movement", 4483362458)
MoveTab:CreateToggle({ Name="Fly", CurrentValue=false, Flag="Fly", Callback=function(v) State.Flying=v; if v then StartFly() else StopFly() end end })
MoveTab:CreateSlider({ Name="Fly Speed", Range={10,300}, Increment=5, Suffix="studs/s", CurrentValue=80, Flag="FlySpeed", Callback=function(v) State.FlySpeed=v end })
MoveTab:CreateToggle({ Name="Speed Hack", CurrentValue=false, Flag="SpeedHack",
    Callback=function(v)
        State.SpeedHack=v
        if v then if Humanoid then Humanoid.WalkSpeed=State.WalkSpeed end; if SpeedRemote then pcall(function() SpeedRemote:FireServer(State.WalkSpeed) end) end
        else if Humanoid then Humanoid.WalkSpeed=16 end; if SpeedRemote then pcall(function() SpeedRemote:FireServer(16) end) end end
    end })
MoveTab:CreateSlider({ Name="Walk Speed", Range={16,500}, Increment=10, Suffix="studs/s", CurrentValue=200, Flag="WalkSpeed",
    Callback=function(v) State.WalkSpeed=v; if State.SpeedHack and Humanoid then Humanoid.WalkSpeed=v; if SpeedRemote then pcall(function() SpeedRemote:FireServer(v) end) end end end })
MoveTab:CreateToggle({ Name="Noclip", CurrentValue=false, Flag="Noclip",
    Callback=function(v) State.Noclip=v; if not v and Character then for _, p in ipairs(Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end end })
MoveTab:CreateToggle({ Name="Infinite Jump", CurrentValue=false, Flag="InfJump", Callback=function(v) State.InfJump=v end })
MoveTab:CreateToggle({ Name="Dash No Cooldown", CurrentValue=false, Flag="DashNoCD", Callback=function(v) if v then StartDashNoCD() else StopDashNoCD() end end })

-- ================================================
-- TAB: TELEPORT
-- ================================================
local TpTab = Window:CreateTab("🔀 Teleport", 4483362458)
local tpSelected = ""
local function GetOtherPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= Player then table.insert(list, p.Name) end end
    if #list == 0 then list = {"(no players)"} end
    return list
end
TpTab:CreateSection("👥 Players Teleport")
local TpDropdown = TpTab:CreateDropdown({ Name="Select Player", Options=GetOtherPlayers(), CurrentOption={"(no players)"}, Flag="TpDropdown",
    Callback=function(selected) tpSelected=selected[1] or "" end })
TpTab:CreateButton({ Name="🔄 Update Player List", Callback=function()
    local list = GetOtherPlayers()
    TpDropdown:Set(list[1] or "(no players)"); TpDropdown:Refresh(list, false); tpSelected=list[1] or ""
    Rayfield:Notify({ Title="✅ Updated", Content=(#list==1 and list[1]=="(no players)") and "No players found." or (#list.." players found."), Duration=2 })
end })
TpTab:CreateButton({ Name="Teleport to Player", Callback=function()
    if tpSelected=="" or tpSelected=="(no players)" then Rayfield:Notify({ Title="⚠️ No player selected", Content="Select a player first.", Duration=2 }); return end
    local target = Players:FindFirstChild(tpSelected)
    if target and target.Character then
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local HRP  = GetHRP()
        if tHRP and HRP then HRP.CFrame=tHRP.CFrame*CFrame.new(0,0,3); Rayfield:Notify({ Title="✅ Teleported", Content="→ "..tpSelected, Duration=2 }); return end
    end
    Rayfield:Notify({ Title="❌ "..tpSelected, Content="Character not found.", Duration=2 })
end })
task.spawn(function() task.wait(2); local list=GetOtherPlayers(); TpDropdown:Refresh(list,false); tpSelected=list[1] or "" end)
TpTab:CreateSection("🏯 My Tycoon")
TpTab:CreateButton({ Name="Teleport to Your Tycoon", Callback=function()
    local HRP=GetHRP(); if not HRP then Rayfield:Notify({ Title="❌ Error", Content="Character not found.", Duration=3 }); return end
    if not CurrentTycoon then DetectMyTycoon() end
    if not CurrentTycoon then Rayfield:Notify({ Title="❌ Tycoon not found", Content="Claim a Tycoon first.", Duration=4 }); return end
    local myTycoon=workspace:FindFirstChild("Map"); myTycoon=myTycoon and myTycoon:FindFirstChild("Tycoons"); myTycoon=myTycoon and myTycoon:FindFirstChild(CurrentTycoon)
    if not myTycoon or not myTycoon.Parent then CurrentTycoon=nil; Rayfield:Notify({ Title="❌ Tycoon not in workspace", Content="Could not locate.", Duration=3 }); return end
    local targetPart=myTycoon:FindFirstChildOfClass("BasePart") or myTycoon:FindFirstChildWhichIsA("BasePart",true)
    if targetPart then HRP.CFrame=CFrame.new(targetPart.Position+Vector3.new(0,6,0)); Rayfield:Notify({ Title="✅ Teleported", Content="Tycoon "..CurrentTycoon:gsub("^Tycoon",""), Duration=2 })
    else Rayfield:Notify({ Title="❌ Could not teleport", Content="No valid position.", Duration=3 }) end
end })
TpTab:CreateSection("🏪 Shops Teleport")
local ShopTeleports = {
    {"Innate Techniques",Vector3.new(-277.799,16.251,238.113)}, {"Limit Breaker",Vector3.new(-213.388,8.620,256.251)},
    {"Swords",Vector3.new(-174.075,16.302,195.120)}, {"Titles",Vector3.new(-211.653,15.462,97.970)},
    {"Clans",Vector3.new(-273.691,4.698,131.744)}, {"Merchant",Vector3.new(-396.008,9.684,140.902)},
}
for _, shop in ipairs(ShopTeleports) do
    local name, pos = shop[1], shop[2]
    TpTab:CreateButton({ Name=name, Callback=function()
        local HRP=GetHRP(); if not HRP then return end
        HRP.CFrame=CFrame.new(pos+Vector3.new(0,5,0)); Rayfield:Notify({ Title="✅ "..name, Content="Teleported.", Duration=2 })
    end })
end
TpTab:CreateSection("👾 Boss Spawn NPC")
local BossSpawnTeleports = {{"Lake",Vector3.new(426.629,19.016,-435.469)},{"Shibuya",Vector3.new(-1816.107,44.559,-381.150)}}
for _, spawn in ipairs(BossSpawnTeleports) do
    local name, pos = spawn[1], spawn[2]
    TpTab:CreateButton({ Name=name.." Boss Spawn", Callback=function()
        local HRP=GetHRP(); if not HRP then return end
        HRP.CFrame=CFrame.new(pos+Vector3.new(0,5,0)); Rayfield:Notify({ Title="✅ "..name, Content="Teleported to Boss Spawn NPC.", Duration=2 })
    end })
end
TpTab:CreateSection("🌀 Shibuya Portal")
TpTab:CreateButton({ Name="Shibuya Portal Entry", Callback=function()
    local HRP=GetHRP(); if not HRP then return end
    HRP.CFrame=CFrame.new(SHIBUYA_PORTAL_ENTRY+Vector3.new(0,5,0)); Rayfield:Notify({ Title="✅ Shibuya", Content="Teleported to Shibuya Portal Entry.", Duration=2 })
end })
TpTab:CreateButton({ Name="Shibuya Portal Outside", Callback=function()
    local HRP=GetHRP(); if not HRP then return end
    HRP.CFrame=CFrame.new(SHIBUYA_PORTAL_EXIT+Vector3.new(0,5,0)); Rayfield:Notify({ Title="✅ Shibuya", Content="Teleported outside Shibuya.", Duration=2 })
end })
TpTab:CreateSection("👹 Boss Status & Teleport")
local ZoneStatusNames = {
    {key="Lac",label="🌊 Lac"},{key="Metro",label="🚇 Metro"},{key="Shibuya",label="🏙️ Shibuya"},
    {key="WorldBoss",label="🌍 World Boss"},{key="Main",label="⚔️ Raid (Main)"},
}
local ZoneStatusParagraphs = {}
for _, zone in ipairs(ZoneStatusNames) do
    local zoneKey, zoneLabel = zone.key, zone.label
    ZoneStatusParagraphs[zoneKey] = TpTab:CreateParagraph({ Title=zoneLabel, Content="Checking..." })
    TpTab:CreateButton({ Name="Teleport to "..zoneLabel.." Boss", Callback=function()
        local HRP=GetHRP(); if not HRP then Rayfield:Notify({ Title="❌ Error", Content="Character not found.", Duration=3 }); return end
        local bossMap=workspace:FindFirstChild("Map"); bossMap=bossMap and bossMap:FindFirstChild("Boss")
        local zoneFolder=bossMap and bossMap:FindFirstChild(zoneKey)
        local bosses=zoneFolder and zoneFolder:FindFirstChild("Bosses")
        if bosses then
            for _, boss in ipairs(bosses:GetChildren()) do
                local bHum=boss:FindFirstChildOfClass("Humanoid"); local bHRP=boss:FindFirstChild("HumanoidRootPart")
                if bHum and bHum.Health>0 and bHRP then
                    if bHRP.Position.X<SHIBUYA_THRESHOLD_X and not IsInShibuya() then
                        HRP.CFrame=CFrame.new(SHIBUYA_PORTAL_EXIT+Vector3.new(0,5,0)); task.wait(0.3)
                        local freshHRP=GetHRP(); if freshHRP then freshHRP.CFrame=bHRP.CFrame*CFrame.new(0,0,3) end
                    else HRP.CFrame=bHRP.CFrame*CFrame.new(0,0,3) end
                    Rayfield:Notify({ Title="✅ Teleported", Content=CleanBossName(boss.Name).." ("..zoneLabel..")", Duration=2 }); return
                end
            end
        end
        Rayfield:Notify({ Title="❌ No boss alive", Content="No alive boss found in "..zoneLabel, Duration=3 })
    end })
end
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local bossMap=workspace:FindFirstChild("Map"); bossMap=bossMap and bossMap:FindFirstChild("Boss")
            if not bossMap then return end
            for _, zone in ipairs(ZoneStatusNames) do
                local para=ZoneStatusParagraphs[zone.key]; if not para then continue end
                local zoneFolder=bossMap:FindFirstChild(zone.key)
                if not zoneFolder then para:Set({ Title=zone.label, Content="Zone not found" }); continue end
                local bosses=zoneFolder:FindFirstChild("Bosses")
                if not bosses then para:Set({ Title=zone.label, Content="No bosses folder" }); continue end
                local aliveBosses={}
                for _, boss in ipairs(bosses:GetChildren()) do
                    local hum=boss:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health>0 then
                        local hp=math.floor(hum.Health); local mx=math.floor(hum.MaxHealth)
                        table.insert(aliveBosses, string.format("%s  HP: %d/%d (%.0f%%)", CleanBossName(boss.Name), hp, mx, (hp/mx)*100))
                    end
                end
                if #aliveBosses>0 then para:Set({ Title="● "..zone.label.." — "..#aliveBosses.." boss", Content=table.concat(aliveBosses,"\n") })
                else para:Set({ Title="○ "..zone.label, Content="No boss alive" }) end
            end
        end)
    end
end)

-- ================================================
-- TAB: ZENON RAID
-- ================================================
local RaidTab = Window:CreateTab("⚔️ Raid", 4483362458)
RaidTab:CreateSection("🌀 Teleport")
RaidTab:CreateButton({ Name="Teleport to Zenon Raid", Callback=function()
    local hrp=Player.Character and Player.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    pcall(function() hrp.CFrame=CFrame.new(RAID_PORTAL_BASE+Vector3.new(0,5,0)) end)
    Rayfield:Notify({ Title="⚔️ Zenon Raid", Content="Teleported to Raid.", Duration=2 })
end })
RaidTab:CreateSection("❤️ HP")
RaidHPParagraph = RaidTab:CreateParagraph({ Title="❤️ Health Bar", Content="Loading..." })
task.defer(function()
    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                local char=Player.Character; if not char then return end
                local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
                local pct=math.floor((hum.Health/hum.MaxHealth)*100)
                local filled=math.floor(pct/5)
                local bar=string.rep("█",filled)..string.rep("░",20-filled)
                RaidHPParagraph:Set({ Title="❤️ Health Bar", Content=string.format("[%s] %d%%  %d / %d", bar, pct, math.floor(hum.Health), math.floor(hum.MaxHealth)) })
            end)
        end
    end)
end)
RaidTab:CreateSection("🤖 Auto Farm Raid")
RaidTab:CreateToggle({ Name="Auto Farm Raid", CurrentValue=false, Flag="RaidAutoFarm",
    Callback=function(v)
        if v then StartRaidAutoFarm(); Rayfield:Notify({ Title="⚔️ Raid Farm ON", Content="Farming bosses.", Duration=3 })
        else StopRaidAutoFarm(); Rayfield:Notify({ Title="⛔ Raid Farm OFF", Content="Farm paused.", Duration=2 }) end
    end })

-- ================================================
-- TAB: INFO
-- ================================================
local InfoTab = Window:CreateTab("ℹ Info", 4483362458)
TycoonParagraph = InfoTab:CreateParagraph({ Title="🏯 My Tycoon", Content="Detecting..." })
task.spawn(function()
    task.wait(3); DetectMyTycoon()
    local display=CurrentTycoon and CurrentTycoon:gsub("^Tycoon","") or "Not found"
    TycoonParagraph:Set({ Title="🏯 My Tycoon", Content=display }); HookClaimRemote()
end)
InfoTab:CreateButton({ Name="🔄 Re-detect Tycoon", Callback=function()
    CurrentTycoon=nil; DetectMyTycoon()
    local display=CurrentTycoon and CurrentTycoon:gsub("^Tycoon","") or "Not found"
    TycoonParagraph:Set({ Title="🏯 My Tycoon", Content=display })
    Rayfield:Notify({ Title="🏯 Tycoon", Content=display, Duration=3 })
end })
InfoTab:CreateButton({ Name="🏠 Claim Detected Tycoon", Callback=function()
    if not CurrentTycoon then DetectMyTycoonIfNeeded() end
    if not CurrentTycoon then Rayfield:Notify({ Title="❌ Tycoon Not Detected", Content="Use Re-detect", Duration=3 }); return end
    local charName=CurrentTycoon:gsub("^Tycoon","")
    if ClaimRemote then
        local ok, err=pcall(function() ClaimRemote:FireServer(charName) end)
        if ok then Rayfield:Notify({ Title="✅ Done", Content=charName, Duration=3 })
        else Rayfield:Notify({ Title="❌ Error", Content=tostring(err), Duration=4 }) end
    else Rayfield:Notify({ Title="❌ Not found", Content="Tycoon.Claim", Duration=3 }) end
end })
local YenParagraph = InfoTab:CreateParagraph({ Title="💰 Currency", Content="Loading..." })
task.spawn(function()
    local ls=Player:WaitForChild("leaderstats",10)
    if ls then
        local yen=ls:FindFirstChild("Yen"); local ce=ls:FindFirstChild("Cursed Energy"); local cf=ls:FindFirstChild("Cursed Fingers")
        local function upd()
            YenParagraph:Set({ Title="💰 Currency", Content=string.format("Yen: %s\nCursed Energy: %s\nCursed Fingers: %s",
                yen and tostring(yen.Value) or "N/A", ce and tostring(ce.Value) or "N/A", cf and tostring(cf.Value) or "N/A") })
        end
        upd()
        if yen then yen:GetPropertyChangedSignal("Value"):Connect(upd) end
        if ce  then ce:GetPropertyChangedSignal("Value"):Connect(upd)  end
        if cf  then cf:GetPropertyChangedSignal("Value"):Connect(upd)  end
    end
end)
InfoTab:CreateButton({ Name="Rejoin Server", Callback=function() game:GetService("TeleportService"):Teleport(game.PlaceId, Player) end })
InfoTab:CreateButton({ Name="Reset Character", Callback=function() if Humanoid then Humanoid.Health=0 end end })
local antiAfkConn=nil
InfoTab:CreateToggle({ Name="Anti AFK", CurrentValue=false, Flag="AntiAfk",
    Callback=function(v)
        if v then
            antiAfkConn=RunService.Heartbeat:Connect(function()
                local vim=game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true,Enum.KeyCode.S,false,game); vim:SendKeyEvent(false,Enum.KeyCode.S,false,game)
            end)
        else if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn=nil end end
    end })
InfoTab:CreateToggle({ Name="Bypass Name", CurrentValue=false, Flag="BypassName",
    Callback=function(v)
        task.spawn(function()
            while v do
                pcall(function()
                    local chars=workspace:FindFirstChild("Characters"); local charFolder=chars and chars:FindFirstChild(Player.Name)
                    local head=charFolder and charFolder:FindFirstChild("Head"); if not head then return end
                    local healthGui=head:FindFirstChild("HealthGui") or head:FindFirstChild("HealthGUI")
                    local nameLabel=healthGui and healthGui:FindFirstChild("CharacterName")
                    if nameLabel then
                        local clanDisplay=charFolder and charFolder:GetAttribute("EquippedClanDisplayName")
                        nameLabel.Text=clanDisplay and ("Not Found - "..clanDisplay) or "Not Found"
                    end
                end)
                task.wait(0.5)
            end
            pcall(function()
                local chars=workspace:FindFirstChild("Characters"); local charFolder=chars and chars:FindFirstChild(Player.Name)
                local head=charFolder and charFolder:FindFirstChild("Head"); if not head then return end
                local healthGui=head:FindFirstChild("HealthGui") or head:FindFirstChild("HealthGUI")
                local nameLabel=healthGui and healthGui:FindFirstChild("CharacterName")
                if nameLabel then
                    local clanDisplay=charFolder and charFolder:GetAttribute("EquippedClanDisplayName")
                    nameLabel.Text=clanDisplay and (Player.Name.." - "..clanDisplay) or Player.Name
                end
            end)
        end)
    end })

-- ================================================
Rayfield:LoadConfiguration()
print("[Sorcerer Scripts v22] Loaded!")

end) -- end InitKeySystem
