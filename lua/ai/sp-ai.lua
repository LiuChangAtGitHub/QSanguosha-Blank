sgs.weapon_range.SPMoonSpear = 3

sgs.ai_skill_playerchosen.sp_moonspear = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and self:damageIsEffective(target) and sgs.isGoodTarget(target, targets, self) then
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sp_moonspear = 80

function SmartAI:getSaveNum(isFriend)
	local num = 0
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if (isFriend and self:isFriend(player)) or (not isFriend and self:isEnemy(player)) then
			if player:objectName() == self.player:objectName() then
				num = num + getCardsNum("Peach", player, self.player)
			end
		end
	end
	return num
end

function getNextJudgeReason(self, player)
	if self:playerGetRound(player) > 2 then
		if player:hasArmorEffect("eight_diagram") then
			if self:playerGetRound(player) > 3 and self:isEnemy(player) then return "EightDiagram"
			else return end
		end
	end
end
