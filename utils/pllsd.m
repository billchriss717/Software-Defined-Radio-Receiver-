% pllsd.m: phase tracking minimizing SD

Ts=1/10000; time=1; t=0:Ts:time-Ts;       % time interval and time vector
fc=100; phoff=-0.8;                       % carrier freq. and phase
rp=cos(4*pi*fc*t+2*phoff);                % simplified received signal
mu=.001;                                  % algorithm stepsize
theta=zeros(1,length(t)); theta(1)=0;     % initialize vector for estimates
fl=25; h=ones(1,fl)/fl;                   % fl averaging coefficients
z=zeros(1,fl); f0=fc;                     % initialize buffers for avg
for k=1:length(t)-1                       % run algorithm
  filtin=(rp(k)-cos(4*pi*f0*t(k)+2*theta(k)))*sin(4*pi*f0*t(k)+2*theta(k));
  z=[z(2:fl), filtin];                    % z's contain fl past inputs
  theta(k+1)=theta(k)-mu*fliplr(h)*z';    % convolve z with h and update
end
plot(t,theta)                             % plot estimated phase
title('Phase Tracking via SD cost')
xlabel('time'); ylabel('phase offset')
