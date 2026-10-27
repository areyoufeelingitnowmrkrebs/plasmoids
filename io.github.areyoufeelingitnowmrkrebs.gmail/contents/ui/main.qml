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
                    :root {
                        --mask-color: transparent !important;
                    }
                    body, input, textarea, select, button, td, th, p, a,
                    .hP, .gD, .go, .g3, .g2, .hb, .yP, .zF, .bog, .y2, .bAq, .ag,
                    .ii.gt, .ii.gt *, .a3s, .a3s *, .Am, .Am * {
                        font-family: "Noto Sans", sans-serif !important;
                        color: #ffffff !important;
                    }
                    .ii.gt a, .a3s a, span#link_undo {
                        color: #00ff00 !important;
                    }
                    /* 100% Transparent Surfaces & Containers */
                    html, body, .wl, .wq, .wp, .wo, .wn, .wF, .aAT, .aAU,
                    .nH, .aeJ, .aeF, .Tm, .AO, .bkK, .bkL, .nn, .apV, .aUx,
                    .aeN, .wT, .bAw, .aeH, .G-atb, .D, .E, .BltHke, .UI,
                    #gb, header, [role="banner"], [role="navigation"], [role="main"],
                    .aKh, .aAy, .aKk, .J-KU-Jg, .F, .Cp,
                    tr.zA, tr.zA.zE, tr.zA.yO, tr.zA > td,
                    ul.bqY, ul.bqY > li, .bqX,
                    .if, .nH.if, .iY, .adn, .ads, .gs, .ii.gt, .a3s,
                    .hi, .ha, .h7, .gE, .gA, .gt, .amn, .ams, .nr, .amr,
                    .btDi4d, .rT5Apb, .tyMQmc, .l2.pfiaof,
                    form[role="search"], #aso_search_form_anchor,
                        form[role="search"] *, .gstl_50, .gssb_c, .gssb_e, .gssb_m, .gssb_a, .gssb_a td,
                            [role="dialog"], [role="menu"], [role="listbox"], .J-M, .aaZ, .M9, .nH.Hd, .AD,
                            [role="dialog"] *, .M9 *, .aDj, .ahe, .IG, .iN, .GQ, .Ap, .Ar, .Au, .Am, .I5 {
                                background: transparent !important;
                                background-color: transparent !important;
                                background-image: none !important;
                                box-shadow: none !important;
                                border-color: transparent !important;
                            }
                            /* Strip All Pseudo-Element Backgrounds (including white inline-reply bar .aDj.ahe::after) */
                            tr.zA::before, tr.zA::after,
                            .G-atb::before, .G-atb::after,
                            .aKh::before, .aKh::after,
                            .aAy::before, .aAy::after,
                            .aDj::before, .aDj::after,
                            .ahe::before, .ahe::after,
                            .Un::before, .UTNHae::before, .UTNHae::after,
                            .ams::after, .J-Z-I::before {
                                background: transparent !important;
                                background-color: transparent !important;
                                background-image: none !important;
                                box-shadow: none !important;
                            }
                            /* Search Bar, Compose FAB, & Reply/Forward Pills - Edgeless Translucent Green */
                            form[role="search"], #aso_search_form_anchor {
                                background: rgba(0, 255, 0, 0.08) !important;
                                border-radius: 24px !important;
                            }
                            .T-I-KE,
                            .T-I.aoO,
                            .T-I.hG,
                            div.TO.aBP.nZ.aiq,
                            span.ams.bkI, span.ams.bkH, span.ams.bkG {
                                background: rgba(0, 255, 0, 0.16) !important;
                                background-color: rgba(0, 255, 0, 0.16) !important;
                                color: #ffffff !important;
                                border: none !important;
                                box-shadow: none !important;
                            }
                            /* Email Row Hover & Selection */
                            tr.zA:hover {
                                background: rgba(0, 255, 0, 0.10) !important;
                                background-color: rgba(0, 255, 0, 0.10) !important;
                            }
                            tr.zA.x7 {
                                background: rgba(0, 255, 0, 0.20) !important;
                                background-color: rgba(0, 255, 0, 0.20) !important;
                            }
                            /* Attachment Chips & Thread Label Badges -> Translucent Blue (#0000ff) */
                            div.brc, div.hN, div.hO, span.LbtP4e {
                                background: rgba(0, 0, 255, 0.18) !important;
                                background-color: rgba(0, 0, 255, 0.18) !important;
                                box-shadow: none !important;
                                border: none !important;
                                color: #ffffff !important;
                            }
                            /* Toast Notification (.vh) -> Translucent Red/Green */
                            div.vh {
                                background: rgba(0, 255, 0, 0.16) !important;
                                background-color: rgba(0, 255, 0, 0.16) !important;
                                box-shadow: none !important;
                                border: none !important;
                                border-radius: 12px !important;
                                color: #ffffff !important;
                            }
                            /* Storage Bar */
                            div.aiC {
                                background: rgba(0, 0, 255, 0.25) !important;
                            }
                            div.aiA {
                                background: #00ff00 !important;
                            }
                            /* Invert Hardcoded Black Thread View Icons to Crisp White */
                            img.ajz, img.ajT, img.mK, .bBf,
                            .adn span.T-KT:not(.xj)::before,
                            span.ams::before,
                            div.Un::after,
                            span.Sz.SB {
                                filter: invert(1) brightness(2) !important;
                            }
                            /* Menu Hover States */
                            [role="menuitem"]:hover, [role="option"]:hover, .gssb_a:hover, .gssb_a:hover td {
                                background: rgba(0, 255, 0, 0.16) !important;
                                background-color: rgba(0, 255, 0, 0.16) !important;
                            }
                            `;
                            const js = `
                            (function() {
                                if (!window._plasmaSheet) {
                                    window._plasmaSheet = new CSSStyleSheet();
                                    document.adoptedStyleSheets = [...document.adoptedStyleSheets, window._plasmaSheet];
                                }
                                window._plasmaSheet.replaceSync(${JSON.stringify(css)});

                                let rafId = null;
                                function updateGmailMasks() {
                                    rafId = null;
                                    /* 1. Scroll-Behind Mask for Inbox & Thread Scroll Container (.Tm.aeJ) */
                                    const scroller = document.querySelector('.Tm.aeJ');
                                    const topBar = document.querySelector('.D.E.G-atb');
                                    const bottomReplyBar = document.querySelector('.btDi4d.rT5Apb.tyMQmc');
                                    const inlineReplyBox = document.querySelector('.ip.adB .M9');

                                    if (scroller) {
                                        const scrollerRect = scroller.getBoundingClientRect();
                                        let topCut = 0;
                                        if (topBar && topBar.offsetHeight > 0) {
                                            topCut = topBar.offsetHeight;
                                        }
                                        let bottomCut = 0;
                                        if (inlineReplyBox && inlineReplyBox.offsetHeight > 0) {
                                            const r = inlineReplyBox.getBoundingClientRect();
                                            if (r.top < scrollerRect.bottom) {
                                                bottomCut = Math.max(0, scrollerRect.bottom - r.top);
                                            }
                                        } else if (bottomReplyBar && bottomReplyBar.offsetHeight > 0) {
                                            bottomCut = bottomReplyBar.offsetHeight;
                                        }

                                        const topStop1 = Math.max(0, topCut - 4);
                                        const topStop2 = topCut + 12;
                                        const botStop1 = Math.max(0, bottomCut + 12);
                                        const botStop2 = Math.max(0, bottomCut - 4);

                                        const grad = \`linear-gradient(to bottom, transparent 0px, transparent \${topStop1}px, black \${topStop2}px, black calc(100% - \${botStop1}px), transparent calc(100% - \${botStop2}px), transparent 100%)\`;
                                        scroller.style.setProperty('-webkit-mask-image', grad, 'important');
                                        scroller.style.setProperty('mask-image', grad, 'important');
                                    }

                                    /* 2. Dynamic 2D Cutout Mask for Floating Compose Dialog, Search Suggestions, Menus, & Toast */
                                    const mainContent = document.querySelector('.nH.bkK');
                                    if (mainContent) {
                                        const overlays = Array.from(document.querySelectorAll(
                                            '.nH.Hd[role="dialog"], .J-M[role="menu"], .gssb_e, div.vh'
                                        )).filter(el => {
                                            const s = window.getComputedStyle(el);
                                            if (s.display === 'none' || s.visibility === 'hidden' || s.opacity === '0') return false;
                                            const r = el.getBoundingClientRect();
                                            return r.width > 15 && r.height > 15;
                                        });

                                        if (overlays.length > 0) {
                                            const mr = mainContent.getBoundingClientRect();
                                            let rects = '';
                                            overlays.forEach(el => {
                                                const r = el.getBoundingClientRect();
                                                const rad = parseFloat(window.getComputedStyle(el).borderRadius) || 16;
                                                const x = r.left - mr.left - 4;
                                                const y = r.top - mr.top - 4;
                                                rects += \`<rect x="\${x}" y="\${y}" width="\${r.width + 8}" height="\${r.height + 8}" rx="\${rad}" ry="\${rad}" fill="black"/>\`;
                                            });
                                            const svg = \`<svg xmlns="http://www.w3.org/2000/svg" width="\${mr.width}" height="\${mr.height}"><defs><mask id="gm"><rect width="100%" height="100%" fill="white"/>\${rects}</mask></defs><rect width="100%" height="100%" fill="black" mask="url(#gm)"/></svg>\`;
                                            const url = \`url("data:image/svg+xml;utf8,\${encodeURIComponent(svg)}")\`;
                                            mainContent.style.setProperty('-webkit-mask-image', url, 'important');
                                            mainContent.style.setProperty('mask-image', url, 'important');
                                        } else {
                                            mainContent.style.removeProperty('-webkit-mask-image');
                                            mainContent.style.removeProperty('mask-image');
                                        }
                                    }
                                }

                                function scheduleGmailUpdate() {
                                    if (!rafId) rafId = requestAnimationFrame(updateGmailMasks);
                                }
                                updateGmailMasks();
                                if (!window._gmailPlasmaObserver) {
                                    window._gmailPlasmaObserver = new MutationObserver(scheduleGmailUpdate);
                                    window._gmailPlasmaObserver.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ['style', 'class', 'aria-expanded'] });
                                    window.addEventListener('resize', scheduleGmailUpdate);
                                    window.addEventListener('scroll', scheduleGmailUpdate, true);
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
