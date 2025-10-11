local Luna = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/luna", true))()

local Window = Luna:CreateWindow({
    Name = "WeroScript - Steal a Brainrot",
    Subtitle = nil,
    LogoID = "73521246377799",
    LoadingEnabled = true,
    LoadingTitle = "WeroScript - Steal a Brainrot",
    LoadingSubtitle = "Made by: WeroScripts",

    ConfigSettings = {
        RootFolder = nil,
        ConfigFolder = "WeroSabScript"
    },

    KeySystem = false,
    KeySettings = {
        Title = "Luna Example Key",
        Subtitle = "Key System",
        Note = "Best Key System Ever! ",
        SaveInRoot = false,
        SaveKey = true,
        Key = {"Example Key"},
        SecondAction = {
            Enabled = true,
            Type = "Link",
            Parameter = ""
        }
    }
})

local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "home",
    ImageSource = "Material",
    ShowTitle = true
})

-- ===== Float Quantum =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local workspace = workspace

local LocalPlayer = Players.LocalPlayer

local TOOL_NAME = "Quantum Cloner"
local CLONE_SEARCH_PATTERN = "^(%d+)_Clone$"
local UPDATE_INTERVAL = 0.05
local LOOK_UP_THRESHOLD = 0.4
local LOOK_DOWN_THRESHOLD = -0.4
local FLY_POWER = 60
local MIN_MOVE_MAG = 0.1

local active = false
local usingClone = false
local currentCloneModel = nil

local function getCamera()
    if workspace.CurrentCamera then return workspace.CurrentCamera end
    local sign = workspace:GetPropertyChangedSignal("CurrentCamera")
    local cam = workspace.CurrentCamera
    if cam then return cam end
    local t0 = tick()
    while not workspace.CurrentCamera and tick() - t0 < 5 do
        sign:Wait()
    end
    return workspace.CurrentCamera
end

local Camera = getCamera()

local function getUseItemRemote()
    -- intento estructurado
    local ok, result = pcall(function()
        local pk = ReplicatedStorage:FindFirstChild("Packages")
        if pk then
            local net = pk:FindFirstChild("Net")
            if net then
                return net:FindFirstChild("RE/UseItem")
            end
        end
    end)
    if ok and result and result:IsA("RemoteEvent") then return result end

    local found = ReplicatedStorage:FindFirstChild("RE/UseItem", true)
    if found and found:IsA("RemoteEvent") then return found end
    return nil
end

local USE_ITEM_REMOTE = getUseItemRemote()

-- Buscar el clon con tu userid
local function findMyClone()
    local uidStr = tostring(LocalPlayer.UserId)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and type(obj.Name) == "string" then
            local uid = string.match(obj.Name, CLONE_SEARCH_PATTERN)
            if uid and tostring(tonumber(uid)) == uidStr then
                return obj
            end
        end
    end
    return nil
end

local function positionCloneUnderPlayer(cloneModel)
    if not cloneModel then return false end
    local cloneHRP = cloneModel:FindFirstChild("HumanoidRootPart") or cloneModel:FindFirstChildWhichIsA("BasePart")
    if not cloneHRP then return false end

    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local look = hrp.CFrame.LookVector
    local backOffset = look * -1 * 1.2
    local desiredPos = hrp.Position + Vector3.new(0, -3.5, 0) + backOffset
    local orient = CFrame.new(desiredPos, desiredPos + hrp.CFrame.LookVector)
    local lieCFrame = orient * CFrame.Angles(math.rad(90), 0, 0)

    pcall(function()
        cloneHRP.Anchored = true
        cloneHRP.CFrame = lieCFrame
    end)
    return true
end

local function flightLoop()
    Camera = getCamera()
    while active and usingClone and currentCloneModel and currentCloneModel.Parent do
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hrp and hum then
                -- posicionar clon
                pcall(function() positionCloneUnderPlayer(currentCloneModel) end)

                local moveMag = hum.MoveDirection and hum.MoveDirection.Magnitude or 0
                local camLookY = (Camera and Camera.CFrame and Camera.CFrame.LookVector.Y) or hrp.CFrame.LookVector.Y
                if moveMag > MIN_MOVE_MAG then
                    if camLookY > LOOK_UP_THRESHOLD then
                        hrp.Velocity = Vector3.new(hrp.Velocity.X, FLY_POWER, hrp.Velocity.Z)
                    elseif camLookY < LOOK_DOWN_THRESHOLD then
                        hrp.Velocity = Vector3.new(hrp.Velocity.X, -FLY_POWER, hrp.Velocity.Z)
                    end
                end
            end
        end
        task.wait(UPDATE_INTERVAL)
    end
end

local function startUsingClone(cloneModel)
    if not cloneModel then return false end
    currentCloneModel = cloneModel
    usingClone = true
    positionCloneUnderPlayer(cloneModel)
    task.spawn(flightLoop)
    return true
end

local function stopUsingClone()
    usingClone = false
    if currentCloneModel and currentCloneModel.Parent then
        local cloneHRP = currentCloneModel:FindFirstChild("HumanoidRootPart") or currentCloneModel:FindFirstChildWhichIsA("BasePart")
        if cloneHRP then
            pcall(function() cloneHRP.Anchored = false end)
        end
    end
    currentCloneModel = nil
end

