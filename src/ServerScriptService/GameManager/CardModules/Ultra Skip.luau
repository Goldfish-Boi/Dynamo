local module = {}

local deckManager = require(script.Parent.Parent.Managers.DeckManager)

function module.Main(plr:Player, plrCards:{string})
	deckManager["IsRoundTerminated"] = true
end

return module