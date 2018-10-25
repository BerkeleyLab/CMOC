/* -------------------------------------------------------------------------------
 * Filename    : grabfmc.c
 * Description :
 * Author      : Qiang Du
 * Maintainer  :
 * -------------------------------------------------------------------------------
 * Created     : Tue May  8 15:44:43 2012 (-0700)
 * Version     :
 * Last-Updated:
 *           By:
 *     Update #: 0

 * Commentary  :  Test bench of fmc_adc module via GTP.
 *
 * -------------------------------------------------------------------------------

 * Change Log  :
 * 8-May-2012    Qiang
 *    Initial draft, derived from grab2k.c. Enabled receive from multiple ports,
 *    created rules of data parsing for the example setting of 0x284 run set,
 *    which would result in 2 frames of 1284 bytes incoming data. First 4 bytes
 *    are sequence numbers, others are combined by 20-bit two channel results to
 *    5-bytes  in big endian (ethernet) format. Final results are dumped to files.
 *
 * -------------------------------------------------------------------------------
 */

/* Code: */


#if 0
# echo "Write regmap x0b13b13b1@11 x01@12 x0b@41, x0284@42, x06@44, x700@40, use cic"
printf "sillyoneDD@\x0b\xb1\x3b\x13\xb1DD@\x0c\x00\x00\x00\x01DD@\x29\x00\x00\x00\x0bDD@\x2a\x00\x00\x02\x84DD@\x2c\x00\x00\x00\x06DD@\x28\x00\x00\x70\x00" | nc -q 2 -u 192.168.21.117 3000 | hexdump -v -e '8/1 "%2.2x " "  "' -e '8/1 "%_p" "\n"'

hexdump -v -e '4/1 "%2.2x " "\n"' ch1.dat | less
#endif

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <netdb.h>     /* gethostbyname */
#include <errno.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define PRINT_PER_TX_PACKET 1
#define PRINT_PER_RX_PACKET 1
#define TRACE_PORT 1000
#define LB_PORT 3000

/* 256 samples per frame, according to 0x284@42 reg. Need to be flexible. */
unsigned ch1_val[256*2];
unsigned ch2_val[256*2];

/* just enable trigger to request trace */
static unsigned char cmd[] = "sillyone\x00\x00\x00\x2c\x00\x00\x00\x06";

static unsigned udp_handle(char *data, unsigned data_len)
{
	unsigned u;
	unsigned frame = (data[0]&0xff) << 8 | (data[1]&0xff);
	unsigned key   = (data[2]&0xff) << 8 | (data[3]&0xff);
	unsigned want_len = 1284;
	unsigned fail=0;

	static unsigned last_key=-1;
	if (1) printf("udp_handle (%u %u)\n", frame, key);
	if (key != last_key+1) {
		printf("dropped packet? key %u not %u+1\n", key, last_key);
	}
	last_key = key;

	if (data_len != want_len) {
	  printf("udp_handle: length not %u\n",want_len);
		fail++;
	}
	if (0) for (u=4; u<data_len; ++u) {
	    printf("%2.2x ", data[u] & 0xff);
	    if ( (u-4) %16 == 15 ) printf("\n");
	  }

	if (1) for (u=0; u<256; u++) {
		ch2_val[u+key*256] =
			(data[u*5+4]&0xff) <<  8 |
			(data[u*5+5]&0xff);
		ch1_val[u+key*256] =
			(data[u*5+6]&0x0f) << 12 |
			(data[u*5+7]&0xff) <<  4 |
			(data[u*5+8]&0xff) >>  4;
		if (1) printf("data[%04u], ch2_val = %05x, ch1_val = %05x\n",
		       u*5+key*1280+4, ch2_val[u], ch1_val[u]);
	}
	if (fail || PRINT_PER_RX_PACKET) printf("udp_handle  length=%u  key=%u  ", data_len, key);
	if (fail) {
		printf("%d FAIL\n", fail);
	} else {
		if (PRINT_PER_RX_PACKET) printf("PASS\n");
	}
	return fail;
}

void write_result(void)
{
	int rc, fd = creat("ch1.dat", 0666);
	FILE * pFile;
	int i, vv1, vv2;
	double scale = 1.0/0xffff;
	double vr1, vr2;

	if (fd != -1) rc=write(fd, ch1_val, sizeof ch1_val);
	if (fd == -1 || rc!=sizeof ch1_val) perror("ch1.dat");
	close(fd);
	fd = creat("ch2.dat", 0666);
	if (fd != -1) rc=write(fd, ch2_val, sizeof ch2_val);
	if (fd == -1 || rc!= sizeof ch2_val) perror("ch2.dat");
	close(fd);

	pFile = fopen("result.dat", "w+");
	for (i=0;i<512;i++) {
	  vv1 = *(ch1_val+i)&0xffff;
	  vv2 = *(ch2_val+i)&0xffff;
	  if (vv1&0x8000) vv1 |= 0xffff0000;
	  if (vv2&0x8000) vv2 |= 0xffff0000;
	  vr1 = vv1*scale;
	  vr2 = vv2*scale;

	  if (1) fprintf(pFile, "%9.5f %9.5f \n", vr1, vr2);
	}
	fclose(pFile);
}

