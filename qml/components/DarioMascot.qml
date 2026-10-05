import QtQuick

Mascot {
    resourceRoot: "qrc:/assets/dario/frames/"
    implicitWidth: 192
    implicitHeight: 208
    floatMotion: false
    frameSmooth: true
    occasionalAnimations: []
    // All 57 occupied cells from the installed atlas, preserving row order.
    // The package contains no timing metadata; use 8 fps for these sampled poses.
    animations: ({
        "idle": { frames: 6 },
        "running-right": { frames: 8 },
        "running-left": { frames: 8 },
        "waving": { frames: 4 },
        "completed": { frames: 5, directory: "jumping" },
        "happy": { frames: 5, directory: "jumping" },
        "failed": { frames: 8 },
        "critical": { frames: 8, directory: "failed" },
        "waiting": { frames: 6 },
        "warning": { frames: 6, directory: "waiting" },
        "working": { frames: 6, directory: "running" },
        "thinking": { frames: 6, directory: "running" },
        "review": { frames: 6 }
    })
}
