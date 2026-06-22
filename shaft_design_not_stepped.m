%% ========================================================================
%
% shaft_fmincon3_layout.m
% 상축/하축 직경 + 축방향 기어 위치(xG)를 함께 최적화.
% ------------------------------------------------------------------------
% 기존 shaft_fmincon2.m은 그대로 두고, 배치 최적화를 별도 파일로 분리.
%
% 설계변수:
%   x(1) = d_upper : 상축 중실 균일 외경 [mm]
%   x(2) = d_lower : 하축 중공 균일 외경 [mm]
%   x(3) = kd_lower: 하축 중공비, Di_lower = kd_lower*d_lower
%   x(4) = xG1     : 1단 기어 중심의 축방향 위치 [mm]
%   x(5) = xG2     : 2단 기어 중심의 축방향 위치 [mm]
%
% xG가 바뀌면 secL도 다음처럼 매번 재계산:
%   [좌저널, 1단기어폭, 중앙부, 2단기어폭, 우저널]
% =========================================================================
clear; clc;

fprintf('========== shaft_fmincon3_layout (diameter + xG optimization) ==========\n\n');

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
addpath(scriptDir);
if exist(fullfile(scriptDir,'.cache'),'dir')
    addpath(fullfile(scriptDir,'.cache'));
end

%% 1. 공통 입력 -----------------------------------------------------------
P_kW    = 50;
n_in    = 6000;
alpha_n = 20;
T_in = 9550*P_kW/n_in*1000;     % [N.mm]

mat = 'SCM440';
E   = 205e3;                    % [MPa]
G   = 80e3;                     % [MPa]
rho = 7850;                     % [kg/m^3]

SF_static_req   = 1.2;
SF_fatigue_req  = 1.0;
def_ratio_allow = 0.30;         % [mm/m]
crit_margin     = 1.25;
theta_allow_deg_per_m = 0.25;   % 하축 비틀림각 제약

pinion_bore_limit = 38.08;      % [mm] 상축 균일 외경 한계

%% 2. 기어 입력 ------------------------------------------------------

gear(1) = struct('name','Stage1','beta',15,'dp',53.58,'dg', 104.82,'b',35.72);
gear(2) = struct('name','Stage2','beta',15.684,'dp',62.32,'dg',96.08,'b',41.55);  %[1.3, 1.5]

%gear(1) = struct('name','Stage1','beta',15,'dp',53.58,'dg', 104.82,'b',33.48);
%gear(2) = struct('name','Stage2','beta',15.684,'dp',62.32,'dg',96.08,'b',38.95); %[1.5,1.6]


%gear(1) = struct('name','Stage1','beta',28.582,'dp',37.86,'dg', 73.74,'b',44.04);
%gear(2) = struct('name','Stage2','beta',28.582,'dp',45.84,'dg',65.75,'b',30.56);  

%gear(1) = struct('name','Stage1','beta',16,'dp',51.49,'dg', 100.13,'b',21.82);
%gear(2) = struct('name','Stage2','beta',16,'dp',60.08,'dg',91.55,'b',18.25);  

%gear(1) = struct('name','Stage1','beta',19.155,'dp',52.40,'dg',101.89,'b',20.96);
%gear(2) = struct('name','Stage2','beta',19.155,'dp',61.13,'dg',93.16,'b',17.47);


%gear(1) = struct('name','Stage1','beta',18.875,'dp',50.51,'dg',98.36,'b',22.48);
%gear(2) = struct('name','Stage2','beta',16.875,'dp',60.12,'dg',88.75,'b',18.22);


% gear(1) = struct('name','Stage1','beta',16.613,'dp',44.35,'dg',86.09,'b',29.92);
% gear(2) = struct('name','Stage2','beta',15.00,'dp',51.76,'dg',78.68,'b',32.76);


% gear(1) = struct('name','Stage1','beta',29.595,'dp',49.16,'dg',95.74,'b',23.02);
% gear(2) = struct('name','Stage2','beta',29.595,'dp',59.51,'dg',85.39,'b',18.03);

for k = 1:2
    [Wt, Wr, Wa] = shaft_load(T_in, gear(k).dp, alpha_n, gear(k).beta);
    gear(k).Wt = Wt;  gear(k).Wr = Wr;  gear(k).Wa = Wa;

    gear(k).T_upper = T_in;
    gear(k).T_lower = T_in * gear(k).dg / gear(k).dp;
    gear(k).n_lower = n_in * gear(k).dp / gear(k).dg;

    gear(k).C_upper = Wa * gear(k).dp / 2;
    gear(k).C_lower = Wa * gear(k).dg / 2;

    gear(k).mass_upper = rho*(pi/4*(gear(k).dp*1e-3)^2)*(gear(k).b*1e-3);
    gear(k).mass_lower = rho*(pi/4*(gear(k).dg*1e-3)^2)*(gear(k).b*1e-3);
