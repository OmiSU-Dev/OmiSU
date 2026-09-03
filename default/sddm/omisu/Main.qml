import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
  id: root
  width: 640
  height: 480
  color: "#1e1e2e"

  // userModel.lastUser is empty on a fresh install before anyone has logged
  // in; fall back to the first real user in the model so sddm.login never
  // fires with an empty username (which fails silently and looks dead).
  property string currentUser: {
    if (userModel.lastUser && userModel.lastUser.length > 0)
      return userModel.lastUser
    if (userModel.rowCount() > 0)
      return (userModel.data(userModel.index(0, 0), Qt.DisplayRole) || "").toString()
    return ""
  }
  property bool loginFailed: false
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1 || name.indexOf("OmiSu") !== -1)
        return i
    }
    return sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
  }

  function tryLogin() {
    if (password.text.length === 0)
      return
    sddm.login(root.currentUser, password.text, root.sessionIndex)
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.forceActiveFocus()
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: 40

    Image {
      id: logo
      source: "logo.png"
      width: Math.min(sourceSize.width, root.width * 0.8)
      height: sourceSize.width > 0 ? Math.round(width * sourceSize.height / sourceSize.width) : 0
      fillMode: Image.PreserveAspectFit
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
      visible: root.currentUser.length > 0
      text: root.currentUser
      color: "#565f89"
      font.pixelSize: 14
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 15

      Image {
        source: root.loginFailed ? "lock-failed.png" : "lock.png"
        width: 34
        height: 38
        fillMode: Image.PreserveAspectFit
        anchors.verticalCenter: parent.verticalCenter
      }

      Item {
        width: entry.width
        height: entry.height

        Image {
          id: entry
          source: root.loginFailed ? "entry-failed.png" : "entry.png"
          anchors.centerIn: parent
        }

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 20
          anchors.verticalCenter: parent.verticalCenter
          spacing: 5

          Repeater {
            model: Math.min(password.text.length, 21)

            Image {
              source: "bullet.png"
              width: 7
              height: 7
            }
          }
        }

        TextInput {
          id: password
          anchors.fill: parent
          anchors.leftMargin: 20
          anchors.rightMargin: 20
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          font.family: "Fira Code"
          font.pixelSize: 24
          font.letterSpacing: 5
          passwordCharacter: "\u2022"
          color: "transparent"
          selectionColor: "transparent"
          selectedTextColor: "transparent"
          cursorDelegate: Item {}
          focus: true

          onTextChanged: root.loginFailed = false
          onAccepted: root.tryLogin()

          Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.tryLogin()
              event.accepted = true
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: password.forceActiveFocus()
        }
      }
    }

    Text {
      visible: root.loginFailed
      text: "Login failed — try again"
      color: "#f7768e"
      font.pixelSize: 14
      anchors.horizontalCenter: parent.horizontalCenter
    }
  }

  Component.onCompleted: password.forceActiveFocus()
}
