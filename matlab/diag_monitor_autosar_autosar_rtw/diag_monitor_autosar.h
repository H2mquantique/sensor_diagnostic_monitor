/*
 * File: diag_monitor_autosar.h
 *
 * Code generated for Simulink model 'diag_monitor_autosar'.
 *
 * Model version                  : 1.2
 * Simulink Coder version         : 9.8 (R2022b) 13-May-2022
 * C/C++ source code generated on : Fri Nov  6 11:58:44 2026
 *
 * Target selection: autosar.tlc
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef RTW_HEADER_diag_monitor_autosar_h_
#define RTW_HEADER_diag_monitor_autosar_h_
#ifndef diag_monitor_autosar_COMMON_INCLUDES_
#define diag_monitor_autosar_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "Rte_diag_monitor_autosar.h"
#endif                               /* diag_monitor_autosar_COMMON_INCLUDES_ */

#include "diag_monitor_autosar_types.h"

/* PublicStructure Variables for Internal Data, for system '<Root>' */
typedef struct {
  float64 v1_z_DSTATE;                 /* '<S1>/v1_z' */
  float64 healCnt;                     /* '<S1>/Supervisor' */
  float64 fc;                          /* '<S1>/Rationality' */
  uint8 dtc;                           /* '<S1>/Supervisor' */
  uint8 is_c3_diag_monitor_autosar;    /* '<S1>/Supervisor' */
  uint8 is_active_c3_diag_monitor_autos;/* '<S1>/Supervisor' */
  boolean ff_valid;                    /* '<S1>/Supervisor' */
  boolean prev_valid;                  /* '<S1>/Rationality' */
} ARID_DEF_diag_monitor_autosar_T;

/* PublicStructure Variables for Internal Data */
extern ARID_DEF_diag_monitor_autosar_T diag_monitor_autosar_ARID_DEF;/* '<S1>/v1_z' */

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'diag_monitor_autosar'
 * '<S1>'   : 'diag_monitor_autosar/DiagMonitor'
 * '<S2>'   : 'diag_monitor_autosar/DiagMonitor/Rationality'
 * '<S3>'   : 'diag_monitor_autosar/DiagMonitor/Supervisor'
 */
#endif                                 /* RTW_HEADER_diag_monitor_autosar_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
