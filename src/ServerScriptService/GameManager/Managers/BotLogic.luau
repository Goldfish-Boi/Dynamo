--!strict
--!optimize 2

local botLogic = {}

local cardInfo:{[string]: any}  = require(game.ReplicatedStorage.Modules.CardInfo)::{[string]: any}
local deckManager = require(script.Parent.Parent.Managers.DeckManager)

local helpers = require(script.Parent.Parent.Helpers)
local stealModule = require(script.Parent.Parent.ActionModules.Steal)

function getSpecificCardCount(card:string, hand:{string}) : number
	local cardCount = 0
	
	for i, card in ipairs(hand) do
		if card == card then
			cardCount += 1
		end
	end
	
	return cardCount
end

function computeRisk(hand:{string}, plrCount:number) : number
	if (not deckManager.InitialDeck) or (not deckManager.CurrentDeck) then return math.random(1, 100) end
	
	local startingDeckSize = #deckManager.InitialDeck
	local deckSize = #deckManager.CurrentDeck

	if deckManager.CurrentDeck[1] == "Exposed Nuke" then
		return 100
	end
	
	if table.find(hand, "Containment") and not table.find(hand, "Dynamite") then
		return 0
	end

	if startingDeckSize == plrCount then
		return 100
	else
		return math.clamp(((startingDeckSize - deckSize) / (startingDeckSize - plrCount)) * 99 + 1, 1, 100)
	end
end

function findHighestPriorityCard(state:string, hand:{string}, risk:number) : string
	local turnsToDo = deckManager.TurnsToDo
	--local canSteal = false
	
	local oppositeState = if state == "Defense" then "Offense" else "Defense"
	local bestCard = nil
	local bestValue = -math.huge
	
	if turnsToDo > 1 then
		if state == "Defense" and table.find(hand, "Ultra Skip") then
			return "Ultra Skip"
		end
		if state == "Offense" and table.find(hand, "Attack") then
			return "Attack"
		end
	end

	-- 1. Search for cards matching the desired state
	for i:number, card:string in ipairs(hand) do
		if cardInfo[card] and cardInfo[card]["UsuabilityType"] == state and cardInfo[card].Usable == true then
			if cardInfo[card].BotUsuability > bestValue then
				bestValue = cardInfo[card].BotUsuability
				bestCard = card
			end
		end
	end

	if bestCard then
		return bestCard
	end

	-- 2. Search for cards matching the opposite state
	bestValue = -math.huge
	
	for i:number, card:string in ipairs(hand) do
		if cardInfo[card] and cardInfo[card].UsuabilityType == oppositeState and cardInfo[card].Usable == true then
			if cardInfo[card].BotUsuability > bestValue then
				bestValue = cardInfo[card].BotUsuability
				bestCard = card
			end
		end
	end

	if bestCard then
		return bestCard
	end

	-- 3. No usable cards found
	return "Take"
end

function botLogic.playCard(bot:Instance, deck:{string}, plrCount:number) : string
	local state
	
	if math.random(1, 10) < bot:GetAttribute("Aggression")::number then
		state = "Offense"
	else
		state = "Defense"
	end
	
	return findHighestPriorityCard(state, deck, computeRisk(deck, plrCount))
end

function botLogic.Play(bot:Instance, hand:{string}, plrCount:number) : string
	if not helpers.getPlrCardsProvider then return "Take" end
	
	local canSteal:boolean = false
	local canTripleSteal:boolean = false
	
	local steals = {}
	local tripleSteals = {}
	
	if #hand ~= 0 then
		local cardsChecked:{string} = {}
		
		for i, card in ipairs(hand) do
			if table.find(cardsChecked, card) then continue end
			
			table.insert(cardsChecked, card)
			
			local specificCardCount = getSpecificCardCount(card, hand)
			
			if specificCardCount >= 2 then
				table.insert(steals, card)
				
				if specificCardCount >= 3 then
					table.insert(tripleSteals, card)
				end
			end
		end
	end
	
	local plrCards = helpers.getPlrCardsProvider()
	local otherPlayers:{string} = helpers.getAllOthers(helpers.getPlayerIndex(bot.Name))
	
	if math.random(1, 100) >= computeRisk(hand, plrCount) and #hand ~= 0 then
		--[[if #steals ~= 0 and plrCards then
			local cardToUse = steals[math.random(1, #steals)]
			
			stealModule.Steal(helpers.getPlayerIndex(bot.Name), {Type = "Steal", TargetIndex = helpers.getPlayerIndex(otherPlayers[math.random(1, #otherPlayers)]), Cards = {cardToUse, cardToUse}})
		end]]--
		
		return "Play"
	else
		return "Take"
	end
end

return botLogic