static void stuff_net_addr(struct in_addr *p, char *hostname)
{
	struct hostent *server;
	server=gethostbyname(hostname);
	if (server == NULL) {
		herror(hostname);
		exit(1);
	}
	if (server->h_length != 4) {
		/* IPv4 only */
		fprintf(stderr,"oops %d\n",server->h_length);
		exit(1);
	}
	memcpy(&(p->s_addr),server->h_addr_list[0],4);
}
static void send_packet_to(int usd, unsigned id, char *host, short port)
{
	char foo[48];
	unsigned u;

	struct sockaddr_in sa_dest;
	socklen_t sa_len = sizeof(sa_dest);

	memset(&sa_dest,0,sa_len);
	sa_dest.sin_family=AF_INET;
	stuff_net_addr(&(sa_dest.sin_addr),host);
	sa_dest.sin_port=htons(port);

	/*if (connect(usd,(struct sockaddr *)&sa_dest,sizeof sa_dest)==-1)
		{perror("connect");exit(1);}
	*/

	printf("sending packet:\n");
	if (0) for (u=0;u<sizeof(cmd);++u)
	  {
	    printf("%2.2x ", cmd[u]);
	    if (u%8 == 7)  printf ("\n");
	  }


	memcpy(foo, cmd, 48);

	if (PRINT_PER_TX_PACKET) printf("send_packet_to %u\n", id);
	sendto(usd,foo,48,0, (struct sockaddr *) &sa_dest, sa_len);
}



static void setup_receive(int usd, unsigned int interface, short port)
{
	struct sockaddr_in sa_rcvr;
	struct sockaddr_in sin;
	socklen_t len = sizeof(sin);

	memset(&sa_rcvr,0,sizeof sa_rcvr);
	sa_rcvr.sin_family=AF_INET;
	sa_rcvr.sin_addr.s_addr=htonl(interface);
	sa_rcvr.sin_port=htons(port);
	if(bind(usd,(struct sockaddr *) &sa_rcvr,sizeof sa_rcvr) == -1) {
		perror("bind");
		fprintf(stderr,"could not bind to udp port %d\n",port);
		exit(1);
	}
	/* Get port */
	if (getsockname(usd, (struct sockaddr *)&sin, &len) == -1)
	  perror("getsockname");
	else
	  printf("receive port number: %d\n", ntohs(sin.sin_port));
}

void primary_loop(int usd, unsigned npack, unsigned juggle, char *target)
{
	fd_set fds_r, fds_e;
	struct sockaddr_in sa_xmit;
	unsigned int sa_xmit_len;
	struct timeval to;
	int i, pack_len;
	int debug1=1;
	unsigned probes_sent=0, probes_recv=0, probes_fail=0;
	unsigned timeouts=0;
	static char incoming[1500];
	sa_xmit_len=sizeof sa_xmit;

	for (probes_sent=0; probes_sent<juggle; ++probes_sent) {
		/* send_packet(usd, probes_sent); */
		send_packet_to(usd, probes_sent, target, LB_PORT);
	}
	to.tv_sec=0;
	to.tv_usec=0;

	for (;npack == 0 || probes_recv < npack;) {
		FD_ZERO(&fds_r);
		FD_SET(usd,&fds_r);
		FD_ZERO(&fds_e);
		FD_SET(usd,&fds_e);
		to.tv_sec=0;
		to.tv_usec=10000;
		i=select(usd+1,&fds_r,NULL,&fds_e,&to);
		  /* Wait on read or error */
		if (debug1) printf("select returns %d,", i);

		if ((i!=1)||(!FD_ISSET(usd,&fds_r))) {
			if (i<0) {
				if (debug1) printf(" error\n");
				if (errno != EINTR) perror("select");
				else printf("EINTR\n");
			} else if (i==0) {
			  if (debug1) printf(" sending...\n");
			 /* send_packet(usd, probes_sent); */
			  send_packet_to(usd, probes_sent, target, LB_PORT);
			  if (++probes_sent > 3) {
			    printf("probes_sent > 3, Aborting...\n");
			    break;
			  }
			  ++timeouts;
			}
			continue;
		}

		if (debug1) printf(" receiving...\n");
		/* change transmit port to TRACE_PORT*/

		/* with the example command, three replies are expected:
		   LB_PORT , cmd echo, length = 48 * 1 ;
		   TRACE_PORT , fmc_adc output, length = 1284 * 2 ;
		 */
		for (i=0;i<3;i++) {
		    pack_len=recvfrom(usd,incoming,sizeof incoming,0,(struct sockaddr *)&sa_xmit,&sa_xmit_len);
		    if (pack_len<0) {
		      perror("recvfrom");
		    } else if (pack_len>0 && (unsigned)pack_len<sizeof incoming){
		      if (debug1) printf("Received from %s:%d, pack_len = %d\n", inet_ntoa(sa_xmit.sin_addr), ntohs(sa_xmit.sin_port), pack_len);
		      if ( ntohs(sa_xmit.sin_port) == LB_PORT ) {
			if (debug1) printf("Dropping echo frame.\n");
			continue;
		      }
		      ++probes_recv;
		      if (udp_handle(incoming,pack_len)>0) ++probes_fail;
		    } else {
		      printf("Ooops.  pack_len=%d\n",pack_len);
		      fflush(stdout);
		      break;
		    }
		    to.tv_sec=0;
		    to.tv_usec=0;
		}
	}
	printf("%u packets sent, %u received, %u failed, %u timeouts\n",
		probes_sent, probes_recv, probes_fail, timeouts);
	if (probes_recv==2 && probes_fail==0) write_result();
}


int main(int argc, char *argv[])
{
        int usd;
	unsigned npack=16;
	unsigned juggle=1;
	if (argc<2) {fprintf(stderr,"Usage: grabfmc <target_ip> <npack> <juggle>\n");exit(1);}

	if (argc>=3) npack=atoi(argv[2]);
	if (argc>=4) juggle=atoi(argv[3]);

	usd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (usd==-1) {perror("socket"); exit(1);}

	setup_receive(usd, INADDR_ANY, 0);

	primary_loop(usd,npack,juggle,argv[1]);
	close(usd);
	return 0;
}

/* grabfmc.c ends here */
