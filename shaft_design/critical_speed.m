function [Nc, detail] = critical_speed(L, Do, Di, secL, E, rho, gearMass, xG)
%% ========================================================================
%  critical_speed.m  (v6 -- Rayleigh component speeds + Dunkerley synthesis)
%  변단면 단순지지축의 1차 위험속도 추정.
%  ------------------------------------------------------------------------
%  1) Rayleigh 적용
%     - 축 자중 단독 임계속도 N0 계산
%     - 각 회전체(기어) 단독 임계속도 N1, N2, ... 계산
%     - 모든 처짐 계산에는 변단면 I(x)를 반영
%
%  2) Dunkerley 합성
%       1/Nc^2 = 1/N0^2 + 1/N1^2 + 1/N2^2 + ...
%
%  여기서 Nc가 최종 반환값이다. 즉 Rayleigh와 Dunkerley 중 작은 값을
%  고르는 방식이 아니라, Rayleigh로 얻은 개별 임계속도를 Dunkerley
%  공식에 넣어 합성한다.
%  ------------------------------------------------------------------------
%  입력:
%    L              : 베어링 스팬 [mm]
%    Do, Di, secL   : 변단면 외경/내경/구간 길이 [mm]
%    E              : 탄성계수 [MPa = N/mm^2]
%    rho            : 축 재료 밀도 [kg/m^3]
%    gearMass       : 기어 집중질량 벡터 [kg] (없으면 축 자중만 사용)
%    xG             : 기어 위치 벡터 [mm]
%  출력:
%    Nc             : Dunkerley 합성 위험속도 [rpm]
%    detail         : 계산 상세값 구조체
% =========================================================================

    g = 9.81;                       % [m/s^2]

    if isempty(gearMass)
        xG = [];
    end

    validate_inputs(L, Do, Di, secL, gearMass, xG);

    N  = 1001;
    xs = linspace(0, L, N);         % [mm]
    dx = xs(2) - xs(1);

    [Ix, q] = section_I_and_weight(xs, Do, Di, secL, rho, g);

    Pgear = gearMass(:).' * g;      % [N]
    xGear = xG(:).';                % [mm]

    % N0: 축 자중 단독 Rayleigh 임계속도
    [N0_rpm, omega0, y0_mm, n0, d0] = ...
        rayleigh_speed(xs, L, Ix, E, q, [], [], g, dx);

    % Ni: 각 회전체 단독 Rayleigh 임계속도
    nGear = numel(Pgear);
    Ni_rpm = inf(1, nGear);
    omegai = inf(1, nGear);
    gear_deflection_mm = zeros(1, nGear);

    for k = 1:nGear
        [Ni_rpm(k), omegai(k), yi_mm] = ...
            rayleigh_speed(xs, L, Ix, E, zeros(size(q)), Pgear(k), xGear(k), g, dx);
        gear_deflection_mm(k) = interp1(xs, abs(yi_mm), xGear(k), 'linear', 0);
    end

    component_N = [N0_rpm, Ni_rpm];
    component_omega = [omega0, omegai];
    valid = isfinite(component_N) & component_N > 0;

    if ~any(valid)
        Nc = inf;
        omega_c = inf;
    else
        inv_N2 = sum(1 ./ component_N(valid).^2);
        Nc = sqrt(1 / inv_N2);

        inv_omega2 = sum(1 ./ component_omega(valid).^2);
        omega_c = sqrt(1 / inv_omega2);
    end

    shaftMass = trapz(xs, q) / g;   % [kg]

    detail = struct();
    detail.method = 'Rayleigh component speeds + Dunkerley synthesis';
    detail.returned_Nc_is = 'Dunkerley synthesis of N0, N1, N2, ...';
    detail.Nc_rpm = Nc;
    detail.omega_n = omega_c;

    % 기존 verify_stepped_shaft 출력과 호환되도록 대표 필드 유지.
    detail.Nc_rayleigh_rpm = N0_rpm;
    detail.Nc_dunkerley_rpm = Nc;

    detail.N0_shaft_rpm = N0_rpm;
    detail.Ni_gear_rpm = Ni_rpm;
    detail.omega0_shaft = omega0;
    detail.omegai_gear = omegai;
    detail.component_N_rpm = component_N;
    detail.component_omega = component_omega;

    detail.x_mm = xs;
    detail.shaft_deflection_mm = y0_mm;
    detail.shaft_deflection_abs_max_mm = max(abs(y0_mm));
    detail.gear_deflection_mm = gear_deflection_mm;
    detail.mass_shaft_kg = shaftMass;
    detail.mass_gear_kg = sum(gearMass);
    detail.mass_total_kg = shaftMass + sum(gearMass);
    detail.rayleigh_shaft_num = n0;
    detail.rayleigh_shaft_den = d0;
