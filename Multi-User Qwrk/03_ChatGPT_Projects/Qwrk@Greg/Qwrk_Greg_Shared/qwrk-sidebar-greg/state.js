/**
 * QSB — State Machine
 *
 * Exactly ONE staged payload at a time.
 * States: idle | staged | executing
 *
 * Transitions:
 *   idle     → staged     : new prime-exec block detected
 *   staged   → staged     : new prime-exec block replaces previous
 *   staged   → executing  : user clicks Execute
 *   executing→ idle       : success (clears staged payload)
 *   executing→ staged     : failure (retains staged payload)
 *   any      → idle       : Clear / page reload / thread switch
 */

QSB.state = {

  /** @type {object|null} The currently staged Gateway payload */
  stagedPayload: null,

  /** @type {boolean} True while a Gateway call is in flight */
  isExecuting: false,

  /** @type {Array<object>} Session execution log (newest first, capped at 50) */
  executionLog: [],

  // --- Transitions --------------------------------------------------------

  /**
   * Stage a new payload. Replaces any existing staged payload.
   * @param {object} payload — parsed JSON from prime-exec block
   */
  stage: function (payload) {
    this.stagedPayload = payload;
    this.isExecuting = false;
    QSB.ui.render();
  },

  /**
   * Clear staged payload and reset to idle.
   */
  clear: function () {
    this.stagedPayload = null;
    this.isExecuting = false;
    QSB.ui.render();
  },

  /**
   * Set the executing flag (called by executor).
   * @param {boolean} value
   */
  setExecuting: function (value) {
    this.isExecuting = value;
    QSB.ui.render();
  },

  /**
   * Append an entry to the execution log.
   * @param {object} entry — { timestamp, success, action, message, rawResponse }
   */
  logEntry: function (entry) {
    this.executionLog.unshift(entry);
    if (this.executionLog.length > 50) {
      this.executionLog.length = 50;
    }
    QSB.ui.render();
  },

  // --- Queries ------------------------------------------------------------

  hasStagedPayload: function () {
    return this.stagedPayload !== null;
  }
};
