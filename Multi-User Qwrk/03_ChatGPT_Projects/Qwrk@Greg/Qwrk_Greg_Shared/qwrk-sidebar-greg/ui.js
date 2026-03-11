/**
 * QSB — UI Module
 *
 * Shadow DOM isolated execution bar injected above ChatGPT's input area.
 * Components: status indicator, controls, execution log, QX debug panel.
 * Positioned via fixed overlay outside React's tree. Re-anchored via MutationObserver.
 */

/* global chrome */

QSB.ui = {

  /** @type {HTMLElement|null} Shadow DOM host (direct child of document.body) */
  _host: null,

  /** @type {ShadowRoot|null} */
  _shadow: null,

  /** @type {HTMLElement|null} Container inside shadow root */
  _container: null,

  /** @type {MutationObserver|null} Re-anchor observer */
  _anchorObserver: null,

  /** @type {number|null} Anchor debounce timer */
  _anchorTimer: null,

  /** @type {boolean} Whether debug panel is visible */
  _debugVisible: false,

  /** @type {boolean} Whether execution log is collapsed */
  _logCollapsed: false,

  /** @type {string} Manual JSON input value (preserved across renders) */
  _manualInput: "",

  /** @type {string} Last request info for debug display */
  _lastRequestInfo: "",

  /** @type {Object<string,boolean>} Expanded log entries by timestamp key */
  _logExpanded: {},

  // --- Lifecycle ----------------------------------------------------------

  init: function () {
    // Create host element — direct child of body, outside React
    this._host = document.createElement("div");
    this._host.id = "qsb-host";
    this._host.style.cssText = "all:initial; position:fixed; z-index:99999; display:none;";

    // Closed shadow — ChatGPT scripts cannot reach into our UI
    this._shadow = this._host.attachShadow({ mode: "closed" });

    // Load isolated stylesheet
    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = chrome.runtime.getURL("styles.css");
    this._shadow.appendChild(link);

    // UI container
    this._container = document.createElement("div");
    this._container.id = "qsb-container";
    this._shadow.appendChild(this._container);

    // Attach to page
    document.body.appendChild(this._host);

    // Initial anchor attempt + observer
    this._anchor();
    this._startAnchorObserver();

    // Initial render
    this.render();
  },

  // --- Positioning --------------------------------------------------------

  /**
   * Position the host above ChatGPT's input container.
   * Uses fixed positioning calculated from the input's bounding rect.
   */
  _anchor: function () {
    var input = this._findInputContainer();
    if (!input) {
      this._host.style.display = "none";
      return;
    }

    var rect = input.getBoundingClientRect();
    this._host.style.cssText =
      "all:initial;" +
      "position:fixed;" +
      "left:" + rect.left + "px;" +
      "width:" + rect.width + "px;" +
      "bottom:" + (window.innerHeight - rect.top + 2) + "px;" +
      "z-index:99999;" +
      "font-size:12px;";
  },

  /**
   * Multi-fallback selector chain for ChatGPT's input container.
   */
  _findInputContainer: function () {
    return document.querySelector("#prompt-textarea")
      && document.querySelector("#prompt-textarea").closest("form")
      || document.querySelector('[role="textbox"]')
      && document.querySelector('[role="textbox"]').closest("form")
      || document.querySelector("form:has(textarea)")
      || document.querySelector("form:has([contenteditable])")
      || null;
  },

  /**
   * Watch for DOM changes and window resize to re-anchor.
   */
  _startAnchorObserver: function () {
    var self = this;

    this._anchorObserver = new MutationObserver(function () {
      clearTimeout(self._anchorTimer);
      self._anchorTimer = setTimeout(function () { self._anchor(); }, 150);
    });

    this._anchorObserver.observe(document.body, { childList: true, subtree: true });

    window.addEventListener("resize", function () {
      clearTimeout(self._anchorTimer);
      self._anchorTimer = setTimeout(function () { self._anchor(); }, 100);
    });
  },

  // --- Debug Info ---------------------------------------------------------

  setLastRequestInfo: function (info) {
    this._lastRequestInfo = info;
  },

  appendRequestInfo: function (line) {
    this._lastRequestInfo += "\n" + line;
    // Re-render only if debug panel is visible
    if (this._debugVisible) this.render();
  },

  // --- Rendering ----------------------------------------------------------

  render: function () {
    if (!this._container) return;

    var s = QSB.state;
    var html = "";

    // --- Status + Controls Bar ---
    var indicatorClass = "idle";
    var statusText = "No staged operation";
    var statusActive = false;

    if (s.isExecuting) {
      indicatorClass = "executing";
      statusText = "Executing\u2026";
      statusActive = true;
    } else if (s.stagedPayload) {
      indicatorClass = "staged";
      statusText = "1 staged: " + (s.stagedPayload.gw_action || "unknown");
      statusActive = true;
    }

    var canExecute = s.stagedPayload && !s.isExecuting;
    var canClear = s.stagedPayload && !s.isExecuting;

    html += '<div class="qsb-bar">';
    html += '  <div class="qsb-status">';
    html += '    <span class="qsb-indicator ' + indicatorClass + '"></span>';
    html += '    <span class="qsb-status-text' + (statusActive ? " active" : "") + '">' + this._esc(statusText) + '</span>';
    html += '  </div>';
    html += '  <div class="qsb-controls">';
    html += '    <button class="qsb-btn execute" data-action="execute"' + (canExecute ? "" : " disabled") + '>Execute</button>';
    html += '    <button class="qsb-btn clear" data-action="clear"' + (canClear ? "" : " disabled") + '>Clear</button>';
    html += '    <select class="qsb-select" data-action="workspace">';
    for (var i = 0; i < QSB.profiles.length; i++) {
      var p = QSB.profiles[i];
      html += '      <option value="' + p.id + '"' + (p.id === QSB.selectedProfileId ? " selected" : "") + '>' + this._esc(p.label) + '</option>';
    }
    html += '    </select>';
    html += '    <button class="qsb-btn debug-toggle" data-action="debug" title="QX Debug">\u2699</button>';
    html += '  </div>';
    html += '</div>';

    // --- Result Summary Card (most recent entry) ---
    if (s.executionLog.length > 0) {
      html += this._renderSummary(s.executionLog[0]);
    }

    // --- Execution Log ---
    if (s.executionLog.length > 0) {
      var chevron = this._logCollapsed ? "\u25BC" : "\u25B2";
      html += '<div class="qsb-log-header">';
      html += '  <span class="qsb-log-header-left" data-action="toggle-log-collapse">';
      html += '    <span class="qsb-log-chevron">' + chevron + '</span>';
      html += '    <span>Log (' + s.executionLog.length + ')</span>';
      html += '  </span>';
      html += '  <button class="qsb-btn qsb-btn-log-clear" data-action="clear-log">Clear Log</button>';
      html += '</div>';

      if (!this._logCollapsed) {
        html += '<div class="qsb-log">';
        for (var j = 0; j < s.executionLog.length; j++) {
          var entry = s.executionLog[j];
          var icon = entry.success ? "\u2714" : "\u2716";
          var iconClass = entry.success ? "success" : "error";
          var time = this._formatTime(entry.timestamp);
          var entryKey = String(entry.timestamp.getTime());

          html += '<div class="qsb-log-entry" data-action="toggle-log" data-key="' + entryKey + '">';
          html += '  <span class="qsb-log-icon ' + iconClass + '">' + icon + '</span>';
          html += '  <span class="qsb-log-message">' + this._esc(entry.action) + ' \u2014 ' + this._esc(entry.message) + '</span>';
          html += '  <span class="qsb-log-time">' + time + '</span>';
          html += '</div>';

          if (this._logExpanded[entryKey] && entry.rawResponse) {
            html += '<div class="qsb-log-detail">';
            html += '  <pre>' + this._esc(JSON.stringify(entry.rawResponse, null, 2)) + '</pre>';
            html += '</div>';
          }
        }
        html += '</div>';
      }
    }

    // --- Debug Panel ---
    if (this._debugVisible) {
      var staged = s.stagedPayload ? JSON.stringify(s.stagedPayload, null, 2) : "(empty)";

      html += '<div class="qsb-debug">';

      // Staged payload (read-only)
      html += '  <div class="qsb-debug-label">Staged Payload</div>';
      html += '  <textarea class="qsb-debug-staged" readonly>' + this._esc(staged) + '</textarea>';

      // Manual JSON input (QX mode)
      html += '  <div class="qsb-debug-label">Manual JSON (QX Mode)</div>';
      html += '  <textarea class="qsb-debug-manual" data-id="manual-input" placeholder="Paste JSON payload here">' + this._esc(this._manualInput) + '</textarea>';

      html += '  <div class="qsb-debug-controls">';
      html += '    <button class="qsb-btn" data-action="stage-manual">Stage</button>';
      html += '    <button class="qsb-btn" data-action="copy-staged">Copy Staged</button>';
      html += '    <button class="qsb-btn" data-action="copy-last-response">Copy Last Response</button>';
      html += '  </div>';

      // Last request info (masked headers)
      if (this._lastRequestInfo) {
        html += '  <div class="qsb-debug-label">Last Request</div>';
        html += '  <div class="qsb-debug-request">';
        var lines = this._lastRequestInfo.split("\n");
        for (var k = 0; k < lines.length; k++) {
          html += '<div class="qsb-header-line">' + this._esc(lines[k]) + '</div>';
        }
        html += '  </div>';
      }

      html += '</div>';
    }

    this._container.innerHTML = html;
    this._bindEvents();
  },

  // --- Event Binding (delegation) -----------------------------------------

  _bindEvents: function () {
    var self = this;

    // Click delegation
    this._container.onclick = function (e) {
      var target = e.target.closest("[data-action]");
      if (!target) return;

      switch (target.dataset.action) {
        case "execute":
          QSB.executor.execute();
          break;
        case "clear":
          QSB.state.clear();
          break;
        case "debug":
          self._toggleDebug();
          break;
        case "toggle-log":
          self._toggleLogEntry(target.dataset.key);
          break;
        case "copy-id":
          self._copyToClipboard(target.dataset.id || "", target);
          break;
        case "copy-contents":
          self._copyContentsFromLog(target);
          break;
        case "copy-error":
          self._copyErrorFromLog(target);
          break;
        case "copy-full-response":
          self._copyFullResponse(target);
          break;
        case "insert-error":
          self._insertErrorIntoChat(target);
          break;
        case "insert-full-response":
          self._insertFullResponseIntoChat(target);
          break;
        case "insert-contents":
          self._insertContentsIntoChat(target);
          break;
        case "insert-list-compact":
          self._insertListCompactIntoChat(target);
          break;
        case "stage-query":
          self._stageQueryFromSummary(target);
          break;
        case "toggle-log-collapse":
          self._logCollapsed = !self._logCollapsed;
          self.render();
          break;
        case "clear-log":
          QSB.state.executionLog = [];
          self._logExpanded = {};
          self._logCollapsed = false;
          self.render();
          break;
        case "stage-manual":
          self._stageManual();
          break;
        case "copy-staged":
          self._copyToClipboard(
            QSB.state.stagedPayload ? JSON.stringify(QSB.state.stagedPayload, null, 2) : "",
            target
          );
          break;
        case "copy-last-response":
          self._copyLastResponse(target);
          break;
      }
    };

    // Workspace selection
    this._container.onchange = function (e) {
      if (e.target.dataset.action === "workspace") {
        QSB.setSelectedProfile(e.target.value);
      }
    };

    // Preserve manual input across renders
    var manualInput = this._container.querySelector('[data-id="manual-input"]');
    if (manualInput) {
      manualInput.oninput = function (e) { self._manualInput = e.target.value; };
    }
  },

  // --- UI Actions ---------------------------------------------------------

  _toggleDebug: function () {
    this._debugVisible = !this._debugVisible;
    this.render();
  },

  _toggleLogEntry: function (key) {
    this._logExpanded[key] = !this._logExpanded[key];
    this.render();
  },

  _stageManual: function () {
    var raw = this._manualInput.trim();
    if (!raw) return;

    try {
      var payload = JSON.parse(raw);
      if (typeof payload === "object" && payload !== null && !Array.isArray(payload)) {
        QSB.state.stage(payload);
        this._manualInput = "";
        this.render();
      }
    } catch (e) {
      // Flash error briefly — just re-render with existing state
      // The staged payload won't change, so user sees no effect = implicit "invalid JSON"
    }
  },

  _copyToClipboard: function (text, triggerBtn) {
    if (!text) return;
    navigator.clipboard.writeText(text).then(function () {
      if (triggerBtn && triggerBtn.nodeType === 1) {
        var orig = triggerBtn.textContent;
        triggerBtn.textContent = "Copied!";
        triggerBtn.disabled = true;
        setTimeout(function () {
          triggerBtn.textContent = orig;
          triggerBtn.disabled = false;
        }, 1200);
      }
    }).catch(function () {
      // Fallback: silent fail in content script context
    });
  },

  _copyLastResponse: function (btn) {
    var log = QSB.state.executionLog;
    if (log.length === 0 || !log[0].rawResponse) return;
    this._copyToClipboard(JSON.stringify(log[0].rawResponse, null, 2), btn);
  },

  /**
   * Copy the error object from the most recent log entry.
   */
  _copyErrorFromLog: function (btn) {
    var log = QSB.state.executionLog;
    if (log.length === 0 || !log[0].rawResponse) return;
    var resp = log[0].rawResponse;
    var errorObj = resp.error || resp;
    this._copyToClipboard(JSON.stringify(errorObj, null, 2), btn);
  },

  /**
   * Copy the full raw Gateway response from the most recent log entry.
   */
  _copyFullResponse: function (btn) {
    var log = QSB.state.executionLog;
    if (log.length === 0 || !log[0].rawResponse) return;
    this._copyToClipboard(JSON.stringify(log[0].rawResponse, null, 2), btn);
  },

  // --- Insert Into Chat ----------------------------------------------------

  /**
   * Insert text into ChatGPT's input as a fenced JSON block.
   * Does NOT auto-send. Cursor lands at end of inserted content.
   * Uses execCommand('insertText') for native React reconciliation,
   * with Range API fallback for deprecated browsers.
   */
  _insertIntoChat: function (jsonText, triggerBtn) {
    if (!jsonText) return;

    var fenced = "```json\n" + jsonText + "\n```\n";

    // Find ChatGPT's contenteditable input
    var input = document.querySelector("#prompt-textarea")
      || document.querySelector('[contenteditable="true"]');
    if (!input) {
      console.log("QSB insert: no chat input found");
      return;
    }

    input.focus();

    // Suspend BOTH observers to prevent mutation cascade.
    // Parser observer: inserting into contenteditable fires hundreds of DOM mutations
    // inside <main>, which the parser observes.
    // Anchor observer: watches document.body with subtree:true — every DOM mutation
    // during insert triggers unnecessary _anchor() recalculations.
    QSB.parser.suspend();
    this._suspendAnchorObserver();

    // Primary: execCommand insertText (fires beforeinput/input natively)
    var success = document.execCommand("insertText", false, fenced);

    if (!success) {
      // Fallback: Range API insertion
      var sel = window.getSelection();
      if (sel && sel.rangeCount > 0) {
        var range = sel.getRangeAt(0);
        range.deleteContents();
        var textNode = document.createTextNode(fenced);
        range.insertNode(textNode);
        range.setStartAfter(textNode);
        range.setEndAfter(textNode);
        sel.removeAllRanges();
        sel.addRange(range);
      } else {
        // Last resort: append to existing content
        input.textContent += fenced;
      }
      // Manual event dispatch for React reconciliation
      input.dispatchEvent(new Event("input", { bubbles: true }));
    }

    // Resume both observers after insert is complete
    QSB.parser.resume();
    this._resumeAnchorObserver();

    // Visual feedback (same pattern as _copyToClipboard)
    if (triggerBtn && triggerBtn.nodeType === 1) {
      var orig = triggerBtn.textContent;
      triggerBtn.textContent = "Inserted!";
      triggerBtn.disabled = true;
      setTimeout(function () {
        triggerBtn.textContent = orig;
        triggerBtn.disabled = false;
      }, 1200);
    }
  },

  /**
   * Insert error JSON from the most recent log entry into ChatGPT input.
   */
  _insertErrorIntoChat: function (btn) {
    var log = QSB.state.executionLog;
    if (log.length === 0 || !log[0].rawResponse) return;
    var resp = log[0].rawResponse;
    var errorObj = resp.error || resp;
    this._insertIntoChat(JSON.stringify(errorObj, null, 2), btn);
  },

  /**
   * Insert full raw Gateway response from the most recent log entry into ChatGPT input.
   */
  _insertFullResponseIntoChat: function (btn) {
    var log = QSB.state.executionLog;
    if (log.length === 0 || !log[0].rawResponse) return;
    this._insertIntoChat(JSON.stringify(log[0].rawResponse, null, 2), btn);
  },

  /**
   * Insert compact list summary into ChatGPT input.
   * Uses _compactListForInsert to reduce payload to essential fields only.
   * Truncates at 25 artifacts to prevent chat overload.
   */
  _insertListCompactIntoChat: function (btn) {
    var log = QSB.state.executionLog;
    if (log.length === 0 || !log[0].rawResponse) return;
    var compact = this._compactListForInsert(log[0].rawResponse, 25);
    this._insertIntoChat(compact, btn);
  },

  /**
   * Insert extension contents from the most recent query result into ChatGPT input.
   * Falls back to full response if no extractable contents.
   */
  _insertContentsIntoChat: function (btn) {
    var log = QSB.state.executionLog;
    if (log.length === 0 || !log[0].rawResponse) return;
    var artifact = this._extractArtifact(log[0].rawResponse);
    var text = this._extractContents(artifact);
    if (text) {
      this._insertIntoChat(text, btn);
    } else {
      this._insertIntoChat(JSON.stringify(log[0].rawResponse, null, 2), btn);
    }
  },

  // --- Result Summary ------------------------------------------------------

  /**
   * Extract the artifact object from a Gateway response, handling multiple shapes.
   * Gateway responses vary by action:
   *   Shape A: { ok: true, data: { artifact: {...} } }      — save/update with nested data
   *   Shape B: { artifact: {...} }                           — query (no ok field)
   *   Shape C: { ok: true, artifact: {...} }                 — direct artifact wrapper
   *   Shape D: { ok: true, artifact_id: "...", ... }         — flat (artifact fields at top level)
   *
   * @param {object} response — rawResponse from log entry
   * @returns {object|null} artifact object or null
   */
  _extractArtifact: function (response) {
    if (!response || typeof response !== "object") return null;
    // Shape A: { data: { artifact: {...} } }
    if (response.data && typeof response.data === "object" && response.data.artifact) {
      return response.data.artifact;
    }
    // Shape B/C: { artifact: {...} }
    if (response.artifact && typeof response.artifact === "object") {
      return response.artifact;
    }
    // Shape D: flat response — response itself has artifact_id
    if (response.artifact_id) {
      return response;
    }
    return null;
  },

  /**
   * Render a summary card for the most recent log entry.
   * Returns HTML string. Falls back to empty string for unknown actions.
   */
  _renderSummary: function (entry) {
    if (!entry || !entry.rawResponse) return "";

    var resp = entry.rawResponse;

    // --- Error card ---
    if (entry.success === false && resp.error) {
      var code = (resp.error && resp.error.code) || "Unknown";
      var msg = (resp.error && resp.error.message) || "";
      var html = '<div class="qsb-summary-card qsb-summary-error">';
      html += '  <div class="qsb-summary-title">\u2716 Gateway Error</div>';
      html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Code:</span> ' + this._esc(code) + '</div>';
      if (msg) {
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Message:</span> ' + this._esc(msg) + '</div>';
      }
      html += '  <div class="qsb-summary-actions">';
      html += '    <button class="qsb-btn" data-action="insert-error">Insert Into Chat</button>';
      html += '    <button class="qsb-btn" data-action="copy-error">Copy Error JSON</button>';
      html += '    <button class="qsb-btn" data-action="copy-full-response">Copy Full Response</button>';
      html += '  </div>';
      html += '</div>';
      return html;
    }

    // --- Success card ---
    if (!entry.success) return "";

    var artifact = this._extractArtifact(resp);
    var action = entry.action || "";

    // No artifact to summarize — unknown shape
    if (!artifact && action !== "artifact.list") return "";

    var artifactId = (artifact && artifact.artifact_id) || "";
    // artifact_type might be on artifact or on the response root (flat shape)
    var artifactType = (artifact && artifact.artifact_type) || resp.artifact_type || "";
    var workspaceId = (artifact && artifact.workspace_id) || resp.workspace_id || resp.gw_workspace_id || "";
    var title = (artifact && artifact.title) || "";
    var typeLabel = artifactType ? (artifactType.charAt(0).toUpperCase() + artifactType.slice(1)) : "Artifact";

    var html = '<div class="qsb-summary-card qsb-summary-success">';

    switch (action) {
      case "artifact.save":
        html += '  <div class="qsb-summary-title">\u2714 ' + this._esc(typeLabel) + ' Saved</div>';
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Artifact ID:</span> ' + this._esc(artifactId) + '</div>';
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Workspace:</span> ' + this._esc(workspaceId) + '</div>';
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Operation:</span> INSERT</div>';
        html += '  <div class="qsb-summary-actions">';
        html += '    <button class="qsb-btn" data-action="copy-id" data-id="' + this._esc(artifactId) + '">Copy ID</button>';
        if (artifactId && artifactType && workspaceId) {
          html += '    <button class="qsb-btn" data-action="stage-query"';
          html += '      data-artifact-id="' + this._esc(artifactId) + '"';
          html += '      data-artifact-type="' + this._esc(artifactType) + '"';
          html += '      data-workspace-id="' + this._esc(workspaceId) + '">Stage Query</button>';
        }
        html += '    <button class="qsb-btn" data-action="insert-full-response">Insert Into Chat</button>';
        html += '    <button class="qsb-btn" data-action="copy-full-response">Copy Full Response</button>';
        html += '  </div>';
        break;

      case "artifact.query":
        html += '  <div class="qsb-summary-title">\u2714 ' + this._esc(typeLabel) + ' Retrieved</div>';
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Artifact ID:</span> ' + this._esc(artifactId) + '</div>';
        if (title) {
          html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Title:</span> ' + this._esc(title) + '</div>';
        }
        if (artifact.version !== undefined) {
          html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Version:</span> ' + this._esc(String(artifact.version)) + '</div>';
        }
        // Extract extension contents for copy (journal.entry_text, snapshot.payload, etc.)
        var contentsText = this._extractContents(artifact);
        html += '  <div class="qsb-summary-actions">';
        html += '    <button class="qsb-btn" data-action="copy-id" data-id="' + this._esc(artifactId) + '">Copy ID</button>';
        if (contentsText) {
          html += '    <button class="qsb-btn" data-action="insert-contents">Insert Into Chat</button>';
          html += '    <button class="qsb-btn" data-action="copy-contents">Copy Contents</button>';
        } else {
          html += '    <button class="qsb-btn" data-action="insert-full-response">Insert Into Chat</button>';
        }
        html += '    <button class="qsb-btn" data-action="copy-full-response">Copy Full Response</button>';
        html += '  </div>';
        break;

      case "artifact.update":
        html += '  <div class="qsb-summary-title">\u2714 ' + this._esc(typeLabel) + ' Updated</div>';
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Artifact ID:</span> ' + this._esc(artifactId) + '</div>';
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Workspace:</span> ' + this._esc(workspaceId) + '</div>';
        html += '  <div class="qsb-summary-actions">';
        html += '    <button class="qsb-btn" data-action="copy-id" data-id="' + this._esc(artifactId) + '">Copy ID</button>';
        if (artifactId && artifactType && workspaceId) {
          html += '    <button class="qsb-btn" data-action="stage-query"';
          html += '      data-artifact-id="' + this._esc(artifactId) + '"';
          html += '      data-artifact-type="' + this._esc(artifactType) + '"';
          html += '      data-workspace-id="' + this._esc(workspaceId) + '">Stage Query</button>';
        }
        html += '    <button class="qsb-btn" data-action="insert-full-response">Insert Into Chat</button>';
        html += '    <button class="qsb-btn" data-action="copy-full-response">Copy Full Response</button>';
        html += '  </div>';
        break;

      case "artifact.promote":
        html += '  <div class="qsb-summary-title">\u2714 ' + this._esc(typeLabel) + ' Promoted</div>';
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Artifact ID:</span> ' + this._esc(artifactId) + '</div>';
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Workspace:</span> ' + this._esc(workspaceId) + '</div>';
        if (artifact.lifecycle_status) {
          html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Status:</span> ' + this._esc(artifact.lifecycle_status) + '</div>';
        }
        html += '  <div class="qsb-summary-actions">';
        html += '    <button class="qsb-btn" data-action="copy-id" data-id="' + this._esc(artifactId) + '">Copy ID</button>';
        if (artifactId && artifactType && workspaceId) {
          html += '    <button class="qsb-btn" data-action="stage-query"';
          html += '      data-artifact-id="' + this._esc(artifactId) + '"';
          html += '      data-artifact-type="' + this._esc(artifactType) + '"';
          html += '      data-workspace-id="' + this._esc(workspaceId) + '">Stage Query</button>';
        }
        html += '    <button class="qsb-btn" data-action="insert-full-response">Insert Into Chat</button>';
        html += '    <button class="qsb-btn" data-action="copy-full-response">Copy Full Response</button>';
        html += '  </div>';
        break;

      case "artifact.list":
        var listData = resp.data || {};
        var listCount = (listData.artifacts && listData.artifacts.length) || 0;
        var listMeta = resp.meta || {};
        var hasMore = listMeta.has_more ? " (more available)" : "";
        html += '  <div class="qsb-summary-title">\u2714 List Results</div>';
        html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Returned:</span> ' + listCount + ' artifacts' + this._esc(hasMore) + '</div>';
        if (listMeta.limit) {
          html += '  <div class="qsb-summary-row"><span class="qsb-summary-label">Limit:</span> ' + this._esc(String(listMeta.limit)) + '</div>';
        }
        html += '  <div class="qsb-summary-actions">';
        html += '    <button class="qsb-btn" data-action="insert-list-compact">Insert Into Chat</button>';
        html += '    <button class="qsb-btn" data-action="copy-full-response">Copy Raw JSON</button>';
        html += '  </div>';
        break;

      default:
        // Unknown action — no summary card
        return "";
    }

    html += '</div>';
    return html;
  },

  /**
   * Extract copyable text contents from an artifact's extension data.
   * Supports journal (entry_text), snapshot (payload), and generic (content).
   * @param {object} artifact
   * @returns {string|null}
   */
  _extractContents: function (artifact) {
    if (!artifact || !artifact.extension) return null;
    var ext = artifact.extension;
    // Journal: entry_text
    if (typeof ext.entry_text === "string" && ext.entry_text) return ext.entry_text;
    // Snapshot/restart: payload (stringify if object)
    if (ext.payload) {
      return typeof ext.payload === "string" ? ext.payload : JSON.stringify(ext.payload, null, 2);
    }
    // Generic: content field
    if (ext.content) {
      return typeof ext.content === "string" ? ext.content : JSON.stringify(ext.content, null, 2);
    }
    return null;
  },

  /**
   * Copy contents from the most recent query result.
   */
  _copyContentsFromLog: function (btn) {
    var log = QSB.state.executionLog;
    if (log.length === 0 || !log[0].rawResponse) return;
    var artifact = this._extractArtifact(log[0].rawResponse);
    var text = this._extractContents(artifact);
    if (text) this._copyToClipboard(text, btn);
  },

  /**
   * Stage a query payload from the summary card's data attributes.
   */
  _stageQueryFromSummary: function (target) {
    var artifactId = target.dataset.artifactId;
    var artifactType = target.dataset.artifactType;
    var workspaceId = target.dataset.workspaceId;
    if (!artifactId || !artifactType || !workspaceId) return;

    QSB.state.stage({
      gw_action: "artifact.query",
      artifact_type: artifactType,
      gw_workspace_id: workspaceId,
      artifact_id: artifactId
    });
  },

  // --- Anchor Observer Suspension ------------------------------------------

  /**
   * Temporarily disconnect the anchor observer to prevent mutation cascade
   * during programmatic DOM changes (e.g., inserting large text into chat).
   */
  _suspendAnchorObserver: function () {
    if (this._anchorObserver) {
      this._anchorObserver.disconnect();
    }
    clearTimeout(this._anchorTimer);
  },

  /**
   * Reconnect the anchor observer after suspension.
   */
  _resumeAnchorObserver: function () {
    if (this._anchorObserver) {
      this._anchorObserver.observe(document.body, { childList: true, subtree: true });
    }
  },

  // --- Compact List Formatting ---------------------------------------------

  /**
   * Build a compact JSON string from a list response for chat insertion.
   * Includes only essential fields per artifact. Truncates at maxItems
   * and sets truncated flag so Q knows the list was clipped.
   *
   * @param {object} rawResponse — full Gateway list response
   * @param {number} [maxItems=25] — max artifacts to include
   * @returns {string} compact JSON string
   */
  _compactListForInsert: function (rawResponse, maxItems) {
    if (!maxItems) maxItems = 25;

    var listData = (rawResponse.data && rawResponse.data.artifacts) || [];
    var meta = rawResponse.meta || {};
    var totalReturned = listData.length;
    var truncated = totalReturned > maxItems;
    var items = truncated ? listData.slice(0, maxItems) : listData;

    var compact = [];
    for (var i = 0; i < items.length; i++) {
      var a = items[i];
      var entry = {
        artifact_id: a.artifact_id,
        artifact_type: a.artifact_type,
        title: a.title
      };
      if (a.lifecycle_status) entry.lifecycle_status = a.lifecycle_status;
      if (a.execution_status) entry.execution_status = a.execution_status;
      if (a.tags && a.tags.length > 0) entry.tags = a.tags;
      if (a.parent_artifact_id) entry.parent_artifact_id = a.parent_artifact_id;
      compact.push(entry);
    }

    var result = {
      gw_action: rawResponse.gw_action || "artifact.list",
      artifact_type: rawResponse.artifact_type || null,
      count: totalReturned,
      artifacts: compact
    };

    if (truncated) {
      result.truncated = true;
      result.truncated_at = maxItems;
    }

    if (meta.has_more) {
      result.has_more = true;
    }

    return JSON.stringify(result, null, 2);
  },

  // --- Helpers ------------------------------------------------------------

  _esc: function (str) {
    var div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  },

  _formatTime: function (date) {
    var h = date.getHours();
    var m = date.getMinutes();
    return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
  }
};
