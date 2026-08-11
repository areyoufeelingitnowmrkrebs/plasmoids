pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt.labs.platform as Platform
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

KCMUtils.SimpleKCM {
    id: appearancePage
    property alias cfg_autoFontAndSize: autoFontAndSizeRadioButton.checked
    property alias cfg_fontFamily: fontDialog.fontChosen.family
    property alias cfg_boldText: fontDialog.fontChosen.bold
    property alias cfg_italicText: fontDialog.fontChosen.italic
    property alias cfg_fontWeight: fontDialog.fontChosen.weight
    property alias cfg_fontStyleName: fontDialog.fontChosen.styleName
    property alias cfg_fontSize: fontDialog.fontChosen.pointSize
    property string cfg_timeFormat: ""
    property alias cfg_showSeconds: showSecondsCheckBox.checked
    property alias cfg_showDate: showDate.checked
    property string cfg_dateFormat: "shortDate"
    property alias cfg_customDateFormat: customDateFormat.text
    property alias cfg_use24hFormat: use24hFormat.currentIndex
    property alias cfg_dateDisplayFormat: dateDisplayFormat.currentIndex
    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Time:")
            spacing: Kirigami.Units.smallSpacing
            QQC2.ComboBox {
                id: use24hFormat
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                model: [
                    i18nc("@item:inlistbox time display option", "12-Hour"),
                    i18nc("@item:inlistbox time display option", "Use region defaults"),
                    i18nc("@item:inlistbox time display option", "24-Hour")
                ]
                onActivated: cfg_use24hFormat = currentIndex
            }
            QQC2.CheckBox {
                id: showSecondsCheckBox
                text: i18n("Show seconds")
            }
        }
        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: i18n("Date:")
            spacing: Kirigami.Units.smallSpacing
            QQC2.CheckBox {
                id: showDate
                text: i18n("Show")
            }
            QQC2.ComboBox {
                id: dateDisplayFormat
                enabled: showDate.checked
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                model: [
                    i18n("Beside time"),
                    i18n("Below time")
                ]
                onActivated: cfg_dateDisplayFormat = currentIndex
            }
        }
        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            enabled: showDate.checked
            QQC2.ComboBox {
                id: dateFormat
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                textRole: "label"
                model: [
                    {
                        label: i18nc("@item:inlistbox date display option, e.g. all numeric", "Short date"),
                        name: "shortDate",
                        formatter(d) { return Qt.formatDate(d, Qt.locale(), Locale.ShortFormat); },
                    },
                    {
                        label: i18nc("@item:inlistbox date display option", "Long date"),
                        name: "longDate",
                        formatter(d) { return Qt.formatDate(d, Qt.locale(), Locale.LongFormat); },
                    },
                    {
                        label: i18nc("@item:inlistbox date display option", "ISO date"),
                        name: "isoDate",
                        formatter(d) { return Qt.formatDate(d, Qt.ISODate); },
                    },
                    {
                        label: i18nc("@item:inlistbox custom date format", "Custom"),
                        name: "custom",
                        formatter(d) { return Qt.locale().toString(d, customDateFormat.text); },
                    },
                ]
                onActivated: cfg_dateFormat = model[currentIndex]["name"];
                Component.onCompleted: {
                    const isConfiguredDateFormat = item => item["name"] === Plasmoid.configuration.dateFormat;
                    currentIndex = model.findIndex(isConfiguredDateFormat);
                    if (currentIndex === -1) currentIndex = 0;
                }
            }
            QQC2.Label {
                id: dateExampleLabel
                Layout.fillWidth: true
                text: dateFormat.model[dateFormat.currentIndex].formatter(new Date());
                font.italic: true
                opacity: 0.7
            }
        }
        QQC2.TextField {
            id: customDateFormat
            Layout.fillWidth: true
            enabled: showDate.checked && cfg_dateFormat === "custom"
            placeholderText: i18n("Enter custom format...")
        }
        Item { Kirigami.FormData.isSection: true }
        QQC2.ButtonGroup {
            buttons: [autoFontAndSizeRadioButton, manualFontAndSizeRadioButton]
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Font:")
            spacing: Kirigami.Units.smallSpacing
            QQC2.RadioButton {
                id: autoFontAndSizeRadioButton
                text: i18nc("@option:radio", "Automatic")
            }
            Item { width: Kirigami.Units.largeSpacing }
            QQC2.RadioButton {
                id: manualFontAndSizeRadioButton
                text: i18nc("@option:radio", "Manual")
                checked: !cfg_autoFontAndSize
                onClicked: {
                    if (cfg_fontFamily === "") {
                        fontDialog.fontChosen = Kirigami.Theme.defaultFont
                    }
                }
            }
        }
        RowLayout {
            visible: manualFontAndSizeRadioButton.checked
            spacing: Kirigami.Units.smallSpacing
            QQC2.Button {
                text: i18nc("@action:button", "Choose Style…")
                icon.name: "settings-configure"
                onClicked: {
                    fontDialog.currentFont = fontDialog.fontChosen
                    fontDialog.open()
                }
            }
            QQC2.Label {
                text: i18nc("@info %1 is the font size, %2 is the font family", "%1pt %2", cfg_fontSize, fontDialog.fontChosen.family)
                font: fontDialog.fontChosen
            }
        }
    }
    Platform.FontDialog {
        id: fontDialog
        title: i18nc("@title:window", "Choose a Font")
        modality: Qt.WindowModal
        parentWindow: appearancePage.Window.window
        property font fontChosen: null
        onAccepted: fontChosen = font
    }
}
