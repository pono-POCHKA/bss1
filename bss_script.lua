-- ================================================
--         BEE SWARM SIMULATOR - AUTO FARM
--              by Claude | github ready
-- ================================================

local Config = {
    Farm        = true,
    AutoConvert = true,
    TargetField = "Sunflower Field",

    CollectDelay = 0.1,
    ConvertDelay = 1.0,
    LoopDelay    = 0.1,
    RespawnWait  = 3.0,
}

-- ============ СЕРВИСЫ ============
local Players  = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root      = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(c)
    character = c
    root      = c:WaitForChild("HumanoidRootPart")
    humanoid  = c:WaitForChild("Humanoid")
    print("[BSS] Персонаж обновлён.")
end)

-- ============ УТИЛИТЫ ============
local function isAlive()
    return character
        and character.Parent
        and humanoid
        and humanoid.Health > 0
end

local function teleport(cf)
    if root then root.CFrame = cf end
end

local function findDescendant(parent, name)
    for _, v in pairs(parent:GetDescendants()) do
        if v.Name == name then return v end
    end
    return nil
end

-- ============ СБОР ПЫЛЬЦЫ ============
local function collectPollen()
    if not isAlive() then return end

    local fieldsFolder = Workspace:FindFirstChild("Fields")
    if not fieldsFolder then
        warn("[Farm] Папка Fields не найдена в Workspace.")
        return
    end

    local field = fieldsFolder:FindFirstChild(Config.TargetField)
    if not field then
        warn("[Farm] Поле '" .. Config.TargetField .. "' не найдено.")
        return
    end

    local parts = {}
    for _, obj in pairs(field:GetDescendants()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        end
    end

    if #parts == 0 then
        warn("[Farm] Объекты в поле не найдены.")
        return
    end

    print("[Farm] Сбор пыльцы... Объектов: " .. #parts)

    for _, part in ipairs(parts) do
        if not Config.Farm or not isAlive() then break end
        teleport(part.CFrame * CFrame.new(0, 3, 0))
        task.wait(Config.CollectDelay)
    end

    print("[Farm] Сбор завершён.")
end

-- ============ КОНВЕРТАЦИЯ В МЁД ============
local function convertToHoney()
    if not Config.AutoConvert then return end
    if not isAlive() then return end

    local hive = Workspace:FindFirstChild("Hive")
        or findDescendant(Workspace, "Hive")

    if not hive then
        warn("[Convert] Улей не найден.")
        return
    end

    local part = hive:IsA("BasePart") and hive
        or hive:FindFirstChildWhichIsA("BasePart")

    if part then
        teleport(part.CFrame * CFrame.new(0, 3, 0))
        task.wait(Config.ConvertDelay)
        print("[Convert] Мёд получен.")
    else
        warn("[Convert] BasePart улья не найден.")
    end
end

-- ============ ОСНОВНОЙ ЦИКЛ ============
task.spawn(function()
    print("==============================")
    print("  BSS Auto Farm | Загружен   ")
    print("  Поле: " .. Config.TargetField)
    print("  /farm on|off  /field <name>")
    print("==============================")

    while true do
        task.wait(Config.LoopDelay)

        if not Config.Farm then
            task.wait(0.5)
            continue
        end

        if not isAlive() then
            print("[BSS] Ожидание респауна...")
            task.wait(Config.RespawnWait)
            continue
        end

        collectPollen()
        convertToHoney()
    end
end)

-- ============ ЧАТ КОМАНДЫ ============
player.Chatted:Connect(function(msg)
    local cmd = msg:lower()

    if cmd == "/farm on" then
        Config.Farm = true
        print("[CMD] Фарм включён")

    elseif cmd == "/farm off" then
        Config.Farm = false
        print("[CMD] Фарм выключен")

    elseif cmd:sub(1, 7) == "/field " then
        local name = msg:sub(8)
        Config.TargetField = name
        print("[CMD] Поле изменено: " .. name)

    elseif cmd == "/sunflower" then
        Config.TargetField = "Sunflower Field"
        print("[CMD] Поле: Sunflower Field")

    elseif cmd == "/dandelion" then
        Config.TargetField = "Dandelion Field"
        print("[CMD] Поле: Dandelion Field")

    elseif cmd == "/mushroom" then
        Config.TargetField = "Mushroom Field"
        print("[CMD] Поле: Mushroom Field")

    elseif cmd == "/clover" then
        Config.TargetField = "Clover Field"
        print("[CMD] Поле: Clover Field")

    elseif cmd == "/blue" then
        Config.TargetField = "Blue Flower Field"
        print("[CMD] Поле: Blue Flower Field")

    elseif cmd == "/spider" then
        Config.TargetField = "Spider Field"
        print("[CMD] Поле: Spider Field")

    elseif cmd == "/status" then
        print(string.format(
            "[Status] Farm=%s | Field=%s | Convert=%s",
            tostring(Config.Farm),
            Config.TargetField,
            tostring(Config.AutoConvert)
        ))
    end
end)
