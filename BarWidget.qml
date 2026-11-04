import QtQuick
import Quickshell
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

  property bool toastOpen: false
  property string toastText: ""
  property bool ready: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: Qt.callLater(function() { root.ready = true })

  function showStatusToast(text) {
    toastText = String(text || "")
    if (toastText === "") return
    toastOpen = true
    toastHide.restart()
  }

  // Confirm ON only after the inhibitor has stayed up a moment (same window
  // the service used to wait before notifying).
  function armOnToast() {
    onConfirm.stop()
    onConfirm.start()
  }

  Timer {
    id: toastHide
    interval: 1200
    repeat: false
    onTriggered: root.toastOpen = false
  }

  Timer {
    id: onConfirm
    interval: 700
    repeat: false
    onTriggered: {
      if (root.held)
        root.showStatusToast("ON")
    }
  }

  // IPC / other screens: mirror hold state into a toast once the widget is live.
  onHeldChanged: {
    if (!root.ready) return
    if (root.held) {
      root.armOnToast()
    } else {
      onConfirm.stop()
      root.showStatusToast("OFF")
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
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
      if (buttonCode === Qt.LeftButton && root.hold)
        root.hold.toggle()
    }
  }

  // Lightweight label under the icon — avoids PopupCard/popout coordination.
  PopupWindow {
    id: toast
    visible: root.toastOpen
    color: "transparent"
    implicitWidth: Math.ceil(bubble.implicitWidth)
    implicitHeight: Math.ceil(bubble.implicitHeight)

    anchor {
      id: toastAnchor
      window: root.QsWindow ? root.QsWindow.window : null
      adjustment: PopupAdjustment.Slide
      edges: Edges.Top | Edges.Left
      gravity: Edges.Bottom | Edges.Right
      rect.width: 1
      rect.height: 1

      onAnchoring: {
        var win = root.QsWindow ? root.QsWindow.window : null
        if (!win || !win.contentItem) return

        var popupWidth = toast.implicitWidth
        var popupHeight = toast.implicitHeight
        var localX = root.width / 2 - popupWidth / 2
        var localY = root.height + 6
        var position = root.bar ? root.bar.position : "top"

        if (position === "bottom") {
          localY = -popupHeight - 6
        } else if (position === "left") {
          localX = root.width + 6
          localY = root.height / 2 - popupHeight / 2
        } else if (position === "right") {
          localX = -popupWidth - 6
          localY = root.height / 2 - popupHeight / 2
        }

        var point = win.contentItem.mapFromItem(root, localX, localY)
        toastAnchor.rect.x = Math.round(point.x)
        toastAnchor.rect.y = Math.round(point.y)
      }
    }

    BorderSurface {
      id: bubble
      implicitWidth: toastLabel.implicitWidth + Style.space(12)
      implicitHeight: toastLabel.implicitHeight + Style.space(8)
      color: Commons.Color.tooltip.background
      borderSpec: Border.surfaceSpec("tooltip", "border", Commons.Color.tooltip.border, 1)
      radius: Style.cornerRadius

      Text {
        id: toastLabel
        textFormat: Text.PlainText
        anchors.centerIn: parent
        text: root.toastText
        color: Commons.Color.tooltip.text
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }
  }
}
