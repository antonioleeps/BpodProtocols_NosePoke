function NosePoke_PlotSideOutcome(AxesHandle, Action, varargin)
% Plots choices made in each trial
% - Left and Right choices get green circles at top and bottom, resp.
% - Early withdrawals are cyan diamonds
% - Jackpots are red x's and appear alongside the left/right choice

global nTrialsToShow %this is for convenience
global BpodSystem

switch Action
    case 'init'
        %initialize pokes plot
        nTrialsToShow = 90; %default number of trials to display
        
        if nargin >= 3 %custom number of trials
            nTrialsToShow =varargin{1};
        end
        axes(AxesHandle);
        %plot in specified axes
        marksize = 10;
        yline(1, '--')
        yline(0.25, '--')
        BpodSystem.GUIHandles.CurrentTrialCircle = line(-1,0.5, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',marksize);
        BpodSystem.GUIHandles.CurrentTrialCross = line(-1,0.5, 'LineStyle','none','Marker','+','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',marksize);
        BpodSystem.GUIHandles.RewardedL = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace','g', 'MarkerSize',marksize);
        BpodSystem.GUIHandles.RewardedR = line(-1,0, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace','g', 'MarkerSize',marksize);
        BpodSystem.GUIHandles.EarlyWithdrawal = line(-1,0, 'LineStyle','none','Marker','d','MarkerEdge','k','MarkerFace','c', 'MarkerSize',marksize);
        BpodSystem.GUIHandles.Jackpot = line(-1,0, 'LineStyle','none','Marker','x','MarkerEdge','r','MarkerFace','r', 'MarkerSize',marksize);
        set(AxesHandle,'TickDir', 'out','YLim', [0.15, 1.1],'XLim',[0,nTrialsToShow], 'YTick', [0.25, 0.5, .75 1],'YTickLabel', {'Right', 'Abort', 'Jackpot', 'Left'}, 'FontSize', 16);
        xlabel(AxesHandle, 'Trial#', 'FontSize', 18);
        pos = get(gca, 'Position');
        set(gca, 'Position', [pos(1)+0.05 pos(2) pos(3)-0.05 pos(4)]);
        hold(AxesHandle, 'on');

        
    case 'update'
        CurrentTrial = varargin{1};
        ChoiceLeft = BpodSystem.Data.Custom.ChoiceLeft;
        
        % recompute xlim
        [mn, ~] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow);
        
        set(BpodSystem.GUIHandles.CurrentTrialCircle, 'xdata', CurrentTrial, 'ydata', .5);
        set(BpodSystem.GUIHandles.CurrentTrialCross, 'xdata', CurrentTrial, 'ydata', .5);
        
        %Plot past trials
        if ~isempty(ChoiceLeft)
            indxToPlot = mn:CurrentTrial-1;
            %Plot Rewarded Left
            ndxRwdL = ChoiceLeft(indxToPlot) == 1;
            Xdata = indxToPlot(ndxRwdL); 
            Ydata = ones(1,sum(ndxRwdL));
            set(BpodSystem.GUIHandles.RewardedL, 'xdata', Xdata, 'ydata', Ydata);
            
            %Plot Rewarded Right
            ndxRwdR = ChoiceLeft(indxToPlot) == 0;
            Xdata = indxToPlot(ndxRwdR); 
            Ydata = zeros(1,sum(ndxRwdR)) + 0.25;
            set(BpodSystem.GUIHandles.RewardedR, 'xdata', Xdata, 'ydata', Ydata);            
        end
        if ~isempty(BpodSystem.Data.Custom.EarlyWithdrawal)
            indxToPlot = mn:CurrentTrial-1;
            ndxEarly = BpodSystem.Data.Custom.EarlyWithdrawal(indxToPlot);
            XData = indxToPlot(ndxEarly);
            YData = 0.5*ones(1,sum(ndxEarly));
            set(BpodSystem.GUIHandles.EarlyWithdrawal, 'xdata', XData, 'ydata', YData);
        end
        if ~isempty(BpodSystem.Data.Custom.Jackpot)
            indxToPlot = mn:CurrentTrial-1;
            ndxJackpot = BpodSystem.Data.Custom.Jackpot(indxToPlot);
            XData = indxToPlot(ndxJackpot);
            YData = 0.75*ones(1,sum(ndxJackpot));
            set(BpodSystem.GUIHandles.Jackpot, 'xdata', XData, 'ydata', YData);
        end

end

end

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end


