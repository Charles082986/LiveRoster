LiveRoster = {};
LR_VERSION = 1;
LR_MINIMUM_VERSION = 1;

function LiveRoster:new()
	local self = {};
	self.Version = 0;
	self.LatestVersionSeen = 0;
	self.Roster = {

	};
	self.Classes = {};
	self.Communication = {
		TimeOutDuration = 5; -- The number of seconds to wait for a response before handling the timeout function.
		DataItemSeparator = ";";
		KeyValueSeparator = ",";
		Prefix = "LIVEROSTER";
		Mappers = {
			MessageKeys = { --abcdnoqst
				a = "CharacterData", -- This message contains a CharacterData object.
				b = "CharacterData2", -- This message contains a CharacterData2 object.
				c = "VolatileCharacterData", -- This message contains a VolatileCharacterData object.
				d = "AlternateCharacters", -- This message contains an alternate character object.
				e = "VersionCheckRequest", -- This message is requesting the current version of the Player's LiveRoster addon.
				f = "SpeakerCheckRequest", -- This message is requesting the current Speaker for the Player's guild.
				g = "SpeakerHandoffRequest", -- This message is requesting the Player's addon take over the role of Speaker.
				h = "CharacterDataRequest", -- This message is requesting the CharacterData object for a given Character.
				i = "CharacterData2Request", -- This message is requesting the CharacterData2 object for a given Character.
				j = "VolatileCharacterDataRequest", -- This message is requesting the VolatileCharacterData object for a given Character.
				k = "FullGuildSyncRequest", -- This message is requesting a full sync of the Player's guild.
				l = "SpeakerHandoffAccept", -- This message is accepting the role of Speaker.
				m = "SpeakerHandoffDecline", -- This message is declining to accept the role of Speaker.
				n = "VersionCheck" -- Response to VersionCheck.
				o = "GuildRosterRecord" -- Contains GuildRosterRecord.
				p = "GuildRosterRecordRequest" -- Requests GuildRosterRecord for a character.
				q = "SpecRecord" -- Contains information about a unit's spec and item level.
				r = "SpecRecordRequest" -- Requests spec data for a unit.
				s = "MythicPlusDungeonRecord" -- Contains data on a player's progress in a specific Mythic Plus Dungeon.
				r = "MythicPlusDungeonRecordRequest" -- Request for data on a player's progress in a specific Mythic Plus Dungeon.
				t = "RaidProgressRecord" -- Contains data on a player's progress ina  specific Raid.
				u = "RaidProgressRecordRequest" -- Requests data on a player's progress in a specific Raid.
			}
			InvertedMessageKeys = {};
		}
	};
	self.Mappers = {
		
		RaidProgressRecord = {
			O = "Originated",
			i = "InstanceName",
			b = "BossName",
			d = "Difficulty"
		}
	}
	self.Logging = {
		DisplayLogPrefix = "\124cFFFF0000Live Roster:\124r"
	};
	self.LiveRosterPenetration = {
		CharactersWithLiveRoster = {};
	};
	return self;
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
		local dataItemSeparator = self.Communciation.DataItemSeparator;
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
		local dataItemSeparator = self.Communciation.DataItemSeparator;
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
	self.GetRosterItemLevel = function(characterSpecInfo,classObject,role) -- Gets the highest item level for a character.
		local iLvl = 0;
		for specIndex = 1,4 do
			specInfo = characterSpecInfo[specIndex];
			if not specInfo then specInfo = { ItemLevel = -1 }; 
			local specIlvl = specInfo.Ilvl;			
			if not role or (role == classObject.Specs[specIndex].Role) then
				if iLvl < specIlvl then iLvl = specIlvl;
			end
		end
		return iLvl;
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
	self.ValidateRoleAndILvl = function(self,tank,healer,ranged,melee,rosterDataItem,itemLevelFilter) -- Validates role and item level for the filtering function.
		for index,value in ipairs(self.Classes[class].Specs)
			if ((tank and value.Role == "Tank") or (healer and value.Role == "Healer") or (melee and value.Role == "Melee") or (ranged and value.Role == "Ranged")) and rosterDataItem["Spec"..index] >= itemLevelFilter then
					return true;
			end
		end
		return false;
	end
	self.GetHighestMythicPlusCompleted = function(self,mythicDungeonsRecord) -- Returns the highest completed mythic plus dungeon.
		local output = 0;
		for k,v in pairs(mythicDungeonsRecord.DungeonProgress) do
			if output < v then output = v;
		end
		return output;
	end
	self.GetLatestRaidTierKills = function(self,raidProgress,difficulty) -- Returns the number of bosses down in the latest raid tier.
		local output = 0;
		local localLength = table.getn;
		for k,v in pairs(raidProgress)
			if v[difficulty] > 0 then output = output + 1;
		end
		return output;
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
	self.GetDetailedCharacterData = function(self,name)
		local data = self.Roster.CharacterData[name];
		local data2 = self.Roster.CharacterData2[name];
		local guild = self.Roster.GuildRoster[name];
		local raids = self.Roster.RaidProgress[name];
		local dungeons = self.Roster.DungeonProgress[name];
		local arenas = self.Roster.Arenas[name];
		local battlegrounds = self.Roster.Battlegrounds[name];
		local petBattles = self.Roster.PetBattles[name];
		local specs = self.Roster.Specs[name];
		local alts = self.Roster.AlternateCharacters[name];
		local class = data.Class;
		local output = {
			FullName = data.FullName,
			Class = class,
			Specs = {},
			RaidProgress = {},
			MythicPlus = {},
			Arenas = {},
			Battlegrounds = {},
			PetBattles = {},
			Alts = {}
		};
		for index,value in ipairs(self.Classes[class].Specs) do
			output.Specs[index] = {
				Name = value.Name,
				Role = value.Role,
				SpecIcon = "",
				RoleIcon = "",
				ItemLevel = specs[index].Value;
			};
		end
		for index,value in ipairs(self.Raids) do
			raids[value.Name] = {
				Normal = self:GetRaidKills(progress,value.Name,"Normal").."/"..value.NormalBossCount;
				Heroic = self:GetRaidKills(progress,value.Name,"Heroic").."/"..value.HeroicBossCount;
				Mythic = self:GetRaidKills(progress,value.Name,"Mythic").."/"..value.MythicBossCount;
				HasAOTC = not not progress.AOTC[value.Name];
				HasCE = not not progress.CuttingEdge[value.Name];
			}
		end
		for index,value in ipairs(self.MythicDungeons) do
			if not not dungeons[value.Name] then
				output.MythicDungeons.DungeonProgress[value.Name] = dungeonProgress[value.Name].HighestCompleted;
			else
				output.MythicDungeons.DungeonProgress[value.Name] = 0;
			end
		end
		output.MythicDungeons.Keystone = dungeons.Keystone;
		output.PetBattles["PvP Wins"] = petBattles.PvPWins;
		output.PetBattles["Pets Collected"] = petBattles.PetsCollected;
		output.Arenas = {};
		for index,value in ipairs(self.Arenas) do
			local stats = arenas[value];
			local arena = { Wins = 0, Played = 0, WinRatio = "0%" };
			if not not stats then
				arena = { Wins = stats.Wins or 0, Played = stats.Played or 0, WinRatio = "0%" };
				if arena.Played ~= 0 then
					arena.WinRatio = LR_ROUNDING(arena.Wins / arena.Played,2).."%";
				end
			end
			output.Arenas[value] = arena;
		end
		output.Battlegrounds = {};
		output.RatedBattlegrounds = {};
		for index,value in ipairs(self.Battlegrounds) do
			local stats = battlegrounds[value];
			local bg = { Wins = 0, Played = 0, WinRatio = "0%" };
			local ratedbg = { Wins = 0, Played = 0, WinRatio = "0%" };
			if not not stats then
				bg = { Wins = stats.Wins, Played = stats.Played, WinRatio = "0%" };
				ratedbg = { Wins = stats.RatedWins, Played = stats.RatedPlayed, WinRatio = "0%" };
				if bg.Played ~= 0 then
					bg.WinRatio = LR_ROUNDING(bg.RatedWins / bg.RatedPlayed,2).."%";
				end
			end
			output.Battlegrounds[value] = bg;
			output.RatedBattlegrounds[value] = ratedbg;
		end
		local alts = {};
		local mainName = data2.MainName;
		if data2.IsAlternateCharacter then 
			alts = { self:CreateAltCard(mainName) };
		end
		for index,value in ipairs(self.Roster.CharacterData2[mainName].Alts) do
			if value ~= name then
				table.insert(alts,self:CreateAltCard(value));
			end
		end
		output.AltCards = alts;
		return output;
	end
	self.BuildRosterFrameData = function(self) -- Run every time roster is opened.
		local rosterFrameData = {};
		local characterData = self.Roster.CharacterData;
		local characterData2 = self.Roster.CharacterData2;
		local raidProgress = self.Roster.RaidProgress;
		local guildRoster = self.Roster.GuildRoster;
		local dungeonProgress = self.Roster.DungeonProgress;
		local specInformation = self.Roster.SpecInformation;
		local arenas = self.Roster.Arenas;
		local battlegrounds = self.Roster.Battlegrounds;
		local petBattles = self.Roster.PetBattles;
		for k,v in pairs(self.CharacterData) do
			local raid = raidProgress[k] or self:EmptyRaidProgress();
			local data2 = characterData2[k] or self:EmptyCharacterData2();
			local guild = guildRoster[k] or self:EmptyGuildRoster();
			local dungeon = dungeonProgress[k] or self:EmptyDungeonProgress();
			local specs = self:SanitizeSpecInformation(specInformation[k]);
			local arena = arenas[k] or self:EmptyArena();
			local battleground = battleground[k] or self:EmptyBattleground();
			local petBattle = petBattles[k] or self:EmptyPetBattle();
			local output = {
				Name = k,
				Class = v.Class,
				Level = data2.Level,
				Zone = guild.Zone,
				Spec1 = specs.Spec1.Value,
				Spec2 = specs.Spec2.Value,
				ILvl = self:GetRosterItemLevel(specs),
				Tank = self:GetRosterItemLevel(specs,classObject,"Tank"),
				Healer = self:GetRosterItemLevel(specs,classObject,"Healer"),
				Melee = self:GetRosterItemLevel(specs,classObject,"Melee"),
				Ranged = self:GetRosterItemLevel(specs,classObject,"Ranged"),
				Raid = self:GetLatestRaidTierKills(raid[self.LatestRaid]),
				RankIndex = data2.RankIndex,
				Rank = data2.Rank,
				Guild = v.Guild
			};
			if specs.Spec3.Value > -1 then 
				output["Spec3"] = specs.Spec3.Value;
				if specs.Spec4.Value > -1 then 
					output["Spec4"] = specs.Spec4.Value; 
				end
			end
			output["M+"] = self:GetHighestMythicPlusCompleted(dungeonProgress);
			output["2v2"] = self:FormatArenaData("2v2",arena);
			output["3v3"] = self:FormatArenaData("3v3",arena);
			output["5v5"] = self:FormatArenaData("5v5",arena);
			output["BGs"] = self:FormatBattlegroundData("All",battleground);
			output["RBGs"] = self:FormatBattlegroundData("Rated",battleground);
			rosterFrameData[k] = output;
		end
	end
	self.EmptyCharacterData2 = function(self) -- Empty CharacterData2 object for displaying placeholder data on the frame.
	end
	self.BuildGroupRoster = function(self)
		local groupSize = GetNumGroupMembers();
		self.GroupRoster = {};
		for idx = 1,groupSize do
			name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(idx);
			self.GroupRoster[idx] = { Name = name };
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
		local messageType = self.Communication.Mappers.MessageKeys[messageKey];
		local rosterItem = self:ParseMessage(messageType,message);
		local isRoster,_ =  "abcdnoqst":find(messageKey); -- Concatenated string of message keys, checking to see if message key exists.  Faster than loop.
		if not not isRoster then
			local saved,update = self:TrySaveRosterItem(messageType,rosterItem);
			local updateAsMessage = self:ParseRosterItemToMessage(messageType,rosterItem);
			if not saved and not not update then
				if not self.IsSpeaker then
					SendAddonMessage(self.Communication.Prefix,self.Communication.Mappers.InvertedMessageKeys[messageType]..updateAsMessage,"WHISPER",sender);
				else
					SendAddonMessage(self.Communication.Prefix,self.Communication.Mappers.InvertedMessageKeys[messageType]..updateAsMessage,"GUILD");
				end
			end
		else
			isRequest,_ = messageType:find("Request");
			if not not isRequest then
				local rosterType = messageType:sub("Request","");
				local request = self:ParseMessage(messageType,message)
				local responseObject = self.Roster[rosterType][request.Name];
				local responseMessage = self:ParseObjectToMessage(rosterType,responseObject);
				SendAddonMessage(self.Communciation.Prefix,self.Communication.Mappers.InvertedMessageKeys[rosterType]..responseMessage,"WHISPER",sender);
			else
				self:LogMessage(messageType.." has no handler attached.");
			end
		end
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

