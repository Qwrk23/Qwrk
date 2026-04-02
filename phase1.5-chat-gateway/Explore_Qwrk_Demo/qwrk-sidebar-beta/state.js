/**
 * QSB Beta — State Machine
 *
 * Exactly ONE staged payload at a time.
 * States: idle | staged | executing
 */

QSB.state = {

  /** @type {object|null} The currently staged Gateway payload */
  stagedPayload: null,

  /** @type {boolean} True while a Gateway call is in flight */
  isExecuting: false,

  /** @type {Array<object>} Session execution log (newest first, capped at 50) */
  executionLog: [],

  // --- Transitions --------------------------------------------------------

  stage: function (payload) {
    this.stagedPayload = payload;
    this.isExecuting = false;
    QSB.ui.render();
  },

  clear: function () {
    this.stagedPayload = null;
    this.isExecuting = false;
    QSB.ui.render();
  },

  setExecuting: function (value) {
    this.isExecuting = value;
    QSB.ui.render();
  },

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
