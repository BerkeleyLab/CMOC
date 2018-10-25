function retval = tab16_one(name,n1,den)
f = fopen(sprintf('%s.v',name),'w');
fprintf(f,'// Machine generated by tab16_one.m\n');
fprintf(f,'//  tab16_one(%s,%d,%d)\n',name,n1,den);
fprintf(f,'`timescale 1ns / 1ns\n\n');
fprintf(f,'module %s(\n\tinput [3:0] a,\n',name);
fprintf(f,'\toutput reg signed [16:0] phase\n);\n\n');
fprintf(f,'always @(*) case (a)\n');
for ix=[0:15]
	fprintf(f,'\t6%cd%2d: phase = %6d;\n', 39, ix, floor(2^17*rem(n1*ix/den,1)))
end
fprintf(f,'endcase\n\n');
fprintf(f,'endmodule\n');
fclose(f);