function LiveRoster.RegisterEvents(self)
	local frame = CreateFrame('LiveRosterFrame_EMPTY');
	frame:RegisterEvent("GROUP_ROSTER_UPDATE");
	frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	frame:RegisterEvent("CHAT_MSG_ADDON")
	frame:SetScript("OnEvent", function(self, event, ...)
		if event == "PLAYER_REGEN_ENABLED" then
			LiRos.InCombat = false;
			LiRos:HandleCombatEnd();
			LiRos:ProcessPendingMessages();
		elseif event == "PLAYER_REGEN_DISABLED" then
			LiRos.InCombat = true;
			LiRos:HandleCombatStart();
		elseif event == "CHAT_MSG_ADDON" then 
			local message = select(2,...);
			local channel = select(3,...);
			local sender = select(4,...);
			local messageKey = string.sub(message,1,1);
			message = string.sub(message,2);
			if not not LiRos.CommunicationEnabled then
				LiRos:HandleMessage(messageKey,sender,message,channel);
			else
				LiRos:AddToPendingMessages(messageKey,sender,message,channel);
			end
		elseif event == "GROUP_ROSTER_UPDATE"
			LiRos:BuildRaidRoster();
		end
	end)
end

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
	PlayerAlternateCharacters = { -- A list of alternate characters for each main character.  These records are rebuilt whenever the associated CharacterData record is rebuilt.  Addon users will broadcast an update when they join a guild linked with the guild another one of their characters is in.
	},
	RosterFrameData = { -- Amalgamated data from CharacterData, CharacterData2, VolatileCharacterData, and PlayerAlternateCharacters.
	},
}
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

