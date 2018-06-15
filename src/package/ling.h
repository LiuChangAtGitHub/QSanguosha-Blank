#ifndef _LING_H
#define _LING_H

#include "package.h"
#include "card.h"

class LingPackage : public Package
{
    Q_OBJECT

public:
    LingPackage();
};

class LuoyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE LuoyiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class NeoFanjianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE NeoFanjianCard();
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