local function floatV2Button(estado)
    if estado == nil then return end

    if estado and not active then
        active = true

        if LocalPlayer.Character then
            local toolInChar = LocalPlayer.Character:FindFirstChild(TOOL_NAME)
            if toolInChar and USE_ITEM_REMOTE then
                pcall(function()
                    USE_ITEM_REMOTE:FireServer(toolInChar)
                end)
            end
        end

        local attempts, maxAttempts = 0, 60
        local myClone = findMyClone()
        while not myClone and attempts < maxAttempts and active do
            attempts = attempts + 1
            task.wait(0.15)
            myClone = findMyClone()
        end

        if myClone then
            local ok = startUsingClone(myClone)
            if not ok then
                warn("[Float v2] fallo al iniciar clon")
                active = false
            end
        else
            warn("[Float v2] no se encontró " .. tostring(LocalPlayer.UserId) .. "_Clone")
            active = false
        end

    elseif not estado and active then
        -- apagar
        active = false
        stopUsingClone()
    end
end

_G.floatV2Button = floatV2Button

local Toggle = MainTab:CreateToggle({
    Name = "Float v2",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
        floatV2Button(Value)
    end
}, "Toggle")

-- ===== Toggle ESP Players =====
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local playersEnabled = false
local espFolder = Instance.new("Folder")
espFolder.Name = "ESP_Players"
espFolder.Parent = gui

-- Limpia todos los ESP actuales
local function clearESP()
    for _, v in pairs(espFolder:GetChildren()) do
        v:Destroy()
    end
end

local function addESP(target)
    if not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bill = Instance.new("BillboardGui")
    bill.Adornee = hrp
    bill.Size = UDim2.new(0, 200, 0, 50)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill.Parent = espFolder

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.TextScaled = true
    txt.Font = Enum.Font.GothamBold
    txt.TextColor3 = Color3.fromRGB(0, 255, 255)
    txt.TextStrokeTransparency = 0.5
    txt.Text = target.Name
    txt.Parent = bill
end

local function updateAllESP()
    clearESP()
    if not playersEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            addESP(plr)
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if playersEnabled then
            task.wait(1)
            addESP(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function()
    updateAllESP()
end)

function toggleEspPlayers(value)
    if typeof(value) ~= "boolean" then
        warn("[ESP] Valor inválido, se esperaba booleano.")
        return
    end

    playersEnabled = value

    if playersEnabled then
        updateAllESP()
    else
        clearESP()
    end
end

local Toggle = MainTab:CreateToggle({
    Name = "ESP Players",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
       toggleEspPlayers(Value)
    end
}, "Toggle")

-- ===== Toggle ESP brainrots =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local brainrotEnabled = false
local currentHighlight, currentBillboard, currentTextLabel
local brainrotConn

local function parseMoney(text)
    if not text then return 0 end
    text = tostring(text):upper()
    local num = text:match("[%d%.]+")
    if not num then return 0 end
    num = tonumber(num) or 0
    if text:find("K") then
        num = num * 1e3
    elseif text:find("M") then
        num = num * 1e6
    elseif text:find("B") then
        num = num * 1e9
    end
    return num
end

local function findBestSpawn()
    local bestPart, bestText, bestScore = nil, nil, -math.huge
    for _, desc in workspace:GetDescendants() do
        if desc.Name == "Generation" then
            local valueText
            if desc:IsA("StringValue") or desc:IsA("IntValue") or desc:IsA("NumberValue") then
                valueText = tostring(desc.Value)
            elseif desc:IsA("TextLabel") or desc:IsA("TextBox") then
                valueText = tostring(desc.Text)
            end
            if valueText and valueText ~= "" then
                local score = parseMoney(valueText)
                if score > bestScore then
                    bestScore = score
                    bestText = valueText
                    local parentPart = desc.Parent
                    while parentPart and not parentPart:IsA("BasePart") do
                        parentPart = parentPart.Parent
                    end
                    bestPart = parentPart
                end
            end
        end
    end
    return bestPart, bestText
end

local function clearBrainrot()
    if currentHighlight then currentHighlight:Destroy() end
    if currentBillboard then currentBillboard:Destroy() end
    currentHighlight, currentBillboard, currentTextLabel = nil, nil, nil
end

local function showBestSpawn()
    local part, text = findBestSpawn()
    if not part or not text then return end

    if not currentHighlight then
        currentHighlight = Instance.new("Highlight")
        currentHighlight.FillTransparency = 1
        currentHighlight.OutlineTransparency = 0
        currentHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        currentHighlight.Parent = part
    else
        currentHighlight.Adornee = part
    end

    if not currentBillboard then
        currentBillboard = Instance.new("BillboardGui")
        currentBillboard.Size = UDim2.new(0, 200, 0, 40)
        currentBillboard.StudsOffset = Vector3.new(0, 3, 0)
        currentBillboard.AlwaysOnTop = true
        currentBillboard.Parent = PlayerGui

        currentTextLabel = Instance.new("TextLabel")
        currentTextLabel.Size = UDim2.new(1, 0, 1, 0)
        currentTextLabel.BackgroundTransparency = 1
        currentTextLabel.TextScaled = true
        currentTextLabel.Font = Enum.Font.GothamBold
        currentTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentTextLabel.TextStrokeTransparency = 0.2
        currentTextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        currentTextLabel.Parent = currentBillboard
    end

    currentBillboard.Adornee = part
    currentTextLabel.Text = "⭐ Best Brainrot: " .. text .. " ⭐"
end

local function toggleBrainrot(value)
    if typeof(value) ~= "boolean" then
        warn("[Brainrot] Valor inválido.")
        return
    end

    brainrotEnabled = value

    if brainrotEnabled then
        if not brainrotConn then
            brainrotConn = RunService.RenderStepped:Connect(function()
                if brainrotEnabled then
                    showBestSpawn()
                end
            end)
        end
    else
        if brainrotConn then
            brainrotConn:Disconnect()
            brainrotConn = nil
        end
        clearBrainrot()
    end
end

