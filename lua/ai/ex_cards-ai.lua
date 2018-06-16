--[[
    卡牌：屎（基本牌）
    效果：当此牌在你的回合内从你的手牌进入弃牌堆时，你将受到自己对自己的1点伤害（黑桃为流失1点体力），其中方块为无属性伤害、梅花为雷电伤害、红桃为火焰伤害。造成伤害的牌为此牌。在你的回合内，你可多次食用。
]]--
local function useShit_LoseHp(self, card, use)
    local lose = 1
    local hp = self.player:getHp()
    local amSafe = ( lose < hp )
    if not amSafe then
        amSafe = ( lose < hp + self:getCardsNum("Peach") )
    end
    if amSafe then
        if self.player:getHandcardNum() == 1 and self.player:getLostHp() == 0 and self:needKongcheng() then
            use.card = card
            return 
        elseif getBestHp(self.player) > self.player:getHp() and self:getOverflow() <= 0 then
            use.card = card
            return 
        end
    else
        if self.role == "renegade" or self.role == "lord" then
            return
        elseif self:getAllPeachNum() > 0 or self:getOverflow() <= 0 then
            return 
        end
    end
end
local function useShit_FireDamage(self, card, use)
    if self.player:isChained() then
        if #(self:getChainedFriends()) > #(self:getChainedEnemies()) then
            return 
        end
    end
    local damage = 1
    if self.player:hasArmorEffect("gale_shell") then
        damage = damage + 1
    elseif self.player:hasArmorEffect("vine") then
        damage = damage + 1
    end
    if damage > 1 and self.player:hasArmorEffect("silver_lion") then
        damage = 1
    end
    local hp = self.player:getHp()
    local amSafe = ( damage < hp )
    local peachNum = nil
    if not amSafe then
        peachNum = self:getCardsNum("Peach")
        amSafe = ( damage < hp + peachNum )
    end
    if amSafe then
        peachNum = peachNum or self:getCardsNum("Peach")
        if self.player:getHandcardNum() == 1 and self.player:getLostHp() == 0 and self:needKongcheng() then
            use.card = card
            return 
        elseif getBestHp(self.player) > self.player:getHp() and self:getOverflow() <= 0 then
            use.card = card
            return 
        end
    else
        if self.role == "renegade" or self.role == "lord" then
            return
        elseif self:getAllPeachNum() > 0 or self:getOverflow() <= 0 then
            return 
        end
    end
end
local function useShit_ThunderDamage(self, card, use)
    if self.player:isChained() then
        if #(self:getChainedFriends()) > #(self:getChainedEnemies()) then
            return 
        end
    end
    local damage = 1
    if damage > 1 and self.player:hasArmorEffect("silver_lion") then
        damage = 1
    end
    local hp = self.player:getHp()
    local amSafe = ( damage < hp )
    local peachNum = nil
    if not amSafe then
        peachNum = self:getCardsNum("Peach")
        amSafe = ( damage < hp + peachNum )
    end
    if amSafe then
        peachNum = peachNum or self:getCardsNum("Peach")
        if self.player:getHandcardNum() == 1 and self.player:getLostHp() == 0 and self:needKongcheng() then
            use.card = card
            return 
        elseif getBestHp(self.player) > self.player:getHp() and self:getOverflow() <= 0 then
            use.card = card
            return 
        end
    else
        if self.role == "renegade" or self.role == "lord" then
            return
        elseif self:getAllPeachNum() > 0 or self:getOverflow() <= 0 then
            return 
        end
    end
end
local function useShit_NormalDamage(self, card, use)
    local damage = 1
    if damage > 1 and self.player:hasArmorEffect("silver_lion") then
        damage = 1
    end
    local hp = self.player:getHp()
    local amSafe = ( damage < hp )
    local peachNum = nil
    if not amSafe then
        peachNum = self:getCardsNum("Peach")
        amSafe = ( damage < hp + peachNum )
    end
    if amSafe then
        peachNum = peachNum or self:getCardsNum("Peach")
        if self.player:getHandcardNum() == 1 and self.player:getLostHp() == 0 and self:needKongcheng() then
            use.card = card
            return 
        elseif getBestHp(self.player) > self.player:getHp() and self:getOverflow() <= 0 then
            use.card = card
            return 
        end
    else
        if self.role == "renegade" or self.role == "lord" then
            return
        elseif self:getAllPeachNum() > 0 or self:getOverflow() <= 0 then
            return 
        end
    end
end
function SmartAI:useCardShit(card, use)
    if self.player:hasSkill("jueqing") then
        useShit_LoseHp(self, card, use)
        return 
    end
    local suit = card:getSuit()
    if suit == sgs.Card_Spade then
        useShit_LoseHp(self, card, use)
        return 
    end
    if suit == sgs.Card_Heart then
        useShit_FireDamage(self, card, use)
    elseif suit == sgs.Card_Club then
        useShit_ThunderDamage(self, card, use)
    elseif suit == sgs.Card_Diamond then
        useShit_NormalDamage(self, card, use)
    end
