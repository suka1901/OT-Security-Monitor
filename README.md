# OT Security Monitor — Fjärrvärme (District Heating)

This project demonstrates, end to end, how to **detect cyber‑attacks on operational technology (OT)** in a
district‑heating plant and turn detections into **NIST CSF 2.0 / NIS2‑aligned incident handling**
and a **risk‑/sårbarhetsanalys**, bridging IT/OT security, AI/ML and the regulatory frameworks.

## What it does
1. **Simulates** realistic district‑heating telemetry (supply/return temperature, flow, pump,
   pressure) driven by outdoor temperature and demand, with a control‑loop setpoint.
2. **Injects four OT attack scenarios** with ground truth:
   - Sensor spoofing / false data injection
   - Command injection (unauthorised setpoint change)
   - Replay attack
   - Ransomware‑like OT disruption (erratic actuator + lost telemetry)
3. **Detects** them by learning the normal baseline and flagging:
   - multivariate outliers (Mahalanobis distance),
   - broken physical relationships (physics residuals),
   - lost telemetry (availability).
4. **Reports**: figures + a **HTML report** mapping incidents to **NIST CSF 2.0** and the
   **NIS2 / cybersäkerhetslagen**, plus a
   **likelihood × consequence risk heatmap**.

## How to run
```matlab
cd OT-Security-Monitor
out = runDemo;                 % runs the full pipeline + builds the report
open(out.rep.html)             % open the Swedish HTML report
OTSecurityMonitor              % launch the interactive dashboard app
ot_build_simulink              % build & open the Simulink control-loop model
```

## Files
| File | Purpose |
|------|---------|
| `ot_config.m` | Parameters |
| `ot_simulate.m` | District-heating telemetry generator |
| `ot_inject_attacks.m` | Four attack scenarios + ground truth |
| `ot_detect.m` | Baseline anomaly + physics-residual detector (base MATLAB) |
| `ot_risk.m` | Likelihood × consequence risk model |
| `ot_report.m` | Figures + HTML report (CSF 2.0 / NIS2) |
| `runDemo.m` | End-to-end orchestrator |
| `ot_build_simulink.m` | Simulink PI control loop (plant + controller) |
| `OTSecurityMonitor.m` | Interactive uifigure dashboard |
| `output/` | Generated figures + `OT_Security_Report.html` |

## Why it matters
- **DETECT / RESPOND (CSF 2.0):** continuous monitoring and incident classification.
- **NIS2 / cybersäkerhetslagen:** automatic 24 h / 72 h / 1‑month reporting deadlines.
- **Risk‑ och sårbarhetsanalys:** structured likelihood × consequence scoring.
- **IT/OT:** detection works on real industrial signals, not just office IT.

> Synthetic data for demonstration. The model is simplified and illustrates method and
> workflow.

*Built with the MATLAB Agentic Toolkit workflow.*