end


function validate_inputs(L, Do, Di, secL, gearMass, xG)
    if any(Do <= Di)
        error('Do(%.1f..) 가 Di(%.1f) 이하인 구간이 있습니다.', min(Do), Di);
    end
    if abs(sum(secL) - L) > 1e-6*max(1,L)
        error('sum(secL)=%.4f 가 L=%.4f 와 불일치합니다.', sum(secL), L);
    end
    if numel(Do) ~= numel(secL)
        error('Do와 secL 길이가 일치해야 합니다.');
    end
    if isempty(gearMass)
        gearMass = [];
        xG = [];
    end
    if numel(gearMass) ~= numel(xG)
        error('gearMass와 xG 길이가 일치해야 합니다.');
    end
    if any(xG < 0) || any(xG > L)
        error('xG는 0 <= xG <= L 범위에 있어야 합니다.');
    end
end


function [Ix, q] = section_I_and_weight(xs, Do, Di, secL, rho, g)
% 위치별 단면2차모멘트 I(x)와 축 자중 q(x)를 만든다. q 단위는 [N/mm].
    edges = [0, cumsum(secL)];
    Ix = zeros(size(xs));
    q  = zeros(size(xs));

    for i = 1:numel(xs)
        idx = find(xs(i) >= edges(1:end-1) & xs(i) <= edges(2:end), 1);
        if isempty(idx)
            idx = numel(Do);
        end

        A = pi/4 * (Do(idx)^2 - Di^2);      % [mm^2]
        Ix(i) = pi/64 * (Do(idx)^4 - Di^4); % [mm^4]

        lineMass = rho * A * 1e-6;          % [kg/m]
        q(i) = lineMass * g / 1000;         % [N/mm]
    end
end


function [Nc_rpm, omega_n, y_mm, num, den] = ...
        rayleigh_speed(xs, L, Ix, E, q, P, a, g, dx)
% 주어진 하중계 q + P@a 단독 상태에 대한 Rayleigh 임계속도.
    if isempty(P)
        P = [];
        a = [];
    end

    if all(q == 0) && isempty(P)
        Nc_rpm = inf;
        omega_n = inf;
        y_mm = zeros(size(xs));
        num = 0;
        den = 0;
        return;
    end

    M = bending_moment_from_static_loads(xs, L, q, P, a, dx);
    y_mm = deflection_from_moment(M, Ix, E, dx, xs, L);
    y_m = abs(y_mm) * 1e-3;         % [m]
    yP_m = interp1(xs, y_m, a, 'linear', 0);

    num = trapz(xs, q .* y_m) + sum(P .* yP_m);       % [N*m]
    den = trapz(xs, q .* y_m.^2) + sum(P .* yP_m.^2); % [N*m^2]

    if num <= 0 || den <= 0
        Nc_rpm = inf;
        omega_n = inf;
        return;
    end

    omega_n = sqrt(g * num / den);  % [rad/s]
    Nc_rpm = omega_n * 60 / (2*pi); % [rpm]
end


function M = bending_moment_from_static_loads(xs, L, q, P, a, dx)
% 단순지지보에 분포하중 q(x)와 집중하중 P@a가 작용할 때의 M(x).
    Q_total = trapz(xs, q) + sum(P);
    moment_about_A = trapz(xs, q .* xs) + sum(P .* a);

    RB = moment_about_A / L;
    RA = Q_total - RB;

    Q_left  = cumtrapz_local(q, dx);
    Qx_left = cumtrapz_local(q .* xs, dx);

    M = RA .* xs - (xs .* Q_left - Qx_left);
    for k = 1:numel(P)
        right = xs >= a(k);
        M(right) = M(right) - P(k) .* (xs(right) - a(k));
    end
end


function y = deflection_from_moment(M, Ix, E, dx, xs, L)
% EI y'' = M 이중적분. 단순지지 경계조건 y(0)=0, y(L)=0 적용.
    curv  = M ./ (E .* Ix);
    theta = cumtrapz_local(curv, dx);
    y0    = cumtrapz_local(theta, dx);
    C1 = -y0(end) / L;
    y = y0 + C1 * xs;
end


function out = cumtrapz_local(f, dx)
    out = zeros(size(f));
    for i = 2:numel(f)
        out(i) = out(i-1) + 0.5*(f(i)+f(i-1))*dx;
    end
end
