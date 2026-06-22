clc
clear

%% ===================== 설계 정보 (design.m 과 동일) =====================
% GA 독립 검증용 — fmincon enumeration 결과를 알고리즘 차이만으로 교차검증
% 초기 population은 순수 랜덤, m_n_lst 전체 후보 사용 (시딩 없음)

n_in    = 6000;        % [rpm]
T_in    = 79577.5;     % [Nmm]
alpha_n = 20;          % [deg]

u1_extent = [1.905, 2.105];
u2_extent = [1.429, 1.579];
m_n_lst   = [1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3];
N_cyc     = 1.8e9;

beta_extent = [15, 30];
db_extent   = [0.8, 1.5];

SF_F_min      = 1.4;
SF_H_min      = 1.1;
eps_alpha_min = 1.2;

Np_max = 25;

%% ===================== 사전 계산 =====================
beta_max = beta_extent(2);

N_min1  = gear.interference_free_p(alpha_n, beta_max, u1_extent(1));
Np1_min = floor(max(N_min1, 13));

N_min2  = gear.interference_free_p(alpha_n, beta_max, u2_extent(1));
Np2_min = floor(max(N_min2, 13));

% K = (m_n2*Σ2)/(m_n1*Σ1) 허용 범위 (beta2 실수해 존재 조건)
ratio_lo = cosd(beta_extent(2)) / cosd(beta_extent(1));
ratio_hi = cosd(beta_extent(1)) / cosd(beta_extent(2));

%% ===================== GA 설계 변수 정의 =====================
% x = [i_mn1, i_mn2, Np1, Ng1, Np2, Ng2, beta1, lambda1, lambda2]
%   i_mn1, i_mn2 : m_n_lst 인덱스 (정수, 1~numel(m_n_lst))
%   Np1, Ng1, Np2, Ng2 : 정수
%   beta1 : 연속 [deg]
%   lambda1 = db_ratio1, lambda2 = db_ratio2 : 연속
%   beta2 는 변수 아님 — K*cosd(beta1) 로 유도 (design.m 과 동일)
% IntCon = [1 2 3 4 5 6]

nvars  = 9;
IntCon = [1 2 3 4 5 6];

% Ng 전역 bounds: Np 종속 범위는 제약함수에서 기어비 제약으로 처리
Ng1_lo_g = floor(u1_extent(1) * Np1_min);
Ng1_hi_g = ceil( u1_extent(2) * Np_max );
Ng2_lo_g = floor(u2_extent(1) * Np2_min);
Ng2_hi_g = ceil( u2_extent(2) * Np_max );

lb = [1,              1,              Np1_min, Ng1_lo_g, Np2_min, Ng2_lo_g, beta_extent(1), db_extent(1), db_extent(1)];
ub = [numel(m_n_lst), numel(m_n_lst), Np_max,  Ng1_hi_g, Np_max,  Ng2_hi_g, beta_extent(2), db_extent(2), db_extent(2)];

%% ===================== GA 클로저 =====================
objf_ga = @(x) ga_vol(x, m_n_lst);
conf_ga = @(x) ga_constr(x, m_n_lst, alpha_n, n_in, T_in, N_cyc, ...
                          u1_extent, u2_extent, ratio_lo, ratio_hi, ...
                          SF_F_min, SF_H_min, eps_alpha_min, beta_extent);

%% ===================== GA 옵션 =====================
opts_ga = optimoptions('ga', ...
    'PopulationSize',    200, ...
    'MaxGenerations',    400, ...
    'FunctionTolerance', 1e-6, ...
    'MaxStallGenerations', 80, ...
    'OutputFcn',         @ga_progress, ...
    'Display', 'off');
% Display,'off' : 내장 테이블 억제. gen-50 진행 상황은 ga_progress OutputFcn 이 출력.

%% ===================== N회 반복 실행 =====================
% rng 시드를 바꿔 N회 실행 -> 확률적 분산 및 전체 best 확인
N_runs = 20;

vol_list  = nan(N_runs, 1);
x_list    = nan(N_runs, nvars);
flag_list = nan(N_runs, 1);

