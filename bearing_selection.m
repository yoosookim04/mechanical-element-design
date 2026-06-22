clc; clear;

%% ================= Integrated Bearing Life Calculator =================
% DGBB: fixed bearing, supports Fr and Fa
% CRB : floating bearing, supports Fr only
%
% Bearing arrangement:
% A side : Upper CRB  - Lower DGBB
% B side : Upper DGBB - Lower CRB

required_life = 5000; % [h]

%% ================= Bearing catalog data =================
upper_DGBB_name  = "SKF 6307";
upper_DGBB_C_kN  = 35.1;
upper_DGBB_C0_kN = 19;
upper_DGBB_f0    = 13;

lower_DGBB_name  = "SKF 6209";
lower_DGBB_C_kN  = 35.1;
lower_DGBB_C0_kN = 21.6;
lower_DGBB_f0    = 14;

upper_CRB_name  = "NU 1007 ECP";
upper_CRB_C_kN  = 35.8;
upper_CRB_C0_kN = 38;

lower_CRB_name  = "NU 1009 ECP";
lower_CRB_C_kN  = 44.6;
lower_CRB_C0_kN = 52;

%% ================= Layout setting =================
upper_DGBB_side = "A";
upper_CRB_side  = "B";

lower_DGBB_side = "B";
lower_CRB_side  = "A";

%% ================= Shaft load data =================
% Data format: [Stage, RA_radial_N, RB_radial_N, Fa_N, rpm]

upper_load = [
    1, 2498.60,  760.17, 795.98, 6000;
    2,  703.22, 2117.20, 717.13, 6000
];

lower_load = [
    1, 2540.30,  813.67, 795.98, 3067;
    2,  734.91, 2142.20, 717.13, 3892
];

%% ================= X, Y table for DGBB =================
% rows: [f0*Fa/C0, e, Y]
XY_table = [
    0.172, 0.19, 2.30;
    0.345, 0.22, 1.99;
    0.689, 0.26, 1.71;
    1.030, 0.28, 1.55;
    1.380, 0.30, 1.45;
    2.070, 0.34, 1.31;
    3.450, 0.38, 1.15;
    5.170, 0.42, 1.04;
    6.890, 0.44, 1.00
];

%% ================= Upper DGBB =================
fprintf("\n========== Upper Shaft DGBB ==========\n");
fprintf("Bearing: %s\n", upper_DGBB_name);

C  = upper_DGBB_C_kN * 1000;
C0 = upper_DGBB_C0_kN * 1000;
f0 = upper_DGBB_f0;

upper_DGBB_result = [];

for i = 1:size(upper_load,1)
    stage = upper_load(i,1);
    RA = upper_load(i,2);
    RB = upper_load(i,3);
    Fa = upper_load(i,4);
    n  = upper_load(i,5);

    if upper_DGBB_side == "A"
        Fr = RA;
    else
        Fr = RB;
    end

    ratio = f0 * Fa / C0;
    Fa_Fr = Fa / Fr;

    e = interp1(XY_table(:,1), XY_table(:,2), ratio, "linear", "extrap");
    Y = interp1(XY_table(:,1), XY_table(:,3), ratio, "linear", "extrap");

    if Fa_Fr <= e
        X = 1;
        Y_used = 0;
    else
        X = 0.56;
        Y_used = Y;
    end

    P = X*Fr + Y_used*Fa;
    L10h = (1e6/(60*n)) * (C/P)^3;

    upper_DGBB_result = [upper_DGBB_result; stage, Fr, Fa, n, ratio, Fa_Fr, e, X, Y_used, P, L10h];

    fprintf("Stage %.0f: Fr=%.2f N, Fa=%.2f N, P=%.2f N, L10h=%.2f h\n", ...
        stage, Fr, Fa, P, L10h);
end

[minLife, idx] = min(upper_DGBB_result(:,11));
fprintf("Minimum life = %.2f h at Stage %.0f\n", minLife, upper_DGBB_result(idx,1));
if minLife >= required_life
    fprintf("Result: PASS\n");
else
    fprintf("Result: FAIL\n");
end

