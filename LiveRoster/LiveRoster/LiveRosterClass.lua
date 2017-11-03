LiveRoster = {
    PlayerCharacters = {},
    Players = {},
    ExtensionButtons = {
        Main = nil
    },
    Roster = {
        MainCharacters = {},
        AlternateCharacters = {},
        Unknown = {},
        NameIndex = {},
        Promotions = {},
    },
    MostAlts = 0,
    OutputChannel = "SAY",
    Promotions = {
        Selected = 0,
        Enabled = 0,
        Completed = 0,
        Total = 0,
    },
    SelectedPlayer = nil,
    SelectedPlayerCharacterIndex = 0,
    ShortNames = {},
    GuildCount = 1,
	CanRemove = nil,
	CanPromote = nil,
	CanInvite = nil,
	CanDemote = nil,
	MyRankIndex = 99
}
LiveRoster.__index = LiveRoster;

function LiveRoster:create ()
    local lr = {};
    setmetatable (lr, LiveRoster);
    if LR_USE_SNAPSHOT > 0 and LR_SNAPSHOT ~= nil and InAltGuild () then
        local guildCount = 1;
        LRE ("Snapshot Found, using.")
        for sName, vMain in pairs (LR_SNAPSHOT.PlayerCharacters) do
            LR_SNAPSHOT_INDEX[guildCount] = sName;
            guildCount = guildCount + 1;
        end
        lr.GuildCount = guildCount;
		lr.CanRemove = CanGuildRemove();
		lr.CanPromote = CanGuildPromote();
		lr.CanInvite = CanGuildInvite();
		lr.CanDemote = CanGuildDemote();
    end
    return lr;
end

function LiveRoster.LoadFullRoster()
	self:PrepareRoster();
	local localInsert = table.insert;
	local localCount = table.getn;
	local guildSize = GetNumGuildMembers();
	for i = 1, guildSize do
		local playerCharacter = LiveRosterPlayerCharacter:create(i,GetGuildRosterInfo(i));
		local mainName, isAlt = LiveRoster_ParseGuildNote(playerCharacter);
		playerCharacter.IsAlternateCharacter = isAlt;
		local characterAltStore = self.AltStore[mainName];
		if not characterAltStore then characterAltStore = LiveRosterAltStore:create(); end
		localInsert(characterAltStore,playerCharacter.Name);
		if not not isAlt then
			playerCharacter.MainName = mainName;
		end
		self.AltStore[mainName] = characterAltStore;
		self.PlayerCharacters[playerCharacter.Name] = playerCharacter;
		self.NameIndex[i] = playerCharacter.Name;
	end
	local altStore = self.AltStore;
	for k,v in pairs(altStore) do
		for a,b in pairs(v) do
			self.PlayerCharacters[b].AlternateCharacters = v;
		end
	end
	self.AltStore = nil;
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