fprintf('GA 실행 중 (총 %d 회, PopSize=%d, MaxGen=%d)...\n', N_runs, 200, 400);
for run = 1:N_runs
    rng(run);  % 시드 = run 번호로 재현성 보장
    fprintf('\n--- run %2d / %2d ---\n', run, N_runs);
    [x_opt, f_opt, exitflag] = ga(objf_ga, nvars, [],[],[],[], lb, ub, conf_ga, IntCon, opts_ga);
    vol_list(run)  = f_opt;
    x_list(run,:)  = x_opt;
    flag_list(run) = exitflag;
    fprintf('  -> 최종 vol = %.4e mm^3  flag = %d\n', f_opt, exitflag);
end

%% ===================== 결과 보고 =====================
% ga_vol는 비실현 설계에 1e30 반환 -> 1e29 미만을 실현 가능 해로 판별
valid = vol_list < 1e29;
if ~any(valid)
    error('모든 GA 실행이 실현 가능한 해를 찾지 못했습니다.');
end

fprintf('\n==== GA 반복 실행 부피 분포 (실현 가능 %d / %d 회) ====\n', sum(valid), N_runs);
fprintf('  최솟값   : %.4e mm^3\n', min(vol_list(valid)));
fprintf('  평균     : %.4e mm^3\n', mean(vol_list(valid)));
fprintf('  표준편차 : %.4e mm^3\n', std(vol_list(valid)));

[~, best_run] = min(vol_list);
xb = x_list(best_run,:);

% 정수 변환 및 물리량 복원
m_n1  = m_n_lst(round(xb(1)));  m_n2 = m_n_lst(round(xb(2)));
Np1   = round(xb(3));  Ng1 = round(xb(4));
Np2   = round(xb(5));  Ng2 = round(xb(6));
beta1 = xb(7);  lam1 = xb(8);  lam2 = xb(9);
Sigma1 = Np1 + Ng1;  Sigma2 = Np2 + Ng2;
K      = (m_n2 * Sigma2) / (m_n1 * Sigma1);
beta2  = acosd(K * cosd(beta1));
u1 = Ng1 / Np1;  u2 = Ng2 / Np2;

s1 = eval_stage(m_n1, beta1, lam1, Np1, Ng1, alpha_n, n_in, T_in, N_cyc);
s2 = eval_stage(m_n2, beta2, lam2, Np2, Ng2, alpha_n, n_in, T_in, N_cyc);
a  = m_n1 * Sigma1 / (2*cosd(beta1));

% design.m 과 동일한 출력 포맷
fprintf('\n==== GA 최적 설계 (design.m 동일 포맷) ====\n');
fprintf('%-5s %-5s %-4s %-4s %-4s %-4s %-7s %-7s %-7s %-7s %-7s %-7s %-7s %-7s %-7s %-6s %-6s %-6s %-6s %-10s\n', ...
    'mn1','mn2','Np1','Ng1','Np2','Ng2','beta1','beta2','dp1','dg1','b1','dp2','dg2','b2','a','SF1','SH1','SF2','SH2','vol[mm^3]');
fprintf('%-5.2f %-5.2f %-4d %-4d %-4d %-4d %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-6.2f %-6.2f %-6.2f %-6.2f %-10.3e\n', ...
    m_n1, m_n2, Np1, Ng1, Np2, Ng2, beta1, beta2, s1.dp, s1.dg, s1.b, s2.dp, s2.dg, s2.b, a, ...
    min(s1.SFp,s1.SFg), min(s1.SHp,s1.SHg), min(s2.SFp,s2.SFg), min(s2.SHp,s2.SHg), vol_list(best_run));

