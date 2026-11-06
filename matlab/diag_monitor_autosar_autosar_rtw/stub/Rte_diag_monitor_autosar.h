/* This file contains stub implementations of the AUTOSAR RTE functions.
   The stub implementations can be used for testing the generated code in
   Simulink, for example, in SIL/PIL simulations of the component under
   test. Note that this file should be replaced with an appropriate RTE
   file when deploying the generated code outside of Simulink.

   This file is generated for:
   Atomic software component:  "diag_monitor_autosar"
   ARXML schema: "R20-11"
   File generated on: "06-Nov-2026 11:58:52"  */

#ifndef Rte_diag_monitor_autosar_h
#define Rte_diag_monitor_autosar_h
#include "Rte_Type.h"
#include "Compiler.h"

/* Data access functions */
#define Rte_IRead_diag_monitor_autosar_Step_ect_ect Rte_IRead_diag_monitor_autosar_diag_monitor_autosar_Step_ect_ect

Double Rte_IRead_diag_monitor_autosar_Step_ect_ect(void);

#define Rte_IRead_diag_monitor_autosar_Step_v1_v1 Rte_IRead_diag_monitor_autosar_diag_monitor_autosar_Step_v1_v1

Double Rte_IRead_diag_monitor_autosar_Step_v1_v1(void);

#define Rte_IRead_diag_monitor_autosar_Step_v2_v2 Rte_IRead_diag_monitor_autosar_diag_monitor_autosar_Step_v2_v2

Double Rte_IRead_diag_monitor_autosar_Step_v2_v2(void);

#define Rte_IWrite_diag_monitor_autosar_Step_state_state Rte_IWrite_diag_monitor_autosar_diag_monitor_autosar_Step_state_state

void Rte_IWrite_diag_monitor_autosar_Step_state_state(UInt8 u);

#define Rte_IWriteRef_diag_monitor_autosar_Step_state_state Rte_IWriteRef_diag_monitor_autosar_diag_monitor_autosar_Step_state_state

UInt8* Rte_IWriteRef_diag_monitor_autosar_Step_state_state(void);

#define Rte_IWrite_diag_monitor_autosar_Step_dtc_dtc Rte_IWrite_diag_monitor_autosar_diag_monitor_autosar_Step_dtc_dtc

void Rte_IWrite_diag_monitor_autosar_Step_dtc_dtc(UInt8 u);

#define Rte_IWriteRef_diag_monitor_autosar_Step_dtc_dtc Rte_IWriteRef_diag_monitor_autosar_diag_monitor_autosar_Step_dtc_dtc

UInt8* Rte_IWriteRef_diag_monitor_autosar_Step_dtc_dtc(void);

#define Rte_IWrite_diag_monitor_autosar_Step_mil_mil Rte_IWrite_diag_monitor_autosar_diag_monitor_autosar_Step_mil_mil

void Rte_IWrite_diag_monitor_autosar_Step_mil_mil(Boolean u);

#define Rte_IWriteRef_diag_monitor_autosar_Step_mil_mil Rte_IWriteRef_diag_monitor_autosar_diag_monitor_autosar_Step_mil_mil

Boolean* Rte_IWriteRef_diag_monitor_autosar_Step_mil_mil(void);

#define Rte_IWrite_diag_monitor_autosar_Step_ff_valid_ff_valid Rte_IWrite_diag_monitor_autosar_diag_monitor_autosar_Step_ff_valid_ff_valid

void Rte_IWrite_diag_monitor_autosar_Step_ff_valid_ff_valid(Boolean u);

#define Rte_IWriteRef_diag_monitor_autosar_Step_ff_valid_ff_valid Rte_IWriteRef_diag_monitor_autosar_diag_monitor_autosar_Step_ff_valid_ff_valid

Boolean* Rte_IWriteRef_diag_monitor_autosar_Step_ff_valid_ff_valid(void);

/* Entry point functions */
extern FUNC(void, diag_monitor_autosar_CODE) diag_monitor_autosar_Init(void);
extern FUNC(void, diag_monitor_autosar_CODE) diag_monitor_autosar_Step(void);

#endif
