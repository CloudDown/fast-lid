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

  property bool feedbackOpen: false
  property string feedbackText: ""

  function close() {
    feedbackTimer.stop()
    feedbackOpen = false
  }

  Connections {
    target: root.hold
    function onLastErrorChanged() {
      if (root.hold.lastError) {
        root.close()
      }
    }
  }

  Timer {
    id: feedbackTimer
    interval: 1300
    onTriggered: root.close()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

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
      if (buttonCode === Qt.LeftButton && root.hold) {
        root.feedbackText = root.held ? "OFF" : "ON"
        root.feedbackOpen = true
        feedbackTimer.restart()
        root.hold.toggle()
      }
    }
  }

  // Passive native popout: no keyboard focus or outside-click grab for a
  // short status acknowledgement. PopupCard handles the bar edge and theme.
  PopupCard {
    id: feedback
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.feedbackOpen
    triggerMode: "hover"
    padding: Style.space(8)
    contentWidth: Style.space(62)
    contentHeight: feedback.fittedContentHeight(label.implicitHeight)

    Text {
      id: label
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: root.feedbackText
      color: Commons.Color.popups.text
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }
}
