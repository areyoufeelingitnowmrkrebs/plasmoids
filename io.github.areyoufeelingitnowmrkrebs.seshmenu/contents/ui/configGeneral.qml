import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes
Kirigami.FormLayout {
    id: root
    property string cfg_icon
    wideMode: true
    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: " "
        Layout.preferredHeight: Kirigami.Units.gridUnit
    }
    RowLayout {
        Kirigami.FormData.label: "Icon:"
        spacing: Kirigami.Units.smallSpacing
        QQC2.Button {
            id: iconButton
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
            icon.width: Kirigami.Units.iconSizes.huge
            icon.height: Kirigami.Units.iconSizes.huge
            icon.name: cfg_icon || "plasmashell"
            display: QQC2.AbstractButton.IconOnly
            onClicked: iconDialog.open()
            KIconThemes.IconDialog {
                id: iconDialog
                onIconNameChanged: cfg_icon = iconName
            }
        }
        QQC2.ToolButton {
            icon.name: "edit-clear"
            onClicked: cfg_icon = "plasmashell"
            Layout.alignment: Qt.AlignVCenter
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: "Reset to default"
        }
    }
}