end
sgs.ai_use_value["Shit"] = -10
sgs.ai_keep_value["Shit"] = 10
--[[
    卡牌：猴子（装备牌·坐骑牌）
    效果：1、当场上有其他角色使用【桃】时，你可以弃置【猴子】，阻止【桃】的结算并将其收为手牌；
        2、你计算与其他角色的距离时，始终-1
]]--
sgs.ai_skill_invoke.grab_peach = function(self, data)
    local from = data:toCardUse().from
    return self:isEnemy(from)
end
--[[
    卡牌：杨修剑（装备牌·武器）
    效果：当你的【杀】造成伤害时，可以指定攻击范围内的一名其他角色为伤害来源，杨修剑归该角色所有
]]--
sgs.weapon_range.YxSword = 3
--room->askForPlayerChosen(player, players, objectName(), "@yxsword-select", true, true)
sgs.ai_skill_playerchosen["yx_sword"] = function(self, targets)
    local data = self.room:getTag("YxSwordData")
    local damage = data:toDamage()
    local victim = damage.to
    local willKillVictim = ( victim:getHp() + self:getAllPeachNum(victim) <= damage.damage )
    local friends, enemies = {}, {}
    for _,p in sgs.qlist(targets) do
        if self:isFriend(p) then
            table.insert(friends, p)
        else
            table.insert(enemies, p)
        end
    end
    if willKillVictim then
        local role = sgs.evaluatePlayerRole(victim)
        if role == "rebel" then
            if #friends > 0 then
                local drawTargets = self:findPlayerToDraw(true, 3, true)
                for _,target in ipairs(drawTargets) do
                    for _,friend in ipairs(friends) do
                        if target:objectName() == friend:objectName() then
                            return friend
                        end
                    end
                end
            end
        elseif role == "loyalist" then
            local lord = getLord(victim)
            if lord and lord:objectName() ~= victim:objectName() and #enemies > 0 then
                for _,enemy in ipairs(enemies) do
                    if lord:objectName() == enemy:objectName() then
                        return enemy
                    end
                end
            end
        end
    end
    if self:cantbeHurt(victim, self.player, damage.damage) then
        if #friends > 0 then
            for _,friend in ipairs(friends) do
                if not self:cantbeHurt(victim, friend, damage.damage) then
                    return friend
                end
            end
        end
        if #enemies > 0 then
            for _,enemy in ipairs(enemies) do
                if self:cantbeHurt(victim, enemy, damage.damage) then
                    return enemy
                end
            end
        end
    end
    if not willKillVictim then
        if self:getDamagedEffects(victim, self.player, true) then
            if #friends > 0 then
                for _,friend in ipairs(friends) do
                    if not self:getDamagedEffects(victim, friend, true) then
                        return friend
                    end
                end
            end
            if #enemies > 0 then
                self:sort(enemies, "defense")
                return enemies[1]
            end
        end
    end
    if self:hasSkills(sgs.lose_equip_skill) and #friends > 0 then
        local cards = { self.player:getWeapon() }
        local weapon, priorTarget = self:getCardNeedPlayer(cards, false)
        if weapon and priorTarget then
            for _,friend in ipairs(friends) do
                if priorTarget:objectName() == friend:objectName() then
                    return friend
                end
            end
        end
        self:sort(friends, "threat")
        friends = sgs.reverse(friends)
        return friends[1]
    end
    return nil
end
--[[
    卡牌：狂风甲（装备牌·防具）
    效果：1、锁定技，每次受到火焰伤害时，该伤害+1；
        2、你可以将狂风甲装备和你距离为1以内的一名角色的装备区内
]]--
sgs.ai_card_intention.GaleShell = 80
sgs.ai_use_priority.GaleShell = 0.9
sgs.dynamic_value.control_card.GaleShell = true
sgs.ai_armor_value["gale_shell"] = function(player, self)
    return -10
end
function SmartAI:useCardGaleShell(card, use)
    self:sort(self.enemies, "threat")
    local targets = {}
    for _,enemy in ipairs(self.enemies) do
        if self.player:distanceTo(enemy) == 1 then
            table.insert(targets, enemy)
        end
    end
    if #targets > 0 then
        local function getArmorUseValue(target)
            local value = 0
            local armor = target:getArmor()
            if armor then
                value = value + 10
                if target:hasArmorEffect("silver_lion") and target:isWounded() then
                    value = value - 4
                end
                if self:hasSkills(sgs.lose_equip_skill, target) then
                    value = value - 1.5
                end
            else
                value = value + 2
                if self:hasSkills(sgs.lose_equip_skill, target) then
                    value = value - 2
                end
                if self:hasSkills(sgs.need_equip_skill, target) then
                    value = value - 2
                end
            end
            return value
        end
        local values = {}
        for _,enemy in ipairs(targets) do
            values[enemy:objectName()] = getArmorUseValue(enemy)
        end
        local compare_func = function(a, b)
            local valueA = values[a:objectName()] or 0
            local valueB = values[b:objectName()] or 0
            return valueA > valueB
        end
        table.sort(targets, compare_func)
        local target = targets[1]
        local value = values[target:objectName()] or 0
        if value > 0 then
            use.card = card
            if use.to then
                use.to:append(target)
            end
        end
    end
