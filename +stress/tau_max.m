function t_max = tau_max(sgm_x, tau_xy)
    % combined stress (평면응력 상태, sgm_x,tau_xy (sgm_y=0)) 상황의 최대전단응력
    % 입력: sgm_x, tau_xy: 인장/압축응력, 전단응력 [MPa]
    % 출력: t_max = 최대전단응력 [MPa]
    t_max = sqrt((sgm_x/2)^2 + tau_xy^2);
end