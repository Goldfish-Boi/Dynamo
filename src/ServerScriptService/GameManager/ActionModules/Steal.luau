--!strict
--!optimize 2

local types = require(script.Parent.Parent.Types)
local helpers = require(script.Parent.Parent.Helpers)

local stealModule = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

function stealModule.Steal(index:number, actionInfo:types.ActionInfo)
	if (not helpers.getPlrCardsProvider) or (not helpers.getPlayerTable) or (not helpers.getPillarsTable) then warn("No Helpers registered") return end
	
	local targetIndex:number = actionInfo.TargetIndex::number
	if typeof(actionInfo.TargetIndex) == "string" then
		targetIndex = helpers.getPlayerIndex(actionInfo.TargetIndex)
	end
	
	local isaPlayer, player = helpers.isPlayer(index)
	local targetIsaPlayer, targetPlayer = helpers.isPlayer(targetIndex)
	local plrCards = helpers.getPlrCardsProvider()
	local pillarsTable = helpers.getPillarsTable()
	
	local players = helpers.getPlayerTable()
	
	print(players[index] .. " is stealing from " .. players[targetIndex])
	
	if isaPlayer and player then
		local success, stealIndex:string|number = pcall(function()
			return replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision:InvokeClient(player, "Steal", #plrCards[targetIndex])
		end)
		
		if not success then
			print("Disconnected")
			return
		else
			print(stealIndex)
		end
		
		if typeof(stealIndex) == "string" or stealIndex == -1 then
			print("AFK while stealing")
			return
		end
		
		local stolenCard:string = plrCards[targetIndex][stealIndex]
		
		if targetIsaPlayer and targetPlayer then
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(targetPlayer, "RemoveCard", nil, stealIndex)
		else
			Random.new():Shuffle(plrCards[targetIndex])
		end
		
		local from = pillarsTable[targetIndex]::Model
		local to = pillarsTable[index]::Model

		if to and to.PrimaryPart and from and from.PrimaryPart then
			replicatedStorage.Communicators.Remotes.Events.CreateClientEffect:FireAllClients({{Type = "TransitionCard", Card = "CardBack", TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), From = from.PrimaryPart.Position + Vector3.new(0, 15, 0), To = to.PrimaryPart.Position + Vector3.new(0, 14, 0), Parabolic = true}})
		end
		
		print(stolenCard)
		
		table.insert(plrCards[index], stolenCard) 
		
		task.delay(0.5, function()
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(player, "AddCard", stolenCard)
		end)
		
		table.remove(plrCards[targetIndex], stealIndex)
	else
		local stealIndex = math.random(1, #plrCards[targetIndex])
		local stolenCard:string = plrCards[targetIndex][stealIndex]

		print(stolenCard)
		
		if targetIsaPlayer and targetPlayer then
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(targetPlayer, "RemoveCard", nil, stealIndex)
		end
		
		local from = pillarsTable[targetIndex]::Model
		local to = pillarsTable[index]::Model

		if to and to.PrimaryPart and from and from.PrimaryPart then
			replicatedStorage.Communicators.Remotes.Events.CreateClientEffect:FireAllClients({{Type = "TransitionCard", Card = "CardBack", TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), From = from.PrimaryPart.Position + Vector3.new(0, 15, 0), To = to.PrimaryPart.Position + Vector3.new(0, 14, 0), Parabolic = true}})
		end
		
		table.insert(plrCards[index], stolenCard) 
			
		table.remove(plrCards[targetIndex], stealIndex)
	end
end

function stealModule.TripleSteal(index:number, actionInfo:types.ActionInfo)
	if (not helpers.getPlrCardsProvider) or (not helpers.getPillarsTable) then warn("No Helpers registered") return end
	
	print("Triple Steal")
	
	local targetIndex:number = actionInfo.TargetIndex::number
	if typeof(actionInfo.TargetIndex) == "string" then
		targetIndex = helpers.getPlayerIndex(actionInfo.TargetIndex)
	end
	
	local isaPlayer, player = helpers.isPlayer(index)
	local targetIsaPlayer, targetPlayer = helpers.isPlayer(targetIndex)
	local plrCards = helpers.getPlrCardsProvider()
	local pillarsTable = helpers.getPillarsTable()

	if isaPlayer and player then
		local success, cardToFind:string = pcall(function()
			return replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision:InvokeClient(player, "ChooseCard")
		end)

		if not success then
			print("Disconnected")
			return
		end

		if cardToFind == "AFK" then
			print("AFK while stealing")
			return
		end
		
		print(cardToFind)
		
		local indexOfStolenCard:number? = table.find(plrCards[targetIndex], cardToFind)
		
		if indexOfStolenCard then
			table.insert(plrCards[index], cardToFind) 
			
			if targetIsaPlayer and targetPlayer then
				replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(targetPlayer, "RemoveCard", nil, indexOfStolenCard)
			end
			
			local from = pillarsTable[targetIndex]::Model
			local to = pillarsTable[index]::Model

			if to and to.PrimaryPart and from and from.PrimaryPart then
				replicatedStorage.Communicators.Remotes.Events.CreateClientEffect:FireAllClients({{Type = "TransitionCard", Card = "CardBack", TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), From = from.PrimaryPart.Position + Vector3.new(0, 15, 0), To = to.PrimaryPart.Position + Vector3.new(0, 14, 0), Parabolic = true}})
			end

			task.delay(0.5, function()
				replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(player, "AddCard", cardToFind)
			end)

			table.remove(plrCards[targetIndex], indexOfStolenCard)
		end
	else
		local stealIndex = math.random(1, #plrCards[targetIndex])
		local stolenCard:string = plrCards[targetIndex][stealIndex]

		print(stolenCard)

		table.insert(plrCards[index], stolenCard) 

		table.remove(plrCards[targetIndex], stealIndex)
	end
end

return stealModule