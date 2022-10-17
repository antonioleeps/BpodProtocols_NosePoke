function sma = StateMatrix(iTrial)

global BpodSystem
global TaskParameters

% Define ports
LeftPort = floor(mod(TaskParameters.GUI.Ports_LMR/100,10));
CenterPort = floor(mod(TaskParameters.GUI.Ports_LMR/10,10));
RightPort = mod(TaskParameters.GUI.Ports_LMR,10);
LeftPortOut = strcat('Port',num2str(LeftPort),'Out');
CenterPortOut = strcat('Port',num2str(CenterPort),'Out');
RightPortOut = strcat('Port',num2str(RightPort),'Out');
LeftPortIn = strcat('Port',num2str(LeftPort),'In');
CenterPortIn = strcat('Port',num2str(CenterPort),'In');
RightPortIn = strcat('Port', num2str(RightPort),'In');

LeftValve = 2^(LeftPort-1);
CenterValve = 2^(CenterPort-1);
RightValve = 2^(RightPort-1);

% random reward - no change in state matrix, changes RewardMagnitude on a trial by trial basis

if TaskParameters.GUI.RandomReward == true && BpodSystem.Data.Custom.TrialData.RandomThresholdPassed(iTrial)==1
    surpriseRewardAmount=TaskParameters.GUI.rewardAmount*TaskParameters.GUI.RandomRewardMultiplier;
    BpodSystem.Data.Custom.TrialData.RewardMagnitude(iTrial,:)= [TaskParameters.GUI.rewardAmount, TaskParameters.GUI.rewardAmount]+surpriseRewardAmount;
else
    BpodSystem.Data.Custom.TrialData.RewardMagnitude(iTrial,:)=BpodSystem.Data.Custom.TrialData.RewardMagnitude(iTrial,:);
    
end

LeftValveTime  = GetValveTimes(BpodSystem.Data.Custom.TrialData.RewardMagnitude(iTrial,1), LeftPort);
if rand(1,1) <= TaskParameters.GUI.CenterPortProb && TaskParameters.GUI.Jackpot == 4
    CenterValveTime  = min([0.1,max([0.001,GetValveTimes(BpodSystem.Data.Custom.TrialData.CenterPortRewAmount(iTrial), CenterPort)])]);
else
    CenterValveTime=0;
end
RightValveTime  = GetValveTimes(BpodSystem.Data.Custom.TrialData.RewardMagnitude(iTrial,2), RightPort);

if TaskParameters.GUI.Jackpot == 3 % Decremental Jackpot reward
    JackpotFactor = max(2,10 - sum(BpodSystem.Data.Custom.TrialData.Jackpot)); 
else 
    JackpotFactor = 2; % Fixed Jackpot reward
end
LeftValveTimeJackpot  = JackpotFactor*GetValveTimes(BpodSystem.Data.Custom.TrialData.RewardMagnitude(iTrial,1), LeftPort);
RightValveTimeJackpot  = JackpotFactor*GetValveTimes(BpodSystem.Data.Custom.TrialData.RewardMagnitude(iTrial,2), RightPort);

if TaskParameters.GUI.PlayStimulus == 1 %no
    StimStartOutput = {};
    StimStart2Output = {};
    StimStopOutput = {};
elseif TaskParameters.GUI.PlayStimulus == 2 %click
    StimStartOutput = {'BNCState',1};
    StimStart2Output = {'BNCState',1};
    StimStopOutput = {'BNCState',0};
% elseif TaskParameters.GUI.PlayStimulus == 3 %freq
%     StimStartOutput = {'SoftCode',21};
%     StimStopOutput = {'SoftCode',22};
%     StimStart2Output = {};
end

if TaskParameters.GUI.EarlyWithdrawalNoise
    PunishSoundIndex=1;
else
    PunishSoundIndex=0;
end

