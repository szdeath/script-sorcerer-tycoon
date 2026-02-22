-- ================================================
-- SORCERER SCRIPTS - RAYFIELD UI v13
-- Auto Farm | Dump Boss | Dash No CD
-- Skills | Auto Awakening | Movement
-- ================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local Player    = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")
local HRP       = Character:WaitForChild("HumanoidRootPart")

local expiry = os.time({year = 2026, month = 2, day = 28, hour = 23, min = 59, sec = 59})
if os.time() > expiry then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = "Ikki",
        Text     = "This script has expired. Contact the owner for an update.",
        Duration = 10,
    })
    return
end

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

local LimitBreakRemote = GetRemote({"LimitBreaker", "LimitBreak"})
local RebirthRemote    = GetRemote({"Tycoon",       "Rebirth"})
local SpeedRemote      = GetRemote({"Movements",    "Speed"})
local M1Remote         = GetRemote({"Skills",       "M1", "M1Attack"})
local SkillRemote      = GetRemote({"Skills",       "SKill"})
local AwakeningRemote  = GetRemote({"Skills",       "Awakening", "ActivateAwakening"})

-- ================================================
-- BOSS ZONES
-- ================================================
local BossZones = {}
pcall(function()
    local Map = workspace:WaitForChild("Map"):WaitForChild("Boss")
    for _, zone in ipairs({"Lac", "Shibuya", "Metro", "WorldBoss"}) do
        local z = Map:FindFirstChild(zone)
        if z then
            local b = z:FindFirstChild("Bosses")
            if b then table.insert(BossZones, b) end
        end
    end
end)

local function GetAnyBoss()
    for _, folder in ipairs(BossZones) do
        for _, boss in ipairs(folder:GetChildren()) do
            local hum = boss:FindFirstChildOfClass("Humanoid")
            local hrp = boss:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                return boss, hum, hrp
            end
        end
    end
    return nil, nil, nil
end

-- ================================================
-- STATE
-- ================================================
local State = {
    AutoFarm      = false,
    DumpBoss      = false,
    Flying        = false,
    Noclip        = false,
    InfJump       = false,
    SpeedHack     = false,
    AutoLB        = false,
    AutoRebirth   = false,
    DashNoCD      = false,
    AutoAwakening = false,
    AutoCollectYen= false,
    AutoUpgrade   = false,
    GodMode       = false,
    FlySpeed      = 80,
    WalkSpeed     = 200,
    LastBossPos   = nil,
}

-- ================================================
-- GOD MODE — Instant Respawn at Death Position
-- Saves CFrame where player died, calls
-- LoadCharacter(), then teleports back there.
-- ================================================
local godModeConns = {}
local lastDeathPos = nil

local function ApplyGodModeToChar(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    local conn = hum.Died:Connect(function()
        if not State.GodMode then return end
        lastDeathPos = hrp.CFrame
        task.wait(0.05)
        pcall(function() Player:LoadCharacter() end)
    end)
    table.insert(godModeConns, conn)
end

local function StartGodMode()
    State.GodMode = true
    ApplyGodModeToChar(Character)
end

local function StopGodMode()
    State.GodMode = false
    lastDeathPos = nil
    for _, c in ipairs(godModeConns) do
        pcall(function() c:Disconnect() end)
    end
    godModeConns = {}
end

local FlyVelocity, FlyGyro
local farmThread    = nil

-- ================================================
-- DASH NO COOLDOWN
-- ================================================
local function ClearDashCD()
    if not Character then return end
    for _, fn in ipairs({"Cooldowns", "Cooldown"}) do
        local f = Character:FindFirstChild(fn)
        if f then
            for _, obj in ipairs(f:GetChildren()) do
                local low = obj.Name:lower()
                if low:find("dash") or low:find("dodge") or
                   low:find("roll") or low:find("blink") or
                   low:find("movement") or low:find("move") then
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
                if low:find("dash") or low:find("dodge") or
                   low:find("roll") or low:find("blink") then
                    if type(v) == "number" and v > 0 then
                        pcall(function() obj:SetAttribute(k, 0) end)
                    elseif type(v) == "boolean" and v then
                        pcall(function() obj:SetAttribute(k, false) end)
                    end
                end
            end
        end
        if obj:IsA("BoolValue") or obj:IsA("NumberValue") or obj:IsA("IntValue") then
            local low = obj.Name:lower()
            if low:find("dash") or low:find("dodge") or
               low:find("roll") or low:find("blink") then
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
        while State.DashNoCD do
            ClearDashCD()
            task.wait(0.05)
        end
        dashCDThread = nil
    end)
