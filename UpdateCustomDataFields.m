function UpdateCustomDataFields(iTrial)

global BpodSystem
global TaskParameters


% data structure references
raw_data = BpodSystem.Data.RawData;
raw_events = BpodSystem.Data.RawEvents;
trial_states = raw_events.Trial{iTrial}.States;

BpodSystem.Data.TrialTypes(iTrial)=1;

%% OutcomeRecord
trial_data = BpodSystem.Data.Custom.TrialData;

trial_data.sample_length(iTrial) = NaN;
trial_data.move_time(iTrial) = NaN; % poke out from center to poke in at a side
trial_data.port_entry_delay(iTrial) = NaN;  % delay time 
trial_data.false_exits(1:50,iTrial) = NaN(50,1);

% Go through the states visited this trial and 
idx_states_visited = raw_data.OriginalStateData{iTrial};
trial_state_names = raw_data.OriginalStateNamesByNumber{iTrial};
states_this_trial = trial_state_names(idx_states_visited);

% Get total amount of time spent sampling
sample_begin = trial_states.StartSampling(1,1);
if any(strcmp('Sampling',states_this_trial))
    if any(strcmp('stillSampling',states_this_trial)) && ~any(strcmp('lat_Go_signal',states_this_trial))
        if any(strcmp('stillSamplingJackpot',states_this_trial))
            sample_end = trial_states.stillSamplingJackpot(1,2);
        else
            sample_end = trial_states.stillSampling(1,2);
        end
    else
            sample_end = trial_states.Sampling(1,end); 
    end
    trial_data.sample_length(iTrial) = sample_end - sample_begin;
end


% Compute length of false exits from side pokes
if any(strcmp('GracePeriod', states_this_trial))
    registered_withdrawals = trial_states.GracePeriod;

    for i_exit = 1:size(registered_withdrawals,1)
        exit_time = registered_withdrawals(i_exit,1);
        return_time = registered_withdrawals(i_exit,2);
        trial_data.false_exits(i_exit,iTrial) = (return_time - exit_time);
    end
end  


%{
Compute: 
- movement times: the time spent to reach the side pokes 
- delay times: time spent in side poke.
    necessary to account for false exit lengths 
    (only want last exit - first entry)
%}
any_wait_L = any(strncmp('wait_L', states_this_trial, 6));
any_wait_R = any(strncmp('wait_R', states_this_trial, 6));
if any(strcmp('EarlyWithdrawal', states_this_trial))
    trial_data.EarlyWithdrawal(iTrial) = true;
elseif any_wait_L || any_wait_R
    start_side_in_wait = trial_states.wait_Sin(1,1);
    
    if any_wait_L
        trial_data.ChoiceLeft(iTrial) = 1;
        side_port_poke_times = trial_states.wait_L_start;
    else
        trial_data.ChoiceLeft(iTrial) = 0;
        side_port_poke_times = trial_states.wait_R_start;
    end

    trial_data.move_time(iTrial) = side_port_poke_times(1,2) - start_side_in_wait;

    t_first_entry = side_port_poke_times(1,1);
    
    t_last_exit = side_port_poke_times(end,end);
    trial_data.port_entry_delay(iTrial) = t_last_exit - t_first_entry; 
end



if any(strncmp('water_L',states_this_trial,7)) 
    trial_data.Rewarded(iTrial) = true;
elseif any(strncmp('water_R',states_this_trial,7)) 
    trial_data.Rewarded(iTrial) = true;
end

if any(strcmp('water_LJackpot',states_this_trial)) || any(strcmp('water_RJackpot',states_this_trial))
    trial_data.Jackpot(iTrial) = true;
    trial_data.Rewarded(iTrial) = true;
    if any(strcmp('water_LJackpot',states_this_trial))
        trial_data.move_time(iTrial) = trial_states.water_LJackpot(1,2) - trial_states.wait_SinJackpot(1,1);
    elseif any(strcmp('water_RJackpot', states_this_trial))
        trial_data.move_time(iTrial) = trial_states.water_RJackpot(1,2) - trial_states.wait_SinJackpot(1,1);
    end
end

if any(strcmp('lat_Go_signal',states_this_trial))
    trial_data.CenterPortRewarded(iTrial) = true;
end

