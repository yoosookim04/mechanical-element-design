function [n_DE,n_MSS] = SF(sgm_x,tau_xy,S_y)
    %  combined stress (평면응력 상태, sgm_x,tau_xy (sgm_y=0))의 정적 파손 진단
    % 압축과 인장에 대한 강도가 비슷하 연성 재료
    % 입력: 응력상태 (sgm_x,tau_xy), 인장항복강도 S_y
    if S_y <= 0
        error('S_y는 양수여야 합니다. 입력값: S_y = %.4f', S_y)
    end
    n_DE = static.SF_DE(sgm_x,tau_xy,S_y);
    n_MSS = static.SF_MSS(sgm_x,tau_xy,S_y);
    fprintf('DE : %.4f\n', n_DE);
    fprintf('MSS : %.4f\n', n_MSS);
end