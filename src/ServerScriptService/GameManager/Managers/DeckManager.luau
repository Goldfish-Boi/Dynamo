--!strict
--!optimize 2

export type DeckModule = {
	TurnsToDo:number,
	IsRoundTerminated:boolean,
	InitialDeck:{string}?,
	CurrentDeck:{string}?,
	
	CreatePlayerDecks: (numberOfPlayers: number) -> {any},
	CreateDeck: (numberOfPlayers: number) -> {string},
	InsertCardAtRandomPosition: (deck: {string}, card: string) -> {string},
	InsertCardAtPosition: (deck: {string}, card: string, position: number) -> {string},
	GetTurnCount: () -> number,
	SetTurnCount: (turns: number) -> (),
	UpdateDeck: (deck: {string}) -> (),
	GetCurrentDeck: () -> {string}?,
	Shuffle: (deck: {any}) -> {any},
}

local deckManager:DeckModule = {
	TurnsToDo = 1,
	IsRoundTerminated = false,
	InitialDeck = nil,
	CurrentDeck = nil,
}::DeckModule

const cards = table.freeze({
	{Name = "Test", Amount = 3},
	{Name = "Shuffle", Amount = 1},
	{Name = "Attack", Amount = 1},
	{Name = "Cheezburger", Amount = 1},
	{Name = "Bloxy Cola", Amount = 1},
	{Name = "Cake", Amount = 1},
	{Name = "Taco", Amount = 1},
	{Name = "Choco Milk", Amount = 1},
	--{Name = "Request", Amount = 2},
	--{Name = "Peek 3x", Amount = 3},
	--{Name = "Deny", Amount = 3},
	--{Name = "Analyse", Amount = 3},
	--{Name = "Dynamite", Amount = 1},
	--[[{Name = "Peek 5x", Amount = 2},
	{Name = "Adjust 3x", Amount = 2},
	{Name = "Adjust 5x", Amount = 1},
	{Name = "Ploobie", Amount = 2},
	{Name = "Precision Attack", Amount = 1},
	{Name = "Reverse", Amount = 2},
	{Name = "Expose", Amount = 2},
	{Name = "Draw from the bottom", Amount = 1},
	{Name = "Invert", Amount = 1},
	{Name = "Friendly adjust 3x", Amount = 1},
	{Name = "Friendly adjust 5x", Amount = 1},
	{Name = "Supercharge", Amount = 2},
	{Name = "Avoid", Amount = 2},
	{Name = "Snatch", Amount = 2},]]--
})

const variableCards = table.freeze({
	{Name = "Skip", Amount = 1, CanBecome = {"Ultra Skip"}, Chance = {20}},
})

const nonStartingCards = table.freeze({
	{Name = "Containment", ChancePerPlr = 7.5},
	{Name = "Defuse", ChancePerPlr = 33},
	--{Name = "Nuke", ChancePerPlr = 4},
	--{Name = "Doomsday", ChancePerPlr = 2},
	--{Name = "Ploobie", ChancePerPlr = 0.5},
	--[[{Name = "Noclip", Amount = 1},
	{Name = "Defuse", Amount = 3},
	{Name = "Spacetime dynamite", Amount = 1},
	{Name = "Doomsday", Amount = 2},]]--
})


local random = Random.new()

local initialDeck:{any}