local Toggle = MainTab:CreateToggle({
    Name = "Esp Best Brainrot",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
        toggleBrainrot(Value)
    end
}, "Toggle")

-- ===== Capa Laser =====
local laserGuiCreated = false
local laserScreenGui = nil
local laserFrameRef = nil

local function createLaserGui()
    if laserGuiCreated then return end
    laserGuiCreated = true

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = player
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local RFCoinsShopServiceRequestBuy
    local REUseItem
    pcall(function()
        RFCoinsShopServiceRequestBuy = ReplicatedStorage.Packages.Net["RF/CoinsShopService/RequestBuy"]
        REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]
    end)

    -- limpiar gui si existe
    for _, existingGui in pairs(player.PlayerGui:GetChildren()) do
        if existingGui:IsA("ScreenGui") and existingGui.Name == "WeroScriptGUI" then
            existingGui:Destroy()
        end
    end

    laserScreenGui = Instance.new("ScreenGui")
    laserScreenGui.Name = "WeroScriptGUI"
    laserScreenGui.ResetOnSpawn = false
    laserScreenGui.Parent = player:WaitForChild("PlayerGui")
    laserScreenGui.Enabled = true

    local frameL = Instance.new("Frame")
    frameL.Size = UDim2.new(0, 250, 0, 150)
    frameL.Position = UDim2.new(0.4, 0, 0.3, 0)
    frameL.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frameL.BorderSizePixel = 0
    frameL.Active = true
    frameL.Draggable = true
    frameL.Parent = laserScreenGui
    laserFrameRef = frameL

    local uicorner = Instance.new("UICorner", frameL)
    uicorner.CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "⚡ WeroScript GUI"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = frameL

    local buyButton = Instance.new("TextButton")
    buyButton.Size = UDim2.new(1, -20, 0, 40)
    buyButton.Position = UDim2.new(0, 10, 0, 50)
    buyButton.BackgroundColor3 = Color3.fromRGB(0, 102, 204)
    buyButton.Text = "🛒 Buy Laser Cape"
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.Font = Enum.Font.GothamBold
    buyButton.TextSize = 16
    buyButton.Parent = frameL

    local buyCorner = Instance.new("UICorner", buyButton)
    buyCorner.CornerRadius = UDim.new(0, 8)

    local autoButton = Instance.new("TextButton")
    autoButton.Size = UDim2.new(1, -20, 0, 40)
    autoButton.Position = UDim2.new(0, 10, 0, 100)
    autoButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
    autoButton.Text = "✔ Auto Laser: OFF"
    autoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoButton.Font = Enum.Font.GothamBold
    autoButton.TextSize = 16
    autoButton.Parent = frameL

    local autoCorner = Instance.new("UICorner", autoButton)
    autoCorner.CornerRadius = UDim.new(0, 8)

    local autoLaserEnabled = false
    local circlePart = nil
    local equipLoop = nil
    local detectConn = nil
    local alreadyBought = false

    buyButton.MouseButton1Click:Connect(function()
        if not alreadyBought then
            if RFCoinsShopServiceRequestBuy then
                pcall(function()
                    RFCoinsShopServiceRequestBuy:InvokeServer("Laser Cape")
                end)
            end
            alreadyBought = true
            buyButton.Text = "✔ Laser Cape Bought"
            buyButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        end
    end)

    autoButton.MouseButton1Click:Connect(function()
        autoLaserEnabled = not autoLaserEnabled
        if autoLaserEnabled then
            autoButton.Text = "✔ Auto Laser: ON"
            autoButton.BackgroundColor3 = Color3.fromRGB(34, 200, 34)

            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

            if not circlePart then
                circlePart = Instance.new("Part")
                circlePart.Shape = Enum.PartType.Cylinder
                circlePart.Anchored = true
                circlePart.CanCollide = false
                circlePart.Size = Vector3.new(120, 1, 120)
                circlePart.Color = Color3.fromRGB(0, 255, 0)
                circlePart.Transparency = 0.5
                circlePart.Material = Enum.Material.Neon
                circlePart.Parent = workspace
            end

            if not equipLoop then
                equipLoop = RunService.Heartbeat:Connect(function()
                    pcall(function()
                        local backpack = LocalPlayer:FindFirstChild("Backpack")
                        local tool = backpack and backpack:FindFirstChild("Laser Cape") or Character:FindFirstChild("Laser Cape")
                        if tool and tool.Parent ~= Character then
                            tool.Parent = Character
                        end
                    end)
                end)
            end

            if not detectConn then
                detectConn = RunService.RenderStepped:Connect(function()
                    if circlePart and autoLaserEnabled then
                        local char = LocalPlayer.Character
                        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                        local hrp = char.HumanoidRootPart
                        circlePart.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(90), 0, 0)

                        for _, plr in ipairs(Players:GetPlayers()) do
                            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                                local targetHRP = plr.Character.HumanoidRootPart
                                local dist = (targetHRP.Position - hrp.Position).Magnitude
                                if dist <= 75 then
                                    if REUseItem then
                                        pcall(function()
                                            REUseItem:FireServer(Vector3.new(-345, -7, 3), targetHRP)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end)
            end

        else
            autoButton.Text = "✔ Auto Laser: OFF"
            autoButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            if circlePart then
                circlePart:Destroy()
                circlePart = nil
            end
            if equipLoop then
                equipLoop:Disconnect()
                equipLoop = nil
            end
            if detectConn then
                detectConn:Disconnect()
                detectConn = nil
            end
        end
    end)
end

function toggleLaserGui(value)
    if typeof(value) ~= "boolean" then
        warn("[LaserGUI] Valor inválido, se esperaba booleano.")
        return
    end

    if value then
        if not laserGuiCreated then
            createLaserGui()
        else
            if laserScreenGui then
                laserScreenGui.Enabled = true
            end
        end
    else
        if laserScreenGui then
            laserScreenGui.Enabled = false
        end
    end
