% qamcostasloop.m simulate costas loop for QAM
% input vreal from qamcompare.m

r=vreal;                                   % vreal is from qamcompare.m
fl=100; f=[0 .2 .3 1]; a=[1 1 0 0];        % filter specification
h=firpm(fl,f,a);                           % LPF design
mu=.003;                                   % algorithm stepsize
f0=1000; q=fl+1;                           % assumed freq. at receiver
th=zeros(1,length(t)); th(1)=randn;        % initialize estimate vector
z1=zeros(1,q); z2=zeros(1,q);              % initialize buffers for LPFs
z4=zeros(1,q); z3=zeros(1,q);              % z's contain past fl+1 inputs
for k=1:length(t)-1
  s=2*r(k);
  z1=[z1(2:q),s*cos(2*pi*f0*t(k)+th(k))];
  z2=[z2(2:q),s*cos(2*pi*f0*t(k)+pi/4+th(k))];
  z3=[z3(2:q),s*cos(2*pi*f0*t(k)+pi/2+th(k))];
  z4=[z4(2:q),s*cos(2*pi*f0*t(k)+3*pi/4+th(k))];
  lpf1=fliplr(h)*z1'; lpf2=fliplr(h)*z2';  % new output of filters
  lpf3=fliplr(h)*z3'; lpf4=fliplr(h)*z4';  % new output of filters
  th(k+1)=th(k)+mu*lpf1*lpf2*lpf3*lpf4;    % algorithm update
end

plot(t,th),
title('Phase Tracking via the Costas Loop')
xlabel('time'); ylabel('phase offset')
