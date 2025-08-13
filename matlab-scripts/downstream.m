combineMonkeyLogicCodes('PIP_25TD0812-CALIBRATION-run01.bhv2');
function combineMonkeyLogicCodes(bhvFile)
% combineMonkeyLogicCodes Reads a MonkeyLogic data file and exports a final CSV file
% with seven columns:
%
%   Trial, AbsCodeTime, CodeNumber, Event_Type, TTL_pulse_start, MissingCode, TotalFixationDuration
%
% For each trial, the function computes an absolute timeline by adding a cumulative
% offset (derived from each trial's duration). It then:
%
%   1. Scans the analog data (data(trialIdx).AnalogData.Button.Btn1) for TTL pulses,
%      defined as a contiguous series of 1’s. For each pulse, it computes the absolute 
%      rising (start) and falling (end) edges.
%
%   2. It checks whether any behavioral event (from BehavioralCodes) with code 50 or 
%      51 (after adding the offset) occurs between the pulse’s start and end.
%
%   3. If no such event is found, it writes a row (with the behavioral columns blank) 
%      with the TTL pulse start in the fifth column, MissingCode set to 52, and Event_Type 
%      set to "TTL_ITI" in the fourth column.
%
%   4. Then, it writes all behavioral events (with absolute timestamps) as rows.
%      For each behavioral event, the Event_Type column is determined by mapping the 
%      CodeNumber to a corresponding string (e.g., 9 -> "Trial_Start", 0 -> "Baseline_onset",
%      1 -> "Stimulus_onset", etc.). Additionally, if the code is 0 the FixationDuration 
%      column is filled with FixTime_baseline (from UserVars); if the code is 1, it is filled
%      with FixTime_stim; otherwise, that column is left blank.
%
% The missing TTL pulse rows are output first for each trial.
%
% USAGE:
%   combineMonkeyLogicCodes('250321_PIP_GenCond_OnlyChecker_withITIrec.bhv2')
%
% REQUIRES:
%   MonkeyLogic’s mlread function must be on the MATLAB path.

    % Define the code number list and the corresponding event types. 
    CODENUM_LIST = [9, 11, 24, 21, 17, 8, 6, 15, 18, 52];
    EVENTTYPE_LIST = ["Trial_Start", "TTL_onset", "Baseline_onset", "TTL_pulse", ...
        "Reward", "Juice", "Stimulus_onset", "Punish", "Trial_End", "TTL_ITI"];
    event_dict = dictionary(CODENUM_LIST,EVENTTYPE_LIST);
    TTL_threshold = 0.05;

    % Read the data file (supports .bhv2, .bhvz, .h5, .mat, etc.)
    data = mlread(bhvFile);
    
    % Create output CSV file name by replacing .bhv2 with .csv
    [filepath, name, ext] = fileparts(bhvFile);
    outputCSV = fullfile(filepath, [name '.csv']);
    
    % Open the final output CSV file for writing.
    fid = fopen(outputCSV, 'w');
    if fid == -1
        error('Could not open %s for writing.', outputCSV);
    end
    % Write CSV header (7 columns)
    % Columns: Trial, AbsCodeTime, CodeNumber, Event_Type, TTL_pulse_start, MissingCode, FixationDuration
    fprintf(fid, 'Trial,AbsCodeTime,CodeNumber,Event_Type,TTL_pulse_start,MissingCode,TotalFixationDuration\n');
    
    % Initialize cumulative offset (in ms).
    cumulativeOffset = 0;
    numTrials = numel(data);
    
    for trialIdx = 1:numTrials
        % Determine trial duration (in ms)
        if isfield(data(trialIdx), 'AnalogData') && ...
           isfield(data(trialIdx).AnalogData, 'Button') && ...
           isfield(data(trialIdx).AnalogData.Button, 'Btn1')
            trialDuration = length(data(trialIdx).AnalogData.Button.Btn1);
        else
            if isfield(data(trialIdx), 'BehavioralCodes') && ...
               isfield(data(trialIdx).BehavioralCodes, 'CodeTimes') && ...
               ~isempty(data(trialIdx).BehavioralCodes.CodeTimes)
                trialDuration = max(data(trialIdx).BehavioralCodes.CodeTimes);
            else
                trialDuration = 0;
            end
        end
        
        % Extract Behavioral Events for the trial
        codeTimes = [];
        codeNumbers = [];
        if isfield(data(trialIdx), 'BehavioralCodes')
            codes = data(trialIdx).BehavioralCodes;
            if isfield(codes, 'CodeTimes') && isfield(codes, 'CodeNumbers')
                codeTimes = codes.CodeTimes;
                codeNumbers = codes.CodeNumbers;
            end
        end
        % Adjust behavioral event times to absolute times.
        adjustedCodeTimes = [];
        if ~isempty(codeTimes)
            adjustedCodeTimes = codeTimes + cumulativeOffset;
        end
        
        % Retrieve Fixation Times from UserVars (if available)
        % We expect fields FixTime_baseline and FixTime_stim in UserVars.
        fixTime_baseline = [];
        fixTime_stim = [];
        if isfield(data(trialIdx), 'UserVars')
            userVars = data(trialIdx).UserVars;
            if isfield(userVars, 'FixTime_baseline')
                fixTime_baseline = userVars.FixTime_baseline;
            end
            if isfield(userVars, 'FixTime_stim')
                fixTime_stim = userVars.FixTime_stim;
            end
        end
        
        % Process TTL Pulses from Analog Data (Button.Btn1)
        if isfield(data(trialIdx), 'AnalogData') && ...
           isfield(data(trialIdx).AnalogData, 'Button') && ...
           isfield(data(trialIdx).AnalogData.Button, 'Btn1')
       
            btnData = data(trialIdx).AnalogData.Button.Btn1;
            btnData = btnData(:);  % Ensure column vector
            
            % Detect rising edges (pulse start) and falling edges (pulse end)
            risingEdges = find(diff([0; btnData]) == 1);
            fallingEdges = find(diff([btnData; 0]) == -1);
            
            % Use the minimum number of pulses if counts differ.
            nPulses = min(length(risingEdges), length(fallingEdges));
            
            for p = 1:nPulses
                absTTLStart = risingEdges(p) + cumulativeOffset;
                % Compute falling edge time (though not output here)
                absTTLEnd   = fallingEdges(p) + cumulativeOffset;
                
                % Check if any behavioral event with code 11 or 21 falls in [absTTLStart, absTTLEnd]
                if isempty(adjustedCodeTimes)
                    eventMatch = false;
                else
                    eventMatch = any(adjustedCodeTimes >= absTTLStart & adjustedCodeTimes <= absTTLEnd & ...
                                     (codeNumbers == 11 | codeNumbers == 21));
                end
                
                % If no matching event is found, output the missing TTL row.
                if ~eventMatch
                    % Write a row with: Trial, (empty AbsCodeTime), (empty CodeNumber),
                    % Event_Type = "TTL_ITI", TTL_pulse_start, MissingCode = 52, (empty FixationDuration)
                    fprintf(fid, '\n%d,,,%s,%g,%d,\n', trialIdx, 'TTL_ITI', absTTLStart, 52);
                end
            end
        end
        
        % Process Behavioral Events (write each row)
        if ~isempty(codeTimes) && ~isempty(codeNumbers)
            if numel(codeTimes) ~= numel(codeNumbers)
                warning('Trial %d: Mismatched CodeTimes and CodeNumbers; skipping behavioral events.', trialIdx);
            else
                % get start_time, end_time for ploting graphs
                start_time = codeTimes(1) + cumulativeOffset;
                end_time = (codeTimes(end) - codeTimes(1)) / 1000;
                reward_list = {};
                punish_list = {};
                ttl_list = {};

                for i = 1:numel(codeTimes)
                    absTime = codeTimes(i) + cumulativeOffset;
                    % Determine Event_Type using a switch-case based on codeNumbers(i)
                    eventType = lookup(event_dict, codeNumbers(i), FallbackValue='');
                    
                    % Determine fixation duration based on event code:
                    % If code is 24, use FixTime_baseline; if 6, use FixTime_stim; otherwise, leave blank.
                    if codeNumbers(i) == 24 && ~isempty(fixTime_baseline)
                        fixDuration = fixTime_baseline;
                        baseline_start = (absTime - start_time) / 1000;
                    elseif codeNumbers(i) == 6 && ~isempty(fixTime_stim)
                        fixDuration = fixTime_stim;
                        baseline_end = (absTime - start_time) / 1000;
                        stimulus_start = (absTime - start_time) / 1000;
                        stimulus_end = end_time;
                    else
                        fixDuration = [];
                        % if 15, add to punish list
                        if codeNumbers(i) == 15
                            punish_list{end+1} = (absTime - start_time) / 1000;
                        % if 17, add to reward list
                        elseif codeNumbers(i) == 17
                            reward_list{end+1} = (absTime - start_time) / 1000;
                        elseif codeNumbers(i) == 11
                            ttl_list{end+1} = (absTime - start_time) / 1000;
                        elseif codeNumbers(i) == 21
                            temp = (absTime - start_time) / 1000;
                            
                            % sometimes TTL will have 2 events happened
                            % simutaneously. 
                            if (temp - ttl_list{end} > TTL_threshold)
                                    ttl_list{end+1} = temp;
                            else
                                warning('Trial %d: same TTL event at %d, skip this event\n.', trialIdx, ttl_list{end});
                                continue;
                            end
                        end
                    end
                    
                    % Write behavioral event row:
                    % Columns: Trial, AbsCodeTime, CodeNumber, Event_Type, (empty TTL_pulse_start), (empty MissingCode), FixationDuration.
                    if isempty(fixDuration)
                        fprintf(fid, '%d,%g,%d,%s,,,\n', trialIdx, absTime, codeNumbers(i), eventType);
                    else
                        fprintf(fid, '%d,%g,%d,%s,,,%g\n', trialIdx, absTime, codeNumbers(i), eventType, fixDuration);
                    end
                end

                % plot the graphs
                % plot_graphs_for_current_trial(trialIdx, end_time, baseline_start, baseline_end, stimulus_start, stimulus_end, reward_list, punish_list, ttl_list);
            end
        end
        
        % Update cumulative offset for next trial.
        cumulativeOffset = cumulativeOffset + trialDuration;
    end
    
    fclose(fid);
    fprintf('Final export complete! Data written to: %s\n', outputCSV);
end




function plot_graphs_for_current_trial(trialIdx, end_time, baseline_start, baseline_end, stimulus_start, stimulus_end, reward_list, punish_list, ttl_list)
    % graph calculation
    t = linspace(-0.1, end_time+0.1, 1000);
    baseline_signal = zeros(size(t));
    baseline_signal(t >= baseline_start & t <= baseline_end) = 1;

    stimulus_signal = zeros(size(t));
    stimulus_signal(t >= stimulus_start & t <= stimulus_end) = 1;

    trial_start_signal = zeros(size(t));
    trial_start_signal(t >=-0.01 & t <= 0.01) = 1;

    trial_end_signal = zeros(size(t));
    trial_end_signal(t >= end_time-0.01 & t <= end_time+0.01) = 1;

    % temporarily diable figures being visible
    set(0,'DefaultFigureVisible','off');

    % plot the trial start and end graph
    figure;
    plot(t, trial_start_signal, t, trial_end_signal, LineWidth=2);
    ylim([-0.2 1.2]); 
    xlim([-1, end_time+1]);
    xlabel('Time (s)');
    ylabel('Pulse');
    title('Trial Start & End Signal');
    legend({'Trial Start','Trial End'},'Location','northwest','Orientation','vertical');
    saveas(gcf, sprintf('Trial-%d-Trial-Start-End-Signal.png', trialIdx));

    % plot the reward graph
    reward_graph_data = ones(size(reward_list));
    figure;
    stem(cell2mat(reward_list), reward_graph_data);
    xlim([-1, end_time+1]);
    ylim([-0.2 1.2]); 
    xlabel('Time (s)');
    ylabel('Reward');
    title('Reward Signal');
    legend({'Reward'},'Location','northwest','Orientation','vertical');
    saveas(gcf, sprintf('Trial-%d-Reward-Signal.png', trialIdx));

    % plot the punish graph
    punish_graph_data = ones(size(punish_list));
    figure;
    stem(cell2mat(punish_list), punish_graph_data);
    xlim([-1, end_time+1]);
    ylim([-0.2 1.2]); 
    xlabel('Time (s)');
    ylabel('Punish');
    title('Punish Signal');
    legend({'Punish'},'Location','northwest','Orientation','vertical');
    saveas(gcf, sprintf('Trial-%d-Punish-Signal.png', trialIdx));

    % plot the TTL graph
    ttl_graph_data = ones(size(ttl_list));
    figure;
    stem(cell2mat(ttl_list), ttl_graph_data);
    xlim([-1, end_time+1]);
    ylim([-0.2 1.2]); 
    xlabel('Time (s)');
    ylabel('TTL');
    title('TTL Signal');
    legend({'TTL'},'Location','northwest','Orientation','vertical');
    saveas(gcf, sprintf('Trial-%d-TTL-Signal.png', trialIdx));

    % Plot the baseline signal
    figure;
    plot(t, baseline_signal, LineWidth=2);
    xlim([-1, end_time+1]);
    ylim([-0.2 1.2]); 
    xlabel('Time (s)');
    ylabel('Beaseline');
    title('Baseline Signal');
    legend({'Baseline'},'Location','northwest','Orientation','vertical');
    saveas(gcf, sprintf('Trial-%d-Baseline-Signal.png', trialIdx));

    % Plot the stimulus signal
    figure;
    plot(t, stimulus_signal, LineWidth=2);
    ylim([-0.2 1.2]); 
    xlim([-1, end_time+1]);
    xlabel('Time (s)');
    ylabel('Stimulus');
    title('Stimulus Signal');
    legend({'Stimulus'},'Location','northwest','Orientation','vertical');
    saveas(gcf, sprintf('Trial-%d-Stimulus-Signal.png', trialIdx));
end