end
--[[
    卡牌：地震（锦囊牌·延时锦囊·天灾牌）
    效果：将【地震】放置于你的判定区里，回合判定阶段进行判定：若判定结果为♣2~9之间，与当前角色距离为1以内的角色(无视+1马)弃置装备区里的所有牌，将【地震】置入弃牌堆。若判定结果不为♣2~9之间，将【地震】移动到当前角色下家的判定区里
]]--
function SmartAI:useCardEarthquake(card, use)
    if self.player:containsTrick("earthquake") then
        return
    elseif self.player:isProhibited(self.player, card) then
        return
    end
    local value = 0
    local finalRetrial, wizard = self:getFinalRetrial(self.player, "earthquake")
    if finalRetrial == 2 then
        return
    elseif finalRetrial == 1 then
        value = value + 12
    end
    local function getEquipsValue(player)
        local v = 0
        local danID = self:getDangerousCard(player)
        local weapon = player:getWeapon()
        if weapon then
            v = v + 5
            if danID and weapon:getEffectiveId() == danID then
                value = value + 2
            end
        end
        local armor = player:getArmor()
        if armor then
            v = v + 8
            if danID and armor:getEffectiveId() == danID then
                value = value + 2
            end
        end
        local dhorse = player:getDefensiveHorse()
        if dhorse then
            v = v + 7
        end
        local ohorse = player:getOffensiveHorse()
        if ohorse then
            v = v + 4
        end
        local treasure = player:getTreasure()
        if treasure then
            v = v + 2
        end
        return v
    end
    if #self.enemies > 0 then
        for _,enemy in ipairs(self.enemies) do
            local equips = enemy:getEquips()
            if not equips:isEmpty() then
                value = value + getEquipsValue(enemy)
                if self:hasSkills(sgs.lose_equip_skill, enemy) then
                    value = value - equips:length() * 2
                end
                if enemy:getArmor() and self:needToThrowArmor(enemy) then
                    value = value - 1.5
                end
            end
        end
    end
    if #self.friends > 0 then
        for _,friend in ipairs(self.friends) do
            local equips = friend:getEquips()
            if not equips:isEmpty() then
                value = value - getEquipsValue(friend)
                if self:hasSkills(sgs.lose_equip_skill, friend) then
                    value = value + equips:length() * 2
                end
                if friend:getArmor() and self:needToThrowArmor(friend) then
                    value = value + 1.5
                end
            end
        end
    end
    if value > 0 then
        use.card = card
    end
end
--[[
    卡牌：台风（锦囊牌·延时锦囊·天灾牌）
    效果：将【台风】放置于你的判定区里，回合判定阶段进行判定：若判定结果为♦2~9之间，与当前角色距离为1的角色弃置6张手牌，将【台风】置入弃牌堆。若判定结果不为♦2~9之间，将【台风】移动到当前角色下家的判定区里
]]--
function SmartAI:useCardTyphoon(card, use)
    if self.player:containsTrick("typhoon") then
        return 
    elseif self.player:isProhibited(self.player, card) then
        return
    end
    local finalRetrial, wizard = self:getFinalRetrial(self.player, "typhoon")
    if finalRetrial == 2 then
        return
    elseif finalRetrial == 1 then
        use.card = card
        return 
    end
    local alives = self.room:getAlivePlayers()
    local value = 0
    for _,p in sgs.qlist(alives) do
        local v = 0
        local num = p:getHandcardNum()
        local discard = math.min(6, num)
        if discard > 0 then
            local keep = num - discard
            v = v + discard * 1.5
            if keep == 0 then
                if self:needKongcheng(p) then
                    v = v - 4
                end
                v = v + 10
            else
                v = v + 1.5 ^ keep
            end
        end
        if self:isFriend(p) then
            v = - v
        end
        value = value + v
    end
    if value > 0 then
        if self:getOverflow() > 0 or value > 6 then
            use.card = card
        end
    end
end
--相关信息：判断是否需要改判
sgs.ai_need_retrial_func["typhoon"] = function(self, judge, isGood, who, isFriend, lord)
    local others = self.room:getOtherPlayers(who)
    local friends, enemies = {}, {}
    for _,p in sgs.qlist(others) do
        if who:distanceTo(p) == 1 then
            if self:isFriend(p) then
                table.insert(friends, p)
            else
                table.insert(enemies, p)
            end
        end
    end
    local friend_discard_num, enemy_discard_num = 0, 0
    for _,friend in ipairs(friends) do
        local num = friend:getHandcardNum()
        num = math.min(6, num)
        friend_discard_num = friend_discard_num + num
    end
    for _,enemy in ipairs(enemies) do
        local num = enemy:getHandcardNum()
        num = math.min(6, num)
        enemy_discard_num = enemy_discard_num + num
    end
    --如果没中奖
    if isGood then
        if friend_discard_num == 0 and enemy_discard_num > 0 then
            return true
        end
        return false
    end
    --如果中奖
    if enemy_discard_num == 0 and friend_discard_num > 0 then
        return true
    elseif friend_discard_num > enemy_discard_num + 1 then
        return true
    end
    return false
end
--相关信息：改判动机值
sgs.ai_retrial_intention["typhoon"] = function(self, player, who, judge, last_judge)
    return 0
