local TweenService = game:GetService("TweenService")

local frame = script.Parent.Timer

Sec = 0
TSec = 0
Min = 0
TMin = 0
Hr = 0
THr = 0
HHr = 0

local tween = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local flashColor = Color3.fromRGB(255, 85, 0)
local activeColor = Color3.fromRGB(255, 255, 255)

while task.wait(1) do
	Sec += 1

	frame.OneSec.TextColor3 = flashColor

	TweenService:Create(frame.OneSec, tween, {TextColor3 = activeColor}):Play()

	if Sec == 10 then
		Sec = 0
		TSec += 1

		frame.TenSecs.TextColor3 = flashColor

		TweenService:Create(frame.TenSecs, tween, {TextColor3 = activeColor}):Play()

		if TSec == 6 then
			TSec = 0
			Min += 1

			frame.OneMin.TextColor3 = flashColor

			TweenService:Create(frame.OneMin, tween, {TextColor3 = activeColor}):Play()

			if frame.ColonMinSec.TextColor3 ~= activeColor then
				frame.ColonMinSec.TextColor3 = flashColor

				TweenService:Create(frame.ColonMinSec, tween, {TextColor3 = activeColor}):Play()
			end

			if Min == 10 then
				Min = 0
				TMin += 1

				frame.TenMins.TextColor3 = flashColor

				TweenService:Create(frame.TenMins, tween, {TextColor3 = activeColor}):Play()

				if TMin == 6 then
					TMin = 0
					Hr += 1

					frame.OneHr.TextColor3 = flashColor

					TweenService:Create(frame.OneHr, tween, {TextColor3 = activeColor}):Play()

					if frame.ColonHrMin.TextColor3 ~= activeColor then
						frame.ColonHrMin.TextColor3 = flashColor

						TweenService:Create(frame.ColonHrMin, tween, {TextColor3 = activeColor}):Play()
					end

					if Hr == 10 then
						Hr = 0
						THr += 1

						frame.TenHrs.TextColor3 = flashColor

						TweenService:Create(frame.TenHrs, tween, {TextColor3 = activeColor}):Play()

						if THr == 10 then
							THr = 0
							HHr += 1

							frame.HundredHrs.TextColor3 = flashColor

							TweenService:Create(frame.HundredHrs, tween, {TextColor3 = activeColor}):Play()
						end
					end
				end
			end
		end
	end

	frame.OneSec.Text = Sec
	frame.TenSecs.Text = TSec

	frame.OneMin.Text = Min
	frame.TenMins.Text = TMin

	frame.OneHr.Text = Hr
	frame.TenHrs.Text = THr
	frame.HundredHrs.Text = HHr
end