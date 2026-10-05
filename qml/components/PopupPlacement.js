.pragma library

// All coordinates are in desktop pixels, including screens with a negative origin.
function place(anchor, popup, preferred, screen) {
    const right = screen.x + screen.width
    const bottom = screen.y + screen.height
    let x = preferred.x
    let y = preferred.y
    if (x < screen.x || x + popup.width > right)
        x = 2 * anchor.x + anchor.width - preferred.x - popup.width
    if (y < screen.y || y + popup.height > bottom)
        y = 2 * anchor.y + anchor.height - preferred.y - popup.height
    x = Math.max(screen.x, Math.min(x, right - popup.width))
    y = Math.max(screen.y, Math.min(y, bottom - popup.height))
    return {x: x, y: y, side: x + popup.width / 2 < anchor.x + anchor.width / 2 ? "left" : "right"}
}
