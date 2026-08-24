--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local debris = game:GetService("Debris")
local replicatedStorage = game:GetService("ReplicatedStorage")

local require = require
local cardInfo:{[string]:any} = require(replicatedStorage.Modules.CardInfo)::{[string]:any}
local universalInfo:{[string]:any} = require(replicatedStorage.Modules.UniversalInfo)::{[string]:any}

local gui = script.Parent
local cardContainer = gui.CardContainer
local listLayout = cardContainer.UIListLayout
local containerAbsSize = cardContainer.AbsoluteSize.X
local containerAbsPos = cardContainer.AbsolutePosition.X
local cardDescription = gui.CardDescription
local cardActions = gui.CardActions
local sounds = script.Sounds

--local cardCount:number = 0
local debounce:boolean = false
local haltCountDown = false
local hoveredCard:Frame? = nil
local antiInactivityCountdown:number = 20
local actionInactivityCountdown:number = 20

local cardRestState:{[Frame] : {rotation:number, yOffset:number}} = {}
local cards:{Frame} = {}
local cardsSelected:{Frame} = {}

local dragTarget:UDim2?
local decision:string|{string}|number?
local action:(number | string)?

local originalCameraCFrame:CFrame? = nil
local dragConnection:RBXScriptConnection?
local countdownThread:thread
local actionCountdownThread:thread

---------------------------------------------------------------------------------------------

listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly

-------------------------------------- Helper Functions --------------------------------------

function findFirstCard(name:string) : (number?, Frame?)
	local index = nil
	local object = nil
	
	for i, card in ipairs(cards) do
		if card.Name == name then
			index = i
			object = card
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
				
				if (cardActions.Take.Visible and cardActions.Steal.Visible) or (not cardActions.Take.Visible) and (not cardActions.Steal.Visible) then
					cardActions.Use.Position = UDim2.fromScale(0.5, 0.5)
				elseif (cardActions.Take.Visible and not cardActions.Steal.Visible) or (not cardActions.Take.Visible and cardActions.Steal.Visible) then
					cardActions.Use.Position = UDim2.fromScale(0.7, 0.5)
				end
				
				cardActions.Use.Visible = true

				tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.333, 1)}):Play()
			end
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
			
			if cardActions.Take.Visible and cardActions.Use.Visible then
				cardActions.Steal.Position = UDim2.fromScale(1, 0.5)
			elseif (cardActions.Take.Visible and not cardActions.Use.Visible) or (not cardActions.Take.Visible and cardActions.Use.Visible) then
				cardActions.Steal.Position = UDim2.fromScale(0.7, 0.5)
			elseif (not cardActions.Take.Visible) and (not cardActions.Use.Visible) then
				cardActions.Steal.Position = UDim2.fromScale(0.5, 0.5)
			end
			
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
		if cardInfo[card.Name]["CanStack"] and #cardsSelected > 1 then
			cardActions.Use.TextLabel.Text = "Use Multiple"
			cardActions.Use.ImageLabel.Image = "rbxassetid://" .. universalInfo["Assets"]["UseMultiple"]
		else
			cardActions.Use.TextLabel.Text = "Use"
			cardActions.Use.ImageLabel.Image = "rbxassetid://" .. universalInfo["Assets"]["UseCard"]
		end
		
		if #cardsSelected <= 2 then
			cardActions.Steal.TextLabel.Text = "Steal"
			cardActions.Steal.ImageLabel.Image = "rbxassetid://" .. universalInfo["Assets"]["Steal"]
		else
			cardActions.Steal.TextLabel.Text = "Triple Steal"
			cardActions.Steal.ImageLabel.Image = "rbxassetid://" .. universalInfo["Assets"]["TripleSteal"]
		end
	end
end

-------------------------------------- Primary Functions --------------------------------------

