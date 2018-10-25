/* tap-vpi.c */

/* Larry Doolittle, LBNL */

#include <vpi_user.h>
#include <string.h>   /* strspn() */
#include <stdlib.h>   /* exit() */
#include <stdio.h>    /* snprintf() */
#include <unistd.h>   /* read() and write() */
#include <time.h>     /* nanosleep() */
#include <fcntl.h>
#include <assert.h>
#include <errno.h>
#include <stdint.h>
#include "crc32.h"
#include "tap_alloc.h"

#define GMII
#ifdef GMII
#define DATA_BASE 8
#define CRC_SIZE 4
#else
#define DATA_BASE 0
#define CRC_SIZE 0
#endif

#define MIN_IFG 12

/*
 * VPI (a.k.a. PLI 2) routines for connection to the Universal tun/tap
 * port to/from a Verilog program.
 *
 * $tap_io(out_octet, out_valid, in_octet, in_valid)
 *   in_octet is data received from the tap Ethernet port, sent
 *      to the Verilog program.
 *   out_octet provided by the Verilog program, will be sent to
 *      the tap Ethernet port, once out_valid is low for a cycle.
 *
 * Written according to standards, but so far only tested on
 * Linux with Icarus Verilog.
 */

#define ETH_MAXLEN 1500   /* maximum line length */

struct pbuf {
	unsigned char buf[ETH_MAXLEN+12];
	unsigned int cur, len;
};

#define HEX(x) ((x)>9 ? 'A' - 10 + (x) : '0' + (x))
static void print_hex(FILE *f, unsigned int c)
{
	fputc(HEX((c>>4)&0xf), f);
	fputc(HEX((c   )&0xf), f);
}

static void print_buf(FILE *f, struct pbuf *b)
{
	for (unsigned jx=0; jx < b->len; jx++) {
		fputc(' ', f);
		print_hex(f, b->buf[jx]);
	}
	fputc('\n', f);
}

