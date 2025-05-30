
local cloneref = cloneref or function(...) return ... end

local httpService = cloneref(game:GetService('HttpService'))

local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'
	-- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default'] = { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"9F6236","BackgroundColor":"141414","OutlineColor":"323232"}') },
		['Gamesense'] = { 2, httpService:JSONDecode('{"FontColor":"919191","MainColor":"101010","AccentColor":"9CB819","SelectedTabColor":"101010","BackgroundColor":"111111","OutlineColor":"2D2D2D"}') },
		['Mae'] = { 3, httpService:JSONDecode('{"FontColor":"c5c5c5","MainColor":"0F0F0F","AccentColor":"ffc6fe","SelectedTabColor":"171717","BackgroundColor":"0f0f0f","OutlineColor":"191919"}') },
		['Fatality'] = { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		['Jester'] = { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Mint'] = { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Tokyo Night'] = { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') }
	}

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		-- custom themes are just regular dictionaries instead of an array with { index, dictionary }

		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			self.Library[idx] = Color3.fromHex(col)
			
			if self.Library.Options[idx] then
				self.Library.Options[idx]:SetValueRGB(Color3.fromHex(col))
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		-- This allows us to force apply themes without loading the themes tab :)
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for i, field in next, options do
			if self.Library.Options and self.Library.Options[field] then
				self.Library[field] = self.Library.Options[field].Value
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
		 	theme = self.DefaultTheme
		end

		if isDefault then
			self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddLabel('Background Color'):AddColorPicker('BackgroundColor', { Title = 'Background Color', Default = self.Library.BackgroundColor });
		groupbox:AddLabel('Main Color')	:AddColorPicker('MainColor', { Title = 'Main Color', Default = self.Library.MainColor });
		groupbox:AddLabel('Accent Color'):AddColorPicker('AccentColor', { Title = 'Accent Color', Default = self.Library.AccentColor });
		groupbox:AddLabel('Outline Color'):AddColorPicker('OutlineColor', { Title = 'Outline Color', Default = self.Library.OutlineColor });
		groupbox:AddLabel('Font Color')	:AddColorPicker('FontColor', { Title = 'Font Color', Default = self.Library.FontColor });

		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

        	groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme List', Values = ThemesArray, Default = 1 })

		groupbox:AddButton('Set As Default', function()
			self:SaveDefault(self.Library.Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format('Set default theme to %q', self.Library.Options.ThemeManager_ThemeList.Value))
		end)

		self.Library.Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(self.Library.Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom Theme Name' })
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom Themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddDivider()
		
		groupbox:AddButton('Save Theme', function() 
			self:SaveCustomTheme(self.Library.Options.ThemeManager_CustomThemeName.Value)

			self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
		end):AddButton('Load Theme', function() 
			self:ApplyTheme(self.Library.Options.ThemeManager_CustomThemeList.Value) 
		end)

		groupbox:AddButton('Refresh List', function()
			self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddButton('Set As Default', function()
			if self.Library.Options.ThemeManager_CustomThemeList.Value ~= nil and self.Library.Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(self.Library.Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', self.Library.Options.ThemeManager_CustomThemeList.Value))
			end
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
		self.Library.Options.MainColor:OnChanged(UpdateTheme)
		self.Library.Options.AccentColor:OnChanged(UpdateTheme)
		self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
		self.Library.Options.FontColor:OnChanged(UpdateTheme)
	end

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)
		
		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3)
		end

		local theme = {}
		local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

		for _, field in next, fields do
			theme[field] = self.Library.Options[field].Value:ToHex()
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				-- i hate this but it has to be done ...

				local pos = file:find('.json', 1, true)
				local char = file:sub(pos, pos)

				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1))
				end
			end
		end

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}

		-- build the entire tree if a path is like some-hub/phantom-forces
		-- makefolder builds the entire tree on Synapse X but not other exploits

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		table.insert(paths, self.Folder .. '/themes')
		table.insert(paths, self.Folder .. '/settings')

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
