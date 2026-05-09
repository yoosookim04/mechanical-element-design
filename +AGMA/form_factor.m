function [Y_p, Y_g] = form_factor(N_p, N_g)
    % Lewis Form Factor 조회 함수 (20° Full-Depth Involute, Shigley's Table 14-2)
    % 선형 보간 이용
    % 입력: N_p = 피니언 잇수, N_g = 기어 잇수
    % 출력: Y_p = 피니언 Lewis Form Factor, Y_g = 기어 Lewis Form Factor

    % ── 1. 테이블 로드 ────────────────────────────────────────────────
    base_dir   = fileparts(mfilename('fullpath'));        % 이 .m 파일의 폴더 경로 (즉, AGMA 폴더 경로)
    % mfilename('fullpath') : 이 .
    % m 파일의 전체 경로 (예: C:...\AGMA\form_factor.m). 'fullpath' 없으면 단순히 'form_factor' 반환
    % [dir,name,ext] = fileparts(mfilename('fullpath')) : dir = 폴더 경로(+AGMA), name = 파일 이름(form_factor), ext = 확장자(.m)
    % base_dir = dir : AGMA 폴더 경로

    table_path = fullfile(base_dir, 'form_factor_table.xlsx');  % 엑셀 파일 전체 경로 조합 (AGMA 폴더에 있는 lewis_table.xlsx까지의 경로)
    T          = readtable(table_path); % 엑셀 파일에서 테이블 읽기 (T는 테이블 형식으로 데이터 저장)
    % 첫 행은 헤더로 자동인식 (NumberOfTeeth_N_, LewisFormFactor_Y_)
    N_table    = T.NumberOfTeeth_N_';
    Y_table    = T.LewisFormFactor_Y_';

    valid   = isfinite(N_table) & isfinite(Y_table);
    N_table = N_table(valid);
    Y_table = Y_table(valid);
    % isfinite : 유효한 데이터만 보간에 사용하기 위해 NaN이나 Inf 제거.
    % 실제 data 마지막 행에 NaN이 있기에 유효한 데이터만 추출하여 보간에 사용.

    % ── 2. 보간 ───────────────────────────────────────────────────────
    Y_p = interp_Y(N_p, N_table, Y_table);
    Y_g = interp_Y(N_g, N_table, Y_table);

    % ── 3. 결과 출력 ──────────────────────────────────────────────────
    fprintf('피니언  N_p = %d  →  Y_p = %.4f\n', N_p, Y_p);
    fprintf('기어    N_g = %d  →  Y_g = %.4f\n', N_g, Y_g);
    % MATLAB fprintf 문법: %d는 정수, %.4f는 소수점 4자리까지의 실수. \n은 줄바꿈.
    % %는 변수 삽입 위치 표시.
end

% ── 로컬 함수: 단일 잇수에 대한 보간 ─────────────────────────────────
function Y = interp_Y(N, N_table, Y_table)
    if N < min(N_table) || N > max(N_table)
        error('잇수 N=%d 는 테이블 범위(%d ~ %d)를 벗어났습니다.', ...
              N, min(N_table), max(N_table))
    end
    Y = interp1(N_table, Y_table, N, 'linear');
    % interp1 : 1차원 선형 보간 함수. N_table과 Y_table에서 N에 해당하는 Y 값을 선형적으로 계산.
    % y = interp1(x_data, y_data, x, method)
    % y: 찾는 값(보간된 값), x_data: 기존 데이터의 x값, y_data: 기존 데이터의 y값, x: 찾는 값, method: 보간 방법
    % 보간방법 : linear (선형), nearest (가장 가까운 값), spline (부드러운 곡선:4개 이상 점 3차곡선), pchip (단조성 보존 3차곡선)   
end
