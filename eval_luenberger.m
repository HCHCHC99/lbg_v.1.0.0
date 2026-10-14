%% eval_luenberger.m
% 评估龙伯格观测器的性能
% 1. 运行仿真
% 2. 提取反电动势、角度、误差数据
% 3. 计算性能指标
% 4. 画图

clear; clc;

%% 打开模型
model_path = 'F:\SIMULINK\Luenberger_BLDC\scripts\test2\lbg.slx';
[~, model_name, ~] = fileparts(model_path);

if ~bdIsLoaded(model_name)
    load_system(model_path);
end

fprintf('模型已加载: %s\n', model_name);

%% 确保 StopTime = 0.01
set_param(model_name, 'StopTime', '0.01');

%% 给关键信号加 To Workspace 模块
fprintf('\n---------- 添加 To Workspace 模块 ----------\n');

signals_to_log = {
    'UD_e_alpha',   1, 'e_alpha_real';
    'UD_e_beta',    1, 'e_beta_real';
    'Demux_emf',    3, 'e_alpha_hat';
    'Demux_emf',    4, 'e_beta_hat';
    'angle_calc',   1, 'theta_e_real';
    'pll_step',     1, 'theta_hat';
    'angle_error',  1, 'theta_err';
};

for i = 1:size(signals_to_log, 1)
    src_block = signals_to_log{i, 1};
    src_port  = signals_to_log{i, 2};
    var_name  = signals_to_log{i, 3};

    tws_block = [model_name '/ToWS_' var_name];

    try
        get_param(tws_block, 'BlockType');
        fprintf('ToWS_%s 已存在。\n', var_name);
    catch
        add_block('simulink/Sinks/To Workspace', tws_block, ...
            'Position', [900 100+i*40 980 130+i*40]);
        set_param(tws_block, 'VariableName', var_name);
        set_param(tws_block, 'SaveFormat', 'Structure With Time');
        fprintf('已添加 ToWS_%s\n', var_name);

        ph_src = get_param([model_name '/' src_block], 'PortHandles');
        ph_tws = get_param(tws_block, 'PortHandles');
        add_line(model_name, ph_src.Outport(src_port), ph_tws.Inport(1), ...
            'autorouting', 'on');
        fprintf('  已连接 %s 端口 %d -> ToWS_%s\n', src_block, src_port, var_name);
    end
end

%% 保存
save_system(model_name);

%% 运行仿真
fprintf('\n---------- 运行仿真 ----------\n');
simOut = sim(model_name);
fprintf('仿真结束。\n');

%% 提取数据
fprintf('\n---------- 提取数据 ----------\n');

[t_e_real, e_alpha_real] = get_signal(simOut, 'e_alpha_real');
[~, e_beta_real]  = get_signal(simOut, 'e_beta_real');
[~, e_alpha_hat]  = get_signal(simOut, 'e_alpha_hat');
[~, e_beta_hat]   = get_signal(simOut, 'e_beta_hat');
[~, theta_e_real] = get_signal(simOut, 'theta_e_real');
[~, theta_hat]    = get_signal(simOut, 'theta_hat');
[~, theta_err]    = get_signal(simOut, 'theta_err');

fprintf('数据提取完成。\n');
fprintf('采样点数: %d\n', length(t_e_real));
fprintf('仿真时长: %.4f s\n', t_e_real(end));

%% 计算性能指标
fprintf('\n========================================\n');
fprintf('龙伯格观测器性能评估\n');
fprintf('========================================\n\n');

e_real_mag = sqrt(e_alpha_real.^2 + e_beta_real.^2);
e_hat_mag  = sqrt(e_alpha_hat.^2 + e_beta_hat.^2);

n = length(t_e_real);
idx_ss = round(0.9*n):n;

e_real_ss = mean(e_real_mag(idx_ss));
e_hat_ss  = mean(e_hat_mag(idx_ss));
emf_mag_err = abs(e_hat_ss - e_real_ss) / e_real_ss * 100;

fprintf('1. 反电动势幅值\n');
fprintf('   真实幅值 (稳态): %.4f V\n', e_real_ss);
fprintf('   估计幅值 (稳态): %.4f V\n', e_hat_ss);
fprintf('   幅值误差: %.2f%%\n', emf_mag_err);
fprintf('\n');

phi_real = atan2(-e_alpha_real(idx_ss), e_beta_real(idx_ss));
phi_hat  = atan2(-e_alpha_hat(idx_ss),  e_beta_hat(idx_ss));

phi_err = mod(phi_real - phi_hat + pi, 2*pi) - pi;
phi_err_deg = mean(abs(phi_err)) * 180 / pi;

fprintf('2. 反电动势相位\n');
fprintf('   相位误差 (稳态平均): %.2f°\n', phi_err_deg);
fprintf('\n');

theta_err_ss = theta_err(idx_ss);
theta_err_deg = theta_err_ss * 180 / pi;

theta_err_mean = mean(theta_err_deg);
theta_err_std  = std(theta_err_deg);
theta_err_max  = max(abs(theta_err_deg));

