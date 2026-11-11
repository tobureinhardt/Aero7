--!nonstrict
-- Aero7: components/DatePicker - Windows 7 DatePicker and MonthCalendar control (SysDateTimePick32 & SysMonthCal32).

local Theme = require("core/Theme")
local Utility = require("core/Utility")

local DatePicker = {}

local MONTH_NAMES = {
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
}

local WEEK_DAYS = { "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" }

local function isLeapYear(y)
	return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
end

local function getDaysInMonth(year, month)
	local days = { 31, isLeapYear(year) and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
	return days[month] or 30
end

-- Zeller / Sakamoto congruence: 0 = Sunday .. 6 = Saturday
local function getDayOfWeek(y, m, d)
	local t = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 }
	if m < 3 then
		y = y - 1
	end
	return (y + math.floor(y / 4) - math.floor(y / 100) + math.floor(y / 400) + t[m] + d) % 7
end

local function formatDate(y, m, d)
	return string.format("%04d-%02d-%02d", y, m, d)
end

function DatePicker.new(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Date"
	local year = tonumber(options.Year) or 2026
	local month = math.clamp(tonumber(options.Month) or 11, 1, 12)
	local day = math.clamp(tonumber(options.Day) or 5, 1, getDaysInMonth(year, month))
	local todayYear, todayMonth, todayDay = year, month, day
	local viewYear, viewMonth = year, month
	local callback = options.Callback or function() end
	local inlineCalendar = (options.Inline == true)

	local wrapper = Utility.Create("Frame", {
		Name = "DatePicker_" .. title,
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})

	local topRow = Utility.Create("Frame", {
		Name = "PickerRow",
		Parent = wrapper,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		ZIndex = wrapper.ZIndex + 1,
	})

	Utility.Create("TextLabel", {
		Name = "PickerLabel",
		Parent = topRow,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0.45, -6, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = topRow.ZIndex + 1,
	})

	local boxBtn = Utility.Create("TextButton", {
		Name = "DateTimeComboButton",
		Parent = topRow,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0.45, 0, 0, 1),
		Size = UDim2.new(0.55, 0, 0, 22),
		Text = "",
		ZIndex = topRow.ZIndex + 1,
	})
	Utility.AddCorner(boxBtn, 2)
	local boxStroke = Utility.AddStroke(boxBtn, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

	local dateTextLbl = Utility.Create("TextLabel", {
		Name = "DateValueLabel",
		Parent = boxBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 7, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = formatDate(year, month, day),
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = boxBtn.ZIndex + 1,
	})

	local dropChip = Utility.Create("Frame", {
		Name = "DropArrowChip",
		Parent = boxBtn,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(1, -19, 0, 1),
		Size = UDim2.new(0, 18, 1, -2),
		ZIndex = boxBtn.ZIndex + 1,
	})
	local chipGrad = Instance.new("UIGradient")
	chipGrad.Rotation = 90
	chipGrad.Color = Theme.Gradients.ButtonNormal
	chipGrad.Parent = dropChip

	Utility.CreateVectorChevron(dropChip, "Down", Color3.fromRGB(48, 64, 84), dropChip.ZIndex + 1)

	-- SysMonthCal32 calendar frame
	local calFrame = Utility.Create("Frame", {
		Name = "SysMonthCal32",
		Parent = wrapper,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0, 28),
		Size = UDim2.new(1, 0, 0, 186),
		Visible = inlineCalendar,
		ZIndex = wrapper.ZIndex + 5,
	})
	Utility.AddCorner(calFrame, 3)
	Utility.AddStroke(calFrame, Theme.Colors.SelectionBorder, 1, 0, Enum.ApplyStrokeMode.Border)

	-- Month / Year navigation header
	local calHeader = Utility.Create("Frame", {
		Name = "CalendarHeader",
		Parent = calFrame,
		BackgroundColor3 = Color3.fromRGB(242, 247, 253),
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 0, 26),
		ZIndex = calFrame.ZIndex + 1,
	})

	local prevBtn = Utility.Create("TextButton", {
		Name = "PrevMonthBtn",
		Parent = calHeader,
		Position = UDim2.new(0, 4, 0, 3),
		Size = UDim2.new(0, 22, 0, 20),
		Text = "",
		ZIndex = calHeader.ZIndex + 1,
	})
	Utility.BindWin7ButtonStates(prevBtn, { CornerRadius = 2 })
	Utility.CreateVectorChevron(prevBtn, "Left", Theme.Colors.TextPrimary, prevBtn.ZIndex + 2)

	local nextBtn = Utility.Create("TextButton", {
		Name = "NextMonthBtn",
		Parent = calHeader,
		Position = UDim2.new(1, -26, 0, 3),
		Size = UDim2.new(0, 22, 0, 20),
		Text = "",
		ZIndex = calHeader.ZIndex + 1,
	})
	Utility.BindWin7ButtonStates(nextBtn, { CornerRadius = 2 })
	Utility.CreateVectorChevron(nextBtn, "Right", Theme.Colors.TextPrimary, nextBtn.ZIndex + 2)

	local monthTitleLbl = Utility.Create("TextLabel", {
		Name = "MonthYearTitle",
		Parent = calHeader,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 30, 0, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Font = Theme.Fonts.Semibold,
		Text = MONTH_NAMES[viewMonth] .. " " .. tostring(viewYear),
		TextColor3 = Theme.Colors.TextGroupTitle,
		TextSize = 13,
		ZIndex = calHeader.ZIndex + 1,
	})

	-- Weekday header row (Su Mo Tu We Th Fr Sa)
	local dowRow = Utility.Create("Frame", {
		Name = "DayOfWeekHeader",
		Parent = calFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 28),
		Size = UDim2.new(1, -12, 0, 18),
		ZIndex = calFrame.ZIndex + 1,
	})
	for i, dName in ipairs(WEEK_DAYS) do
		Utility.Create("TextLabel", {
			Name = "DOW_" .. dName,
			Parent = dowRow,
			BackgroundTransparency = 1,
			Position = UDim2.new((i - 1) / 7, 0, 0, 0),
			Size = UDim2.new(1 / 7, 0, 1, 0),
			Font = Theme.Fonts.Regular,
			Text = dName,
			TextColor3 = Theme.Colors.TextSecondary,
			TextSize = 11,
			ZIndex = dowRow.ZIndex + 1,
		})
	end

	Utility.Create("Frame", {
		Name = "DOWDivider",
		Parent = calFrame,
		BackgroundColor3 = Theme.Colors.GroupBoxBorder,
		Position = UDim2.new(0, 6, 0, 46),
		Size = UDim2.new(1, -12, 0, 1),
		ZIndex = calFrame.ZIndex + 1,
	})

	-- 42-day calendar grid (6x7)
	local daysGrid = Utility.Create("Frame", {
		Name = "DaysGridHost",
		Parent = calFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 49),
		Size = UDim2.new(1, -12, 0, 112),
		ZIndex = calFrame.ZIndex + 1,
	})

	-- "Today" footer quick-jump
	local todayBtn = Utility.Create("TextButton", {
		Name = "JumpTodayButton",
		Parent = calFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 1, -22),
		Size = UDim2.new(1, -12, 0, 20),
		Font = Theme.Fonts.Semibold,
		Text = "Today: " .. formatDate(todayYear, todayMonth, todayDay),
		TextColor3 = Theme.Colors.TextLink,
		TextSize = 12,
		ZIndex = calFrame.ZIndex + 1,
	})

	local controller = {
		Wrapper = wrapper,
		CalendarFrame = calFrame,
		Year = year,
		Month = month,
		Day = day,
		Value = formatDate(year, month, day),
	}

	local function rebuildCalendarGrid()
		monthTitleLbl.Text = (MONTH_NAMES[viewMonth] or "Month") .. " " .. tostring(viewYear)
		for _, child in ipairs(daysGrid:GetChildren()) do
			child:Destroy()
		end

		local firstDow = getDayOfWeek(viewYear, viewMonth, 1) -- 0..6
		local daysInCurr = getDaysInMonth(viewYear, viewMonth)
		local prevM = (viewMonth == 1) and 12 or (viewMonth - 1)
		local prevY = (viewMonth == 1) and (viewYear - 1) or viewYear
		local daysInPrev = getDaysInMonth(prevY, prevM)

		for cellIdx = 0, 41 do
			local r = math.floor(cellIdx / 7)
			local c = cellIdx % 7
			local dNum = cellIdx - firstDow + 1
			local cellYear, cellMonth, cellDay
			local isCurrentMonth = true

			if dNum < 1 then
				isCurrentMonth = false
				cellYear = prevY
				cellMonth = prevM
				cellDay = daysInPrev + dNum
			elseif dNum > daysInCurr then
				isCurrentMonth = false
				cellMonth = (viewMonth == 12) and 1 or (viewMonth + 1)
				cellYear = (viewMonth == 12) and (viewYear + 1) or viewYear
				cellDay = dNum - daysInCurr
			else
				cellYear = viewYear
				cellMonth = viewMonth
				cellDay = dNum
			end

			local isSelected = (cellYear == year and cellMonth == month and cellDay == day)
			local isToday = (cellYear == todayYear and cellMonth == todayMonth and cellDay == todayDay)

			local cellBtn = Utility.Create("TextButton", {
				Name = string.format("Day_%04d_%02d_%02d", cellYear, cellMonth, cellDay),
				Parent = daysGrid,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = isSelected and 0.05 or 1,
				Position = UDim2.new(c / 7, 1, r / 6, 1),
				Size = UDim2.new(1 / 7, -2, 1 / 6, -2),
				Font = isSelected and Theme.Fonts.Semibold or Theme.Fonts.Regular,
				Text = tostring(cellDay),
				TextColor3 = isCurrentMonth and Theme.Colors.TextPrimary or Theme.Colors.TextDisabled,
				TextSize = 11,
				ZIndex = daysGrid.ZIndex + 1,
			})
			Utility.AddCorner(cellBtn, 2)

			local cellStroke = Utility.AddStroke(
				cellBtn,
				isSelected and Theme.Colors.SelectionBorder or (isToday and Theme.Colors.ControlBorderHover or Theme.Colors.SelectionHoverBorder),
				1,
				(isSelected or isToday) and 0.05 or 1,
				Enum.ApplyStrokeMode.Border
			)

			local cellGrad = Instance.new("UIGradient")
			cellGrad.Rotation = 90
			cellGrad.Color = isSelected and Theme.Gradients.ExplorerItemSelected or Theme.Gradients.ExplorerItemHover
			cellGrad.Parent = cellBtn

			cellBtn.MouseEnter:Connect(function()
				if not isSelected then
					cellBtn.BackgroundTransparency = 0.15
					cellStroke.Transparency = 0.2
				end
			end)
			cellBtn.MouseLeave:Connect(function()
				if not isSelected then
					cellBtn.BackgroundTransparency = 1
					cellStroke.Transparency = isToday and 0.05 or 1
				end
			end)
			cellBtn.MouseButton1Click:Connect(function()
				controller:SetDate(cellYear, cellMonth, cellDay)
			end)
		end
	end

	function controller:SetDate(y, m, d, silent)
		year = tonumber(y) or year
		month = math.clamp(tonumber(m) or month, 1, 12)
		day = math.clamp(tonumber(d) or day, 1, getDaysInMonth(year, month))
		viewYear, viewMonth = year, month
		self.Year = year
		self.Month = month
		self.Day = day
		self.Value = formatDate(year, month, day)
		dateTextLbl.Text = self.Value
		rebuildCalendarGrid()
		if not silent then
			callback(self.Value, year, month, day)
		end
	end

	prevBtn.MouseButton1Click:Connect(function()
		if viewMonth == 1 then
			viewMonth = 12
			viewYear = viewYear - 1
		else
			viewMonth = viewMonth - 1
		end
		rebuildCalendarGrid()
	end)

	nextBtn.MouseButton1Click:Connect(function()
		if viewMonth == 12 then
			viewMonth = 1
			viewYear = viewYear + 1
		else
			viewMonth = viewMonth + 1
		end
		rebuildCalendarGrid()
	end)

	todayBtn.MouseButton1Click:Connect(function()
		controller:SetDate(todayYear, todayMonth, todayDay)
	end)

	boxBtn.MouseEnter:Connect(function()
		boxStroke.Color = Theme.Colors.EditBorderHover
		chipGrad.Color = Theme.Gradients.ButtonHover
	end)
	boxBtn.MouseLeave:Connect(function()
		boxStroke.Color = Theme.Colors.EditBorderNormal
		chipGrad.Color = Theme.Gradients.ButtonNormal
	end)
	boxBtn.MouseButton1Click:Connect(function()
		calFrame.Visible = not calFrame.Visible
	end)

	rebuildCalendarGrid()
	return controller
end

return DatePicker