end

local function StopDashNoCD()
    State.DashNoCD = false
    dashCDThread = nil
end

-- ================================================
-- AUTO AWAKENING
-- ================================================
local function StartAutoAwakening()
    State.AutoAwakening = true
    task.spawn(function()
        while State.AutoAwakening do
            if Character then
                for _, fn in ipairs({"Cooldowns", "Cooldown"}) do
                    local f = Character:FindFirstChild(fn)
                    if f then
                        local awCD = f:FindFirstChild("AwakeningCooldown")
                        if awCD then pcall(function() awCD:Destroy() end) end
                    end
                end
                if AwakeningRemote then
                    pcall(function() AwakeningRemote:FireServer() end)
                end
            end
            task.wait(0.1)
        end
    end)
end

local function StopAutoAwakening()
    State.AutoAwakening = false
end

-- ================================================
-- DUMP BOSS
-- ================================================
local function StartDumpBoss()
    State.DumpBoss = true
    task.spawn(function()
        while State.DumpBoss do
            local boss, bossHum = GetAnyBoss()
            if boss then
                pcall(function()
                    for _, p in ipairs(boss:GetDescendants()) do
                        if p:IsA("BasePart") then p.Anchored = true end
                        if p:IsA("Script")   then p.Disabled = true end
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
    local boss, bossHum = GetAnyBoss()
    if boss then
        pcall(function()
            for _, p in ipairs(boss:GetDescendants()) do
                if p:IsA("BasePart") then p.Anchored = false end
                if p:IsA("Script")   then p.Disabled = false end
            end
            if bossHum then bossHum.WalkSpeed = 16; bossHum.JumpPower = 50 end
        end)
    end
end

-- ================================================
-- AUTO COLLECT YEN
-- ================================================
local function StartAutoCollectYen()
    State.AutoCollectYen = true
    task.spawn(function()
        while State.AutoCollectYen do
            if HRP then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if not State.AutoCollectYen then break end
                    if obj:IsA("ProximityPrompt") then
                        local low = obj.Parent and obj.Parent.Name:lower() or ""
                        local actionLow = obj.ActionText and obj.ActionText:lower() or ""
                        if low:find("yen") or low:find("coin") or low:find("drop") or
                           low:find("reward") or low:find("pickup") or low:find("collect") or
                           low:find("cursed energy") or low:find("cursed finger") or
                           low:find("remain") or low:find("relic") or low:find("orb") or
                           actionLow:find("collect") or actionLow:find("pick") or
                           actionLow:find("grab") then
                            pcall(function() fireproximityprompt(obj) end)
                        end
                    end
                    if obj:IsA("BasePart") then
                        local low = obj.Name:lower()
                        if low:find("yen") or low:find("coin") or low:find("drop") or
                           low:find("pickup") or low:find("collect") or
                           low:find("cursed energy") or low:find("cursed finger") then
                            pcall(function() firetouchinterest(HRP, obj, 0) end)
                            pcall(function() firetouchinterest(HRP, obj, 1) end)
                        end
                    end
                end
            end
            task.wait(0.3)
        end
    end)
end

-- ================================================
-- AUTO UPGRADE TYCOON
-- ================================================
local TycoonNames = {
    "Choso","Gojo","Hanami","Jogo","Maki",
    "Megumi","Nanami","Nobara","Todo","Toge","Toji","Yuji"
}

local TycoonStateRemote = GetRemote({"Tycoon", "GetTycoonsState"})
local CurrentTycoon     = nil

local function DetectMyTycoon()
    if TycoonStateRemote then
        local ok, result = pcall(function()
            return TycoonStateRemote:InvokeServer()
        end)
        if ok and type(result) == "table" then
            for name, data in pairs(result) do
                if type(data) == "table" and data.claimed and
                   data.ownerId == Player.UserId then
                    CurrentTycoon = name
                    return name
                end
            end
        end
    end
    local folder = workspace:FindFirstChild("Map")
    folder = folder and folder:FindFirstChild("Tycoon")
    if folder then
        for _, name in ipairs(TycoonNames) do
            local t = folder:FindFirstChild(name)
            if t then
                local ov = t:FindFirstChild("Owner") or t:FindFirstChild("OwnerName")
                if ov then
                    if ov:IsA("StringValue") and ov.Value == Player.Name then
                        CurrentTycoon = name; return name
                    end
                    if ov:IsA("ObjectValue") and ov.Value == Player then
                        CurrentTycoon = name; return name
                    end
                end
                if t:GetAttribute("Owner") == Player.Name or
                   t:GetAttribute("OwnerId") == Player.UserId then
                    CurrentTycoon = name; return name
                end
            end
        end
    end
    return nil
end

local upgradeThread = nil
local function StartAutoUpgrade()
    State.AutoUpgrade = true
    upgradeThread = task.spawn(function()
        while State.AutoUpgrade do
            if not CurrentTycoon then DetectMyTycoon() end
            if CurrentTycoon and HRP then
                local folder = workspace:FindFirstChild("Map")
                folder = folder and folder:FindFirstChild("Tycoon")
                local myTycoon = folder and folder:FindFirstChild(CurrentTycoon)
                if myTycoon then
                    local pads = {}
                    for _, obj in ipairs(myTycoon:GetDescendants()) do
                        if obj:IsA("BasePart") and
                           obj.Name:sub(1, 14) == "Marker_Button_" and
                           obj:FindFirstChild("TouchInterest") then
                            table.insert(pads, obj)
                        end
                    end
                    table.sort(pads, function(a, b)
                        local na = tonumber(a.Name:match("_(%d+)$")) or 0
                        local nb = tonumber(b.Name:match("_(%d+)$")) or 0
                        if na == nb then return a.Name < b.Name end
                        return na < nb
                    end)
                    local savedCFrame = HRP.CFrame
                    for _, pad in ipairs(pads) do
                        if not State.AutoUpgrade then break end
                        pcall(function()
                            HRP.CFrame = CFrame.new(
                                pad.Position.X,
                                pad.Position.Y + pad.Size.Y / 2 + 2.5,
                                pad.Position.Z
                            )
                            task.wait(0.05)
                            firetouchinterest(HRP, pad, 0)
                            task.wait(0.05)
                            firetouchinterest(HRP, pad, 1)
                        end)
                        task.wait(0.1)
                    end
                    pcall(function() HRP.CFrame = savedCFrame end)
                else
                    DetectMyTycoon()
                end
            end
            task.wait(1)
        end
        upgradeThread = nil
    end)
end

local function StopAutoUpgrade()
    State.AutoUpgrade = false
    upgradeThread = nil
end

-- ================================================
-- SKILL SPAM (farm)
-- ================================================
local function SpamSkills(boss, _, bossHRP)
    if SkillRemote then
        -- ============================================================
        -- SKILLS LIST — edit here to add/remove skills
        -- Format: SkillRemote:FireServer("Character", "SkillName")
        -- ============================================================
        pcall(function() SkillRemote:FireServer("Jogo", "Coffin of the Iron Mountain") end)
        -- ADD MORE SKILLS BELOW:
        -- pcall(function() SkillRemote:FireServer("Character", "SkillName") end)
        -- ============================================================
    end
    if M1Remote then pcall(function() M1Remote:FireServer(bossHRP) end) end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        for _, key in ipairs({
            Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C,
            Enum.KeyCode.V, Enum.KeyCode.Q, Enum.KeyCode.E,
            Enum.KeyCode.R, Enum.KeyCode.T, Enum.KeyCode.G,
        }) do
            vim:SendKeyEvent(true,  key, false, game)
            task.defer(function() vim:SendKeyEvent(false, key, false, game) end)
        end
    end)
end

-- ================================================
-- FARM LOOP
-- ================================================
local function StartFarm()
    if farmThread then return end
    farmThread = task.spawn(function()
        while State.AutoFarm do
            local boss, bossHum, bossHRP = GetAnyBoss()
            if boss and bossHRP then
                State.LastBossPos = bossHRP.CFrame
                if HRP then
                    HRP.CFrame = bossHRP.CFrame * CFrame.new(0, 0, 3)
                    HRP.CFrame = CFrame.lookAt(HRP.Position, bossHRP.Position)
                end
                SpamSkills(boss, bossHum, bossHRP)
                if State.DashNoCD then ClearDashCD() end
            else
                task.wait(1)
            end
            task.wait(0.1)
        end
        farmThread = nil
    end)
end

local function StopFarm()
    State.AutoFarm = false
    farmThread = nil
end

-- ================================================
-- FLY
-- ================================================
local function StartFly()
    Character = Player.Character
    if not Character then return end
    HRP      = Character:FindFirstChild("HumanoidRootPart")
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then Humanoid.PlatformStand = true end
    FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    FlyVelocity.Velocity  = Vector3.zero
    FlyVelocity.Parent    = HRP
    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    FlyGyro.D = 100
    FlyGyro.Parent = HRP
    RunService:BindToRenderStep("SorcFly", Enum.RenderPriority.Input.Value, function()
        if not State.Flying or not HRP then return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)           then dir += cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)           then dir -= cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)           then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)           then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.new(0, 1, 0)  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0)  end
        FlyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * State.FlySpeed or Vector3.zero
        FlyGyro.CFrame = cam.CFrame
    end)
