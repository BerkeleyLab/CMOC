/* Glue layer to move from Verilog VPI to a conventional C subroutine
 * Both calls look the same:
 *    sysmodel(dac, dacsel, adca, adcb, adcc);
 * where the dac value is supplied to the system model, and the adc values
 * are returned.  OK, the Verilog PLI call has a "$" in front of "sysmodel".
 */

#include <stdio.h>   /* scaffolding */
#include <assert.h>
#include <string.h>
#include <vpi_user.h>

#if 1
#include "pmodel.h"
#else
void init_pmodel(void)
{
	printf("init_sysmodel() called\n"); fflush(stdout);
}

void pmodel(int drive_i, int drive_q, int *field_i, int *field_q, int *reflect_i, int *reflect_q)
{
	printf("sysmodel(%d,%d,...)\n", drive_i, drive_q); fflush(stdout);
	*field_i = *field_q = *reflect_i = *reflect_q = 0;
}
#endif

static PLI_INT32 sysmodel_compiletf(char*cd)
{
	vpiHandle sys = vpi_handle(vpiSysTfCall, NULL);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle arg;
	int i;

	(void) cd;  /* parameter is unused */
	/* Need exactly six arguments */
	for (i=0; i<6; i++) {
		arg = vpi_scan(argv);
		assert(arg);
	}
	arg = vpi_scan(argv);
	assert(!arg);
	init_pmodel();
	return 0;
}

static PLI_INT32 sysmodel_calltf(char*cd)
{
	s_vpi_value value;
	vpiHandle sys = vpi_handle(vpiSysTfCall, NULL);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);

	(void) cd;  /* parameter is unused */
#define INIT(v) vpiHandle v; int v##_val; v = vpi_scan(argv); assert(v);
#define PULL(v) value.format = vpiIntVal; vpi_get_value(v, &value); v##_val = value.value.integer;
#define PUSH(v) value.format = vpiIntVal; value.value.integer = v##_val; vpi_put_value(v, &value, NULL, vpiNoDelay);

	INIT(drive_i)
	INIT(drive_q)
	INIT(field_i)
	INIT(field_q)
	INIT(reflect_i)
	INIT(reflect_q)

	PULL(drive_i)
	PULL(drive_q)

	pmodel(drive_i_val, drive_q_val, &field_i_val, &field_q_val, &reflect_i_val, &reflect_q_val);

	PUSH(field_i)
	PUSH(field_q)
	PUSH(reflect_i)
	PUSH(reflect_q)

	return 0;
}

static void llrf_sysmodel2_register(void)
{
	s_vpi_systf_data tf_data;

	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$llrf_sysmodel2";
	tf_data.calltf    = sysmodel_calltf;
	tf_data.compiletf = sysmodel_compiletf;
	tf_data.sizetf    = NULL;
	tf_data.user_data = strdup("$llrf_sysmodel2");
	vpi_register_systf(&tf_data);

}

void (*vlog_startup_routines[])(void) = {
	llrf_sysmodel2_register,
	NULL
};
