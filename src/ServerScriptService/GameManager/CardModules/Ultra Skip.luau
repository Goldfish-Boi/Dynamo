local module = {}

local deckManager = require(script.Parent.Parent.Managers.DeckManager)

function module.Main()
	deckManager["IsRoundTerminated"] = true
end

return module