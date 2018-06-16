-- This is the Smart AI, and it should be loaded and run at the server side

-- "middleclass" is the Lua OOP library written by kikito
-- more information see: https://github.com/kikito/middleclass
require "middleclass"

-- initialize the random seed for later use
math.randomseed(os.time())

-- SmartAI is the base class for all other specialized AI classes
SmartAI = (require "middleclass").class("SmartAI")

version = "QSanguosha AI 20141006 (V1.32 Alpha)"

-- checkout https://github.com/haveatry823/QSanguoshaAI for details

--- this function is only function that exposed to the host program
--- and it clones an AI instance by general name
-- @param player The ServerPlayer object that want to create the AI object
-- @return The AI object
function CloneAI(player)
    return SmartAI(player).lua_ai
end

sgs.ais =                   {}
sgs.ai_card_intention =     {}
sgs.ai_playerchosen_intention = {}
sgs.ai_Yiji_intention =     {}
sgs.ai_retrial_intention =  {}
sgs.role_evaluation =       {}
sgs.ai_role =               {}
sgs.ai_keep_value =         {}
sgs.ai_use_value =          {}
sgs.ai_use_priority =       {}
sgs.ai_suit_priority =      {}
sgs.ai_global_flags =       {}
sgs.ai_skill_invoke =       {}
sgs.ai_skill_suit =         {}
sgs.ai_skill_cardask =      {}
sgs.ai_skill_choice =       {}
sgs.ai_skill_askforag =     {}
sgs.ai_skill_askforyiji =   {}
sgs.ai_skill_pindian =      {}
sgs.ai_filterskill_filter = {}
sgs.ai_skill_playerchosen = {}
sgs.ai_skill_discard =      {}
sgs.ai_cardshow =           {}
sgs.ai_nullification =      {}
sgs.ai_skill_cardchosen =   {}
sgs.ai_skill_use =          {}
sgs.ai_cardneed =           {}
sgs.ai_skill_use_func =     {}
sgs.ai_skills =             {}
sgs.ai_slash_weaponfilter = {}
sgs.ai_slash_prohibit =     {}
sgs.ai_view_as = {}
sgs.ai_cardsview = {}
sgs.ai_cardsview_valuable = {}
sgs.dynamic_value =         {
    damage_card =           {},
    control_usecard =       {},
    control_card =          {},
    lucky_chance =          {},
    benefit =               {}
}
sgs.ai_choicemade_filter =  {
    cardUsed =              {},
    cardResponded =         {},
    skillInvoke =           {},
    skillChoice =           {},
    Nullification =         {},
    playerChosen =          {},
    cardChosen =            {},
    Yiji =                  {},
    viewCards =             {},
    pindian =               {}
}

sgs.card_lack =             {}
sgs.ai_need_damaged =       {}
sgs.ai_debug_func =         {}
sgs.ai_chat_func =          {}
sgs.ai_event_callback =     {}
sgs.explicit_renegade =     false
sgs.ai_NeedPeach =          {}
sgs.ai_damage_effect =      {}
sgs.ai_current_judge =      {}
sgs.ai_need_retrial_func =  {}


for i=sgs.NonTrigger, sgs.NumOfEvents, 1 do
    sgs.ai_debug_func[i]    ={}
    sgs.ai_chat_func[i]     ={}
    sgs.ai_event_callback[i]={}
end

function setInitialTables()
    sgs.current_mode_players = { lord = 0, loyalist = 0, rebel = 0, renegade = 0 }
    sgs.ai_type_name =          {"Skill", "Basic", "Trick", "Equip"}
    sgs.lose_equip_skill = ""
    sgs.need_kongcheng = ""
    sgs.masochism_skill = ""
    sgs.wizard_skill = ""
    sgs.wizard_harm_skill = ""
    sgs.priority_skill = ""
    sgs.save_skill = ""
    sgs.exclusive_skill = ""
    sgs.Active_cardneed_skill = ""
    sgs.notActive_cardneed_skill =  ""
    sgs.cardneed_skill = sgs.Active_cardneed_skill .. "|" .. sgs.notActive_cardneed_skill
    sgs.drawpeach_skill = ""
    sgs.recover_skill = ""
    sgs.use_lion_skill = ""
    sgs.need_equip_skill = ""
    sgs.judge_reason = ""
    sgs.straight_damage_skill = ""
    sgs.double_slash_skill = ""
    sgs.need_maxhp_skill = ""
    sgs.bad_skills = ""

    sgs.Friend_All = 0
    sgs.Friend_Draw = 1
    sgs.Friend_Male = 2
    sgs.Friend_Female = 3
    sgs.Friend_Wounded = 4
    sgs.Friend_MaleWounded = 5
    sgs.Friend_FemaleWounded = 6
    sgs.Friend_Weak = 7

    for _, aplayer in sgs.qlist(global_room:getAllPlayers()) do
        table.insert(sgs.role_evaluation, aplayer:objectName())
        table.insert(sgs.ai_role, aplayer:objectName())
        if aplayer:isLord() then
            sgs.role_evaluation[aplayer:objectName()] = {lord = 99999, rebel = 0, loyalist = 99999, renegade = 0}
            sgs.ai_role[aplayer:objectName()] = "loyalist"
        else
            sgs.role_evaluation[aplayer:objectName()] = {rebel = 0, loyalist = 0, renegade = 0}
            sgs.ai_role[aplayer:objectName()] = "neutral"
        end
    end

end

function SmartAI:initialize(player)
    self.player = player
    self.room = player:getRoom()
    self.role = player:getRole()
    self.lua_ai = sgs.LuaAI(player)
    self.lua_ai.callback = function(full_method_name, ...)
        --The __FUNCTION__ macro is defined as CLASS_NAME::SUBCLASS_NAME::FUNCTION_NAME
        --in MSVC, while in gcc only FUNCTION_NAME is in place.
        local method_name_start = 1
        while true do
            local found = string.find(full_method_name, "::", method_name_start)
            if found ~= nil then
                method_name_start = found + 2
            else
                break
            end
        end
        local method_name = string.sub(full_method_name, method_name_start)
        local method = self[method_name]
        if method then
            local success, result1, result2
            success, result1, result2 = pcall(method, self, ...)
            if not success then
                self.room:writeToConsole(result1)
                self.room:writeToConsole(method_name)
                self.room:writeToConsole(debug.traceback())
                self.room:outputEventStack()
            else
                return result1, result2
            end
        end
    end

    self.retain = 2
    self.keepValue = {}
    self.kept = {}
    self.keepdata = {}
    self.predictedRange = 1
    self.slashAvail = 1
    if not sgs.initialized then
        sgs.initialized = true
        sgs.ais = {}
        sgs.turncount = 0
        sgs.debugmode = false
        global_room = self.room
        global_room:writeToConsole(version .. ", Powered by " .. _VERSION)

        setInitialTables()
        if sgs.isRolePredictable() then
            for _, aplayer in sgs.qlist(global_room:getAllPlayers()) do
                if aplayer:getRole() == "renegade" then sgs.explicit_renegade = true end
                if aplayer:getRole() ~= "lord" then
                    sgs.role_evaluation[aplayer:objectName()][aplayer:getRole()] = 65535
                    sgs.ai_role[aplayer:objectName()] = aplayer:getRole()
                end
            end
        end
    end

    sgs.ais[player:objectName()] = self

    sgs.card_lack[player:objectName()] = {}
    sgs.card_lack[player:objectName()]["Slash"] = 0
    sgs.card_lack[player:objectName()]["Jink"] = 0
    sgs.card_lack[player:objectName()]["Peach"] = 0
    sgs.ai_NeedPeach[player:objectName()] = 0


    sgs.updateAlivePlayerRoles()
    self:updatePlayers()
    self:assignKeep(true)
end

function sgs.getCardNumAtCertainPlace(card, player, place)
    if not card:isVirtualCard() and place == sgs.Player_PlaceHand then return 1
    elseif card:subcardsLength() == 0 then return 0
    else
        local num = 0
        for _, id in sgs.qlist(card:getSubcards()) do
            if place == sgs.Player_PlaceHand then
                if player:handCards():contains(id) then num = num + 1 end
            elseif place == sgs.Player_PlaceEquip then
                if player:hasEquip(sgs.Sanguosha:getCard(id)) then num = num + 1 end
            end
        end
        return num
    end
end

function sgs.getValue(player)
    if not player then global_room:writeToConsole(debug.traceback()) end
    return player:getHp() * 2 + player:getHandcardNum()
end

function sgs.getDefense(player)
    if not player then global_room:writeToConsole(debug.traceback()) return 0 end
    local current_player = global_room:getCurrent()
    if not current_player then return sgs.getValue(player) end

    local defense = player:getHp() * 2 + player:getHandcardNum()

    if player:getArmor() and player:hasArmorEffect(player:getArmor():objectName()) then defense = defense + 2 end
    if player:getDefensiveHorse() then defense = defense + 1 end

    if player:hasTreasure("wooden_ox") then defense = defense + player:getPile("wooden_ox"):length() end

    local hasEightDiagram = false
    if player:hasArmorEffect("eight_diagram") then
        hasEightDiagram = true
    end

    local m = sgs.masochism_skill:split("|")
    for _, masochism in ipairs(m) do
        if player:hasSkill(masochism) and sgs.isGoodHp(player) then
            defense = defense + 1
        end
    end

    if player:getHp() > getBestHp(player) then defense = defense + 0.8 end
    if player:getHp() <= 2 then defense = defense - 0.4 end

    if isLord(player) then
        defense = defense - 0.4
        if sgs.isLordInDanger() then defense = defense - 0.7 end
    end

    if player:getMark("@skill_invalidity") > 0 then defense = defense - 5 end

    if not player:faceUp() then defense = defense - 1 end

    if player:containsTrick("indulgence") then defense = defense - 0.5 end
    if player:containsTrick("supply_shortage") then defense = defense - 0.5 end

    defense = defense + (player:aliveCount() - (player:getSeat() - current_player:getSeat()) % player:aliveCount()) / 4

    defense = defense + player:getVisibleSkillList(true):length() * 0.25

    return defense
end

function SmartAI:assignKeep(start)
    self.keepValue = {}
    self.kept = {}

    if start then
        --[[
            通常的保留顺序
            "peach-1" = 7,
            "peach-2" = 5.8, "jink-1" = 5.2,
            "peach-3" = 4.5, "analeptic-1" = 4.1,
            "jink-2" = 4.0, "ExNihilo-1" = 3.9, "nullification-1" = 3.8, "thunderslash-1" = 3.66 "fireslash-1" = 3.63
            "slash-1" = 3.6 indulgence-1 = 3.5 SupplyShortage-1 = 3.48 snatch-1 = 3.46 Dismantlement-1 = 3.44 Duel-1 = 3.42
            Collateral-1 = 3.40 ArcheryAttack-1 = 3.38 SavageAssault-1 = 3.36 IronChain = 3.34 GodSalvation-1 = 3.32, Fireattack-1 = 3.3 "peach-4" = 3.1
            "analeptic-2" = 2.9, "jink-3" = 2.7 ExNihilo-2 = 2.7 nullification-2 = 2.6 thunderslash-2 = 2.46 fireslash-2 = 2.43 slash-2 = 2.4
            ...
            Weapon-1 = 2.08 Armor-1 = 2.06 DefensiveHorse-1 = 2.04 OffensiveHorse-1 = 2
            ...
            AmazingGrace-1 = -9 Lightning-1 = -10
        ]]

        self.keepdata = {}
        for k, v in pairs(sgs.ai_keep_value) do
            self.keepdata[k] = v
        end

        for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
            local skilltable = sgs[askill:objectName() .. "_keep_value"]
            if skilltable then
                for k, v in pairs(skilltable) do
                    self.keepdata[k] = v
                end
            end
        end
    end

    if sgs.turncount <= 1 and #self.enemies == 0 then
        self.keepdata.Jink = 4.2
    end

    if not self:isWeak() or self.player:getHandcardNum() >= 4 then
        for _, friend in ipairs(self.friends_noself) do
            if self:willSkipDrawPhase(friend) or self:willSkipPlayPhase(friend) then
                self.keepdata.Nullification = 5.5
                break
            end
        end
    end

    if self:getOverflow(self.player, true) == 1 then
        self.keepdata.Analeptic = (self.keepdata.Jink or 5.2) + 0.1
        -- 特殊情况下还是要留闪，待补充...
    end

    if not self:isWeak() then
        local needDamaged = false
        if self.player:getHp() > getBestHp(self.player) then needDamaged = true end
        if not needDamaged and not sgs.isGoodTarget(self.player, self.friends, self) then needDamaged = true end
        if not needDamaged then
            for _, skill in sgs.qlist(self.player:getVisibleSkillList(true)) do
                local callback = sgs.ai_need_damaged[skill:objectName()]
                if type(callback) == "function" and callback(self, nil, self.player) then
                    needDamaged = true
                    break
                end
            end
        end
        if needDamaged then
            self.keepdata.ThunderSlash = 5.2
            self.keepdata.FireSlash = 5.1
            self.keepdata.Slash = 5
            self.keepdata.Jink = 4.5
        end
    end

    for _, enemy in ipairs(self.enemies) do
        if enemy:hasSkill("nosqianxi") and enemy:distanceTo(self.player) == 1 then
            self.keepdata.Jink = 6
        end
    end

    for _, card in sgs.qlist(self.player:getCards("he")) do
        self.keepValue[card:getId()] = self:getKeepValue(card, self.kept, true)
    end

    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards, true)

    local resetCards = function(allcards)
        local result = {}
        for _, a in ipairs(allcards) do
            local found
            for _, b in ipairs(self.kept) do
                if a:getEffectiveId() == b:getEffectiveId() then
                    found = true
                    break
                end
            end
            if not found then table.insert(result, a) end
        end
        return result
    end

    for i = 1, self.player:getHandcardNum() do
        for _, card in ipairs(cards) do
            self.keepValue[card:getId()] = self:getKeepValue(card, self.kept)
            table.insert(self.kept, card)
            break
        end
        cards = resetCards(cards)
    end
end

function SmartAI:getKeepValue(card, kept, writeMode)
    if type(card) == "number" then global_room:writeToConsole(debug.traceback()) return 0 end
    local owner = self.room:getCardOwner(card:getEffectiveId())
    if owner and owner:objectName() ~= self.player:objectName() then
        self.room:writeToConsole(debug.traceback())
        return sgs.ai_keep_value[card:getClassName()] or 0
    end
    if not kept then
        return self.keepValue[card:getId()] or self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
    end

    local maxvalue = self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
    local mostvaluable_class = card:getClassName()
    for k, v in pairs(self.keepdata) do
        if isCard(k, card, self.player) and v > maxvalue then
            maxvalue = v
            mostvaluable_class = k
        end
    end

    local cardPlace = self.room:getCardPlace(card:getEffectiveId())
    if writeMode then
        if cardPlace == sgs.Player_PlaceEquip then
            if card:isKindOf("Armor") and self:needToThrowArmor() then return -10
            elseif self.player:hasSkills(sgs.lose_equip_skill) then
                if card:isKindOf("OffensiveHorse") then return -10
                elseif card:isKindOf("Weapon") then return -9.9
                elseif card:isKindOf("OffensiveHorse") then return -9.8
                else return -9.7
                end
            elseif self:needKongcheng() then return 5.0
            end
            local value = 0
            if card:isKindOf("Armor") then value = self:isWeak() and 5.2 or 3.2
            elseif card:isKindOf("DefensiveHorse") then value = self:isWeak() and 4.3 or 3.19
            elseif card:isKindOf("Weapon") then value = self.player:getPhase() == sgs.Player_Play and self:slashIsAvailable() and 3.39 or 3.2
            elseif card:isKindOf("OffensiveHorse") then value = 3.17
            else value = 3.18
            end
            if mostvaluable_class ~= card:getClassName() then
                value = value + maxvalue
            end
            return value
        elseif cardPlace == sgs.Player_PlaceHand then
            local value_suit, value_number, newvalue = 0, 0, 0
            local suit_string = card:getSuitString()
            local number = card:getNumber()
            local i = 0

            for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
                if sgs[askill:objectName() .. "_suit_value"] then
                    local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
                    if v then
                        i = i + 1
                        value_suit = value_suit + v
                    end
                end
            end
            if i > 0 then value_suit = value_suit / i end

            i = 0
            for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
                if sgs[askill:objectName() .. "_number_value"] then
                    local v = sgs[askill:objectName() .. "_number_value"][tostring(number)]
                    if v then
                        i = i + 1
                        value_number = value_number + v
                    end
                end
            end
            if i > 0 then value_number = value_number / i end

            newvalue = maxvalue + value_suit + value_number
            if mostvaluable_class ~= card:getClassName() then newvalue = newvalue + 0.1 end
            newvalue = self:adjustKeepValue(card, newvalue)

            return newvalue
        else
            return self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
        end
    end

    local newvalue = self.keepValue[card:getId()] or self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
    if cardPlace == sgs.Player_PlaceHand then
        local dec = 0
        for _, acard in ipairs(kept) do
            if isCard(mostvaluable_class, acard, self.player) then
                newvalue = newvalue - 1.2 - dec
                dec = dec + 0.1
            elseif acard:isKindOf("Slash") and card:isKindOf("Slash") then
                newvalue = newvalue - 1.2 - dec
                dec = dec + 0.1
            end
        end
    end

    return newvalue
end

function SmartAI:adjustKeepValue(card, v)
    local suits = {"club", "spade", "diamond", "heart"}
    for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
        local callback = sgs.ai_suit_priority[askill:objectName()]
        if type(callback) == "function" then
            suits = callback(self, card):split("|")
            break
        elseif type(callback) == "string" then
            suits = callback:split("|")
            break
        end
    end

    table.insert(suits, "no_suit")
    if card:isKindOf("Slash") then
        if card:isRed() then v = v + 0.002 end
        if card:isKindOf("NatureSlash") then v = v + 0.003 end
    end

    if self.player:getPile("wooden_ox"):contains(card:getEffectiveId()) then
        v = v - 0.1
    end

    local suits_value = {}
    for index,suit in ipairs(suits) do
        suits_value[suit] = index
    end
    v = v + (suits_value[card:getSuitString()] or 0) / 1000
    v = v + card:getNumber() / 1000
    return v
end

function SmartAI:getUseValue(card)
    local class_name = card:getClassName()
    local v = sgs.ai_use_value[class_name] or 0
    if class_name == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
        v = sgs.ai_use_value[card:objectName()] or 0
    end

    if card:isKindOf("GuhuoCard") or card:isKindOf("NosGuhuoCard") then
        local userstring = card:toString()
        userstring = (userstring:split(":"))[3]
        local guhuocard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
        local usevalue = self:getUseValue(guhuocard) + #self.enemies * 0.3
        if sgs.Sanguosha:getCard(card:getSubcards():first()):objectName() == userstring
            and (card:isKindOf("GuhuoCard") or card:getSuit() == sgs.Card_Heart) then usevalue = usevalue + 3 end
        return usevalue
    end

    if card:getTypeId() == sgs.Card_TypeEquip then
        if self.player:hasEquip(card) then
            if card:isKindOf("OffensiveHorse") and self.player:getAttackRange() > 2 then return 5.5 end
            if card:isKindOf("DefensiveHorse") and self:hasEightDiagramEffect() then return 5.5 end
            return 9
        end
        if not self:getSameEquip(card) then v = 6.7 end
        if self.weaponUsed and card:isKindOf("Weapon") then v = 2 end
        if self.player:hasSkills(sgs.lose_equip_skill) then return 10 end
    elseif card:getTypeId() == sgs.Card_TypeBasic then
        if card:isKindOf("Slash") then
            v = sgs.ai_use_value[class_name] or 0
            if self:hasHeavySlashDamage(self.player, card) then v = 8.7 end
            if self.player:getPhase() == sgs.Player_Play and self:slashIsAvailable() and #self.enemies > 0 and self:getCardsNum("Slash") == 1 then v = v + 5 end
            if self:hasCrossbowEffect() then v = v + 4 end
            if card:getSkillName() == "spear"   then v = v - 1 end
        elseif card:isKindOf("Jink") then
            if self:getCardsNum("Jink") > 1 then v = v-6 end
        elseif card:isKindOf("Peach") then
            if self.player:isWounded() then v = v + 6 end
        end
    elseif card:getTypeId() == sgs.Card_TypeTrick then
        if self.player:getWeapon() and not self.player:hasSkills(sgs.lose_equip_skill) and card:isKindOf("Collateral") then v = 2 end
        if card:isKindOf("Duel") then v = v + self:getCardsNum("Slash") * 2 end
    end

    if self:hasSkills(sgs.need_kongcheng) then
        if self.player:getHandcardNum() == 1 then v = 10 end
    end

    if self.player:getPile("wooden_ox"):contains(card:getEffectiveId()) then
        v = v + 1
    end

    if self.player:hasWeapon("halberd") and card:isKindOf("Slash") and self.player:isLastHandCard(card) then v = 10 end
    if self.player:getPhase() == sgs.Player_Play then v = self:adjustUsePriority(card, v) end
    return v
end

function SmartAI:getUsePriority(card)
    local class_name = card:getClassName()
    local v = 0
    if card:isKindOf("EquipCard") then
        if self.player:hasSkills(sgs.lose_equip_skill) then return 15 end
        if card:isKindOf("Armor") and not self.player:getArmor() then v = (sgs.ai_use_priority[class_name] or 0) + 5.2
        elseif card:isKindOf("Weapon") and not self.player:getWeapon() then v = (sgs.ai_use_priority[class_name] or 0) + 3
        elseif card:isKindOf("DefensiveHorse") and not self.player:getDefensiveHorse() then v = 5.8
        elseif card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then v = 5.5
        end
        return v
    end

    v = sgs.ai_use_priority[class_name] or 0
    if class_name == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
        v = sgs.ai_use_priority[card:objectName()] or 0
    end
    return self:adjustUsePriority(card, v)
end

function SmartAI:adjustUsePriority(card, v)
    local suits = {"club", "spade", "diamond", "heart"}

    if card:getTypeId() == sgs.Card_Skill then return v end

    for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
        local callback = sgs.ai_suit_priority[askill:objectName()]
        if type(callback) == "function" then
            suits = callback(self, card):split("|")
            break
        elseif type(callback) == "string" then
            suits = callback:split("|")
            break
        end
    end

    table.insert(suits, "no_suit")
    if card:isKindOf("Slash") then
        if card:getSkillName() == "spear" then v = v - 0.1 end
        if card:isRed() then
            v = v - 0.05
        end
        if card:isKindOf("NatureSlash") then
            if self.slashAvail == 1 then
                v = v + 0.05
                if card:isKindOf("FireSlash") then
                    for _, enemy in ipairs(self.enemies) do
                        if enemy:hasArmorEffect("vine") then v = v + 0.07 break end
                    end
                end
            else v = v - 0.05
            end
        end
        if self.slashAvail == 1 then
            v = v + math.min(sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card) * 0.1, 0.5)
            v = v + math.min(sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, card) * 0.05, 0.5)
        end
    end

    if self.player:getPile("wooden_ox"):contains(card:getEffectiveId()) then
        v = v + 0.1
    end

    local suits_value = {}
    for index, suit in ipairs(suits) do
        suits_value[suit] = -index
    end
    v = v + (suits_value[card:getSuitString()] or 0) / 1000
    v = v + (13 - card:getNumber()) / 10000
    return v
end

function SmartAI:getDynamicUsePriority(card)
    if not card then return 0 end

    if card:hasFlag("AIGlobal_KillOff") then return 15 end
    local dynamic_value

    -- direct control
    if card:isKindOf("DelayedTrick") and #card:getSkillName() > 0 then
        return (sgs.ai_use_priority[card:getClassName()] or 0.01) - 0.01
    end

    if card:isKindOf("Duel") then
        if self:hasCrossbowEffect()
            or self.player:canSlashWithoutCrossbow()
            or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0 then
            return sgs.ai_use_priority.Slash - 0.1
        end
    end

    local value = self:getUsePriority(card) or 0
    if card:getTypeId() == sgs.Card_TypeEquip then
        if self.player:hasSkills(sgs.lose_equip_skill) then value = value + 12 end
        if card:isKindOf("Weapon") and self.player:getPhase() == sgs.Player_Play and #self.enemies > 0 then
            self:sort(self.enemies)
            local enemy = self.enemies[1]
            local v, inAttackRange = self:evaluateWeapon(card, self.player, enemy) / 20
            value = value + string.format("%3.3f", v)
            if inAttackRange then value = value + 0.5 end
        end
    end

    if card:isKindOf("AmazingGrace") then
        dynamic_value = 10
        for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            dynamic_value = dynamic_value - 1
            if self:isEnemy(player) then dynamic_value = dynamic_value - ((player:getHandcardNum() + player:getHp()) / player:getHp()) * dynamic_value
            else dynamic_value = dynamic_value + ((player:getHandcardNum() + player:getHp()) / player:getHp()) * dynamic_value
            end
        end
        value = value + dynamic_value
    end

    return value
