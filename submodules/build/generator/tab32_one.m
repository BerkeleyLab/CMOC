function retval = tab32_one(name,n1,den)
f = fopen(sprintf('%s.v',name),'wb');
fprintf(f,'// Machine generated by tab32_one.m\n');
fprintf(f,'//  tab32_one(%s,%d,%d)\n',name,n1,den);
fprintf(f,'`timescale 1ns / 1ns\n\n');
fprintf(f,'module %s(\n\tinput [4:0] a,\n',name);
fprintf(f,'\toutput reg signed [16:0] phase\n);\n\n');
fprintf(f,'always @(*) case (a)\n');
for ix=[0:31]
	fprintf(f,'\t6%cd%2d: phase = %6d;\n', 39, ix, floor(2^17*rem(n1*ix/den,1)))
end
fprintf(f,'endcase\n\n');
fprintf(f,'endmodule\n');
fclose(f);
