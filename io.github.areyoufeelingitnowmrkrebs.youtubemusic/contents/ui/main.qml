import QtQuick
import QtQuick.Window
import QtWebEngine
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
PlasmoidItem {
    id: root
    Plasmoid.status: (fullRepresentationItem && fullRepresentationItem.isAudible)
    ? PlasmaCore.Types.ActiveStatus
    : PlasmaCore.Types.PassiveStatus
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
            source: "youtube-music-tray"
            active: compactRoot.containsMouse
        }
    }
    fullRepresentation: Item {
        id: musicRoot
        property bool isAudible: webviewLoader.item ? webviewLoader.item.recentlyAudible : false
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
                function onNegativeTextColorChanged() { if (webviewLoader.item) webviewLoader.item.injectThemeCss() }
                function onDefaultFontChanged() { if (webviewLoader.item) webviewLoader.item.injectThemeCss() }
            }
        }

        function findTrayRootItem() {
            let node = musicRoot.parent;
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
            if (!root.expanded || !musicRoot.visible || isActiveInPopup) return;
            let win = musicRoot.Window.window;
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
            let win = musicRoot.Window.window;
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
                if (root.expanded && musicRoot.visible) {
                    Qt.callLater(musicRoot.onOpen);
                } else if (!root.expanded && musicRoot.isActiveInPopup) {
                    musicRoot.onClose();
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
        Loader {
            id: webviewLoader
            active: false
            anchors.fill: parent
            sourceComponent: WebEngineView {
                id: webview
                anchors.fill: parent
                url: "https://music.youtube.com"
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
                        --ytmusic-background: transparent !important;
                        --ytmusic-general-background-a: transparent !important;
                        --ytmusic-general-background-b: transparent !important;
                        --ytmusic-general-background-c: transparent !important;
                        --ytmusic-brand-background-solid: transparent !important;
                        --ytmusic-nav-bar: transparent !important;
                        --ytmusic-player-bar-background: transparent !important;
                        --ytmusic-player-page-background: transparent !important;
                        --ytmusic-search-background: transparent !important;
                        --ytmusic-search-border: transparent !important;
                        --ytmusic-dropdown-background: transparent !important;
                        --ytmusic-dialog-background-color: transparent !important;
                        --paper-dialog-background-color: transparent !important;
                        --paper-listbox-background-color: transparent !important;
                        --paper-menu-background-color: transparent !important;
                        --yt-spec-base-background: transparent !important;
                        --yt-spec-general-background-a: transparent !important;
                        --yt-spec-general-background-b: transparent !important;
                        --yt-spec-raised-background: transparent !important;
                        --yt-spec-menu-background: transparent !important;
                        --yt-sys-color-baseline--base-background: transparent !important;
                        --yt-sys-color-baseline--raised-background: transparent !important;
                        --yt-sys-color-baseline--surface-container: transparent !important;
                        --yt-sys-color-baseline--menu-background: transparent !important;
                        --yt-sys-color-baseline--text-primary: var(--plasma-text) !important;
                        --yt-sys-color-baseline--text-secondary: var(--plasma-text) !important;
                        --yt-sys-color-baseline--call-to-action: var(--plasma-accent) !important;
                        --ytmusic-color-white1: var(--plasma-text) !important;
                        --ytmusic-color-grey2: var(--plasma-text) !important;
                        --ytmusic-color-grey3: var(--plasma-text) !important;
                        --ytmusic-color-lightblue: var(--plasma-accent) !important;
                        --ytmusic-brand-link-text: var(--plasma-accent) !important;
                        --ytmusic-playback-progress-color: var(--plasma-accent) !important;
                        --ytmusic-badge-chip-background: rgba(var(--plasma-secondary-rgb), 0.16) !important;
                        --ytmusic-badge-chip-inactive-hover: rgba(var(--plasma-accent-rgb), 0.20) !important;
                        --ytmusic-search-suggestion-focus-active-background: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        --ytmusic-menu-item-hover-background-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        background: transparent !important;
                        background-color: transparent !important;
                        height: 100vh !important;
                        overflow: hidden !important;
                    }
                    body, input, button, yt-formatted-string, span, a, div,
                    .title, .subtitle, .byline, .time-info {
                        font-family: var(--plasma-font) !important;
                        color: var(--plasma-text) !important;
                    }
                    /* Content Scroller with Top & Bottom Fade Masks for Nav Bar & Player Bar */
                    ytmusic-app-layout > #content {
                        position: fixed !important;
                        top: 0 !important;
                        left: 72px !important;
                        right: 0 !important;
                        bottom: 0 !important;
                        height: 100vh !important;
                        overflow-y: auto !important;
                        overflow-x: hidden !important;
                        padding-top: 64px !important;
                        padding-bottom: 92px !important;
                        box-sizing: border-box !important;
                        background: transparent !important;
                        background-color: transparent !important;
                        -webkit-mask-image: linear-gradient(to bottom, transparent 0px, transparent 60px, black 76px, black calc(100% - 92px), transparent calc(100% - 76px), transparent 100%) !important;
                        mask-image: linear-gradient(to bottom, transparent 0px, transparent 60px, black 76px, black calc(100% - 92px), transparent calc(100% - 76px), transparent 100%) !important;
                    }
                    #browse-page, ytmusic-search-page {
                    padding-top: 8px !important;
                    margin-top: 0 !important;
                    }
                    ytmusic-app,
                    ytmusic-app-layout,
                    #layout,
                    #content,
                    #browse-page,
                    ytmusic-browse-response,
                    #background-gradient,
                    .background-gradient,
                    .gradient-container,
                    ytmusic-section-list-renderer,
                    #contents.ytmusic-section-list-renderer,
                    ytmusic-carousel-shelf-renderer,
                    ytmusic-shelf-renderer,
                    ytmusic-grid-renderer,
                    ytmusic-tabbed-search-results-renderer,
                    ytmusic-search-page,
                    ytmusic-nav-bar,
                    .center-content.ytmusic-nav-bar,
                    .left-content.ytmusic-nav-bar,
                    .right-content.ytmusic-nav-bar,
                    #guide,
                    #guide-wrapper,
                    #mini-guide,
                    #mini-guide-background,
                    ytmusic-guide-renderer,
                    #guide-content,
                    ytmusic-guide-section-renderer,
                    tp-yt-app-drawer,
                    #contentContainer.tp-yt-app-drawer,
                    ytmusic-chip-cloud-renderer,
                    #chips.ytmusic-chip-cloud-renderer,
                    ytmusic-header-renderer,
                    ytmusic-immersive-header-renderer,
                    ytmusic-visual-header-renderer,
                    ytmusic-detail-header-renderer,
                    ytmusic-carousel-shelf-basic-header-renderer,
                    ytmusic-two-row-item-renderer,
                    ytmusic-responsive-list-item-renderer,
                    ytmusic-player-page,
                    #player-page,
                    .content.ytmusic-player-page,
                    #main-panel,
                    .side-panel.ytmusic-player-page,
                    ytmusic-tab-renderer,
                    ytmusic-player-queue,
                    ytmusic-search-box,
                    .search-container.ytmusic-search-box,
                    #suggestion-list.ytmusic-search-box,
                    ytmusic-search-suggestions-section,
                    ytmusic-search-suggestion,
                    tp-yt-paper-listbox,
                    ytmusic-menu-popup-renderer {
                        background: transparent !important;
                        background-color: transparent !important;
                        background-image: none !important;
                        box-shadow: none !important;
                        border: none !important;
                    }
                    ytmusic-app-layout::before, ytmusic-app-layout::after,
                    ytmusic-browse-response::before, ytmusic-browse-response::after,
                    ytmusic-section-list-renderer::before, ytmusic-section-list-renderer::after,
                    ytmusic-immersive-header-renderer::before, ytmusic-immersive-header-renderer::after,
                    #browse-page::before, #browse-page::after,
                    #content::before, #content::after {
                    background: transparent !important;
                    background-color: transparent !important;
                    background-image: none !important;
                    box-shadow: none !important;
                    content: none !important;
                    }
                    #background.ytmusic-app-layout,
                    #nav-bar-background,
                    #nav-bar-divider,
                    #player-bar-background,
                    ytmusic-fullbleed-thumbnail-renderer,
                    #background-gradient.ytmusic-browse-response {
                    display: none !important;
                    }
                    /* Player Bar & Search Box -> Edgeless Translucent Accent Glass */
                    ytmusic-player-bar {
                        background-color: rgba(var(--plasma-accent-rgb), 0.08) !important;
                        background-image: none !important;
                        border-radius: 20px !important;
                        margin: 0 12px 10px 12px !important;
                        width: calc(100% - 24px) !important;
                        box-sizing: border-box !important;
                        box-shadow: none !important;
                        border: none !important;
                    }
                    .search-box.ytmusic-search-box {
                        background-color: rgba(var(--plasma-accent-rgb), 0.08) !important;
                        background-image: none !important;
                        border-radius: 24px !important;
                        border: none !important;
                        box-shadow: none !important;
                    }
                    /* Guide Active Entry, New Playlist Button & Filter Chips */
                    tp-yt-paper-item.ytmusic-guide-entry-renderer {
                        background-color: transparent !important;
                        background-image: none !important;
                        border-radius: 12px !important;
                    }
                    ytmusic-guide-entry-renderer[active] tp-yt-paper-item,
                    tp-yt-paper-item.ytmusic-guide-entry-renderer:hover,
                    button.ytSpecButtonShapeNextHost {
                        background-color: rgba(var(--plasma-accent-rgb), 0.16) !important;
                        background-image: none !important;
                    }
                    a.ytmusic-chip-cloud-chip-renderer {
                        background-color: rgba(var(--plasma-secondary-rgb), 0.16) !important;
                        background-image: none !important;
                        border-radius: 8px !important;
                    }
                    ytmusic-chip-cloud-chip-renderer[is-selected] a.ytmusic-chip-cloud-chip-renderer,
                    a.ytmusic-chip-cloud-chip-renderer:hover {
                        background-color: rgba(var(--plasma-accent-rgb), 0.22) !important;
                        background-image: none !important;
                    }
                    /* Progress Bar -> Plasma Accent & Alert */
                    #primaryProgress.tp-yt-paper-progress {
                    background-color: var(--plasma-accent) !important;
                    background-image: linear-gradient(90deg, var(--plasma-accent) 80%, var(--plasma-alert) 100%) !important;
                    }
                    .slider-knob-inner.tp-yt-paper-slider {
                        background-color: var(--plasma-accent) !important;
                        border-color: var(--plasma-accent) !important;
                    }
                    `;
                    const js = `
                    (function() {
                        let style = document.getElementById('plasma-ytm-style');
                        if (!style) {
                            style = document.createElement('style');
                            style.id = 'plasma-ytm-style';
                            document.head.appendChild(style);
                        }
                        style.textContent = ${JSON.stringify(css)};

                        let rafId = null;
                        function updateYtmCutouts() {
                            rafId = null;
                            const layout = document.querySelector('ytmusic-app-layout');
                            if (!layout) return;

                            const overlays = Array.from(document.querySelectorAll(
                                'ytmusic-search-box[opened] #suggestion-list, ytmusic-popup-container tp-yt-iron-dropdown:not([aria-hidden="true"]), ytmusic-player-page[open]'
                            )).filter(el => {
                                const s = window.getComputedStyle(el);
                                if (s.display === 'none' || s.visibility === 'hidden' || s.opacity === '0') return false;
                                const r = el.getBoundingClientRect();
                                return r.width > 15 && r.height > 15;
                            });

                            const browsePage = document.querySelector('#browse-page, ytmusic-search-page');
                            if (browsePage) {
                                const br = browsePage.getBoundingClientRect();
                                if (overlays.length > 0 && br.width > 50 && br.height > 50) {
                                    let rects = '';
                                    overlays.forEach(el => {
                                        const r = el.getBoundingClientRect();
                                        const rad = parseFloat(window.getComputedStyle(el).borderRadius) || 12;
                                        const x = r.left - br.left - 4;
                                        const y = r.top - br.top - 4;
                                        rects += \`<rect x="\${x}" y="\${y}" width="\${r.width + 8}" height="\${r.height + 8}" rx="\${rad}" ry="\${rad}" fill="black"/>\`;
                                    });
                                    const svg = \`<svg xmlns="http://www.w3.org/2000/svg" width="\${Math.max(1, br.width)}" height="\${Math.max(1, br.height)}"><defs><mask id="ym"><rect width="100%" height="100%" fill="white"/>\${rects}</mask></defs><rect width="100%" height="100%" fill="black" mask="url(#ym)"/></svg>\`;
                                    const url = \`url("data:image/svg+xml;utf8,\${encodeURIComponent(svg)}")\`;
                                    browsePage.style.setProperty('-webkit-mask-image', url, 'important');
                                    browsePage.style.setProperty('mask-image', url, 'important');
                                } else {
                                    browsePage.style.removeProperty('-webkit-mask-image');
                                    browsePage.style.removeProperty('mask-image');
                                }
                            }
                        }

                        function scheduleYtmUpdate() {
                            if (!rafId) rafId = requestAnimationFrame(updateYtmCutouts);
                        }
                        updateYtmCutouts();
                        if (!window._ytmPlasmaObserver) {
                            window._ytmPlasmaObserver = new MutationObserver(scheduleYtmUpdate);
                            window._ytmPlasmaObserver.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ['opened', 'open', 'aria-hidden', 'style', 'class'] });
                            window.addEventListener('resize', scheduleYtmUpdate);
                            window.addEventListener('scroll', scheduleYtmUpdate, true);
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
