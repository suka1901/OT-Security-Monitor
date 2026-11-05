function mdl = ot_build_simulink(open_it)
%OT_BUILD_SIMULINK Programmatically build a district-heating supply-temperature
%  control loop (PI controller + first-order heat-Exchanger plant) and save it.
if nargin < 1, open_it = true; end
mdl = 'dh_control_loop';
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl);

add_block('simulink/Sources/Constant',     [mdl '/Setpoint'], 'Value','90', 'Position',[30 100 70 130]);
add_block('simulink/Math Operations/Sum',  [mdl '/Error'], 'Inputs','+-', 'Position',[110 95 140 135]);
add_block('simulink/Continuous/PID Controller',[mdl '/PI'], 'Controller','PI', ...
    'P','1.2','I','0.05', 'Position',[180 88 250 142]);
add_block('simulink/Continuous/Transfer Fcn',[mdl '/HeatExchanger'], ...
    'Numerator','[1]','Denominator','[120 1]', 'Position',[300 95 380 135]);
add_block('simulink/Sinks/Scope',          [mdl '/SupplyTemp'], 'Position',[440 95 480 135]);
add_block('simulink/Sinks/To Workspace',   [mdl '/Log'], 'VariableName','dh_out', ...
    'SaveFormat','Timeseries', 'Position',[440 165 500 195]);

add_line(mdl,'Setpoint/1','Error/1');
add_line(mdl,'Error/1','PI/1');
add_line(mdl,'PI/1','HeatExchanger/1');
add_line(mdl,'HeatExchanger/1','SupplyTemp/1');
add_line(mdl,'HeatExchanger/1','Error/2','autorouting','on');
add_line(mdl,'HeatExchanger/1','Log/1','autorouting','on');

set_param(mdl,'StopTime','600');
slx = fullfile(fileparts(mfilename('fullpath')), [mdl '.slx']);
save_system(mdl, slx);
if open_it, open_system(mdl); end
fprintf('Simulink model saved: %s\n', slx);
end
