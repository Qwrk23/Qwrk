/**
 * QSB — Workspace Profiles
 *
 * Same model as QX: hardcoded profiles with per-profile endpoint + credential.
 * auth_mode: "basic" (v1 default) | "bearer" (future)
 * Selected profile persisted via chrome.storage.local.
 */

/* global chrome */

const QSB = {};

// --- Workspace Profiles ---------------------------------------------------

QSB.profiles = [
  {
    id: "qwrk-personal",
    label: "Qwrk Prime",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2",
    credential: "cXdyay1nYXRld2F5OmFzbGZqYSd3d2UqKCNmaHdvSUk4NDNnaGx3X2VrMmw=",
    auth_mode: "basic",
    home_workspace_id: "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
  },
  {
    id: "qwrk-beta",
    label: "Qwrk Beta",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2/beta",
    credential: "as;dhfa;ew7)(uoahsho!3ihllaa",
    auth_mode: "bearer",
    workspace_id: "717c617f-c130-47de-83e5-759723123735",
    home_workspace_id: "717c617f-c130-47de-83e5-759723123735"
  }
];

// --- Cross-Workspace Write Gate: Workspace Display Names -----------------
// Used by executor.js to render human-readable confirmation dialogs.
// Add entries only when workspace UUID is explicitly confirmed.

QSB.workspaceNames = {
  "be0d3a48-c764-44f9-90c8-e846d9dbbd0a": "Prime",
  "635bb8d7-7b93-4bea-8ca6-ee2c924c9557": "Q@W",
  "b4e7f648-96d5-44a7-80b9-c39cac4efbd1": "BlaggLife",
  "963973e0-a98c-4044-b421-71e7348eaeaf": "Akara",
  "970d0df8-ab84-47f5-926c-3e784ba5dfa2": "Greg",
  "0af5712b-2534-47c1-8e28-45be4a2131dc": "Explore Qwrk Demo"
};

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