end

function SmartAI:cardNeed(card)
    if not self.friends then self.room:writeToConsole(debug.traceback()) self.room:writeToConsole(sgs.turncount) return end
    local class_name = card:getClassName()
    local suit_string = card:getSuitString()
    local value
    if card:isKindOf("Peach") then
        self:sort(self.friends,"hp")
        if self.friends[1]:getHp() < 2 then return 10 end
        if self.player:getHp() < 3 or self.player:getLostHp() > 1 then return 14 end
        return self:getUseValue(card)
    end
    if self:isWeak() and card:isKindOf("Jink") and self:getCardsNum("Jink") < 1 then return 12 end

    local i = 0
    for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
        if sgs[askill:objectName() .. "_keep_value"] then
            local v = sgs[askill:objectName() .. "_keep_value"][class_name]
            if v then
                i = i + 1
                if value then value = value + v else value = v end
            end
        end
    end
    if value then return value / i + 4 end
    i = 0
    for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
        if sgs[askill:objectName() .. "_suit_value"] then
            local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
            if v then
                i = i + 1
                if value then value = value + v else value = v end
            end
        end
    end
    if value then return value / i + 4 end

    if card:isKindOf("Slash") and self:getCardsNum("Slash") == 0 then return 5.9 end
    if card:isKindOf("Analeptic") then
        if self.player:getHp() < 2 then return 10 end
    end
    if card:isKindOf("Slash") and (self:getCardsNum("Slash") > 0) then return 4 end
    if card:isKindOf("Weapon") and (not self.player:getWeapon()) and (self:getCardsNum("Slash") > 1) then return 6 end
    if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
        if self:willSkipPlayPhase() or self:willSkipDrawPhase() then return 10 end
        for _, friend in ipairs(self.friends) do
            if self:willSkipPlayPhase(friend) or self:willSkipDrawPhase(friend) then return 9 end
        end
        return 6
    end
    return self:getUseValue(card)
end

-- compare functions
sgs.ai_compare_funcs = {
    hp = function(a, b)
        local c1 = a:getHp()
        local c2 = b:getHp()
        if c1 == c2 then
            return sgs.ai_compare_funcs.defense(a, b)
        else
            return c1 < c2
        end
    end,

    handcard = function(a, b)
        local c1 = a:getHandcardNum()
        local c2 = b:getHandcardNum()
        if c1 == c2 then
            return sgs.ai_compare_funcs.defense(a, b)
        else
            return c1 < c2
        end
    end,

    handcard_defense = function(a, b)
        local c1 = a:getHandcardNum()
        local c2 = b:getHandcardNum()
        if c1 == c2 then
            return  sgs.ai_compare_funcs.defense(a, b)
        else
            return c1 < c2
        end
    end,

    value = function(a, b)
        return sgs.getValue(a) < sgs.getValue(b)
    end,

    chaofeng = function(a, b)
        return sgs.getDefense(a) > sgs.getDefense(b)
    end,

    defense = function(a, b)
        return sgs.getDefenseSlash(a) < sgs.getDefenseSlash(b)
    end,

    threat = function(a, b)
        local players = sgs.QList2Table(a:getRoom():getOtherPlayers(a))
        local d1 = a:getHandcardNum()
        for _, player in ipairs(players) do
            if a:canSlash(player) then
                d1 = d1 + 10 / (sgs.getDefense(player))
            end
        end
        players = sgs.QList2Table(b:getRoom():getOtherPlayers(b))
        local d2 = b:getHandcardNum()
        for _, player in ipairs(players) do
            if b:canSlash(player) then
                d2 = d2 + 10 / (sgs.getDefense(player))
            end
        end

        return d1 > d2
    end,
}

function SmartAI:sort(players, key)
    if not players then self.room:writeToConsole(debug.traceback()) end
    if #players == 0 then return end
    local func
    if not key or key == "defense" or key == "defenseSlash" then
        func = function(a, b)
            return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
        end
    elseif key == "hp" then
        func = function(a, b)
            local c1 = a:getHp()
            local c2 = b:getHp()
            if c1 == c2 then
                return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
            else
                return c1 < c2
            end
        end
    elseif key == "handcard" then
        func = function(a, b)
            local c1 = a:getHandcardNum()
            local c2 = b:getHandcardNum()
            if c1 == c2 then
                return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
            else
                return c1 < c2
            end
        end
    elseif key == "handcard_defense" then
        func = function(a, b, self)
            local c1 = a:getHandcardNum()
            local c2 = b:getHandcardNum()
            if c1 == c2 then
                return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
            else
                return c1 < c2
            end
        end
    else
        func = sgs.ai_compare_funcs[key]
    end

    if not func then self.room:writeToConsole(debug.traceback()) return end

    function _sort(players, key)
        table.sort(players, func)
    end
    if not pcall(_sort, players, key) then self.room:writeToConsole(debug.traceback()) end
end

function SmartAI:sortByKeepValue(cards, inverse, kept)
    local compare_func = function(a, b)
        local v1 = self:getKeepValue(a)
        local v2 = self:getKeepValue(b)

        if v1 ~= v2 then
            if inverse then return v1 > v2 end
            return v1 < v2
        else
            if not inverse then return a:getNumber() > b:getNumber() end
            return a:getNumber() < b:getNumber()
        end
    end

    table.sort(cards, compare_func)
end

function SmartAI:sortByUseValue(cards, inverse)
    local compare_func = function(a, b)
        local value1 = self:getUseValue(a)
        local value2 = self:getUseValue(b)

        if value1 ~= value2 then
            if not inverse then return value1 > value2 end
            return value1 < value2
        else
            if not inverse then return a:getNumber() > b:getNumber() end
            return a:getNumber() < b:getNumber()
        end
    end

    table.sort(cards, compare_func)
end

function SmartAI:sortByUsePriority(cards, player)
    local compare_func = function(a, b)
        local value1 = self:getUsePriority(a)
        local value2 = self:getUsePriority(b)

        if value1 ~= value2 then
            return value1 > value2
        else
            return a:getNumber() > b:getNumber()
        end
    end
    table.sort(cards, compare_func)
end

function SmartAI:sortByDynamicUsePriority(cards)
    local compare_func = function(a,b)
        local value1 = self:getDynamicUsePriority(a)
        local value2 = self:getDynamicUsePriority(b)

        if value1 ~= value2 then
            return value1 > value2
        else
            return a and a:getTypeId() ~= sgs.Card_TypeSkill and not (b and b:getTypeId() ~= sgs.Card_TypeSkill)
        end
    end

    table.sort(cards, compare_func)
end

function SmartAI:sortByCardNeed(cards, inverse)
    local compare_func = function(a,b)
        local value1 = self:cardNeed(a)
        local value2 = self:cardNeed(b)

        if value1 ~= value2 then
            if inverse then return value1 > value2 end
            return value1 < value2
        else
            if not inverse then return a:getNumber() > b:getNumber() end
            return a:getNumber() < b:getNumber()
        end
    end

    table.sort(cards, compare_func)
end


function SmartAI:getPriorTarget()
    if #self.enemies == 0 then return end
    self:sort(self.enemies, "defense")
    return self.enemies[1]
end

function sgs.evaluatePlayerRole(player)
    if not player then global_room:writeToConsole(debug.traceback()) return end
    if player:getRole() == "lord" then return "loyalist" end
    if sgs.isRolePredictable() then return player:getRole() end
    return sgs.ai_role[player:objectName()]
end

function sgs.compareRoleEvaluation(player, first, second)
    if player:isLord() then return "loyalist" end
    if sgs.isRolePredictable() then return player:getRole() end
    if (first == "renegade" or second == "renegade") and sgs.ai_role[player:objectName()] == "renegade" then return "renegade" end
    if sgs.ai_role[player:objectName()] == first then return first end
    if sgs.ai_role[player:objectName()] == second then return second end
    return "neutral"
end

function sgs.isRolePredictable(classical)
    if not classical and sgs.GetConfig("RolePredictable", false) then return true end
    local mode = string.lower(global_room:getMode())
    local isMini = (mode:find("mini") or mode:find("custom_scenario"))
    if (not mode:find("0") and not isMini) or mode =="02p" or mode =="02_1v1" or mode == "06_3v3" or mode == "06_XMode" 
        or (not classical and isMini) then return true end
    return false
end

function sgs.findIntersectionSkills(first, second)
    if type(first) == "string" then first = first:split("|") end
    if type(second) == "string" then second = second:split("|") end

    local findings = {}
    for _, skill in ipairs(first) do
        for _, compare_skill in ipairs(second) do
            if skill == compare_skill and not table.contains(findings, skill) then table.insert(findings, skill) end
        end
    end
    return findings
end

function sgs.findUnionSkills(first, second)
    if type(first) == "string" then first = first:split("|") end
    if type(second) == "string" then second = second:split("|") end

    local findings = table.copyFrom(first)
    for _, skill in ipairs(second) do
        if not table.contains(findings, skill) then table.insert(findings, skill) end
    end

    return findings
end

sgs.ai_card_intention.general = function(from, to, level)
    if sgs.isRolePredictable() then return end
    if not to then global_room:writeToConsole(debug.traceback()) return end
    if from:isLord() or level == 0 then return end
    if sgs.ai_doNotUpdateIntenion then
        sgs.ai_doNotUpdateIntenion = nil
        level = 0
    end

    -- 将level固定为 10或者-10，目的是由原来的忠反值的变化 更改为 统计AI跳身份的行为次数，因为感觉具体的level值不太好把握，容易出现忠反值不合理飙涨的情况
    level = level > 0 and 10 or -10

    sgs.outputRoleValues(from, level)

    local loyalist_value = sgs.role_evaluation[from:objectName()]["loyalist"]
    local renegade_value = sgs.role_evaluation[from:objectName()]["renegade"]

    local hasRebel = sgs.current_mode_players["rebel"] > 0
    local hasRenegade = sgs.current_mode_players["renegade"] > 0
    local hasLoyalist = sgs.current_mode_players["loyalist"] > 0

    if sgs.evaluatePlayerRole(to) == "loyalist" then

        if not to:isLord() and (sgs.UnknownRebel or sgs.role_evaluation[to:objectName()]["renegade"] > 0 and not sgs.explicit_renegade) then
        elseif (hasRebel and level > 0) or ((hasRenegade or hasLoyalist) and level < 0) then
            sgs.role_evaluation[from:objectName()]["loyalist"] = sgs.role_evaluation[from:objectName()]["loyalist"] - level
        end

        if hasRenegade then
            if sgs.UnknownRebel and not hasRenegade and hasLoyalist and level > 0 then
                    --反装忠
            elseif not hasRebel and not to:isLord() and hasLoyalist and level > 0 and sgs.explicit_renegade == false then
                    -- 进入主忠内, 但是没人跳过内，这个时候忠臣之间的相互攻击，不更新内奸值
            elseif hasRenegade and (sgs.ai_role[from:objectName()] == "loyalist" and level > 0
                                    or sgs.ai_role[from:objectName()] == "renegade" and level > 0
                                    or sgs.ai_role[from:objectName()] == "rebel" and level < 0) then
                sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + math.abs(level)
            elseif level > 0 and to:isLord() and hasRenegade and (sgs.ai_role[from:objectName()] == "loyalist" or sgs.ai_role[from:objectName()] == "renegade") then
                sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + math.abs(level)
            end
        end

    elseif sgs.evaluatePlayerRole(to) == "rebel" then
        sgs.role_evaluation[from:objectName()]["loyalist"] = sgs.role_evaluation[from:objectName()]["loyalist"] + level

        if hasRenegade and (sgs.ai_role[from:objectName()] == "loyalist" and level < 0
                or sgs.ai_role[from:objectName()] == "renegade" and level < 0
                or sgs.ai_role[from:objectName()] == "rebel" and level > 0) then
            sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + math.abs(level)
        end
    end

    for _, p in sgs.qlist(global_room:getAlivePlayers()) do
        sgs.ais[p:objectName()]:updatePlayers(true, p:isLord())
    end

    sgs.outputRoleValues(from, level)
end

function sgs.outputRoleValues(player, level)
    global_room:writeToConsole(player:getGeneralName() .. " " .. level .. " " .. sgs.evaluatePlayerRole(player)
                                .. " L:" .. math.ceil(sgs.role_evaluation[player:objectName()]["loyalist"])
                                .. " R:" .. math.ceil(sgs.role_evaluation[player:objectName()]["renegade"])
                                .. " " .. sgs.gameProcess(player:getRoom()) .. "," .. string.format("%3.3f", sgs.gameProcess(player:getRoom(), 1))
                                .. " " .. sgs.current_mode_players["loyalist"] .. sgs.current_mode_players["rebel"] .. sgs.current_mode_players["renegade"])
end

function sgs.updateIntention(from, to, intention, card)
    if not to then global_room:writeToConsole(debug.traceback()) return end
    if from:objectName() == to:objectName() then return end

    sgs.ai_card_intention.general(from, to, intention)
end

function sgs.updateIntentions(from, tos, intention, card)
    for _, to in ipairs(tos) do
        sgs.updateIntention(from, to, intention, card)
    end
end

function sgs.isLordHealthy()
    local lord = global_room:getLord()
    local lord_hp
    if not lord then return true end
    lord_hp = lord:getHp()
    return lord_hp > 3 or (lord_hp > 2 and sgs.getDefense(lord) > 3)
end

function sgs.isLordInDanger()
    local lord = global_room:getLord()
    local lord_hp
    if not lord then return false end
    lord_hp = lord:getHp()
    return lord_hp < 3
end

function sgs.gameProcess(room, arg, update)
    if not update then
        if arg then
            if sgs.ai_gameProcess_arg then return sgs.ai_gameProcess_arg end
        elseif sgs.ai_gameProcess then return sgs.ai_gameProcess
        end
    end
    local rebel_num = sgs.current_mode_players["rebel"]
    local loyal_num = sgs.current_mode_players["loyalist"]

    if rebel_num == 0 and loyal_num > 0 then
        if arg then sgs.ai_gameProcess_arg = 99 return 99
        else sgs.ai_gameProcess = "loyalist" return "loyalist"
        end
    elseif loyal_num == 0 and rebel_num > 1 then
        if arg then sgs.ai_gameProcess_arg = -99 return -99
        else sgs.ai_gameProcess = "rebel" return "rebel"
        end
    end

    local loyal_value, rebel_value = 0, 0, 0
    local health = sgs.isLordHealthy()
    local danger = sgs.isLordInDanger()
    local lord = room:getLord()
    local currentplayer = room:getCurrent()
    for _, aplayer in sgs.qlist(room:getAlivePlayers()) do
        local role = aplayer:getRole()
        local hp = aplayer:getHp()
        if role == "rebel" then
            rebel_value = rebel_value + hp + math.max(sgs.getDefense(aplayer) - hp * 2, 0) * 0.5
            if lord and aplayer:inMyAttackRange(lord) then rebel_value = rebel_value + 0.4 end
        elseif role == "loyalist" or role == "lord" then
            loyal_value = loyal_value + hp + math.max(sgs.getDefense(aplayer) - hp * 2, 0) * 0.5
        end
    end
    local diff = loyal_value - rebel_value + (loyal_num + 1 - rebel_num) * 3
    if arg then sgs.ai_gameProcess_arg = diff end

    local process = "neutral"
    if diff >= 4 then
        if health then process = "loyalist"
        else process = "dilemma" end
    elseif diff >= 2 then
        if health then process = "loyalish"
        elseif danger then process = "dilemma"
        else process = "rebelish" end
    elseif diff <= -4 then process = "rebel"
    elseif diff <= -2 then
        if health then process = "rebelish"
        else process = "rebel" end
    elseif not health then process = "rebelish"
    else process = "neutral"
    end
    sgs.ai_gameProcess = process
    if arg then return diff end
    return process
end

