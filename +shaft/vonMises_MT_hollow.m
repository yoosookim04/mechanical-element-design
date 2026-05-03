function  sgm_von = vonMises_MT_hollow(M,T,d_2,x)
    % 원형 축단면, 굽힘,비틀림 복합하중 시 vonMises 등가응력
    % 입력: M 굽힘 모멘트, T 비틀림 모멘트 [Nmm]
    % d_2: 외경 [mm], x: 내경/외경 비율
    % 출력: sgm_von = vonMises 등가응력 [MPa]
    sgm_von = (16/(pi*(d_2^3)*(1-x^4)))*sqrt(3*(T^2) + 4*(M^2)); 
end