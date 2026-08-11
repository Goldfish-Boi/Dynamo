local module = {}

function module.Main(plr:Player, deck:{string})
	local newDeck = {}

	for i in deck do
		if deck[i] == "Dynamite" then
			table.insert(newDeck, deck[i])
			table.remove(deck, i)
		end
	end

	for i in deck do
		table.insert(newDeck, deck[i])
		table.remove(deck, i)
	end

	return {valueType = "Deck", value = newDeck}
end

return module