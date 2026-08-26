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
  property string refreshPath: ""
  property string statusOutput: ""
  property bool demoActive: false
  property bool storageReady: false
  property bool stateLoaded: false

  signal pinAccepted()

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || home + "/.local/share"
  readonly property string dataDir: dataHome + "/omarchy-handoff"
  readonly property string statePath: dataDir + "/state.json"
  readonly property var selectedProject:
    selectedIndex >= 0 && selectedIndex < projects.length ? projects[selectedIndex] : null
  readonly property bool validating: validateProcess.running
  readonly property string statusLabel: refreshing ? "Refreshing Git state"
    : projects.length === 0 ? "No saved projects"
    : projects.length === 1 ? "1 saved project"
    : projects.length + " saved projects"

  function clone(value) { return JSON.parse(JSON.stringify(value)) }

  function projectIndexForPath(path) {
    for (var i = 0; i < projects.length; i++) {
      if (projects[i].path === path) return i
    }
    return -1
  }

  function gitCommand(path, arguments_) {
    return [
      "git",
      "-c", "core.hooksPath=/dev/null",
      "-c", "core.fsmonitor=false",
      "-C", path
    ].concat(arguments_)
  }

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
    if (demoActive || stateLoaded) return
    stateLoaded = true
    var loaded = []
    var source = String(raw || "").trim()
    try {
      var parsed = source === "" ? { version: 1, projects: [] } : JSON.parse(source)
      if (!parsed || parsed.version !== 1 || !Array.isArray(parsed.projects))
        throw new Error("unsupported state format")
      for (var i = 0; i < parsed.projects.length; i++) {
        var project = normalizedProject(parsed.projects[i])
        if (project) loaded.push(project)
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
    if (candidate.charAt(0) !== "/") {
      notice = "Enter an absolute path or a path beginning with ~/."
      return
    }
    if (validateProcess.running) return
    pendingPath = candidate
    notice = "Checking Git project…"
    validateProcess.output = ""
    validateProcess.command = gitCommand(candidate, ["rev-parse", "--show-toplevel"])
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
        notice = "Project is already saved in Handoff."
        pinAccepted()
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
    notice = "Project added to Handoff."
    pinAccepted()
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
    var path = projects[index].path
    if (refreshing) {
      if (refreshQueue.indexOf(path) < 0 && refreshPath !== path)
        refreshQueue = refreshQueue.concat([path])
      return
    }
    refreshQueue = [path]
    beginNextRefresh()
  }

  function refreshAll() {
    if (demoActive || refreshing || projects.length === 0) return
    var queue = []
    for (var i = 0; i < projects.length; i++) queue.push(projects[i].path)
    refreshQueue = queue
    beginNextRefresh()
  }

  function beginNextRefresh() {
    if (refreshQueue.length === 0) {
      refreshing = false
      refreshIndex = -1
      refreshPath = ""
      persist()
      return
    }
    refreshing = true
    refreshPath = refreshQueue[0]
    refreshQueue = refreshQueue.slice(1)
    refreshIndex = projectIndexForPath(refreshPath)
    if (refreshIndex < 0) {
      beginNextRefresh()
      return
    }
    statusOutput = ""
    statusProcess.output = ""
    statusProcess.command = gitCommand(refreshPath, ["status", "--porcelain=v2", "--branch"])
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
    var index = projectIndexForPath(refreshPath)
    if (index < 0) return false
    var next = clone(projects)
    next[index].branch = branch === "(detached)" ? "detached HEAD" : branch
    next[index].dirty = dirty
    next[index].checkedAt = new Date().toISOString()
    projects = next
    return true
  }

  function applyLog(text) {
    var fields = String(text || "").trim().split("\u001f")
    var index = projectIndexForPath(refreshPath)
    if (index < 0) {
      beginNextRefresh()
      return
    }
    var next = clone(projects)
    if (fields.length >= 3) {
      next[index].commit = fields[0]
      next[index].commitSubject = fields[1]
      next[index].commitAt = fields[2]
    }
    next[index].checkedAt = new Date().toISOString()
    projects = next
    beginNextRefresh()
  }

  Process {
    id: ensureDirProcess
    command: ["mkdir", "-p", root.dataDir]
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.lastError = "Could not prepare Handoff's local data directory."
        root.state = "error"
        return
      }
      root.storageReady = true
      stateFile.reload()
    }
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: if (root.storageReady) root.load(text())
    onLoadFailed: if (root.storageReady) root.load("")
    onFileChanged: reload()
    onSaveFailed: function(error) {
      root.lastError = "Could not save Handoff data. Your current session is unchanged."
      root.notice = root.lastError
    }
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
      var index = root.projectIndexForPath(root.refreshPath)
      if (index < 0) { root.beginNextRefresh(); return }
      if (exitCode !== 0) {
        var next = root.clone(root.projects)
        next[index].branch = "unavailable"
        next[index].dirty = false
        next[index].checkedAt = new Date().toISOString()
        root.projects = next
        root.beginNextRefresh()
        return
      }
      if (!root.applyStatus(output)) { root.beginNextRefresh(); return }
      logProcess.output = ""
      logProcess.command = root.gitCommand(root.refreshPath,
        ["log", "-1", "--format=%H%x1f%s%x1f%cI"])
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
      if (root.projectIndexForPath(root.refreshPath) < 0) {
        root.beginNextRefresh()
        return
      }
      if (exitCode === 0) root.applyLog(output)
      else root.applyLog("")
    }
  }

  Component.onCompleted: ensureDirProcess.running = true
}
