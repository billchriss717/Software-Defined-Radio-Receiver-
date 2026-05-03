% qamcompare.m: compare real and complex QAM implementations
N=1000; M=20; Ts=.0001;               % no. symbols, oversampling factor
time=Ts*(N*M-1); t=0:Ts:time;         % sampling interval and time vectors
s1=pam(N,2,1); s2=pam(N,2,1);         % real 2-level signals of length N
ps=hamming(M);                        % pulse shape of width M
fc=1000; th=-1.0; j=sqrt(-1);         % carrier freq. and phase

s1up=zeros(1,N*M); s1up(1:M:end)=s1;  % oversample by integer length M
s2up=zeros(1,N*M); s2up(1:M:end)=s2;  % oversample by integer length M
sp1=filter(ps,1,s1up);                % convolve pulse shape with data s1
sp2=filter(ps,1,s2up);                % convolve pulse shape with data s2
vreal=sp1.*cos(2*pi*fc*t+th)-sp2.*sin(2*pi*fc*t+th);  % real version
vcomp = real((sp1+j*sp2).*exp(j*(2*pi*fc*t+th)));     % complex carrier
max(abs(vcomp-vreal))                 % verify that they're the same
