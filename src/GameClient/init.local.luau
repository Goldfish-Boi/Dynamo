--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local debris = game:GetService("Debris")
local replicatedStorage = game:GetService("ReplicatedStorage")

local cardInfo:{[string]:any} = require(replicatedStorage.Modules.CardInfo)::{[string]:any}

local gui = script.Parent
local cardContainer = gui.CardContainer
local listLayout = cardContainer.UIListLayout
local containerAbsSize = cardContainer.AbsoluteSize.X
local containerAbsPos = cardContainer.AbsolutePosition.X
local cardDescription = gui.CardDescription
local takeCard = gui.TakeCard
local cardActions = gui.CardActions
local sounds = script.Sounds

local dragTarget:UDim2?
local decision:string|{string}?

--local cardCount:number = 0
local debounce:boolean = false
local antiInactivityCountdown:number = 20

local cardRestState:{[Frame] : {rotation:number, yOffset:number}} = {}
local cards:{Frame} = {}
local cardsSelected:{Frame} = {}

local dragConnection:RBXScriptConnection?
local countdownThread:thread

-------------------------------------- Helper Functions --------------------------------------

function findfirstcard(name) : (number?, Frame?)
	local index = nil
	local object = nil
	
	for i, obj in cards do
		if obj.Name == name then
			index = i
			object = obj
			break
		end
	end
	
	return index, object
end

function getIndexFromLayoutOrder(card:Frame):number
	local index = 1
	
	for i, frame in ipairs(cards) do
		if frame.LayoutOrder < card.LayoutOrder then
			index += 1
		end
	end	
	
	return index
end

function moveCardToPosition(card:Frame, n:number)
	local currentIndex = table.find(cards, card)
	if not currentIndex then return end

	n = math.clamp(n, 1, #cards)

	table.remove(cards, currentIndex)
	table.insert(cards, n, card)

	for i, card in cards do
		card.LayoutOrder = i * 10
		card.ZIndex = i * 10
	end
end

function highlightCardType(cardName:string?)
	for i, cardFrame in ipairs(cardContainer:GetChildren()) do
		local icon = cardFrame:FindFirstChild("Icon")::ImageButton
		
		if icon then
			tweenService:Create(icon, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageColor3 = Color3.new(1, 1, 1)}):Play()
		end
	end
	
	if not cardName then return end
	
	for i, cardFrame in ipairs(cardContainer:GetChildren()) do
		if cardFrame.Name == cardName then continue end
		
		local icon = cardFrame:FindFirstChild("Icon")::ImageButton

		if icon then
			tweenService:Create(icon, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageColor3 = Color3.new(0.6, 0.6, 0.6)}):Play()
		end
	end
end

function adjustDeckFromTable()
	for i, card in ipairs(cardContainer:GetChildren()) do
		if card:IsA("Frame") then
			card:Destroy()
		end
	end
	
	--cardCount = 0

	for i, card in cards do
		task.wait()
		addCard(card.Name)
	end

	updateScaling()
end

function activateCards(enabled:boolean)
	for i, instance in ipairs(cardContainer:GetDescendants()) do
		if instance:IsA("ImageButton") then
			instance.Active = enabled
		elseif instance:IsA("UIDragDetector") then
			instance.Enabled = not enabled
		end
	end
end

function generateDeckFromTable(deck:{string}, addDelay:boolean?)
	for i, card in ipairs(deck) do
		addCard(card)
		
		if addDelay then
			task.wait(0.05)
		end
	end
end

function updateCardArc(card:Frame, index:number)
	local n = #cards
	if n == 0 then return end
	
	local t = n > 1 and (index - (n + 1) / 2) / ((n - 1) / 2) or 0

	local rotation = t * 7.5
	local yOffset = (t * t) * 0.2

	cardRestState[card] = {rotation = rotation, yOffset = yOffset}

	if table.find(cardsSelected, card) then return end

	local icon = card:FindFirstChild("Icon")::ImageButton
	if not icon then return end

	tweenService:Create(icon, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5 + yOffset), Rotation = rotation}):Play()
end

function updateAllCardArcs()
	local n = #cards
	if n == 0 then return end

	for i, card in cards do
		updateCardArc(card, i)
	end
end