function SmartAI:objectiveLevel(player)
    if player:objectName() == self.player:objectName() then return -2 end

    local players = self.room:getOtherPlayers(self.player)
    players = sgs.QList2Table(players)

    if #players == 1 then return 5 end

    if sgs.isRolePredictable(true) then
        if self.lua_ai:isFriend(player) then return -2
        elseif self.lua_ai:isEnemy(player) then return 5
        elseif self.lua_ai:relationTo(player) == sgs.AI_Neutrality then
            if self.lua_ai:getEnemies():isEmpty() then return 4 else return 0 end
        else return 0 end
    end

    local rebel_num = sgs.current_mode_players["rebel"]
    local loyal_num = sgs.current_mode_players["loyalist"]
    local renegade_num = sgs.current_mode_players["renegade"]
    local target_role = sgs.evaluatePlayerRole(player)

    if self.role == "renegade" then
        if player:isLord() and not sgs.GetConfig("EnableHegemony", false) and self.room:getMode() ~= "couple"
            and player:getHp() <= 0 and player:hasFlag("Global_Dying") then return -2 end

        if target_role == "rebel" and player:getHp() <= 1 and not hasBuquEffect(player) and player:isKongcheng()
            and getCardsNum("Peach", player, self.player) == 0 and getCardsNum("Analepic", player, self.player) == 0 then return 5 end

        if rebel_num == 0 or loyal_num == 0 then
            if rebel_num > 0 then
                if rebel_num > 1 then
                    if player:isLord() then
                        return -2
                    elseif target_role == "rebel" then
                        return 5
                    else
                        return 0
                    end
                elseif renegade_num > 1 then
                    if player:isLord() then
                        return 0
                    elseif target_role == "renegade" then
                        return 3
                    else
                        return 5
                    end
                else
                    local process = sgs.gameProcess(self.room)
                    if process == "loyalist" then
                        if player:isLord() then
                            if not sgs.isLordHealthy() then return -1
                            else return 1 end
                        elseif target_role == "rebel" then
                            return 0
                        else
                            return 5
                        end
                    elseif process:match("rebel") then
                        if target_role == "rebel" then
                            return 5
                        else
                            return -1
                        end
                    else
                        if player:isLord() then
                            return 0
                        else
                            return 5
                        end
                    end
                end
            elseif loyal_num > 0 then
                if sgs.explicit_renegade and renegade_num == 1 and sgs.role_evaluation[self.player:objectName()]["renegade"] == 0
                    and sgs.evaluatePlayerRole(self.player) == "loyalist" then
                    if target_role == "renegade" then return 5 else return -1 end
                end
                if player:isLord() then
                    if not sgs.explicit_renegade and sgs.role_evaluation[self.player:objectName()]["renegade"] == 0 then return 0 end
                    if not sgs.isLordHealthy() then return 0
                    else return 1 end
                elseif target_role == "renegade" and renegade_num > 1 then
                    return 3
                else
                    return 5
                end
            else
                if player:isLord() then
                    if sgs.isLordInDanger then return 0
                    elseif not sgs.isLordHealthy() then return 3
                    else return 5 end
                elseif sgs.isLordHealthy() then return 3
                else
                    return 5
                end
            end
        end
        local process = sgs.gameProcess(self.room)
        if process == "neutral" or (sgs.turncount <= 1 and sgs.isLordHealthy()) then
            if sgs.turncount <= 1 and sgs.isLordHealthy() then
                if renegade_num > 1 then return 0
                elseif self:getOverflow() <= -1 then return 0 end
                local rebelish = (loyal_num + 1 < rebel_num)
                if player:isLord() then return rebelish and -1 or 0 end
                if target_role == "loyalist" then return rebelish and 0 or 3.5
                elseif target_role == "rebel" then return rebelish and 3.5 or 0
                else return 0
                end
            end
            if player:isLord() then return -1 end
            local renegade_attack_skill = string.format("%s|%s|%s|%s", sgs.priority_skill, sgs.save_skill, sgs.recover_skill, sgs.drawpeach_skill)
            for i = 1, #players, 1 do
                if not players[i]:isLord() and players[i]:hasSkills(renegade_attack_skill) then return 5 end
            end
            return self:getOverflow() > 0 and 3 or 0
        elseif process:match("rebel") then
            return target_role == "rebel" and 5 or target_role == "neutral" and 0 or -1
        elseif process:match("dilemma") then
            if target_role == "rebel" then return 5
            elseif target_role == "loyalist" or target_role == "renegade" then return 0
            elseif player:isLord() then return -2
            else return 5 end
        elseif process == "loyalish" then
            if player:isLord() or target_role == "renegade" then return 0 end
            local rebelish = (sgs.current_mode_players["loyalist"] + 1 < sgs.current_mode_players["rebel"])
            if target_role == "loyalist" then return rebelish and 0 or 3.5
            elseif target_role == "rebel" then return rebelish and 3.5 or 0
            else return 0
            end
        else
            if player:isLord() or target_role == "renegade" then return 0 end
            return target_role == "rebel" and -2 or 5
        end
    end

    if self.player:isLord() or self.role == "loyalist" then
        if player:isLord() then return -2 end

        if loyal_num == 0 and renegade_num == 0 then return 5 end

        if self.role == "loyalist" and loyal_num == 1 and renegade_num == 0 then return 5 end

        if sgs.ai_role[player:objectName()] == "neutral" then
            if rebel_num > 0 then
                local current_friend_num, current_enemy_num, current_renegade_num = 0, 0, 0
                local mode = self.room:getMode()
                local consider_renegade = mode == "05p" or mode == "07p" or mode == "09p"
                local rebelish = sgs.gameProcess(self.room):match("rebel")
                for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
                    if sgs.ai_role[aplayer:objectName()] == "loyalist" or aplayer:objectName() == self.player:objectName() then
                        current_friend_num = current_friend_num + 1
                    elseif sgs.ai_role[aplayer:objectName()] == "renegade" then
                        current_renegade_num = current_renegade_num + 1
                    elseif sgs.ai_role[aplayer:objectName()] == "rebel" then
                        current_enemy_num = current_enemy_num + 1
                    end
                end
                if current_friend_num + ((consider_renegade or rebelish) and current_renegade_num or 0) >= loyal_num + ((rebelish or consider_renegade) and renegade_num or 0) + 1 then
                    return self:getOverflow() > -1 and 5 or 3
                elseif current_enemy_num + (consider_renegade and current_renegade_num or rebelish and 0 or current_renegade_num)
                    >= rebel_num + (consider_renegade and renegade_num or rebelish and 0 or renegade_num) then
                    return -1
                elseif self:getOverflow() > -1 and (current_friend_num + ((consider_renegade or rebelish) and current_renegade_num or 0) + 1
                    == loyal_num + ((rebelish or consider_renegade) and renegade_num or 0) + 1) and current_enemy_num <= 1 and current_enemy_num / rebel_num < 0.35 then
                    return 1
                end
            elseif sgs.explicit_renegade and renegade_num == 1 then return -1 end
        end

        if rebel_num == 0 then
            if #players == 2 and self.role == "loyalist" then return 5 end

            if self.player:isLord() and player:getHp() <= 2 and self:hasHeavySlashDamage(self.player, nil, player) then
                return 0
            end

            if not sgs.explicit_renegade then
                self:sort(players, "hp")
                local maxhp = players[#players]:isLord() and players[#players - 1]:getHp() or players[#players]:getHp()
                if maxhp > 2 then return player:getHp() == maxhp and 5 or 0 end
                if maxhp == 2 then return self.player:isLord() and 0 or (player:getHp() == maxhp and 5 or 1) end
                return self.player:isLord() and 0 or 5
            else
                if self.player:isLord() then
                    if target_role == "loyalist" then return -2
                    elseif target_role == "renegade" and sgs.role_evaluation[player:objectName()]["renegade"] > 50 then
                        return 5
                    else
                        return player:getHp() > 1 and 4 or 0
                    end
                else
                    if self.role == "loyalist" and sgs.ai_role[self.player:objectName()] == "renegade" then
                        local renegade_value, renegade_player = 0
                        for _, p in ipairs(players) do
                            if sgs.role_evaluation[p:objectName()]["renegade"] > 0 then
                                renegade_value = sgs.role_evaluation[p:objectName()]["renegade"]
                                renegade_player = p
                            end
                        end
                        if renegade_player then return renegade_player:objectName() == player:objectName() and 5 or -2
                        else return 4 end
                    else
                        if target_role == "loyalist" then return -2
                        else return 4 end
                    end
                end
            end
        end
        if loyal_num == 0 then
            if rebel_num > 2 then
                if target_role == "renegade" then return -1 end
            elseif rebel_num > 1 then
                if target_role == "renegade" then return (tonumber(player:getHp()) - 1) end
            elseif target_role == "renegade" then return sgs.isLordInDanger() and -1 or (tonumber(player:getHp()) + 1) end
        end
        if renegade_num == 0 then
            if sgs.ai_role[player:objectName()] == "loyalist" then return -2 end

            if rebel_num > 0 and sgs.turncount > 1 then
                local hasRebel
                for _, p in ipairs(players) do
                    if sgs.ai_role[p:objectName()] == "rebel" then hasRebel = true sgs.UnknownRebel = false break end
                end
                if not hasRebel then
                    sgs.UnknownRebel = true
                    local newplayers = {}
                    for _, p in ipairs(players) do
                        table.insert(newplayers, p)
                    end
                    self:sort(newplayers, "hp")
                    local maxhp = newplayers[#newplayers]:isLord() and newplayers[#newplayers - 1]:getHp() or newplayers[#newplayers]:getHp()
                    if maxhp > 2 then return player:getHp() == maxhp and 5 or 0 end
                    if maxhp == 2 then return self.player:isLord() and 0 or (player:getHp() == maxhp and 5 or 1) end
                    return self.player:isLord() and 0 or 5
                end
            end
        end

        if sgs.ai_role[player:objectName()] == "rebel" then return 5
        elseif sgs.ai_role[player:objectName()] == "loyalist" then return -2 end
        if target_role == "renegade" then
            if sgs.gameProcess(self.room):match("rebel") then return -2
            else return sgs.isLordInDanger() and 0 or (tonumber(player:getHp()) + 1) end
        end
        return 0
    elseif self.role == "rebel" then

        if loyal_num == 0 and renegade_num == 0 then return player:isLord() and 5 or -2 end

        if sgs.ai_role[player:objectName()] == "neutral" then
            local current_friend_num, current_enemy_num, current_renegade_num = 0, 0, 0
            for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
                if sgs.ai_role[aplayer:objectName()] == "rebel" or aplayer:objectName() == self.player:objectName() then
                    current_friend_num = current_friend_num + 1
                elseif sgs.ai_role[aplayer:objectName()] == "renegade" then current_renegade_num = current_renegade_num + 1
                elseif sgs.ai_role[aplayer:objectName()] == "loyalist" then current_enemy_num = current_enemy_num + 1 end
            end
            local loyalish = sgs.gameProcess(self.room):match("loyal")
            local mode = self.room:getMode()
            local consider_renegade = mode == "05p" or mode == "07p" or mode == "09p"
            if current_friend_num + ((consider_renegade or loyalish) and current_renegade_num or 0) >= rebel_num + ((consider_renegade or loyalish) and renegade_num or 0) then
                return self:getOverflow() > -1 and 5 or 3
            elseif current_enemy_num + (consider_renegade and current_renegade_num or loyalish and 0 or current_renegade_num)
                >= loyal_num + (consider_renegade and renegade_num or loyalish and 0 or renegade_num) + 1 then
                return -1
            elseif loyal_num + renegade_num > 0 and self:getOverflow() > -1 and (current_friend_num + ((consider_renegade or loyalish) and current_renegade_num or 0) + 1
                == rebel_num + ((consider_renegade or loyalish) and renegade_num or 0)) and current_enemy_num <= 1 and current_enemy_num / (loyal_num + renegade_num) < 0.35 then
                return 1
            else
                return 0
            end
        end

        if player:isLord() then return 5
        elseif sgs.ai_role[player:objectName()] == "loyalist" then return 5 end
        local gameProcess = sgs.gameProcess(self.room)
        if target_role == "rebel" then return (rebel_num > 1 or renegade_num > 0 and gameProcess:match("loyal")) and -2 or 5 end
        if target_role == "renegade" then return gameProcess:match("loyal") and -1 or (tonumber(player:getHp()) + 1) end
        return 0
    end
    return 0
end

function SmartAI:isFriend(other, another)
    if not other then self.room:writeToConsole(debug.traceback()) return end
    if another then
        local of, af = self:isFriend(other), self:isFriend(another)
        return of ~= nil and af ~= nil and of == af
    end
    if sgs.isRolePredictable(true) and self.lua_ai:relationTo(other) ~= sgs.AI_Neutrality then return self.lua_ai:isFriend(other) end
    if self.player:objectName() == other:objectName() then return true end
    local obj_level = self:objectiveLevel(other)
    if obj_level < 0 then return true
    elseif obj_level == 0 then return nil end
    local mode = string.lower(global_room:getMode())
    return false
end

function SmartAI:isEnemy(other, another)
    if not other then self.room:writeToConsole(debug.traceback()) return end
    if another then
        local of, af = self:isFriend(other), self:isFriend(another)
        return of ~= nil and af ~= nil and of ~= af
    end
    if sgs.isRolePredictable(true) and self.lua_ai:relationTo(other) ~= sgs.AI_Neutrality then return self.lua_ai:isEnemy(other) end
    if self.player:objectName() == other:objectName() then return false end
    local obj_level = self:objectiveLevel(other)
    if obj_level > 0 then return true
    elseif obj_level == 0 then return nil end
    local mode = string.lower(global_room:getMode())
    return false
end

function SmartAI:getFriendsNoself(player)
    player = player or self.player
    local friends_noself = {}
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if self:isFriend(p, player) and p:objectName() ~= player:objectName() then table.insert(friends_noself, p) end
    end
    return friends_noself
end

function SmartAI:getFriends(player)
    player = player or self.player
    local friends = {}
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if self:isFriend(p, player) then table.insert(friends, p) end
    end
    return friends
end

function SmartAI:getEnemies(player)
    local enemies = {}
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if self:isEnemy(p, player) then table.insert(enemies, p) end
    end
    return enemies
end

function SmartAI:sortEnemies(players)
    local comp_func = function(a, b)
        local alevel = self:objectiveLevel(a)
        local blevel = self:objectiveLevel(b)

        if alevel ~= blevel then return alevel > blevel end
        return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
    end
    table.sort(players, comp_func)
end

function sgs.updateAlivePlayerRoles()
    for _, arole in ipairs({"lord", "loyalist", "rebel", "renegade"}) do
        sgs.current_mode_players[arole] = 0
    end
    for _, aplayer in sgs.qlist(global_room:getAllPlayers()) do
        sgs.current_mode_players[aplayer:getRole()] = sgs.current_mode_players[aplayer:getRole()] + 1
    end
end

function SmartAI:updatePlayers(clear_flags, update)
    if clear_flags ~= false then clear_flags = true end
    if update ~= false then update = true end
    if self.role ~= self.player:getRole() then
        if not ((self.role == "lord" and self.player:getRole() == "loyalist") or (self.role == "loyalist" and self.player:getRole() == "lord")) then
            sgs.role_evaluation[self.player:objectName()]["loyalist"] = 0
            sgs.role_evaluation[self.player:objectName()]["rebel"] = 0
            sgs.role_evaluation[self.player:objectName()]["renegade"] = 0
        end
        self.role = self.player:getRole()
    end
    if sgs.isRolePredictable() and sgs.ai_role[self.player:objectName()] ~= self.player:getRole()
            and not (self.player:getRole() == "lord" and sgs.ai_role[self.player:objectName()] == "loyalist") then self:adjustAIRole() end
    if clear_flags then
        for _, aflag in ipairs(sgs.ai_global_flags) do
            sgs[aflag] = nil
        end
    end

    sgs.updateAlivePlayerRoles()

    if update then
        sgs.updateAlivePlayerRoles()
        sgs.gameProcess(self.room, 1, true)
    end

    if sgs.isRolePredictable(true) then
        self.friends = {}
        self.friends_noself = {}
        local friends = sgs.QList2Table(self.lua_ai:getFriends())
        for i = 1, #friends, 1 do
            if friends[i]:isAlive() and friends[i]:objectName() ~= self.player:objectName() then
                table.insert(self.friends, friends[i])
                table.insert(self.friends_noself, friends[i])
            end
        end
        table.insert(self.friends, self.player)

        local enemies = sgs.QList2Table(self.lua_ai:getEnemies())
        for i = 1, #enemies, 1 do
            if enemies[i]:isDead() or enemies[i]:objectName() == self.player:objectName() then table.remove(enemies, i) end
        end
        self.enemies = enemies

        self.retain = 2
        self.harsh_retain = false
        if #self.enemies == 0 then
            local neutrality = {}
            for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                if self.lua_ai:relationTo(aplayer) == sgs.AI_Neutrality and not aplayer:isDead() then table.insert(neutrality, aplayer) end
            end
            local function compare_func(a, b)
                return self:objectiveLevel(a) > self:objectiveLevel(b)
            end
            table.sort(neutrality, compare_func)
            table.insert(self.enemies, neutrality[1])
        end
        return
    end

    if update and not sgs.isRolePredictable() then sgs.evaluateAlivePlayersRole() end
    self.enemies = {}
    self.friends = {}
    self.friends_noself = {}

    self.retain = 2
    self.harsh_retain = true

    for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local level = self:objectiveLevel(player)
        if level < 0 then
            table.insert(self.friends_noself, player)
            table.insert(self.friends, player)
        elseif level > 0 then
            table.insert(self.enemies, player)
        end
    end
    table.insert(self.friends, self.player)
end

function sgs.evaluateAlivePlayersRole()
    local players = sgs.QList2Table(global_room:getAlivePlayers())
    sgs.explicit_renegade = false
    local cmp = function(a, b)
        local ar_value, br_value = sgs.role_evaluation[a:objectName()]["renegade"], sgs.role_evaluation[b:objectName()]["renegade"]
        local al_value, bl_value = sgs.role_evaluation[a:objectName()]["loyalist"], sgs.role_evaluation[b:objectName()]["loyalist"]
        return (ar_value > br_value) or (ar_value == br_value and al_value > bl_value)
    end
    table.sort(players, cmp)

    local l_count, R_count, r_count = sgs.current_mode_players["loyalist"], sgs.current_mode_players["renegade"], sgs.current_mode_players["rebel"]
    local renegade, loyalist, rebel = 0, 0, 0

    for i = 1, #players, 1 do
        local p = players[i]
        if i <= sgs.current_mode_players["renegade"] and sgs.role_evaluation[p:objectName()]["renegade"] >= 10
            and not (sgs.role_evaluation[p:objectName()]["renegade"] <= 10 and sgs.role_evaluation[p:objectName()]["loyalist"] <= -50) then
            renegade = renegade + 1
            sgs.ai_role[p:objectName()] = "renegade"
            sgs.explicit_renegade = sgs.role_evaluation[p:objectName()]["renegade"] >= (sgs.current_mode_players["rebel"] == 0 and 10 or 20)
        else
            if sgs.role_evaluation[p:objectName()]["loyalist"] > 0 and sgs.current_mode_players["loyalist"] > 0 or p:isLord() then
                sgs.ai_role[p:objectName()] = "loyalist"
                loyalist = loyalist + 1
            elseif sgs.role_evaluation[p:objectName()]["loyalist"] < 0 and sgs.current_mode_players["rebel"] > 0 then
                sgs.ai_role[p:objectName()] = "rebel"
                rebel = rebel + 1
            else
                if sgs.current_mode_players["renegade"] > renegade and (sgs.role_evaluation[p:objectName()]["loyalist"] > 0 or sgs.role_evaluation[p:objectName()]["loyalist"] < 0) then
                    sgs.ai_role[p:objectName()] = "renegade"
                    sgs.explicit_renegade = true
                    renegade = renegade + 1
                else
                    sgs.ai_role[p:objectName()] = "neutral"
                end
            end
        end
        if sgs.current_mode_players["rebel"] == 0 and sgs.current_mode_players["loyalist"] == 0 and not p:isLord() then
            renegade = renegade + 1
            sgs.ai_role[p:objectName()] = "renegade"
            sgs.explicit_renegade = true
        end
    end

    if renegade > 0 and loyalist + renegade > l_count + R_count and rebel < r_count then
        local lR_players = {}
        for _, p in ipairs(players) do
            if sgs.ai_role[p:objectName()] == "loyalist" or sgs.ai_role[p:objectName()] == "renegade" then
                table.insert(lR_players, p)
            end
        end
        cmp_rebel = function(a, b)
            return sgs.role_evaluation[a:objectName()]["loyalist"] < sgs.role_evaluation[b:objectName()]["loyalist"]
        end
        table.sort(lR_players, cmp_rebel)
        for _, p in ipairs(lR_players) do
            local name = p:objectName()
            if sgs.role_evaluation[name]["loyalist"] < 0 and sgs.role_evaluation[name]["renegade"] > 0 then
                sgs.role_evaluation[name]["loyalist"] = math.min(-sgs.role_evaluation[name]["renegade"], sgs.role_evaluation[name]["loyalist"])
                sgs.role_evaluation[name]["renegade"] = 0
                sgs.ai_role[name] = "rebel"
                sgs.outputRoleValues(p, 0)
                global_room:writeToConsole("rebel:" .. p:getGeneralName() .." Modified Success!")
                rebel = rebel + 1
                if rebel == r_count then break end
            end
        end
    end
end

---查找room内指定objectName的player
function findPlayerByObjectName(room, name, include_death, except)
    if not room then
        return
    end
    local players = nil
    if include_death then
        players = room:getPlayers()
    else
        players = room:getAllPlayers()
    end
    if except then
        players:removeOne(except)
    end
    for _,p in sgs.qlist(players) do
        if p:objectName() == name then
            return p
        end
    end
end

function getTrickIntention(trick_class, target)
    local intention = sgs.ai_card_intention[trick_class]
    if type(intention) == "number" then
        return intention
    elseif type(intention == "function") then
        if trick_class == "IronChain" then
            if target and target:isChained() then return -60 else return 60 end
        elseif trick_class == "Drowning" then
            if target and target:getArmor() and target:hasSkills("yizhong|bazhen") then return 0 else return 60 end
        end
    end
    if trick_class == "Collateral" then return 0 end
    if sgs.dynamic_value.damage_card[trick_class] then
        return 70
    end
    if sgs.dynamic_value.benefit[trick_class] then
        return -40
    end
    if target then
        if trick_class == "Snatch" or trick_class == "Dismantlement" then
            local judgelist = target:getCards("j")
            if not judgelist or judgelist:isEmpty() then
                if not target:hasArmorEffect("silver_lion") or not target:isWounded() then
                    return 80
                end
            end
        end
    end
    return 0
end

sgs.ai_choicemade_filter.Nullification.general = function(self, player, promptlist)
    local trick_class = promptlist[2]
    local target_objectName = promptlist[3]
    if trick_class == "Nullification" then
        if not sgs.nullification_source or not sgs.nullification_intention or type(sgs.nullification_intention) ~= "number" then
            self.room:writeToConsole(debug.traceback())
            return
        end
        sgs.nullification_level = sgs.nullification_level + 1
        if sgs.nullification_level % 2 == 0 then
            sgs.updateIntention(player, sgs.nullification_source, sgs.nullification_intention)
        elseif sgs.nullification_level % 2 == 1 then
            sgs.updateIntention(player, sgs.nullification_source, -sgs.nullification_intention)
        end
    else
        sgs.nullification_source = findPlayerByObjectName(global_room, target_objectName)
        sgs.nullification_level = 1
        sgs.nullification_intention = getTrickIntention(trick_class, sgs.nullification_source)
        if player:objectName() ~= target_objectName then
            sgs.updateIntention(player, sgs.nullification_source, -sgs.nullification_intention)
        end
    end
end

sgs.ai_choicemade_filter.playerChosen.general = function(self, from, promptlist)
    if from:objectName() == promptlist[3] then return end
    local reason = string.gsub(promptlist[2], "%-", "_")
    local to = findPlayerByObjectName(self.room, promptlist[3])
    local callback = sgs.ai_playerchosen_intention[reason]
    if callback then
        if type(callback) == "number" then
            sgs.updateIntention(from, to, sgs.ai_playerchosen_intention[reason])
        elseif type(callback) == "function" then
            callback(self, from, to)
        end
    end
end

sgs.ai_choicemade_filter.viewCards.general = function(self, from, promptlist)
    local to = findPlayerByObjectName(self.room, promptlist[#promptlist])
    if to and not to:isKongcheng() then
        local flag = string.format("%s_%s_%s", "visible", from:objectName(), to:objectName())
        for _, card in sgs.qlist(to:getHandcards()) do
            if not card:hasFlag("visible") then card:setFlags(flag) end
        end
    end
end

sgs.ai_choicemade_filter.Yiji.general = function(self, from, promptlist)
    local from = findPlayerByObjectName(self.room, promptlist[3])
    local to = findPlayerByObjectName(self.room, promptlist[4])
    local reason = promptlist[2]
    local cards = {}
    local card_ids = promptlist[5]:split("+")
    for _, id in ipairs(card_ids) do
        local card = sgs.Sanguosha:getCard(tonumber(id))
        table.insert(cards, card)
    end
    if from and to then
        local callback = sgs.ai_Yiji_intention[reason]
        if callback then
            if type(callback) == "number" and not (self:needKongcheng(to, true) and #cards == 1) then
                sgs.updateIntention(from, to, sgs.ai_Yiji_intention[reason])
            elseif type(callback) == "function" then
                callback(self, from, to, cards)
            end
        elseif not (self:needKongcheng(to, true) and #cards == 1) then
            sgs.updateIntention(from, to, -10)
        end
    end
end

function SmartAI:filterEvent(event, player, data)
    if not sgs.recorder then
        sgs.recorder = self
        --self.player:speak(version)
    end
    if player:objectName() == self.player:objectName() then
        if sgs.debugmode and type(sgs.ai_debug_func[event]) == "table" then
            for _, callback in pairs(sgs.ai_debug_func[event]) do
                if type(callback) == "function" then callback(self, player, data) end
            end
        end
        if type(sgs.ai_chat_func[event]) == "table" and sgs.GetConfig("AIChat", false) and sgs.GetConfig("OriginAIDelay", 0) > 0 then
            for _, callback in pairs(sgs.ai_chat_func[event]) do
                if type(callback) == "function" then callback(self, player, data) end
            end
        end
        if type(sgs.ai_event_callback[event]) == "table" then
            for _, callback in pairs(sgs.ai_event_callback[event]) do
                if type(callback) == "function" then callback(self, player, data) end
            end
        end
    end

    if sgs.DebugMode_Niepan and event == sgs.AskForPeaches then endlessNiepan(data:toDying().who) end

    sgs.lastevent = event
    sgs.lasteventdata = data
    if event == sgs.ChoiceMade and (self == sgs.recorder or self.player:objectName() == sgs.recorder.player:objectName()) then
        local carduse = data:toCardUse()
        if carduse and carduse.card ~= nil then
            for _, aflag in ipairs(sgs.ai_global_flags) do
                sgs[aflag] = nil
            end
            for _, callback in ipairs(sgs.ai_choicemade_filter.cardUsed) do
                if type(callback) == "function" then
                    callback(self, player, carduse)
                end
            end
        elseif data:toString() then
            promptlist = data:toString():split(":")
            local callbacktable = sgs.ai_choicemade_filter[promptlist[1]]
            if callbacktable and type(callbacktable) == "table" then
                local index = 2
                if promptlist[1] == "cardResponded" then

                    if promptlist[2]:match("jink") then sgs.card_lack[player:objectName()]["Jink"] = promptlist[#promptlist] == "_nil_" and 1 or 0
                    elseif promptlist[2]:match("slash") then sgs.card_lack[player:objectName()]["Slash"] = promptlist[#promptlist] == "_nil_" and 1 or 0
                    elseif promptlist[2]:match("peach") then sgs.card_lack[player:objectName()]["Peach"] = promptlist[#promptlist] == "_nil_" and 1 or 0
                    end

                    index = 3
                end
                local callback = callbacktable[promptlist[index]] or callbacktable.general
                if type(callback) == "function" then
                    callback(self, player, promptlist)
                end
            end
        end
    elseif event == sgs.CardFinished or event == sgs.GameStart or event == sgs.EventPhaseStart then
        self:updatePlayers(true, self == sgs.recorder)
    elseif event == sgs.BuryVictim or event == sgs.HpChanged or event == sgs.MaxHpChanged then
        self:updatePlayers(false, self == sgs.recorder)
    end

    if event == sgs.BuryVictim then
        if self == sgs.recorder then sgs.updateAlivePlayerRoles() end
    end

    if self.player:objectName() == player:objectName() and event == sgs.AskForPeaches then
        local dying = data:toDying()
        if self:isFriend(dying.who) and dying.who:getHp() < 1 then
            sgs.card_lack[player:objectName()]["Peach"]=1
        end
    end
    if self.player:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_Play and event == sgs.CardsMoveOneTime then
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and player:getHandcardNum() > 1 then
            self:assignKeep()
        end
    end

    if self ~= sgs.recorder then return end

    if event == sgs.TargetConfirmed then
        local struct = data:toCardUse()
        local from  = struct.from
        local card = struct.card
        if from and from:objectName() == player:objectName() then
            if card:isKindOf("SingleTargetTrick") then sgs.TrickUsefrom = from end
            local to = sgs.QList2Table(struct.to)
            local callback = sgs.ai_card_intention[card:getClassName()]
            if callback then
                if type(callback) == "function" then
                    callback(self, card, from, to)
                elseif type(callback) == "number" then
                    sgs.updateIntentions(from, to, callback, card)
                end
            end
            if card:getClassName() == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
                local luaskillcardcallback = sgs.ai_card_intention[card:objectName()]
                if luaskillcardcallback then
                    if type(luaskillcardcallback) == "function" then
                        luaskillcardcallback(self, card, from, to)
                    elseif type(luaskillcardcallback) == "number" then
                        sgs.updateIntentions(from, to, luaskillcardcallback, card)
                    end
                end
            end
        end

        local lord = getLord(player)
        if lord and struct.card and lord:getHp() == 1 and self:aoeIsEffective(struct.card, lord, from) then
            if struct.card:isKindOf("SavageAssault") and struct.to:contains(lord) then
                sgs.ai_lord_in_danger_SA = true
            elseif struct.card:isKindOf("ArcheryAttack") and struct.to:contains(lord) then
                sgs.ai_lord_in_danger_AA = true
            end
        end

        local to = sgs.QList2Table(struct.to)
        local isneutral = true
        for _, p in ipairs(to) do
            if sgs.ai_role[p:objectName()] ~= "neutral" then isneutral = false break end
        end
        local who = to[1]
        if sgs.turncount <= 1 and lord and who and from and from:objectName() == player:objectName() and sgs.evaluatePlayerRole(from) == "neutral" then
                if (card:isKindOf("FireAttack")
                    or ((card:isKindOf("Dismantlement") or card:isKindOf("Snatch"))
                        and not self:needToThrowArmor(who)
                        and not (who:getCards("j"):length() > 0)
                        and not (who:getCards("e"):length() > 0 and self:hasSkills(sgs.lose_equip_skill, who))
                        and not (self:needKongcheng(who) and who:getHandcardNum() == 1))
                    or (card:isKindOf("Slash") and not (self:getDamagedEffects(who, player, true) or self:needToLoseHp(who, player, true, true)))
                    or (card:isKindOf("Duel")
                        and not (self:getDamagedEffects(who, player) or self:needToLoseHp(who, player, nil, true, true))))
                then
                local exclude_lord = #self:exclude({lord}, card, from) > 0
                if CanUpdateIntention(from) and exclude_lord and sgs.evaluatePlayerRole(who) == "neutral" and isneutral then sgs.updateIntention(from, lord, -10)
                else sgs.updateIntention(from, who, 10)
                end
            end
        end

        if from and sgs.ai_role[from:objectName()] == "rebel" and not self:isFriend(from, from:getNextAlive())
            and (card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") or card:isKindOf("Duel") or card:isKindOf("Slash")) then
            for _, target in ipairs(to) do
                if self:isFriend(target, from) and sgs.ai_role[target:objectName()] == "rebel" and target:getHp() == 1 and target:isKongcheng()
                and sgs.isGoodTarget(target, nil, self) and getCardsNum("Analeptic", target, from) + getCardsNum("Peach", target, from) == 0
                and self:getEnemyNumBySeat(from, target) > 0 then
                    if not target:hasFlag("AI_doNotSave") then target:setFlags("AI_doNotSave") end
                end
            end
        end

    elseif event == sgs.CardEffect then
        local struct = data:toCardEffect()
        local card = struct.card
        local from = struct.from
        local to = struct.to
        local card = struct.card
        local lord = getLord(player)

        if card and card:isKindOf("AOE") and to and to:isLord() and (sgs.ai_lord_in_danger_SA or sgs.ai_lord_in_danger_AA) then
            sgs.ai_lord_in_danger_SA = nil
            sgs.ai_lord_in_danger_AA = nil
        end

    elseif event == sgs.PreDamageDone then
        local damage = data:toDamage()
        local clear = true
        if clear and damage.to:isChained() then
            for _, p in sgs.qlist(self.room:getOtherPlayers(damage.to)) do
                if p:isChained() and damage.nature ~= sgs.DamageStruct_Normal then
                    clear = false
                    break
                end
            end
        end
        if not clear then
            if damage.nature ~= sgs.DamageStruct_Normal and not damage.chain then
                for _, p in sgs.qlist(self.room:getAlivePlayers()) do
                    local added = 0
                    if p:objectName() == damage.to:objectName() and p:isChained() and p:getHp() <= damage.damage then
                        sgs.ai_NeedPeach[p:objectName()] = damage.damage + 1 - p:getHp()
                    elseif p:objectName() ~= damage.to:objectName() and p:isChained() and self:damageIsEffective(p, damage.nature, damage.from) then
                        if damage.nature == sgs.DamageStruct_Fire then
                            added = p:hasArmorEffect("vine") and added + 1 or added
                            sgs.ai_NeedPeach[p:objectName()] = damage.damage + 1 + added - p:getHp()
                        elseif damage.nature == sgs.DamageStruct_Thunder then
                            sgs.ai_NeedPeach[p:objectName()] = damage.damage + 1 + added - p:getHp()
                        end
                    end
                end
            end
        else
            for _, p in sgs.qlist(self.room:getAlivePlayers()) do
                sgs.ai_NeedPeach[p:objectName()] = 0
            end
        end
    elseif event == sgs.Damaged then
        local damage = data:toDamage()
        local card = damage.card
        local from = damage.from
        local to = damage.to
        local source = self.room:getCurrent()
        local reason = damage.reason

        if not damage.card then
            local intention
            intention = 100
            if damage.transfer or damage.chain then intention = 0 end

            if from and intention ~= 0 then sgs.updateIntention(from, to, intention) end
        end
    elseif event == sgs.CardUsed then
        local struct = data:toCardUse()
        local card = struct.card
        local lord = getLord(player)
        local who
        if not struct.to:isEmpty() then who = struct.to:first() end

        if card and lord and card:isKindOf("Duel") and lord:hasFlag("AIGlobal_NeedToWake") then
            lord:setFlags("-AIGlobal_NeedToWake")
        end

        if card:isKindOf("Snatch") or card:isKindOf("Dismantlement") then
            for _, p in sgs.qlist(struct.to) do
                for _, c in sgs.qlist(p:getCards("hej")) do
                    self.room:setCardFlag(c, "-AIGlobal_SDCardChosen_"..card:objectName())
                end
            end
        end

        if card:isKindOf("AOE") and sgs.ai_AOE_data then
            sgs.ai_AOE_data = nil
        end

        if card:isKindOf("Slash") and struct.from:objectName() == self.room:getCurrent():objectName() and struct.m_reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and struct.m_addHistory then struct.from:setFlags("hasUsedSlash") end

        if card:isKindOf("Collateral") then sgs.ai_collateral = false end

    elseif event == sgs.CardsMoveOneTime then
        local move = data:toMoveOneTime()
        local from = nil   -- convert move.from from const Player * to ServerPlayer *
        local to   = nil   -- convert move.to to const Player * to ServerPlayer *
        if move.from then from = findPlayerByObjectName(self.room, move.from:objectName(), true) end
        if move.to   then to   = findPlayerByObjectName(self.room, move.to:objectName(), true) end
        local reason = move.reason
        local from_places = sgs.QList2Table(move.from_places)
        local lord = getLord(player)

        for i = 0, move.card_ids:length()-1 do
            local place = move.from_places:at(i)
            local card_id = move.card_ids:at(i)
            local card = sgs.Sanguosha:getCard(card_id)

            if place == sgs.Player_DrawPile
                or (move.to_place == sgs.Player_DrawPile) then
                self.top_draw_pile_id = nil
            end

            if move.to_place == sgs.Player_PlaceHand and to and player:objectName() == to:objectName() then
                if card:hasFlag("visible") then
                    if isCard("Slash",card, player) then sgs.card_lack[player:objectName()]["Slash"] = 0 end
                    if isCard("Jink",card, player) then sgs.card_lack[player:objectName()]["Jink"] = 0 end
                    if isCard("Peach",card, player) then sgs.card_lack[player:objectName()]["Peach"] = 0 end
                else
                    sgs.card_lack[player:objectName()]["Slash"] = 0
                    sgs.card_lack[player:objectName()]["Jink"] = 0
                    sgs.card_lack[player:objectName()]["Peach"] = 0
                end
            end

            if move.to_place == sgs.Player_PlaceHand and to and place ~= sgs.Player_DrawPile then
                if from and player:objectName() == from:objectName()
                    and from:objectName() ~= to:objectName() and place == sgs.Player_PlaceHand and not card:hasFlag("visible") then
                    local flag = string.format("%s_%s_%s", "visible", from:objectName(), to:objectName())
                    global_room:setCardFlag(card_id, flag, from)
                end
            end

            if player:hasFlag("AI_Playing") and sgs.turncount <= 3 and player:getPhase() == sgs.Player_Discard
                and reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD then

                local is_neutral = sgs.evaluatePlayerRole(player) == "neutral" and CanUpdateIntention(player)

                if isCard("Slash", card, player) and not player:hasFlag("hasUsedSlash") then
                    for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
                        local has_slash_prohibit_skill = false
                        for _, askill in sgs.qlist(target:getVisibleSkillList(true)) do
                            local s_name = askill:objectName()
                            local filter = sgs.ai_slash_prohibit[s_name]
                            if filter and type(filter) == "function" then
                                has_slash_prohibit_skill = true
                                break
                            end
                        end

                        if player:canSlash(target, card, true) and self:slashIsEffective(card, target)
                                and not has_slash_prohibit_skill and sgs.isGoodTarget(target,self.enemies, self) then
                            if is_neutral then
                                sgs.updateIntention(player, target, -35)
                            end
                        end
                    end
                end

                    if isCard("Indulgence", card, player) and lord then
                        for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
                            if not (target:containsTrick("indulgence")) then
                                local aplayer = self:exclude( {target}, card, player)
                                if #aplayer == 1 and is_neutral then
                                    sgs.updateIntention(player, target, -35)
                                end
                            end
                        end
                    end

                    if isCard("SupplyShortage", card, player) and lord then
                        for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
                            if player:distanceTo(target) <= 1 and
                                    not (target:containsTrick("supply_shortage")) then
                                local aplayer = self:exclude( {target}, card, player)
                                if #aplayer == 1 and is_neutral then
                                    sgs.updateIntention(player, target, -35)
                                end
                            end
                        end
                    end

            end
        end

    elseif event == sgs.StartJudge then
        local judge = data:toJudge()
        local reason = judge.reason
        local judgex = { who = judge.who, reason = judge.reason, good = judge:isGood() }
        table.insert(sgs.ai_current_judge, judgex)
    elseif event == sgs.AskForRetrial then
        local judge = data:toJudge()
        local judge_len = #sgs.ai_current_judge
        local last_judge = sgs.ai_current_judge[judge_len]
        table.remove(sgs.ai_current_judge, judge_len)
        local intention = nil
        local callback = sgs.ai_retrial_intention[last_judge.reason]
        if type(callback) == "function" then
            intention = callback(self, player, last_judge.who, judge, last_judge)
        end
        if type(intention) ~= "number" then
            if not last_judge.good and judge:isGood() then
                intention = -30
            elseif last_judge.good and not judge:isGood() then
                intention = 30
            end
        end
        if type(intention) == "number" and intention ~= 0 then
            sgs.updateIntention(player, last_judge.who, intention)
        end
        last_judge.good = judge:isGood()
        table.insert(sgs.ai_current_judge, last_judge)
    elseif event == sgs.FinishJudge then
        table.remove(sgs.ai_current_judge, #sgs.ai_current_judge)
    elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
        player:setFlags("AI_Playing")
    elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
        if player:isLord() then sgs.turncount = sgs.turncount + 1 end

        sgs.debugmode = io.open("lua/ai/debug")
        if sgs.debugmode then sgs.debugmode:close() end

        if sgs.turncount == 1 and player:isLord() then
            local msg = ""
            local humanCount = 0
            for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
                if aplayer:getState() ~= "robot" then humanCount = humanCount +1 end
                if not aplayer:isLord() then
                    msg = msg..string.format("%s\t%s\r\n",aplayer:getGeneralName(),aplayer:getRole())
                end
            end
            self.room:setTag("humanCount",sgs.QVariant(humanCount))
        end

    elseif event == sgs.GameStart then
        sgs.debugmode = io.open("lua/ai/debug")
        if sgs.debugmode then sgs.debugmode:close() end
        if player:isLord() then
            if sgs.debugmode then logmsg("ai.html","<meta charset='utf-8'/>") end
        end

    end
end

function SmartAI:askForSuit(reason)
    if not reason then return sgs.ai_skill_suit.fanjian(self) end -- this line is kept for back-compatibility
    local callback = sgs.ai_skill_suit[reason]
    if type(callback) == "function" then
        if callback(self) then return callback(self) end
    end
    return math.random(0, 3)
end

function SmartAI:askForSkillInvoke(skill_name, data)
    skill_name = string.gsub(skill_name, "%-", "_")
    local invoke = sgs.ai_skill_invoke[skill_name]
    if type(invoke) == "boolean" then
        return invoke
    elseif type(invoke) == "function" then
        return invoke(self, data)
    else
        local skill = sgs.Sanguosha:getSkill(skill_name)
        return skill and skill:getFrequency() == sgs.Skill_Frequent
    end
end

function SmartAI:askForChoice(skill_name, choices, data)
    local choice = sgs.ai_skill_choice[skill_name]
    if type(choice) == "string" then
        return choice
    elseif type(choice) == "function" then
        return choice(self, choices, data)
    else
        local skill = sgs.Sanguosha:getSkill(skill_name)
        if skill and choices:match(skill:getDefaultChoice(self.player)) then
            return skill:getDefaultChoice(self.player)
        else
            local choice_table = choices:split("+")
            local r = math.random(1, #choice_table)
            return choice_table[r]
        end
    end
end

function SmartAI:askForDiscard(reason, discard_num, min_num, optional, include_equip)
    min_num = min_num or discard_num
    local exchange = self.player:hasFlag("Global_AIDiscardExchanging")
    local callback = sgs.ai_skill_discard[reason]
    self:assignKeep(true)
    if type(callback) == "function" then
        local cb = callback(self, discard_num, min_num, optional, include_equip)
        if cb then
            if type(cb) == "number" and not self.player:isJilei(sgs.Sanguosha:getCard(cb)) then return { cb }
            elseif type(cb) == "table" then
                for _, card_id in ipairs(cb) do
                    if not exchange and self.player:isJilei(sgs.Sanguosha:getCard(card_id)) then
                        return {}
                    end
                end
                return cb
            end
            return {}
        end
    elseif optional then
        return min_num == 1 and self:needToThrowArmor() and self.player:getArmor():getEffectiveId() or {}
    end

    local flag = "h"
    if include_equip and (self.player:getEquips():isEmpty() or not self.player:isJilei(self.player:getEquips():first())) then flag = flag .. "e" end
    local cards = self.player:getCards(flag)
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local to_discard, temp = {}, {}

    local least = min_num
    if discard_num - min_num > 1 then
        least = discard_num - 1
    end
    for _, card in ipairs(cards) do
        if exchange or not self.player:isJilei(card) then
            place = self.room:getCardPlace(card:getEffectiveId())
            if discardEquip and place == sgs.Player_PlaceEquip then
                table.insert(temp, card:getEffectiveId())
            elseif self:getKeepValue(card) >= 4.1 then
                table.insert(temp, card:getEffectiveId())
            else
                table.insert(to_discard, card:getEffectiveId())
            end
            if self.player:hasSkills(sgs.lose_equip_skill) and place == sgs.Player_PlaceEquip then discardEquip = true end
        end
        if #to_discard >= discard_num then break end
    end
    if #to_discard < discard_num then
        for _, id in ipairs(temp) do
            table.insert(to_discard, id)
            if #to_discard >= discard_num then break end
        end
    end
    return to_discard
end

sgs.ai_skill_discard.gamerule = function(self, discard_num, min_num)

    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local to_discard = {}

    local least = min_num
    if discard_num - min_num > 1 then least = discard_num - 1 end

    for _, card in ipairs(cards) do
        if not self.player:isCardLimited(card, sgs.Card_MethodDiscard, true) then
            table.insert(to_discard, card:getId())
        end
        if #to_discard >= discard_num or self.player:isKongcheng() then break end
    end

    return to_discard
end


---询问无懈可击--
function SmartAI:askForNullification(trick, from, to, positive)
    if self.player:isDead() then return nil end
    local null_card
    null_card = self:getCardId("Nullification") --无懈可击
    local null_num = self:getCardsNum("Nullification")
    if null_card then null_card = sgs.Card_Parse(null_card) else return nil end --没有无懈可击
    if self.player:isLocked(null_card) then return nil end
    if (from and from:isDead()) or (to and to:isDead()) then return nil end --已死

    if trick:isKindOf("FireAttack") then
        if to:isKongcheng() or from:isKongcheng() then return nil end
        if self.player:objectName() == from:objectName() and self.player:getHandcardNum() == 1 and self.player:handCards():first() == null_card:getId() then return nil end
    end

    if ("snatch|dismantlement"):match(trick:objectName()) and to:isAllNude() then return nil end

    if self:isFriend(to) and to:hasFlag("AIGlobal_NeedToWake") then return end

    if from then
        if (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("AOE")) and
            ((self:getDamagedEffects(to, from) and self:isFriend(to))) then
            return nil
        end --决斗、火攻、AOE
        if (trick:isKindOf("Duel") or trick:isKindOf("AOE")) and not self:damageIsEffective(to, sgs.DamageStruct_Normal) then return nil end --决斗、AOE
        if trick:isKindOf("FireAttack") and not self:damageIsEffective(to, sgs.DamageStruct_Fire) then return nil end --火攻
    end
    if (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("AOE")) and self:needToLoseHp(to, from) and self:isFriend(to) then
        return nil --扣减体力有利
    end
    if trick:isKindOf("Drowning") and self:needToThrowArmor(to) and self:isFriend(to) then return nil end

    local callback = sgs.ai_nullification[trick:getClassName()]
    if type(callback) == "function" then
        local shouldUse = callback(self, trick, from, to, positive)
        if shouldUse then return null_card end
    end

    if positive then
        if from and (trick:isKindOf("FireAttack") or trick:isKindOf("Duel") or trick:isKindOf("AOE")) and (self:needDeath(to) or self:cantbeHurt(to, from)) then
            if self:isFriend(from) then return null_card end
            return
        end
        if ("snatch|dismantlement"):match(trick:objectName()) and (to:containsTrick("indulgence") or to:containsTrick("supply_shortage")) then
            if self:isEnemy(from) then return null_card end
            if self:isFriend(to) and to:isNude() then return nil end
        end

        if from and self:isEnemy(from) and (sgs.evaluatePlayerRole(from) ~= "neutral" or sgs.isRolePredictable()) then
             --敌方在虚弱、需牌技中使用无中生有->命中
            if trick:isKindOf("ExNihilo") and (self:isWeak(from) or from:hasSkills(sgs.cardneed_skill))
                and not (self.role == "rebel" and not hasExplicitRebel(self.room) and sgs.turncount == 0 and self.room:getCurrent():getNextAlive():objectName() ~= self.player:objectName()) then
                return null_card
            end
            --铁索连环的目标没有藤甲->不管
            if trick:isKindOf("IronChain") and not to:hasArmorEffect("vine") then return nil end
            if self:isFriend(to) then
                if trick:isKindOf("Dismantlement") then
                    --敌方拆友方威胁牌、价值牌、最后一张手牌->命中
                    if self:getDangerousCard(to) or self:getValuableCard(to) then return null_card end
                    if to:getHandcardNum() == 1 and not self:needKongcheng(to) then
                        if (getKnownCard(to, self.player, "TrickCard", false) == 1 or getKnownCard(to, self.player, "EquipCard", false) == 1 or getKnownCard(to, self.player, "Slash", false) == 1) then
                            return nil
                        end
                        return null_card
                    end
                else
                    if trick:isKindOf("Snatch") then return null_card end
                    if trick:isKindOf("Duel") and self:isWeak(to) then return null_card end
                    if trick:isKindOf("FireAttack") and from:objectName() ~= to:objectName() then
                        if from:getHandcardNum() > 2
                            or self:isWeak(to)
                            or to:hasArmorEffect("vine")
                            or to:isChained() and not self:isGoodChainTarget(to, from)
                            then return null_card end
                    end
                end
            elseif self:isEnemy(to) then
                 --敌方顺手牵羊、过河拆桥敌方判定区延时性锦囊->命中
                if (trick:isKindOf("Snatch") or trick:isKindOf("Dismantlement")) and to:getCards("j"):length() > 0 then
                    return null_card
                end
            end
        end

        if self:isFriend(to) then
                --友方判定区有乐不思蜀->视情形而定
                if trick:isKindOf("Indulgence") and not to:isSkipped(sgs.Player_Play) then
                    if to:getHp() - to:getHandcardNum() >= 2 then return nil end
                    if (to:containsTrick("supply_shortage") or self:willSkipDrawPhase(to)) and null_num <= 1 and self:getOverflow(to) < -1 then return nil end
                    return null_card
                end
                --友方判定区有兵粮寸断->视情形而定
                if trick:isKindOf("SupplyShortage") and not to:isSkipped(sgs.Player_Draw) then
                    if (to:containsTrick("indulgence") or self:willSkipPlayPhase(to)) and null_num <= 1 and self:getOverflow(to) > 1 then return nil end
                    return null_card
                end
            --来源使用多目标攻击性非延时锦囊
            if trick:isKindOf("AOE") then
                local lord = getLord(self.player)
                local currentplayer = self.room:getCurrent()
                --主公
                if lord and self:isFriend(lord) and self:isWeak(lord) and self:aoeIsEffective(trick, lord) and
                    ((lord:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount())) >
                    ((to:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount())) and not
                    (self.player:objectName() == to:objectName() and self.player:getHp() == 1 and not self:canAvoidAOE(trick)) then
                    return nil
                end
                --自己
                if self.player:objectName() == to:objectName() then
                    if not self:canAvoidAOE(trick) then
                        return null_card
                    end
                end
                --队友
                if self:isWeak(to) and self:aoeIsEffective(trick, to) then
                    if ((to:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount())) >
                    ((self.player:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount())) or null_num > 1 then
                        return null_card
                    elseif self:canAvoidAOE(trick) or self.player:getHp() > 1 or (isLord(to) and self.role == "loyalist") then
                        return null_card
                    end
                end
            end
            --来源对自己使用决斗
            if trick:isKindOf("Duel") then
                if self.player:objectName() == to:objectName() then
                    if self:hasSkills(sgs.masochism_skill, self.player) and
                        (self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
                        return nil
                    elseif self:getCardsNum("Slash") == 0 then
                        return null_card
                    end
                end
            end
        end
        --虚弱敌方遇到桃园结义->命中
        if from then
            if self:isEnemy(to) then
                if trick:isKindOf("GodSalvation") and self:isWeak(to) then
                    return null_card
                end
            end
        end

        if trick:isKindOf("AmazingGrace") and self:isEnemy(to) then
            local NP = to:getNextAlive()
            if self:isFriend(NP) then
                local ag_ids = self.room:getTag("AmazingGrace"):toIntList()
                local peach_num, exnihilo_num, snatch_num, analeptic_num, crossbow_num, indulgence_num = 0, 0, 0, 0, 0, 0
                local fa_card
                for _, ag_id in sgs.qlist(ag_ids) do
                    local ag_card = sgs.Sanguosha:getCard(ag_id)
                    if ag_card:isKindOf("Peach") then peach_num = peach_num + 1 end
                    if ag_card:isKindOf("ExNihilo") then exnihilo_num = exnihilo_num + 1 end
                    if ag_card:isKindOf("Snatch") then snatch_num = snatch_num + 1 end
                    if ag_card:isKindOf("Analeptic") then analeptic_num = analeptic_num + 1 end
                    if ag_card:isKindOf("Crossbow") then crossbow_num = crossbow_num + 1 end
                    if ag_card:isKindOf("FireAttack") then fa_card = ag_card end
                    if ag_card:isKindOf("Indulgence") then indulgence_num = indulgence_num + 1 end
                end
                if (peach_num == 1 and to:getHp() < getBestHp(to))
                    or (peach_num > 0 and (self:isWeak(to) or (NP:getHp() < getBestHp(NP) and self:getOverflow(NP) <= 0))) then
                    return null_card
                end
                if peach_num == 0 and not self:willSkipPlayPhase(NP) then
                    if exnihilo_num == 0 then
                        for _, enemy in ipairs(self.enemies) do
                            if indulgence_num > 0 and not self:willSkipPlayPhase(enemy, true) then
                                return null_card
                            elseif snatch_num > 0 and to:distanceTo(enemy) == 1 and (self:willSkipPlayPhase(enemy, true) or self:willSkipDrawPhase(enemy, true)) then
                                return null_card
                            elseif analeptic_num > 0 and (enemy:hasWeapon("axe") or getCardsNum("Axe", enemy, self.player) > 0) then
                                return null_card
                            elseif crossbow_num > 0 and getCardsNum("Slash", enemy, self.player) >= 3 then
                                local slash = sgs.Sanguosha:cloneCard("slash")
                                for _, friend in ipairs(self.friends) do
                                    if enemy:distanceTo(friend) == 1 and self:slashIsEffective(slash, friend, enemy) then
                                        return null_card
                                    end
                                end
                            end
                        end
                        if fa_card then
                            for _, friend in ipairs(self.friends) do
                                if (friend:hasArmorEffect("vine")) and self:hasTrickEffective(fa_card, friend, to) and to:getHandcardNum() > 2 then
                                    return null_card
                                end
                            end
                        end
                    end
                end
            end
        end

    else
        if from then
            if (trick:isKindOf("FireAttack") or trick:isKindOf("Duel") or trick:isKindOf("AOE")) and (self:needDeath(to) or self:cantbeHurt(to, from)) then
                if self:isEnemy(from) then return null_card end
                return
            end
            if from:objectName() == to:objectName() then
                if self:isFriend(from) then return null_card else return end
            end
            if not (trick:isKindOf("GlobalEffect") or trick:isKindOf("AOE")) then
                if self:isFriend(from) and not self:isFriend(to) then
                    if ("snatch|dismantlement"):match(trick:objectName()) and to:isNude() then
                    elseif trick:isKindOf("FireAttack") and to:isKongcheng() then
                    else return null_card end
                end
            end
        else
            if self:isEnemy(to) and (sgs.evaluatePlayerRole(to) ~= "neutral" or sgs.isRolePredictable()) then return null_card else return end
        end
    end
end

function SmartAI:getCardRandomly(who, flags)
    local cards = who:getCards(flags)
    if cards:isEmpty() then return end
    local r = math.random(0, cards:length() - 1)
    local card = cards:at(r)
    if who:hasArmorEffect("silver_lion") then
        if self:isEnemy(who) and who:isWounded() and card == who:getArmor() then
            if r ~= (cards:length() - 1) then
                card = cards:at(r + 1)
            elseif r > 0 then
                card = cards:at(r - 1)
            end
        end
    end
    return card:getEffectiveId()
end

function SmartAI:askForCardChosen(who, flags, reason, method)
    local isDiscard = (method == sgs.Card_MethodDiscard)
    local cardchosen = sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")]
    local card
    if type(cardchosen) == "function" then
        card = cardchosen(self, who, flags, method)
        if type(card) == "number" then return card
        elseif card then return card:getEffectiveId() end
    elseif type(cardchosen) == "number" then
        sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")] = nil
        for _, acard in sgs.qlist(who:getCards(flags)) do
            if acard:getEffectiveId() == cardchosen then return cardchosen end
        end
    end

    if ("snatch|dismantlement"):match(reason) then
        local flag = "AIGlobal_SDCardChosen_" .. reason
        local to_choose
        for _, card in sgs.qlist(who:getCards(flags)) do
            if card:hasFlag(flag) then
                card:setFlags("-" .. flag)
                to_choose = card:getId()
                break
            end
        end
        if to_choose then
            local is_handcard
            if not who:isKongcheng() and who:handCards():contains(to_choose) then is_handcard = true end
            if is_handcard and reason == "dismantlement" and self.room:getMode() == "02_1v1" and sgs.GetConfig("1v1/Rule", "Classical") == "2013" then
                local cards = sgs.QList2Table(who:getHandcards())
                local peach, jink
                for _, card in ipairs(cards) do
                    if not peach and isCard("Peach", card, who) then peach = card:getId() end
                    if not jink and isCard("Jink", card, who) then jink = card:getId() end
                    if peach and jink then break end
                end
                if peach or jink then return peach or jink end
                self:sortByKeepValue(cards, true)
                return cards[1]:getEffectiveId()
            else
                return to_choose
            end
        end
    end

    if self:isFriend(who) then
        if flags:match("j") then
            local tricks = who:getCards("j")
            local lightning, indulgence, supply_shortage
            for _, trick in sgs.qlist(tricks) do
                if trick:isKindOf("Lightning") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
                    lightning = trick:getId()
                elseif trick:isKindOf("Indulgence") and (not isDiscard or self.player:canDiscard(who, trick:getId()))  then
                    indulgence = trick:getId()
                elseif not trick:isKindOf("Disaster") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
                    supply_shortage = trick:getId()
                end
            end

            if self:hasWizard(self.enemies) and lightning then
                return lightning
            end

            if indulgence and supply_shortage then
                if who:getHp() < who:getHandcardNum() then
                    return indulgence
                else
                    return supply_shortage
                end
            end

            if indulgence or supply_shortage then
                return indulgence or supply_shortage
            end
        end

        if flags:match("e") then
            if who:getArmor() and self:needToThrowArmor(who) and (not isDiscard or self.player:canDiscard(who, who:getArmor():getEffectiveId())) then
                return who:getArmor():getEffectiveId()
            end
            if who:getArmor() and self:evaluateArmor(who:getArmor(), who) < -5 and (not isDiscard or self.player:canDiscard(who, who:getArmor():getEffectiveId())) then
                return who:getArmor():getEffectiveId()
            end
            if who:hasSkills(sgs.lose_equip_skill) and self:isWeak(who) then
                if who:getWeapon() and (not isDiscard or self.player:canDiscard(who, who:getWeapon():getEffectiveId())) then return who:getWeapon():getEffectiveId() end
                if who:getOffensiveHorse() and (not isDiscard or self.player:canDiscard(who, who:getOffensiveHorse():getEffectiveId())) then return who:getOffensiveHorse():getEffectiveId() end
            end
        end
    else
        local dangerous = self:getDangerousCard(who)
        if flags:match("e") and dangerous and (not isDiscard or self.player:canDiscard(who, dangerous)) then return dangerous end
        if flags:match("e") and who:getTreasure() and who:getPile("wooden_ox"):length() > 1 and (not isDiscard or self.player:canDiscard(who, who:getTreasure():getId())) then
            return who:getTreasure():getEffectiveId()
        end
        if flags:match("e") and who:hasArmorEffect("eight_diagram") and who:getArmor() and not self:needToThrowArmor(who)
            and (not isDiscard or self.player:canDiscard(who, who:getArmor():getId())) then return who:getArmor():getId() end
        if flags:match("e") then
            local valuable = self:getValuableCard(who)
            if valuable and (not isDiscard or self.player:canDiscard(who, valuable)) then
                return valuable
            end
        end
        if flags:match("h") and (not isDiscard or self.player:canDiscard(who, "h")) then
            local cards = sgs.QList2Table(who:getHandcards())
            local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), who:objectName())
            if #cards <= 2 and not self:doNotDiscard(who, "h", false, 1, reason) then
                for _, cc in ipairs(cards) do
                    if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
                        return self:getCardRandomly(who, "h")
                    end
                end
            end
        end

        if flags:match("j") then
            local tricks = who:getCards("j")
            local lightning, yanxiao
            for _, trick in sgs.qlist(tricks) do
                if trick:isKindOf("Lightning") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
                    lightning = trick:getId()
                end
            end
            if self:hasWizard(self.enemies, true) and lightning then
                return lightning
            end
        end

        if flags:match("h") and not self:doNotDiscard(who, "h") then
            if (who:getHandcardNum() == 1 and sgs.getDefenseSlash(who, self) < 3 and who:getHp() <= 2) or who:hasSkills(sgs.cardneed_skill) then
                return self:getCardRandomly(who, "h")
            end
        end

        if flags:match("e") and not self:doNotDiscard(who, "e") then
            if who:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(who, who:getDefensiveHorse():getEffectiveId())) then return who:getDefensiveHorse():getEffectiveId() end
            if who:getArmor() and not self:needToThrowArmor(who) and (not isDiscard or self.player:canDiscard(who, who:getArmor():getEffectiveId())) then return who:getArmor():getEffectiveId() end
            if who:getOffensiveHorse() and (not isDiscard or self.player:canDiscard(who, who:getOffensiveHorse():getEffectiveId())) then return who:getOffensiveHorse():getEffectiveId() end
            if who:getWeapon() and (not isDiscard or self.player:canDiscard(who, who:getWeapon():getEffectiveId())) then return who:getWeapon():getEffectiveId() end
        end

        if flags:match("h") then
            if (not who:isKongcheng() and who:getHandcardNum() <= 2) and not self:doNotDiscard(who, "h", false, 1, reason) then
                return self:getCardRandomly(who, "h")
            end
        end
    end
    return -1
end

function sgs.ai_skill_cardask.nullfilter(self, data, pattern, target)
    if self.player:isDead() then return "." end
    local damage_nature = sgs.DamageStruct_Normal
    local effect
    if type(data) == "userdata" then
        effect = data:toSlashEffect()

        if effect and effect.slash then
            damage_nature = effect.nature
        end
    end
    if effect and self:hasHeavySlashDamage(target, effect.slash, self.player) then return end
    if not self:damageIsEffective(nil, damage_nature, target) then return "." end
    if effect and target and target:hasWeapon("ice_sword") and self.player:getCards("he"):length() > 1 then return end
    if self:getDamagedEffects(self.player, target) or self:needToLoseHp() then return "." end

    if target and sgs.ai_role[target:objectName()] == "rebel" and self.role == "rebel" and self.player:hasFlag("AI_doNotSave") then return "." end
    if target and self:needDeath() then return "." end
end

function SmartAI:askForCard(pattern, prompt, data)
    local target, target2
    local parsedPrompt = prompt:split(":")
    local players
    if parsedPrompt[2] then
        local players = self.room:getPlayers()
        players = sgs.QList2Table(players)
        for _, player in ipairs(players) do
            if player:getGeneralName() == parsedPrompt[2] or player:objectName() == parsedPrompt[2] then target = player break end
        end
        if parsedPrompt[3] then
            for _, player in ipairs(players) do
                if player:getGeneralName() == parsedPrompt[3] or player:objectName() == parsedPrompt[3] then target2 = player break end
            end
        end
    end
    local arg, arg2 = parsedPrompt[4], parsedPrompt[5]
    local callback = sgs.ai_skill_cardask[parsedPrompt[1]]
    if type(callback) == "function" then
        local ret = callback(self, data, pattern, target, target2, arg, arg2)
        if ret then return ret end
    end

    if data and type(data) == "number" then return end
    local card
    if pattern == "slash" then
        card = sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Slash") or "."
        if card == "." then sgs.card_lack[self.player:objectName()]["Slash"] = 1 end
    elseif pattern == "jink" then
        card = sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Jink") or "."
        if card == "." then sgs.card_lack[self.player:objectName()]["Jink"] = 1 end
    end
    return card
end

function SmartAI:askForUseCard(pattern, prompt, method)
    local use_func = sgs.ai_skill_use[pattern]
    if use_func then
        return use_func(self, prompt, method) or "."
    else
        return "."
    end
end

function SmartAI:askForAG(card_ids, refusable, reason)
    local cardchosen = sgs.ai_skill_askforag[string.gsub(reason, "%-", "_")]
    if type(cardchosen) == "function" then
        local card_id = cardchosen(self, card_ids)
        if card_id then return card_id end
    end
	
    local ids = card_ids
    local cards = {}
    for _, id in ipairs(ids) do
        table.insert(cards, sgs.Sanguosha:getCard(id))
    end
    for _, card in ipairs(cards) do
        if card:isKindOf("Peach") then return card:getEffectiveId() end
    end
    for _, card in ipairs(cards) do
        if card:isKindOf("Indulgence") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then return card:getEffectiveId() end
        if card:isKindOf("AOE") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then return card:getEffectiveId() end
    end
    self:sortByCardNeed(cards)
    return cards[#cards]:getEffectiveId()
end

function SmartAI:askForCardShow(requestor, reason)
    local func = sgs.ai_cardshow[reason]
    if func then
        return func(self, requestor)
    else
        return self.player:getRandomHandCard()
    end
end

function sgs.ai_cardneed.bignumber(to, card, self)
    if not self:willSkipPlayPhase(to) and self:getUseValue(card) < 6 then
        return card:getNumber() > 10
    end
end

function sgs.ai_cardneed.equip(to, card, self)
    if not self:willSkipPlayPhase(to) then
        return card:getTypeId() == sgs.Card_TypeEquip
    end
end

function sgs.ai_cardneed.weapon(to, card, self)
    if not self:willSkipPlayPhase(to) then
        return card:isKindOf("Weapon")
    end
end

function SmartAI:getEnemyNumBySeat(from, to, target, include_neutral)
    target = target or from
    local players = sgs.QList2Table(self.room:getAllPlayers())
    local to_seat = (to:getSeat() - from:getSeat()) % #players
    local enemynum = 0
    for _, p in ipairs(players) do
        if  (self:isEnemy(target, p) or (include_neutral and not self:isFriend(target, p))) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then
            enemynum = enemynum + 1
        end
    end
    return enemynum
end

function SmartAI:getFriendNumBySeat(from, to)
    local players = sgs.QList2Table(self.room:getAllPlayers())
    local to_seat = (to:getSeat() - from:getSeat()) % #players
    local friendnum = 0
    for _, p in ipairs(players) do
        if self:isFriend(from, p) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then
            friendnum = friendnum + 1
        end
    end
    return friendnum
end

function SmartAI:hasHeavySlashDamage(from, slash, to, getValue)
    from = from or self.room:getCurrent()
    slash = slash or self:getCard("Slash", from)
    to = to or self.player
    if not from or not to then self.room:writeToConsole(debug.traceback()) return false end
    if (to:hasArmorEffect("silver_lion") and not IgnoreArmor(from, to)) then
        if getValue then return 1
        else return false end
    end
    local dmg = 1
    local fireSlash = slash and (slash:isKindOf("FireSlash") or
        (slash:objectName() == "slash" and from:hasWeapon("fan")))
    local thunderSlash = slash and slash:isKindOf("ThunderSlash")
    if (slash and slash:hasFlag("drank")) then
        dmg = dmg + 1
    elseif from:getMark("drank") > 0 then
        dmg = dmg + from:getMark("drank")
    end
    if to:hasArmorEffect("vine") and not IgnoreArmor(from, to) and fireSlash then dmg = dmg + 1 end
    if from:hasWeapon("guding_blade") and slash and to:isKongcheng() then dmg = dmg + 1 end
    if getValue then return dmg end
    return (dmg > 1)
end

function SmartAI:needKongcheng(player, keep)
    player = player or self.player
    if keep then
        return false
    end

    if not self:hasLoseHandcardEffective(player) and not player:isKongcheng() then return true end
    return player:hasSkills(sgs.need_kongcheng)
end

function SmartAI:getLeastHandcardNum(player)
    player = player or self.player
    local least = 0
    return least
end

function SmartAI:hasLoseHandcardEffective(player)
    player = player or self.player
    return player:getHandcardNum() > self:getLeastHandcardNum(player)
end

function SmartAI:hasCrossbowEffect(player)
    player = player or self.player
    return player:hasWeapon("crossbow")
end

function SmartAI:getCardNeedPlayer(cards, include_self)
    cards = cards or sgs.QList2Table(self.player:getHandcards())

    if #self.enemies > 0 then
        self:sort(self.enemies, "hp")
        for _,acard in ipairs(cards) do
            if acard:isKindOf("Shit") then
                return acard, self.enemies[1]
            end
        end
    end
    
    local cardtogivespecial = {}
    local keptslash = 0
    local friends={}
    local cmpByAction = function(a,b)
        return a:getRoom():getFront(a, b):objectName() == a:objectName()
    end

    local cmpByNumber = function(a,b)
        return a:getNumber() > b:getNumber()
    end

    local friends_table = include_self and self.friends or self.friends_noself
    for _, player in ipairs(friends_table) do
        local exclude = self:needKongcheng(player) or self:willSkipPlayPhase(player)
        if player:getHp() - player:getHandcardNum() >= 3
            or (player:isLord() and self:isWeak(player) and self:getEnemyNumBySeat(self.player, player) >= 1) then
            exclude = false
        end
        if self:objectiveLevel(player) <= -2 and not exclude then
            table.insert(friends, player)
        end
    end

    local AssistTarget = self:AssistTarget()
    if AssistTarget and (self:needKongcheng(AssistTarget, true) or self:willSkipPlayPhase(AssistTarget)) then
        AssistTarget = nil
    end

    if self.role ~= "renegade" then
        local R_num = sgs.current_mode_players["renegade"]
        if R_num > 0 and #friends > R_num then
            local k = 0
            local temp_friends, new_friends = {}, {}
            for _, p in ipairs(friends) do
                if k < R_num and sgs.explicit_renegade and sgs.ai_role[p:objectName()] == "renegade" then
                    if AssistTarget and p:objectName() == AssistTarget:objectName() then AssistTarget = nil end
                    k = k + 1
                else table.insert(temp_friends, p) end
            end
            if k == R_num then friends = temp_friends
            else
                local cmp = function(a, b)
                    local ar_value, br_value = sgs.role_evaluation[a:objectName()]["renegade"], sgs.role_evaluation[b:objectName()]["renegade"]
                    local al_value, bl_value = sgs.role_evaluation[a:objectName()]["loyalist"], sgs.role_evaluation[b:objectName()]["loyalist"]
                    return (ar_value > br_value) or (ar_value == br_value and al_value > bl_value)
                end
                table.sort(temp_friends, cmp)
                for _, p in ipairs(temp_friends) do
                    if k < R_num and sgs.role_evaluation[p:objectName()]["renegade"] > 0 then
                        k = k + 1
                        if AssistTarget and p:objectName() == AssistTarget:objectName() then AssistTarget = nil end
                    else table.insert(new_friends, p) end
                end
                friends = new_friends
            end
        end
    end

    -- keep a jink
    local cardtogive = {}
    local keptjink = 0
    for _, acard in ipairs(cards) do
        if isCard("Jink", acard, self.player) and keptjink < 1 then
            keptjink = keptjink + 1
        else
            table.insert(cardtogive, acard)
        end
    end

    -- weak
    self:sort(friends, "defense")
    for _, friend in ipairs(friends) do
        if self:isWeak(friend) and friend:getHandcardNum() < 3  then
            for _, hcard in ipairs(cards) do
                if hcard:isKindOf("Shit") then
                elseif isCard("Peach",hcard,friend) or (isCard("Jink",hcard,friend) and self:getEnemyNumBySeat(self.player,friend)>0) or isCard("Analeptic",hcard,friend) then
                    return hcard, friend
                end
            end
        end
    end

    -- Armor,DefensiveHorse
    for _, friend in ipairs(friends) do
        if friend:getHp()<=2 and friend:faceUp() then
            for _, hcard in ipairs(cards) do
                if (hcard:isKindOf("Armor") and not friend:getArmor())
                            or (hcard:isKindOf("DefensiveHorse") and not friend:getDefensiveHorse()) then
                    return hcard, friend
                end
            end
        end
    end

    --Crossbow

    for _, friend in ipairs(friends) do
        if getKnownCard(friend, self.player, "Crossbow") > 0 then
            for _, p in ipairs(self.enemies) do
                if sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) <= 1 then
                    for _, hcard in ipairs(cards) do
                        if isCard("Slash", hcard, friend) then
                            return hcard, friend
                        end
                    end
                end
            end
        end
    end

    table.sort(friends, cmpByAction)

    for _, friend in ipairs(friends) do
        if friend:faceUp() then
            local can_slash = false
            for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
                if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) <= friend:getAttackRange() then
                    can_slash = true
                    break
                end
            end
            local flag = string.format("weapon_done_%s_%s",self.player:objectName(),friend:objectName())
            if not can_slash then
                for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
                    if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) > friend:getAttackRange() then
                        for _, hcard in ipairs(cardtogive) do
                            if hcard:isKindOf("Weapon") and friend:distanceTo(p) <= friend:getAttackRange() + (sgs.weapon_range[hcard:getClassName()] or 0)
                                    and not friend:getWeapon() and not friend:hasFlag(flag) then
                                self.room:setPlayerFlag(friend, flag)
                                return hcard, friend
                            end
                            if hcard:isKindOf("OffensiveHorse") and friend:distanceTo(p) <= friend:getAttackRange() + 1
                                    and not friend:getOffensiveHorse() and not friend:hasFlag(flag) then
                                self.room:setPlayerFlag(friend, flag)
                                return hcard, friend
                            end
                        end
                    end
                end
            end

        end
    end


    table.sort(cardtogive, cmpByNumber)

    for _, friend in ipairs(friends) do
        if not self:needKongcheng(friend, true) and friend:faceUp() then
            for _, hcard in ipairs(cardtogive) do
                for _, askill in sgs.qlist(friend:getVisibleSkillList(true)) do
                    local callback = sgs.ai_cardneed[askill:objectName()]
                    if type(callback)=="function" and callback(friend, hcard, self) then
                        return hcard, friend
                    end
                end
            end
        end
    end

    if AssistTarget then
        for _, hcard in ipairs(cardtogive) do
            return hcard, AssistTarget
        end
    end

    self:sort(friends, "defense")
    for _, hcard in ipairs(cardtogive) do
        for _, friend in ipairs(friends) do
            if not self:needKongcheng(friend, true) and not self:willSkipPlayPhase(friend) and self:hasSkills(sgs.priority_skill,friend)
                and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3) and friend:getHandcardNum() <= 3 then
                return hcard, friend
            end
        end
    end

    local shoulduse = false

    if #cardtogive == 0 and shoulduse then cardtogive = cards end

    self:sort(friends, "handcard")
    for _, hcard in ipairs(cardtogive) do
        for _, friend in ipairs(friends) do
            if not self:needKongcheng(friend, true) then
                if friend:getHandcardNum() <= 3 and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shoulduse) then
                    return hcard, friend
                end
            end
        end
    end


    for _, hcard in ipairs(cardtogive) do
        for _, friend in ipairs(friends) do
            if (not self:needKongcheng(friend, true) or #friends == 1) then
                if self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shoulduse then
                    return hcard, friend
                end
            end
        end
    end

    for _, hcard in ipairs(cardtogive) do
        for _, friend in ipairs(friends_table) do
            if (not self:needKongcheng(friend, true) or #friends_table == 1) then
                if self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shoulduse then
                    return hcard, friend
                end
            end
        end
    end

    if #cards > 0 and shoulduse then
        local need_rende = (sgs.current_mode_players["rebel"] ==0 and sgs.current_mode_players["loyalist"] > 0 and self.player:isWounded()) or
                (sgs.current_mode_players["rebel"] >0 and sgs.current_mode_players["renegade"] >0 and sgs.current_mode_players["loyalist"] ==0 and self:isWeak())
        if need_rende then
            local players=sgs.QList2Table(self.room:getOtherPlayers(self.player))
            self:sort(players,"defense")
            self:sortByUseValue(cards, true)
            return cards[1], players[1]
        end
    end

end

function SmartAI:askForYiji(card_ids, reason)

    if reason then
        local callback = sgs.ai_skill_askforyiji[string.gsub(reason,"%-","_")]
        if type(callback) == "function" then
            local target, cardid = callback(self, card_ids)
            if target and cardid then return target, cardid end
        end
    end
    return nil, -1
end

function SmartAI:askForPindian(requestor, reason)
    local passive = {}
    if self.player:objectName() == requestor:objectName() and not table.contains(passive, reason) then
        if self[reason .. "_card"] then
            local id = self[reason .. "_card"]
            self[reason .. "_card"] = nil
            if not self.room:getCardOwner(id) or self.room:getCardOwner(id):objectName() ~= self.player:objectName() or self.room:getCardPlace(id) ~= sgs.Player_PlaceHand then
                id = nil
            end
            if id then return id end
        else
            self.room:writeToConsole("Pindian card for " .. reason .. " not found!!")
            return self:getMaxCard(self.player):getId()
        end
    end
    local cards = sgs.QList2Table(self.player:getHandcards())
    local compare_func = function(a, b)
        return a:getNumber() < b:getNumber()
    end
    table.sort(cards, compare_func)
    local maxcard, mincard, minusecard
    for _, card in ipairs(cards) do
        if self:getUseValue(card) < 6 then mincard = card break end
    end
    for _, card in ipairs(sgs.reverse(cards)) do
        if self:getUseValue(card) < 6 then maxcard = card break end
    end
    self:sortByUseValue(cards, true)
    minusecard = cards[1]
    maxcard = maxcard or minusecard
    mincard = mincard or minusecard

    local sameclass, c1 = true
    for _, c2 in ipairs(cards) do
        if not c1 then c1 = c2
        elseif c1:getClassName() ~= c2:getClassName() then sameclass = false end
    end
    if sameclass then
        if self:isFriend(requestor) then return self:getMinCard()
        else return self:getMaxCard() end
    end

    local callback = sgs.ai_skill_pindian[reason]
    if type(callback) == "function" then
        local ret = callback(minusecard, self, requestor, maxcard, mincard)
        if ret then return ret end
    end
    if self:isFriend(requestor) then return mincard else return maxcard end
end

sgs.ai_skill_playerchosen.damage = function(self, targets)
    local targetlist = sgs.QList2Table(targets)
    self:sort(targetlist, "hp")
    for _, target in ipairs(targetlist) do
        if self:isEnemy(target) then return target end
    end
    return targetlist[#targetlist]
end

function SmartAI:askForPlayerChosen(targets, reason)
    local playerchosen = sgs.ai_skill_playerchosen[string.gsub(reason, "%-", "_")]
    local target = nil
    if type(playerchosen) == "function" then
        target = playerchosen(self, targets)
        return target
    end
    local r = math.random(0, targets:length() - 1)
    return targets:at(r)
end

function SmartAI:ableToSave(saver, dying)
    local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuitRed, 0)
    if saver:isCardLimited(peach, sgs.Card_MethodUse, true) then return false end
    return true
end

function SmartAI:willUsePeachTo(dying)
    local card_str
    local forbid = sgs.Sanguosha:cloneCard("peach")
    if self.player:isLocked(forbid) or dying:isLocked(forbid) then return "." end
    if self.player:objectName() == dying:objectName() and not self:needDeath(dying) then
        local analeptic = sgs.Sanguosha:cloneCard("analeptic")
        if not self.player:isLocked(analeptic) and self:getCardId("Analeptic") then return self:getCardId("Analeptic") end
        if self:getCardId("Peach") then return self:getCardId("Peach") end
    end
--[[ 
该段代码仅影响某些情况下内奸出桃救主公，但维护麻烦，会导致一些未写入该段的模式出桃错误
    local mode = string.lower(self.room:getMode())
    if not (mode == "couple" or mode =="02p" or mode =="02_1v1" or mode =="04_1v3"
    or mode =="08_defense" or mode =="04_boss" or mode == "06_XMode") then
        if (self.role == "loyalist" or self.role == "renegade") and isLord(dying) and self.player:aliveCount() > 2 then
            return self:getCardId("Peach")
        end
    end
--]]
    if not sgs.GetConfig("EnableHegemony", false) and self.role == "renegade" and not (dying:isLord() or dying:objectName() == self.player:objectName())
        and (sgs.current_mode_players["loyalist"] + 1 == sgs.current_mode_players["rebel"]
                or sgs.current_mode_players["loyalist"] == sgs.current_mode_players["rebel"]
                or self.room:getCurrent():objectName() == self.player:objectName()
                or sgs.gameProcess(self.room) == "neutral")
            then
        return "."
    end

    if isLord(self.player) and dying:objectName() ~= self.player:objectName() and self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player) > 0 and
        self:getCardsNum("Peach") == 1 and self:isWeak() and self.player:getHp() == 1 then return "." end

    if sgs.ai_role[dying:objectName()] == "renegade" and dying:objectName() ~= self.player:objectName() then
        if self.role == "loyalist" or self.role == "lord" or self.role == "renegade" then
            if sgs.current_mode_players["loyalist"] + sgs.current_mode_players["renegade"] >= sgs.current_mode_players["rebel"] then return "."
            elseif sgs.gameProcess(self.room) == "loyalist" or sgs.gameProcess(self.room) == "loyalish" or sgs.gameProcess(self.room) == "dilemma" then return "."
            end
        end
        if self.role == "rebel" or self.role == "renegade" then
            if sgs.current_mode_players["rebel"] + sgs.current_mode_players["renegade"] - 1 >= sgs.current_mode_players["loyalist"] + 1 then return "."
            elseif sgs.gameProcess(self.room) == "rebelish" or sgs.gameProcess(self.room) == "rebel" or sgs.gameProcess(self.room) == "dilemma" then return "."
            end
        end
    end

    if self:isFriend(dying) then
        if self:needDeath(dying) then return "." end

        local lord = getLord(self.player)
        if not sgs.GetConfig("EnableHegemony", false) and self.player:objectName() ~= dying:objectName() and not dying:isLord() and
        (self.role == "loyalist" or self.role == "renegade" and self.room:alivePlayerCount() > 2) and
            ((self:getCardsNum("Peach") <= sgs.ai_NeedPeach[lord:objectName()]) or
            (sgs.ai_lord_in_danger_SA and lord and getCardsNum("Slash", lord, self.player) < 1 and self:getCardsNum("Peach") < 2) or
            (sgs.ai_lord_in_danger_AA and lord and getCardsNum("Jink", lord, self.player) < 1 and self:getCardsNum("Peach") < 2)) then
            return "."
        end

        if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= sgs.ai_NeedPeach[self.player:objectName()] and not isLord(dying) then return "." end

        if math.ceil(self:getAllPeachNum()) < 1 - dying:getHp() and not isLord(dying) then return "." end

        if not dying:isLord() and dying:objectName() ~= self.player:objectName() then
            local possible_friend = 0
            for _, friend in ipairs(self.friends_noself) do
                if (self:getKnownNum(friend) == friend:getHandcardNum() and getCardsNum("Peach", friend, self.player) == 0)
                    or (self:playerGetRound(friend) < self:playerGetRound(self.player)) then
                elseif sgs.card_lack[friend:objectName()]["Peach"] == 1 then
                elseif not self:ableToSave(friend, dying) then
                elseif friend:getHandcardNum() > 0 or getCardsNum("Peach", friend, self.player) > 0 then
                    possible_friend = possible_friend + 1
                end
            end
            if possible_friend == 0 and self:getCardsNum("Peach") < 1 - dying:getHp() then
                return "."
            end
        end

        local CP = self.room:getCurrent()
        if lord then
            if dying:objectName() ~= lord:objectName() and dying:objectName() ~= self.player:objectName() and lord:getHp() == 1 and
                self:isFriend(lord) and self:isEnemy(CP) and CP:canSlash(lord, nil, true) and getCardsNum("Peach", lord, self.player) < 1 and
                getCardsNum("Analeptic", lord, self.player) < 1 and #self.friends_noself <= 2 and self:slashIsAvailable(CP) and
                self:damageIsEffective(CP, nil, lord) and self:getCardsNum("Peach") <= self:getEnemyNumBySeat(CP, lord, self.player) + 1 then
                return "."
            end
        end

        local weaklord = 0

        if (self.player:objectName() == dying:objectName()) then
            card_str = self:getCardId("Analeptic")
            if not card_str then
                card_str = self:getCardId("Peach")
            end
        elseif dying:isLord() then
            card_str = self:getCardId("Peach")
        elseif self:doNotSave(dying) then return "."
        else
            for _, friend in ipairs(self.friends_noself) do
                if friend:getHp() == 1 and friend:isLord() then  weaklord = weaklord + 1 end
            end
            for _, enemy in ipairs(self.enemies) do
                if enemy:getHp() == 1 and enemy:isLord() and self.player:getRole() == "renegade" then weaklord = weaklord + 1 end
            end
            if weaklord < 1 or self:getAllPeachNum() > 1 then
                card_str = self:getCardId("Peach")
            end
        end
    else --救对方的情形
       -- 鞭尸...
        if not dying:hasSkills(sgs.masochism_skill)
            and not sgs.GetConfig("EnableHegemony", false) then
            local mode = string.lower(self.room:getMode())
            if mode == "couple" or mode == "fangcheng" or mode == "guandu" or mode == "custom_scenario"
                or string.find(mode, "mini") or mode == "04_1v3" then
            elseif mode == "06_3v3"  then
                if #self.enemies == 1 and self.enemies[1]:isNude() and #self.friends == 3 then
                    local hasWeakfriend
                    for _, friend in ipairs(self.friends) do
                        if self:isWeak(friend) then hasWeakfriend = true break end
                    end
                    if not hasWeakfriend then
                        card_str = self:getCardId("Peach")
                        if card_str then
                            self:speak("bianshi", dying:isFemale())
                            sgs.ai_doNotUpdateIntenion = true
                        end
                    end
                end
            elseif string.find(mode, "p") and mode >= "03p" and sgs.current_mode_players.renegade == 0 then
                if (self.role == "lord" or self.role == "loyalist") and sgs.current_mode_players.rebel == 1 and #self.enemies == 1 and self.enemies[1]:isNude() and
                    self.room:getCurrent():getNextAlive():objectName() ~= self.enemies[1]:objectName() and #self.friends >= 3 then
                    card_str = self:getCardId("Peach")
                    if card_str then
                        self:speak("bianshi", dying:isFemale())
                        sgs.ai_doNotUpdateIntenion = true
                    end
                elseif self.role == "rebel" and sgs.current_mode_players.loyalist == 0 and #self.enemies == 1 and self.enemies[1]:isNude() and
                    self.room:getCurrent():getNextAlive():objectName() ~= self.enemies[1]:objectName() and #self.friends >= 3 then
                    local hasWeakfriend
                    for _, friend in ipairs(self.friends) do
                        if self:isWeak(friend) then hasWeakfriend = true break end
                    end
                    if not hasWeakfriend then
                        card_str = self:getCardId("Peach")
                        if card_str then
                            self:speak("bianshi", dying:isFemale())
                            sgs.ai_doNotUpdateIntenion = true
                        end
                    end
                end
            end
        end

    end
    if not card_str then return nil end
    return card_str
end

function SmartAI:askForSinglePeach(dying)
    local card_str = self:willUsePeachTo(dying)
    return card_str or "."
end

function SmartAI:getTurnUse()
    local cards = {}
    for _ ,c in sgs.qlist(self.player:getHandcards()) do
        if c:isAvailable(self.player) then table.insert(cards, c) end
    end
    for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
        local c = sgs.Sanguosha:getCard(id)
        if c:isAvailable(self.player) then table.insert(cards, c) end
    end

    local turnUse = {}
    local slash = sgs.Sanguosha:cloneCard("slash")
    local slashAvail = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash)
    self.slashAvail = slashAvail
    self.predictedRange = self.player:getAttackRange()
    self.slash_distance_limit = (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50)

    self.weaponUsed = false
    self:fillSkillCards(cards)
    self:sortByUseValue(cards)

    if self.player:hasWeapon("crossbow") or #self.player:property("extra_slash_specific_assignee"):toString():split("+") > 1 then
        slashAvail = 100
        self.slashAvail = slashAvail
    elseif self.player:hasWeapon("vscrossbow") then
        slashAvail = slashAvail + 3
        self.slashAvail = slashAvail
    end

    for _, card in ipairs(cards) do
        local dummy_use = { isDummy = true }

        local type = card:getTypeId()
        self["use" .. sgs.ai_type_name[type + 1] .. "Card"](self, card, dummy_use)

        if dummy_use.card then
            if dummy_use.card:isKindOf("Slash") then
                if slashAvail > 0 then
                    slashAvail = slashAvail - 1
                    table.insert(turnUse, dummy_use.card)
                elseif dummy_use.card:hasFlag("AIGlobal_KillOff") then table.insert(turnUse, dummy_use.card) end
            else
                if self.player:hasFlag("InfinityAttackRange") or self.player:getMark("InfinityAttackRange") > 0 then
                    self.predictedRange = 10000
                elseif dummy_use.card:isKindOf("Weapon") then
                    self.predictedRange = sgs.weapon_range[card:getClassName()]
                    self.weaponUsed = true
                else
                    self.predictedRange = 1
                end
                if dummy_use.card:objectName() == "Crossbow" then slashAvail = 100 self.slashAvail = slashAvail end
                if dummy_use.card:objectName() == "VSCrossbow" then slashAvail = slashAvail + 3 self.slashAvail = slashAvail end
                table.insert(turnUse, dummy_use.card)
            end
        end
    end

    return turnUse
end

function SmartAI:activate(use)
    self:updatePlayers()
    self:assignKeep(true)
    self.toUse = self:getTurnUse()
    self:sortByDynamicUsePriority(self.toUse)
    for _, card in ipairs(self.toUse) do
        if not self.player:isCardLimited(card, card:getHandlingMethod())
            or (card:canRecast() and not self.player:isCardLimited(card, sgs.Card_MethodRecast)) then
            local type = card:getTypeId()
            self["use" .. sgs.ai_type_name[type + 1] .. "Card"](self, card, use)

            if use:isValid(nil) then
                self.toUse = nil
                return
            end
        end
    end
    self.toUse = nil
end

function SmartAI:getOverflow(player, getMaxCards)
    player = player or self.player

    local MaxCards = 0
    if getMaxCards and MaxCards > 0 then return MaxCards end
    MaxCards = player:getMaxCards()
    if getMaxCards then return player:getMaxCards() end

    return player:getHandcardNum() - MaxCards
end

function SmartAI:isWeak(player)
    player = player or self.player
    local hcard = player:getHandcardNum()
    if (player:getHp() <= 2 and hcard <= 2) or player:getHp() <= 1 then return true end
    return false
end

function SmartAI:useCardByClassName(card, use)
    if not card then global_room:writeToConsole(debug.traceback()) return end
    local class_name = card:getClassName()
    local use_func = self["useCard" .. class_name]

    if use_func then
        use_func(self, card, use)
    end
end

function SmartAI:hasWizard(players, onlyharm)
    local skill
    if onlyharm then skill = sgs.wizard_harm_skill else skill = sgs.wizard_skill end
    for _, player in ipairs(players) do
        if player:hasSkills(skill) then
            return true
        end
    end
end

function SmartAI:canRetrial(player, to_retrial, reason)
    player = player or self.player
    to_retrial = to_retrial or self.player
    return false
end

function SmartAI:getFinalRetrial(player, reason)
    local maxfriendseat = -1
    local maxenemyseat = -1
    local tmpfriend
    local tmpenemy
    local wizardf, wizarde
    player = player or self.room:getCurrent()
    for _, aplayer in ipairs(self.friends) do
        if aplayer:hasSkills(sgs.wizard_harm_skill) and self:canRetrial(aplayer, player, reason) then
            tmpfriend = (aplayer:getSeat() - player:getSeat()) % (global_room:alivePlayerCount())
            if tmpfriend > maxfriendseat then
                maxfriendseat = tmpfriend
                wizardf = aplayer
            end
        end
    end
    for _, aplayer in ipairs(self.enemies) do
        if aplayer:hasSkills(sgs.wizard_harm_skill) and self:canRetrial(aplayer, player, reason) then
            tmpenemy = (aplayer:getSeat() - player:getSeat()) % (global_room:alivePlayerCount())
            if tmpenemy > maxenemyseat then
                maxenemyseat = tmpenemy
                wizarde = aplayer
            end
        end
    end
    if maxfriendseat == -1 and maxenemyseat == -1 then return 0, nil
    elseif maxfriendseat > maxenemyseat then return 1, wizardf
    else return 2, wizarde end
end

--- Determine that the current judge is worthy retrial
-- @param judge The JudgeStruct that contains the judge information
-- @return True if it is needed to retrial
function SmartAI:needRetrial(judge)
    local reason = judge.reason
    local lord = getLord(self.player)
    local who = judge.who
    local isFriend = self:isFriend(who)
    local isGood = judge:isGood()
    if reason == "lightning" then
        if lord and (who:isLord() or (who:isChained() and lord:isChained())) and self:objectiveLevel(lord) <= 3 then
            if lord:hasArmorEffect("silver_lion") and lord:getHp() >= 2 and self:isGoodChainTarget(lord, self.player, sgs.DamageStruct_Thunder) then return false end
            return self:damageIsEffective(lord, sgs.DamageStruct_Thunder) and not judge:isGood()
        end

        if who:hasArmorEffect("silver_lion") and who:getHp() > 1 then return false end

        if self:isFriend(who) then
            if who:isChained() and self:isGoodChainTarget(who, self.player, sgs.DamageStruct_Thunder, 3) then return false end
        else
            if who:isChained() and not self:isGoodChainTarget(who, self.player, sgs.DamageStruct_Thunder, 3) then return judge:isGood() end
        end
    end

    if reason == "indulgence" then
        if self:isFriend(who) then
            local drawcardnum = self:ImitateResult_DrawNCards(who, who:getVisibleSkillList(true))
            if who:getHp() - who:getHandcardNum() >= drawcardnum and self:getOverflow() < 0 then return false end
            return not judge:isGood()
        else
            return judge:isGood()
        end
    end

    if reason == "supply_shortage" then
        if self:isFriend(who) then
            return not judge:isGood()
        else
            return judge:isGood()
        end
    end

    local callback = sgs.ai_need_retrial_func[reason]
    if type(callback) == "function" then
        local need = callback(self, judge, isGood, who, isFriend, lord)
        if type(need) == "boolean" then
            return need
        end
    elseif type(callback) == "boolean" then
        return callback
    end
    
    if self:isFriend(who) then
        return not judge:isGood()
    elseif self:isEnemy(who) then
        return judge:isGood()
    else
        return false
    end
end

--- Get the retrial cards with the lowest keep value
-- @param cards the table that contains all cards can use in retrial skill
-- @param judge the JudgeStruct that contains the judge information
-- @return the retrial card id or -1 if not found
function SmartAI:getRetrialCardId(cards, judge, self_card)
    if self_card == nil then self_card = true end
    local can_use = {}
    local reason = judge.reason
    local who = judge.who

    local other_suit, hasSpade = {}
    for _, card in ipairs(cards) do
        local card_x = sgs.Sanguosha:getEngineCard(card:getEffectiveId())
        if self:isFriend(who) and judge:isGood(card_x)
                and not (self_card and (self:getFinalRetrial() == 2 or self:dontRespondPeachInJudge(judge)) and isCard("Peach", card_x, self.player)) then
            table.insert(can_use, card)
        elseif self:isEnemy(who) and not judge:isGood(card_x)
                and not (self_card and (self:getFinalRetrial() == 2 or self:dontRespondPeachInJudge(judge)) and isCard("Peach", card_x, self.player)) then
            table.insert(can_use, card)
        end
    end
    if not hasSpade and #other_suit > 0 then table.insertTable(can_use, other_suit) end
    
    if reason ~= "lightning" then
        for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
            if aplayer:containsTrick("lightning") then
                for i, card in ipairs(can_use) do
                    if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
                        table.remove(can_use, i)
                        break
                    end
                end
            end
        end
    end
    
    if next(can_use) then
        if self:needToThrowArmor() then
            for _, c in ipairs(can_use) do
                if c:getEffectiveId() == self.player:getArmor():getEffectiveId() then return c:getEffectiveId() end
            end
        end
        self:sortByKeepValue(can_use)
        return can_use[1]:getEffectiveId()
    else
        return -1
    end
end

function SmartAI:damageIsEffective(to, nature, from)
    local damageStruct = {}
    damageStruct.to = to or self.player
    damageStruct.from = from or self.room:getCurrent()
    damageStruct.nature = nature or sgs.DamageStruct_Normal
    return self:damageIsEffective_(damageStruct)
end

function SmartAI:damageIsEffective_(damageStruct)

    if type(damageStruct) ~= "table" and type(damageStruct) ~= "userdata" then self.room:writeToConsole(debug.traceback()) return end
    if not damageStruct.to then self.room:writeToConsole(debug.traceback()) return end
    local to = damageStruct.to
    local nature = damageStruct.nature or sgs.DamageStruct_Normal
    local damage = damageStruct.damage or 1
    local from = damageStruct.from

    for _, callback in ipairs(sgs.ai_damage_effect) do
        if type(callback) == "function" then
            local is_effective = callback(self, to, nature, from)
            if not is_effective then return false end
        end
    end

    return true
end

function SmartAI:getDamagedEffects(to, from, isSlash)
    from = from or self.room:getCurrent()
    to = to or self.player

    if isSlash then
        if from:hasWeapon("ice_sword") and to:getCards("he"):length() > 1 and not self:isFriend(from, to) then
            return false
        end
    end

    if from:objectName() ~= to:objectName() and self:hasHeavySlashDamage(from, nil, to) then return false end

    if sgs.isGoodHp(to) then
        for _, askill in sgs.qlist(to:getVisibleSkillList(true)) do
            local callback = sgs.ai_need_damaged[askill:objectName()]
            if type(callback) == "function" and callback(self, from, to) then return true end
        end
    end
    return false
end

local function prohibitUseDirectly(card, player)
    if player:isCardLimited(card, card:getHandlingMethod()) then return true end
    if card:isKindOf("Peach") and player:getMark("Global_PreventPeach") > 0 then return true end
    return false
end

function sgs.getPlayerSkillList(player)
    local skills = sgs.QList2Table(player:getVisibleSkillList(true))
    return skills
end

local function cardsViewValuable(self, class_name, player)
    for _, skill in ipairs(sgs.getPlayerSkillList(player)) do
        local askill = skill:objectName()
        if player:hasSkill(askill) or player:hasLordSkill(askill) then
            local callback = sgs.ai_cardsview_valuable[askill]
            if type(callback) == "function" then
                local ret = callback(self, class_name, player)
                if ret then return ret end
            end
        end
    end
end

local function cardsView(self, class_name, player)
    for _, skill in ipairs(sgs.getPlayerSkillList(player)) do
        local askill = skill:objectName()
        if player:hasSkill(askill) or player:hasLordSkill(askill) then
            local callback = sgs.ai_cardsview_valuable[askill]
            if type(callback) == "function" then
                local ret = callback(self, class_name, player)
                if ret then return ret end
            end
        end
    end
    for _, skill in ipairs(sgs.getPlayerSkillList(player)) do
        local askill = skill:objectName()
        if player:hasSkill(askill) or player:hasLordSkill(askill) then
            local callback = sgs.ai_cardsview[askill]
            if type(callback) == "function" then
                local ret = callback(self, class_name, player)
                if ret then return ret end
            end
        end
    end
end

local function getSkillViewCard(card, class_name, player, card_place)
    for _, skill in ipairs(sgs.getPlayerSkillList(player)) do
        local askill = skill:objectName()
        if player:hasSkill(askill) or player:hasLordSkill(askill) then
            local callback = sgs.ai_view_as[askill]
            if type(callback) == "function" then
                local skill_card_str = callback(card, player, card_place, class_name)
                if skill_card_str then
                    local skill_card = sgs.Card_Parse(skill_card_str)
                    if skill_card:isKindOf(class_name) and not player:isCardLimited(skill_card, skill_card:getHandlingMethod()) then return skill_card_str end
                end
            end
        end
    end
end

function isCard(class_name, card, player)
    if not player or not card then global_room:writeToConsole(debug.traceback()) end
    if not card:isKindOf(class_name) then
        local place
        local id = card:getEffectiveId()
        if global_room:getCardOwner(id) == nil or global_room:getCardOwner(id):objectName() ~= player:objectName() then place = sgs.Player_PlaceHand
        else place = global_room:getCardPlace(card:getEffectiveId()) end
        if getSkillViewCard(card, class_name, player, place) then return true end
    else
        if not prohibitUseDirectly(card, player) then return true end
    end
    return false
end

function SmartAI:getMaxCard(player, cards)
    player = player or self.player

    if player:isKongcheng() then
        return nil
    end

    cards = cards or player:getHandcards()
    local max_card, max_point = nil, 0
    for _, card in sgs.qlist(cards) do
        local flag = string.format("%s_%s_%s", "visible", global_room:getCurrent():objectName(), player:objectName())
        if (player:objectName() == self.player:objectName() and not self:isValuableCard(card)) or card:hasFlag("visible") or card:hasFlag(flag) then
            local point = card:getNumber()
            if point > max_point then
                max_point = point
                max_card = card
            end
        end
    end
    if player:objectName() == self.player:objectName() and not max_card then
        for _, card in sgs.qlist(cards) do
            local point = card:getNumber()
            if point > max_point then
                max_point = point
                max_card = card
            end
        end
    end

    if player:objectName() ~= self.player:objectName() then return max_card end
	
    return max_card
end

function SmartAI:getMinCard(player)
    player = player or self.player

    if player:isKongcheng() then
        return nil
    end

    local cards = player:getHandcards()
    local min_card, min_point = nil, 14
    for _, card in sgs.qlist(cards) do
        local flag = string.format("%s_%s_%s", "visible", global_room:getCurrent():objectName(), player:objectName())
        if player:objectName() == self.player:objectName() or card:hasFlag("visible") or card:hasFlag(flag) then
            local point = card:getNumber()
            if point < min_point then
                min_point = point
                min_card = card
            end
        end
    end

    return min_card
end

function SmartAI:getKnownNum(player)
    player = player or self.player
    if not player then
        return self.player:getHandcardNum()
    else
        local cards = player:getHandcards()
        for _, id in sgs.qlist(player:getPile("wooden_ox")) do
            cards:append(sgs.Sanguosha:getCard(id))
        end
        local known = 0
        for _, card in sgs.qlist(cards) do
            local flag=string.format("%s_%s_%s","visible",global_room:getCurrent():objectName(),player:objectName())
            if card:hasFlag("visible") or card:hasFlag(flag) then
                known = known + 1
            end
        end
        return known
    end
end

function getKnownNum(player, anotherplayer)
    if not player then global_room:writeToConsole(debug.traceback()) return end
    local cards = player:getHandcards()
    for _, id in sgs.qlist(player:getPile("wooden_ox")) do
        cards:append(sgs.Sanguosha:getCard(id))
    end
    local known = 0
    anotherplayer = anotherplayer or global_room:getCurrent()
    if not anotherplayer then global_room:writeToConsole("cheat?") return 0 end
    for _, card in sgs.qlist(cards) do
        local flag=string.format("%s_%s_%s", "visible", anotherplayer:objectName(), player:objectName())
        if card:hasFlag("visible") or card:hasFlag(flag) then
            known = known + 1
        end
    end
    return known
end

function getKnownCard(player, from, class_name, viewas, flags)
    if not player or (flags and type(flags) ~= "string") then global_room:writeToConsole(debug.traceback()) return 0 end
    flags = flags or "h"
    player = findPlayerByObjectName(global_room, player:objectName(), true)
    local forbid = false
    if not from and global_room:getCurrent() and player:objectName() == global_room:getCurrent():objectName() then
        forbid = true
    end
    from = from or global_room:getCurrent()
    local cards = player:getCards(flags)
    if flags:match("h") then
        for _, id in sgs.qlist(player:getPile("wooden_ox")) do
            cards:append(sgs.Sanguosha:getCard(id))
        end
    end
    local known = 0
    local suits = {["club"] = 1, ["spade"] = 1, ["diamond"] = 1, ["heart"] = 1}
    for _, card in sgs.qlist(cards) do
        local flag = string.format("%s_%s_%s", "visible", from:objectName(), player:objectName())
        if card:hasFlag("visible") or card:hasFlag(flag) or not forbid and player:objectName() == from:objectName() then
            if (viewas and isCard(class_name, card, player)) or card:isKindOf(class_name)
                or (suits[class_name] and card:getSuitString() == class_name)
                or (class_name == "red" and card:isRed()) or (class_name == "black" and card:isBlack()) then
                known = known + 1
            end
        end
    end
    return known
end

function SmartAI:getCardId(class_name, player, acard)
    player = player or self.player
    local cards
    if acard then cards = { acard }
    else
        cards = player:getCards("he")
        for _, key in sgs.list(player:getPileNames()) do
            for _, id in sgs.qlist(player:getPile(key)) do
                cards:append(sgs.Sanguosha:getCard(id))
            end
        end
        cards = sgs.QList2Table(cards)
    end
    self:sortByUsePriority(cards, player)

    local card_str = cardsViewValuable(self, class_name, player)
    if card_str then return card_str end

    local viewArr, cardArr = {}, {}

    for _, card in ipairs(cards) do
        local viewas, cardid
        local card_place = self.room:getCardPlace(card:getEffectiveId())
        viewas = getSkillViewCard(card, class_name, player, card_place)

        local isCard = card:isKindOf(class_name) and not prohibitUseDirectly(card, self.player)
                        and (card_place ~= sgs.Player_PlaceSpecial or self.player:getPile("wooden_ox"):contains(card:getEffectiveId()))
        if viewas then
            table.insert(viewArr, viewas)
        end
        if isCard then
            table.insert(cardArr, card:getEffectiveId())
        end
    end
    if #viewArr > 0 or #cardArr > 0 then
        local viewas, cardid
        viewas = #viewArr > 0 and viewArr[1]
        cardid = #cardArr > 0 and cardArr[1]
        local viewCard
        if viewas then viewCard = sgs.Card_Parse(viewas) end
        return (cardid or viewas)
    end
    return cardsView(self, class_name, player)
end

function SmartAI:getCard(class_name, player)
    player = player or self.player
    local card_id = self:getCardId(class_name, player)
    if card_id then return sgs.Card_Parse(card_id) end
end

function SmartAI:getCards(class_name, flag)
    local player = self.player
    local room = self.room
    if flag and type(flag) ~= "string" then room:writeToConsole(debug.traceback()) return {} end

    local private_pile
    if not flag then private_pile = true end
    flag = flag or "he"
    local all_cards = player:getCards(flag)
    if private_pile then
        for _, key in sgs.list(player:getPileNames()) do
            for _, id in sgs.qlist(player:getPile(key)) do
                all_cards:append(sgs.Sanguosha:getCard(id))
            end
        end
    elseif flag:match("h") then
        for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
            all_cards:append(sgs.Sanguosha:getCard(id))
        end
    end

    local cards = {}
    local card_place, card_str

    card_str = cardsViewValuable(self, class_name, player)
    if card_str then
        card_str = sgs.Card_Parse(card_str)
        table.insert(cards, card_str)
    end

    for _, card in sgs.qlist(all_cards) do
        card_place = room:getCardPlace(card:getEffectiveId())

        if card:hasFlag("AI_Using") then
        elseif class_name == "." and card_place ~= sgs.Player_PlaceSpecial then table.insert(cards, card)
        elseif card:isKindOf(class_name) and not prohibitUseDirectly(card, player) and card_place ~= sgs.Player_PlaceSpecial then table.insert(cards, card)
        else
            card_str = getSkillViewCard(card, class_name, player, card_place)
            if card_str then
                card_str = sgs.Card_Parse(card_str)
                table.insert(cards, card_str)
            end
        end
    end

    card_str = cardsView(self, class_name, player)
    if card_str then
        card_str = sgs.Card_Parse(card_str)
        table.insert(cards, card_str)
    end

    return cards
end

function getCardsNum(class_name, player, from)
    if not player then
        global_room:writeToConsole(debug.traceback())
        return 0
    end
    local cards = sgs.QList2Table(player:getHandcards())
    for _, id in sgs.qlist(player:getPile("wooden_ox")) do
        table.insert(cards, sgs.Sanguosha:getCard(id))
    end
    local num = 0
    local shownum = 0
    local redpeach = 0
    local redslash = 0
    local blackcard = 0
    local blacknull = 0
    local equipnull = 0
    local equipcard = 0
    local heartslash = 0
    local heartpeach = 0
    local spadenull = 0
    local spadewine = 0
    local spadecard = 0
    local diamondcard = 0
    local clubcard = 0
    local slashjink = 0

    local forbid = false
    if not from and global_room:getCurrent() and player:objectName() == global_room:getCurrent():objectName() then
        forbid = true
    end

    from = from or global_room:getCurrent()

    if not player then
        return #getCards(class_name, player)
    else
        for _, card in ipairs(cards) do
            local flag = string.format("%s_%s_%s", "visible", from:objectName(), player:objectName())
            if card:hasFlag("visible") or card:hasFlag(flag) or not forbid and from:objectName() == player:objectName() then
                shownum = shownum + 1
                if card:isKindOf(class_name) then
                    num = num + 1
                end
                if card:isKindOf("EquipCard") then
                    equipcard = equipcard + 1
                end
                if card:isKindOf("Slash") or card:isKindOf("Jink") then
                    slashjink = slashjink + 1
                end
                if card:isRed() then
                    if not card:isKindOf("Slash") then
                        redslash = redslash + 1
                    end
                    if not card:isKindOf("Peach") then
                        redpeach = redpeach + 1
                    end
                end
                if card:isBlack() then
                    blackcard = blackcard + 1
                    if not card:isKindOf("Nullification") then
                        blacknull = blacknull + 1
                    end
                end
                if card:getSuit() == sgs.Card_Heart then
                    if not card:isKindOf("Slash") then
                        heartslash = heartslash + 1
                    end
                    if not card:isKindOf("Peach") then
                        heartpeach = heartpeach + 1
                    end
                end
                if card:getSuit() == sgs.Card_Spade then
                    if not card:isKindOf("Nullification") then
                        spadenull = spadenull + 1
                    end
                    if not card:isKindOf("Analeptic") then
                        spadewine = spadewine + 1
                    end
                end
                if card:getSuit() == sgs.Card_Diamond and not card:isKindOf("Slash") then
                    diamondcard = diamondcard + 1
                end
                if card:getSuit() == sgs.Card_Club then
                    clubcard = clubcard + 1
                end
            end
        end
    end
    local ecards = player:getCards("e")
    for _, card in sgs.qlist(ecards) do
        equipcard = equipcard + 1
        if player:getHandcardNum() > player:getHp() then
            equipnull = equipnull + 1
        end
        if card:isRed() then
            redpeach = redpeach + 1
            redslash = redslash + 1
        end
        if card:getSuit() == sgs.Card_Heart then
            heartpeach = heartpeach + 1
        end
        if card:getSuit() == sgs.Card_Spade then
            spadecard = spadecard + 1
        end
        if card:getSuit() == sgs.Card_Diamond  then
            diamondcard = diamondcard + 1
        end
        if card:getSuit() == sgs.Card_Club then
            clubcard = clubcard + 1
        end
    end

    if class_name == "Slash" then
        local slashnum = num+(player:getHandcardNum() - shownum)*0.35
        return slashnum
    elseif class_name == "Jink" then
        return num + (player:getHandcardNum() - shownum)*0.6
    elseif class_name == "Peach" then
        return num
    elseif class_name == "Analeptic" then
        return num
    elseif class_name == "Nullification" then
        return num
    else
        return num
    end
end

function SmartAI:getCardsNum(class_name, flag, selfonly)
    local player = self.player
    local n = 0
    if type(class_name) == "table" then
        for _, each_class in ipairs(class_name) do
            n = n + self:getCardsNum(each_class, flag, selfonly)
        end
        return n
    end
    n = #self:getCards(class_name, flag)

    local card_str = cardsView(self, class_name, player)
    if card_str then
        card_str = sgs.Card_Parse(card_str)
        if card_str then
            if card_str:getSkillName() == "spear" then
                n = n + math.floor(player:getHandcardNum() / 2) - 1
            end
        end
    end

    if selfonly then return n end
    return n
end

function SmartAI:getAllPeachNum(player)
    player = player or self.player
    local n = 0
    for _, friend in ipairs(self:getFriends(player)) do
        local num = self.player:objectName() == friend:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", friend, self.player)
        n = n + num
    end
    return n
end
function SmartAI:getRestCardsNum(class_name, yuji)
    yuji = yuji or self.player
    local ban = sgs.Sanguosha:getBanPackages()
    ban = table.concat(ban, "|")
    sgs.discard_pile = self.room:getDiscardPile()
    local totalnum = 0
    local discardnum = 0
    local knownnum = 0
    local card
    for i=1, sgs.Sanguosha:getCardCount() do
        card = sgs.Sanguosha:getEngineCard(i-1)
        if card:isKindOf(class_name) then totalnum = totalnum + 1 end
    end
    for _, card_id in sgs.qlist(sgs.discard_pile) do
        card = sgs.Sanguosha:getEngineCard(card_id)
        if card:isKindOf(class_name) then discardnum = discardnum + 1 end
    end
    for _, player in sgs.qlist(self.room:getOtherPlayers(yuji)) do
        knownnum = knownnum + getKnownCard(player, self.player, class_name)
    end
    return totalnum - discardnum - knownnum
end

function SmartAI:hasSuit(suit_strings, include_equip, player)
    return self:getSuitNum(suit_strings, include_equip, player) > 0
end

function SmartAI:getSuitNum(suit_strings, include_equip, player)
    player = player or self.player
    local n = 0
    local flag = include_equip and "he" or "h"
    local allcards
    if player:objectName() == self.player:objectName() then
        allcards = sgs.QList2Table(player:getCards(flag))
    else
        allcards = include_equip and sgs.QList2Table(player:getEquips()) or {}
        local handcards = sgs.QList2Table(player:getHandcards())
        local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), player:objectName())
        for i = 1, #handcards, 1 do
            if handcards[i]:hasFlag("visible") or handcards[i]:hasFlag(flag) then
                table.insert(allcards, handcards[i])
            end
        end
    end
    for _, card in ipairs(allcards) do
        for _, suit_string in ipairs(suit_strings:split("|")) do
            if card:getSuitString() == suit_string
                or (suit_string == "black" and card:isBlack()) or (suit_string == "red" and card:isRed()) then
                n = n + 1
            end
        end
    end
    return n
end

function SmartAI:hasSkill(skill)
    local skill_name = skill
    if type(skill) == "table" then
        skill_name = skill.name
    end

    local real_skill = sgs.Sanguosha:getSkill(skill_name)
    if real_skill and real_skill:isLordSkill() then
        return self.player:hasLordSkill(skill_name)
    else
        return self.player:hasSkill(skill_name)
    end
end

function SmartAI:hasSkills(skill_names, player)
    player = player or self.player
    if type(player) == "table" then
        for _, p in ipairs(player) do
            if p:hasSkills(skill_names) then return true end
        end
        return false
    end
    if type(skill_names) == "string" then
        return player:hasSkills(skill_names)
    end
    return false
end

function SmartAI:fillSkillCards(cards)
    local i = 1
    while i <= #cards do
        if prohibitUseDirectly(cards[i], self.player) then
            table.remove(cards, i)
        else
            i = i + 1
        end
    end
    for _, skill in ipairs(sgs.ai_skills) do
        if self:hasSkill(skill) or self.player:getMark("ViewAsSkill_" .. skill.name .. "Effect") > 0 then
            local skill_card = skill.getTurnUseCard(self, #cards == 0)
            if skill_card then table.insert(cards, skill_card) end
        end
    end
end

function SmartAI:useSkillCard(card, use)
    local name
    if card:isKindOf("LuaSkillCard") then
        name = "#" .. card:objectName()
    else
        name = card:getClassName()
    end
    if sgs.ai_skill_use_func[name] then
        sgs.ai_skill_use_func[name](card, use, self)
        if use.to then
            if not use.to:isEmpty() and sgs.dynamic_value.damage_card[name] then
                for _, target in sgs.qlist(use.to) do
                    if self:damageIsEffective(target) then return end
                end
                use.card = nil
            end
        end
        return
    end
    if self["useCard"..name] then
        self["useCard"..name](self, card, use)
    end
    if use.card then
        local shit = 0
        local subcards = use.card:getSubcards()
        for _,c in sgs.qlist(subcards) do
            if c:isKindOf("Shit") then
                shit = shit + 1
            end
        end
        if shit > 0 and shit >= self.player:getHp() then
            if shit - self.player:getHp() > self:getAllPeachNum() then
                use.card = nil
            end
        end
    end    
end

function SmartAI:useBasicCard(card, use)
    if not card then global_room:writeToConsole(debug.traceback()) return end
    if not (card:isKindOf("Peach") and self.player:getLostHp() > 1) and self:needBear() then return end
    self:useCardByClassName(card, use)
end

function SmartAI:aoeIsEffective(card, to, source)
    local players = self.room:getAlivePlayers()
    players = sgs.QList2Table(players)
    source = source or self.room:getCurrent()

    if to:hasArmorEffect("vine") then
        return false
    end
    if self.room:isProhibited(self.player, to, card) then
        return false
    end
    if to:isLocked(card) then
        return false
    end

    if not self:hasTrickEffective(card, to, source) or not self:damageIsEffective(to, sgs.DamageStruct_Normal, source) then
        return false
    end
    return true
end

function SmartAI:canAvoidAOE(card)
    if not self:aoeIsEffective(card, self.player) then return true end
    if card:isKindOf("SavageAssault") then
        if self:getCardsNum("Slash") > 0 then
            return true
        end
    end
    if card:isKindOf("ArcheryAttack") then
        if self:getCardsNum("Jink") > 0 or (self:hasEightDiagramEffect() and self.player:getHp() > 1) then
            return true
        end
    end
    return false
end

function SmartAI:getDistanceLimit(card, from)
    from = from or self.player
    if (card:isKindOf("Snatch") or card:isKindOf("SupplyShortage")) then
        return 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, from, card)
    elseif card:isKindOf("Slash") then
        return from:getAttackRange() + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, from, card)
    end
end

function SmartAI:exclude(players, card, from)
    from = from or self.player
    local excluded = {}
    local limit = self:getDistanceLimit(card, from)
    local range_fix = 0

    if type(players) ~= "table" then players = sgs.QList2Table(players) end

    if card:isVirtualCard() then
        for _, id in sgs.qlist(card:getSubcards()) do
            if from:getOffensiveHorse() and from:getOffensiveHorse():getEffectiveId() == id then range_fix = range_fix + 1 end
        end
    end

    for _, player in ipairs(players) do
        if not self.room:isProhibited(from, player, card) then
            local should_insert = true
            if limit then
                should_insert = from:distanceTo(player, range_fix) <= limit
            end
            if should_insert then
                table.insert(excluded, player)
            end
        end
    end
    return excluded
end


function SmartAI:getJiemingChaofeng(player)
    local max_x, chaofeng = 0, 0
    for _, friend in ipairs(self:getFriends(player)) do
        local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
        if x > max_x then
            max_x = x
        end
    end
    if max_x < 2 then
        chaofeng = 5 - max_x * 2
    else
        chaofeng = (-max_x) * 2
    end
    return chaofeng
end

function SmartAI:getAoeValueTo(card, to, from)
    local value, sj_num = 0, 0
    if card:isKindOf("ArcheryAttack") then sj_num = getCardsNum("Jink", to, from) end
    if card:isKindOf("SavageAssault") then sj_num = getCardsNum("Slash", to, from) end

    if self:aoeIsEffective(card, to, from) then
        local jink = sgs.Sanguosha:cloneCard("jink")
        local slash = sgs.Sanguosha:cloneCard("slash")
        local isLimited
        if card:isKindOf("ArcheryAttack") and to:isCardLimited(jink, sgs.Card_MethodResponse) then isLimited = true
        elseif card:isKindOf("SavageAssault") and to:isCardLimited(slash, sgs.Card_MethodResponse) then isLimited = true end
        if card:isKindOf("SavageAssault") and sgs.card_lack[to:objectName()]["Slash"] == 1
            or card:isKindOf("ArcheryAttack") and sgs.card_lack[to:objectName()]["Jink"] == 1
            or sj_num < 1 or isLimited then
            value = -70
        else
            value = -50
        end
        value = value + math.min(20, to:getHp() * 5)

        if self:getDamagedEffects(to, from) then value = value + 40 end
        if self:needToLoseHp(to, from, nil, true) then value = value + 10 end

        if card:isKindOf("ArcheryAttack") then
            if self:hasEightDiagramEffect(to) then
                value = value + 20
                if self:getFinalRetrial(to) == 2 then
                    value = value - 15
                elseif self:getFinalRetrial(to) == 1 then
                    value = value + 10
                end
            end
        end

        if card:isKindOf("ArcheryAttack") and sj_num >= 1 then
        elseif card:isKindOf("SavageAssault") and sj_num >= 1 then
        end

            if self.room:getMode() ~= "06_3v3" and self.room:getMode() ~= "06_XMode" then
                if to:getHp() == 1 and isLord(from) and sgs.evaluatePlayerRole(to) == "loyalist" and self:getCardsNum("Peach") == 0 then
                    value = value - from:getCardCount() * 20
                end
            end

    else
        value = value + 10
    end

    return value
end

function getLord(player)
    if not player then global_room:writeToConsole(debug.traceback()) return end

    if sgs.GetConfig("EnableHegemony", false) then return nil end
    local room = global_room
    player = findPlayerByObjectName(room, player:objectName(), true)

    local mode = string.lower(room:getMode())
    if mode == "06_3v3" then
        if player:getRole() == "lord" or player:getRole() == "renegade" then return player end
        if player:getRole() == "loyalist" then return room:getLord() end
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:getRole() == "renegade" then return p end
        end
    end
    return room:getLord() or player
end

function isLord(player)
    return player and getLord(player) and getLord(player):objectName() == player:objectName()
end

function SmartAI:getAoeValue(card, player)
    local attacker = player or self.player
    local good, bad = 0, 0
    local lord = getLord(self.player)

    local canHelpLord = function()
        if not lord or self:isEnemy(lord, attacker) then return false end

        local peach_num, null_num, slash_num, jink_num = 0, 0, 0, 0
        if card:isVirtualCard() and card:subcardsLength() > 0 then
            for _, subcardid in sgs.qlist(card:getSubcards()) do
                local subcard = sgs.Sanguosha:getCard(subcardid)
                if isCard("Peach", subcard, attacker) then peach_num = peach_num - 1 end
                if isCard("Slash", subcard, attacker) then slash_num = slash_num - 1 end
                if isCard("Jink", subcard, attacker) then jink_num = jink_num - 1 end
                if isCard("Nullification", subcard, attacker) then null_num = null_num - 1 end
            end
        end

        if self:getCardsNum("Peach") > peach_num then return true end

        local goodnull, badnull = 0, 0
        for _, p in sgs.qlist(self.room:getAlivePlayers()) do
            if self:isFriend(lord, p) then
                goodnull = goodnull +  getCardsNum("Nullification", p, attacker)
            else
                badnull = badnull +  getCardsNum("Nullification", p, attacker)
            end
        end
        return goodnull - null_num - badnull >= 2
    end

    local isEffective_F, isEffective_E = 0, 0
    for _, friend in ipairs(self:getFriendsNoself(attacker)) do
        good = good + self:getAoeValueTo(card, friend, attacker)
        if self:aoeIsEffective(card, friend, attacker) then isEffective_F = isEffective_F + 1 end
    end

    for _, enemy in ipairs(self:getEnemies(attacker)) do
        bad = bad + self:getAoeValueTo(card, enemy, attacker)
        if self:aoeIsEffective(card, enemy, attacker) then isEffective_E = isEffective_E + 1 end
    end

    if isEffective_F == 0 and isEffective_E == 0 then
        return -100
    elseif isEffective_E == 0 then
        return -100
    end
    if not sgs.GetConfig("EnableHegemony", false) then
        if self.role ~= "lord" and sgs.isLordInDanger() and self:aoeIsEffective(card, lord, attacker) and not canHelpLord() and not hasBuquEffect(lord) then
            if self:isEnemy(lord) then
                good = good + (lord:getHp() == 1 and 200 or 150)
                if lord:getHp() <= 2 then
                    if #self.enemies == 1 then good = good + 150 - lord:getHp() * 50 end
                    if lord:isKongcheng() then good = good + 150 - lord:getHp() * 50 end
                end
            else
                bad = bad + (lord:getHp() == 1 and 2013 or 250)
            end
        end
    end

    local enemy_number = 0
    for _, player in sgs.qlist(self.room:getOtherPlayers(attacker)) do
        if self:cantbeHurt(player, attacker) and self:aoeIsEffective(card, player, attacker) then
                bad = bad + 250
        end

        if self:aoeIsEffective(card, player, attacker) and not self:isFriend(player, attacker) then enemy_number = enemy_number + 1 end
    end

    local forbid_start = true
    if not sgs.GetConfig("EnableHegemony", false) then
        if forbid_start and sgs.turncount < 2 and attacker:getSeat() <= 3 and card:isKindOf("SavageAssault") and enemy_number > 0 then
            if self.role ~= "rebel" then
                good = good + (isEffective_E > 0 and 50 or 0)
            else
                bad = bad + (isEffective_F > 0 and 50 or 0)
            end
        end
        if sgs.current_mode_players["rebel"] == 0 and attacker:getRole() ~= "lord" and sgs.current_mode_players["loyalist"] > 0 and self:isWeak(lord) then
            bad = bad + 300
        end
    end

    return good - bad
end

function SmartAI:hasTrickEffective(card, to, from)
    from = from or self.room:getCurrent()
    to = to or self.player
    if self.room:isProhibited(from, to, card) then return false end

    local nature = sgs.DamageStruct_Normal
    if card:isKindOf("FireAttack") then nature = sgs.DamageStruct_Fire end

    if (card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault")) then
        self.equipsToDec = sgs.getCardNumAtCertainPlace(card, from, sgs.Player_PlaceEquip)
        local eff = self:damageIsEffective(to, nature, from)
        self.equipsToDec = 0
        if not eff then return false end
    end

    return true
end

function SmartAI:useTrickCard(card, use)
    if not card then global_room:writeToConsole(debug.traceback()) return end
    if card:isKindOf("AOE") then
        local others = self.room:getOtherPlayers(self.player)
        others = sgs.QList2Table(others)
        local avail = #others
        local avail_friends = 0
        for _, other in ipairs(others) do
            if self.room:isProhibited(self.player, other, card) then
                avail = avail - 1
            elseif self:isFriend(other) then
                avail_friends = avail_friends + 1
            end
        end
        if avail < 1 then return end
		
        local mode = global_room:getMode()
        if mode:find("p") and mode >= "04p" then
            if self.player:isLord() and sgs.turncount < 2 and card:isKindOf("ArcheryAttack") and self:getOverflow() < 1
                and not self.player:hasFlag("AI_fangjian") then return end
            if self.role == "loyalist" and sgs.turncount < 2 and card:isKindOf("ArcheryAttack") then return end
            if self.role == "rebel" and sgs.turncount < 2 and card:isKindOf("SavageAssault") then return end
        end

        local good = self:getAoeValue(card)
        if self.player:hasFlag("AI_fangjian") and sgs.turncount < 2 then good = good + 300 end
        if good > 0 then
            use.card = card
        end
    else
        self:useCardByClassName(card, use)
    end
    if use.to then
        if not use.to:isEmpty() and sgs.dynamic_value.damage_card[card:getClassName()] then
            local nature = card:isKindOf("FireAttack") and sgs.DamageStruct_Fire or sgs.DamageStruct_Normal
            for _, target in sgs.qlist(use.to) do
                if self:damageIsEffective(target, nature) then return end
            end
            use.card = nil
        end
    end
end

sgs.weapon_range = {}

function SmartAI:hasEightDiagramEffect(player)
    player = player or self.player
    return player:hasArmorEffect("eight_diagram")
end

function SmartAI:hasCrossbowEffect(player)
    player = player or self.player
    return player:hasWeapon("crossbow")
end

sgs.ai_weapon_value = {}

function SmartAI:evaluateWeapon(card, player, target)
    player = player or self.player
    local deltaSelfThreat, inAttackRange = 0
    local currentRange
    local enemies = target and { target } or self:getEnemies(player)
    if not card then return -1
    else
        currentRange = sgs.weapon_range[card:getClassName()] or 0
    end
    for _, enemy in ipairs(enemies) do
        if player:distanceTo(enemy) <= currentRange then
            inAttackRange = true
            local def = sgs.getDefenseSlash(enemy, self) / 2
            if def < 0 then def = 6 - def
            elseif def <= 1 then def = 6
            else def = 6 / def
            end
            deltaSelfThreat = deltaSelfThreat + def
        end
    end

    local slash_num = player:objectName() == self.player:objectName() and self:getCardsNum("Slash") or getCardsNum("Slash", player, self.player)
    local analeptic_num = player:objectName() == self.player:objectName() and self:getCardsNum("Analeptic") or getCardsNum("Analeptic", player, self.player)
    local peach_num = player:objectName() == self.player:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", player, self.player)
    if card:isKindOf("Crossbow") and inAttackRange then
        deltaSelfThreat = deltaSelfThreat + slash_num * 3 - 2
        if player:getWeapon() and not self:hasCrossbowEffect(player) and not player:canSlashWithoutCrossbow() and slash_num > 0 then
            for _, enemy in ipairs(enemies) do
                if player:distanceTo(enemy) <= currentRange
                    and (sgs.card_lack[enemy:objectName()]["Jink"] == 1 or slash_num >= enemy:getHp()) then
                    deltaSelfThreat = deltaSelfThreat + 10
                end
            end
        end
    end
    local callback = sgs.ai_weapon_value[card:objectName()]
    if type(callback) == "function" then
        deltaSelfThreat = deltaSelfThreat + (callback(self, nil, player) or 0)
        for _, enemy in ipairs(enemies) do
            if player:distanceTo(enemy) <= currentRange and callback then
                local added = sgs.ai_slash_weaponfilter[card:objectName()]
                if type(added) == "function" and added(self, enemy, player) then deltaSelfThreat = deltaSelfThreat + 1 end
                deltaSelfThreat = deltaSelfThreat + (callback(self, enemy, player) or 0)
            end
        end
    end

    return deltaSelfThreat, inAttackRange
end

sgs.ai_armor_value = {}

function SmartAI:evaluateArmor(card, player)
    player = player or self.player
    local ecard = card or player:getArmor()
    if not ecard then return 0 end

    local value = 0
    for _, askill in sgs.qlist(player:getVisibleSkillList(true)) do
        local callback = sgs.ai_armor_value[askill:objectName()]
        if type(callback) == "function" then
            return value + (callback(ecard, player, self) or 0)
        end
    end
    local callback = sgs.ai_armor_value[ecard:objectName()]
    if type(callback) == "function" then
        return value + (callback(player, self) or 0)
    end
    return value + 0.5
end

function SmartAI:getSameEquip(card, player)
    player = player or self.player
    if not card then return end
    if card:isKindOf("Weapon") then return player:getWeapon()
    elseif card:isKindOf("Armor") then return player:getArmor()
    elseif card:isKindOf("DefensiveHorse") then return player:getDefensiveHorse()
    elseif card:isKindOf("OffensiveHorse") then return player:getOffensiveHorse()
    elseif card:isKindOf("Treasure") then return player:getTreasure()
    end
end

function SmartAI:useEquipCard(card, use)
    if not card then global_room:writeToConsole(debug.traceback()) return end
    if self.player:getHandcardNum() == 1 and self:needKongcheng() and self:evaluateArmor(card) > -5 then
        use.card = card
        return
    end
    local same = self:getSameEquip(card)
    local canUseSlash = self:getCardId("Slash") and self:slashIsAvailable(self.player)
    self:useCardByClassName(card, use)
    if use.card then return end
    if card:isKindOf("Weapon") then
        if not use.to and not self:needKongcheng() and not self:hasSkills(sgs.lose_equip_skill) and self:getOverflow() <= (canUseSlash and self.slashAvail or 0)
            and not canUseSlash and not card:isKindOf("Crossbow") and not card:isKindOf("VSCrossbow") then return end
        if not self:needKongcheng() and self.player:getHandcardNum() <= self.player:getHp() - 2 then return end
        if not self.player:getWeapon() or self:evaluateWeapon(card) > self:evaluateWeapon(self.player:getWeapon()) then
            use.card = card
        end
    elseif card:isKindOf("Armor") then
        local lion = self:getCard("SilverLion")
        if lion and self.player:isWounded() and not self.player:hasArmorEffect("silver_lion") and not card:isKindOf("SilverLion") then
            use.card = lion
            return
        end
        if self:evaluateArmor(card) > self:evaluateArmor() or isenemy_zzzh and self:getOverflow() > 0 then use.card = card end
        return
    elseif card:isKindOf("OffensiveHorse") then
            if not self:hasSkills(sgs.lose_equip_skill) and self:getOverflow() <= 0 and not (canUseSlash or self:getCardId("Snatch")) then
                return
            else
                if self.lua_ai:useCard(card) then
                    use.card = card
                    return
                end
            end
    elseif card:isKindOf("DefensiveHorse") then
    elseif card:isKindOf("Treasure") then
        if not card:isKindOf("WoodenOx") and not self.player:getTreasure()then
            for _, friend in ipairs(self.friends) do
                if (friend:getTreasure() and friend:getPile("wooden_ox"):length() > 1) then
                    return
                end
            end
        end
        if not self.player:getTreasure() then
            use.card = card
        end
    elseif self.lua_ai:useCard(card) then
        use.card = card
    end
end

function SmartAI:damageMinusHp(self, enemy, type)
        local trick_effectivenum = 0
        local slash_damagenum = 0
        local analepticpowerup = 0
        local effectivefireattacknum = 0
        local basicnum = 0
        local cards = self.player:getCards("he")
        cards = sgs.QList2Table(cards)
        for _, acard in ipairs(cards) do
            if acard:getTypeId() == sgs.Card_TypeBasic and not acard:isKindOf("Peach") then basicnum = basicnum + 1 end
        end
        for _, acard in ipairs(cards) do
            if ((acard:isKindOf("Duel") or acard:isKindOf("SavageAssault") or acard:isKindOf("ArcheryAttack") or acard:isKindOf("FireAttack"))
            and not self.room:isProhibited(self.player, enemy, acard))
            or ((acard:isKindOf("SavageAssault") or acard:isKindOf("ArcheryAttack")) and self:aoeIsEffective(acard, enemy)) then
                if acard:isKindOf("FireAttack") then
                    if not enemy:isKongcheng() then
                    effectivefireattacknum = effectivefireattacknum + 1
                    else
                    trick_effectivenum = trick_effectivenum -1
                    end
                end
                trick_effectivenum = trick_effectivenum + 1
            elseif acard:isKindOf("Slash") and self:slashIsEffective(acard, enemy) and (slash_damagenum == 0 or self:hasCrossbowEffect())
                and (self.player:distanceTo(enemy) <= self.player:getAttackRange()) then
                slash_damagenum = slash_damagenum + 1
                if self:getCardsNum("Analeptic") > 0 and analepticpowerup == 0
                    and not (enemy:hasArmorEffect("silver_lion") or self:hasEightDiagramEffect(enemy))
                    and not IgnoreArmor(self.player, enemy) then
                    slash_damagenum = slash_damagenum + 1
                    analepticpowerup = analepticpowerup + 1
                end
                if self.player:hasWeapon("guding_blade")
                    and (enemy:isKongcheng())
                    and not (enemy:hasArmorEffect("silver_lion") and not IgnoreArmor(self.player, enemy)) then
                    slash_damagenum = slash_damagenum + 1
                end
            end
        end
        if type == 0 then return (trick_effectivenum + slash_damagenum - effectivefireattacknum - enemy:getHp())
        else return (trick_effectivenum + slash_damagenum - enemy:getHp()) end
    return -10
end

function getBestHp(player)
    local arr = {}
    for skill,dec in pairs(arr) do
        if player:hasSkill(skill) then
            return math.max( (player:isLord() and 3 or 2) ,player:getMaxHp() - dec)
        end
    end
    return player:getMaxHp()
end

function SmartAI:needToLoseHp(to, from, isSlash, passive, recover)
    from = from or self.room:getCurrent()
    to = to or self.player
    if isSlash then
        if from:hasWeapon("ice_sword") and to:getCards("he"):length() > 1 and not self:isFriend(from, to) then
            return false
        end
    end
    if self:hasHeavySlashDamage(from, nil, to) then return false end
    local n = getBestHp(to)

    if recover then return to:getHp() >= n end
    return to:getHp() > n
end

function IgnoreArmor(from, to)
    if not from or not to then global_room:writeToConsole(debug.traceback()) return end
    if from:hasWeapon("qinggang_sword") or to:getMark("Armor_Nullified") > 0 then
        return true
    end
    return false
end

function SmartAI:needToThrowArmor(player)
    player = player or self.player
    if not player:getArmor() or not player:hasArmorEffect(player:getArmor():objectName()) then return false end
    if self:evaluateArmor(player:getArmor(), player) <= -2 then return true end
    if player:hasArmorEffect("silver_lion") and player:isWounded() then
        if self:isFriend(player) then
            if player:objectName() == self.player:objectName() then
                return true
            else
                return self:isWeak(player) and not player:hasSkills(sgs.use_lion_skill)
            end
        else
            return true
        end
    end
    local FS = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
    if player:hasArmorEffect("vine") and player:objectName() ~= self.player:objectName() and self:isEnemy(player)
        and self.player:getPhase() == sgs.Player_Play and self:slashIsAvailable() and not self:slashProhibit(FS, player, self.player) and not IgnoreArmor(self.player, player)
        and (self:getCard("FireSlash") or (self:getCard("Slash") and (self.player:hasWeapon("fan") or self:getCardsNum("fan") >= 1)))
        and (player:isKongcheng() or sgs.card_lack[player:objectName()]["Jink"] == 1 or getCardsNum("Jink", player, self.player) < 1) then
        return true
    end
    return false
end

function SmartAI:doNotDiscard(to, flags, conservative, n, cant_choose)
    if not to then global_room:writeToConsole(debug.traceback()) return end
    n = n or 1
    flags = flags or "he"
    if to:isNude() then return true end
    conservative = conservative or (sgs.turncount <= 2 and self.room:alivePlayerCount() > 2)
    local enemies = self:getEnemies(to)
	
    if cant_choose then
        if self:needKongcheng(to) and to:getHandcardNum() <= n then return true end
        if self:getLeastHandcardNum(to) <= n then return true end
        if self:hasSkills(sgs.lose_equip_skill, to) and to:hasEquip() then return true end
        if self:needToThrowArmor(to) then return true end
    else
        if flags == "h" or (flags == "he" and not to:hasEquip()) then
            if to:isKongcheng() or not self.player:canDiscard(to, "h") then return true end
            if not self:hasLoseHandcardEffective(to) then return true end
            if to:getHandcardNum() == 1 and self:needKongcheng(to) then return true end
        elseif flags == "e" or (flags == "he" and to:isKongcheng()) then
            if not to:hasEquip() then return true end
            if self:hasSkills(sgs.lose_equip_skill, to) then return true end
            if to:getCardCount(true) == 1 and self:needToThrowArmor(to) then return true end
        end
        if flags == "he" and n == 2 then
            if not self.player:canDiscard(to, "e") then return true end
            if to:getCardCount(true) < 2 then return true end
            if not to:hasEquip() then
                if not self:hasLoseHandcardEffective(to) then return true end
                if to:getHandcardNum() <= 2 and self:needKongcheng(to) then return true end
            end
            if self:hasSkills(sgs.lose_equip_skill, to) and to:getHandcardNum() < 2 then return true end
            if to:getCardCount(true) <= 2 and self:needToThrowArmor(to) then return true end
        end
    end
    if flags == "he" and n > 2 then
        if not self.player:canDiscard(to, "e") then return true end
        if to:getCardCount() < n then return true end
    end
    return false
end

function SmartAI:findPlayerToDiscard(flags, include_self, isDiscard, players, return_table)
    local player_table = {}
    if isDiscard == nil then isDiscard = true end
    local friends, enemies = {}, {}
    if not players then
        friends = include_self and self.friends or self.friends_noself
        enemies = self.enemies
    else
        for _, player in sgs.qlist(players) do
            if self:isFriend(player) and (include_self or player:objectName() ~= self.player:objectName()) then table.insert(friends, player)
            elseif self:isEnemy(player) then table.insert(enemies, player) end
        end
    end
    flags = flags or "he"

    self:sort(enemies, "defense")
    if flags:match("e") then
        for _, enemy in ipairs(enemies) do
            if self.player:canDiscard(enemy, "e") then
                local dangerous = self:getDangerousCard(enemy)
                if dangerous and (not isDiscard or self.player:canDiscard(enemy, dangerous)) then
                    table.insert(player_table, enemy)
                end
            end
        end
        for _, enemy in ipairs(enemies) do
            if enemy:hasArmorEffect("eight_diagram") and enemy:getArmor() and not self:needToThrowArmor(enemy) and self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId()) then
                table.insert(player_table, enemy)
            end
        end
    end

    if flags:match("j") then
        for _, friend in ipairs(friends) do
            if ((friend:containsTrick("indulgence")) or friend:containsTrick("supply_shortage"))
                and (not isDiscard or self.player:canDiscard(friend, "j")) then
                table.insert(player_table, friend)
            end
        end
        for _, friend in ipairs(friends) do
            if friend:containsTrick("lightning") and self:hasWizard(enemies, true) and (not isDiscard or self.player:canDiscard(friend, "j")) then table.insert(player_table, friend) end
        end
        for _, enemy in ipairs(enemies) do
            if enemy:containsTrick("lightning") and self:hasWizard(enemies, true) and (not isDiscard or self.player:canDiscard(enemy, "j")) then table.insert(player_table, enemy) end
        end
    end

    if flags:match("e") then
        for _, friend in ipairs(friends) do
            if self:needToThrowArmor(friend) and (not isDiscard or self.player:canDiscard(friend, friend:getArmor():getEffectiveId())) then
                table.insert(player_table, friend)
            end
        end
        for _, enemy in ipairs(enemies) do
            if self.player:canDiscard(enemy, "e") then
                local valuable = self:getValuableCard(enemy)
                if valuable and (not isDiscard or self.player:canDiscard(enemy, valuable)) then
                    table.insert(player_table, enemy)
                end
            end
        end
    end

    if flags:match("h") then
        for _, enemy in ipairs(enemies) do
            local cards = sgs.QList2Table(enemy:getHandcards())
            local flag = string.format("%s_%s_%s","visible", self.player:objectName(), enemy:objectName())
            if #cards <= 2 and not enemy:isKongcheng() then
                for _, cc in ipairs(cards) do
                    if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) and (not isDiscard or self.player:canDiscard(enemy, cc:getId())) then
                        table.insert(player_table, enemy)
                    end
                end
            end
        end
    end

    if flags:match("e") then
        for _, enemy in ipairs(enemies) do
            if enemy:hasEquip() and not self:doNotDiscard(enemy, "e") and (not isDiscard or self.player:canDiscard(enemy, "e")) then
                table.insert(player_table, enemy)
            end
        end
    end

    if flags:match("h") then
        self:sort(enemies, "handcard")
        for _, enemy in ipairs(enemies) do
            if (not isDiscard or self.player:canDiscard(enemy, "h")) and not self:doNotDiscard(enemy, "h") then
                table.insert(player_table, enemy)
            end
        end
    end

    if return_table then return player_table
    else
        if #player_table == 0 then return nil else return player_table[1] end
    end
end

function SmartAI:findPlayerToDraw(include_self, drawnum, count)
    drawnum = drawnum or 1
    local players = sgs.QList2Table(include_self and self.room:getAllPlayers() or self.room:getOtherPlayers(self.player))
    local friends = {}
    local player_list = sgs.SPlayerList()
    for _, player in ipairs(players) do
        if self:isFriend(player) then
            table.insert(friends, player)
        end
    end
    if #friends == 0 then return nil end

    self:sort(friends, "defense")
    for _, friend in ipairs(friends) do
        if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
            if count then
                if not player_list:contains(friend) then player_list:append(friend) end
                if count == player_list:length() then return sgs.QList2Table(player_list) end
            else return friend end
        end
    end

    local AssistTarget = self:AssistTarget()
    if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and (AssistTarget:getHandcardNum() < AssistTarget:getMaxCards() * 2 or AssistTarget:getHandcardNum() < self.player:getHandcardNum())then
        for _, friend in ipairs(friends) do
            if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) then
                if count then
                    if not player_list:contains(friend) then player_list:append(friend) end
                    if count == player_list:length() then return sgs.QList2Table(player_list) end
                else return friend end
            end
        end
    end

    for _, friend in ipairs(friends) do
        if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) then
            if count then
                if not player_list:contains(friend) then player_list:append(friend) end
                if count == player_list:length() then return sgs.QList2Table(player_list) end
            else return friend end
        end
    end

    self:sort(friends, "handcard")
    for _, friend in ipairs(friends) do
        if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
            if count then
                if not player_list:contains(friend)  then player_list:append(friend) end
                if count == player_list:length() then return sgs.QList2Table(player_list) end
            else return friend end
        end
    end
    if count then return sgs.QList2Table(player_list) end
    return nil
