--!strict
--!optimize 2

local players = game:GetService("Players")

local data = require(script.Data)

function playerAdded(plr:Player)
	data.loadPlayerData(plr)
end

players.PlayerAdded:Connect(function(plr:Player) playerAdded(plr) end)
players.PlayerRemoving:Connect(function(plr:Player) data.savePlayerData(plr) end)