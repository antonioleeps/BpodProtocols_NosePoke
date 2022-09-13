function InitializeCustomDataFields()
%{ 
Initializing data (trial type) vectors and first values
%}

global BpodSystem
global TaskParameters


BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.SampleTime(1) = TaskParameters.GUI.MinSampleTime;
BpodSystem.Data.Custom.EarlyWithdrawal(1) = false;
BpodSystem.Data.Custom.Jackpot(1) = false;

BpodSystem.Data.Custom.RandomReward=TaskParameters.GUI.RandomReward;
BpodSystem.Data.Custom.RandomThresholdPassed(1)=0;
BpodSystem.Data.Custom.RandomRewardProb=TaskParameters.GUI.RandomRewardProb;
BpodSystem.Data.Custom.RandomRewardAmount=TaskParameters.GUI.RandomRewardMultiplier*[TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];

BpodSystem.Data.Custom.RewardMagnitude = [TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];
BpodSystem.Data.Custom.CenterPortRewAmount =TaskParameters.GUI.CenterPortRewAmount;
BpodSystem.Data.Custom.Rewarded = false;
BpodSystem.Data.Custom.CenterPortRewarded = false;
BpodSystem.Data.Custom.GracePeriod = 0;
BpodSystem.Data.Custom.LightLeft = rand(1,1)<0.5;
BpodSystem.Data.Custom.RewardAvailable = rand(1,1)<TaskParameters.GUI.RewardProb;
BpodSystem.Data.Custom.RewardDelay = TaskParameters.GUI.DelayMean;
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);
%server data
[~,BpodSystem.Data.Custom.Rig] = system('hostname');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.Path.CurrentDataFile))));
BpodSystem.Data.Custom.PsychtoolboxStartup=false;
BpodSystem.Data.Custom.MaxSampleTime = 1; %only relevant for max stimulus length
[BpodSystem.Data.Custom.RightClickTrain,BpodSystem.Data.Custom.LeftClickTrain] = GetClickStimulus(BpodSystem.Data.Custom.MaxSampleTime);
BpodSystem.Data.Custom.FreqStimulus = GetFreqStimulus(BpodSystem.Data.Custom.MaxSampleTime);

end