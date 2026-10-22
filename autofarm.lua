local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gravityNormal = workspace.Gravity

local isRunning = false
local speed = 450 -- Скорость 450
local currentTween = nil

local sessionStartTime = tick()

-- Переменные для правильного подсчета золота
local lastGold = 0
local roundEarned = 0
local totalEarned = 0

-- Переменные для Anti-Stuck
local lastProgressTime = tick()

local destinations = {
    CFrame.new(-43.6134491, 62.1137619, 672.744934, -0.999842644, -0.00183729955, 0.017645346, 0, 0.994622767, 0.103564225, -0.0177407414, 0.103547923, -0.994466245),
    CFrame.new(-60.1504707, 97.4659729, 8767.91406, -0.99889338, 0.000705028593, 0.0470264405, 0, 0.999887645, -0.0149902813, -0.047031723, -0.0149736926, -0.998781145),
    CFrame.new(-54.331871, -345.398346, 9488.60645, -0.98221302, 0, 0.187770084, 0, 1, 0, -0.187770084, 0, -0.98221302),
}

local function getGold()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in pairs(leaderstats:GetChildren()) do
            local name = stat.Name:lower()
            if name:find("gold") or name:find("coin") or name:find("money") or name:find("cash") then
                return stat.Value
            end
        end
    end
    local gui = player:FindFirstChild("PlayerGui")
    if gui then
        for _, obj in pairs(gui:GetDescendants()) do
            if obj:IsA("TextLabel") and (obj.Name:lower():find("gold") or obj.Name:lower():find("coin")) then
                local num = tonumber(obj.Text:match("%d+"))
                if num then return num end
            end
        end
    end
    return 0
end

lastGold = getGold()

-- При респавне персонажа сбрасываем счетчик текущего раунда
player.CharacterAdded:Connect(function()
    task.wait(1)
    lastGold = getGold()
    roundEarned = 0
    lastProgressTime = tick()
end)

-- ============ NOCLIP (Только во время полета) ============
RunService.Stepped:Connect(function()
    -- Если скрипт работает и гравитация выключена (мы в полете)
    if isRunning and player.Character and workspace.Gravity == 0 then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

-- ============ GUI ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KLX_AutoFarm"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 260, 0, 250)
menu.Position = UDim2.new(0.5, -130, 0.5, -125)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
menu.BorderSizePixel = 0
menu.Active = true
menu.Draggable = true
menu.Parent = screenGui
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 10)

local menuStroke = Instance.new("UIStroke", menu)
menuStroke.Color = Color3.fromRGB(60, 60, 70)
menuStroke.Thickness = 2

local menuGradient = Instance.new("UIGradient", menu)
menuGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
})
menuGradient.Rotation = 90

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = menu
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
local titleBarFix = Instance.new("Frame")
titleBarFix.Size = UDim2.new(1, 0, 0.5, 0)
titleBarFix.Position = UDim2.new(0, 0, 0.5, 0)
titleBarFix.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBarFix.BorderSizePixel = 0
titleBarFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "KLX | Build a Boat"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -35, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = titleBar
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -30, 0, 45)
toggle.Position = UDim2.new(0, 15, 0, 55)
toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
toggle.Text = "AutoFarm + AntiAfk"
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.Parent = menu
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

local statsBtn = Instance.new("TextButton")
statsBtn.Size = UDim2.new(1, -30, 0, 45)
statsBtn.Position = UDim2.new(0, 15, 0, 110)
statsBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 200)
statsBtn.Text = "Stats: OFF"
statsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
statsBtn.Font = Enum.Font.GothamBold
statsBtn.TextSize = 14
statsBtn.Parent = menu
Instance.new("UICorner", statsBtn).CornerRadius = UDim.new(0, 8)

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 30)
footer.Position = UDim2.new(0, 0, 1, -35)
footer.BackgroundTransparency = 1
footer.Text = "by KLXteam"
footer.TextColor3 = Color3.fromRGB(100, 100, 100)
footer.Font = Enum.Font.Gotham
footer.TextSize = 12
footer.Parent = menu

-- ============ ОКНО СТАТИСТИКИ ============
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0, 220, 0, 160)
statsFrame.Position = UDim2.new(0, 280, 0, 0)
statsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
statsFrame.BorderSizePixel = 0
statsFrame.Visible = false
statsFrame.Active = true
statsFrame.Draggable = true
statsFrame.Parent = menu
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 10)

local statsStroke = Instance.new("UIStroke", statsFrame)
statsStroke.Color = Color3.fromRGB(60, 60, 70)
statsStroke.Thickness = 2

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, -20, 0, 30)
timeLabel.Position = UDim2.new(0, 10, 0, 15)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "Время сессии: 00:00"
timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timeLabel.Font = Enum.Font.Gotham
timeLabel.TextSize = 14
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.Parent = statsFrame

