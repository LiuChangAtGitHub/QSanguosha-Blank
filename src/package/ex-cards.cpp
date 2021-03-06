#include "ex-cards.h"
#include "util.h"
#include "settings.h"
#include "wrapped-card.h"
#include "engine.h"
#include "clientplayer.h"
#include "roomthread.h"
#include "room.h"
#include "maneuvering.h"

class SPMoonSpearSkill : public WeaponSkill
{
public:
    SPMoonSpearSkill() : WeaponSkill("sp_moonspear")
    {
        events << CardUsed << CardResponded;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::NotActive)
            return false;

        const Card *card = NULL;
        if (triggerEvent == CardUsed) {
            CardUseStruct card_use = data.value<CardUseStruct>();
            card = card_use.card;
        } else if (triggerEvent == CardResponded) {
            card = data.value<CardResponseStruct>().m_card;
        }

        if (card == NULL || !card->isBlack()
            || (card->getHandlingMethod() != Card::MethodUse && card->getHandlingMethod() != Card::MethodResponse))
            return false;

        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *tmp, room->getAlivePlayers()) {
            if (player->inMyAttackRange(tmp))
                targets << tmp;
        }
        if (targets.isEmpty()) return false;

        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@sp_moonspear", true, true);
        if (!target) return false;
        room->setEmotion(player, "weapon/moonspear");
        if (!room->askForCard(target, "jink", "@moon-spear-jink", QVariant(), Card::MethodResponse, player))
            room->damage(DamageStruct(objectName(), player, target));
        return false;
    }
};

SPMoonSpear::SPMoonSpear(Suit suit, int number)
    : Weapon(suit, number, 3)
{
    setObjectName("sp_moonspear");
}

SPCardPackage::SPCardPackage()
    : Package("sp_cards")
{
    (new SPMoonSpear)->setParent(this);
    skills << new SPMoonSpearSkill;

    type = CardPack;
}

ADD_PACKAGE(SPCard)

class MoonSpearSkill : public WeaponSkill
{
public:
    MoonSpearSkill() : WeaponSkill("moon_spear")
    {
        events << CardUsed << CardResponded;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::NotActive)
            return false;

        const Card *card = NULL;
        if (triggerEvent == CardUsed) {
            CardUseStruct card_use = data.value<CardUseStruct>();
            card = card_use.card;
        } else if (triggerEvent == CardResponded) {
            card = data.value<CardResponseStruct>().m_card;
        }

        if (card == NULL || !card->isBlack()
            || (card->getHandlingMethod() != Card::MethodUse && card->getHandlingMethod() != Card::MethodResponse))
            return false;

        player->setFlags("MoonspearUse");
        if (!room->askForUseCard(player, "slash", "@moon-spear-slash", -1, Card::MethodUse, false))
            player->setFlags("-MoonspearUse");

        return false;
    }
};

MoonSpear::MoonSpear(Suit suit, int number)
    : Weapon(suit, number, 3)
{
    setObjectName("moon_spear");
}

NosRendeCard::NosRendeCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void NosRendeCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.first();

    QDateTime dtbefore = source->tag.value("nosrende", QDateTime(QDate::currentDate(), QTime(0, 0, 0))).toDateTime();
    QDateTime dtafter = QDateTime::currentDateTime();

    if (dtbefore.secsTo(dtafter) > 3 * Config.AIDelay / 1000)
        room->broadcastSkillInvoke("rende");

    source->tag["nosrende"] = QDateTime::currentDateTime();

    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), target->objectName(), "nosrende", QString());
    room->obtainCard(target, this, reason, false);

    int old_value = source->getMark("nosrende");
    int new_value = old_value + subcards.length();
    room->setPlayerMark(source, "nosrende", new_value);

    if (old_value < 2 && new_value >= 2)
        room->recover(source, RecoverStruct(source));
}

NostalgiaPackage::NostalgiaPackage()
    : Package("nostalgia")
{
    type = CardPack;

    Card *moon_spear = new MoonSpear;
    moon_spear->setParent(this);

    skills << new MoonSpearSkill;

    addMetaObject<NosRendeCard>();
}

