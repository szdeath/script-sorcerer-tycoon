-- ================================================
-- SORCERER SCRIPTS - RAYFIELD UI v14
-- Auto Farm | Dump Boss | Dash No CD
-- Skills | Auto Awakening | Movement
-- ================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

print("[SorcererScript] Iniciando...")

local Player    = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")
local HRP       = Character:WaitForChild("HumanoidRootPart")

-- Sempre retorna o HRP atual (evita crash ao regenerar)
local function GetHRP()
    local char = Player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local expiry = os.time({year = 2026, month = 2, day = 28, hour = 23, min = 59, sec = 59})
if os.time() > expiry then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = "Ikki",
        Text     = "This script has expired. Contact the owner for an update.",
        Duration = 10,
    })
    return
end
print("[SorcererScript] Expiração OK")

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
-- Remove prefixo numérico "6874.817_Toji" → "Toji" e sufixo numérico "Boss 1" → "Boss"
local function CleanBossName(name)
    name = name:gsub("^[%d%.]+_", "")  -- remove prefixo "12345.678_"
    name = name:gsub("%s*%d+%s*$", "") -- remove sufixo " 1"
    name = name:gsub("^%s*", ""):gsub("%s*$", "")
    return name
end
pcall(function()
    local Map = workspace:WaitForChild("Map"):WaitForChild("Boss")
    -- Scan dinâmico: pega TODAS as zonas, não só lista hardcoded
    for _, zone in ipairs(Map:GetChildren()) do
        local b = zone:FindFirstChild("Bosses")
        if b then table.insert(BossZones, b) end
    end
    -- Monitora novas zonas adicionadas (ex: Shibuya aparece depois)
    Map.ChildAdded:Connect(function(zone)
        task.wait(0.5)
        local b = zone:FindFirstChild("Bosses")
        if b then
            -- Evita duplicatas
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
    HitboxSize      = 30,
    FlySpeed        = 80,
    WalkSpeed       = 200,
    LastBossPos     = nil,
}

-- ================================================
-- GOD MODE
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
    for _, c in ipairs(godModeConns) do pcall(function() c:Disconnect() end) end
    godModeConns = {}
end

local FlyVelocity, FlyGyro
local farmThread = nil

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
                if low:find("dash") or low:find("dodge") or low:find("roll") or low:find("blink") then
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
-- AUTO AWAKENING ON LOW HP
-- ================================================
local function GetPlayerHealth()
    local char = Player.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil, nil end
    return hum.Health, hum.MaxHealth
end

local function FireAwakening()
    if Character then
        for _, fn in ipairs({"Cooldowns", "Cooldown"}) do
            local f = Character:FindFirstChild(fn)
            if f then
                local awCD = f:FindFirstChild("AwakeningCooldown")
                if awCD then pcall(function() awCD:Destroy() end) end
            end
        end
    end
    if AwakeningRemote then
        pcall(function() AwakeningRemote:FireServer() end)
    end
end

local awakeningThread = nil
local lastAwakeningTime = 0
local AWAKENING_COOLDOWN = 60

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
                    lastAwakeningTime = now
                    FireAwakening()
                end
            end
            task.wait(0.5)
        end
        awakeningThread = nil
    end)
end

local function StopAutoAwakening()
    State.AutoAwakening = false
    awakeningThread = nil
end

-- ================================================
-- BOSS SELECTION
-- ================================================
local selectedBossName = "Any"

local function GetAllBossNames()
    local names = {"Any"}
    local bossMap = workspace:FindFirstChild("Map")
    bossMap = bossMap and bossMap:FindFirstChild("Boss")
    if bossMap then
        for _, zone in ipairs(bossMap:GetChildren()) do
            local bosses = zone:FindFirstChild("Bosses")
            if bosses then
                for _, boss in ipairs(bosses:GetChildren()) do
                    local hum = boss:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local name = CleanBossName(boss.Name)
                        local found = false
                        for _, n in ipairs(names) do if n == name then found = true break end end
                        if not found then table.insert(names, name) end
                    end
                end
            end
        end
    end
    if #names == 1 then table.insert(names, "(no bosses found)") end
    return names
end

local function GetSelectedBoss()
    local bossMap = workspace:FindFirstChild("Map")
    bossMap = bossMap and bossMap:FindFirstChild("Boss")
    if not bossMap then return nil, nil, nil end
    for _, zone in ipairs(bossMap:GetChildren()) do
        local bosses = zone:FindFirstChild("Bosses")
        if bosses then
            for _, boss in ipairs(bosses:GetChildren()) do
                local hum = boss:FindFirstChildOfClass("Humanoid")
                local hrp = boss:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then
                    -- Remove prefixo numérico tipo "6874.81709306105_Toji" → "Toji"
                    local name = CleanBossName(boss.Name)
                    if selectedBossName == "Any" or name == selectedBossName then
                        return boss, hum, hrp
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

-- ================================================
-- DUMP BOSS
-- ================================================
-- Posição de saída do portal de Shibuya
local SHIBUYA_PORTAL_ENTRY  = Vector3.new(-861.687, 44.683, -480.250)
local SHIBUYA_PORTAL_EXIT   = Vector3.new(-1770.879, 62.717, -423.178)
local SHIBUYA_THRESHOLD_X   = -1200 -- X menor que isso = dentro de Shibuya

local function IsInShibuya()
    local HRP = GetHRP()
    if not HRP then return false end
    return HRP.Position.X < SHIBUYA_THRESHOLD_X
end

local function TeleportToBossPos(bossHRP)
    local HRP = GetHRP()
    if not HRP or not bossHRP then return end
    local targetPos = bossHRP.Position
    -- Se boss está em Shibuya mas player não está, teleporta pela saída do portal
    if targetPos.X < SHIBUYA_THRESHOLD_X and not IsInShibuya() then
        HRP.CFrame = CFrame.new(SHIBUYA_PORTAL_EXIT + Vector3.new(0, 5, 0))
        task.wait(0.3)
    end
    local freshHRP = GetHRP()
    if freshHRP then
        freshHRP.CFrame = bossHRP.CFrame * CFrame.new(0, 0, 3)
    end
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
    local boss, bossHum = GetSelectedBoss()
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
-- TYCOON DETECTION
-- ================================================
local TycoonNames = {
    "TycoonChoso","TycoonGojo","TycoonHanami","TycoonJogo","TycoonMaki",
    "TycoonMegumi","TycoonNanami","TycoonNobara","TycoonTodo","TycoonToge",
    "TycoonToji","TycoonYuji"
}

local CurrentTycoon = nil
-- Pre-declarado para o hook poder referenciar
local TycoonParagraph = nil

local function DetectMyTycoon()
    if TycoonStateRemote then
        local ok, result = pcall(function()
            return TycoonStateRemote:InvokeServer()
        end)
        if ok and type(result) == "table" then
            for charName, data in pairs(result) do
                if type(data) == "table" and data.claimed == true and
                   data.ownerId == Player.UserId then
                    CurrentTycoon = "Tycoon" .. charName
                    return CurrentTycoon
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

local lastDetectTime = 0
local DETECT_COOLDOWN = 30

local function DetectMyTycoonIfNeeded()
    if CurrentTycoon then return end
    local now = os.clock()
    if now - lastDetectTime < DETECT_COOLDOWN then return end
    lastDetectTime = now
    DetectMyTycoon()
end

