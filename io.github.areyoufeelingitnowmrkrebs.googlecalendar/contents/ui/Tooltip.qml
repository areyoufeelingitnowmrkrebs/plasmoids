import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: root
    implicitWidth: Kirigami.Units.gridUnit * 18
    implicitHeight: layout.implicitHeight + Kirigami.Units.gridUnit
    property var dateTime: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.dateTime = new Date()
    }
    GridLayout {
        id: layout
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.largeSpacing * 2)
        columns: 2
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.smallSpacing
        PlasmaComponents.Label {
            text: "YEAR"
            font.family: "Monospace"
            font.weight: Font.Bold
            opacity: 0.8
            Layout.alignment: Qt.AlignRight
        }
        PlasmaComponents.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 1.5
            from: 0
            to: 100
            value: {
                var now = root.dateTime
                var start = new Date(now.getFullYear(), 0, 1);
                var diff = now - start;
                var oneDay = 1000 * 60 * 60 * 24;
                var daysPassed = diff / oneDay;
                var isLeap = ((now.getFullYear() % 4 === 0) && (now.getFullYear() % 100 !== 0)) || (now.getFullYear() % 400 === 0);
                var daysInYear = isLeap ? 366 : 365;
                return (daysPassed / daysInYear) * 100
            }
        }
        PlasmaComponents.Label {
            text: "MONTH"
            font.family: "Monospace"
            font.weight: Font.Bold
            opacity: 0.8
            Layout.alignment: Qt.AlignRight
        }
        PlasmaComponents.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 1.5
            from: 0
            to: 100
            value: {
                var now = root.dateTime
                var daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
                var currentDay = now.getDate() + (now.getHours() / 24);
                return (currentDay / daysInMonth) * 100
            }
        }
        PlasmaComponents.Label {
            text: "WEEK"
            font.family: "Monospace"
            font.weight: Font.Bold
            opacity: 0.8
            Layout.alignment: Qt.AlignRight
        }
        PlasmaComponents.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 1.5
            from: 0
            to: 100
            value: {
                var now = root.dateTime
                var dayIndex = (now.getDay() + 6) % 7;
                var exactDay = dayIndex + (now.getHours() / 24);
                return (exactDay / 7) * 100
            }
        }
        PlasmaComponents.Label {
            text: "DAY"
            font.family: "Monospace"
            font.weight: Font.Bold
            opacity: 0.8
            Layout.alignment: Qt.AlignRight
        }
        PlasmaComponents.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 1.5
            from: 0
            to: 1440
            value: (root.dateTime.getHours() * 60) + root.dateTime.getMinutes()
        }
        PlasmaComponents.Label {
            text: "HOUR"
            font.family: "Monospace"
            font.weight: Font.Bold
            opacity: 0.8
            Layout.alignment: Qt.AlignRight
        }
        PlasmaComponents.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 1.5
            from: 0
            to: 60
            value: root.dateTime.getMinutes() + (root.dateTime.getSeconds() / 60)
        }
        PlasmaComponents.Label {
            text: "MINUTE"
            font.family: "Monospace"
            font.weight: Font.Bold
            opacity: 0.8
            Layout.alignment: Qt.AlignRight
        }
        PlasmaComponents.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 1.5
            from: 0
            to: 60
            value: root.dateTime.getSeconds()
        }
    }
}
