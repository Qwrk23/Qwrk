/**
 * QSB Beta — Service Worker (Background)
 *
 * Handles all Gateway fetch() calls from the extension context.
 * Identical to Prime QSB background.js.
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

  return true;
});
