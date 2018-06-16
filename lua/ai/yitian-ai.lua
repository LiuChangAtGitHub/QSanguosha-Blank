--[[
	卡牌：倚天剑
	技能：每当你于回合外受到伤害结算完毕后，你可以使用一张【杀】；当你失去装备区里的【倚天剑】时，你可以对一名其他角色造成【倚天剑】造成的1点伤害。
]]--
sgs.weapon_range.YitianSword = 2
sgs.ai_use_priority.YitianSword = 2.625
--room->askForPlayerChosen(player, room->getAlivePlayers(), "yitian_sword", "@YitianSword-lost", true, true)
sgs.ai_skill_playerchosen["yitian_sword"] = sgs.ai_skill_playerchosen["damage"]
