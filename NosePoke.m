function NosePoke()
% Learning to Nose Poke side ports

global BpodSystem
global TaskParameters
global nidaq

TaskParameters = GUISetup();  % Set experiment parameters in GUISetup.m

InitializeCustomDataFields(); % Initialize data (trial type) vectors and first values

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';

%% Configuring PulsePal
load PulsePalParamStimulus.mat
load PulsePalParamFeedback.mat
BpodSystem.Data.Custom.PulsePalParamStimulus=PulsePalParamStimulus;
BpodSystem.Data.Custom.PulsePalParamFeedback=PulsePalParamFeedback;
clear PulsePalParamFeedback PulsePalParamStimulus
if ~BpodSystem.EmulatorMode
%     ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamStimulus);
%     SendCustomPulseTrain(1, BpodSystem.Data.Custom.RightClickTrain, ones(1,length(BpodSystem.Data.Custom.RightClickTrain))*5);
%     SendCustomPulseTrain(2, BpodSystem.Data.Custom.LeftClickTrain, ones(1,length(BpodSystem.Data.Custom.LeftClickTrain))*5); 
    if TaskParameters.GUI.PlayStimulus == 3
        InitiatePsychtoolbox();
        PsychToolboxSoundServer('Load', 1, BpodSystem.Data.Custom.FreqStimulus);
    end
end

InitializePlots();

if TaskParameters.GUI.Photometry
    [FigNidaq1,FigNidaq2]=InitializeNidaq();
end

%% --------------------------Main loop------------------------------ %%
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    InitiatePsychtoolbox();
    
    sma = StateMatrix(iTrial);
    SendStateMatrix(sma);
    
    %% NIDAQ Get nidaq ready to start
    if TaskParameters.GUI.Photometry
        Nidaq_photometry('WaitToStart');
    end
    
    %% Run Trial
    RawEvents = RunStateMatrix;
    
    %% NIDAQ Stop acquisition and save data in bpod structure
    if TaskParameters.GUI.Photometry
        Nidaq_photometry('Stop');
        [PhotoData,Photo2Data]=Nidaq_photometry('Save');
        BpodSystem.Data.NidaqData{iTrial}=PhotoData;
        if TaskParameters.GUI.DbleFibers || TaskParameters.GUI.RedChannel
            BpodSystem.Data.Nidaq2Data{iTrial}=Photo2Data;
        end
        PlotPhotometryData(FigNidaq1, FigNidaq2, PhotoData, Photo2Data);
    end
    
    %% Bpod save
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end

    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.

    if BpodSystem.Status.BeingUsed == 0
        return
    end
    
    %% update fields
    UpdateCustomDataFields(iTrial)
    
    %% update figures
    NosePoke_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot,'update',iTrial);

    iTrial = iTrial + 1;    
end % Main loop

if TaskParameters.GUI.Photometry
    CheckPhotometry(PhotoData, Photo2Data);
end

end % NosePoke()