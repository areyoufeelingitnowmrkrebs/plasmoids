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
                    --gm3-autocomplete-filled-text-field-container-color: rgba(0, 255, 0, 0.08) !important;
                    --gm3-text-field-filled-container-color: rgba(0, 255, 0, 0.08) !important;
                    --gm3-select-filled-text-field-container-color: rgba(0, 255, 0, 0.08) !important;
                    --gm3-sys-color-on-background: #ffffff !important;
                    --gm3-sys-color-on-surface: #ffffff !important;
                    --gm3-sys-color-on-surface-variant: #ffffff !important;
                    --gm3-sys-color-primary: #00ff00 !important;
                    --gm3-sys-color-primary-container: rgba(0, 255, 0, 0.20) !important;
                    --gm3-sys-color-on-primary: #ffffff !important;
                    --gm3-sys-color-on-primary-container: #ffffff !important;
                    --gm3-sys-color-secondary: #0000ff !important;
                    --gm3-sys-color-secondary-container: rgba(0, 0, 255, 0.22) !important;
                    --gm3-sys-color-on-secondary: #ffffff !important;
                    --gm3-sys-color-on-secondary-container: #ffffff !important;
                    --gm3-sys-color-tertiary: #ff0000 !important;
                    --gm3-sys-color-tertiary-container: rgba(255, 0, 0, 0.20) !important;
                    --gm3-sys-color-outline: transparent !important;
                    --gm3-sys-color-outline-variant: transparent !important;
                    --cal-sys-color-now-indicator: #ff0000 !important;
                    --dt-background: transparent !important;
                    --dt-surface: transparent !important;
                    --gm3-autocomplete-filled-menu-list-item-label-text-font: "Noto Sans", sans-serif !important;
                    --gm3-autocomplete-outlined-menu-list-item-label-text-font: "Noto Sans", sans-serif !important;
                    --gm3-autocomplete-outlined-text-field-input-text-font: "Noto Sans", sans-serif !important;
                    --gm3-menu-list-item-label-text-font: "Noto Sans", sans-serif !important;
                    --gm3-menu-list-item-supporting-text-font: "Noto Sans", sans-serif !important;
                    --gm3-menu-list-item-trailing-supporting-text-font: "Noto Sans", sans-serif !important;
                    --gm3-menu-group-title-text-font: "Noto Sans", sans-serif !important;
                    background: transparent !important;
                    background-color: transparent !important;
                }
                body, input, textarea, select, button,
                h1, h2, h3, h4, p, a, th, td,
                span:not(.google-material-icons):not(.notranslate),
                div:not(.google-material-icons):not(.notranslate) {
                    font-family: "Noto Sans", sans-serif !important;
                    color: #ffffff !important;
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
                    background: transparent !important;
                    background-color: transparent !important;
                    background-image: none !important;
                    box-shadow: none !important;
                    border-color: transparent !important;
                }
                /* Strip Opaque Pseudo-Elements (including Drawer right-gradient .hEtGGf::after & shadows) */
                .hEtGGf::before, .hEtGGf::after,
                .MMvswb::before, .MMvswb::after,
                .UTNHae::before, .UTNHae::after {
                    background: transparent !important;
                    background-color: transparent !important;
                    background-image: none !important;
                    box-shadow: none !important;
                }
                /* Create Button, Active View Switcher, Today Badge -> Translucent Green (#00ff00) */
                div.dwlvNd.Hrn1mc,
                button.t9Sj3d-BIzmGd,
                button.gPr58d,
                button.aOXrUc,
                button.AeBiU-LgbsSe,
                h2.F262Ye,
                button.sOjuj[aria-label*="today" i] {
                    background: rgba(0, 255, 0, 0.16) !important;
                    background-color: rgba(0, 255, 0, 0.16) !important;
                    box-shadow: none !important;
                    border: none !important;
                    color: #ffffff !important;
                }
                /* Search for People Box in Drawer */
                div.J09ahd.TanRXd,
                div.Fgl6fe-fmcmS-yrriRe {
                    background: rgba(0, 255, 0, 0.08) !important;
                    background-color: rgba(0, 255, 0, 0.08) !important;
                    border-radius: 12px !important;
                }
                /* Event Chips -> High-Transparency Edgeless RGB */
                [data-eventchip] > div,
                div.KF4T6b {
                    background: rgba(0, 0, 255, 0.22) !important;
                    background-color: rgba(0, 0, 255, 0.22) !important;
                    box-shadow: none !important;
                    border: none !important;
                    border-radius: 6px !important;
                }
                [data-eventchip]:hover > div,
                div.KF4T6b:hover {
                    background: rgba(0, 255, 0, 0.25) !important;
                    background-color: rgba(0, 255, 0, 0.25) !important;
                }
                /* Event Chip Color Dots & Checkboxes -> Pure RGB (#ff0000 / #00ff00 / #0000ff) */
                div.VlNR9e {
                    border-color: #00ff00 !important;
                }
                span.CPXyj {
                    background-color: #ff0000 !important;
                }
                div.KGC9Kd-YQoJzd {
                    background-color: rgba(0, 255, 0, 0.30) !important;
                    border-color: #00ff00 !important;
                }
                /* Menu Item Hover */
                [role="menuitem"]:hover, [role="menuitemcheckbox"]:hover, [role="option"]:hover {
                    background: rgba(0, 255, 0, 0.16) !important;
                    background-color: rgba(0, 255, 0, 0.16) !important;
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
                        /* 1. Drawer Scroller Top Fade Behind Floating "Create" Button */
                        const drawerScroller = document.querySelector('.hEtGGf.HDIIVe');
                        if (drawerScroller) {
                            const fade = 'linear-gradient(to bottom, transparent 0px, black 14px, black 100%)';
                            drawerScroller.style.setProperty('-webkit-mask-image', fade, 'important');
                            drawerScroller.style.setProperty('mask-image', fade, 'important');
                        }

                        /* 2. Dynamic 2D Cutout Mask on Calendar Grid & Drawer Behind Open Menus / Event Popovers / Create Button */
                        const mainArea = document.querySelector('.SGWAac');
                        if (mainArea) {
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
                                const mr = mainArea.getBoundingClientRect();
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
