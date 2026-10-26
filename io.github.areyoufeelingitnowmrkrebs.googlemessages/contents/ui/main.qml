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
            source: "android-messages-desktop-tray"
            active: compactRoot.containsMouse
        }
    }
    fullRepresentation: Item {
        id: messagesRoot
        property Item trayRootItem: null
        property int savedTrayW: 0
        property int savedTrayH: 0
        property bool isActiveInPopup: false
        function findTrayRootItem() {
            let node = messagesRoot.parent;
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
            if (!root.expanded || !messagesRoot.visible || isActiveInPopup) return;
            let win = messagesRoot.Window.window;
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
            let win = messagesRoot.Window.window;
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
                if (root.expanded && messagesRoot.visible) {
                    Qt.callLater(messagesRoot.onOpen);
                } else if (!root.expanded && messagesRoot.isActiveInPopup) {
                    messagesRoot.onClose();
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
                iconName: "android-messages-desktop-tray"
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
                if (notification.origin.toString().indexOf("messages.google.com") !== -1) {
                    var nativeNotification = notificationComponent.createObject(messagesRoot);
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
                url: "https://messages.google.com/web"
                profile: WebEngine.defaultProfile
                backgroundColor: "transparent"
                function injectThemeCss() {
                    const css = `
                    html, body,
                    mw-app, mw-app-container,
                    .main-container, .content-container,
                    mw-main-nav, mw-main-nav-header, .nav-list-container,
                    mw-conversation-container, .container,
                    mws-header, .header,
                    mws-messages-list,
                    mws-bottom-anchored, .bottom-anchored-content,
                    mws-message-compose {
                        background: transparent !important;
                        background-color: transparent !important;
                        background-image: none !important;
                        box-shadow: none !important;
                    }
                    mws-bottom-anchored::before, mws-bottom-anchored::after,
                    .bottom-anchored-content::before, .bottom-anchored-content::after,
                    mws-message-compose::before, mws-message-compose::after,
                    .compose-transparent-wrapper::before, .compose-transparent-wrapper::after {
                        background: transparent !important;
                        background-color: transparent !important;
                        background-image: none !important;
                        box-shadow: none !important;
                        border: none !important;
                        content: none !important;
                    }
                    `;
                    const js = `
                    (function() {
                        let style = document.getElementById('plasma-theme-style');
                        if (!style) {
                            style = document.createElement('style');
                            style.id = 'plasma-theme-style';
                            document.head.appendChild(style);
                        }
                        style.textContent = ${JSON.stringify(css)};
                        function cleanUI() {
                            const startChatBtn = Array.from(document.querySelectorAll('a, button, mw-fab-link'))
                            .find(el => el.textContent && el.textContent.trim().includes('Start chat'));
                            const menuBtn = document.querySelector('button[aria-label*="Main menu"], button[aria-label*="menu"], #gb');
                            if (menuBtn) {
                                let bar = menuBtn;
                                while (bar && bar.parentElement) {
                                    if (startChatBtn && bar.contains(startChatBtn)) {
                                        break;
                                    }
                                    if (bar.offsetHeight >= 40 && bar.offsetHeight < 90 && bar.offsetWidth > 200) {
                                        bar.style.setProperty('display', 'none', 'important');
                                        break;
                                    }
                                    bar = bar.parentElement;
                                }
                            }
                            const convHeader = document.querySelector('mws-header, mw-conversation-container header');
                            const msgList = document.querySelector('mws-messages-list, .messages-list, [role="log"]');
                            if (convHeader && msgList) {
                                const headerH = convHeader.offsetHeight || 56;
                                const maskGradient = \`linear-gradient(to bottom, transparent 0px, transparent \${headerH - 4}px, black \${headerH + 10}px, black 100%)\`;
                                msgList.style.setProperty('-webkit-mask-image', maskGradient, 'important');
                                msgList.style.setProperty('mask-image', maskGradient, 'important');
                            }
                            const inputEl = document.querySelector('[contenteditable="true"], textarea');
                            const emojiBtn = document.querySelector('button[aria-label*="emoji" i], button[aria-label*="Emoji" i], mws-message-compose button');
                            if (inputEl) {
                                let innerPill = inputEl;
                                let curr = inputEl.parentElement;
                                while (curr && curr !== document.body) {
                                    const containsToolbar = emojiBtn ? curr.contains(emojiBtn) : (curr.offsetHeight >= 70);
                                    const s = window.getComputedStyle(curr);
                                    const radius = parseFloat(s.borderTopLeftRadius) || 0;
                                    if (containsToolbar && radius >= 12 && curr.offsetWidth > 200) {
                                        innerPill = curr;
                                        break;
                                    }
                                    curr = curr.parentElement;
                                }
                                let ancestor = innerPill.parentElement;
                                while (ancestor && ancestor !== document.body) {
                                    ancestor.classList.add('compose-transparent-wrapper');
                                    ancestor.style.setProperty('background', 'transparent', 'important');
                                    ancestor.style.setProperty('background-color', 'transparent', 'important');
                                    ancestor.style.setProperty('background-image', 'none', 'important');
                                    ancestor.style.setProperty('box-shadow', 'none', 'important');
                                    ancestor.style.setProperty('border-color', 'transparent', 'important');
                                    Array.from(ancestor.children).forEach(child => {
                                        if (child !== innerPill && !child.contains(innerPill)) {
                                            child.classList.add('compose-transparent-wrapper');
                                            child.style.setProperty('background', 'transparent', 'important');
                                            child.style.setProperty('background-color', 'transparent', 'important');
                                            child.style.setProperty('background-image', 'none', 'important');
                                            child.style.setProperty('box-shadow', 'none', 'important');
                                        }
                                    });
                                    if (ancestor.tagName.toLowerCase() === 'mw-conversation-container') break;
                                    ancestor = ancestor.parentElement;
                                }
                            }
                        }
                        cleanUI();
                        if (!window._plasmaObserver) {
                            window._plasmaObserver = new MutationObserver(() => cleanUI());
                            window._plasmaObserver.observe(document.body, { childList: true, subtree: true });
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
}
