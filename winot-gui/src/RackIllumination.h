#ifndef RACKILLUMINATION_H
#define RACKILLUMINATION_H

#include <QObject>
#include <QNetworkAccessManager>

class RackIllumination : public QObject
{
    Q_OBJECT
public:
    explicit RackIllumination(QObject *parent = nullptr);

    enum class Colour { Green, Red, Yellow, Purple };
    Q_ENUM(Colour)

    Q_INVOKABLE void setSlotToColour(int slot, RackIllumination::Colour colour);
    Q_INVOKABLE void allOff();

signals:

private:
    QNetworkAccessManager mNAM;
};

#endif // RACKILLUMINATION_H
