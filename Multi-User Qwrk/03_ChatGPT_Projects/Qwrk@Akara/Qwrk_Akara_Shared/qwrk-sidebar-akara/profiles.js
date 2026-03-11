/**
 * QSB — Workspace Profiles (Akara)
 * Single-profile version.
 */

/* global chrome */

const QSB = {};

QSB.profiles = [
  {
    id: "qwrk-akara",
    label: "Akara",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/akara",
    credential: "cXdyay1ndy1ha2FyYTpzYTtsODIzNGh0MjkxJilramxoZGFoIWUzODBkamthaHQqdWhrd2U=",
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
