--!strict
--!optimize 2

local types = require(script.Parent.Parent.Types)
local helpers:types.Helpers = require(script.Parent.Parent.Helpers)

local module = {}

function module.Main()
	if not helpers.getDeck then warn("No Helpers registered") return end

	local deck = helpers.getDeck()
	
	local newDeck = {}
	
	for i = #deck, 1, -1 do
		table.insert(newDeck, deck[i])
		table.remove(deck, i)
	end
	
	deck = newDeck
end

return module