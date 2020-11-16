scan_targets = {}
local CHECK_INTERVAL = .1
local found = {}
local isFind
local scan = CreateFrame'Frame'
local pluginName = 'Scan'
scan:SetScript('OnUpdate', function() scan.UPDATE() end)
scan:SetScript('OnEvent', function(_, event, arg1)
	if event == 'ADDON_ACTION_FORBIDDEN' and arg1 == pluginName then
        isFind = true
	elseif event == 'ADDON_LOADED' and arg1 == pluginName then
		
		scan.LOAD()
	end
end)
scan:RegisterEvent'ADDON_LOADED'
scan:RegisterEvent'ADDON_ACTION_FORBIDDEN'


function scan.LOAD()
	print('load')
    UIParent:UnregisterEvent'ADDON_ACTION_FORBIDDEN'
    do
		local flash = CreateFrame'Frame'
		scan.flash = flash
		flash:Show()
		flash:SetAllPoints()
		flash:SetAlpha(0)
		flash:SetFrameStrata'FULLSCREEN_DIALOG'
		
		local texture = flash:CreateTexture()
		texture:SetBlendMode'ADD'
		texture:SetAllPoints()
		texture:SetTexture[[Interface\FullScreenTextures\LowHealth]]

		flash.animation = CreateFrame'Frame'
		flash.animation:Hide()
		flash.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .5 then
				flash:SetAlpha(t * 2)
			elseif t <= 1 then
				flash:SetAlpha(1)
			elseif t <= 1.5 then
				flash:SetAlpha(1 - (t - 1) * 2)
			else
				flash:SetAlpha(0)
				self.loops = self.loops - 1
				if self.loops == 0 then
					self.t0 = nil
					self:Hide()
				else
					self.t0 = GetTime()
				end
			end
		end)
		function flash.animation:Play()
			if self.t0 then
				self.loops = 4
			else
				self.t0 = GetTime()
				self.loops = 3
			end
			self:Show()
		end
	end
end

do
	scan.last_check = GetTime()
	function scan.UPDATE()
		if GetTime() - scan.last_check >= CHECK_INTERVAL then
			scan.last_check = GetTime()
			for name in pairs(scan_targets) do
				scan.target(name)
			end
		end
	end
end
do
	local last_played
	function scan.play_sound()
		if not last_played or GetTime() - last_played > 8 then
			PlaySoundFile([[Interface\AddOns\scan\Event_wardrum_ogre.ogg]], 'Master')
			PlaySoundFile([[Interface\AddOns\scan\scourge_horn.ogg]], 'Master')
			last_played = GetTime()
		end
	end
end
function scan.tip(name)
    scan.flash.animation:Play()
	scan.play_sound()
	local name = UnitName("player")
	SendChatMessage('<scan> ' .. name, "WHISPER", nil, name)
end
function scan.target(name)
    isFind = false
	local sound_setting = GetCVar'Sound_EnableAllSound'
    SetCVar('Sound_EnableAllSound', 0)
	TargetUnit(name, true)
	SetCVar('Sound_EnableAllSound', sound_setting)
    if isFind then
        if not found[name] then
            found[name] = true
            scan.tip(name)
        end
    else
		found[name] = false
    end
end

function scan.toggle_target(name)
	local key = strupper(name)
	if scan_targets[key] then
		scan_targets[key] = nil
		found[key] = nil
		scan.print('- ' .. key)
	elseif key ~= '' then
		scan_targets[key] = true
		scan.print('+ ' .. key)
	end
end

function scan.print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(LIGHTYELLOW_FONT_COLOR_CODE .. '<scan> ' .. msg)
	end
end



SLASH_My1 = '/scan'
function SlashCmdList.My(parameter)
    if parameter == 'test' then
		scan.tip('啊啊啊')
        -- scan.flash.animation:Play()
    elseif parameter == 'clear' then
        for key in pairs(scan_targets) do
            scan_targets[key] = nil
        end
    elseif parameter == '' then
        for key in pairs(scan_targets) do
            scan.print(key)
        end    
    else
        scan.toggle_target(parameter)
    end
end
