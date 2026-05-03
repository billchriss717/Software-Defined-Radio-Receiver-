
clear; close all; clc;
clear functions; rehash;

% Load signal
signal_choice = input('Which signal? (1/2/3): ');

if signal_choice == 1
  dat = load("./mystery_files/mysteryA.mat"); r = dat.r(:)';

  f_if = 2.4e6;
  f_s = 1.5e6;
  srrc_length = 4;
  srrc_rolloff = 0.3;
  T_t = 6.3e-6;
  Rs  = 1/T_t;
  M = f_s / Rs;

elseif signal_choice == 2
  dat = load("./mystery_files/mysteryB.mat"); r = dat.r(:)';

  f_if = 0.8e6;
  f_s = 620e3;
  srrc_length = 8;
  srrc_rolloff = 0.22;
  T_t = 8.0e-6;
  Rs  = 1/T_t;
  M = f_s / Rs;


elseif signal_choice == 3
  dat = load("./mystery_files/mysteryC.mat"); r = dat.r(:)';

  f_if = 1.34e6;
  f_s = 750e3;
  srrc_length = 9;
  srrc_rolloff = 0.18;
  T_t = 5.8e-6;
  Rs  = 1/T_t;
  M = f_s / Rs;

else
  error('bad choice');
end

userDataLength = 105;
preamble = 'A4B no frame header is perfect';
preamble_syms = letters2pam(preamble);  preamble_syms = preamble_syms(:);
preamble_length = length(preamble_syms);

N = length(r);
Ts = 1/f_s
t = (0:N-1)*Ts;

fc = abs(mod(f_if + f_s/2, f_s) - f_s/2)

% Notch filter (only used for the mystery signal C)
if signal_choice == 3
  r_notch = r;
  for f0 = [90e3, 100e3]
    w0 = 2*pi*f0/f_s;
    rr = 0.998;

    b = [1, -2*cos(w0), 1];
    a = [1, -2*rr*cos(w0), rr^2];

    r_notch = filter(b, a, r_notch);
  end
  r = r_notch;
end


%Plot the original signal
figure; plotspec(r, Ts); title("Received signal");

%Downconversion using Costas PLL loop and LPF

bw = (1+srrc_rolloff)/2 * Rs;
wp = min(2*bw/f_s, 0.45);
ws = min(1.25*wp, 0.50);

fl = 100;
ff = [0, wp, ws, 1];
fa = [1, 1, 0, 0];
h  = firpm(fl, ff, fa);

mu = 0.02;

theta = zeros(N,1);

zs = zeros(fl+1,1);
zc = zeros(fl+1,1);
w0 = 2*pi*fc;

for k = 1:N-1
  ph = w0*t(k) + theta(k);
  zs = [zs(2:fl+1); 2*r(k)*sin(ph)];
  zc = [zc(2:fl+1); 2*r(k)*cos(ph)];
  lpfs = flipud(h(:))' * zs;
  lpfc = flipud(h(:))' * zc;
  theta(k+1) = theta(k) - mu*lpfs*lpfc;
end

c = cos(2*pi*fc*t + theta');
r_dm = r.*c ;

r_bb =2*filter(h,1,r_dm);

figure; plotspec(r_bb, Ts); title("Signal basebasnd after downconversion");

% Matched filter (SRRC)

pulse = srrc(srrc_length, srrc_rolloff, round(M));
pulse = pulse/sqrt(sum(pulse.^2));
r_mf  = filter(fliplr(pulse), 1, r_bb);

figure; plotspec(r_mf, Ts); title("Signal after SRRC matched filter");


%  Timing recovery
l = srrc_length * round(M);
tnow = l + 1;
tau = 0;

mu_tau = 0.01;
delta  = 0.5;

r_t = zeros(1, length(r_mf));
tausave = zeros(1, length(r_mf));
i = 0;

while tnow < length(r_mf) - 2*l
  i = i + 1;

  r_t(i) = interpsinc(r_mf, tnow + tau, l);
  xdp   = interpsinc(r_mf, tnow + tau + delta, l);
  xdm   = interpsinc(r_mf, tnow + tau - delta, l);
  dx    = xdp - xdm;

  qx = quantalph(r_t(i), [-3 -1 1 3]);
  tau = tau + mu_tau * dx * (qx - r_t(i));

  tnow = tnow + M;
  tausave(i) = tau;
end


r_t = r_t(1:i);
tausave = tausave(1:i);

figure; plot(r_t,'b.'); grid on; title("Constellation after timing recovery");


% Frame sync (correlation with a known preamble)

payload_length = userDataLength*4;
frame_length = preamble_length + payload_length;

corr_vals = zeros(length(r_t)-preamble_length+1,1);
corr_sign = zeros(length(r_t)-preamble_length+1,1);

for idx = 1:length(corr_vals)
  seg = r_t(idx:idx+preamble_length-1);
  c = sum(seg(:) .* preamble_syms);
  corr_vals(idx) = abs(c);
  corr_sign(idx) = sign(c + 1e-12);
end

[~, pre_start] = max(corr_vals);

all_syms = [];

k = pre_start;
while k + frame_length - 1 <= length(r_t)
  frame_preamble = r_t(k:k+preamble_length-1);
  frame_corr = sum(frame_preamble(:) .* preamble_syms);

  if frame_corr < 0
    frame_multiplier = -1;
  else
    frame_multiplier = 1;
  end

  payload_start = k + preamble_length;
  payload_end   = payload_start + payload_length - 1;

  payload_soft = frame_multiplier * r_t(payload_start:payload_end);
  payload = quantalph(payload_soft, [-3 -1 1 3]);

  all_syms = [all_syms; payload(:)];
  k = k + frame_length;
end

n = length(all_syms);
n_valid = floor(n/4)*4;
all_syms = all_syms(1:n_valid);

% Decode
reconstructed_message = pam2letters(all_syms.');
disp("Reconstructed message");
disp(reconstructed_message);