ADD_PACKAGE(Nostalgia)

VSCrossbow::VSCrossbow(Suit suit, int number)
    : Crossbow(suit, number)
{
    setObjectName("vscrossbow");
}

bool VSCrossbow::match(const QString &pattern) const
{
    QStringList patterns = pattern.split("+");
    if (patterns.contains("crossbow"))
        return true;
    else
        return Crossbow::match(pattern);
}

New3v3CardPackage::New3v3CardPackage()
    : Package("New3v3Card")
{
    QList<Card *> cards;
    cards << new SupplyShortage(Card::Spade, 1)
        << new SupplyShortage(Card::Club, 12)
        << new Nullification(Card::Heart, 12);

    foreach(Card *card, cards)
        card->setParent(this);

    type = CardPack;
}

ADD_PACKAGE(New3v3Card)

New3v3_2013CardPackage::New3v3_2013CardPackage()
: Package("New3v3_2013Card")
{
    QList<Card *> cards;
    cards << new VSCrossbow(Card::Club)
        << new VSCrossbow(Card::Diamond);

    foreach(Card *card, cards)
        card->setParent(this);

    type = CardPack;
}

ADD_PACKAGE(New3v3_2013Card)

Drowning::Drowning(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("drowning");
}

bool Drowning::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
    return targets.length() < total_num && to_select != Self;
}

void Drowning::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    if (!effect.to->getEquips().isEmpty()
        && room->askForChoice(effect.to, objectName(), "throw+damage", QVariant::fromValue(effect)) == "throw")
        effect.to->throwAllEquips();
    else
        room->damage(DamageStruct(this, effect.from->isAlive() ? effect.from : NULL, effect.to));
}

New1v1CardPackage::New1v1CardPackage()
: Package("New1v1Card")
{
    QList<Card *> cards;
    cards << new Duel(Card::Spade, 1)
        << new EightDiagram(Card::Spade, 2)
        << new Dismantlement(Card::Spade, 3)
        << new Snatch(Card::Spade, 4)
        << new Slash(Card::Spade, 5)
        << new QinggangSword(Card::Spade, 6)
        << new Slash(Card::Spade, 7)
        << new Slash(Card::Spade, 8)
        << new IceSword(Card::Spade, 9)
        << new Slash(Card::Spade, 10)
        << new Snatch(Card::Spade, 11)
        << new Spear(Card::Spade, 12)
        << new SavageAssault(Card::Spade, 13);

    cards << new ArcheryAttack(Card::Heart, 1)
        << new Jink(Card::Heart, 2)
        << new Peach(Card::Heart, 3)
        << new Peach(Card::Heart, 4)
        << new Jink(Card::Heart, 5)
        << new Indulgence(Card::Heart, 6)
        << new ExNihilo(Card::Heart, 7)
        << new ExNihilo(Card::Heart, 8)
        << new Peach(Card::Heart, 9)
        << new Slash(Card::Heart, 10)
        << new Slash(Card::Heart, 11)
        << new Dismantlement(Card::Heart, 12)
        << new Nullification(Card::Heart, 13);

    cards << new Duel(Card::Club, 1)
        << new RenwangShield(Card::Club, 2)
        << new Dismantlement(Card::Club, 3)
        << new Slash(Card::Club, 4)
        << new Slash(Card::Club, 5)
        << new Slash(Card::Club, 6)
        << new Drowning(Card::Club, 7)
        << new Slash(Card::Club, 8)
        << new Slash(Card::Club, 9)
        << new Slash(Card::Club, 10)
        << new Slash(Card::Club, 11)
        << new SupplyShortage(Card::Club, 12)
        << new Nullification(Card::Club, 13);

    cards << new Crossbow(Card::Diamond, 1)
        << new Jink(Card::Diamond, 2)
        << new Jink(Card::Diamond, 3)
        << new Snatch(Card::Diamond, 4)
        << new Axe(Card::Diamond, 5)
        << new Slash(Card::Diamond, 6)
        << new Jink(Card::Diamond, 7)
        << new Jink(Card::Diamond, 8)
        << new Slash(Card::Diamond, 9)
        << new Jink(Card::Diamond, 10)
        << new Jink(Card::Diamond, 11)
        << new Peach(Card::Diamond, 12)
        << new Slash(Card::Diamond, 13);

    foreach(Card *card, cards)
        card->setParent(this);

    type = CardPack;
}

