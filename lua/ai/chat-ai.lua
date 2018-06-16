sgs.ai_chat = {}

function speak(to, type)
	if not sgs.GetConfig("AIChat", false) then return end
	if to:getState() ~= "robot" then return end
	if sgs.GetConfig("OriginAIDelay", 0) == 0 then return end

	if table.contains(sgs.ai_chat, type) then
		local i = math.random(1, #sgs.ai_chat[type])
		to:speak(sgs.ai_chat[type][i])
	end
end

function speakTrigger(card,from,to,event)
	if sgs.GetConfig("OriginAIDelay", 0) == 0 then return end
	if type(to) == "table" then
		for _, t in ipairs(to) do
			speakTrigger(card, from, t, event)
		end
		return
	end
	
	if not card then return end

	if card:isKindOf("Indulgence") and (to:getHandcardNum()>to:getHp()) then
		speak(to, "indulgence")
	elseif card:isKindOf("Peach") and math.random() < 0.1 then
		speak(to, "usepeach")
	end
end

sgs.ai_chat_func[sgs.SlashEffected].blindness=function(self, player, data)
	if player:getState() ~= "robot" then return end
	local effect= data:toSlashEffect()
	local chat ={
				"小内啊，您老悠着点儿",
				"尼玛你杀我，你真是夏侯惇啊",
				"盲狙一时爽啊, 我泪奔啊",
				"我次奥，哥们，盲狙能不能轻点？",
				"再杀我一下，老子和你拼命了"}
	if not effect.from then return end

	if self:hasCrossbowEffect(effect.from) then
		table.insert(chat, "杀得我也是醉了。。。")
		table.insert(chat, "果然是连弩降智商呀。")
		table.insert(chat, "杀死我也没牌拿，真2")
	end

	if effect.from:getMark("drank") > 0 then
		table.insert(chat, "喝醉了吧，乱砍人？")
	end

	if effect.from:isLord() then
		table.insert(chat, "尼玛眼瞎了，老子是忠啊")
		table.insert(chat, "主公别打我，我是忠")
		table.insert(chat, "再杀我，你会裸")
		table.insert(chat, "主公，别开枪，自己人")
	end

	local index =1+ (os.time() % #chat)

	if not effect.to:isLord() and effect.to:isAlive() and math.random() < 0.2 then
		effect.to:speak(chat[index])
	end
end

sgs.ai_chat_func[sgs.Death].stupid_lord=function(self, player, data)
	if player:getState() ~= "robot" then return end
	local damage=data:toDeath().damage
	local chat ={"2B了吧",
				"主要臣死，臣不得不死",
				"房主下盘T了这个主，拉黑不解释",
				"还有更2的吗",
				"真的很无语",
				}
	if damage and damage.from and damage.from:isLord() and self.role=="loyalist" and damage.to:objectName() == player:objectName() then
		local index =1+ (os.time() % #chat)
		damage.to:speak(chat[index])
	end
end

sgs.ai_chat_func[sgs.Dying].fuck_renegade=function(self, player, data)
	if player:getState() ~= "robot" then return end
	local dying = data:toDying()
	local chat ={"小内，你还不跳啊，要崩盘吧",
				"9啊，不9就输了",
				"999...999...",
				"小内，我死了，你也赢不了",
				"没戏了，小内不帮忙的话，我们全部托管吧",
				}
	if (self.role=="rebel" or self.role=="loyalist") and sgs.current_mode_players["renegade"]>0 and dying.who:objectName() == player:objectName() and math.random() < 0.5 then
		local index =1+ (os.time() % #chat)
		player:speak(chat[index])
	end
end

sgs.ai_chat_func[sgs.EventPhaseStart].beset=function(self, player, data)
	if player:getState() ~= "robot" then return end
	local chat ={
		"大家一起围观一下主公",
		"不要一下弄死了，慢慢来",
		"速度，一人一下，弄死",
		"主公，你投降吧，免受皮肉之苦啊，投降给全尸",
	}
	if player:getPhase()== sgs.Player_Start and self.role=="rebel" and sgs.current_mode_players["renegade"]==0
			and sgs.current_mode_players["loyalist"]==0  and sgs.current_mode_players["rebel"]>=2 and os.time() % 10 < 4 then
		local index =1+ (os.time() % #chat)
		player:speak(chat[index])
	end
end

sgs.ai_chat_func[sgs.CardUsed].blade = function(self, player, data)
	if player:getState() ~= "robot" then return end
	local use = data:toCardUse()
	if use.card:isKindOf("Blade") and use.from and use.from:objectName() == player:objectName() and math.random() < 0.1 then
		player:speak("这把刀就是我爷爷传下来的，上斩逗比，下斩傻逼！")
	end
end

sgs.ai_chat_func[sgs.CardFinished].yaoseng = function(self, player, data)
	if player:getState() ~= "robot" then return end
	local use = data:toCardUse()
	if use.card:isKindOf("OffensiveHorse") and use.from:objectName() == player:objectName() then
		for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
			if self:isEnemy(player, p) and player:distanceTo(p) == 1 and player:distanceTo(p, 1) == 2 and math.random() < 0.2 then
				player:speak("妖僧" .. p:screenName() .. "你往哪里跑")
				return
			end
		end
	end
end

sgs.ai_chat_func[sgs.TargetConfirmed].gounannv = function(self, player, data)
	if player:getState() ~= "robot" then return end
	local use = data:toCardUse()
	if use.card:isKindOf("Peach") then
		local to = use.to:first()
		if to:objectName() ~= use.from:objectName() and use.from:isFemale() and to:isMale() and math.random() < 0.1
			and to:getState() == "robot" and use.from:getState() == "robot" then
			use.from:speak("复活吧，我的勇士")
			to:speak("为你而战，我的女王")
		end
	end
end

sgs.ai_chat_func[sgs.CardFinished].analeptic = function(self, player, data)
	local use = data:toCardUse()
	if use.card:isKindOf("Analeptic") and use.card:getSkillName() ~= "zhendu" then
		local to = use.to:first()
		if to:getMark("drank") == 0 then return end
		local suit = { "spade", "heart", "club", "diamond" }
		suit = suit[math.random(1, #suit)]
		local chat = {
			"呵呵",
			"喜闻乐见",
			"前排围观，出售爆米花，矿泉水，花生，瓜子...",
			"不要砍我，我有" .. "<b><font color = 'yellow'>" .. sgs.Sanguosha:translate("jink")
				.. string.format("[<img src='image/system/log/%s.png' height = 12/>", suit) .. math.random(1, 10) .. "] </font></b>",
			"我菊花一紧"
		}
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:objectName() ~= to:objectName() and p:getState() == "robot" and not self:isFriend(p) and math.random() < 0.2 then
				if not p:isWounded() then
					table.insert(chat, "我满血，不慌")
				end
				p:speak(chat[math.random(1, #chat)])
				return
			end
		end
	end
end

function SmartAI:speak(cardtype, isFemale)
	if not sgs.GetConfig("AIChat", false) then return end
	if self.player:getState() ~= "robot" then return end
	if sgs.GetConfig("OriginAIDelay", 0) == 0 then return end

	if sgs.ai_chat[cardtype] then
		if type(sgs.ai_chat[cardtype]) == "function" then
			sgs.ai_chat[cardtype](self)
		elseif type(sgs.ai_chat[cardtype]) == "table" then
			if isFemale and sgs.ai_chat[cardtype .. "_female"] then cardtype = cardtype .. "_female" end
			local i = math.random(1, #sgs.ai_chat[cardtype])
			self.player:speak(sgs.ai_chat[cardtype][i])
		end
	end
end

sgs.ai_chat_func[sgs.EventPhaseStart].role = function(self, player, data)
	if sgs.isRolePredictable() then return end
	if sgs.GetConfig("EnableHegemony", false) then return end
	local name
	local friend_name
	local enemy_name
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) and p:objectName() ~= self.player:objectName() and math.random() < 0.5 then
			friend_name = sgs.Sanguosha:translate(p:getGeneralName())
		elseif self:isEnemy(p) and math.random() < 0.5 then
			enemy_name = sgs.Sanguosha:translate(p:getGeneralName())
		end
	end
	local chat = {}
	local chat1= {
		"你们要记住：该跳就跳，不要装身份",
		"到底谁是内啊？",
		}
	local quick = {
		"都快点，打完这局我要去吃饭",
		"都快点，打完这局我要去取快递",
		"都快点，打完这局我要去做面膜",
		"都快点，打完这局我要去洗衣服",
		"都快点，打完这局我要去跪搓衣板",
		"都快点，打完这局我要去上班了",
		"都快点，打完这局我要去睡觉了",
		"都快点，打完这局我要去尿尿",
		"都快点，打完这局我要去撸啊撸",
		"都快点，打完这局我要去跳广场舞",
		}
	local role1 = {
		"孰忠孰反，其实我早就看出来了",
		"五个反，怎么打！"
	}
	local role2 = {
		"我觉得当忠臣，个人能力要强",
		"装个忠我容易嘛我",
		"这主坑内，投降算了"
	}
	local role3 = {
		"反贼都集火啊！集火！",
		"我们根本没有输出",
		"对这种阵容，我已经没有赢的希望了"
		}
	if friend_name then
		table.insert(role1, "忠臣"..friend_name.."，你是在坑我吗？")
	end
	if enemy_name then
		table.insert(chat1, "游戏可以输，"..enemy_name.."必须死！")
		table.insert(chat1, enemy_name.."你这样坑队友，连我都看不下去了")
	end
	if player:getPhase() == sgs.Player_RoundStart then
		if player:getState() == "robot" and math.random() < 0.2 then
			if math.random() < 0.2 then
				table.insert(chat, quick[math.random(1, #quick)])
			end
			if math.random() < 0.3 then
				table.insert(chat, chat1[math.random(1, #chat1)])
			end
			if player:isLord() then
				table.insert(chat, role1[math.random(1, #role1)])
			elseif player:getRole() == "loyalist" or player:getRole() == "renegade" and math.random() < 0.2 then
				table.insert(chat, role2[math.random(1, #role2)])
			elseif player:getRole() == "rebel" or player:getRole() == "renegade" and math.random() < 0.2 then
				table.insert(chat, role3[math.random(1, #role3)])
			end
			if #chat ~= 0 and sgs.turncount >= 2 then
				player:speak(chat[math.random(1, #chat)])
			end
		end
	end
end

sgs.ai_chat_func[sgs.EventPhaseStart].jieyin = function(self, player, data)
	if player:getPhase() == sgs.Player_Play then
		local chat = {
			"香香睡我",
		}
		local chat1 = {
			"牌不够啊",
		}
		if self.player:hasSkill("jieyin") then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:objectName() ~= player:objectName() and p:getState() == "robot" 
				and self:isFriend(p) and p:isMale() and self:isWeak(p) then
					p:speak(chat[math.random(1, #chat)])
				elseif p:objectName() == player:objectName() and p:getState() == "robot" and math.random() < 0.1 then
					p:speak(chat1[math.random(1, #chat1)])
				end
			end
		end
	end
end

sgs.ai_chat={}

sgs.ai_chat.Snatch_female = {
"啧啧啧，来帮你解决点手牌吧",
"叫你欺负人!" ,
"手牌什么的最讨厌了"
}

sgs.ai_chat.Snatch = {
"yoooo少年，不来一发么",
"果然还是看你不爽",
"我看你霸气外露，不可不防啊"
}

sgs.ai_chat.Dismantlement_female = sgs.ai_chat.Snatch_female

sgs.ai_chat.Dismantlement = sgs.ai_chat.Snatch

sgs.ai_chat.respond_hostile={
"擦，小心菊花不保",
"内牛满面了", "哎哟我去"
}

sgs.ai_chat.friendly=
{ "。。。" }

sgs.ai_chat.respond_friendly=
{ "谢了。。。" }

sgs.ai_chat.duel_female=
{
"哼哼哼，怕了吧"
}

sgs.ai_chat.duel=
{
"来吧！像男人一样决斗吧！"
}

sgs.ai_chat.lucky=
{
"哎哟运气好",
"哈哈哈哈哈"
}

sgs.ai_chat.collateral_female=
{
"别以为这样就算赢了！"
}

sgs.ai_chat.collateral=
{
"你妹啊，我的刀！"
}

--huanggai
sgs.ai_chat.kurou=
{
"有桃么!有桃么？",
"教练，我想要摸桃",
"桃桃桃我的桃呢",
"求桃求连弩各种求"
}

--indulgence
sgs.ai_chat.indulgence=
{
"乐，乐你妹啊乐",
"擦，乐我",
"诶诶诶被乐了！"
}

sgs.ai_chat.bianshi = {
	"据我观察现在可以鞭尸",
	"鞭他，最后一下留给我",
	"这个可以鞭尸",
	"我要刷战功，这个人头是我的"
}

sgs.ai_chat.bianshi_female = {
	"对面是个美女你们慢点",
	"美人，来香一个",
	"人人有份，永不落空"
}

sgs.ai_chat.usepeach = {
"不好，这桃里有屎"
}