function updateCardDescription(card:Frame?)
	if not card then
		tweenService:Create(cardDescription, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 1}):Play()
		tweenService:Create(cardDescription.Title, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 1}):Play()
		tweenService:Create(cardDescription.Title.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
		tweenService:Create(cardDescription.Description, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 1}):Play()
		
		return
	end
	
	local colour = cardInfo[card.Name]["Colour"]::Color3
	local h, s, v = colour:ToHSV()
	
	local highlightColor = if cardInfo[card.Name]["UseStroke"] then colour else Color3.new(if v >= 0.5 then 0 else 1, if v >= 0.5 then 0 else 1, if v >= 0.5 then 0 else 1)
	
	cardDescription.Title.Text = card.Name
	cardDescription.Title.TextColor3 = if cardInfo[card.Name]["UseStroke"] then Color3.fromRGB(17, 17, 17) else colour
	cardDescription.Title.UIStroke.Color = if cardInfo[card.Name]["UseStroke"] then colour else highlightColor
	cardDescription.Description.Text = cardInfo[card.Name]["DeckDescription"]
	
	tweenService:Create(cardDescription, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.5}):Play()
	tweenService:Create(cardDescription.Title, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
	tweenService:Create(cardDescription.Description, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
	tweenService:Create(cardDescription.Title.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0}):Play()
end

function hoverCard(card:Frame, hovering:boolean)
	local rest = cardRestState[card] or {rotation = 0, yOffset = 0}
	local icon:ImageButton? = card:FindFirstChild("Icon")::ImageButton?
	
	if not icon then return end
	
	tweenService:Create(icon, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), if hovering then {Position = UDim2.fromScale(0.5, math.max(0.5 + rest.yOffset - 0.375, 0)), Rotation = 0} else {Position = UDim2.fromScale(0.5, 0.5 + rest.yOffset), Rotation = rest.rotation}):Play()
end

function addCardFunctionality(card:Frame)
	local icon:ImageButton = card:FindFirstChild("Icon")::ImageButton
	if not icon then return end

	local dragDetector = icon:FindFirstChildOfClass("UIDragDetector")
	if not dragDetector then return end

	--[[card.MouseEnter:Connect(function()
		if table.find(cardsSelected, card) or dragConnection then return end
		if hoveredCard == card then return end
		if hoveredCard and hoveredCard.ZIndex > card.ZIndex then return end
		
		if hoveredCard and hoveredCard.ZIndex < card.ZIndex then
			hoverCard(hoveredCard, false)
		end
		
		hoveredCard = card

		hoverCard(card, true)
	end)]]--
	
	card.MouseMoved:Connect(function()
		if table.find(cardsSelected, card) or dragConnection or hoveredCard == card or (hoveredCard and hoveredCard.ZIndex > card.ZIndex) then return end
		
		if hoveredCard and hoveredCard.ZIndex < card.ZIndex and (not table.find(cardsSelected, hoveredCard)) then
			hoverCard(hoveredCard, false)
		end
		
		hoveredCard = card
		
		updateCardDescription(card)
		hoverCard(card, true)
	end)

	card.MouseLeave:Connect(function()
		if table.find(cardsSelected, card) or dragConnection then return end
		
		if hoveredCard == card then
			hoveredCard = nil
		end
		
		updateCardDescription(nil)
		hoverCard(card, false)
	end)

	icon.Activated:Connect(function()
		if hoveredCard == card then
			hoveredCard = nil
		end
		
		updateCardDescription(nil)
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
			dragConnection = nil
		end

		if n then
			moveCardToPosition(card, n)
		end

		task.delay(0.1, function()
			updateAllCardArcs()
		end)

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
				
				tweenService:Create(pc, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(card.AbsolutePosition.X, card.AbsolutePosition.Y), Rotation = rest.rotation}):Play()
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

