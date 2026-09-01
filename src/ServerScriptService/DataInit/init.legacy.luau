--!strict
--!optimize 2

local players = game:GetService("Players")
local badgeService = game:GetService("BadgeService")

local data = require(script.Data)

function playerAdded(plr:Player)
	pcall(function()
		badgeService:AwardBadgeAsync(plr.User, 2065808100555139)
	end)
	
	data.loadPlayerData(plr)
end

players.PlayerAdded:Connect(function(plr:Player) playerAdded(plr) end)
players.PlayerRemoving:Connect(function(plr:Player) data.savePlayerData(plr) end)