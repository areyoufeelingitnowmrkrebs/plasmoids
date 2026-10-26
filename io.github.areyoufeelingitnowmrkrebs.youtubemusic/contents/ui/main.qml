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
                function injectThemeCss() {
                    const css = `
                    :root, html, body {
                        --ytmusic-background: transparent !important;
                        --ytmusic-general-background-a: transparent !important;
                        --ytmusic-general-background-b: transparent !important;
                        --ytmusic-general-background-c: transparent !important;
                        --ytmusic-nav-bar: transparent !important;
                        --ytmusic-player-bar-background: transparent !important;
                        --yt-spec-base-background: transparent !important;
                        --yt-spec-general-background-a: transparent !important;
                        --yt-spec-general-background-b: transparent !important;
                        --yt-spec-raised-background: transparent !important;
                        --yt-spec-menu-background: rgba(35, 37, 40, 0.95) !important;
                        background: transparent !important;
                        background-color: transparent !important;
                        height: 100vh !important;
                        overflow: hidden !important;
                    }
                    ytmusic-app-layout > #content {
                        position: fixed !important;
                        top: 64px !important;
                        left: 72px !important;
                        right: 0 !important;
                        bottom: 0 !important;
                        height: calc(100vh - 64px) !important;
                        overflow-y: auto !important;
                        overflow-x: hidden !important;
                        padding-top: 0 !important;
                        margin-top: 0 !important;
                        background: transparent !important;
                        background-color: transparent !important;
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
                    ytmusic-TwoRowItemRenderer {
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
                    ytmusic-player-page,
                    #player-page {
                    background: rgba(15, 15, 18, 0.90) !important;
                    }
                    .content.ytmusic-player-page,
                    #main-panel,
                    .side-panel.ytmusic-player-page,
                    ytmusic-tab-renderer,
                    ytmusic-player-queue {
                        background: transparent !important;
                    }
                    ytmusic-player-bar {
                        background: rgba(40, 42, 45, 0.92) !important;
                        border-radius: 20px !important;
                        margin: 0 12px 10px 12px !important;
                        width: calc(100% - 24px) !important;
                        box-sizing: border-box !important;
                        box-shadow: none !important;
                    }
                    ytmusic-search-box {
                        background: transparent !important;
                    }
                    .search-box.ytmusic-search-box {
                        background: rgba(40, 42, 45, 0.92) !important;
                        border-radius: 24px !important;
                        border: none !important;
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
                        function cleanYtmBackgrounds() {
                            const containers = document.querySelectorAll(
                                'ytmusic-app, ytmusic-app-layout, #layout, #content, #browse-page, ' +
                                'ytmusic-browse-response, ytmusic-section-list-renderer, #contents, ' +
                                'ytmusic-carousel-shelf-renderer, ytmusic-shelf-renderer, ytmusic-grid-renderer, ' +
                                'ytmusic-immersive-header-renderer, .background-gradient, .gradient-container, #background'
                            );
                            containers.forEach(el => {
                                el.style.setProperty('background', 'transparent', 'important');
                                el.style.setProperty('background-color', 'transparent', 'important');
                                el.style.setProperty('background-image', 'none', 'important');
                                el.style.setProperty('box-shadow', 'none', 'important');
                            });
                        }
                        cleanYtmBackgrounds();
                        if (!window._ytmPlasmaObserver) {
                            window._ytmPlasmaObserver = new MutationObserver(() => cleanYtmBackgrounds());
                            window._ytmPlasmaObserver.observe(document.body, { childList: true, subtree: true });
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
