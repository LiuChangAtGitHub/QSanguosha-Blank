#include "skill.h"
#include "nostalgia.h"
#include "settings.h"
#include "room.h"

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
