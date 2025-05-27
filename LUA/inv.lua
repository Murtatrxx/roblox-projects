local StarterGui = game:GetService('StarterGui')
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local player = Players.LocalPlayer
local char = workspace:WaitForChild(player.Name)
local bp = player.Backpack
local hum = char:WaitForChild("Humanoid")
local frame = script.Parent.Frame
local template = frame.Template

-- Configuration
local CONFIG = {
    equippedTransparency = 0.2,
    unequippedTransparency = 0.7,
    iconSize = template.Size,
    iconBorder = { x = 15, y = 5 },
    cooldownColor = Color3.fromRGB(100, 100, 100),
    normalColor = Color3.fromRGB(255, 255, 255),
    tooltipFadeTime = 0.3,
    defaultCooldown = 1, -- seconds
}

local inputKeys = {
    ["One"]   = { txt = "1", slot = 1 },
    ["Two"]   = { txt = "2", slot = 2 },
    ["Three"] = { txt = "3", slot = 3 },
    ["Four"]  = { txt = "4", slot = 4 },
    ["Five"]  = { txt = "5", slot = 5 }
}

local inputOrder = {
    inputKeys["One"],
    inputKeys["Two"],
    inputKeys["Three"],
    inputKeys["Four"],
    inputKeys["Five"]
}

local cooldowns = {}
local dragging = nil
local hotbarConfig = {}

local tooltip = Instance.new("Frame")
tooltip.Size = UDim2.new(0, 200, 0, 50)
tooltip.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tooltip.BackgroundTransparency = 0.2
tooltip.Visible = false
tooltip.Parent = frame

local tooltipLabel = Instance.new("TextLabel")
tooltipLabel.Size = UDim2.new(1, -10, 1, -10)
tooltipLabel.Position = UDim2.new(0, 5, 0, 5)
tooltipLabel.BackgroundTransparency = 1
tooltipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
tooltipLabel.TextScaled = true
tooltipLabel.Parent = tooltip

local function saveHotbarConfig()
    hotbarConfig = {}
    for i, value in ipairs(inputOrder) do
        if value.tool then
            hotbarConfig[value.txt] = value.tool.Name
        end
    end
end

local function loadHotbarConfig()
    for key, toolName in pairs(hotbarConfig) do
        local tool = bp:FindFirstChild(toolName) or char:FindFirstChild(toolName)
        if tool then
            for _, value in ipairs(inputOrder) do
                if value.txt == key and not value.tool then
                    value.tool = tool
                    break
                end
            end
        end
    end
end

local function showTooltip(icon, tool)
    if tool then
        tooltip.Position = UDim2.new(0, icon.Position.X.Offset, 0, -60)
        tooltipLabel.Text = tool.Name .. "\n" .. (tool:GetAttribute("Description") or "No description")
        tooltip.Visible = true
    end
end

local function hideTooltip()
    tooltip.Visible = false
end

local function startCooldown(icon, duration)
    cooldowns[icon] = duration or CONFIG.defaultCooldown
    icon.ImageColor3 = CONFIG.cooldownColor
    local startTime = tick()
    
    while cooldowns[icon] and cooldowns[icon] > 0 do
        cooldowns[icon] = math.max(0, cooldowns[icon] - (tick() - startTime))
        icon.Tool.ImageTransparency = CONFIG.equippedTransparency + (cooldowns[icon] / duration) * 0.5
        wait()
    end
    
    if icon and icon.Parent then
        icon.ImageColor3 = CONFIG.normalColor
        icon.Tool.ImageTransparency = icon.Tool.Parent.Parent.ImageTransparency
        cooldowns[icon] = nil
    end
end

local function handleEquip(tool, icon)
    if tool and not cooldowns[icon] then
        if tool.Parent ~= char then
            hum:EquipTool(tool)
            startCooldown(icon, tool:GetAttribute("Cooldown") or CONFIG.defaultCooldown)
        else
            hum:UnequipTools()
        end
    end
end

