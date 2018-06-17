#ifndef EXCARDS_H
#define EXCARDS_H

#include "package.h"
#include "standard.h"
#include "standard-equips.h"

class SPCardPackage : public Package
{
    Q_OBJECT

public:
    SPCardPackage();
};

class SPMoonSpear : public Weapon
{
    Q_OBJECT

public:
    Q_INVOKABLE SPMoonSpear(Card::Suit suit = Diamond, int number = 12);
};

class NostalgiaPackage : public Package
{
    Q_OBJECT

public:
    NostalgiaPackage();
};

class MoonSpear : public Weapon
{
    Q_OBJECT

public:
    Q_INVOKABLE MoonSpear(Card::Suit suit = Diamond, int number = 12);
};

// Used by client\aux-skills.cpp
// -> class NosYijiCard : public NosRendeCard {};

class NosRendeCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE NosRendeCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class VSCrossbow : public Crossbow
{
    Q_OBJECT

public:
    Q_INVOKABLE VSCrossbow(Card::Suit suit, int number = 1);

    bool match(const QString &pattern) const;
};

class New3v3CardPackage : public Package
{
    Q_OBJECT

public:
    New3v3CardPackage();
};

class New3v3_2013CardPackage : public Package
{
    Q_OBJECT

public:
    New3v3_2013CardPackage();
};

class Drowning : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE Drowning(Card::Suit suit, int number);

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class New1v1CardPackage : public Package
{
    Q_OBJECT

public:
    New1v1CardPackage();
};

class YitianSword :public Weapon
{
    Q_OBJECT

public:
    Q_INVOKABLE YitianSword(Card::Suit suit = Spade, int number = 6);

    void onUninstall(ServerPlayer *player) const;
};

class YitianCardPackage : public Package
{
    Q_OBJECT

public:
    YitianCardPackage();
};

class JoyPackage : public Package
{
    Q_OBJECT

public:
    JoyPackage();
};

class DisasterPackage : public Package
{
    Q_OBJECT

public:
    DisasterPackage();
};

class JoyEquipPackage : public Package
{
    Q_OBJECT

public:
    JoyEquipPackage();
};

class Shit: public BasicCard
{
    Q_OBJECT

public:
    Q_INVOKABLE Shit(Card::Suit suit, int number);
    QString getSubtype() const;

    static bool HasShit(const Card *card);
};



// five disasters:

class Deluge : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE Deluge(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

class Typhoon : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE Typhoon(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

class Earthquake : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE Earthquake(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

class Volcano : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE Volcano(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

class MudSlide : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE MudSlide(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

class Monkey : public OffensiveHorse
{
    Q_OBJECT

public:
    Q_INVOKABLE Monkey(Card::Suit suit, int number);
};

class GaleShell :public Armor
{
    Q_OBJECT

public:
    Q_INVOKABLE GaleShell(Card::Suit suit, int number);

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
};

class YxSword : public Weapon
{
    Q_OBJECT

public:
    Q_INVOKABLE YxSword(Card::Suit suit, int number);
};

class RendeCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE RendeCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class JieyinCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JieyinCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class GuoseCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE GuoseCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    const Card *validate(CardUseStruct &cardUse) const;
    void onUse(Room *room, const CardUseStruct &use) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class KurouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE KurouCard();

    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class FiveLines : public Armor
{
    Q_OBJECT

public:
    Q_INVOKABLE FiveLines(Card::Suit suit, int number);

    void onInstall(ServerPlayer *player) const;
};

#endif // EXCARDS_H
