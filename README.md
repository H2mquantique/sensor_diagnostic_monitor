# Sensor Diagnostic Monitor

[![Verification](https://img.shields.io/badge/diag--logic%20checks-passing-brightgreen)](verify_diag_logic.js)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2022b-orange)](matlab/)
[![Simulink](https://img.shields.io/badge/Simulink%20%7C%20Stateflow%20%7C%20Embedded%20Coder-required-blue)](matlab/)
[![AUTOSAR](https://img.shields.io/badge/AUTOSAR-Classic%20SWC-lightgrey)](autosar/DiagMonitor.arxml)
[![ROS 2](https://img.shields.io/badge/ROS%202-Simulink%20Bridge-2496ED)](ros2_autosar_bridge.slx)
[![MIL/SIL](https://img.shields.io/badge/MIL%20%2F%20SIL-equivalence%20tested-brightgreen)](docs/test-plan.md)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## Overview

**Sensor Diagnostic Monitor** is a Model-Based Design (MBD) project focused on automotive sensor monitoring and fault diagnosis. It implements an OBD-style diagnostic monitor for a redundant analog sensor pair, using Simulink and Stateflow to detect abnormal sensor behavior, manage Diagnostic Trouble Codes (DTCs), control the Malfunction Indicator Lamp (MIL), and capture Freeze Frame data.

The diagnostic logic performs range, rate, and cross-signal rationality checks, applies fault debouncing, and manages the diagnostic lifecycle through a Stateflow-based supervisor.

The project was extended with an **AUTOSAR Classic software component configuration**, **C code and ARXML generation**, and a **ROS 2 / Simulink communication bridge**. MIL and SIL simulations were also executed using identical input data, with the four diagnostic outputs showing zero maximum error in the tested scenario.

The project demonstrates an automotive development workflow combining model-based design, software architecture, code generation, middleware communication, and model-to-code verification.

> This is an original, generic design based on public automotive diagnostic principles. It does not contain employer/client signals, calibrations, requirements, or proprietary structures.

---

## What it does

The monitor observes a redundant sensor pair, such as an accelerator-pedal position sensor pair (APP1 / APP2).

Its main functions include:

- **Range monitoring:** detects measurements outside their permitted operating range.
- **Rate monitoring:** detects implausible variations, spikes, or sudden changes.
- **Cross-signal correlation:** checks the consistency between redundant sensor measurements.
- **Fault debouncing:** avoids triggering a confirmed fault from a single transient measurement.
- **DTC management:** supervises diagnostic states such as `NO_FAULT`, `PENDING`, `CONFIRMED`, and `HEALING`.
- **Freeze Frame:** captures relevant operating parameters when a fault is confirmed.
- **MIL control:** activates or clears the malfunction indicator according to diagnostic status.
- **Healing:** manages the recovery process after a sustained period of valid measurements.

The implementation is organized around a Simulink model and a Stateflow diagnostic supervisor.

See [docs/design.md](docs/design.md) for the diagnostic logic and [docs/requirements.md](docs/requirements.md) for the requirements and traceability.

---

## Project extensions

### 1. AUTOSAR Classic configuration and code generation

A dedicated copy of the original Simulink model, `diag_monitor_autosar.slx`, was configured using the AUTOSAR Classic target.

The AUTOSAR configuration includes:

- A diagnostic Software Component (SWC).
- Sender-Receiver input and output ports.
- Runnable configuration for initialization and periodic execution.
- A periodic Step event configured with a 10 ms period.
- Data mapping using `ImplicitReceive` and `ImplicitSend`.
- Generated C source files, headers, and AUTOSAR ARXML descriptions.

The generated ARXML files were successfully parsed as XML using MATLAB. This confirms their XML syntax, but does not constitute full XSD validation or validation in an AUTOSAR integration environment.

### 2. ROS 2 / Simulink communication bridge

A dedicated Simulink model, `ros2_autosar_bridge.slx`, was created to demonstrate communication between ROS 2 topics and the diagnostic algorithm.

It receives five sensor measurements:

| Input | ROS 2 topic |
|---|---|
| v1 | `/vehicle/sensor/v1` |
| v2 | `/vehicle/sensor/v2` |
| rpm | `/vehicle/sensor/rpm` |
| load | `/vehicle/sensor/load` |
| ect | `/vehicle/sensor/ect` |

It publishes four diagnostic results:

| Output | ROS 2 topic |
|---|---|
| state | `/vehicle/diagnostic/state` |
| dtc | `/vehicle/diagnostic/dtc` |
| mil | `/vehicle/diagnostic/mil` |
| ff_valid | `/vehicle/diagnostic/ff_valid` |

The end-to-end test successfully received the expected diagnostic messages for the tested input scenario.

**Implementation note:** the ROS 2 bridge currently executes the original Simulink model configured with the GRT target. The AUTOSAR-configured model is a separate copy used for AUTOSAR configuration and code generation. The generated AUTOSAR code has not yet been integrated into an AUTOSAR RTE connected to ROS 2.

### 3. MIL / SIL verification

The diagnostic algorithm was tested in both Model-in-the-Loop (MIL) and Software-in-the-Loop (SIL) modes.

The same input Dataset was supplied to both simulations over a 6-second test duration. The resulting output signals were compared over 601 time samples.

| Diagnostic output | MIL final | SIL final | Maximum error |
|---|---:|---:|---:|
| state | 2 | 2 | 0 |
| dtc | 4 | 4 | 0 |
| mil | 1 | 1 | 0 |
| ff_valid | 1 | 1 | 0 |

**Result: 4/4 outputs matched, with zero maximum error in the tested scenario.**

This demonstrates MIL/SIL equivalence for the selected test case. It does not establish exhaustive verification of all diagnostic scenarios or formal safety compliance.

---

## Repository layout

```text
sensor-diagnostic-monitor/
├── README.md
├── docs/
│   ├── requirements.md
│   ├── design.md
│   └── test-plan.md
├── matlab/
│   ├── diag_params.m
│   ├── diag_const.m
│   ├── build_model.m
│   ├── run_mil.m
│   ├── run_sil.m
│   ├── gen_code.m
│   ├── collect_coverage.m
│   └── test/
│       └── test_diag_monitor.m
├── autosar/
│   └── DiagMonitor.arxml
├── diag_monitor.slx
├── diag_monitor_autosar.slx
├── ros2_autosar_bridge.slx
├── generated/
├── assets/
├── presentation/
└── verify_diag_logic.js
```

*Note: some generated folders and artifacts are created locally when the MATLAB workflow is executed. Their presence in the repository depends on what has been committed.*

---

## Headless verification (no MATLAB required)

The diagnostic logic can be checked independently using Node.js:

```bash
node verify_diag_logic.js
```

The verification script checks the main diagnostic behaviors, including:

- Range and out-of-range detection.
- Rate and spike detection.
- Sensor correlation faults.
- Fault confirmation and debouncing.
- Prevention of false trips caused by a one-sample glitch.
- Freeze Frame capture.
- MIL activation.
- Fault healing and MIL clearing.
- Enable-condition handling.
- Output range validity.

Expected result:

```text
ALL CHECKS PASSED
```

---

## MATLAB toolchain

### Requirements

The project was developed and tested with MATLAB R2022b and the following products:

- Simulink
- Stateflow
- Embedded Coder
- Simulink Coder
- AUTOSAR Blockset
- Simulink Coverage
- ROS Toolbox

### Load diagnostic parameters

```matlab
run('matlab\diag_params.m');
```

### Run the original diagnostic model

```matlab
open_system('diag_monitor.slx');
sim('diag_monitor');
```

### Build the AUTOSAR model

```matlab
open_system('diag_monitor_autosar.slx');
slbuild('diag_monitor_autosar');
```

The AUTOSAR-generated files are produced in the model's code-generation output directory.

### Open the ROS 2 bridge

```matlab
open_system('ros2_autosar_bridge.slx');
```

The bridge requires a compatible ROS 2 environment and the ROS Toolbox.

### MIL / SIL verification

MIL and SIL simulations should use the same input Dataset and simulation duration. Compare the corresponding output signals (`state`, `dtc`, `mil`, and `ff_valid`) to assess model-to-code equivalence.

---

## Model-Based Design workflow

| Stage | Description | Main artifact |
|---|---|---|
| Requirements | Diagnostic requirements and traceability | `docs/requirements.md` |
| Design | Simulink / Stateflow diagnostic model | `diag_monitor.slx` |
| Model-in-the-Loop | Simulation of the diagnostic model | MIL simulation results |
| Code generation | AUTOSAR C code and ARXML generation | `diag_monitor_autosar` build |
| Software-in-the-Loop | Execution of generated code in SIL mode | MIL/SIL comparison |
| Structural coverage | Decision, condition and MC/DC analysis | Simulink Coverage report |
| AUTOSAR architecture | SWC, ports, interfaces and runnables | `autosar/DiagMonitor.arxml` |
| Middleware communication | Sensor input and diagnostic output topics | `ros2_autosar_bridge.slx` |

---

## Verification status

- [x] Diagnostic requirements and design documentation.
- [x] Simulink / Stateflow diagnostic model.
- [x] Headless diagnostic logic checks.
- [x] AUTOSAR Classic model configuration.
- [x] AUTOSAR C code and ARXML generation.
- [x] XML syntax parsing of generated ARXML files.
- [x] ROS 2 publisher/subscriber communication tests.
- [x] Simulink / ROS 2 end-to-end diagnostic test.
- [x] MIL simulation with a defined input Dataset.
- [x] SIL simulation with the same input Dataset.
- [x] MIL/SIL comparison: four outputs matched with zero maximum error for the tested scenario.
- [x] Coverage report obtained, including 100% decision, condition, and MC/DC coverage for the reported objectives.
- [ ] Exhaustive multi-scenario MIL/SIL regression campaign.
- [ ] Full AUTOSAR RTE integration and execution on a target ECU.
- [ ] Full ARXML XSD and AUTOSAR integration validation.
- [ ] HIL testing and vehicle-level validation.

**Safety note:** this project is an academic engineering demonstration. It does not claim ISO 26262 compliance, a definitive ASIL classification, or production ECU qualification.

---

## Related automotive MBD projects

This project belongs to a set of automotive Model-Based Design projects:

- [boost-pressure-control](https://github.com/SaaimSaad/boost-pressure-control) — diesel turbocharger boost-pressure control.
- [torque-safety-monitor](https://github.com/SaaimSaad/torque-safety-monitor) — functional-safety-oriented torque monitoring.

---

## License

MIT — see [LICENSE](LICENSE).

Original generic engineering project; no third-party or proprietary content.