local function create()
    local toShow = #inputOrder
    local totalX = (toShow * CONFIG.iconSize.X.Offset) + ((toShow + 1) * CONFIG.iconBorder.x)
    local totalY = CONFIG.iconSize.Y.Offset + (2 * CONFIG.iconBorder.y)
    
    frame.Size = UDim2.new(0, totalX, 0, totalY)
    frame.Position = UDim2.new(0.5, - (totalX / 2), 1, - (totalY + (CONFIG.iconBorder.y * 2)))
    frame.Visible = true

    for i, value in ipairs(inputOrder) do
        local clone = template:Clone()
        clone.Parent = frame
        clone.Label.Text = value.txt
        clone.Name = value.txt
        clone.Visible = true
        clone.Position = UDim2.new(0, (i-1) * CONFIG.iconSize.X.Offset + (CONFIG.iconBorder.x * i), 0, CONFIG.iconBorder.y)
        
        if value.tool then
            clone.Tool.Image = value.tool.TextureId
        end

        -- Mouse interactions
        clone.Tool.MouseButton1Down:Connect(function()
            handleEquip(value.tool, clone)
        end)
        
        clone.Tool.MouseEnter:Connect(function()
            showTooltip(clone, value.tool)
        end)
        
        clone.Tool.MouseLeave:Connect(hideTooltip)
        
        -- Drag and drop
        clone.Tool.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = {icon = clone, originalSlot = value}
            end
        end)
        
        clone.Tool.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
                for _, otherValue in ipairs(inputOrder) do
                    if otherValue.txt == clone.Name and dragging.originalSlot ~= otherValue then
                        -- Swap tools
                        local tempTool = otherValue.tool
                        otherValue.tool = dragging.originalSlot.tool
                        dragging.originalSlot.tool = tempTool
                        adjust()
                        saveHotbarConfig()
                        break
                    end
                end
                dragging = nil
            end
        end)
    end
    
    template:Destroy()
end

local function setup()
    loadHotbarConfig()
    local tools = bp:GetChildren()
    for _, tool in ipairs(tools) do
        if tool:IsA("Tool") then
            for _, value in ipairs(inputOrder) do
                if not value.tool then
                    value.tool = tool
                    break
                end
            end
        end
    end
    create()
    adjust()
    saveHotbarConfig()
end

local function adjust()
    for _, value in ipairs(inputOrder) do
        local tool = value.tool
        local icon = frame:FindFirstChild(value.txt)
        if icon then
            if tool then
                icon.Tool.Image = tool.TextureId
                icon.ImageTransparency = tool.Parent == char and not cooldowns[icon] 
                    and CONFIG.equippedTransparency or CONFIG.unequippedTransparency
            else
                icon.Tool.Image = ""
                icon.ImageTransparency = CONFIG.unequippedTransparency
            end
            icon.ImageColor3 = cooldowns[icon] and CONFIG.cooldownColor or CONFIG.normalColor
        end
    end
end

local function onKeyPress(inputObject)
    local key = inputObject.KeyCode.Name
    local value = inputKeys[key]
    if value and UserInputService:GetFocusedTextBox() == nil then
        local icon = frame:FindFirstChild(value.txt)
        handleEquip(value.tool, icon)
    end
end

local function handleAddition(adding)
    if adding:IsA("Tool") then
        local new = true
        for _, value in ipairs(inputOrder) do
            if value.tool == adding then
                new = false
                break
            end
        end

        if new then
            for _, value in ipairs(inputOrder) do
                if not value.tool then
                    value.tool = adding
                    break
                end
            end
        end

        adjust()
        saveHotbarConfig()
    end
end

local function handleRemoval(removing)
    if removing:IsA("Tool") and removing.Parent ~= char and removing.Parent ~= bp then
        for _, value in ipairs(inputOrder) do
            if value.tool == removing then
                value.tool = nil
                break
            end
        end
        adjust()
        saveHotbarConfig()
    end
end

UserInputService.InputBegan:Connect(onKeyPress)
char.ChildAdded:Connect(handleAddition)
char.ChildRemoved:Connect(handleRemoval)
bp.ChildAdded:Connect(handleAddition)
bp.ChildRemoved:Connect(handleRemoval)

setup()