end
--[[
    卡牌：火山（锦囊牌·延时锦囊·天灾牌）
    效果：将【火山】放置于你的判定区里，回合判定阶段进行判定：若判定结果为♥2~9之间，当前角色受到2点火焰伤害，与当前角色距离为1的角色(无视+1马)受到1点火焰伤害，【火山】生效后即置入弃牌堆。若判定结果不为♥2~9之间，将【火山】移动到当前角色下家的判定区里
]]--
function SmartAI:useCardVolcano(card, use)
    if self.player:containsTrick("volcano") then
        return 
    elseif self.player:isProhibited(self.player, card) then
        return
    end
    local finalRetrial, wizard = self:getFinalRetrial(self.player, "volcano")
    if finalRetrial == 2 then
        return
    elseif finalRetrial == 1 then
        use.card = card
        return 
    end
    local careLord = ( self.role == "renegade" and self.room:alivePlayerCount() > 2 )
    local alives = self.room:getAlivePlayers()
    local value = 0
    for _,p in sgs.qlist(alives) do
        local v = 0
        local damage = 0
        local deathFlag = false
        local can_transfer = false
        local isFriend = self:isFriend(p)
        if self:damageIsEffective(p, sgs.DamageStruct_Fire) then
            damage = 2
            if p:hasArmorEffect("vine") or p:hasArmorEffect("gale_shell") then
                damage = damage + 1
            end
            if p:hasArmorEffect("silver_lion") then
                damage = 1
            end
        end
        if damage > 0 and not can_transfer then
            local hp = p:getHp()
            if hp <= damage then
                if hp + self:getAllPeachNum(p) <= damage then
                    deathFlag = true
                end
            end
            if deathFlag then
                v = v + 50
            else
                if self:isWeak(p) then
                    v = v + 1
                end
            end
        end
        if isFriend then
            v = - v
        end
        if can_transfer then
            if isFriend then
                v = v + 4
            else
                v = v - 5
            end
        end
        if deathFlag and careLord and p:isLord() then
            v = v - 100
        end
        value = value + v
    end
    if value > 0 then
        if self:getOverflow() > 0 or value > 6 then
            use.card = card
        end
    end
end
--[[
    卡牌：洪水（锦囊牌·延时锦囊·天灾牌）
    效果：将【洪水】放置于你的判定区里，回合判定阶段进行判定：若判定结果为 A,K，从当前角色的牌随机取出和场上存活人数相等的数量置于桌前，从下家开始，每人选一张收为手牌，将【洪水】置入弃牌堆。若判定结果不为AK，将【洪水】移到当前角色下家的判定区里
]]--
function SmartAI:useCardDeluge(card, use)
    if self.player:containsTrick("deluge") then
        return 
    elseif self.player:isProhibited(self.player, card) then
        return
    end
    local finalRetrial, wizard = self:getFinalRetrial(self.player, "deluge")
    if finalRetrial == 2 then
        return
    elseif finalRetrial == 1 then
        use.card = card
        return 
    end
    local alives = self.room:getAlivePlayers()
    local count = alives:length()
    local value = 0
    local function getValue(target)
        local v = 0
        local isFriend = self:isFriend(target)
        local card_count = target:getCardCount(true)
        local throw_count = math.min(card_count, count)
        if throw_count > 0 then
            if isFriend then
                v = v - throw_count
            else
                v = v + throw_count
            end
            local the_lucky = target:getNextAlive()
            for i=1, throw_count, 1 do
                if self:isFriend(the_lucky) then
                    v = v + 1
                else
                    v = v - 1
                end
                the_lucky = the_lucky:getNextAlive()
            end
        end
        return v
    end
    local values, targets = {}, {}
    for _,p in sgs.qlist(alives) do
        values[p:objectName()] = getValue(p) or 0
        table.insert(targets, p)
    end
    local compare_func = function(a, b)
        local valueA = values[a:objectName()] or 0
        local valueB = values[b:objectName()] or 0
        return valueA > valueB
    end
    table.sort(targets, compare_func)
    local target = targets[1]
    local target_value = values[target:objectName()] or 0
    value = value + target_value
    if value > 0 then
        if self:getOverflow() > 0 or value > 6 then
            use.card = card
        end
    end
