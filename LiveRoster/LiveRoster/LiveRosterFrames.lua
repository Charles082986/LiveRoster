StaticPopupDialogs["LR_SMART_ADD_GUILDMEMBER"] = {
	text = ADD_GUILDMEMBER_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	autoCompleteParams = AUTOCOMPLETE_LIST.GUILD_INVITE,
	maxLetters = 77,
	OnAccept = function(self)
		local player = self.editBox:GetText();
		local sName, sServer = string.split("-", player)
		if not sServer then player = sName.."-"..string.gsub(LRServer, " ", "") end
		 --Queue up either an alt invite or main invite depending.
		if LiveRoster_InvitedAltMain then
			LiveRoster_InvitedAlt=player;
		else
			LiveRoster_InvitedToon=player;
		end
		LRE("Added: "..LiveRoster_InvitedToon);
		C_Timer.After(3, function() LR_SystemMsg(LiveRoster_InvitedToon.." has joined the guild."); end);
		GuildInvite(self.editBox:GetText());
	end,
	OnShow = function(self)
		if LiveRoster_InvitedAltMain then
			self.text:SetText("Add alt for "..LiveRoster_InvitedAltMain);
		else
			self.text:SetText("Add New Main(Select main first to add alt)");
		end
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		GuildInvite(parent.editBox:GetText());
		LiveRoster_InvitedToon = parent.editBox:GetText()
		LRE("Added: "..LiveRoster_InvitedToon);
		C_Timer.After(3, function() LR_SystemMsg(LiveRoster_InvitedToon.." has joined the guild."); end);
		GuildInvite(LiveRoster_InvitedToon);
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["LR_PROMOTION_CONFIRM"] = {
	text = "Set new rank?",--..LiveRoster.Roster[LiveRoster_Selected_PromotionIndex].ShortName.." to the rank of "..GuildControlGetRankName(LiveRoster.Roster.Promotions[LiveRoster_Selected_Promotion].NewRankIndex+1).."?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		-- Queue up either an alt invite or main invite depending.
		SetGuildMemberRank(GetGuildRosterSelection(), LiveRoster.Roster.Promotions[LiveRoster_Selected_Promotion].NewRankIndex+1) --seems to need a +1
		GuildRoster_Update();
		LiveRoster.UpdateRoster();
		C_Timer.After(1,function(self) LiveRoster_NextPromotion(LiveRosterPromotionNext,"LeftButton"); PlaySound("LOOTWINDOWCOINSOUND"); LiveRoster.UpdateRoster(); end);

	end,
	OnShow = function(self)
	self.text:SetText("Promote "..LiveRoster.Roster[GetGuildRosterSelection()].ShortName.." to the rank of "..GuildControlGetRankName(LiveRoster.Roster.Promotions[LiveRoster_Selected_Promotion].NewRankIndex+1).."?");

	end,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1

}

StaticPopupDialogs["LR_ALT_PROMOTION_CONFIRM"] = {
	text = "Set new rank?",--..LiveRoster.Roster[LiveRoster_Selected_PromotionIndex].ShortName.." to the rank of "..GuildControlGetRankName(LiveRoster.Roster.Promotions[LiveRoster_Selected_Promotion].NewRankIndex+1).."?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		-- Queue up either an alt invite or main invite depending.
		SetGuildMemberRank(GetGuildRosterSelection(), LiveRoster.AltPromotions[LiveRoster_Selected_AltPromotion].NewRankIndex+1) --seems to need a +1
		GuildRoster_Update();
		LiveRoster.UpdateRoster();
		C_Timer.After(1,function(self) LiveRoster_AltPromotion(LiveRosterPromotionAlts,"LeftButton"); PlaySound("LOOTWINDOWCOINSOUND") end);
		LiveRoster.AltPromotions = nil;
	end,
	OnShow = function(self)
	self.text:SetText("Promote "..LiveRoster.Roster[GetGuildRosterSelection()].ShortName.." to the rank of "..GuildControlGetRankName(LiveRoster.AltPromotions[LiveRoster_Selected_AltPromotion].NewRankIndex+1).."?");
	end,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}
