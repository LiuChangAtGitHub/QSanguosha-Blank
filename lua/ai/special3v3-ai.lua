sgs.ai_skill_choice["3v3_direction"] = function(self, choices, data)
	local card = data:toCard()
	local aggressive = (card and card:isKindOf("AOE"))
	if self:isFriend(self.player:getNextAlive()) == aggressive then return "cw" else return "ccw" end
end