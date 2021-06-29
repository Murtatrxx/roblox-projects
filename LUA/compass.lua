local smoothness = 30/3;

wait(1)

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local dev = script.Parent

local lastY = 0
local units = {
	[dev.N ] = -math.pi * 4 / 4;
	[dev.NE] = -math.pi * 3 / 4;
	[dev.E ] = -math.pi * 2 / 4;
	[dev.SE] = -math.pi * 1 / 4;
	[dev.S ] =  math.pi * 0 / 4;
	[dev.SW] =  math.pi * 1 / 4;
	[dev.W ] =  math.pi * 2 / 4;
	[dev.NW] =  math.pi * 3 / 4;
}

function restrictAngle(angle)
	if angle < -math.pi then
		return angle + math.pi * 2
	elseif angle > math.pi then
		return angle - math.pi * 2
	else
		return angle
	end
end

while true do
	local delta = wait(1 / 30)

	local look = camera.CoordinateFrame.lookVector
	local look = Vector3.new(look.x, 0, look.z).unit
	local lookY = math.atan2(look.z, look.x)

	local difY = restrictAngle(lookY - lastY)
	lookY = restrictAngle(lastY + difY * delta * smoothness)
	lastY = lookY

	for unit, rot in pairs(units) do
		rot = restrictAngle(lookY - rot)
		if math.sin(rot) > 0 then
			local cosRot = math.cos(rot)
			local cosRot2 = cosRot * cosRot

			unit.Visible = true
			unit:TweenPosition(UDim2.new(0.5 + cosRot * 0.6, unit.Position.X.Offset, 0, 3), "Out" , "Quart" , 0.2 , true)
			
			unit.BackgroundTransparency =  0.00 + 1.50 * cosRot2
		else
			unit.Visible = false
		end
	end
end