fprintf('\n==== GA 최적 설계 상세 ====\n');
fprintf('1단 모듈 m_n1 = %.2f mm  |  2단 모듈 m_n2 = %.2f mm\n', m_n1, m_n2);
fprintf('헬릭스 beta1 = %.3f deg  |  beta2 = %.3f deg\n', beta1, beta2);
fprintf('1단 : Np=%d, Ng=%d (u=%.3f), dp=%.2f mm, dg=%.2f mm, b=%.2f mm\n', Np1, Ng1, u1, s1.dp, s1.dg, s1.b);
fprintf('2단 : Np=%d, Ng=%d (u=%.3f), dp=%.2f mm, dg=%.2f mm, b=%.2f mm\n', Np2, Ng2, u2, s2.dp, s2.dg, s2.b);
fprintf('중심거리 a  = %.2f mm (두 단 공유)\n', a);
fprintf('안전계수 1단: SF_F=%.2f  SF_H=%.2f | 2단: SF_F=%.2f  SF_H=%.2f\n', ...
    min(s1.SFp,s1.SFg), min(s1.SHp,s1.SHg), min(s2.SFp,s2.SFg), min(s2.SHp,s2.SHg));
fprintf('접촉비   1단: %.3f | 2단: %.3f\n', s1.eps, s2.eps);
fprintf('블랭크 부피 = %.4e mm^3\n', vol_list(best_run));


%% ===================== 로컬 함수 (3개) =====================
function V = ga_vol(x, m_n_lst)
    % 목적함수: design.m volume_obj 로직과 동일, GA 변수 x에서 decode
    m_n1  = m_n_lst(round(x(1)));  m_n2 = m_n_lst(round(x(2)));
    Np1   = round(x(3));  Ng1 = round(x(4));
    Np2   = round(x(5));  Ng2 = round(x(6));
    beta1 = x(7);  lam1 = x(8);  lam2 = x(9);
    Sigma1 = Np1 + Ng1;  Sigma2 = Np2 + Ng2;
    c1 = cosd(beta1);
    c2 = (m_n2*Sigma2) / (m_n1*Sigma1) * c1;
    if c2 >= 1 || c2 <= 0, V = 1e30; return; end  % beta2 실수해 없음 -> 실현 불가
    dp1 = m_n1*Np1/c1;  dg1 = m_n1*Ng1/c1;
    dp2 = m_n2*Np2/c2;  dg2 = m_n2*Ng2/c2;
    b1  = dp1/lam1;  b2 = dp2/lam2;
    V = (pi/4) * ( (dp1^2 + dg1^2)*b1 + (dp2^2 + dg2^2)*b2 );
end

