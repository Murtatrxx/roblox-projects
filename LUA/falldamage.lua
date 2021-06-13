local minHeigth = 10;
local maxHeigth = 20;
local damage = 20;

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char) 
		local humanoid = char:WaitForChild("Humanoid");
		local humanoidRootPart = char:WaitForChild("HumanoidRootPart");
		local _playerHeigth
		
		if humanoid and humanoidRootPart  then
			wait(5);
			
			humanoid.FreeFalling:Connect(function(newState)
				if newState then
					_playerHeigth = humanoidRootPart.Position.Y	
				elseif not newState then
					local fallHeigth = _playerHeigth - humanoidRootPart.Position.Y
					
					if fallHeigth >= maxHeigth and humanoid.FloorMaterial == "" then
						humanoid.Health = humanoid.Health - damage
					elseif fallHeigth >= minHeigth then
						humanoid.Health = humanoid.Health - math.floor(fallHeigth)
					end
				end
			end)
		end
	end)
end)