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

        SystemPalette {
            id: activePalette
            colorGroup: SystemPalette.Active
            onWindowTextChanged: if (webviewLoader.item) webviewLoader.item.injectThemeCss()
            onHighlightChanged: if (webviewLoader.item) webviewLoader.item.injectThemeCss()
        }
        Item {
            id: themeProbe
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.inherit: false
            Connections {
                target: themeProbe.Kirigami.Theme
                function onTextColorChanged() { if (webviewLoader.item) webviewLoader.item.injectThemeCss() }
                function onHighlightColorChanged() { if (webviewLoader.item) webviewLoader.item.injectThemeCss() }
                function onLinkColorChanged() { if (webviewLoader.item) webviewLoader.item.injectThemeCss() }
                function onVisitedLinkColorChanged() { if (webviewLoader.item) webviewLoader.item.injectThemeCss() }
                function onDefaultFontChanged() { if (webviewLoader.item) webviewLoader.item.injectThemeCss() }
            }
        }

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
            if (webviewLoader.item) webviewLoader.item.injectThemeCss();
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
                function toRgbStr(c) {
                    return `${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}`;
                }
                function injectThemeCss() {
                    const textColor = activePalette.windowText;
                    const accentColor = activePalette.highlight;
                    const secondaryColor = themeProbe.Kirigami.Theme.linkColor;
                    const visitedColor = themeProbe.Kirigami.Theme.visitedLinkColor;
                    const textHex = textColor.toString();
                    const textRgb = toRgbStr(textColor);
                    const accentHex = accentColor.toString();
                    const accentRgb = toRgbStr(accentColor);
                    const secondaryHex = secondaryColor.toString();
                    const secondaryRgb = toRgbStr(secondaryColor);
                    const visitedRgb = toRgbStr(visitedColor);
                    const fontName = themeProbe.Kirigami.Theme.defaultFont.family;
                    const css = `
                    :root, body, .dark-theme {
                        --plasma-text: ${textHex};
                        --plasma-text-rgb: ${textRgb};
                        --plasma-accent: ${accentHex};
                        --plasma-accent-rgb: ${accentRgb};
                        --plasma-secondary: ${secondaryHex};
                        --plasma-secondary-rgb: ${secondaryRgb};
                        --plasma-visited-rgb: ${visitedRgb};
                        --plasma-font: "${fontName}", sans-serif;
                        --body-bg-color: transparent !important;
                        --dialog-bg-color: transparent !important;
                        --cdk-overlay-backdrop-bg-color: transparent !important;
                        --mat-app-background-color: transparent !important;
                        --mat-app-text-color: var(--plasma-text) !important;
                        --mat-dialog-container-color: transparent !important;
                        --mat-menu-container-color: transparent !important;
                        --mat-menu-bg-color: transparent !important;
                        --mat-menu-bg-color-hover: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        --mat-menu-color: var(--plasma-text) !important;
                        --mat-menu-item-label-text-color: var(--plasma-text) !important;
                        --mat-menu-item-icon-color: var(--plasma-accent) !important;
                        --mat-menu-item-hover-state-layer-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        --mat-menu-item-focus-state-layer-color: rgba(var(--plasma-accent-rgb), 0.22) !important;
                        --mat-select-panel-background-color: transparent !important;
                        --mat-option-label-text-color: var(--plasma-text) !important;
                        --mat-option-selected-state-label-text-color: var(--plasma-accent) !important;
                        --mat-option-hover-state-layer-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        --mat-option-selected-state-layer-color: rgba(var(--plasma-accent-rgb), 0.22) !important;
                        --mat-focus-indicator-border-color: var(--plasma-accent) !important;
                        --focus-ring-color: var(--plasma-accent) !important;
                        --icon-button-color: var(--plasma-text) !important;
                        --icon-button-disabled-color: rgba(var(--plasma-text-rgb), 0.35) !important;
                        --button-hover-bg-color: rgba(var(--plasma-accent-rgb), 0.14) !important;
                        --mat-chip-bg-color: rgba(var(--plasma-secondary-rgb), 0.16) !important;
                        --mat-chip-color: var(--plasma-text) !important;
                        --mat-snackbar-bg-color: transparent !important;
                        --mat-snackbar-color: var(--plasma-text) !important;
                        --mat-snackbar-action-color: var(--plasma-accent) !important;
                        --mat-slide-toggle-selected-track-color: rgba(var(--plasma-accent-rgb), 0.35) !important;
                        --mat-slide-toggle-selected-handle-color: var(--plasma-accent) !important;
                        --mdc-switch-on-track-color: rgba(var(--plasma-accent-rgb), 0.35) !important;
                        --mdc-switch-on-handle-color: var(--plasma-accent) !important;
                        --mat-progress-spinner-active-indicator-color: var(--plasma-accent) !important;
                        --mention-pill-incoming-bg: rgba(var(--plasma-secondary-rgb), 0.22) !important;
                        --mention-pill-incoming-color: var(--plasma-text) !important;
                        --mention-pill-outgoing-bg: rgba(var(--plasma-accent-rgb), 0.22) !important;
                        --mention-pill-outgoing-color: var(--plasma-text) !important;
                    }
                    body, button, input, textarea, select,
                    h1, h2, h3, h4, h5, h6, p, a, span, div,
                    .name, .snippet-text, .title, .input,
                    .mat-mdc-menu-item-text, .mdc-button__label, .fab-label,
                    mws-message-part-content, mws-conversation-snippet, mws-relative-timestamp {
                        font-family: var(--plasma-font) !important;
                        color: var(--plasma-text) !important;
                    }
                    html, body,
                    mw-app, mw-bootstrap, .main-stack, mw-g-ui-container,
                    main.content-container, .main-content, mw-main-container, .main-container,
                    mw-main-nav, .main-nav-header, mws-conversations-list, nav.conversation-list, .conv-container,
                    mw-conversation-container, .wrapper, .container, .conversation, .headers,
                    mw-conversation-header, mws-header, .header,
                    mws-messages-list, mws-bottom-anchored, .bottom-anchored-content,
                    mws-message-compose, .compose-container, .input-background,
                    .input-box, .input-area, .input-row, mws-autosize-textarea, .input,
                    .mat-mdc-menu-panel, .mat-mdc-menu-content,
                    .mat-mdc-dialog-container, .mdc-dialog__surface,
                    mws-picker-wrapper, mws-emoji-picker, mws-sticker-picker, mws-gif-picker {
                        background-color: transparent !important;
                        background-image: none !important;
                        box-shadow: none !important;
                        border: none !important;
                    }
                    mws-bottom-anchored::before, mws-bottom-anchored::after,
                    .bottom-anchored-content::before, .bottom-anchored-content::after,
                    mws-message-compose::before, mws-message-compose::after,
                    .compose-transparent-wrapper::before, .compose-transparent-wrapper::after,
                    mw-main-nav::before, mw-main-nav::after {
                        background-color: transparent !important;
                        background-image: none !important;
                        box-shadow: none !important;
                        border: none !important;
                        content: none !important;
                    }
                    /* Start Chat FAB - Edgeless Translucent Accent */
                    a.mdc-button.fab, mw-fab-link a {
                        background-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        background-image: none !important;
                        box-shadow: none !important;
                        border: none !important;
                    }
                    a.mdc-button.fab::after, a.mdc-button.fab::before,
                    a.mdc-button.fab .mdc-button__ripple::before,
                    a.mdc-button.fab .mdc-button__ripple::after {
                        background-color: transparent !important;
                        background-image: none !important;
                    }
                    .fab-icon, .fab-label, mws-icon {
                        color: var(--plasma-text) !important;
                        fill: var(--plasma-text) !important;
                    }
                    /* Conversation List Selection & Hover */
                    a.list-item {
                        background-color: transparent !important;
                        background-image: none !important;
                        border-radius: 16px !important;
                    }
                    a.list-item:hover {
                        background-color: rgba(var(--plasma-accent-rgb), 0.08) !important;
                        background-image: none !important;
                    }
                    a.list-item.selected {
                        background-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        background-image: none !important;
                    }
                    a.list-item.selected::after {
                        background-color: var(--plasma-accent) !important;
                    }
                    /* Outgoing Message Bubbles -> Translucent Accent */
                    mws-message-part-content.outgoing,
                    mws-message-part-content.rcs-outgoing,
                    div.link-preview-container.outgoing {
                        background-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        background-image: none !important;
                        box-shadow: none !important;
                        border: none !important;
                        color: var(--plasma-text) !important;
                    }
                    /* Incoming Message Bubbles -> Translucent Secondary */
                    mws-message-part-content.incoming,
                    mws-message-part-content.rcs-incoming,
                    div.link-preview-container.incoming,
                    mws-link-preview-decorator {
                        background-color: rgba(var(--plasma-secondary-rgb), 0.18) !important;
                        background-image: none !important;
                        box-shadow: none !important;
                        border: none !important;
                        color: var(--plasma-text) !important;
                    }
                    /* Emoji Reaction Pills */
                    span.msg-reactions-bubble {
                        background-color: rgba(var(--plasma-visited-rgb), 0.20) !important;
                        background-image: none !important;
                        box-shadow: none !important;
                        border: none !important;
                    }
                    span.msg-reactions-bubble::before {
                        box-shadow: none !important;
                    }
                    /* Compose Input Box - Edgeless Translucent Glass */
                    div.input-box {
                        background-color: rgba(var(--plasma-accent-rgb), 0.08) !important;
                        background-image: none !important;
                        box-shadow: none !important;
                        border: none !important;
                    }
                    button.send-button {
                        background-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        background-image: none !important;
                    }
                    button.send-button::after,
                    .mdc-icon-button__ripple::before {
                        background-color: transparent !important;
                        background-image: none !important;
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

                        let rafId = null;
                        function updateMaskAndCleanUI() {
                            rafId = null;
                            const startChatBtn = Array.from(document.querySelectorAll('a, button, mw-fab-link'))
                            .find(el => el.textContent && el.textContent.trim().includes('Start chat'));
                            const menuBtn = document.querySelector('button[aria-label*="Main menu"], button[aria-label*="menu"], #gb');
                            if (menuBtn) {
                                let bar = menuBtn;
                                while (bar && bar.parentElement) {
                                    if (startChatBtn && bar.contains(startChatBtn)) break;
                                    if (bar.offsetHeight >= 40 && bar.offsetHeight < 90 && bar.offsetWidth > 200) {
                                        bar.style.setProperty('display', 'none', 'important');
                                        break;
                                    }
                                    bar = bar.parentElement;
                                }
                            }

                            /* 1. Top Header & Bottom Compose Scroll-Fade Mask */
                            const convHeader = document.querySelector('mws-header, mw-conversation-container header');
                            const composeBox = document.querySelector('mws-message-compose');
                            const msgList = document.querySelector('mws-messages-list, .messages-list, [role="log"]');
                            if (msgList) {
                                const headerH = convHeader ? (convHeader.offsetHeight || 68) : 68;
                                const composeH = composeBox ? (composeBox.offsetHeight || 82) : 82;
                                const maskGradient = \`linear-gradient(to bottom, transparent 0px, transparent \${headerH - 4}px, black \${headerH + 12}px, black calc(100% - \${composeH + 10}px), transparent calc(100% - \${composeH - 6}px), transparent 100%)\`;
                                msgList.style.setProperty('-webkit-mask-image', maskGradient, 'important');
                                msgList.style.setProperty('mask-image', maskGradient, 'important');
                            }

                            /* 2. Left Nav List Top Fade Behind "Start chat" Header */
                            const navHeader = document.querySelector('.main-nav-header');
                            const convList = document.querySelector('mws-conversations-list, nav.conversation-list');
                            if (navHeader && convList) {
                                const maskNav = 'linear-gradient(to bottom, transparent 0px, black 12px, black 100%)';
                                convList.style.setProperty('-webkit-mask-image', maskNav, 'important');
                                convList.style.setProperty('mask-image', maskNav, 'important');
                            }

                            /* 3. Dynamic 2D Cutout Mask for Popups/Menus/Emoji Pickers */
                            const mainContainer = document.querySelector('mw-main-container');
                            if (mainContainer) {
                                const vw = window.innerWidth;
                                const vh = window.innerHeight;
                                const overlays = Array.from(document.querySelectorAll(
                                    '.cdk-overlay-pane, mws-picker-wrapper > *, [role="menu"], [role="dialog"]'
                                )).filter(el => {
                                    const r = el.getBoundingClientRect();
                                    return r.width > 10 && r.height > 10 && window.getComputedStyle(el).visibility !== 'hidden' && window.getComputedStyle(el).opacity !== '0';
                                });

                                if (overlays.length > 0 && vw > 50 && vh > 50) {
                                    let rects = '';
                                    overlays.forEach(el => {
                                        const r = el.getBoundingClientRect();
                                        const rad = parseFloat(window.getComputedStyle(el).borderRadius) || 12;
                                        rects += \`<rect x="\${Math.max(0, r.left - 4)}" y="\${Math.max(0, r.top - 4)}" width="\${r.width + 8}" height="\${r.height + 8}" rx="\${rad}" ry="\${rad}" fill="black"/>\`;
                                    });
                                    const svg = \`<svg xmlns="http://www.w3.org/2000/svg" width="\${vw}" height="\${vh}"><defs><mask id="m"><rect width="100%" height="100%" fill="white"/>\${rects}</mask></defs><rect width="100%" height="100%" fill="black" mask="url(#m)"/></svg>\`;
                                    const url = \`url("data:image/svg+xml;utf8,\${encodeURIComponent(svg)}")\`;
                                    mainContainer.style.setProperty('-webkit-mask-image', url, 'important');
                                    mainContainer.style.setProperty('mask-image', url, 'important');
                                } else {
                                    mainContainer.style.removeProperty('-webkit-mask-image');
                                    mainContainer.style.removeProperty('mask-image');
                                }
                            }
                        }

                        function scheduleUpdate() {
                            if (!rafId) rafId = requestAnimationFrame(updateMaskAndCleanUI);
                        }
                        updateMaskAndCleanUI();
                        if (!window._plasmaObserver) {
                            window._plasmaObserver = new MutationObserver(scheduleUpdate);
                            window._plasmaObserver.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ['style', 'class', 'aria-expanded'] });
                            window.addEventListener('resize', scheduleUpdate);
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
