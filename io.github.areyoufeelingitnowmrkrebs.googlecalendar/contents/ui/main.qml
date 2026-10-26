pragma ComponentBehavior: Bound;
import QtQuick;
import QtQuick.Layouts;
import org.kde.plasma.plasmoid;
import org.kde.plasma.core as PlasmaCore;
import org.kde.plasma.plasma5support as P5Support;
import org.kde.kirigami as Kirigami;
import "." as Local
PlasmoidItem {
    id: root;
    width: Kirigami.Units.gridUnit * 10;
    height: Kirigami.Units.gridUnit * 4;
    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground;
    hideOnWindowDeactivate: !Plasmoid.configuration.pin;
    toolTipItem: Local.Tooltip { }
    preferredRepresentation: compactRepresentation;
    compactRepresentation: Loader {
        id: compactLoader
        Layout.minimumWidth: item ? item.Layout.minimumWidth : 0;
        Layout.minimumHeight: item ? item.Layout.minimumHeight : 0;
        Layout.preferredWidth: item ? item.Layout.preferredWidth : 0;
        Layout.preferredHeight: item ? item.Layout.preferredHeight : 0;
        Layout.maximumWidth: item ? item.Layout.maximumWidth : 0;
        Layout.maximumHeight: item ? item.Layout.maximumHeight : 0;
        sourceComponent: digitalClockComponent;
    }
    fullRepresentation: Calendar {
        plasmoidItem: root
    }
    Component.onCompleted: {
        root.fullRepresentationItem;
    }
    Component {
        id: digitalClockComponent;
        Clock {
            activeFocusOnTab: true;
            hoverEnabled: true;
            onClicked: {
                root.expanded = !root.expanded;
            }
            dataSource: dataSource
        }
    }
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
}
