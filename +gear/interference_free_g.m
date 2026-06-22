function N_max = interference_free_g(alpha_n, beta, u)
    % 간섭 회피 최대 잇수 계산 (기어)
    % 입력 alpha_n: 축직각 압력각, beta: helix angle, u: 기어비 (u >= 1)
    % 출력 N_max: maximum number of teeth of gear to avoid interference (k=1, alpha=alpha_t, Z_p=interference_free_p 기준)

    alpha_t = atand(tand(alpha_n) / cosd(beta)); % 치직각 압력각
    k  = 1;
    Zp = gear.interference_free_p(alpha_n, beta, u); % 간섭 회피 최소 피니언 잇수 (Z_p)
    N_max = (Zp^2 * sind(alpha_t)^2 - 4*k^2) / (4*k - 2*Zp*sind(alpha_t)^2); % 간섭 회피 최대 잇수 공식 (기어)
end
