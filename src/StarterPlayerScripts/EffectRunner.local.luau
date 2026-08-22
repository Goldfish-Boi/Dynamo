--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local cardInfo:{[string]:any} = require(replicatedStorage.Modules.CardInfo)::{[string]:any}

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

type transitionCardInfo = {
	Type:"TransitionCard",
	Card:string|{string},
	TweenInfo:TweenInfo,
	From:Vector3,
	To:Vector3|string,
	Parabolic:boolean?,
	Delay:number?,
}

type effectInfo = transitionCardInfo

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

replicatedStorage.Communicators.Remotes.Events.CreateClientEffect.OnClientEvent:Connect(function(effect:effectInfo)
	if effect.Type == "TransitionCard" then
		
		if typeof(effect.Card) == "table" then
			for i, cardToTransition in ipairs(effect.Card) do
				transitionCard(cardToTransition, effect.TweenInfo, effect.From, getLocation(effect.To), effect.Parabolic)
				
				task.wait(effect.Delay or 0.1)
			end
		else
			transitionCard(effect.Card, effect.TweenInfo, effect.From, getLocation(effect.To), effect.Parabolic)
		end
	end
end)