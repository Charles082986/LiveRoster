LR_KEY = "LRS";
RegisterAddonMessagePrefix(LR_KEY);
LR_TITLE = "\124cFFFF0000Live Roster\124r";
LR_HIGHESTVERSIONSEEN = 0;
LR_VERSIONCHECKKEY = "1";
LR_VERSIONCHECKRESPONSEKEY = "2";
LR_ROSTERITEMKEY = "3";
LR_ROSTERREQUESTKEY = "4";
LR_KEYVALUESEPARATOR = "|";
LR_PROPERTYSEPARATOR = ";";

LR_GUILDVERSIONS = {};

function LiveRoster_RecievedMessageHandler(prefix,message,channel,sender,messageKey,messageHasData,messageData)
	if prefix == LR_KEY and Ambiguate(sender,"GUILD") == LR.MyName then
		if messageKey == LR_VERSIONCHECKKEY and messageHasData then 
			LiveRoster_VersionCheck(sender,messageData);
			SendAddonMessage(LR_KEY,LR_VERSIONCHECKRESPONSEKEY..LR_VERSION,"WHISPER",sender);
		end
		if messageKey == LR_ROSTERITEMKEY and messageHasData then
			LiveRoster_LiveRosterGuildDataRosterItemRecieved(sender,messageData);
		end
	end
end

function LiveRoster_VersionCheck(sender,version)
	LR_GUILDVERSIONS[sender] = version;
	if version > LR_VERSION and version > LR_HIGHESTVERSIONSEEN then
		DEFAULT_CHAT_FRAME:AddMessage(LR_TITLE.." is out of date.");
		LR_HIGHESTVERSIONSEEN = version;
	end
end

function LiveRoster_InitiateVersionCheck(sender,version)
	SendAddonMessage(LR_KEY,LR_VERSIONCHECKKEY..LR_VERSION,"GUILD");
end

function LiveRoster_LiveRosterGuildDataRosterItemRecieved(sender,item)
	local receivedItem = {};
	local storedItem = {};
	for node in split(item,LR_PROPERTYSEPARATOR) do
		local components = split(node,LR_KEYVALUESEPARATOR);
		local rosterItemKey = LiveRoster_RosterItemMapper[components[1]];
		if not rosterItemKey then
			rosterItemKey = components[1];
		end
		receivedItem[rosterItemKey] = components[2];
	end
	if LR_GUILDDATA:ValidateRosterItem(recievedItem) then
		local storedItem = LR_GUILDDATA.GetStoredRosterItem(receivedItem.Name);
		if not storedItem then 			
			LR_GUILDDATA.SaveRosterItem(recievedItem);
			LiveRoster_SendAddonMessage(LR_ROSTERITEMKEY,storedItem,LiveRoster_RosterItemMapper,"WHISPER",sender);
		elseif LiveRoster_CheckReplaceItem(storedItem,recievedItem) then
			LR_GUILDDATA.SaveRosterItem(recievedItem,storedItem);
		end	
	else
		LiveRoster_SendAddonMessage(LR_ROSTERITEMKEY,storedItem,LiveRoster_RosterItemMapper,"WHISPER",sender);
	end
end

function LiveRoster_BuildCommunicationString(item,mapper)
	local responseItemString = nil;
	for k,v in pairs(item) do
		local prop = mapper[k];
		if not prop then prop = k;
		if responseItemString then
			responseItemString = responseItemString..LR_PROPERTYSEPARATOR..prop..LR_KEYVALUESEPARATOR..v;
		else
			responseItemString = prop..LR_KEYVALUESEPARATOR..v;
		end
	end
end

function LiveRoster_SendAddonMessage(key,value,mapper,channel,target)
	local communicationString = LiveRoster_BuildCommunicationString(value,mapper);
	if channel ~= "WHISPER" then 
		SendAddonMessage(LR_KEY,key..communicationString,channel);
	else
		SendAddonMessage(LR_KEY,key..communicationString,channel,target);
	end
end

function LiveRoster_ValidateInteralStorage(collection,mapper)
	local validatedCollection = {};
	for k,v in pairs(collection) do
		local validatedItem = v;
		for a,b in pairs(v) do
			local mappedName = mapper[a];
			if not not mappedName then
				validatedItem[a] = nil;
				validatedItem[mappedName] = b;
			end
		end
		validatedCollection[k] = validatedItem;
	end
	return validatedCollection;
end

LiveRoster_RosterItemMapper = {};
LiveRoster_RosterItemMapper["n"]="Name";
LiveRoster_RosterItemMapper["i"]="InvitedBy";
LiveRoster_RosterItemMapper["j"]="JoinDate";
LiveRoster_RosterItemMapper["C"]="Concurrency_OriginDate";