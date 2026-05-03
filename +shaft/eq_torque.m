function T_e = eq_torque(M,T)
    % 원형(중공축 가능) 축단면, 굽힘,비틀림 복합하중 시 등가비틀림모멘트
    % 입력: M 굽힘 모멘트, T 비틀림 모멘트 [Nmm]
    % 출력: T_e = 등가비틀림모멘트 [Nmm]
    T_e = sqrt(M^2 + T^2);
end