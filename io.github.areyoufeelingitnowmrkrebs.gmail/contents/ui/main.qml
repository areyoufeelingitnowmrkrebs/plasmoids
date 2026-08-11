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
            source: "applications-email-panel"
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
                if (mailWindow.visible) {
                    mailWindow.hide()
                } else {
                    mailWindow.showMaximized()
                    mailWindow.raise()
                    mailWindow.requestActivate()
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
            iconName: "applications-email-panel"
            autoDelete: true
            actions: [
                NotificationAction {
                    id: openAction
                    label: "Open"
                    onActivated: {
                        mailWindow.showMaximized()
                        mailWindow.raise()
                        mailWindow.requestActivate()
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
            if (notification.origin.toString().indexOf("mail.google.com") !== -1) {
                var nativeNotification = notificationComponent.createObject(root);
                nativeNotification.title = notification.title;
                nativeNotification.text = notification.message;
                nativeNotification.webNotification = notification;
                nativeNotification.sendEvent();
            }
        }
    }
    Window {
        id: mailWindow
        width: 1200
        height: 800
        title: "Gmail"
        transientParent: null
        onClosing: (closeEvent) => {
            closeEvent.accepted = false
            mailWindow.hide()
        }
        onVisibilityChanged: {
            if (visibility === Window.Minimized) {
                mailWindow.hide()
            }
        }
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            WebEngineView {
                id: webview
                anchors.fill: parent
                anchors.margins: 1
                url: "https://mail.google.com"
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
                    var urlStr = request.requestedUrl.toString();
                    if (urlStr.indexOf("mail.google.com") >= 0 && urlStr.indexOf("/popout") >= 0) {
                        var match = urlStr.match(/th=(%23|#)([^&]+)/);
                        if (match) {
                            var threadId = decodeURIComponent(match[2]);
                            var baseUrl = urlStr.split("/popout")[0];
                            var newUrl = baseUrl + "/#inbox/" + threadId;
                            webview.url = newUrl;
                            return;
                        }
                    }
                    if (request.userInitiated) {
                        Qt.openUrlExternally(request.requestedUrl);
                    }
                }
            }
        }
    }
}
