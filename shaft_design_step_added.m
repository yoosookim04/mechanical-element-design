%% ========================================================================
% verify_stepped_shaft3_layout.m
% shaft_fmincon3_layout.m 저장 결과 기반 단차축 검증
% ------------------------------------------------------------------------
% 기존 verify_stepped_shaft.m은 그대로 둔다.
% 이 파일은 shaft_fmincon3_layout.m이 저장한
%   shaft_fmincon3_layout_result.mat
% 을 불러와 xG, secL, 기어값, 스팬을 그대로 사용하고,
% 아래 입력부의 최종 단차축 Do/Di를 검증한다.
%
% 배치:
%   xG1, xG2는 축방향 기어 중심 위치이다.
%   secL = [좌저널, 1단 기어폭, 중앙부, 2단 기어폭, 우저널]
% =========================================================================
clear; clc;

fprintf('================ verify stepped shaft 3: layout optimized ================\n\n');

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
addpath(scriptDir);
if exist(fullfile(scriptDir,'.cache'),'dir')
    addpath(fullfile(scriptDir,'.cache'));
end

%% 1. 저장된 배치 최적화 결과 불러오기 ------------------------------------
resultFile = fullfile(scriptDir, 'shaft_fmincon3_layout_result.mat');
if ~exist(resultFile, 'file')
    error(['shaft_fmincon3_layout_result.mat 파일이 없습니다.\n', ...
           '먼저 shaft_fmincon3_layout.m을 실행해서 최적화 결과를 저장하세요.']);
end

S = load(resultFile, 'layoutResult');
layoutResult = S.layoutResult;

P_kW = layoutResult.P_kW;
n_in = layoutResult.n_in;
alpha_n = layoutResult.alpha_n;
T_in = layoutResult.T_in;

mat = layoutResult.mat;
E = layoutResult.E;
G = layoutResult.G;
rho = layoutResult.rho;

SF_static_req = layoutResult.SF_static_req;
SF_fatigue_req = layoutResult.SF_fatigue_req;
def_ratio_allow = layoutResult.def_ratio_allow;
crit_margin = layoutResult.crit_margin;
theta_allow_deg_per_m = layoutResult.theta_allow_deg_per_m;
pinion_bore_limit = layoutResult.pinion_bore_limit;
gear_sections = [2 4];          % section 2: 1단 기어, section 4: 2단 기어

%% 2. 최적화 결과 배치/기어값 ---------------------------------------------
xopt = layoutResult.xopt;
fval = layoutResult.fval;
exitflag = layoutResult.exitflag;
output = layoutResult.output;

gear = layoutResult.gear;
b1 = layoutResult.b1;
b2 = layoutResult.b2;
brg_side_nom = layoutResult.brg_side_nom;
brg_side_min = layoutResult.brg_side_min;
gap_gc = layoutResult.gap_gc;
Lc1 = layoutResult.Lc1;
Lc2 = layoutResult.Lc2;
L_clutch = layoutResult.L_clutch;
center_min = layoutResult.center_min;
brg_side_req = 27;              % [mm], section 1/5 최소 베어링 여유
clutch_center_min = 58;         % [mm], section 3 최소 클러치 공간
if isfield(layoutResult, 'clutch_center_min')
    clutch_center_min = layoutResult.clutch_center_min;
end

L_span = layoutResult.L_span;
xG = layoutResult.xG;
secL = layoutResult.secL;
xStep = layoutResult.xStep;

Do_upper_fmincon = layoutResult.Do_upper_fmincon;
Di_upper_fmincon = layoutResult.Di_upper_fmincon;
Do_lower_fmincon = layoutResult.Do_lower_fmincon;
Di_lower_fmincon = layoutResult.Di_lower_fmincon;

fprintf('[Loaded saved layout result]\n');
fprintf('  file = %s\n', resultFile);
fprintf('  L_span = %.2f mm\n', L_span);
fprintf('  xG = [%.2f, %.2f] mm\n', xG(1), xG(2));
fprintf('  secL = [%s] mm\n\n', num2str(secL,'%.2f '));
fprintf('  section 2 = Stage1 gear width %.2f mm\n', b1);
fprintf('  section 3 = clutch/center space, minimum %.2f mm\n', center_min);
fprintf('  section 4 = Stage2 gear width %.2f mm\n\n', b2);

