function SmartAI:canLiegong(to, from)
	return false
end

function SmartAI:cantbeHurt(player, from, damageNum)
	return false
end

function SmartAI:canSaveSelf(player)
	if getCardsNum("Analeptic", player, self.player) > 0 then return true end
	return false
end

function SmartAI:canUseJieyuanDecrease(damage_from, player)
	return false
end

function SmartAI:doNotSave(player)
	if player:hasFlag("AI_doNotSave") then return true end
	return false
end

function SmartAI:findLeijiTarget(player, leiji_value, slasher, latest_version)
	return nil
end

function SmartAI:findLijianTarget(card_name, use)
	local lord = self.room:getLord()
	local duel = sgs.Sanguosha:cloneCard("duel")

	local findFriend_maxSlash = function(self, first)
		self:log("Looking for the friend!")
		local maxSlash = 0
		local friend_maxSlash
		for _, friend in ipairs(self.friends_noself) do
			if friend:isMale() and self:hasTrickEffective(duel, first, friend) then
				if (getCardsNum("Slash", friend) > maxSlash) then
					maxSlash = getCardsNum("Slash", friend)
					friend_maxSlash = friend
				end
			end
		end

		if friend_maxSlash then
			local safe = false
			if (getCardsNum("Slash", friend_maxSlash) >= getCardsNum("Slash", first)) then safe = true end
			if safe then return friend_maxSlash end
		else self:log("unfound")
		end
		return nil
	end

	if self.role == "rebel" or (self.role == "renegade" and sgs.current_mode_players["loyalist"] + 1 > sgs.current_mode_players["rebel"]) then

		if lord and lord:isMale() and not lord:isNude() and lord:objectName() ~= self.player:objectName() then      -- 优先离间1血忠和主
			self:sort(self.enemies, "handcard")
			local e_peaches = 0
			local loyalist

			for _, enemy in ipairs(self.enemies) do
				e_peaches = e_peaches + getCardsNum("Peach", enemy)
				if enemy:getHp() == 1 and self:hasTrickEffective(duel, enemy, lord) and enemy:objectName() ~= lord:objectName()
				and enemy:isMale() and not loyalist then
					loyalist = enemy
					break
				end
			end

			if loyalist and e_peaches < 1 then return loyalist, lord end
		end

		if #self.friends_noself >= 2 and self:getAllPeachNum() < 1 then     --收友方反
			local nextplayerIsEnemy
			local nextp = self.player:getNextAlive()
			for i = 1, self.room:alivePlayerCount() do
				if not self:willSkipPlayPhase(nextp) then
					if not self:isFriend(nextp) then nextplayerIsEnemy = true end
					break
				else
					nextp = nextp:getNextAlive()
				end
			end
			if nextplayerIsEnemy then
				local round = 50
				local to_die, nextfriend
				self:sort(self.enemies, "hp")

				for _, a_friend in ipairs(self.friends_noself) do   -- 目标1：寻找1血友方
					if a_friend:getHp() == 1 and a_friend:isKongcheng() and a_friend:isMale() then
						for _, b_friend in ipairs(self.friends_noself) do       --目标2：寻找位于我之后，离我最近的友方
							if b_friend:objectName() ~= a_friend:objectName() and b_friend:isMale() and self:playerGetRound(b_friend) < round
							and self:hasTrickEffective(duel, a_friend, b_friend) then

								round = self:playerGetRound(b_friend)
								to_die = a_friend
								nextfriend = b_friend

							end
						end
						if to_die and nextfriend then break end
					end
				end

				if to_die and nextfriend then return to_die, nextfriend end
			end
		end
	end

	if not self.player:hasUsed(card_name) then
		self:sort(self.enemies, "defense")
		local males, others = {}, {}
		local first, second

		for _, enemy in ipairs(self.enemies) do
			if enemy:isMale() then
					for _, anotherenemy in ipairs(self.enemies) do
						if anotherenemy:isMale() and anotherenemy:objectName() ~= enemy:objectName() then
							if #males == 0 and self:hasTrickEffective(duel, enemy, anotherenemy) then
								table.insert(males, enemy)
							end
							if #males == 1 and self:hasTrickEffective(duel, males[1], anotherenemy) then
								if not anotherenemy:hasSkills("jizhi") then
									table.insert(males, anotherenemy)
								else
									table.insert(others, anotherenemy)
								end
								if #males >= 2 then break end
							end
						end
					end
				if #males >= 2 then break end
			end
		end

		if #males >= 1 and sgs.ai_role[males[1]:objectName()] == "rebel" and males[1]:getHp() == 1 then
			if lord and self:isFriend(lord) and lord:isMale() and lord:objectName() ~= males[1]:objectName() and self:hasTrickEffective(duel, males[1], lord)
				and not lord:isLocked(duel) and lord:objectName() ~= self.player:objectName() and lord:isAlive()
				and (getCardsNum("Slash", males[1]) < 1
					or getCardsNum("Slash", males[1]) < getCardsNum("Slash", lord)
					or self:getKnownNum(males[1]) == males[1]:getHandcardNum() and getKnownCard(males[1], self.player, "Slash", true, "he") == 0)
				then
				return males[1], lord
			end

			local afriend = findFriend_maxSlash(self, males[1])
			if afriend and afriend:objectName() ~= males[1]:objectName() then
				return males[1], afriend
			end
		end

		if #males == 1 then
			if isLord(males[1]) and sgs.turncount <= 1 and self.role == "rebel" and self.player:aliveCount() >= 3 then
				local p_slash, max_p, max_pp = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if p:isMale() and not self:isFriend(p) and p:objectName() ~= males[1]:objectName() and self:hasTrickEffective(duel, males[1], p) and not p:isLocked(duel)
						and p_slash < getCardsNum("Slash", p) then
						if p:getKingdom() == males[1]:getKingdom() then
							max_p = p
							break
						elseif not max_pp then
							max_pp = p
						end
					end
				end
				if max_p then table.insert(males, max_p) end
				if max_pp and #males == 1 then table.insert(males, max_pp) end
			end
		end

		if #males == 1 then
			if #others >= 1 and not others[1]:isLocked(duel) then
				table.insert(males, others[1])
			end
		end

		if #males == 1 and #self.friends_noself > 0 then
			self:log("Only 1")
			first = males[1]
			local friend_maxSlash = findFriend_maxSlash(self, first)
			if friend_maxSlash then table.insert(males, friend_maxSlash) end
		end

		if #males >= 2 then
			first = males[1]
			second = males[2]
			if lord and first:getHp() <= 1 then
				if self.player:isLord() or sgs.isRolePredictable() then
					local friend_maxSlash = findFriend_maxSlash(self, first)
					if friend_maxSlash then second = friend_maxSlash end
				elseif lord:isMale() then
					if self.role=="rebel" and not first:isLord() and self:hasTrickEffective(duel, first, lord) then
						second = lord
					else
						if ( (self.role == "loyalist" or self.role == "renegade") )
							and ( getCardsNum("Slash", first) <= getCardsNum("Slash", second) ) then
							second = lord
						end
					end
				end
			end

			if first and second and first:objectName() ~= second:objectName() and not second:isLocked(duel) then
				return first, second
			end
		end
	end