end

function SmartAI:findPlayerToDamage(damage, source, nature, targets, include_self, base_value, return_table)
    damage = damage or 1
    nature = nature or sgs.DamageStruct_Normal
    source = source or nil
    base_value = base_value or 0
    if include_self == nil then include_self = true    end
    
    local victims
    if targets then
        victims = targets
    else
        victims = include_self and self.room:getOtherPlayers(self.player) or self.room:getAlivePlayers()
    end
    if type(victims) ~= "table" then
        victims = sgs.QList2Table(victims)
    end
    if #victims == 0 then
        if return_table then
            return {}
        else
            return nil
        end
    end
    
    local isSourceFriend = ( source and self:isFriend(source) )
    local isSourceEnemy = ( source and self:isEnemy(source) )
    
    local function getDamageValue(target, self_only)
        local value = 0
        local isFriend = self:isFriend(target)
        local isEnemy = self:isEnemy(target)
        local careLord = ( self.role == "renegade" and target:isLord() and self.room:alivePlayerCount() > 2 )
        local count = damage
        if self:damageIsEffective(target, nature, source) then
            if nature == sgs.DamageStruct_Fire then
                if target:hasArmorEffect("vine") or target:hasArmorEffect("gale_shell") then
                    count = count + 1
                end
            end
            if count > 1 and target:hasArmorEffect("silver_lion") then
                count = 1
            end
        else
            count = 0
        end
        if count > 0 then
            value = value + count * 20 --设1牌价值为10，且1体力价值2牌，1回合价值2.5牌，下同
            local hp = target:getHp()
            local deathFlag = false
            if count >= hp then
                deathFlag = ( count >= hp + self:getAllPeachNum(target) )
            end
            if deathFlag then
                value = value + 500
            else
                if hp >= getBestHp(target) + count then
                    value = value - 2
                end
                if self:needToLoseHp(target, source) then
                    value = value - 5
                end
                if self:isWeak(target) then
                    value = value + 15
                else
                    value = value + 12 - sgs.getDefense(target)
                end
            end
            if isFriend then
                value = - value
            elseif not isEnemy then
                value = value / 2
            end
            if self_only or nature == sgs.DamageStruct_Normal then
            elseif target:isChained() then
                local others = self.room:getOtherPlayers(target)
                for _,p in sgs.qlist(others) do
                    if p:isChained() then
                        local v = values[p:objectName()] or getDamageValue(p, true)
                        value = value + v
                    end
                end
            end
            if self:cantbeHurt(target, source, count) then
                value = value - 800
            end
            if deathFlag and careLord then
                value = value - 1000
            end
        end
        return value
    end
    
    local values = {}
    for _,victim in ipairs(victims) do
        values[victim:objectName()] = getDamageValue(victim, false) or 0
    end
    
    local compare_func = function(a, b)
        local valueA = values[a:objectName()] or 0
        local valueB = values[b:objectName()] or 0
        return valueA >= valueB
    end
    
    table.sort(victims, compare_func)
    
    if return_table then
        local result = {}
        for _,victim in ipairs(victims) do
            if values[victim:objectName()] > base_value then
                table.insert(result, victim)
            end
        end
        return result
    end
    
    local victim = victims[1]
    local value = values[victim:objectName()] or 0
    if value > base_value then
        return victim
    end
    
    return nil