okLayoutBearing = secL(1) >= brg_side_req && secL(5) >= brg_side_req;
okLayoutClutch = secL(3) >= clutch_center_min;
okLayout = okLayoutBearing && okLayoutClutch;

%% 3. 최종 단차축 입력 ----------------------------------------------------
% 저장 결과는 xG 배치와 참고용 균일축 직경을 제공한다.
% 실제 검증할 최종 단차축 치수는 아래에 직접 입력한다.
%
% section 1 = 좌측 저널
% section 2 = 1단 기어 삽입부
% section 3 = 중앙/클러치부
% section 4 = 2단 기어 삽입부
% section 5 = 우측 저널
%
% 상축 피니언/기어 끼움 조건은 section 2, 4 직경으로 검사한다.
Do_upper = [35 38.08 47.2 38.08 35];    % [mm] 상축 중실 단차 외경
Di_upper = 0;                           % [mm] 중실축

Do_lower = [45 50 57 50 45];            % [mm] 하축 기존 중공 단차 외경
Di_lower = 35;                          % [mm] 하축 기존 중공 내경

if numel(Do_upper) ~= numel(secL) || numel(Do_lower) ~= numel(secL)
    error('Do_upper/Do_lower는 secL과 같은 5개 구간 값을 가져야 합니다.');
end

shaft(1) = struct('name','상축 solid stepped', ...
                  'Do',Do_upper, 'Di',Di_upper, ...
                  'Tfield','T_upper', 'Cfield','C_upper', ...
                  'massfield','mass_upper', 'n_oper',n_in, ...
                  'use_torsion_constraint',true);

shaft(2) = struct('name','하축 hollow stepped', ...
                  'Do',Do_lower, 'Di',Di_lower, ...
                  'Tfield','T_lower', 'Cfield','C_lower', ...
                  'massfield','mass_lower', 'n_oper',max([gear.n_lower]), ...
                  'use_torsion_constraint',true);

%% 6. 최적화 결과 및 레이아웃 출력 ----------------------------------------
fprintf('\n================ optimized design ================\n');
fprintf('xopt = [d_upper, d_lower, kd_lower, xG1, xG2]\n');
fprintf('     = [%s]\n', num2str(xopt,'%.4f '));
fprintf('objective mass = %.4f kg, exitflag = %d\n', fval, exitflag);
fprintf('iterations = %d, funcCount = %d\n\n', output.iterations, output.funcCount);
fprintf('loaded reference uniform shafts:\n');
fprintf('  upper Do = [%s] mm, Di = %.2f mm\n', ...
    num2str(Do_upper_fmincon,'%.2f '), Di_upper_fmincon);
fprintf('  lower Do = [%s] mm, Di = %.2f mm\n\n', ...
    num2str(Do_lower_fmincon,'%.2f '), Di_lower_fmincon);

fprintf('[Final stepped shaft input used for verification]\n');
fprintf('  upper Do = [%s] mm, Di = %.2f mm\n', num2str(Do_upper,'%.2f '), Di_upper);
fprintf('  lower Do = [%s] mm, Di = %.2f mm\n\n', num2str(Do_lower,'%.2f '), Di_lower);

fprintf('[Optimized layout]\n');
fprintf('  L_span = %.2f mm\n', L_span);
fprintf('  xG = [%.2f, %.2f] mm\n', xG(1), xG(2));
fprintf('  gear edges = [%.2f, %.2f] / [%.2f, %.2f] mm\n', ...
    xStep(2), xStep(3), xStep(4), xStep(5));
fprintf('  secL = [%s] mm\n', num2str(secL,'%.2f '));
sectionTbl = array2table([(1:numel(secL)).', xStep(1:end-1).', xStep(2:end).', secL.'], ...
    'VariableNames', {'section','x_start_mm','x_end_mm','L_mm'});
disp(sectionTbl);
fprintf('  Gear section length check: section2=%.2f mm, section4=%.2f mm [%s]\n', ...
    secL(gear_sections(1)), secL(gear_sections(2)), ...
    passfail(abs(secL(gear_sections(1))-b1) < 1e-6 && abs(secL(gear_sections(2))-b2) < 1e-6));
