%% =====================================================================
%  UTV 변속기 습식 다판 클러치 최적 설계  v2
%  ---------------------------------------------------------------------
%  v1 대비 추가/개선 (프로젝트 사양서 요구사항 반영)
%   (1) 열 검증     : 슬립속도 V<=Vmax,  열유속 q'' <= q_allow
%   (2) 다목적화    : Cost = w1*질량 + w2*부피 + w3*효율(드래그손실)
%                     -> Priority#1 무게, #2 부피, + High efficiency
%   (3) 마모 수명   : 마찰판 두께 = 구조최소 + 마모여유(B10 5,000h 듀티에서 역산)
%  ---------------------------------------------------------------------
%  방법 : MINLP 실용적 접근 (정수 nf -> 반복문, 연속변수 -> fmincon/SQP)
%  강도 : 균일 마모(uniform wear)
%  * *표시 파라미터는 가정값 -> 실제 관성/듀티/마모 데이터로 교체할 것
% =====================================================================
clear; clc; close all;

%% ===== 1. 설계 입력 =================================================
P  = 50e3;  N1 = 3000;  N2 = 4000;        % 동력[W], 1/2단 출력회전수[rpm]
T1_req = P/(2*pi*N1/60);                   % ~159.2 Nm (최대 -> 지배)
T2_req = P/(2*pi*N2/60);                   % ~119.4 Nm
SF = 1.4;
T1_design = T1_req*SF;  T2_design = T2_req*SF;

fprintf('요구토크 T1=%.1f T2=%.1f | 설계토크 T1=%.1f T2=%.1f Nm\n\n', ...
        T1_req,T2_req,T1_design,T2_design);

%% ===== 2. 재료 / 마찰 ==============================================
prm.d_inner = 24e-3;  prm.ri = prm.d_inner/2;   % 클러치 내경(하축)  *Thu 확정
prm.f       = 0.06;        % 마찰계수 (sintered wet, 보수적 하한)
prm.p_max   = 3.4e6;       % 허용 접촉압력 [Pa]
prm.etaA    = 1.00;        % 유효 마찰면적 계수 (오일홈 고려 시 0.8 권장)
prm.rho_f   = 7200;        % 마찰판(소결) 밀도
prm.rho_s   = 7850;        % 분리/쿠션/반력판(강) 밀도

%% ===== 3. 듀티 / 열 / 마모 (*가정값) ===============================
prm.dN    = abs(N1-N2);                 % 변속 슬립 미스매치 [rpm] (=1000)
prm.dw    = 2*pi*prm.dN/60;             % 슬립 각속도 [rad/s]
prm.Jeq   = 0.05;        % * 클러치 환산 등가관성 [kg.m^2]
prm.z_hr  = 30;          % * 시간당 변속(체결) 횟수 [1/h]
prm.life  = 5000;        % B10 수명 [h]
prm.E_slip= 0.5*prm.Jeq*prm.dw^2;             % 1회 체결당 슬립에너지 [J]
prm.E_tot = prm.E_slip*prm.z_hr*prm.life;     % 수명 총 슬립에너지 [J]

prm.Vmax    = 18.0;      % 허용 슬립속도 [m/s] (sintered wet 표값)
prm.q_allow = 1.0e6;     % * 허용 평균 열유속 [W/m^2]
prm.w_s     = 5e-13;     % * 비마모율 (마모부피/에너지) [m^3/J]
prm.tf_str  = 1.2e-3;    % 마찰판 구조/취급 최소두께 [m] (마모여유는 별도 가산)

prm.mu    = 0.03;        % * 윤활유 점도 [Pa.s] (드래그 계산용)
prm.h_gap = 0.3e-3;      % * 개방 시 판 간극 [m]

%% ===== 4. 변수 범위 / 다목적 가중치 ================================
prm.nf_min=2; prm.nf_max=10;
prm.ro_max=60e-3; prm.delta_min=5e-3; prm.Lmax=60e-3;
% 두께 하한/상한 [m] : [마찰 분리 쿠션 반력]  (마찰 하한은 구조최소, 마모는 제약으로 가산)
prm.t_lb=[prm.tf_str, 1.2e-3, 1.0e-3, 2.0e-3];
prm.t_ub=[5e-3,5e-3,5e-3,5e-3];

