// Rita PoV Guide — Side Panel Logic
// Manages session lifecycle: start -> step-through -> completion.

(function () {
  "use strict";

  // ── Configuration ──────────────────────────────────────────────────────
  const API_BASE = "https://n8n.halosparkai.com/webhook/pov";

  // ── State ──────────────────────────────────────────────────────────────
  let sessionId = null;
  let currentStep = null;
  let stepNumber = 0;
  let totalSteps = 0;
  let scenarioName = "";

  // ── DOM References ─────────────────────────────────────────────────────
  const screenWelcome = document.getElementById("screen-welcome");
  const screenStep = document.getElementById("screen-step");
  const screenComplete = document.getElementById("screen-complete");
  const screenError = document.getElementById("screen-error");

  const btnStart = document.getElementById("btn-start");
  const btnCta = document.getElementById("btn-cta");
  const btnRestart = document.getElementById("btn-restart");
  const btnErrorRetry = document.getElementById("btn-error-retry");
  const btnValueToggle = document.getElementById("btn-value-toggle");

  const progressText = document.getElementById("progress-text");
  const scenarioNameEl = document.getElementById("scenario-name");
  const progressBarFill = document.getElementById("progress-bar-fill");
  const stepTypeBadge = document.getElementById("step-type-badge");
  const stepTitle = document.getElementById("step-title");
  const stepDescription = document.getElementById("step-description");
  const valueSection = document.getElementById("value-section");
  const valueMessage = document.getElementById("value-message");
  const completeSummary = document.getElementById("complete-summary");
  const errorMessage = document.getElementById("error-message");

  // ── Screen Management ──────────────────────────────────────────────────
  function showScreen(screen) {
    [screenWelcome, screenStep, screenComplete, screenError].forEach(function (s) {
      s.classList.remove("active");
    });
    screen.classList.add("active");
  }

  // ── API Helpers ────────────────────────────────────────────────────────
  async function apiPost(path, body) {
    const url = API_BASE + path;
    const options = {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    };
    const response = await fetch(url, options);
    if (!response.ok) {
      let detail = "";
      try {
        const errBody = await response.json();
        detail = errBody.message || errBody.error || JSON.stringify(errBody);
      } catch (_) {
        detail = response.statusText || "Request failed";
      }
      throw new Error(detail);
    }
    return response.json();
  }

  // ── Loading State ──────────────────────────────────────────────────────
  function setLoading(button, loading) {
    if (loading) {
      button.classList.add("loading");
      button.disabled = true;
    } else {
      button.classList.remove("loading");
      button.disabled = false;
    }
  }

  // ── Render Step ────────────────────────────────────────────────────────
  function renderStep(step, number, total) {
    currentStep = step;
    stepNumber = number;
    totalSteps = total;

    // Progress
    progressText.textContent = "Step " + number + " of " + total;
    const pct = Math.round((number / total) * 100);
    progressBarFill.style.width = pct + "%";

    // Scenario name
    if (scenarioName) {
      scenarioNameEl.textContent = scenarioName;
      scenarioNameEl.style.display = "";
    } else {
      scenarioNameEl.style.display = "none";
    }

    // Type badge
    const stepType = step.type || "instruction";
    stepTypeBadge.textContent = stepType;
    stepTypeBadge.setAttribute("data-type", stepType);

    // Title and description
    stepTitle.textContent = step.title || "";
    stepDescription.textContent = step.description || "";

    // CTA button label
    const ctaLabel = (step.ui && step.ui.cta_label) ? step.ui.cta_label : "Next";
    btnCta.textContent = ctaLabel;

    // Show/hide CTA based on ui.show_next
    const showNext = step.ui && step.ui.show_next !== undefined ? step.ui.show_next : true;
    btnCta.style.display = showNext ? "" : "none";

    // Value section
    const hasValue = step.value && step.value.message;
    if (hasValue) {
      valueSection.classList.remove("hidden");
      valueSection.classList.remove("expanded");
      valueMessage.textContent = step.value.message;
    } else {
      valueSection.classList.add("hidden");
      valueSection.classList.remove("expanded");
    }

    showScreen(screenStep);
  }

  // ── Start Session ──────────────────────────────────────────────────────
  async function startSession() {
    setLoading(btnStart, true);
    try {
      const data = await apiPost("/start", {});
      sessionId = data.session_id;
      scenarioName = data.scenario_name || "";
      totalSteps = data.total_steps || 0;
      renderStep(data.current_step, 1, data.total_steps);
    } catch (err) {
      showError(err.message || "Could not start the experience. Please try again.");
    } finally {
      setLoading(btnStart, false);
    }
  }

  // ── Advance to Next Step ───────────────────────────────────────────────
  async function advanceStep() {
    if (!sessionId || !currentStep) return;

    setLoading(btnCta, true);
    try {
      // If this is the last step, call complete
      if (stepNumber >= totalSteps) {
        await completeSession();
        return;
      }

      const data = await apiPost("/next", {
        session_id: sessionId,
        current_step_id: currentStep.step_id,
      });

      if (data.completed) {
        showCompletion(data.summary || "You have completed the guided experience.");
        return;
      }

      renderStep(data.current_step, data.step_number, data.total_steps);
    } catch (err) {
      showError(err.message || "Could not advance to the next step.");
    } finally {
      setLoading(btnCta, false);
    }
  }

  // ── Complete Session ───────────────────────────────────────────────────
  async function completeSession() {
    try {
      const data = await apiPost("/complete", {
        session_id: sessionId,
      });
      showCompletion(data.summary || "You have completed the guided experience.");
    } catch (err) {
      showError(err.message || "Could not finalize the experience.");
    }
  }

  // ── Completion Screen ──────────────────────────────────────────────────
  function showCompletion(summary) {
    completeSummary.textContent = summary;
    showScreen(screenComplete);
    resetState();
  }

  // ── Error Screen ───────────────────────────────────────────────────────
  function showError(message) {
    errorMessage.textContent = message;
    showScreen(screenError);
  }

  // ── Reset ──────────────────────────────────────────────────────────────
  function resetState() {
    sessionId = null;
    currentStep = null;
    stepNumber = 0;
    totalSteps = 0;
    scenarioName = "";
  }

  function returnToWelcome() {
    resetState();
    showScreen(screenWelcome);
  }

  // ── Value Toggle ───────────────────────────────────────────────────────
  function toggleValue() {
    valueSection.classList.toggle("expanded");
  }

  // ── Event Listeners ────────────────────────────────────────────────────
  btnStart.addEventListener("click", startSession);
  btnCta.addEventListener("click", advanceStep);
  btnRestart.addEventListener("click", returnToWelcome);
  btnErrorRetry.addEventListener("click", returnToWelcome);
  btnValueToggle.addEventListener("click", toggleValue);
})();
