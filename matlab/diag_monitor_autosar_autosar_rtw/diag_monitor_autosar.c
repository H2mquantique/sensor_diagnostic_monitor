/*
 * File: diag_monitor_autosar.c
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

#include "diag_monitor_autosar.h"
#include "rtwtypes.h"
#include <math.h>

/* Named constants for Chart: '<S1>/Supervisor' */
#define diag_monitor_autos_IN_CONFIRMED ((uint8)1U)
#define diag_monitor_autosa_IN_NO_FAULT ((uint8)3U)
#define diag_monitor_autosar_IN_HEALING ((uint8)2U)
#define diag_monitor_autosar_IN_PENDING ((uint8)4U)

/* PublicStructure Variables for Internal Data */
ARID_DEF_diag_monitor_autosar_T diag_monitor_autosar_ARID_DEF;/* '<S1>/v1_z' */

/* Forward declaration for local functions */
static void diag_mon_enter_atomic_CONFIRMED(uint8 *state, boolean *mil, const
  uint8 *testbits);

/* Function for Chart: '<S1>/Supervisor' */
static void diag_mon_enter_atomic_CONFIRMED(uint8 *state, boolean *mil, const
  uint8 *testbits)
{
  *state = 2U;
  *mil = true;
  if (!diag_monitor_autosar_ARID_DEF.ff_valid) {
    diag_monitor_autosar_ARID_DEF.dtc = *testbits;
    diag_monitor_autosar_ARID_DEF.ff_valid = true;
  }
}

