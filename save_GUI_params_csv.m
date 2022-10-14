function save_GUI_params_csv()
%{
Function to write trial GUI params from NosePoke
into a tab separated value file (.tsv)

Author: Greg Knoll
Date: October 14, 2022
%}

global BpodSystem

params = BpodSystem.GUIData.ParameterGUI;

data_table = cell2table(params.LastParamValues, "VariableNames", params.ParamNames);

[filepath, session_name, ext] = fileparts(BpodSystem.Path.CurrentDataFile);
file_name = string(strcat("O:\data\", session_name, "_trial_params.csv"));
writetable(data_table, file_name, "Delimiter", "\t")

end  % save_GUI_params_csv()