end

%% 3. 배치 입력 -----------------------------------------------------------
b1 = gear(1).b;
b2 = gear(2).b;

brg_side_nom = 27;
brg_side_min = 27;              % 배치 최적화 중 허용할 최소 저널/베어링 여유
gap_gc = 5;
Lc1 = 28.4;  Lc2 = 29.3;  L_clutch = Lc1 + Lc2;
clutch_center_min = 60;         % 하축 가운데 클러치 최소 확보 길이
center_min = max(L_clutch + 2*gap_gc, clutch_center_min);

% 전체 베어링 스팬
L_span = brg_side_nom + b1 + center_min + b2 + brg_side_nom;

% 기존 배치에서 시작.
xG0 = [brg_side_nom + b1/2, ...
       brg_side_nom + b1 + center_min + b2/2];

secL0 = secL_from_xG(L_span, xG0, b1, b2);

fprintf('[Initial layout]\n');
fprintf('  L_span = %.2f mm\n', L_span);
fprintf('  xG0 = [%.2f, %.2f] mm\n', xG0(1), xG0(2));
fprintf('  secL0 = [%s] mm\n\n', num2str(secL0,'%.2f '));

%% 4. 최적화 --------------------------------------------------------------
% x = [d_upper, d_lower, kd_lower, xG1, xG2]
x0 = [28, 30, 0.6, xG0(1), xG0(2)];
lb = [18, 18, 0.5, b1/2 + brg_side_min, b1/2];
ub = [pinion_bore_limit, 70, 0.7, L_span - b1/2, L_span - b2/2 - brg_side_min];

obj = @(x) total_mass_objective(x, L_span, b1, b2, rho);
nonlcon = @(x) layout_constraints( ...
    x, L_span, b1, b2, brg_side_min, center_min, ...
    E, G, rho, gear, mat, ...
    SF_static_req, SF_fatigue_req, def_ratio_allow, crit_margin, ...
    theta_allow_deg_per_m, n_in);

opts = optimoptions('fmincon','Algorithm','sqp','Display','iter', ...
    'MaxFunctionEvaluations',5000, ...
    'OptimalityTolerance',1e-8,'ConstraintTolerance',1e-8);

[xopt, fval, exitflag, output] = fmincon( ...
    obj, x0, [], [], [], [], lb, ub, nonlcon, opts);

%% 5. 결과 출력 -----------------------------------------------------------
ev = evaluate_design(xopt, L_span, b1, b2, E, G, rho, gear, mat);
secL = secL_from_xG(L_span, ev.xG, b1, b2);
xStep = [0, cumsum(secL)];
xG = ev.xG;

Do_upper_fmincon = xopt(1)*ones(1,5);
Di_upper_fmincon = 0;
Do_lower_fmincon = xopt(2)*ones(1,5);
Di_lower_fmincon = xopt(3)*xopt(2);

layoutResult = struct();
layoutResult.xopt = xopt;
layoutResult.fval = fval;
layoutResult.exitflag = exitflag;
layoutResult.output = output;
layoutResult.xG = xG;
layoutResult.secL = secL;
layoutResult.xStep = xStep;
layoutResult.L_span = L_span;
layoutResult.gear = gear;
layoutResult.b1 = b1;
layoutResult.b2 = b2;
layoutResult.brg_side_nom = brg_side_nom;
layoutResult.brg_side_min = brg_side_min;
layoutResult.gap_gc = gap_gc;
layoutResult.Lc1 = Lc1;
layoutResult.Lc2 = Lc2;
layoutResult.L_clutch = L_clutch;
layoutResult.clutch_center_min = clutch_center_min;
layoutResult.center_min = center_min;
layoutResult.Do_upper_fmincon = Do_upper_fmincon;
layoutResult.Di_upper_fmincon = Di_upper_fmincon;
layoutResult.Do_lower_fmincon = Do_lower_fmincon;
layoutResult.Di_lower_fmincon = Di_lower_fmincon;
layoutResult.P_kW = P_kW;
layoutResult.n_in = n_in;
layoutResult.alpha_n = alpha_n;
layoutResult.T_in = T_in;
layoutResult.mat = mat;
layoutResult.E = E;
layoutResult.G = G;
layoutResult.rho = rho;
layoutResult.SF_static_req = SF_static_req;
layoutResult.SF_fatigue_req = SF_fatigue_req;
layoutResult.def_ratio_allow = def_ratio_allow;
layoutResult.crit_margin = crit_margin;
layoutResult.theta_allow_deg_per_m = theta_allow_deg_per_m;
layoutResult.pinion_bore_limit = pinion_bore_limit;