ADD_PACKAGE(New1v1Card)

class YitianSwordSkill : public WeaponSkill
{
public:
    YitianSwordSkill() :WeaponSkill("yitian_sword")
    {
        events << DamageComplete << CardsMoveOneTime;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == DamageComplete) {
            if (WeaponSkill::triggerable(player) && player->getPhase() == Player::NotActive) {
                room->askForUseCard(player, "slash", "@YitianSword-slash");
            }
        } else {
            if (player->hasFlag("YitianSwordDamage")) {
                CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
                if (move.from != player || !move.from_places.contains(Player::PlaceEquip))
                    return false;
                for (int i = 0; i < move.card_ids.size(); i++) {
                    if (move.from_places[i] != Player::PlaceEquip) continue;
                    const Card *card = Sanguosha->getEngineCard(move.card_ids[i]);
                    if (card->objectName() == objectName()) {
                        player->setFlags("-YitianSwordDamage");
                        ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), "yitian_sword", "@YitianSword-lost", true, true);
                        if (target != NULL)
                            room->damage(DamageStruct("yitian_sword", player, target));
                        return false;
                    }
                }
            }
        }
        return false;
    }
};

YitianSword::YitianSword(Suit suit, int number)
    :Weapon(suit, number, 2)
{
    setObjectName("yitian_sword");
}

void YitianSword::onUninstall(ServerPlayer *player) const
{
    if (player->isAlive() && player->getMark("Equips_Nullified_to_Yourself") == 0 && player->hasWeapon(objectName()))
        player->setFlags("YitianSwordDamage");
}

YitianCardPackage::YitianCardPackage()
    :Package("yitian_cards")
{
    (new YitianSword)->setParent(this);

    type = CardPack;

    skills << new YitianSwordSkill;
}

ADD_PACKAGE(YitianCard)

Shit::Shit(Suit suit, int number)
    :BasicCard(suit, number)
{
    setObjectName("shit");

    target_fixed = true;
}

QString Shit::getSubtype() const{
    return "disgusting_card";
}

bool Shit::HasShit(const Card *card) {
    if (card->isVirtualCard()) {
        QList<int> card_ids = card->getSubcards();
        foreach(int card_id, card_ids) {
            const Card *c = Sanguosha->getCard(card_id);
            if(c->objectName() == "shit")
                return true;
        }
        return false;
    }
    return card->objectName() == "shit";
}

class ShitEffect : public TriggerSkill
{
public:
    ShitEffect() : TriggerSkill("shit_effect") {
        events << CardsMoveOneTime;
        frequency = Compulsory;
        global = true;
    }

    bool trigger(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const {

        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from)
            return false;
        if (move.from->objectName() != player->objectName())
            return false;
        if (move.to_place == Player::PlaceTable || move.to_place == Player::DiscardPile) {

            QList<Card *> shits;
            for (int index = 0; index < move.card_ids.length(); index++) {
                Card *shit = Sanguosha->getCard(move.card_ids.at(index));
                if (shit->isKindOf("Shit")) {
                    if (move.from_places.at(index) == Player::PlaceHand)
                        shits.append(shit);
                }
            }
            if (shits.isEmpty())
                return false;

            foreach(Card *shit, shits) {
                LogMessage log;
                log.card_str = shit->toString();
                log.from = player;

                switch (shit->getSuit()) {

                case Card::Spade:
                    log.type = "$ShitLostHp";
                    room->sendLog(log);
                    room->loseHp(player);
                    break;

                case Card::Heart:
                    log.type = "$ShitDamage";
                    room->sendLog(log);
                    room->damage(DamageStruct(shit, player, player, 1, DamageStruct::Fire));
                    break;

                case Card::Club:
                    log.type = "$ShitDamage";
                    room->sendLog(log);
                    room->damage(DamageStruct(shit, player, player, 1, DamageStruct::Thunder));
                    break;

                case Card::Diamond:
                    log.type = "$ShitDamage";
                    room->sendLog(log);
                    room->damage(DamageStruct(shit, player, player));
                    break;
                }

                if (player->isDead())
                    break;
            }
        }
        return false;
    }

