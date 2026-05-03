% DDequalizer.m find a DD equalizer f for the channel b
b=[0.5 1 -0.6];              % define channel
m=1000; s=sign(randn(1,m));  % binary source of length m
r=filter(b,1,s);             % output of channel
n=4; f=[0 1 0 0]';           % initialize equalizer
mu=.1;                       % stepsize
for i=n+1:m                  % iterate
  rr=r(i:-1:i-n+1)';         % vector of received signal
  e=sign(f'*rr)-f'*rr;       % calculate error
  f=f+mu*e*rr;               % update equalizer coefficients
end

