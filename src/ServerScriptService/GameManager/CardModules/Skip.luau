local module = {}

local deckManager = require(script.Parent.Parent.Managers.DeckManager)

function module.Main()
	deckManager.SetTurnCount(deckManager.GetTurnCount() - 1)
end

return module