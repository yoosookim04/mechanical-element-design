function n = SF_MSS(sgm_x, tau_xy,S_y) 
    % combined stress (평면응력 상태, sgm_x,tau_xy (sgm_y=0)) 상황의 최대전단응력에 따른 정적파손
    % 주의: sgm_y != 0 의 경우, 별도의 계산 필요
    % 입력: sgm_x, tau_xy: 인장/압축응력, 전단응력 [MPa], S_y = 인장 항복 강도 [MPa]
    % 출력: n = 안전계수 (MSS 이론 기반 정적 파손)
    if S_y <= 0
        error('S_y는 양수여야 합니다. 입력값: S_y = %.4f', S_y)
    end
    tau_max = stress.tau_max(sgm_x,tau_xy);
    S_sy = 0.5 * S_y;
    n = S_sy / tau_max;
end