resultFile = fullfile(scriptDir, 'shaft_fmincon3_layout_result.mat');
save(resultFile, 'layoutResult');

fprintf('\n================ fmincon3_layout 결과 ================\n');
fprintf('xopt = [d_upper, d_lower, kd_lower, xG1, xG2]\n');
fprintf('     = [%s]\n', num2str(xopt,'%.4f '));
fprintf('objective mass = %.4f kg, exitflag = %d\n\n', fval, exitflag);
fprintf('saved result = %s\n\n', resultFile);

fprintf('[Optimized layout]\n');
fprintf('  xG = [%.2f, %.2f] mm\n', xG(1), xG(2));
fprintf('  gear edges = [%.2f, %.2f] / [%.2f, %.2f] mm\n', ...
    xStep(2), xStep(3), xStep(4), xStep(5));
fprintf('  secL = [%s] mm\n', num2str(secL,'%.2f '));
disp(array2table([(1:numel(secL)).', xStep(1:end-1).', xStep(2:end).', secL.'], ...
    'VariableNames', {'section','x_start_mm','x_end_mm','L_mm'}));

fprintf('\n[Upper shaft]\n');
print_eval(ev.upper, SF_static_req, SF_fatigue_req, def_ratio_allow, ...
    crit_margin, n_in, false, theta_allow_deg_per_m);

fprintf('\n[Lower shaft]\n');
print_eval(ev.lower, SF_static_req, SF_fatigue_req, def_ratio_allow, ...
    crit_margin, max([gear.n_lower]), true, theta_allow_deg_per_m);

%% ========================================================================
% Local functions
% =========================================================================

function secL = secL_from_xG(L, xG, b1, b2)
    xG = xG(:).';
    xStep = [0, xG(1)-b1/2, xG(1)+b1/2, xG(2)-b2/2, xG(2)+b2/2, L];
    secL = diff(xStep);
end

function mass = total_mass_objective(x, L, b1, b2, rho)
    xG = x(4:5);
    xG = xG(:).';
    secL = secL_from_xG(L, xG, b1, b2);
    dU = x(1);
    dL = x(2);
    kd = x(3);
    DoU = dU*ones(1,5);  DiU = 0;
    DoL = dL*ones(1,5);  DiL = kd*dL;
    mass = shaft_mass(DoU, DiU, secL, rho) + shaft_mass(DoL, DiL, secL, rho);
end

function mass = shaft_mass(Do, Di, secL, rho)
    A = pi/4*(Do.^2 - Di^2);
    mass = rho * sum(A .* secL) * 1e-9;
end

function [c, ceq] = layout_constraints( ...
    x, L, b1, b2, brg_min, center_min, ...
    E, G, rho, gear, mat, ...
    SFs_req, SFf_req, def_allow, crit_margin, theta_allow, n_upper)

    ev = evaluate_design(x, L, b1, b2, E, G, rho, gear, mat);
    secL = ev.secL;

    c = [];
    % 배치 제약
    c(end+1) = brg_min - secL(1);
    c(end+1) = center_min - secL(3);
    c(end+1) = brg_min - secL(5);

    % 상축: 비틀림각은 참고만, 피니언 외경은 ub로 제한
    c = append_strength_constraints(c, ev.upper, SFs_req, SFf_req, ...
        def_allow, crit_margin, n_upper, false, theta_allow);

    % 하축: 기존 중공축처럼 비틀림각 포함
    c = append_strength_constraints(c, ev.lower, SFs_req, SFf_req, ...
        def_allow, crit_margin, max([gear.n_lower]), true, theta_allow);

    ceq = [];
end

function c = append_strength_constraints(c, ev, SFs_req, SFf_req, ...
        def_allow, crit_margin, n_oper, use_torsion, theta_allow)
    c(end+1) = SFs_req - ev.SF_static_min;
    c(end+1) = SFf_req - ev.SF_fatigue_min;
    c(end+1) = ev.def_ratio_max - def_allow;
    c(end+1) = crit_margin*n_oper - ev.Nc;
    if use_torsion
        c(end+1) = ev.theta_per_m_max - theta_allow;
    end
