/**
 * QSB — PrimeExecutionObject Parser (v5 — DOM-aware extraction)
 *
 * Detection strategy:
 *   1. MutationObserver on <main> (debounced 300ms)
 *   2. Anchor to last assistant message via data-message-author-role
 *   3. Normalize smart/curly quotes in textContent (ChatGPT typography)
 *   4. Gate: text must contain "prime-exec"
 *   5. Extract (A): DOM <pre><code> blocks — ChatGPT renders ```json as HTML code blocks
 *   6. Extract (B): balanced brace fallback on textContent after marker
 */

QSB.parser = {

  /** @type {MutationObserver|null} */
  _observer: null,

  /** @type {number|null} debounce timer */
  _debounceTimer: null,

  /** @type {string|null} fingerprint of last staged payload (prevents re-staging same block) */
  _lastStagedFingerprint: null,

  // --- Lifecycle ----------------------------------------------------------

  start: function () {
    var self = this;

    this._observer = new MutationObserver(function () {
      clearTimeout(self._debounceTimer);
      self._debounceTimer = setTimeout(function () { self.scan(); }, 300);
    });

    var target = document.querySelector("main") || document.body;
    this._observer.observe(target, { childList: true, subtree: true, characterData: true });
  },

  stop: function () {
    if (this._observer) {
      this._observer.disconnect();
      this._observer = null;
    }
    clearTimeout(this._debounceTimer);
  },

  /**
   * Temporarily disconnect the observer without destroying it.
   * Use before programmatic DOM mutations (e.g., inserting into chat input)
   * to prevent observer cascade / main-thread stall.
   */
  suspend: function () {
    if (this._observer) {
      this._observer.disconnect();
    }
    clearTimeout(this._debounceTimer);
  },

  /**
   * Reconnect a suspended observer. No-op if observer was never created.
   */
  resume: function () {
    if (this._observer) {
      var target = document.querySelector("main") || document.body;
      this._observer.observe(target, { childList: true, subtree: true, characterData: true });
    }
  },

  /**
   * Reset fingerprint on navigation so the same block can be re-detected
   * in a different conversation context.
   */
  resetFingerprint: function () {
    this._lastStagedFingerprint = null;
  },

  // --- Quote Normalization -------------------------------------------------

  /**
   * Normalize smart/curly quotes to straight ASCII equivalents.
   * ChatGPT's markdown renderer applies typography when JSON is outside
   * a fenced code block, converting " to \u201C/\u201D. This breaks both
   * balanced-brace string tracking and JSON.parse.
   */
  _normalizeQuotes: function (text) {
    return text
      .replace(/[\u201C\u201D\u201E\u201F\u2033\u2036]/g, '"')
      .replace(/[\u2018\u2019\u201A\u201B\u2032\u2035]/g, "'");
  },

  // --- Scanning -----------------------------------------------------------

  scan: function () {
    console.log("QSB scan() fired");
    var messages = document.querySelectorAll('[data-message-author-role="assistant"]');
    if (!messages.length) {
      console.log("QSB scan: no assistant messages found");
      return;
    }

    var last = messages[messages.length - 1];
    var text = this._normalizeQuotes(last.textContent);

    // Gate: marker string must be present
    var markerPos = text.indexOf("prime-exec");
    if (markerPos === -1) return;

    console.log("QSB scan: marker found, extracting payload");

    // Strategy A: DOM-based — find JSON inside <pre><code> (rendered fenced blocks)
    var candidate = this._extractFromCodeBlock(last);

    // Strategy B: balanced brace fallback on textContent
    if (candidate === null) {
      var afterMarker = text.substring(markerPos);
      candidate = this._extractBalanced(afterMarker);
    }

    if (candidate === null) {
      console.log("QSB scan: marker found but no JSON extracted");
      return;
    }

    // Fingerprint check — don't re-stage identical text
    if (candidate === this._lastStagedFingerprint) return;

    // Validate and stage
    this._tryStage(candidate);
  },

  // --- Extraction ---------------------------------------------------------

  /**
   * Strategy A: Find JSON inside rendered <pre><code> blocks.
   * ChatGPT converts ```json fences to <pre><code> HTML elements.
   * Backticks never appear in textContent — must query the DOM directly.
   * Searches last code block first (payload is typically at end of message).
   */
  _extractFromCodeBlock: function (messageEl) {
    var codeEls = messageEl.querySelectorAll("pre code");
    if (!codeEls.length) return null;

    for (var i = codeEls.length - 1; i >= 0; i--) {
      var text = this._normalizeQuotes(codeEls[i].textContent).trim();
      if (text.charAt(0) === "{" && text.charAt(text.length - 1) === "}") {
        console.log("QSB extract: found JSON in <pre><code> block", i);
        return text;
      }
    }
    return null;
  },

  /**
   * Strategy B: Find the first balanced JSON object after the marker.
   * Uses brace-depth counting, skipping braces inside JSON strings.
   */
  _extractBalanced: function (text) {
    var start = text.indexOf("{");
    if (start === -1) return null;

    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = start; i < text.length; i++) {
      var ch = text.charAt(i);

      if (escaped) {
        escaped = false;
        continue;
      }

      if (ch === "\\") {
        if (inString) escaped = true;
        continue;
      }

      if (ch === '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (ch === "{") {
        depth++;
      } else if (ch === "}") {
        depth--;
        if (depth === 0) {
          return text.substring(start, i + 1);
        }
      }
    }

    // Unbalanced — no complete object found
    return null;
  },

  // --- Validation ---------------------------------------------------------

  /**
   * Parse candidate JSON string, validate required keys, stage if valid.
   */
  _tryStage: function (candidate) {
    try {
      var parsed = JSON.parse(candidate);

      if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
        console.log("QSB tryStage: parsed but not a plain object");
        return;
      }

      if (parsed.gw_action && parsed.gw_workspace_id) {
        this._lastStagedFingerprint = candidate;
        QSB.state.stage(parsed);
      } else {
        console.log("QSB tryStage: missing gw_action or gw_workspace_id", Object.keys(parsed));
      }
    } catch (e) {
      // Diagnostic: show first 200 chars + char codes at positions 0-4 for debugging
      var codes = [];
      for (var k = 0; k < Math.min(5, candidate.length); k++) {
        codes.push("pos" + k + "=" + candidate.charCodeAt(k) + "('" + candidate.charAt(k) + "')");
      }
      console.log("QSB tryStage: JSON.parse failed", e.message);
      console.log("QSB tryStage: first chars:", codes.join(", "));
      console.log("QSB tryStage: candidate[0..200]:", candidate.substring(0, 200));
    }
  }
};
