local module = {}

function module.Main(plr:Player, deck:{string})
	local message:string
	
	for i in deck do
		if deck[i] == "Dynamite" then
			if i == 1 then
				message = "Dynamite is the next card"
			else
				message = "The next dynamite is in " .. i .. " cards"
			end

			break
		end
	end

	return {valueType = "Message", value = message}
end

return module
