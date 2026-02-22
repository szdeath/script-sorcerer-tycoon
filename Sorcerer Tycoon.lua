-- ================================================
-- SORCERER SCRIPTS - RAYFIELD UI v11
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
    return  -- stops the entire script here
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
    FlySpeed      = 80,
    WalkSpeed     = 200,
    LastBossPos   = nil,
}

local FlyVelocity, FlyGyro
local farmThread = nil

-- ================================================
-- DASH NO COOLDOWN
-- Removes only dash/movement cooldowns every 0.05s
-- Placed inside the main farm loop automatically
-- ================================================
local function ClearDashCD()
    if not Character then return end
    -- Destroy dash-related values in Cooldowns folder
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
    -- Zero dash cooldown attributes on character
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
                    local name = obj.Name:lower()
                    if obj:IsA("BasePart") and (
                        name:find("yen") or name:find("coin") or
                        name:find("money") or name:find("pickup") or
                        name:find("collect") or name:find("drop")
                    ) then
                        pcall(function()
                            firetouchinterest(HRP, obj, 0)
                            firetouchinterest(HRP, obj, 1)
                        end)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- ================================================
-- SKILL SPAM (farm)
-- ================================================
local function SpamSkills(boss, _, bossHRP)
    if SkillRemote then
        -- ============================================================
        -- SKILLS LIST — edite aqui para adicionar/remover skills
        -- Formato: SkillRemote:FireServer("Personagem", "NomeDaSkill")
        -- ============================================================
        pcall(function() SkillRemote:FireServer("Jogo", "Coffin of the Iron Mountain") end)
        -- ADICIONE MAIS SKILLS ABAIXO:
        -- pcall(function() SkillRemote:FireServer("Personagem", "NomeDaSkill") end)
        -- pcall(function() SkillRemote:FireServer("Personagem", "NomeDaSkill") end)
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
-- FARM LOOP  (also runs Dash No CD while farming)
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
                -- Dash CD cleared every farm tick when DashNoCD is on
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

-- ================================================
-- RESPAWN HANDLER
-- ================================================
Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    HRP       = char:WaitForChild("HumanoidRootPart")
    State.Flying = false
    State.Noclip = false
    if State.AutoFarm and State.LastBossPos then
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
    if State.DashNoCD     then task.wait(1); StartDashNoCD()      end
    if State.AutoAwakening then task.wait(1); StartAutoAwakening() end
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
logoGui.Name = "IkkiLogoGui"
logoGui.ResetOnSpawn = false
logoGui.DisplayOrder = 999
logoGui.IgnoreGuiInset = true
logoGui.Parent = Player.PlayerGui

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 42, 0, 42)
logo.Position = UDim2.new(0, 14, 0, 14)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://" .. tostring(IKKI_ASSET_ID)
logo.ScaleType = Enum.ScaleType.Fit
logo.ZIndex = 999
logo.Parent = logoGui
Instance.new("UICorner", logo).CornerRadius = UDim.new(1, 0)

-- ================================================
-- TAB: AUTO FARM
-- ================================================
local FarmTab = Window:CreateTab("⚔ Auto Farm", 4483362458)

local StatusParagraph = FarmTab:CreateParagraph({
    Title = "Boss Status", Content = "Verificando...",
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

-- ============================================================
-- SKILLS INDIVIDUAIS — botões para disparar cada skill manualmente
-- ============================================================

-- JOGO
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
-- ADICIONE MAIS PERSONAGENS ABAIXO NESTE FORMATO:
--
-- SkillTab:CreateParagraph({ Title = "NomePersonagem", Content = "Skills de NomePersonagem" })
--
-- SkillTab:CreateButton({
--     Name = "NomePersonagem — NomeDaSkill",
--     Callback = function()
--         if SkillRemote then
--             pcall(function() SkillRemote:FireServer("NomePersonagem", "NomeDaSkill") end)
--         end
--     end,
-- })
-- ============================================================

-- ================================================
-- TAB: MOVEMENT
-- ================================================
local MoveTab = Window:CreateTab("🏃 Movement", 4483362458)

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

local YenParagraph = InfoTab:CreateParagraph({ Title = "💰 Currency", Content = "Carregando..." })

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
print("[Sorcerer Scripts v11] Loaded!")