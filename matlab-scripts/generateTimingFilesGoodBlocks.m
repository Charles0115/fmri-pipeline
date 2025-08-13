function generateTimingFilesGoodBlocks(perfFile, timingFile, dateStr, runNum, overallFixPercentage)
% generateTimingFilesGoodBlocks  Produce AFNI .1D timing files per condition
%   generateTimingFilesGoodBlocks(perfFile, timingFile, dateStr, runNum, overallFixPercentage)
%   reads performance Excel and timing CSV, filters trials by overall fixation,
%   dynamically creates timing files for each stimulus named in perfFile.
%
% Inputs:
%   perfFile             Path to performance Excel workbook
%   timingFile           Path to MonkeyLogic timing CSV file
%   dateStr              Sheet name in perfFile (e.g. '2025_04_09')
%   runNum               Run number (integer, e.g. 1)
%   overallFixPercentage Threshold for overall fixation (0 to 1)

% Read performance sheet
perfCells = readcell(perfFile, 'Sheet', dateStr);
runLabel = sprintf('RUN%02d', runNum);
nextRunLabel = sprintf('RUN%02d', runNum+1);
startRow = find(strcmp(perfCells(:,1), runLabel),1,'first')+1;
endRow   = size(perfCells,1);
idxNext  = find(strcmp(perfCells(:,1), nextRunLabel),1,'first');
if ~isempty(idxNext), endRow = idxNext-1; end
perfData = perfCells(startRow:endRow,1:7);

% Parse performance columns robustly
nTrials = size(perfData,1);
trialNums = zeros(nTrials,1);
stimNames = cell(nTrials,1);
overallPct = zeros(nTrials,1);
for i=1:nTrials
    % Trial number
    val = perfData{i,1};
    if isnumeric(val), trialNums(i)=val;
    else trialNums(i)=str2double(val);
    end
    % Stimulus name
    stimNames{i} = perfData{i,2};
    % Overall fixation percentage
    valp = perfData{i,7};
    if isnumeric(valp), overallPct(i)=valp;
    else overallPct(i)=str2double(valp);
    end
end

% Filter valid trials
maskValid = overallPct>=overallFixPercentage;
validTrials = trialNums(maskValid);
validStim  = stimNames(maskValid);

% Load timing CSV and convert times
timTbl = readtable(timingFile);
timTbl.AbsTimeSec = timTbl.AbsCodeTime/1000;
% Time-zero = first TTL onset
iTTL = find(strcmp(timTbl.Event_Type,'TTL_onset'),1);
timeZero = timTbl.AbsTimeSec(iTTL);

% Containers for baseline and stimulus onsets
baselineOnsets = {};
stimOnsets   = struct();  % dynamic fields per condition

% Loop over valid trials
for k=1:numel(validTrials)
    tnum = validTrials(k);
    sraw = lower(validStim{k});
    % Determine condition name: sanitize stimulus name
    % replace non-alphanum with underscore
    cond = regexprep(sraw,'[^a-z0-9]+','_');
    if isempty(cond), continue; end
    % Initialize container if first occurrence
    if ~isfield(stimOnsets,cond)
        stimOnsets.(cond) = {};
    end
    % Get trial-specific rows
    idx = timTbl.Trial==tnum;
    sub = timTbl(idx,:);
    % Find baseline(24), stim(6), end(18)
    b = find(sub.CodeNumber==24,1);
    s = find(sub.CodeNumber==6,1);
    e = find(sub.CodeNumber==18,1);
    if isempty(b)||isempty(s)||isempty(e)
        warning('Missing codes for trial %d',tnum); continue;
    end
    baseOn = sub.AbsTimeSec(b)-timeZero;
    stimOn = sub.AbsTimeSec(s)-timeZero;
    endOn  = sub.AbsTimeSec(e)-timeZero;
    % Baseline onset:duration
    baseDur = stimOn-baseOn;
    baselineOnsets{end+1} = sprintf('%.3f:%.3f', baseOn, baseDur);
    % Stimulus onset:duration
    stimDur = endOn-stimOn;
    stimOnsets.(cond){end+1} = sprintf('%.3f:%.3f', stimOn, stimDur);
end

% Determine output directory
[outDir,~,~] = fileparts(timingFile);
if isempty(outDir), outDir = pwd; end

% Write baseline file
bname = sprintf('baseline_run%02d_valid.1D',runNum);
bpath = fullfile(outDir,bname);
fid = fopen(bpath,'w');
if isempty(baselineOnsets), fprintf(fid,'*');
else fprintf(fid,'%s ',baselineOnsets{:});
end
fprintf(fid,'\n'); fclose(fid);
fprintf('Wrote: %s\n',bpath);

% Write one file per condition dynamically
conds = fieldnames(stimOnsets);
for i=1:numel(conds)
    cn = conds{i};
    on = stimOnsets.(cn);
    fname = sprintf('%s_run%02d_valid.1D',cn,runNum);
    fpath = fullfile(outDir,fname);
    fid = fopen(fpath,'w');
    if isempty(on), fprintf(fid,'*');
    else fprintf(fid,'%s ',on{:});
    end
    fprintf(fid,'\n'); fclose(fid);
    fprintf('Wrote: %s\n',fpath);
end
end