function updateStealScaling()
	if (#gui.StealCardContainer:GetChildren() - 1) == 0 then return end
	
	local containerWidth = gui.StealCardContainer.AbsoluteSize.X
	local card = gui.StealCardContainer:FindFirstChildOfClass("Frame")::Frame
	local cardWidth = card.AbsoluteSize.X

	if (#gui.StealCardContainer:GetChildren() - 1) == 1 then
		gui.StealCardContainer.UIListLayout.Padding = UDim.new(0, 0)
		return
	end

	local totalCardWidth = cardWidth * (#gui.StealCardContainer:GetChildren() - 1)
	local availableGapSpace = containerWidth - totalCardWidth

	if availableGapSpace >= 0 then
		gui.StealCardContainer.UIListLayout.Padding = UDim.new(0, 0)
	else
		local paddingPerGap = availableGapSpace / ((#gui.StealCardContainer:GetChildren() - 1) - 1)

		--tweenService:Create(listLayout, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Padding = UDim.new(0, paddingPerGap)}):Play()
		gui.StealCardContainer.UIListLayout.Padding = UDim.new(0, paddingPerGap)
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
		newCard.Icon.ImageTransparency = 1
	end
	
	cards[#cards + 1] = newCard

	newCard.LayoutOrder = #cards * 10
	newCard.ZIndex = #cards * 10
	newCard.Visible = true
	newCard.Name = card
	newCard.UIAspectRatioConstraint.AspectRatio = 0.1
	newCard.Icon.InputSink = Enum.InputSink.All
	newCard.Icon.UIDragDetector.Enabled = decision ~= "Awaiting"
	newCard.Icon.Active = decision == "Awaiting"

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

function terminateDecision(bypassCameraReset:boolean?)
	if decision then
		if typeof(decision) == "string" then
			if cardInfo[decision] and cardInfo[decision]["SkipsTurn"] == false then
				return
			end
		elseif typeof(decision) == "table" then
			if cardInfo[decision[1]] and cardInfo[decision[1]]["SkipsTurn"] == false then
				return
			end
		end
	end
	
	decision = nil
	enableTaking(false)
	
	if workspace.Camera.CameraType == Enum.CameraType.Scriptable and not bypassCameraReset then
		task.delay(0.5, function()
			workspace.Camera.CameraType = Enum.CameraType.Custom
			originalCameraCFrame = nil
		end)
		
		tweenService:Create(workspace.Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = originalCameraCFrame}):Play()
	end

	if #cardsSelected == 1 and not cardInfo[cardsSelected[1].Name]["CanStack"] then
		deselectAllCards()
	end
end

function terminateAction()
	action = nil
	haltCountDown = false
	
	if decision == "Awaiting" then
		enableTaking(true)
		activateCards(true)

		local topMostCard  = workspace.Round.Cards.Deck:FindFirstChild(tostring(#workspace.Round.Cards.Deck:GetChildren()))::BasePart

		if topMostCard then
			tweenService:Create(workspace.Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(topMostCard.Position) * CFrame.new(0, 15, -15) * CFrame.Angles(0, math.rad(180), 0) * CFrame.Angles(math.rad(-60), 0, 0)}):Play()
		end
	else
		tweenService:Create(workspace.Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = originalCameraCFrame}):Play()
	end
	
	tweenService:Create(gui.StealCardContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, -0.25)}):Play()
	tweenService:Create(cardContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.75)}):Play()
end

function enableTaking(enabled:boolean)
	if enabled then
		if not cardActions.Take.Visible then
			cardActions.Take.Size = UDim2.fromScale(0.001, 1)
		end
		
		if cardActions.Use.Visible and cardActions.Steal.Visible then
			cardActions.Take.Position = UDim2.fromScale(0, 0.5)
		elseif (cardActions.Use.Visible and not cardActions.Steal.Visible) or (not cardActions.Use.Visible and cardActions.Steal.Visible) then
			cardActions.Take.Position = UDim2.fromScale(0.3, 0.5)
		elseif (not cardActions.Use.Visible) and (not cardActions.Steal.Visible) then
			cardActions.Take.Position = UDim2.fromScale(0.5, 0.5)
		end
		
		cardActions.Take.Visible = true
		
		tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.333, 1)}):Play()
	else
		if cardActions.Take.Visible then
			task.spawn(function()
				tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.001, 1)}):Play()

				task.wait(0.25)

				cardActions.Take.Visible = false
			end)
		end
	end
end

