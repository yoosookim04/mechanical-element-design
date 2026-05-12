function [Y_J_p, Y_J_g] = Y_J(N_p, N_g)
    % Geometry Factor for Bending, Y_J (AGMA 908-B89, p.38)
    % 20도 압력각 표준 스퍼기어 기준 (whole depth factor : 2.25, tooth edge radius: 0.25)
    % HPSTC 기준
    % 입력 N_p: 피니언 잇수, N_g: 기어 잇수 (생략 시 N_p 단독 계산)
    % 출력 Y_J_p: 피니언 형상계수, Y_J_g: 기어 형상계수 (N_g 입력 시)

    pinion_teeth_axis = [21, 26, 35, 55, 135];
    gear_teeth_axis   = [21, 26, 35, 55, 135];

    Jp_table = [
    % Np=21  Np=26  Np=35  Np=55  Np=135
      0.33,   0.00,  0.00,  0.00,  0.00;  % Ng=21
      0.33,   0.35,  0.00,  0.00,  0.00;  % Ng=26
      0.34,   0.36,  0.39,  0.00,  0.00;  % Ng=35
      0.34,   0.37,  0.40,  0.43,  0.00;  % Ng=55
      0.35,   0.38,  0.41,  0.45,  0.49   % Ng=135
    ];

    Jg_table = [
    % Np=21  Np=26  Np=35  Np=55  Np=135
      0.33,   0.00,  0.00,  0.00,  0.00;  % Ng=21
      0.35,   0.35,  0.00,  0.00,  0.00;  % Ng=26
      0.37,   0.38,  0.39,  0.00,  0.00;  % Ng=35
      0.40,   0.41,  0.42,  0.43,  0.00;  % Ng=55
      0.43,   0.44,  0.45,  0.47,  0.49   % Ng=135
    ];

    if nargin == 1
        if N_p < 21
            error('잇수 N=%d 는 허용 범위(21 이상)를 벗어났습니다.', N_p)
        end
        [X, Y] = meshgrid(pinion_teeth_axis, gear_teeth_axis);
        Y_J_p = interp2(X, Y, Jp_table, N_p, N_p, 'linear');
        Y_J_g = [];
        fprintf('Geometry Factor for Bending  Y_J = %.4f\n', Y_J_p);
        return
    end

    if N_p < 21 || N_g < 21
        error('잇수가 21 미만입니다 (언더컷 범위).')
    end
    if N_g < N_p
        warning('일반적으로 기어(N_g)의 잇수가 피니언(N_p)보다 많거나 같습니다.')
    end

    [X, Y] = meshgrid(pinion_teeth_axis, gear_teeth_axis);
    Y_J_p = interp2(X, Y, Jp_table, N_p, N_g, 'linear');
    Y_J_g = interp2(X, Y, Jg_table, N_p, N_g, 'linear');
    fprintf('Pinion: Geometry Factor for Bending  Y_J = %.4f\n', Y_J_p);
    fprintf('Gear:   Geometry Factor for Bending  Y_J = %.4f\n', Y_J_g);
end