end

local Toggle = MainTab:CreateToggle({
    Name = "Wero Laser Cape GUI",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
        toggleLaserGui(Value)
    end
}, "Toggle")

-- ===== Toggle ESP Timer =====
getgenv().ESP_Global = getgenv().ESP_Global or {}
getgenv().ESP_Global.espBases = getgenv().ESP_Global.espBases or {}
local espBases = getgenv().ESP_Global.espBases

local espBasesEnabled = false

local function findPrimaryPart(model)
    if not model then return nil end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function createESPBaseFor(model)
    if not model then return end
    if type(espBases) ~= "table" then return end
    if espBases[model] then return end

    local basePart = findPrimaryPart(model)
    if not basePart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WeroScriptESP_Board"
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = basePart

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 1, 0)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = model.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextScaled = true
    label.Parent = billboard

    local remTime = model:FindFirstChild("RemainingTime", true)
    if remTime and remTime:IsA("TextLabel") then
        label.Text = remTime.Text
        remTime:GetPropertyChangedSignal("Text"):Connect(function()
            if label and label.Parent then
                label.Text = remTime.Text
            end
        end)
    end

    local ok, box = pcall(function()
        local s = Instance.new("SelectionBox")
        s.Name = "WeroScriptESP_Box"
        s.Adornee = basePart
        s.LineThickness = 0.02
        s.Color3 = Color3.fromRGB(255, 255, 255)
        s.SurfaceTransparency = 1
        s.Parent = basePart
        return s
    end)

    if not ok or not box then
        local hl = Instance.new("Highlight")
        hl.Name = "WeroScriptESP_Box"
        hl.FillTransparency = 1
        hl.OutlineTransparency = 0
        hl.OutlineColor3 = Color3.fromRGB(255, 255, 255)
        hl.Parent = model
        espBases[model] = {billboard = billboard, box = hl}
    else
        espBases[model] = {billboard = billboard, box = box}
    end
end

local function removeBaseESP(model)
    if type(espBases) ~= "table" then return end
    local t = espBases[model]
    if not t then return end
    if t.billboard and t.billboard.Parent then pcall(function() t.billboard:Destroy() end) end
    if t.box and t.box.Parent then pcall(function() t.box:Destroy() end) end
    espBases[model] = nil
end

local function clearAllBaseESP()
    if type(espBases) ~= "table" then return end
    local keys = {}
    for model,_ in pairs(espBases) do table.insert(keys, model) end
    for _, model in ipairs(keys) do removeBaseESP(model) end
end

local plots = workspace:FindFirstChild("Plots") or workspace:WaitForChild("Plots", 5)
if plots then
    plots.ChildAdded:Connect(function(child)
        if espBasesEnabled and child:IsA("Model") then
            task.wait(0.3)
            createESPBaseFor(child)
        end
    end)

    plots.ChildRemoved:Connect(function(child)
        if type(espBases) == "table" and espBases[child] then
            removeBaseESP(child)
        end
    end)
else
    warn("WeroScript: workspace.Plots no encontrado en 5s; no se crearán ESP de bases.")
end

local function espBasesToggle(state)
    espBasesEnabled = state
    clearAllBaseESP()
    if state and plots then
        for _, base in pairs(plots:GetChildren()) do
            if base:IsA("Model") then
                createESPBaseFor(base)
            end
        end
    end
end

local Toggle = MainTab:CreateToggle({
    Name = "Esp Bases Timer",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
        espBasesToggle(Value)
    end
}, "Toggle")

-- ===== Falling Fly =====
local caerLentoActivo = false

-- Funcion que aplica la caida lenta
local function activarCaidaLenta()
    local player = game.Players.LocalPlayer
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

    if not humanoid then return end

    -- Reducimos la gravedad solo para el cliente
    game:GetService("RunService").Heartbeat:Connect(function()
        if caerLentoActivo and humanoid and humanoid.RootPart then
            humanoid.RootPart.Velocity = Vector3.new(
                humanoid.RootPart.Velocity.X,
                math.clamp(humanoid.RootPart.Velocity.Y, -0.001, 0.001),
                humanoid.RootPart.Velocity.Z
            )
        end
    end)
end

local function toggleCaidaLenta()
    caerLentoActivo = not caerLentoActivo
    if caerLentoActivo then
        print("Caída lenta ACTIVADA")
    else
        print("Caída lenta DESACTIVADA")
    end
end

activarCaidaLenta()

local Toggle = MainTab:CreateToggle({
    Name = "Falling Fly",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
        toggleCaidaLenta(Value)
    end
}, "Toggle")

-- ===== Control Players GUI=====
local controlGuiCreated = false
local controlScreenGui = nil
local controlFrameRef = nil
local controlTarget = nil
local controlling = false
local originalChar = nil
local originalCamSubject = nil

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local REUseItem
pcall(function()
    REUseItem = ReplicatedStorage.Packages.Net["RE/UseItem"]
end)

