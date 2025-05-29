--[[
    Hotbar System
    Manages a customizable hotbar for equipping tools in Roblox.
    Configuration: Edit the CONFIG table to adjust appearance and behavior.
    Usage: Place this script in a ScreenGui under StarterGui.
    Dependencies: Requires a Frame with a Template child (ImageLabel and TextLabel) in the script's parent.
]]

local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Disable default backpack UI
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Player and character setup with error handling
local player = Players.LocalPlayer
local char = workspace:WaitForChild(player.Name, 5)
if not char then
    warn("Character not found for player: " .. player.Name)
    return
end
local bp = player.Backpack
local hum = char:WaitForChild("Humanoid", 5)
if not hum then
    warn("NOHUM " .. player.Name)
    return
end
local frame = script.Parent.Frame
local template = frame.Template

-- Configuration table for easy customization
local CONFIG = {
    equippedTransparency = 0.2,
    unequippedTransparency = 0.7,
    iconSize = template.Size,
    iconBorder = { x = 15, y = 5 },
    cooldownColor = Color3.fromRGB(100, 100, 100),
    normalColor = Color3.fromRGB(255, 255, 255),
    tooltipFadeTime = 0.3,
    defaultCooldown = 1, -- seconds
    tooltipSize = UDim2.new(0, 200, 0, 50),
    tooltipBackgroundColor = Color3.fromRGB(50, 50, 50),
    tooltipBackgroundTransparency = 0.2
}

-- Input key mappings
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

-- State variables
local cooldowns = {}
local dragging = nil
local hotbarConfig = {}
local connections = {} -- Store event connections for cleanup

-- Tooltip setup
local tooltip = Instance.new("Frame")
tooltip.Size = CONFIG.tooltipSize
tooltip.BackgroundColor3 = CONFIG.tooltipBackgroundColor
tooltip.BackgroundTransparency = CONFIG.tooltipBackgroundTransparency
tooltip.Visible = false
tooltip.Parent = frame

local tooltipLabel = Instance.new("TextLabel")
tooltipLabel.Size = UDim2.new(1, -10, 1, -10)
tooltipLabel.Position = UDim2.new(0, 5, 0, 5)
tooltipLabel.BackgroundTransparency = 1
tooltipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
tooltipLabel.TextScaled = true
tooltipLabel.Parent = tooltip

-- Saves the current hotbar configuration
local function saveHotbarConfig()
    hotbarConfig = {}
    for i, value in ipairs(inputOrder) do
        if value.tool then
            hotbarConfig[value.txt] = value.tool.Name
        end
    end
end

-- Loads saved hotbar configuration
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

-- Shows tooltip with tool information
local function showTooltip(icon, tool)
    if not tool then return end
    tooltip.Position = UDim2.new(0, icon.Position.X.Offset, 0, -CONFIG.tooltipSize.Y.Offset - 10)
    tooltipLabel.Text = tool.Name .. "\n" .. (tool:GetAttribute("Description") or "No description")
    tooltip.Visible = true
end

-- Hides the tooltip
local function hideTooltip()
    tooltip.Visible = false
end

-- Starts a cooldown animation for an icon
local function startCooldown(icon, duration)
    if not icon or not icon.Parent then return end
    cooldowns[icon] = duration or CONFIG.defaultCooldown
    icon.ImageColor3 = CONFIG.cooldownColor
    local startTime = tick()
    
    while cooldowns[icon] and cooldowns[icon] > 0 do
        cooldowns[icon] = math.max(0, cooldowns[icon] - (tick() - startTime))
        icon.Tool.ImageTransparency = CONFIG.equippedTransparency + (cooldowns[icon] / duration) * 0.5
        task.wait()
    end
    
    if icon and icon.Parent then
        icon.ImageColor3 = CONFIG.normalColor
        icon.Tool.ImageTransparency = icon.Tool.Parent.Parent.ImageTransparency
        cooldowns[icon] = nil
    end
end

-- Equips or unequips a tool
local function handleEquip(tool, icon)
    if not tool or cooldowns[icon] then return end
    if tool.Parent ~= char then
        hum:EquipTool(tool)
        startCooldown(icon, tool:GetAttribute("Cooldown") or CONFIG.defaultCooldown)
    else
        hum:UnequipTools()
    end
end

