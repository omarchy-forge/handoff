import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Ui
import "services"

Panel {
  id: root
  moduleName: "omaforge.handoff"
  ipcTarget: "omaforge.handoff"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: bar ? bar.accent : Color.accent
  readonly property color brandOrange: "#ff5a00"
  readonly property color brandCyan: "#52e7f0"
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property url brandIcon: Qt.resolvedUrl("images/omaforge-app-icon.png")
  readonly property var project: handoff.selectedProject
  readonly property bool showDirtyIndicator:
    !settings || settings.showDirtyIndicator !== false
  property Item forgeScreenshotTarget: content

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    handoff.refreshAll()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }
  onProjectChanged: if (!noteArea.activeFocus)
    noteArea.text = project ? project.note : ""

  DataService { id: handoff; settings: root.settings }
  Connections {
    target: handoff
    function onPinAccepted() { pathField.text = "" }
  }
  Process { id: terminalProcess }

  function openProject() {
    if (!project || terminalProcess.running) return
    terminalProcess.command = ["xdg-terminal-exec", "--dir=" + project.path]
    terminalProcess.running = true
    root.close()
  }
  function setDemoState(state) { return handoff.setDemoState(state) }
  function refresh() { handoff.refreshAll() }
  function forgeTestPin(path) { handoff.pin(path) }
  readonly property int forgeTestProjectCount: handoff.projects.length
  readonly property string forgeTestState: handoff.state

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { handoff.refreshAll() }
    function setDemoState(state: string): string { return root.setDemoState(state) }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.opened
    tooltipText: handoff.statusLabel
    iconComponent: Component {
      Image {
        source: root.brandIcon
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton || buttonCode === Qt.MiddleButton) handoff.refreshAll()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: popout
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: popout.fittedContentWidth(Style.space(500))
    contentHeight: popout.fittedContentHeight(Math.min(content.implicitHeight, Style.space(700)))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: pathField.activeFocus || noteArea.activeFocus
      onCloseRequested: root.close()
      onActivateRequested: if (root.project) root.openProject()
      onTextKey: function(text) {
        if (text === "r" || text === "R") handoff.refreshAll()
      }

      Shortcut {
        sequence: StandardKey.Save
        enabled: root.opened && root.project !== null
        onActivated: handoff.saveNote(noteArea.text)
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: content
          width: panelFlick.width
          spacing: Style.space(14)

          Item {
            width: parent.width
            implicitHeight: Style.space(42)

            Image {
              id: headerLogo
              source: root.brandIcon
              width: Style.space(42)
              height: Style.space(42)
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              fillMode: Image.PreserveAspectFit
              smooth: true
              mipmap: true
            }

            Column {
              anchors.left: headerLogo.right
              anchors.leftMargin: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              spacing: 0

              Text {
                text: "OMAFORGE"
                color: root.brandOrange
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: Style.space(1)
              }
              Text {
                text: "Handoff"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }
            }

            Text {
              id: pinnedCount
              anchors.right: closeButton.left
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              text: handoff.projects.length === 1 ? "1 project  ●"
                : handoff.projects.length + " projects  ●"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
            Text {
              id: closeButton
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: "×"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          Text {
            width: parent.width
            text: "Add a Git project to remember its branch, changes, latest commit, and what to do next."
            color: Qt.darker(root.foreground, 1.25)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }

          Text {
            visible: handoff.state === "loading"
            width: parent.width
            text: "Loading saved projects…"
            color: Qt.darker(root.foreground, 1.35)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            visible: handoff.state === "empty"
            width: parent.width
            text: "No saved projects yet."
            color: Qt.darker(root.foreground, 1.35)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
          Text {
            visible: handoff.state === "error"
            width: parent.width
            text: handoff.lastError
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            text: "ADD A GIT PROJECT"
            color: Qt.darker(root.foreground, 1.25)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.letterSpacing: Style.space(0.6)
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            TextField {
              id: pathField
              width: parent.width - pinButton.width - parent.spacing
              placeholderText: "~/Code/project"
              foreground: root.foreground
              accent: root.brandOrange
              font.family: root.fontFamily
              Keys.onReturnPressed: pinButton.clicked()
            }
            Button {
              id: pinButton
              text: handoff.validating ? "Checking…" : "Add project"
              enabled: !handoff.validating
              opacity: enabled ? 1 : 0.65
              foreground: root.foreground
              accent: root.brandOrange
              active: true
              fontFamily: root.fontFamily
              horizontalPadding: Style.space(18)
              onClicked: {
                handoff.pin(pathField.text)
              }
            }
          }

          Text {
            width: parent.width
            text: handoff.notice !== "" ? handoff.notice : "Local only • nothing leaves your machine"
            color: Qt.darker(root.foreground, 1.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Text {
            visible: handoff.projects.length > 0
            width: parent.width
            text: "SAVED PROJECTS"
            color: Qt.darker(root.foreground, 1.35)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.letterSpacing: Style.space(0.6)
          }

          Repeater {
            model: handoff.projects
            delegate: Rectangle {
              required property int index
              required property var modelData
              width: content.width
              implicitHeight: projectRow.implicitHeight + Style.space(18)
              radius: Style.cornerRadius
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.025)
              border.width: Style.normalBorderWidth
              border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b,
                index === handoff.selectedIndex ? 0.28 : 0.16)

              Rectangle {
                visible: index === handoff.selectedIndex
                width: Style.space(2)
                radius: width
                color: root.brandOrange
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
              }

              RowLayout {
                id: projectRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.space(10)
                spacing: Style.space(10)

                Rectangle {
                  Layout.preferredWidth: Style.space(9)
                  Layout.preferredHeight: Style.space(9)
                  radius: width / 2
                  color: modelData.branch === "unavailable" ? Color.urgent : root.accent
                }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: Style.space(2)
                  Text {
                    Layout.fillWidth: true
                    text: modelData.name
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.subtitle
                    font.bold: true
                    elide: Text.ElideRight
                  }
                  RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(8)
                    Text {
                      Layout.fillWidth: true
                      text: (modelData.branch || "Git state unavailable") + (modelData.dirty ? "*" : "")
                      color: root.brandCyan
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      elide: Text.ElideRight
                    }
                    Text {
                      visible: root.showDirtyIndicator
                      text: modelData.dirty ? "Uncommitted changes" : "Clean"
                      color: modelData.dirty ? root.brandOrange : root.accent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                    }
                  }
                }
                Text {
                  text: "›"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.display
                }
              }

              TapHandler { onTapped: handoff.select(index) }
              HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
          }

          Column {
            visible: root.project !== null
            width: parent.width
            spacing: Style.space(10)

            Rectangle {
              width: parent.width
              implicitHeight: detailColumn.implicitHeight + Style.space(20)
              radius: Style.cornerRadius
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.025)
              border.width: Style.normalBorderWidth
              border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)

              Column {
                id: detailColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.space(11)
                spacing: Style.space(8)

                RowLayout {
                  width: parent.width
                  Text {
                    Layout.fillWidth: true
                    text: root.project ? root.project.name : ""
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.subtitle
                    font.bold: true
                    elide: Text.ElideRight
                  }
                  Rectangle {
                    implicitWidth: branchLabel.implicitWidth + Style.space(14)
                    implicitHeight: branchLabel.implicitHeight + Style.space(8)
                    radius: Style.cornerRadius
                    color: "transparent"
                    border.width: Style.normalBorderWidth
                    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)
                    Text {
                      id: branchLabel
                      anchors.centerIn: parent
                      text: root.project ? root.project.branch : ""
                      color: root.brandCyan
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                    }
                  }
                }
                Text {
                  text: "LATEST COMMIT"
                  color: Qt.darker(root.foreground, 1.4)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.letterSpacing: Style.space(0.5)
                }
                Text {
                  width: parent.width
                  text: root.project && root.project.commitSubject !== ""
                    ? root.project.commitSubject : "No commit recorded"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }
              }
            }

            Text {
              width: parent.width
              text: "NEXT STEP"
              color: Qt.darker(root.foreground, 1.35)
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.letterSpacing: Style.space(0.6)
            }
            Rectangle {
              width: parent.width
              implicitHeight: Math.max(Style.space(112), noteArea.contentHeight + Style.space(26))
              radius: Style.cornerRadius
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.025)
              border.width: Style.normalBorderWidth
              border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)

              TextArea {
                id: noteArea
                anchors.fill: parent
                anchors.margins: Style.space(9)
                anchors.bottomMargin: Style.space(22)
                text: root.project ? root.project.note : ""
                placeholderText: "What should happen next?"
                wrapMode: TextEdit.Wrap
                color: root.foreground
                selectionColor: root.brandOrange
                selectedTextColor: Color.background
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                background: Item {}
                onActiveFocusChanged: if (activeFocus && root.project) text = root.project.note
                onTextChanged: if (length > 500) text = text.slice(0, 500)
              }
              Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Style.space(8)
                text: noteArea.length + " / 500"
                color: Qt.darker(root.foreground, 1.5)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }

            Text {
              width: parent.width
              text: "ACTIONS"
              color: Qt.darker(root.foreground, 1.35)
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.letterSpacing: Style.space(0.6)
            }
            Row {
              width: parent.width
              spacing: Style.space(10)
              Button {
                width: (parent.width - parent.spacing * 2) / 3
                text: "Save note"
                foreground: root.foreground
                accent: root.brandOrange
                active: true
                fontFamily: root.fontFamily
                onClicked: handoff.saveNote(noteArea.text.slice(0, 500))
              }
              Button {
                width: (parent.width - parent.spacing * 2) / 3
                text: "Open terminal"
                foreground: root.foreground
                accent: root.brandOrange
                bordered: true
                fontFamily: root.fontFamily
                onClicked: root.openProject()
              }
              Button {
                width: (parent.width - parent.spacing * 2) / 3
                text: "Remove"
                foreground: Qt.darker(root.foreground, 1.35)
                fontFamily: root.fontFamily
                onClicked: handoff.removeSelected()
              }
            }
          }

          PanelSeparator { foreground: root.foreground }
          RowLayout {
            width: parent.width
            Text {
              Layout.fillWidth: true
              text: "r  Refresh"
              color: Qt.darker(root.foreground, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            Text {
              Layout.fillWidth: true
              text: "Enter  Open"
              color: Qt.darker(root.foreground, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignHCenter
            }
            Text {
              Layout.fillWidth: true
              text: "Ctrl+S  Save"
              color: Qt.darker(root.foreground, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignHCenter
            }
            Text {
              Layout.fillWidth: true
              text: "Esc  Close"
              color: Qt.darker(root.foreground, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }
  }
}
