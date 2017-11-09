LiveRosterGuildData = {
	Roster = {},
	GuildMasterConfigurationSettings = {},
	ConfigurationSettings = {}
}

function LiveRosterGuildData:create()
	local lrgd = {};
	setmetatable(lrgd,LiveRosterGuildData);
	lrgd.Roster = {};
	lrgd.GuildMasterConfigurationSettings = {};
	lrgd.ConfigurationSettings = {};
	return lrgd;
end

LiveRosterGuildDataRosterItem = {
	Name = nil,
	InvitedBy = nil,
	JoinDate = nil,
	Concurrency_OriginDate = nil
}

function LiveRosterGuildDataRosterItem:create(name,invitedBy,joinDate,concurrency_OriginDate)
	local lrgdri = {};
	setmetatable(lrgdri,LiveRosterGuildDataRosterItem);
	lrgdri.Name = name;
	lrgdri.InvitedBy = invitedBy;
	lrgdri.JoinDate = joinDate;
	lrgdri.Concurrency_OriginDate = concurrency_OriginDate;
	return lgdri;
end

function LiveRosterGuildDataRosterItem:originate(name,inviteBy,joinDate)
	local lrgdri = {};
	setmetatable(lrgdri,LiveRosterGuildDataRosterItem);
	lrgdri.Name = name;
	lrgdri.InvitedBy = invitedBy;
	lrgdri.JoinDate = joinDate;
	lrgdri.Concurrency_OriginDate = time();
	return lgdri;
end

LiveRosterGuildDataGuildMasterConfigurationSettings = {
	GuildMasterSettings = {},
	Concurrency_OriginDate = nil
}

function LiveRosterGuildDataGuildMasterConfigurationSettings:create(liveRosterGuildMasterConfigurationSettings,concurrency_OriginDate)
	local lrgdgmcs = {};
	setmetatable(lrgdgmcs,LiveRosterGuildDataGuildMasterConfigurationSettings);
	lrgdgmcs.GuildMasterSettings = liveRosterGuildMasterConfigurationSettings;
	lrgdgmcs.Concurrency_OriginDate = concurrency_OriginDate;
	return lrgdgmcs;
end

function LiveRosterGuildDataGuildMasterConfigurationSettings:originate(liveRosterGuildMasterConfigurationSettings)
	local lrgdgmcs = {};
	setmetatable(lrgdgmcs,LiveRosterGuildDataGuildMasterConfigurationSettings);
	lrgdgmcs.GuildMasterSettings = liveRosterGuildMasterConfigurationSettings;
	lrgdgmcs.Concurrency_OriginDate = time();
	return lrgdgmcs;
end