end

function SmartAI:getGuhuoCard(class_name, at_play, latest_version)
	return nil
end

function SmartAI:getGuhuoViewCard(class_name, latest_version)
	return nil
end

function SmartAI:getJijiangSlashNum(player)
	return 0
end

function SmartAI:getLijianCard()
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				  and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	return card_id
end

function SmartAI:getSaveNum(isFriend)
	local num = 0
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if (isFriend and self:isFriend(player)) or (not isFriend and self:isEnemy(player)) then
			if player:objectName() == self.player:objectName() then
				num = num + self:getCardsNum("Peach")
			else
				num = num + getCardsNum("Peach", player, self.player)
			end
		end
	end
	return num
end

function SmartAI:getWoundedFriend(maleOnly, include_self)
	local friends = include_self and self.friends or self.friends_noself
	self:sort(friends, "hp")
	local list1 = {}    -- need help
	local list2 = {}    -- do not need help
	local addToList = function(p,index)
		if ( (not maleOnly) or (maleOnly and p:isMale()) ) and p:isWounded() then
			table.insert(index ==1 and list1 or list2, p)
		end
	end

	local getCmpHp = function(p)
		local hp = p:getHp()
		if p:isLord() and self:isWeak(p) then hp = hp - 10 end
		return hp
	end


	local cmp = function (a, b)
		if getCmpHp(a) == getCmpHp(b) then
			return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
		else
			return getCmpHp(a) < getCmpHp(b)
		end
	end

	for _, friend in ipairs(friends) do
		if friend:isLord() then
			if self:needToLoseHp(friend, nil, nil, true, true) then
				addToList(friend, 2)
			elseif not sgs.isLordHealthy() then
				addToList(friend, 1)
			end
		else
			if self:needToLoseHp(friend, nil, nil, nil, true) then
				addToList(friend, 2)
			else
				addToList(friend, 1)
			end
		end
	end
	if #list2 > 0 then
		for _, p in ipairs(list2) do
			if table.contains(list1, p) then
				table.removeOne(list2, p)
			end
		end
	end
	table.sort(list1, cmp)
	table.sort(list2, cmp)
	return list1, list2
