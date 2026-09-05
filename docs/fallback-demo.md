# VEILOS Fallback Demo & Recovery Plan

If unexpected hardware, display, or network issues occur during a live hackathon presentation, follow these controlled fallbacks:

---

## Scenario A: Internet Down at Hackathon Venue
1. **Action:** Demonstrate the offline security capability using **App Testing** profile:
   ```bash
   veil-run --profile app-testing
   ```
2. **Talking Point:** *"Notice that VEILOS operates completely offline. The App Testing workspace enforces an air-gapped network policy via kernel network unsharing, proving local zero-trust isolation."*

---

## Scenario B: Display or Graphical Artifact Glitches
1. **Action:** Switch to terminal demonstration using the diagnostic verification CLI:
   ```bash
   veil-hackathon-demo
   tests/demo-smoke-test.sh
   ```
2. **Talking Point:** *"All VEILOS controls are managed by an underlying deterministic policy engine. Here, our automated smoke test runs the complete 15-step lifecycle right in the terminal with live cryptographic destruction verification."*

---

## Scenario C: Stale Workspaces from Previous Practice Runs
1. **Action:** Execute the safe one-command demo reset:
   ```bash
   veil-demo-reset
   ```
2. **Result:** Instantly cleans RAM workspace state without killing unrelated processes.