-- Creates a single hotbar icon
local function createIcon(value, index)
    local clone = template:Clone()
    clone.Parent = frame
    clone.Label.Text = value.txt
    clone.Name = value.txt
    clone.Visible = true
    clone.Position = UDim2.new(0, (index - 1) * CONFIG.iconSize.X.Offset + (CONFIG.iconBorder.x * index), 0, CONFIG.iconBorder.y)
    if value.tool then
        clone.Tool.Image = value.tool.TextureId
    end
    return clone
end

-- Binds mouse and drag-and-drop events to an icon
local function bindIconEvents(clone, value)
    table.insert(connections, clone.Tool.MouseButton1Down:Connect(function()
        handleEquip(value.tool, clone)
    end))
    table.insert(connections, clone.Tool.MouseEnter:Connect(function()
        showTooltip(clone, value.tool)
    end))
    table.insert(connections, clone.Tool.MouseLeave:Connect(hideTooltip))
    table.insert(connections, clone.Tool.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = { icon = clone, originalSlot = value }
        end
    end))
    table.insert(connections, clone.Tool.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            for _, otherValue in ipairs(inputOrder) do
                if otherValue.txt == clone.Name and dragging.originalSlot ~= otherValue then
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
    end))
end

-- Configures the hotbar frame size and position
local function configureFrame()
    local toShow = #inputOrder
    local totalX = (toShow * CONFIG.iconSize.X.Offset) + ((toShow + 1) * CONFIG.iconBorder.x)
    local totalY = CONFIG.iconSize.Y.Offset + (2 * CONFIG.iconBorder.y)
    frame.Size = UDim2.new(0, totalX, 0, totalY)
    frame.Position = UDim2.new(0.5, -totalX / 2, 1, -(totalY + CONFIG.iconBorder.y * 2))
    frame.Visible = true
end

-- Creates all hotbar icons and binds events
local function create()
    configureFrame()
    for i, value in ipairs(inputOrder) do
        local clone = createIcon(value, i)
        bindIconEvents(clone, value)
    end
    template:Destroy()
end

-- Updates a single hotbar slot's appearance
local function adjustSingleSlot(value)
    local icon = frame:FindFirstChild(value.txt)
    if not icon then return end
    if value.tool then
        icon.Tool.Image = value.tool.TextureId
        icon.ImageTransparency = value.tool.Parent == char and not cooldowns[icon] 
            and CONFIG.equippedTransparency or CONFIG.unequippedTransparency
    else
        icon.Tool.Image = ""
        icon.ImageTransparency = CONFIG.unequippedTransparency
    end
    icon.ImageColor3 = cooldowns[icon] and CONFIG.cooldownColor or CONFIG.normalColor
end

-- Updates all hotbar slots
local function adjust()
    for _, value in ipairs(inputOrder) do
        adjustSingleSlot(value)
    end
end

-- Assigns tools to empty slots
local function assignTools()
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
end

-- Initializes the hotbar
local function setup()
    loadHotbarConfig()
    assignTools()
    create()
    adjust()
    saveHotbarConfig()
end

-- Handles keypress input for equipping tools
local function onKeyPress(inputObject)
    if UserInputService:GetFocusedTextBox() then return end
    local key = inputObject.KeyCode.Name
    local value = inputKeys[key]
    if value then
        local icon = frame:FindFirstChild(value.txt)
        handleEquip(value.tool, icon)
    end
end

-- Handles adding a tool to the hotbar
local function handleAddition(adding)
    if not adding:IsA("Tool") then return end
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
                adjustSingleSlot(value)
                saveHotbarConfig()
                break
            end
        end
    end
end

-- Handles removing a tool from the hotbar
local function handleRemoval(removing)
    if not removing:IsA("Tool") or removing.Parent == char or removing.Parent == bp then return end
    for _, value in ipairs(inputOrder) do
        if value.tool == removing then
            value.tool = nil
            adjustSingleSlot(value)
            saveHotbarConfig()
            break
        end
    end
end

-- Bind events
table.insert(connections, UserInputService.InputBegan:Connect(onKeyPress))
table.insert(connections, char.ChildAdded:Connect(handleAddition))
table.insert(connections, char.ChildRemoved:Connect(handleRemoval))
table.insert(connections, bp.ChildAdded:Connect(handleAddition))
table.insert(connections, bp.ChildRemoved:Connect(handleRemoval))

-- Cleanup function to disconnect events
local function cleanup()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    connections = {}
end

-- Connect cleanup on script destruction
table.insert(connections, script.AncestryChanged:Connect(function(_, parent)
    if parent == nil then
        cleanup()
    end
end))

-- Initialize the hotbar
setup()
