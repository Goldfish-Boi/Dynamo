--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local teams = game:GetService("Teams")

type data = {
	valueType:string,
	value:any
}

local require = require
local universalInfo = require(replicatedStorage.Modules.UniversalInfo)
local cardInfo = require(replicatedStorage.Modules.CardInfo)
local deckManager = require(script.Managers.DeckManager)
local botLogic = require(script.Managers.BotLogic)

local pi = math.pi

local roundFolder = workspace.Round
local cardsFolder = roundFolder.Cards
local pillarsFolder = roundFolder.Pillars
local botsFolder = roundFolder.Bots
local turnIndicator = roundFolder.TurnIndicator

local mainScreen = workspace.Lobby.ServerDataSigns.MainScreen
local circleTemplate = mainScreen.SurfaceGui.Circles.CircleTemplate
local playerStatus = workspace.Lobby.ServerDataSigns.PlayerStatuses

local currentTurnIndex:number = 0
local intermissionLength:number = 0
local bombDutyCountdownLength:number = 0
local usedCardCount:number = 0

local botCountOverride:number? = nil
local initialDeckSize:number?
local roundTime:number?

local deck:{string} = {}
local tweenTable:{Tween} = {}
local pillarsTable:{Model} = {}
local playerTable:{string} = {}
local plrCards:{any} = {}

--------------------------------- Helper Functions ---------------------------------

function clearValues()
	deck = {}
	initialDeckSize = nil
	pillarsTable = {}
	playerTable = {}
	plrCards = {}
	usedCardCount = 0
	currentTurnIndex = 0
end

function bezier(object:BasePart, tweenInfo:TweenInfo, p0:Vector3, p1:Vector3, p2:Vector3)
	local connection
	local a = 0

	connection = runService.Heartbeat:Connect(function(deltaTime:number)
		a += math.clamp(deltaTime / tweenInfo.Time, 0, 1)
		
		if a > 1 and connection then
			connection:Disconnect()
			connection = nil
		end
		
		local n = tweenService:GetValue(a, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
		
		local position = ((1 - n) * (1 - n)) * p0 + 2 * (1 - n) * n * p1 + (n * n) * p2
		object.Position = position
	end)
end

function copyTable(t:{any}) : {[any]:any}
	if typeof(t) ~= "table" then return t end

	local copy = {}

	for k, v in pairs(t) do
		copy[k] = copyTable(v)
	end

	return copy
end

function isPlayer(index:number) : (boolean, Player?)
	if #playerTable == 0 then return false, nil end
	
	local plr = playerTable[index]
	local player = players:FindFirstChild(plr)
	
	if player then
		return true, player::Player
	else
		return false, nil
	end
end

function formatTime(seconds:number) : string
	local minutes = tostring(math.floor(seconds / 60))
	local remainingSeconds = math.floor(seconds % 60)

	if tostring(remainingSeconds):len() == 1 then
		remainingSeconds = "0" .. tostring(remainingSeconds)
	end
	
	return minutes .. ":" .. remainingSeconds
end

function removePlayerFromTable(index:number)
	local circle:Frame = mainScreen.SurfaceGui.Circles:FindFirstChild(tostring(playerTable[index]))::Frame
	
	if circle then
		circle.BackgroundColor3 = Color3.new(1, 0, 0)
		
		local imageLabel = circle:FindFirstChildOfClass("ImageLabel")
		if imageLabel and imageLabel.Image ~= "" then
			imageLabel.ImageColor3 = Color3.new(1, 0.5, 0.5)
		end
	end
	
	if playerTable[index] then
		table.remove(playerTable, index)
	end
	
	if plrCards[index] then
		local primary = pillarsTable[index].PrimaryPart

		if primary then
			for i, card in ipairs(plrCards[index]) do
				task.spawn(function()
					transitionCard(card, primary.Position + Vector3.new(0, 30, 0), workspace.UsedCards.Position + Vector3.new(0, 0.25 + (0.5 * (usedCardCount)), 0), true)
					
					task.wait(1.5)
					
					setUsedCardsModel({card})
				end)
				
				task.wait(0.125)
			end
		end
				
		--setUsedCardsModel(plrCards[index])
		table.remove(plrCards, index)
	end
	
	
	if pillarsTable[index] then
		table.remove(pillarsTable, index)
	end
end

function setDeckModel(updateType:string)
	if not deck or #deck == 0 then return end
	
	if updateType == "Set" then
		for i, card in pairs(deck) do
			local cardPart = workspace.Deck:Clone()

			cardPart.Name = tostring(i)
			cardPart.Position = workspace.Deck.Position + Vector3.new(0, 0.25 + (0.5 * (i - 1)), 0)
			cardPart.Orientation = Vector3.new(0, math.random(-100, 100) / 10, 90)
			cardPart.Transparency = 0
			cardPart.Decal.Transparency = 0
			cardPart.Parent = cardsFolder.Deck
		end
		
		mainScreen.SurfaceGui.TextLabel2.Text = tostring(#deck)
	elseif updateType == "RemoveFirst" then
		local n = 0
		
		for i, card in ipairs(cardsFolder.Deck:GetChildren()) do
			if tonumber(card.Name)::number > n then
				n = tonumber(card.Name)
			end
		end
		
		local card = cardsFolder.Deck:FindFirstChild(tostring(n))
		
		if card then
			task.spawn(function()
				tweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = Vector3.new(0.5, 1.4, 1)}):Play()
				
				task.wait(0.25)
				
				card:Destroy()
			end)
		end
		
		mainScreen.SurfaceGui.TextLabel2.TextColor3 = Color3.fromRGB(255, 105, 105)
		mainScreen.SurfaceGui.TextLabel2.Text = tostring(#deck)
		
		tweenService:Create(mainScreen.SurfaceGui.TextLabel2, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.new(1, 1, 1)}):Play()
	elseif updateType == "RemoveAll" then
		cardsFolder.Deck:ClearAllChildren()
		mainScreen.SurfaceGui.TextLabel2.Text = ""
	end
