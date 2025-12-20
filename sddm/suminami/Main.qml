import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    color: "#16161D"

    property string fgColor: "#DCD7BA"
    property string accentColor: "#D27E99"
    property string subtleColor: "#727169"
    property string inputBg: "#1F1F28"
    property string borderColor: "#363646"
    property int selectedUser: 0
    property bool multipleUsers: userModel.count > 1

    // Wallpapers stored in theme folder (copied during install)
    property string themeDir: "/usr/share/sddm/themes/suminami"
    property var wallpapers: [
        themeDir + "/wallpapers/kanagawa.jpg",
        themeDir + "/wallpapers/kanagawa-dragon.jpg",
        themeDir + "/wallpapers/kanagawa-lotus.jpg",
        themeDir + "/wallpapers/kanagawa-blossom.jpg",
        themeDir + "/wallpapers/catppuccin-mocha.jpg",
        themeDir + "/wallpapers/catppuccin-macchiato.jpg",
        themeDir + "/wallpapers/catppuccin-frappe.jpg",
        themeDir + "/wallpapers/catppuccin-latte.jpg",
        themeDir + "/wallpapers/gruvbox-dark.jpg"
    ]

    // Random background
    Image {
        id: bgImage
        anchors.fill: parent
        source: wallpapers[Math.floor(Math.random() * wallpapers.length)]
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }

    // Dark overlay to dim the background
    Rectangle {
        anchors.fill: parent
        color: "#16161D"
        opacity: 0.85
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorMsg.text = "Login failed"
            passInput.text = ""
        }
    }

    // Clock
    Text {
        anchors { top: parent.top; right: parent.right; margins: 32 }
        color: fgColor
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 48; bold: true }
        text: Qt.formatTime(new Date(), "HH:mm")
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm")
        }
    }

    // Login form
    Column {
        anchors.centerIn: parent
        spacing: 12
        width: 280

        // User selector (only shown if multiple users)
        Rectangle {
            width: parent.width; height: 40
            color: inputBg
            border { color: userArea.containsMouse ? accentColor : borderColor; width: 1 }
            visible: multipleUsers

            Text {
                anchors { fill: parent; margins: 10 }
                text: userModel.count > 0 ? userModel.data(userModel.index(selectedUser, 0), Qt.UserRole + 1) : ""
                color: fgColor
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 10 }
                text: "▼"
                color: subtleColor
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
            }

            MouseArea {
                id: userArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: userDropdown.visible = !userDropdown.visible
            }

            // Dropdown
            Rectangle {
                id: userDropdown
                anchors { top: parent.bottom; left: parent.left; right: parent.right }
                height: Math.min(userModel.count * 36, 180)
                color: inputBg
                border { color: borderColor; width: 1 }
                visible: false
                z: 100

                ListView {
                    anchors.fill: parent
                    model: userModel
                    clip: true
                    delegate: Rectangle {
                        width: parent ? parent.width : 0
                        height: 36
                        color: delegateArea.containsMouse ? borderColor : "transparent"

                        Text {
                            anchors { fill: parent; margins: 10 }
                            text: name
                            color: fgColor
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: delegateArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                selectedUser = index
                                userDropdown.visible = false
                                passInput.focus = true
                            }
                        }
                    }
                }
            }
        }

        // Password field with lock icon
        Rectangle {
            width: parent.width; height: 48
            color: inputBg
            border { color: passInput.activeFocus ? accentColor : borderColor; width: 1 }

            // Lock icon
            Text {
                id: lockIcon
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                text: "󰌾"
                color: passInput.activeFocus ? accentColor : subtleColor
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
            }

            TextInput {
                id: passInput
                anchors {
                    left: lockIcon.right; right: parent.right
                    top: parent.top; bottom: parent.bottom
                    leftMargin: 12; rightMargin: 14
                    topMargin: 14; bottomMargin: 14
                }
                color: fgColor
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 14; bold: true }
                echoMode: TextInput.Password
                focus: true
                verticalAlignment: TextInput.AlignVCenter
                onAccepted: {
                    var username = userModel.data(userModel.index(selectedUser, 0), Qt.UserRole + 1)
                    sddm.login(username, passInput.text, 0)
                }
            }

            Text {
                anchors {
                    left: lockIcon.right; verticalCenter: parent.verticalCenter
                    leftMargin: 12
                }
                text: "Password"
                color: subtleColor
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 14; bold: true }
                visible: !passInput.text && !passInput.activeFocus
            }
        }

        Text {
            id: errorMsg
            width: parent.width
            color: "#E46876"
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            width: parent.width; height: 44
            color: loginArea.containsMouse ? borderColor : inputBg
            border { color: loginArea.containsMouse ? accentColor : borderColor; width: 1 }
            Text {
                anchors.centerIn: parent
                text: "Login"
                color: fgColor
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; bold: true }
            }
            MouseArea {
                id: loginArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    var username = userModel.data(userModel.index(selectedUser, 0), Qt.UserRole + 1)
                    sddm.login(username, passInput.text, 0)
                }
            }
        }
    }

    // Power buttons
    Row {
        anchors { bottom: parent.bottom; right: parent.right; margins: 32 }
        spacing: 20

        Text {
            text: "Suspend"
            color: ma1.containsMouse ? accentColor : subtleColor
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
            MouseArea { id: ma1; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.suspend() }
        }
        Text {
            text: "Reboot"
            color: ma2.containsMouse ? accentColor : subtleColor
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
            MouseArea { id: ma2; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.reboot() }
        }
        Text {
            text: "Shutdown"
            color: ma3.containsMouse ? accentColor : subtleColor
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
            MouseArea { id: ma3; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.powerOff() }
        }
    }
}
