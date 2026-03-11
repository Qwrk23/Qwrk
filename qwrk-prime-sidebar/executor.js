/**
 * QSB — Execution Handler
 *
 * Sends staged payload to Gateway via Service Worker (background.js).
 * Content script never calls fetch directly — all Gateway traffic
 * originates from the chrome-extension:// context.
 *
 * Logs request details (masked auth) for debug panel.
 * Never modifies the payload — pure transport.
 */

QSB.executor = {

  /**
   * Execute the currently staged payload against the selected workspace.
   * Sends message to background service worker; awaits response.
   */
  execute: function () {
    var payload = QSB.state.stagedPayload;
    if (!payload || QSB.state.isExecuting) return;

    var profile = QSB.getSelectedProfile();
    if (!profile) {
      QSB.state.logEntry({
        timestamp: new Date(),
        success: false,
        action: payload.gw_action || "unknown",
        message: "No workspace profile selected",
        rawResponse: null
      });
      return;
    }

    QSB.state.setExecuting(true);

    var maskedAuth = QSB.auth.maskHeader(profile);

    // Store request info for debug panel (masked)
    QSB.ui.setLastRequestInfo(
      "POST " + profile.endpoint + "\n" +
      "Authorization: " + maskedAuth + "\n" +
      "Content-Type: application/json\n" +
      "Workspace: " + profile.label + "\n" +
      "Payload action: " + (payload.gw_action || "unknown")
    );

    // Send to background service worker
    chrome.runtime.sendMessage(
      {
        type: "QSB_EXECUTE",
        payload: payload,
        profile: {
          endpoint: profile.endpoint,
          credential: profile.credential,
          auth_mode: profile.auth_mode
        }
      },
      function (response) {
        if (chrome.runtime.lastError) {
          QSB.ui.appendRequestInfo("Error: " + chrome.runtime.lastError.message);

          QSB.state.logEntry({
            timestamp: new Date(),
            success: false,
            action: payload.gw_action || "unknown",
            message: "Runtime: " + chrome.runtime.lastError.message,
            rawResponse: null
          });

          QSB.state.isExecuting = false;
          QSB.ui.render();
          return;
        }

        if (!response) {
          QSB.state.logEntry({
            timestamp: new Date(),
            success: false,
            action: payload.gw_action || "unknown",
            message: "No response from service worker",
            rawResponse: null
          });

          QSB.state.isExecuting = false;
          QSB.ui.render();
          return;
        }

        // Network or fetch error from background
        if (!response.ok) {
          QSB.ui.appendRequestInfo("Error: " + response.error);

          QSB.state.logEntry({
            timestamp: new Date(),
            success: false,
            action: payload.gw_action || "unknown",
            message: "Network: " + response.error,
            rawResponse: null
          });

          QSB.state.isExecuting = false;
          QSB.ui.render();
          return;
        }

        // Successful fetch — process Gateway response
        var data = response.data;
        QSB.ui.appendRequestInfo("Status: " + response.status + " " + response.statusText);

        if (data.ok === true) {
          var artifactId = (data.data && data.data.artifact && data.data.artifact.artifact_id)
            || data.artifact_id
            || null;
          var shortId = artifactId ? artifactId.substring(0, 8) : "ok";

          QSB.state.logEntry({
            timestamp: new Date(),
            success: true,
            action: payload.gw_action || "unknown",
            message: shortId,
            rawResponse: data
          });

          QSB.state.stagedPayload = null;
          QSB.state.isExecuting = false;
          QSB.ui.render();
          QSB.ui.autoPasteResponse(data);

        } else if (data.ok === false) {
          var errorCode = (data.error && data.error.code) || "Unknown error";

          QSB.state.logEntry({
            timestamp: new Date(),
            success: false,
            action: payload.gw_action || "unknown",
            message: errorCode,
            rawResponse: data
          });

          QSB.state.stagedPayload = null;
          QSB.state.isExecuting = false;
          QSB.ui.render();
          QSB.ui.autoPasteResponse(data);

        } else {
          // Response without ok field (list/query results)
          QSB.state.logEntry({
            timestamp: new Date(),
            success: true,
            action: payload.gw_action || "unknown",
            message: "Response received",
            rawResponse: data
          });

          QSB.state.stagedPayload = null;
          QSB.state.isExecuting = false;
          QSB.ui.render();
          QSB.ui.autoPasteResponse(data);
        }
      }
    );
  }
};