-- === D-PAD PARA CELULAR ===
local function createMobileControls(parentFrame, setDir, setJump)
    local dpad = Instance.new("Frame")
    dpad.Size = UDim2.new(0, 150, 0, 150)
    dpad.Position = UDim2.new(1, -160, 1, -160)
    dpad.BackgroundTransparency = 1
    dpad.Parent = parentFrame

    local function makeBtn(text, pos, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 40)
        btn.Position = pos
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.Text = text
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.Parent = dpad
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

        btn.MouseButton1Down:Connect(function() callback(true) end)
        btn.MouseButton1Up:Connect(function() callback(false) end)
        btn.TouchLongPress:Connect(function(_, state) 
            if state == Enum.UserInputState.Begin then callback(true) end
            if state == Enum.UserInputState.End then callback(false) end
        end)
    end

    makeBtn("↑", UDim2.new(0, 55, 0, 0), function(pressed) 
        if pressed then setDir(Vector3.new(0,0,1)) else setDir(Vector3.zero) end
    end)
    makeBtn("↓", UDim2.new(0, 55, 0, 110), function(pressed) 
        if pressed then setDir(Vector3.new(0,0,-1)) else setDir(Vector3.zero) end
    end)
    makeBtn("←", UDim2.new(0, 0, 0, 55), function(pressed) 
        if pressed then setDir(Vector3.new(-1,0,0)) else setDir(Vector3.zero) end
    end)
    makeBtn("→", UDim2.new(0, 110, 0, 55), function(pressed) 
        if pressed then setDir(Vector3.new(1,0,0)) else setDir(Vector3.zero) end
    end)
    makeBtn("⤴", UDim2.new(0, 200, 0, 55), function(pressed) 
        setJump(pressed)
    end)
end

-- Función para crear GUI
local function createControlGui()
    if controlGuiCreated then return end
    controlGuiCreated = true

    for _, existingGui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
        if existingGui:IsA("ScreenGui") and existingGui.Name == "WeroScriptControlGUI" then
            existingGui:Destroy()
        end
    end

    controlScreenGui = Instance.new("ScreenGui")
    controlScreenGui.Name = "WeroScriptControlGUI"
    controlScreenGui.ResetOnSpawn = false
    controlScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    controlScreenGui.Enabled = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 150)
    frame.Position = UDim2.new(0.4, 0, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = controlScreenGui
    controlFrameRef = frame
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🎮 Control Players"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = frame

    local shootButton = Instance.new("TextButton")
    shootButton.Size = UDim2.new(1, -20, 0, 40)
    shootButton.Position = UDim2.new(0, 10, 0, 50)
    shootButton.BackgroundColor3 = Color3.fromRGB(0, 102, 204)
    shootButton.Text = "🔫 Shoot Nearest Player"
    shootButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    shootButton.Font = Enum.Font.GothamBold
    shootButton.TextSize = 16
    shootButton.Parent = frame
    Instance.new("UICorner", shootButton).CornerRadius = UDim.new(0, 8)

    local controlButton = Instance.new("TextButton")
    controlButton.Size = UDim2.new(1, -20, 0, 40)
    controlButton.Position = UDim2.new(0, 10, 0, 100)
    controlButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
    controlButton.Text = "🎭 Control Player"
    controlButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    controlButton.Font = Enum.Font.GothamBold
    controlButton.TextSize = 16
    controlButton.Parent = frame
    Instance.new("UICorner", controlButton).CornerRadius = UDim.new(0, 8)

    local function getNearestPlayer()
        local nearest = nil
        local shortestDist = math.huge
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        local myPos = myChar.HumanoidRootPart.Position
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearest = plr
                end
            end
        end
        return nearest
    end

    shootButton.MouseButton1Click:Connect(function()
        local nearest = getNearestPlayer()
        if nearest and nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart") then
            controlTarget = nearest
            if REUseItem then
                pcall(function()
                    REUseItem:FireServer(Vector3.new(-345, -7, 3), nearest.Character.HumanoidRootPart)
                end)
            end
            shootButton.Text = "✔ Shot: "..nearest.Name
            shootButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        else
            shootButton.Text = "❌ No player found"
            shootButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        end
    end)

    controlButton.MouseButton1Click:Connect(function()
        if controlTarget and controlTarget.Character and not controlling then
            controlling = true
            local targetChar = controlTarget.Character
            originalChar = LocalPlayer.Character
            originalCamSubject = Camera.CameraSubject

            local targetHumanoid = targetChar:FindFirstChild("Humanoid")
            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            if not targetHumanoid or not targetHRP then return end

            Camera.CameraSubject = targetHumanoid
            LocalPlayer.Character = targetChar
            controlButton.Text = "🎭 Controlling..."
            controlButton.BackgroundColor3 = Color3.fromRGB(200, 200, 0)

            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(400000, 0, 400000)
            bv.Velocity = Vector3.zero
            bv.P = 10000
            bv.Parent = targetHRP

            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(0, 400000, 0)
            bg.CFrame = targetHRP.CFrame
            bg.P = 10000
            bg.Parent = targetHRP

            local moveDir = Vector3.new(0,0,0)
            local jump = false

            -- PC INPUT
            local inputConn = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode == Enum.KeyCode.S then moveDir = Vector3.new(0,0,-1) end
                if input.KeyCode == Enum.KeyCode.W then moveDir = Vector3.new(0,0,1) end
                if input.KeyCode == Enum.KeyCode.A then moveDir = Vector3.new(-1,0,0) end
                if input.KeyCode == Enum.KeyCode.D then moveDir = Vector3.new(1,0,0) end
                if input.KeyCode == Enum.KeyCode.Space then jump = true end
            end)
            local inputEndConn = UserInputService.InputEnded:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S or
                   input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
                    moveDir = Vector3.new(0,0,0)
                end
                if input.KeyCode == Enum.KeyCode.Space then jump = false end
            end)

            -- MOBILE INPUT (D-Pad)
            createMobileControls(controlFrameRef, function(dir)
                moveDir = dir
            end, function(isJumping)
                jump = isJumping
            end)

            local moveConn
            moveConn = RunService.Heartbeat:Connect(function()
                local camCFrame = Camera.CFrame
                local dir = (camCFrame.RightVector * moveDir.X + camCFrame.LookVector * moveDir.Z)
                bv.Velocity = dir * 24 + Vector3.new(0, bv.Velocity.Y, 0)
                if jump and targetHumanoid.FloorMaterial ~= Enum.Material.Air then
                    targetHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                bg.CFrame = CFrame.new(targetHRP.Position, targetHRP.Position + camCFrame.LookVector)
            end)

            task.delay(10, function()
                if controlling then
                    controlling = false
                    LocalPlayer.Character = originalChar
                    Camera.CameraSubject = originalCamSubject
                    controlButton.Text = "🎭 Control Player"
                    controlButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
                    bv:Destroy()
                    bg:Destroy()
                    inputConn:Disconnect()
                    inputEndConn:Disconnect()
                    moveConn:Disconnect()
                end
            end)
        end
    end)