function [c, ceq] = ga_constr(x, m_n_lst, alpha_n, n_in, T_in, N_cyc, ...
                               u1_extent, u2_extent, ratio_lo, ratio_hi, ...
                               SF_F_min, SF_H_min, eps_min, beta_extent)
    % 비선형 제약: design.m constr 로직 + enumeration 게이트(기어비, K 범위) 통합
    ceq  = [];
    m_n1 = m_n_lst(round(x(1)));  m_n2 = m_n_lst(round(x(2)));
    Np1  = round(x(3));  Ng1 = round(x(4));
    Np2  = round(x(5));  Ng2 = round(x(6));
    beta1 = x(7);  lam1 = x(8);  lam2 = x(9);
    Sigma1 = Np1 + Ng1;  Sigma2 = Np2 + Ng2;
    u1   = Ng1 / Np1;  u2 = Ng2 / Np2;
    K    = (m_n2 * Sigma2) / (m_n1 * Sigma1);
    cos2 = K * cosd(beta1);

    if cos2 >= 1 || cos2 <= 0  % beta2 실수해 없음 -> 큰 위반값 반환 (NaN/복소수 방지)
        c = ones(22, 1) * 1e6; return;
    end
    beta2 = acosd(cos2);

    % beta2·기어비가 범위 밖 -> eval_stage(AGMA 호출) 없이 즉시 반환
    if beta2 < beta_extent(1) || beta2 > beta_extent(2) || ...
       u1 < u1_extent(1) || u1 > u1_extent(2) || ...
       u2 < u2_extent(1) || u2 > u2_extent(2)
        c = ones(22, 1) * 1e6; return;
    end

    s1 = eval_stage(m_n1, beta1, lam1, Np1, Ng1, alpha_n, n_in, T_in, N_cyc);
    s2 = eval_stage(m_n2, beta2, lam2, Np2, Ng2, alpha_n, n_in, T_in, N_cyc);

    % ── 피니언과 기어 잇수 서로소 제약 (toggle) ──────────────────────────────────
    % design.m gcd 게이트와 apples-to-apples 비교 시 아래 두 줄 주석 해제
    gcd_c1 = 0;  % gcd(Np1,Ng1)~=1 이면 1e6
    gcd_c2 = 0;  % gcd(Np2,Ng2)~=1 이면 1e6
    % if gcd(Np1, Ng1) ~= 1, gcd_c1 = 1e6; end
    % if gcd(Np2, Ng2) ~= 1, gcd_c2 = 1e6; end
    % ─────────────────────────────────────────────────────────

    c = [ u1_extent(1) - u1;          % 1단 기어비 하한
          u1 - u1_extent(2);          % 1단 기어비 상한
          u2_extent(1) - u2;          % 2단 기어비 하한
          u2 - u2_extent(2);          % 2단 기어비 상한
          ratio_lo - K;               % K 하한 (beta2 실수해 범위)
          K - ratio_hi;               % K 상한
          SF_F_min - s1.SFp;          % 1단 굽힘 (피니언)
          SF_F_min - s1.SFg;          % 1단 굽힘 (기어)
          SF_H_min - s1.SHp;          % 1단 접촉 (피니언)
          SF_H_min - s1.SHg;          % 1단 접촉 (기어)
          eps_min   - s1.eps;         % 1단 접촉비
          s1.Nmin   - Np1;            % 1단 언더컷
          SF_F_min - s2.SFp;          % 2단 굽힘 (피니언)
          SF_F_min - s2.SFg;          % 2단 굽힘 (기어)
          SF_H_min - s2.SHp;          % 2단 접촉 (피니언)
          SF_H_min - s2.SHg;          % 2단 접촉 (기어)
          eps_min   - s2.eps;         % 2단 접촉비
          s2.Nmin   - Np2;            % 2단 언더컷
          beta2 - beta_extent(2);     % beta2 상한
          beta_extent(1) - beta2;     % beta2 하한
          gcd_c1;                     % 서로소 (1단, 기본 off)
          gcd_c2 ];                   % 서로소 (2단, 기본 off)
end

function [state, options, changed] = ga_progress(options, state, flag)
    % 50 generation 마다 진행 상황 출력, 수렴 시 최종 보고
    changed = false;
    switch flag
        case 'iter'
            if mod(state.Generation, 50) == 0
                fprintf('    Gen %4d  best = %.4e mm^3\n', state.Generation, state.Best(end));
            end
        case 'done'
            fprintf('    Gen %4d  [수렴] best = %.4e mm^3\n', state.Generation, state.Best(end));
    end
end

function s = eval_stage(m_n, beta, db_ratio, Np, Ng, alpha_n, n_in, T_in, N_cyc)
    % design.m eval_stage 와 완전히 동일 (시그니처 변경 없음)
    cb  = cosd(beta);
    m_t = m_n / cb;
    dp  = m_t * Np;   dg = m_t * Ng;
    b   = dp / db_ratio;
    v   = (2*pi*n_in/60) * (dp/2) / 1000;
    Wt  = 2 * T_in / dp;

    [SFp, SFg] = AGMA.S_F(N_cyc, Wt, v, m_n, alpha_n, beta, b, Np, Ng);
    [SHp, SHg] = AGMA.S_H(N_cyc, Wt, v, m_n, alpha_n, beta, b, Np, Ng);

    alpha_t = atand( tand(alpha_n) / cb );
    rp  = dp/2;  rg = dg/2;
    rbp = rp*cosd(alpha_t);  rbg = rg*cosd(alpha_t);
    Z   = sqrt((rp+m_n)^2 - rbp^2) + sqrt((rg+m_n)^2 - rbg^2) - (rp+rg)*sind(alpha_t);
    eps = Z / (pi*m_t*cosd(alpha_t));

    Nmin = gear.interference_free_p(alpha_n, beta, Ng/Np);

    s = struct('dp',dp,'dg',dg,'b',b,'SFp',SFp,'SFg',SFg, ...
               'SHp',SHp,'SHg',SHg,'eps',eps,'Nmin',Nmin);
end
