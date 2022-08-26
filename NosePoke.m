function NosePoke()
% Learning to Nose Poke side ports

global BpodSystem
global TaskParameters


TaskParameters = GUISetup();  % Set experiment parameters in GUISetup.m

%% Initializing data (trial type) vectors and first values
BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.SampleTime(1) = TaskParameters.GUI.MinSampleTime;
BpodSystem.Data.Custom.EarlyWithdrawal(1) = false;
BpodSystem.Data.Custom.Jackpot(1) = false;
BpodSystem.Data.Custom.RewardMagnitude = [TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);
%server data
[~,BpodSystem.Data.Custom.Rig] = system('hostname');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.Path.CurrentDataFile))));
BpodSystem.Data.Custom.PsychtoolboxStartup=false;
BpodSystem.Data.Custom.MaxSampleTime = 1; %only relevant for max stimulus length
[BpodSystem.Data.Custom.RightClickTrain,BpodSystem.Data.Custom.LeftClickTrain] = getClickStimulus(BpodSystem.Data.Custom.MaxSampleTime);
BpodSystem.Data.Custom.FreqStimulus = getFreqStimulus(BpodSystem.Data.Custom.MaxSampleTime);

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';

%% Configuring PulsePal
%% Configuring PulsePal
% load PulsePalParamStimulus.mat
% load PulsePalParamFeedback.mat
% BpodSystem.Data.Custom.PulsePalParamStimulus=PulsePalParamStimulus;
% BpodSystem.Data.Custom.PulsePalParamFeedback=PulsePalParamFeedback;
% clear PulsePalParamFeedback PulsePalParamStimulus
% if ~BpodSystem.EmulatorMode
%     ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamStimulus);
%     SendCustomPulseTrain(1, BpodSystem.Data.Custom.RightClickTrain, ones(1,length(BpodSystem.Data.Custom.RightClickTrain))*5);
%     SendCustomPulseTrain(2, BpodSystem.Data.Custom.LeftClickTrain, ones(1,length(BpodSystem.Data.Custom.LeftClickTrain))*5); 
%     if TaskParameters.GUI.PlayStimulus == 3
%         InitiatePsychtoolbox();
%         PsychToolboxSoundServer('Load', 1, BpodSystem.Data.Custom.FreqStimulus);
%     end
% end


%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [200 200 1000, 300] , 'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .3 .89 .6]);
NosePoke_PlotSideOutcome(BpodSystem.GUIHandles.SideOutcomePlot,'init');

% BpodNotebook('init');

%% ------------------------------Main loop------------------------------ %%
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    InitiatePsychtoolbox();
    
    sma = StateMatrix(iTrial);
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
    
    UpdateCustomDataFields(iTrial);
    NosePoke_PlotSideOutcome(BpodSystem.GUIHandles.SideOutcomePlot,'update',iTrial);
    iTrial = iTrial + 1;
    
end  % Main loop
end  % NosePoke()





function [RightClickTrain,LeftClickTrain]=getClickStimulus(time)
rr = rand(1,1)*0.6+0.2;
l = ceil(rr*100);
r=100-l;
RightClickTrain=GeneratePoissonClickTrain(r,time);
LeftClickTrain=GeneratePoissonClickTrain(l,time);
end

function Sound = getFreqStimulus(time)
StimulusSettings=struct();
            StimulusSettings.SamplingRate = 192000; % Sound card sampling rate;
            StimulusSettings.ramp = 0.003;
            StimulusSettings.nFreq = 18; % Number of different frequencies to sample from
            StimulusSettings.ToneOverlap = 0.6667;
            StimulusSettings.ToneDuration = 0.03;
            StimulusSettings.Noevidence=0;
            StimulusSettings.minFreq = 5000 ;
            StimulusSettings.maxFreq = 40000 ;
            StimulusSettings.UseMiddleOctave=0;
            StimulusSettings.Volume=50;
            StimulusSettings.nTones = floor((time-StimulusSettings.ToneDuration*StimulusSettings.ToneOverlap)/(StimulusSettings.ToneDuration*(1-StimulusSettings.ToneOverlap))); %number of tones
            newFracHigh = rand(1,1);
            [Sound, ~, ~] = GenerateToneCloudDual(newFracHigh, StimulusSettings);
end