end

function SmartAI:getWuhunRevengeTargets()
	return {}
end

local function getPriorFriendsOfLiyu(self, lvbu)
	lvbu = lvbu or self.player
	local prior_friends = {}
	if not string.startsWith(self.room:getMode(), "06_") and not sgs.GetConfig("EnableHegemony", false) then
		if lvbu:isLord() then
			for _, friend in ipairs(self:getFriendsNoself(lvbu)) do
				if sgs.evaluatePlayerRole(friend) == "loyalist" then table.insert(prior_friends, friend) end
			end
		elseif lvbu:getRole() == "loyalist" then
			local lord = self.room:getLord()
			if lord then prior_friends = { lord } end
		end
	elseif self.room:getMode() == "06_3v3" then
		if lvbu:getRole() == "loyalist" then
			for _, friend in ipairs(self:getFriendsNoself(lvbu)) do
				if friend:getRole() == "lord" then table.insert(prior_friends, friend) break end
			end
		elseif lvbu:getRole() == "rebel" then
			for _, friend in ipairs(self:getFriendsNoself(lvbu)) do
				if friend:getRole() == "renegade" then table.insert(prior_friends, friend) break end
			end
		end
	elseif self.room:getMode() == "06_XMode" then
		local leader = lvbu:getTag("XModeLeader"):toPlayer()
		local backup = 0
		if leader then
			backup = #leader:getTag("XModeBackup"):toStringList()
			if backup == 0 then
				prior_friends = self:getFriendsNoself(lvbu)
			end
		end
	end
	return prior_friends
end

