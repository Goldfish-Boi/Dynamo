--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local guiService = game:GetService("GuiService")

local gui = script.Parent
local holder = gui.Holder
local buttons = holder.Buttons
local mainFrame = holder.MainFrame
local uiTemplates = script.UITemplates

local openCloseButton = gui.OpenCloseButton

local open = false
local debounce = false
local currentMenu = "Main"

local playerData = nil
local background:ScreenGui? = nil

local originalValues = {}
local managers = {}

local topBarPlus = require(replicatedStorage.Modules.Icon)
managers["MenuDataManager"] = require(script.MenuManagers.MenuDataManager)
managers["CreditsManager"] = require(script.MenuManagers.CreditsManager)
managers["InventoryManager"] = require(script.MenuManagers.InventoryManager)
managers["SettingsManager"] = require(script.MenuManagers.SettingsManager)
managers["ShopManager"] = require(script.MenuManagers.ShopManager)

--------------------------------------- Helper Functions ---------------------------------------

playerData = replicatedStorage.Communicators.Remotes.Functions.RequestData:InvokeServer("All")

print(playerData)

--------------------------------------- Main Functions ---------------------------------------

function returnToMain()
	if currentMenu ~= "Main" then
		managers[currentMenu .. "Manager"].Close()
	end
	
	currentMenu = "Main"
	
	tweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.25, 0.025), Position = UDim2.fromScale(0.5, 0.525)}):Play()
	tweenService:Create(mainFrame.UICorner, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CornerRadius = UDim.new(0.25, 0)}):Play()
	
	task.wait(0.1)
	
	for i, button in ipairs(buttons:GetChildren()) do
		if not button:IsA("TextButton") then continue end
		
		local textLabel:TextLabel = button:FindFirstChildOfClass("TextLabel")::TextLabel
		local imageLabel:ImageLabel = button:FindFirstChildOfClass("ImageLabel")::ImageLabel
		
		tweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = originalValues[button]["Size"], Position = originalValues[button]["Position"], BackgroundTransparency = 0.5}):Play()
		tweenService:Create(textLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
		tweenService:Create(imageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
	end
end

function openMenu(menuName:string)
	if menuName == currentMenu then
		returnToMain() return
	end
	
	currentMenu = menuName
	
	for i, button in ipairs(buttons:GetChildren()) do
		if (not button:IsA("TextButton")) or button.Name == menuName .. "Button" then continue end
		
		local textLabel:TextLabel = button:FindFirstChildOfClass("TextLabel")::TextLabel
		local imageLabel:ImageLabel = button:FindFirstChildOfClass("ImageLabel")::ImageLabel
		
		tweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 1}):Play()
		tweenService:Create(textLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 1}):Play()
		tweenService:Create(imageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
	end
	
	managers[menuName .. "Manager"].Open()
end

function setMenuState(enabled:boolean)
	if enabled == true then
		openCloseButton.TextLabel.Text = "Exit Menu"

		background = uiTemplates.MenuEffects:Clone()

		background.Enabled = true
		background.Parent = script.Parent.Parent

		local insets = guiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
		local insets2 = guiService:GetInsetArea(Enum.ScreenInsets.None)

		background.MenuPulse.Position = UDim2.fromOffset((openCloseButton.AbsolutePosition.X - insets2.Min.X) + (openCloseButton.AbsoluteSize.X / 2), (openCloseButton.AbsolutePosition.Y - insets2.Min.Y) + (openCloseButton.AbsoluteSize.Y / 2))
		background.MenuPulse.Size = UDim2.fromOffset(openCloseButton.AbsoluteSize.X, openCloseButton.AbsoluteSize.X)

		local scale = math.max(2.5 * (workspace.Camera.ViewportSize.X / workspace.Camera.ViewportSize.Y), 2.5 * (workspace.Camera.ViewportSize.Y / workspace.Camera.ViewportSize.X))

		tweenService:Create(background.MenuPulse, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Size = UDim2.fromScale(scale, scale)}):Play()

		task.wait(0.5)

		background.MenuPulse.Size = UDim2.fromScale(10 * scale, 10 * scale)
		holder.Visible = true

		tweenService:Create(background.Frame.WaveTexture, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
		tweenService:Create(background.Benzene, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.95}):Play()
		tweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.5}):Play()
		for i, button in ipairs(buttons:GetChildren()) do
			if not button:IsA("TextButton") then continue end

			local textLabel:TextLabel = button:FindFirstChildOfClass("TextLabel")::TextLabel
			local imageLabel:ImageLabel = button:FindFirstChildOfClass("ImageLabel")::ImageLabel

			tweenService:Create(button, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.5}):Play()
			tweenService:Create(textLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
			tweenService:Create(imageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
		end

		tweenService:Create(background.Frame.WaveTexture, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Position = UDim2.fromScale(-1, 2)}):Play()
		tweenService:Create(background.Benzene, TweenInfo.new(20, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = background.Benzene.Rotation + 360}):Play()

		background.CoverGradient.Visible = true

		task.spawn(function()
			if not background then return end

			local frame = background:FindFirstChild("Frame")::Frame
			local waveTexture:ImageLabel = frame:FindFirstChild("WaveTexture")::ImageLabel

			while true do
				task.wait(10)

				if waveTexture then
					waveTexture.Position = UDim2.fromScale(0, 1)
				end
			end
		end)
	elseif enabled == false then
		openCloseButton.TextLabel.Text = "Open Menu"

		if not background then return end

		if currentMenu ~= "Main" then
			returnToMain()
			task.wait(0.35)
		end

		local menuPulse:Frame = background:FindFirstChild("MenuPulse")::Frame
		local frame = background:FindFirstChild("Frame")::Frame
		local waveTexture:ImageLabel = frame:FindFirstChild("WaveTexture")::ImageLabel
		local benzene:ImageLabel = background:FindFirstChild("Benzene")::ImageLabel
		local coverGradient:ImageLabel = background:FindFirstChild("CoverGradient")::ImageLabel

		local scale = math.max(2.5 * (workspace.Camera.ViewportSize.X / workspace.Camera.ViewportSize.Y), 2.5 * (workspace.Camera.ViewportSize.Y / workspace.Camera.ViewportSize.X))

		menuPulse.Size = UDim2.fromScale(scale, scale)

		tweenService:Create(waveTexture, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
		tweenService:Create(benzene, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
		tweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 1}):Play()
		for i, button in ipairs(buttons:GetChildren()) do
			if not button:IsA("TextButton") then continue end

			local textLabel:TextLabel = button:FindFirstChildOfClass("TextLabel")::TextLabel
			local imageLabel:ImageLabel = button:FindFirstChildOfClass("ImageLabel")::ImageLabel

			tweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 1}):Play()
			tweenService:Create(textLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 1}):Play()
			tweenService:Create(imageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
		end

		task.wait(0.25)

		coverGradient.Visible = false
		tweenService:Create(menuPulse, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 0)}):Play()

		task.wait(0.5)

		holder.Visible = false

		background:Destroy()
		background = nil
	end
