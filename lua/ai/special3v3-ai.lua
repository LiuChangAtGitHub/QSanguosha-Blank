sgs.ai_skill_choice["3v3_direction"] = function(self, choices, data)
	local card = data:toCard()
	local aggressive = (card and card:isKindOf("AOE"))
	if self:isFriend(self.player:getNextAlive()) == aggressive then return "cw" else return "ccw" end
end

sgs.weapon_range.VSCrossbow = sgs.weapon_range.Crossbow
sgs.ai_use_priority.VSCrossbow = sgs.ai_use_priority.Crossbow