function updateCardActions(card:Frame?)
	--print(card.Name, #cardsSelected)
	
	if card and cardInfo[card.Name]["Usable"] then
		if #cardsSelected > 0 then
			if not cardActions.Use.Visible then
				cardActions.Use.Size = UDim2.fromScale(0.001, 1)
			end
			
			cardActions.Use.Visible = true

			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.333, 1)}):Play()
		else
			if cardActions.Use.Visible then
				task.spawn(function()
					tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.001, 1)}):Play()	

					task.wait(0.25)

					cardActions.Use.Visible = false
				end)
			end
		end
	else
		task.spawn(function()
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.001, 1)}):Play()	

			task.wait(0.25)

			cardActions.Use.Visible = false
		end)
	end

	if #cardsSelected >= 2 then
		if not cardActions.Steal.Visible then
			cardActions.Steal.Size = UDim2.fromScale(0.001, 1)
			
			cardActions.Steal.Visible = true
			
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.333, 1)}):Play()
		end
	else
		if cardActions.Steal.Visible then
			task.spawn(function()
				tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.001, 1)}):Play()

				task.wait(0.25)

				cardActions.Steal.Visible = false
			end)
		end
	end

	if card then
		cardActions.Use.TextLabel.Text = if cardInfo[card.Name]["CanStack"] and #cardsSelected > 1 then "Use Multiple" else "Use"
		cardActions.Steal.TextLabel.Text = if #cardsSelected <= 2 then "Steal" else "Super Steal"
	end
end

-------------------------------------- Primary Functions --------------------------------------

function addCardFunctionality(card:Frame)
	local icon:ImageButton = card:FindFirstChild("Icon")::ImageButton
	if not icon then return end

	local dragDetector = icon:FindFirstChildOfClass("UIDragDetector")
	if not dragDetector then return end

	card.MouseEnter:Connect(function()
		if table.find(cardsSelected, card) or dragConnection then return end

		local rest = cardRestState[card] or {rotation = 0, yOffset = 0}

		tweenService:Create(icon, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, math.max(0.5 + rest.yOffset - 0.375, 0)), Rotation = 0}):Play()
	end)

	card.MouseLeave:Connect(function()
		if table.find(cardsSelected, card) or dragConnection then return end

		local rest = cardRestState[card] or {rotation = 0, yOffset = 0}

		tweenService:Create(icon, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5 + rest.yOffset), Rotation = rest.rotation}):Play()
	end)

	icon.Activated:Connect(function()
		selectCard(card)
	end)
	
	local n:number?
	local prevN:number?
	
	local pseudoCard:Frame?
	local originalIndex:number?
	
	local smoothX:number = 0
	local smoothY:number = 0
	local velX:number = 0
	local velY:number = 0
	
	dragDetector.DragStart:Connect(function(initialPosition)
		print("Dragging")
		
		icon.BackgroundTransparency = 1
		icon.ImageTransparency = 1
		
		for i, frame in ipairs(cards) do
			if frame == card then continue end
			
			local cardIcon = frame:FindFirstChild("Icon")::ImageButton
			if not cardIcon then continue end
			
			tweenService:Create(cardIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5), Rotation = 0}):Play()
		end
		
		local uiStroke = icon:FindFirstChildOfClass("UIStroke")
		if uiStroke then
			uiStroke.Transparency = 1
		end
		
		pseudoCard = script.CardTemplate:Clone()
		pseudoCard.Parent = gui
		pseudoCard.Position = UDim2.fromOffset(card.AbsolutePosition.X, card.AbsolutePosition.Y)
		pseudoCard.Size = UDim2.fromOffset(card.AbsoluteSize.X, card.AbsoluteSize.Y)
		
		local pIcon = pseudoCard:FindFirstChildOfClass("ImageButton")
		if pIcon then
			pIcon.BackgroundColor3 = icon.BackgroundColor3
			
			if cardInfo[card.Name]["IconID"] then
				pIcon.Image = "rbxassetid://" .. cardInfo[card.Name]["IconID"]
			end
		end
		
		local shadow = script.UIShadow:Clone()
		shadow.Parent = pIcon
		
		tweenService:Create(shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BlurRadius = UDim.new(0.05, 0), Offset = UDim2.fromScale(0.125, 0.125)}):Play()
		
		smoothX = 0
		smoothY = 0
		velX = 0
		velY = 0
		originalIndex = table.find(cards, card)
		
		dragTarget = dragDetector.DragUDim2
		
		dragConnection = runService.RenderStepped:Connect(function(dt)
			if not dragTarget then return end
			if not pseudoCard then return end

			local newPosX, newVelX = tweenService:SmoothDamp(smoothX, dragTarget.X.Offset, velX, 0.05)
			local newPosY, newVelY = tweenService:SmoothDamp(smoothY, dragTarget.Y.Offset, velY, 0.05)
			
			smoothX, velX = newPosX, newVelX
			smoothY, velY = newPosY, newVelY
			
			pseudoCard.Rotation = velX / 100

			pseudoCard.Position = UDim2.fromOffset(initialPosition.X + smoothX - (pseudoCard.AbsoluteSize.X / 2), initialPosition.Y + smoothY - (pseudoCard.AbsoluteSize.Y / 2))

			local a = ((pseudoCard.AbsolutePosition.X + pseudoCard.AbsoluteSize.X / 2) - cardContainer.AbsolutePosition.X) / (cardContainer.AbsoluteSize.X)

			n = math.clamp(math.round(1 + a * (#cards - 1)), 1, #cards)
			
			if n ~= prevN then
				task.spawn(function()
					if not n then return end
					if not originalIndex then return end
					
					card.LayoutOrder = if n <= originalIndex then n * 10 - 5 else n * 10 + 5
					
					sounds.MoveCard.PitchShiftSoundEffect.Octave = 1 + (math.random(-5, 5) / 100)
					sounds.MoveCard:Play()
				end)
			end
			
			prevN = n
		end)
	end)

	dragDetector.DragContinue:Connect(function()
		dragTarget = dragDetector.DragUDim2
	end)

	dragDetector.DragEnd:Connect(function()
		print("Stopped")
		
		if dragConnection then
			dragConnection:Disconnect()
			dragConnection = nil -- clear this BEFORE updateCardArc, or it'll skip every card
		end

		if n then
			moveCardToPosition(card, n)
		end

		updateAllCardArcs()

		local rest = cardRestState[card] or {rotation = 0, yOffset = 0}
		icon.Position = UDim2.fromScale(0.5, 0.5 + rest.yOffset)
		icon.Rotation = rest.rotation
		
		if pseudoCard then
			local pc = pseudoCard
			pseudoCard = nil
			
			task.spawn(function()
				runService.RenderStepped:Wait()
				
				local shadow = pc:FindFirstChildWhichIsA("UIShadow", true)
				if shadow then
					tweenService:Create(shadow, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BlurRadius = UDim.new(0, 0), Offset = UDim2.fromScale(0, 0)}):Play()
				end
				
				tweenService:Create(pc, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(card.AbsolutePosition.X, card.AbsolutePosition.Y), Rotation = 0}):Play()
				task.wait(0.1)
				
				pc:Destroy()
				icon.BackgroundTransparency = 0
				icon.ImageTransparency = 0
				
				local uiStroke = icon:FindFirstChildOfClass("UIStroke")
				if uiStroke then
					uiStroke.Transparency = 0
				end
			end)
		end
		
		n = nil
	end)