    bool triggerable(Player *target) const {
        if (target)
            return target->getPhase() != Player::NotActive;
        return false;
    }

    int getPriority() const {
        return 1;
    }
};

// -----------  Deluge -----------------

Deluge::Deluge(Card::Suit suit, int number)
    :Disaster(suit, number)
{
    setObjectName("deluge");

    judge.pattern = ".|.|1,13";
    judge.good = false;
    judge.reason = objectName();
}

void Deluge::takeEffect(ServerPlayer *target) const
{
    QList<const Card *> cards = target->getCards("he");

    Room *room = target->getRoom();
    int n = qMin(cards.length(), target->aliveCount());
    if (n == 0)
        return;

    qShuffle(cards);
    cards = cards.mid(0, n);

    QList<int> card_ids;
    foreach (const Card *card, cards) {
        card_ids << card->getEffectiveId();
        room->throwCard(card, NULL);
    }

    room->fillAG(card_ids);

    QList<ServerPlayer *> players = room->getAllPlayers();
    players.removeAll(target);
    players << target;
    players = players.mid(0, n);
    foreach (ServerPlayer *player, players) {
        if (player->isAlive()) {
            int card_id = room->askForAG(player, card_ids, false, "deluge");
            card_ids.removeOne(card_id);

            room->takeAG(player, card_id, false);

            room->moveCardTo(Sanguosha->getCard(card_id), player, Player::PlaceHand, true);
        }
    }

    foreach(int card_id, card_ids)
        room->takeAG(NULL, card_id, false);

    room->clearAG();
}

// -----------  Typhoon -----------------

Typhoon::Typhoon(Card::Suit suit, int number)
    :Disaster(suit, number)
{
    setObjectName("typhoon");

    judge.pattern = ".|diamond|2~9";
    judge.good = false;
    judge.reason = objectName();
}

void Typhoon::takeEffect(ServerPlayer *target) const
{
    Room *room = target->getRoom();
    QList<ServerPlayer *> players = room->getAllPlayers();
    foreach (ServerPlayer *player, players) {
        if (target->distanceTo(player) == 1) {
            int discard_num = qMin(6, player->getHandcardNum());
            if (discard_num != 0) {
                room->askForDiscard(player, objectName(), discard_num, discard_num);
            }

            room->getThread()->delay();
        }
    }
}

// -----------  Earthquake -----------------

Earthquake::Earthquake(Card::Suit suit, int number)
    :Disaster(suit, number)
{
    setObjectName("earthquake");

    judge.pattern = ".|club|2~9";
    judge.good = false;
    judge.reason = objectName();
}

void Earthquake::takeEffect(ServerPlayer *target) const
{
    Room *room = target->getRoom();
    QList<ServerPlayer *> players = room->getAllPlayers();
    foreach (ServerPlayer *player, players) {
        bool plus1Horse = (player->getOffensiveHorse() != NULL);
        int distance = 2 - target->distanceTo(player, plus1Horse ? -1 : 0); // ignore plus 1 horse
        if (distance <= 1) {
            if (!player->getEquips().isEmpty())
                player->throwAllEquips();

            room->getThread()->delay();
        }
    }
}

// -----------  Volcano -----------------

Volcano::Volcano(Card::Suit suit, int number)
    :Disaster(suit, number)
{
    setObjectName("volcano");

    judge.pattern = ".|heart|2~9";
    judge.good = false;
    judge.reason = objectName();
}