end

function setUsedCardsModel(cards:{string}, updateType:string?)
	if updateType == "RemoveAll" then
		cardsFolder.UsedCards:ClearAllChildren()
		
		return
	end
	
	if #cards == 0 then return end
	
	for i, card in ipairs(cards) do
		usedCardCount += 1
		
		local cardPart = workspace.UsedCards:Clone()
		cardPart.Name = card
		cardPart.Position = workspace.UsedCards.Position + Vector3.new(0, 0.25 + (0.5 * (usedCardCount - 1)), 0)
		cardPart.Color = cardInfo[card]["Color"]
		cardPart.Orientation = Vector3.new(0, math.random(-100, 100) / 10, 90)
		cardPart.Transparency = 0
		cardPart.Size = Vector3.new(0.5, 1.4, 1)
		cardPart.Parent = cardsFolder.UsedCards
		
		if cardInfo[card]["IconID"] then
			cardPart.Decal.ColorMap = "rbxassetid://" .. cardInfo[card]["IconID"]
		end
		
		tweenService:Create(cardPart, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(0.5, 14, 10)}):Play()
	end
end

function setPillars()
	print(playerTable)
	
	for i, playerName in ipairs(playerTable) do
		--task.wait(1)
		
		local pillar = replicatedStorage.Assets.Pillars.Test:Clone()
		local circumference = 25 * #playerTable
		local radius = math.max(circumference / (2 * math.pi), 50)
		local isaPlayer, player = isPlayer(i)

		if not pillar.PrimaryPart then continue end

		pillarsTable[i] = pillar
		pillar:PivotTo(CFrame.new(Vector3.new(workspace.Origin.Position.X, pillar.PrimaryPart.Position.Y, workspace.Origin.Position.Z)))
		pillar:PivotTo(pillar.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(i * 360 / #playerTable), 0) * CFrame.new(radius, 0, 0))

		pillar.Parent = pillarsFolder
		
		if not isaPlayer then
			local bot = replicatedStorage.Assets.Round.Bot:Clone()
			bot.Name = playerName
			bot:PivotTo(pillar.PlayerSpawn.CFrame)
			bot:SetAttribute("Aggression", math.random(1, 9))
			bot.Parent = botsFolder
			pillar.Name = playerName
			
			continue
		end
		
		if not player then continue end
		
		pillar.Name = player.Name

		if not player.Character then return end
		
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local humanoidRootPart:BasePart = player.Character:FindFirstChild("HumanoidRootPart")::BasePart

		if (not humanoidRootPart) or (not humanoid) then return end
		
		humanoid.PlatformStand = true
		humanoidRootPart.CFrame = pillar.PlayerSpawn.CFrame
		humanoidRootPart.Anchored = true

		replicatedStorage.Communicators.Remotes.Events.GiveDeck:FireClient(player, plrCards[i])
	end
end

function setCircles(enabled:boolean)
	for i, circle in pairs(circleTemplate.Parent:GetChildren()) do
		if circle:IsA("Frame") and circle.Name ~= "CircleTemplate" then
			circle:Destroy()
		end
	end
	
	if not enabled then return end
	
	local n = #playerTable
	
	if n == 0 then return end
	
	mainScreen.SurfaceGui.TextLabel1.Text = ""
	
	for i = 1, n do
		--task.wait(1)

		local circle = circleTemplate:Clone()
		local plr = playerTable[i]
		local isaPlayer, player = isPlayer(i)

		local theta = math.rad(i * 360 / n)
		local dx = -math.cos(theta)
		local dz = -math.sin(theta)

		circle.Position = UDim2.fromScale(0.5 + 0.4 * dz, 0.5 + 0.4 * dx)
		circle.Visible = true
		circle.Name = tostring(plr)
		circle.ZIndex = i

		if isaPlayer and player then
			circle.ImageLabel.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"
		else
			circle.ImageLabel.Image = "rbxassetid://" .. tostring(universalInfo["Assets"]["BotIcon"])
		end

		circle.Parent = circleTemplate.Parent
	end
end

local currentlyHighlightedCircle:Frame? = nil

function highlightPlayerCircle(index:number)
	local circleToUpdate:Frame = mainScreen.SurfaceGui.Circles:FindFirstChild(tostring(playerTable[index]))::Frame
	if not circleToUpdate then return end

	if currentlyHighlightedCircle and currentlyHighlightedCircle ~= circleToUpdate then
		local uiStroke = currentlyHighlightedCircle:FindFirstChildWhichIsA("UIStroke")::UIStroke
		if uiStroke then
			tweenService:Create(uiStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Thickness = 0}):Play()
		end
	end

	local uiStroke = circleToUpdate:FindFirstChildWhichIsA("UIStroke")::UIStroke
	if uiStroke then
		tweenService:Create(uiStroke, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Thickness = 0.25}):Play()
	end

	currentlyHighlightedCircle = circleToUpdate
