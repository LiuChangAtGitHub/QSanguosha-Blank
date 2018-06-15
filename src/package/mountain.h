#ifndef _MOUNTAIN_H
#define _MOUNTAIN_H

#include "generaloverview.h"

class HuashenDialog : public GeneralOverview
{
    Q_OBJECT

public:
    HuashenDialog();

public slots:
    void popup();
};

#endif

