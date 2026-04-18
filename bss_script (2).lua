-- ================================================
--         BEE SWARM SIMULATOR - AUTO FARM
--              by pono-POCHKA | GUI v3
-- ================================================

local Config = {
    Farm        = true,
    AutoConvert = true,
    TargetField = "Sunflower Field",

    CollectDelay     = 0.3,
    ConvertDelay     = 1.5,
    LoopDelay        = 1.0,
    RespawnWait      = 3.0,
    MaxPartsPerRound = 30,
}

-- ============ СЕРВИСЫ ============
local Players       = game:GetService("Players")
local Workspace     = game:GetService("Workspace")
local TweenService  = game:GetService("TweenService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root      = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(c)
    character = c
    root      = c:WaitForChild("HumanoidRootPart")
    humanoid  = c:WaitForChild("Humanoid")
end)

-- ============ УТИЛИТЫ ============
local function isAlive()
    return character and character.Parent and humanoid and humanoid.Health > 0
end

local function teleport(cf)
    if root then root.CFrame = cf end
end

local function deepFind(parent, name)
    for _, v in pairs(parent:GetDescendants()) do
        if v.Name == name then return v end
    end
    return nil
end

local function findField(fieldName)
    local f1 = Workspace:FindFirstChild("Fields")
    if f1 then
        local field = f1:FindFirstChild(fieldName)
        if field then return field end
    end
    local map = Workspace:FindFirstChild("Map")
    if map then
        local f2 = map:FindFirstChild("Fields")
        if f2 then
            local field = f2:FindFirstChild(fieldName)
            if field then return field end
        end
    end
    return deepFind(Workspace, fieldName)
end

local function findHive()
    local h = Workspace:FindFirstChild("Hive")
    if h then return h end
    local map = Workspace:FindFirstChild("Map")
    if map then
        local h2 = map:FindFirstChild("Hive")
        if h2 then return h2 end
    end
    return deepFind(Workspace, "Hive")
end

-- ============ GUI ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BSSFarmGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- Главный фрейм
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 220, 0, 310)
main.Position = UDim2.new(0, 16, 0.5, -155)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

-- Тень
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5028857084"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(24, 24, 276, 276)
shadow.ZIndex = 0
shadow.Parent = main

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🍯 BSS AUTO FARM"
titleLabel.TextColor3 = Color3.fromRGB(30, 20, 0)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Контейнер
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -54)
content.Position = UDim2.new(0, 10, 0, 50)
content.BackgroundTransparency = 1
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = content

-- Текущее поле
local fieldLabel = Instance.new("TextLabel")
fieldLabel.Size = UDim2.new(1, 0, 0, 22)
fieldLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
fieldLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
fieldLabel.TextSize = 11
fieldLabel.Font = Enum.Font.Gotham
fieldLabel.Text = "🌻 " .. Config.TargetField
fieldLabel.LayoutOrder = 0
fieldLabel.Parent = content
Instance.new("UICorner", fieldLabel).CornerRadius = UDim.new(0, 6)

-- Toggle кнопка
local function makeToggle(text, initState, order, callback)
    local state = initState
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = state and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(40, 40, 55)
    btn.TextColor3 = state and Color3.fromRGB(30, 20, 0) or Color3.fromRGB(180, 180, 200)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Text = text .. (state and "  ✓ ВКЛ" or "  ✗ ВЫКЛ")
    btn.LayoutOrder = order
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        state = not state
        local col  = state and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(40, 40, 55)
        local tcol = state and Color3.fromRGB(30, 20, 0) or Color3.fromRGB(180, 180, 200)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = col, TextColor3 = tcol}):Play()
        btn.Text = text .. (state and "  ✓ ВКЛ" or "  ✗ ВЫКЛ")
        callback(state)
    end)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = state and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(55, 55, 75)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = state and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(40, 40, 55)
        }):Play()
    end)
end

makeToggle("🐝 ФАРМ", Config.Farm, 1, function(v) Config.Farm = v end)
makeToggle("🍯 КОНВЕРТАЦИЯ", Config.AutoConvert, 2, function(v) Config.AutoConvert = v end)

