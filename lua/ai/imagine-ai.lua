--[[
	主题：特定事件模拟
	函数列表：
		SmartAI:ImitateResult_DrawNCards(player, skills, overall)
]]--
--[[
	函数名：ImitateResult_DrawNCards
	功能：模拟指定技能对摸牌阶段摸牌数目的影响
	参数表：
		player：摸牌目标，ServerPlayer类型
		skills：技能列表，表示加以考虑的技能，QList<Skill*>类型
		overall：是否考虑所有指定的技能，取值为：
			true：考虑所有所给技能
			false：仅考虑所给技能中目标实际拥有的技能（默认值）
	返回值：一个数值，表示最终的摸牌数目
	注：神速、巧变、绝境（高达一号）等因属于跳过阶段的情形，这里不加以考虑
]]--
function SmartAI:ImitateResult_DrawNCards(player, skills, overall)
	if not player then
		return 0
	end
	if player:isSkipped(sgs.Player_Draw) then
		return 0
	end
	if not skills or skills:length() == 0 then
		return 2
	end
	return 2
end