local goldLabel = Instance.new("TextLabel")
goldLabel.Size = UDim2.new(1, -20, 0, 30)
goldLabel.Position = UDim2.new(0, 10, 0, 50)
goldLabel.BackgroundTransparency = 1
goldLabel.Text = "Заработано: 0"
goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
goldLabel.Font = Enum.Font.GothamBold
goldLabel.TextSize = 14
goldLabel.TextXAlignment = Enum.TextXAlignment.Left
goldLabel.Parent = statsFrame

local totalGoldLabel = Instance.new("TextLabel")
totalGoldLabel.Size = UDim2.new(1, -20, 0, 30)
totalGoldLabel.Position = UDim2.new(0, 10, 0, 85)
totalGoldLabel.BackgroundTransparency = 1
totalGoldLabel.Text = "Заработано всего: 0"
totalGoldLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
totalGoldLabel.Font = Enum.Font.GothamBold
totalGoldLabel.TextSize = 14
totalGoldLabel.TextXAlignment = Enum.TextXAlignment.Left
totalGoldLabel.Parent = statsFrame

local statsFooter = Instance.new("TextLabel")
statsFooter.Size = UDim2.new(1, 0, 0, 20)
statsFooter.Position = UDim2.new(0, 0, 1, -25)
statsFooter.BackgroundTransparency = 1
statsFooter.Text = "by KLXteam"
statsFooter.TextColor3 = Color3.fromRGB(100, 100, 100)
statsFooter.Font = Enum.Font.Gotham
statsFooter.TextSize = 10
statsFooter.Parent = statsFrame

-- ============ ПРАВИЛЬНЫЙ ПОДСЧЕТ ============
local statsVisible = false

RunService.RenderStepped:Connect(function()
    local currentGold = getGold()
    
    if currentGold > lastGold then
        local diff = currentGold - lastGold
        roundEarned = roundEarned + diff
        totalEarned = totalEarned + diff
        lastProgressTime = tick() -- Обновляем время прогресса
    end
    lastGold = currentGold

    if statsVisible then
        local elapsed = math.floor(tick() - sessionStartTime)
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60
        timeLabel.Text = string.format("Время сессии: %02d:%02d", mins, secs)
        goldLabel.Text = "Заработано: " .. tostring(roundEarned)
        totalGoldLabel.Text = "Заработано всего: " .. tostring(totalEarned)
    end
end)

-- ============ АНТИ-ЗАВИСАНИЕ (Без убийства) ============
task.spawn(function()
    while true do
        task.wait(1)
        if isRunning then
            if tick() - lastProgressTime >= 50 then
                if player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        if currentTween then currentTween:Cancel() end
                        -- Поднимаем персонажа на 25 стадов вверх, чтобы вытолкнуть из текстуры
                        root.CFrame = root.CFrame + Vector3.new(0, 25, 0)
                        workspace.Gravity = gravityNormal
                    end
                end
                lastProgressTime = tick()
                task.wait(3) -- Даем время на восстановление
            end
        else
            lastProgressTime = tick()
        end
    end
end)

statsBtn.MouseButton1Click:Connect(function()
    statsVisible = not statsVisible
    statsFrame.Visible = statsVisible
    statsBtn.Text = "Stats: " .. (statsVisible and "ON" or "OFF")
    statsBtn.BackgroundColor3 = statsVisible and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 80, 200)
end)

-- ============ ЛОГИКА АВТОФАРМА (Исходная) ============
close.MouseButton1Click:Connect(function()
    isRunning = false
    workspace.Gravity = gravityNormal
    if currentTween then
        currentTween:Cancel()
    end
    screenGui:Destroy()
end)

local function moveTo(targetCFrame, setGravity)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / speed

    currentTween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    currentTween:Play()

    local reached = false
    currentTween.Completed:Connect(function()
        reached = true
    end)

    if setGravity then
        workspace.Gravity = gravityNormal
    else
        workspace.Gravity = 0
    end

    while not reached and isRunning do
        RunService.Heartbeat:Wait()
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        if isRunning then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.K, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.K, false, game)
        end
    end
end)

local function autoFarmLoop()
    while isRunning do
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not root then return end

        for i, cf in ipairs(destinations) do
            if not isRunning then return end
            moveTo(cf, i == #destinations)
        end

        repeat
            wait(1)
        until player.CharacterAdded:Wait()
    end
end

toggle.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if not isRunning then
        toggle.Text = "AutoFarm + AntiAfk"
        toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        workspace.Gravity = gravityNormal
        if currentTween then
            currentTween:Cancel()
        end
    else
        toggle.Text = "Stop AutoFarm"
        toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        lastProgressTime = tick()
        task.spawn(autoFarmLoop)
    end
end)

player.CharacterAdded:Connect(function()
    if isRunning then
        task.spawn(autoFarmLoop)
    end
end)

player.CharacterAdded:Connect(function()
    if isRunning then
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root then
            wait(1)
            moveTo(destinations[1], false)
            task.spawn(autoFarmLoop)
        end
    end
end)
