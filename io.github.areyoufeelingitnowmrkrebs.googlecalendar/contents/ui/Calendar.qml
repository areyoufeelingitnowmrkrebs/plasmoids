import QtQuick
import QtQuick.Layouts
import QtWebEngine
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.notification
Item {
    id: calendarRoot
    property PlasmoidItem plasmoidItem
    implicitWidth: 1200
    implicitHeight: 800
    Layout.minimumWidth: Kirigami.Units.gridUnit * 25
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20
    Layout.preferredWidth: 1200
    Layout.preferredHeight: 800
    Component.onCompleted: {
        if (WebEngine.defaultProfile.storageName !== "Google") {
            WebEngine.defaultProfile.storageName = "Google"
            WebEngine.defaultProfile.offTheRecord = false
            WebEngine.defaultProfile.isPushServiceEnabled = true
            WebEngine.defaultProfile.persistentCookiesPolicy = WebEngineProfile.ForcePersistentCookies
        }
        webviewLoader.active = true
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
                        if (calendarRoot.plasmoidItem) {
                            calendarRoot.plasmoidItem.expanded = true
                        }
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
                var nativeNotification = notificationComponent.createObject(calendarRoot);
                nativeNotification.title = notification.title;
                nativeNotification.text = notification.message;
                nativeNotification.webNotification = notification;
                nativeNotification.sendEvent();
            }
        }
    }
    Loader {
        id: webviewLoader
        active: false
        anchors.fill: parent
        sourceComponent: WebEngineView {
            id: webview
            anchors.fill: parent
            url: "https://calendar.google.com/r"
            profile: WebEngine.defaultProfile
            backgroundColor: "transparent"
            function injectThemeCss() {
                const css = `
                :root, html, body {
                    --gm3-sys-color-background: transparent !important;
                    --dt-background: transparent !important;
                    background: transparent !important;
                    background-color: transparent !important;
                }
                body > div,
                header,
                header[role="banner"],
                #gb,
                [role="banner"],
                [role="navigation"],
                [role="main"],
                [role="grid"],
                [role="row"],
                [role="rowgroup"],
                [role="gridcell"],
                [role="columnheader"] {
                    background-color: transparent !important;
                    background-image: none !important;
                }
                [role="gridcell"],
                [role="columnheader"],
                [role="row"] {
                    border-color: rgba(255, 255, 255, 0.12) !important;
                }
                [data-eventid],
                [data-eventid] *,
                [data-eventchip],
                [data-eventchip] * {
                    --gm3-sys-color-surface: #131314 !important;
                    --dt-surface: #131314 !important;
                }
                [role="dialog"],
                [role="menu"],
                [role="listbox"],
                [data-modal="true"] {
                    background-color: rgba(32, 34, 38, 0.96) !important;
                    border-radius: 16px !important;
                    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5) !important;
                }
                `;
                const js = `
                (function() {
                    let style = document.getElementById('plasma-gcal-style');
                    if (!style) {
                        style = document.createElement('style');
                        style.id = 'plasma-gcal-style';
                        document.head.appendChild(style);
                    }
                    style.textContent = ${JSON.stringify(css)};
                    function cleanCalendarUI() {
                        const allEls = document.querySelectorAll('div, main, header, aside, section');
                        allEls.forEach(el => {
                            if (el.closest('[role="dialog"], [role="menu"], [role="listbox"], [data-eventid], [data-eventchip], button, [role="button"]')) {
                                return;
                            }
                            if (el.offsetWidth < 220 && el.offsetHeight < 90) {
                                return;
                            }
                            if (el.offsetHeight <= 2 || el.offsetWidth <= 2) {
                                return;
                            }
                            const computed = window.getComputedStyle(el);
                            const bg = computed.backgroundColor;
                            if (bg && bg !== 'rgba(0, 0, 0, 0)' && bg !== 'transparent') {
                                const match = bg.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)/);
                                if (match) {
                                    const r = parseInt(match[1]), g = parseInt(match[2]), b = parseInt(match[3]);
                                    const maxDiff = Math.max(Math.abs(r - g), Math.abs(g - b), Math.abs(r - b));
                                    if (maxDiff < 25) {
                                        el.style.setProperty('background', 'transparent', 'important');
                                        el.style.setProperty('background-color', 'transparent', 'important');
                                        el.style.setProperty('background-image', 'none', 'important');
                                        el.style.setProperty('box-shadow', 'none', 'important');
                                    }
                                }
                            }
                        });
                    }
                    cleanCalendarUI();
                    if (!window._gcalPlasmaObserver) {
                        window._gcalPlasmaObserver = new MutationObserver(() => cleanCalendarUI());
                        window._gcalPlasmaObserver.observe(document.body, { childList: true, subtree: true });
                    }
                })();
                `;
                webview.runJavaScript(js);
            }
            onLoadingChanged: loadingInfo => {
                if (loadingInfo.status === WebEngineView.LoadSucceededStatus) {
                    injectThemeCss();
                }
            }
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