end

function SmartAI:dontRespondPeachInJudge(judge)
    if not judge or type(judge) ~= "userdata" then self.room:writeToConsole(debug.traceback()) return end
    local peach_num = self:getCardsNum("Peach")
    if peach_num == 0 then return false end
    if self:willSkipPlayPhase() and self:getCardsNum("Peach") > self:getOverflow(self.player, true) then return false end

    local card = self:getCard("Peach")
    local dummy_use = { isDummy = true }
    self:useBasicCard(card, dummy_use)
    if dummy_use.card then return true end

    if peach_num <= self.player:getLostHp() then return true end

    if peach_num > self.player:getLostHp() then
        for _, friend in ipairs(self.friends) do
            if self:isWeak(friend) then return true end
        end
    end

    if (judge.reason == "EightDiagram") and
        self:isFriend(judge.who) and (not self:isWeak(judge.who) or judge.who:hasSkills(sgs.masochism_skill)) then return true
    end

    return false
end

function CanUpdateIntention(player)
    if not player then global_room:writeToConsole(debug.traceback()) end
    local current_rebel_num, current_loyalist_num = 0, 0
    local rebel_num = sgs.current_mode_players["rebel"]

    for _, aplayer in sgs.qlist(global_room:getAlivePlayers()) do
        if sgs.ai_role[aplayer:objectName()] == "rebel" then current_rebel_num = current_rebel_num + 1 end
    end

    if sgs.ai_role[player:objectName()] == "rebel" and current_rebel_num >= rebel_num then return false
    elseif sgs.ai_role[player:objectName()] == "neutral" and current_rebel_num + 2 >= rebel_num then return false end

    return true
