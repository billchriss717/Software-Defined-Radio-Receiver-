%% ========================================================================
%  Project: Digital Communication Receiver - Mystery Signal Recovery
%  Author:  Tadouanla Guetchuin Billy
%  Description: Professional SDR receiver chain featuring Costas PLL, 
%               Mueller-Muller Timing Recovery, and Frame Synchronization.
% ========================================================================

clear; close all; clc;
addpath('./utils'); 

%% 1. SYSTEM CONFIGURATION & PARAMETER INITIALIZATION
% -------------------------------------------------------------------------
fprintf('--- Digital Receiver Initialization ---\n');
choice = input('Select Target Signal (1, 2, or 3): ');

config = struct();

switch choice
    case 1
        data_file = "./mystery_files/mysteryA.mat";
        config.f_if = 2.4e6;    config.f_s = 1.5e6;
        config.span = 4;        config.beta = 0.3;      config.T_t = 6.3e-6;
    case 2
        data_file = "./mystery_files/mysteryB.mat";
        config.f_if = 0.8e6;    config.f_s = 620e3;
        config.span = 8;        config.beta = 0.22;     config.T_t = 8.0e-6;
    case 3
        data_file = "./mystery_files/mysteryC.mat";
        config.f_if = 1.34e6;   config.f_s = 750e3;
        config.span = 9;        config.beta = 0.18;     config.T_t = 5.8e-6;
    otherwise
        error('Invalid selection. Choose 1, 2, or 3.');
end

% Derived Parameters
config.Rs = 1 / config.T_t;             
config.M  = config.f_s / config.Rs;      
config.Ts = 1 / config.f_s;             

% Load signal
dat = load(data_file); r = dat.r(:)';
N = length(r);
t = (0:N-1) * config.Ts;
fc = abs(mod(config.f_if + config.f_s/2, config.f_s) - config.f_s/2);

%% 2. ADAPTIVE SIGNAL PRE-PROCESSING
% -------------------------------------------------------------------------
if choice == 3
    fprintf('Applying Notch Filters to suppress interference...\n');
    for f0 = [90e3, 100e3]
        w0 = 2*pi*f0/config.f_s;
        rr = 0.998;
        b = [1, -2*cos(w0), 1];
        a = [1, -2*rr*cos(w0), rr^2];
        r = filter(b, a, r);
    end
end

%% 3. CARRIER PHASE RECOVERY (COSTAS PLL)
% -------------------------------------------------------------------------
fprintf('Syncing Carrier Phase (Costas Loop)...\n');
bw = (1 + config.beta)/2 * config.Rs;
wp = min(2*bw/config.f_s, 0.45);
ws = min(1.25*wp, 0.50);
h  = firpm(100, [0, wp, ws, 1], [1, 1, 0, 0]);

mu = 0.02;
theta = zeros(N,1);
zs = zeros(101,1); zc = zeros(101,1);
w0 = 2*pi*fc;

for k = 1:N-1
    ph = w0*t(k) + theta(k);
    zs = [zs(2:101); 2*r(k)*sin(ph)];
    zc = [zc(2:101); 2*r(k)*cos(ph)];
    lpfs = flipud(h(:))' * zs;
    lpfc = flipud(h(:))' * zc;
    theta(k+1) = theta(k) - mu*lpfs*lpfc;
end

