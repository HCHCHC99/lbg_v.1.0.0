%% sweep_speed.m
% 批量测试不同转速下龙伯格观测器的性能
% 转速范围: 1000 ~ 7800 rpm, 步长约 2000 rpm
% 不改 pll_step，只改 omega_e 的值

clear; clc;

%% 打开模型
model_path = 'F:\SIMULINK\Luenberger_BLDC\scripts\test2\lbg.slx';
[~, model_name, ~] = fileparts(model_path);

if ~bdIsLoaded(model_name)
    load_system(model_path);
end

fprintf('模型已加载: %s\n', model_name);

%% 电机参数
p = 10;   % 极对数

%% 测试转速列表 (rpm)
speeds_rpm = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 7800];

%% 确保 StopTime = 0.03
set_param(model_name, 'StopTime', '0.03');

%% 结果存储
results = struct();

fprintf('\n========================================\n');
fprintf('开始批量测试\n');
fprintf('========================================\n\n');

for i = 1:length(speeds_rpm)
    n_rpm = speeds_rpm(i);
    omega_e = p * 2 * pi * n_rpm / 60;

    fprintf('---------- 测试 %d rpm (omega_e = %.1f rad/s) ----------\n', ...
        n_rpm, omega_e);

    % 改 omega_e
    set_param([model_name '/omega_e'], 'Value', num2str(omega_e));

    % 运行仿真
    try
        simOut = sim(model_name);
    catch ME
        fprintf('  仿真失败: %s\n', ME.message);
        results(i).rpm = n_rpm;
        results(i).omega_e = omega_e;
        results(i).status = 'FAIL';
        continue;
    end

    % 提取数据
    try
        [t, e_alpha_real] = get_signal(simOut, 'e_alpha_real');
        [~, e_beta_real]  = get_signal(simOut, 'e_beta_real');
        [~, e_alpha_hat]  = get_signal(simOut, 'e_alpha_hat');
        [~, e_beta_hat]   = get_signal(simOut, 'e_beta_hat');
        [~, theta_e_real] = get_signal(simOut, 'theta_e_real');
        [~, theta_hat]    = get_signal(simOut, 'theta_hat');
        [~, theta_err]    = get_signal(simOut, 'theta_err');
    catch ME
        fprintf('  数据提取失败: %s\n', ME.message);
        results(i).rpm = n_rpm;
        results(i).omega_e = omega_e;
        results(i).status = 'NO_DATA';
        continue;
    end

    % 稳态索引（最后 20%）
    n_samples = length(t);
    idx_ss = round(0.8*n_samples):n_samples;

    % 指标 1：反电动势幅值误差
    e_real_mag = sqrt(e_alpha_real.^2 + e_beta_real.^2);
    e_hat_mag  = sqrt(e_alpha_hat.^2 + e_beta_hat.^2);
    e_real_ss  = mean(e_real_mag(idx_ss));
    e_hat_ss   = mean(e_hat_mag(idx_ss));
    emf_mag_err = abs(e_hat_ss - e_real_ss) / e_real_ss * 100;

    % 指标 2：反电动势相位误差
    phi_real = atan2(-e_alpha_real(idx_ss), e_beta_real(idx_ss));
    phi_hat  = atan2(-e_alpha_hat(idx_ss),  e_beta_hat(idx_ss));
    phi_err  = mod(phi_real - phi_hat + pi, 2*pi) - pi;
    phi_err_deg = mean(abs(phi_err)) * 180 / pi;

    % 指标 3：角度误差
    theta_err_ss = theta_err(idx_ss) * 180 / pi;
    theta_err_mean = mean(theta_err_ss);
    theta_err_std  = std(theta_err_ss);
    theta_err_max  = max(abs(theta_err_ss));

    % 指标 4：收敛时间
    threshold = 5;
    theta_err_abs_deg = abs(theta_err * 180 / pi);
    converged = false;
    t_conv = NaN;
    for k = 1:length(t)
        if all(theta_err_abs_deg(k:end) < threshold)
            t_conv = t(k);
            converged = true;
            break;
        end
    end

    % 指标 5：稳定性
    if any(isnan(theta_err)) || any(isinf(theta_err))
        stability = 'DIVERGED';
    elseif max(abs(theta_err_ss)) > 180
        stability = 'UNSTABLE';
    else
        stability = 'STABLE';
    end

    % 存储
    results(i).rpm          = n_rpm;
    results(i).omega_e      = omega_e;
    results(i).emf_mag_err  = emf_mag_err;
    results(i).phi_err_deg  = phi_err_deg;
    results(i).theta_mean   = theta_err_mean;
    results(i).theta_std    = theta_err_std;
    results(i).theta_max    = theta_err_max;
    results(i).t_conv       = t_conv;
    results(i).converged    = converged;
    results(i).stability    = stability;
    results(i).status       = 'OK';

    % 打印
    fprintf('  反电动势幅值误差: %.2f%%\n', emf_mag_err);
    fprintf('  反电动势相位误差: %.2f°\n', phi_err_deg);
    fprintf('  角度平均误差: %.2f°\n', theta_err_mean);
    fprintf('  角度标准差: %.2f°\n', theta_err_std);
    fprintf('  角度最大误差: %.2f°\n', theta_err_max);
    if converged
        fprintf('  收敛时间: %.2f ms\n', t_conv*1000);
    else
        fprintf('  收敛时间: 未收敛\n');
    end
    fprintf('  稳定性: %s\n', stability);
    fprintf('\n');
end

%% 汇总表格
fprintf('\n========================================\n');
fprintf('批量测试汇总\n');
fprintf('========================================\n\n');

fprintf('%-8s %-10s %-10s %-10s %-10s %-10s %-10s %-10s\n', ...
    'rpm', 'omega_e', 'EMF幅值%', '相位°', '角度均值°', '角度最大°', '收敛ms', '稳定性');
fprintf('%-8s %-10s %-10s %-10s %-10s %-10s %-10s %-10s\n', ...
    '--------', '----------', '----------', '----------', ...
    '----------', '----------', '----------', '----------');

for i = 1:length(results)
    r = results(i);
    if strcmp(r.status, 'OK')
        if r.converged
            t_conv_str = sprintf('%.2f', r.t_conv*1000);
        else
            t_conv_str = 'N/A';
        end
        fprintf('%-8d %-10.1f %-10.2f %-10.2f %-10.2f %-10.2f %-10s %-10s\n', ...
            r.rpm, r.omega_e, r.emf_mag_err, r.phi_err_deg, ...
            r.theta_mean, r.theta_max, t_conv_str, r.stability);
    else
        fprintf('%-8d %-10.1f %-10s\n', r.rpm, r.omega_e, r.status);
    end
end

fprintf('\n');

%% 保存结果到 .mat
save('sweep_speed_results.mat', 'results');
fprintf('结果已保存: sweep_speed_results.mat\n');

%% ---------- 函数定义放在文件末尾 ----------

function [t, v] = get_signal(simOut, var_name)
    try
        data = simOut.get(var_name);
        t = data.time;
        v = squeeze(data.signals.values);
    catch
        error('无法提取变量 %s，请检查 To Workspace 模块。', var_name);
    end
end