%% ================= Lower DGBB =================
fprintf("\n========== Lower Shaft DGBB ==========\n");
fprintf("Bearing: %s\n", lower_DGBB_name);

C  = lower_DGBB_C_kN * 1000;
C0 = lower_DGBB_C0_kN * 1000;
f0 = lower_DGBB_f0;

lower_DGBB_result = [];

for i = 1:size(lower_load,1)
    stage = lower_load(i,1);
    RA = lower_load(i,2);
    RB = lower_load(i,3);
    Fa = lower_load(i,4);
    n  = lower_load(i,5);

    if lower_DGBB_side == "A"
        Fr = RA;
    else
        Fr = RB;
    end

    ratio = f0 * Fa / C0;
    Fa_Fr = Fa / Fr;

    e = interp1(XY_table(:,1), XY_table(:,2), ratio, "linear", "extrap");
    Y = interp1(XY_table(:,1), XY_table(:,3), ratio, "linear", "extrap");

    if Fa_Fr <= e
        X = 1;
        Y_used = 0;
    else
        X = 0.56;
        Y_used = Y;
    end

    P = X*Fr + Y_used*Fa;
    L10h = (1e6/(60*n)) * (C/P)^3;

    lower_DGBB_result = [lower_DGBB_result; stage, Fr, Fa, n, ratio, Fa_Fr, e, X, Y_used, P, L10h];

    fprintf("Stage %.0f: Fr=%.2f N, Fa=%.2f N, P=%.2f N, L10h=%.2f h\n", ...
        stage, Fr, Fa, P, L10h);
end

[minLife, idx] = min(lower_DGBB_result(:,11));
fprintf("Minimum life = %.2f h at Stage %.0f\n", minLife, lower_DGBB_result(idx,1));
if minLife >= required_life
    fprintf("Result: PASS\n");
else
    fprintf("Result: FAIL\n");
end

%% ================= Upper CRB =================
fprintf("\n========== Upper Shaft CRB ==========\n");
fprintf("Bearing: %s\n", upper_CRB_name);

C = upper_CRB_C_kN * 1000;
p = 10/3;

upper_CRB_result = [];

for i = 1:size(upper_load,1)
    stage = upper_load(i,1);
    RA = upper_load(i,2);
    RB = upper_load(i,3);
    n  = upper_load(i,5);

    if upper_CRB_side == "A"
        Fr = RA;
    else
        Fr = RB;
    end

    P = Fr;
    L10h = (1e6/(60*n)) * (C/P)^p;

    upper_CRB_result = [upper_CRB_result; stage, Fr, n, P, L10h];

    fprintf("Stage %.0f: Fr=%.2f N, P=%.2f N, L10h=%.2f h\n", ...
        stage, Fr, P, L10h);
end

[minLife, idx] = min(upper_CRB_result(:,5));
fprintf("Minimum life = %.2f h at Stage %.0f\n", minLife, upper_CRB_result(idx,1));
if minLife >= required_life
    fprintf("Result: PASS\n");
else
    fprintf("Result: FAIL\n");
end

%% ================= Lower CRB =================
fprintf("\n========== Lower Shaft CRB ==========\n");
fprintf("Bearing: %s\n", lower_CRB_name);

C = lower_CRB_C_kN * 1000;
p = 10/3;

lower_CRB_result = [];

for i = 1:size(lower_load,1)
    stage = lower_load(i,1);
    RA = lower_load(i,2);
    RB = lower_load(i,3);
    n  = lower_load(i,5);

    if lower_CRB_side == "A"
        Fr = RA;
    else
        Fr = RB;
    end

    P = Fr;
    L10h = (1e6/(60*n)) * (C/P)^p;

    lower_CRB_result = [lower_CRB_result; stage, Fr, n, P, L10h];

    fprintf("Stage %.0f: Fr=%.2f N, P=%.2f N, L10h=%.2f h\n", ...
        stage, Fr, P, L10h);
end

[minLife, idx] = min(lower_CRB_result(:,5));
fprintf("Minimum life = %.2f h at Stage %.0f\n", minLife, lower_CRB_result(idx,1));
if minLife >= required_life
    fprintf("Result: PASS\n");
else
    fprintf("Result: FAIL\n");
end