% correct/error?
trial_data.Correct(iTrial) = true; %any choice is correct
    if TaskParameters.GUI.LightGuided
        if trial_data.LightLeft(iTrial)==1 && trial_data.ChoiceLeft(iTrial)==1
            trial_data.Correct(iTrial) = true;
        elseif trial_data.LightLeft(iTrial)==0 && trial_data.ChoiceLeft(iTrial)==0
            trial_data.Correct(iTrial) = true;
        elseif trial_data.LightLeft(iTrial)==1 && trial_data.ChoiceLeft(iTrial)==0
            trial_data.Correct(iTrial) = false;
        elseif trial_data.LightLeft(iTrial)==0 && trial_data.ChoiceLeft(iTrial)==1
            trial_data.Correct(iTrial) = false;
        end
    else
    trial_data.Correct(iTrial) = true;
    end

% %what trials are randomly rewarded
% if any(strcmp('RandomReward_water_L',states_this_trial)) || any(strcmp('RandomReward_water_R',states_this_trialde))
%     trial_data.RandomReward(iTrial)=true;
%     trial_data.Rewarded(iTrial) = true;
% else
%     trial_data.RandomReward(iTrial)=false;
% end



%% initialize next trial values
trial_data.ChoiceLeft(iTrial+1) = NaN;
trial_data.EarlyWithdrawal(iTrial+1) = false;
trial_data.Jackpot(iTrial+1) = false;

trial_data.sample_length(iTrial+1) = NaN;
trial_data.move_time(iTrial+1) = NaN;
trial_data.port_entry_delay(iTrial+1) = NaN;
trial_data.false_exits(1:50,iTrial+1) = NaN(50,1);

trial_data.Rewarded(iTrial+1) = false;
trial_data.CenterPortRewarded(iTrial+1) = false;
trial_data.LightLeft(iTrial+1) = rand(1,1)<0.5;

trial_data.RewardAvailable(iTrial+1) = rand(1,1) < TaskParameters.GUI.RewardProb;
trial_data.RewardDelay(iTrial+1) = abs(randn(1,1)*TaskParameters.GUI.DelaySigma + TaskParameters.GUI.DelayMean);
trial_data.RandomThresholdPassed(iTrial+1) = rand(1) < TaskParameters.GUI.RandomRewardProb;



% stimuli
if ~BpodSystem.EmulatorMode
    if TaskParameters.GUI.PlayStimulus == 2
%         [BpodSystem.Data.Custom.SessionMeta.RightClickTrain,BpodSystem.Data.Custom.SessionMeta.LeftClickTrain] = getClickStimulus(BpodSystem.Data.Custom.SessionMeta.MaxSampleTime);
%         SendCustomPulseTrain(1, BpodSystem.Data.Custom.SessionMeta.RightClickTrain, ones(1,length(BpodSystem.Data.Custom.SessionMeta.RightClickTrain))*5);
%         SendCustomPulseTrain(2, BpodSystem.Data.Custom.SessionMeta.LeftClickTrain, ones(1,length(BpodSystem.Data.Custom.SessionMeta.LeftClickTrain))*5);
    elseif TaskParameters.GUI.PlayStimulus == 3
        InitiatePsychtoolbox();
        BpodSystem.Data.Custom.SessionMeta.FreqStimulus = getFreqStimulus(BpodSystem.Data.Custom.SessionMeta.MaxSampleTime);
        PsychToolboxSoundServer('Load', 1, BpodSystem.Data.Custom.SessionMeta.FreqStimulus);
    end
end

%jackpot time
if  TaskParameters.GUI.Jackpot ==2 || TaskParameters.GUI.Jackpot ==3
    if sum(~isnan(trial_data.ChoiceLeft(1:iTrial)))>10
        TaskParameters.GUI.JackpotTime = max(TaskParameters.GUI.JackpotMin,quantile(trial_data.ST,0.95));
    else
        TaskParameters.GUI.JackpotTime = TaskParameters.GUI.JackpotMin;
    end
end
%%
%% REWARD

