% plldd.m: decision directed phase tracking
% (must run pulrecsig first)
fl=100; fbe=[0 .2 .3 1]; damps=[1 1 0 0 ];     % parameters for LPF
h=firpm(fl,fbe,damps);                         % LPF impulse response
fzc=zeros(1,fl+1); fzs=zeros(1,fl+1);          % initial state of filters=0
theta=zeros(1,N); theta(1)=-0.9;               % initial phase estimate random
mu=.03; j=1; f0=fc;                            % algorithm stepsize mu
for k=1:length(rsc)
  cc=2*cos(2*pi*f0*t(k)+theta(j));             % cosine for demod
  ss=2*sin(2*pi*f0*t(k)+theta(j));             % sine for demod
  rc=rsc(k)*cc; rs=rsc(k)*ss;                  % do the demods
  fzc=[fzc(2:fl+1),rc]; fzs=[fzs(2:fl+1),rs];  % states for LPFs
  x(k)=fliplr(h)*fzc';xder=fliplr(h)*fzs';     % LPFs give x and its derivative
  if mod(0.5*fl+M/2-k,M)==0                    % downsample to pick correct timing
    qx=quantalph(x(k),[-3,-1,1,3]);            % quantize to nearest symbol
    theta(j+1)=theta(j)-mu*(qx-x(k))*xder;     % algorithm update
    j=j+1;
  end
end

plot(theta)
xlabel('time')
ylabel('phase estimates')