function SmartAI:hasLiyuEffect(target, slash)
	local upperlimit = 1
	if #self.friends_noself == 0 then return false end
	if not self:slashIsEffective(slash, target, self.player) then return false end

	local targets = { target }
	if target:isChained() and slash:isKindOf("NatureSlash") then
		for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
			if p:isChained() and p:objectName() ~= self.player:objectName() then table.insert(targets, p) end
		end
	end
	local unsafe = false
	for _, p in ipairs(targets) do
		if self:isEnemy(target) and not target:isNude() then
			unsafe = true
			break
		end
	end
	if not unsafe then return false end

	local duel = sgs.Sanguosha:cloneCard("Duel")
	if self.player:isLocked(duel) then return false end

	local enemy_null = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) then enemy_null = enemy_null - getCardsNum("Nullification", p, self.player) end
		if self:isEnemy(p) then enemy_null = enemy_null + getCardsNum("Nullification", p, self.player) end
	end
	enemy_null = enemy_null - self:getCardsNum("Nullification")
	if enemy_null <= -1 then return false end

	local prior_friends = getPriorFriendsOfLiyu(self)
	if #prior_friends == 0 then return false end
	for _, friend in ipairs(prior_friends) do
		if self:hasTrickEffective(duel, friend, self.player) and self:isWeak(friend) and (getCardsNum("Slash", friend, self.player) < upperlimit or self:isWeak()) then
			return true
		end
	end

	if sgs.isJinkAvailable(self.player, target, slash) and getCardsNum("Jink", target, self.player) >= upperlimit
		and not self:needToLoseHp(target, self.player, true) and not self:getDamagedEffects(target, self.player, true) then return false end
	if slash:hasFlag("AIGlobal_KillOff") or (target:getHp() == 1 and self:isWeak(target) and self:getSaveNum() < 1) then return false end

	if self.player:hasSkills("jizhi") then return false end
	if not string.startsWith(self.room:getMode(), "06_") and not sgs.GetConfig("EnableHegemony", false) and self.role ~= "rebel" then
		for _, friend in ipairs(self.friends_noself) do
			if self:hasTrickEffective(duel, friend, self.player) and self:isWeak(friend) and (getCardsNum("Slash", friend, self.player) < upperlimit or self:isWeak())
				and self:getSaveNum(true) < 1 then
				return true
			end
		end
	end
	return false
end

function SmartAI:hasNosQiuyuanEffect(from, to)
	return false
end

function SmartAI:hasQiuyuanEffect(from, to)
	return false
end

function SmartAI:isLihunTarget(player, drawCardNum)
	return false
end

function SmartAI:isTiaoxinTarget(enemy)
	if not enemy then self.room:writeToConsole(debug.traceback()) return end
	if getCardsNum("Slash", enemy) < 1 and self.player:getHp() > 1 and not self:canHit(self.player, enemy)
		and not (enemy:hasWeapon("double_sword") and self.player:getGender() ~= enemy:getGender())
		then return true end
	if sgs.card_lack[enemy:objectName()]["Slash"] == 1
		or self:needLeiji(self.player, enemy)
		or self:getDamagedEffects(self.player, enemy, true)
		or self:needToLoseHp(self.player, enemy, true)
		then return true end
	if self:getOverflow() and self:getCardsNum("Jink") > 1 then return true end
	return false
end

function SmartAI:isValuableCard(card, player)
	player = player or self.player
	if (isCard("Peach", card, player) and getCardsNum("Peach", player, self.player) <= 2)
		or (self:isWeak(player) and isCard("Analeptic", card, player))
		or (player:getPhase() ~= sgs.Player_Play
			and ((isCard("Nullification", card, player) and getCardsNum("Nullification", player, self.player) < 2 and player:hasSkills("jizhi"))
				or (isCard("Jink", card, player) and getCardsNum("Jink", player, self.player) < 2)))
		or (player:getPhase() == sgs.Player_Play and isCard("ExNihilo", card, player) and not player:isLocked(card)) then
		return true
	end
	local dangerous = self:getDangerousCard(player)
	if dangerous and card:getEffectiveId() == dangerous then return true end
	local valuable = self:getValuableCard(player)
	if valuable and card:getEffectiveId() == valuable then return true end
end

function SmartAI:ImitateResult_DrawNCards(player, skills, overall)
	player = player or self.player
	if player:isSkipped(sgs.Player_Draw) then
		return 0
	end
	return 2
end

function SmartAI:needBear(player)
	return false
end

function SmartAI:needDeath(player)
	return false
end

function SmartAI:needLeiji(to, from)
	return false
end

