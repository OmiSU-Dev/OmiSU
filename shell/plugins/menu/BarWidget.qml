import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "omisu.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue900"
    fontFamily: "omisu"
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omisu-shell shell toggle omisu.menu '{\"menu\":\"root\"}'")
    }
  }
}
