function initMonitor(side)
    local monitor = peripheral.wrap(side)
    monitor.clear()
    resetCursor(monitor)

    return monitor
end

function resetCursor(monitor)
    local _, currentY = monitor.getCursorPos()
    local _, monitorHeight = monitor.getSize()

    local newY = currentY + 1

    if (newY >= monitorHeight) then
        newY = monitorHeight
        monitor.scroll(1)
    end

    monitor.setCursorPos(1, newY)
end

function writeLine(monitor, line)
    local monitorWidth, _ = monitor.getSize()

    if (string.len(line) > monitorWidth) then
        --Break the string
    else
        monitor.write(line)
        resetCursor(monitor)
    end
end