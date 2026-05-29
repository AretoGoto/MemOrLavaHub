if _G.autoAnswerRunning then
    _G.autoAnswerRunning = false
    task.wait(0.5)
end
_G.autoAnswerRunning = true

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

local Events = RS:WaitForChild("Events")
local QuestionData = Events:WaitForChild("QuestionData")
local StartQuestion = Events:WaitForChild("StartQuestion")
local OpenUI = Events:WaitForChild("OpenUI")
local TimedRewardsEvent = Events:WaitForChild("TimedRewards")

local SongInfo = require(RS:WaitForChild("Modules"):WaitForChild("SongInfo"))

local SpinDuration = RS:WaitForChild("SpinDuration")
local originalSpinDuration = SpinDuration.Value

local currentQuestion = nil
local autoAnswerEnabled = false
local autoRewardsEnabled = false
local fastCrateEnabled = false
local delayMin = 30  
local delayMax = 130

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Meme or Lava",
    SubTitle = "by akiosoj",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.K,
})

local Tabs = {
    Main = Window:AddTab({ Title = "Угадывание", Icon = "music" }),
    Rewards = Window:AddTab({ Title = "Награды", Icon = "gift" }),
    Settings = Window:AddTab({ Title = "Настройки", Icon = "settings" }),
}

Tabs.Main:AddToggle("AutoAnswer", {
    Title = "Авто угадывание мемов",
    Description = "Автоматически выбирает правильный ответ",
    Default = false,
    Callback = function(value)
        autoAnswerEnabled = value
        print("[Hub] Авто угадывание: " .. tostring(value))
    end,
})

Tabs.Main:AddSlider("DelayMin", {
    Title = "Минимальная задержка",
    Description = "Минимальное время перед ответом (сек)",
    Default = 0.5,
    Min = 0.3,
    Max = 3.0,
    Rounding = 1,
    Callback = function(value)
        delayMin = math.floor(value * 100)
        if delayMin > delayMax then delayMax = delayMin end
        print("[Hub] Мин задержка: " .. value .. " сек")
    end,
})

Tabs.Main:AddSlider("DelayMax", {
    Title = "Максимальная задержка",
    Description = "Максимальное время перед ответом (сек)",
    Default = 1.3,
    Min = 0.3,
    Max = 3.0,
    Rounding = 1,
    Callback = function(value)
        delayMax = math.floor(value * 100)
        if delayMax < delayMin then delayMin = delayMax end
        print("[Hub] Макс задержка: " .. value .. " сек")
    end,
})

Tabs.Rewards:AddToggle("AutoRewards", {
    Title = "Авто сбор наград",
    Description = "Автоматически забирает награды за игровое время",
    Default = false,
    Callback = function(value)
        autoRewardsEnabled = value
        print("[Hub] Авто награды: " .. tostring(value))
    end,
})

Tabs.Rewards:AddToggle("FastCrate", {
    Title = "Быстрое открытие кейсов",
    Description = "Убирает анимацию прокрутки кейса",
    Default = false,
    Callback = function(value)
        fastCrateEnabled = value

        if value then
            
            SpinDuration.Value = 0.1
            print("[Hub] Быстрые кейсы: ВКЛ (SpinDuration = 0.1)")
        else
            
            SpinDuration.Value = originalSpinDuration
            print("[Hub] Быстрые кейсы: ВЫКЛ (SpinDuration = " .. originalSpinDuration .. ")")
        end
    end,
})

Tabs.Rewards:AddParagraph({
    Title = "Как работает",
    Content = "Авто награды: каждые 60 сек проверяет и забирает доступные награды.\nБыстрые кейсы: ускоряет анимацию прокрутки при открытии кейса."
})

Tabs.Settings:AddDropdown("ThemeSelect", {
    Title = "Тема",
    Description = "Цветовая схема интерфейса",
    Values = {"Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose"},
    Default = "Dark",
    Callback = function(value)
        Fluent:SetTheme(value)
        print("[Hub] Тема: " .. value)
    end,
})

Tabs.Settings:AddParagraph({
    Title = "Сворачивание",
    Content = "Свернуть/развернуть окно — клавиша K"
})

SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("MemeGuesserHub")
SaveManager:IgnoreThemeSettings()

