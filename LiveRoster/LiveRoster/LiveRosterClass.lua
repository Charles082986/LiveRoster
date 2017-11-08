LiveRoster = {
    PlayerCharacters = {},
    CanRemove = nil,
	CanPromote = nil,
	CanInvite = nil,
	CanDemote = nil,
	MyGuildRankIndex = 99,
	Frame = {},
}
LiveRoster.__index = LiveRoster;

function LiveRoster:create ()
    local lr = {};
    setmetatable (lr, LiveRoster);
	lr.CanRemove = CanGuildRemove();
	lr.CanPromote = CanGuildPromote();
	lr.CanInvite = CanGuildInvite();
	lr.CanDemote = CanGuildDemote();
	lr.Frame = LiveRosterFrame;
    return lr;
end

function LiveRoster.RegisterEvents()
	local frame = self.Frame;
	local function OnEvent(self,event,...)
		if event=="ADDON_LOADED" and select(1,...)=="LiveRoster" then
			self:UnregisterEvent("ADDON_LOADED")
			GuildRosterFrame:HookScript("OnShow",self.GuildRosterFrame_Show);
			GuildRosterFrame:HookScript("OnHide",self.GuildRosterFrame_Hide);
		  elseif event=="PLAYER_LOGIN" then
			if IsAddOnLoaded("LiveRoster") then
			  OnEvent(self,"ADDON_LOADED","LiveRoster");
			else
			  self:RegisterEvent("ADDON_LOADED");
			end
		  end
		end
	end
	frame:SetScript("OnEvent", OnEvent);
	frame:RegisterEvent("PLAYER_LOGIN");
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
	local guildSize = GetNumGuildMembers();
	for i = 1, guildSize do
		local playerCharacter = LiveRosterPlayerCharacter:create(i,GetGuildRosterInfo(i));
		local mainName, isAlt = LiveRoster_ParseGuildNote(playerCharacter);
		playerCharacter.IsAlternateCharacter = isAlt;
		local characterAltStore = altStore[mainName];
		if not characterAltStore then characterAltStore = LiveRosterAltStore:create(); end
		localInsert(characterAltStore,playerCharacter.Name);
		if not not isAlt then
			playerCharacter.MainName = mainName;
		end
		altStore[mainName] = characterAltStore;
		self.PlayerCharacters[playerCharacter.Name] = playerCharacter;
		self.NameIndex[i] = playerCharacter.Name;
	end
	for k,v in pairs(altStore) do
		for a,b in pairs(v) do
			self.PlayerCharacters[b].AlternateCharacters = v;
		end
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
			GuildUninvite(v);
		end
	end
end

function LiveRoster.SetMemberRank(iIndex,iTargetRankIndex)
	local playerCharacter = self.PlayerCharacters[self.NameIndex[iIndex]];
	self.SyncGuildRanks(iIndex);
	if iTargetRankIndex > self.MyGuildRankIndex and playerCharacter.RankIndex > self.MyGuildRankIndex 
		and ((iTargetRankIndex < playerCharacter.RankIndex and self.CanPromote) 
		or (iTargetRankIndex > playerCharacter.RankIndex and self.CanDemote)) then
		for k,v in pairs(playerCharacter.AlternateCharacters) do
			local promoteCharacter = self.PlayerCharacters[v];
			if not not iTargetRank then 
				SetGuildMemberRank(promoteCharacter.Index,iTargetRank);
			end 
		end
	end
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
	Name = nil, 
	Rank = nil, 
	Index = 0, 
	RankIndex = 0, 
	Class = nil, 
	Level = nil, 
	Zone = nil,
	Note = nil,
	OfficerNote = nil,
	DaysInGuild = 0,
	ErrorStatus = 0,
	NeedsPromotion = 0,
	ShortName = nil,
	Online = 0,
	ClassFileName = nil,
	AchievementPoints = 0,
	AchievementRank = 0,
	IsMobile = false,
	CanSoR = false,
	Reputation = 0,
	IsAlternateCharacter = nil,
	MainName = nil;
	Alts = {}
}

function LiveRosterPlayerCharacter:create(iIndex,sName,sRank,iRankIndex,iLevel,sClass,sZone,sNote,sOfficerNote,bOnline,sClassFileName,iAchievementPoints,iAchievementRank,bIsMobile,bCanSoR,iReputation,bIsAlt,sMainName)
	local lrpc = {};
	setmetatable(lrpc,LiveRosterPlayerCharacter);
	lrpc.Name = sName;
	lrpc.Rank = sRank;
	lrpc.Index = iIndex;
	lrpc.RankIndex = iRankIndex;
	lrpc.Level = iLevel;
	lrpc.Class = sClass;
	lrpc.Note = sNote;
	lrpc.OfficerNote = sOfficerNote;
	lrpc.Online = bOnline;
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