fprintf('  Bearing-side length check: section1=%.2f mm, section5=%.2f mm >= %.2f mm [%s]\n', ...
    secL(1), secL(5), brg_side_req, passfail(okLayoutBearing));
fprintf('  Clutch center length check: section3=%.2f mm >= %.2f mm [%s]\n', ...
    secL(3), clutch_center_min, passfail(okLayoutClutch));
fprintf('\n');

fprintf('[Gear loads]\n');
for k = 1:2
    fprintf('  %s: Wt=%.0f N, Wr=%.0f N, Fa=%.0f N, T_lower=%.1f N.m, n_lower=%.0f rpm\n', ...
        gear(k).name, gear(k).Wt, gear(k).Wr, gear(k).Wa, ...
        gear(k).T_lower/1000, gear(k).n_lower);
end
fprintf('\n');

%% 7. 최종 검증 -----------------------------------------------------------
summaryRows = [];

for s = 1:numel(shaft)
    sh = shaft(s);
    ev = evaluate_stepped_shaft(L_span, xG, secL, E, G, rho, gear, sh, mat);
    mass_kg = stepped_shaft_mass(sh.Do, sh.Di, secL, rho);

    okSF  = ev.SF_static_min >= SF_static_req;
    okFat = ev.SF_fatigue_min >= SF_fatigue_req;
    okDef = ev.def_ratio_max <= def_ratio_allow;
    okNc  = ev.Nc >= crit_margin*sh.n_oper;
    theta_max_display = trunc2(ev.theta_per_m_max);
    okTheta = true;
    if sh.use_torsion_constraint
        okTheta = theta_max_display <= theta_allow_deg_per_m;
    end
    okFit = true;
    if s == 1
        okFit = max(sh.Do(gear_sections)) <= pinion_bore_limit;
    end

    fprintf('================ %s 검증 ================\n', sh.name);
    fprintf('  Do = [%s] mm, Di = %.2f mm\n', num2str(sh.Do,'%.2f '), sh.Di);
    fprintf('  구간별 치수/길이:\n');
    shaftSectionTbl = array2table([(1:numel(secL)).', xStep(1:end-1).', xStep(2:end).', secL.', sh.Do(:)], ...
        'VariableNames', {'section','x_start_mm','x_end_mm','L_mm','Do_mm'});
    disp(shaftSectionTbl);
    if s == 1
        fprintf('  Pinion fit check: %s  (gear-section Do = [%.2f %.2f] mm <= %.2f mm)\n', ...
            passfail_word(okFit), sh.Do(gear_sections(1)), sh.Do(gear_sections(2)), pinion_bore_limit);
    end
    fprintf('  mass = %.4f kg\n', mass_kg);
    fprintf('  min static SF = %.3f  [%s]\n', ev.SF_static_min, passfail(okSF));
    fprintf('  min fatigue SF = %.3f  [%s]\n', ev.SF_fatigue_min, passfail(okFat));
    fprintf('  max delta/L = %.3f mm/m  (allow %.2f) [%s]\n', ...
        ev.def_ratio_max, def_ratio_allow, passfail(okDef));
    if sh.use_torsion_constraint
        fprintf('  max theta/L = %.2f deg/m  (allow %.2f) [%s]\n', ...
            theta_max_display, theta_allow_deg_per_m, passfail(okTheta));
    else
        fprintf('  max theta/L = %.2f deg/m  [reference only]\n', theta_max_display);
    end
    fprintf('  Critical speed check: %s\n', passfail_word(okNc));
    fprintf('    Nc = %.0f rpm, required = %.0f rpm, margin = %.2f\n', ...
        ev.Nc, crit_margin*sh.n_oper, ev.Nc/sh.n_oper);
    fprintf('    N0 shaft(Rayleigh) = %.0f rpm\n', ev.N0_shaft);
    fprintf('    Ni gear(Rayleigh) = [%s] rpm\n', num2str(ev.Ni_gear,'%.0f '));
    fprintf('    Nc Dunkerley synthesis = %.0f rpm\n', ev.Nc_dunkerley);
    fprintf('  critical section for static SF: %s, x = %.1f mm\n', ...
        ev.critical_stage_name, ev.x_crit);

    for k = 1:2
        fprintf('    %s: SF=%.3f, def=%.3f mm/m, theta=%.2f deg/m\n', ...
            gear(k).name, ev.SF_static_stage(k), ...
            ev.def_ratio_stage(k), trunc2(ev.theta_per_m_stage(k)));
    end
    fprintf('\n');

    summaryRows = [summaryRows; ...
        s, mass_kg, ev.SF_static_min, ev.SF_fatigue_min, ...
        ev.def_ratio_max, theta_max_display, ev.Nc, ...
        ev.N0_shaft, ev.Nc_dunkerley, ...
        okSF, okFat, okDef, okTheta, okNc, okFit];
