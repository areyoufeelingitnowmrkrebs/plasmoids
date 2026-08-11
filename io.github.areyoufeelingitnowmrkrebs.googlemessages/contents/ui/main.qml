import QtQuick
import QtQuick.Window
import QtWebEngine
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.notification
import org.kde.plasma.core as PlasmaCore
import "../../../io.github.areyoufeelingitnowmrkrebs.googleaccount"
PlasmoidItem {
    id: root
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        Layout.minimumWidth: Kirigami.Units.iconSizes.smallMedium
        Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium
        Kirigami.Icon {
            anchors.fill: parent
            source: "android-messages-desktop-tray"
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                let node = root.parent;
                while (node) {
                    if (typeof node.expanded !== "undefined" && node !== root) {
                        node.expanded = false;
                    }
                    node = node.parent;
                }
                if (messageWindow.visible) {
                    messageWindow.hide()
                } else {
                    messageWindow.showMaximized()
                    messageWindow.raise()
                    messageWindow.requestActivate()
                }
            }
        }
    }
    fullRepresentation: Item {}
    Component {
        id: notificationComponent
        Notification {
            id: internalNotification
            property var webNotification
            componentName: "plasma_workspace"
            eventId: "notification"
            iconName: "android-messages-desktop-tray"
            autoDelete: true
            actions: [
                NotificationAction {
                    id: openAction
                    label: "Open"
                    onActivated: {
                        messageWindow.showMaximized()
                        messageWindow.raise()
                        messageWindow.requestActivate()
                        if (internalNotification.webNotification) {
                            internalNotification.webNotification.click()
                        }
                    }
                }
            ]
        }
    }
    Connections {
        target: Session.profile
        function onPresentNotification(notification) {
            if (notification.origin.toString().indexOf("messages.google.com") !== -1) {
                var nativeNotification = notificationComponent.createObject(root);
                nativeNotification.title = notification.title;
                nativeNotification.text = notification.message;
                nativeNotification.webNotification = notification;
                nativeNotification.sendEvent();
            }
        }
    }
    Window {
        id: messageWindow
        width: 680
        height: 900
        title: "Google Messages"
        transientParent: null
        onClosing: (closeEvent) => {
            closeEvent.accepted = false
            messageWindow.hide()
        }
        onVisibilityChanged: {
            if (visibility === Window.Minimized) {
                messageWindow.hide()
            }
        }
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            WebEngineView {
                id: webview
                anchors.fill: parent
                anchors.margins: 1
                url: "https://messages.google.com/web"
                profile: Session.profile
                settings {
                    javascriptCanAccessClipboard: true
                    allowRunningInsecureContent: false
                    accelerated2dCanvasEnabled: true
                    webGLEnabled: true
                    showScrollBars: false
                }
                onPermissionRequested: permission => {
                    if (permission.permissionType === WebEnginePermission.PermissionType.Notifications) {
                        permission.grant();
                    } else {
                        permission.deny();
                    }
                }
                onNewWindowRequested: request => {
                    if (request.userInitiated) {
                        Qt.openUrlExternally(request.requestedUrl);
                    }
                }
            }
        }
    }
}
