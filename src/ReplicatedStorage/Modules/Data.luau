--!strict
--!optimize 2

local dataModule = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local dataStoreService = game:GetService("DataStoreService")
local playerData = dataStoreService:GetDataStore("PlayerData")
local robuxLeaderboard = dataStoreService:GetOrderedDataStore("Leaderboards", "Robux")
local winsLeaderboard = dataStoreService:GetOrderedDataStore("Leaderboards", "Wins")

local cardInfo:{[string]:{any}} = require(script.Parent.CardInfo)::{[string]:{any}}

local communicators = replicatedStorage.Communicators

local tablePlayerData:{[number]:any} = {}
local updatePlayerData:{[number]:any} = {}
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

function dataModule.returnPlayerData(plr:Player, returnType:string) : {[string]:any} | string
	local currentData = stitchData(plr.UserId)
	
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
		if not data["Inventory"]["Strings"] then data["Inventory"]["Strings"] = 0 end
	
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
	local newData:{[string]:any} = copyTable(updatePlayerData[userId])
	local data
	
	if not newData then newData = {} end
	
	if previousData then
		data = copyTable(previousData)
	else
		data = copyTable(tablePlayerData[userId])
	end
	
	if newData["Inventory"] then
		
	end
	
	if newData["Settings"] then
		for setting, value in pairs(newData["Settings"]) do
			if not data["Settings"][setting] then data["Settings"][setting] = value continue end
			
			if typeof(data["Settings"][setting]) == typeof(value) then
				data["Settings"][setting] = value
			end
		end
	end
	
	if newData["Stats"] then
		for category, value in pairs(newData["Stats"]) do
			if typeof(value) ~= "number" then continue end
			
			data["Stats"][category] += value
		end
		
		if newData["Stats"]["CardStats"] then
			for cardName, cardStats:{[string]:any} in pairs(newData["Stats"]["CardStats"]::{[string]:any}) do
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
	
	tablePlayerData[plr.UserId] = data
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