fprintf('3. 角度误差\n');
fprintf('   平均误差: %.2f°\n', theta_err_mean);
fprintf('   标准差: %.2f°\n', theta_err_std);
fprintf('   最大误差: %.2f°\n', theta_err_max);
fprintf('\n');

threshold = 5;
theta_err_abs_deg = abs(theta_err * 180 / pi);
converged = false;
t_conv = NaN;

for k = 1:length(t_e_real)
    if all(theta_err_abs_deg(k:end) < threshold)
        t_conv = t_e_real(k);
        converged = true;
        break;
    end
end

fprintf('4. 收敛时间\n');
if converged
    fprintf('   进入 ±%d° 的时间: %.4f s (%.2f ms)\n', ...
        threshold, t_conv, t_conv*1000);
else
    fprintf('   未在仿真时间内收敛到 ±%d°\n', threshold);
end
fprintf('\n');

fprintf('5. 稳定性\n');
if any(isnan(theta_err)) || any(isinf(theta_err))
    fprintf('   发散（存在 NaN 或 Inf）\n');
elseif max(abs(theta_err_deg)) > 180
    fprintf('   可能不稳定（误差超过 180°）\n');
else
    fprintf('   稳定\n');
end
fprintf('\n');

emf_err_alpha = e_alpha_real - e_alpha_hat;
emf_err_beta  = e_beta_real  - e_beta_hat;
emf_err_mag   = sqrt(emf_err_alpha.^2 + emf_err_beta.^2);
emf_err_ss    = mean(emf_err_mag(idx_ss));

fprintf('6. 反电动势跟踪误差 (稳态)\n');
fprintf('   alpha 轴误差: %.4f V\n', mean(abs(emf_err_alpha(idx_ss))));
fprintf('   beta 轴误差: %.4f V\n', mean(abs(emf_err_beta(idx_ss))));
fprintf('   幅值误差: %.4f V\n', emf_err_ss);
fprintf('\n');

%% 画图
fprintf('---------- 画图 ----------\n');

figure('Name', 'Luenberger Observer Evaluation', 'Position', [100 100 1200 800]);

subplot(3, 2, 1);
plot(t_e_real*1000, e_alpha_real, 'b', 'LineWidth', 1.5); hold on;
plot(t_e_real*1000, e_alpha_hat, 'r--', 'LineWidth', 1.5);
xlabel('Time (ms)'); ylabel('e_\alpha (V)');
title('EMF alpha'); legend('real', 'hat'); grid on;

subplot(3, 2, 2);
plot(t_e_real*1000, e_beta_real, 'b', 'LineWidth', 1.5); hold on;
plot(t_e_real*1000, e_beta_hat, 'r--', 'LineWidth', 1.5);
xlabel('Time (ms)'); ylabel('e_\beta (V)');
title('EMF beta'); legend('real', 'hat'); grid on;

subplot(3, 2, 3);
plot(t_e_real*1000, e_real_mag, 'b', 'LineWidth', 1.5); hold on;
plot(t_e_real*1000, e_hat_mag, 'r--', 'LineWidth', 1.5);
xlabel('Time (ms)'); ylabel('|e| (V)');
title('EMF magnitude'); legend('real', 'hat'); grid on;

subplot(3, 2, 4);
plot(t_e_real*1000, theta_e_real*180/pi, 'b', 'LineWidth', 1.5); hold on;
plot(t_e_real*1000, theta_hat*180/pi, 'r--', 'LineWidth', 1.5);
xlabel('Time (ms)'); ylabel('\theta (deg)');
title('Electrical angle'); legend('real', 'hat'); grid on;

subplot(3, 2, 5);
plot(t_e_real*1000, theta_err*180/pi, 'k', 'LineWidth', 1.5);
xlabel('Time (ms)'); ylabel('\theta_{err} (deg)');
title('Angle error'); grid on;
yline(5, 'r--'); yline(-5, 'r--');

subplot(3, 2, 6);
plot(t_e_real*1000, emf_err_alpha, 'b', 'LineWidth', 1); hold on;
plot(t_e_real*1000, emf_err_beta, 'r', 'LineWidth', 1);
xlabel('Time (ms)'); ylabel('Error (V)');
title('EMF tracking error');
legend('e_\alpha err', 'e_\beta err'); grid on;

saveas(gcf, 'luenberger_eval.png');
fprintf('图片已保存: luenberger_eval.png\n');

%% 总结
fprintf('\n========================================\n');
fprintf('评估总结\n');
fprintf('========================================\n');
fprintf('反电动势幅值误差: %.2f%%\n', emf_mag_err);
fprintf('反电动势相位误差: %.2f°\n', phi_err_deg);
fprintf('角度平均误差: %.2f°\n', theta_err_mean);
fprintf('角度最大误差: %.2f°\n', theta_err_max);
if converged
    fprintf('收敛时间: %.2f ms\n', t_conv*1000);
else
    fprintf('收敛时间: 未收敛\n');
end
fprintf('========================================\n');

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