-- Разделитель
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, 0, 0, 1)
sep.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
sep.BorderSizePixel = 0
sep.LayoutOrder = 3
sep.Parent = content

-- Подпись
local flabel = Instance.new("TextLabel")
flabel.Size = UDim2.new(1, 0, 0, 16)
flabel.BackgroundTransparency = 1
flabel.Text = "ВЫБОР ПОЛЯ"
flabel.TextColor3 = Color3.fromRGB(120, 120, 150)
flabel.TextSize = 10
flabel.Font = Enum.Font.GothamBold
flabel.LayoutOrder = 4
flabel.Parent = content

-- Сетка полей
local gridFrame = Instance.new("Frame")
gridFrame.Size = UDim2.new(1, 0, 0, 72)
gridFrame.BackgroundTransparency = 1
gridFrame.LayoutOrder = 5
gridFrame.Parent = content

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 94, 0, 30)
grid.CellPadding = UDim2.new(0, 6, 0, 6)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = gridFrame

local fields = {
    {"🌻 Подсолнух", "Sunflower Field"},
    {"🌼 Одуванчик",  "Dandelion Field"},
    {"🍄 Грибы",      "Mushroom Field"},
    {"🍀 Клевер",     "Clover Field"},
    {"💙 Синие цв.",  "Blue Flower Field"},
    {"🕷 Паук",       "Spider Field"},
}

for _, f in ipairs(fields) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.TextSize = 10
    btn.Font = Enum.Font.Gotham
    btn.Text = f[1]
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = gridFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    btn.MouseButton1Click:Connect(function()
        Config.TargetField = f[2]
        fieldLabel.Text = "🌻 " .. f[2]
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 180, 0)}):Play()
        task.delay(0.4, function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 50)}):Play()
        end)
    end)
end

-- Анимация появления
main.Position = UDim2.new(0, -240, 0.5, -155)
TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
    Position = UDim2.new(0, 16, 0.5, -155)
}):Play()

-- ============ СБОР ПЫЛЬЦЫ ============
local function collectPollen()
    if not isAlive() then return end
    local field = findField(Config.TargetField)
    if not field then return end

    local parts = {}
    for _, obj in pairs(field:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Hitbox" then
            table.insert(parts, obj)
        end
    end
    if #parts == 0 then return end

    local limit = math.min(#parts, Config.MaxPartsPerRound)
    for i = 1, limit do
        if not Config.Farm or not isAlive() then break end
        teleport(parts[i].CFrame * CFrame.new(0, 3, 0))
        task.wait(Config.CollectDelay)
    end
end

-- ============ КОНВЕРТАЦИЯ ============
local function convertToHoney()
    if not Config.AutoConvert or not isAlive() then return end
    local hive = findHive()
    if not hive then return end
    local part = hive:IsA("BasePart") and hive or hive:FindFirstChildWhichIsA("BasePart")
    if part then
        teleport(part.CFrame * CFrame.new(0, 3, 0))
        task.wait(Config.ConvertDelay)
    end
end

-- ============ ОСНОВНОЙ ЦИКЛ ============
task.spawn(function()
    while true do
        task.wait(Config.LoopDelay)
        if not Config.Farm then task.wait(0.5) continue end
        if not isAlive() then task.wait(Config.RespawnWait) continue end
        collectPollen()
        convertToHoney()
    end
end)

-- ============ ЧАТ КОМАНДЫ (оставлены для совместимости) ============
player.Chatted:Connect(function(msg)
    local cmd = msg:lower()
    if cmd == "/farm on" then Config.Farm = true
    elseif cmd == "/farm off" then Config.Farm = false
    elseif cmd == "/convert on" then Config.AutoConvert = true
    elseif cmd == "/convert off" then Config.AutoConvert = false
    elseif cmd:sub(1,7) == "/field " then
        Config.TargetField = msg:sub(8)
        fieldLabel.Text = "🌻 " .. Config.TargetField
    end
end)
