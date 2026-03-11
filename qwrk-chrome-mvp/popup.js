// Qwrk Chrome Extension - JSON Command Console v1.2
// Purpose: Send arbitrary JSON payloads to Qwrk Gateway
// Supports multi-workspace profile switching

// =============================================================================
// WORKSPACE PROFILES
// =============================================================================
// To add a new workspace: add an entry to this array.
// credential = base64("principal:password") — generate with btoa() in console.
const WORKSPACE_PROFILES = [
  {
    id: "qwrk-personal",
    label: "Qwrk Prime",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1",
    credential: "cXdyay1nYXRld2F5OmFzbGZqYSd3d2UqKCNmaHdvSUk4NDNnaGx3X2VrMmw="
  },
  {
    id: "qwrk-work",
    label: "Qwrk@Work",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/work",
    credential: "cXdyay1ndy13b3JrOnVmd3BqTkYwUEVNcTRSOTJTVDZ6S1FNNWVlVnM3Qm5N"
  },
  {
    id: "qwrk-blagglife",
    label: "BlaggLife",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/blagglife",
    credential: "cXdyay1ndy1ibGFnZ2xpZmU6ZmprczBmZ2hsMjhnaGxzayZ0Z2woaGRoYWx4aGxzZWhlJmx3ZWxraGc="
  },
  {
    id: "qwrk-akara",
    label: "Akara",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/akara",
    credential: "cXdyay1ndy1ha2FyYTpzYTtsODIzNGh0MjkxJilramxoZGFoIWUzODBkamthaHQqdWhrd2U="
  },
  {
    id: "qwrk-greg",
    label: "Greg",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/greg",
    credential: "cXdyay1ndy1ncmVnOkRsbExUaEhNVFpuRU5ZZndmOFhjR3J0Z0pMdGlvRHpWdDhvdGpSSldJNUE="
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
  sendBtn.textContent = "Send to " + profile.label;
}

// Initialize
populateProfiles();
loadSavedProfile();
updateProfileIndicator();
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
    console.error("[Qwrk] JSON parse error:", err);
    return;
  }

  // Send request
  setStatus("Sending to " + profile.label + "...");
  sendBtn.disabled = true;

  console.log("[Qwrk] Profile:", JSON.stringify(profile, null, 2));
  console.log("[Qwrk] Endpoint:", profile.endpoint);
  console.log("[Qwrk] Credential present:", !!profile.credential, "Length:", (profile.credential || "").length);
  console.log("[Qwrk] Authorization header:", "Basic " + profile.credential);
  console.log("[Qwrk] Request payload:", JSON.stringify(payload, null, 2));

  try {
    const response = await fetch(profile.endpoint, {
      method: "POST",
      headers: {
        "Authorization": "Basic " + profile.credential,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();
    console.log("[Qwrk] Response:", JSON.stringify(data, null, 2));

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
    console.error("[Qwrk] Network error:", err);
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
    console.error("[Qwrk] Copy error:", err);
  }
});
