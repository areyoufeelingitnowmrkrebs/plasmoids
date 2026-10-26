import QtQuick
import QtQuick.Window
import QtWebEngine
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
PlasmoidItem {
    id: root
    Plasmoid.status: (webviewLoader.item && webviewLoader.item.recentlyAudible)
    ? PlasmaCore.Types.ActiveStatus
    : PlasmaCore.Types.PassiveStatus
    Component.onCompleted: {
        if (WebEngine.defaultProfile.storageName !== "Google") {
            WebEngine.defaultProfile.storageName = "Google"
            WebEngine.defaultProfile.offTheRecord = false
            WebEngine.defaultProfile.isPushServiceEnabled = true
            WebEngine.defaultProfile.persistentCookiesPolicy = WebEngineProfile.ForcePersistentCookies
        }
        webviewLoader.active = true
    }
    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        Layout.minimumWidth: Kirigami.Units.iconSizes.smallMedium
        Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium
        Kirigami.Icon {
            anchors.fill: parent
            source: "youtube-music-tray"
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
                if (musicWindow.visible) {
                    musicWindow.hide()
                } else {
                    musicWindow.showMaximized()
                    musicWindow.raise()
                    musicWindow.requestActivate()
                }
            }
        }
    }
    fullRepresentation: Item {}
    Window {
        id: musicWindow
        width: 1200
        height: 800
        title: "YouTube Music"
        transientParent: null
        onClosing: (closeEvent) => {
            closeEvent.accepted = false
            musicWindow.hide()
        }
        onVisibilityChanged: {
            if (visibility === Window.Minimized) {
                musicWindow.hide()
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
                    anchors.margins: 1
                    url: "https://music.youtube.com"
                    profile: WebEngine.defaultProfile
                    settings {
                        allowRunningInsecureContent: false
                        accelerated2dCanvasEnabled: true
                        webGLEnabled: true
                        showScrollBars: false
                    }
                    onPermissionRequested: permission => {
                        permission.deny();
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
}
