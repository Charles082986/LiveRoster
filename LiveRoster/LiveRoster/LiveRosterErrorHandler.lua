LiveRosterError = {
    Message = nil,
    Debug = 4,
	Verbose = 0
}

function LiveRosterError:create (errorMessage, debugLevel, isVerbose)
    local lre = {};
    setmetatable (lre, LiveRosterError);
    lre.Message = errorMessage or "UNKNOWN_ERROR_AMG";
	if not not debugLevel then 
        lre.Debug = debugLevel;
    end
    if not not isVerbose then
        lre.Verbose = isVerbose;
    end
	return lre;
end

function LiveRosterError:log()
	if (self.Verbose > 0 and self.Verbose <= LREVERBOSE) or (self.Debug > 0 and self.Debug <= LREDEBUG) or self.Debug == 4 then
		DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000Live Roster Error:\124r"..sError);
	end
end