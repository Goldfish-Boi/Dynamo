const univeralInfo = table.freeze({
	["Assets"] = {
		["BotIcon"] = 80798742429722,
	},
	["Explosions"] = {
		["E001"] = {
			Name = "Boom",
			Price = 0,
			Category = "Basic",
		},
	},
	["Pillars"] = {
		["P001"] = {
			Name = "Rectangular Prism",
			Price = 0,
			Category = "Basic",
			
			Skins = {
				["P001-S01"] = {
					Name = "Red",
					Price = 50,
					Type = "Colour",
				},
				["P001-S02"] = {
					Name = "Orange",
					Price = 50,
					Type = "Colour",
				},
				["P001-S03"] = {
					Name = "Yellow",
					Price = 50,
					Type = "Colour",
				},
				["P001-S04"] = {
					Name = "Green",
					Price = 50,
					Type = "Colour",
				},
				["P001-S05"] = {
					Name = "Blue",
					Price = 50,
					Type = "Colour",
				},
				["P001-S06"] = {
					Name = "Indigo",
					Price = 50,
					Type = "Colour",
				},
				["P001-S07"] = {
					Name = "Violet",
					Price = 50,
					Type = "Colour",
				},
				["P001-S08"] = {
					Name = "Full Spectrum",
					Price = 500,
					Type = "Upgrade",
					
					Prerequisites = {
						"P001-S01",
						"P001-S02",
						"P001-S03",
						"P001-S04",
						"P001-S05",
						"P001-S06",
						"P001-S07",
					},
				},
				["P001-S09"] = {
					Name = "Gradients",
					Price = 500,
					Type = "Upgrade",
					
					Prerequisites = {
						"P001-S01",
						"P001-S02",
						"P001-S03",
						"P001-S04",
						"P001-S05",
						"P001-S06",
						"P001-S07",
					},
				},
			},
		},
	},
	["Emotes"] = {
		["Em001"] = {
			Name = "Point",
			Price = 0,
		},
	},
})

return univeralInfo