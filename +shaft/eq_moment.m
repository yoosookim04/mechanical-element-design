function M_e = eq_moment(M,T)
    % 원형(중공축 가능) 축단면, 굽힘,비틀림 복합하중 시 등가굽힘모멘트
    % 입력: M 굽힘 모멘트, T 비틀림 모멘트 [Nmm]
    % 출력: M_e = 등가굽힘모멘트 [Nmm]
    M_e = (1/2)*(M + sqrt(M^2 + T^2));
end