end
--[[
    卡牌：泥石流（锦囊牌·延时锦囊·天灾牌）
    效果：将【泥石流】放置于你的判定区里，回合判定阶段进行判定：若判定结果为黑桃或梅花A,K,4,7，从当前角色开始，每名角色依次按顺序弃置武器、防具、+1马、-1马，无装备者受到1点无属性伤害，当总共被弃置的装备达到4件或你上家结算完成时，【泥石流】停止结算并置入弃牌堆。若判定牌不为黑色AK47，将【泥石流】移动到下家的判定区里
]]--
function SmartAI:useCardMudslide(card, use)
    if self.player:containsTrick("mudslide") then
        return 
    elseif self.player:isProhibited(self.player, card) then
        return
    end
    local finalRetrial, wizard = self:getFinalRetrial(self.player, "mudslide")
    if finalRetrial == 2 then
        return
    elseif finalRetrial == 1 then
        use.card = card
        return 
    end
    local alives = self.room:getAlivePlayers()
    local value = 0
    local values = {}
    for _,p in sgs.qlist(alives) do
        values[p:objectName()] = {}
    end
    starter = self.player:objectName()
    local function getMudSlideValue(target, task)
        if task > 0 then
            local v = 0
            local isFriend = self:isFriend(target)
            local e_num = target:getEquips():length()
            if e_num == 0 then --make damage
                if isFriend then
                    v = v - 4
                else
                    v = v + 4
                end
            else --discard equips
                if isFriend then
                    if self:hasSkills(sgs.lose_equip_skill, target) then
                        v = v + e_num * 2
                    end
                    if target:getArmor() and self:needToThrowArmor(target) then
                        v = v + 1.5
                    end
                else
                    if self:hasSkills(sgs.lose_equip_skill, target) then
                        v = v - e_num * 2
                    end
                    if target:getArmor() and self:needToThrowArmor(target) then
                        v = v - 1.5
                    end
                end
            end
            table.insert(values[target:objectName()], v)
            task = task - e_num
            local next_target = target:getNextAlive()
            if next_target:objectName() ~= starter and task > 0 then
                getMudSlideValue(next_target, task)
            end
        end
    end
    for _,p in sgs.qlist(alives) do
        getMudSlideValue(p, 4)
    end
    for _,p in sgs.qlist(alives) do
        local pv, pc = 0, 0
        for _,v in ipairs(values[p:objectName()]) do
            pv = pv + v
            pc = pc + 1
        end
        if pc > 0 then
            value = value + pv / pc
        end
    end
    if value > 0 then
        if self:getOverflow() > 0 or value > 4 then
            use.card = card
        end
    end
end
--[[
	卡牌：银月枪（装备牌·武器）
	效果：你的回合外，每当你使用或打出了一张黑色牌时，你可以使用一张【杀】
]]--
sgs.weapon_range.MoonSpear = 3
sgs.ai_use_priority.MoonSpear = 2.635
--[[
	卡牌：SP银月枪（装备牌·武器）
	效果：你的回合外，每当你使用或打出一张黑色牌时，你可以令你攻击范围内的一名角色打出一张【闪】，否则该角色受到1点伤害。
]]--
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
--[[
	卡牌：水淹七军（锦囊牌·单体锦囊）
	效果：令目标角色选择一项：弃置装备区的所有牌（至少一张），或受到1点伤害。
]]--
function SmartAI:useCardDrowning(card, use)
	self:sort(self.enemies)
	local targets, equip_enemy = {}, {}
	for _, enemy in ipairs(self.enemies) do
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
			and self:hasTrickEffective(card, enemy) and self:damageIsEffective(enemy) and self:canAttack(enemy)
			and not self:getDamagedEffects(enemy, self.player) and not self:needToLoseHp(enemy, self.player) then
			if enemy:hasEquip() then table.insert(equip_enemy, enemy)
			else table.insert(targets, enemy)
			end
		end
	end
		if #equip_enemy > 0 then
			local function cmp(a, b)
				return a:getEquips():length() >= b:getEquips():length()
			end
			table.sort(equip_enemy, cmp)
			for _, enemy in ipairs(equip_enemy) do
				if not self:needToThrowArmor(enemy) then table.insert(targets, enemy) end
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if not (not use.current_targets or not table.contains(use.current_targets, friend:objectName())) and self:needToThrowArmor(friend) then
				table.insert(targets, friend)
			end
		end
	if #targets > 0 then
		local targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
		if use.isDummy and use.extra_target then targets_num = targets_num + use.extra_target end
		use.card = card
		if use.to then
			for i = 1, targets_num, 1 do
				use.to:append(targets[i])
				if #targets == i then break end
			end
		end
	end
end

sgs.ai_card_intention.Drowning = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		if not self:hasTrickEffective(card, to, from) or not self:damageIsEffective(to, sgs.DamageStruct_Normal, from)
			or self:needToThrowArmor(to) then
		else
			sgs.updateIntention(from, to, 80)
		end
	end
end

sgs.ai_use_value.Drowning = 5
sgs.ai_use_priority.Drowning = 7

sgs.ai_skill_choice.drowning = function(self, choices, data)
	local effect = data:toCardEffect()
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, effect.from)
		or self:needToLoseHp(self.player, effect.from)
		or self:getDamagedEffects(self.player, effect.from) then return "damage" end
	if self:isWeak() and not self:needDeath() then return "throw" end

	local value = 0
	for _, equip in sgs.qlist(self.player:getEquips()) do
		if equip:isKindOf("Weapon") then value = value + self:evaluateWeapon(equip)
		elseif equip:isKindOf("Armor") then
			value = value + self:evaluateArmor(equip)
			if self:needToThrowArmor() then value = value - 5 end
		elseif equip:isKindOf("OffensiveHorse") then value = value + 2.5
		elseif equip:isKindOf("DefensiveHorse") then value = value + 5
		end
	end
	if value < 8 then return "throw" else return "damage" end