end

local function StopFly()
    State.Flying = false
    RunService:UnbindFromRenderStep("SorcFly")
    if FlyVelocity then FlyVelocity:Destroy(); FlyVelocity = nil end
    if FlyGyro     then FlyGyro:Destroy();     FlyGyro     = nil end
    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

-- ================================================
-- RUNTIME LOOPS
-- ================================================
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
    while task.wait(3) do
        if State.AutoLB and LimitBreakRemote then
            pcall(function() LimitBreakRemote:FireServer() end)
        end
    end
end)

task.spawn(function()
    while task.wait(5) do
        if State.AutoRebirth and RebirthRemote then
            pcall(function() RebirthRemote:FireServer() end)
        end
    end
end)

task.spawn(function()
    task.wait(3)
    DetectMyTycoon()
end)

-- ================================================
-- RESPAWN HANDLER
-- ================================================
Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    HRP       = char:WaitForChild("HumanoidRootPart")
    State.Flying = false
    State.Noclip = false

    -- God Mode: teleport back to exact death position
    if State.GodMode and lastDeathPos then
        task.spawn(function()
            for _ = 1, 8 do
                task.wait(0.1)
                if HRP then
                    pcall(function() HRP.CFrame = lastDeathPos end)
                end
            end
        end)
    elseif State.AutoFarm and State.LastBossPos then
        task.spawn(function()
            for _ = 1, 5 do
                task.wait(0.2)
                local _, _, freshHRP = GetAnyBoss()
                if HRP then
                    HRP.CFrame = freshHRP
                        and freshHRP.CFrame * CFrame.new(0, 0, 3)
                        or  State.LastBossPos * CFrame.new(0, 0, 3)
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
    if State.DashNoCD      then task.wait(1); StartDashNoCD()      end
    if State.AutoAwakening then task.wait(1); StartAutoAwakening() end
    if State.GodMode then
        for _, c in ipairs(godModeConns) do pcall(function() c:Disconnect() end) end
        godModeConns = {}
        task.wait(0.5)
        ApplyGodModeToChar(char)
    end
end)