function deckManager.CreatePlayerDecks(numberOfPlayers:number)
	local playerDecks:{any} = {}
	local cardCount = 0
	
	initialDeck = {}
	
	--[[for i in cards do
		for j = 1, cards[i].Amount do
			cardCount += 1

			initialDeck[cardCount] = cards[i].Name
		end
	end]]--
	
	for i, card in pairs(cards) do
		for j = 1, card.Amount * numberOfPlayers do
			cardCount += 1
			
			initialDeck[cardCount] = card.Name
		end
	end
	
	for i, card in pairs(variableCards) do
		for j = 1, card.Amount * numberOfPlayers do
			cardCount += 1
			
			for i, variation in ipairs(card.CanBecome) do
				if math.random(1, 100) <= card.Chance[i] then
					initialDeck[cardCount] = variation
					break
				else
					initialDeck[cardCount] = card.Name
					break
				end
			end
		end
	end
	
	local checkIfEven = {
		"Cheezburger",
		"Taco",
		"Cake",
		"Bloxy Cola",
		"Chocolate Milk",
	}
	
	for i, cardToCheck in ipairs(checkIfEven) do
		local count = 0
		
		for j, card in ipairs(initialDeck) do
			if card == cardToCheck then
				count += 1
			end
		end
		
		if count % 2 ~= 0 then
			cardCount += 1

			initialDeck[cardCount] = cardToCheck
		end
	end

	deckManager.Shuffle(initialDeck)
	
	for i = 1, numberOfPlayers do
		playerDecks[i] = {}
		
		for j = 1, 7 do
			local n = math.random(1, #initialDeck)
			
			playerDecks[i][j] = initialDeck[n]
			table.remove(initialDeck, n)
		end
		
		playerDecks[i][8] = "Defuse"
	end
	
	cardCount = #initialDeck
	
	for i = 1, numberOfPlayers - 1 do
		cardCount += 1
		
		initialDeck[cardCount] = "Dynamite"
	end
	
	return playerDecks
end

function deckManager.CreateDeck(numberOfPlayers:number)
	local cardCount = #initialDeck
	
	for i = 1, numberOfPlayers - 1 do
		cardCount += 1

		initialDeck[cardCount] = "Dynamite"
	end
	
	for i, nonStartingCard in ipairs(nonStartingCards) do
		local loops = (nonStartingCard.ChancePerPlr * numberOfPlayers) // 100

		print(loops)
		
		if loops == 0 then
			if math.random(1, 100) <= (nonStartingCard.ChancePerPlr * numberOfPlayers) % 100 then
				cardCount += 1

				initialDeck[cardCount] = nonStartingCard.Name
			end
		elseif math.floor(loops) == loops then
			for count = 1, loops do
				cardCount += 1
				
				initialDeck[cardCount] = nonStartingCard.Name
			end
		else
			for count = 1, loops do
				if count == loops then
					if math.random(1, 100) <= (nonStartingCard.ChancePerPlr * numberOfPlayers) % 100 then
						cardCount += 1
						
						initialDeck[cardCount] = nonStartingCard.Name
					end
				else
					cardCount += 1
					
					initialDeck[cardCount] = nonStartingCard.Name
				end
			end
		end
	end
	
	for i, card in ipairs(initialDeck) do
		if card == "Containment" then
			cardCount += 1
			
			initialDeck[cardCount] = "Dynamite"
		end
	end
	
	--[[for i in nonStartingCards do
		for j = 1, cards[i].Amount do
			cardCount += 1
			
			deck[cardCount] = cards[i].Name
		end
	end]]--
	
	return initialDeck
end

function deckManager.InsertCardAtRandomPosition(deck:{string}, card:string)
	local position = math.random(1, #deck + 1)

	local newDeck = {}

	table.move(deck, 1, position - 1, 1, newDeck)
	table.insert(newDeck, card)

	if position <= #deck then
		table.move(deck, position, #deck, #newDeck + 1, newDeck)
	end
	
	return newDeck
end

function deckManager.InsertCardAtPosition(deck:{string}, card:string, position:number)
	local newDeck = {}
	
	table.move(deck, 1, position - 1, 1, newDeck)
	table.insert(newDeck, card)
	
	if position < #deck then
		table.move(deck, position, #deck, #newDeck + 1, newDeck)
	end
	
	return newDeck
end

function deckManager.GetTurnCount()
	return deckManager["TurnsToDo"]
end

function deckManager.SetTurnCount(turns:number)
	deckManager["TurnsToDo"] = turns
end

function deckManager.UpdateDeck(deck:{string})
	deckManager["CurrentDeck"] = deck
end

function deckManager.GetCurrentDeck()
	return deckManager["CurrentDeck"]
end

function deckManager.Shuffle(Deck:{any})
	random:Shuffle(Deck)
	
	return Deck
end

return deckManager
