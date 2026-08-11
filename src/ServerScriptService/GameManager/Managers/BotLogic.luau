--!strict
--!optimize 2

local botLogic = {}

local cardInfo:{[string]: any}  = require(game.ReplicatedStorage.Modules.CardInfo)::{[string]: any}

function findHighestPriorityCard(state:string, deck:{string})
	local desiredType = state
	local oppositeType = if state == "Defense" then "Offense" else "Defense"

	local bestCard = nil
	local bestValue = -math.huge

	-- 1. Search for cards matching the desired state
	for i:number, card:string in ipairs(deck) do
		if cardInfo[card] and cardInfo[card]["UsuabilityType"] == desiredType and cardInfo[card].Usable == true then
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
	
	for i:number, card:string in ipairs(deck) do
		if cardInfo[card] and cardInfo[card].UsuabilityType == oppositeType and cardInfo[card].Usable == true then
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

function botLogic.playCard(bot:Instance, deck:{string})
	local state
	
	if math.random(1, 10) < bot:GetAttribute("Aggression")::number then
		state = "Offense"
	else
		state = "Defense"
	end
	
	return findHighestPriorityCard(state, deck)
end

function botLogic.Play(bot, startingDeckSize:number, plrCount:number, deckSize:number)
	local risk:number
	
	if startingDeckSize == plrCount then
		risk = 100
	else
		risk = math.clamp(((startingDeckSize - deckSize) / (startingDeckSize - plrCount)) * 99 + 1, 1, 100)
	end
	
	if math.random(1, 100) >= risk then
		return "Play"
	else
		return "Take"
	end
end

return botLogic