-- ================================================
-- RAYFIELD UI
-- ================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "Sorcerer Tycoon Script",
    Icon            = 0,
    LoadingTitle    = "Made by Ikki",
    LoadingSubtitle = "v1",
    Theme           = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "SorcererScripts",
        FileName   = "Config",
    },
    KeySystem = false,
})

-- ================================================
-- LOGO — Ikki
-- ================================================
local IKKI_ASSET_ID = 79541805588283

local logoGui = Instance.new("ScreenGui")
logoGui.Name           = "IkkiLogoGui"
logoGui.ResetOnSpawn   = false
logoGui.DisplayOrder   = 999
logoGui.IgnoreGuiInset = true
logoGui.Parent         = Player.PlayerGui

local logo = Instance.new("ImageLabel")
logo.Size                   = UDim2.new(0, 42, 0, 42)
logo.Position               = UDim2.new(0, 14, 0, 14)
logo.BackgroundTransparency = 1
logo.Image                  = "rbxassetid://" .. tostring(IKKI_ASSET_ID)
logo.ScaleType              = Enum.ScaleType.Fit
logo.ZIndex                 = 999
logo.Parent                 = logoGui
Instance.new("UICorner", logo).CornerRadius = UDim.new(1, 0)

-- ================================================
-- TAB: MAIN
-- ================================================
local FarmTab = Window:CreateTab("⚔ Main", 4483362458)