end
--[[
	卡牌：连弩（装备牌·武器）
	效果：锁定技。出牌阶段，你可以额外使用三张【杀】。
]]--
sgs.weapon_range.VSCrossbow = sgs.weapon_range.Crossbow
sgs.ai_use_priority.VSCrossbow = sgs.ai_use_priority.Crossbow
--[[
	卡牌：倚天剑（装备牌·武器）
	效果：每当你于回合外受到伤害结算完毕后，你可以使用一张【杀】；当你失去装备区里的【倚天剑】时，你可以对一名其他角色造成【倚天剑】造成的1点伤害。
]]--
sgs.weapon_range.YitianSword = 2
sgs.ai_use_priority.YitianSword = 2.625
--room->askForPlayerChosen(player, room->getAlivePlayers(), "yitian_sword", "@YitianSword-lost", true, true)
sgs.ai_skill_playerchosen["yitian_sword"] = sgs.ai_skill_playerchosen["damage"]
--[[
	卡牌：五道杠（装备牌·防具）
	效果：当你的体力值：
		不小于5，视为你拥有“苦肉”；
		为4，视为你拥有“国色”；
		为3，视为你拥有“结姻”；
		为2，视为你拥有“集智”；
		不大于1，视为你拥有“仁德”
]]--
--[[
	技能：苦肉（阶段技）
	描述：你可以弃置一张牌：若如此做，你失去1点体力。
]]--
local function getKurouCard(self, not_slash)
	local card_id
	local hold_crossbow = (self:getCardsNum("Slash") > 1)
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
					and not self:isValuableCard(acard) and not (acard:isKindOf("Crossbow") and hold_crossbow)
					and not (acard:isKindOf("Slash") and not_slash) then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getWeapon() and self:evaluateWeapon(self.player:getWeapon()) < 3
				and not (player:getWeapon():isKindOf("Crossbow") and hold_crossbow) then card_id = player:getWeapon():getId()
		elseif player:getArmor() and self:evaluateArmor(self.player:getArmor()) < 2 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not self:isValuableCard(acard) and not (acard:isKindOf("Crossbow") and hold_crossbow)
					and not (acard:isKindOf("Slash") and not_slash) then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	return card_id
end

