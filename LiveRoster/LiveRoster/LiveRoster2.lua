LiveRoster = {};
LR_VERSION = 1;
LR_MINIMUM_VERSION = 1;
function LiveRoster:new()
	local self = {};
	self.Version = 0;
	self.LatestVersionSeen = 0;
	self.Roster = {
		IndexCollection = { -- Collection of names and indexes for the player's local guild.  Updates every time the roster is opened.
		};
		CharacterData = { -- Data that should reasonably never change.  Check for new entries when the player logs on.  The records are automatically rebuilt once per month, and can be manually rebuilt using a FullGuildSyncRequest.
		};
		CharacterData2 = { -- Data that should rarely change, or that may change frequently until it reaches a cap (Level, Reputation, etc).  The records are automatically rebuilt every time the player logs in.
		}
		VolatileCharacterData = { -- Data that changes frequently.  The records are automatically rebuilt every time the roster opens.  While awaiting responses, the character's roster record is bordered in red.
			SpecInfo = {},
			GuildRosterInfo = {}
		};
		PlayerAlternateCharacters = { -- A list of alternate characters for each main character.  These records are rebuilt whenever the associated CharacterData record is rebuilt.
		};
		Mappers = {
			CharacterData = {
				f = "FullName",
				s = "ShortName",
				g = "GuildContextName",
				c = "Class",
				C = "ClassFileName",
				I = "InvitedBy",
				J = "JoinDate",
				O = "Originated"
			},
			InvertedCharacterData = {},
			CharacterData2 = {
				g = "GuildName",
				r = "Rank",
				R = "RankIndex",
				l = "Level",
				s = "CanSoR",
				u = "Reputation",
				A = "AchievementPoints",
				a = "AchievementRank",
				v = "IsAlternateCharacter",
				M = "MainName",
				O = "Originated"
			},
			InvertedCharacterData2 = {},
			GuildRosterRecord = {
				O = "Originated",
				z = "Zone",
				n = "Note",
				o = "OfficerNote",
				a = "Online",
				s = "Status",
				m = "IsMobile"
			},
			SpecInformation = {
				O = "Originated",
				b = "Spec1",
				f = "Spec2",
				g = "Spec3",
				r = "Spec4",	
			},
			InvertedVolatileCharacterData = {},
		},
		RosterFrameData = { -- Amalgamated data from CharacterData, CharacterData2, VolatileCharacterData, and PlayerAlternateCharacters.
			
		},
	};
	self.Classes = {};
	self.Communication = {
		TimeOutDuration = 5; -- The number of seconds to wait for a response before handling the timeout function.
		DataItemSeparator = ";";
		KeyValueSeparator = ",";
		Prefix = "LIVEROSTER";
		Mappers = {
			MessageKeys = {
				a = "CharacterData", -- This message contains a CharacterData object.
				b = "CharacterData2", -- This message contains a CharacterData2 object.
				c = "VolatileCharacterData", -- This message contains a VolatileCharacterData object.
				d = "AlternateCharacters", -- This message contains an alternate character object.
				e = "VersionCheck", -- This message is requesting the current version of the Player's LiveRoster addon.
				f = "SpeakerCheck", -- This message is requesting the current Speaker for the Player's guild.
				g = "SpeakerHandoffRequest", -- This message is requesting the Player's addon take over the role of Speaker.
				h = "CharacterDataRequest", -- This message is requesting the CharacterData object for a given Character.
				i = "CharacterData2Request", -- This message is requesting the CharacterData2 object for a given Character.
				j = "VolatileCharacterDataRequest", -- This message is requesting the VolatileCharacterData object for a given Character.
				k = "FullGuildSyncRequest", -- This message is requesting a full sync of the Player's guild.
				l = "SpeakerHandoffAccept", -- This message is accepting the role of Speaker.
				m = "SpeakerHandoffDecline", -- This message is declining to accept the role of Speaker.
				n = "VersionCheckResponse" -- Response to VersionCheck.
				o = "GuildRosterRecord" -- Contains GuildRosterRecord.
				p = "GuildRosterRecordRequest" -- Requests GuildRosterRecord for a character.
				q = "SpecRecord" -- Contains information about a unit's spec and item level.
				r = "SpecRecordRequest" -- Requests spec data for a unit.
			}
			InvertedMessageKeys = {};
		}
	};
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
	self.GetRosterItemLevel = function(item) -- Gets the highest item level for a character.
		if not item.Spec1 then item.Spec1 = -1; end
		if not item.Spec2 then item.Spec2 = -1; end
		if not item.Spec3 then item.Spec3 = -1; end
		if not item.Spec4 then item.Spec4 = -1; end
		return math.max(item.Spec1,item.Spec2,item.Spec3,item.Spec4);
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
	self.CreateRosterFrameData = function(self,name,characterData,characterData2,volatileCharacterData)
		local specInfo = volatileCharacterData.SpecInformation;
		local rosterData = volatileCharacterData.GuildRosterData;
		local output = {
			Name = name,
			Class = characterData.Class,
			Level = characterData.Level,
			Zone = rosterData.Zone,
			Spec1 = specInfo.Spec1.Value,
			Spec2 = specInfo.Spec2.Value,
			ILvl = self:GetRosterItemLevel(specInfo),
			Tank = self:GetRosterItemLevel(specInfo,"Tank"),
			Healer = self:GetRosterItemLevel(specInfo,"Healer"),
			Melee = self:GetRosterItemLevel(specInfo,"Melee"),
			Ranged = self:GetRosterItemLevel(specInfo,"Ranged"),
			Raid = self:GetLatestRaidTierKills(volatileCharacterData.RaidProgress[self.LatestRaid]),
			RankIndex = characterData2.RankIndex,
			Rank = characterData2.Rank,
			Guild = characterData.Guild
		};
		if not not specInfo.Spec3 then 
			output["Spec3"] = specInfo.Spec3.Value;
			if not not specInfo.Spec3 then 
				output["Spec4"] = specInfo.Spec3.Value; 
			end
		end
		output["M+"] = self:GetHighestMythicPlusCompleted(volatileCharacterData.MythicDungeons);
		return output;
	end
	self.UpdateVolatileRosterFrameData = function(self,rosterFrameData,volatileCharacterData)
		local specInfo = volatileCharacterData.SpecInformation;
		local rosterData = volatileCharacterData.GuildRosterData;
		rosterFrameData.Zone = rosterData.Zone,
		rosterFrameData.Spec1 = specInfo.Spec1.Value,
		rosterFrameData.Spec2 = specInfo.Spec2.Value,
		rosterFrameData.ILvl = self:GetRosterItemLevel(specInfo);
		rosterFrameData.Tank = self:GetRosterItemLevel(specInfo,"Tank");
		rosterFrameData.Healer = self:GetRosterItemLevel(specInfo,"Healer");
		rosterFrameData.Melee = self:GetRosterItemLevel(specInfo,"Melee");
		rosterFrameData.Ranged = self:GetRosterItemLevel(specInfo,"Ranged");
		rosterFrameData.["M+"] = self:GetHighestMythicPlusCompleted(volatileCharacterData.MythicDungeons);
		rosterFrameData.Raid = self:GetLatestRaidTierKills(volatileCharacterData.RaidProgress[self.LatestRaid]);
		return rosterFrameData;
	end
	self.GetDetailedCharacterData = function(self,characterData,characterData2,volatileCharacterData)
		local class = characterData.Class;
		local output = {
			FullName = characterData.FullName,
			Class = class,
			Specs = {},
			RaidProgress = {},
			MythicPlus = {},
			PvP = {},
			PetBattles = {},
			Alts = {}
		};
		for index,value in ipairs(self.Classes[class].Specs) do
			output.Specs[index] = {
				Name = value.Name,
				Role = value.Role,
				SpecIcon = "",
				RoleIcon = "",
				ItemLevel = volatileCharacterData.SpecInformation[index]
			};
		end
		local progress = volaitleCharacterData.RaidProgress;
		for index,value in ipairs(self.Raids) do
			output.RaidProgress[value.Name] = {
				Normal = self:GetRaidKills(progress,value.Name,"Normal").."/"..value.NormalBossCount;
				Heroic = self:GetRaidKills(progress,value.Name,"Heroic").."/"..value.HeroicBossCount;
				Mythic = self:GetRaidKills(progress,value.Name,"Mythic").."/"..value.MythicBossCount;
				HasAOTC = not not progress.AOTC[value.Name];
				HasCE = not not progress.CuttingEdge[value.Name];
			}
		end
		local dungeonProgress = volatileCharacterData.MythicDungeons.DungeonProgress;
		for index,value in ipairs(self.MythicDungeons) do
			if not not dugeonProgress[value.Name] then
				output.MythicDungeons.DungeonProgress[value.Name] = dungeonProgress[value.Name].HighestCompleted;
			else
				output.MythicDungeons.DungeonProgress[value.Name] = 0;
			end
		end
		output.MythicDungeons.Keystone = volatileCharacterData.MythicDungeons.Keystone;
		output.PetBattles["PvP Wins"] = volatileCharacterData.PetBattleInfo.PvPWins;
		output.PetBattles["Pets Collected"] = volatileCharacterData.PetsCollected;
		local pvp = volatileCharacterData.PvPStatistics or {};
		local arenas = {};
		for index,value in ipairs(self.Arenas) do
			local stats = pvp[value.."v"..value];
			local arena = { Wins = 0, Played = 0, WinRatio = "0%" };
			if not not stats then
				arena = { Wins = stats.Wins or 0, Played = stats.Played or 0, WinRatio = "0%" };
				if arena.Played ~= 0 then
					arena.WinRatio = LR_ROUNDING(arena.Wins / arena.Played,2).."%";
				end
			end
			arenas[value.."v"..value] = arena;
		end
		local bgs = {};
		for index,value in ipairs(self.Battlegrounds) do
			local stats = pvp[value];
			local bg = { Wins = 0, Played = 0, WinRatio = "0%" };
			local ratedbg = { Wins = 0, Played = 0, WinRatio = "0%" };
			if not not stats then
				bg = { Wins = stats.Wins, Played = stats.Played, WinRatio = "0%" };
				ratedbg = { Wins = stats.RatedWins, Played = stats.RatedPlayed, WinRatio = "0%" };
				if bg.Played ~= 0 then
					bg.WinRatio = LR_ROUNDING(bg.RatedWins / bg.RatedPlayed,2).."%";
				end
			end
			bgs[value] = bg;
			bgs["Rated "..value] = ratedbg;
		end
		output.PvP = { Arenas = arenas, Battlegrounds = bgs };
		local alts = {};
		local mainName = characterData2.MainName;
		if not characterDat2.IsAlternateCharacter then 
			alts = { self:CreateAltCard(mainName) };
		end
		for index,value in ipairs(self.Roster.CharacterData2[mainName].Alts) do
			table.insert(alts,self:CreateAltCard(value))
		end
		output.Alts = alts;
		return output;
	end
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