end

local function ToggleControl()
    controlToggle = not controlToggle  -- Cambia el estado (ON/OFF)

    if controlToggle then
        -- 🔵 ACTIVAR
        if not controlGuiCreated then
            createControlGui() -- Crea la GUI si no existe
        else
            if controlScreenGui then
                controlScreenGui.Enabled = true -- Solo la muestra
            end
        end
    else
        -- 🔴 DESACTIVAR
        if controlScreenGui then
            controlScreenGui.Enabled = false -- Oculta la GUI
        end
    end
end

local Toggle = MainTab:CreateToggle({
    Name = "Control Players Wero GUI",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
        ToggleControl(Value)
    end
}, "Toggle")

-- ===== Air Walk =====
local airPart
local floatConn
local floatEnabled = false

-- Función toggle automática
local function ToggleFloatV1()
    floatEnabled = not floatEnabled

    if floatEnabled then
        -- Activar Float
        if not airPart then
            airPart = Instance.new("Part")
            airPart.Anchored = true
            airPart.Size = Vector3.new(6, 1, 6)
            airPart.Transparency = 1
            airPart.Color = Color3.fromRGB(0, 255, 0)
            airPart.Parent = workspace

            -- Actualizar posición
            floatConn = RunService.RenderStepped:Connect(function()
                if not airPart or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                    if floatConn then floatConn:Disconnect() end
                    return
                end
                airPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, -3, 0)
            end)
        end
    else
        -- Desactivar Float
        if floatConn then
            floatConn:Disconnect()
            floatConn = nil
        end
        if airPart then
            airPart:Destroy()
            airPart = nil
        end
    end
end

local Toggle = MainTab:CreateToggle({
    Name = "Float v1",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
        ToggleFloatV1(Value)
    end
}, "Toggle")

--=======FLOATS=========
-- Wero Floats GUI (corregido: minimizado, clipping, toggles bonitos)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local floatList = {
    {Name = "Float V1", Callback = function(state) ToggleFloatV1(state) end},
    {Name = "Float V2", Callback = "floatV2Button"},
    {Name = "Falling Fly", Callback = function(state) toggleCaidaLenta(state) end},
}

local guiCreated = false
local screenGui, mainFrame
local btnObjects = {}

local function resolveCallback(cb)
    if typeof(cb) == "function" then return cb end
    if typeof(cb) == "string" and type(_G[cb]) == "function" then
        return _G[cb]
    end
    return nil
end

