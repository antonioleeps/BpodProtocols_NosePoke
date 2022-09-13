function [RightClickTrain,LeftClickTrain]=GetClickStimulus(time)
rr = rand(1,1)*0.6+0.2;
l = ceil(rr*100);
r=100-l;
RightClickTrain=GeneratePoissonClickTrain(r,time);
LeftClickTrain=GeneratePoissonClickTrain(l,time);
end