import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  visible: false

  property var settings: ({})
  property var projects: []
  property int selectedIndex: -1
  property string state: "loading"
  property string lastError: ""
  property string notice: ""
  property bool refreshing: false
  property string pendingPath: ""
  property var refreshQueue: []
  property int refreshIndex: -1
  property string statusOutput: ""
  property bool demoActive: false

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || home + "/.local/share"
  readonly property string dataDir: dataHome + "/omarchy-handoff"
  readonly property string statePath: dataDir + "/state.json"
  readonly property var selectedProject:
    selectedIndex >= 0 && selectedIndex < projects.length ? projects[selectedIndex] : null
  readonly property string statusLabel: refreshing ? "Refreshing Git state"
    : projects.length === 0 ? "No projects pinned"
    : projects.length === 1 ? "1 pinned project"
    : projects.length + " pinned projects"

  function clone(value) { return JSON.parse(JSON.stringify(value)) }

  function setDemoState(nextState) {
    var candidate = String(nextState || "")
    if (candidate !== "ready" && candidate !== "empty" && candidate !== "error") return "invalid"
    demoActive = true
    refreshing = false
    refreshQueue = []
    if (candidate === "ready") {
      projects = [normalizedProject({
        path: "/home/demo/forge",
        name: "forge",
        note: "Review the release checklist and prepare the next milestone.",
        branch: "feat/handoff",
        dirty: true,
        commit: "780abe7a3f337477391038837f42d50d72ea1712",
        commitSubject: "fix: disable automatic Node package caching",
        commitAt: "2026-08-22T12:35:00-04:00",
        checkedAt: "2026-08-22T12:36:00-04:00"
      })]
      selectedIndex = 0
      state = "ready"
      notice = "Fictional demo data; nothing was saved."
    } else {
      projects = []
      selectedIndex = -1
      state = "empty"
      notice = candidate === "error"
        ? "Fictional demo error: Git metadata could not be refreshed."
        : "Fictional empty state; nothing was saved."
    }
    return "ok"
  }

  function normalizedProject(candidate) {
    if (!candidate || typeof candidate !== "object") return null
    var path = String(candidate.path || "").trim()
    if (path === "" || path.indexOf("\n") >= 0) return null
    return {
      path: path,
      name: String(candidate.name || path.split("/").pop() || path),
      note: String(candidate.note || ""),
      branch: String(candidate.branch || ""),
      dirty: candidate.dirty === true,
      commit: String(candidate.commit || ""),
      commitSubject: String(candidate.commitSubject || ""),
      commitAt: String(candidate.commitAt || ""),
      checkedAt: String(candidate.checkedAt || ""),
      addedAt: String(candidate.addedAt || new Date().toISOString())
    }
  }

  function load(raw) {
    if (demoActive) return
    var loaded = []
    try {
      var parsed = JSON.parse(String(raw || ""))
      if (parsed && parsed.version === 1 && Array.isArray(parsed.projects)) {
        for (var i = 0; i < parsed.projects.length; i++) {
          var project = normalizedProject(parsed.projects[i])
          if (project) loaded.push(project)
        }
      }
    } catch (error) {
      lastError = "Could not read saved Handoff data. The file was left untouched."
      projects = []
      selectedIndex = -1
      state = "error"
      return
    }
    projects = loaded
    selectedIndex = loaded.length > 0 ? 0 : -1
    state = loaded.length > 0 ? "ready" : "empty"
    if (loaded.length > 0) refreshAll()
  }

  function persist() {
    if (demoActive) return
    stateFile.setText(JSON.stringify({ version: 1, projects: projects }, null, 2) + "\n")
  }

  function select(index) {
    if (index < 0 || index >= projects.length) return
    selectedIndex = index
    notice = ""
  }

  function expandHome(path) {
    var value = String(path || "").trim()
    if (value === "~") return home
    if (value.indexOf("~/") === 0) return home + value.slice(1)
    return value
  }

  function pin(path) {
    var candidate = expandHome(path)
    if (candidate === "" || candidate.indexOf("\n") >= 0) {
      notice = "Enter a project directory."
      return
    }
    if (validateProcess.running) return
    pendingPath = candidate
    notice = "Checking Git project…"
    validateProcess.output = ""
    validateProcess.command = ["git", "-C", candidate, "rev-parse", "--show-toplevel"]
    validateProcess.running = true
  }

  function acceptPinnedPath(path) {
    var canonical = String(path || "").trim()
    if (canonical === "") {
      notice = "That directory is not a readable Git project."
      return
    }
    for (var i = 0; i < projects.length; i++) {
      if (projects[i].path === canonical) {
        selectedIndex = i
        notice = "Project is already pinned."
        return
      }
    }
    var next = clone(projects)
    next.push(normalizedProject({
      path: canonical,
      name: canonical.split("/").pop(),
      addedAt: new Date().toISOString()
    }))
    projects = next
    selectedIndex = next.length - 1
    state = "ready"
    notice = "Project pinned locally."
    persist()
    refreshOne(selectedIndex)
  }

  function saveNote(note) {
    if (!selectedProject) return
    var next = clone(projects)
    next[selectedIndex].note = String(note || "")
    next[selectedIndex].checkedAt = new Date().toISOString()
    projects = next
    persist()
    notice = "Next step saved locally."
  }

  function removeSelected() {
    if (!selectedProject) return
    var next = clone(projects)
    next.splice(selectedIndex, 1)
    projects = next
    selectedIndex = next.length === 0 ? -1 : Math.min(selectedIndex, next.length - 1)
    state = next.length === 0 ? "empty" : "ready"
    notice = "Project removed from Handoff. Files were not changed."
    persist()
  }

  function refreshOne(index) {
    if (index < 0 || index >= projects.length) return
    if (refreshing) {
      refreshQueue = refreshQueue.concat([index])
      return
    }
    refreshQueue = [index]
    beginNextRefresh()
  }

  function refreshAll() {
    if (demoActive || refreshing || projects.length === 0) return
    var queue = []
    for (var i = 0; i < projects.length; i++) queue.push(i)
    refreshQueue = queue
    beginNextRefresh()
  }

  function beginNextRefresh() {
    if (refreshQueue.length === 0) {
      refreshing = false
      refreshIndex = -1
      persist()
      return
    }
    refreshing = true
    refreshIndex = refreshQueue[0]
    refreshQueue = refreshQueue.slice(1)
    statusOutput = ""
    var project = projects[refreshIndex]
    statusProcess.output = ""
    statusProcess.command = ["git", "-C", project.path, "status", "--porcelain=v2", "--branch"]
    statusProcess.running = true
  }

  function applyStatus(text) {
    statusOutput = String(text || "")
    var lines = statusOutput.split("\n")
    var branch = ""
    var dirty = false
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].indexOf("# branch.head ") === 0) branch = lines[i].slice(14).trim()
      else if (lines[i] !== "" && lines[i].charAt(0) !== "#") dirty = true
    }
    var next = clone(projects)
    next[refreshIndex].branch = branch === "(detached)" ? "detached HEAD" : branch
    next[refreshIndex].dirty = dirty
    next[refreshIndex].checkedAt = new Date().toISOString()
    projects = next
  }

  function applyLog(text) {
    var fields = String(text || "").trim().split("\u001f")
    var next = clone(projects)
    if (fields.length >= 3) {
      next[refreshIndex].commit = fields[0]
      next[refreshIndex].commitSubject = fields[1]
      next[refreshIndex].commitAt = fields[2]
    }
    next[refreshIndex].checkedAt = new Date().toISOString()
    projects = next
    beginNextRefresh()
  }

  Process {
    id: ensureDirProcess
    command: ["mkdir", "-p", root.dataDir]
    onExited: stateFile.reload()
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.load(text())
    onLoadFailed: root.load("")
    onFileChanged: reload()
  }

  Process {
    id: validateProcess
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: validateProcess.output = text
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.notice = "That directory is not a readable Git project."
      else root.acceptPinnedPath(output)
    }
  }

  Process {
    id: statusProcess
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: statusProcess.output = text
    }
    onExited: function(exitCode) {
      if (root.refreshIndex < 0 || root.refreshIndex >= root.projects.length) {
        root.refreshing = false
        root.refreshQueue = []
        return
      }
      if (exitCode !== 0) {
        var next = root.clone(root.projects)
        next[root.refreshIndex].branch = "unavailable"
        next[root.refreshIndex].dirty = false
        next[root.refreshIndex].checkedAt = new Date().toISOString()
        root.projects = next
        root.beginNextRefresh()
        return
      }
      root.applyStatus(output)
      var project = root.projects[root.refreshIndex]
      logProcess.output = ""
      logProcess.command = ["git", "-C", project.path, "log", "-1", "--format=%H%x1f%s%x1f%cI"]
      logProcess.running = true
    }
  }

  Process {
    id: logProcess
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: logProcess.output = text
    }
    onExited: function(exitCode) {
      if (root.refreshIndex < 0 || root.refreshIndex >= root.projects.length) {
        root.refreshing = false
        root.refreshQueue = []
        return
      }
      if (exitCode === 0) root.applyLog(output)
      else root.applyLog("")
    }
  }

  Component.onCompleted: ensureDirProcess.running = true
}