void Volcano::takeEffect(ServerPlayer *target) const
{
    Room *room = target->getRoom();

    DamageStruct damage;
    damage.card = this;
    damage.damage = 2;
    damage.to = target;
    damage.nature = DamageStruct::Fire;
    room->damage(damage);

    QList<ServerPlayer *> players = room->getAllPlayers();
    players.removeAll(target);

    foreach (ServerPlayer *player, players) {
        bool plus1Horse = (player->getOffensiveHorse() != NULL);
        int distance = target->distanceTo(player, plus1Horse ? -1 : 0); // ignore plus 1 horse
        if (distance == 1) {
            DamageStruct damage;
            damage.card = this;
            damage.damage = 1;
            damage.to = player;
            damage.nature = DamageStruct::Fire;
            room->damage(damage);
        }
    }
}

// -----------  MudSlide -----------------
MudSlide::MudSlide(Card::Suit suit, int number)
    :Disaster(suit, number)
{
    setObjectName("mudslide");

    judge.pattern = ".|black|1,13,4,7";
    judge.good = false;
    judge.reason = objectName();
}

void MudSlide::takeEffect(ServerPlayer *target) const
{
    Room *room = target->getRoom();
    QList<ServerPlayer *> players = room->getAllPlayers();
    int to_destroy = 4;
    foreach (ServerPlayer *player, players) {
        QList<const Card *> equips = player->getEquips();
        if (equips.isEmpty()) {
            DamageStruct damage;
            damage.card = this;
            damage.to = player;
            room->damage(damage);
        } else {
            int n = qMin(equips.length(), to_destroy);
            for (int i = 0; i < n; i++) {
                CardMoveReason reason(CardMoveReason::S_REASON_DISCARD, QString(), QString(), "mudslide");
                room->throwCard(equips.at(i), reason, player);
            }

            to_destroy -= n;
            if (to_destroy == 0)
                break;
        }
    }
}

class GrabPeach : public TriggerSkill
{
public:
    GrabPeach() :TriggerSkill("grab_peach")
    {
        events << CardUsed;
        global = true;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room* room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Peach")) {
            QList<ServerPlayer *> players = room->getOtherPlayers(player);

            foreach (ServerPlayer *p, players) {
                if (p->getOffensiveHorse() != NULL && p->getOffensiveHorse()->isKindOf("Monkey") && p->getMark("Equips_Nullified_to_Yourself") == 0 &&
                    p->askForSkillInvoke("grab_peach", data)) {
                    room->throwCard(p->getOffensiveHorse(), p);
                    p->obtainCard(use.card);

                    use.to.clear();
                    data = QVariant::fromValue(use);
                }
            }
        }

        return false;
    }
};

Monkey::Monkey(Card::Suit suit, int number)
    :OffensiveHorse(suit, number)
{
    setObjectName("monkey");
}


class GaleShellSkill : public ArmorSkill
{
public:
    GaleShellSkill() :ArmorSkill("gale_shell")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.nature == DamageStruct::Fire) {
            LogMessage log;
            log.type = "#GaleShellDamage";
            log.from = player;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);

            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

GaleShell::GaleShell(Suit suit, int number) :Armor(suit, number)
{
    setObjectName("gale_shell");

    target_fixed = false;
}

bool GaleShell::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->distanceTo(to_select) <= 1;
}

/*
1.rende
2.jizhi
3.jieyin
4.guose
5.kurou
*/

RendeCard::RendeCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    mute = true;
}

void RendeCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{

    if (!source->tag.value("rende_using", false).toBool())
        room->broadcastSkillInvoke("rende");

    ServerPlayer *target = targets.first();

    int old_value = source->getMark("rende");
    QList<int> rende_list;
    if (old_value > 0)
        rende_list = StringList2IntList(source->property("rende").toString().split("+"));
    else
        rende_list = source->handCards();
    foreach(int id, this->subcards)
        rende_list.removeOne(id);
    room->setPlayerProperty(source, "rende", IntList2StringList(rende_list).join("+"));

    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), target->objectName(), "rende", QString());
    room->obtainCard(target, this, reason, false);

    int new_value = old_value + subcards.length();
    room->setPlayerMark(source, "rende", new_value);

    if (old_value < 2 && new_value >= 2)
        room->recover(source, RecoverStruct(source));

    if (source->isKongcheng() || source->isDead() || rende_list.isEmpty()) return;
    room->addPlayerHistory(source, "RendeCard", -1);

    source->tag["rende_using"] = true;

    if (!room->askForUseCard(source, "@@rende", "@rende-give", -1, Card::MethodNone))
        room->addPlayerHistory(source, "RendeCard");

    source->tag["rende_using"] = false;
}

