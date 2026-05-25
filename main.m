clc
clear
% <설계 정보>

% 재료: 침탄강 (Eh, Carburized and hardened, grade 2)
% 기어 quality: 6 (AGMA 6급)
% 압력각: 20 deg (치직각)
alpha_n = 20; % deg
% uncrowned teeth (일단은 이렇게.)
% commercial enclosed gear units (상업용 밀폐 기어 유닛, 일반적으로 사용되는 기어유닛)

% input power = 50 kW

% input speed = 6000 rpm
n_in = 6000; % rpm

% input torque = 79577 Nmm
T_in = 79577; % Nmm

% output speed(stage1) = 3000 rpm (+- 5%), u = 2 (임시값)
% output speed(stage2) = 4000 rpm (+ -5%), u = 1.5 (임시값)
% required life time: B10 = 5000 hours, 90% reliability (for bearing)

% required life cycle(1stage pinion) = 1.8 * 10^9 cycles
N_1 = 1.8 * 10^9; % cycles

% 1st stage gear ratio extent: [1.905, 2.105]
u1 = [1.905, 2.105];
% 2nd stage gear ratio extent: [1.429, 1.579]
u2 = [1.429, 1.579];

% 표준 모듈 규격 (ISO, JIS 규격 기준)
m_n_lst = [1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3];


% operating-point 헬퍼
% op(m_n, beta, N_p) → d_p, v, W_t 반환. (dp=(mn/cos⁡β)Npd_p = (m_n/\cos\beta)N_p
% dp​=(mn​/cosβ)Np​, v=ω dp/2v=\omega\,d_p/2
% v=ωdp​/2, Wt=2Tin/dpW_t = 2T_{in}/d_p
% Wt​=2Tin​/dp​ — mm↔m 단위만 조심.) 이게 sgm/sgm_c가 요구하는 W_t, v 입력을 채워주는 다리야.

% Design Variable: m, 
% Objective Function
% Constraint

% helical angle = 20 deg (임시값)

% 영향계수, 고정값
K_o = 1.25; % 과부하계수
K_B = 1; % 림두께계수 (rim thickness / gear tooth height >= 1.2)
Z_E = 191;  % Eh
Z_R = 1;    % for normal commercial gear
S_t = 448; % MPa Allowable Bending Stress Number,(Carburized and hardened, grade 2, 10^7 cycles, 신뢰도 0.99)
S_c = 1551; % MPa Allowable Contact Stress Number (Carburized and hardened, grade 2, 10^7 cycles, 신뢰도 0.99)