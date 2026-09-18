--!strict
--!optimize 2

local players = game:GetService("Players")
local badgeService = game:GetService("BadgeService")
local serverStorage = game:GetService("ServerStorage")

local data = require(script.Data)
local specialIds = require(script.SpecialIds)

function playerAdded(plr:Player)
	if table.find(specialIds["Owner"], plr.UserId) then
		require(serverStorage.Handlers.RespectPlus)(plr)
	end
	
	require(serverStorage.Handlers.BadgeHandler).AwardBadge(plr, 2065808100555139)
	
	data.loadPlayerData(plr)
end

players.PlayerAdded:Connect(function(plr:Player) playerAdded(plr) end)
players.PlayerRemoving:Connect(function(plr:Player) data.savePlayerData(plr) end)