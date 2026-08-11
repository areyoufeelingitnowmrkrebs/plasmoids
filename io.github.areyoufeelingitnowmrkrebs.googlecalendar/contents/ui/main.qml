pragma ComponentBehavior: Bound;
import QtQuick;
import QtQuick.Window;
import QtQuick.Layouts;
import org.kde.plasma.plasmoid;
import org.kde.plasma.core as PlasmaCore;
import org.kde.plasma.plasma5support as P5Support;
import org.kde.kirigami as Kirigami;
import org.kde.config as KConfig;
import org.kde.kcmutils as KCMUtils;
import "." as Local
PlasmoidItem {
    id: root;
    width: Kirigami.Units.gridUnit * 10;
    height: Kirigami.Units.gridUnit * 4;
    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground;
    toolTipItem: Local.Tooltip { }
    readonly property string dateFormatString: setDateFormatString();
    preferredRepresentation: compactRepresentation;
    fullRepresentation: Item {}
    Calendar {
        id: calendarWindow
    }
    compactRepresentation: Loader {
        id: compactLoader
        Layout.minimumWidth: item.Layout.minimumWidth;
        Layout.minimumHeight: item.Layout.minimumHeight;
        Layout.preferredWidth: item.Layout.preferredWidth;
        Layout.preferredHeight: item.Layout.preferredHeight;
        Layout.maximumWidth: item.Layout.maximumWidth;
        Layout.maximumHeight: item.Layout.maximumHeight;
        sourceComponent: digitalClockComponent;
    }
    Component {
        id: digitalClockComponent;
        Clock {
            activeFocusOnTab: true;
            hoverEnabled: true;
            onClicked: {
                let node = root.parent;
                while (node) {
                    if (typeof node.expanded !== "undefined" && node !== root) {
                        node.expanded = false;
                    }
                    node = node.parent;
                }
                if (calendarWindow.visible) {
                    calendarWindow.hide()
                } else {
                    calendarWindow.showMaximized()
                    calendarWindow.raise()
                    calendarWindow.requestActivate()
                }
            }
            dataSource: dataSource
        }
    }
    hideOnWindowDeactivate: !Plasmoid.configuration.pin;
    P5Support.DataSource {
        id: dataSource;
        engine: "time";
        connectedSources: ["Local"];
        interval: intervalAlignment === P5Support.Types.NoAlignment ? 1000 : 60000;
        intervalAlignment: {
            if (Plasmoid.configuration.showSeconds) {
                return P5Support.Types.NoAlignment;
            } else {
                return P5Support.Types.AlignToMinute;
            }
        }
    }
    function setDateFormatString() {
        let format = Qt.locale().dateFormat(Locale.LongFormat);
        format = format.replace(/(^dddd.?\s)|(,?\sdddd$)/, "");
        return format;
    }
}
