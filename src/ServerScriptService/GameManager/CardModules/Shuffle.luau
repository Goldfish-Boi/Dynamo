local module = {}

function module.Main(plr:Player, plrCards:{string})
	local deck = require(script.Parent.Parent.Managers.DeckManager).GetCurrentDeck()
	
	print(deck)
	
	Random.new():Shuffle(deck)
	
	print(deck)
end

return module