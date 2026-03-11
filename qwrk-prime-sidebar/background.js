/**
 * QSB — Service Worker (Background)
 *
 * Handles all Gateway fetch() calls from the extension context.
 * Content script sends payload + profile via chrome.runtime.sendMessage.
 * This avoids origin issues (requests come from chrome-extension://, not chatgpt.com).
 *
 * Message contract:
 *   Request:  { type: "QSB_EXECUTE", payload: object, profile: object }
 *   Response: { ok: true, status: number, statusText: string, data: object }
 *          OR { ok: false, error: string, status: number, statusText: string }
 *          OR { ok: false, error: string }  (network failure)
 */

/* global chrome */

chrome.runtime.onMessage.addListener(function (message, sender, sendResponse) {
  if (message.type !== "QSB_EXECUTE") return false;

  var payload = message.payload;
  var profile = message.profile;

  if (!payload || !profile || !profile.endpoint || !profile.credential) {
    sendResponse({ ok: false, error: "Missing payload or profile" });
    return false;
  }

  // Build auth header
  var mode = profile.auth_mode || "basic";
  var authValue;
  if (mode === "bearer") {
    authValue = "Bearer " + profile.credential;
  } else {
    authValue = "Basic " + profile.credential;
  }

  fetch(profile.endpoint, {
    method: "POST",
    headers: {
      "Authorization": authValue,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(payload)
  })
  .then(function (response) {
    var status = response.status;
    var statusText = response.statusText;
    return response.json().then(function (data) {
      sendResponse({ ok: true, status: status, statusText: statusText, data: data });
    });
  })
  .catch(function (err) {
    sendResponse({ ok: false, error: err.message });
  });

  // Return true to keep the message channel open for async sendResponse
  return true;
});