function decisionTake(turnCount:number) : string | {string}
	antiInactivityCountdown = 20
	decision = "Awaiting"
	
	enableTaking(true)

	local topMostCard  = workspace.Round.Cards.Deck:FindFirstChild(tostring(#workspace.Round.Cards.Deck:GetChildren()))::BasePart

	if topMostCard then
		workspace.Camera.CameraType = Enum.CameraType.Scriptable
		
		if not originalCameraCFrame then
			originalCameraCFrame = workspace.Camera.CFrame
		end

		tweenService:Create(workspace.Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(topMostCard.Position) * CFrame.new(0, 15, -15) * CFrame.Angles(0, math.rad(180), 0) * CFrame.Angles(math.rad(-60), 0, 0)}):Play()
	end

	activateCards(true)
	
	if countdownThread then
		coroutine.close(countdownThread)
	end

	countdownThread = task.spawn(function()
		while task.wait(1) do
			if antiInactivityCountdown == 0 then
				break
			elseif not haltCountDown then
				antiInactivityCountdown -= 1
			end
		end
	end)

	while task.wait() do
		if decision and decision ~= "Awaiting" then
			print(decision)

			task.defer(function()			
				terminateDecision((typeof(decision) == "table" and decision[1] and decision[1] == "Targeted Attack" and cardInfo[decision[1]]) or turnCount > 1)
			end)

			return decision
		end

		if antiInactivityCountdown == 0 then
			task.defer(function()
				terminateDecision((typeof(decision) == "table" and decision[1] and decision[1] == "Targeted Attack" and cardInfo[decision[1]]) or turnCount > 1)
			end)

			return "AFK"
		end
	end

	task.defer(function()
		terminateDecision((typeof(decision) == "table" and decision[1] and decision[1] == "Targeted Attack" and cardInfo[decision[1]]) or turnCount > 1)
	end)

	return "AFK"
end

function decisionSteal(cardCount:number) : number | string
	action = "Awaiting"
	actionInactivityCountdown = 20
	antiInactivityCountdown = 20
	haltCountDown = true
	
	tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, -0.5)}):Play()

	for i, button in ipairs(cardActions:GetChildren()) do
		if not button:IsA("TextButton") then continue end

		button.Interactable = false
	end
	
	for i, child in ipairs(gui.StealCardContainer:GetChildren()) do
		if not child:IsA("Frame") then continue end

		child:Destroy()
	end
	
	enableTaking(false)

	for count = 1, cardCount do
		local newCard = script.CardTemplate:Clone()

		newCard.Icon.Image = "rbxassetid://" .. cardInfo["CardBack"]["IconID"]
		newCard.LayoutOrder = count
		newCard.ZIndex = count
		newCard.Visible = true
		newCard.Icon.InputSink = Enum.InputSink.All
		newCard.Icon.UIDragDetector:Destroy()
		newCard.Name = tostring(count)

		newCard.Parent = gui.StealCardContainer

		newCard.Icon.Activated:Connect(function()
			if action == "Awaiting" then
				action = count
			end
		end)

		local t = cardCount > 1 and (count - (cardCount + 1) / 2) / ((cardCount - 1) / 2) or 0

		local rotation = t * 10
		local yOffset = (t * t) * 0.2

		newCard.Icon.Position = UDim2.fromScale(0.5, 0.5 - yOffset)
		newCard.Icon.Rotation = -rotation
	end

	updateStealScaling()

	tweenService:Create(gui.StealCardContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.33)}):Play()
	tweenService:Create(cardContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 1.25)}):Play()

	activateCards(false)
	
	if actionCountdownThread then
		coroutine.close(actionCountdownThread)
	end

	actionCountdownThread = task.spawn(function()
		while task.wait(1) do
			if actionInactivityCountdown == 0 then
				break
			else
				actionInactivityCountdown -= 1
			end
		end
	end)

	while task.wait() do
		if action and action ~= "Awaiting" then
			print(action)

			task.defer(function()
				tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.1)}):Play()

				for i, button in ipairs(cardActions:GetChildren()) do
					if not button:IsA("TextButton") then continue end

					button.Interactable = true
				end
				
				terminateAction()
			end)

			return action
		end

		if actionInactivityCountdown == 0 then
			task.defer(function()
				tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.1)}):Play()

				for i, button in ipairs(cardActions:GetChildren()) do
					if not button:IsA("TextButton") then continue end

					button.Interactable = true
				end
				
				terminateAction()
			end)

			return -1
		end
	end

	task.defer(function()
		tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.1)}):Play()
		
		for i, button in ipairs(cardActions:GetChildren()) do
			if not button:IsA("TextButton") then continue end

			button.Interactable = true
		end
		
		terminateAction()
	end)

	return -1
end

