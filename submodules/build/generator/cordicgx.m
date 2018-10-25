cordicg_conf

printf('// machine generated from cordicgx.m\n');
printf('// o=%d  s=%d\n', o, s);
printf('`ifndef CORDIC_COMPUTE\n');
printf('parameter cordic_delay=%d;\n', s);
printf('`else\n');

printf('wire [%d:0] x1 = {xt1,{(%d-width){1%cb0}}};\n', o-1, o, 39);
printf('wire [%d:0] y1 = {yt1,{(%d-width){1%cb0}}};\n', o-1, o, 39);
printf('wire [%d:0] z1 = {zt1,{(%d-width){1%cb0}}};\n', o,   o, 39);

ix=[0:s-2]';
a=floor(atan((0.5).^ix)/(2*pi)*2**(o+1)+.5);
for i=[1:s-2]
  printf('wire op%-2d; wire [%d:0] x%-2d, y%-2d; wire [%d:0] z%-2d;  ', i+1, o-1, i+1, i+1, o, i+1);
  printf('cstageg #( %2d, %d, %d, def_op) ', i, o+1, o);
  printf('cs%-2d (clk, op%-2d, x%-2d,  y%-2d, z%-2d, %2d%cd%-6d, op%-2d, x%-2d,  y%-2d,  z%-2d);\n',
  i,i,i,i,i,o+1,39,a(i+1),i+1,i+1,i+1,i+1);
end

% This rounding construction can be considered wasteful; it adds
% hardware and slows the logic down.  OTOH, I haven't found any
% alternative that works as well.

printf('// round, not truncate\n');
printf('assign xout     = x%d[%d:%d-width] + x%d[%d-width];\n', s-1, o-1, o, s-1, o-1);
printf('assign yout     = y%d[%d:%d-width] + y%d[%d-width];\n', s-1, o-1, o, s-1, o-1);
printf('assign phaseout = z%d[%d:%d-width] + z%d[%d-width];\n', s-1, o,   o, s-1, o-1);
printf('`endif\n');
