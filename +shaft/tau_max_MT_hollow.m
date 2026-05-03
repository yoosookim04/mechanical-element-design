function tau_max = tau_max_MT_hollow(M,T,d_2,x)
    % 원형 축단면, 굽힘,비틀림 복합하중 시 최대전단응력
    % 입력: M 굽힘 모멘트, T 비틀림 모멘트 [Nmm]
    % d_2: 외경 [mm], x: 내경/외경 비율
    % 출력: tau_max = 최대전단응력 [MPa] (등가비틀림모멘트에 대한 비틀림전단응력)
    T_e = shaft.eq_torque(M,T);
    tau_max = stress.torsion_stress_hollow(T_e,d_2,x);
end