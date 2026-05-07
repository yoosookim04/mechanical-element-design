function n = SF_DE(sgm_x,tau_xy,S_y)
    % combined stress (평면응력 상태, sgm_x,tau_xy (sgm_y=0)) 상황의 vonMises 이론에 따른 정적파손
    % 입력: sgm_x, tau_xy 인장/압축응력, 전단응력 [MPa], S_y 인장 항복 강도 [MPa]
    % 출력: n = 안전계수 (DE 이론 기반 정적 파손)
    if S_y <= 0
        error('S_y는 양수여야 합니다. 입력값: S_y = %.4f', S_y)
    end
    sgm_von = stress.vonMises(sgm_x, tau_xy);
    n = S_y / sgm_von;
end