% Cost = w1*질량/m_ref + w2*부피/v_ref + w3*드래그/P_ref  (정규화로 가중치 비교 가능)
prm.w  = [0.5, 0.3, 0.2];          % [무게, 부피, 효율]
prm.ref= [1.0, 1.5e-4, 30.0];      % [kg, m^3, W] 정규화 기준

%% ===== 5. 최적화 실행 ==============================================
fprintf('>> Stage 1 최적화...\n');  S1 = designClutch(T1_design, prm);
fprintf('>> Stage 2 최적화...\n');  S2 = designClutch(T2_design, prm);

%% ===== 6. 결과 ====================================================
printResult('Stage 1', S1, T1_req, prm);
printResult('Stage 2', S2, T2_req, prm);

mt=S1.mass+S2.mass;  vt=S1.vol+S2.vol;
fprintf('\n==================================================\n');
fprintf(' 총 질량 = %.3f kg | 총 부피 = %.0f cm^3\n', mt, vt*1e6);
fprintf(' 개방 드래그(작동 중 한쪽만): 최대 %.0f W (= 동력의 %.2f%%)\n', ...
        max(S1.drag,S2.drag), max(S1.drag,S2.drag)/P*100);
fprintf('==================================================\n');


% =====================================================================
%  LOCAL FUNCTIONS
% =====================================================================
function R = designClutch(T_des, prm)
% nf 반복(loop) + 각 nf 에서 fmincon(SQP) 로 Cost 최소화
    ri=prm.ri;  best.cost=inf;
    opts=optimoptions('fmincon','Algorithm','sqp','Display','off', ...
                      'MaxFunctionEvaluations',3000);
    for nf=prm.nf_min:prm.nf_max
        cnt=[nf, nf-1, 1, 1];
        % 토크 제약을 만족하는 해석적 최소 ro (좋은 초기값 & 타당성 게이트)
        ro_need=sqrt( T_des/(prm.etaA*2*nf*prm.f*pi*prm.p_max*ri) + ri^2 );
        if ro_need>prm.ro_max, continue; end          % 이 nf로는 토크 불가능

        lb=[ri+prm.delta_min, prm.t_lb];
        ub=[prm.ro_max,       prm.t_ub];
        % 선형: (1) 팩 길이  (2) 최소 접촉폭
        A=[0, nf, nf-1, 1, 1;  -1,0,0,0,0];
        b=[prm.Lmax;  -(ri+prm.delta_min)];
        x0=[min(ro_need*1.002,prm.ro_max), ...
            prm.tf_str+dwear(nf,ro_need,prm)+1e-4, prm.t_lb(2:4)];

        obj=@(x) clutchCost(x,cnt,prm);
        non=@(x) clutchCon(x,nf,prm,T_des);
        [x,fval,ef]=fmincon(obj,x0,A,b,[],[],lb,ub,non,opts);

        % fmincon 이 라인서치에서 멈추면(ef<=0) 해석적 binding 점으로 대체
        if ef<=0 || ~isFeasible(x,nf,prm,T_des)
            xa=[ro_need, prm.tf_str+dwear(nf,ro_need,prm), prm.t_lb(2:4)];
            if isFeasible(xa,nf,prm,T_des), x=xa; fval=clutchCost(xa,cnt,prm); else, continue; end
        end
        if fval<best.cost
            best.cost=fval; best.x=x; best.nf=nf; best.cnt=cnt;
        end
    end
    if ~isfield(best,'x'), error('가능한 해 없음: ro_max/nf 범위 확인'); end
    % 결과 지표 사전 계산
    ro=best.x(1);
    best.mass=clutchMass(best.x,best.cnt,prm);
    best.vol =clutchVol(best.x,best.cnt,prm);
    best.drag=Pdrag(best.nf,ro,prm);
    R=best;
end

% ---- 목적함수(다목적) ----
function J = clutchCost(x,cnt,prm)
    m=clutchMass(x,cnt,prm);  v=clutchVol(x,cnt,prm);  d=Pdrag(cnt(1),x(1),prm);
    J = prm.w(1)*m/prm.ref(1) + prm.w(2)*v/prm.ref(2) + prm.w(3)*d/prm.ref(3);
end