-- Hook no ClaimRemote — detecta tycoon automaticamente quando player clama uma
-- Claim:FireServer("Gojo") → CurrentTycoon = "TycoonGojo"
local function HookClaimRemote()
    if not ClaimRemote then return end
    -- hookmetamethod só disponível em alguns executors (ex: Synapse, KRNL)
    -- Se não existir, não quebra o script
    if not hookmetamethod or not getnamecallmethod then return end
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local ok, method = pcall(getnamecallmethod)
            if ok and method == "FireServer" and self == ClaimRemote then
                local args = {...}
                local charName = args[1]
                if type(charName) == "string" then
                    CurrentTycoon = "Tycoon" .. charName
                    lastDetectTime = os.clock()
                    task.defer(function()
                        if TycoonParagraph then
                            pcall(function()
                                TycoonParagraph:Set({
                                    Title   = "🏯 Minha Tycoon",
                                    Content = charName .. " (auto)",
                                })
                            end)
                        end
                    end)
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end

-- Mutex para evitar que Yen e Upgrade rodem simultaneamente
local tycoonBusy = false

-- ================================================
-- AUTO COLLECT YEN
-- ================================================
local function StartAutoCollectYen()
    State.AutoCollectYen = true
    task.spawn(function()
        while State.AutoCollectYen do
            if tycoonBusy then task.wait(0.5) continue end
            local HRP = GetHRP()
            if HRP then
                if not CurrentTycoon then DetectMyTycoonIfNeeded() end
                if CurrentTycoon then
                    local myTycoon = workspace:FindFirstChild("Map")
                    myTycoon = myTycoon and myTycoon:FindFirstChild("Tycoons")
                    myTycoon = myTycoon and myTycoon:FindFirstChild(CurrentTycoon)
                    if not myTycoon or not myTycoon.Parent then
                        CurrentTycoon = nil
                        task.wait(2)
                        continue
                    end
                    local base = myTycoon:FindFirstChild("Base")
                    if base then
                        tycoonBusy = true
                        for _, folder in ipairs(base:GetChildren()) do
                            if not State.AutoCollectYen then break end
                            local col = folder:FindFirstChild("Collector")
                            if col and col:IsA("BasePart") and col.Parent
                               and col:FindFirstChild("TouchInterest") then
                                pcall(function()
                                    firetouchinterest(HRP, col, 0)
                                    task.wait(0.15)
                                    firetouchinterest(HRP, col, 1)
                                end)
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
-- AUTO COLLECT BOSS DROPS
-- ================================================
local DropZonePaths = {"Lac","Metro","Shibuya","WorldBoss"}

local function StartAutoCollectDrops()
    State.AutoCollectDrops = true
    task.spawn(function()
        while State.AutoCollectDrops do
            local currentHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not currentHRP then
                task.wait(1)
                continue
            end
            local bossMap = workspace:FindFirstChild("Map")
            bossMap = bossMap and bossMap:FindFirstChild("Boss")
            if bossMap then
                for _, zoneName in ipairs(DropZonePaths) do
                    if not State.AutoCollectDrops then break end
                    local zone = bossMap:FindFirstChild(zoneName)
                    if not zone then continue end
                    local drops = zone:FindFirstChild("Drops")
                    if not drops or #drops:GetChildren() == 0 then continue end

                    for _, item in ipairs(drops:GetChildren()) do
                        if not State.AutoCollectDrops then break end
                        if not item or not item.Parent then continue end
                        currentHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        if not currentHRP then break end

                        local part = item:IsA("BasePart") and item
                            or item:FindFirstChildOfClass("BasePart")
                        if not part or not part.Parent then continue end

                        local prompt = item:FindFirstChild("Prompt")
                        if not prompt then continue end

                        pcall(function()
                            prompt.MaxActivationDistance = math.huge
                            prompt.HoldDuration = 0
                        end)
                        pcall(function()
                            currentHRP.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                        end)
                        task.wait(0.1)

                        if not item.Parent then continue end

                        pcall(function() fireproximityprompt(prompt) end)
                        task.wait(0.05)
                        pcall(function()
                            firetouchinterest(currentHRP, part, 0)
                            task.wait(0.03)
                            firetouchinterest(currentHRP, part, 1)
                        end)

                        local t = 0
                        while item.Parent and t < 0.3 do
                            task.wait(0.05)
                            t += 0.05
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
end

-- ================================================
-- AUTO UPGRADE TYCOON
-- ================================================
local upgradeThread = nil
local function StartAutoUpgrade()
    State.AutoUpgrade = true
    upgradeThread = task.spawn(function()
        while State.AutoUpgrade do
            if tycoonBusy then task.wait(0.5) continue end
            if not CurrentTycoon then DetectMyTycoonIfNeeded() end
            local HRP = GetHRP()
            if CurrentTycoon and HRP then
                local myTycoon = workspace:FindFirstChild("Map")
                myTycoon = myTycoon and myTycoon:FindFirstChild("Tycoons")
                myTycoon = myTycoon and myTycoon:FindFirstChild(CurrentTycoon)
                if not myTycoon or not myTycoon.Parent then
                    CurrentTycoon = nil
                    task.wait(2)
                    continue
                end
                local purshases = myTycoon and myTycoon:FindFirstChild("Purshases")
                if purshases and purshases.Parent then
                    local pads = {}
                    for _, folder in ipairs(purshases:GetChildren()) do
                        if not folder.Parent then continue end
                        for _, btn in ipairs(folder:GetChildren()) do
                            if btn.Name:sub(1, 7) == "Button_" then
                                local base = btn:FindFirstChild("base")
                                if base and base:IsA("BasePart") and base.Parent
                                   and base:FindFirstChild("TouchInterest") then
                                    table.insert(pads, base)
                                end
                            end
                        end
                    end
                    table.sort(pads, function(a, b)
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
                        pcall(function()
                            firetouchinterest(HRP, pad, 0)
                            task.wait(0.15)
                            firetouchinterest(HRP, pad, 1)
                        end)
                        task.wait(0.5)
                    end
                    tycoonBusy = false
                else
                    CurrentTycoon = nil
                    lastDetectTime = 0
                end
            end
            task.wait(3)
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
-- Remote: SKill:FireServer(charName, skillName, skillType)
-- ================================================
local function SpamSkills(boss, _, bossHRP)
    local backpack = Player:FindFirstChild("Backpack")
    if backpack and SkillRemote then
        for _, tool in ipairs(backpack:GetChildren()) do
            if not tool:IsA("Tool") then continue end
            local skillName = tool.Name
            local charName  = tool:GetAttribute("CharacterName")
                           or tool:GetAttribute("Character")
                           or tool:GetAttribute("Char")
            local skillType = tool:GetAttribute("SkillType")
                           or tool:GetAttribute("Type")
                           or tool:GetAttribute("ToolType")
            if charName and skillType then
                pcall(function() SkillRemote:FireServer(charName, skillName, skillType) end)
            elseif charName then
                pcall(function() SkillRemote:FireServer(charName, skillName) end)
            else
                pcall(function() SkillRemote:FireServer(skillName) end)
            end
        end
    end
    if M1Remote and bossHRP then
        pcall(function() M1Remote:FireServer(bossHRP) end)
    end
end

-- ================================================
-- FARM LOOP
-- ================================================
local function StartFarm()
    if farmThread then return end
    StartAutoAwakening()
    farmThread = task.spawn(function()
        while State.AutoFarm do
            local boss, bossHum, bossHRP = GetSelectedBoss()
            if not boss or not bossHRP then
                task.wait(1)
                continue
            end

            local bossZone = nil
            local bossMap = workspace:FindFirstChild("Map")
            local bossMapBoss = bossMap and bossMap:FindFirstChild("Boss")
            if bossMapBoss then
                for _, zone in ipairs(bossMapBoss:GetChildren()) do
                    local bosses = zone:FindFirstChild("Bosses")
                    if bosses and bosses:IsAncestorOf(boss) then
                        bossZone = zone
                        break
                    end
                end
            end

            while State.AutoFarm and boss.Parent and bossHum and bossHum.Health > 0 do
                State.LastBossPos = bossHRP.CFrame
                local HRP = GetHRP()
                if HRP then
                    pcall(function()
                        TeleportToBossPos(bossHRP)
                    end)
                end
                SpamSkills(boss, bossHum, bossHRP)
                if State.DashNoCD then ClearDashCD() end
                task.wait(0.1)
            end

            if not State.AutoFarm then break end

            if bossZone then
                local drops = bossZone:FindFirstChild("Drops")
                if drops then
                    local waited = 0
                    while #drops:GetChildren() == 0 and waited < 3 do
                        task.wait(0.2)
                        waited += 0.2
                    end
                    local timeout = 0
                    while #drops:GetChildren() > 0 and timeout < 15 do
                        task.wait(0.3)
                        timeout += 0.3
                    end
                end
            end

            task.wait(0.5)
        end
        farmThread = nil
    end)
end

local function StopFarm()
    State.AutoFarm = false
    farmThread = nil
    StopAutoAwakening()
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
    while task.wait(5) do
        if State.AutoRebirth and RebirthRemote then
            pcall(function() RebirthRemote:FireServer() end)
        end
    end
end)

-- ================================================
-- SUPRESSOR DE NOTIFICAÇÃO "Tycoon not complete"
-- ================================================
task.spawn(function()
    local playerGui = Player:WaitForChild("PlayerGui", 10)
    if not playerGui then return end

    local function checkAndSuppress(gui)
        if not gui or not gui.Parent then return end
        task.wait(0.05)
        if not gui.Parent then return end
        for _, v in ipairs(gui:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("TextButton") then
                local t = v.Text:lower()
                if t:find("tycoon not complete") or t:find("not complete %(") then
                    pcall(function() gui:Destroy() end)
                    return
                end
            end
        end
    end

    playerGui.ChildAdded:Connect(checkAndSuppress)
    pcall(function()
        game:GetService("CoreGui").ChildAdded:Connect(checkAndSuppress)
    end)
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
                local _, _, freshHRP = GetAnyBoss()
                local HRP = GetHRP()
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
    if State.DashNoCD then task.wait(1); StartDashNoCD() end
    if State.AutoFarm  then task.wait(1); StartFarm()    end
    if State.GodMode then
        for _, c in ipairs(godModeConns) do pcall(function() c:Disconnect() end) end
        godModeConns = {}
        task.wait(0.5)
        ApplyGodModeToChar(char)
    end
end)

-- ================================================
-- KILL AURA
-- TurtleSpy confirmed: M1 is fired via SKill:FireServer(charName, "M1_1")
-- We spam M1_1 of the equipped character at every nearby target's HRP.
-- The char name is read from the player's equipped tool attributes.
-- ================================================
local ReportHitsRemote = GetRemote({"Skills", "ReportHits"})
local AnimHitRemote    = GetRemote({"Skills", "AnimationHit"})

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
                if (tHRP.Position - hrp.Position).Magnitude <= range then
                    table.insert(results, p.Character)
                end
            end
        end
    end
    -- Bosses
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
                        if (bHRP.Position - hrp.Position).Magnitude <= range then
                            table.insert(results, boss)
                        end
                    end
                end
            end
        end
    end
    -- NPCs from Map.NPCs.Spawns
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
                        if (nHRP.Position - hrp.Position).Magnitude <= range then
                            table.insert(results, npc)
                        end
                    end
                end
            end
        end
    end
    return results
end

-- Get the character name from equipped tools (e.g. "Hanami", "Gojo")
local function GetEquippedCharName()
    local backpack = Player:FindFirstChild("Backpack")
    local char = Player.Character
    -- Check character first (equipped tool), then backpack
    for _, parent in ipairs({char, backpack}) do
        if parent then
            for _, tool in ipairs(parent:GetChildren()) do
                if tool:IsA("Tool") then
                    local n = tool:GetAttribute("CharacterName")
                           or tool:GetAttribute("Character")
                           or tool:GetAttribute("Char")
                    if n then return n end
                end
            end
        end
    end
    return nil
end

-- Get the character name from Player attribute (confirmed by TurtleSpy/decompiled M1Handler)
local function GetActiveCharName()
    return Player:GetAttribute("ActiveCharacter")
end

local killAuraThread = nil
local killAuraCombo = 1
local killAuraMaxCombo = 5  -- updated dynamically if PreloadAnimations fires

-- Track max combo from PreloadAnimations (same as game does)
local PreloadRemote = GetRemote({"Skills", "PreloadAnimations"})
if PreloadRemote then
    PreloadRemote.OnClientEvent:Connect(function(animTable)
        if type(animTable) ~= "table" then return end
        local maxCombo = 0
        for k, _ in pairs(animTable) do
            if string.sub(k, 1, 3) == "M1_" then
                local n = tonumber(string.sub(k, 4, 4))
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
                -- Don't fire if character is Attacking or Stunned (server rejects it)
                if char:GetAttribute("Attacking") or char:GetAttribute("Stunned") then return end
                local targets = GetNearbyCharacters(State.KillAuraRange)
                if #targets == 0 then return end
                -- Fire M1 combo step
                SkillRemote:FireServer(charName, "M1_" .. killAuraCombo)
                -- Advance combo
                if killAuraCombo >= killAuraMaxCombo then
                    killAuraCombo = 1
                else
                    killAuraCombo = killAuraCombo + 1
                end
            end)
            task.wait(0.2)
        end
        killAuraThread = nil
        killAuraCombo = 1
    end)
end

local function StopKillAura()
    State.KillAura = false
    killAuraThread = nil
    killAuraCombo = 1
end

-- ================================================
-- EXTEND HITBOX
-- Safe approach: does NOT use hookmetamethod (breaks other remotes).
-- Instead, after each ReportHits fires normally, we fire a second one
-- with all nearby targets that weren't in the original hit list.
-- We listen to PlaySkillVFX (which fires every hit marker) to know
-- when a hit is happening, then immediately send an expanded ReportHits.
-- ================================================
local extendHitboxConn = nil

local function StartExtendHitbox()
    State.ExtendHitbox = true
    if extendHitboxConn then return end
    local PlaySkillVFXRemote = GetRemote({"Skills", "PlaySkillVFX"})
    if not PlaySkillVFXRemote or not ReportHitsRemote then return end

    -- Listen for VFX hit markers — these fire at the same time as ReportHits
    extendHitboxConn = PlaySkillVFXRemote.OnClientEvent:Connect(function(attackId, marker)
        if not State.ExtendHitbox then return end
        -- Only fire on actual hit markers
        if marker ~= "Hit" and marker ~= "Slash1" and marker ~= "Slash2"
           and marker ~= "Slash3" and marker ~= "Impact" then return end

        local targets = GetNearbyCharacters(State.HitboxSize)
        if #targets == 0 then return end

        local hitList = {}
        for _, char in ipairs(targets) do
            local p = Players:GetPlayerFromCharacter(char)
            table.insert(hitList, {
                characterName = char.Name,
                userId = p and p.UserId or nil,
            })
        end

        -- Fire an extra ReportHits with expanded targets
        local hitKey = tostring(attackId) .. "_hit1"
        pcall(function()
            ReportHitsRemote:FireServer(hitKey, hitList)
        end)
    end)
end

local function StopExtendHitbox()
    State.ExtendHitbox = false
    if extendHitboxConn then
        extendHitboxConn:Disconnect()
        extendHitboxConn = nil
    end
end

-- ================================================
-- ANIM BYPASS — scoped helper (used only by Hollow Purple 200%)
-- Activates animation speedup for ~2s then cleans up completely.
-- Not a global toggle — no persistent Heartbeat, no lingering effects.
-- ================================================
local function FireSkillWithAnimBypass(skillRemote, ...)
    local args = {...}
    local char = Player.Character
    if not char then
        pcall(function() skillRemote:FireServer(table.unpack(args)) end)
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")

    -- Save current movement stats BEFORE skill fires
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

    -- Speed-up heartbeat — runs only while active flag is true
    local hbConn
    hbConn = RunService.Heartbeat:Connect(function()
        if not active then hbConn:Disconnect(); return end
        if not animator then return end
        pcall(function()
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Speed > 0 and track.Speed < 999 then
                    track:AdjustSpeed(999)
                end
            end
        end)
        if hum then
            if hum.WalkSpeed <= 1 then
                if savedStats then
                    hum.WalkSpeed  = savedStats.walkSpeed
                    hum.JumpPower  = savedStats.jumpPower
                    hum.JumpHeight = savedStats.jumpHeight
                end
            end
            if hum.PlatformStand then hum.PlatformStand = false end
        end
    end)

    -- hookfunction approach if executor supports it
    local oldPlay = nil
    local hooked = false
    if hookfunction and newcclosure and animator then
        pcall(function()
            local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://0"
            local ok, dummyTrack = pcall(function() return animator:LoadAnimation(a) end)
            if ok and dummyTrack and dummyTrack.Play then
                oldPlay = hookfunction(dummyTrack.Play, newcclosure(function(self, ...)
                    local r = oldPlay(self, ...)
                    if active then pcall(function() self:AdjustSpeed(999) end) end
                    return r
                end))
                hooked = true
            end
        end)
    end

    -- Fire the actual skill
    pcall(function() skillRemote:FireServer(table.unpack(args)) end)

    -- Cleanup after 2s — stops bypass and restores everything
    task.delay(2, function()
        active = false
        pcall(function() hbConn:Disconnect() end)
        if hooked and oldPlay then
            pcall(function()
                local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://0"
                local ok, dummyTrack = pcall(function() return animator:LoadAnimation(a) end)
                if ok and dummyTrack then
                    hookfunction(dummyTrack.Play, oldPlay)
                end
            end)
        end
        if animator then
            pcall(function()
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    pcall(function() track:Stop(0) end)
                end
            end)
        end
        if hum and savedStats then
            pcall(function()
                hum.WalkSpeed  = savedStats.walkSpeed
                hum.JumpPower  = savedStats.jumpPower
                hum.JumpHeight = savedStats.jumpHeight
                hum.PlatformStand = false
            end)
        end
    end)
end

-- ================================================
-- ZENON RAID SYSTEM
-- Portal area: -481.42, 52.60, -59.99
-- Each difficulty is a child of workspace.Map.ZenonRaidsLoc.ZoneInfo
-- Boss spawner: workspace.Map.Boss.Main.Spawner.Spawner
-- Farm pos: -65.17, -21.19, -160.63 (above spawner)
-- Drops: workspace.Map.Boss.Main.Drops.*
-- ================================================

local RaidHPParagraph = nil  -- set after UI tab is created

local RAID_PORTAL_BASE = Vector3.new(-481.420, 52.603, -59.995)

local RAID_DIFFICULTIES = {
    { name = "Easy (15 Rebirths)",    rebirths = 15,  offset = Vector3.new(0,   0,   0)  },
    { name = "Medium (30 Rebirths)",  rebirths = 30,  offset = Vector3.new(10,  0,   0)  },
    { name = "Hard (50 Rebirths)",    rebirths = 50,  offset = Vector3.new(20,  0,   0)  },
    { name = "Extreme (70 Rebirths)", rebirths = 70,  offset = Vector3.new(30,  0,   0)  },
}

-- Try to find exact portal positions from ZoneInfo
local function GetRaidPortalPos(difficultyIndex)
    local zoneInfo = workspace:FindFirstChild("Map")
    zoneInfo = zoneInfo and zoneInfo:FindFirstChild("ZenonRaidsLoc")
    zoneInfo = zoneInfo and zoneInfo:FindFirstChild("ZoneInfo")
    if zoneInfo then
        local children = zoneInfo:GetChildren()
        local target = children[difficultyIndex]
        if target then
            local part = target:IsA("BasePart") and target
                      or target:FindFirstChildOfClass("BasePart")
            if part then return part.Position + Vector3.new(0, 5, 0) end
        end
    end
    -- Fallback: offset from known portal area
    return RAID_PORTAL_BASE + RAID_DIFFICULTIES[difficultyIndex].offset + Vector3.new(0, 5, 0)
end

local RAID_FARM_POS = Vector3.new(-65.178, -21.197 + 48, -160.639)
local RAID_SPAWNER_POS = Vector3.new(-102.169, -11.037 + 5, -86.828)

local raidFarmThread = nil
local State_RaidFarm = false

-- Collected drop filter (default all on)
local RaidDropFilter = {
    Yen            = true,
    CursedEnergy   = true,
    CursedFinger   = true,
    CharacterRemains = true,
}

-- Drop folder name patterns
local DROP_FOLDER_PATTERNS = {
    Yen              = {"Yen", "yen"},
    CursedEnergy     = {"CursedEnergy", "Cursed Energy", "cursed_energy"},
    CursedFinger     = {"CursedFingers", "CursedFinger", "cursed_finger"},
    CharacterRemains = {"CharacterRemains", "Character Remains"},
}

local function ItemMatchesFilter(itemName)
    for filterKey, enabled in pairs(RaidDropFilter) do
        if not enabled then continue end
        local patterns = DROP_FOLDER_PATTERNS[filterKey]
        if patterns then
            for _, pat in ipairs(patterns) do
                if string.find(itemName, pat, 1, true) then return true end
            end
        end
    end
    return false
end

local function CollectRaidDrops()
    local dropsFolder = workspace:FindFirstChild("Map")
    dropsFolder = dropsFolder and dropsFolder:FindFirstChild("Boss")
    dropsFolder = dropsFolder and dropsFolder:FindFirstChild("Main")
    dropsFolder = dropsFolder and dropsFolder:FindFirstChild("Drops")
    if not dropsFolder then return end

    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Save farm position to return after collecting
    local savedPos = hrp.CFrame

    for _, folder in ipairs(dropsFolder:GetChildren()) do
        if not ItemMatchesFilter(folder.Name) then continue end
        local items = folder:IsA("Folder") and folder:GetChildren() or {folder}
        for _, item in ipairs(items) do
            if not item or not item.Parent then continue end
            local part = item:IsA("BasePart") and item or item:FindFirstChildOfClass("BasePart")
            if not part or not part.Parent then continue end
            local prompt = item:FindFirstChild("Prompt")
                        or (part and part:FindFirstChild("Prompt"))
            -- Also check Prompt.Manager child
            if not prompt then
                for _, child in ipairs(item:GetDescendants()) do
                    if child.Name == "Prompt" and child:IsA("ProximityPrompt") then
                        prompt = child; break
                    end
                end
            end
            pcall(function()
                hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
            end)
            task.wait(0.08)
            if prompt then
                pcall(function() prompt.MaxActivationDistance = math.huge end)
                pcall(function() prompt.HoldDuration = 0 end)
                pcall(function() fireproximityprompt(prompt) end)
            end
            pcall(function()
                firetouchinterest(hrp, part, 0)
                task.wait(0.03)
                firetouchinterest(hrp, part, 1)
            end)
            task.wait(0.05)
        end
    end

    -- Return to farm position
    pcall(function() hrp.CFrame = savedPos end)
end

local function TeleportBossesToSpawner()
    local spawnerPart = workspace:FindFirstChild("Map")
    spawnerPart = spawnerPart and spawnerPart:FindFirstChild("Boss")
    spawnerPart = spawnerPart and spawnerPart:FindFirstChild("Main")
    spawnerPart = spawnerPart and spawnerPart:FindFirstChild("Spawner")
    spawnerPart = spawnerPart and spawnerPart:FindFirstChild("Spawner")
    local targetPos = spawnerPart and spawnerPart.Position or RAID_SPAWNER_POS

    local bossMap = workspace:FindFirstChild("Map")
    bossMap = bossMap and bossMap:FindFirstChild("Boss")
    bossMap = bossMap and bossMap:FindFirstChild("Main")
    local bosses = bossMap and bossMap:FindFirstChild("Bosses")
    if bosses then
        for _, boss in ipairs(bosses:GetChildren()) do
            local bHRP = boss:FindFirstChild("HumanoidRootPart")
            local bHum = boss:FindFirstChildOfClass("Humanoid")
            if bHRP and bHum and bHum.Health > 0 then
                pcall(function()
                    bHRP.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                end)
            end
        end
    end
end

local function StartRaidAutoFarm()
    if raidFarmThread then return end
    State_RaidFarm = true

    -- Enable DumpBoss and Hitbox
    State.DumpBoss = true
    State.ExtendHitbox = true
    State.HitboxSize = 10000
    StartExtendHitbox()

    raidFarmThread = task.spawn(function()
        -- Teleport player to farm position
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function() hrp.CFrame = CFrame.new(RAID_FARM_POS) end)
        end

        -- Watch for boss spawns and teleport them to spawner
        local spawnWatcher = task.spawn(function()
            while State_RaidFarm do
                pcall(TeleportBossesToSpawner)
                task.wait(1)
            end
        end)

        -- HP bar is updated by the global watcher in InfoTab
        -- Auto awakening watcher
        local awakeningCooldown = false
        local hpWatcher = task.spawn(function()
            while State_RaidFarm do
                pcall(function()
                    local char = Player.Character
                    if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local pct = math.floor((hum.Health / hum.MaxHealth) * 100)
                    -- Auto awakening at 20% HP — use cooldown to avoid spam
                    if pct <= 20 and not awakeningCooldown and AwakeningRemote then
                        awakeningCooldown = true
                        _G._RaidSkillPause = true
                        task.wait(0.3)
                        pcall(function() AwakeningRemote:FireServer() end)
                        task.wait(1)
                        _G._RaidSkillPause = false
                        task.delay(10, function() awakeningCooldown = false end)
                    end
                end)
                task.wait(0.5)
            end
        end)

        -- Main farm loop: spam skills at farm pos
        while State_RaidFarm do
            pcall(function()
                -- Re-teleport to farm pos every cycle
                hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function() hrp.CFrame = CFrame.new(RAID_FARM_POS) end)
                end

                local char = Player.Character
                if char then
                    local attacking = char:GetAttribute("Attacking")
                    local stunned   = char:GetAttribute("Stunned")
                    if not attacking and not stunned and not _G._RaidSkillPause then
                        -- Spam all skills
                        local backpack = Player:FindFirstChild("Backpack")
                        if backpack and SkillRemote then
                            for _, tool in ipairs(backpack:GetChildren()) do
                                if not tool:IsA("Tool") then continue end
                                local charName  = tool:GetAttribute("CharacterName")
                                               or tool:GetAttribute("Character")
                                               or tool:GetAttribute("Char")
                                local skillName = tool.Name
                                local skillType = tool:GetAttribute("SkillType")
                                               or tool:GetAttribute("Type")
                                               or tool:GetAttribute("ToolType")
                                if charName and skillType then
                                    pcall(function() SkillRemote:FireServer(charName, skillName, skillType) end)
                                elseif charName then
                                    pcall(function() SkillRemote:FireServer(charName, skillName) end)
                                end
                            end
                        end
                        -- Also M1 via Kill Aura range
                        if SkillRemote then
                            local activeChar = Player:GetAttribute("ActiveCharacter")
                            if activeChar and not (char:GetAttribute("Attacking") or char:GetAttribute("Stunned")) then
                                SkillRemote:FireServer(activeChar, "M1_" .. killAuraCombo)
                                killAuraCombo = (killAuraCombo % killAuraMaxCombo) + 1
                            end
                        end
                    end
                end

                -- DumpBoss
                if State.DumpBoss then
                    pcall(function()
                        local bossMap = workspace:FindFirstChild("Map")
                        bossMap = bossMap and bossMap:FindFirstChild("Boss")
                        bossMap = bossMap and bossMap:FindFirstChild("Main")
                        local bosses = bossMap and bossMap:FindFirstChild("Bosses")
                        if bosses then
                            for _, boss in ipairs(bosses:GetChildren()) do
                                local bHRP = boss:FindFirstChild("HumanoidRootPart")
                                if bHRP then
                                    bHRP.CFrame = CFrame.new(RAID_FARM_POS + Vector3.new(0, -5, 0))
                                end
                            end
                        end
                    end)
                end

                -- Collect drops periodically
                CollectRaidDrops()
            end)
            task.wait(0.1)
        end

        task.cancel(spawnWatcher)
        task.cancel(hpWatcher)
        raidFarmThread = nil
    end)
end

local function StopRaidAutoFarm()
    State_RaidFarm = false
    raidFarmThread = nil
    StopExtendHitbox()
end

-- ================================================
-- RAYFIELD UI
-- ================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
print("[SorcererScript] Rayfield carregado")

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

local BossDropdown = FarmTab:CreateDropdown({
    Name          = "Select Boss",
    Options       = {"Any"},
    CurrentOption = {"Any"},
    Flag          = "BossSelect",
    Callback = function(v)
        selectedBossName = v[1] or "Any"
    end,
})

task.spawn(function()
    task.wait(3)
    local names = GetAllBossNames()
    BossDropdown:Refresh(names, false)
end)

local StatusParagraph = FarmTab:CreateParagraph({
    Title = "Boss Status", Content = "Checking...",
})

task.spawn(function()
    while task.wait(0.5) do
        local boss, bossHum = GetSelectedBoss()
        if boss and bossHum then
            local hp = math.floor(bossHum.Health)
            local mx = math.floor(bossHum.MaxHealth)
            local bossName = CleanBossName(boss.Name)
            StatusParagraph:Set({
                Title   = "● " .. bossName .. " — ALIVE",
                Content = string.format("HP: %d / %d  (%.1f%%)", hp, mx, (hp/mx)*100),
            })
        else
            StatusParagraph:Set({
                Title   = "No boss active",
                Content = selectedBossName == "Any" and "Lac / Shibuya / Metro / WorldBoss" or selectedBossName,
            })
        end
    end
end)

FarmTab:CreateButton({
    Name = "🔄 Refresh Boss List",
    Callback = function()
        local names = GetAllBossNames()
        BossDropdown:Refresh(names, false)
        BossDropdown:Set("Any")
        selectedBossName = "Any"
        Rayfield:Notify({ Title = "✅ Updated", Content = (#names - 1) .. " bosses found.", Duration = 2 })
    end,
})

FarmTab:CreateButton({
    Name = "Teleport to Boss",
    Callback = function()
        local _, _, bossHRP = GetSelectedBoss()
        if bossHRP then
            TeleportToBossPos(bossHRP)
            Rayfield:Notify({ Title = "✅ Teleported", Content = "You are at the Boss.", Duration = 2 })
        else
            Rayfield:Notify({ Title = "❌ Boss not found", Content = "Wait for boss to spawn.", Duration = 3 })
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
    Name = "God Mode (Instant Respawn)", CurrentValue = false, Flag = "GodMode",
    Callback = function(v)
        if v then StartGodMode() else StopGodMode() end
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
    Name = "Auto Collect Boss Drops", CurrentValue = false, Flag = "AutoCollectDrops",
    Callback = function(v)
        State.AutoCollectDrops = v
        if v then StartAutoCollectDrops() end
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Upgrade Tycoon", CurrentValue = false, Flag = "AutoUpgrade",
    Callback = function(v)
        if v then
            if not CurrentTycoon then DetectMyTycoonIfNeeded() end
            StartAutoUpgrade()
        else
            StopAutoUpgrade()
        end
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Rebirth", CurrentValue = false,
    Callback = function(v) State.AutoRebirth = v end,
})

FarmTab:CreateSection("⚔️ Combat")

FarmTab:CreateToggle({
    Name = "Kill Aura", CurrentValue = false, Flag = "KillAura",
    Callback = function(v)
        if v then StartKillAura() else StopKillAura() end
    end,
})

FarmTab:CreateSlider({
    Name = "Kill Aura Range", Range = {5, 50000}, Increment = 10,
    Suffix = "studs", CurrentValue = 60, Flag = "KillAuraRange",
    Callback = function(v)
        State.KillAuraRange = v
    end,
})

FarmTab:CreateToggle({
    Name = "Extend Hitbox", CurrentValue = false, Flag = "ExtendHitbox",
    Callback = function(v)
        if v then StartExtendHitbox() else StopExtendHitbox() end
    end,
})

FarmTab:CreateSlider({
    Name = "Hitbox Size", Range = {10, 50000}, Increment = 10,
    Suffix = "studs", CurrentValue = 30, Flag = "HitboxSize",
    Callback = function(v)
        State.HitboxSize = v
    end,
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
        if SkillRemote then pcall(function() SkillRemote:FireServer("Jogo", "Coffin of the Iron Mountain") end) end
        Rayfield:Notify({ Title = "Jogo", Content = "Coffin of the Iron Mountain", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Gojo Domain Expansion",
    Callback = function()
        if SkillRemote then pcall(function() SkillRemote:FireServer("Gojo", "Unlimited Void") end) end
        Rayfield:Notify({ Title = "Gojo", Content = "Unlimited Void", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Nanami Domain Expansion",
    Callback = function()
        if SkillRemote then pcall(function() SkillRemote:FireServer("Nanami", "Overtime: Ratio Collapse") end) end
        Rayfield:Notify({ Title = "Nanami", Content = "Overtime: Ratio Collapse", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Toji Domain Expansion",
    Callback = function()
        if SkillRemote then pcall(function() SkillRemote:FireServer("Toji", "Heavenly Restriction: Complete") end) end
        Rayfield:Notify({ Title = "Toji", Content = "Heavenly Restriction: Complete", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Megumi Domain Expansion",
    Callback = function()
        if SkillRemote then pcall(function() SkillRemote:FireServer("Megumi", "Chimera Shadow Garden") end) end
        Rayfield:Notify({ Title = "Megumi", Content = "Chimera Shadow Garden", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Yuji Domain Expansion",
    Callback = function()
        if SkillRemote then pcall(function() SkillRemote:FireServer("Yuji", "Memory of Soul") end) end
        Rayfield:Notify({ Title = "Yuji", Content = "Memory of Soul", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Hanami Domain Expansion",
    Callback = function()
        if SkillRemote then pcall(function() SkillRemote:FireServer("Hanami", "Garden of Earthly Delights") end) end
        Rayfield:Notify({ Title = "Hanami", Content = "Garden of Earthly Delights", Duration = 2 })
    end,
})
SkillTab:CreateParagraph({
    Title   = "Innate Techniques",
    Content = "Character Innate Techniques. You need unlock all First",
})

SkillTab:CreateButton({
    Name = "Cursed Barrier",
    Callback = function()
        if not EquipTechRemote or not SkillRemote then
            Rayfield:Notify({ Title = "❌ Error", Content = "Remote not found.", Duration = 3 })
            return
        end
        task.spawn(function()
            pcall(function() EquipTechRemote:FireServer("Reverse Cursed Technique", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Minor Reverse Flow", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Simple Domain", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Cursed Barrier", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Cursed Barrier", false) end)
            task.wait(0.02)
            pcall(function() SkillRemote:FireServer("Cursed Barrier", "Cursed Barrier", "InnateTechnique") end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Cursed Barrier", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Reverse Cursed Technique", false) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Simple Domain", false) end)
            Rayfield:Notify({ Title = "Cursed Barrier", Content = "Executed.", Duration = 2 })
        end)
    end,
})

SkillTab:CreateButton({
    Name = "Minor Reverse Flow",
    Callback = function()
        if not EquipTechRemote or not SkillRemote then
            Rayfield:Notify({ Title = "❌ Error", Content = "Remote not found.", Duration = 3 })
            return
        end
        task.spawn(function()
            pcall(function() EquipTechRemote:FireServer("Reverse Cursed Technique", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Minor Reverse Flow", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Simple Domain", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Cursed Barrier", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Minor Reverse Flow", false) end)
            task.wait(0.02)
            pcall(function() SkillRemote:FireServer("Minor Reverse Flow", "Minor Reverse Flow", "InnateTechnique") end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Minor Reverse Flow", true) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Reverse Cursed Technique", false) end)
            task.wait(0.02)
            pcall(function() EquipTechRemote:FireServer("Simple Domain", false) end)
            Rayfield:Notify({ Title = "Minor Reverse Flow", Content = "Executed.", Duration = 2 })
        end)
    end,
})

SkillTab:CreateButton({
    Name = "Gojo Mugen",
    Callback = function()
        if SkillRemote then pcall(function() SkillRemote:FireServer("Gojo", "Infinity") end) end
        Rayfield:Notify({ Title = "Gojo", Content = "Infinity", Duration = 2 })
    end,
})

SkillTab:CreateButton({
    Name = "Hollow Purple 200%",
    Callback = function()
        if SkillRemote then
            FireSkillWithAnimBypass(SkillRemote, "Gojo", "Hollow Purple")
        end
        Rayfield:Notify({ Title = "Gojo", Content = "Hollow Purple 200%", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Red",
    Callback = function()
        if SkillRemote then
            FireSkillWithAnimBypass(SkillRemote, "Gojo", "Red")
        end
        Rayfield:Notify({ Title = "Gojo", Content = "Red", Duration = 2 })
    end,
})
SkillTab:CreateButton({
    Name = "Lapse Blue",
    Callback = function()
        if SkillRemote then
            FireSkillWithAnimBypass(SkillRemote, "Gojo", "Lapse Blue")
        end
        Rayfield:Notify({ Title = "Gojo", Content = "Lapse Blue", Duration = 2 })
    end,
})
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
-- TAB: TELEPORT
-- ================================================
local TpTab = Window:CreateTab("🔀 Teleport", 4483362458)

local tpSelected = ""

local function GetOtherPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then table.insert(list, p.Name) end
    end
    if #list == 0 then list = {"(no players)"} end
    return list
end

-- ---- Players Teleport ----
TpTab:CreateSection("👥 Players Teleport")

local TpDropdown = TpTab:CreateDropdown({
    Name    = "Select Player",
    Options = GetOtherPlayers(),
    CurrentOption = {"(no players)"},
    Flag    = "TpDropdown",
    Callback = function(selected)
        tpSelected = selected[1] or ""
    end,
})

TpTab:CreateButton({
    Name = "🔄 Update Player List",
    Callback = function()
        local list = GetOtherPlayers()
        TpDropdown:Set(list[1] or "(no players)")
        TpDropdown:Refresh(list, false)
        tpSelected = list[1] or ""
        Rayfield:Notify({
            Title = "✅ Updated",
            Content = (#list == 1 and list[1] == "(no players)") and "No players found." or (#list .. " players found."),
            Duration = 2,
        })
    end,
})

TpTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if tpSelected == "" or tpSelected == "(no players)" then
            Rayfield:Notify({ Title = "⚠️ No player selected", Content = "Select a player first.", Duration = 2 })
            return
        end
        local target = Players:FindFirstChild(tpSelected)
        if target and target.Character then
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            local HRP = GetHRP()
            if tHRP and HRP then
                HRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
                Rayfield:Notify({ Title = "✅ Teleported", Content = "→ " .. tpSelected, Duration = 2 })
                return
            end
        end
        Rayfield:Notify({ Title = "❌ " .. tpSelected, Content = "Character not found.", Duration = 2 })
    end,
})

task.spawn(function()
    task.wait(2)
    local list = GetOtherPlayers()
    TpDropdown:Refresh(list, false)
    tpSelected = list[1] or ""
end)

-- ---- My Tycoon Teleport ----
TpTab:CreateSection("🏯 My Tycoon")

TpTab:CreateButton({
    Name = "→ Teleport to Your Tycoon",
    Callback = function()
        local HRP = GetHRP()
        if not HRP then
            Rayfield:Notify({ Title = "❌ Error", Content = "Character not found.", Duration = 3 })
            return
        end

        -- Garante que a tycoon foi detectada
        if not CurrentTycoon then
            DetectMyTycoon()
        end

        if not CurrentTycoon then
            Rayfield:Notify({
                Title   = "❌ Tycoon not found",
                Content = "Claim a Tycoon first or use Re-detect in the Info tab.",
                Duration = 4,
            })
            return
        end

        local myTycoon = workspace:FindFirstChild("Map")
        myTycoon = myTycoon and myTycoon:FindFirstChild("Tycoons")
        myTycoon = myTycoon and myTycoon:FindFirstChild(CurrentTycoon)

        if not myTycoon or not myTycoon.Parent then
            CurrentTycoon = nil
            Rayfield:Notify({
                Title   = "❌ Tycoon not in workspace",
                Content = "Could not locate your Tycoon in the map.",
                Duration = 3,
            })
            return
        end

        -- Tenta achar um BasePart de referência dentro da tycoon para teleportar
        local targetPart = myTycoon:FindFirstChildOfClass("BasePart")
            or myTycoon:FindFirstChild("Base") and myTycoon.Base:FindFirstChildOfClass("BasePart")
            or myTycoon:FindFirstChildWhichIsA("BasePart", true)

        local teleportPos
        if targetPart then
            teleportPos = targetPart.Position + Vector3.new(0, 6, 0)
        else
            -- Fallback: usa o PrimaryPart ou pivot do model
            local pivot = pcall(function() return myTycoon:GetPivot() end) and myTycoon:GetPivot()
            if pivot then
                teleportPos = pivot.Position + Vector3.new(0, 6, 0)
            end
        end

        if teleportPos then
            HRP.CFrame = CFrame.new(teleportPos)
            local charName = CurrentTycoon:gsub("^Tycoon", "")
            Rayfield:Notify({
                Title   = "✅ Teleported",
                Content = "→ Tycoon " .. charName,
                Duration = 2,
            })
        else
            Rayfield:Notify({
                Title   = "❌ Could not teleport",
                Content = "No valid position found in your Tycoon.",
                Duration = 3,
            })
        end
    end,
})

-- ---- Shops Teleport ----
-- Posições confirmadas via Template.Position no DEX
-- InnateTechniques: -277.799, 16.251, 238.113 (confirmado pelo usuário)
-- Restantes: detectados via Template BasePart dinamicamente
TpTab:CreateSection("🏪 Shops Teleport")

local ShopTeleports = {
    { name = "Innate Techniques", pos = Vector3.new(-277.799, 16.251, 238.113) },
    { name = "Limit Breaker",     pos = Vector3.new(-213.388, 8.620,  256.251) },
    { name = "Swords",            pos = Vector3.new(-174.075, 16.302, 195.120) },
    { name = "Titles",            pos = Vector3.new(-211.653, 15.462, 97.970)  },
    { name = "Clans",             pos = Vector3.new(-273.691, 4.698,  131.744) },
    { name = "Merchant",          pos = Vector3.new(-396.008, 9.684,  140.902) },
}

local function GetShopPos(shop)
    return shop.pos
end

for _, shop in ipairs(ShopTeleports) do
    local shopRef = shop
    TpTab:CreateButton({
        Name = "→ " .. shopRef.name,
        Callback = function()
            local HRP = GetHRP()
            if not HRP then return end
            local pos = GetShopPos(shopRef)
            if pos then
                HRP.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                Rayfield:Notify({ Title = "✅ " .. shopRef.name, Content = "Teleported.", Duration = 2 })
            else
                Rayfield:Notify({ Title = "❌ " .. shopRef.name, Content = "Shop not found.", Duration = 2 })
            end
        end,
    })
end

-- ---- Boss Spawns NPC ----
TpTab:CreateSection("👾 Boss Spawns NPC")

local BossSpawnTeleports = {
    { name = "Lake",    pos = Vector3.new(426.629,   19.016, -435.469) },
    { name = "Shibuya", pos = Vector3.new(-1816.1075439453125, 44.559661865234375, -381.15045166015625) },
}

-- Tenta pegar posição dinâmica do Template, fallback para hardcoded
local function GetBossSpawnPos(zoneName, fallback)
    local obj = workspace:FindFirstChild("Map")
    obj = obj and obj:FindFirstChild("Shops")
    obj = obj and obj:FindFirstChild("BossSpawns")
    obj = obj and obj:FindFirstChild(zoneName)
    if obj then
        local template = obj:FindFirstChild("Template")
        local part = template and (template:IsA("BasePart") and template or template:FindFirstChildOfClass("BasePart"))
                  or obj:FindFirstChildOfClass("BasePart")
        if part then return part.Position end
    end
    return fallback
end

for _, spawn in ipairs(BossSpawnTeleports) do
    local spawnRef = spawn
    TpTab:CreateButton({
        Name = "→ " .. spawnRef.name .. " Boss Spawn",
        Callback = function()
            local HRP = GetHRP()
            if not HRP then return end
            local pos = GetBossSpawnPos(spawnRef.name, spawnRef.pos)
            HRP.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            Rayfield:Notify({ Title = "✅ " .. spawnRef.name, Content = "Teleported to Boss Spawn NPC.", Duration = 2 })
        end,
    })
end

TpTab:CreateSection("🌀 Shibuya Portal")
TpTab:CreateButton({
    Name = "Shibuya Portal Entry",
    Callback = function()
        local HRP = GetHRP()
        if not HRP then return end
        HRP.CFrame = CFrame.new(SHIBUYA_PORTAL_ENTRY + Vector3.new(0, 5, 0))
        Rayfield:Notify({ Title = "✅ Shibuya", Content = "Teleported to Shibuya Portal Entry.", Duration = 2 })
    end,
})
TpTab:CreateButton({
    Name = "Shibuya Portal Outside",
    Callback = function()
        local HRP = GetHRP()
        if not HRP then return end
        HRP.CFrame = CFrame.new(SHIBUYA_PORTAL_EXIT + Vector3.new(0, 5, 0))
        Rayfield:Notify({ Title = "✅ Shibuya", Content = "Teleported outside Shibuya.", Duration = 2 })
    end,
})
-- ================================================
-- TAB: ZENON RAID
-- ================================================
local RaidTab = Window:CreateTab("⚔️ Raid", 4483362458)

RaidTab:CreateSection("🌀 Teleport")

RaidTab:CreateButton({
    Name = "Teleport to Zenon Raid",
    Callback = function()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        pcall(function() hrp.CFrame = CFrame.new(RAID_PORTAL_BASE + Vector3.new(0, 5, 0)) end)
        Rayfield:Notify({ Title = "⚔️ Zenon Raid", Content = "Teleported to Raid.", Duration = 2 })
    end,
})

RaidTab:CreateSection("❤️ HP")

RaidHPParagraph = RaidTab:CreateParagraph({
    Title   = "❤️ Health Bar",
    Content = "loading...",
})

-- Always-on HP bar, visible regardless of farm state
-- task.defer so RaidHPParagraph is guaranteed assigned before first tick
task.defer(function()
    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                local char = Player.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                local pct = math.floor((hum.Health / hum.MaxHealth) * 100)
                local filled = math.floor(pct / 5)
                local bar = string.rep("█", filled) .. string.rep("░", 20 - filled)
                RaidHPParagraph:Set({
                    Title   = "❤️ Health Bar",
                    Content = string.format("[%s] %d%%  %d / %d", bar, pct,
                        math.floor(hum.Health), math.floor(hum.MaxHealth)),
                })
            end)
        end
    end)
end)

RaidTab:CreateSection("🤖 Auto Farm Raid")

RaidTab:CreateToggle({
    Name = "Auto Farm Raid", CurrentValue = false, Flag = "RaidAutoFarm",
    Callback = function(v)
        if v then
            StartRaidAutoFarm()
            Rayfield:Notify({ Title = "⚔️ Raid Farm ON", Content = "Teleport and farming bosses.", Duration = 3 })
        else
            StopRaidAutoFarm()
            Rayfield:Notify({ Title = "⛔ Raid Farm OFF", Content = "Farm paused.", Duration = 2 })
        end
    end,
})

RaidTab:CreateSection("Auto Collect")

RaidTab:CreateToggle({
    Name = "Yen", CurrentValue = true, Flag = "RaidDropYen",
    Callback = function(v) RaidDropFilter.Yen = v end,
})

RaidTab:CreateToggle({
    Name = "Cursed Energy", CurrentValue = true, Flag = "RaidDropCE",
    Callback = function(v) RaidDropFilter.CursedEnergy = v end,
})

RaidTab:CreateToggle({
    Name = "Cursed Finger", CurrentValue = true, Flag = "RaidDropCF",
    Callback = function(v) RaidDropFilter.CursedFinger = v end,
})

RaidTab:CreateToggle({
    Name = "Character Remains", CurrentValue = true, Flag = "RaidDropCR",
    Callback = function(v) RaidDropFilter.CharacterRemains = v end,
})

-- ================================================
-- TAB: INFO
-- ================================================
local InfoTab = Window:CreateTab("ℹ Info", 4483362458)

TycoonParagraph = InfoTab:CreateParagraph({
    Title   = "🏯 My Tycoon",
    Content = "Detectig...",
})

task.spawn(function()
    task.wait(3)
    DetectMyTycoon()
    local display = CurrentTycoon and CurrentTycoon:gsub("^Tycoon","") or "Nothing"
    TycoonParagraph:Set({ Title = "🏯 My Tycoon", Content = display })
    HookClaimRemote()
end)

InfoTab:CreateButton({
    Name = "🔄 Re-detect Tycoon",
    Callback = function()
        CurrentTycoon = nil
        DetectMyTycoon()
        local display = CurrentTycoon and CurrentTycoon:gsub("^Tycoon","") or "Nothing"
        TycoonParagraph:Set({ Title = "🏯 My Tycoon", Content = display })
        Rayfield:Notify({ Title = "🏯 Tycoon", Content = display, Duration = 3 })
    end,
})

InfoTab:CreateButton({
    Name = "🏠 Claim detected tycoon",
    Callback = function()
        if not CurrentTycoon then DetectMyTycoonIfNeeded() end
        if not CurrentTycoon then
            Rayfield:Notify({ Title = "❌ Tycoon Not Detected", Content = "Use Re-detect", Duration = 3 })
            return
        end
        local charName = CurrentTycoon:gsub("^Tycoon", "")
        if ClaimRemote then
            local ok, err = pcall(function() ClaimRemote:FireServer(charName) end)
            if ok then
                Rayfield:Notify({ Title = "✅ Done", Content = charName, Duration = 3 })
            else
                Rayfield:Notify({ Title = "❌ Error", Content = tostring(err), Duration = 4 })
            end
        else
            Rayfield:Notify({ Title = "❌ No found", Content = "Tycoon.Claim", Duration = 3 })
        end
    end,
})

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

local antiAfkConn = nil
InfoTab:CreateToggle({
    Name = "Anti AFK", CurrentValue = false, Flag = "AntiAfk",
    Callback = function(v)
        if v then
            antiAfkConn = RunService.Heartbeat:Connect(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.S, false, game)
                vim:SendKeyEvent(false, Enum.KeyCode.S, false, game)
            end)
        else
            if antiAfkConn then
                antiAfkConn:Disconnect()
                antiAfkConn = nil
            end
        end
    end,
})

InfoTab:CreateToggle({
    Name = "Bypass Name", CurrentValue = false, Flag = "BypassName",
    Callback = function(v)
        task.spawn(function()
            while v do
                pcall(function()
                    local chars = workspace:FindFirstChild("Characters")
                    local charFolder = chars and chars:FindFirstChild(Player.Name)
                    local head = charFolder and charFolder:FindFirstChild("Head")
                    if not head then return end
                    local healthGui = head:FindFirstChild("HealthGui")
                                   or head:FindFirstChild("HealthGUI")
                    local nameLabel = healthGui and healthGui:FindFirstChild("CharacterName")
                    if nameLabel then
                        local clanDisplay = charFolder and charFolder:GetAttribute("EquippedClanDisplayName")
                        if clanDisplay then
                            nameLabel.Text = string.format("Not Found - %s", clanDisplay)
                        else
                            nameLabel.Text = "Not Found"
                        end
                    end
                end)
                task.wait(0.5)
            end
            pcall(function()
                local chars = workspace:FindFirstChild("Characters")
                local charFolder = chars and chars:FindFirstChild(Player.Name)
                local head = charFolder and charFolder:FindFirstChild("Head")
                if not head then return end
                local healthGui = head:FindFirstChild("HealthGui")
                               or head:FindFirstChild("HealthGUI")
                local nameLabel = healthGui and healthGui:FindFirstChild("CharacterName")
                if nameLabel then
                    local clanDisplay = charFolder and charFolder:GetAttribute("EquippedClanDisplayName")
                    if clanDisplay then
                        nameLabel.Text = string.format("%s - %s", Player.Name, clanDisplay)
                    else
                        nameLabel.Text = Player.Name
                    end
                end
            end)
        end)
    end,
})

-- ================================================
Rayfield:LoadConfiguration()
print("[Sorcerer Scripts v14] Loaded!")
