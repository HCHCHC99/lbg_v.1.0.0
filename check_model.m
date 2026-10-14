%% check_model.m
% 检查 lbg.slx 的模块、参数、连线、悬空端口、求解器设置，
% 并打印所有 MATLAB Function 的代码

clear; clc;

%% 1. 打开模型
model_path = 'F:\SIMULINK\Luenberger_BLDC\scripts\test2\lbg.slx';
[~, model_name, ~] = fileparts(model_path);

if ~bdIsLoaded(model_name)
    load_system(model_path);
end

fprintf('========================================\n');
fprintf('模型名称: %s\n', model_name);
fprintf('========================================\n\n');

%% 2. 求解器设置
fprintf('---------- 求解器设置 ----------\n');
fprintf('SolverType   : %s\n', get_param(model_name, 'SolverType'));
fprintf('Solver       : %s\n', get_param(model_name, 'Solver'));
fprintf('FixedStep    : %s\n', get_param(model_name, 'FixedStep'));
fprintf('StopTime     : %s\n', get_param(model_name, 'StopTime'));
fprintf('\n');

%% 3. 所有模块列表
fprintf('---------- 模块列表 ----------\n');
blocks = find_system(model_name, 'Type', 'Block');
for i = 1:length(blocks)
    bt = get_param(blocks{i}, 'BlockType');
    name = get_param(blocks{i}, 'Name');
    fprintf('%2d. %-40s [%s]\n', i, name, bt);
end
fprintf('\n');

%% 4. Unit Delay 参数
fprintf('---------- Unit Delay 参数 ----------\n');
ud_blocks = find_system(model_name, 'BlockType', 'UnitDelay');
for i = 1:length(ud_blocks)
    st = get_param(ud_blocks{i}, 'SampleTime');
    ic = get_param(ud_blocks{i}, 'InitialCondition');
    fprintf('%s\n', ud_blocks{i});
    fprintf('    SampleTime       = %s\n', st);
    fprintf('    InitialCondition = %s\n', ic);
end
fprintf('\n');

%% 5. Constant 参数
fprintf('---------- Constant 参数 ----------\n');
const_blocks = find_system(model_name, 'BlockType', 'Constant');
for i = 1:length(const_blocks)
    val = get_param(const_blocks{i}, 'Value');
    fprintf('%s = %s\n', const_blocks{i}, val);
end
fprintf('\n');

%% 6. MATLAB Function 模块（打印代码）
fprintf('---------- MATLAB Function 模块代码 ----------\n');
mf_blocks = find_system(model_name, 'BlockType', 'SubSystem');
for i = 1:length(mf_blocks)
    block = mf_blocks{i};
    block_name = get_param(block, 'Name');

    % 判断是否是 MATLAB Function
    is_mf = false;
    try
        masktype = get_param(block, 'MaskType');
    catch
        masktype = '';
    end
    if contains(masktype, 'MATLAB Function', 'IgnoreCase', true)
        is_mf = true;
    end
    if any(strcmp(block_name, {'luenberger_step', 'pll_step', 'motor_step', ...
            'angle_calc', 'angle_error'}))
        is_mf = true;
    end

    if ~is_mf
        continue;
    end

    fprintf('\n========================================\n');
    fprintf('模块: %s\n', block_name);
    fprintf('========================================\n');

    try
        sf_root = sfroot;
        sf_chart = sf_root.find('-isa', 'Stateflow.EMChart', '-and', 'Path', block);
        if ~isempty(sf_chart)
            code = sf_chart.Script;
            fprintf('%s\n', code);
        else
            code = get_param(block, 'MATLABFunction');
            if ~isempty(code)
                fprintf('%s\n', code);
            else
                fprintf('（无法读取代码）\n');
            end
        end
    catch ME
        fprintf('读取失败: %s\n', ME.message);
    end
end
fprintf('\n');

%% 7. Scope 参数
fprintf('---------- Scope 参数 ----------\n');
scope_blocks = find_system(model_name, 'BlockType', 'Scope');
for i = 1:length(scope_blocks)
    nports = get_param(scope_blocks{i}, 'NumInputPorts');
    fprintf('%s : NumInputPorts = %s\n', scope_blocks{i}, nports);
end
fprintf('\n');

%% 8. 所有连线
fprintf('---------- 连线 ----------\n');
lines = find_system(model_name, 'FindAll', 'on', 'Type', 'Line');
for i = 1:length(lines)
    try
        src_handle = get_param(lines(i), 'SrcBlockHandle');
        dst_handle = get_param(lines(i), 'DstBlockHandle');
        if src_handle > 0 && dst_handle > 0
            src_name = get_param(src_handle, 'Name');
            dst_name = get_param(dst_handle, 'Name');
            src_port = get_param(lines(i), 'SrcPort');
            dst_port = get_param(lines(i), 'DstPort');
            fprintf('%s (port %s) --> %s (port %s)\n', ...
                src_name, src_port, dst_name, dst_port);
        end
    catch
        fprintf('Line %d: 无法读取\n', i);
    end
end
fprintf('\n');

%% 9. 检查悬空输入端口
fprintf('---------- 悬空输入端口 ----------\n');
for i = 1:length(blocks)
    try
        ph = get_param(blocks{i}, 'PortHandles');
        for j = 1:length(ph.Inport)
            line = get_param(ph.Inport(j), 'Line');
            if line == -1
                fprintf('悬空: %s 输入端口 %d\n', blocks{i}, j);
            end
        end
    catch
        fprintf('无法读取: %s\n', blocks{i});
    end
end
fprintf('\n');

%% 10. 检查悬空输出端口
fprintf('---------- 悬空输出端口 ----------\n');
for i = 1:length(blocks)
    try
        ph = get_param(blocks{i}, 'PortHandles');
        for j = 1:length(ph.Outport)
            line = get_param(ph.Outport(j), 'Line');
            if line == -1
                fprintf('悬空: %s 输出端口 %d\n', blocks{i}, j);
            end
        end
    catch
        fprintf('无法读取: %s\n', blocks{i});
    end
end
fprintf('\n');

%% 11. 每个模块的输入来源
fprintf('---------- 每个模块的输入来源 ----------\n');
for i = 1:length(blocks)
    try
        ph = get_param(blocks{i}, 'PortHandles');
        if isempty(ph.Inport)
            continue;
        end
        fprintf('%s\n', blocks{i});
        for j = 1:length(ph.Inport)
            line = get_param(ph.Inport(j), 'Line');
            if line == -1
                fprintf('    输入 %d: 悬空\n', j);
            else
                src = get_param(line, 'SrcBlockHandle');
                src_name = get_param(src, 'Name');
                fprintf('    输入 %d: 来自 %s\n', j, src_name);
            end
        end
    catch
        fprintf('无法读取: %s\n', blocks{i});
    end
end
fprintf('\n');

fprintf('========================================\n');
fprintf('检查完成\n');
fprintf('========================================\n');