%% depletion
%if a random reward appears - it does not disrupt the previous depletion
%train and depletion is calculated by multiplying from the normal reward
%amount and not the surprise reward amount (e.g. reward amount for all
%right choices 25 - 20 -16- 12.8 - 10.24 -8.192 - 5.2429 - 37.5 - 4.194

if TaskParameters.GUI.Deplete
    if trial_data.RewardMagnitude(iTrial,:)>[TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount]
        if length(trial_data.ChoiceLeft)>1 && trial_data.ChoiceLeft(iTrial)==trial_data.ChoiceLeft(iTrial-1)
            DummyRewardMag=trial_data.RewardMagnitude(iTrial-1,:);
        else
            DummyRewardMag=[TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];
        end
        
    else
        DummyRewardMag=trial_data.RewardMagnitude(iTrial,:);
    end


    if  trial_data.ChoiceLeft(iTrial) == 1 && TaskParameters.GUI.Deplete
        trial_data.RewardMagnitude(iTrial+1,1) = DummyRewardMag(1,1)*TaskParameters.GUI.DepleteRateLeft;
        trial_data.RewardMagnitude(iTrial+1,2) = TaskParameters.GUI.rewardAmount;
    elseif trial_data.ChoiceLeft(iTrial) == 0 && TaskParameters.GUI.Deplete
        trial_data.RewardMagnitude(iTrial+1,2) = DummyRewardMag(1,2)*TaskParameters.GUI.DepleteRateRight;
        trial_data.RewardMagnitude(iTrial+1,1) = TaskParameters.GUI.rewardAmount;
    elseif isnan(trial_data.ChoiceLeft(iTrial)) && TaskParameters.GUI.Deplete
        trial_data.RewardMagnitude(iTrial+1,:) = trial_data.RewardMagnitude(iTrial,:);
    else
        trial_data.RewardMagnitude(iTrial+1,:) = [TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];
    end
end
%center port reward amount
trial_data.CenterPortRewAmount(iTrial+1) = TaskParameters.GUI.CenterPortRewAmount;

%increase sample time
if TaskParameters.GUI.AutoIncrSample
    History = 50; % Rat: History = 50
    Crit = 0.8; % Rat: Crit = 0.8
    if iTrial<5
        ConsiderTrials = iTrial;
    else
        ConsiderTrials = max(1,iTrial-History):1:iTrial;
    end
    ConsiderTrials = ConsiderTrials(~isnan(trial_data.ChoiceLeft(ConsiderTrials))|trial_data.EarlyWithdrawal(ConsiderTrials));
    if sum(~trial_data.EarlyWithdrawal(ConsiderTrials))/length(ConsiderTrials) > Crit % If SuccessRate > crit (80%)
        if ~trial_data.EarlyWithdrawal(iTrial) % If last trial is not EWD
            trial_data.SampleTime(iTrial+1) = min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,trial_data.SampleTime(iTrial) + TaskParameters.GUI.MinSampleIncr)); % SampleTime increased
        else % If last trial = EWD
            trial_data.SampleTime(iTrial+1) = min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,trial_data.SampleTime(iTrial))); % SampleTime = max(MinSampleTime or SampleTime)
        end
    elseif sum(~trial_data.EarlyWithdrawal(ConsiderTrials))/length(ConsiderTrials) < Crit/2  % If SuccessRate < crit/2 (40%)
        if trial_data.EarlyWithdrawal(iTrial) % If last trial = EWD
            trial_data.SampleTime(iTrial+1) = max(TaskParameters.GUI.MinSampleTime,min(TaskParameters.GUI.MaxSampleTime,trial_data.SampleTime(iTrial) - TaskParameters.GUI.MinSampleDecr)); % SampleTime decreased
        else
            trial_data.SampleTime(iTrial+1) = min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,trial_data.SampleTime(iTrial))); % SampleTime = max(MinSampleTime or SampleTime)
        end
    else % If crit/2 < SuccessRate < crit
        trial_data.SampleTime(iTrial+1) =  trial_data.SampleTime(iTrial); % SampleTime unchanged
    end
else
    trial_data.SampleTime(iTrial+1) = TaskParameters.GUI.MinSampleTime;
end
if trial_data.Jackpot(iTrial) % If last trial is Jackpottrial
    trial_data.SampleTime(iTrial+1) = trial_data.SampleTime(iTrial+1)+0.05*TaskParameters.GUI.JackpotTime; % SampleTime = SampleTime + 5% JackpotTime
end
TaskParameters.GUI.SampleTime = trial_data.SampleTime(iTrial+1); % update SampleTime

%send bpod status to server
% try
% script = 'receivebpodstatus.php';
% %create a common "outcome" vector
% outcome = trial_data.ChoiceLeft(1:iTrial); %1=left, 0=right
% outcome(trial_data.EarlyWithdrawal(1:iTrial)) = 3; %early withdrawal=3
% outcome(trial_data.Jackpot(1:iTrial)) = 4;%jackpot=4
% SendTrialStatusToServer(script,BpodSystem.Data.Info.Rig,outcome,BpodSystem.Data.Info.Subject,BpodSystem.CurrentProtocolName);
% catch
% end

BpodSystem.Data.Custom.TrialData = trial_data;

end