% ---- 비선형 제약 (c<=0) : 토크 / 슬립속도 / 열유속 / 마모여유 ----
function [c,ceq]=clutchCon(x,nf,prm,T_des)
    ro=x(1); tf=x(2);
    c=[ T_des            - Tcap(nf,ro,prm);                 % 토크용량 >= 설계
        prm.dw*ro        - prm.Vmax;                        % 슬립속도 <= Vmax
        heatflux(nf,ro,prm) - prm.q_allow;                  % 열유속 <= q_allow
       (prm.tf_str + dwear(nf,ro,prm)) - tf ];              % 마찰두께 >= 구조+마모
    ceq=[];
end

function tf_ok = isFeasible(x,nf,prm,T_des)
    [c,~]=clutchCon(x,nf,prm,T_des);
    lin = (x(1)-prm.ri>=prm.delta_min-1e-9) && ...
          (nf*x(2)+(nf-1)*x(3)+x(4)+x(5) <= prm.Lmax+1e-9);
    tf_ok = all(c<=1e-6) && lin;
end

% ---- 물리 헬퍼 ----
function T=Tcap(nf,ro,prm)        % 균일마모 토크용량
    T=prm.etaA*(2*nf)*prm.f*pi*prm.p_max*prm.ri*(ro^2-prm.ri^2);
end
function A=Afric(nf,ro,prm)       % 총 마찰면적
    A=(2*nf)*pi*(ro^2-prm.ri^2)*prm.etaA;
end
function d=dwear(nf,ro,prm)       % 수명 마모 깊이(여유)
    d=prm.w_s*prm.E_tot/Afric(nf,ro,prm);
end
function q=heatflux(nf,ro,prm)    % 평균 열유속
    q=prm.E_slip*(prm.z_hr/3600)/Afric(nf,ro,prm);
end
function Pd=Pdrag(nf,ro,prm)      % 개방 시 점성 드래그 손실
    Pd=(2*nf)*pi*prm.mu*prm.dw^2*(ro^4-prm.ri^4)/(2*prm.h_gap);
end
function m=clutchMass(x,cnt,prm)
    ro=x(1); A=pi*(ro^2-prm.ri^2);
    m=A*( cnt(1)*x(2)*prm.rho_f + (cnt(2)*x(3)+cnt(3)*x(4)+cnt(4)*x(5))*prm.rho_s );
end
function v=clutchVol(x,cnt,prm)   % 외형(엔벨로프) 부피
    L=cnt(1)*x(2)+cnt(2)*x(3)+cnt(3)*x(4)+cnt(4)*x(5);
    v=pi*x(1)^2*L;
end

% ---- 결과 출력 ----
function printResult(name,S,T_req,prm)
    ro=S.x(1); tf=S.x(2); ts=S.x(3); tc=S.x(4); tr=S.x(5); nf=S.nf; ri=prm.ri;
    Tc=Tcap(nf,ro,prm); V=prm.dw*ro; q=heatflux(nf,ro,prm);
    dwr=dwear(nf,ro,prm); L=nf*tf+(nf-1)*ts+tc+tr;
    fprintf('\n=============== %s ===============\n',name);
    fprintf(' 판수 : 마찰 %d / 분리 %d / 쿠션 1 / 반력 1\n',nf,nf-1);
    fprintf(' 직경 : ID=%.0f mm, OD=%.1f mm (접촉폭 %.1f mm)\n',2*ri*1e3,2*ro*1e3,(ro-ri)*1e3);
    fprintf(' 두께 : 마찰 %.2f mm (구조 %.1f + 마모 %.2f) / 분리 %.1f / 쿠션 %.1f / 반력 %.1f\n', ...
            tf*1e3,prm.tf_str*1e3,dwr*1e3,ts*1e3,tc*1e3,tr*1e3);
    fprintf(' [강도] 토크용량 %.0f Nm  (요구 %.0f 대비 +%.0f%%)\n',Tc,T_req,(Tc/T_req-1)*100);
    fprintf(' [열]   슬립속도 %.1f m/s (<%.0f) | 열유속 %.0f W/m^2 (<%.0e)\n',V,prm.Vmax,q,prm.q_allow);
    fprintf(' [효율] 개방 드래그 %.0f W\n',Pdrag(nf,ro,prm));
    fprintf(' [부피] 팩 길이 %.1f mm | 엔벨로프 %.0f cm^3\n',L*1e3,clutchVol(S.x,S.cnt,prm)*1e6);
    fprintf(' [무게] %.3f kg\n',S.mass);
end