FarmTab:CreateToggle({
    Name = "God Mode (Instant Respawn)", CurrentValue = false, Flag = "GodMode",
    Callback = function(v)
        if v then StartGodMode() else StopGodMode() end
    end,
})

local StatusParagraph = FarmTab:CreateParagraph({
    Title = "Boss Status", Content = "Checking...",
})

task.spawn(function()
    while task.wait(0.5) do
        local boss, bossHum = GetAnyBoss()
        if boss and bossHum then
            local hp = math.floor(bossHum.Health)
            local mx = math.floor(bossHum.MaxHealth)
            StatusParagraph:Set({
                Title   = "● " .. boss.Name .. "  ALIVE",
                Content = string.format("HP: %d / %d  (%.1f%%)", hp, mx, (hp/mx)*100),
            })
        else
            StatusParagraph:Set({
                Title   = "All Boss defeated or not spawned",
                Content = "Lac / Shibuya / Metro / WorldBoss",
            })
        end
    end
end)

FarmTab:CreateButton({
    Name = "Teleport to Boss",
    Callback = function()
        local _, _, bossHRP = GetAnyBoss()
        if bossHRP and HRP then
            HRP.CFrame = bossHRP.CFrame * CFrame.new(0, 0, 3)
            Rayfield:Notify({ Title = "✅ Teleported", Content = "You In Boss.", Duration = 2 })
        else
            Rayfield:Notify({ Title = "❌ Boss not found", Content = "Wait boss spawn", Duration = 3 })
        end
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Farm Boss", CurrentValue = false, Flag = "AutoFarm",
    Callback = function(v)
        State.AutoFarm = v
        if v then StartFarm() else StopFarm() end
    end,
})

FarmTab:CreateToggle({
    Name = "Dump Boss", CurrentValue = false, Flag = "DumpBoss",
    Callback = function(v)
        State.DumpBoss = v
        if v then StartDumpBoss() else StopDumpBoss() end
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Collect Yen", CurrentValue = false, Flag = "AutoCollectYen",
    Callback = function(v)
        if v then StartAutoCollectYen() else State.AutoCollectYen = false end
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Upgrade Tycoon", CurrentValue = false, Flag = "AutoUpgrade",
    Callback = function(v)
        if v then
            if not CurrentTycoon then DetectMyTycoon() end
            StartAutoUpgrade()
        else
            StopAutoUpgrade()
        end
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Limit Break", CurrentValue = false, Flag = "AutoLB",
    Callback = function(v) State.AutoLB = v end,
})

