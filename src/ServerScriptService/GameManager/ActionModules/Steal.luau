--!strict
--!optimize 2

local types = require(script.Parent.Parent.Types)
local helpers = require(script.Parent.Parent.Helpers)

local stealModule = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

function stealModule.Steal(index:number, actionInfo:types.ActionInfo)
	if (not helpers.getPlrCardsProvider) or (not helpers.getPlayerTable) then warn("No Helpers registered") return end
	
	local isaPlayer, player = helpers.isPlayer(index)
	local targetIsaPlayer, targetPlayer = helpers.isPlayer(actionInfo.TargetIndex)
	local plrCards = helpers.getPlrCardsProvider()
	
	local players = helpers.getPlayerTable()
	
	print(players[index] .. " is stealing from " .. players[actionInfo.TargetIndex])
	
	if isaPlayer and player then
		local success, stealIndex:string|number = pcall(function()
			return replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision:InvokeClient(player, "Steal", #plrCards[actionInfo.TargetIndex])
		end)
		
		if not success then
			print("Disconnected")
			return
		end
		
		if typeof(stealIndex) == "string" then
			print("AFK while stealing")
			return
		end
		
		local stolenCard:string = plrCards[actionInfo.TargetIndex][stealIndex]
		
		if targetIsaPlayer and targetPlayer then
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(targetPlayer, "RemoveCard", nil, stealIndex)
		else
			Random.new():Shuffle(plrCards[actionInfo.TargetIndex])
		end
		
		print(stolenCard)
		
		table.insert(plrCards[index], stolenCard) 
		
		task.delay(0.5, function()
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(player, "AddCard", stolenCard)
		end)
		
		table.remove(plrCards[actionInfo.TargetIndex], stealIndex)
	else
		local stealIndex = math.random(1, #plrCards[actionInfo.TargetIndex])
		local stolenCard:string = plrCards[actionInfo.TargetIndex][stealIndex]

		print(stolenCard)
		
		if targetIsaPlayer and targetPlayer then
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(targetPlayer, "RemoveCard", nil, stealIndex)
		end
		
		table.insert(plrCards[index], stolenCard) 
			
		table.remove(plrCards[actionInfo.TargetIndex], stealIndex)
	end
end

function stealModule.TripleSteal(index:number, actionInfo:types.ActionInfo)
	if not helpers.getPlrCardsProvider then warn("No Helpers registered") return end
	
	print("Triple Steal")
	
	local isaPlayer, player = helpers.isPlayer(index)
	local targetIsaPlayer, targetPlayer = helpers.isPlayer(actionInfo.TargetIndex)
	local plrCards = helpers.getPlrCardsProvider()

	if isaPlayer and player then
		local success, stealIndex:string|number = pcall(function()
			return replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision:InvokeClient(player, "Triple Steal", #plrCards[actionInfo.TargetIndex])
		end)

		if not success then
			print("Disconnected")
			return
		end

		if typeof(stealIndex) == "string" then
			print("AFK while stealing")
			return
		end

		local stolenCard:string = plrCards[actionInfo.TargetIndex][stealIndex]

		print(stolenCard)

		table.insert(plrCards[index], stolenCard) 

		task.delay(0.5, function()
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(player, "AddCard", stolenCard)
		end)

		table.remove(plrCards[actionInfo.TargetIndex], stealIndex)
	else
		local stealIndex = math.random(1, #plrCards[actionInfo.TargetIndex])
		local stolenCard:string = plrCards[actionInfo.TargetIndex][stealIndex]

		print(stolenCard)

		table.insert(plrCards[index], stolenCard) 

		table.remove(plrCards[actionInfo.TargetIndex], stealIndex)
	end
end


return stealModule
