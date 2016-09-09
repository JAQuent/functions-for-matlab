function [RT] = getVoiceResponse(threshold, time, filename, varargin)
%getVoiceResponse(threshold, time, wavFilename, varargin)
%   The functions was written to collect responses and reaction times in
%   psychological experiments making use of the Psychtoolbox 3 (PTB-3)
%   function PsychPortAudio(). For more details on this function see: help
%   PsychPortAudio. Once the function is called, the function records until the
%   the specified time elapsed and finds amplitude that is higher then the chosen 
%   threshold. The time point of this is saved and returned. The 
%   function saves the sound and a figure with the threshold and where this is reached 
%   if a filename is provided. If this is not wished, use [] instead. If
%   you only want to save one of them, use the optional argument
%   'savemode'.
%
%   Mandatory arguments:
%    threshold   -> Value between 0 and 1.
%    time        -> Value for recording time in seconds. 
%    filename    -> A string for a file name to save the figure and the
%                   .wav file. If no file name is proivded, nothing is
%                   saved. 
%
%   Varargin:
%    'savemode'     -> If 1 (default), everything is saved. If 2, only the 
%                      .wav file is saved. If 3, only the plot is saved. 
%    'screenflip'   -> A If provide the screen flips to background after the specified time. [handle time];
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
%% Get time and parse input arguments
timePoint1 = GetSecs;

% Default values
freq         = 44100; % Frequency of capture
mode         = 2;     % Capture only
latencyMode  = 0;     % See PsychPortAudio('Open?') -> 'reqlatencyclass'
channels     = 2;     % For stereo capture
RT           = [];
idx          = [];
flip         = 0;
saveMode     = 1; % Saves everything

i = 1;
while(i<=length(varargin))
    switch lower(varargin{i});
        case 'savemode'
            i             = i + 1;
            saveMode      = varargin{i};
            i             = i + 1;
        case 'screenflip'
            i             = i + 1;
            screenInfo    = varargin{i};
            flip          = 1;
            i             = i + 1;
        case 'freq'
            i             = i + 1;
            freq          = varargin{i};
            i             = i + 1;
        case 'latencymode'
            i             = i + 1;
            latencyMode   = varargin{i};
            i             = i + 1;
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

%% Calculate RT
s        = PsychPortAudio('GetStatus', paHandle);
idx1     = min(find(abs(audioData(1,:)) >= threshold));
idx2     = min(find(abs(audioData(2,:)) >= threshold));
idx      = min(min([idx1 idx2]));
RT       = idx/s.SampleRate*1000;

if  length(RT) < 1
    RT = -99;
else
    RT = RT + (timePoint2 - timePoint1)*1000;
end

if length(idx) <1
    idx = -99;
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