end

function SmartAI:AssistTarget()
    if sgs.ai_AssistTarget_off then return end
    local human_count, player = 0
    if not sgs.ai_AssistTarget then
        for _, p in sgs.qlist(self.room:getAlivePlayers()) do
            if p:getState() ~= "robot" then
                human_count = human_count + 1
                player = p
            end
        end
        if human_count == 1 and player then
            sgs.ai_AssistTarget = player
        else
            sgs.ai_AssistTarget_off = true
        end
    end
    player = sgs.ai_AssistTarget
    if player and player:isAlive() and self:isFriend(player) and player:objectName() ~= self.player:objectName() and self:getOverflow(player) > 1
        and self:getOverflow(player) < 3 then
        return player
    end
    return
end

function SmartAI:findFriendsByType(prompt, player)
    player = player or self.player
    local friends = self:getFriendsNoself(player)
    if #friends < 1 then return false end
    if prompt == sgs.Friend_Draw then
        for _, friend in ipairs(friends) do
            if not self:needKongcheng(friend, true) then return true end
        end
    elseif prompt == sgs.Friend_Male then
        for _, friend in ipairs(friends) do
            if friend:isMale() then return true end
        end
    elseif prompt == sgs.Friend_MaleWounded then
        for _, friend in ipairs(friends) do
            if friend:isMale() and friend:isWounded() then return true end
        end
    elseif prompt == sgs.Friend_All then
        return true
    elseif prompt == sgs.Friend_Weak then
        for _, friend in ipairs(friends) do
            if self:isWeak(friend) then return true end
        end
    else
        global_room:writeToConsole(debug.traceback())
        return
    end
    return false
