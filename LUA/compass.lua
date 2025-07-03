--[[
Hi, welcome to my scipt where I code my own compass, this was quite the journey and I hope you like my code, Scriptone
it's a bit long but I tried to make it as readable as possible. As I explain below, it is fully standalone and self-contained
and needs nothing more than the script itself.

The script is completely standalone and self-contained, it creates all of the needed assets itself and needs nothing more -- This is by design

It has many little features, sound aid, haptic feedback and tweening to name a few. It has some advanced math/cframe calculation, hope I explained them well.

You can skip to line ~230 for actual logic. All before is either import or UI setup.
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")
local SoundService      = game:GetService("SoundService")

local player            = Players.LocalPlayer or Players.PlayerAdded:Wait()
local camera            = workspace.CurrentCamera or workspace:WaitForChild("Camera", 5)

-- I set this to false because i was testing UI in studio too andi i didn't want it to double appear to I disable it first and script overrides
player.PlayerGui:WaitForChild("CompassGUI", 5).Enabled = false

local waypointSound =Instance.new("Sound") 
waypointSound.Name = "WaypointProximity"
waypointSound.SoundId = "rbxassetid://72841109192126"  -- Some audio i found from the toolbox
waypointSound.Volume = 0.5
waypointSound.Parent = SoundService

local screenGui =Instance.new("ScreenGui")
screenGui.Name = "CompassGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui", 5)

-- Parent frame, contains all but debug label
local compassGui = Instance.new("Frame")
compassGui.Name = "Compass"
compassGui.Size = UDim2.new(0.8, 0, 0, 50)
compassGui.Position = UDim2.new(0.5, 0, 0.1, 0)
compassGui.AnchorPoint = Vector2.new(0.5, 0)
compassGui.BackgroundTransparency = 1
compassGui.Parent = screenGui

local compassStrip = Instance.new("Frame")
compassStrip.Name = "Strip"
compassStrip.Size = UDim2.new(1, 0, 1, 0)
compassStrip.Position = UDim2.new(0, 0, 0, 0)
compassStrip.BackgroundTransparency = 1
compassStrip.Parent = compassGui

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Name = "Selected"
selectedLabel.Text = "Selected: None (Tap Waypoint to select)"
selectedLabel.AnchorPoint = Vector2.new(0.5, 0.5)
selectedLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
selectedLabel.Position = UDim2.new(0.5, 0, 0, -30)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
selectedLabel.TextScaled = true
selectedLabel.Font = Enum.Font.SourceSansBold
selectedLabel.Parent = compassGui

-- To rename and delete waypoints
local managementPanel = Instance.new("Frame")
managementPanel.Name = "ManagementPanel"
managementPanel.Size = UDim2.new(0.3, 0, 0.15, 0)
managementPanel.Position = UDim2.new(0.35, 0, 0.25, 0)
managementPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
managementPanel.BackgroundTransparency = 0.2
managementPanel.BorderSizePixel = 2
managementPanel.BorderColor3 = Color3.fromRGB(100, 100, 100)
managementPanel.Visible = false
managementPanel.Parent = screenGui

local managementTitle = Instance.new("TextLabel")
managementTitle.Name = "Title"
managementTitle.Size = UDim2.new(1, 0, 0.3, 0)
managementTitle.Position = UDim2.new(0, 0, 0, 0)
managementTitle.BackgroundTransparency = 1
managementTitle.Text = "Waypoint Management"
managementTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
managementTitle.TextScaled = true
managementTitle.Font = Enum.Font.SourceSansBold
managementTitle.Parent = managementPanel

local renameButton = Instance.new("TextButton")
renameButton.Name = "RenameButton"
renameButton.Size = UDim2.new(0.45, 0, 0.3, 0)
renameButton.Position = UDim2.new(0.025, 0, 0.35, 0)
renameButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
renameButton.BorderSizePixel = 1
renameButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
renameButton.Text = "Rename"
renameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
renameButton.TextScaled = true
renameButton.Font = Enum.Font.SourceSansBold
renameButton.Parent = managementPanel

local deleteButton = Instance.new("TextButton")
deleteButton.Name = "DeleteButton"
deleteButton.Size = UDim2.new(0.45, 0, 0.3, 0)
deleteButton.Position = UDim2.new(0.525, 0, 0.35, 0)
deleteButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
deleteButton.BorderSizePixel = 1
deleteButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
deleteButton.Text = "Delete"
deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteButton.TextScaled = true
deleteButton.Font = Enum.Font.SourceSansBold
deleteButton.Parent = managementPanel

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(1, 0, 0.25, 0)
closeButton.Position = UDim2.new(0, 0, 0.75, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
closeButton.BorderSizePixel = 1
closeButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = managementPanel

-- Rename dialog
local renameDialog = Instance.new("Frame")
renameDialog.Name = "RenameDialog"
renameDialog.Size = UDim2.new(0.4, 0, 0.2, 0)
renameDialog.Position = UDim2.new(0.3, 0, 0.4, 0)
renameDialog.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
renameDialog.BackgroundTransparency = 0.1
renameDialog.BorderSizePixel = 2
renameDialog.BorderColor3 = Color3.fromRGB(150, 150, 150)
renameDialog.Visible = false
renameDialog.Parent = screenGui

local renameTitle = Instance.new("TextLabel")
renameTitle.Name = "Title"
renameTitle.Size = UDim2.new(1, 0, 0.3, 0)
renameTitle.Position = UDim2.new(0, 0, 0, 0)
renameTitle.BackgroundTransparency = 1
renameTitle.Text = "Rename Waypoint"
renameTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
renameTitle.TextScaled = true
renameTitle.Font = Enum.Font.SourceSansBold
renameTitle.Parent = renameDialog

local renameTextBox = Instance.new("TextBox")
renameTextBox.Name = "TextBox"
renameTextBox.Size = UDim2.new(0.9, 0, 0.25, 0)
renameTextBox.Position = UDim2.new(0.05, 0, 0.35, 0)
renameTextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
renameTextBox.BorderSizePixel = 1
renameTextBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
renameTextBox.Text = ""
renameTextBox.PlaceholderText = "Enter new name..."
renameTextBox.TextColor3 = Color3.fromRGB(0, 0, 0)
renameTextBox.TextScaled = true
renameTextBox.Font = Enum.Font.SourceSans
renameTextBox.Parent = renameDialog

local confirmRenameButton = Instance.new("TextButton")
confirmRenameButton.Name = "ConfirmButton"
confirmRenameButton.Size = UDim2.new(0.4, 0, 0.25, 0)
confirmRenameButton.Position = UDim2.new(0.1, 0, 0.7, 0)
confirmRenameButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
confirmRenameButton.BorderSizePixel = 1
confirmRenameButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
confirmRenameButton.Text = "Confirm"
confirmRenameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmRenameButton.TextScaled = true
confirmRenameButton.Font = Enum.Font.SourceSansBold
confirmRenameButton.Parent = renameDialog

local cancelRenameButton = Instance.new("TextButton")
cancelRenameButton.Name = "CancelButton"
cancelRenameButton.Size = UDim2.new(0.4, 0, 0.25, 0)
cancelRenameButton.Position = UDim2.new(0.5, 0, 0.7, 0)
cancelRenameButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
cancelRenameButton.BorderSizePixel = 1
cancelRenameButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
cancelRenameButton.Text = "Cancel"
cancelRenameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelRenameButton.TextScaled = true
cancelRenameButton.Font = Enum.Font.SourceSansBold
cancelRenameButton.Parent = renameDialog

local waypointTemplate = Instance.new("ImageButton")
waypointTemplate.Name = "Waypoint"
waypointTemplate.Size = UDim2.new(0, 40, 0, 40)
waypointTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
waypointTemplate.AutoButtonColor = false
waypointTemplate.Image = "" -- I could've used a bg color instead of image but whatever
waypointTemplate.ImageTransparency = 0.5
waypointTemplate.BackgroundTransparency = 0
waypointTemplate.Visible = false
waypointTemplate.ClipsDescendants = false
waypointTemplate.AnchorPoint = Vector2.new(0.5, 0.5)

local textLabel = Instance.new("TextLabel")
textLabel.Name = "TextLabel"
textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
textLabel.Size = UDim2.new(2, 0, 0.5, 0)
textLabel.Position = UDim2.new(0.5, 0, 1.3, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.SourceSansBold
textLabel.Text = ""
textLabel.Parent = waypointTemplate

waypointTemplate.Parent = screenGui

local debugLabel = Instance.new("TextLabel")
debugLabel.Name = "Debug"
debugLabel.Text = "Debug: OFF"
debugLabel.AnchorPoint = Vector2.new(0.5, 1)  
debugLabel.Size = UDim2.new(0.35, 0, 0.05, 0)
debugLabel.Position = UDim2.new(0.5, 0, 1, -10)
debugLabel.BackgroundTransparency = 1
debugLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
debugLabel.TextScaled = true
debugLabel.Font = Enum.Font.RobotoMono -- Mono font because otherwise numbers scale and jump around a bit too much
debugLabel.Visible = false
debugLabel.Parent = screenGui

-- Waypoints folader
local waypointFolder = Instance.new("Folder")
waypointFolder.Name = "Waypoints"
waypointFolder.Parent = workspace

local waypoints = {}
local selectedWaypoint = nil
local pulseToggle = false
local debugMode = false

local COMPASS_FOV = math.pi / 2.2 -- equates to around ~82 degrees of field of vision
local COMPASS_SPREAD = 0.4 -- This controls how far elements spread horizontally

-- Here I define each direction's angle and color. I gave primary ones a distinct color
local directions = {
  { label = "N", angle = 0, color = Color3.fromRGB(255, 0, 0) },
  { label = "NE", angle = math.pi / 4, color = Color3.fromRGB(255, 255, 255) },
  { label = "E", angle = math.pi / 2, color = Color3.fromRGB(0, 0, 255) },
  { label = "SE", angle = 3 * math.pi / 4, color = Color3.fromRGB(255, 255, 255) },
  { label = "S", angle = math.pi, color = Color3.fromRGB(0, 255, 0) },
  { label = "SW", angle = -3 * math.pi / 4, color = Color3.fromRGB(255, 255, 255) },
  { label = "W", angle = -math.pi / 2, color = Color3.fromRGB(255, 255, 0) },
  { label = "NW", angle = -math.pi / 4, color = Color3.fromRGB(255, 255, 255) },
}

-- Helper func, to keep angles between -pi and pi
local function restrictAngle(angle)
  -- Look at that readable math(!)
  if angle<-math.pi then
    return angle+2*math.pi
  elseif angle>math.pi then
    return angle-2*math.pi
  end
  return angle
end

-- Position each direction label initially, as these positions will be overwritten by acutal compass behaviour
for _, dir in ipairs(directions) do
  local label       = Instance.new("TextLabel")
  label.Name        = dir.label
  label.Size        = UDim2.new(0, 30, 0, 30)
  label.Position    = UDim2.new(0.5, 0, 0.5, 0)
  label.Text        = dir.label
  label.TextColor3  = dir.color
  label.TextScaled  = true
  label.Font        = Enum.Font.SourceSansBold
  label.AnchorPoint = Vector2.new(0.5, 0.5)
  label.Parent      = compassStrip
  label.BackgroundTransparency = 1
  
  dir.object = label
end

-- Waypoint Management funcs, to rename and delete the selected WP
local function deleteWaypoint(waypoint)
  if waypoint and waypoint.part then
    for i, wp in ipairs(waypoints) do
      if wp == waypoint then
        table.remove(waypoints, i)
        break
      end
    end

    waypoint.part:Destroy()
    waypoint.ui:Destroy()

    if selectedWaypoint == waypoint then
      selectedWaypoint = nil
      selectedLabel.Text = "Selected: None (Tap Waypoint to select)"
    end

    managementPanel.Visible = false

    pcall(function()
      StarterGui:SetCore("Vibrate", Enum.VibrationMotor.Small)
    end)
  end
end

local function renameWaypoint(waypoint, newName)
  if waypoint and waypoint.part and newName and newName ~= "" then
    waypoint.part.Name = newName
    waypoint.ui.Name = newName

    -- Update selected label if this is the selected waypoint
    if selectedWaypoint == waypoint then
      selectedLabel.Text = "Selected: "..newName
    end

    pcall(function()
      StarterGui:SetCore("Vibrate",Enum.VibrationMotor.Small)
    end)
  end
end

-- Handlers for Waypoint ui mgr
renameButton.MouseButton1Click:Connect(function()
  if selectedWaypoint then
    renameTextBox.Text      = selectedWaypoint.part.Name
    renameDialog.Visible    = true
    managementPanel.Visible = false
    renameTextBox:CaptureFocus()
  end
end)

--slick oneliners
deleteButton.MouseButton1Click:Connect(function() if selectedWaypoint then deleteWaypoint(selectedWaypoint) end end)
closeButton.MouseButton1Click:Connect(function() managementPanel.Visible = false end)

-- Handlers for rename dialogue
confirmRenameButton.MouseButton1Click:Connect(function()
  if selectedWaypoint then
    local newName =renameTextBox.Text:gsub("^%s*(.-)%s*$", "%1")--Trim whitespace like spaces or invisible unicode characters
    if newName ~= "" then
      renameWaypoint(selectedWaypoint, newName)
    end
  end
  renameDialog.Visible = false
end)

cancelRenameButton.MouseButton1Click:Connect(function() renameDialog.Visible = false end)

-- Same thing, but now for enter key
renameTextBox.FocusLost:Connect(function(enterPressed)
  if enterPressed and selectedWaypoint then
    local newName = renameTextBox.Text:gsub("^%s*(.-)%s*$", "%1")
    if newName ~= "" then
      renameWaypoint(selectedWaypoint, newName)
    end
    renameDialog.Visible = false;
  end
end)


-- [MAIN WAYPOINT TABLE]
local Waypoint = {}
Waypoint.__index = Waypoint

function Waypoint.new(part)
  local self = setmetatable({}, Waypoint)
  self.part = part
  self.ui = waypointTemplate:Clone()
  self.ui.Visible = true
  self.ui.Name = part.Name
  self.ui.Parent = compassGui
  self.tag = CollectionService:HasTag(part, "Important")
  self.scale = 1
  self.soundPlayed = false

  -- Connect click event for waypoint selection
  self.ui.MouseButton1Click:Connect(function()
    selectedWaypoint = self
    selectedLabel.Text = "Selected: ".. self.part.Name
    pcall(function()
      StarterGui:SetCore("Vibrate", Enum.VibrationMotor.Small)
    end)
  end)

  return self
end

-- This runs every render step, updating the position of the waypoint on the compass
function Waypoint:update(dt, lookY)
  if not self.part or not self.part.Parent then
    self.ui:Destroy()
    return false
  end
  local dir = (self.part.Position-camera.CFrame.Position)
  dir = Vector3.new(dir.X,0,dir.Z).Unit -- GEt the unit vector for the direction of compass
  local angle = math.atan2(dir.Z, dir.X)
  local rel = restrictAngle(angle-lookY)
  local dist = (self.part.Position - camera.CFrame.Position).Magnitude

  -- Plays sound and vibrates when you come near some waypoint
  if dist < 10 and not self.soundPlayed then
    waypointSound:Play()
    self.soundPlayed = true
    pcall(function()
      StarterGui:SetCore("Vibrate", Enum.VibrationMotor.Large)
    end)
  elseif dist >= 10 and self.soundPlayed then
    self.soundPlayed = false
  end
  
  --[[
  This is some of the more advanced math stuff and i will try to give a top-level explaination of how things work here
  So this manages the display and positioning of the compass, it determines whether the element should be visible based on its relative angle (rel) within the COMPASS_FOV, and if visible, direction label is positioned on-screen by normalizing the angle to -1 to 1 range and scaling it with COMPASS_SPREAD to calculate its horizontal position, posX.
  - And, the indicator smoothly transitions to this position using tweenservice
  - Text shows the name of the associated object's self.part.Name and its distance in studs (dist). The text's transparency fades based on how close the angle is to the edge of the field of view, creating a smooth fade effect. 
  - Waypoint indicator's size scales dynamically based on distance, it shrinks as the object gets further away
  
  Additionallt, if relative angle exceeds `COMPASS_FOV`,wp indicator  is hidden away. 
  at the end, returns `true` if successful.
  ]]

  if math.abs(rel) < COMPASS_FOV then
    local normalizedAngle = rel / COMPASS_FOV -- Normalize to -1 to 1
    local posX = 0.5 + normalizedAngle * COMPASS_SPREAD
    self.ui.Visible = true
    self.ui:TweenPosition(UDim2.new(posX, 0, 0.5, 0), "Out", "Quad", 0.1, true)
    self.ui.TextLabel.Text = self.part.Name .. "\n(" .. math.floor(dist) .. " studs)"

    -- This couple (with line 546) tend to perform better at transparency calculation
    local fadeStrength = math.abs(normalizedAngle)
    self.ui.TextLabel.TextTransparency = 0.2 + 0.6 * fadeStrength

    self.ui.BackgroundColor3 = self.tag and Color3.fromRGB(255, 170, 0) or (selectedWaypoint == self and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 255, 255))
    self.scale               = 1.0 + math.clamp(1 - dist / 100, 0, 1)
    self.ui.Size             = UDim2.new(0, 40 * self.scale, 0, 40 * self.scale)

    if self.tag and pulseToggle then
      self.ui.BackgroundTransparency = 0.2
    else
      self.ui.BackgroundTransparency = 0
    end
  else
    self.ui.Visible = false
  end
  return true
end

-- 
for _, part in ipairs(waypointFolder:GetChildren()) do
  if part:IsA("BasePart") then
    table.insert(waypoints, Waypoint.new(part))
  end
end


-- Handle key presses: G, M, C, and F
UserInputService.InputBegan:Connect(function(input, gpe)
  -- Game processed event
  if gpe then return end
  if input.KeyCode == Enum.KeyCode.F then
    
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local ray = camera:ScreenPointToRay(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)     
    if result and result.Instance then  
      local newPart      = Instance.new("Part") 
      newPart.Size       = Vector3.new(1,1,1) 
      newPart.Position   = result.Position + Vector3.new(0, 2, 0)
      newPart.Anchored   = true
      newPart.Name       = "TempWaypoint_" .. #waypoints + 1 -- Give it a temporary name until you rename it via waypoint manager
      newPart.BrickColor = BrickColor.random() -- Random color for easy differentiation between waypoints
      newPart.Parent     = waypointFolder
      
      table.insert(waypoints, Waypoint.new(newPart))
      pcall(function()
        StarterGui:SetCore("Vibrate", Enum.VibrationMotor.Large)
        waypointSound:Play()
      end)
    end
  elseif input.KeyCode == Enum.KeyCode.C then
    compassGui.Visible = not compassGui.Visible
  elseif input.KeyCode == Enum.KeyCode.G then
    debugMode = not debugMode
    debugLabel.Visible = debugMode
    debugLabel.Text = debugMode and "Debug: ON" or "Debug: OFF"
  elseif input.KeyCode == Enum.KeyCode.M then
    if selectedWaypoint then
      managementPanel.Visible = not managementPanel.Visible
    end
  end
end)

-- State variables, these control how compass and directions are gonna be rendered
local lookY = 0 -- lookY is the current angle (yaw) of the camera
local smoothness = 10 -- How smooth the tween needs to be
local pulseTimer = 0 -- This was intended to control the pulse effect but it doesn't work as of now

-- Here is the second advacned part of the compass system and one of the most critical ones,
-- i tried to explain it in clear groups
-- 
-- 1. camera look direction processing
--     First, extract the camera's look vector and flatten it to the XZ plane (remoe Y)
--     This gives us the horizontal direction the camera is facing
--     Convert to unit vector for consistent magnitude
--
-- 2) Angle calc and smoothing
--     math.atan2(look.Z, look.X) converts the look vector to a rotation angle in radians
--     restrictAngle i defined earlier ensures angles stay within -pi and (+)pi range to prevent wrapping issues
--     Smooth LERPing using this formula;
--     lookY = lookY + (targetAngle - currentAngle) * deltaTime * smoothness
--
-- 3) directionl label positibning
--     For each compass direction (N, NE, E,and such) calculate offset from current camera angle
--     restrictAngle(lookY - dir.angle) finds the relative angle between camera and direction
--     Only show directions within COMPASS_FOV to avoid clutter
--
-- 4) screen position mapping
--     normalizedAngle = offset/COMPASS_FOV converts the angle to a -1 to 1 range
--     posX            = 0.5+normalizedAngle*COMPASS_SPREAD maps this to screen coordinates
--     center (0.5) represents middle of compass, spread controls how far elements extend on the horizontal axis
--
-- 5) transparency fade effect
--     fadeStrength      = math.abs(normalizedAngle) gives distance from center (0.00-1.00)
--     TextTransparency  = 0.2 + 0.6 * fadeStrength creates smooth fade from center to edges
--     Thus making central elements more visible while fading auxilarry ones
--
RunService.RenderStepped:Connect(function(dt)
  if not camera or not player.Character then return end
  local look = camera.CFrame.LookVector
  look = Vector3.new(look.X, 0, look.Z).Unit
  local currentY = math.atan2(look.Z, look.X)
  local diff = restrictAngle(currentY - lookY)
  lookY = restrictAngle(lookY + diff * dt * smoothness)

  for _, dir in ipairs(directions) do
    local offset = restrictAngle(lookY - dir.angle)
    if math.abs(offset) < COMPASS_FOV then
      local normalizedAngle = offset / COMPASS_FOV -- Normalize to -1 to 1
      local posX = 0.5 + normalizedAngle * COMPASS_SPREAD
      dir.object.Position = UDim2.new(posX, 0, 0.5, 0)

      --This tends ot be abetter transparency calculation for wider FOVs
      local fadeStrength = math.abs(normalizedAngle)
      dir.object.TextTransparency = 0.2 + 0.6 * fadeStrength
      dir.object.Visible = true
    else
      dir.object.Visible = false
    end
  end

  pulseTimer += dt
  if pulseTimer > 0.5 then
    pulseToggle = not pulseToggle
    pulseTimer = 0
  end

  --Update waypoints and clean up possibly corrupt ones
  for i = #waypoints, 1, -1 do
    if not waypoints[i]:update(dt, lookY) then
      table.remove(waypoints, i)
    end
  end

  -- debug info
  if debugMode then
    debugLabel.Text = string.format("Yaw: %.2f | Waypoints: %d | FOV: %.1f°", math.deg(lookY), #waypoints, math.deg(COMPASS_FOV * 2))
  end
end)

-- Helper prints in case you can access the console
print("Enhanced Compass system loaded!")
print("Controls:")
print("- 'C' to toggle compass UI")
print("- 'F' to create waypoint at cursor")
print("- 'G' to toggle debug mode")
print("- 'M' to open management panel (select waypoint first)")
print("- Click waypoints to select them")
