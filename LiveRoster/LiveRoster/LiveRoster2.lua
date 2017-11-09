FrameXML_Debug (enable);

LR_NAME = "LiveRoster";
LR_VERSION = 2.0;

LR_SETTINGS = LR_SETTINGS or LiveRosterSettings:create();
LR_GUILDDATA = LR_GUILDDATA or {};

LR = LiveRoster:create();
LR.RegisterEvents();

function LiveRoster_IsAltGuild ()
    local GuildName, _ = GetGuildInfo ("Player")
    if not not GuildName and GuildName == LR_ALTGUILD then
		return 1;
    end
	return nil;
end

function LiveRoster_GetServerName()
    local server = GetRealmName();
    if not not server then
		return string.gsub(server,"%s+","");
    end
	return nil;
end


function LiveRoster_OnEvent(me,event,...)
	if event=="ADDON_LOADED" and select(1,...)=="LiveRoster" then
		self:UnregisterEvent("ADDON_LOADED")
		GuildRosterFrame:HookScript("OnShow",self.GuildRosterFrame_Show);
		GuildRosterFrame:HookScript("OnHide",self.GuildRosterFrame_Hide);
	elseif event == "CHAT_MSG_ADDON" then
			
	elseif event=="PLAYER_LOGIN" then
		if IsAddOnLoaded("LiveRoster") then
			OnEvent(self,"ADDON_LOADED","LiveRoster");
		else
			self:RegisterEvent("ADDON_LOADED");
		end
	end
end

function LiveRoster_ConvertValuesToNumeric(pairsCollection)
    for k,v in ipairs(pairsCollection) do 
        pairsCollection[k] = tonumber(v);
    end
	return pairsCollection;
end

function LiveRoster_CanGuildPromote()
	local success,result = pcall(CanGuildPromote());
	if not success then 
		return false, false; 
	else 
		return result; 
	end
end

function LiveRoster_CanGuildDemote()
	local success,result = pcall(CanGuildDemote());
	if not success then 
		return false, false; 
	else 
		return result; 
	end
end

function LiveRoster_CanGuildInvite()
	local success,result = pcall(CanGuildInvite());
	if not success then 
		return false, false; 
	else 
		return result; 
	end
end

function LiveRoster_CanGuildRemove()
	local success,result = pcall(CanGuildRemove());
	if not success then 
		return false, false; 
	else 
		return result; 
	end
end

function LiveRoster_GetPriorityValue(playerCharacter)
	if not not playerCharacter.Online then return 2;
	else if not playerCharacter.IsAlternateCharacter then return 1;
	else return 0;
	end
end

function LiveRoster_PrioritySort(a,b)
	local Pa = LiveRoster_GetPriorityValue(a);
	local Pb = LiveRoster_GetPriorityValue(b);
	if Pa ~= Pb then
		return Pa > Pb;
	else
		return a.Name < b.Name;
	end
end

function LiveRoster_ConcurrencySort(a,b)
	local da = a.Concurrency_OriginDate or 0;
	local db = b.Concurrency_OriginDate or 0;
	if da ~= db then
		return da > db;
	else
		return a > b;
	end
end