end

function SmartAI:adjustAIRole()
    sgs.explicit_renegade = false
    for _, player in sgs.qlist(self.room:getAlivePlayers()) do
        if player:getRole() == "renegade" then sgs.explicit_renegade = true end
        if player:getRole() ~= "lord" then
            sgs.role_evaluation[player:objectName()]["loaylist"] = 0
            sgs.role_evaluation[player:objectName()]["renegade"] = 0
            local role = player:getRole()
            if role == "rebel" then
                sgs.role_evaluation[player:objectName()]["loaylist"] = -65535
            else
                sgs.role_evaluation[player:objectName()][role] = 65535
            end
            sgs.ai_role[player:objectName()] = role
        end
    end
end

dofile "lua/ai/debug-ai.lua"
dofile "lua/ai/guanxing-ai.lua"
dofile "lua/ai/compat-ai.lua"
dofile "lua/ai/standard_cards-ai.lua"
dofile "lua/ai/maneuvering-ai.lua"
dofile "lua/ai/ex_cards-ai.lua"
dofile "lua/ai/chat-ai.lua"

local loaded = "standard_cards|maneuvering"

local ai_files = sgs.GetFileNames("lua/ai")

for _, aextension in ipairs(sgs.Sanguosha:getExtensions()) do
    if not loaded:match(aextension) then
        for _, ai_file in ipairs(ai_files) do
            if string.lower(aextension) .. "-ai.lua" == string.lower(ai_file) then
                dofile("lua/ai/" .. string.lower(aextension) .. "-ai.lua")
                break
            end
        end
    end
end

dofile "lua/ai/basara-ai.lua"
dofile "lua/ai/special3v3-ai.lua"

for _, ascenario in ipairs(sgs.Sanguosha:getModScenarioNames()) do
    if not loaded:match(ascenario) then
        for _, ai_file in ipairs(ai_files) do
            if string.lower(ascenario) .. "-ai.lua" == string.lower(ai_file) then
                dofile("lua/ai/" .. string.lower(ascenario) .. "-ai.lua")
                break
            end
        end
    end
end

