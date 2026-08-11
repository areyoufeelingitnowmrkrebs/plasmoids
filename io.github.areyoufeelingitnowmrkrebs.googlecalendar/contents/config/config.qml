pragma ComponentBehavior: Bound;

import QtQuick;
import org.kde.plasma.configuration;

ConfigModel {
    id: configModel;
    ConfigCategory {
        name: i18n("Appearance");
        icon: "preferences-desktop-color";
        source: "configAppearance.qml";
    }
}
