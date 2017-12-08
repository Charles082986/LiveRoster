LR_VERSION = 1;
LR_MINIMUM_VERSION = 1;
LR_ROSTERSORT = function(a,b)
	sort = LiRos.SortObject;
	if not sort or sort == {} then 
		LiRos.SortObject = {};
		LiRos.SortObject[1] = { Name = "Online", Inverted = false };
		LiRos.SortObject[2] = { Name = "FullName", Inverted = false };
		sort = LiRos.SortObject;
	end
	for index,value in ipairs(sort) do
		local n = value[Name];
		local aVal = a[n], bVal = b[n];
		if aVal ~= bVal then 
			if value[Inverted] then return aVal < bVal; else return aVal > bVal; end
		end
	end
	return a["FullName"] > b["FullName"];
end
LR_ROUNDING = function(num,decimalPlaces)
	local mult = 10^(decimalPlaces or 0);
	return math.floor(num * mult) / mult;
end
LR_METATABLESEARCH = function(k,plist)
	for i=1, table.getn(plist) do
		local v = plist[i][k]
		if v then return v end
	end
end
LR_SETMETATABLES = function(item,classes)
	setmetatable(item, { 
		__index = function (t, k)
			local v = LR_METATABLESEARCH(k,classes);
			t[k] = v;
			return v;
		end
	});
end
LR_ISVALIDDATE = function(str)
	local sanitizedStr,_ = gsub(str,"%D","/");
	local m, d, y = strmatch(sanitizedStr,"(%a+) (%d+), (%d+)");
	if not not m and not not d and not not y then
		if y < 2004 then y = y + 2000; end
		local months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" };
		for idx,val in ipairs(months) do
			if m == val then m = idx; break; end
		end
		return true, time({ year = y, month = m, day = d, hour = 0 });
	else
		return false, nil;
	end
end
LR_ONUPDATE = function(self,elapsed)
	if not LR.InCombat then 
		local totalTime = LR_Waiter.TotalTime + elapsed;
		LR_Waiter.TotalTime = totalTime;
		local timeoutFunctions = LR_Waiter.TimeoutFunctions;
		for k,v in pairs(timeoutFunctions) do
			if totalTime >= v.ExecuteTime then 
				v:Execute();
				LR_Waiter.TimeoutFunctions[k] = nil;
			end
		end
		timeoutFunctions = nil;
		local intervalFuntions = LR_Waiter.IntervalFunctions;
		for k,v in pairs(intervalFunctions) do
			if totalTime >= v.ExecuteTime then 
				v:Execute();
				LR_Waiter.IntervalFunctions[k] = v.ExecuteTime + v.Interval;
			end
		end
	end
end

