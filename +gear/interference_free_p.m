function N_min = interference_free_p(alpha_n, beta, u)
    % 간섭 회피 최소 잇수 계산
    % 입력 alpha_n: 축직각 압력각, beta: helix angle, u: 기어비 (u >= 1)
    % 출력 N_min: minimum number of teeth of pinion to avoid interference

    alpha_t = atand(tand(alpha_n) / cosd(beta)); % 치직각 압력각
    N_min = 2 * cosd(beta) / ((1+ 2*u) * sind(alpha_t)^2) * (u + sqrt(u^2 + (1+2*u)*sind(alpha_t)^2)); % 간섭 회피 최소 잇수 공식
    N_min = ceil(N_min); % 잇수는 정수여야 하므로 올림
end