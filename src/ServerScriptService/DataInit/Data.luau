--!strict
--!optimize 2

local dataModule = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local dataStoreService = game:GetService("DataStoreService")
local playerData = dataStoreService:GetDataStore("PlayerData")
local robuxLeaderboard = dataStoreService:GetOrderedDataStore("Leaderboards", "Robux")
local winsLeaderboard = dataStoreService:GetOrderedDataStore("Leaderboards", "Wins")

local cardInfo:{[string]:{any}} = require(replicatedStorage.Modules.CardInfo)::{[string]:{any}}

local communicators = replicatedStorage.Communicators

local tablePlayerData:{[number]:any} = {}
local updatePlayerData:{[number]:any} = {}
local removePlayerData:{[number]:any} = {}
local updateGlobalData = {}

--------------------------------- Helper Functions ---------------------------------

function copyTable(t:{any}) : {[any]:any}
	if typeof(t) ~= "table" then return t end
	
	local copy = {}
	
	for k, v in pairs(t) do
		copy[k] = copyTable(v)
	end
	
	return copy
end

function dataModule.returnAllData()
	return tablePlayerData
end

function dataModule.returnPlayerData(plr:Player, returnType:string) : {[string]:any} | string
	local attempts = 0
	
	repeat
		attempts += 1
		task.wait(0.1)
	until tablePlayerData[plr.UserId] or attempts == 100
	
	local currentData = tablePlayerData[plr.UserId]
	
	if not currentData then 
		return "Error"
	end
	
	if returnType == "All" then
		return currentData
	elseif returnType == "Inventory" then
		return currentData["Inventory"]
	elseif returnType == "Settings" then
		return currentData["Settings"]
	elseif returnType == "Stats" then
		return currentData["Stats"]
	end

	return "Error"
end

function constructPlayerData(preloadedData:{[string]:any}?) : {[string]:any}
	local data:{[string]:any} = preloadedData or {}
	
	if not data["Equipped"] then data["Equipped"] = {} end
		if not data["Equipped"]["Emotes"] then data["Equipped"]["Emotes"] = {"Em001"} end
		if not data["Equipped"]["Explosion"] then data["Equipped"]["Explosion"] = "E001" end
		if not data["Equipped"]["Pillar"] then data["Equipped"]["Pillar"] = "P001" end
	
	if not data["Inventory"] then data["Inventory"] = {} end
		if not data["Inventory"]["Badges"] then data["Inventory"]["Badges"] = {} end
		if not data["Inventory"]["Emotes"] then data["Inventory"]["Emotes"] = {} end
		if not data["Inventory"]["Explosions"] then data["Inventory"]["Explosions"] = {["E001"] = {}} end
		if not data["Inventory"]["Gamepasses"] then data["Inventory"]["Gamepasses"] = {} end
		if not data["Inventory"]["Items"] then data["Inventory"]["Items"] = {} end
		if not data["Inventory"]["Nitro"] then data["Inventory"]["Nitro"] = 0 end
		if not data["Inventory"]["Pillars"] then data["Inventory"]["Pillars"] = {["P001"] = {}} end
		if not data["Inventory"]["Strings"] then data["Inventory"]["Strings"] = {} end
	
	if not data["Settings"] then data["Settings"] = {} end
	
	if not data["Stats"] then data["Stats"] = {} end
		if not data["Stats"]["NitroEarned"] then data["Stats"]["NitroEarned"] = 0 end
		if not data["Stats"]["NitroSpent"] then data ["Stats"]["NitroSpent"] = 0 end
		if not data["Stats"]["RobuxSpent"] then data["Stats"]["RobuxSpent"] = 0 end
		if not data["Stats"]["RoundsPlayed"] then data["Stats"]["RoundsPlayed"] = 0 end
		if not data["Stats"]["RoundsWon"] then data["Stats"]["RoundsWon"] = 0 end
		if not data["Stats"]["TotalPlaytime"] then data["Stats"]["TotalPlaytime"] = 0 end
		
		if not data["Stats"]["CardStats"] then data["Stats"]["CardStats"] = {} end
			for cardName:string, cardInfo in pairs(cardInfo) do
				if not data["Stats"]["CardStats"][cardName] then
					data["Stats"]["CardStats"][cardName] = {}
					
					if not data["Stats"]["CardStats"][cardName]["CardsReceived"] then data["Stats"]["CardStats"][cardName]["CardsReceived"] = 0 end
					if not data["Stats"]["CardStats"][cardName]["CardsUsed"] then data["Stats"]["CardStats"][cardName]["CardsUsed"] = 0 end
				end
			end
	
	return data
