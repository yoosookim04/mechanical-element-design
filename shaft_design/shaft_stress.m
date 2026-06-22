function [SF_static, SF_fatigue, detail] = shaft_stress(Mx, Tx, Do, Di, secL, xs, mat, Kf, Kfs)
%% ========================================================================
%  shaft_stress.m 
%   "축 설계 제약조건" 식:
%    sigma_b_nom = M*(do/2)/I ;  tau_t_nom = T*(do/2)/J
%    sigma_b = kf*sigma_b_nom ;  tau_t = kfs*tau_t_nom
%    sigma_a = sigma_b/2 ;       sigma_m = sigma_b/2   (양진 굽힘 가정)
%    n_static_inv  = sqrt(sigma_b^2 + 3*tau_t^2)/Sy   -> SF_static  = 1/inv
%    n_fatigue_inv = sigma_a/Se + sigma_m/Sut         -> SF_fatigue = 1/inv
%  물성: Table2 (SCM440: Sy=846, Sut=1050)
%  변단면 전구간 스캔 -> 최소 SF 반환
% =========================================================================
if nargin < 8 || isempty(Kf),  Kf  = 1.0; end
if nargin < 9 || isempty(Kfs), Kfs = 1.0; end

% ----- 재료 물성 [MPa] : Table2 (KS) 기준 -----
switch upper(mat)
    case 'SCM440'    %  Sy=846, tau_y=440, Sut=1050
        Sy=846;  Sut=1050;
    case 'SNCM439'   
        Sy=950;  Sut=1050;
    case 'SNCM630'
        Sy=951;  Sut=1100;
    case 'SM45C'
        Sy=490;  Sut=686;
    otherwise
        error('지원 재료(Table2): SCM440/SNCM439/SNCM630/SM45C (입력=%s)', mat);
end
Se = 0.5*Sut;   % 피로한도 1차근사

N = numel(xs);
if isscalar(Tx), Tx = Tx*ones(1,N); end

edges = [0, cumsum(secL)];
SFs_all = inf(1,N);  SFf_all = inf(1,N);
sb_all = zeros(1,N); tt_all = zeros(1,N);

for i = 1:N
    idx = find(xs(i) >= edges(1:end-1) & xs(i) <= edges(2:end), 1);
    if isempty(idx), idx = numel(Do); end
    d = Do(idx);
    I = pi/64*(d^4 - Di^4);
    J = pi/32*(d^4 - Di^4);
    c = d/2;

    sigma_b_nom = Mx(i)*c/I;
    tau_t_nom   = Tx(i)*c/J;
    sigma_b = Kf *sigma_b_nom;
    tau_t   = Kfs*tau_t_nom;
    sb_all(i)=sigma_b; tt_all(i)=tau_t;

    % --- von Mises ---
    n_static_inv = sqrt(sigma_b^2 + 3*tau_t^2) / Sy;
    SFs_all(i)   = 1 / max(n_static_inv, eps);

    % --- 양진굽힘 sigma_a=sigma_m=sigma_b/2 ---
    sigma_a = abs(sigma_b)/2;
    sigma_m = abs(sigma_b)/2;
    n_fatigue_inv = sigma_a/Se + sigma_m/Sut;
    SFf_all(i)    = 1 / max(n_fatigue_inv, eps);
end

[SF_static, is] = min(SFs_all);
[SF_fatigue, ~] = min(SFf_all);

detail = struct('mat',mat,'Sy',Sy,'Sut',Sut,'Se',Se, ...
    'x_crit',xs(is),'sigma_b_crit',sb_all(is), ...
    'tau_crit',tt_all(is),'SFs_curve',SFs_all);
end