static void ethernet_model(int out_octet, int out_valid, int *in_octet, int *in_valid)
{
	static struct pbuf inbuf;
	static struct pbuf outbuf;
	static int initialized=0;
	static unsigned int activity_counter=0;
	static int prev_out_valid=0;
	int val = 0;
	char device[20];
	static int tapfd;
	static int sleepctr=0;
	static int sleepmax=1;
	char in_txt[15], out_txt[15];

	if (out_valid) {
		sprintf(out_txt,"0x%2.2x",(unsigned int)(out_octet&0xff));
	} else {
		strcpy(out_txt,"----");
	}

	if (!initialized) {
		fprintf(stderr, "ethernet_model initializing\n");
		inbuf.cur = 0;
		inbuf.len = 0;
#ifdef GMII
		{
			unsigned u;
			for (u=0; u<7; u++) inbuf.buf[u]=0x55;  /* Preamble */
		}
		inbuf.buf[7]=0xd5;  /* SFD */
#endif
		outbuf.cur = 0;
		outbuf.len = 0;
		initialized = 1;
		strcpy(device,"tap0");
		if ((tapfd = tap_alloc(device)) < 0) {
			perror("tap_alloc");
			exit(1);
		}
		fcntl(tapfd, F_SETFL, O_NONBLOCK);
	}

	if (inbuf.cur == inbuf.len + MIN_IFG) {
		/* non-blocking read packet */
		int rc = read(tapfd, inbuf.buf+DATA_BASE, ETH_MAXLEN);
		if (rc < 0) {
			if ((errno != EAGAIN) && (errno != EWOULDBLOCK)) {
				struct timespec minsleep = {0, 500000000};
				fprintf(stderr,"TAP read failed: errno %d (%s)\n", errno, strerror(errno));
				nanosleep(&minsleep, NULL);
			}
			if (!out_valid && sleepctr++ > sleepmax) {
				struct timespec minsleep = {0, 10000000};
				nanosleep(&minsleep, NULL);
			}
		} else {
			fprintf(stderr,"input packet read %d tap bytes\n", rc);
#ifdef GMII
			append_crc32(inbuf.buf+DATA_BASE,rc);
			if (check_crc32(inbuf.buf+DATA_BASE, rc)==0) {
				fprintf(stderr, "CRC self-test failed\n");
			}
#endif
			inbuf.len = rc+DATA_BASE+CRC_SIZE;
			inbuf.cur = 0;
			fputs("Rx:",stderr); print_buf(stderr, &inbuf);
		}
	}
	if (inbuf.cur < inbuf.len) {
		if (in_octet) *in_octet = inbuf.buf[inbuf.cur];
		inbuf.cur++;
		val = 1;
	} else if (inbuf.cur < inbuf.len + MIN_IFG) {
		if (in_octet) *in_octet = 0;  /* could in principle be XX */
		inbuf.cur++;
		val = 0;
	}
	if (in_valid) *in_valid = val;
	if (val) {
		sprintf(in_txt,"0x%2.2x",(unsigned int)((*in_octet)&0xff));
	} else {
		strcpy(in_txt,"----");
	}
	if (0) fprintf(stderr, "Ethernet model %s to Verilog, %s from Verilog\n", in_txt, out_txt);
	activity_counter++;
	if (activity_counter > 30) {
		fputc('-',stderr);
		activity_counter = 0;
	}
	if (out_valid) {
		outbuf.buf[outbuf.cur] = out_octet;
		if (outbuf.cur < ETH_MAXLEN) outbuf.cur++;
		else fprintf(stderr,"Ethernet output packet too long\n");
	} else if (prev_out_valid) {
		unsigned nout = outbuf.cur;
		/* write output packet */
		outbuf.len = outbuf.cur;
		fputs("\nTx:",stderr); print_buf(stderr, &outbuf);
#ifdef GMII
		const unsigned char *p=outbuf.buf;
		while (*p==0x55 && p<(outbuf.buf+outbuf.cur)) { p++; }
		if ((*p & 0xff) != 0xd5) {
			fprintf(stderr, "output packet len %d missing SFD (%2.2x %2.2x)\n",
				outbuf.cur, outbuf.buf[0], *p);
		} else if (nout=outbuf.buf+outbuf.cur-(p+5), check_crc32(p+1, nout)==0) {
			fprintf(stderr, "output packet len %d CRC failed\n",
				outbuf.cur);
		} else
#endif
		{
			int rc = write(tapfd, p+1, nout);
			fprintf(stderr, "output packet len %d, write rc=%d\n",outbuf.cur, rc);
		}
		outbuf.cur=0;
	}
	prev_out_valid = out_valid;
}

static PLI_INT32 tap_io_compiletf(char*cd)
{
	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle arg;
	int i;

	(void) cd;  /* parameter is unused */
	/* Need four arguments */
	for (i=0; i<4; i++) {
		arg = vpi_scan(argv);
		assert(arg);
	}
	return 0;
}

static PLI_INT32 tap_io_calltf(char*cd)
{
	s_vpi_value value;
	int out_octet_val, out_valid_val, in_octet_val=0, in_valid_val=0;

	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle out_octet, out_valid, in_octet, in_valid;

	(void) cd;  /* parameter is unused */
	out_octet = vpi_scan(argv); assert(out_octet);
	out_valid = vpi_scan(argv); assert(out_valid);
	in_octet  = vpi_scan(argv); assert(in_octet);
	in_valid  = vpi_scan(argv); assert(in_valid);

	value.format = vpiIntVal;
	vpi_get_value(out_octet, &value);
	out_octet_val = value.value.integer;

	value.format = vpiIntVal;
	vpi_get_value(out_valid, &value);
	out_valid_val = value.value.integer;

	ethernet_model(out_octet_val, out_valid_val, &in_octet_val, &in_valid_val);

	value.format = vpiIntVal;
	value.value.integer = in_octet_val;
	vpi_put_value(in_octet, &value, 0, vpiNoDelay);

	value.format = vpiIntVal;
	value.value.integer = in_valid_val;
	vpi_put_value(in_valid, &value, 0, vpiNoDelay);

	return 0;
}

static void sys_tap_io_register(void)
{
	s_vpi_systf_data tf_data;

	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$tap_io";
	tf_data.calltf    = tap_io_calltf;
	tf_data.compiletf = tap_io_compiletf;
	tf_data.sizetf    = 0;
	tf_data.user_data = strdup("$tap_io");
	vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])(void) = {
	sys_tap_io_register,
	0
};
