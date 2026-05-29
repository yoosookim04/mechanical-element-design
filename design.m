clc
clear

% <설계 정보>


%beta_extent = [15,30]; % [deg] helix angle extent
%db_extent = [0.8, 1.5]; % face width to pitch diameter ratio extent



% Design Variable: m_n, N_p, N_g, beta, b

% 영향계수, 고정값 정보
%K_o = 1.25; % 과부하계수
%K_B = 1; % 림두께계수 (rim thickness / gear tooth height >= 1.2)
%Z_E = 191;  % sqrt(MPa) 탄성계수,포아송비 -> 탄성정수계수 (Eh, Carburized and hardened, grade 2)
%Z_R = 1;    % for normal commercial gear
%S_t = 448; % MPa Allowable Bending Stress Number,(Carburized and hardened, grade 2, 10^7 cycles, 신뢰도 0.99)
%S_c = 1551; % MPa Allowable Contact Stress Number (Carburized and hardened, grade 2, 10^7 cycles, 신뢰도 0.99)

% 임시값
% beta = 30 (언더컷 free 잇수가 가장 작게 나옴)
% u1 = 2, u2 = 1.5 (이후 잇수 결정 되면 허용 오차 내에서 수정될듯)

%% ===================== 설계 정보 =====================
% 재료 : 침탄강 (Eh, Carburized and hardened, grade 2)
% 기어 quality : 6 (AGMA),  uncrowned teeth(일단은 이렇게.),  commercial enclosed gear units (상업적으로 가장 많이 사용되는 거)
% 구조 : 2-speed (1단/2단 병렬 기어쌍). 두 쌍이 같은 입력축-출력축 위에 있으므로
%        중심거리 공유. -> "잇수 합 동일" 제약으로 구현.
% 가정 : 두 단 모듈/헬릭스각 통일  =>  N_p1+N_g1 = N_p2+N_g2 (Sigma 동일)
%        입력동력 = 출력동력 (50 kW), 두 단 모두 풀 토크/풀 수명으로 설계(보수적)

n_in    = 6000;        % [rpm] input speed (두 단 피니언 모두 입력축 위 -> 동일 회전수)
T_in    = 79577.5;     % [Nmm] input torque (= 50kW / (6000rpm))
alpha_n = 20;          % [deg] normal pressure angle

u1_extent = [1.905, 2.105];   % 1단 기어비 허용범위 (target 2.0,  6000->3000 ±5%)
u2_extent = [1.429, 1.579];   % 2단 기어비 허용범위 (target 1.5,  6000->4000 ±5%)
m_n_lst   = [1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3];  % 표준 모듈 (ISO/JIS)
N_cyc     = 1.8e9;     % [cycles] 피니언 요구 수명 (6000rpm * 60 * 5000h)

beta_extent = [15, 25];   % [deg] helix angle 범위
db_extent   = [0.8, 1.5]; % d/b (피치원지름/치폭) 범위 — 피니언·기어 모두 적용

SF_F_min      = 1.4;      % bending  안전계수 하한 (제약)
SF_H_min      = 1.1;      % contact  안전계수 하한 (제약)
eps_alpha_min = 1.2;      % 횡 접촉비 하한 (제약)

Np_max = 25;              % 외부 루프 피니언 잇수 상한 (작을수록 가벼움 -> 최적은 하한 근처)

% (참고) 아래 영향계수들은 현재 AGMA 라이브러리 내부에 하드코딩되어 있어
% K_o = 1.25;  K_B = 1;  Z_E = 191;  Z_R = 1;  S_t = 448;  S_c = 1551; 

%% ===================== 최적화 루프 =====================
beta_max = beta_extent(2); % 간섭회피에 대한 최소 피니언 잇수가 가장 작게 나오도록, 가장 큰 beta 기준으로 시작. 

% 잇수 하한: 가장 느슨한 beta(=30°)에서의 언더컷 미발생 최소잇수 (이보다 작으면 어떤 beta로도 불가)

N_min = gear.interference_free_p(alpha_n, beta_max, u1_extent(1));
% N_min이 기어비에 비례해서, 가장 작은 기어비에 대한 잇수부터 탐색하기 위한 목적으로 u1_extent(1) 기준으로 계산
Np_min = floor(max(N_min, 13)); % 간섭이 발생하지 않는 피니언의 최소잇수    

opts = optimoptions('fmincon', 'Display','off', 'Algorithm','sqp', ...
                    'ConstraintTolerance', 1e-6);
