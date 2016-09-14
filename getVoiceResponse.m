function [RT] = getVoiceResponse(threshold, time, filename, varargin)
%getVoiceResponse(threshold, time, wavFilename, varargin)
%   The functions was written to collect responses and reaction times in
%   psychological experiments making use of the Psychtoolbox 3 (PTB-3)
%   function PsychPortAudio(). The function records audio data until
%   the specified time elapsed and then tries to find the voice onset. A 
%   time point is interpreted as the voice onset if the time point is
%   followed by enough values, which are also above the threshold. The 
%   specific criterion is that the number of values exceeding the defined 
%   treshold within the time window starting with the value at hand and 
%   lasting a specified amount of time (default = 5 msec) is not smaller 
%   than a specified number (default = 20). The function chronologically 
%   probes whether the values fulfill this requirement. The earliest time 
%   point, which meets this requirement is interpreted as the voice onset.
%   If no time point fulfills this requirement, -99 is returned as the voice 
%   onset. The procdure was chosen to avoid that short lasting noise or 
%   other short signal fluctuations are interpreted as the voice onset. 
%   Additionaly, the function saves the sound and a figure with lines 
%   marking the threshold and the voice onset for later inspection if a 
%   filename is provided. If this is not wished, use [] instead. If you 
%   only want to save one of them, use the optional argument 'savemode'. 
%   Note that this function was written for a 2-channel set up and that it 
%   only works if the function InitializePsychSound is called. 
%
%   Mandatory arguments:
%    threshold   -> Value between 0 and 1.
%    time        -> Value for recording time in seconds. 
%    filename    -> A string for a file name to save the figure and the
%                   .wav file. If no file name is proivded, nothing is
%                   saved. 
%
%   Varargin:
%    'timewindow'   -> The length of the time window in msec, in which additional
%                      peaks (absolute values above threshold) need to
%                      occur so that a value above the thresold is
%                      interpreted as the voice onset. Default is set to 5
%                      msec. 
%    'npeaks'       -> Number of peaks, which have to occur within the specified 
%                      time window so that the  a value is interpreted as the 
%                      voice onset. Default is 20. 
%    'savemode'     -> If 1 (default), everything is saved. If 2, only the 
%                      .wav file is saved. If 3, only the plot is saved. 
%    'screenflip'   -> A If provide the screen flips to background after the 
%                      specified time. [handle time];
%    'freq'         -> For more information see PsychPortAudio('Open?') in
%                      'freq'. Default is 44100.
%    'latencymode'  -> For more information see PsychPortAudio('Open?') in
%                      'reqlatencyclass'. Default is 0.
%
%
%   Author: Joern Alexander Quent
%   e-mail: alexander.quent@rub.de
%   Version history:
%                    1.0 - 13. August 2016   - First draft
%                    2.0 - 2. September 2016 - Total revision because 
%                    PsychPortAudio('GetAudioData') returns empty
%                    recordings. 
%                    2.1 - 8. September 2016 - Adding the possibilty to
%                    save a plot and to flip the screen. 
%                    2.2 - 11. September 2016 - Change the signal detection
%                    algorithm. 
%                    2.3 - 14. September 2016 - Improved documentation and
%                    comments


%% Start of function (time point 1)
timePoint1 = GetSecs;

%% Get time and parse input arguments
% Default values
freq            = 44100; % Frequency of capture
mode            = 2;     % Capture only
latencyMode     = 0;     % See PsychPortAudio('Open?') -> 'reqlatencyclass'
channels        = 2;     % For stereo capture
RT              = [];
idx             = [];
flip            = 0;
saveMode        = 1; % Saves everything
timeWindowMsec  = 5; % msec
nPeaks          = 20;

i = 1;
while(i<=length(varargin))
    switch lower(varargin{i});
        case 'timewindow'
            i              = i + 1;
            timeWindowMsec = varargin{i};
            i              = i + 1;
        case 'npeaks'
            i              = i + 1;
            npeaks         = varargin{i};
            i              = i + 1;
        case 'savemode'
            i              = i + 1;
            saveMode       = varargin{i};
            i              = i + 1;
        case 'screenflip'
            i              = i + 1;
            screenInfo     = varargin{i};
            flip           = 1;
            i              = i + 1;
        case 'freq'
            i              = i + 1;
            freq           = varargin{i};
            i              = i + 1;
        case 'latencymode'
            i              = i + 1;
            latencyMode    = varargin{i};
            i              = i + 1;
    end
end

%% Open the default audio device
try
    paHandle    = PsychPortAudio('Open', [], mode, latencyMode, freq, channels);
catch
    error('Did you use InitializePsychSound?')
end

%% Record the signal
% Preallocate an internal audio recording  buffer with a capacity of 10 seconds:
PsychPortAudio('GetAudioData', paHandle, 5);

% Start of recording (time point 2)
timePoint2 = GetSecs;
PsychPortAudio('Start', paHandle, 0, 0, 1);
timePoint3   = GetSecs;
while time > (timePoint3 - timePoint2)
    if flip == 1
        if screenInfo(2) < (timePoint3 - timePoint2)
            Screen('Flip', screenInfo(1))
            flip = 0;
        end
    end
    timePoint3   = GetSecs;