function SmartAI:resetCards(cards, except)
	local result = {}
	for _, c in ipairs(cards) do
		if c:getEffectiveId() == except:getEffectiveId() then continue
		else table.insert(result, c) end
	end
	return result
end

function SmartAI:shouldUseRende()
	if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > 0 then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			local inAttackRange = self.player:distanceTo(enemy) == 1 or self.player:distanceTo(enemy) == 2
									and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()
			if inAttackRange and sgs.isGoodTarget(enemy, self.enemies, self) then
				local slashs = self:getCards("Slash")
				local slash_count = 0
				for _, slash in ipairs(slashs) do
					if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) then
						slash_count = slash_count + 1
					end
				end
				if slash_count >= enemy:getHp() then return false end
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:canSlash(self.player) and not self:slashProhibit(nil, self.player, enemy) then
			if enemy:hasWeapon("guding_blade") and self.player:getHandcardNum() == 1 and getCardsNum("Slash", enemy) >= 1 then
				return
			elseif self:hasCrossbowEffect(enemy) and getCardsNum("Slash", enemy) > 1 and self:getOverflow() <= 0 then
				return
			end
		end
	end
	local keepNum = 1
	if self.player:getMark("rende") == 0 then
		if self.player:getHandcardNum() == 3 then
			keepNum = 0
		end
		if self.player:getHandcardNum() > 3 then
			keepNum = 3
		end
	end
	if self:getOverflow() > 0  then
		return true
	end
	if self.player:getHandcardNum() > keepNum  then
		return true
	end
	if self.player:getMark("rende") ~= 0 and self.player:getMark("rende") < 2
		and (2 - self.player:getMark("rende")) >=  (self.player:getHandcardNum() - keepNum) then
		return true
	end
end

function SmartAI:toTurnOver(player, n, reason) -- @todo: param of toTurnOver
	if not player then global_room:writeToConsole(debug.traceback()) return end
	n = n or 0
	if not player:faceUp() then
		return false
	end
	if n > 1 then
		if ( player:getPhase() ~= sgs.Player_NotActive and (player:hasSkills(sgs.Active_cardneed_skill) or player:hasWeapon("Crossbow")) )
		or ( player:getPhase() == sgs.Player_NotActive and player:hasSkills(sgs.notActive_cardneed_skill) ) then
		return false end
	end
	return true
end