local function makeText(parent, props)
    local lbl = Instance.new("TextLabel")
    lbl.Size = props.Size or UDim2.new(1,0,0,30)
    lbl.Position = props.Position or UDim2.new(0,0,0,0)
    lbl.BackgroundTransparency = props.BackgroundTransparency or 1
    lbl.Text = props.Text or ""
    lbl.TextColor3 = props.TextColor3 or Color3.fromRGB(255,255,255)
    lbl.Font = props.Font or Enum.Font.GothamBold
    lbl.TextSize = props.TextSize or 16
    lbl.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function createGui()
    if guiCreated then return end
    guiCreated = true

    -- eliminar gui previa si existe
    for _, g in pairs(playerGui:GetChildren()) do
        if g:IsA("ScreenGui") and g.Name == "WeroFloatsGUI" then
            g:Destroy()
        end
    end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WeroFloatsGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    screenGui.Enabled = false

    local height = 86 + #floatList * 56
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 340, 0, height)
    mainFrame.Position = UDim2.new(0.56, 0, 0.26, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(16,16,18)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    -- FIX: recortar hijos para que no se vean fuera al minimizar
    mainFrame.ClipsDescendants = true

    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
    local uiStroke = Instance.new("UIStroke", mainFrame)
    uiStroke.Color = Color3.fromRGB(36,36,40)
    uiStroke.Transparency = 0.7
    uiStroke.Thickness = 1

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1,0,0,64)
    header.BackgroundTransparency = 1
    header.Parent = mainFrame

    local titleLabel = makeText(header, {
        Size = UDim2.new(0.78, -12, 1, 0),
        Position = UDim2.new(0, 16, 0, 12),
        Text = "⚡ Wero Floats",
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local icon = Instance.new("Frame")
    icon.Size = UDim2.new(0,48,0,48)
    icon.Position = UDim2.new(1, -74, 0, 8)
    icon.BackgroundColor3 = Color3.fromRGB(35,160,255)
    icon.Parent = header
    icon.ClipsDescendants = true
    Instance.new("UICorner", icon).CornerRadius = UDim.new(1,0)
    local iconLabel = makeText(icon, {
        Size = UDim2.new(1,0,1,0),
        Text = "FL",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Center
    })

    local grad = Instance.new("UIGradient", mainFrame)
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(14,14,16)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20,20,22))
    })

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -24, 0, height - 90)
    content.Position = UDim2.new(0, 12, 0, 76)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    content.ClipsDescendants = true -- seguridad extra

    -- Guardar originales para restaurar
    local orig = {
        mainSize = mainFrame.Size,
        titlePos = titleLabel.Position,
        titleSize = titleLabel.Size,
        titleAnchor = titleLabel.AnchorPoint,
        titleAlign = titleLabel.TextXAlignment,
        iconPos = icon.Position,
        iconSize = icon.Size,
        closePos = nil,
        contentVis = content.Visible,
    }

    for i, data in ipairs(floatList) do
        local y = (i - 1) * 54
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 48)
        row.Position = UDim2.new(0, 0, 0, y)
        row.BackgroundTransparency = 1
        row.Parent = content

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundColor3 = Color3.fromRGB(26,26,28)
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Parent = row
        button.Text = ""
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
        -- sutil borde para cada fila
        local btnStroke = Instance.new("UIStroke", button)
        btnStroke.Color = Color3.fromRGB(34,34,36)
        btnStroke.Transparency = 0.9
        btnStroke.Thickness = 1

        local lbl = makeText(button, {
            Size = UDim2.new(0.72, 0, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            Text = data.Name,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(0, 84, 0, 34)
        pill.Position = UDim2.new(1, -100, 0.5, -17)
        pill.BackgroundColor3 = Color3.fromRGB(88,88,92)
        pill.Parent = button
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 30, 0, 30)
        dot.Position = UDim2.new(0, 2, 0.5, -15)
        dot.BackgroundColor3 = Color3.fromRGB(245,245,245)
        dot.Parent = pill
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

        local stateLabel = makeText(button, {
            Size = UDim2.new(0, 64, 0, 28),
            Position = UDim2.new(1, -88, 0.5, -14),
            Text = "OFF",
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center
        })

        btnObjects[i] = {
            button = button,
            pill = pill,
            dot = dot,
            stateLabel = stateLabel,
            active = false,
            callbackRaw = data.Callback,
            name = data.Name
        }

        -- Hover: solo cambio sutil, independiente del estado active
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(33,33,36)}):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(26,26,28)}):Play()
        end)

        -- Click: cambiar pill y dot, sin tocar el fondo del button
        button.MouseButton1Click:Connect(function()
            local obj = btnObjects[i]
            obj.active = not obj.active

            local pillColor = obj.active and Color3.fromRGB(34,200,34) or Color3.fromRGB(88,88,92)
            local dotTargetPos = obj.active and UDim2.new(1, -34, 0.5, -15) or UDim2.new(0, 2, 0.5, -15)
            obj.stateLabel.Text = obj.active and "ON" or "OFF"

            TweenService:Create(obj.pill, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {BackgroundColor3 = pillColor}):Play()
            TweenService:Create(obj.dot, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = dotTargetPos}):Play()

            local cb = resolveCallback(obj.callbackRaw)
            if cb then
                local ok, err = pcall(function() cb(obj.active) end)
                if not ok then
                    warn("[WeroFloatsGUI] Error ejecutando callback for "..tostring(obj.name)..": "..tostring(err))
                end
            else
                warn("[WeroFloatsGUI] No se encontró función para "..tostring(obj.name).." (callback: "..tostring(obj.callbackRaw)..")")
                -- revertir estado visual
                obj.active = not obj.active
                local revertColor = obj.active and Color3.fromRGB(34,200,34) or Color3.fromRGB(88,88,92)
                TweenService:Create(obj.pill, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = revertColor}):Play()
                TweenService:Create(obj.dot, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Position = obj.active and UDim2.new(1, -34, 0.5, -15) or UDim2.new(0, 2, 0.5, -15)}):Play()
                obj.stateLabel.Text = obj.active and "ON" or "OFF"
            end
        end)
    end

    -- Close / minimize button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -40, 0, 12)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "—"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = Color3.fromRGB(200,200,200)
    closeBtn.Parent = mainFrame

    -- guardar close position
    orig.closePos = closeBtn.Position

    local minimized = false

    closeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            -- minimizar: reducir frame
            TweenService:Create(mainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 180, 0, 48)}):Play()

            -- centrar título (anchor y position)
            titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            titleLabel.TextXAlignment = Enum.TextXAlignment.Center
            TweenService:Create(titleLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.7, 0, 0.9, 0)}):Play()

            -- mover icon a la izquierda y hacerlo más pequeño
            TweenService:Create(icon, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 8, 0.5, -24), Size = UDim2.new(0,36,0,36)}):Play()

            -- ocultar contenido (y forzar invisibilidad en descendientes)
            content.Visible = false
            for _, obj in ipairs(btnObjects) do
                if obj and obj.button then
                    obj.button.Visible = false
                    obj.pill.Visible = false
                    obj.dot.Visible = false
                    obj.stateLabel.Visible = false
                end
            end

            closeBtn.Text = "▢"
            TweenService:Create(closeBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -40, 0, 6)}):Play()
        else
            -- restaurar tamaño
            TweenService:Create(mainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Size = orig.mainSize}):Play()

            -- restaurar titulo y anchor
            TweenService:Create(titleLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = orig.titlePos, Size = orig.titleSize}):Play()
            titleLabel.AnchorPoint = orig.titleAnchor or Vector2.new(0,0)
            titleLabel.TextXAlignment = orig.titleAlign or Enum.TextXAlignment.Left

            -- restaurar icon y close btn
            TweenService:Create(icon, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = orig.iconPos, Size = orig.iconSize}):Play()
            TweenService:Create(closeBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = orig.closePos}):Play()

            -- mostrar contenido y botones
            content.Visible = orig.contentVis or true
            for _, obj in ipairs(btnObjects) do
                if obj and obj.button then
                    obj.button.Visible = true
                    obj.pill.Visible = true
                    obj.dot.Visible = true
                    obj.stateLabel.Visible = true
                end
            end

            closeBtn.Text = "—"
        end
    end)
