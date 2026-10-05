import QtQuick

Mascot {
    resourceRoot: "qrc:/assets/pip/"
    implicitWidth: 192
    implicitHeight: 208
    floatMotion: false
    frameSmooth: true
    // Sixteen genuine poses per action. Finite playback remains in Mascot.
    occasionalAnimations: []
    animations: ({
        "idle": { frames: 16, directory: "idle", durations: [160, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 300] },
        "working": { frames: 16, directory: "running", durations: [150, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 220] },
        "thinking": { frames: 16, directory: "running", durations: [150, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 220] },
        "review": { frames: 16, directory: "review", durations: [160, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 260] },
        "waiting": { frames: 16, directory: "waiting", durations: [160, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 260] },
        "completed": { frames: 16, directory: "jumping", durations: [140, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 260] },
        "failed": { frames: 16, directory: "failed", durations: [140, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 300] },
        "happy": { frames: 16, directory: "jumping", durations: [140, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 260] },
        "warning": { frames: 16, directory: "waiting", durations: [160, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 260] },
        "critical": { frames: 16, directory: "failed", durations: [140, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 300] },
        "waving": { frames: 16, directory: "waving", durations: [130, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 300] },
        "running-right": { frames: 16, directory: "running-right", durations: [100, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 140] },
        "running-left": { frames: 16, directory: "running-left", durations: [100, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 140] }
    })
}