function SmartAI:willSkipDrawPhase(player, NotContains_Null)
	local player = player or self.player
	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p, player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p, player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				local trick = sgs.Sanguosha:cloneCard(hcard:objectName(), hcard:getSuit(), hcard:getNumber())
				if self:hasTrickEffective(trick, player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if player:containsTrick("supply_shortage") then
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		return true
	end
	return false
end

function SmartAI:willSkipPlayPhase(player, NotContains_Null)
	local player = player or self.player

	if player:isSkipped(sgs.Player_Play) then return true end

	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				local trick = sgs.Sanguosha:cloneCard(hcard:objectName(), hcard:getSuit(), hcard:getNumber())
				if self:hasTrickEffective(trick, player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p, player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p, player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if player:containsTrick("Indulgence") then
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		return true
	end
	return false
end

sgs.ai_get_cardType = function(card)
	if card:isKindOf("Weapon") then return 1 end
	if card:isKindOf("Armor") then return 2 end
	if card:isKindOf("DefensiveHorse") then return 3 end
	if card:isKindOf("OffensiveHorse")then return 4 end
end

function DimengIsWorth(self, friend, enemy, mycards, myequips)
	local e_hand1, e_hand2 = enemy:getHandcardNum(), enemy:getHandcardNum() - self:getLeastHandcardNum(enemy)
	local f_hand1, f_hand2 = friend:getHandcardNum(), friend:getHandcardNum() - self:getLeastHandcardNum(friend)
	local e_peach, f_peach = getCardsNum("Peach", enemy), getCardsNum("Peach", friend)
	if e_hand1 < f_hand1 then
		return false
	elseif e_hand2 <= f_hand2 and e_peach <= f_peach then
		return false
	elseif e_peach < f_peach and e_peach < 1 then
		return false
	end
	local cardNum = #mycards
	local delt = e_hand1 - f_hand1 --assert: delt>0
	if delt > cardNum then
		return false
	end
	--now e_hand1>f_hand1 and delt<=cardNum
	local soKeep = 0
	local soUse = 0
	local marker = math.ceil(delt / 2)
	for i=1, delt, 1 do
		local card = mycards[i]
		local keepValue = self:getKeepValue(card)
		if keepValue > 4 then
			soKeep = soKeep + 1
		end
		local useValue = self:getUseValue(card)
		if useValue >= 6 then
			soUse = soUse + 1
		end
	end
	if soKeep > marker then
		return false
	end
	if soUse > marker then
		return false
	end
	return true
end

function hasManjuanEffect(player)
	return false
end

function getGuixinValue(self, player)
	if player:isAllNude() then return 0 end
	local card_id = self:askForCardChosen(player, "hej", "dummy")
	if self:isEnemy(player) then
		for _, card in sgs.qlist(player:getJudgingArea()) do
			if card:getEffectiveId() == card_id then
				if card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 0.8
					elseif self:hasWizard(self.friends, true) then return 0.4
					else return 0.5 * (#self.friends) / (#self.friends + #self.enemies) end
				else
					return -0.2
				end
			end
		end
		for i = 0, 3 do
			local card = player:getEquip(i)
			if card and card:getEffectiveId() == card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0 end
				local value = 0
				if self:getDangerousCard(player) == card_id then value = 1.5
				elseif self:getValuableCard(player) == card_id then value = 1.1
				elseif i == 1 then value = 1
				elseif i == 2 then value = 0.8
				elseif i == 0 then value = 0.7
				elseif i == 3 then value = 0.5
				end
				if player:hasSkills(sgs.lose_equip_skill) or self:doNotDiscard(player, "e", true) then value = value - 0.2 end
				return value
			end
		end
		if self:needKongcheng(player) and player:getHandcardNum() == 1 then return 0 end
		if not self:hasLoseHandcardEffective() then return 0.1
		else
			local index = player:hasSkills("jieyin") and 0.7 or 0.6
			local value = 0.2 + index / (player:getHandcardNum() + 1)
			if self:doNotDiscard(player, "h", true) then value = value - 0.1 end
			return value
		end
	elseif self:isFriend(player) then
		for _, card in sgs.qlist(player:getJudgingArea()) do
			if card:getEffectiveId() == card_id then
				if card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 1
					elseif self:hasWizard(self.friends, true) then return 0.8
					else return 0.4 * (#self.enemies) / (#self.friends + #self.enemies) end
				else
					return 1.5
				end
			end
		end
		for i = 0, 3 do
			local card = player:getEquip(i)
			if card and card:getEffectiveId() == card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0.9 end
				local value = 0
				if i == 1 then value = 0.1
				elseif i == 2 then value = 0.2
				elseif i == 0 then value = 0.25
				elseif i == 3 then value = 0.25
				end
				if player:hasSkills(sgs.lose_equip_skill) then value = value + 0.1 end
				return value
			end
		end
		if self:needKongcheng(player, true) and player:getHandcardNum() == 1 then return 0.5
		elseif self:needKongcheng(player) and player:getHandcardNum() == 1 then return 0.3 end
		if not self:hasLoseHandcardEffective() then return 0.2
		else
			local index = player:hasSkills("jieyin") and 0.5 or 0.4
			local value = 0.2 - index / (player:getHandcardNum() + 1)
			return value
		end
	end
	return 0.3
end

function getNextJudgeReason(self, player)
	if self:playerGetRound(player) > 2 then
		if player:hasArmorEffect("eight_diagram") then
			if self:playerGetRound(player) > 3 and self:isEnemy(player) then return "EightDiagram"
			else return end
		end
	end
end
