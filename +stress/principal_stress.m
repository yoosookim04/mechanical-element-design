function [sgm_1,sgm_2] =principal_stress(sgm_x,tau_xy)
    % combined stress (평면응력상태, sgm_x,tau_xy (sgm_y=0)) 상황의 주응력
    % 입력: sgm_x, tau_xy: 인장/압축응력, 전단응력 [MPa]
    % 출력: sgm_1,sgm_2 = 주응력 [MPa]
    sgm_1 = sgm_x / 2 + sqrt((sgm_x / 2)^2 + tau_xy^2);
    sgm_2 = sgm_x / 2 - sqrt((sgm_x / 2)^2 + tau_xy^2);
end