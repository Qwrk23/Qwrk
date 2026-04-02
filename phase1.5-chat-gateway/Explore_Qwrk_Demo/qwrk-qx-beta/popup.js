// Qwrk Beta — JSON Command Console v1.0
// Single-profile, Bearer auth, workspace_id auto-injected

const PROFILE = {
  label: "Demo JBlagg",
  endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2/beta",
  authorization: "Bearer as;dhfa;ew7)(uoahsho!3ihllaa",
  workspace_id: "717c617f-c130-47de-83e5-759723123735"
};

const payloadEl = document.getElementById("payload");
const sendBtn = document.getElementById("send");
const statusEl = document.getElementById("status");
const responseEl = document.getElementById("response");
const copyBtn = document.getElementById("copy");
const badgeEl = document.getElementById("workspace-badge");

// Show workspace label
badgeEl.textContent = PROFILE.label;

function setStatus(message, type) {
  statusEl.textContent = message;
  statusEl.className = type || "";
}

function setResponse(data) {
  responseEl.textContent = JSON.stringify(data, null, 2);
}

sendBtn.addEventListener("click", async () => {
  const raw = payloadEl.value.trim();

  setStatus("");
  setResponse({});

  if (!raw) {
    setStatus("Payload is empty", "error");
    return;
  }

  let payload;
  try {
    payload = JSON.parse(raw);
  } catch (err) {
    setStatus("Invalid JSON: " + err.message, "error");
    return;
  }

  // Auto-inject workspace_id if not present
  if (!payload.gw_workspace_id && PROFILE.workspace_id) {
    payload.gw_workspace_id = PROFILE.workspace_id;
  }

  setStatus("Sending...");
  sendBtn.disabled = true;

  try {
    const response = await fetch(PROFILE.endpoint, {
      method: "POST",
      headers: {
        "Authorization": PROFILE.authorization,
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