function decisionPickPlayer(hideEmptyDecks:boolean, resetCamera:boolean?) : string
	if not game.Players.LocalPlayer then return "Bot 1" end

	local target = nil
	local antiAFK = false

	local billboards:{BillboardGui} = {}

	workspace.Camera.CameraType = Enum.CameraType.Scriptable

	tweenService:Create(cardContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 1.5)}):Play()
	tweenService:Create(workspace.Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.lookAt(workspace.Origin.Position + Vector3.new(-10, 100 + (5 * #workspace.Round.Pillars:GetChildren()), 0), workspace.Origin.Position)}):Play()
	tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, -0.5)}):Play()
	
	for i, button in ipairs(cardActions:GetChildren()) do
		if not button:IsA("TextButton") then continue end

		button.Interactable = false
	end
	
	local cardCounts:{[string]:number} = replicatedStorage.Communicators.Remotes.Functions.ClientInfoRequester:InvokeServer("CardCounts")
	
	task.wait(0.45)
	
	for i, pillar in ipairs(workspace.Round.Pillars:GetChildren()) do
		if pillar:HasTag("Eliminated") or pillar.Name == tostring(game.Players.LocalPlayer) then continue end

		local billboard = replicatedStorage.Assets.Round.TargetGUI:Clone()
		local billboardFolder = game.Players.LocalPlayer.PlayerGui:FindFirstChild("Billboards")
		local player = game.Players:FindFirstChild(pillar.Name)::Player?

		table.insert(billboards, billboard)

		billboard.Parent = billboardFolder or game.Players.LocalPlayer.PlayerGui
		billboard.Size = UDim2.fromScale(0.001, 0.001)
		billboard.Adornee = pillar
		billboard.Name = pillar.Name
		billboard.Enabled = true
		
		tweenService:Create(billboard, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(40, 40)}):Play()
		
		if hideEmptyDecks and cardCounts and cardCounts[pillar.Name] == 0 then
			billboard.Enabled = false
		end
		
		billboard.TextButton.Holder.TextLabel.Text = pillar.Name
		billboard.TextButton.Holder.ImageLabel.TextLabel.Text = if cardCounts then tostring(cardCounts[pillar.Name]) else "?"
		billboard.TextButton.Icon.Image = if  player then "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420" else "rbxassetid://" .. tostring(universalInfo["Assets"]["BotIcon"])
		
		billboard.TextButton.MouseEnter:Connect(function()
			print("Entered: " .. billboard.Name)
		end)
		
		billboard.TextButton.Activated:Connect(function()
			target = pillar.Name
		end)
		
		task.wait(0.05)
	end

	task.delay(20, function()
		antiAFK = true
	end)

	while task.wait() do
		if target then
			tweenService:Create(cardContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.75)}):Play()
			tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.1)}):Play()
			
			for i, button in ipairs(cardActions:GetChildren()) do
				if not button:IsA("TextButton") then continue end

				button.Interactable = true
			end

			if resetCamera and originalCameraCFrame then
				task.delay(0.5, function()
					workspace.Camera.CameraType = Enum.CameraType.Custom
					originalCameraCFrame = nil
				end)

				tweenService:Create(workspace.Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = originalCameraCFrame}):Play()
			end

			for i, billboard in ipairs(billboards) do
				if billboard.Name == target then
					local button = billboard:FindFirstChildOfClass("TextButton")
					
					billboard.ClipsDescendants = false
					
					if button then
						button.Rotation = 30
						tweenService:Create(button, TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Rotation = 0}):Play()
					end
					
					tweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(60, 60)}):Play()
					
					task.delay(1.5, function()
						tweenService:Create(billboard, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.001, 0.001)}):Play()
						
						task.wait(0.25)
						
						billboard:Destroy()
					end)
				else
					tweenService:Create(billboard, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.001, 0.001)}):Play()
						
					task.delay(0.25, function()
						billboard:Destroy()	
					end)
				end
			end

			return target
		end

		if antiAFK then
			break
		end
	end

	tweenService:Create(cardContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.75)}):Play()
	tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.1)}):Play()
	
	for i, button in ipairs(cardActions:GetChildren()) do
		if not button:IsA("TextButton") then continue end

		button.Interactable = true
	end

	if resetCamera and originalCameraCFrame then
		task.delay(0.5, function()
			workspace.Camera.CameraType = Enum.CameraType.Custom
			originalCameraCFrame = nil
		end)

		tweenService:Create(workspace.Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = originalCameraCFrame}):Play()
	end

	for i, billboard in ipairs(billboards) do
		tweenService:Create(billboard, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.001, 0.001)}):Play()

		task.delay(0.25, function()
			billboard:Destroy()	
		end)
	end

	return " "
end

function decisionChooseDeckIndex() : number
	return 0
end