end

function stitchData(userId:number, previousData:{any}?) : {[string]:any}
	local updateData:{[string]:any} = copyTable(updatePlayerData[userId])
	local data
	
	if not updateData then updateData = {} end
	
	if previousData then
		data = copyTable(previousData)
	else
		data = copyTable(tablePlayerData[userId])
	end
	
	if updateData["Equipped"] then
		for index, value in pairs(updateData["Equipped"]) do
			data["Equipped"][index] = value
		end
	end
	
	if updateData["Inventory"] then
		for index, value in pairs(updateData["Inventory"]) do
			if not data["Inventory"][index] then data["Inventory"][index] = value continue end
			
			if typeof(value) == "number" then
				data["Inventory"][index] += value
			elseif typeof(value) == "table" then
				for i, item in pairs(value) do
					if not table.find(data["Inventory"][index], item) then table.insert(data["Inventory"][index], item) end
				end
			end
		end
	end
	
	if updateData["Settings"] then
		for setting, value in pairs(updateData["Settings"]) do
			if not data["Settings"][setting] then data["Settings"][setting] = value continue end
			
			if typeof(data["Settings"][setting]) == typeof(value) then
				data["Settings"][setting] = value
			end
		end
	end
	
	if updateData["Stats"] then
		for category, value in pairs(updateData["Stats"]) do
			if typeof(value) ~= "number" then continue end
			
			data["Stats"][category] += value
		end
		
		if updateData["Stats"]["CardStats"] then
			for cardName, cardStats:{[string]:any} in pairs(updateData["Stats"]["CardStats"]::{[string]:any}) do
				if not data["Stats"]["CardStats"][cardName] then data["Stats"]["CardStats"][cardName] = cardStats continue end
				
				for statName, statValue in pairs(cardStats) do
					if data["Stats"]["CardStats"][cardName][statName] then
						data["Stats"]["CardStats"][cardName][statName] += statValue
					else
						data["Stats"]["CardStats"][cardName][statName] = statValue
					end
				end
			end
		end
	end
	
	return data
end

--------------------------------- Primary Functions ---------------------------------

function dataModule.loadPlayerData(plr:Player)
	local success, data = pcall(function()
		return playerData:GetAsync(tostring(plr.UserId))
	end)
	
	if not success then
		plr:Kick("Failed to load in data, please try again another time")
	end
	
	data = constructPlayerData(data)
	
	print(data)
	
	tablePlayerData[plr.UserId] = data
end

function dataModule.equipItem(plr:Player, position:string, value:string)
	local dataToUpdate = updatePlayerData[plr.UserId]
	
	if not dataToUpdate then dataToUpdate = {} end
	if not dataToUpdate["Equipped"] then dataToUpdate["Equipped"] = {} end
	
	if position:sub(1, 6) == "Emotes" then
		if not dataToUpdate["Equipped"]["Emotes"] then dataToUpdate["Equipped"]["Emotes"] = {} end
		
		dataToUpdate["Equipped"]["Emotes"][tonumber(position:sub(7, 7))] = value
	elseif position == "Pillar" or position == "Explosion" then
		dataToUpdate["Equipped"][position] = value
	end
end