function LiveRoster.addFunctions(self)

	self.TrySaveRosterItem = function(self,collectionName,item) -- Attempts to save the roster item.  It will return true if the item successfully saves.  It will return false if the item does not save.  If the item fails to save because the record is out of date, then the newer record will be returned so it can be sent back to the source.
		local main = item.MainName;
		if not not main then
			local storedItem = self[collectionName][main]
			if not not storedItem then
				local state = self.CheckRecency(item,storedItem);
				if state == 1 then
					for k,v in pairs(item) do
						storedItem[k] = v;
					end
					return true;
				elseif state == -1 then
					return false,storedItem;
				end
			else
				self[collectionName][main] = item;
				return true;
			end
		else
			return false,nil;
		end
	end;
	self.ParseMessageToRosterItem = function(self,rosterType,message) -- Converts a message to a roster item.
		local me = {};
		local data = substr(message,2);
		local dataItemSeparator = self.Communication.DataItemSeparator;
		local keyValueSeparator = self.Communication.KeyValueSeparator;
		local splitData = split(data,dataItemSeparator);
		local mapper = self.Roster.Mappers[rosterType];
		for d in splitData do
			local dataItem = split(splitData,keyValueSeparator);
			local mappedKey = mapper[dataItem[1]];
			me[mappedKey] = dataItem[2];
		end
		return me;
	end;
	self.ParseRosterItemToMessage = function(self,collectionName,item) -- Converts a roster item to a message data stream.
		local me = "";
		local dataItemSeparator = self.Communication.DataItemSeparator;
		local keyValueSeparator = self.Communication.KeyValueSeparator;
		local mapper = self.Roster.Mappers["Inverted"..collectionName];
		for k,v in pairs(item) do
			local mappedKey = mapper[k];
			if me ~= "" then
				me = me..dataItemSeparator;
			end
			me = me..mappedKey..keyValueSeparator..v;
		end
		return me;
	end
	self.ValidateInternalStorage = function(self) -- Validates internal storage of local guild members, dumping all records of players that no longer appear in the roster.
		local x = true;
	end;
	self.BeginVersionCheck = function(self) -- Checks version upon login.
		SendAddonMessage(self.Communication.Prefix,self.Communication.Mappers.InvertedMessageKeys["VersionCheck"]..LR_VERSION,"GUILD");
	end
	self.HandleIncomingVersionCheck = function(self,sender,version) -- Responds to VersionCheck.
		SendAddonMessage(self.Communication.Prefix,self.Communication.Mappers.InvertedMessageKeys["VersionCheckResponse"]..LR_VERSION,"WHISPER",sender);
		self.CheckVersionAgainstIncoming(version);
	end
	self.HandleVersionCheckResponse = function(self,sender,version,minimumVersion) -- Handles responses to a VersionCheck.
		self.CheckVersionAgainstIncoming(version,minimumVersion);
		table.insert(self.LiveRosterPenetration.CharactersWithLiveRoster,sender);
	end
	self.CheckVersionAgainstIncoming = function(self,version,minimumVersion) -- Checks local version against incoming versions.
		if self.LatestVersionSeen < version and LR_VERSION < version then
			self.LatestVersionSeen = version;
			self.LogMessage("Your version of LiveRoster is out of date.  Please update to version "..version..".");
			if LR_VERSION < minimumVersion then
				self.LogMessage("Your version of LiveRoster predates the minimum supported version.  Communication has been disabled.  Please update LiveRoster as soon as possible.");
				self.CommunicationEnabled = false;
			end
		end
	end
	self.LogMessage = function(self,message)  -- Logs a message to the default chat frame.
		DEFAULT_CHAT_FRAME:AddMessage(self.Logging.DisplayLogPrefix..message); 
	end
	self.GetFilteredRoster = function(self,filterObject,sortObject) -- Returns the filtered and sorted roster to the UI.
		-- FilterObject: { Name:"", Death Knight: true, Demon Hunter: true, Druid: true, Hunter: true, Mage: true, Monk: true, Paladin: true, Priest: true
		--				, Rogue: true, Shaman: true, Warlock: true, Warrior: true, Tank: true, Melee: true, Ranged: true, Healer: true
		--				, Item Level: 900, Mythic Plus: 13, Raid Kills: 7, AOTC: true, Cutting Edge: true }
		local containsName = filterObject["Name"];
		local isTank = not not filterObject["Tank"];
		local isMelee = not not filterObject["Melee"];
		local isRanged = not not filterObject["Ranged"];
		local isHealer = not not filterObject["Healer"];
		local minItemLevel = filterObject["Item Level"];
		local mythicPlus = filterObject["Mythic Plus"];
		local raidProgression = filterObject["Raid Kills"];
		local hasAOTC = not not filterObject["AOTC"];
		local hasCE = not not filterObject["Cutting Edge"];
		local localsort = table.sort;
		for k,v in pairs(self.Roster.RosterFrameData) do
			if self:FilterRosterItem(v,containsName,filterObject,isTank,isMelee,isRanged,isHealer,minItemLevel,mythicPlus,raidProgression,hasAOTC,hasCE) then 
				localInsert(output,result);
			end
		end
		self.SortObject = sortObject or {};
		return localsort(output,LR_ROSTERSORT);
	end
	self.FilterRosterItem = function(self,rosterDataItem,filterObject,name,isTank,isMelee,isRanged,isHealer,minItemLevel,mythicPlus,raidProgression,hasAOTC,hasCE)  -- Compares the roster item to the filter parameters to determine if the roster item should be passed back to the UI.
		local output = {};
		local localInsert = table.insert;
		local localFind = string.find;	
		local class = rosterDataItem["Class"];
		minItemLevel = minItemLevel or 0;
		if not filterObject[class] then return false;
		elseif (not isHealer and not isTank and not isMelee and not isRanged) then return false;
		elseif not self:ValidateRoleAndILvl(isTank,isHealer,isRanged,isMelee,rosterDataItem,minItemLevel) then return false;
		elseif not not mythicPlus and self:GetHighestMythicPlusCompleted(rosterDataItem) < mythicPlus then return false;
		elseif not not raidProgression and self:GetLatestRaidTierKills(rosterDataItem,raidProgression.Difficulty) < raidProgression.Progress then return false;
		elseif not not hasAOTC and not rosterDataItem.RaidProgress[self.LatestRaid].AOTC then return false;
		elseif not not hasCE and not rosterDataItem.RaidProgress[self.LatestRaid].CuttingEdge then return false;
		elseif not not name and not localFind(rosterDataItem["ShortName"],name) then return false;
		else return true;
		end
	end
	
	self.HandleCombatEnd = function(self)
		self.CommunicationEnabled == true;
		if not not self.CombatEncounter then
			local encounter = self.CombatEncounter;
			local zone = self.Zone;
			if zone.Type == "Raid" then
				local newBossKill = not self.RaidProgression[zone.Name][zone.Difficulty][encounter.Name];
				if newBossKill then
					local record = {
						Originated = time(),
						zoneName = zone.Name,
						Difficulty = zone.Difficulty,
						BossName = encounter.Name
					}
					SendAddonMessage(self.Communication.Prefix,self.Communication.Mappers.InvertedMessageKeys["RaidProgressRecord"]..self:ParseObjectToMessage(self.Roster.Mappers["RaidProgressRecord"]),"GUILD")
				end
			elseif zone.Type == "Dungeon" then

			elseif zone.Type == "PvP" then
			
			else

			end
		end
		self.CombatEncounter = nil;
	end
	self.HandleCombatStart = function(self)
		local ecnounters = self.Zone.Encounters;
		self.CommunicationEnabled == false;
		if self.Zone.Type ~= "PvP" then
			local boss = UnitName("boss1");
			local encounter = encounters[UnitName("boss1") or "NO_UNIT"];
			if not boss then
				for index,value in ipairs(self.GroupRoster) do
					local targetName = UnitName(value.Name);
					encounter = encounters[UnitName(value.Name) or "NO_UNIT"];
					if not not encounter then break;
				end
			end
			if not not encounter then self.CombatEncounter = encounter; end
		end
	end
	self.HandleMessage = function(self,messageKey,sender,message,channel)
		local msg = LiveRoster_InboundMessage(messageKey,message,channel,sender or {});
		msg.SaveOrRespond();
	end
	self.AddToPendingMessages = function(messageKey,sender,message,channel)
		self.PendingMessages = self.PendingMessages or {};
		self.PendingMessages[#self.PendingMessages+1] = { Key = messageKey, Sender = sender, Message = message, Channel = channel };
	end
	self.HandlePendingMessages = function()
		for index,value in ipairs(self.PendingMessages) do
			self:HandleMessage(value.Key,value.Sender,value.Message,value.Channel);
		end
	end
end

LiveRoster = {
	New = function(self,savedSelf)
		local me = {};
		LR_SETMETATABLES(me,{ LiveRoster });
		me.Version = LR_VERSION;
		me.LatestVersionSeen = 0;
		return me;
	end
	Version = 0,
	LatestVersionSeen = 0,
};

LiveRoster_Logger = {
	AddOn = "";	
	New = function(self,context)
		local me = {};
		LR_SETMETATABLES(me,{ LiveRoster_Logger });
		me.AddOn = "\124cFFFF0000Live Roster\124r";
		return me;
	end
	Inform = function(self,message)
		if LiRos.Settings.Debug.Inform then
			DEFAULT_CHAT_FRAME:AddMessage(self.Addon..":"..message); 
		end
	end
	Log = function(self,message)
		if LiRos.Settings.Debug.Log then
			DEFAULT_CHAT_FRAME:AddMessage(self.Addon..":"..message);
		end
	end
	Warn = function(self,message)
		if LiRos.Settings.Debug.Warn then
			DEFAULT_CHAT_FRAME:AddMessage(self.Addon..":"..message);
		end
	end
	Error = function(self,message)
		if LiRos.Settings.Debug.Error then
			DEFAULT_CHAT_FRAME:AddMessage(self.Addon..":"..message);
		end
	end
}

LiveRoster_Roster = {
	IndexCollection = { -- Name <-> Index Relationship for currently open roster frame.  Rebuilt every time the roster is opened.
	},
	CharacterData = { -- Data that should reasonably never change.  Check for new entries when the player logs on.  The records are automatically rebuilt once per month, and can be manually rebuilt using a FullGuildSyncRequest.  
	},
	CharacterData2 = { -- Data that should rarely change, or that may change frequently until it reaches a cap (Level, Reputation, etc).  The records are automatically rebuilt every time the player logs in.
	},
	GuildRosterRecord = { -- Guild Roster Data that changes frequently.  The records are updated every hour while the player is not in combat, or when the player logs in.
	},
	SpecInformation = { -- Data about a character's spec-specific item level.  The records are updated every time the player logs in.
	},
	RaidProgress = { -- Data about a character's raid progress.  The records are updated every time the player logs in.  Addon users will broadcast a record update when they down a new raid boss.
	},
	DungeonProgress = { -- Data about a character's Mythic Plus Dungeon Progress.  The records are updated every time the player logs in. Addon users will broadcast a record update when they achieve a new personal best.
	},
	BattlegroundProgress = { -- Data about a character's Battleground and RatedBattleground statistics.  These records are updated every time the player logs in.  Addon users will broakdcast a record update when they achieve a new personal best.	
	},
	ArenaProgress = { -- Data about a character's Arena and Rated Arena statistics.  These records are updated every time the player logs in.  Addon users will broakdcast a record update when they achieve a new personal best.	
	},
	PlayerAlternateCharacters = { -- A list of alternate characters for each main character.  These records are rebuilt whenever the associated CharacterData record is rebuilt.  Addon users will broadcast an update when they join a guild linked with the guild another one of their characters is in.
	},
	New = function(self,savedSelf)
		local me = savedSelf or {};
		LR_SETMETATABLES(me, { LiveRoster_Roster });
		return me;
	end
	Build = function(self)

	end
	GetCharacterDetail = function(self,name)

	end
	GetServerDataByName = function(self,name)

	end
	GetServerDataByIndex = function(self,index)
		local fullName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, reputation = GetGuildRosterInfo(index);
		local character = LiveRoster_Character:New({ 
			FullName: fullname, 
			Class = class, 
			ShortName = Ambiguate(fullname,"short"),
			GuildContextName = Ambiguate(fullname,"guild"),
		});
		local character2 = LiveRoster_Character2:New({
			FullName = fullname,
			GuildName = LR.GuildName,
			Rank = rank,
			RankIndex = rankIndex,
			Level = level,
			CanSoR = canSoR,
			Reputation = reputation,
			AchievementPoints = achievementPoints,
			IsAlternateCharacter = 
			MainName = 
		})

	end
	ParseGuildNote = function(self,note)
		local noteArray = strsplit(note, " ");
		local isAlt = "";
		local mainName = "";
		local joinDate = "";
		local invitedBy = "";
		if noteArray[1] == "Main" then -- Main Zatenkein 10-1-2017, Main 10-1-2017 Zatenkein
			
		elseif noteArray[1] == "Alt" then -- Alt Zatenkein

		elseif noteArray[2] == "Alt" -- Zatenkein Alt

		elseif 
		end
	end
	BeginGetServerGuildData = function(self)
		LR_Events:Register("GUILD_ROSTER_UPDATE",self:DoGetServerGuildData());
		GuildRoster();
	end
	DoGetServerGuildData = function(self)
		local guildSize = GetNumGuildMembers();
		for i = 1, guildSize do
			local character,character2,guildCharacter = self:GetServerDataByIndex(i);
		end
	end
}
LiveRoster_RosterItem = {
	Type = "",
	FullName = "",
	Originated = 0,
	Save = function(self)
		if self.Type then
			local roster = LiRos.Roster[self.Type];
			local existingItem = roster[self.FullName] or {};
			if not existingItem.Originated or existingItem.Originated =< self.Originated then
				for k,v in pairs(self) do
					if type(v) ~= function then
						existingItem[k] = v;
					end
				end	
				LiRos.Roster[self.Type][self.FullName] = existingItem;
				return true;
			else
				local content = {};
				for k,v in pairs(self) do
					if type(v) ~= function then
						content[k] = v;
					end
				end
				return false,content;
			end
		end
	end
	New = function(self,values)
		local me = values or {};
		setmetatable(me,self);
		self.__index = self;
		return me;
	end
}
LiveRoster_Character = {
	New = function(self,values)
		local me = values or {};
		LR_SETMETATABLES(me,LiveRoster_CharacterData, LiveRoster_RosterItem);
		me.Type = "Character";
		me.Originated = time();
		return me;
	end
	ShortName = "",
	GuildContextName = "",
	Class = "",
	InvitedBy = "",
	JoinDate = ""
}
LiveRoster_Character2 = {
	New = function(self,values)
		local me = values or {};
		LR_SETMETATABLES(me,LiveRoster_Character2, LiveRoster_RosterItem);
		me.Type = "Character2";
		return me;
	end
	GuildName = "",
	Rank = "",
	RankIndex = 16,
	Level = 1,
	CanSoR = false,
	Reputation = 0,
	AchievementPoints = 0,
	IsAlternateCharacter = false,
	MainName = "",
	Originated = 0
}
LiveRoster_GuildCharacter = {
	New = function(self,values)
		local me = values or {};
		LR_SETMETATABLES(me,LiveRoster_GuildCharacter, LiveRoster_RosterItem);
		me.Type = "GuildCharacter";
		return me;
	end
	Zone = "",
	Note = "",
	OfficerNote = "",
	Online = 0,
	Status = "",
	IsMobile = false,
	Originated = 0
}
LiveRoster_CharacterSpecializations = {
	New = function(self,values,class)
		local me = values or {};
		LR_SETMETATABLES(me,{LiveRoster_CharacterSpecializations, LiveRoster_RosterItem});
		if not values and not not class then
			local specs = LR_CLasses[class].Specializations;
			for idx,val in ipairs(specs)
				me["Specialization"..idx] = LiveRoster_Specialization:New({ Name = val.Name, Role = val.Role, ItemLevel = -1, PrimaryStat = val.PrimaryStat });
				if idx > me.SpecializationCount then me.SpecializationCount = idx;
			end
		end
		return me;
	end
	Specialization1 = {},
	Specialization2 = {},
	Specialization3 = {},
	Specialization4 = {},
	SpecializationCount = 0,
	GetMaxItemLevel = function(self,role)
		local s1 = self.Specialization1;
		local s2 = self.Specialziation2;
		local s3 = self.Specialization3;
		local s4 = self.Specialization4;
		if not role then
			return math.max(s1.ItemLevel or 0, s2.ItemLevel or 0, s3.ItemLevel or 0, s4.ItemLevel or 0);
		else
			local maxILvl = 0;
			if s1.Role == role and s1.ItemLevel > maxIlvl then maxIlvl = s1.ItemLevel; end
			if s2.Role == role and s2.ItemLevel > maxIlvl then maxIlvl = s2.ItemLevel; end
			if s3.Role == role and s3.ItemLevel > maxIlvl then maxIlvl = s3.ItemLevel; end
			if s4.Role == role and s4.ItemLevel > maxIlvl then maxIlvl = s4.ItemLevel; end
			return maxIlvl;
		end
	end
}
LiveRoster_Specialization = {
	ItemLevel = 0,
	Name = "",
	Role = "",
	PrimaryStat = "",
	New = function(self,values)
		local me = values or {};
		LR_SETMETATABLES(me, { LiveRoster_Specialization });
		return me;
	end
}
LiveRoster_CharacterRaidProgress = {
	New = function(self,values)
		local me = values or {};
		LR_SETMETATABLES(me,{ LiveRoster_CharacterRaidProgress, LiveRoster_RosterItem });
		me.Type = "CharacterRaidProgress";
		return me;
	end
	GetProgress = function(self,raidName,difficulty)
		if not raidName then raidName = LR_Raids.LatestRaid;
		local myRaid = self.Raids[raidName];
		local raid = LR_Raids[raidName];
		if not difficulty then
			if not myRaid then
				return "0/"..raid.NormalBossCount.." N";
			else
				if myRaid.MythicProgress > 0 then
					return myRaid.MythicProgress.."/"..raid.MythicBossCount.." M";
				elseif myRaid.HeroicProgress > 0 then
					return myRaid.HeroicProgress.."/"..raid.HeroicBossCount.." H";
				else
					return myRaid.NormalProgress.."/"..raid.NormalBossCount.." N";
				end
			end
		else
			if not myRaid then 
				return "0/"..raid[difficulty.."BossCount"];
			else
				return myRaid[difficulty.."Progress"].."/"..raid[difficulty.."BossCount"];
			end
		end
	end
	Raids = {},
}
LiveRoster_RaidProgress = {
	New = function(self,raid,values)
		local me = values or {};
		LR_SETMETATABLES(me,{ LiveRoster_RaidProgress });
		me.Raid = raid;
		return me;
	end
	Raid = "NoName",
	NormalProgress = 0,
	HeroicProgress = 0,
	MythicProgress = 0,
	AOTC = false,
	CE = false	
}
LiveRoster_CharacterDungeonProgress = {
	New = function(self,dungeon,values)
		local me = values or {};
		LR_SETMETATABLES(me, { LiveRoster_CharacterDungeonProgress });
		me.Dungeon = dungeon;
	end
	Dungeon = "NoName",
	HighestKeystone = 0
}

LiveRoster_CharacterBattlegroundProgress = {
	New = function(self,battleground,values)
		local me = values or {};
		LR_SETMETATABLES(me, { LIveRoster_CharacterBattlegroundProgress })
		me.Battleground = battleground;
	end
	Battleground = "NoName",

}
LiveRoster_CharacterArenaProgress = {}

LiveRoster_Communication = {
	New = function(self,savedSelf)
		local me = savedSelf or {};
		LR_SETMETATABLES(me, { LiveRoster_Communication } )
		me.Mappers = {
			InboundMessageKeys = {
				a = "CharacterRequest",
				A = "Character",
				b = "Character2Request",
				B = "Character2",
				c = "GuildCharacterRequest",
				C = "GuildCharacter",
				d = "CharacterSpecializationsRequest",
				D = "CharacterSpecialization",
				e = "CharacterRaidProgressRequest",
				E = "CharacterRaidProgress",
				f = "CharacterDungeonProgressRequest",
				F = "CharacterDungeonProgress",
				g = "CharacterBattlegroundsProgressRequest",
				G = "CharacterBattlegroundProgress",
				h = "CharacterArenaProgressRequest",
				H = "CharacterArenaProgress",
				i = "GuildSettingsRequest",
				I = "GuildSettings"
			},
			OutboundMessageKeys = {
				CharacterRequest = "a",
				Character = "A",
				Character2Request = "b",
				Character2 = "B",
				GuildCharacterRequest = "c",
				GuildCharacter = "C",
				CharacterSpecializationsRequest = "d",
				CharacterSpecialization = "D",
				CharacterRaidProgressRequest = "e",
				CharacterRaidProgress = "E",
				CharacterDungeonProgressRequest = "f",
				CharacterDungeonProgress = "F",
				CharacterBattlegroundsProgressRequest = "g",
				CharacterBattlegroundProgress = "G",
				CharacterArenaProgressRequest = "h",
				CharacterArenaProgress = "H",
				GuildSettingsRequest = "i",
				GuildSettings = "I"
			},
			OutboundCharacterRequest = {
				FullName = "a"
			},
			InboundCharacterRequest = {
				a = "FullName"
			},
			OutboundCharacter = {
				Originated = "O",
				FullName = "a",
				ShortName = "b",
				GuildContextName = "c",
				Class = "d",
				InvitedBy = "e",
				JoinDate = "f"
			},
			InboundCharacter = {
				O = "Originated",
				a = "FullName",
				b = "ShortName",
				c = "GuildContextName",
				d = "Class",
				e = "InvitedBy",
				f = "JoinDate"
			},
			OutboundCharacter2Request = {
				FullName = "a"
			},
			InboundCharacter2Request = {
				a = "FullName"
			},
			OutboundCharacter2 = {},
			InboundCharacter2 = {},
			OutboundGuildCharacterRequest = {
				FullName = "a"
			},
			InboundGuildCharacterRequest = {
				a = "FullName"
			},
			OutboundGuildCharacter = {},
			InboundGuildCharacter = {},
			OutbooundCharacterSpecializationRequest = {
				FullName = "a",
				SpecializationIndex = "b"
			},
			InboundCharacterSpecializationRequest = {
				a = "FullName",
				b = "SpecializationIndex"
			},
			OutboundCharacterSpecialization = {},
			InboundCharacterSpecialization = {},
			OutboundCharacterRaidProgressRequest = {
				FullName = "a",
				RaidName = "b"
			},
			InboundCharacterRaidProgressRequest = {
				a = "FullName",
				b = "RaidName"
			},
			OutboundCharacterRaidProgress = {
			
			},
			InboundCharacterRaidProgress = {
		
			},
			OutboundCharacterDungeonProgressRequest = {
				FullName = "a",
				DungeonName = "b"
			},
			InboundCharacterDungeonProgressRequest = {
				a = "FullName",
				b = "DungeonName"
			},
			OutboundCharacterDungeonProgress = {
		
			},
			InboundCharacterDungeonProgress = {
		
			},
			OutboundCharacterBattlegroundProgressRequest = {
				FullName = "a",
				BattlegroundName = "b",
				Rated = "c"
			},
			InboundCharacterBattlegroundProgressRequest = {
				a = "FullName",
				b = "BattlegroundName",
				c = "Rated"
			},
			OuboundCharacterBattlegroundProgress = {
			
			}, 
			InboundCharacterBattlegroundProgress = {
			
			}, 
			OutboundCharacterArenaProgressRequest = {
				FullName = "a",
				ArenaName = "b",
				ArenaSize = "c",
				Rated = "d"
			},
			InboundCharacterArenaProgressRequest = {
				a = "FullName",
				b = "ArenaName",
				c = "ArenaSize",
				d = "Rated"
			},
			OutboundCharacterArenaProgress = {
		
			},
			InboundCharacterArenaProgress = {
		
			},
			OutboundGuildSettingsRequest = {
				GuildName = "a",
			},
			InboundGuildSettingsRequest = {
				a = "GuildName",
			},
			OutboundGuildSettings = {
		
			},
			InboundGuildSettings = {
		
			}
		},
		me.Prefix = "LIVEROSTER",
		me.DataItemSeparator = ";",
		me.TimeOutDuration = 5;
	    return me;
	end
}
LiveRoster_OutboundMessage = {
	Type = "",
	Content = {},
	New = function(self,type,content)
		local me = { Type = type, Content = content };
		local comm = LiRos.Communication;
		LR_SETMETATABLES(me,{ LiveRoster_OutboundMessage });
		local key = comm.OutboundMessageKeys[type];
		local mapper = comm.Mappers[mapperKey];
		local dataSeparator = comm.DataSeparator;
		local valueSeparator = comm.ValueSeparator;
		local message = key;
		for k,v in pairs(content) do
			if message ~= key then
				message = message..dataSeparator;
			end
			message = message..mapper[k]..valueSeparator..v;
		end
		return me;
	end
	SendToGuild = function(self)
		SendAddonMessage(LiRos.Communication.Prefix,self.Message,"GUILD");
	end
	Whisper = function(self,target)
		SendAddonMessage(LiRos.Communication.Prefix,self.Message,"WHISPER",target);
	end
}
LiveRoster_InboundMessage = {
	Type = "",
	Content = {},
	Sender = "",
	Channel = "",
	New = function(self,key,message,channel,sender)
		local me = { Channel = channel, Sender = sender };
		local comm = LiRos.Communication;
		LR_SETMETATABLES(me, { LiveRoster_InboundMessage });
		me.Type = comm.Mappers.InboundMessageKeys[key];
		local mapper = comm.Mappers[me.Type];
		local content = {};
		local segments = {};
		local dataSeparator = comm.DataItemSeparator;
		local dataArray = strsplit(message,dataSeparator);
		for idx,val in ipairs(dataArray)
			local contentKey = mapper[strsub(val,1,1)];
			content[contentKey] = strsub(val,2);
		end
		me.Content = content;
		return me;
	end
}

LiveRoster_Events = {
	New = function(self,savedSelf)
		local me = {};
		LR_SETMETATABLES(me, { LiveRoster_Events });
		return me;
	end
	OnEvent = function(self,event,...)
		local self.EventHandlers = handlers;
		for k,v in pairs(handlers) do
			if event == k then v(...);
		end
	end
	RegisterEvents = function(self)
		local self.EventHandlers = handlers;
		local myFrame = CreateFrame("LR_EVENTFRAME");
		for k,v in pairs(handlers) do
			myFrame:RegisterEvent(k);
		end
	end
	EventHandlers = {
		PLAYER_REGEN_ENABLED = function(eventArgs)
			LR.InCombat = false;
			LR_Communication:HandlePendingMessages();
		end,
		PLAYER_REGEN_DISABLED = function(eventArgs)
			LR.InCombat = true;
		end,
		CHAT_MSG_ADDON = function(eventArgs)
			local message = select(2,eventArgs);
			local channel = select(3,eventArgs);
			local sender = select (4,eventArgs);
			local messageKey = strsub(message,1,1);
			message = strsub(message,2);
			if not not LR.InCombat then 
				LR_Communication:HandleMessage(messageKey,sender,message,channel);
			else
				LR_Communication:AddToPendingMessages(messageKey,sender,message,channel);
			end
		end,
		GROUP_ROSTER_UPDATE = function(eventArgs)
			LR_Roster:BuildGroupRoster();
			if IsInGroup() then
				LR_Inspector:TryBeginGroupInspection();
			else
				LR_Inspector:EndGroupInspection();
			end
		end,
		INSPECT_READY = function(eventArgs)
			LR_Inspector:BeginInspection();
		end
	}
}

LiveRoster_Inspector = {
	New = function(self)
		local me = {};
		LR_SETMETATABLES(me, { LiveRoster_Inspector });
		return me;
	end
	FindNextGroupMember = function(self,startIndex)
		startIndex = startIndex or 0;
		for idx,val in ipairs(LR_Roster.GroupRoster) do
			if idx >= startIndex then
				local inspection = self.InspectionHistory[val.FullName];
				if LR.HasAddon(val.FullName) and (not inspection or inspection.Timestamp < (time() - 1800)) then
					return val.FullName, idx;
				end
			end
		end
		return nil,0;
	end
	TryBeginGroupInspection = function(self)
		if not self.InspectionRunning then 
			self:BeginGroupInspection();
		end
	end
	EndGroupInspection = function(self)
		self.InspectionRunning = false;
	end
	BeginGroupInspection = function(self)
		local igKey = "INSPECT_GROUP";
		self.InspectionRunning = true;
		LR_Waiter:RegisterInterval(10
		,function(self,me,key,startIndex,attempts)
			if not me.InspectPending then
				local inspectTarget = '';
				local attempts = attempts or 0;
				local startIndex = startIndex or 0;
				inspectTarget, startIndex = me:FindNextGroupMember(startIndex);
				if not CanInspect(inspectTarget, false) then
					if attempts >= 9 then
						attempts = 0;
						startIndex = startIndex + 1;
					else
						attempts = attempts + 1;
					end
				else
					NotifyInspect(inspectTarget);
					me.InspectPending = true;
					me.InspectTarget = inspectTarget;
				end
				LR_Waiter.IntervalFunctions[key].CallbackArgs = { me, key, startIndex, attempts };
			end
		end
		,{ self, igKey, 0, 0 }
		,igKey)
	end,
	BeginInspection = function(self)
		local target = self:InspectTarget;
		LR_Waiter:RegisterTimeout(1,function(self,me,target)
			
		end,
		{ self, target },
		"DUNGEON_INSPECT");
		LR_Watier:RegisterTimeout(3,function(self,me,target) 
		
		end,
		{ self, target },
		"RAID_INSPECT");
		LR_Waiter:RegisterTimeout(5,function(self,me,target)

		end,
		{ self, target },
		"BATTLEGROUND_INSPECT");
		LR_Waiter:RegisterTimeout(7,function(self,me,target)

		end,
		{ self, target },
		"2V2_INSPECT");
		LR_Waiter:RegisterTimeout(9,function(self,me,target)

		end,
		{ self, target },
		"3V3_INSPECT");
	end,
	InspectPending = false,
	InspectTarget = ""
}

LiveRoster_Waiter = {
	New = function(self)
		local me = {};
		LR_SETMETATABLES(me, { LiveRoster_Waiter });
		me.TotalTime = 0;
		me.__FRAME = CreateFrame("LiveRoster_WaitFrame");
		me.__FRAME:SetScript("OnUpdate",LR_ONUPDATE);
		return me;
	end
	__FRAME = {}
	TotalTime = 0;
	RegisterTimeout = function(self,seconds,callback,callbackArgs,key)
		self.TimeoutFunctions[key] = {
			Exeecute = function(self)
				self.Callback(select(1,self.CallbackArgs));
			end,
			Key = key,
			Callback = callback,
			CallbackArgs = callbackArgs,
			ExecuteTime = self.TimeElapsed + seconds
		}
	end
	RegisterInterval = function(self,seconds,callback,callbackArgs,key)
		self.IntervalFunctions[key] = {
			Exeecute = function(self)
				self.Callback(select(1,self.CallbackArgs));
			end,
			Key = key,
			Callback = callback,
			CallbackArgs = callbackArgs,
			ExecuteTime = self.TimeElapsed + seconds,
			ExecuteInterval = seconds
		}
	end
	IntervalFunctions = {};
	TimeoutFunctions = {};
	RemoveTimeout = function(self,key)
		self.TimeoutFunctions[key] = nil;
	end
	RemoveInterval = function(self,key)
		self.IntervalFunctions[key] = nil;
	end
}

LR = LiveRoster:New(LR or nil); -- Manages versioning and addon settings.
LR_Logger = LiveRoster_Logger:New(); -- Manages logging messages to user and error handling.
LR_Communication = LiveRoster_Communiction:New(); -- Manages addon communication.
LR_Roster = LiveRoster_Roster:New(LR_Roster or nil); -- Manages roster information and storing data.
LR_Classes = LiveRoster_ClassCollection:New(); -- Library of class, role, and spec information.
LR_Dungeons = LiveRoster_DungeonCollection:New(); -- Library of dungeons.
LR_Raids = LiveRoster_RaidsCollection:New(); -- Library of raids.
LR_Battlegrounds = LiveRoster_BattlegroundCollections:New(); -- Library of Battlegrounds.
LR_Arenas = LiveRoster_ArenaCollection:New(); -- Library of Arenas.
LR_Events = LiveRoster_Events:New(); -- Manages event-driven addon behavior.
LR_Inspector = LiveRoster_Inspector:New(); -- Handles inspection of nearby players.
LR_Waiter = LiveRoster_Waiter:New() -- Handles wait and delay timers.

LR_Events:RegisterEvents();