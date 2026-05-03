% costasloop.m simulate costas loop with input from pulrecsig.m
r=rsc;                                    % rsc is from pulrecsig.m
fl=500; ff=[0 .01 .02 1]; fa=[1 1 0 0];
h=firpm(fl,ff,fa);                        % LPF design
mu=.003;                                  % algorithm stepsize
f0=1000;                                  % assumed freq. at receiver
theta=zeros(1,length(t)); theta(1)=0;     % initialize estimate vector
zs=zeros(1,fl+1); zc=zeros(1,fl+1);       % initialize buffers for LPFs
for k=1:length(t)-1                       % z's contain past fl+1 inputs
  zs=[zs(2:fl+1), 2*r(k)*sin(2*pi*f0*t(k)+theta(k))];
  zc=[zc(2:fl+1), 2*r(k)*cos(2*pi*f0*t(k)+theta(k))];
  lpfs=fliplr(h)*zs'; lpfc=fliplr(h)*zc'; % new output of filters
  theta(k+1)=theta(k)-mu*lpfs*lpfc;       % algorithm update
end

plot(t,theta),
title('Phase Tracking via the Costas Loop')
xlabel('time'); ylabel('phase offset')