end

summaryTbl = array2table(summaryRows, 'VariableNames', { ...
    'shaft_id','mass_kg','SF_static','SF_fatigue', ...
    'def_mm_per_m','theta_deg_per_m','Nc_rpm', ...
    'N0_shaft_rayleigh_rpm','Nc_dunkerley_rpm', ...
    'OK_static','OK_fatigue','OK_deflection','OK_torsion','OK_critical','OK_pinion_fit'});
summaryTbl.shaft_id = ["upper"; "lower"];

fprintf('================ Summary table ================\n');
disp(summaryTbl);

okAllProject = okLayout && all(summaryTbl.OK_static) && all(summaryTbl.OK_fatigue) && ...
    all(summaryTbl.OK_deflection) && all(summaryTbl.OK_torsion) && ...
    all(summaryTbl.OK_critical) && all(summaryTbl.OK_pinion_fit);

fprintf('\n================ Project condition verdict ================\n');
fprintf('Layout bearing sections 1/5 >= %.2f mm: %s\n', ...
    brg_side_req, passfail_word(okLayoutBearing));
fprintf('Layout clutch section 3 >= %.2f mm: %s\n', ...
    clutch_center_min, passfail_word(okLayoutClutch));
fprintf('Shaft static SF >= %.2f: %s\n', ...
    SF_static_req, passfail_word(all(summaryTbl.OK_static)));
fprintf('Overall project condition: %s\n', passfail_word(okAllProject));

%% 8. 베어링 담당자 전달값 ------------------------------------------------
fprintf('\n================ 베어링 담당자 전달값 ================\n');
fprintf('베어링 스팬 L = %.2f mm\n', L_span);
fprintf('기어 위치 xG1 = %.2f mm, xG2 = %.2f mm\n', xG(1), xG(2));
fprintf('상축 저널 후보 = %.2f mm, 하축 저널 후보 = %.2f mm\n', ...
    min(Do_upper), min(Do_lower));
fprintf('상축 회전수 = %.0f rpm\n', n_in);
fprintf('하축 회전수 = Stage1 %.0f rpm / Stage2 %.0f rpm\n', ...
    gear(1).n_lower, gear(2).n_lower);

[RA_env, RB_env, Fa_env, reactTbl] = bearing_reaction_envelope(L_span, xG, gear, shaft);
fprintf('Radial reaction envelope: RA = %.0f N, RB = %.0f N\n', RA_env, RB_env);
fprintf('Axial load envelope: Fa = %.0f N\n\n', Fa_env);
disp(reactTbl);

%% ========================================================================
% Local functions
% =========================================================================

function secL = secL_from_xG(L, xG, b1, b2)
    xG = xG(:).';
    xStep = [0, xG(1)-b1/2, xG(1)+b1/2, xG(2)-b2/2, xG(2)+b2/2, L];
    secL = diff(xStep);
end

