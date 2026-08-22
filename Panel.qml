import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Commons
import qs.Ui
import "services"

Panel {
  id: root
  moduleName: "org.omarchyforge.handoff"
  ipcTarget: "org.omarchyforge.handoff"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: bar ? bar.accent : Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
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

  Process { id: terminalProcess }

  function openProject() {
    if (!project || terminalProcess.running) return
    terminalProcess.command = ["xdg-terminal-exec", "--dir=" + project.path]
    terminalProcess.running = true
    root.close()
  }
  function setDemoState(state) { return handoff.setDemoState(state) }
  function refresh() { handoff.refreshAll() }

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
    text: "󰈙"
    active: root.opened
    tooltipText: handoff.statusLabel
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
    contentWidth: popout.fittedContentWidth(Style.space(440))
    contentHeight: popout.fittedContentHeight(Math.min(content.implicitHeight, Style.space(680)))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: if (root.project) root.openProject()
      onTextKey: function(text) {
        if (text === "r" || text === "R") handoff.refreshAll()
      }

      Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight
        clip: true

        Column {
          id: content
          width: parent.width
          spacing: Style.space(12)

          PanelHero {
            width: parent.width
            title: "Handoff"
            meta: handoff.statusLabel
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text {
                text: "󰈙"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

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
            text: "No projects pinned yet. Add a Git project below to create its first handoff."
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
            text: "Pin a Git project"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            TextField {
              id: pathField
              width: parent.width - pinButton.width - parent.spacing
              placeholderText: "~/Code/project"
              foreground: root.foreground
              accent: root.accent
              font.family: root.fontFamily
              Keys.onReturnPressed: pinButton.clicked()
            }

            Button {
              id: pinButton
              text: "Pin"
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: {
                handoff.pin(pathField.text)
                pathField.text = ""
              }
            }
          }

          Text {
            visible: handoff.notice !== ""
            width: parent.width
            text: handoff.notice
            color: Qt.darker(root.foreground, 1.35)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Repeater {
            model: handoff.projects
            delegate: Rectangle {
              required property int index
              required property var modelData
              width: content.width
              implicitHeight: projectColumn.implicitHeight + Style.space(18)
              radius: Style.cornerRadius
              color: index === handoff.selectedIndex
                ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.13)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
              border.color: index === handoff.selectedIndex
                ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.1)

              Column {
                id: projectColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.space(9)
                spacing: Style.space(3)

                Text {
                  width: parent.width
                  text: modelData.name
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  width: parent.width
                  text: (modelData.branch || "Git state unavailable")
                    + (!root.showDirtyIndicator ? ""
                      : modelData.dirty ? " · uncommitted changes" : " · clean")
                  color: modelData.dirty && root.showDirtyIndicator
                    ? Color.urgent : Qt.darker(root.foreground, 1.4)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              TapHandler { onTapped: handoff.select(index) }
              HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
          }

          Column {
            visible: root.project !== null
            width: parent.width
            spacing: Style.space(8)

            PanelSeparator { foreground: root.foreground }

            Text {
              width: parent.width
              text: root.project ? root.project.name : ""
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: root.project && root.project.commitSubject !== ""
                ? root.project.commitSubject : "No commit recorded"
              color: Qt.darker(root.foreground, 1.35)
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
            }

            Rectangle {
              width: parent.width
              implicitHeight: Math.max(Style.space(100), noteArea.contentHeight + Style.space(20))
              radius: Style.cornerRadius
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
              border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

              TextArea {
                id: noteArea
                anchors.fill: parent
                anchors.margins: Style.space(8)
                text: root.project ? root.project.note : ""
                placeholderText: "What should happen next?"
                wrapMode: TextEdit.Wrap
                color: root.foreground
                selectionColor: root.accent
                selectedTextColor: Color.background
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                background: Item {}
                onActiveFocusChanged: if (activeFocus && root.project) text = root.project.note
              }
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              Button {
                width: (parent.width - parent.spacing * 2) / 3
                text: "Save note"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: handoff.saveNote(noteArea.text)
              }
              Button {
                width: (parent.width - parent.spacing * 2) / 3
                text: "Open terminal"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: root.openProject()
              }
              Button {
                width: (parent.width - parent.spacing * 2) / 3
                text: "Unpin"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: handoff.removeSelected()
              }
            }
          }

          Text {
            width: parent.width
            text: "R refreshes Git state · Enter opens the selected project · Esc closes"
            color: Qt.darker(root.foreground, 1.45)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
