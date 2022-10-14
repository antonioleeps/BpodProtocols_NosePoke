function save_custom_data_csv()

%{
Function to write trial custom data from NosePoke
into a tab separated value file (.tsv)

Author: Greg Knoll
Date: October 13, 2022
%}

global BpodSystem

n_trials = BpodSystem.Data.nTrials;

trial_data = BpodSystem.Data.Custom.TrialData;

%{
preprocess the data
- remove last entry in arrays that are n_trials+1 long (from the incomplete
  last trial)
- split any n_trials x 2 array into two n_trials x 1 arrays

then save in the table as a column (requires using .', which inverts the
dimensions)
%}
data_table = table();

% ---------------------Sample and Choice variables-------------------- %
data_table.EarlyWithdrawal = trial_data.EarlyWithdrawal(1:n_trials).';
data_table.SampleTime = trial_data.SampleTime(1:n_trials).';
data_table.sample_length = trial_data.sample_length(1:n_trials).';

data_table.ChoiceLeft = trial_data.ChoiceLeft(1:n_trials).';
data_table.move_time = trial_data.move_time(1:n_trials).';
data_table.port_entry_delay = trial_data.port_entry_delay(1:n_trials).';


% -----------------------Reward variables------------------------------ %
data_table.Correct = trial_data.Correct(1:n_trials).';
data_table.Rewarded = trial_data.Rewarded(1:n_trials).';
data_table.RewardAvailable = trial_data.RewardAvailable(1:n_trials).';
data_table.RewardDelay = trial_data.RewardDelay(1:n_trials).';
data_table.RewardMagnitude_L = trial_data.RewardMagnitude(1:n_trials, 1);
data_table.RewardMagnitude_R = trial_data.RewardMagnitude(1:n_trials, 2);

data_table.CenterPortRewAmount = trial_data.CenterPortRewAmount(1:n_trials).';
data_table.CenterPortRewarded = trial_data.CenterPortRewarded(1:n_trials).';

% -------------------------Misc variables------------------------------ %
data_table.Jackpot = trial_data.Jackpot(1:n_trials).';
data_table.RandomThresholdPassed = trial_data.RandomThresholdPassed(1:n_trials).';
data_table.LightLeft = trial_data.LightLeft(1:n_trials).';

[filepath, session_name, ext] = fileparts(BpodSystem.Path.CurrentDataFile);
file_name = string(strcat("O:\data\", session_name, "_trial_custom_data_and_params.csv"));
writetable(data_table, file_name, "Delimiter", "\t")

end  % save_custom_data_and_params_tsv()