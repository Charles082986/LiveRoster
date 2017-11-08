FrameXML_Debug (enable);
LR_USE_SNAPSHOT = 1;
LR_SNAPSHOT_INDEX = {};
LR_ALTGUILD = "Bastions of Twilight";
LR = LiveRoster:create();

LR.RegisterEvents();

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



function LiveRoster_ConvertValuesToNumeric(pairsCollection)
    for k,v in ipairs(pairsCollection) do 
        pairsCollection[k] = tonumber(v);
    end
	return pairsCollection;
end