% Concept behind a_compress.v
% Note that output only exceeds unity if sat_ctl > 0.75
x = [0:.001:1]'*sqrt(2);
mag = x.^2;
sat_ctl=0;
for sat_ctl=[0.25:0.125:0.75]
  quad = mag.^2;
  quad = (mag<=1).*quad + (mag>1).*(2*mag-1);
  gain = 1 + sat_ctl - mag + quad/4;
  y = gain.*x;
  plot(x,y);
  hold on
end

sat_ctl = 0.75;
verilog=load('a_compress.dat')(3:end,:);
x = verilog(:,1)*sqrt(2)/2^17;
y_verilog = verilog(:,2)*sqrt(2)/2^17;
mag = x.^2;
quad = mag.^2;
quad = (mag<=1).*quad + (mag>1).*(2*mag-1);
gain = 1 + sat_ctl - mag + quad/4;
y = gain.*x;
plot(x,y_verilog,'r')

hold off
xlabel('input')
ylabel('output')

err = y-y_verilog;
if (max(abs(err)) > 0.0001)
  printf('FAIL\n')
  exit(1)
else
  printf('PASS\n')
end