local kurou_skill = {}
kurou_skill.name = "kurou"
table.insert(sgs.ai_skills, kurou_skill)
kurou_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("KurouCard") or not self.player:canDiscard(self.player, "he") then return end
	if (self.player:getHp() > 3 and self.player:getHandcardNum() > self.player:getHp())
		or (self.player:getHp() - self.player:getHandcardNum() >= 2) then
		local id = getKurouCard(self)
		if id then return sgs.Card_Parse("@KurouCard=" .. id) end
	end

	local function can_kurou_with_cb(self)
		if self.player:getHp() > 1 then return true end
		return false
	end

	local slash = sgs.Sanguosha:cloneCard("slash")
	if (self.player:hasWeapon("crossbow") or self:getCardsNum("Crossbow") > 0) or self:getCardsNum("Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and self:slashIsEffective(slash, enemy)
				and sgs.isGoodTarget(enemy, self.enemies, self, true) and not self:slashProhibit(slash, enemy) and can_kurou_with_cb(self) then
				local id = getKurouCard(self, true)
				if id then return sgs.Card_Parse("@KurouCard=" .. id) end
			end
		end
	end

	if self.player:getHp() <= 1 and self:getCardsNum("Analeptic") + self:getCardsNum("Peach") > 1 then
		local id = getKurouCard(self)
		if id then return sgs.Card_Parse("@KurouCard=.") end
	end
end

sgs.ai_skill_use_func.KurouCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.KurouCard = 6.8
--[[
	技能：国色（阶段技）
	描述：你可以选择一项：1.将一张方块牌当【乐不思蜀】使用；2.弃置一张方块牌并选择场上的一张【乐不思蜀】：若如此做，你弃置此【乐不思蜀】。然后你摸一张牌。
]]--
local guose_skill = {}
guose_skill.name = "guose"
table.insert(sgs.ai_skills, guose_skill)
guose_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("GuoseCard") then return end
	local cards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
		local c = sgs.Sanguosha:getCard(id)
		cards:prepend(c)
	end
	cards = sgs.QList2Table(cards)

	self:sortByUseValue(cards, true)
	local card = nil
	local has_weapon, has_armor = false, false

	for _, acard in ipairs(cards) do
		if acard:isKindOf("Weapon") and not (acard:getSuit() == sgs.Card_Diamond) then has_weapon = true end
	end

	for _, acard in ipairs(cards) do
		if acard:isKindOf("Armor") and not (acard:getSuit() == sgs.Card_Diamond) then has_armor = true end
	end

	for _, acard in ipairs(cards) do
		if (acard:getSuit() == sgs.Card_Diamond) and ((self:getUseValue(acard) < sgs.ai_use_value.Indulgence) or inclusive) then
			local shouldUse = true

			if acard:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor() > 0 then shouldUse = false
				end
			end

			if acard:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(acard) and not has_weapon then shouldUse = false
				end
			end

			if shouldUse then
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	return sgs.Card_Parse("@GuoseCard=" .. card:getEffectiveId())
end

sgs.ai_skill_use_func.GuoseCard = function(card, use, self)
	self:sort(self.friends)
	local id = card:getEffectiveId()
	local indul_only = self.player:handCards():contains(id)
	local rcard = sgs.Sanguosha:getCard(id)
	if not indul_only and not self.player:isJilei(rcard) then
		sgs.ai_use_priority.GuoseCard = 5.5
		for _, friend in ipairs(self.friends) do
			if friend:containsTrick("Indulgence") and self:willSkipPlayPhase(friend)
				and (self:isWeak(friend) or self:getOverflow(friend) > 1) then
				for _, c in sgs.qlist(friend:getJudgingArea()) do
					if c:isKindOf("Indulgence") and self.player:canDiscard(friend, card:getEffectiveId()) then
						use.card = card
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end

	local indulgence = sgs.Sanguosha:cloneCard("Indulgence")
	indulgence:addSubcard(id)
	if not self.player:isLocked(indulgence) then
		sgs.ai_use_priority.GuoseCard = sgs.ai_use_priority.Indulgence
		local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardIndulgence(indulgence, dummy_use)
		if dummy_use.card and dummy_use.to:length() > 0 then
			use.card = card
			if use.to then use.to:append(dummy_use.to:first()) end
			return
		end
	end

	sgs.ai_use_priority.GuoseCard = 5.5
	if not indul_only and not self.player:isJilei(rcard) then
		for _, friend in ipairs(self.friends) do
			if friend:containsTrick("Indulgence") and self:willSkipPlayPhase(friend) then
				for _, c in sgs.qlist(friend:getJudgingArea()) do
					if c:isKindOf("Indulgence") and self.player:canDiscard(friend, card:getEffectiveId()) then
						use.card = card
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end

	if not indul_only and not self.player:isJilei(rcard) then
		for _, friend in ipairs(self.friends) do
			if friend:containsTrick("Indulgence") then
				for _, c in sgs.qlist(friend:getJudgingArea()) do
					if c:isKindOf("Indulgence") and self.player:canDiscard(friend, card:getEffectiveId()) then
						use.card = card
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_priority.GuoseCard = 5.5
sgs.ai_use_value.GuoseCard = 5
sgs.ai_card_intention.GuoseCard = -60

function sgs.ai_cardneed.guose(to, card)
	return card:getSuit() == sgs.Card_Diamond
end

sgs.guose_suit_value = {
	diamond = 3.9
}
sgs.ai_suit_priority.guose= "club|spade|heart|diamond"
--[[
	技能：结姻（阶段技）
	描述：你可以弃置两张手牌并选择一名已受伤的男性角色：若如此做，你和该角色各回复1点体力。
]]--
local jieyin_skill={}
jieyin_skill.name = "jieyin"
table.insert(sgs.ai_skills,jieyin_skill)
jieyin_skill.getTurnUseCard=function(self)
	if self.player:getHandcardNum() < 2 then return nil end
	if self.player:hasUsed("JieyinCard") then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local first, second
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") then
			local dummy_use = {isDummy = true}
			self:useTrickCard(card, dummy_use)
			if not dummy_use.card then
				if not first then first = card:getEffectiveId()
				elseif first and not second then second = card:getEffectiveId()
				end
			end
			if first and second then break end
		end
	end

	for _, card in ipairs(cards) do
		if card:getTypeId() ~= sgs.Card_TypeEquip and (not self:isValuableCard(card) or self.player:isWounded()) then
			if not first then first = card:getEffectiveId()
			elseif first and first ~= card:getEffectiveId() and not second then second = card:getEffectiveId()
			end
		end
		if first and second then break end
	end

	if not second or not first then return end
	local card_str = ("@JieyinCard=%d+%d"):format(first, second)
	assert(card_str)
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func.JieyinCard = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend(true)
	local target = nil

	repeat
		if #arr1 > 0 and (self:isWeak(arr1[1]) or self:isWeak() or self:getOverflow() >= 1) then
			target = arr1[1]
			break
		end
		if #arr2 > 0 and self:isWeak() then
			target = arr2[1]
			break
		end
	until true

	if not target and self:isWeak() and self:getOverflow() >= 2 and (self.role == "lord" or self.role == "renegade") then
		local others = self.room:getOtherPlayers(self.player)
		for _, other in sgs.qlist(others) do
			if other:isWounded() and other:isMale() then
				if not self:hasSkills(sgs.masochism_skill, other) then
					target = other
					self.player:setFlags("jieyin_isenemy_"..other:objectName())
					break
				end
			end
		end
	end

	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority.JieyinCard = 2.8    -- 下调至决斗之后

sgs.ai_card_intention.JieyinCard = function(self, card, from, tos)
	if not from:hasFlag("jieyin_isenemy_"..tos[1]:objectName()) then
		sgs.updateIntention(from, tos[1], -80)
	end
end

sgs.dynamic_value.benefit.JieyinCard = true

--[[
	技能：集智
	描述：每当你使用一张锦囊牌时，你可以展示牌堆顶的一张牌：若此牌为基本牌，你选择一项：将之置入弃牌堆，或用一张手牌替换之；若此牌不为基本牌，你获得之。
]]--
sgs.ai_skill_cardask["@jizhi-exchange"] = function(self, data)
	local card = data:toCard()
	local handcards = sgs.QList2Table(self.player:getHandcards())
	if self.player:getPhase() ~= sgs.Player_Play then
		if hasManjuanEffect(self.player) then return "." end
		self:sortByKeepValue(handcards)
		for _, card_ex in ipairs(handcards) do
			if self:getKeepValue(card_ex) < self:getKeepValue(card) and not self:isValuableCard(card_ex) then
				return "$" .. card_ex:getEffectiveId()
			end
		end
	else
		if card:isKindOf("Slash") and not self:slashIsAvailable() then return "." end
		self:sortByUseValue(handcards)
		for _, card_ex in ipairs(handcards) do
			if self:getUseValue(card_ex) < self:getUseValue(card) and not self:isValuableCard(card_ex) then
				return "$" .. card_ex:getEffectiveId()
			end
		end
	end
	return "."
end

function sgs.ai_cardneed.jizhi(to, card)
	return card:getTypeId() == sgs.Card_TypeTrick
end

sgs.jizhi_keep_value = {
	Peach       = 6,
	Analeptic   = 5.9,
	Jink        = 5.8,
	ExNihilo    = 5.7,
	Snatch      = 5.7,
	Dismantlement = 5.6,
	IronChain   = 5.5,
	SavageAssault=5.4,
	Duel        = 5.3,
	ArcheryAttack = 5.2,
	AmazingGrace = 5.1,
	Collateral  = 5,
	FireAttack  =4.9
}
--[[
	技能：仁德（阶段技）
	描述：你可以将至少一张手牌任意分配给其他角色。每当你于本阶段内以此法给出的手牌首次达到两张或更多后，你回复1点体力。
]]--
local rende_skill = {}
rende_skill.name = "rende"
table.insert(sgs.ai_skills, rende_skill)
rende_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("RendeCard") or self.player:isKongcheng() then return end
	local mode = string.lower(global_room:getMode())

	if self:shouldUseRende() then
		return sgs.Card_Parse("@RendeCard=.")
	end
end

sgs.ai_skill_use_func.RendeCard = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)

	local notFound
	for i = 1, #cards do
		local card, friend = self:getCardNeedPlayer(cards)
		if card and friend then
			cards = self:resetCards(cards, card)
		else
			notFound = true
			break
		end

		if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then continue end
		if card:isAvailable(self.player) and (card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			local cardtype = card:getTypeId()
			self["use" .. sgs.ai_type_name[cardtype + 1] .. "Card"](self, card, dummy_use)
			if dummy_use.card and dummy_use.to:length() > 0 then
				if card:isKindOf("Slash") or card:isKindOf("Duel") then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length() > 1 then continue
					elseif t1:getHp() == 1 or sgs.card_lack[t1:objectName()]["Jink"] == 1
							or t1:isCardLimited(sgs.Sanguosha:cloneCard("jink"), sgs.Card_MethodResponse) then continue
					end
				elseif (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and self:getEnemyNumBySeat(self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then hasDelayedTrick = true break end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif card:isAvailable(self.player) and self:getEnemyNumBySeat(self.player, friend) > 0 and (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")) then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then continue end
		end
		use.card = sgs.Card_Parse("@RendeCard=" .. card:getId())
		if use.to then use.to:append(friend) end
		return
	end
end

sgs.ai_use_value.RendeCard = 8.5
sgs.ai_use_priority.RendeCard = 8.8

sgs.ai_card_intention.RendeCard = function(self,card, from, tos)
	local to = tos[1]
	local intention = -70
	sgs.updateIntention(from, to, intention)
end

sgs.dynamic_value.benefit.RendeCard = true

sgs.ai_skill_use["@@rende"] = function(self, prompt)
	local cards = {}
	local rende_list = self.player:property("rende"):toString():split("+")
	for _, id in ipairs(rende_list) do
		local num_id = tonumber(id)
		local hcard = sgs.Sanguosha:getCard(num_id)
		if hcard then table.insert(cards, hcard) end
	end
	if #cards == 0 then return "." end
	self:sortByUseValue(cards, true)

	for i = 1, #cards do
		local card, friend = self:getCardNeedPlayer(cards)
		if card and friend then
			cards = self:resetCards(cards, card)
		else return "." end

		if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then continue end
		if card:isAvailable(self.player) and (card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			local cardtype = card:getTypeId()
			self["use" .. sgs.ai_type_name[cardtype + 1] .. "Card"](self, card, dummy_use)
			if dummy_use.card and dummy_use.to:length() > 0 then
				if card:isKindOf("Slash") or card:isKindOf("Duel") then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length() > 1 then continue
					elseif t1:getHp() == 1 or sgs.card_lack[t1:objectName()]["Jink"] == 1
							or t1:isCardLimited(sgs.Sanguosha:cloneCard("jink"), sgs.Card_MethodResponse) then continue
					end
				elseif (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and self:getEnemyNumBySeat(self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then hasDelayedTrick = true break end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif card:isAvailable(self.player) and self:getEnemyNumBySeat(self.player, friend) > 0 and (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")) then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then continue end
		end

		local usecard
		usecard = "@RendeCard=" .. card:getId()
		if usecard then return usecard .. "->" .. friend:objectName() end
	end

end
