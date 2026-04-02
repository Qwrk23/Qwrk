// Qx — Akara (Beta)
// Single-workspace JSON command console for Qwrk Beta via Gateway v2
// Uses Akara's existing workspace and credentials

// =============================================================================
// WORKSPACE PROFILE
// =============================================================================
// Uses Beta Gateway with Bearer auth + workspace_id auto-injection
// TODO (Option A): Create dedicated qwrk-gw-akara-beta principal + ACL entry
const WORKSPACE_PROFILES = [
  {
    id: "qwrk-beta-akara",
    label: "Akara (Beta)",
    display_name: "Akara",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2/beta",
    authorization: "Bearer as;dhfa;ew7)(uoahsho!3ihllaa",
    workspace_id: "963973e0-a98c-4044-b421-71e7348eaeaf"
  }
];
// =============================================================================

const STORAGE_KEY = "qwrk_selected_profile";

const profileSelect = document.getElementById("profile");
const payloadEl = document.getElementById("payload");
const sendBtn = document.getElementById("send");
const statusEl = document.getElementById("status");
const responseEl = document.getElementById("response");
const copyBtn = document.getElementById("copy");

// Populate profile dropdown
function populateProfiles() {
  profileSelect.innerHTML = "";
  WORKSPACE_PROFILES.forEach(p => {
    const opt = document.createElement("option");
    opt.value = p.id;
    opt.textContent = p.label;
    profileSelect.appendChild(opt);
  });
}

function getSelectedProfile() {
  const id = profileSelect.value;
  return WORKSPACE_PROFILES.find(p => p.id === id) || WORKSPACE_PROFILES[0];
}

// Persist selection across popup opens
function loadSavedProfile() {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved && WORKSPACE_PROFILES.some(p => p.id === saved)) {
    profileSelect.value = saved;
  }
}

profileSelect.addEventListener("change", () => {
  localStorage.setItem(STORAGE_KEY, profileSelect.value);
  updateProfileIndicator();
});

function updateProfileIndicator() {
  const profile = getSelectedProfile();
  sendBtn.textContent = "Send as " + (profile.display_name || profile.label);
}

// Initialize
populateProfiles();
loadSavedProfile();
updateProfileIndicator();

// Show user greeting
const greetingEl = document.getElementById("user-greeting");
if (greetingEl) {
  const profile = getSelectedProfile();
  greetingEl.textContent = "Qx — " + (profile.display_name || profile.label);
}

payloadEl.focus();

function setStatus(message, type) {
  statusEl.textContent = message;
  statusEl.className = type || "";
}

function setResponse(data) {
  responseEl.textContent = JSON.stringify(data, null, 2);
}

sendBtn.addEventListener("click", async () => {
  const raw = payloadEl.value.trim();
  const profile = getSelectedProfile();

  // Clear previous state
  setStatus("");
  setResponse({});

  // Validate: not empty
  if (!raw) {
    setStatus("Payload is empty", "error");
    return;
  }

  // Validate: parseable JSON
  let payload;
  try {
    payload = JSON.parse(raw);
  } catch (err) {
    setStatus("Invalid JSON: " + err.message, "error");
    return;
  }

  // Auto-inject workspace_id if not in payload (Beta CustomGPT doesn't include it)
  if (!payload.gw_workspace_id && profile.workspace_id) {
    payload.gw_workspace_id = profile.workspace_id;
  }

  // Send request
  setStatus("Sending to " + profile.label + "...");
  sendBtn.disabled = true;

  try {
    const response = await fetch(profile.endpoint, {
      method: "POST",
      headers: {
        "Authorization": profile.authorization,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    setResponse(data);

    if (data.ok === true) {
      const artifactId = data.data?.artifact?.artifact_id || data.artifact_id || null;
      if (artifactId) {
        setStatus("Success: " + artifactId.substring(0, 8) + "...", "success");
      } else {
        setStatus("Success", "success");
      }
    } else if (data.ok === false) {
      setStatus("Error: " + (data.error?.code || "Unknown"), "error");
    } else {
      setStatus("Response received", "success");
    }
  } catch (err) {
    setStatus("Network error: " + err.message, "error");
    setResponse({ error: err.message });
  } finally {
    sendBtn.disabled = false;
  }
});

// Copy response to clipboard
copyBtn.addEventListener("click", async () => {
  const text = responseEl.textContent;
  if (!text || text === "{}") {
    setStatus("Nothing to copy", "error");
    return;
  }
  try {
    await navigator.clipboard.writeText(text);
    const originalText = copyBtn.textContent;
    copyBtn.textContent = "Copied!";
    setTimeout(() => { copyBtn.textContent = originalText; }, 1500);
  } catch (err) {
    setStatus("Copy failed", "error");
  }
});