% fmincon 옵션 설정

R = struct('mn',{},'Np1',{},'Ng1',{},'u1',{},'Np2',{},'Ng2',{},'u2',{}, ...
           'Sigma',{},'beta',{},'dp1',{},'dg1',{},'b1',{},'dp2',{},'dg2',{},'b2',{},'a',{},'vol',{}, ...
           'SF1',{},'SH1',{},'SF2',{},'SH2',{},'eps1',{},'eps2',{});
% 결과 보고할 때 사용할 빈 구조체 배열. 최적화 루프에서 실현 가능한 설계가 나올 때마다 구조체로 변수들이 저장됨.


for m_n = m_n_lst
    for Np1 = Np_min : Np_max
        Ng1_lo = ceil( u1_extent(1) * Np1 );
        Ng1_hi = floor(u1_extent(2) * Np1 );
        for Ng1 = Ng1_lo : Ng1_hi
            u1    = Ng1 / Np1;
            Sigma = Np1 + Ng1;                       % 공유 잇수 합

            % 2단: 같은 Sigma 에서 u2 범위를 만족하는 Np2 후보
            Np2_lo = ceil( Sigma / (1 + u2_extent(2)) );
            Np2_hi = floor(Sigma / (1 + u2_extent(1)) );
            for Np2 = Np2_lo : Np2_hi
                Ng2 = Sigma - Np2;
                if Ng2 <= 0, continue; end
                u2 = Ng2 / Np2;
                if u2 < u2_extent(1) || u2 > u2_extent(2), continue; end

                % beta=30° 에서도 언더컷이면 어떤 beta로도 불가 -> 후보 제외
                if Np1 < gear.interference_free_p(alpha_n, beta_max, u1), continue; end
                if Np2 < gear.interference_free_p(alpha_n, beta_max, u2), continue; end

                % -------- 내부 최적화: x = [beta, db_ratio1, db_ratio2] --------
                x0 = [mean(beta_extent), mean(db_extent), mean(db_extent)];
                lb = [beta_extent(1),    db_extent(1),    db_extent(1)];
                ub = [beta_extent(2),    db_extent(2),    db_extent(2)];

                objf = @(x) volume_obj(x, m_n, Np1, Ng1, Np2, Ng2);
                conf = @(x) constr(x, m_n, Np1, Ng1, Np2, Ng2, ...
                                   alpha_n, n_in, T_in, N_cyc, ...
                                   SF_F_min, SF_H_min, eps_alpha_min);

                [xo, fo, flag] = fmincon(objf, x0, [],[],[],[], lb, ub, conf, opts);
                if flag <= 0, continue; end          % 수렴 실패

                cc = conf(xo);                        % 미세 위반 재확인
                if any(cc > 1e-4), continue; end

                % 결과 저장 (보고용 재계산 = eval_stage 재사용)
                s1 = eval_stage(m_n, xo(1), xo(2), Np1, Ng1, alpha_n, n_in, T_in, N_cyc);
                s2 = eval_stage(m_n, xo(1), xo(3), Np2, Ng2, alpha_n, n_in, T_in, N_cyc);
                a  = m_n * Sigma / (2*cosd(xo(1)));   % 두 단 공유 중심거리
                R(end+1) = struct('mn',m_n,'Np1',Np1,'Ng1',Ng1,'u1',u1, ...
                    'Np2',Np2,'Ng2',Ng2,'u2',u2,'Sigma',Sigma, ...
                    'beta',xo(1),'dp1',s1.dp,'dg1',s1.dg,'b1',s1.b,'dp2',s2.dp,'dg2',s2.dg,'b2',s2.b,'a',a,'vol',fo, ...
                    'SF1',min(s1.SFp,s1.SFg),'SH1',min(s1.SHp,s1.SHg), ...
                    'SF2',min(s2.SFp,s2.SFg),'SH2',min(s2.SHp,s2.SHg), ...
                    'eps1',s1.eps,'eps2',s2.eps); %#ok<SAGROW>
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
fprintf('%-5s %-4s %-4s %-4s %-4s %-7s %-7s %-7s %-7s %-7s %-7s %-7s %-7s %-6s %-6s %-6s %-6s %-10s\n', ...
    'm_n','Np1','Ng1','Np2','Ng2','beta','dp1','dg1','b1','dp2','dg2','b2','a','SF1','SH1','SF2','SH2','vol[mm^3]');
