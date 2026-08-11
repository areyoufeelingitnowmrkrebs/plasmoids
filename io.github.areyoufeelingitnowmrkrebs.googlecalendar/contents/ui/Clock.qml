pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

MouseArea {
    id: main
    objectName: "digital-clock-compactrepresentation"
    property var dataSource
    property date currentTime: new Date()
    property string timeFormat
    property string timeFormatWithSeconds
    readonly property var dateFormatter: {
        if (Plasmoid.configuration.dateFormat === "custom") {
            return (d) => { return Qt.locale().toString(d, Plasmoid.configuration.customDateFormat); };
        } else if (Plasmoid.configuration.dateFormat === "isoDate") {
            return (d) => { return Qt.formatDate(d, Qt.ISODate); };
        } else if (Plasmoid.configuration.dateFormat === "longDate") {
            return (d) => { return Qt.formatDate(d, Qt.locale(), Locale.LongFormat); };
        } else {
            return (d) => { return Qt.formatDate(d, Qt.locale(), Locale.ShortFormat); };
        }
    }
    property string lastDate: ""
    readonly property bool oneLineMode: {
        if (Plasmoid.configuration.dateDisplayFormat === 0) {
            return true;
        } else {
            return false;
        }
    }
    Accessible.role: Accessible.Button
    Accessible.onPressAction: clicked(null)
    Connections {
        target: Plasmoid.configuration
        function onShowDateChanged() { main.timeFormatCorrection(); }
        function onUse24hFormatChanged() { main.timeFormatCorrection(); }
    }
    function getCurrentTime(): date {
        return main.currentTime;
    }
    function pointToPixel(pointSize: int): int {
        const pixelsPerInch = Screen.pixelDensity * 25.4
        return Math.round(pointSize / 72 * pixelsPerInch)
    }
    states: [
        State {
            name: "horizontalPanel"
            when: Plasmoid.formFactor === PlasmaCore.Types.Horizontal && !main.oneLineMode
            PropertyChanges {
                target: main
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.minimumWidth: contentItem.width
                Layout.maximumWidth: Layout.minimumWidth
            }
            PropertyChanges {
                target: contentItem
                height: timeLabel.height + (Plasmoid.configuration.showDate ? 0.8 * timeLabel.height : 0)
                width: Math.max(timeLabel.width, dateLabel.paintedWidth) + Kirigami.Units.largeSpacing
            }
            PropertyChanges {
                target: labelsGrid
                rows: Plasmoid.configuration.showDate ? 2 : 1
            }
            AnchorChanges {
                target: labelsGrid
                anchors.horizontalCenter: contentItem.horizontalCenter
            }
            PropertyChanges {
                target: timeLabel
                height: sizehelper.height
                width: timeLabel.paintedWidth
                font.pixelSize: timeLabel.height
            }
            PropertyChanges {
                target: dateLabel
                height: 0.8 * timeLabel.height
                width: dateLabel.paintedWidth
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: dateLabel.height
            }
            AnchorChanges {
                target: dateLabel
                anchors.top: labelsGrid.bottom
                anchors.horizontalCenter: labelsGrid.horizontalCenter
            }
            PropertyChanges {
                target: sizehelper
                height: Math.min(Plasmoid.configuration.showDate ? main.height * 0.56 : main.height * 0.71, fontHelper.font.pixelSize)
                font.pixelSize: sizehelper.height
            }
        },
        State {
            name: "oneLineDate"
            when: Plasmoid.formFactor !== PlasmaCore.Types.Vertical && main.oneLineMode
            PropertyChanges {
                target: main
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.minimumWidth: contentItem.width
                Layout.maximumWidth: Layout.minimumWidth
            }
            PropertyChanges {
                target: contentItem
                height: sizehelper.height
                width: (dateLabel.visible ? dateLabel.width + timeMetrics.advanceWidth(" ") * 2 + separator.width : 0) + labelsGrid.width
            }
            AnchorChanges {
                target: labelsGrid
                anchors.right: contentItem.right
            }
            PropertyChanges {
                target: dateLabel
                height: timeLabel.height
                width: dateLabel.paintedWidth
                font.pixelSize: 1024
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.VerticalFit
            }
            AnchorChanges {
                target: dateLabel
                anchors.left: contentItem.left
                anchors.verticalCenter: labelsGrid.verticalCenter
            }
            PropertyChanges {
                target: timeLabel
                height: sizehelper.height
                width: timeLabel.paintedWidth
                fontSizeMode: Text.VerticalFit
            }
            PropertyChanges {
                target: sizehelper
                height: Math.min(main.height, fontHelper.contentHeight)
                fontSizeMode: Text.VerticalFit
                font.pixelSize: fontHelper.font.pixelSize
            }
        },
        State {
            name: "verticalPanel"
            when: Plasmoid.formFactor === PlasmaCore.Types.Vertical
            PropertyChanges {
                target: main
                Layout.fillHeight: false
                Layout.fillWidth: true
                Layout.maximumHeight: contentItem.height
                Layout.minimumHeight: Layout.maximumHeight
            }
            PropertyChanges {
                target: contentItem
                height: Plasmoid.configuration.showDate ? labelsGrid.height + dateLabel.contentHeight : labelsGrid.height
                width: main.width
            }
            PropertyChanges {
                target: labelsGrid
                rows: 2
            }
            PropertyChanges {
                target: timeLabel
                height: sizehelper.contentHeight
                width: main.width
                font.pixelSize: Math.min(timeLabel.height, fontHelper.font.pixelSize)
                fontSizeMode: Text.Fit
            }
            PropertyChanges {
                target: dateLabel
                width: main.width
                height: Kirigami.Units.gridUnit * 10
                fontSizeMode: Text.Fit
                verticalAlignment: Text.AlignTop
                font.pixelSize: Math.min(0.7 * timeLabel.height, Kirigami.Theme.defaultFont.pixelSize * 1.4)
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
            }
            AnchorChanges {
                target: dateLabel
                anchors.top: labelsGrid.bottom
                anchors.horizontalCenter: labelsGrid.horizontalCenter
            }
            PropertyChanges {
                target: sizehelper
                width: main.width
                fontSizeMode: Text.HorizontalFit
                font.pixelSize: fontHelper.font.pixelSize
            }
        },
        State {
            name: "other"
            when: Plasmoid.formFactor !== PlasmaCore.Types.Vertical && Plasmoid.formFactor !== PlasmaCore.Types.Horizontal
            PropertyChanges {
                target: main
                Layout.fillHeight: false
                Layout.fillWidth: false
                Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                Layout.minimumHeight: Kirigami.Units.gridUnit * 3
            }
            PropertyChanges {
                target: contentItem
                height: main.height
                width: main.width
            }
            PropertyChanges {
                target: labelsGrid
                rows: 2
            }
            PropertyChanges {
                target: timeLabel
                height: sizehelper.height
                width: main.width
                fontSizeMode: Text.Fit
            }
            PropertyChanges {
                target: dateLabel
                height: 0.7 * timeLabel.height
                font.pixelSize: 1024
                width: Math.max(timeLabel.contentWidth, Kirigami.Units.gridUnit * 3)
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 1
                wrapMode: Text.WordWrap
            }
            AnchorChanges {
                target: dateLabel
                anchors.top: labelsGrid.bottom
                anchors.horizontalCenter: labelsGrid.horizontalCenter
            }
            PropertyChanges {
                target: sizehelper
                height: {
                    if (Plasmoid.configuration.showDate) {
                        return 0.56 * main.height
                    }
                    return main.height
                }
                width: main.width
                fontSizeMode: Text.Fit
                font.pixelSize: 1024
            }
        }
    ]
    Item {
        id: contentItem
        anchors.verticalCenter: main.verticalCenter
        Grid {
            id: labelsGrid
            rows: 1
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
            flow: Grid.TopToBottom
            columnSpacing: Kirigami.Units.smallSpacing
            PlasmaComponents.Label  {
                id: timeLabel
                font {
                    family: fontHelper.font.family
                    weight: fontHelper.font.weight
                    italic: fontHelper.font.italic
                    features: { "tnum": 1 }
                    pixelSize: 1024
                }
                minimumPixelSize: 1
                text: Qt.formatTime(main.getCurrentTime(), Plasmoid.configuration.showSeconds ? main.timeFormatWithSeconds : main.timeFormat)
                textFormat: Text.PlainText
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
        Rectangle {
            id: separator
            property bool isOneLineMode: main.state == "oneLineDate"
            height: timeLabel.height * 0.8
            width: timeLabel.height / 16
            radius: width / 2
            color: Kirigami.Theme.textColor
            anchors.leftMargin: timeMetrics.advanceWidth(" ") + width / 2
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: dateLabel.right
            visible: isOneLineMode && Plasmoid.configuration.showDate
        }
        PlasmaComponents.Label {
            id: dateLabel
            visible: Plasmoid.configuration.showDate
            font.family: timeLabel.font.family
            font.weight: timeLabel.font.weight
            font.italic: timeLabel.font.italic
            font.pixelSize: 1024
            minimumPixelSize: 1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
        }
    }
    PlasmaComponents.Label {
        id: sizehelper
        font.family: timeLabel.font.family
        font.weight: timeLabel.font.weight
        font.italic: timeLabel.font.italic
        minimumPixelSize: 1
        visible: false
        textFormat: Text.PlainText
    }
    PlasmaComponents.Label {
        id: fontHelper
        height: 1024
        font.family: (Plasmoid.configuration.autoFontAndSize || Plasmoid.configuration.fontFamily.length === 0) ? Kirigami.Theme.defaultFont.family : Plasmoid.configuration.fontFamily
        font.weight: Plasmoid.configuration.autoFontAndSize ? Kirigami.Theme.defaultFont.weight : Plasmoid.configuration.fontWeight
        font.italic: Plasmoid.configuration.autoFontAndSize ? Kirigami.Theme.defaultFont.italic : Plasmoid.configuration.italicText
        font.pixelSize: Plasmoid.configuration.autoFontAndSize ? 3 * Kirigami.Theme.defaultFont.pixelSize : pointToPixel(Plasmoid.configuration.fontSize)
        fontSizeMode: Text.VerticalFit
        visible: false
        textFormat: Text.PlainText
    }
    FontMetrics {
        id: timeMetrics
        font.family: timeLabel.font.family
        font.weight: timeLabel.font.weight
        font.italic: timeLabel.font.italic
        font.pixelSize: dateLabel.contentHeight
    }
    function timeFormatCorrection(timeFormatString = Qt.locale().timeFormat(Locale.ShortFormat)) {
        const regexp = /(h+|H+)(.+)(mm)/
        const match = regexp.exec(timeFormatString);
        if (!match) {
            timeFormat = timeFormatString;
            timeFormatWithSeconds = timeFormatString;
            return;
        }
        let hours = match[1];
        const delimiter = match[2];
        const minutes = match[3];
        const seconds = "ss";
        const amPm = "AP";
        const uses24hFormatByDefault = hours.indexOf("H") !== -1;
        const force12h = Plasmoid.configuration.use24hFormat === 0;
        const force24h = Plasmoid.configuration.use24hFormat === 2;
        let result;
        if (force24h) {
            result = hours.toUpperCase() + delimiter + minutes;
        } else if (force12h) {
            result = hours.toLowerCase() + delimiter + minutes;
        } else {
            result = hours + delimiter + minutes;
        }
        let result_sec = result + delimiter + seconds;
        if (force12h || (!force24h && !uses24hFormatByDefault)) {
            result += " " + amPm;
            result_sec += " " + amPm;
        }
        timeFormat = result;
        timeFormatWithSeconds = result_sec;
        setupLabels();
    }
    function setupLabels() {
        if (Plasmoid.configuration.showDate) {
            dateLabel.text = dateFormatter(getCurrentTime());
        } else {
            dateLabel.text = "";
        }
        let maximumWidthNumber = 0;
        let maximumAdvanceWidth = 0;
        for (let i = 0; i <= 9; i++) {
            const advanceWidth = timeMetrics.advanceWidth(i);
            if (advanceWidth > maximumAdvanceWidth) {
                maximumAdvanceWidth = advanceWidth;
                maximumWidthNumber = i;
            }
        }
        const format = timeFormat.replace(/(h+|m+|s+)/g, "" + maximumWidthNumber + maximumWidthNumber);
        const date = new Date(2000, 0, 1, 1, 0, 0);
        const timeAm = Qt.formatTime(date, format);
        const advanceWidthAm = timeMetrics.advanceWidth(timeAm);
        date.setHours(13);
        const timePm = Qt.formatTime(date, format);
        const advanceWidthPm = timeMetrics.advanceWidth(timePm);
        if (advanceWidthAm > advanceWidthPm) {
            sizehelper.text = timeAm;
        } else {
            sizehelper.text = timePm;
        }
        fontHelper.text = sizehelper.text
    }
    function dateTimeChanged() {
        main.currentTime = new Date();
        let doCorrections = false;
        if (Plasmoid.configuration.showDate) {
            const currentDate = Qt.formatDateTime(getCurrentTime(), "yyyy-MM-dd");
            if (lastDate !== currentDate) {
                doCorrections = true;
                lastDate = currentDate
            }
        }
        if (doCorrections) {
            timeFormatCorrection();
        }
    }
    Component.onCompleted: {
        dateTimeChanged();
        timeFormatCorrection();
        if (dataSource) {
            dataSource.dataChanged.connect(dateTimeChanged);
        }
        dateFormatterChanged.connect(setupLabels);
        stateChanged.connect(setupLabels);
    }
}
