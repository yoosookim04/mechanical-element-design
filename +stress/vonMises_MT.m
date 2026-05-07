function  sgm_von = vonMises_MT(M,T,d,x)
    % 원형 축단면, 굽힘,비틀림 복합하중 시 vonMises 등가응력
    % 입력: M 굽힘 모멘트, T 비틀림 모멘트 [Nmm], d 직경(외경) [mm]
    % 중공축의 경우 x 내경/외경 비율
    % 출력: sgm_von = vonMises 등가응력 [MPa]
    if nargin < 4
        sgm_von = (16/(pi*d^3))*sqrt(3*(T^2) + 4*(M^2)); 
    else
        sgm_von = (16/(pi*(d^3)*(1-x^4))) * sqrt(3*(T^2) + 4*(M^2));
    end
end