%light guided task
if TaskParameters.GUI.LightGuided 
    if BpodSystem.Data.Custom.TrialData.LightLeft(iTrial)
        LeftLight=255;
        RightLight = 0;
    elseif ~BpodSystem.Data.Custom.TrialData.LightLeft(iTrial)
        LeftLight=0;
        RightLight=255;
    else
        error('Light guided state matrix error');
    end
else
    LeftLight=255;
    RightLight=255;
end

% reward available?
RightWaitAction = 'ITI';
LeftWaitAction = 'ITI';

if BpodSystem.Data.Custom.TrialData.RewardAvailable(iTrial) && TaskParameters.GUI.RandomReward==true
    DelayTime = BpodSystem.Data.Custom.TrialData.RewardDelay(iTrial);
    %dummy state added for plotting
    if TaskParameters.GUI.LightGuided && BpodSystem.Data.Custom.TrialData.LightLeft(iTrial)
        LeftWaitAction = 'RandomReward_water_L';
    elseif TaskParameters.GUI.LightGuided && ~BpodSystem.Data.Custom.TrialData.LightLeft(iTrial)
        RightWaitAction = 'RandomReward_water_R';
    else
        LeftWaitAction = 'water_L';
        RightWaitAction = 'water_R';
    end 
elseif BpodSystem.Data.Custom.TrialData.RewardAvailable(iTrial) && TaskParameters.GUI.RandomReward==false
    DelayTime = BpodSystem.Data.Custom.TrialData.RewardDelay(iTrial);
    if TaskParameters.GUI.LightGuided && BpodSystem.Data.Custom.TrialData.LightLeft(iTrial)
        LeftWaitAction = 'water_L';
    elseif TaskParameters.GUI.LightGuided && ~BpodSystem.Data.Custom.TrialData.LightLeft(iTrial)
        RightWaitAction = 'water_R';
    else
        LeftWaitAction = 'water_L';
        RightWaitAction = 'water_R';
    end
else
    DelayTime = 30;
end

    
    
