# demonstrates that there is a 57317 count offset in the 18-bit phase
# between that recorded by a_field waveform and that seen by the feedback circuit

make llrf_dsp_tb || exit

for p in `seq 0 0.3 3.0`; do
  vvp -n llrf_dsp_tb +trace +phase=$p | awk '
FNR==9 {a=atan2($7,$8)/3.141593*131072; printf("Fiber %7d %7d %7d  ", a, $9, $9-a)}
FNR==14{a=atan2($1,$2)/3.141593*131072; printf("ADC   %7d %7d %7d\n", a, $9, $9-a)}'
done
