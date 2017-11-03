FrameXML_Debug (enable);
LR_USE_SNAPSHOT = 1;
LR_SNAPSHOT_INDEX = {};
LR_ALTGUILD = "Bastions of Twilight";
LR = LiveRoster:create();
LR_SNAPSHOT = LiveRosterSnapshot:create();

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

function LiveRoster_PrepareRoster()

end

function LiveRoster_Execute()
	self = LiveRosterFrame;
    local serverName = LiveRoster_GetServerName();
	ShowUIPanel(GuildFrame);
	SetCVar("guildRosterView","guildStatus");
	hooksecurefunc("GuildRoster_Update", LiveRoster.RosterUpdatePostHook)  --So we know when to add all the goodies to the guild roster
	hooksecurefunc("HybridScrollFrame_Update", LiveRoster.ScrollFrameUpdatePostHook);
	hooksecurefunc("GuildRosterViewDropdown_OnClick", LiveRoster.ViewMenuClickPostHook);
	GuildFrame:HookScript("OnLoad", GuildFrame_OnLoadHook );
	LiveRoster_Main = self;
	LiveRoster_RegisterExecuteEvents(self);
	LiveRoster_PromoteButtonText = "Player Promotions";
	LR_ALTBUTTONTEXT = "Alt Promotions";
	LiveRosterSearchBox.autoCompleteParams = AUTOCOMPLETE_LIST_TEMPLATES.IN_GUILD
	SLASH_LIVEROSTER1, SLASH_LIVEROSTER2 = '/liveroster','/lr' -- 3.

	LR_Player_Name = UnitName("player").."-"..LRServer;
	-- Search box needs some room.
	GuildRosterViewDropdown:SetPoint("TOPLEFT",GuildRosterFrame , "TOPLEFT", 150, -24);

	LiveRoster_SetRankSettings();

	-- Ensures values are numeric.
	LIVEROSTER_RANK_DAYS = LiveRoster_ConvertValuesToNumeric(LIVEROSTER_RANK_DAYS);
	LIVEROSTER_RANK_ACTIVE = LiveRoster_ConvertValuesToNumeric(LIVEROSTER_RANK_ACTIVE);

    LiveRoster.UpdateRoster();
end

function LiveRoster_RegisterExecuteEvents(frame)
    if not not self then
		self:RegisterEvent("ADDON_LOADED");
		self:RegisterEvent("VARIABLES_LOADED");
		self:RegisterEvent("PLAYER_ENTERING_WORLD");
		self:RegisterEvent("SAVED_VARIABLES_TOO_LARGE");
		self:RegisterEvent("CHAT_MSG_SYSTEM");
		self:RegisterEvent("GUILD_ROSTER_UPDATE");
		self:RegisterEvent("FRIENDLIST_UPDATE");
		self:RegisterEvent("FRIENDLIST_SHOW");
		self:RegisterEvent("CHAT_MSG_CHANNEL_JOIN");
		self:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE");
		self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");
		self:RegisterEvent("CHAT_MSG_SAY");
		self:RegisterEvent("CHAT_MSG_GUILD");
		self:RegisterEvent("VARIABLES_LOADED");
		self:RegisterEvent("PLAYER_ENTERING_WORLD");
		self:RegisterEvent("SAVED_VARIABLES_TOO_LARGE");
		self:RegisterEvent("CHAT_MSG_SYSTEM");
		self:RegisterEvent("GUILD_ROSTER_UPDATE");
		self:RegisterEvent("FRIENDLIST_UPDATE");
		self:RegisterEvent("FRIENDLIST_SHOW");
		self:RegisterEvent("CHAT_MSG_CHANNEL_JOIN");
		self:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE");
        self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");
    end
end

function LiveRoster_ConvertValuesToNumeric(pairsCollection)
    for k,v in ipairs(pairsCollection) do 
        pairsCollection[k] = tonumber(v);
    end
	return pairsCollection;
end

function LiveRoster_SetRankSettings()
    if not LRSETTINGS then 
        print("Didn't find LRSETTINGS");
        LRSETTINGS = {
            LIVEROSTER_RANK_COLORS = LIVEROSTER_RANK_COLORS,
            LIVEROSTER_RANK_DAYS   = LIVEROSTER_RANK_DAYS,
            LIVEROSTER_RANK_ACTIVE = LIVEROSTER_RANK_DAYS
        }
    else
        print("Found LRSETTINGS, trying to load.");
        LIVEROSTER_RANK_COLORS = LRSETTINGS.LIVEROSTER_RANK_COLORS;
        LIVEROSTER_RANK_DAYS   = LRSETTINGS.LIVEROSTER_RANK_DAYS
        LIVEROSTER_RANK_ACTIVE = LRSETTINGS.LIVEROSTER_RANK_DAYS
    end	
end