function decisionChooseCard() : string
	if not game.Players.LocalPlayer then return "Defuse" end

	local target = nil
	local antiAFK = false

	tweenService:Create(cardContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 1.5)}):Play()
	tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, -0.5)}):Play()
	
	for i, button in ipairs(cardActions:GetChildren()) do
		if not button:IsA("TextButton") then continue end
		
		button.Interactable = false
	end

	task.delay(20, function()
		antiAFK = true
	end)

	while task.wait() do
		if target then
			task.defer(function()
				tweenService:Create(cardContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.75)}):Play()
				tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.1)}):Play()
				
				for i, button in ipairs(cardActions:GetChildren()) do
					if not button:IsA("TextButton") then continue end

					button.Interactable = true
				end
			end)

			return target
		end

		if antiAFK then
			break
		end
	end

	task.defer(function()
		tweenService:Create(cardContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.75)}):Play()
		tweenService:Create(cardActions, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.1)}):Play()
		
		for i, button in ipairs(cardActions:GetChildren()) do
			if not button:IsA("TextButton") then continue end

			button.Interactable = true
		end
	end)

	return "Defuse"
end

function decisionChooseCardFromDeck() : string
	return "Test"
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
	gui.StealCardContainer.Visible = not gui.StealCardContainer.Visible
	cardDescription.Visible = not cardDescription.Visible
end)

-------------------------------------- Connections --------------------------------------

pcall(function()
	game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
end)

replicatedStorage.Communicators.Remotes.Functions.RequestPlayerDecision.OnClientInvoke = function(DecisionType:string, Data1:(number|boolean)?, Data2:boolean?) : string | {string} | number
	if DecisionType == "Take" then
		return decisionTake(Data1::number)
	elseif DecisionType == "Steal" and typeof(Data1) == "number" then
		return decisionSteal(Data1)
	elseif DecisionType == "PickPlayer" and typeof(Data1) == "boolean" then
		return decisionPickPlayer(Data1, Data2)
	elseif DecisionType == "ChooseDeckIndex" then
		return decisionChooseDeckIndex()
	elseif DecisionType == "ChooseCard" then
		return decisionChooseCard()
	elseif DecisionType == "ChooseCardFromDeck" then
		return decisionChooseCardFromDeck()
	else
		warn("Invalid Decision Type")
		
		return 0
	end
end

cardActions.Take.Activated:Connect(function()
	if debounce then return end

	debounce = true

	enableTaking(false)

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
		
		if #cardsSelected > 1 and cardInfo[cardsToUse[1].Name]["CanStack"] then
			for i, card:Frame in ipairs(cardsToUse) do
				table.insert(cardsToSend, card.Name)
			end
		else
			local indexToRemove = table.find(cards, cardsToUse[1])

			table.insert(cardsToSend, cardsToUse[1].Name)
			
			if indexToRemove then
				removeCard(indexToRemove)
			end
		end

		enableTaking(false)

		antiInactivityCountdown = 20

		print(cardsToSend)

		decision = cardsToSend

		if countdownThread then
			coroutine.close(countdownThread)
		end
		
		if #cardsSelected == 1 and not cardInfo[cardsToUse[1].Name]["CanStack"] then
			deselectAllCards()
		end
		
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

		replicatedStorage.Communicators.Remotes.Events.InitiateAction:FireServer({Type = if #cardsSelected == 3 then "Triple Steal" else "Steal", TargetIndex = decisionPickPlayer(true), Cards = cardNames, RequestedCard = if #cardsSelected == 3 then "Defuse" else nil})

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

cardActions.Take.MouseEnter:Connect(function()
	local highlight = workspace.Camera:FindFirstChildOfClass("Highlight")
	local topMostCard  = workspace.Round.Cards.Deck:FindFirstChild(tostring(#workspace.Round.Cards.Deck:GetChildren()))::BasePart

	tweenService:Create(cardActions.Take.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Thickness = 0.05}):Play()

	if not highlight then
		highlight = replicatedStorage.Highlight:Clone()::Highlight
		highlight.Parent = workspace.Camera
	end

	if topMostCard and highlight then
		highlight.OutlineTransparency = 1
		highlight.FillTransparency = 1

		highlight.Adornee = topMostCard

		tweenService:Create(highlight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {OutlineTransparency = 0, FillTransparency = 0.5}):Play()
	end
end)

cardActions.Take.MouseLeave:Connect(function()
	local highlight = workspace.Camera:FindFirstChildOfClass("Highlight")

	tweenService:Create(cardActions.Take.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Thickness = 0}):Play()

	if highlight then
		highlight.Adornee = nil
	end
end)

cardActions.Use.MouseEnter:Connect(function()
	tweenService:Create(cardActions.Use.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Thickness = 0.05}):Play()
end)

cardActions.Use.MouseLeave:Connect(function()
	tweenService:Create(cardActions.Use.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Thickness = 0}):Play()
end)

cardActions.Steal.MouseEnter:Connect(function()
	tweenService:Create(cardActions.Steal.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Thickness = 0.05}):Play()
end)

