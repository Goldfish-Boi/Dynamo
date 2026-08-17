--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local contentProvider = game:GetService("ContentProvider")

local loadingScreenTips:{string} = require(script.LoadingScreenTips)

local loadingScreen = script.LoadingScreen

local debounceBuffer = 0

if game.Players.LocalPlayer then
	script.LoadingScreen.Parent = game.Players.LocalPlayer.PlayerGui
end

local sillyTexts = task.spawn(function()
	while true do
		loadingScreen.Frame.SillyText.Text = loadingScreenTips[math.random(1, #loadingScreenTips)]
		
		task.wait(3)
	end
end)

local spin = task.spawn(function()
	while true do
		tweenService:Create(loadingScreen.Frame.Spin, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Rotation = loadingScreen.Frame.Spin.Rotation + 60}):Play()
		
		task.wait(1)
	end
end)

local serviceCount = #game:GetChildren()

for i, service in ipairs(game:GetChildren()) do
	local descrendantCount = #service:GetDescendants()
	
	--loadingScreen.Frame.InfoText.Text = "Loading: " .. service.Name .. " [" .. 0 .. "/" .. tostring(descrendantCount) .. "]"
	
	for i, descendant in ipairs(service:GetDescendants()) do
		--loadingScreen.Frame.InfoText.Text = "Loading: " .. service.Name .. "/" .. descendant.Name .. " [" .. i .. "/" .. tostring(descrendantCount) .. "]"
		loadingScreen.Frame.InfoText.Text = "Loading: " .. service.Name .. "/" .. descendant.Name
		
		contentProvider:PreloadAsync({descendant})
		
		debounceBuffer += 1
		
		--print(service, descendant)
		
		if debounceBuffer == 1000 then
			debounceBuffer = 0
			
			task.wait()
		end
	end
	
	tweenService:Create(loadingScreen.Frame.Spin.UIGradient, TweenInfo.new(0.125, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Offset = Vector2.new(0, 0.5 - (i / serviceCount))}):Play()
	
	task.wait()
end

task.wait(0.25)

tweenService:Create(loadingScreen.Frame.SillyText, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 1}):Play()
tweenService:Create(loadingScreen.Frame.InfoText, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 1}):Play()
tweenService:Create(loadingScreen.Frame.Spin, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()

task.wait(0.5)

task.spawn(function()
	require(script.SplashScreen)()
end)

tweenService:Create(loadingScreen.Frame.Background.Upper, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Position = UDim2.fromScale(0, -0.5)}):Play()
tweenService:Create(loadingScreen.Frame.Background.Lower, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Position = UDim2.fromScale(0, 1)}):Play()
tweenService:Create(loadingScreen.Frame.Background.Flash, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()

task.wait(1)

task.cancel(spin)
task.cancel(sillyTexts)

loadingScreen:Destroy()