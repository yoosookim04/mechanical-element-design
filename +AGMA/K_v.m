function K_v = K_v(v,Q_v)
    % 속도계수 K_v
    % 입력: v pich line velocity [m/s] (경험식, fitting), Q_v: 정밀도 등급
    % 출력: K_v 속도계수
    B = 0.25*(12-Q_v)^(2/3);
    A = 50 + 56*(1-B);
    K_v = ((A+sqrt(200*v))/A)^B;
    % 단위 변환: 1 m/s ≈ 200 ft/min (196.85의 근사, K_v에 미치는 오차 ~0.8%)
end