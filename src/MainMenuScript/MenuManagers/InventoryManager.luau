--!strict
--!optimize 2

local module = {}

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local gui = script.Parent.Parent.Parent
local holder = gui.Holder
local buttons = holder.Buttons
local mainFrame = holder.MainFrame
local uiTemplates = script.Parent.Parent.UITemplates

local inventoryTemplates = uiTemplates.InventoryTemplates

local active:boolean = false
local currentTab:string = "Pillars"

local playerData:any?
local auxillary:Frame?
local tabs:Frame?

---------------------------------- Helper Functions ----------------------------------

function addFunctionality()
	if not tabs then return end
	
	for i, child in ipairs(tabs:GetChildren()) do
		if not child:IsA("TextButton") then continue end
		
		child.MouseEnter:Connect(function()
			if currentTab == child.Name then return end
			
			local uiCorner = child:FindFirstChildOfClass("UICorner")
			if not uiCorner then return end
			
			tweenService:Create(uiCorner, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BottomLeftRadius = UDim.new(0, 0), BottomRightRadius = UDim.new(0, 0), TopLeftRadius = UDim.new(0, 0), TopRightRadius = UDim.new(0, 0)}):Play()
		end)
		
		child.MouseLeave:Connect(function()
			if currentTab == child.Name then return end
			
			local uiCorner = child:FindFirstChildOfClass("UICorner")
			if not uiCorner then return end

			tweenService:Create(uiCorner, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BottomLeftRadius = UDim.new(0, 0), BottomRightRadius = UDim.new(0, 0), TopLeftRadius = UDim.new(0.5, 0), TopRightRadius = UDim.new(0.5, 0)}):Play()
		end)
		
		child.Activated:Connect(function()
			if currentTab == child.Name then return end
			
			openTab(child.Name)
		end)
	end
end

---------------------------------- Primary Functions ----------------------------------

function openTab(tab:string)
	if not tabs then return end
	
	local tabButton:TextLabel = tabs:FindFirstChild(currentTab)::TextLabel
	
	if tabButton then
		local uiCorner = tabButton:FindFirstChildOfClass("UICorner")
		if not uiCorner then return end
		
		tabButton.FontFace.Bold = false
		
		tweenService:Create(tabButton, TweenInfo.new(0.125, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 0.75, TextColor3 = Color3.new(0, 0, 0)}):Play()
		tweenService:Create(uiCorner, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BottomLeftRadius = UDim.new(0, 0), BottomRightRadius = UDim.new(0, 0), TopLeftRadius = UDim.new(0.5, 0), TopRightRadius = UDim.new(0.5, 0)}):Play()
	end
	
	currentTab = tab
	
	tabButton = tabs:FindFirstChild(currentTab)::TextLabel
	
	if tabButton then
		local uiCorner = tabButton:FindFirstChildOfClass("UICorner")
		if not uiCorner then return end

		tabButton.FontFace.Bold = true
		
		tweenService:Create(tabButton, TweenInfo.new(0.125, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(0.75, 1), BackgroundTransparency = 0.5, TextColor3 = Color3.new(1, 1, 1)}):Play()
		tweenService:Create(uiCorner, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BottomLeftRadius = UDim.new(0, 0), BottomRightRadius = UDim.new(0, 0), TopLeftRadius = UDim.new(0, 0), TopRightRadius = UDim.new(0, 0)}):Play()
	end
end

function module.Open()
	active = true
	
	mainFrame.Size = UDim2.fromScale(0.125, 0.025)
	mainFrame.Position = UDim2.fromScale(0.437, 0.525)	
	tweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.5, 0.75), Position = UDim2.fromScale(0.37, 0.513)}):Play()
	tweenService:Create(mainFrame.UICorner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BottomLeftRadius = UDim.new(0.075, 0), BottomRightRadius = UDim.new(0, 0), TopLeftRadius = UDim.new(0, 0), TopRightRadius = UDim.new(0, 0)}):Play()
	
	auxillary = inventoryTemplates.AuxillaryFrame:Clone()
	auxillary.Size = UDim2.fromScale(0.125, 0.025)
	auxillary.Position = UDim2.fromScale(0.563, 0.525)
	auxillary.Parent = holder
	tweenService:Create(auxillary, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.25, 0.75), Position = UDim2.fromScale(0.755, 0.513)}):Play()
	tweenService:Create(auxillary.UICorner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BottomLeftRadius = UDim.new(0, 0), BottomRightRadius = UDim.new(0.1, 0), TopLeftRadius = UDim.new(0, 0), TopRightRadius = UDim.new(0.1, 0)}):Play()
	
	tabs = inventoryTemplates.Tabs:Clone()
	
	tabs.Parent = holder
	tabs.Position = UDim2.fromScale(0.437, 0.538)
	tabs.Size = UDim2.fromScale(0.125, 0.001)
	tweenService:Create(tabs, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.37, 0.113), Size = UDim2.fromScale(0.5, 0.05)}):Play()
	
	tweenService:Create(buttons.InventoryButton, TweenInfo.new(0.225, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.15, 0.15), Position = UDim2.fromScale(0.05, 0.26)}):Play()
	
	addFunctionality()
	openTab("Pillars")
end

function module.Close()
	active = false
	
	if auxillary then
		tweenService:Create(auxillary, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.001, 0.025), Position = UDim2.fromScale(0.625, 0.513)}):Play()
		auxillary:Destroy()
	end
	
	if tabs then
		tabs:Destroy()
	end
end

---------------------------------- Connections ----------------------------------

return module