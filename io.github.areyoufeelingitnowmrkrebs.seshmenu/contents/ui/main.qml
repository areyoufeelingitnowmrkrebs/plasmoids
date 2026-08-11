import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.sessions as Sessions
PlasmoidItem {
    id: root
    Plasmoid.icon: Plasmoid.configuration.icon || "plasmashell"
    Sessions.SessionManagement {
        id: sessionManagement
    }
    fullRepresentation: ColumnLayout {
        spacing: 0
        Layout.minimumWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
//        PlasmaComponents.ItemDelegate {
//            text: "Refresh"
//            Layout.fillWidth: true
//            onClicked:
//        }
        PlasmaComponents.ItemDelegate {
            text: "Lock"
            Layout.fillWidth: true
            onClicked: sessionManagement.lock()
        }
        PlasmaComponents.ItemDelegate {
            text: "Switch"
            Layout.fillWidth: true
            onClicked: sessionManagement.switchUser()
        }
        PlasmaComponents.ItemDelegate {
            text: "Leave"
            Layout.fillWidth: true
            onClicked: sessionManagement.requestLogout(Sessions.SessionManagement.Skip)
        }
        PlasmaComponents.ItemDelegate {
            text: "Restart"
            Layout.fillWidth: true
            onClicked: sessionManagement.requestReboot(Sessions.SessionManagement.Skip)
        }
        PlasmaComponents.ItemDelegate {
            text: "Power"
            Layout.fillWidth: true
            onClicked: sessionManagement.requestShutdown(Sessions.SessionManagement.Skip)
        }
    }
}
