--!strict
--!optimize 2

local menuDataManager = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local require = require
local topBarPlus = require(replicatedStorage.Modules.Icon)

--[[local nitroIcon = topBarPlus.new()
	:setName("Nitro")
	--:setLabel("0")
	:setImage(92231235191960)
	:align("Left")
--:setCaption("You have 0 Nitro")
--:setWidth(88)]]--

menuDataManager.PlayerData = replicatedStorage.Communicators.Remotes.Functions.RequestData:InvokeServer("All")

print(menuDataManager.PlayerData)

--[[if menuDataManager.PlayerData and menuDataManager.PlayerData["Inventory"] and menuDataManager.PlayerData["Inventory"]["Nitro"] then
	nitroIcon:setLabel(tostring(menuDataManager.PlayerData["Inventory"]["Nitro"])):setCaption("You have " .. tostring(menuDataManager.PlayerData["Inventory"]["Nitro"]) .. " Nitro")
end]]--

replicatedStorage.Communicators.Remotes.Events.PlayerDataUpdated.OnClientEvent:Connect(function(data)
	if not data then return end
	
	menuDataManager.PlayerData = data
	
	--[[if menuDataManager.PlayerData["Inventory"] and menuDataManager.PlayerData["Inventory"]["Nitro"] then
		nitroIcon:setLabel(tostring(menuDataManager.PlayerData["Inventory"]["Nitro"])):setCaption("You have " .. tostring(menuDataManager.PlayerData["Inventory"]["Nitro"]) .. " Nitro")
	end]]--
	
	for i, module:ModuleScript in ipairs(script.Parent:GetChildren()::{ModuleScript}) do
		if module == script then continue end
		
		require(module).updateData()
	end
end)

return menuDataManager
