
/**
 * QSB — Content Script Entry Point (Instrumented)
 *
 * Boots QSB inside ChatGPT.
 * Adds console instrumentation for debugging.
 */

/* global QSB, chrome */

(function () {
  "use strict";

  console.log("QSB content.js loaded");

  if (typeof QSB === "undefined") {
    console.error("QSB namespace not found — earlier script failed to load.");
    return;
  }

  console.log("QSB namespace detected");

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

    console.log("QSB navigation detected:", newConversationId);

    if (newConversationId !== lastConversationId) {
      lastConversationId = newConversationId;

      if (QSB.state && QSB.parser) {
        console.log("QSB clearing state + fingerprint");
        QSB.state.clear();
        QSB.parser.resetFingerprint();
      }
    }
  }

  setInterval(checkNavigation, 500);
  window.addEventListener("popstate", checkNavigation);

  // --- Boot ---------------------------------------------------------------

  QSB.loadProfile(function () {
    console.log("QSB profile loaded");

    if (QSB.ui) {
      QSB.ui.init();
      console.log("QSB UI initialized");
    }

    if (QSB.parser) {
      QSB.parser.start();
      console.log("QSB parser started");
    }
  });
})();