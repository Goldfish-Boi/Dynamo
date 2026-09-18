--!strict
--!optimize 2

local players = game:GetService("Players")
local serverStorage = game:GetService("ServerStorage")

return function (player:Player)
	local function respectPlus(char:Model)
		local head = char:FindFirstChild("Head")::BasePart
		
		if not head then return end
		
		head.Touched:Connect(function(otherPart)
			if not (otherPart.Name == "Left Leg" and otherPart.Name == "Right Leg") then return end
			
			local otherChar = otherPart.Parent::Object
			if char == otherChar or not otherChar:IsA("Model") then return end
			
			local otherPlr = players:GetPlayerFromCharacter(otherChar)
			if not otherPlr then return end
			
			
		end)
	end
	
	player.CharacterAdded:Connect(function(char)
		respectPlus(char)
	end)
	
	local char = player.Character or player.CharacterAdded:Wait()
	
	if char then
		respectPlus(char)
	end
end