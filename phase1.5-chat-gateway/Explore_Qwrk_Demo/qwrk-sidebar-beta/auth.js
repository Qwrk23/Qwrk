/**
 * QSB Beta — Auth Provider Module
 *
 * Abstracts credential header construction.
 * Beta uses "basic" auth mode.
 */

QSB.auth = {

  /**
   * Build the Authorization header value for a profile.
   * @param {object} profile — workspace profile from QSB.profiles
   * @returns {string} header value (e.g. "Basic abc123...")
   */
  buildHeader: function (profile) {
    var mode = profile.auth_mode || "basic";
    switch (mode) {
      case "basic":
        return "Basic " + profile.credential;
      case "bearer":
        return "Bearer " + profile.credential;
      default:
        throw new Error("[QSB] Unknown auth_mode: " + mode);
    }
  },

  /**
   * Masked header for debug logging — never exposes credential value.
   * @param {object} profile
   * @returns {string} e.g. "Basic ***"
   */
  maskHeader: function (profile) {
    var mode = profile.auth_mode || "basic";
    switch (mode) {
      case "basic":
        return "Basic ***";
      case "bearer":
        return "Bearer ***";
      default:
        return "*** (unknown mode)";
    }
  }
};
