function sgm = axial_stress(F,A)
    % 원형 단면 인장응력
    % 입력: F = axial load [N], A = 단면적 [mm^2]
    % 출력: sgm = 인장응력 [MPa]
    if A <= 0
        error ('A는 양수여야 합니다. 입력값 : A = %.4f', A)
    end

    sgm = F / A;
end