sma = NewStateMatrix();
sma = SetGlobalTimer(sma,1,TaskParameters.GUI.SampleTime);
sma = SetGlobalTimer(sma,2,DelayTime);
sma = AddState(sma, 'Name', 'state_0',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'PreITI'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'PreITI',...
    'Timer', TaskParameters.GUI.PreITI,...
    'StateChangeConditions', {'Tup', 'wait_Cin'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'wait_Cin',...
    'Timer', 0,...
    'StateChangeConditions', {CenterPortIn, 'StartSampling'},...
    'OutputActions', {strcat('PWM',num2str(CenterPort)),255});

sma = AddState(sma, 'Name', 'StartSampling',...
    'Timer', 0.01,...
    'StateChangeConditions', {'Tup', 'Sampling'},...S
    'OutputActions', {'GlobalTimerTrig',1});
sma = AddState(sma, 'Name', 'Sampling',...
    'Timer', TaskParameters.GUI.SampleTime,...
    'StateChangeConditions', {CenterPortOut, 'GracePeriod','Tup','stillSampling','GlobalTimer1_End','stillSampling'},...
    'OutputActions', StimStartOutput);
sma = AddState(sma, 'Name', 'GracePeriod',...
    'Timer', TaskParameters.GUI.GracePeriod,...
    'StateChangeConditions', {CenterPortIn, 'Sampling','Tup','EarlyWithdrawal','GlobalTimer1_End','EarlyWithdrawal',LeftPortIn,'EarlyWithdrawal',RightPortIn,'EarlyWithdrawal'},...
    'OutputActions',{});

%% jackpot
if TaskParameters.GUI.Jackpot == 1 % Jackpot == none
    sma = AddState(sma, 'Name', 'stillSampling',...
        'Timer', TaskParameters.GUI.ChoiceDeadline,...
        'StateChangeConditions', {CenterPortOut, 'stop_stim','Tup','stop_stim'},...
        'OutputActions', StimStart2Output);
    sma = AddState(sma, 'Name', 'stop_stim',...
        'Timer',0.001,...
        'StateChangeConditions', {'Tup','wait_Sin'},...
        'OutputActions',[StimStopOutput {strcat('PWM',num2str(LeftPort)),255,strcat('PWM',num2str(RightPort)),255}]);
elseif TaskParameters.GUI.Jackpot == 2 || TaskParameters.GUI.Jackpot == 3 % Jackpot activated (either Fixed or Decremental)
    sma = AddState(sma, 'Name', 'stillSampling',...
        'Timer', TaskParameters.GUI.JackpotTime-TaskParameters.GUI.SampleTime,...
        'StateChangeConditions', {CenterPortOut, 'stop_stim','Tup','stillSamplingJackpot'},...
        'OutputActions', StimStart2Output);
    sma = AddState(sma, 'Name', 'stillSamplingJackpot',...
        'Timer', TaskParameters.GUI.ChoiceDeadline-TaskParameters.GUI.JackpotTime-TaskParameters.GUI.SampleTime,...
        'StateChangeConditions', {CenterPortOut, 'stop_stim_jackpot','Tup','ITI'},...
        'OutputActions', StimStart2Output);
    sma = AddState(sma, 'Name', 'stop_stim_jackpot',...
        'Timer',0.001,...
        'StateChangeConditions', {'Tup','wait_SinJackpot'},...
        'OutputActions',[StimStopOutput {strcat('PWM',num2str(LeftPort)),255,strcat('PWM',num2str(RightPort)),255}]);
    sma = AddState(sma, 'Name', 'stop_stim',...
        'Timer',0.001,...
        'StateChangeConditions', {'Tup','wait_Sin'},...
        'OutputActions',[StimStopOutput {strcat('PWM',num2str(LeftPort)),255,strcat('PWM',num2str(RightPort)),255}]);
elseif TaskParameters.GUI.Jackpot ==4 % 
    sma = AddState(sma, 'Name', 'stillSampling',...
        'Timer', CenterValveTime,...
        'StateChangeConditions', {'Tup','lat_Go_signal'},...
        'OutputActions', [StimStopOutput {'ValveState', CenterValve}]);
    sma = AddState(sma, 'Name', 'lat_Go_signal',...
        'Timer',0.001,...
        'StateChangeConditions', {'Tup','wait_Sin'},...
        'OutputActions',{strcat('PWM',num2str(LeftPort)),LeftLight,strcat('PWM',num2str(RightPort)),RightLight});
end

%%
sma = AddState(sma, 'Name', 'wait_Sin',...
    'Timer',TaskParameters.GUI.ChoiceDeadline,...
    'StateChangeConditions', {LeftPortIn,'wait_L_start',RightPortIn,'wait_R_start','Tup','ITI'},...
    'OutputActions',{strcat('PWM',num2str(LeftPort)),LeftLight,strcat('PWM',num2str(RightPort)),RightLight});
sma = AddState(sma, 'Name', 'wait_L_start',...
    'Timer',0,...
    'StateChangeConditions', {'Tup','wait_L'},...
    'OutputActions',{'GlobalTimerTrig',2});
sma = AddState(sma, 'Name', 'wait_L',...
    'Timer',DelayTime,...
    'StateChangeConditions', {'Tup',LeftWaitAction,'GlobalTimer2_End',LeftWaitAction,LeftPortOut,'wait_L_grace'},...
    'OutputActions',{strcat('PWM',num2str(LeftPort)),0});
sma = AddState(sma, 'Name', 'wait_L_grace',...
    'Timer',TaskParameters.GUI.DelayGracePeriod,...
    'StateChangeConditions', {'Tup','ITI','GlobalTimer2_End',LeftWaitAction,LeftPortIn,'wait_L'},...
    'OutputActions',{});
sma = AddState(sma, 'Name', 'wait_R_start',...
    'Timer',0,...
    'StateChangeConditions', {'Tup','wait_R'},...
    'OutputActions',{'GlobalTimerTrig',2});
sma = AddState(sma, 'Name', 'wait_R',...
    'Timer',DelayTime,...
    'StateChangeConditions', {'Tup',RightWaitAction,'GlobalTimer2_End',RightWaitAction,RightPortOut,'wait_R_grace'},...
    'OutputActions',{strcat('PWM',num2str(RightPort)),0});
sma = AddState(sma, 'Name', 'wait_R_grace',...
    'Timer',TaskParameters.GUI.DelayGracePeriod,...
    'StateChangeConditions', {'Tup','ITI','GlobalTimer2_End',RightWaitAction,RightPortIn,'wait_R'},...
    'OutputActions',{});

%% water rewards and grace period for drinking

%dummy states for photometry alignment
sma = AddState(sma, 'Name', 'RandomReward_water_L',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','water_L'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'RandomReward_water_R',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','water_R'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'water_L',...
    'Timer', LeftValveTime,...
    'StateChangeConditions', {'Tup','DrinkingL'},...
    'OutputActions', {'ValveState', LeftValve});
sma = AddState(sma, 'Name', 'water_R',...
    'Timer', RightValveTime,...
    'StateChangeConditions', {'Tup','DrinkingR'},...
    'OutputActions', {'ValveState', RightValve});


sma = AddState(sma, 'Name', 'DrinkingL',...
    'Timer', TaskParameters.GUI.DrinkingTime,...
    'StateChangeConditions', {'Tup','ITI', LeftPortOut,  'DrinkingGraceL'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'DrinkingR',...
    'Timer', TaskParameters.GUI.DrinkingTime,...
    'StateChangeConditions', {'Tup','ITI', RightPortOut, 'DrinkingGraceR'},...
    'OutputActions', {});


sma = AddState(sma, 'Name', 'DrinkingGraceR',...
    'Timer', TaskParameters.GUI.DrinkingGrace,...
    'StateChangeConditions', {'Tup','ITI', RightPortIn, 'DrinkingR'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'DrinkingGraceL',...
    'Timer', TaskParameters.GUI.DrinkingGrace,...
    'StateChangeConditions', {'Tup','ITI', LeftPortIn, 'DrinkingL'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'wait_SinJackpot',...
    'Timer',TaskParameters.GUI.ChoiceDeadline,...
    'StateChangeConditions', {LeftPortIn,'water_LJackpot',RightPortIn,'water_RJackpot','Tup','ITI'},...
    'OutputActions',{strcat('PWM',num2str(LeftPort)),255,strcat('PWM',num2str(RightPort)),255});
sma = AddState(sma, 'Name', 'water_LJackpot',...
    'Timer', LeftValveTimeJackpot,...
    'StateChangeConditions', {'Tup','DrinkingL'},...
    'OutputActions', {'ValveState', LeftValve});
sma = AddState(sma, 'Name', 'water_RJackpot',...
    'Timer', RightValveTimeJackpot,...
    'StateChangeConditions', {'Tup','DrinkingR'},...
    'OutputActions', {'ValveState', RightValve});
sma = AddState(sma, 'Name', 'EarlyWithdrawal',...
    'Timer', TaskParameters.GUI.EarlyWithdrawalTimeOut,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'WavePlayer1',PunishSoundIndex});
%     'OutputActions', {'SoftCode',PunishSoundAction});
if TaskParameters.GUI.VI
    sma = AddState(sma, 'Name', 'ITI',...
        'Timer',exprnd(TaskParameters.GUI.FI),...
        'StateChangeConditions',{'Tup','exit'},...
        'OutputActions',{});
else
    sma = AddState(sma, 'Name', 'ITI',...
        'Timer',TaskParameters.GUI.FI,...
        'StateChangeConditions',{'Tup','exit'},...
        'OutputActions',{});
end

end % StateMatrix
