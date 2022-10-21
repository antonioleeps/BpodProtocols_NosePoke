function [LeftClickTrain,RightClickTrain] = GetClickStimulus(Duration, SamplingRate, ClickLength, Mode)

global TaskParameters
global BpodSystem

if nargin<4
    Mode = 'uniform';
end
if nargin<3
    ClickLength = 1;
end
if nargin<2
    SamplingRate = 25000; % in Hz
end
if nargin<1
    Duration = 1; % in seconds
end

% draw ClickRate for left and right sound
switch Mode
    case 'uniform'
        rr = rand(1,1)*0.6+0.2;
        LeftClickRate = ceil(rr*100);
        RightClickRate = 100 - LeftClickRate;
    case 'beta'
        BpodSystem.Data.Custom.AuditoryOmega(a) = betarnd(TaskParameters.GUI.AuditoryAlpha/4,TaskParameters.GUI.AuditoryAlpha/4,1,1);
        LeftClickRate = round(BpodSystem.Data.Custom.AuditoryOmega(a)*TaskParameters.GUI.SumRates);
        RightClickRate = TaskParameters.GUI.SumRates - LeftClickRate;
end

LeftClickTrain = GeneratePoissonClickTrain(LeftClickRate, Duration, SamplingRate, ClickLength);
RightClickTrain = GeneratePoissonClickTrain(RightClickRate, Duration, SamplingRate, ClickLength);

end