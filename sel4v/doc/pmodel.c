#include <stdio.h>
#ifdef USE_PYTHON_HOOK
#include <Python.h>
#endif
#include "pmodel.h"

static struct {
	double fi, fq;
	double ri, rq;  // sate propagator for f
	double ci, cq;  // coupling to input drive
} state;

void init_pmodel(void)
{
	printf("# init_sysmodel() called\n"); fflush(stdout);
#if 1
	state.fi=900.0;
	state.fq=436.0;
#else
	state.fi=0.0;
	state.fq=0.0;
#endif
	// actual LCLS-2 value is 0.9999975
	// exp((-10e3+2e3*i)*2*pi/(100e6/2))
	state.ri=0.998744;
	state.rq=0.000251;
	state.ci=0.0012;
	state.cq=0.0;

	// experimental and still useless
#ifdef USE_PYTHON_HOOK
	Py_Initialize();
	PyRun_SimpleString("print '# Hello, world!'");
	Py_Finalize();
#endif
}

static int adc(double x) {
	int a = (int) (x+0.5);
	if (a> 120000) a= 120000;
	if (a<-120000) a=-120000;
	return a;
}


void pmodel(int drive_i, int drive_q, int *field_i, int *field_q, int *reflect_i, int *reflect_q)
{
	static unsigned fake_time=0;
	// move from 0.00025 to 0.0002 in 1000 steps (20 us)
	if (1 && fake_time > 12000 && fake_time < 13000) state.rq += -1.5e-7;
	if (0 && fake_time == 16000) state.rq=0.000251;
	double rr = state.fi * state.ri - state.fq * state.rq;
	state.fq = state.fi * state.rq + state.fq * state.ri;
	state.fi = rr;
	state.fi += drive_i * state.ci - drive_q * state.cq;
	state.fq += drive_i * state.cq + drive_q * state.ci;

	if (0) {
		printf("%d %d %.1f %.1f pmodel\n", drive_i, drive_q, state.fi, state.fq);
		fflush(stdout);
	}

	if (field_i) *field_i = adc(state.fi);
	if (field_q) *field_q = adc(state.fq);

	if (reflect_i) *reflect_i=0;
	if (reflect_q) *reflect_q=0;
	fake_time++;
}
