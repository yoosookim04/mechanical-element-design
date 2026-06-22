clc
clear

% <설계 정보>
% Design Variable: m_n, Np1, Ng1, Np2, Ng2, beta1, beta2, b1, b2
%% ===================== 설계 정보 =====================
% 재료 : 침탄강 (Eh, Carburized and hardened, grade 2)
% 기어 quality : 6 (AGMA),  uncrowned teeth(일단은 이렇게.),  commercial enclosed gear units (상업적으로 가장 많이 사용되는 거)
% 구조 : 2-speed (1단/2단 병렬 기어쌍). 두 쌍이 같은 입력축-출력축 위에 있으므로
%        중심거리 공유. -> 등식: Sigma1/cos(β1) = Sigma2/cos(β2) (모듈 공유, β2는 β1로부터 유도)
% **두 단 모듈 통일, 헬릭스각은 단별로 독립 최적화 (β2는 중심거리 등식에서 결정)
%        입력동력 = 출력동력 (50 kW), 두 단 모두 풀 토크/풀 수명으로 설계(보수적)

n_in    = 6000;        % [rpm] input speed (두 단 피니언 모두 입력축 위 -> 동일 회전수)
T_in    = 79577.5;     % [Nmm] input torque (= 50kW / (6000rpm))
alpha_n = 20;          % [deg] normal pressure angle

u1_extent = [1.905, 2.105];   % 1단 기어비 허용범위 (target 2.0,  6000->3000 ±5%)
u2_extent = [1.429, 1.579];   % 2단 기어비 허용범위 (target 1.5,  6000->4000 ±5%)
m_n_lst   = [1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3];  % 표준 모듈 (ISO/JIS)
N_cyc     = 1.8e9;     % [cycles] 피니언 요구 수명 (6000rpm * 60 * 5000h)

beta_extent = [15, 30];   % [deg] helix angle 범위 (각 단에 공통 적용)
db_extent   = [0.8, 1.5]; % d/b (피치원지름/치폭) 범위 — 피니언·기어 모두 적용

SF_F_min      = 1.4;      % bending  안전계수 하한 (제약)
SF_H_min      = 1.1;      % contact  안전계수 하한 (제약)
eps_alpha_min = 1.2;      % 횡 접촉비 하한 (제약)

Np_max = 25;              % 외부 루프 피니언 잇수 상한 (작을수록 가벼움 -> 최적은 하한 근처)

% 영향계수, 고정값 정보 (AGMA 패키지 내부에 하드코딩되어 있음)
%K_o = 1.25; % 과부하계수
%K_B = 1; % 림두께계수 (rim thickness / gear tooth height >= 1.2 가정)
%Z_E = 191;  % sqrt(MPa) 탄성계수,포아송비 -> 탄성정수계수 (Eh, Carburized and hardened, grade 2)
%Z_R = 1;    % for normal commercial gear
%S_t = 448; % MPa Allowable Bending Stress Number,(Carburized and hardened, grade 2, 10^7 cycles, 신뢰도 0.99)
%S_c = 1551; % MPa Allowable Contact Stress Number (Carburized and hardened, grade 2, 10^7 cycles, 신뢰도 0.99)

%% ===================== 최적화 루프 =====================
beta_max = beta_extent(2); % 간섭회피에 대한 최소 피니언 잇수가 가장 작게 나오도록, 가장 큰 beta 기준으로 시작.

% 잇수 하한: 가장 느슨한 beta(=30°)에서의 언더컷 미발생 최소잇수 (언더컷 발생 최소잇수는 beta가 커질수록 작아짐)

% 1단
N_min1  = gear.interference_free_p(alpha_n, beta_max, u1_extent(1));
% N_min이 기어비에 비례해서, 가장 작은 기어비에 대한 잇수부터 탐색하기 위한 목적으로 u_extent(1) 기준으로 계산
Np1_min = floor(max(N_min1, 13)); % 1단 피니언 최소잇수

% 2단
N_min2  = gear.interference_free_p(alpha_n, beta_max, u2_extent(1));
Np2_min = floor(max(N_min2, 13)); % 2단 피니언 최소잇수