end

local function toggleFloatsGui(state)
    if typeof(state) ~= "boolean" then
        warn("[FloatsGUI] Valor inválido.")
        return
    end
    if state then
        if not guiCreated then createGui() end
        if screenGui then screenGui.Enabled = true end
    else
        if screenGui then screenGui.Enabled = false end
    end
end

_G.ToggleWeroFloatsGUI = toggleFloatsGui

local Toggle = MainTab:CreateToggle({
    Name = "Display Floats GUI",
    Description = nil,
    CurrentValue = false,
    Callback = function(Value)
        toggleFloatsGui(Value)
    end
}, "Toggle")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Configuración
local GUI_NAME = "DesyncButtonGUI_Quick"
local BUTTON_NAME = "DesyncButton_Quick"
local TOOL_NAME = "Quantum Cloner"
local REMOTE_NAME_1 = "RE/UseItem"
local REMOTE_NAME_2 = "RE/QuantumCloner/OnTeleport"

-- Estado
local QuantumExecuted = false
local DesyncButton = nil
local DesyncToggleState = false

-- Depuración
local function dbg(...) print("[Desync]", ...) end

-- Buscar remotes
local function getRemotes()
	local rem1, rem2 = nil, nil
	pcall(function()
		local packages = ReplicatedStorage:FindFirstChild("Packages")
		if packages then
			local netFolder = packages:FindFirstChild("Net")
			if netFolder then
				rem1 = netFolder:FindFirstChild(REMOTE_NAME_1)
				rem2 = netFolder:FindFirstChild(REMOTE_NAME_2)
			end
		end
	end)
	if not rem1 then rem1 = ReplicatedStorage:FindFirstChild(REMOTE_NAME_1) end
	if not rem2 then rem2 = ReplicatedStorage:FindFirstChild(REMOTE_NAME_2) end
	return rem1, rem2
end

-- Ejecutor remoto seguro
local function safeCallRemote(remote, tool)
	if not remote then return false end
	local ok = pcall(function() remote:FireServer(tool) end)
	return ok
end

-- 🔥 Acción principal (equipar, ejecutar remotes, aplicar desync visual)
local function DoDesyncAction()
	if QuantumExecuted then return end
	QuantumExecuted = true

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:WaitForChild("HumanoidRootPart")
	local backpack = player:WaitForChild("Backpack")
	local tool = backpack:FindFirstChild(TOOL_NAME) or character:FindFirstChild(TOOL_NAME)

	if not tool or not humanoid then
		dbg("No se encontró herramienta o humanoid.")
		return
	end

	-- Equipar
	pcall(function() humanoid:EquipTool(tool) end)

	-- Ejecutar remotos
	local r1, r2 = getRemotes()
	if r1 then safeCallRemote(r1, tool) end
	task.wait(0.5)
	if r2 then safeCallRemote(r2, tool) end

	-- ⚡ Aplicar nuevos FFlags personalizados
	pcall(function()
		if setfflag then
			setfflag("DFFlagPlayerHumanoidPropertyUpdateRestrict", "False")
			setfflag("DFIntDebugDefaultTargetWorldStepsPerFrame", "-2147483648")
			setfflag("DFIntMaxMissedWorldStepsRemembered", "-2147483648")
			setfflag("DFIntWorldStepsOffsetAdjustRate", "2147483648")
			setfflag("DFIntDebugSendDistInSteps", "-2147483648")
			setfflag("DFIntWorldStepMax", "-2147483648")
			setfflag("DFIntWarpFactor", "2147483648")
			dbg("Nuevos FFlags aplicados correctamente.")
		end
	end)

	-- 🧠 Desync visual: detener replicación mientras tú te sigues moviendo
	task.spawn(function()
		local hrp = character:WaitForChild("HumanoidRootPart")
		local fakePos = hrp.CFrame
		while task.wait(0.1) do
			if not character or not hrp or not hrp.Parent then break end
			pcall(function()
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.Anchored = false
				game:GetService("RunService").Heartbeat:Wait()
				hrp.CFrame = fakePos
			end)
		end
	end)

	dbg("Desync visual activado (otros te verán bugueado).")
end

-- GUI del botón
local function removeOldGUI()
	local old = player:FindFirstChildOfClass("PlayerGui"):FindFirstChild(GUI_NAME)
	if old then old:Destroy() end
end

local function CreateDesyncButton()
	removeOldGUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local btn = Instance.new("TextButton")
	btn.Name = BUTTON_NAME
	btn.Size = UDim2.new(0,120,0,50)
	btn.Position = UDim2.new(0.85,0,0.8,0)
	btn.AnchorPoint = Vector2.new(0.5,0.5)
	btn.BackgroundColor3 = Color3.fromRGB(0,0,0)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextSize = 18
	btn.Font = Enum.Font.GothamBold
	btn.Text = "Desync"
	btn.Visible = false
	btn.Parent = gui

	btn.MouseButton1Click:Connect(function()
		dbg("Desync activado manualmente.")
		DoDesyncAction()
	end)

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0,22)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255,255,255)

	DesyncButton = btn
end

local function SetDesyncButtonVisible()
	if not DesyncButton then CreateDesyncButton() end
	DesyncButton.Visible = DesyncToggleState
end

CreateDesyncButton()

local Toggle = MainTab:CreateToggle({
	Name = "Display Desync",
	CurrentValue = false,
	Callback = function(Value)
		DesyncToggleState = Value
		SetDesyncButtonVisible()
	end
})

