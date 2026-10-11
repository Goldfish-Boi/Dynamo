--!strict
--!optimize 2

local players = game:GetService("Players")
local badgeService = game:GetService("BadgeService")
local serverStorage = game:GetService("ServerStorage")

local data = require(serverStorage.Handlers.Data)
local specialIds = require(script.SpecialIds)
local badgeHandler = require(serverStorage.Handlers.BadgeHandler)

function playerAdded(plr:Player)
	data.loadPlayerData(plr)
	
	local statsData = data.returnPlayerData(plr, "Stats")
	
	if table.find(specialIds["Owner"], plr.UserId) then
		require(serverStorage.Handlers.RespectPlus)(plr)
	end
	
	badgeHandler.AwardBadge(plr, 2065808100555139)
	
	if statsData and typeof(statsData) ~= "string" and statsData["Sessions"] and typeof(statsData["Sessions"]) == "number" then
		if statsData["Sessions"] >= 2 then
			badgeHandler.AwardBadge(plr, 76543470190133)
		end
		
		if statsData["Sessions"] >= 10 then
			badgeHandler.AwardBadge(plr, 2488405764011811)
		end
	end
end

players.PlayerAdded:Connect(function(plr:Player) playerAdded(plr) end)
players.PlayerRemoving:Connect(function(plr:Player) data.savePlayerData(plr) end)