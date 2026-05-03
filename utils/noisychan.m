% noisychan.m generate 4-level data and add noise
m=1000;                           % length of data sequence
p=1/15; s=1.0;                    % power of noise and signal
x=pam(m,4,s);                     % generate 4-PAM input with power 1...
l=sqrt(1/5);                      %     ...with amp levels l
n=sqrt(p)*randn(1,m);             % generate noise with power p
y=x+n;                            % output of system adds noise to data
qy=quantalph(y,[-3*l,-l,l,3*l]);  % quantize output to [-3*l,-l,l,3*l]
err=sum(abs(sign(qy'-x)))/m;      % percent transmission errors
