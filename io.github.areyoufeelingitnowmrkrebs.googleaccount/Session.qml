pragma Singleton
import QtQuick
import QtWebEngine

QtObject {
    readonly property WebEngineProfile profile: WebEngineProfile {
        storageName: "Google"
        offTheRecord: false
        isPushServiceEnabled: true
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
    }
}
