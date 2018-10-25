import json
import numpy
from numpy import exp, log, sin, cos, pi


def send(v, n):
    e = json_dict[n]
    base = e["base_addr"]
    for j, x in enumerate(v):
        print "%d %x" % (base+j, x)


error_cnt = 0


# Scale a floating point number in range [-1,1) to fit in b-bit register
# Stolen from paramhg.py
def fix(x, b, msg, opt=None):
    global error_cnt
    ss = 1 << (b-1)
    # cordic_g = 1.646760258
    if opt is "cordic":
        ss = int(ss / 1.646760258)
    xx = int(x*ss+0.5)
    # print x,b,ss,xx
    if xx > ss-1:
        xx = ss-1
        # print("# error: %f too big (%s)"%(x,msg))
        error_cnt += 1
    if xx < -ss:
        xx = -ss
        # print("# error: %f too small (%s)"%(x,msg))
        error_cnt += 1
    return xx


def real_resp(B, mmm, z):
    # B/(z-mmm)
    # print B, mmm, z
    # for the moment I'll take the real part
    n = mmm.shape[0]
    I = numpy.identity(n)
    resp = [(zz*I - mmm).getI().dot(B)[0, 0] for zz in z]
    print "foo", len(resp), resp[0].shape
    return resp

with open("regmap_gen_afilter_siso_tb.json", "r") as json_file:
    json_dict = json.load(json_file)
    dt = 20/125e6  # set by run_filter logic in afilter_siso_tb.v
    gscale = 2**20  # XXX
    # Notation mostly from the famous "slide 7", see slide7.tex
    #          G     psi  omega  zeta
    modes = [[0.3,   0.0,  2500,  0.02],
             [0.4,   0.7,   300,  0.05],
             [0.2,   0.0,   450,  0.90]]
    modes = [[0.4,   0.0,  2500,  1.00]]
    # zeta is damping ratio, zeta \defined 1/(2*Q)
    # special handling of integrator, be prepared to flip sign?
    igain = 4  # /s
    b2 = igain*dt*gscale
    b3 = fix(b2, 18, "b0")
    # print("integrator %d/%d" % (b3, 2**17))
    out_k = [b3, 0]
    res_k = [0, 0]
    dot_k = [131071, 0]
    # set up for (potential) plot
    f_plt = numpy.arange(-1000, 1000, 1)  # Hz
    z_plt = exp(2j*pi*f_plt*dt)
    gain = f_plt*0  # using complex numbers
    gain_e = f_plt*0  # using real numbers
    for m in modes:
        G, psi, omega, zeta = m
        a = exp(dt*(1j - zeta)*omega)
        a1 = a.real - 1
        b1 = a.imag
        scale = int(-log(max(abs(a1), abs(b1)))/log(4))
        scale = max(min(scale, 9), 2)
        a2 = a1 * 4**scale
        b2 = b1 * 4**scale
        # print("(%.5f, %.5f) * 4**%d" % (a2, b2, -scale))
        a3 = (fix(a2, 18, "a2") & (2**18-1)) + ((9-scale) << 18)
        b3 = (fix(b2, 18, "b2") & (2**18-1)) + ((9-scale) << 18)
        c2 = fix(G * cos(psi), 18, "c2")
        d2 = fix(G * sin(psi), 18, "d2")
        out_k += [131071, 0]
        res_k += [a3, b3]
        dot_k += [c2, d2]
        print G, omega, a, a-1, scale
        # complex number expression: simple :-)
        gain = gain + 0.25**scale*G*exp(1j*psi) / (z_plt-a)
	# real numbers
        mmm = numpy.matrix([[a.real, a.imag], [-a.imag, a.real]])
        # z*x = mmm*x + B*u
        #     without the B*u term, this would be an eigen-equation
        # (z-mmm)*x = B*u
        # x/u = B/(z-mmm)
        B = numpy.array([1, 0])
        gain_e += real_resp(B, mmm, z_plt)
    if error_cnt:
        print("%d scaling errors!" % error_cnt)
        exit(2)
    plot = True
    if plot:
        from matplotlib import pyplot
        pyplot.plot(f_plt, gain.real, label='real')
        pyplot.plot(f_plt, gain.imag, label='imag')
        pyplot.plot(f_plt, gain_e.real*0.001, label='real E')
        pyplot.plot(f_plt, gain_e.imag, label='imag E')
        pyplot.legend()
        pyplot.show()
    else:
        send(out_k, "afilter_siso_outer_prod_k_out")
        send(res_k, "afilter_siso_resonator_prop_const")
        send(dot_k, "afilter_siso_dot_k_out")