cardActions.Steal.MouseLeave:Connect(function()
	tweenService:Create(cardActions.Steal.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Thickness = 0}):Play()
end)

cardActions.Take:GetPropertyChangedSignal("Visible"):Connect(function()
	if cardActions.Take.Visible then
		if cardActions.Use.Visible and cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(1, 0.5)}):Play()
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		elseif cardActions.Use.Visible and not cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(1, 0.5)}):Play()
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.7, 0.5)}):Play()
		elseif not cardActions.Use.Visible and cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.7, 0.5)}):Play()
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		end
	else
		if cardActions.Use.Visible and cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.7, 0.5)}):Play()
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.3, 0.5)}):Play()
		elseif cardActions.Use.Visible and not cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(1, 0.5)}):Play()
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		elseif not cardActions.Use.Visible and cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		end
	end
end)

cardActions.Use:GetPropertyChangedSignal("Visible"):Connect(function()
	if cardActions.Use.Visible then
		if cardActions.Take.Visible and cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(1, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0, 0.5)}):Play()
		elseif cardActions.Take.Visible and not cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(1, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.3, 0.5)}):Play()
		elseif not cardActions.Take.Visible and cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.7, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0, 0.5)}):Play()
		end
	else
		if cardActions.Take.Visible and cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.7, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.3, 0.5)}):Play()
		elseif cardActions.Take.Visible and not cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(1, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		elseif not cardActions.Take.Visible and cardActions.Steal.Visible then
			tweenService:Create(cardActions.Steal, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0, 0.5)}):Play()
		end
	end
end)

cardActions.Steal:GetPropertyChangedSignal("Visible"):Connect(function()
	if cardActions.Steal.Visible then
		if cardActions.Take.Visible and cardActions.Use.Visible then
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0, 0.5)}):Play()
		elseif cardActions.Take.Visible and not cardActions.Use.Visible then
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.3, 0.5)}):Play()
		elseif not cardActions.Take.Visible and cardActions.Use.Visible then
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.3, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0, 0.5)}):Play()
		end
	else
		if cardActions.Take.Visible and cardActions.Use.Visible then
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.7, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.3, 0.5)}):Play()
		elseif cardActions.Take.Visible and not cardActions.Use.Visible then
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		elseif not cardActions.Take.Visible and cardActions.Use.Visible then
			tweenService:Create(cardActions.Use, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
			tweenService:Create(cardActions.Take, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0, 0.5)}):Play()
		end
	end
end)

replicatedStorage.Communicators.Remotes.Events.PlayerEliminated.OnClientEvent:Connect(function(pillarToDestroy:Model)
	local explosionModule = pillarToDestroy:FindFirstChildWhichIsA("ModuleScript", true)
	
	if explosionModule then
		require(explosionModule)()
	end
end)

replicatedStorage.Communicators.Remotes.Events.OrderClientAction.OnClientEvent:Connect(function(Action:string, Target:string|{string}?, index:number?)
	if Action == "RemoveFirst" then
		if not Target then return end
		
		if typeof(Target) == "table" then
			for i, card in Target do
				local indexToRemove = findFirstCard(card)
				if not indexToRemove then continue end
				
				removeCard(indexToRemove)
			end
			
			return
		end
		
		local indexToRemove = findFirstCard(Target)
		if not indexToRemove then return end
		
		removeCard(indexToRemove)
	elseif Action == "RemoveCard" then
		if not index then return end
		
		removeCard(index)
		updateScaling()
	elseif Action == "AddCard" then
		if not Target then return end
		
		addCard(Target)
	elseif Action == "RemoveSelected" then
		if not index then return end
		
		local cardsToUse = table.clone(cardsSelected)
		
		print(index, cardsToUse, cardsSelected)
		
		if index > 0 then
			for i, card:Frame in ipairs(cardsToUse) do
				local indexToRemove = table.find(cards, card)
				if not indexToRemove then continue end

				removeCard(indexToRemove)
				
				if i == index then break end
			end
		end
		
		deselectAllCards()
	end
end)

replicatedStorage.Communicators.Remotes.Events.GiveDeck.OnClientEvent:Connect(function(deck) 
	generateDeckFromTable(deck, true)
end)