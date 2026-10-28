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
            function onNegativeTextColorChanged() { if (webviewLoader.item) webviewLoader.item.injectThemeCss() }
            function onDefaultFontChanged() { if (webviewLoader.item) webviewLoader.item.injectThemeCss() }
        }
    }

    onVisibleChanged: {
        if (visible && webviewLoader.item) {
            Qt.callLater(webviewLoader.item.injectThemeCss);
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
            function toRgbStr(c) {
                return `${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}`;
            }
            function injectThemeCss() {
                const textColor = activePalette.windowText;
                const accentColor = activePalette.highlight;
                const secondaryColor = themeProbe.Kirigami.Theme.linkColor;
                const alertColor = themeProbe.Kirigami.Theme.negativeTextColor;
                const textHex = textColor.toString();
                const textRgb = toRgbStr(textColor);
                const accentHex = accentColor.toString();
                const accentRgb = toRgbStr(accentColor);
                const secondaryHex = secondaryColor.toString();
                const secondaryRgb = toRgbStr(secondaryColor);
                const alertHex = alertColor.toString();
                const alertRgb = toRgbStr(alertColor);
                const fontName = themeProbe.Kirigami.Theme.defaultFont.family;
                const css = `
                :root, html, body {
                    --plasma-text: ${textHex};
                    --plasma-text-rgb: ${textRgb};
                    --plasma-accent: ${accentHex};
                    --plasma-accent-rgb: ${accentRgb};
                    --plasma-secondary: ${secondaryHex};
                    --plasma-secondary-rgb: ${secondaryRgb};
                    --plasma-alert: ${alertHex};
                    --plasma-alert-rgb: ${alertRgb};
                    --plasma-font: "${fontName}", sans-serif;
                    --gm3-sys-color-background: transparent !important;
                    --gm3-sys-color-surface: transparent !important;
                    --gm3-sys-color-surface-dim: transparent !important;
                    --gm3-sys-color-surface-bright: transparent !important;
                    --gm3-sys-color-surface-container: transparent !important;
                    --gm3-sys-color-surface-container-low: transparent !important;
                    --gm3-sys-color-surface-container-lowest: transparent !important;
                    --gm3-sys-color-surface-container-high: transparent !important;
                    --gm3-sys-color-surface-container-highest: transparent !important;
                    --gm3-sys-color-surface-variant: transparent !important;
                    --gm3-menu-surface-container-color: transparent !important;
                    --gm3-select-shared-menu-container-color: transparent !important;
                    --gm3-autocomplete-filled-text-field-container-color: rgba(var(--plasma-accent-rgb), 0.08) !important;
                    --gm3-text-field-filled-container-color: rgba(var(--plasma-accent-rgb), 0.08) !important;
                    --gm3-select-filled-text-field-container-color: rgba(var(--plasma-accent-rgb), 0.08) !important;
                    --gm3-sys-color-on-background: var(--plasma-text) !important;
                    --gm3-sys-color-on-surface: var(--plasma-text) !important;
                    --gm3-sys-color-on-surface-variant: var(--plasma-text) !important;
                    --gm3-sys-color-primary: var(--plasma-accent) !important;
                    --gm3-sys-color-primary-container: rgba(var(--plasma-accent-rgb), 0.20) !important;
                    --gm3-sys-color-on-primary: var(--plasma-text) !important;
                    --gm3-sys-color-on-primary-container: var(--plasma-text) !important;
                    --gm3-sys-color-secondary: var(--plasma-secondary) !important;
                    --gm3-sys-color-secondary-container: rgba(var(--plasma-secondary-rgb), 0.22) !important;
                    --gm3-sys-color-on-secondary: var(--plasma-text) !important;
                    --gm3-sys-color-on-secondary-container: var(--plasma-text) !important;
                    --gm3-sys-color-tertiary: var(--plasma-alert) !important;
                    --gm3-sys-color-tertiary-container: rgba(var(--plasma-alert-rgb), 0.20) !important;
                    --gm3-sys-color-outline: transparent !important;
                    --gm3-sys-color-outline-variant: transparent !important;
                    --cal-sys-color-now-indicator: var(--plasma-alert) !important;
                    --dt-background: transparent !important;
                    --dt-surface: transparent !important;
                    --gm3-autocomplete-filled-menu-list-item-label-text-font: var(--plasma-font) !important;
                    --gm3-autocomplete-outlined-menu-list-item-label-text-font: var(--plasma-font) !important;
                    --gm3-autocomplete-outlined-text-field-input-text-font: var(--plasma-font) !important;
                    --gm3-menu-list-item-label-text-font: var(--plasma-font) !important;
                    --gm3-menu-list-item-supporting-text-font: var(--plasma-font) !important;
                    --gm3-menu-list-item-trailing-supporting-text-font: var(--plasma-font) !important;
                    --gm3-menu-group-title-text-font: var(--plasma-font) !important;
                    background: transparent !important;
                    background-color: transparent !important;
                }
                body, input, textarea, select, button,
                h1, h2, h3, h4, p, a, th, td,
                span:not(.google-material-icons):not(.notranslate),
                div:not(.google-material-icons):not(.notranslate) {
                    font-family: var(--plasma-font) !important;
                    color: var(--plasma-text) !important;
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
                [role="columnheader"],
                [role="complementary"],
                [role="dialog"],
                [role="menu"],
                [role="listbox"],
                [data-modal="true"],
                .eU5T0b, .tEhMVd, .pSp5K, .KKOvEb, .SGWAac, .lYYbjc, .K2fuAf, .RAaXne,
                .QQYuzf, .YO50ue, .LXjtcc, .hEtGGf, .dOqRGf, .tB5Jxf-xl07Ob-XxIAqe, .aqdrmf-rymPhb {
                    background-color: transparent !important;
                    background-image: none !important;
                    box-shadow: none !important;
                    border-color: transparent !important;
                }
                /* Strip Opaque Pseudo-Elements */
                .hEtGGf::before, .hEtGGf::after,
                .MMvswb::before, .MMvswb::after,
                .UTNHae::before, .UTNHae::after {
                    background-color: transparent !important;
                    background-image: none !important;
                    box-shadow: none !important;
                }
                /* Create Button, Active View Switcher, Today Badge -> Translucent Accent */
                div.dwlvNd.Hrn1mc,
                button.t9Sj3d-BIzmGd,
                button.gPr58d,
                button.aOXrUc,
                button.AeBiU-LgbsSe,
                h2.F262Ye,
                button.sOjuj[aria-label*="today" i] {
                    background-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                    background-image: none !important;
                    box-shadow: none !important;
                    border: none !important;
                    color: var(--plasma-text) !important;
                }
                /* Search for People Box in Drawer */
                div.J09ahd.TanRXd,
                div.Fgl6fe-fmcmS-yrriRe {
                    background-color: rgba(var(--plasma-accent-rgb), 0.08) !important;
                    background-image: none !important;
                    border-radius: 12px !important;
                }
                /* Event Chips -> High-Transparency Edgeless Secondary/Accent */
                [data-eventchip] > div,
                div.KF4T6b {
                    background-color: rgba(var(--plasma-secondary-rgb), 0.22) !important;
                    background-image: none !important;
                    box-shadow: none !important;
                    border: none !important;
                    border-radius: 6px !important;
                }
                [data-eventchip]:hover > div,
                div.KF4T6b:hover {
                    background-color: rgba(var(--plasma-accent-rgb), 0.25) !important;
                    background-image: none !important;
                }
                /* Event Chip Color Dots & Checkboxes -> Plasma Accent / Alert */
                div.VlNR9e {
                    border-color: var(--plasma-accent) !important;
                }
                span.CPXyj {
                    background-color: var(--plasma-alert) !important;
                }
                div.KGC9Kd-YQoJzd {
                    background-color: rgba(var(--plasma-accent-rgb), 0.30) !important;
                    border-color: var(--plasma-accent) !important;
                }
                /* Menu Item Hover */
                [role="menuitem"]:hover, [role="menuitemcheckbox"]:hover, [role="option"]:hover {
                    background-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                    background-image: none !important;
                    border-radius: 8px !important;
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

                    let rafId = null;
                    function updateCalendarMasks() {
                        rafId = null;
                        const drawerScroller = document.querySelector('.hEtGGf.HDIIVe');
                        if (drawerScroller) {
                            const fade = 'linear-gradient(to bottom, transparent 0px, black 14px, black 100%)';
                            drawerScroller.style.setProperty('-webkit-mask-image', fade, 'important');
                            drawerScroller.style.setProperty('mask-image', fade, 'important');
                        }

                        const mainArea = document.querySelector('.SGWAac');
                        if (mainArea) {
                            const mr = mainArea.getBoundingClientRect();
                            if (mr.width < 50 || mr.height < 50) {
                                mainArea.style.removeProperty('-webkit-mask-image');
                                mainArea.style.removeProperty('mask-image');
                                return;
                            }
                            const createBtn = document.querySelector('.dwlvNd.Hrn1mc');
                            const popups = Array.from(document.querySelectorAll(
                                '[role="dialog"], [role="menu"], [role="listbox"], [data-modal="true"]'
                            )).filter(el => {
                                const s = window.getComputedStyle(el);
                                if (s.display === 'none' || s.visibility === 'hidden' || s.opacity === '0') return false;
                                const r = el.getBoundingClientRect();
                                return r.width > 15 && r.height > 15 && r.top < window.innerHeight && r.bottom > 0;
                            });

                            if (createBtn) {
                                const cr = createBtn.getBoundingClientRect();
                                if (cr.width > 15 && cr.height > 15) popups.push(createBtn);
                            }

                            if (popups.length > 0) {
                                let rects = '';
                                popups.forEach(el => {
                                    const r = el.getBoundingClientRect();
                                    const rad = parseFloat(window.getComputedStyle(el).borderRadius) || 16;
                                    const x = r.left - mr.left - 4;
                                    const y = r.top - mr.top - 4;
                                    rects += \`<rect x="\${x}" y="\${y}" width="\${r.width + 8}" height="\${r.height + 8}" rx="\${rad}" ry="\${rad}" fill="black"/>\`;
                                });
                                const svg = \`<svg xmlns="http://www.w3.org/2000/svg" width="\${Math.max(1, mr.width)}" height="\${Math.max(1, mr.height)}"><defs><mask id="cm"><rect width="100%" height="100%" fill="white"/>\${rects}</mask></defs><rect width="100%" height="100%" fill="black" mask="url(#cm)"/></svg>\`;
                                const url = \`url("data:image/svg+xml;utf8,\${encodeURIComponent(svg)}")\`;
                                mainArea.style.setProperty('-webkit-mask-image', url, 'important');
                                mainArea.style.setProperty('mask-image', url, 'important');
                            } else {
                                mainArea.style.removeProperty('-webkit-mask-image');
                                mainArea.style.removeProperty('mask-image');
                            }
                        }
                    }

                    function scheduleCalUpdate() {
                        if (!rafId) rafId = requestAnimationFrame(updateCalendarMasks);
                    }
                    updateCalendarMasks();
                    if (!window._gcalPlasmaObserver) {
                        window._gcalPlasmaObserver = new MutationObserver(scheduleCalUpdate);
                        window._gcalPlasmaObserver.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ['style', 'class', 'aria-expanded', 'aria-hidden'] });
                        window.addEventListener('resize', scheduleCalUpdate);
                        window.addEventListener('scroll', scheduleCalUpdate, true);
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
