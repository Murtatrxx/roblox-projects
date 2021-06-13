local player = game.Players.LocalPlayer;
local char = player.Character or player.CharacterAdded:Wait();
local hum = char:WaitForChild("Humanoid")

local UIS = game:GetService("UserInputService");
local tween = game:GetService("TweenService");

local power = 100;
local running = false;

local UIS = game:GetService("UserInputService")
local DefaultFOV = 70

local lastTime = tick()

repeat wait() until game.Players.LocalPlayer.Character

UIS.InputBegan:Connect(function(input, gameprocessed)
	if input.KeyCode == Enum.KeyCode.W then
		local now = tick()
		local difference = (now - lastTime)

		if difference <= 0.2 and hum.WalkSpeed < 17 then running = true;
			if running then
				power = power - 0.5
				hum.WalkSpeed = 22

				local properties = {FieldOfView = DefaultFOV + 15}
				local Info = TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0.1)
				local T = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera, Info, properties)
				T:Play()	

				while power >= 1 and running do
					power = power - 0.1
					script.Parent:TweenSize(UDim2.new(power / 100, 0 , 1), "Out" , "Quad" , 0.2 , true)
					script.Parent.Parent.Text.Text = math.floor(power) .." / 100"
					wait()

					if power <= 1  then
						local properties = {FieldOfView = DefaultFOV}
						local Info = TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0.1)
						local T = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera,Info,properties)
						T:Play()
						hum.WalkSpeed = 16;
						running = false;
					end
				end
			end
		end
		lastTime = tick()
	end
end)

UIS.InputEnded:Connect(function(input, gameprocessed)
	if input.KeyCode == Enum.KeyCode.W then
		hum.WalkSpeed = 16
		running = false;

		local properties = {FieldOfView = DefaultFOV}
		local Info = TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0.1)
		local T = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera,Info,properties)
		T:Play()

		while power < 100 and not running do	
			power = power + 0.1
			script.Parent:TweenSize(UDim2.new(power / 100 , 0 , 1), "Out" , "Quad" , 0.2 , true)
			script.Parent.Parent.Text.Text = math.floor(power) .." / 100"
			wait()

			if power <= 0 then
				hum.WalkSpeed = 16
				running = false
				power = power + 0.1
			end
		end
	end

end)

hum.Died:Connect(function()
	game.Workspace.Camera.FieldOfView = DefaultFOV
	hum.WalkSpeed = 16
	power = 0;
end)