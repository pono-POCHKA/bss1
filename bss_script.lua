-- ================================================
--         BEE SWARM SIMULATOR - AUTO FARM
--              by pono-POCHKA | fixed v2
-- ================================================

local Config = {
    Farm        = true,
    AutoConvert = true,
    TargetField = "Sunflower Field",

    CollectDelay = 0.3,   -- было 0.1 → лаги. 0.3 оптимально
    ConvertDelay = 1.5,
    LoopDelay    = 1.0,   -- было 0.1 → лаги. Главный цикл раз в секунду
    RespawnWait  = 3.0,
    MaxPartsPerRound = 30, -- телепортируемся не ко всем частям, а к 30 крайним
}

-- ============ СЕРВИСЫ ============
local Players   = game:GetService("Players")
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

-- Ищет объект по имени по всему Workspace рекурсивно
local function deepFind(parent, name)
    for _, v in pairs(parent:GetDescendants()) do
        if v.Name == name then return v end
    end
    return nil
end

-- Ищет поле по нескольким возможным путям (BSS меняет структуру)
local function findField(fieldName)
    -- Вариант 1: Workspace.Fields.FieldName
    local f1 = Workspace:FindFirstChild("Fields")
    if f1 then
        local field = f1:FindFirstChild(fieldName)
        if field then return field end
    end

    -- Вариант 2: Workspace.Map.Fields.FieldName
    local map = Workspace:FindFirstChild("Map")
    if map then
        local f2 = map:FindFirstChild("Fields")
        if f2 then
            local field = f2:FindFirstChild(fieldName)
            if field then return field end
        end
    end

    -- Вариант 3: Поиск по всему Workspace
    return deepFind(Workspace, fieldName)
end

-- Ищет улей
local function findHive()
    -- Прямой путь
    local h = Workspace:FindFirstChild("Hive")
    if h then return h end

    -- Через Map
    local map = Workspace:FindFirstChild("Map")
    if map then
        local h2 = map:FindFirstChild("Hive")
        if h2 then return h2 end
    end

    -- Глубокий поиск
    return deepFind(Workspace, "Hive")
end

-- ============ СБОР ПЫЛЬЦЫ ============
local function collectPollen()
    if not isAlive() then return end

    local field = findField(Config.TargetField)
    if not field then
        warn("[Farm] Поле '" .. Config.TargetField .. "' не найдено. Проверь название!")
        return
    end

    -- Собираем только BasePart (не Model, не Script и т.д.)
    local parts = {}
    for _, obj in pairs(field:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Hitbox" then
            table.insert(parts, obj)
        end
    end

    if #parts == 0 then
        warn("[Farm] В поле нет объектов.")
        return
    end

    -- Ограничиваем количество телепортаций чтобы не лагало
    local limit = math.min(#parts, Config.MaxPartsPerRound)
    print("[Farm] Сбор пыльцы... Точек: " .. limit .. " из " .. #parts)

    for i = 1, limit do
        if not Config.Farm or not isAlive() then break end
        local part = parts[i]
        teleport(part.CFrame * CFrame.new(0, 3, 0))
        task.wait(Config.CollectDelay)
    end

    print("[Farm] Сбор завершён.")
end

-- ============ КОНВЕРТАЦИЯ В МЁД ============
local function convertToHoney()
    if not Config.AutoConvert then return end
    if not isAlive() then return end

    local hive = findHive()
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
    print("=========================================")
    print("  BSS Auto Farm | Fixed v2               ")
    print("  Поле: " .. Config.TargetField)
    print("  Команды в чате:                        ")
    print("    /farm on|off   /convert on|off        ")
    print("    /field <name>  /status                ")
    print("    /sunflower  /dandelion  /mushroom      ")
    print("    /clover  /blue  /spider  /bamboo       ")
    print("    /speed <число>  (задержка сбора)      ")
    print("=========================================")

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

    elseif cmd == "/convert on" then
        Config.AutoConvert = true
        print("[CMD] Конвертация включена")

    elseif cmd == "/convert off" then
        Config.AutoConvert = false
        print("[CMD] Конвертация выключена")

    elseif cmd:sub(1, 7) == "/field " then
        local name = msg:sub(8)
        Config.TargetField = name
        print("[CMD] Поле изменено: " .. name)

    elseif cmd:sub(1, 7) == "/speed " then
        local val = tonumber(msg:sub(8))
        if val and val > 0 then
            Config.CollectDelay = val
            print("[CMD] Задержка сбора: " .. val .. " сек")
        end

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

    elseif cmd == "/bamboo" then
        Config.TargetField = "Bamboo Field"
        print("[CMD] Поле: Bamboo Field")

    elseif cmd == "/status" then
        print(string.format(
            "[Status] Farm=%s | Field=%s | Convert=%s | Delay=%.2f",
            tostring(Config.Farm),
            Config.TargetField,
            tostring(Config.AutoConvert),
            Config.CollectDelay
        ))
    end
end)
