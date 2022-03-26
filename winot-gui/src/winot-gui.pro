QT += quick webview network

SOURCES += \
        RackIllumination.cpp \
        main.cpp

qml.files = $$files(*.qml)
qml.prefix = /qml
fonts.files = $$files(fonts/*)
fonts.prefix = / # will automatically get directory name "fonts" as prefix
RESOURCES += qml fonts

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    RackIllumination.h