end

listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly

function updateScaling()
	if #cards == 0 then return end

	local containerWidth = cardContainer.AbsoluteSize.X
	local cardWidth = cards[1].AbsoluteSize.X

	if #cards == 1 then
		listLayout.Padding = UDim.new(0, 0)
		return
	end

	local totalCardWidth = cardWidth * #cards
	local availableGapSpace = containerWidth - totalCardWidth

	if availableGapSpace >= 0 then
		listLayout.Padding = UDim.new(0, 0)
	else
		local paddingPerGap = availableGapSpace / (#cards - 1)

		--tweenService:Create(listLayout, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Padding = UDim.new(0, paddingPerGap)}):Play()
		listLayout.Padding = UDim.new(0, paddingPerGap)
	end
end

function addCard(card:string | {string})
	if typeof(card) == "table" then
		for i, cardString in pairs(card) do
			addCard(cardString)
		end
		
		return
	end
	
	local newCard = script.CardTemplate:Clone()
	
	if cardInfo[card]["IconID"] then
		newCard.Icon.Image = "rbxassetid://" .. cardInfo[card]["IconID"]
		newCard.Icon.BackgroundColor3 = Color3.new(0, 0, 0)
	else
		newCard.Icon.BackgroundColor3 = cardInfo[card]["Colour"]

	end

	newCard.LayoutOrder = #cards * 10
	newCard.ZIndex = #cards * 10
	newCard.Visible = true
	newCard.Name = card
	newCard.UIAspectRatioConstraint.AspectRatio = 0.1

	cards[#cards + 1] = newCard

	newCard.Parent = cardContainer
	
	tweenService:Create(newCard.UIAspectRatioConstraint, TweenInfo.new(0.125, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {AspectRatio = 0.714}):Play()
	
	task.spawn(function()
		newCard.Icon.Size = UDim2.fromScale(0.25, 1.5)
		task.wait(0.125)
		
		newCard.Icon.Size = UDim2.fromScale(1.1, 0.8)
		task.wait(0.125)
		
		newCard.Icon.Size = UDim2.fromScale(0.95, 1.05)
		task.wait(0.125)
		
		newCard.Icon.Size = UDim2.fromScale(1, 1)
	end)
	
	updateScaling()
	
	addCardFunctionality(newCard)
	updateAllCardArcs()
	
	debounce = false
end

function removeCard(index)
	local cardToRemove = cards[index]
	if not cardToRemove then return end
	
	local icon:ImageButton = cardToRemove:FindFirstChild("Icon")::ImageButton
	if not icon then return end
	
	local aspectRatio = cardToRemove:FindFirstChildOfClass("UIAspectRatioConstraint")
	if not aspectRatio then return end
	
	cardToRemove.ZIndex -= 5
	cardToRemove.LayoutOrder -= 5
	
	if table.find(cardsSelected, cardToRemove) then
		table.remove(cardsSelected, table.find(cardsSelected, cardToRemove))
	end

	for i = index + 1, #cards do
		local card = cards[i]

		if card then
			card.LayoutOrder -= 10
			card.ZIndex -= 10
		end
	end
	
	table.remove(cards, index)

	task.spawn(function()
		icon.Size = UDim2.fromScale(0.95, 1.05)
		task.wait(0.125)
		
		icon.Size = UDim2.fromScale(1.1, 0.8)
		task.wait(0.125)
		
		icon.Size = UDim2.fromScale(0.25, 1.5)
		
		tweenService:Create(aspectRatio, TweenInfo.new(0.125, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {AspectRatio = 0.001}):Play()
	end)
	
	print("Removed", cards, cardsSelected, #cardsSelected)
	
	debris:AddItem(cardToRemove, 0.375)
	
	task.spawn(function() updateScaling() end)
	updateCardActions()
	updateAllCardArcs()
end

function selectCard(card:Frame)
	local icon = card:FindFirstChild("Icon")::ImageButton
	if not icon then return end
	
	if #cardsSelected > 0 then
		for i, selectedCard in pairs(cardsSelected) do
			if selectedCard.Name == card.Name then continue end
			
			deselectAllCards(true, true)
			
			break
		end
	end
	
	if table.find(cardsSelected, card) then
		deselectCard(card)
		return
	else
		table.insert(cardsSelected, card)

		sounds.SelectCard.PitchShiftSoundEffect.Octave = 1 + (math.random(-10, 10) / 100)
		sounds.SelectCard:Play()
		
		tweenService:Create(icon, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0), Rotation = 0}):Play()
	end
	
	if #cardsSelected > 3 then
		deselectCard(cardsSelected[1], nil, true)
	end
	
	task.defer(function()
		highlightCardType(card.Name)
		updateCardActions(card)
	end)
end

function deselectCard(card:Frame, skipUpdate:boolean?, silent:boolean?)
	local icon = card:FindFirstChild("Icon")::ImageButton
	
	table.remove(cardsSelected, table.find(cardsSelected, card))
	
	if not icon then return end
	
	local rest = cardRestState[card] or {rotation = 0, yOffset = 0}
	
	tweenService:Create(icon, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5 + rest.yOffset), Rotation = rest.rotation}):Play()
	
	if not silent then
		sounds.DeselectCard.PitchShiftSoundEffect.Octave = 1 + (math.random(-10, 10) / 100)
		sounds.DeselectCard:Play()
	end
	
	if skipUpdate then return end
	
	highlightCardType(if #cardsSelected == 0 then nil else cardsSelected[1].Name)
	updateCardActions(if #cardsSelected == 0 then nil else cardsSelected[1])
end

function deselectAllCards(silent:boolean?, hideSound:boolean?)
	local cardsToDeselect = {}

	for i, card in pairs(cardsSelected) do
		table.insert(cardsToDeselect, card)
	end

	for i, card in cardsToDeselect do
		deselectCard(card, true, hideSound)
	end
	
	if silent then return end
	
	highlightCardType(nil)
	updateCardActions(nil)
end

takeCard.Activated:Connect(function()
	if debounce then return end
	
	debounce = true
	
	takeCard.Visible = false
	
	antiInactivityCountdown = 20
	
	deselectAllCards()
	highlightCardType(nil)
	activateCards(false)
	
	if countdownThread then
		coroutine.close(countdownThread)
	end
	
	task.delay(0.5, function() debounce = false end)
	
	if decision == "Awaiting" then
		decision = "Take"
	end
end)

cardActions.Use.Activated:Connect(function()
	if decision == "Awaiting" and #cardsSelected > 0 then
		local cardsToUse = table.clone(cardsSelected)
		local cardsToSend = {}
		
		for i, card:Frame in ipairs(cardsToUse) do
			local indexToRemove = table.find(cards, card)
			if not indexToRemove then continue end
			
			table.insert(cardsToSend, card.Name)
			
			removeCard(indexToRemove)
		end
		
		takeCard.Visible = false
		
		antiInactivityCountdown = 20
		
		print(cardsToSend)
		
		decision = cardsToSend
		
		if countdownThread then
			coroutine.close(countdownThread)
		end
		
		deselectAllCards()
		highlightCardType(nil)
		activateCards(false)
	end
end)

cardActions.Steal.Activated:Connect(function()
	if decision == "Awaiting" and #cardsSelected >= 2 then
		antiInactivityCountdown = 20
		
		local cardsToRemove = table.clone(cardsSelected)
		
		local cardNames = {}
		for i, card in ipairs(cardsSelected) do
			table.insert(cardNames, card.Name)
		end
		
		replicatedStorage.Communicators.Remotes.Events.InitiateAction:FireServer(if #cardsSelected == 3 then "Triple Steal" else "Steal", cardNames)
		
		for i, card in ipairs(cardsToRemove) do
			local indexToRemove = table.find(cards, card)
			if not indexToRemove then continue end
			
			print(indexToRemove)
			
			removeCard(indexToRemove)
		end
		
		cardsSelected = {}
		
		highlightCardType(nil)
		updateCardActions(nil)
	end
end)

function hoverCard(card:Frame)
	print("Hovering " .. card.Name)
	
	local icon = card:FindFirstChild("Icon")::ImageButton
	if not icon then return end
	
	tweenService:Create(icon, TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.125)}):Play()
end

replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision.OnClientInvoke = function():string|{string}
	antiInactivityCountdown = 20
	decision = "Awaiting"
	
	gui.TakeCard.Visible = true
	
	activateCards(true)
	
	if countdownThread then
		coroutine.close(countdownThread)
	end
	
	countdownThread = task.spawn(function()
		while task.wait(1) do
			if antiInactivityCountdown == 0 then
				break
			else
				antiInactivityCountdown -= 1
				--print(antiInactivityCountdown)
			end
		end
	end)
	
	while task.wait() do
		if decision and decision ~= "Awaiting" then
			print(decision)
			
			task.defer(function()
				decision = nil
				gui.TakeCard.Visible = false
				
				deselectAllCards()
			end)
			
			return decision
		end
		
		if antiInactivityCountdown == 0 then
			task.defer(function()
				decision = nil
				gui.TakeCard.Visible = false
				
				deselectAllCards()
			end)
			
			return "AFK"
		end
	end
	
	task.defer(function()
		decision = nil
		gui.TakeCard.Visible = false
		
		deselectAllCards()
	end)
	
	return "AFK"
end

replicatedStorage.Communicators.Remotes.Events.TransitionWithRound.OnClientEvent:Connect(function()
	cards = {}
	
	for i, card in ipairs(cardContainer:GetChildren()) do
		if card:IsA("Frame") then
			card:Destroy()
		end
	end
	
	task.wait(if cardContainer.Visible == true then 0 else 3)
	
	cardContainer.Visible = not cardContainer.Visible
	cardDescription.Visible = not cardDescription.Visible
end)

-------------------------------------- Connections --------------------------------------

cardActions.Use:GetPropertyChangedSignal("Visible"):Connect(function()
	if cardActions.Use.Visible then
		tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.7, 0.5)}):Play()
	else
		tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
	end
end)

cardActions.Steal:GetPropertyChangedSignal("Visible"):Connect(function()
	if cardActions.Steal.Visible then
		tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.3, 0.5)}):Play()
	else
		tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
	end
end)

replicatedStorage.Communicators.Remotes.Events.OrderClientAction.OnClientEvent:Connect(function(Action:string, Target:string|{string})
	if Action == "RemoveFirst" then
		local indexToRemove = findfirstcard(Target)
		if not indexToRemove then return end
		
		removeCard(indexToRemove)
	elseif Action == "AddCard" then
		addCard(Target)
	end
end)

replicatedStorage.Communicators.Remotes.Events.GiveDeck.OnClientEvent:Connect(function(deck) 
	generateDeckFromTable(deck, true)
end)