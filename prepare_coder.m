%% prepare_coder.m
% 复制 lbg.slx 为 untitled_coder.slx
% 并注释掉所有不支持代码生成的模块

clear; clc;

%% 原模型
model_path = 'F:\SIMULINK\Luenberger_BLDC\scripts\test2\lbg.slx';
[~, model_name, ~] = fileparts(model_path);

%% 新模型
new_model_name = 'untitled_coder';
new_model_path = fullfile(fileparts(model_path), [new_model_name '.slx']);

%% 关闭已加载的模型
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end
if bdIsLoaded(new_model_name)
    close_system(new_model_name, 0);
end

%% 复制模型
copyfile(model_path, new_model_path);
fprintf('已复制: %s -> %s\n', model_path, new_model_path);

%% 加载新模型
load_system(new_model_path);

%% 要注释的模块
blocks_to_comment = {
    'Scope_emf', ...
    'Scope_angle', ...
    'Scope_theta_err', ...
    'ToWS_e_alpha_hat', ...
    'ToWS_e_alpha_real', ...
    'ToWS_e_beta_hat', ...
    'ToWS_e_beta_real', ...
    'ToWS_theta_e_real', ...
    'ToWS_theta_err', ...
    'ToWS_theta_hat'
};

fprintf('\n---------- 注释模块 ----------\n');
for i = 1:length(blocks_to_comment)
    block = [new_model_name '/' blocks_to_comment{i}];
    try
        set_param(block, 'Commented', 'on');
        fprintf('已注释: %s\n', blocks_to_comment{i});
    catch ME
        fprintf('跳过: %s（%s）\n', blocks_to_comment{i}, ME.message);
    end
end

%% 配置模型参数
fprintf('\n---------- 配置模型参数 ----------\n');

% 求解器
set_param(new_model_name, 'SolverType', 'Fixed-step');
set_param(new_model_name, 'Solver', 'FixedStepDiscrete');
set_param(new_model_name, 'FixedStep', '5e-05');
set_param(new_model_name, 'StopTime', '0.03');
fprintf('求解器: Fixed-step, discrete, 5e-05\n');

% 代码生成
set_param(new_model_name, 'SystemTargetFile', 'ert.tlc');
fprintf('系统目标文件: ert.tlc\n');

% 语言
set_param(new_model_name, 'TargetLang', 'C');
fprintf('语言: C\n');

% 生成报告
set_param(new_model_name, 'GenerateReport', 'on');
set_param(new_model_name, 'LaunchReport', 'on');
fprintf('代码生成报告: 开\n');

% 默认数据类型
set_param(new_model_name, 'DefaultUnderspecifiedDataType', 'double');
fprintf('默认数据类型: double\n');

%% 保存
save_system(new_model_name);
fprintf('\n模型已保存: %s\n', new_model_path);

%% 检查
fprintf('\n---------- 检查注释状态 ----------\n');
for i = 1:length(blocks_to_comment)
    block = [new_model_name '/' blocks_to_comment{i}];
    try
        commented = get_param(block, 'Commented');
        fprintf('%s: Commented = %s\n', blocks_to_comment{i}, commented);
    catch
        fprintf('%s: 不存在\n', blocks_to_comment{i});
    end
end

fprintf('\n完成。\n');
fprintf('下一步：打开 %s，按 Ctrl+B 生成代码。\n', new_model_path);