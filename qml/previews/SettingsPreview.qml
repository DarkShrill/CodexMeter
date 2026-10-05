import QtQuick
import ".."

SettingsWindow {
    id: root
    visible: true
    settings: previewData.settings
    client: previewData.client
    rateModel: previewData.rateModel

    FontLoader { source: "../../assets/fonts/Poppins-Regular.ttf" }
    FontLoader { source: "../../assets/fonts/Poppins-Medium.ttf" }
    FontLoader { source: "../../assets/fonts/Poppins-SemiBold.ttf" }
    FontLoader { source: "../../assets/fonts/Poppins-Bold.ttf" }
    PreviewData { id: previewData }
}