nshow = min(10, numel(R));
for k = 1:nshow
    r = R(k);
    fprintf('%-5.2f %-4d %-4d %-4d %-4d %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-7.2f %-6.2f %-6.2f %-6.2f %-6.2f %-10.3e\n', ...
        r.mn, r.Np1, r.Ng1, r.Np2, r.Ng2, r.beta, r.dp1, r.dg1, r.b1, r.dp2, r.dg2, r.b2, r.a, ...
        r.SF1, r.SH1, r.SF2, r.SH2, r.vol);
end

best = R(1);
fprintf('\n==== 최적 설계 ====\n');
fprintf('모듈  m_n   = %.2f mm\n', best.mn);
fprintf('헬릭스 beta = %.3f deg\n', best.beta);
fprintf('1단 : Np=%d, Ng=%d (u=%.3f), dp=%.2f mm, dg=%.2f mm, b=%.2f mm\n', best.Np1, best.Ng1, best.u1, best.dp1, best.dg1, best.b1);
fprintf('2단 : Np=%d, Ng=%d (u=%.3f), dp=%.2f mm, dg=%.2f mm, b=%.2f mm\n', best.Np2, best.Ng2, best.u2, best.dp2, best.dg2, best.b2);
fprintf('중심거리 a  = %.2f mm (두 단 공유)\n', best.a);
fprintf('안전계수 1단: SF_F=%.2f  SF_H=%.2f | 2단: SF_F=%.2f  SF_H=%.2f\n', ...
    best.SF1, best.SH1, best.SF2, best.SH2);
fprintf('접촉비   1단: %.3f | 2단: %.3f\n', best.eps1, best.eps2);
fprintf('블랭크 부피 = %.4e mm^3\n', best.vol);


%% ===================== 로컬 함수 (3개) =====================
function V = volume_obj(x, m_n, Np1, Ng1, Np2, Ng2)
    % 목적함수: 각 기어를 피치원에 대한 원통이라고 가정한 전체 기어 부피 합 ~ 무게와 가장 직결된다고 예상 (priority #1)
    % AGMA 강도 호출 없이 기하만 계산 (fmincon 목적함수 사용 목적)
    % db_ratio = d_p/b 제형으로 최적화하므로, b = dp/db_ratio 으로 치폭 계산
    beta = x(1);  c = cosd(beta);
    dp1 = m_n*Np1/c;  dg1 = m_n*Ng1/c;
    dp2 = m_n*Np2/c;  dg2 = m_n*Ng2/c;
    b1  = dp1/x(2);   b2  = dp2/x(3);
    V = (pi/4) * ( (dp1^2 + dg1^2)*b1 + (dp2^2 + dg2^2)*b2 );
end

function [c, ceq] = constr(x, m_n, Np1, Ng1, Np2, Ng2, ...
                           alpha_n, n_in, T_in, N_cyc, ...
                           SF_F_min, SF_H_min, eps_min)
    ceq = [];
    s1 = eval_stage(m_n, x(1), x(2), Np1, Ng1, alpha_n, n_in, T_in, N_cyc);
    s2 = eval_stage(m_n, x(1), x(3), Np2, Ng2, alpha_n, n_in, T_in, N_cyc);
    % g(x) <= 0  (d/b 범위는 피니언 기준: bounds lb/ub 로 처리, 기어는 미적용)
    c = [ SF_F_min - s1.SFp;  SF_F_min - s1.SFg;   % 1단 굽힘
          SF_H_min - s1.SHp;  SF_H_min - s1.SHg;   % 1단 접촉
          eps_min  - s1.eps;                         % 1단 접촉비
          s1.Nmin  - Np1;                            % 1단 언더컷 (beta 종속)
          SF_F_min - s2.SFp;  SF_F_min - s2.SFg;   % 2단 굽힘
          SF_H_min - s2.SHp;  SF_H_min - s2.SHg;   % 2단 접촉
          eps_min  - s2.eps;                         % 2단 접촉비
          s2.Nmin  - Np2 ];                          % 2단 언더컷
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

    Nmin = gear.interference_free_p(alpha_n, beta, Ng/Np);   % 연속값 (ceil 없음)

    s = struct('dp',dp,'dg',dg,'b',b,'SFp',SFp,'SFg',SFg, ...
               'SHp',SHp,'SHg',SHg,'eps',eps,'Nmin',Nmin);
end