function dataModule.modifyData(plr:Player, updateData:{[string]:any})
	local dataToUpdate = updatePlayerData[plr.UserId]
	
	if not dataToUpdate then dataToUpdate = {} end
	
	if updateData["Inventory"] then
		if not dataToUpdate["Inventory"] then dataToUpdate["Inventory"] = {} end
		
		for category, value in pairs(updateData["Inventory"]) do
			if not dataToUpdate["Inventory"][category] then dataToUpdate["Inventory"][category] = value continue end
			
			if typeof(value) == "number" then
				dataToUpdate["Inventory"][category] += value
			elseif typeof(value) == "table" then
				for index, item in pairs(value) do
					if not table.find(dataToUpdate["Inventory"][category], item) then table.insert(dataToUpdate["Inventory"][category], item) end
				end
			end
		end
	end
	
	if updateData["Settings"] then
		if not dataToUpdate["Settings"] then dataToUpdate["Settings"] = {} end
			
		for setting, value in pairs(updateData["Settings"]) do
			if typeof(value) == typeof(dataToUpdate["Settings"][setting]) then
				dataToUpdate["Settings"][setting] = value
			end
		end
	end
	
	if updateData["Stats"] then
		if not dataToUpdate["Stats"] then dataToUpdate["Stats"] = {} end
		
		for statistic, value in pairs(updateData["Stats"]) do
			if statistic == "CardStats" and typeof(value) == "table" then
				if not dataToUpdate["Stats"]["CardStats"] then dataToUpdate["Stats"]["CardStats"] = {} end
				
				for cardName, cardStats in pairs(value) do
					if not dataToUpdate["Stats"]["CardStats"][cardName] then dataToUpdate["Stats"]["CardStats"][cardName] = {} end
					
					if typeof(cardStats) ~= "table" then continue end
					
					for cardStat, cardStatValue in pairs(cardStats) do
						if dataToUpdate["Stats"]["CardStats"][cardName][cardStat] then
							dataToUpdate["Stats"]["CardStats"][cardName][cardStat] += cardStatValue
						else
							dataToUpdate["Stats"]["CardStats"][cardName][cardStat] = cardStatValue
						end
					end
				end
				
				continue
			end
			
			if dataToUpdate["Stats"][statistic] then
				dataToUpdate["Stats"][statistic] += value
			else
				dataToUpdate["Stats"][statistic] = value
			end
		end
	end
end

const acceptableRemoveLocations:{string} = {
	"Emotes",
	"Explosions",
	"Items",
	"Pillars",
}

function dataModule.removeFromInventory(plr:Player, location:string, key:string)
	if not table.find(acceptableRemoveLocations, location) then return end
	
	local dataToUpdate = removePlayerData[plr.UserId]

	if not dataToUpdate then dataToUpdate = {} end
	
	if not dataToUpdate[location] then dataToUpdate[location] = {} end
	
	table.insert(dataToUpdate[location], key)
end

function dataModule.savePlayerData(plr:Player)
	pcall(function()
		playerData:SetAsync(tostring(plr.UserId), tablePlayerData[plr.UserId])
		--playerData:UpdateAsync(tostring(plr.UserId), stitchData(plr.UserId))
	end)
	
	tablePlayerData[plr.UserId] = nil
end

--------------------------------- Connections ---------------------------------

communicators.Remotes.Functions.RequestData.OnServerInvoke = function(plr:Player, returnType:string?)
	--return dataModule.loadPlayerData(plr, returnType)
	return dataModule.returnPlayerData(plr, returnType or "All")
end

game:BindToClose(function()
	for userId, data in pairs(tablePlayerData) do
		pcall(function()
			playerData:SetAsync(tostring(userId), data)
			--playerData:UpdateAsync(tostring(userId), stitchData(userId))
		end)
		
		task.wait(0.1)
	end
	
	table.clear(tablePlayerData)
end)

return dataModule