/* Model step function */
void diag_monitor_autosar_Step(void)
{
  float64 range_bad_tmp_tmp;
  uint8 state;
  uint8 testbits;
  boolean any_bad;
  boolean corr_bad;
  boolean mil;
  boolean range_bad;

  /* Outputs for Atomic SubSystem: '<Root>/DiagMonitor' */
  /* MATLAB Function: '<S1>/Rationality' incorporates:
   *  Inport: '<Root>/ect'
   *  Inport: '<Root>/v1'
   *  Inport: '<Root>/v2'
   *  UnitDelay: '<S1>/v1_z'
   * */
  range_bad_tmp_tmp = Rte_IRead_diag_monitor_autosar_Step_v1_v1();
  range_bad = ((range_bad_tmp_tmp < 0.2) || (range_bad_tmp_tmp > 4.8));
  mil = (diag_monitor_autosar_ARID_DEF.prev_valid && (fabs(range_bad_tmp_tmp -
           diag_monitor_autosar_ARID_DEF.v1_z_DSTATE) > 1.5));
  diag_monitor_autosar_ARID_DEF.prev_valid = true;
  corr_bad = (fabs((range_bad_tmp_tmp - 0.5) / 4.0 * 100.0 -
                   (Rte_IRead_diag_monitor_autosar_Step_v2_v2() - 0.25) / 2.0 *
                   100.0) > 10.0);
  any_bad = (range_bad || mil || corr_bad);
  testbits = (uint8)(((mil << 1) + range_bad) + (corr_bad << 2));
  range_bad = (Rte_IRead_diag_monitor_autosar_Step_ect_ect() >= 60.0);
  if (range_bad) {
    if (any_bad) {
      diag_monitor_autosar_ARID_DEF.fc = fmin(diag_monitor_autosar_ARID_DEF.fc +
        1.0, 20.0);
    } else {
      diag_monitor_autosar_ARID_DEF.fc = fmax(diag_monitor_autosar_ARID_DEF.fc -
        1.0, 0.0);
    }
  }

  /* Chart: '<S1>/Supervisor' incorporates:
   *  MATLAB Function: '<S1>/Rationality'
   */
  if (diag_monitor_autosar_ARID_DEF.is_active_c3_diag_monitor_autos == 0U) {
    diag_monitor_autosar_ARID_DEF.is_active_c3_diag_monitor_autos = 1U;
    diag_monitor_autosar_ARID_DEF.is_c3_diag_monitor_autosar =
      diag_monitor_autosa_IN_NO_FAULT;
    state = 0U;
    mil = false;
    diag_monitor_autosar_ARID_DEF.dtc = 0U;
    diag_monitor_autosar_ARID_DEF.ff_valid = false;
    diag_monitor_autosar_ARID_DEF.healCnt = 0.0;
  } else {
    switch (diag_monitor_autosar_ARID_DEF.is_c3_diag_monitor_autosar) {
     case diag_monitor_autos_IN_CONFIRMED:
      state = 2U;
      mil = true;
      if (range_bad && (!any_bad)) {
        diag_monitor_autosar_ARID_DEF.is_c3_diag_monitor_autosar =
          diag_monitor_autosar_IN_HEALING;
        state = 3U;
        diag_monitor_autosar_ARID_DEF.healCnt = 0.0;
      } else {
        diag_monitor_autosar_ARID_DEF.dtc |= testbits;
      }
      break;

     case diag_monitor_autosar_IN_HEALING:
      state = 3U;
      mil = true;
      if (any_bad) {
        diag_monitor_autosar_ARID_DEF.is_c3_diag_monitor_autosar =
          diag_monitor_autos_IN_CONFIRMED;
        diag_mon_enter_atomic_CONFIRMED(&state, &mil, &testbits);
      } else if (diag_monitor_autosar_ARID_DEF.healCnt >= 300.0) {
        diag_monitor_autosar_ARID_DEF.is_c3_diag_monitor_autosar =
          diag_monitor_autosa_IN_NO_FAULT;
        state = 0U;
        mil = false;
        diag_monitor_autosar_ARID_DEF.dtc = 0U;
        diag_monitor_autosar_ARID_DEF.ff_valid = false;
        diag_monitor_autosar_ARID_DEF.healCnt = 0.0;
      } else {
        diag_monitor_autosar_ARID_DEF.healCnt++;
      }
      break;

     case diag_monitor_autosa_IN_NO_FAULT:
      state = 0U;
      mil = false;
      if (diag_monitor_autosar_ARID_DEF.fc > 0.0) {
        diag_monitor_autosar_ARID_DEF.is_c3_diag_monitor_autosar =
          diag_monitor_autosar_IN_PENDING;
        state = 1U;
      }
      break;

     default:
      /* case IN_PENDING: */
      state = 1U;
      mil = false;
      if (diag_monitor_autosar_ARID_DEF.fc >= 20.0) {
        diag_monitor_autosar_ARID_DEF.is_c3_diag_monitor_autosar =
          diag_monitor_autos_IN_CONFIRMED;
        diag_mon_enter_atomic_CONFIRMED(&state, &mil, &testbits);
      } else if (diag_monitor_autosar_ARID_DEF.fc == 0.0) {
        diag_monitor_autosar_ARID_DEF.is_c3_diag_monitor_autosar =
          diag_monitor_autosa_IN_NO_FAULT;
        state = 0U;
        diag_monitor_autosar_ARID_DEF.dtc = 0U;
        diag_monitor_autosar_ARID_DEF.ff_valid = false;
        diag_monitor_autosar_ARID_DEF.healCnt = 0.0;
      }
      break;
    }
  }

  /* End of Chart: '<S1>/Supervisor' */

  /* Update for UnitDelay: '<S1>/v1_z' */
  diag_monitor_autosar_ARID_DEF.v1_z_DSTATE = range_bad_tmp_tmp;

  /* End of Outputs for SubSystem: '<Root>/DiagMonitor' */

  /* Outport: '<Root>/state' */
  Rte_IWrite_diag_monitor_autosar_Step_state_state(state);

  /* Outport: '<Root>/dtc' */
  Rte_IWrite_diag_monitor_autosar_Step_dtc_dtc(diag_monitor_autosar_ARID_DEF.dtc);

  /* Outport: '<Root>/mil' */
  Rte_IWrite_diag_monitor_autosar_Step_mil_mil(mil);

  /* Outport: '<Root>/ff_valid' */
  Rte_IWrite_diag_monitor_autosar_Step_ff_valid_ff_valid
    (diag_monitor_autosar_ARID_DEF.ff_valid);
}

/* Model initialize function */
void diag_monitor_autosar_Init(void)
{
  /* (no initialization code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
