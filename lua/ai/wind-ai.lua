
sgs.ai_get_cardType = function(card)
	if card:isKindOf("Weapon") then return 1 end
	if card:isKindOf("Armor") then return 2 end
	if card:isKindOf("DefensiveHorse") then return 3 end
	if card:isKindOf("OffensiveHorse")then return 4 end
end

function SmartAI:canLiegong(to, from)
	return false
end

function SmartAI:findLeijiTarget(player, leiji_value, slasher, latest_version)
	return nil
end

function SmartAI:needLeiji(to, from)
	return false
end

function SmartAI:getGuhuoViewCard(class_name, latest_version)
	return nil
end

function SmartAI:getGuhuoCard(class_name, at_play, latest_version)
	return nil
end
