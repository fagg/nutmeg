import QtQuick 2.2
import Graphr 1.0
import "Util.js" as Util
//import "Vector.js" as Vector

FigureBase {
    objectName: "figure"
    width: parent.width
    height: parent.height

    handle: "fig"

    property int tabIndex: -1
    property var guiItem: null

    function axisAtPoint(point) {
        var axes = getAxisList()
        for (var i=0; i<axes.length; ++i) {
            var p = mapToItem(axes[i], point.x, point.y)
            if (axes[i].contains(Qt.point(p.x, p.y))) {
                return axes[i]
            }
        }
    }

    MouseArea {
        id: mouseArea
        z: 10
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.RightButton

        property var currentAxis
        property point startMouse: Qt.point(0,0)
        property rect startLimits: Qt.rect(0,0,0,0)
        property point delta: Qt.point(0,0)
        property bool dragActive: false
        property int mode: -1

        property real zoomSensitivity: 1.0

        onPressed: {
            if ((!(mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier))
                 && mouse.button == Qt.MiddleButton) || dragActive) {
                mouse.accepted = false
                return
            }
            dragActive = true
            currentAxis = axisAtPoint(mouse)

            startMouse.x = mouse.x
            startMouse.y = mouse.y

            startLimits = Util.copyRect(currentAxis.limits)
            if (mouse.modifiers & Qt.ShiftModifier) {
                mode = 1
            } else {
                mode = 0
            }
        }

        onPositionChanged: {
            if (!dragActive) return
            delta.x = mouse.x - startMouse.x
            delta.y = mouse.y - startMouse.y

            var limits = Util.copyRect(currentAxis.limits)

            // TODO: Add xScale and yScale props to Axis{}
            var xScale = (currentAxis.maxX - currentAxis.minX) / currentAxis.plotRect.width
            var yScale = (currentAxis.maxY - currentAxis.minY) / currentAxis.plotRect.height

            if (mode == 0) {
                limits.x = startLimits.x - xScale*delta.x
                limits.y = startLimits.y + yScale*delta.y
            } else if (mode == 1) {
                var sx = Math.pow(10, delta.x*0.005*zoomSensitivity)
                var sy = Math.pow(10, delta.y*0.005*zoomSensitivity)
                console.log("Scale", sx, sy)
                var dw = sx*startLimits.width
                var dh = sy*startLimits.height

                var tx = (startMouse.x - currentAxis.plotRect.x)/currentAxis.plotRect.width
                var ty = 1 - (startMouse.y - currentAxis.plotRect.y)/currentAxis.plotRect.height

                limits.x = startLimits.x - (dw - startLimits.width)*tx
                limits.width = dw
                limits.y = startLimits.y - (dh - startLimits.height)*ty
                limits.height = dh
            }

            currentAxis.limits = limits

        }

        onReleased: {
            dragActive = false
            mode = -1
        }

        onWheel: {
            if (dragActive) return
            currentAxis = axisAtPoint(wheel)
        }
    }

    MultiPointPinchArea {
        id: touchArea
        z: 10
        anchors.fill: parent
        mouseEnabled: false
        areaEnabled: !mouseArea.dragActive
        property real panSensitivity: 3.0
        property real scaleLimit: 0.1
        property real startWidth
        property real startHeight
        property real minVel: 1/1000 // pxl/ms
        property real minInitVel: 100.0/1000 // pxl/ms
        property real maxVel: 1000.0/1000 // pxl/ms
        property real damping: 5

        property var currentAxis: null

        onPressed: {
            mrTimer.stopTimer()
        }

        onPinchStarted: {
            currentAxis = axisAtPoint(touchArea.p1)

            startWidth = currentAxis.maxX - currentAxis.minX
            startHeight = currentAxis.maxY - currentAxis.minY
        }

        onPinchUpdated: {
            var dx = pinch.center.x - pinch.previousCenter.x
            var dy = pinch.center.y - pinch.previousCenter.y

            var xScale = (currentAxis.maxX - currentAxis.minX) / currentAxis.plotRect.width
            var yScale = (currentAxis.maxY - currentAxis.minY) / currentAxis.plotRect.height
            dx *= xScale*panSensitivity // TODO: Acceleration goes here
            dy *= yScale*panSensitivity

            var newLimits = Qt.rect(currentAxis.limits.x - dx, currentAxis.limits.y + dy,
                                    currentAxis.limits.width, currentAxis.limits.height)

            var pinchCenter = mapToItem(currentAxis, touchArea.p1.x, touchArea.p1.y)

            // If there is ZOOMING happening
            if (pinch.pinchMode == mode.pinchPan || pinch.pinchMode == mode.pinchXpan) {
                var scale = Math.max( Math.min(1/pinch.scaleX, 1/scaleLimit), scaleLimit )
                var dw = scale * startWidth
                var w = currentAxis.maxX - currentAxis.minX
                var t = pinchCenter.x/currentAxis.plotRect.width

                newLimits.x -= (dw - w)*t
                newLimits.width = dw
            }
            if (pinch.pinchMode == mode.pinchPan || pinch.pinchMode == mode.pinchYpan) {
                var scale = Math.max( Math.min(1/pinch.scaleY, 1/scaleLimit), scaleLimit )
                var dh = scale * startHeight
                var h = currentAxis.maxY - currentAxis.minY
                var t = 1 - pinchCenter.y/currentAxis.plotRect.height

                newLimits.y -= (dh - h)*t
                newLimits.height = dh
            }
            currentAxis.limits = newLimits
        }

        onPinchFinished: {
            mrTimer.lastT = new Date().getTime()

            mrTimer.velX = pinch.velocity.x
            if (Math.abs(pinch.velocity.x) > maxVel)
                mrTimer.velX = Util.sign(pinch.velocity.x)*maxVel

            mrTimer.velY =pinch.velocity.y
            if (Math.abs(pinch.velocity.y) > maxVel)
                mrTimer.velY = Util.sign(pinch.velocity.y)*maxVel

            mrTimer.startTimer()
        }

        Timer {
            id: mrTimer
            property real lastT: 0
            property real velX: 0
            property real velY: 0
            repeat: true
            interval: 20
            onTriggered: {
                var ct = new Date().getTime()
                var dt = (ct - lastT)

                var vx = velX*dt
                var vy = velY*dt

                velX -= velX*touchArea.damping*dt*0.001
                velY -= velY*touchArea.damping*dt*0.001

                var currentAxis = touchArea.currentAxis
                var newLimits = Qt.rect(currentAxis.limits.x, currentAxis.limits.y,
                                        currentAxis.limits.width, currentAxis.limits.height)

                // Use "city block" instead of "euclidean" - slightly faster and simpler
                var vMax = Math.max(Math.abs(velX), Math.abs(velY));
                if (vMax < touchArea.minVel) {
                    stopTimer() // Velocity is too tiny, stop updating
                }

                var xScale = (currentAxis.maxX - currentAxis.minX) / currentAxis.plotRect.width
                var yScale = (currentAxis.maxY - currentAxis.minY) / currentAxis.plotRect.height


                var sens = touchArea.panSensitivity
                vx *= xScale*sens
                vy *= yScale*sens

                newLimits.x -= vx
                newLimits.y += vy

                currentAxis.limits = newLimits

                lastT = ct
            }

            function startTimer() {
                // Use "city block" instead of "euclidean" - slightly faster and simpler
                var lim = touchArea.currentAxis.limits
                var vMax = Math.max(Math.abs(velX)*lim.width, Math.abs(velY)*lim.height);
                if (vMax > touchArea.minInitVel)
                    start()
                else
                    stopTimer()
            }

            function stopTimer() {
                velX = 0;
                velY = 0;
                stop();
            }
        }
    }
}