function ev = evaluate_stepped_shaft(L, xG, secL, E, G, rho, gear, sh, mat)
    Do = sh.Do;
    Di = sh.Di;

    nStage = numel(gear);
    delta = zeros(1,nStage);
    def_ratio = zeros(1,nStage);
    SFs = zeros(1,nStage);
    SFf = zeros(1,nStage);
    theta_pm = zeros(1,nStage);
    xcrit = zeros(1,nStage);

    for k = 1:nStage
        g = gear(k);
        Cmag = g.(sh.Cfield);
        T = g.(sh.Tfield);

        [dmax, ~, ~, xs] = bending_deflection( ...
            L, xG(k), g.Wt, g.Wr, Cmag, Do, Di, secL, E);
        delta(k) = dmax;
        def_ratio(k) = dmax/(L/1000);

        Mx = resultant_moment_curve(L, xs, xG(k), g.Wt, g.Wr, Cmag);
        [SFs(k), SFf(k), detail] = shaft_stress(Mx, T, Do, Di, secL, xs, mat);
        xcrit(k) = detail.x_crit;

        [~, theta_pm(k)] = torsion_angle(T, Do, Di, secL, G);
    end

    gearMass = [gear.(sh.massfield)];
    [Nc, cdetail] = critical_speed(L, Do, Di, secL, E, rho, gearMass, xG);
    [SFmin, idxCrit] = min(SFs);

    ev = struct();
    ev.delta_stage = delta;
    ev.def_ratio_stage = def_ratio;
    ev.def_ratio_max = max(def_ratio);
    ev.SF_static_stage = SFs;
    ev.SF_fatigue_stage = SFf;
    ev.SF_static_min = SFmin;
    ev.SF_fatigue_min = min(SFf);
    ev.theta_per_m_stage = theta_pm;
    ev.theta_per_m_max = max(theta_pm);
    ev.Nc = Nc;
    ev.N0_shaft = cdetail.N0_shaft_rpm;
    ev.Ni_gear = cdetail.Ni_gear_rpm;
    ev.Nc_dunkerley = cdetail.Nc_dunkerley_rpm;
    ev.critical_detail = cdetail;
    ev.critical_stage_index = idxCrit;
    ev.critical_stage_name = gear(idxCrit).name;
    ev.x_crit = xcrit(idxCrit);
end

function Mres = resultant_moment_curve(L, xs, a, Ft, Fr, Cmag)
    Mt = beam_moment_for_eval(Ft, a, L, 0, xs);
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

function mass_kg = stepped_shaft_mass(Do, Di, secL, rho)
    A = pi/4*(Do.^2 - Di^2);
    V = sum(A .* secL);
    mass_kg = rho * V * 1e-9;
end

function [RA_env, RB_env, Fa_env, tbl] = bearing_reaction_envelope(L, xG, gear, shaft)
    rows = zeros(numel(shaft)*numel(gear), 10);
    irow = 1;

    for s = 1:numel(shaft)
        sh = shaft(s);
        for k = 1:numel(gear)
            Ft = gear(k).Wt;
            Fr = gear(k).Wr;
            Fa = gear(k).Wa;
            Cmag = gear(k).(sh.Cfield);
            a = xG(k);

            RA_t = Ft*(L-a)/L;
            RB_t = Ft*a/L;

            RB_r_p = (Fr*a + Cmag)/L;
            RA_r_p = Fr - RB_r_p;
            RB_r_n = (Fr*a - Cmag)/L;
            RA_r_n = Fr - RB_r_n;

            RA = max(hypot(RA_t, RA_r_p), hypot(RA_t, RA_r_n));
            RB = max(hypot(RB_t, RB_r_p), hypot(RB_t, RB_r_n));

            rows(irow,:) = [s, k, a, Ft, Fr, Fa, Cmag, RA, RB, max(RA,RB)];
            irow = irow + 1;
        end
    end

    tbl = array2table(rows, 'VariableNames', { ...
        'shaft_id','stage','xG_mm','Wt_N','Wr_N','Fa_N','C_Nmm', ...
        'RA_radial_N','RB_radial_N','Rmax_N'});
    tbl.shaft_name = strings(height(tbl),1);
    for s = 1:numel(shaft)
        tbl.shaft_name(tbl.shaft_id == s) = string(shaft(s).name);
    end
    tbl = movevars(tbl, 'shaft_name', 'After', 'shaft_id');

    RA_env = max(tbl.RA_radial_N);
    RB_env = max(tbl.RB_radial_N);
    Fa_env = max(abs(tbl.Fa_N));
end

function s = passfail(tf)
    if tf
        s = 'OK';
    else
        s = 'FAIL';
    end
end

function s = passfail_word(tf)
    if tf
        s = 'PASS';
    else
        s = 'FAIL';
    end
end

function y = trunc2(x)
    y = floor(x*100)/100;
end