end

function setPlayerStatuses(enabled:boolean)
	for i, instance in ipairs(playerStatus.SurfaceGui.ScrollingFrame:GetChildren()) do
		if instance:IsA("Frame") and instance.Name ~= "PlayerTemplate" then
			instance:Destroy()
		end
	end
	
	if (not enabled) or (#playerTable == 0) then return end
	
	for i, playerName in ipairs(playerTable) do
		local playerStatusFrame = playerStatus.SurfaceGui.ScrollingFrame.PlayerTemplate:Clone()
		local isaPlayer, player = isPlayer(i)
		
		playerStatusFrame.Name = playerName
		
		if isaPlayer and player then
			local oneUser = player.DisplayName == player.Name
			
			playerStatusFrame.ImageLabel.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"
			
			playerStatusFrame.DisplayName.Visible = not oneUser
			playerStatusFrame.UserName.Visible = not oneUser
			playerStatusFrame.OnlyDisplayName.Visible = oneUser
			
			if oneUser then
				playerStatusFrame.OnlyDisplayName.Text = player.DisplayName
			else
				playerStatusFrame.DisplayName.Text = player.DisplayName
				playerStatusFrame.UserName.Text = "@" .. player.Name
			end
		else
			playerStatusFrame.DisplayName.Visible = false
			playerStatusFrame.UserName.Visible = false
			playerStatusFrame.OnlyDisplayName.Visible = true
			
			playerStatusFrame.OnlyDisplayName.Text = playerName
			playerStatusFrame.ImageLabel.Image = "rbxassetid://" .. tostring(universalInfo["Assets"]["BotIcon"])
		end
		
		playerStatusFrame.LayoutOrder = -99999
		playerStatusFrame.Visible = true
		playerStatusFrame.Parent = playerStatus.SurfaceGui.ScrollingFrame
	end
end

local statuses : {[string] : Color3} = {
	["Off Duty"] = Color3.fromRGB(255, 180, 180),
	["Disconnected"] = Color3.fromRGB(180, 180, 180),
}

function updatePlayerStatus(index:number, status:string)
	local player = playerTable[index]
	local playerStatusFrame = playerStatus.SurfaceGui.ScrollingFrame:FindFirstChild(tostring(player))::Frame
	if not playerStatusFrame then return end
	
	local h, s, v = statuses[status]:ToHSV()
	local darkerColour = Color3.fromHSV(h, s, v * 0.5)
	
	playerStatusFrame.BackgroundColor3 = Color3.fromHSV(h, s, v)
	
	for i, child in ipairs(playerStatusFrame:GetChildren()) do
		if child.Name == "Divider" and child:IsA("Frame") then
			child.BackgroundColor3 = darkerColour
		end
	end
	
	local uiStroke = playerStatusFrame:FindFirstChildWhichIsA("UIStroke")::UIStroke
	if uiStroke then
		uiStroke.Color = darkerColour
	end
	
	local statusLabel = playerStatusFrame:FindFirstChild("Status")::TextLabel
	if statusLabel then
		statusLabel.Text = status
	end
	
	local timeLabel = playerStatusFrame:FindFirstChild("Time")::TextLabel
	if timeLabel and roundTime then
		local timeOnDuty = workspace.DistributedGameTime - roundTime
		
		playerStatusFrame.LayoutOrder = -timeOnDuty
		timeLabel.Text = formatTime(timeOnDuty)
		timeLabel.Visible = true
	else
		playerStatusFrame.LayoutOrder = 99999
	end
end

function moveTurnIndicator(index:number, tween:boolean?)
	local isaPlayer, player = isPlayer(index)
	
	local primary
	
	if isaPlayer and player then
		local character = player.Character
		if not character then return end
		
		primary = character.PrimaryPart
	else
		local bot = roundFolder.Bots:FindFirstChild(playerTable[index])::Model?
		if not bot then return end

		primary = bot.PrimaryPart
	end
	
	if not primary then return end
	
	if tween then
		tweenService:Create(turnIndicator, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CFrame = primary.CFrame * CFrame.new(0, 35, 0) * CFrame.Angles(math.rad(180), 0, 0)}):Play()
	else
		turnIndicator.CFrame = primary.CFrame * CFrame.new(0, 50, 0) * CFrame.Angles(math.rad(180), 0, 0)
	end
