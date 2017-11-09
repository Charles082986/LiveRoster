LiveRoster = {
    PlayerCharacters = {},
    CanRemove = nil,
	CanPromote = nil,
	CanInvite = nil,
	CanDemote = nil,
	MyGuildRankIndex = 99,
	MyName = nil,
	MyGuildName = nil,
	Frame = {},
}
LiveRoster.__index = LiveRoster;

function LiveRoster:create ()
    local lr = {};
    setmetatable (lr, LiveRoster);
	lr.CanRemove = LiveRoster_CanGuildRemove();
	lr.CanPromote = LiveRoster_CanGuildPromote();
	lr.CanInvite = LiveRoster_CanGuildInvite();
	lr.CanDemote = LiveRoster_CanGuildDemote();
	lr.Frame = LiveRosterFrame;
	local guildName,guildRankName,guildRankIndex = GetGuildInfo("player");
	lr.MyGuildName = guildName;
	lr.MyGuildRankIndex = guildRankIndex;
	lr.MyName = UnitName("player");
    return lr;
end

function LiveRoster.OnEvent(me,event,...)
	if event=="ADDON_LOADED" and select(1,...)==LR_NAME then
		self.Frame:UnregisterEvent("ADDON_LOADED")
		GuildRosterFrame:HookScript("OnShow",self.GuildRosterFrame_Show);
		GuildRosterFrame:HookScript("OnHide",self.GuildRosterFrame_Hide);
	elseif event == "CHAT_MSG_ADDON" then
		local prefix = select(1,...);
		local message = select(2,...);
		local channel = select(3,...);
		local sender = select(4,...);
		local messageKey = string.sub(message,1,1);
		local messageHasData,messageData = pcall(string.sub(message,3));
		LiveRoster_ReceivedMessageHandler(prefix,message,channel,sender,messageKey,messageHasData,messageData);
	elseif event=="PLAYER_LOGIN" then
		if IsAddOnLoaded(LR_NAME) then
			OnEvent(me,"ADDON_LOADED",LR_NAME);
		else
			self.Frame:RegisterEvent("ADDON_LOADED");
		end
	end
end

function LiveRoster.RegisterEvents()
	local frame = self.Frame;
	frame:SetScript("OnEvent", LiveRoster_OnEvent);
	frame:RegisterEvent("PLAYER_LOGIN");
	frame:RegisterEvent("CHAT_MSG_ADDON");
end

function LiveRoster.GuildRosterFrame_Show(me)
	print("The Guild Roster Frame is Now Showing.");
end

function LiveRoster.GuildRosterFrame_Hide(me)
	print("The Guild Roster Frame is Now Hidden.");
end

function LiveRoster.LoadFullRoster()
	self:PrepareRoster();
	local altStore = {};
	local localInsert = table.insert;
	local localCount = table.getn;
	local localSort = table.sort;
	local guildSize = GetNumGuildMembers();
	for i = 1, guildSize do
		local playerCharacter = LiveRosterPlayerCharacter:create(i,GetGuildRosterInfo(i));
		local mainName, isAlt = LiveRoster_ParseGuildNote(playerCharacter);
		playerCharacter.IsAlternateCharacter = isAlt;
		local characterAltStore = altStore[mainName];
		if not characterAltStore then characterAltStore = LiveRosterAltStore:create(); end
		localInsert(characterAltStore,playerCharacter);
		if not not isAlt then
			playerCharacter.MainName = mainName;
		end
		altStore[mainName] = characterAltStore;
		self.PlayerCharacters[playerCharacter.Name] = playerCharacter;
		self.NameIndex[i] = playerCharacter.Name;
	end
	for k,v in pairs(altStore) do
		local specificAltStore = v;
		localSort(specificAltStore,LiveRoster_PrioritySort);
		local count = 0;
		local priorityCharacter;
		for k2,v2 in pairs(specificAltStore) do
			if not priorityCharacter then
				priorityCharacter = v2;
				priorityCharacter.OnlinePriorityCharacter = {};
			elseif not not v2.Online then
				localInsert(priorityCharacter.OnlineSubordinateCharacters,v2);
			else
				localInsert(priorityCharacter.OfflineSubordinateCharacters,v2);
			end
		end
		localInsert(self.PriorityCharacters,priorityCharacter);
	end
end

function LiveRoster:PrepareRoster()
	ShowUIPanel(GuildFrame);
	GuildFrame:Show();
	GuildFrameTab2:Click();
	GuildRosterShowOfflineButton:SetChecked(true);
	GuildRosterShowOffline(1);
	SortGuildRoster("level");
	SortGuildRoster("name");
end

