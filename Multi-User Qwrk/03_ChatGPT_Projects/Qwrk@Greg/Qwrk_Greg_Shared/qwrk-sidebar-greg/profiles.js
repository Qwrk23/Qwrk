/**
 * QSB — Workspace Profiles (Greg)
 * Single-profile version.
 */

/* global chrome */

const QSB = {};

QSB.profiles = [
  {
    id: "qwrk-greg",
    label: "Greg",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2",
    credential: "cXdyay1ndy1ncmVnOkRsbExUaEhNVFpuRU5ZZndmOFhjR3J0Z0pMdGlvRHpWdDhvdGpSSldJNUE=",
    auth_mode: "basic"
  }
];

QSB.selectedProfileId = QSB.profiles[0].id;

QSB.loadProfile = function (callback) {
  if (callback) callback();
};

QSB.setSelectedProfile = function (id) {
  QSB.selectedProfileId = id;
};

QSB.getSelectedProfile = function () {
  return QSB.profiles[0];
};
