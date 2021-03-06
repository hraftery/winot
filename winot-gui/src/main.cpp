#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtWebView>
#include <QQuickWindow>

#include "RackIllumination.h"

int main(int argc, char *argv[])
{
    //When the app runs, this warning is printed to the console:
    // > Qt WebEngine seems to be initialized from a plugin. Please set Qt::AA_ShareOpenGLContexts using QCoreApplication::setAttribute and QSGRendererInterface::OpenGLRhi using QQuickWindow::setGraphicsApi before constructing QGuiApplication.
    //Given I was asked nicely, I do so below. But it makes no discernable difference and the Internet is nonethewiser. ¯\_(ツ)_/¯
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGLRhi);

    QtWebView::initialize();
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    //Warning: Arial is not licensed for free redistribution.
    //This is a stopgap measure for development purposes only.
    QFontDatabase::addApplicationFont(":/fonts/Arial.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Arial Italic.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Arial Bold.ttf");
    QFontDatabase::addApplicationFont(":/fonts/Arial Bold Italic.ttf");

    qmlRegisterType<RackIllumination>("Winot.Gui", 1, 0, "RackIllumination");

    const QUrl url(u"qrc:/qml/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