% Sigma2/Sigma1 비율의 허용 범위: (β2 = acosd((Sigma2/Sigma1)*cosd(beta1))
% a 등식 m_n*Sigma1/cosβ1 = m_n*Sigma2/cosβ2 -> Sigma2/Sigma1 = cosβ2/cosβ1
% β1·β2 ∈ [beta_min,beta_max] 에서 실수해가 존재하려면,
ratio_lo = cosd(beta_extent(2)) / cosd(beta_extent(1)); % 하한 (β1_max / β2_min)
ratio_hi = cosd(beta_extent(1)) / cosd(beta_extent(2)); % 상한 (β1_min / β2_max)

opts = optimoptions('fmincon', 'Display','off', 'Algorithm','sqp', ...
                    'ConstraintTolerance', 1e-6);
% fmincon 옵션 설정
% 'Display','off' : 최적화 진행 상황 출력 X
% 'Algorithm','sqp' : 제약이 있는 비선형 최적화 문제에 적합한 알고리즘 선택
% 'ConstraintTolerance', 1e-6 : 제약을 만족했다고 허용하는 오차 크기

R = struct('mn',{},'Np1',{},'Ng1',{},'u1',{},'Np2',{},'Ng2',{},'u2',{}, ...
           'Sigma1',{},'Sigma2',{},'beta1',{},'beta2',{}, ...
           'dp1',{},'dg1',{},'b1',{},'dp2',{},'dg2',{},'b2',{},'a',{},'vol',{}, ...
           'SF1',{},'SH1',{},'SF2',{},'SH2',{},'eps1',{},'eps2',{});
% 결과 보고할 때 사용할 빈 구조체 배열. 최적화 루프에서 실현 가능한 설계가 나올 때마다 구조체로 변수들이 저장됨.


for m_n = m_n_lst
    for Np1 = Np1_min : Np_max
        Ng1_lo = ceil( u1_extent(1) * Np1 ); % 기어비를 만족하는 1단 기어의 최소잇수
        Ng1_hi = floor(u1_extent(2) * Np1 ); % 기어비를 만족하는 1단 기어의 최대잇수
        for Ng1 = Ng1_lo : Ng1_hi
            u1     = Ng1 / Np1;  % 최종 기어비 (1단)
            Sigma1 = Np1 + Ng1;  % 1단 잇수 합 (중심거리 a = m_n*Sigma1/(2*cosd(beta1)))
            if Np1 < gear.interference_free_p(alpha_n, beta_max, u1), continue; end % 1단 최종 기어비가 간섭회피하는지 확인
% ---------------- m_n에 대해 간섭회피 조건 하에 1단 기어쌍 잇수 선정 완료 -----------------

            for Np2 = Np2_min : Np_max
                Ng2_lo = ceil( u2_extent(1) * Np2 ); % 기어비를 만족하는 2단 기어의 최소잇수
                Ng2_hi = floor(u2_extent(2) * Np2 ); % 기어비를 만족하는 2단 기어의 최대잇수
                for Ng2 = Ng2_lo : Ng2_hi
                    u2     = Ng2 / Np2;   % 최종 기어비 (2단)
                    Sigma2 = Np2 + Ng2;   % 2단 잇수 합 (중심거리 a = m_n*Sigma2/(2*cosd(beta2)))
                    if Np2 < gear.interference_free_p(alpha_n, beta_max, u2), continue; end % 2단 최종 기어비가 간섭회피하는지 확인
% ---------------- m_n에 대해 간섭회피 조건 하에 2단 기어쌍 잇수 선정 완료 -----------------

                    % Sigma2/Sigma1 비율이 허용 범위 확인 (beta2가 정의 가능한 범위 내에 있는지)
                    ratio = Sigma2 / Sigma1;
                    if ratio < ratio_lo || ratio > ratio_hi, continue; end

                    % ── 피니언과 기어 잇수 서로소 제약 (toggle) ──────────────────────────────────
                    % 이 블록 전체를 주석처리하면 서로소 조건 비활성화 (피니언과 기어 잇수가 서로소인 경우만 pass)
                    % if gcd(Np1, Ng1) ~= 1, continue; end   % (~= : !=)
                    % if gcd(Np2, Ng2) ~= 1, continue; end
                    % ─────────────────────────────────────────────────────────

                    % -------- 내부 최적화: x = [beta1, db_ratio1, db_ratio2] --------
                    % beta2는 beta2 = acosd( (Sigma2/Sigma1)*cosd(beta1) ) 로 유도 (중심거리 등식)
                    x0 = [mean(beta_extent), mean(db_extent), mean(db_extent)];
                    lb = [beta_extent(1),    db_extent(1),    db_extent(1)];
                    ub = [beta_extent(2),    db_extent(2),    db_extent(2)];

                    objf = @(x) volume_obj(x, m_n, Np1, Ng1, Np2, Ng2, Sigma1, Sigma2);
                    conf = @(x) constr(x, m_n, Np1, Ng1, Np2, Ng2, Sigma1, Sigma2, ...
                                       alpha_n, n_in, T_in, N_cyc, ...
                                       SF_F_min, SF_H_min, eps_alpha_min, beta_extent);

                    [xo, fo, flag] = fmincon(objf, x0, [],[],[],[], lb, ub, conf, opts);
                    % xo : 최적화된 설계 변수 (beta1, db_ratio1, db_ratio2)
                    % fo : 최적화된 목적 함수 값 (블랭크 부피)
                    % flag : 최적화 종료 상태 (1: 수렴, 0: 최대 반복 횟수 초과, -2: 제약 위반 등)

                    if flag <= 0, continue; end          % 수렴 실패 -> 다음 루프

                    cc = conf(xo);                        % 미세 위반 재확인
                    if any(cc > 1e-4), continue; end

                    % beta2 유도 (보고용)
                    beta2 = acosd( (Sigma2/Sigma1) * cosd(xo(1)) );

                    % 결과 저장 (보고용 재계산 = eval_stage 재사용)
                    s1 = eval_stage(m_n, xo(1),    xo(2), Np1, Ng1, alpha_n, n_in, T_in, N_cyc);
                    s2 = eval_stage(m_n, beta2, xo(3), Np2, Ng2, alpha_n, n_in, T_in, N_cyc);
                    a  = m_n * Sigma1 / (2*cosd(xo(1)));   % 두 단 공유 중심거리 (beta1 기준)
                    R(end+1) = struct('mn',m_n,'Np1',Np1,'Ng1',Ng1,'u1',u1, ...
                        'Np2',Np2,'Ng2',Ng2,'u2',u2,'Sigma1',Sigma1,'Sigma2',Sigma2, ...
                        'beta1',xo(1),'beta2',beta2, ...
                        'dp1',s1.dp,'dg1',s1.dg,'b1',s1.b,'dp2',s2.dp,'dg2',s2.dg,'b2',s2.b,'a',a,'vol',fo, ...
                        'SF1',min(s1.SFp,s1.SFg),'SH1',min(s1.SHp,s1.SHg), ...
                        'SF2',min(s2.SFp,s2.SFg),'SH2',min(s2.SHp,s2.SHg), ...
                        'eps1',s1.eps,'eps2',s2.eps); %#ok<SAGROW>
                end
            end
        end
    end
end

%% ===================== 결과 보고 =====================
if isempty(R)
    error('실현 가능한 설계를 찾지 못했습니다. 범위(잇수/beta/b·d/모듈)를 확인하세요.');
end

[~, order] = sort([R.vol]);
R = R(order);

fprintf('\n==== 실현 가능 설계 %d 개 (부피 기준 정렬) ====\n', numel(R));
fprintf('%-5s %-4s %-4s %-4s %-4s %-7s %-7s %-7s %-7s %-7s %-7s %-7s %-7s %-7s %-6s %-6s %-6s %-6s %-10s\n', ...
    'm_n','Np1','Ng1','Np2','Ng2','beta1','beta2','dp1','dg1','b1','dp2','dg2','b2','a','SF1','SH1','SF2','SH2','vol[mm^3]');
nshow = min(10, numel(R));
for k = 1:nshow
    r = R(k);
    fprintf('%-5.2f %-4d %-4d %-4d %-4d %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-6.2f %-6.2f %-6.2f %-6.2f %-10.3e\n', ...
        r.mn, r.Np1, r.Ng1, r.Np2, r.Ng2, r.beta1, r.beta2, r.dp1, r.dg1, r.b1, r.dp2, r.dg2, r.b2, r.a, ...
        r.SF1, r.SH1, r.SF2, r.SH2, r.vol);
end

best = R(1);
fprintf('\n==== 최적 설계 ====\n');
fprintf('모듈  m_n    = %.2f mm\n', best.mn);
fprintf('헬릭스 beta1 = %.3f deg  |  beta2 = %.3f deg\n', best.beta1, best.beta2);
fprintf('1단 : Np=%d, Ng=%d (u=%.3f), dp=%.2f mm, dg=%.2f mm, b=%.2f mm\n', best.Np1, best.Ng1, best.u1, best.dp1, best.dg1, best.b1);
fprintf('2단 : Np=%d, Ng=%d (u=%.3f), dp=%.2f mm, dg=%.2f mm, b=%.2f mm\n', best.Np2, best.Ng2, best.u2, best.dp2, best.dg2, best.b2);
fprintf('중심거리 a  = %.2f mm (두 단 공유)\n', best.a);
fprintf('안전계수 1단: SF_F=%.2f  SF_H=%.2f | 2단: SF_F=%.2f  SF_H=%.2f\n', ...
    best.SF1, best.SH1, best.SF2, best.SH2);
fprintf('접촉비   1단: %.3f | 2단: %.3f\n', best.eps1, best.eps2);
fprintf('블랭크 부피 = %.4e mm^3\n', best.vol);


%% ===================== 로컬 함수 (3개) =====================
function V = volume_obj(x, m_n, Np1, Ng1, Np2, Ng2, Sigma1, Sigma2)
    % 목적함수: 각 기어를 피치원에 대한 원통이라고 가정한 전체 기어 부피 합 ~ 무게와 가장 직결된다고 예상 (priority #1)
    % beta2는 중심거리 등식 Sigma1/cosβ1 = Sigma2/cosβ2 에서 유도; acosd 없이 cos값만 사용
    beta1 = x(1);  c1 = cosd(beta1);
    c2    = (Sigma2/Sigma1) * c1;   % = cosd(beta2), 중심거리 등식으로 유도
    if c2 >= 1, V = 1e30; return; end  % beta2 실수해 없음 -> 실현 불가
    dp1 = m_n*Np1/c1;  dg1 = m_n*Ng1/c1;
    dp2 = m_n*Np2/c2;  dg2 = m_n*Ng2/c2;
    b1  = dp1/x(2);    b2  = dp2/x(3);
    V = (pi/4) * ( (dp1^2 + dg1^2)*b1 + (dp2^2 + dg2^2)*b2 );
end

function [c, ceq] = constr(x, m_n, Np1, Ng1, Np2, Ng2, Sigma1, Sigma2, ...
                           alpha_n, n_in, T_in, N_cyc, ...
                           SF_F_min, SF_H_min, eps_min, beta_extent)
    ceq   = [];
    beta1 = x(1);
    cos2  = (Sigma2/Sigma1) * cosd(beta1);   % = cosd(beta2)
    if cos2 >= 1  % beta2 실수해 없음 -> 모든 제약에 큰 위반값 반환 (NaN/복소수 방지)
        c = ones(14, 1) * 1e6;  return;
    end
    beta2 = acosd(cos2);
    s1 = eval_stage(m_n, beta1, x(2), Np1, Ng1, alpha_n, n_in, T_in, N_cyc);
    s2 = eval_stage(m_n, beta2, x(3), Np2, Ng2, alpha_n, n_in, T_in, N_cyc);
    % g(x) <= 0  (d/b 범위는 피니언 기준: bounds lb/ub 로 처리, 기어는 미적용)
    c = [ SF_F_min - s1.SFp;  SF_F_min - s1.SFg;   % 1단 굽힘
          SF_H_min - s1.SHp;  SF_H_min - s1.SHg;   % 1단 접촉
          eps_min  - s1.eps;                         % 1단 접촉비
          s1.Nmin  - Np1;                            % 1단 언더컷 (beta1 종속)
          SF_F_min - s2.SFp;  SF_F_min - s2.SFg;   % 2단 굽힘
          SF_H_min - s2.SHp;  SF_H_min - s2.SHg;   % 2단 접촉
          eps_min  - s2.eps;                         % 2단 접촉비
          s2.Nmin  - Np2;                            % 2단 언더컷 (beta2 종속)
          beta2 - beta_extent(2);                    % beta2 상한 제약
          beta_extent(1) - beta2 ];                  % beta2 하한 제약
end

function s = eval_stage(m_n, beta, db_ratio, Np, Ng, alpha_n, n_in, T_in, N_cyc) % db_ratio = d_p/b
    % 한 기어쌍의 모든 설계량 계산 (operating point + 강도 + 접촉비 + 언더컷)
    cb  = cosd(beta);
    m_t = m_n / cb;
    dp  = m_t * Np;   dg = m_t * Ng;     % 피치원 지름 [mm]
    b   = dp / db_ratio;                       % 치폭 [mm]  (db_ratio = d_p/b)
    v   = (2*pi*n_in/60) * (dp/2) / 1000; % 선속도 [m/s]  (mm->m)
    Wt  = 2 * T_in / dp;                  % 전달하중 [N]   (Nmm, mm)

    % 강도
    [SFp, SFg] = AGMA.S_F(N_cyc, Wt, v, m_n, alpha_n, beta, b, Np, Ng);
    [SHp, SHg] = AGMA.S_H(N_cyc, Wt, v, m_n, alpha_n, beta, b, Np, Ng);

    % 횡 접촉비 (Z_I_helical 작용선 길이와 동일 기하, addendum = m_n)
    alpha_t = atand( tand(alpha_n) / cb );
    rp  = dp/2;  rg = dg/2;
    rbp = rp*cosd(alpha_t);  rbg = rg*cosd(alpha_t);
    Z   = sqrt((rp+m_n)^2 - rbp^2) + sqrt((rg+m_n)^2 - rbg^2) - (rp+rg)*sind(alpha_t);
    eps = Z / (pi*m_t*cosd(alpha_t));

    Nmin = gear.interference_free_p(alpha_n, beta, Ng/Np);   

    s = struct('dp',dp,'dg',dg,'b',b,'SFp',SFp,'SFg',SFg, ...
               'SHp',SHp,'SHg',SHg,'eps',eps,'Nmin',Nmin);
end