FarmTab:CreateToggle({
    Name = "Auto Rebirth", CurrentValue = false, Flag = "AutoRebirth",
    Callback = function(v) State.AutoRebirth = v end,
})

-- ================================================
-- TAB: SKILLS
-- ================================================
local SkillTab = Window:CreateTab("⚡ Skills", 4483362458)

SkillTab:CreateParagraph({
    Title   = "Domain Expansion",
    Content = "Character Domain Expansion and Skill. You need unlock all First",
})

SkillTab:CreateButton({
    Name = "Jogo Domain Expansion",
    Callback = function()
        if SkillRemote then
            pcall(function() SkillRemote:FireServer("Jogo", "Coffin of the Iron Mountain") end)
        end
        Rayfield:Notify({ Title = "Jogo", Content = "Coffin of the Iron Mountain", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Gojo Domain Expansion",
    Callback = function()
        if SkillRemote then
            pcall(function() SkillRemote:FireServer("Gojo", "Unlimited Void") end)
        end
        Rayfield:Notify({ Title = "Gojo", Content = "Unlimited Void", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Gojo Mugen",
    Callback = function()
        if SkillRemote then
            pcall(function() SkillRemote:FireServer("Gojo", "Infinity") end)
        end
        Rayfield:Notify({ Title = "Gojo", Content = "Infinity", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Toji Domain Expansion",
    Callback = function()
        if SkillRemote then
            pcall(function() SkillRemote:FireServer("Toji", "Heavenly Restriction: Complete") end)
        end
        Rayfield:Notify({ Title = "Toji", Content = "Heavenly Restriction: Complete", Duration = 2 })
    end,
})

-- ============================================================
-- ADD MORE CHARACTERS BELOW IN THIS FORMAT:
--
-- SkillTab:CreateParagraph({ Title = "CharacterName", Content = "CharacterName Skills" })
--
-- SkillTab:CreateButton({
--     Name = "CharacterName — SkillName",
--     Callback = function()
--         if SkillRemote then
--             pcall(function() SkillRemote:FireServer("CharacterName", "SkillName") end)
--         end
--     end,
-- })
-- ============================================================

SkillTab:CreateToggle({
    Name = "Auto Awakening", CurrentValue = false, Flag = "AutoAwakening",
    Callback = function(v)
        if v then StartAutoAwakening() else StopAutoAwakening() end
    end,
})

-- ================================================
-- TAB: MOVEMENT
-- ================================================
local MoveTab = Window:CreateTab("🏃 Movement", 4483362458)

-- ================================================
-- TAB: TELEPORT
-- ================================================
-- Rayfield does not support removing elements from a tab visually.
-- Solution: destroy the entire tab and recreate it on refresh.
local TpTab = nil

local function GetPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            table.insert(names, p.Name)
        end
    end
    return names
end

local function BuildTeleportTab()
    -- Destroy old tab if it exists
    if TpTab then
        pcall(function() TpTab:Destroy() end)
        TpTab = nil
    end

    TpTab = Window:CreateTab("🔀 Teleport", 4483362458)

    -- Update button always at the top
    TpTab:CreateButton({
        Name = "🔄 Update List",
        Callback = function()
            BuildTeleportTab()
            Rayfield:Notify({ Title = "✅ List updated", Content = #GetPlayerNames() .. " players", Duration = 2 })
        end,
    })

    local names = GetPlayerNames()
    if #names == 0 then
        TpTab:CreateParagraph({ Title = "No players online", Content = "Click Update List to refresh." })
        return
    end

    for _, name in ipairs(names) do
        local pName = name
        TpTab:CreateButton({
            Name = "➡ " .. pName,
            Callback = function()
                local target = Players:FindFirstChild(pName)
                if target and target.Character then
                    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                    if tHRP and HRP then
                        HRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
                        Rayfield:Notify({ Title = "✅ Teleported", Content = "→ " .. pName, Duration = 2 })
                    end
                else
                    Rayfield:Notify({ Title = "❌ " .. pName, Content = "Character not found.", Duration = 2 })
                end
            end,
        })
    end
end

-- Build on load
task.spawn(function()
    task.wait(2)
    BuildTeleportTab()
end)

-- Auto rebuild when players join/leave
Players.PlayerAdded:Connect(function() task.wait(0.5) BuildTeleportTab() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) BuildTeleportTab() end)

MoveTab:CreateToggle({
    Name = "Fly", CurrentValue = false, Flag = "Fly",
    Callback = function(v)
        State.Flying = v
        if v then StartFly() else StopFly() end
    end,
})
MoveTab:CreateSlider({
    Name = "Fly Speed", Range = {10, 300}, Increment = 5,
    Suffix = "studs/s", CurrentValue = 80, Flag = "FlySpeed",
    Callback = function(v) State.FlySpeed = v end,
})
MoveTab:CreateToggle({
    Name = "Speed Hack", CurrentValue = false, Flag = "SpeedHack",
    Callback = function(v)
        State.SpeedHack = v
        if v then
            if Humanoid then Humanoid.WalkSpeed = State.WalkSpeed end
            if SpeedRemote then pcall(function() SpeedRemote:FireServer(State.WalkSpeed) end) end
        else
            if Humanoid then Humanoid.WalkSpeed = 16 end
            if SpeedRemote then pcall(function() SpeedRemote:FireServer(16) end) end
        end
    end,
})
MoveTab:CreateSlider({
    Name = "Walk Speed", Range = {16, 500}, Increment = 10,
    Suffix = "studs/s", CurrentValue = 200, Flag = "WalkSpeed",
    Callback = function(v)
        State.WalkSpeed = v
        if State.SpeedHack and Humanoid then
            Humanoid.WalkSpeed = v
            if SpeedRemote then pcall(function() SpeedRemote:FireServer(v) end) end
        end
    end,
})
MoveTab:CreateToggle({
    Name = "Noclip", CurrentValue = false, Flag = "Noclip",
    Callback = function(v)
        State.Noclip = v
        if not v and Character then
            for _, p in ipairs(Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end,
})
MoveTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",
    Callback = function(v) State.InfJump = v end,
})
MoveTab:CreateToggle({
    Name = "Dash No Cooldown", CurrentValue = false, Flag = "DashNoCD",
    Callback = function(v)
        if v then StartDashNoCD() else StopDashNoCD() end
    end,
})

-- ================================================
-- TAB: INFO
-- ================================================
local InfoTab = Window:CreateTab("ℹ Info", 4483362458)

local YenParagraph = InfoTab:CreateParagraph({ Title = "💰 Currency", Content = "Loading..." })

task.spawn(function()
    local ls = Player:WaitForChild("leaderstats", 10)
    if ls then
        local yen = ls:FindFirstChild("Yen")
        local ce  = ls:FindFirstChild("Cursed Energy")
        local cf  = ls:FindFirstChild("Cursed Fingers")
        local function upd()
            YenParagraph:Set({
                Title   = "💰 Currency",
                Content = string.format("Yen: %s\nCursed Energy: %s\nCursed Fingers: %s",
                    yen and tostring(yen.Value) or "N/A",
                    ce  and tostring(ce.Value)  or "N/A",
                    cf  and tostring(cf.Value)  or "N/A"),
            })
        end
        upd()
        if yen then yen:GetPropertyChangedSignal("Value"):Connect(upd) end
        if ce  then ce:GetPropertyChangedSignal("Value"):Connect(upd)  end
        if cf  then cf:GetPropertyChangedSignal("Value"):Connect(upd)  end
    end
end)

InfoTab:CreateButton({ Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
    end,
})
InfoTab:CreateButton({ Name = "Reset Character",
    Callback = function() if Humanoid then Humanoid.Health = 0 end end,
})

-- ================================================
Rayfield:LoadConfiguration()
print("[Sorcerer Scripts v13] Loaded!")