end

function ev = evaluate_design(x, L, b1, b2, E, G, rho, gear, mat)
    dU = x(1);
    dL = x(2);
    kd = x(3);
    xG = x(4:5);
    xG = xG(:).';
    secL = secL_from_xG(L, xG, b1, b2);

    ev = struct();
    ev.xG = xG;
    ev.secL = secL;
    ev.upper = evaluate_one_shaft( ...
        L, xG, secL, E, G, rho, gear, mat, ...
        dU*ones(1,5), 0, 'T_upper', 'C_upper', 'mass_upper');
    ev.lower = evaluate_one_shaft( ...
        L, xG, secL, E, G, rho, gear, mat, ...
        dL*ones(1,5), kd*dL, 'T_lower', 'C_lower', 'mass_lower');
end

function ev = evaluate_one_shaft( ...
        L, xG, secL, E, G, rho, gear, mat, Do, Di, Tfield, Cfield, massfield)
    nStage = numel(gear);
    def_ratio = zeros(1,nStage);
    SFs = zeros(1,nStage);
    SFf = zeros(1,nStage);
    theta_pm = zeros(1,nStage);

    for k = 1:nStage
        g = gear(k);
        Cmag = g.(Cfield);
        T = g.(Tfield);

        [dmax, ~, ~, xs] = bending_deflection( ...
            L, xG(k), g.Wt, g.Wr, Cmag, Do, Di, secL, E);
        def_ratio(k) = dmax/(L/1000);

        Mx = resultant_moment_curve(L, xs, xG(k), g.Wt, g.Wr, Cmag);
        [SFs(k), SFf(k)] = shaft_stress(Mx, T, Do, Di, secL, xs, mat);

        [~, theta_pm(k)] = torsion_angle(T, Do, Di, secL, G);
    end

    gm = [gear.(massfield)];
    [Nc, cdet] = critical_speed(L, Do, Di, secL, E, rho, gm, xG);

    ev = struct();
    ev.Do = Do;
    ev.Di = Di;
    ev.mass_kg = shaft_mass(Do, Di, secL, rho);
    ev.SF_static_stage = SFs;
    ev.SF_static_min = min(SFs);
    ev.SF_fatigue_stage = SFf;
    ev.SF_fatigue_min = min(SFf);
    ev.def_ratio_stage = def_ratio;
    ev.def_ratio_max = max(def_ratio);
    ev.theta_per_m_stage = theta_pm;
    ev.theta_per_m_max = max(theta_pm);
    ev.Nc = Nc;
    ev.critical_detail = cdet;
end

function Mres = resultant_moment_curve(L, xs, a, Ft, Fr, Cmag)
    Mt   = beam_moment_for_eval(Ft, a, L, 0, xs);
    Mr_p = beam_moment_for_eval(Fr, a, L,  Cmag, xs);
    Mr_n = beam_moment_for_eval(Fr, a, L, -Cmag, xs);
    Mres = max(sqrt(Mt.^2 + Mr_p.^2), sqrt(Mt.^2 + Mr_n.^2));
end

function M = beam_moment_for_eval(F, a, L, C, xs)
    RB = (F*a + C)/L;
    RA = F - RB;
    M = zeros(size(xs));
    left = xs < a;
    right = ~left;
    M(left) = RA*xs(left);
    M(right) = RA*xs(right) - F*(xs(right)-a) + C;
end

function print_eval(ev, SFs_req, SFf_req, def_allow, crit_margin, n_oper, use_torsion, theta_allow)
    theta_display = trunc2(ev.theta_per_m_max);
    fprintf('  Do = [%s] mm, Di = %.2f mm\n', num2str(ev.Do,'%.2f '), ev.Di);
    fprintf('  mass = %.4f kg\n', ev.mass_kg);
    fprintf('  SF_static = %.3f (req %.2f)\n', ev.SF_static_min, SFs_req);
    fprintf('  SF_fatigue = %.3f (req %.2f)\n', ev.SF_fatigue_min, SFf_req);
    fprintf('  def ratio = %.3f mm/m (allow %.2f)\n', ev.def_ratio_max, def_allow);
    if use_torsion
        fprintf('  theta = %.2f deg/m (allow %.2f)\n', theta_display, theta_allow);
    else
        fprintf('  theta = %.2f deg/m (reference only)\n', theta_display);
    end
    fprintf('  Nc = %.0f rpm (req %.0f rpm)\n', ev.Nc, crit_margin*n_oper);
end

function y = trunc2(x)
    y = floor(x*100)/100;
end