end
PsychPortAudio('Stop', paHandle);
audioData = PsychPortAudio('GetAudioData', paHandle, [], [], [], 1);

%% Find voiece onset and calculate RT
s               = PsychPortAudio('GetStatus', paHandle);
timeWindowIdx   = round(s.SampleRate/(1000/timeWindowMsec));

% Channel 1
idx1         = find(abs(audioData(1,:)) >= threshold); % Returns all values above the threshold in channel 1
if ~isempty(idx1) % Excute only if peaks were found
    i            = 1;
    narrowWindow = 0; % Used for correcting the size if the time window is larger than idx1
    if i + timeWindowIdx > length(idx1) % If the index exceeds the idx1 vector, make window smaller
        narrowWindow = length(idx1) - (i + timeWindowIdx);
    end
    timeWindow = idx1(i):(idx1(i) + timeWindowIdx); % Returns all values in the time window

    % The if statement compares the actual values above the threshold
    % within the specified time window with the number of possible values.
    if length(timeWindow) - length(setdiff(idx1(i:(i + timeWindowIdx + narrowWindow)), timeWindow)) < nPeaks
        while length(timeWindow) - length(setdiff(idx1(i:(i + timeWindowIdx + narrowWindow)), timeWindow)) < nPeaks
            i          = i + 1;
            if i > length(idx1)
                idx1 = [];
                break
            end
            timeWindow = idx1(i):(idx1(i) + timeWindowIdx);
            if i + timeWindowIdx > length(idx1) % If the index exceeds the idx1 vector, make window smaller
                narrowWindow = length(idx1) - (i + timeWindowIdx);
            end
        end
    end
    idx1      = idx1(i);
end

% Channel 2
idx2         = find(abs(audioData(2,:)) >= threshold); % Returns all values above the threshold in channel 2.
if ~isempty(idx2) % Excute only if peaks were found.
    i            = 1;
    narrowWindow = 0; % Used for correcting the size if the time window is larger than idxs.
    if i + timeWindowIdx > length(idx2)% If the index exceeds the idx2 vector, make window smaller.
        narrowWindow = length(idx2) - (i + timeWindowIdx);
    end
    timeWindow = idx2(i):(idx2(i) + timeWindowIdx);

    % The if statement compares the actual values above the threshold
    % within the specified time window with the number of possible values.
    if length(timeWindow) - length(setdiff(idx2(i:(i + timeWindowIdx + narrowWindow)), timeWindow)) < nPeaks
        while length(timeWindow) - length(setdiff(idx2(i:(i + timeWindowIdx + narrowWindow)), timeWindow)) < nPeaks
            i          = i + 1;
            if i > length(idx2)
                idx2 = [];
                break
            end
            timeWindow = idx2(i):(idx2(i) + timeWindowIdx);
            if i + timeWindowIdx > length(idx2) % If the index exceeds the idx2 vector, make window smaller.
                narrowWindow = length(idx2) - (i + timeWindowIdx);
            end
        end
    end
    idx2      = idx2(i);
end

% Returns the earliest value from the two channels. This index value is
% divided by the sample rate and multiplied with 1000 to convert the RT
% from sec to msec. 
idx       = min([idx1 idx2]);
RT        = idx/s.SampleRate*1000;

if  length(RT) < 1
    RT  = -99;
    idx = -99;
else
    % The period between the time point 1 (beginning of the function) and 
    % time point 2 (just before the recoding starts) is added to the reaction 
    % time. 
    RT = RT + (timePoint2 - timePoint1)*1000;
end

%% Close the audio device:
PsychPortAudio('Close', paHandle);

%% Saving
if ~isempty(filename) % If no file name is provided, nothing is saved.
    if saveMode == 1 % both
        % Save plot
        times = linspace(0, length(audioData(1,:))/s.SampleRate*1000, length(audioData(1,:)));
        figure('Visible','off')
        hold on
        plot(times, abs(audioData(1,:)))
        ylabel('Absolute amplitude');
        xlabel('Time in msec');
        axis([0,max(times),0,1])
        plot(times, abs(audioData(2,:)))
        line([idx/s.SampleRate*1000 idx/s.SampleRate*1000], [0 1], 'Color','red');
        hline = refline([0 threshold]);
        set(hline,'Color','red')
        hold off
        saveas(gcf,horzcat(filename, '.png'))
        close

        % Save .wav file
        wavwrite(transpose(audioData), 44100, 16, horzcat(filename, '.wav'))
    elseif saveMode == 2 % Only .wav
        % Save .wav file
        wavwrite(transpose(audioData), 44100, 16, horzcat(filename, '.wav'))
    elseif saveMode == 3 % Only plot
        % Save plot
        times = linspace(0, length(audioData(1,:))/s.SampleRate*1000, length(audioData(1,:)));
        figure('Visible','off')
        hold on
        plot(times, abs(audioData(1,:)))
        ylabel('Absolute amplitude');
        xlabel('Time in msec');
        axis([0,max(times),0,1])
        plot(times, abs(audioData(2,:)))
        line([idx/s.SampleRate*1000 idx/s.SampleRate*1000], [0 1], 'Color','red');
        hline = refline([0 threshold]);
        set(hline,'Color','red')
        hold off
        saveas(gcf,horzcat(filename, '.png'))
        close
    end
end
end