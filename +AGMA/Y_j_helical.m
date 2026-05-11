function [Y_j_p, Y_j_g] = Y_j_helical(beta, N_p, N_g)
    % Geometry Factor for Bending, Y_J — Helical Gear
    % Ref: Shigley's Mechanical Engineering Design, Fig. 14-7 & 14-8 (AGMA 908-B89)
    % 20도 압력각 기준
    % 입력 beta: 비틀림각 [deg], N_p: 피니언 잇수, N_g: 기어 잇수 (생략 시 피니언만 계산)
    % 출력 Y_j_p: 피니언 형상계수, Y_j_g: 기어 형상계수 (N_g 입력 시)

    psi_axis = [0, 5, 10, 15, 20, 25, 30, 35];

    % Fig. 14-7: J' — 행=자기 잇수 N, 열=비틀림각 beta
    N_axis_top = [20, 30, 60, 150, 500];
    %                  b=0°   5°     10°    15°    20°    25°    30°    35°
    Jprime_table = [
                    0.430, 0.460, 0.475, 0.480, 0.480, 0.470, 0.450, 0.435;  % N=20
                    0.485, 0.510, 0.525, 0.530, 0.525, 0.510, 0.495, 0.475;  % N=30
                    0.530, 0.560, 0.578, 0.584, 0.580, 0.568, 0.548, 0.528;  % N=60
                    0.580, 0.615, 0.635, 0.645, 0.640, 0.625, 0.605, 0.585;  % N=150
                    0.620, 0.650, 0.670, 0.680, 0.675, 0.665, 0.645, 0.625   % N=500
                  ];

    % Fig. 14-8: Modifying Factor — 행=상대 잇수 N, 열=비틀림각 beta
    N_axis_bot = [20, 30, 50, 75, 150, 500];
    %              b=0°   5°     10°    15°    20°    25°    30°    35°
    MF_table = [
                0.925, 0.927, 0.930, 0.932, 0.935, 0.937, 0.940, 0.945;  % mating N=20
                0.953, 0.957, 0.962, 0.968, 0.973, 0.978, 0.983, 0.988;  % mating N=30
                0.978, 0.980, 0.982, 0.983, 0.984, 0.985, 0.985, 0.985;  % mating N=50
                1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000;  % mating N=75 (기준)
                1.025, 1.024, 1.023, 1.022, 1.021, 1.019, 1.017, 1.015;  % mating N=150
                1.040, 1.039, 1.038, 1.036, 1.034, 1.032, 1.030, 1.027   % mating N=500
              ];

    validate(beta, N_p, N_axis_top, psi_axis);

    [Psi_top, N_top] = meshgrid(psi_axis, N_axis_top);
    [Psi_bot, N_bot] = meshgrid(psi_axis, N_axis_bot);

    Jp_prime = interp2(Psi_top, N_top, Jprime_table, beta, N_p, 'linear');

    if nargin == 2
        Y_j_g = [];
        Y_j_p = Jp_prime;   % MF(mating=75) = 1.0
        fprintf('Geometry Factor for Bending  Y_J = %.4f\n', Y_j_p);
        return
    end

    validate(beta, N_g, N_axis_top, psi_axis);

    MF_p     = interp2(Psi_bot, N_bot, MF_table, beta, N_g, 'linear');
    Y_j_p    = Jp_prime * MF_p;

    Jg_prime = interp2(Psi_top, N_top, Jprime_table, beta, N_g, 'linear');
    MF_g     = interp2(Psi_bot, N_bot, MF_table,     beta, N_p, 'linear');
    Y_j_g    = Jg_prime * MF_g;

    fprintf('Pinion: Geometry Factor for Bending  Y_J = %.4f\n', Y_j_p);
    fprintf('Gear:   Geometry Factor for Bending  Y_J = %.4f\n', Y_j_g);
end

function validate(beta, N, N_axis, psi_axis)
    if N < min(N_axis) || N > max(N_axis)
        error('잇수 N=%d 가 그래프 범위(%d ~ %d)를 벗어났습니다.', N, min(N_axis), max(N_axis))
    end
    if beta < min(psi_axis) || beta > max(psi_axis)
        error('비틀림각 beta=%g 도가 그래프 범위(%g ~ %g 도)를 벗어났습니다.', beta, min(psi_axis), max(psi_axis))
    end
end
