#if 0
# request trace, without trace_nowait
printf "sillyoneDD0\170xxx\040TT03yyyy" | nc -q 1 -u 192.168.8.2 3000 | hexdump -v -e '8/1 "%2.2x " "\n"'

# read out Goodbye world! (acq complete) or Goodbye David! (acq still pending)
printf "sillyoneDD@1xxxxTT@0yyyyTT@1yyyyTT@2yyyyTT@3yyyy" | nc -q 1 -u 192.168.8.2 3000 |hexdump -v -e '8/1 "%2.2x " "  "' -e '8/1 "%_p" "\n"'

for j in `seq 48 55`; do
perl -e "\$j=$j"';printf "sillyone"; for ($i=  0; $i< 64; $i++) {printf "TT%c%cyyyy",$j,$i}' | nc -q 1 -u 192.168.8.2 3000
perl -e "\$j=$j"';printf "sillyone"; for ($i= 64; $i<128; $i++) {printf "TT%c%cyyyy",$j,$i}' | nc -q 1 -u 192.168.8.2 3000
perl -e "\$j=$j"';printf "sillyone"; for ($i=128; $i<192; $i++) {printf "TT%c%cyyyy",$j,$i}' | nc -q 1 -u 192.168.8.2 3000
perl -e "\$j=$j"';printf "sillyone"; for ($i=192; $i<256; $i++) {printf "TT%c%cyyyy",$j,$i}' | nc -q 1 -u 192.168.8.2 3000
done > dump2k.dat

hexdump -v -e '4/1 "%2.2x " "\n"' dump2k.dat | less
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


#define PRINT_PER_TX_PACKET 0
#define PRINT_PER_RX_PACKET 0

char final_answer[2048*4];

static unsigned udp_handle(char *data, unsigned data_len)
{
	unsigned u;
	unsigned key = ((data[10]&0x07) << 1) | ((data[11]&0xff) >> 7);  /* 0-15 */
	unsigned want_len = 1032;
	unsigned fail=0;

	static unsigned last_key=-1;
	if (1) fprintf(stderr,"udp_handle (%2.2x %2.2x) %u\n", data[10]&0xff, data[11]&0xff, key);
	if (key != last_key+1) {
		printf("dropped packet? key %u not %u+1\n", key, last_key);
	}
	last_key = key;

	if (data_len != want_len) {
		printf("length not %u", want_len);
		fail++;
	}
	if (0) for (u=0; u<128; u++) {
		unsigned val =
			(data[u*8+4+8]&0xff) << 24 |
			(data[u*8+5+8]&0xff) << 16 |
			(data[u*8+6+8]&0xff) <<  8 |
			(data[u*8+7+8]&0xff);
		printf("data[%u]=%2.2x\n", u+key*128, val);
	}
	if (1) for (u=0; u<128; u++) {
		final_answer[u*4+key*512  ] = data[u*8+4+8];
		final_answer[u*4+key*512+1] = data[u*8+5+8];
		final_answer[u*4+key*512+2] = data[u*8+6+8];
		final_answer[u*4+key*512+3] = data[u*8+7+8];
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
	int rc, fd = creat("dump2k.dat", 0666);
	if (fd != -1) rc=write(fd, final_answer, 2048*4);
	if (fd == -1 || rc!=2048*4) perror("dump2k.dat");
	close(fd);
}

static void send_packet(int usd, unsigned id)
{
	char foo[1500];
	unsigned u;
	memcpy(foo,"sillyone",8);
	for (u=0; u<128; u++) {
		foo[8*u  +8] = 'T';
		foo[8*u+1+8] = 'T';
		foo[8*u+2+8] = id/2+48;
		foo[8*u+3+8] = u+(id%2)*128;
		foo[8*u+4+8] = 'y';
		foo[8*u+5+8] = 'y';
		foo[8*u+6+8] = 'y';
		foo[8*u+7+8] = 'y';
	}
	if (PRINT_PER_TX_PACKET) printf("send_packet %u\n", id);
	send(usd,foo,1032,0);
}

void primary_loop(int usd, unsigned npack, unsigned juggle)
{
	fd_set fds_r, fds_e;
	struct sockaddr sa_xmit;
	unsigned int sa_xmit_len;
	struct timeval to;
	int i, pack_len;
	int debug1=0;
	unsigned probes_sent=0, probes_recv=0, probes_fail=0;
	unsigned timeouts=0;
	static char incoming[1500];
	sa_xmit_len=sizeof sa_xmit;
	for (probes_sent=0; probes_sent<juggle; probes_sent++) {
		send_packet(usd, probes_sent);
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
				if (debug1) printf(" sending\n");
				send_packet(usd, probes_sent);
				++probes_sent;
				++timeouts;
			}
			continue;
		}
		if (debug1) printf(" receiving\n");
		pack_len=recvfrom(usd,incoming,sizeof incoming,0,
		                  &sa_xmit,&sa_xmit_len);
		if (pack_len<0) {
			perror("recvfrom");
		} else if (pack_len>0 && (unsigned)pack_len<sizeof incoming){
			++probes_recv;
			if (udp_handle(incoming,pack_len)>0) ++probes_fail;
			if (probes_recv > probes_sent-juggle) {
				send_packet(usd, probes_sent);
				++probes_sent;
			}
		} else {
			printf("Ooops.  pack_len=%d\n",pack_len);
			fflush(stdout);
			break;
		}
		to.tv_sec=0;
		to.tv_usec=0;
	}
	printf("%u packets sent, %u received, %u failed, %u timeouts\n",
		probes_sent, probes_recv, probes_fail, timeouts);
	if (probes_recv==16 && probes_fail==0) write_result();
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

static void setup_receive(int usd, unsigned int interface, short port)
{
	struct sockaddr_in sa_rcvr;
	memset(&sa_rcvr,0,sizeof sa_rcvr);
	sa_rcvr.sin_family=AF_INET;
	sa_rcvr.sin_addr.s_addr=htonl(interface);
	sa_rcvr.sin_port=htons(port);
	if(bind(usd,(struct sockaddr *) &sa_rcvr,sizeof sa_rcvr) == -1) {
		perror("bind");
		fprintf(stderr,"could not bind to udp port %d\n",port);
		exit(1);
	}
}

static void setup_transmit(int usd, char *host, short port)
{
	struct sockaddr_in sa_dest;
	memset(&sa_dest,0,sizeof sa_dest);
	sa_dest.sin_family=AF_INET;
	stuff_net_addr(&(sa_dest.sin_addr),host);
	sa_dest.sin_port=htons(port);
	if (connect(usd,(struct sockaddr *)&sa_dest,sizeof sa_dest)==-1)
		{perror("connect");exit(1);}
}

int main(int argc, char *argv[])
{
	int usd;
	unsigned npack=16;
	unsigned juggle=1;
	if (argc<2) {fprintf(stderr,"Usage\n");exit(1);}

	if (argc>=3) npack=atoi(argv[2]);
	if (argc>=4) juggle=atoi(argv[3]);

	usd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (usd==-1) {perror("socket"); exit(1);}

	setup_receive(usd, INADDR_ANY, 0);

	setup_transmit(usd, argv[1], 3000);

	primary_loop(usd,npack,juggle);
	close(usd);
	return 0;
}