JieyinCard::JieyinCard()
{
}

bool JieyinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty())
        return false;

    return to_select->isMale() && to_select->isWounded() && to_select != Self;
}

void JieyinCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    RecoverStruct recover(effect.from);
    room->recover(effect.from, recover, true);
    room->recover(effect.to, recover, true);
}

GuoseCard::GuoseCard()
{
    handling_method = Card::MethodNone;
}

bool GuoseCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty()) return false;
    int id = getEffectiveId();

    Indulgence *indulgence = new Indulgence(getSuit(), getNumber());
    indulgence->addSubcard(id);
    indulgence->setSkillName("guose");
    indulgence->deleteLater();

    bool canUse = !Self->isLocked(indulgence);
    if (canUse && to_select != Self && !to_select->containsTrick("indulgence") && !Self->isProhibited(to_select, indulgence))
        return true;
    bool canDiscard = false;
    foreach (const Card *card, (Self->getHandcards() + Self->getEquips())) {
        if (card->getEffectiveId() == id && !Self->isJilei(Sanguosha->getCard(id))) {
            canDiscard = true;
            break;
        }
    }
    if (!canDiscard || !to_select->containsTrick("indulgence"))
        return false;
    foreach (const Card *card, to_select->getJudgingArea()) {
        if (card->isKindOf("Indulgence") && Self->canDiscard(to_select, card->getEffectiveId()))
            return true;
    }
    return false;
}

const Card *GuoseCard::validate(CardUseStruct &cardUse) const
{
    ServerPlayer *to = cardUse.to.first();
    if (!to->containsTrick("indulgence")) {
        Indulgence *indulgence = new Indulgence(getSuit(), getNumber());
        indulgence->addSubcard(getEffectiveId());
        indulgence->setSkillName("guose");
        return indulgence;
    }
    return this;
}

void GuoseCard::onUse(Room *room, const CardUseStruct &use) const
{
    CardUseStruct card_use = use;

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();
    thread->trigger(PreCardUsed, room, card_use.from, data);
    card_use = data.value<CardUseStruct>();

    LogMessage log;
    log.from = card_use.from;
    log.to = card_use.to;
    log.type = "#UseCard";
    log.card_str = card_use.card->toString();
    room->sendLog(log);

    CardMoveReason reason(CardMoveReason::S_REASON_THROW, card_use.from->objectName(), QString(), "guose", QString());
    room->moveCardTo(this, card_use.from, NULL, Player::DiscardPile, reason, true);

    thread->trigger(CardUsed, room, card_use.from, data);
    card_use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, card_use.from, data);
}

void GuoseCard::onEffect(const CardEffectStruct &effect) const
{
    foreach (const Card *judge, effect.to->getJudgingArea()) {
        if (judge->isKindOf("Indulgence") && effect.from->canDiscard(effect.to, judge->getEffectiveId())) {
            effect.from->getRoom()->throwCard(judge, NULL, effect.from);
            effect.from->drawCards(1, "guose");
            return;
        }
    }
}

KurouCard::KurouCard()
{
    target_fixed = true;
}

void KurouCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->loseHp(source);
}

