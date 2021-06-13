wait(.3)
script.Parent.Frame:TweenSize(UDim2.new(1.004, 0,1, 0) , Enum.EasingDirection.Out , Enum.EasingStyle.Quad , 0.2 , true);

local plr = game.Players.LocalPlayer;
local char = plr.Character or plr.CharacterAdded:Wait();
local hum = char:WaitForChild("Humanoid");

hum.HealthChanged:connect(function(damage)
	script.Parent.Frame:TweenSize(UDim2.new(damage / hum.MaxHealth + 0.004 , 0 , 1) , "Out" , "Quad" , 0.2 , true);
	script.Parent.Health.Text = math.floor(hum.Health) .." / ".. hum.MaxHealth;
end)

hum.Died:connect(function()
	script.Parent.Frame.Visible = false;
end)