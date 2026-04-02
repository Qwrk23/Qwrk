/**
 * QSB Beta — Workspace Profile
 *
 * Single-profile configuration for beta users.
 * workspace_id is injected into every payload automatically by the executor.
 * The user (and the GPT) never need to know the workspace_id.
 */

/* global chrome */

var QSB = {};

// --- Workspace Profile -------------------------------------------------------

QSB.profiles = [
  {
    id: "qwrk-beta",
    label: "Demo JBlagg",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2/beta",
    credential: "as;dhfa;ew7)(uoahsho!3ihllaa",
    auth_mode: "bearer",
    workspace_id: "717c617f-c130-47de-83e5-759723123735"
  }
];

// --- Profile Selection (single profile — no switching) -----------------------

QSB.selectedProfileId = QSB.profiles[0].id;

/** @type {boolean} Auto-paste Gateway response into ChatGPT input after execution */
QSB.autoPaste = false;

QSB.loadProfile = function (callback) {
  chrome.storage.local.get(["qsb_selected_profile", "qsb_auto_paste"], function (result) {
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
  return QSB.profiles[0];
};
