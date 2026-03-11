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
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1",
    credential: "cXdyay1nYXRld2F5OmFzbGZqYSd3d2UqKCNmaHdvSUk4NDNnaGx3X2VrMmw=",
    auth_mode: "basic"
  },
  {
    id: "qwrk-work",
    label: "Qwrk@Work",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/work",
    credential: "cXdyay1ndy13b3JrOnVmd3BqTkYwUEVNcTRSOTJTVDZ6S1FNNWVlVnM3Qm5N",
    auth_mode: "basic"
  },
  {
    id: "qwrk-blagglife",
    label: "BlaggLife",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/blagglife",
    credential: "cXdyay1ndy1ibGFnZ2xpZmU6ZmprczBmZ2hsMjhnaGxzayZ0Z2woaGRoYWx4aGxzZWhlJmx3ZWxraGc=",
    auth_mode: "basic"
  },
  {
    id: "qwrk-akara",
    label: "Akara",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/akara",
    credential: "cXdyay1ndy1ha2FyYTpzYTtsODIzNGh0MjkxJilramxoZGFoIWUzODBkamthaHQqdWhrd2U=",
    auth_mode: "basic"
  },
  {
    id: "qwrk-greg",
    label: "Greg",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/greg",
    credential: "cXdyay1ndy1ncmVnOkRsbExUaEhNVFpuRU5ZZndmOFhjR3J0Z0pMdGlvRHpWdDhvdGpSSldJNUE=",
    auth_mode: "basic"
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
