/**
 * QSB — Workspace Profiles (Akazanar Beta)
 *
 * Single-profile build for Akazanar beta user.
 * auth_mode: "basic" — uses shared Beta Gateway Basic Auth credential.
 * workspace_id injected automatically by executor.js into every payload.
 */

/* global chrome */

const QSB = {};

// --- Workspace Profiles ---------------------------------------------------

QSB.profiles = [
  {
    id: "qwrk-beta-akazanar",
    label: "Akazanar (Beta)",
    display_name: "Akara",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2/beta",
    credential: "REPLACE_WITH_BASE64_CREDENTIAL",
    auth_mode: "basic",
    workspace_id: "01c43873-9bfb-48fd-9eae-65a4d9e062f1"
  }
];

// --- Profile Selection ----------------------------------------------------

QSB.selectedProfileId = QSB.profiles[0].id;

/** @type {boolean} Auto-paste Gateway response into ChatGPT input after execution */
QSB.autoPaste = false;

QSB.loadProfile = function (callback) {
  chrome.storage.local.get(["qsb_selected_profile", "qsb_auto_paste"], function (result) {
    var saved = result.qsb_selected_profile;
    if (saved && QSB.profiles.some(function (p) { return p.id === saved; })) {
      QSB.selectedProfileId = saved;
    }
    if (result.qsb_auto_paste === true) {
      QSB.autoPaste = true;
    }
    if (callback) callback();
  });
};

QSB.setAutoPaste = function (enabled) {
  QSB.autoPaste = !!enabled;
  chrome.storage.local.set({ qsb_auto_paste: QSB.autoPaste });
};

QSB.setSelectedProfile = function (id) {
  QSB.selectedProfileId = id;
  chrome.storage.local.set({ qsb_selected_profile: id });
};

QSB.getSelectedProfile = function () {
  var match = QSB.profiles.find(function (p) { return p.id === QSB.selectedProfileId; });
  return match || QSB.profiles[0];
};
