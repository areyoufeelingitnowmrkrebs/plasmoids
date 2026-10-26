import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtWebEngine
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.notification
Window {
    id: calendarWindow
    width: 1200
    height: 800
    title: "Google Calendar"
    transientParent: null
    Component.onCompleted: {
        if (WebEngine.defaultProfile.storageName !== "Google") {
            WebEngine.defaultProfile.storageName = "Google"
            WebEngine.defaultProfile.offTheRecord = false
            WebEngine.defaultProfile.isPushServiceEnabled = true
            WebEngine.defaultProfile.persistentCookiesPolicy = WebEngineProfile.ForcePersistentCookies
        }
        webviewLoader.active = true
    }
    onClosing: (closeEvent) => {
        closeEvent.accepted = false
        calendarWindow.hide()
    }
    onVisibilityChanged: {
        if (visibility === Window.Minimized) {
            calendarWindow.hide()
        }
    }
    Component {
        id: notificationComponent
        Notification {
            id: internalNotification
            property var webNotification
            componentName: "plasma_workspace"
            eventId: "notification"
            iconName: "mini-calendar"
            autoDelete: true
            actions: [
                NotificationAction {
                    id: openAction
                    label: "Open"
                    onActivated: {
                        calendarWindow.showMaximized()
                        calendarWindow.raise()
                        calendarWindow.requestActivate()
                        if (internalNotification.webNotification) {
                            internalNotification.webNotification.click()
                        }
                    }
                }
            ]
        }
    }
    Connections {
        target: WebEngine.defaultProfile
        function onPresentNotification(notification) {
            if (notification.origin.toString().indexOf("calendar.google.com") !== -1) {
                var nativeNotification = notificationComponent.createObject(calendarWindow);
                nativeNotification.title = notification.title;
                nativeNotification.text = notification.message;
                nativeNotification.webNotification = notification;
                nativeNotification.sendEvent();
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        Loader {
            id: webviewLoader
            active: false
            anchors.fill: parent
            sourceComponent: WebEngineView {
                id: webview
                anchors.fill: parent
                url: "https://calendar.google.com/r"
                profile: WebEngine.defaultProfile
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
