function  sgm_von = vonMises_MT(M,T,d)
    % 원형 축단면, 굽힘,비틀림 복합하중 시 vonMises 등가응력
    % 입력: M 굽힘 모멘트, T 비틀림 모멘트 [Nmm], d 직경 [mm]
    % 출력: sgm_von = vonMises 등가응력 [MPa]
    sgm_von = (16/(pi*d^3))*sqrt(3*(T^2) + 4*(M^2)); 
end