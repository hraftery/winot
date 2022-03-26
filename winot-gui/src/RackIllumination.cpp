#include "RackIllumination.h"

#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <qdebug.h>

RackIllumination::RackIllumination(QObject *parent)
    : QObject{parent}
{
}

void RackIllumination::setSlotToColour(int slot, RackIllumination::Colour colour)
{
    unsigned int colourCode, offset1, length1, offset2, length2;
    switch(colour)
    {
        case Colour::Green:     colourCode = 0x90E080;     break;
        case Colour::Red:       colourCode = 0xF08080;     break;
        case Colour::Yellow:    colourCode = 0xF0C070;     break;
        case Colour::Purple:    colourCode = 0xB090F0;     break;
        default: qDebug("Unsupported colour.");            return;
    }
    switch(slot)
    {
        case 1: offset1 = 0; length1 = 8; offset2 =75; length2 = 7; break;
        case 2: offset1 = 8; length1 = 7; offset2 =67; length2 = 8; break;
        case 3: offset1 =15; length1 = 8; offset2 =60; length2 = 7; break;
        case 4: offset1 =23; length1 = 7; offset2 =52; length2 = 8; break;
        case 5: offset1 =30; length1 = 8; offset2 =45; length2 = 7; break;
        default: qDebug("Unsupported slot."); return;
    }

    QString urlStr = "http://192.168.0.120/pixels?offset=%1";
    QNetworkRequest req(QUrl(urlStr.arg(offset1)));
    req.setAttribute(QNetworkRequest::Http2AllowedAttribute, false); //uvicorn doesn't support it. Needlessly complex anyway.
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    //This is all so unnecessarily hard.
    QJsonArray arr;
    for (unsigned int i = 0; i < length1; i++)
        arr.append(QJsonValue((int)colourCode)); //32-bit int wont be enough if alpha is used
    mNAM.put(req, QJsonDocument(arr).toJson());

    req.setUrl(urlStr.arg(offset2));
    QJsonArray arr2;
    for (unsigned int i = 0; i < length2; i++)
        arr2.append(QJsonValue((int)colourCode)); //32-bit int wont be enough if alpha is used
    mNAM.put(req, QJsonDocument(arr2).toJson());
}

void RackIllumination::allOff(void)
{
    QString urlStr = "http://192.168.0.120/pixels/off";
    QNetworkRequest req((QUrl(urlStr)));
    req.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "text/plain"); //uvicorn complains with application/json
    mNAM.put(req, "");
}
