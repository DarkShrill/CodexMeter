import QtQuick
UsageCard {
    property var settings: null
    cardStyle: settings ? settings.cardStyle : 1
    allLimits: true
}
