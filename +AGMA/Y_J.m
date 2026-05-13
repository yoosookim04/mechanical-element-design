function [Y_J_p, Y_J_g] = Y_J(beta, N_p, N_g)
    % Geometry Factor (형상계수) for Helical Gear Bending, Y_J
    % Shigley Figures 14-7 (J'), 14-8 (J 보정계수)
    % beta = 0 입력 시 Figure 14-6 (스퍼기어) 등가값 반환
    % 오차 약 0.005 - 0.01 (더 보수적인 방향이고, 충분히 작다고 판단됨)
    % 입력
    %   beta : 헬릭스 각 [deg], 0 ≤ beta ≤ 35
    %   N_p  : 피니언 잇수
    %   N_g  : 기어 잇수
    % 출력
    %   Y_J_p : 피니언 형상계수
    %   Y_J_g : 기어 형상계수

    % --- 입력 범위 검증 ---
    if N_p < 20
        error('피니언 잇수 N_p = %d T 는 최솟값(20T) 미만입니다. 20T 이상의 잇수를 입력하세요.', N_p);
    end
    if N_g > 500
        error('기어 잇수 N_g = %d T 는 최댓값(500T) 초과입니다. 500T 이하의 잇수를 입력하세요.', N_g);
    end

    % --- 1단계: Figure 14-7 — 75T 상대기어 기준 J' ---
    Jp_prime = fig_14_7(beta, N_p);
    Jg_prime = fig_14_7(beta, N_g);

    % --- 2단계: Figure 14-8 — 실제 상대기어 보정 ---
    mult_p = fig_14_8(beta, N_g);   % 피니언 보정 (상대=기어)
    mult_g = fig_14_8(beta, N_p);   % 기어 보정 (상대=피니언)

    % --- 3단계: Y_J = J' × m ---
    Y_J_p = Jp_prime * mult_p;
    Y_J_g = Jg_prime * mult_g;

    fprintf('Pinion: Geometry Factor for Bending  Y_J_p = %.4f\n', Y_J_p);
    fprintf('Gear:   Geometry Factor for Bending  Y_J_g = %.4f\n', Y_J_g);
end

function Jp = fig_14_7(beta, N)
    % Figure 14-7: J' (상대기어 75잇수 기준)
    beta_grid = [0  5  10  15  20  25  30  35];
    N_grid    = [20  30  60  150  500];

    %                N=20    N=30    N=60    N=150   N=500
    J_table = [    0.340   0.390   0.450   0.480   0.530;   % beta=0
                   0.380   0.430   0.480   0.510   0.550;   % beta=5
                   0.420   0.460   0.510   0.540   0.575;   % beta=10
                   0.450   0.490   0.535   0.565   0.595;   % beta=15
                   0.475   0.515   0.555   0.585   0.615;   % beta=20
                   0.490   0.525   0.570   0.595   0.625;   % beta=25
                   0.500   0.535   0.575   0.600   0.630;   % beta=30
                   0.500   0.535   0.575   0.600   0.625];  % beta=35

    if beta < 0 || beta > 35
        warning('beta = %.2f° 가 범위(0°~35°) 밖. 클램프 사용', beta);
        beta = max(0, min(35, beta));
    end
    if N < 20
        warning('N = %d T 가 테이블 최솟값(20T) 미만 — 외삽 결과는 신뢰 불가', N);
    end

    Jp = interp2(N_grid, beta_grid, J_table, N, beta, 'makima');
end

function m = fig_14_8(beta, N_mate)
    % Figure 14-8: J 보정계수 (N_mate = 75 에서 m = 1)
    beta_grid = [0  5  10  15  20  25  30];
    N_grid    = [20  30  50  75  100  150  300  500];

    %             20T     30T     50T     75T     100T    150T    300T    500T
    m_table = [  0.910   0.940   0.980   1.000   1.020   1.050   1.080   1.100;   % beta=0
                 0.918   0.945   0.980   1.000   1.020   1.045   1.075   1.090;   % beta=5
                 0.922   0.948   0.982   1.000   1.020   1.042   1.072   1.085;   % beta=10
                 0.925   0.950   0.984   1.000   1.018   1.040   1.068   1.080;   % beta=15
                 0.928   0.953   0.985   1.000   1.017   1.038   1.064   1.078;   % beta=20
                 0.930   0.955   0.986   1.000   1.016   1.037   1.062   1.075;   % beta=25
                 0.932   0.957   0.987   1.000   1.015   1.036   1.060   1.075];  % beta=30

    if beta > 30, beta = 30; end
    if N_mate < 20
        warning('상대기어 잇수 = %d 가 너무 적음', N_mate);
        N_mate = 20;
    elseif N_mate > 500
        N_mate = 500;
    end

    m = interp2(N_grid, beta_grid, m_table, N_mate, beta, 'makima');
end