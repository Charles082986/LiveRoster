LiveRosterSettings = {
	RankColors = {},
	ClassColors = {}
}

function LiveRosterSettings:create()
	lrs = {};
	setmetatable(lrs,LiveRosterSettings);
	lrs.RankColors = {
		"FFFF0000"
		, "FFFF8000"
		, "FFFFD700"
		, "FFFFD700"
		, "FFa335EE"
		, "FF0070DD"
		, "FF1EFF00"
		, "FFFFFFFF"
		, "FF9D9D9D"
	},
	lrs["Death Knight"] = "FFC41F3B";
	lrs["Demon Hunter"] = "FFA335EE";
	lrs["Druid"] = "FFFF7D0A";
	lrs["Hunter"] = "FFABD473";
	lrs["Mage"] = "FF69CCF0";
	lrs["Monk"] = "FF00FF96";
	lrs["Paladin"] = "FFF58CBA";
	lrs["Priest"] = "FFFFFFFF";
	lrs["Rogue"] = "FFFFF569";
	lrs["Shaman"] = "FF0070DE";
	lrs["Warlock"] = "FF9482C9";
	lrs["Warrior"] = "FFC79C6E";
	return lrs;
end