end

openCloseButton.Activated:Connect(function()
	if debounce == true then return end
	
	debounce = true
	
	task.spawn(function()
		task.wait(1)
		
		debounce = false
	end)
	
	openCloseButton.Rotation = -60
	openCloseButton.ImageLabel.Rotation = -75
	
	tweenService:Create(openCloseButton, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.1, 0.1), Rotation = 0}):Play()
	tweenService:Create(openCloseButton.ImageLabel, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
	
	if not open then
		setMenuState(true)
	else
		setMenuState(false)
	end
	
	open = not open
end)

function init()
	holder.Visible = false

	for i, button in ipairs(buttons:GetChildren()) do
		if not button:IsA("TextButton") then continue end

		local textLabel:TextLabel = button:FindFirstChildOfClass("TextLabel")::TextLabel
		local imageLabel:ImageLabel = button:FindFirstChildOfClass("ImageLabel")::ImageLabel

		button.BackgroundTransparency = 1
		textLabel.TextTransparency = 1
		imageLabel.ImageTransparency = 1

		local originalSize = button.Size
		originalValues[button] = {Size = originalSize, Position = button.Position}

		button.MouseEnter:Connect(function()
			if debounce == true then return end
			
			tweenService:Create(imageLabel, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = math.random(-15, 15)}):Play()
			
			if currentMenu == "Main" then
				tweenService:Create(button, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(originalSize.X.Scale * 1.1, originalSize.Y.Scale * 1.1), Rotation = math.random(-5, 5)}):Play()
			else
				tweenService:Create(button, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.15 * 1.1, 0.15 * 1.1), Rotation = math.random(-5, 5)}):Play()
			end
		end)

		button.MouseLeave:Connect(function()
			if debounce == true then return end
			
			tweenService:Create(imageLabel, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
			
			if currentMenu == "Main" then
				tweenService:Create(button, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = originalSize, Rotation = 0}):Play()
			else
				tweenService:Create(button, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.15, 0.15), Rotation = 0}):Play()
			end
		end)
		
		button.Activated:Connect(function()
			if debounce == true then return end
			
			debounce = true

			task.spawn(function()
				task.wait(0.5)

				debounce = false
			end)

			button.Rotation = -60
			imageLabel.Rotation = -75

			tweenService:Create(button, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
			tweenService:Create(imageLabel, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
			
			openMenu(button.Name:gsub("Button", ""))
		end)
	end

	openCloseButton.MouseEnter:Connect(function()
		if debounce == true then return end

		tweenService:Create(openCloseButton, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.15, 0.15), Rotation = math.random(-5, 5)}):Play()
		tweenService:Create(openCloseButton.ImageLabel, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = math.random(-15, 15)}):Play()
	end)

	openCloseButton.MouseLeave:Connect(function()
		if debounce == true then return end

		tweenService:Create(openCloseButton, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromScale(0.1, 0.1), Rotation = 0}):Play()
		tweenService:Create(openCloseButton.ImageLabel, TweenInfo.new(0.125, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
	end)
end

--------------------------------------- Connections ---------------------------------------

local nitroIcon = topBarPlus.new()
	:setName("Nitro")
	--:setLabel("0")
	:setImage(92231235191960)
	:align("Left")
	--:setCaption("You have 0 Nitro")
	--:setWidth(88)
	
if playerData then
	if playerData["Inventory"]["Nitro"] then
		nitroIcon:setLabel(tostring(playerData["Inventory"]["Nitro"])):setCaption("You have " .. tostring(playerData["Inventory"]["Nitro"]) .. " Nitro")
	end
end

replicatedStorage.Communicators.Remotes.Events.PlayerDataUpdated.OnClientEvent:Connect(function(data)
	playerData = data
	
	if playerData["Inventory"]["Nitro"] then
		nitroIcon:setLabel(tostring(playerData["Inventory"]["Nitro"])):setCaption("You have " .. tostring(playerData["Inventory"]["Nitro"]) .. " Nitro")
	end
end)

replicatedStorage.Communicators.Remotes.Events.TransitionWithRound.OnClientEvent:Connect(function()
	debounce = true
	
	setMenuState(false)
	
	task.delay(3, function()
		debounce = false
	end)
	
	local n = if openCloseButton.Visible == true then 0 else 0.1
	
	tweenService:Create(openCloseButton, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromScale(n, n)}):Play()
	
	task.wait(if openCloseButton.Visible == true then 0.5 else 0)
	
	openCloseButton.Visible = not openCloseButton.Visible
end)

init()