local function waitForButton(number, timeout)
    timeout = timeout or 5
    local startTime = tick()
    while tick() - startTime < timeout do
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local QuestionGUI = PlayerGui:FindFirstChild("QuestionGUI")
        if QuestionGUI then
            local f1 = QuestionGUI:FindFirstChild("Frame")
            if f1 then
                local f2 = f1:FindFirstChild("Frame")
                if f2 then
                    local opt = f2:FindFirstChild(tostring(number))
                    if opt then
                        local btn = opt:FindFirstChild("ImageButton")
                        if btn and btn.Visible and btn.Active then
                            return btn
                        end
                    end
                end
            end
        end
        task.wait(0.05)
    end
    return nil
end

local function clickButton(button)
    if not button then return false end
    return pcall(function()
        local centerX = button.AbsolutePosition.X + button.AbsoluteSize.X / 2
        local centerY = button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.2)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    end)
end

local function randomDelay()
    local delay = math.random(delayMin, delayMax) / 100
    print("[Hub] Задержка: " .. delay .. " сек")
    task.wait(delay)
end

local function claimTimedRewards()
    print("\n[Награды] Проверяю...")

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    pcall(function()
        OpenUI:FireServer("TimedRewards")
    end)
    task.wait(1)

    local TimedRewardsGui = PlayerGui:FindFirstChild("TimedRewards")
    if not TimedRewardsGui then
        print("[Награды] GUI не найден!")
        return
    end

    local frame = TimedRewardsGui:FindFirstChild("Frame")
    if not frame then return end

    local container = frame:FindFirstChild("Container")
    if not container then return end

    local claimed = 0

    for i = 1, 6 do
        local slot = container:FindFirstChild(tostring(i))
        if slot then
            local timerLabel = slot:FindFirstChild("TimerLabel")
            if timerLabel then
                local timerText = timerLabel.Text

                local textLabel = nil
                for _, child in pairs(slot:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Name == "TextLabel" then
                        textLabel = child
                        break
                    end
                end

                local buttonText = textLabel and textLabel.Text or ""

                if timerText == "✅" then
                    print("[Награда " .. i .. "] ✅ Уже забрана")
                elseif timerText == "" and buttonText == "Claim!" then
                    print("[Награда " .. i .. "] Забираю!")
                    pcall(function()
                        TimedRewardsEvent:FireServer(i)
                    end)
                    task.wait(0.5)
                    claimed = claimed + 1
                    print("[✓] Награда " .. i .. " забрана!")
                else
                    print("[Награда " .. i .. "] Таймер: " .. timerText)
                end
            end
        end
    end

    print("[Награды] Забрано: " .. claimed .. " наград")
end

task.spawn(function()
    while _G.autoAnswerRunning do
        if autoRewardsEnabled then
            claimTimedRewards()
            task.wait(60)
        else
            task.wait(5)
        end
    end
end)

QuestionData.OnClientEvent:Connect(function(data)
    currentQuestion = data
    print("[Hub] Данные получены! Раундов: " .. #data)
end)

StartQuestion.OnClientEvent:Connect(function(data)
    local roundNum = data.RoundNumber
    print("\n[Раунд " .. roundNum .. "] Начался!")

    if not autoAnswerEnabled or not currentQuestion then return end

    pcall(function() StartQuestion:FireServer("Received") end)

    for _, qData in ipairs(currentQuestion) do
        if qData.Round == roundNum then
            local correctOption = nil

            if qData.RoundType == "Song" then
                for i, option in ipairs(qData.Options) do
                    if option == qData.SongNum then
                        correctOption = i
                        break
                    end
                end
                local name = SongInfo[qData.SongNum] and SongInfo[qData.SongNum].Name or "?"
                print("[Song] Вариант: " .. (correctOption or "?") .. " (" .. name .. ")")

            elseif qData.RoundType == "Vote" then
                correctOption = math.random(1, #qData.Options)
                print("[Vote] Вариант: " .. correctOption)
            end

            if correctOption then
                randomDelay()
                if not _G.autoAnswerRunning then return end
                local button = waitForButton(correctOption, 5)
                clickButton(button)
                pcall(function() StartQuestion:FireServer(correctOption) end)
                print("[✓] Ответ: вариант " .. correctOption)
            end
            break
        end
    end
end)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Meme Guesser",
    Content = "Hub загружен!",
    Duration = 4
})

print("[✓] Meme Guesser Hub загружен!")
