function sgm_von = vonMises(sgm_x,tau_xy)
    % combined stress (평면응력상태, sgm_x,tau_xy (sgm_y=0)) 상황의 vonMises
    % 입력: sgm_x, tau_xy: 인장/압축응력, 전단응력 [MPa]
    % 출력: sgm_von = vonMises stress [MPa]
    sgm_von = sqrt(sgm_x^2 + 3*tau_xy^2);
end