class Jizhi : public TriggerSkill
{
public:
    Jizhi() : TriggerSkill("jizhi")
    {
        frequency = Frequent;
        events << CardUsed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *yueying, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();

        if (use.card->getTypeId() == Card::TypeTrick
            && (yueying->getMark("JilveEvent") > 0 || room->askForSkillInvoke(yueying, objectName()))) {
            if (yueying->getMark("JilveEvent") > 0)
                room->broadcastSkillInvoke("jilve", 5);
            else
                room->broadcastSkillInvoke(objectName());

            QList<int> ids = room->getNCards(1, false);
            CardsMoveStruct move(ids, yueying, Player::PlaceTable,
                CardMoveReason(CardMoveReason::S_REASON_TURNOVER, yueying->objectName(), "jizhi", QString()));
            room->moveCardsAtomic(move, true);

            int id = ids.first();
            const Card *card = Sanguosha->getCard(id);
            if (!card->isKindOf("BasicCard")) {
                CardMoveReason reason(CardMoveReason::S_REASON_DRAW, yueying->objectName(), "jizhi", QString());
                room->obtainCard(yueying, card, reason);
            } else {
                const Card *card_ex = NULL;
                if (!yueying->isKongcheng())
                    card_ex = room->askForCard(yueying, ".", "@jizhi-exchange:::" + card->objectName(),
                    QVariant::fromValue(card), Card::MethodNone);
                if (card_ex) {
                    CardMoveReason reason1(CardMoveReason::S_REASON_PUT, yueying->objectName(), "jizhi", QString());
                    CardMoveReason reason2(CardMoveReason::S_REASON_DRAW, yueying->objectName(), "jizhi", QString());
                    CardsMoveStruct move1(card_ex->getEffectiveId(), yueying, NULL, Player::PlaceUnknown, Player::DrawPile, reason1);
                    CardsMoveStruct move2(ids, yueying, yueying, Player::PlaceUnknown, Player::PlaceHand, reason2);

                    QList<CardsMoveStruct> moves;
                    moves.append(move1);
                    moves.append(move2);
                    room->moveCardsAtomic(moves, false);
                } else {
                    CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, yueying->objectName(), "jizhi", QString());
                    room->throwCard(card, reason, NULL);
                }
            }
        }

        return false;
    }
};

class FiveLinesVS : public ViewAsSkill
{
public:
    FiveLinesVS() : ViewAsSkill("five_lines")
    {
        //response_or_use = true;
    }

    bool isResponseOrUse() const
    {
        return Self->getHp() == 4;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        const Card *armor = Self->getArmor();
        if (armor != NULL) {
            if (to_select->getId() == armor->getId())
                return false;
        }

        int hp = Self->getHp();
        if (hp <= 0)
            hp = 1;
        else if (hp > 5)
            hp = 5;

        switch (hp) {
        case 1:
            return !to_select->isEquipped();
            break;
        case 2:
            return false; // Trigger Skill
            break;
        case 3:
            return selected.length() < 2 && !to_select->isEquipped() && !Self->isJilei(to_select);
            break;
        case 4:
            return selected.isEmpty() && to_select->getSuit() == Card::Diamond;
            break;
        case 5:
            return selected.isEmpty() && !Self->isJilei(to_select);
            break;
        }

        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int hp = Self->getHp();
        if (hp <= 0)
            hp = 1;
        else if (hp > 5)
            hp = 5;

        switch (hp) {
        case 1:
            if (cards.length() > 0) {
                RendeCard *rd = new RendeCard;
                rd->addSubcards(cards);
                return rd;
            }
            return NULL;
            break;
        case 2:
            return NULL; // Trigger Skill
            break;
        case 3:
            if (cards.length() == 2) {
                JieyinCard *jy = new JieyinCard;
                jy->addSubcards(cards);
                return jy;
            }
            return NULL;
            break;
        case 4:
            if (cards.length() == 1) {
                GuoseCard *gs = new GuoseCard;
                gs->addSubcards(cards);
                return gs;
            }
            return NULL;
            break;
        case 5:
            if (cards.length() == 1) {
                KurouCard *kr = new KurouCard;
                kr->addSubcards(cards);
                return kr;
            }
            return NULL;
            break;
        }

        return NULL;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        int hp = Self->getHp();
        if (hp <= 0)
            hp = 1;
        else if (hp > 5)
            hp = 5;

        switch (hp) {
        case 1:
            return !player->hasUsed("RendeCard");
            break;
        case 2:
            return false; // Trigger Skill
            break;
        case 3:
            return !player->hasUsed("JieyinCard");
            break;
        case 4:
            return !player->hasUsed("GuoseCard");
            break;
        case 5:
            return !player->hasUsed("KurouCard");
            break;
        }

        return false;
    }
};

