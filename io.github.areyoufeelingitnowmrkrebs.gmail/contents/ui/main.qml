import QtQuick
import QtQuick.Window
import QtWebEngine
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.notification
import org.kde.plasma.core as PlasmaCore
PlasmoidItem {
    id: root
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    Component.onCompleted: {
        root.fullRepresentationItem
    }
    compactRepresentation: MouseArea {
        id: compactRoot
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        Layout.minimumWidth: Kirigami.Units.iconSizes.smallMedium
        Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Kirigami.Icon {
            anchors.fill: parent
            source: "applications-email-panel"
            active: compactRoot.containsMouse
        }
    }
    fullRepresentation: Item {
        id: mailRoot
        property Item trayRootItem: null
        property int savedTrayW: 0
        property int savedTrayH: 0
        property bool isActiveInPopup: false
        function findTrayRootItem() {
            let node = mailRoot.parent;
            let lastItem = null;
            while (node) {
                if (node.Layout !== undefined) {
                    lastItem = node;
                }
                node = node.parent;
            }
            return lastItem;
        }
        function setPopupSize(win, w, h) {
            if (trayRootItem) {
                trayRootItem.Layout.preferredWidth = w;
                trayRootItem.Layout.preferredHeight = h;
            }
            win.width = w;
            win.height = h;
        }
        function onOpen() {
            if (!root.expanded || !mailRoot.visible || isActiveInPopup) return;
            let win = mailRoot.Window.window;
            if (!win) return;
            if (!trayRootItem) trayRootItem = findTrayRootItem();
            savedTrayW = win.width;
            savedTrayH = win.height;
            isActiveInPopup = true;
            if (Plasmoid.configuration.popupWidth > 0 && Plasmoid.configuration.popupHeight > 0) {
                setPopupSize(win, Plasmoid.configuration.popupWidth, Plasmoid.configuration.popupHeight);
            }
        }
        function onClose() {
            if (!isActiveInPopup) return;
            isActiveInPopup = false;
            let win = mailRoot.Window.window;
            if (!win) return;
            if (win.width > 100 && win.height > 100) {
                Plasmoid.configuration.popupWidth = win.width;
                Plasmoid.configuration.popupHeight = win.height;
            }
            if (savedTrayW > 100 && savedTrayH > 100) {
                setPopupSize(win, savedTrayW, savedTrayH);
            }
        }
        onVisibleChanged: {
            if (visible && root.expanded) {
                Qt.callLater(onOpen);
            } else if (!visible && isActiveInPopup) {
                onClose();
            }
        }
        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded && mailRoot.visible) {
                    Qt.callLater(mailRoot.onOpen);
                } else if (!root.expanded && mailRoot.isActiveInPopup) {
                    mailRoot.onClose();
                }
            }
        }
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
                iconName: "applications-email-panel"
                autoDelete: true
                actions: [
                    NotificationAction {
                        id: openAction
                        label: "Open"
                        onActivated: {
                            root.expanded = true
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
                if (notification.origin.toString().indexOf("mail.google.com") !== -1) {
                    var nativeNotification = notificationComponent.createObject(mailRoot);
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
                url: "https://mail.google.com"
                profile: WebEngine.defaultProfile
                backgroundColor: "transparent"
                function injectThemeCss() {
                    const css = `
                    html, body, .wl, .wF, .aAT, .aAU,
                    .nH, .aeJ, .aeF, .Tm, .AO, .bkK, .bkL, .nn, .apV, .aUx,
                    .aeN, .wT, .bAw, .aeH, .G-atb, .D, .E, .BltHke, .UI,
                    #gb, header, [role="banner"], [role="navigation"], [role="main"],
                    .aKh, .aAy, .aKk, .J-KU-Jg, .F, .Cp,
                    tr.zA, tr.zA.zE, tr.zA.yO, tr.zA > td,
                    ul.bqY, ul.bqY > li, .bqX,
                    .if, .nH.if, .iY, .adn, .ads, .gs, .ii.gt, .a3s,
                    .hi, .ha, .h7, .gE, .gA, .gt, .amn, .ams, .nr {
                        background: transparent !important;
                        background-color: transparent !important;
                        background-image: none !important;
                        box-shadow: none !important;
                    }
                    tr.zA::before, tr.zA::after,
                    .G-atb::before, .G-atb::after,
                    .aKh::before, .aKh::after,
                    .aAy::before, .aAy::after {
                        background: transparent !important;
                        box-shadow: none !important;
                    }
                    tr.zA {
                        border-bottom: 1px solid rgba(255, 255, 255, 0.08) !important;
                    }
                    tr.zA:hover {
                        background-color: rgba(255, 255, 255, 0.10) !important;
                    }
                    tr.zA.x7 {
                        background-color: rgba(138, 180, 248, 0.20) !important;
                    }
                    .hP, .gD, .go, .g3, .g2, .hb, .ii.gt, .a3s {
                        color: #e8eaed !important;
                    }
                    form[role="search"], .aso_search_form_anchor {
                        background: rgba(32, 34, 38, 0.96) !important;
                        background-color: rgba(32, 34, 38, 0.96) !important;
                        border-radius: 24px !important;
                        box-shadow: none !important;
                    }
                    form[role="search"] div,
                        form[role="search"] table,
                            form[role="search"] tbody,
                                form[role="search"] tr,
                                    form[role="search"] td,
                                        .gstl_50, .gssb_c, .gssb_e, .gssb_m, .gssb_a, .gssb_a td {
                                            background: rgba(32, 34, 38, 0.98) !important;
                                            background-color: rgba(32, 34, 38, 0.98) !important;
                                            color: #e8eaed !important;
                                            border-color: rgba(255, 255, 255, 0.08) !important;
                                            box-shadow: none !important;
                                        }
                                        .T-I-KE {
                                            background-color: rgba(40, 42, 45, 0.92) !important;
                                            color: #e8eaed !important;
                                            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3) !important;
                                        }
                                        [role="dialog"], [role="menu"], [role="listbox"], .J-M, .aaZ, .M9, .nH.Hd, .AD {
                                            background: rgba(32, 34, 38, 0.96) !important;
                                            background-color: rgba(32, 34, 38, 0.96) !important;
                                            color: #e8eaed !important;
                                            border-radius: 16px !important;
                                            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5) !important;
                                        }
                                        [role="dialog"] div,
                                        [role="dialog"] table,
                                        [role="dialog"] tbody,
                                        [role="dialog"] tr,
                                        [role="dialog"] td,
                                        [role="dialog"] form,
                                        [role="dialog"] input,
                                        [role="dialog"] textarea,
                                        [role="dialog"] span,
                                        .M9 div, .M9 table, .M9 td, .Am {
                                            background: transparent !important;
                                            background-color: transparent !important;
                                            color: #e8eaed !important;
                                            border-color: rgba(255, 255, 255, 0.10) !important;
                                            box-shadow: none !important;
                                        }
                                        [role="dialog"] .T-I.J-J5-Ji.aoO {
                                            background-color: #0b57d0 !important;
                                            color: #ffffff !important;
                                            border-radius: 18px !important;
                                        }
                                        `;
                                        const js = `
                                        (function() {
                                            if (!window._plasmaSheet) {
                                                window._plasmaSheet = new CSSStyleSheet();
                                                document.adoptedStyleSheets = [...document.adoptedStyleSheets, window._plasmaSheet];
                                            }
                                            window._plasmaSheet.replaceSync(${JSON.stringify(css)});
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
