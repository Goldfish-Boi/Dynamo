--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local cardInfo:{[string]:any} = require(replicatedStorage.Modules.CardInfo)::{[string]:any}

local roundFolder = workspace.Round
local cardsFolder = roundFolder.Cards

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

function transitionCard(card:string, tweenInfo:TweenInfo, from:Vector3, to:Vector3, parabolic:boolean?)
	if not cardInfo[card] then return end

	local cardBillboard = replicatedStorage.Assets.Round.CardBillboard:Clone()
	cardBillboard.Position = from
	cardBillboard.BillboardGui.ImageLabel.Image = "rbxassetid://" .. cardInfo[card]["IconID"]
	cardBillboard.BillboardGui.ImageLabel.Position = UDim2.fromScale(0.5, 1)
	cardBillboard.Attachment0.Trail.Color = ColorSequence.new(cardInfo[card]["Colour"]::Color3)
	cardBillboard.Parent = workspace

	task.spawn(function()
		tweenService:Create(cardBillboard.BillboardGui.ImageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()

		task.wait(0.5)

		if not parabolic then
			tweenService:Create(cardBillboard, tweenInfo, {Position = to}):Play()
			tweenService:Create(cardBillboard.BillboardGui.ImageLabel, tweenInfo, {Size = UDim2.fromScale(0, 0)}):Play()
		else
			tweenService:Create(cardBillboard.BillboardGui.ImageLabel, tweenInfo, {Size = UDim2.fromScale(0, 0)}):Play()
			bezier(cardBillboard, tweenInfo, from, Vector3.new(from.X + ((2 / 3) * (to.X - from.X)), (from.Y + ((1 / 3) * (to.Y - from.Y))) + 10, from.Z + ((2 / 3) * (to.Z - from.Z))), to)
		end

		task.wait(1)

		local particleAttachment = replicatedStorage.Assets.Round.ParticleAttachment:Clone()
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

function setUsedCardsModel(cards:{string}?, updateType:string?, delayNumber:number?, initialDelayNumber:number?)
	if updateType == "RemoveAll" then
		cardsFolder.UsedCards:ClearAllChildren()

		return
	end

	if (not cards) or #cards == 0 then return end
	
	if initialDelayNumber then task.wait(initialDelayNumber) end
	
	for i, card in ipairs(cards) do
		local cardPart = workspace.UsedCards:Clone()
		cardPart.Name = card
		cardPart.Position = workspace.UsedCards.Position + Vector3.new(0, workspace.UsedCards.Position.Y + (0.5 * #cardsFolder.UsedCards:GetChildren()), 0)
		cardPart.Color = cardInfo[card]["Colour"]
		cardPart.Orientation = Vector3.new(0, math.random(-100, 100) / 10, 90)
		cardPart.Transparency = 0
		cardPart.Size = Vector3.new(0.5, 1.4, 1)
		cardPart.Parent = cardsFolder.UsedCards

		if cardInfo[card]["IconID"] then
			cardPart.Decal.ColorMap = "rbxassetid://" .. cardInfo[card]["IconID"]
		end

		tweenService:Create(cardPart, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(0.5, 14, 10)}):Play()

		if delayNumber then task.wait(delayNumber) end
	end
end

type transitionCardInfo = {
	Type:"TransitionCard",
	Card:string|{string},
	TweenInfo:TweenInfo,
	From:Vector3,
	To:Vector3|string,
	Parabolic:boolean?,
	Delay:number?,
}
type setUsedCardsInfo = {
	Type:"SetUsedCards",
	Cards:{string},
	UpdateType:string?,
	DelayNumber:number?,
	InitialDelayNumber:number?,
}

type effectInfo = transitionCardInfo | setUsedCardsInfo

function getLocation(to:Vector3|string) : Vector3
	local newTo:Vector3
	
	if typeof(to) == "Vector3" then
		newTo = to
	else
		if to == "UsedCards" then
			newTo = workspace.UsedCards.Position + Vector3.new(0, 0.25 + (0.5 * (#workspace.UsedCards:GetChildren())), 0)
		else
			newTo = workspace.Origin.Position
		end
	end
	
	return newTo
end

replicatedStorage.Communicators.Remotes.Events.CreateClientEffect.OnClientEvent:Connect(function(effect:{effectInfo})
	for i, effectToDo in ipairs(effect) do
		task.spawn(function()
			if effectToDo.Type == "TransitionCard" then
				if typeof(effectToDo.Card) == "table" then
					for i, cardToTransition in ipairs(effectToDo.Card) do
						transitionCard(cardToTransition, effectToDo.TweenInfo, effectToDo.From, getLocation(effectToDo.To), effectToDo.Parabolic)

						task.wait(effectToDo.Delay or 0.1)
					end
				else
					transitionCard(effectToDo.Card, effectToDo.TweenInfo, effectToDo.From, getLocation(effectToDo.To), effectToDo.Parabolic)
				end
			elseif effectToDo.Type == "SetUsedCards" then
				setUsedCardsModel(effectToDo.Cards, effectToDo.UpdateType, effectToDo.DelayNumber, effectToDo.InitialDelayNumber)
			end
		end)
	end
end)