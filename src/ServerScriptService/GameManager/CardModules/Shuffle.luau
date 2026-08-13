--!strict
--!optimize 2

local types = require(script.Parent.Parent.Types)
local helpers:types.Helpers = require(script.Parent.Parent.Helpers)

local module = {}

function module.Main()
	if not helpers.getDeck then warn("No Helpers registered") return end

	local deck = helpers.getDeck()
	
	print(deck)
	
	Random.new():Shuffle(deck)
	
	print(deck)
end

return module