end

--------------------------------- Primary Functions ---------------------------------

function setTweenState(state:boolean)
	if state == true then
		mainScreen.SurfaceGui.WarningStripes1.Position = UDim2.fromScale(0, mainScreen.SurfaceGui.WarningStripes1.Position.Y.Scale)
		mainScreen.SurfaceGui.WarningStripes2.Position = UDim2.fromScale(0, mainScreen.SurfaceGui.WarningStripes2.Position.Y.Scale)
		
		tweenService:Create(mainScreen.SurfaceGui.WarningStripes1, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
		tweenService:Create(mainScreen.SurfaceGui.WarningStripes2, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
		
		tweenTable[#tweenTable + 1] = tweenService:Create(mainScreen.SurfaceGui.WarningStripes1, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Position = UDim2.fromScale(1, mainScreen.SurfaceGui.WarningStripes1.Position.Y.Scale)})
		tweenTable[#tweenTable + 1] = tweenService:Create(mainScreen.SurfaceGui.WarningStripes2, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Position = UDim2.fromScale(1, mainScreen.SurfaceGui.WarningStripes2.Position.Y.Scale)})
		
		for i, tween in pairs(tweenTable) do
			tween:Play()
		end
		
		task.spawn(function()
			while task.wait(5) do
				if not tweenTable[1] then break end
				
				if tweenTable[1].PlaybackState == Enum.PlaybackState.Playing then
					mainScreen.SurfaceGui.WarningStripes1.Position = UDim2.fromScale(0, mainScreen.SurfaceGui.WarningStripes1.Position.Y.Scale)
					mainScreen.SurfaceGui.WarningStripes2.Position = UDim2.fromScale(0, mainScreen.SurfaceGui.WarningStripes2.Position.Y.Scale)
				else
					break
				end
			end
		end)
	else
		tweenService:Create(mainScreen.SurfaceGui.WarningStripes1, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
		tweenService:Create(mainScreen.SurfaceGui.WarningStripes2, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
		
		task.wait(1)
		
		for i, tween in pairs(tweenTable) do
			tween:Cancel()
			table.remove(tweenTable, i)
		end
	end
end

function eliminatePlayer(index:number, leaving:boolean?)
	local playerName = playerTable[index]
	if not playerName then return end
	
	local isaPlayer, player = isPlayer(index)
	local pillarToDestroy
	
	
	if not isaPlayer then
		pillarToDestroy = pillarsFolder:FindFirstChild(playerName)
		
		local bot = botsFolder:FindFirstChild(playerName)
		if bot then 
			bot:Destroy() 
		end
	else
		pillarToDestroy = pillarsFolder:FindFirstChild(playerName)
		
		if player then
			replicatedStorage.Communicators.Remotes.Events.TransitionWithRound:FireClient(player)

			player:LoadCharacterAsync()
		end
	end

	if pillarToDestroy then
		local explosionModule = pillarToDestroy:WaitForChild("ExplosionModule")::Instance
		if explosionModule and explosionModule:IsA("ModuleScript") then
			require(explosionModule).explode()
		end
	end
	
	updatePlayerStatus(index, if leaving then "Disconnected" else "Off Duty")

	removePlayerFromTable(index)
end

function transitionCard(card:string, from:Vector3, to:Vector3, parabolic:boolean?)
	if not cardInfo[card] then return end
	
	local cardBillboard = serverStorage.ServerAssets.CardBillboard:Clone()
	cardBillboard.Position = from
	cardBillboard.BillboardGui.ImageLabel.Image = "rbxassetid://" .. cardInfo[card]["IconID"]
	cardBillboard.BillboardGui.ImageLabel.Position = UDim2.fromScale(0.5, 1)
	cardBillboard.Attachment0.Trail.Color = ColorSequence.new(cardInfo[card]["Colour"]::Color3)
	cardBillboard.Parent = workspace
	
	task.spawn(function()
		tweenService:Create(cardBillboard.BillboardGui.ImageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		
		task.wait(0.5)
		
		if not parabolic then
			tweenService:Create(cardBillboard, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Position = to}):Play()
			tweenService:Create(cardBillboard.BillboardGui.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0)}):Play()
		else
			tweenService:Create(cardBillboard.BillboardGui.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0)}):Play()
			bezier(cardBillboard, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), from, Vector3.new(from.X + ((2 / 3) * (to.X - from.X)), (from.Y + ((1 / 3) * (to.Y - from.Y))) + 10, from.Z + ((2 / 3) * (to.Z - from.Z))), to)
		end
		
		task.wait(1)
		
		local particleAttachment = serverStorage.ServerAssets.ParticleAttachment:Clone()
		particleAttachment.Position = to
		particleAttachment.Sparkles.Color = ColorSequence.new(cardInfo[card]["Colour"]::Color3)
		particleAttachment.Shockwave.Color = ColorSequence.new(cardInfo[card]["Colour"]::Color3)
		particleAttachment.Parent = workspace
		
		particleAttachment.Sparkles:Emit(15)
		particleAttachment.Shockwave:Emit(1)
		
		task.wait(1)
		
		cardBillboard:Destroy()
		particleAttachment:Destroy()
	end)
end

function cardTakenFromDeck(index:number) : boolean
	if (not deck) or (not plrCards) then return false end

	local card = deck[1]
	local isaPlayer, player = isPlayer(index)
	local from = roundFolder.Cards.Deck:FindFirstChild(tostring(#deck))::BasePart
	
	table.remove(deck, 1)
	
	if card == "Exposed Nuke" then
		deckManager.SetTurnCount(1)
		setDeckModel("RemoveFirst")
		eliminatePlayer(index)

		return true
	end
	
	if card ~= "Dynamite" then
		deckManager.SetTurnCount(deckManager.GetTurnCount() - 1)
		table.insert(plrCards[index], card)

		if isaPlayer and player then
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(player, "AddCard", card)
		end
		
		local to = pillarsTable[index]::Model
		
		if to and to.PrimaryPart then
			transitionCard("CardBack", from.Position + Vector3.new(0, 15, 0), to.PrimaryPart.Position + Vector3.new(0, 14, 0), true)
		end
		
		setDeckModel("RemoveFirst")
		
		return false
	end
	
	-- Dynamite
	
	if table.find(plrCards[index], "Containment") and not table.find(plrCards[index], "Dynamite") then
		deckManager.SetTurnCount(deckManager.GetTurnCount() - 1)
		table.insert(plrCards[index], card)
		
		if isaPlayer and player then
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(player, "AddCard", card)
		end
		
		local to = pillarsTable[index]::Model

		if to and to.PrimaryPart then
			transitionCard("CardBack", from.Position + Vector3.new(0, 15, 0), to.PrimaryPart.Position + Vector3.new(0, 14, 0), true)
		end
		
		setDeckModel("RemoveFirst")
		
		return false
	end


	if table.find(plrCards[index], "Defuse") then
		deckManager.SetTurnCount(deckManager.GetTurnCount() - 1)
		
		local primary = pillarsTable[index].PrimaryPart

		if primary then
			transitionCard("Defuse", primary.Position + Vector3.new(0, 30, 0), workspace.UsedCards.Position + Vector3.new(0, 0.25 + (0.5 * (usedCardCount)), 0), true)
		end

		task.spawn(function()
			task.wait(1.5)
			setUsedCardsModel({"Defuse"})
		end)
		
		table.remove(plrCards[index], table.find(plrCards[index], "Defuse"))

		if isaPlayer and player then
			replicatedStorage.Communicators.Remotes.Events.OrderClientAction:FireClient(player, "RemoveFirst", "Defuse")
		end
		
		deck = deckManager.InsertCardAtRandomPosition(deck, "Dynamite")	

		--setDeckModel("RemoveFirst")
		
		return false
	end
	
	-- No defuse and dynamite
	
	task.spawn(function()
		local primary = pillarsTable[index].PrimaryPart

		if primary then
			task.wait((#plrCards[index] + 1) * 0.125)
			
			transitionCard("Dynamite", from.Position + Vector3.new(0, 15, 0), workspace.UsedCards.Position + Vector3.new(0, 0.25 + (0.5 * (usedCardCount)), 0), true)
		end
	end)

	task.spawn(function()
		task.wait(((#plrCards[index] + 1) * 0.125) + 1.5)
		setUsedCardsModel({"Dynamite"})
	end)
	
	task.wait(0.125)

	deckManager.SetTurnCount(1)
	eliminatePlayer(index)
	setDeckModel("RemoveFirst")

	return true
end

function initiateAction(index:number, action:{[string]:any})
	if not plrCards then return end
	if #playerTable <= 1 then return end
	
	if action.Type == "Steal" then
		print("Steal")
	elseif action.Type == "Triple Steal" then
		print("Triple Steal")
	end
end

function getDecision(index:number) : string?|{string}?
	if not deck then return nil end
	
	local playerName = playerTable[index]
	local isaPlayer, player = isPlayer(index)

	if not isaPlayer then
		task.wait(math.random(5, 15) / 10)
		
		local decision = botLogic.Play(botsFolder:FindFirstChild(playerName), initialDeckSize, #playerTable, #deck)

		if decision == "Play" then
			local cardPlayed = botLogic.playCard(botsFolder:FindFirstChild(playerName)::Instance, plrCards[index])
			return cardPlayed == "Take" and "Take" or {cardPlayed}
		end

		return decision
	end
	
	if not player then return nil end

	local playerDecision:string|{string}
	
	local success = pcall(function()
		playerDecision = replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision:InvokeClient(player)
	end)

	if not success then
		return "Disconnected"
	end

	return playerDecision
end

function checkDecision(index:number, decision:string | {string} ) : boolean
	local playerName = playerTable[index]
	local isaPlayer, player = isPlayer(index)

	if decision == "Disconnected" then
		removePlayerFromTable(index)
		return true
	end

	if typeof(decision) == "table" then
		if #decision == 1 then
			print(tostring(playerName) .. " has chosen: " .. decision[1])
			
			local module = script.CardModules:FindFirstChild(decision[1])::Instance
			if module then
				require(script.CardModules:FindFirstChild(decision[1])::Instance).Main(player, plrCards[index])
			end
			
			local primary = pillarsTable[index].PrimaryPart
			
			if primary then
				transitionCard(decision[1], primary.Position + Vector3.new(0, 30, 0), workspace.UsedCards.Position + Vector3.new(0, 0.25 + (0.5 * (usedCardCount)), 0), true)
			end
			
			task.spawn(function()
				task.wait(1.5)
				setUsedCardsModel(decision)
			end)
			
			table.remove(plrCards[index], table.find(plrCards[index], decision[1]))
		else
			for i, card in ipairs(decision) do
				local module = script.CardModules:FindFirstChild(decision[i])::Instance
				if module then
					require(script.CardModules:FindFirstChild(decision[i])::Instance).Main(player, plrCards[index])
				end

				local primary = pillarsTable[index].PrimaryPart

				if primary then
					transitionCard(decision[1], primary.Position + Vector3.new(0, 30, 0), workspace.UsedCards.Position + Vector3.new(0, 0.25 + (0.5 * (usedCardCount)), 0), true)
				end

				task.spawn(function()
					task.wait(1.5)
					setUsedCardsModel(decision)
				end)
				
				table.remove(plrCards[index], table.find(plrCards[index], decision[i]))
			end
		end
		
		return false
	end

	print(tostring(playerName) .. " has chosen: " .. decision)
	
	if decision == "AFK" and isaPlayer and player then
		local penalty = (player:GetAttribute("AFKPenalty") or 0) + 1
		player:SetAttribute("AFKPenalty", penalty)

		if penalty >= 3 then
			player:Kick("Fired! Inactive during bomb duty")
			return true
		end
	end
	
	if decision == "Take" or decision == "AFK" then
		local eliminated = cardTakenFromDeck(index)
		
		if eliminated then return true end
	end

	return false
end

function turn(index:number) : boolean
	if deck == nil then return false end

	if deckManager.GetTurnCount() == 0 then
		deckManager.SetTurnCount(1)
	end

	deckManager["IsRoundTerminated"] = false
	
	moveTurnIndicator(index, true)
	
	highlightPlayerCircle(index)

	task.wait(0.25)

	local eliminated = false
	
	repeat
		if #playerTable <= 1 then break end
		if not playerTable[index] then break end

		if deckManager["IsRoundTerminated"] then
			deckManager["IsRoundTerminated"] = false
			break
		end

		local decision = getDecision(index)
		if not decision then break end

		eliminated = checkDecision(index, decision)

		if eliminated then break end

		task.wait(0.25)
	until deckManager.GetTurnCount() <= 0 or eliminated

	deckManager.UpdateDeck(deck)

	return eliminated
end

function beginRound()
	roundTime = workspace.DistributedGameTime
	
	plrCards = deckManager.CreatePlayerDecks(#playerTable)
	deck = deckManager.Shuffle(deckManager.CreateDeck(#playerTable))
	initialDeckSize = #deck
	
	print(deck)
	
	replicatedStorage.Communicators.Remotes.Events.TransitionWithRound:FireAllClients()
	
	task.wait(3)

	setPillars()
	setCircles(true)
	setPlayerStatuses(true)
	setDeckModel("Set")
	
	deckManager.UpdateDeck(deck)
	
	task.wait(2)
end

function runRoundLoop()
	currentTurnIndex = math.random(1, #playerTable)
	
	tweenService:Create(turnIndicator, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Transparency = 0, Size = Vector3.new(10, 15, 10)}):Play()

	moveTurnIndicator(currentTurnIndex)
	
	local eliminated = turn(currentTurnIndex)

	while task.wait(0.25) do
		if #playerTable == 1 or #playerTable == 0 or #deck == 0 then
			print("Ending bomb duty", playerTable, #playerTable, deck, #deck)
			
			break
		end

		if not eliminated then
			currentTurnIndex = (currentTurnIndex >= #playerTable) and 1 or currentTurnIndex + 1
		elseif currentTurnIndex > #playerTable then
			currentTurnIndex = 1
		end

		eliminated = turn(currentTurnIndex)
	end
	
	task.wait(3)
end

function endRound()
	print("Round Complete")

	pillarsFolder:ClearAllChildren()
	botsFolder:ClearAllChildren()

	for i, playerName in ipairs(playerTable) do
		local isaPlayer, player = isPlayer(i)
		
		if (not isaPlayer) or (not player) then continue end
		
		replicatedStorage.Communicators.Remotes.Events.TransitionWithRound:FireClient(player)

		local character = player.Character
		if not character then continue end

		local hrp = character:FindFirstChild("HumanoidRootPart")::BasePart
		if not hrp then continue end

		hrp.Anchored = false
		player:LoadCharacterAsync()
	end
	
	task.spawn(function()
		setCircles(false)
	end)
	
	task.spawn(function()
		setPlayerStatuses(false)	
	end)
	
	task.spawn(function()
		clearValues()	
	end)
	
	task.spawn(function()
		setDeckModel("RemoveAll")	
	end)
	
	task.spawn(function()
		setUsedCardsModel({}, "RemoveAll")
	end)
		
	turnIndicator.Transparency = 1
	mainScreen.SurfaceGui.TextLabel2.Text = ""

	task.wait(3)
end

function setUpRound()
	beginRound()
	runRoundLoop()
	endRound()
end

function gameLoop()
	while true do
		mainScreen.SurfaceGui.TextLabel1.Size = UDim2.fromScale(0.75, 0.25)
		mainScreen.SurfaceGui.TextLabel1.Text = "Intermission"
		
		local pulseTween = tweenService:Create(mainScreen.SurfaceGui.TextLabel1, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, intermissionLength / 2, true), {TextTransparency = 0.75})
		pulseTween:Play()
		
		task.wait(intermissionLength + 2)
		
		setTweenState(true)
		
		for countDown = bombDutyCountdownLength, 1, -1 do
			mainScreen.SurfaceGui.TextLabel1.Text = "Bomb duty in " .. tostring(countDown) .. "s"
			task.wait(1)
		end

		mainScreen.SurfaceGui.TextLabel1.Text = "Bomb duty now!"
		
		setTweenState(false)
		
		for i, player in ipairs(players:GetPlayers()) do
			table.insert(playerTable, player.Name)
		end
		
		local numberOfBots = botCountOverride or math.max(4 - #playerTable, 0)
		
		if numberOfBots ~= 0 then
			for i = 1, numberOfBots do
				table.insert(playerTable, "Bot" .. i)
			end
		end
		
		Random.new():Shuffle(playerTable)
		
		setUpRound()
	end
end

--------------------------------- Connections ---------------------------------

replicatedStorage.Communicators.Remotes.Events.InitiateAction.OnServerEvent:Connect(function(plr:Player, actionType:string, cards:{string})
	local index = table.find(playerTable, plr.Name)
	if not index then return end
	if plr.Name ~= playerTable[currentTurnIndex] then return end
	
	local currentCards = copyTable(plrCards[index])
	
	if (actionType == "Steal" or "Triple Steal") then
		for i, card in ipairs(cards) do
			if table.find(currentCards, card) then
				table.remove(currentCards, table.find(currentCards, card))
			else
				return
			end
		end
		
		initiateAction(index, {["Type"] = actionType, ["Cards"] = cards})
	end
end)

function init()
	turnIndicator.Size = Vector3.new(0.01, 0.015, 0.01)
	
	task.spawn(function()
		gameLoop()
	end)
end

players.PlayerRemoving:Connect(function(player)
	local index = table.find(playerTable, player.Name)
	
	if index then
		eliminatePlayer(index, true)
	end
end)

init()