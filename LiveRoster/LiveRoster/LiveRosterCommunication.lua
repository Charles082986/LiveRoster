LR_KEY = "LRS";
RegisterAddonMessagePrefix(LR_KEY);
LR_TITLE = "\124cFFFF0000Live Roster\124r";
LR_HIGHESTVERSIONSEEN = 0;
LR_VERSIONCHECKKEY = "1";
LR_VERSIONCHECKRESPONSEKEY = "2";
LR_ROSTERPUSHKEY = "3";
LR_ROSTERREQUESTKEY = "4";

function LiveRoster_RecievedMessageHandler(prefix,message,channel,sender,messageKey,messageHasData,messageData)
	if prefix == LR_KEY and Ambiguate(sender,"GUILD") == LR.MyName then
		if messageKey == LR_VERSIONCHECKKEY then 
			LiveRoster_VersionCheck(sender,messageData);
			SendAddonMessage(LR_KEY,"VRP:"..LR_VERSION,"WHISPER",sender);
		end
	end
end

function LiveRoster_VersionCheck(sender,version)
	if version > LR_VERSION and version > LR_HIGHESTVERSIONSEEN then
		DEFAULT_CHAT_FRAME:AddMessage(LR_TITLE.." is out of date.");
		LR_HIGHESTVERSIONSEEN = version;
	end
end

function LiveRoster_InitiateVersionCheck(sender,version)
	SendAddonMessage(LR_KEY,LR_VERSION,"GUILD");
end