function LiveRoster.RemoveMember(iIndex)
	if not not self.CanRemove then
		local playerCharacter = self.PlayerCharacters[self.NameIndex[iIndex]];
		for k,v in pairs(playerCharacter.AlternateCharacters) do
			local success = pcall(GuildUninvite(v));
			if not success then false; end
		end
	end
	return true;
end

function LiveRoster.SetMemberRank(iIndex,iTargetRankIndex)
	local playerCharacter = self.PlayerCharacters[self.NameIndex[iIndex]];
	for k,v in pairs(playerCharacter.AlternateCharacters) do
		local promoteCharacter = self.PlayerCharacters[v];
		if iTargetRankIndex > self.MyGuildRankIndex and promoteCharacter.RankIndex > self.MyGuildRankIndex 
			and ((iTargetRankIndex < promoteCharacter.RankIndex and self.CanPromote) 
			or (iTargetRankIndex > promoteCharacter.RankIndex and self.CanDemote)) then
			if not not iTargetRank then 
				local success = pcall(SetGuildMemberRank(promoteCharacter.Index,iTargetRank));
				if not success then return false; end
			end 
		end
	end
	return true;
end

function LiveRoster.InviteAlternateCharacter(mainName, characterName)
end

LiveRosterAltStore = {
	Alts = {}
}

function LiveRosterAltStore:create()
	local lras = {};
	setmetatable(lras,LiveRosterAltSTore);
	lras.Alts = {};
	return lras;
end

LiveRosterInvitation = {
    CharacterName = nil,
    IsAltInvite = nil,
    MainCharacterName = nil,
}

function LiveRosterInvitation:create (characterName, isAltInvite, mainCharacterName)
    local lri = {};
    setmetatable (lri, LiveRosterInvitation);
    lri.CharacterName = characterName;
    lri.IsAltInvite = isAltInvite;
    lri.MainCharacterName = mainCharacterName;
	return lri;
end

LiveRosterDismissal = {
    CharacterName = nil,
    CharacterAlts = {},
	MainCharacterName = nil
}

function LiveRosterDismissal:create (characterName)
    local lrd = {};
    setmetatable (lrd, LiveRosterDismissal);
    lrd.CharacterName = characterName;
    lrd.CharacterAlts = GetAlternateCharacters (characterName);
    lrd.MainCharacterName = GetMainCharacterName (characterName);
	return lrd;
end

LiveRosterPlayerCharacter = {
	FullName = nil,
	ShortName = nil,
	GuildContextName = nil,
	Rank = nil, 
	Index = 0, 
	RankIndex = 0, 
	Class = nil, 
	Level = nil, 
	Zone = nil,
	Note = nil,
	OfficerNote = nil,
	Online = 0,
	Status = nil;
	ClassFileName = nil,
	AchievementPoints = 0,
	AchievementRank = 0,
	IsMobile = false,
	CanSoR = false,
	Reputation = 0,
	IsAlternateCharacter = nil,
	MainName = nil,
	OnlineSubordinateCharacters = {},
	OfflineSubordinateCharacters = {},
}

function LiveRosterPlayerCharacter:create(iIndex,sFullName,sRank,iRankIndex,iLevel,sClass,sZone,sNote,sOfficerNote,bOnline,sStatus,sClassFileName,iAchievementPoints,iAchievementRank,bIsMobile,bCanSoR,iReputation,bIsAlt,sMainName)
	local lrpc = {};
	setmetatable(lrpc,LiveRosterPlayerCharacter);
	lrpc.FullName = sFullName;
	lrpc.ShortName = Ambiguate(sFullName,"short");
	lrpc.GuildContextName = Ambiguate(sFullName,"guild");
	lrpc.Rank = sRank;
	lrpc.Index = iIndex;
	lrpc.RankIndex = iRankIndex;
	lrpc.Level = iLevel;
	lrpc.Class = sClass;
	lrpc.Note = sNote;
	lrpc.OfficerNote = sOfficerNote;
	lrpc.Online = bOnline;
	lrpc.Status = sStatus;
	lrpc.ClassFileName = sClassFileName;
	lrpc.AchievementPoints = iAchievementPoints;
	lrpc.AchievementRank = iAchievementRank;
	lrpc.IsMobile = bIsMobile;
	lrpc.CanSoR = bCanSoR;
	lrpc.Reputation = iReputation;
	lrpc.IsAlternateCharacter = bIsAlt;
	lrpc.MainName = sMainName;
	return lrpc;
end

LiveRosterEventHandler = {
	Events = {};
}

function LiveRosterEventHandler:create()
	local lreh = {};
	setmetatable(lreh,LiveRosterEventHandler);
	lreh.Events = {

	}
	return lreh;
end