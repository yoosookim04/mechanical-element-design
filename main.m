clc
clear

K_v = AGMA.K_v(0.262)
[K_s_p, K_s_g] = AGMA.K_s(2.5, 0, 18, 20, 36)
K_H = AGMA.K_H(2.5, 0, 18, 20)
[Y_J_p,Y_J_g] = AGMA.Y_J_helical(0,20,36)