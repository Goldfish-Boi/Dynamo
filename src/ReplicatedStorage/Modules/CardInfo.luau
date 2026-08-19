const cardInfo = table.freeze({
	["CardBack"] = {
		Colour = Color3.fromRGB(42, 0, 63),
		IconID = 98449158402718,
	},
	
	["Test"] = {
		Colour = Color3.fromRGB(200, 200, 200),
		IconID = 137576054394981,
		DeckDescription = "Functions functions uh variable code code if statement table dictionary what next um uh service remote",
		MenuDescription = "This was the very first card added, mostly because it doesn't do anything",		
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,
		
		UsuabilityType = "None",
		BotUsuability = 0,
	},
	["Dynamite"] = {
		Colour = Color3.fromRGB(30, 30, 30),
		IconID = 104310645136189,
		DeckDescription = "A dangerous card, avoid holding on to this",
		MenuDescription = "The main product of this facility and the very thing you wish to avoid",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,
		
		UsuabilityType = "None",
		BotUsuability = -9999,
	},
	["Shuffle"] = {
		Colour = Color3.fromRGB(204, 188, 128),
		IconID = 76885960028848,
		DeckDescription = "Shuffles every card in the deck randomly",
		MenuDescription = "Go my lovely psuedorandom method",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = false,
		
		UsuabilityType = "Defense",
		BotUsuability = 1,
	},
	["Defuse"] = {
		Colour = Color3.fromRGB(156, 255, 134),
		IconID = 132309707595377,
		DeckDescription = "Will automatically save you if a dynamite is going to eliminate you",	
		MenuDescription = "Why don't we have more of these, I should make an entire deck of these",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,
		
		UsuabilityType = "Defense",
		BotUsuability = 999,
	},
	["Peek"] = {
		Colour = Color3.fromRGB(180, 138, 214),
		IconID = 113840094808338,
		DeckDescription = "Get a look at the next three cards on the deck",
		MenuDescription = "Gem alert 🚨🚨🗣️🔥🔥💥",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = false,
		
		UsuabilityType = "Defense",
		BotUsuability = 15,
	},
	["Skip"] = {
		Colour = Color3.fromRGB(76, 183, 232),
		IconID = 75972992026610,
		DeckDescription = "Skips one turn",
		MenuDescription = "Yeah no",
		
		SkipsTurn = true,
		Usable = true,
		CanStack = true,
		
		UsuabilityType = "Defense",
		BotUsuability = 10,
	},
	["Request"] = {
		Colour = Color3.fromRGB(45, 51, 63),
		IconID = 116510499183394,
		DeckDescription = "Make a player give you one of their cards",
		MenuDescription = "Gimme gimme",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = true,
		
		UsuabilityType = "Offense",
		BotUsuability = 10,
	},
	["Attack"] = {
		Colour = Color3.fromRGB(214, 139, 74),
		IconID = 71529133395865,
		DeckDescription = "Forces the next player to take two turns and can chain. Ends your turn",		
		MenuDescription = "Auuuuuuuugh 🤬",
		
		SkipsTurn = true,
		Usable = true,
		CanStack = false,
		
		UsuabilityType = "Offense",
		BotUsuability = 15,
	},
	["Deny"] = {
		Colour = Color3.fromRGB(161, 10, 13),
		IconID = 109600127359870,
		DeckDescription = "Cancel another player's action. Works on most cards, including itself",
		MenuDescription = "Nuh uh",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = false,
		
		UsuabilityType = "Defense",
		BotUsuability = 100
	},
	["Cheezburger"] = {
		Colour = Color3.fromRGB(200, 200, 200),
		IconID = 70877843847181,
		DeckDescription = "Useless on its own. Grants the ability to steal a card from another player when used with more of itself",
		MenuDescription = "Mmm... Chezburger",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,
		
		UsuabilityType = "Offense",
		BotUsuability = 0,
	},
	["Bloxy Cola"] = {
		Colour = Color3.fromRGB(200, 200, 200),
		IconID = 117538141877342,
		DeckDescription = "Useless on its own. Grants the ability to steal a card from another player when used with more of itself",
		MenuDescription = "Pepis",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,

		UsuabilityType = "Offense",
		BotUsuability = 0,
	},
	["Cake"] = {
		Colour = Color3.fromRGB(200, 200, 200),
		IconID = 70375801848911,
		DeckDescription = "Useless on its own. Grants the ability to steal a card from another player when used with more of itself",	
		MenuDescription = "Yayyyy",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,
		
		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Taco"] = {
		Colour = Color3.fromRGB(200, 200, 200),
		IconID = 126573726108374,
		DeckDescription = "Useless on its own. Grants the ability to steal a card from another player when used with more of itself",	
		MenuDescription = "It's raining tacos~~",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,
		
		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Choco Milk"] = {
		Colour = Color3.fromRGB(200, 200, 200),
		IconID = 137076446129208,
		DeckDescription = "Useless on its own. Grants the ability to steal a card from another player when used with more of itself",	
		MenuDescription = "Mmmmm, yummy!",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,
		
		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Analyse"] = {
		Colour = Color3.fromRGB(104, 20, 90),
		IconID = 86306289198577,
		DeckDescription = "Tells you when the next dynamite will appear in the deck",
		MenuDescription = "What did he see?",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = false,
		
		UsuabilityType = "Information",
		BotUsuability = 0
	},
	["Doomsday"] = {
		Colour = Color3.fromRGB(8, 8, 8),
		IconID = 99529482828802,
		DeckDescription = "Gathers every dynamite card and brings them to the top of the deck",
		MenuDescription = "One thousand yard stare",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = false,
		
		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Containment"] = {
		Colour = Color3.fromRGB(33, 117, 52),
		IconID = 118041764380797,
		DeckDescription = "When in your deck, it will allow you to hold onto one dynamite card safely",	
		MenuDescription = "There there little dynamite, don't cry",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,

		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Adjust"] = {
		Colour = Color3.fromRGB(137, 71, 217),
		IconID = 106252258774534,
		DeckDescription = "Change the ordering of the next three cards on the deck",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = false,

		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Ultra Skip"] = {
		Colour = Color3.fromRGB(91, 124, 255),
		IconID = 112760098681816,
		DeckDescription = "Skips all turns you currently have",		
		MenuDescription = "The cooler skip",
		
		SkipsTurn = true,
		Usable = true,
		CanStack = false,
		
		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Ploobie"] = {
		Colour = Color3.fromRGB(200, 200, 200),
		IconID = 113180431580478,
		DeckDescription = "Does absolutely nothing",
		MenuDescription = "Why was this even added???",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,

		UsuabilityType = nil,
		BotUsuability = -math.huge
	},
	["Targeted Attack"] = {
		Colour = Color3.fromRGB(214, 139, 74),
		IconID = 109000279447257,
		DeckDescription = "Forces a player of your choice to take two turns, can chain. Ends your turn",	
		MenuDesciption = "Bye bye Russia 👋👋👋💥",
		
		SkipsTurn = true,
		Usable = true,
		CanStack = false,
		
		UsuabilityType = "Offense",
		BotUsuability = 100
	},
	["Reverse"] = {
		Colour = Color3.fromRGB(0, 234, 226),
		IconID = 111947283702587,
		DeckDescription = "Reverse the order of play and skips a turn",
		MenuDescription = "Uno reverse",
		
		SkipsTurn = true,
		Usable = true,
		CanStack = true,
		
		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Expose"] = {
		Colour = Color3.fromRGB(214, 93, 141),
		IconID = 100370152296282,
		DeckDescription = "Reveal a card that another person has",
		MenuDescription = "Well well well, what do we have here? 😈",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = true,
		
		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Draw from the bottom"] = {
		Colour = Color3.fromRGB(147, 166, 107),
		IconID = nil,
		DeckDescription = "Take the bottom-most card from the deck on your next turn",		
		
		SkipsTurn = false,
		Usable = true,
		CanStack = true,

		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Invert"] = {
		Colour = Color3.fromRGB(52, 56, 7),
		IconID = nil,
		DeckDescription = "Inverts the deck",	
		MenuDescription = "kced eht strevnI",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = false,

		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Nuke"] = {
		Colour = Color3.fromRGB(64, 66, 111),
		IconID = 118923559882263,
		DeckDescription = "How do you even have this 🥀💔",
		InfoOverrideDescription = "Place back in the deck face up when drawn face down. Eliminates immediately when drawn face up",
		MenuDescription = "Ok seriously WHY DO WE HAVE THESE???",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,

		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Supercharge"] = {
		Colour = Color3.fromRGB(211, 118, 12),
		IconID = nil,
		Description = "Force yourself to take 3 turns",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = true,
		
		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Avoid"] = {
		Colour = Color3.fromRGB(126, 126, 126),
		IconID = nil,
		Description = "Put away the next card you draw rather than taking it into your deck",
		
		SkipsTurn = true,
		Usable = true,
		CanStack = false,

		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Noclip"] = {
		Colour = Color3.fromRGB(160, 197, 207),
		IconID = nil,
		Description = "Grants immunity to being stolen from",
		
		SkipsTurn = false,
		Usable = false,
		CanStack = false,

		UsuabilityType = "Offense",
		BotUsuability = 0
	},
	["Snatch"] = {
		Colour = Color3.fromRGB(180, 255, 249),
		IconID = nil,
		Description = "Take the next card that someone else takes",
		
		SkipsTurn = false,
		Usable = true,
		CanStack = true,
		
		UsuabilityType = "Offense",
		BotUsuability = 0
	},
})

return cardInfo