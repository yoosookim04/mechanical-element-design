function [Y_p, Y_g] = form_factor(N_p, N_g)
    % Lewis Form Factor 조회 함수 (20° Full-Depth Involute, Shigley's Table 14-2(Gear Rating 강의자료 52p))
    % 선형 보간 이용
    % 입력: N_p = 잇수 (단독 사용 가능), N_g = 기어 잇수 (생략가능)
    % 출력: Y_p = Lewis Form Factor, Y_g = 기어 Lewis Form Factor(생략가능)

    % ── 1. 테이블 로드 ────────────────────────────────────────────────
    % Shigley's Table 14-2: 20° Full-Depth Involute Lewis Form Factor
    N_table = [12,    13,    14,    15,    16,    17,    18,    19,    20, ...
               22,    24,    26,    28,    30,    34,    38,    43,    50, ...
               60,    75,   100,   150,   300,   400];
    Y_table = [0.245, 0.261, 0.277, 0.290, 0.296, 0.303, 0.309, 0.314, 0.322, ...
               0.331, 0.337, 0.346, 0.353, 0.359, 0.371, 0.384, 0.397, 0.409, ...
               0.422, 0.435, 0.447, 0.460, 0.472, 0.480];

    % ── 2. 보간 ───────────────────────────────────────────────────────
    Y_p = interp_Y(N_p, N_table, Y_table);

    if nargin == 1
        fprintf('잇수  N = %d  →  Y = %.4f\n', N_p, Y_p);
        return
    end

    Y_g = interp_Y(N_g, N_table, Y_table);

    % ── 3. 결과 출력 ──────────────────────────────────────────────────
    fprintf('피니언  N_p = %d  →  Y_p = %.4f\n', N_p, Y_p);
    fprintf('기어    N_g = %d  →  Y_g = %.4f\n', N_g, Y_g);
end

% ── 로컬 함수: 단일 잇수에 대한 보간 ─────────────────────────────────
function Y = interp_Y(N, N_table, Y_table)
    if N < min(N_table) || N > max(N_table)
        error('잇수 N=%d 는 테이블 범위(%d ~ %d)를 벗어났습니다.', ...
              N, min(N_table), max(N_table))
    end
    Y = interp1(N_table, Y_table, N, 'linear');
end
