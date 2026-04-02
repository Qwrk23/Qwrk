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
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2",
    credential: "cXdyay1nYXRld2F5OmFzbGZqYSd3d2UqKCNmaHdvSUk4NDNnaGx3X2VrMmw=",
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
