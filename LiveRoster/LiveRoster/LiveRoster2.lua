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
			VolatileCharacterData = {
				z = "Zone",
				n = "Note",
				o = "OfficerNote",
				a = "Online",
				s = "Status",
				m = "IsMobile",
				b = "Spec1",
				f = "Spec2",
				g = "Spec3",
				r = "Spec4",
				i = "Index",
				O = "Originated"
			},
			InvertedVolatileCharacterData = {},
		}
	};
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
		
	end;
	self.BeginVersionCheck = function(self) -- Checks version upon login.
		SendAddonMessage(self.Communication.Prefix,self.Communication.Mappers.InvertedMessageKeys["VersionCheck"]..LR_VERSION,"GUILD");
	end
	self.HandleIncomingVersionCheck = function(self,sender,version) -- Responds to VersionCheck.
		SendAddonMessage(self.Communication.Prefix,self.Communication.Mappers.InvertedMessageKeys["VersionCheckResponse"]..LR_VERSION,"WHISPER",sender);
		self.CheckVersionAgainstIncoming(version);
	end
	self.HandleVersionCheckResponse = function(self,sender,version) -- Handles responses to a VersionCheck.
		self.CheckVersionAgainstIncoming(version);
		table.insert(self.LiveRosterPenetration.CharactersWithLiveRoster,sender);
	end
	self.CheckVersionAgainstIncoming = function(version) -- Checks local version against incoming versions.
		if self.LatestVersionSeen < version and LR_VERSION < version then
			self.LatestVersionSeen = version;
			DEFAULT_CHAT_FRAME:AddMessage(self.Logging.DisplayLogPrefix.." You're version of LiveRoster is out of date.  Please update to the latest version: "..version..".");
		end
	end
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
		self.Roster.Mappers.InvertedVolatileCharacterData = invertKeys(self.Roster.Mappers.VolatileCharacterData);
		self.Version = LR_VERSION;
	end
end

LiRos = LiRos or LiveRoster:new();
LiRos:addFunctions();
LiRos:Update();