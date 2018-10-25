#include <stdlib.h>
#include <stdio.h>
#include <math.h>

struct state {
	// literal state
	int a, b;
	// propagation coefficients
	int d, w, f;
};

#define SCALE (4)

static void step(struct state *s, int drive)
{
	int old_a = (s->a) >> 16;
	int old_b = (s->b) >> 16;
	int delta_a = -(s->d) * old_a + (s->w) * old_b + (s->f) * drive;
	int delta_b = -(s->w) * old_a - (s->d) * old_b;
	s->a += delta_a >> SCALE;
	s->b += delta_b >> SCALE;
}

int main(int argc, char **argv)
{
	if (argc != 3) exit(1);
	double f0 = strtod(argv[1], NULL);  // normalized to sample rate
	double damp = strtod(argv[2], NULL);  // damp = 1/(2*Q)
	double r = exp(-f0*damp);

	struct state s;
	double scale = 1<<(16+SCALE);
	s.a = 0;
	s.b = 0;
	s.d = (1.0-r*cos(f0)) * scale;
	s.w =     (r*sin(f0)) * scale;
	s.f =         (1/r-r) * scale;
	printf("# d %d\n", s.d);
	printf("# w %d\n", s.w);
	printf("# f %d\n", s.f);
	double q = scale-s.d;
	printf("# back-computed r^2 %f\n", (q*q+s.w*s.w)/pow(2.0,32+2*SCALE));
	for (unsigned u=0; u<3000; u++) {
		int drive = 30000;
		drive = 0.0;
		if (u<150000) drive = 0.49*cos(f0*u)*(1<<16);
		step(&s, drive);
		printf("%u %d %d %d\n", u, drive, s.a, s.b);
		// plot "foo.dat" using 1:3 with l, "foo.dat" using 1:4 with l
	}
	return 0;
}
