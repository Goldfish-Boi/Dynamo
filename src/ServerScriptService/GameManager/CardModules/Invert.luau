local module = {}

function module.Main(plr:Player, deck:{string})
	local newDeck = {}
	
	for i = #deck, 1, -1 do
		table.insert(newDeck, deck[i])
		table.remove(deck, i)
	end

	return {valueType = "Deck", value = newDeck}
end

return module