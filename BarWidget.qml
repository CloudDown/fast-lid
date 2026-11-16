import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "clouddown.fast-lid"

  readonly property var hold: bar && bar.shell && bar.shell.serviceFor
    ? bar.shell.serviceFor("clouddown.fast-lid")
    : null

  readonly property bool held: hold ? hold.held === true : false

  // Other bar widgets read this instead of bar.foreground: on a transparent
  // bar it is the black or white the bar computed against the wallpaper.
  readonly property color ink: bar ? bar.barForeground : Commons.Color.foreground

  property bool panelOpen: false
  readonly property var hoverSlot: {
    var item = root.parent
    while (item) {
      if ("activeItem" in item && item.activeItem === root && "hovered" in item)
        return item
      item = item.parent
    }
    return null
  }

  function updateHoverClose() {
    if (!panelOpen || (hoverSlot ? hoverSlot.hovered : button.tooltipHovered) || panel.containsMouse)
      hoverCloseTimer.stop()
    else
      hoverCloseTimer.restart()
  }

  function durationLabel(step) {
    if (step <= 0) return "OFF"
    if (step >= 33) return "ON"
    var minutes = step * 15
    var hours = Math.floor(minutes / 60)
    var remainder = minutes % 60
    return (hours ? hours + " h" : "") + (remainder ? (hours ? " " : "") + remainder + " min" : "")
  }

  function countdownLabel(seconds) {
    var hours = Math.floor(seconds / 3600)
    var minutes = Math.floor(seconds % 3600 / 60)
    var secs = seconds % 60
    return (hours ? hours + "h " : "") + minutes + " min " + secs + " sec"
  }

  function close() {
    hoverCloseTimer.stop()
    panelOpen = false
  }

  Timer {
    id: hoverCloseTimer
    interval: 250
    onTriggered: root.close()
  }

  Connections {
    target: root.hoverSlot
    ignoreUnknownSignals: true
    function onHoveredChanged() { root.updateHoverClose() }
  }

  Connections {
    target: root.hold
    function onLastErrorChanged() {
      if (root.hold.lastError) {
        root.close()
      }
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    onTooltipHoveredChanged: if (!root.hoverSlot) root.updateHoverClose()
    iconComponent: Component {
      Item {
        width: 16
        height: 16

        // An open laptop drawn to match the bar's line weight: a rounded
        // screen over a slimmer, solid base. Custom geometry stays crisp at
        // bar size and avoids font glyphs that change shape between themes.
        Rectangle {
          x: 3.05
          y: 1.15
          width: 9.9
          height: 8.25
          radius: 1.1
          color: "transparent"
          border.width: 1.25
          border.color: root.ink
        }

        Rectangle {
          x: 0.85
          y: 10.35
          width: 14.3
          height: 1.7
          radius: 0.85
          color: root.ink
        }

        // The only difference between held and off: a slash in the same ink
        // laid over the same laptop.
        Rectangle {
          visible: !root.held
          anchors.centerIn: parent
          width: 13.4
          height: 1.25
          radius: height / 2
          rotation: -45
          color: root.ink
        }
      }
    }
    onPressed: function(buttonCode) {
      if (!root.hold) return
      if (buttonCode === Qt.RightButton) {
        root.hold.toggle()
        root.panelOpen = true
      } else if (buttonCode === Qt.LeftButton) {
        root.hold.updateCountdown()
        root.panelOpen = !root.panelOpen
      }
    }
  }

  PopupCard {
    id: panel
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.panelOpen
    onContainsMouseChanged: root.updateHoverClose()
    contentWidth: fittedContentWidth(Style.space(280))
    contentHeight: fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      width: parent.width
      spacing: Style.space(8)

      Text {
        id: label
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
        text: slider.dragging ? root.durationLabel(slider.liveValue)
          : root.hold && root.hold.expiresAt > 0 ? root.countdownLabel(root.hold.remainingSeconds)
          : root.durationLabel(slider.value)
        color: Commons.Color.popups.text
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Math.round(Style.font.body * 1.25)
        font.bold: true
      }

      PanelSlider {
        id: slider
        width: parent.width
        bar: root.bar
        minimum: 0
        maximum: 33
        step: 1
        integer: true
        value: root.hold ? root.hold.durationStep : 0
        onReleased: function(v) { if (root.hold) root.hold.setDuration(v) }
      }
    }
  }
}