class FiveLinesSkill : public ArmorSkill
{
public:
    FiveLinesSkill() : ArmorSkill("five_lines")
    {
        events << CardUsed;
        view_as_skill = new FiveLinesVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return ArmorSkill::triggerable(target) && target->getHp() == 2;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        const TriggerSkill *jz = Sanguosha->getTriggerSkill("jizhi");
        if (use.card != NULL && use.card->isKindOf("TrickCard") && jz != NULL)
            return jz->trigger(triggerEvent, room, player, data);

        return false;
    }
};

FiveLines::FiveLines(Card::Suit suit, int number)
    : Armor(suit, number)
{
    setObjectName("five_lines");
}

void FiveLines::onInstall(ServerPlayer *player) const
{
    QList<const TriggerSkill *> skills;
    skills << Sanguosha->getTriggerSkill("rende") << Sanguosha->getTriggerSkill("guose");

    foreach (const TriggerSkill *s, skills) {
        if (s != NULL)
            player->getRoom()->getThread()->addTriggerSkill(s);
    }

    Armor::onInstall(player);
}

DisasterPackage::DisasterPackage()
    :Package("Disaster")
{
    QList<Card *> cards;

    cards << new Deluge(Card::Spade, 1)
        << new Typhoon(Card::Spade, 4)
        << new Earthquake(Card::Club, 10)
        << new Volcano(Card::Heart, 13)
        << new MudSlide(Card::Heart, 7);

    foreach(Card *card, cards)
        card->setParent(this);

    type = CardPack;
}

JoyPackage::JoyPackage()
    :Package("joy")
{
    QList<Card *> cards;

    cards << new Shit(Card::Club, 1)
    << new Shit(Card::Heart, 8)
    << new Shit(Card::Diamond, 13)
    << new Shit(Card::Spade, 10);

    foreach(Card *card, cards)
    card->setParent(this);

    type = CardPack;
    skills << new ShitEffect;
}

class YxSwordSkill : public WeaponSkill
{
public:
    YxSwordSkill() :WeaponSkill("yx_sword")
    {
        events << DamageCaused;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isKindOf("Slash")) {
            QList<ServerPlayer *> players = room->getOtherPlayers(player);
            QMutableListIterator<ServerPlayer *> itor(players);

            while (itor.hasNext()) {
                itor.next();
                if (!player->inMyAttackRange(itor.value()))
                    itor.remove();
            }

            if (players.isEmpty())
                return false;

            QVariant _data = QVariant::fromValue(damage);
            room->setTag("YxSwordData", _data);
            ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@yxsword-select", true, true);
            room->removeTag("YxSwordData");
            if (target != NULL) {
                damage.from = target;
                data = QVariant::fromValue(damage);
                room->moveCardTo(player->getWeapon(), player, target, Player::PlaceHand,
                    CardMoveReason(CardMoveReason::S_REASON_TRANSFER, player->objectName(), objectName(), QString()));
            }
        }
        return damage.to->isDead();
    }
};

YxSword::YxSword(Suit suit, int number)
    :Weapon(suit, number, 3)
{
    setObjectName("yx_sword");
}

JoyEquipPackage::JoyEquipPackage()
    : Package("JoyEquip")
{
    (new Monkey(Card::Diamond, 5))->setParent(this);
    (new GaleShell(Card::Heart, 1))->setParent(this);
    (new YxSword(Card::Club, 9))->setParent(this);
    (new FiveLines(Card::Heart, 5))->setParent(this);

    type = CardPack;
    skills << new GaleShellSkill << new YxSwordSkill << new GrabPeach << new Jizhi << new FiveLinesSkill;

    addMetaObject<RendeCard>();
    addMetaObject<JieyinCard>();
    addMetaObject<GuoseCard>();
    addMetaObject<KurouCard>();
}

ADD_PACKAGE(Joy)
ADD_PACKAGE(Disaster)
ADD_PACKAGE(JoyEquip)