r_bb = 2 * filter(h, 1, r .* cos(2*pi*fc*t + theta'));

%% 4. MATCHED FILTERING & SYMBOL TIMING RECOVERY
% -------------------------------------------------------------------------
fprintf('Executing SRRC Matched Filter & Timing Recovery...\n');
pulse = srrc(config.span, config.beta, round(config.M));
pulse = pulse / sqrt(sum(pulse.^2));
r_mf  = filter(fliplr(pulse), 1, r_bb);

l = config.span * round(config.M);
tnow = l + 1;
tau = 0; mu_tau = 0.01; delta = 0.5;

r_t = []; tausave = []; i = 0;

while tnow < length(r_mf) - 2*l
    i = i + 1;
    r_t(i) = interpsinc(r_mf, tnow + tau, l);
    dx = interpsinc(r_mf, tnow + tau + delta, l) - interpsinc(r_mf, tnow + tau - delta, l);
    
    qx = quantalph(r_t(i), [-3 -1 1 3]);
    tau = tau + mu_tau * dx * (qx - r_t(i));
    
    tnow = tnow + config.M;
    tausave(i) = tau;
end

%% 5. FRAME SYNCHRONIZATION MATH
% -------------------------------------------------------------------------
preamble = 'A4B no frame header is perfect';
preamble_syms = letters2pam(preamble)(:);
pre_len = length(preamble_syms);

corr_vals = zeros(length(r_t)-pre_len+1, 1);
for idx = 1:length(corr_vals)
    seg = r_t(idx:idx+pre_len-1);
    corr_vals(idx) = abs(sum(seg(:) .* preamble_syms));
end
[~, pre_start] = max(corr_vals);

%% 6. COMPREHENSIVE VISUALIZATION DASHBOARD
% -------------------------------------------------------------------------
fprintf('Generating Analysis Plots...\n');

% Figure 1: Spectral Analysis
figure('Name', 'Spectral Analysis');
plotspec(r_bb, config.Ts);
title('Baseband Signal Spectrum');
grid on;
print('./Pictures/spectral_analysis_Mystery_file_A.png', '-dpng', '-r600');

% Figure 2: Convergence Analysis
figure('Name', 'Synchronization Performance');
subplot(2,1,1);
plot(theta, '-b', 'LineWidth', 1.5);
title('Costas PLL Phase Tracking'); ylabel('\theta [rad]'); grid on;
subplot(2,1,2);
plot(tausave, '-b', 'LineWidth', 1.5);
title('Timing Error Tracking'); ylabel('\tau'); xlabel('Symbol Index'); grid on;
print('./Pictures/Synchronization_Performance_Mystery_file_A.png', '-dpng', '-r600');

% Figure 3: High-Resolution Eye Diagram (Default Colors)
figure('Name', 'Post-MF Eye Diagram');
hold on;
eye_pts = round(2 * config.M);
for k = 100:700 
    idx = round((k-1)*config.M) + (1:eye_pts);
    if idx(end) < length(r_mf)
        plot(r_mf(idx), 'LineWidth', 2); 
    end
end
title('Post-Matched Filter Eye Diagram'); grid on; axis tight;
hold off;
print('./Pictures/Post-MF_Eye_Diagram_Mystery_file_A.png', '-dpng', '-r600');

% Figure 4: Full Constellation Diagram - Row-wise Horizontal Strips
figure('Name', 'Full Constellation: All Symbols');
% Symbols on Y-axis and Noise on X-axis creates horizontal "rows"
plot(randn(size(r_t))*0.04, r_t, '.'); 
title('Full Constellation: Row-wise Symbols (All Info)');
ylabel('Symbol Amplitude'); xlabel('Quadrature/Noise');
ylim([-5 5]); grid on;
print('./Pictures/Full_Constellation_Mystery_file_A.png', '-dpng', '-r600');

% Figure 5: Frame Synchronization
figure('Name', 'Frame Detection');
plot(corr_vals, '-b', 'LineWidth', 1.5); hold on;
plot(pre_start, corr_vals(pre_start), 'ro', 'LineWidth', 1.5);
title('Preamble Correlation Peaks'); xlabel('Symbol Index'); grid on;
print('./Pictures/Frame Detection_Mystery_file_A.png', '-dpng', '-r600');

%% 7. PAYLOAD EXTRACTION & DECODING
% -------------------------------------------------------------------------
payload_len = 105 * 4; 
frame_len = pre_len + payload_len;
all_payload_syms = [];
k = pre_start;

while k + frame_len - 1 <= length(r_t)
    frame_corr = sum(r_t(k:k+pre_len-1) .* preamble_syms');
    polarity = sign(frame_corr);
    payload_soft = polarity * r_t(k+pre_len : k+frame_len-1);
    payload_hard = quantalph(payload_soft, [-3 -1 1 3]);
    all_payload_syms = [all_payload_syms; payload_hard(:)];
    k = k+frame_len;
end

% Final terminal output
reconstructed_msg = pam2letters(all_payload_syms(1:floor(length(all_payload_syms)/4)*4).');
fprintf('\n==========================================\n');
fprintf('RECONSTRUCTED MESSAGE:\n%s\n', reconstructed_msg);
fprintf('==========================================\n');