LiveRoster_RosterItem = {
	Type = "",
	CharacterName = "",
	Originated = 0,
	Save = function(self)
		if self.Type then
			local roster = LiRos.Roster[self.Type];
			local existingItem = roster[self.CharacterName];
			if existingItem.Originated and existingItem.Originated > self.Originated then
				for k,v in pairs(self)
					if type(v) ~= function then
						existingItem[k] = v;
					end
				end
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
	New = function(self,values)
		local me = values or {};
		LR_SETMETATABLES(me,LiveRoster_CharacterSpecializations, LiveRoster_RosterItem);
		me.Type = "CharacterSpecializations";
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

LiveRoster_CharacterRaidProgress = {
	New = function(self,values)
		local me = values or {};
		LR_SETMETATABLES(me,LiveRoster_Raids, LiveRoster_RosterItem);
		me.Type = "CharacterRaidProgress";
		for k,v in pairs(LiRos.Raids) do
			for a,b in pairs(v) do
				me[k][a] = b;
			end
		end
		return me;
	end
}

LiveRoster_RaidProgress

function LiveRoster.Update(self) -- Insert code here to ensure LiveRoster object settings are updated when new versions are released.
	if self.Version < LR_MINIMUM_VERSION then
		local invertKeys = function(collection)
			local output = {};
			for k,v in pairs(collection) do
				output[v] = k;
			end
			return output;
		end
		self.Communciation.Mappers.InvertedMessageKeys = invertKeys(self.Communication.Mappers.MessageKeys);
		self.Roster.Mappers.InvertedCharacterData = invertKeys(self.Roster.Mappers.CharacterData);
		self.Roster.Mappers.InvertedCharacterData2 = invertKeys(self.Roster.Mappers.CharacterData2);
		self.Roster.Mappers.InvertedGuildRosterRecord = invertKeys(self.Roster.Mappers.GuildRosterRecord);
		self.Roster.Mappers.InvertedSpecInformation = invertKeys(self.Roster.Mappers.SpecInformation);
		local addClass = function(armor, spec1Name,spec1Role,spec1Stat,spec2Name,spec2Role,spec2Stat,spec3Name,spec3Role,spec3Stat,spec4Name,spec4Role,spec4Stat)
			local me = { Armor = armor, Specs = {} };
			me.Specs[1] = { Name = spec1Name, Role = spec1Role, Stat = spec1Stat };
			me.Specs[2] = { Name = spec2Name, Role = spec2Role, Stat = spec2Stat };
			if not not spec3Name then
				me.Specs[3] = { Name = spec3Name, Role = spec3Role, Stat = spec3Stat };
			end
			if not not spec4Name then
				me.Specs[4] = { Name = spec4Name, Role = spec4Role, Stat = spec4Stat };
			end
			return me;
		end
		self.Classes["Death Knight"] = addClass("Plate","Blood","Tank","Strength","Frost","Melee","Strength","Unholy","Melee","Strength");
		self.Classes["Demon Hunter"] = addClass("Leather","Havoc", "Melee", "Agility", "Vengeance","Tank","Agility");
		self.Classes["Druid"] = addClass("Leather","Balance","Ranged","Intellect","Feral","Melee","Agility","Guardian","Tank","Agility","Restoration","Heal","Intellect");
		self.Classes["Hunter"] = addClass("Mail","Beast Mastery","Ranged","Agility","Marksmanship","Ranged","Agility","Survival","Melee","Agility");
		self.Classes["Mage"] = addClass("Cloth","Arcane","Ranged","Intellect","Fire","Ranged","Intellect","Frost","Ranged","Intellect");
		self.Classes["Monk"] = addClass("Leather","Brewmaster","Tank","Agility","Mistweaver","Healer","Intellect","Windwalker","Melee","Agility");
		self.Classes["Paladin"] = addClass("Plate","Holy","Heal","Intellect","Protection","Tank","Strength","Retribution","Melee","Strength");
		self.Classes["Priest"] = addClass("Cloth","Discipline","Heal","Intellect","Holy","Heal","Intellect","Shadow","Ranged","Intellect");
		self.Classes["Rogue"] = addClass("Leather","Assassination","Melee","Agility","Outlaw","Melee","Agility","Subtlety","Melee","Agility");
		self.Classes["Shaman"] = addClass("Mail","Elemental","Ranged","Intellect","Enhancement","Melee","Agility","Restoration","Heal","Intellect");
		self.Classes["Warlock"] = addClass("Cloth","Affliction","Ranged","Intellect","Demonology","Ranged","Intellect","Destruction","Ranged","Intellect");
		self.Classes["Warrior"] = addClass("Plate","Arms","Melee","Strength","Fury","Melee","Strength","Protection","Tank","Strength");
		self.Healers = { "Druid", "Monk", "Paladin","Priest","Shaman"};
		self.Tanks = { "Death Knight", "Demon Hunter", "Druid", "Monk", "Paladin", "Warrior" };
		self.Melee = { "Death Knight", "Demon Hunter", "Druid", "Hunter", "Monk", "Paladin", "Rogue", "Shaman", "Warrior" };
		self.Ranged = { "Druid", "Hunter", "Mage", "Priest", "Shaman", "Warlock"};
		self.MythicPlusDungeons = { "Black Rook Hold", "Cathedral of Eternal Night", "Court of Stars", "Darkheart Thicket", "Eye of Azshara", "Halls of Valor", "Maw of Souls", "Neltharion's Lair", "The Arcway", "Vaul tof the Wardens", "Lower Karazhan", "Upper Karazhan", "Seat of the Triumverate" };
		self.Version = LR_VERSION;
	end
end

LiRos = LiRos or LiveRoster:new();
LiRos:addFunctions();
LiRos:Update();
LiRos.Update = nil;
LiRos.CommunicationEnabled = true;