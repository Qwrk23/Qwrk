/**
 * QSB Beta — Content Script Entry Point
 *
 * Boots QSB inside ChatGPT.
 */

/* global QSB, chrome */

(function () {
  "use strict";

  if (typeof QSB === "undefined") {
    console.error("QSB namespace not found — earlier script failed to load.");
    return;
  }

  // --- SPA Navigation Watcher ---------------------------------------------

  var lastUrl = location.href;

  function extractConversationId(url) {
    var match = url.match(/\/[cg]\/([a-f0-9-]+)/);
    return match ? match[1] : null;
  }

  var lastConversationId = extractConversationId(location.href);

  function checkNavigation() {
    if (location.href === lastUrl) return;

    var newConversationId = extractConversationId(location.href);
    lastUrl = location.href;

    if (newConversationId !== lastConversationId) {
      lastConversationId = newConversationId;

      if (QSB.state && QSB.parser) {
        QSB.state.clear();
        QSB.parser.resetFingerprint();
      }
    }
  }

  setInterval(checkNavigation, 500);
  window.addEventListener("popstate", checkNavigation);

  // --- Boot ---------------------------------------------------------------

  QSB.loadProfile(function () {
    if (QSB.ui) {
      QSB.ui.init();
    }

    if (QSB.parser) {
      QSB.parser.start();
    }
  });
})();
