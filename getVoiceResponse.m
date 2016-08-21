function [onsetTrigger] = getVoiceResponse(threshold, time, wavFilename, varargin)
%getVoiceResponse(threshold, maxSecs, varargin)
%   The functions was written to collect responses and reaction times in
%   psychological experiments making use of the Psychtoolbox 3 (PTB-3)
%   function PsychPortAudio(). For more details on this function see: help
%   PsychPortAudio. Once the function is called, the functions until the
%   measured amplitude is higher then the chosen threshold. The time point 
%   of this is saved and returned. After the trigger has been activated the 
%   function records the sounds for the duration specified in the variable 
%   time. 
%
%   Mandatory arguments:
%    threshold   -> pointer to the window
%    time        -> pointer to the window
%    wavFilename -> A string ending on .wav
%
%   Varargin:
%    'freq'         -> For more information see PsychPortAudio('Open?') in
%                      'freq'. Default is 44100.
%    'screentoflip' -> A PTB-3 screen handle. Once the trigger has been
%                      activated, the screen will be flipped to the
%                      background if this argument is provided.
%    'latencymode'  -> For more information see PsychPortAudio('Open?') in
%                      'reqlatencyclass'. Default is 0.
%
%
%   Author: Joern Alexander Quent
%   e-mail: alexander.quent@rub.de
%   Version history:
%                    1.0 - 13. August 2016 - First draft

%% Parse input arguments
% Default values
freq         = 44100; % Frequency of capture
mode         = 2;     % Capture only
latencyMode  = 0;     % See PsychPortAudio('Open?') -> 'reqlatencyclass'
channels     = 2;     % For stereo capture
flip         = 0;     % Don't flip screen
 
i = 1;
while(i<=length(varargin))
    switch lower(varargin{i});
        case 'screentoflip'
            i             = i + 1;
            screenPointer = varargin{i};
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

% Preallocate an internal audio recording  buffer with a capacity of 10 seconds:
PsychPortAudio('GetAudioData', paHandle, 10);


% Start audio capture immediately and wait for the capture to start.
% We set the number of 'repetitions' to zero,
% i.e. record until recording is manually stopped.
PsychPortAudio('Start', paHandle, 0, 0, 1);

% Yes. Fetch audio data and check against threshold:
level = 0;

% Repeat as long as below trigger-threshold:
while level < threshold
    % Fetch current audiodata:
    onsetTrigger = GetSecs;
    audioData    = PsychPortAudio('GetAudioData', paHandle);
    
    % Compute maximum signal amplitude in this chunk of data:
    if ~isempty(audioData)
        level = max(abs(audioData(1,:)));
    else
        level = 0;
    end

    % Below trigger-threshold?
    if level < threshold
        % Wait for a millisecond before next scan:
        WaitSecs(0.0001);
    end
end

% Flip screen
if flip == 1
    Screen('Flip', screenPointer)
end

% Ok, last fetched chunk was above threshold!
% Find exact location of first above threshold sample.
idx = min(find(abs(audioData(1,:)) >= threshold));

% Initialize our recordedaudio vector with captured data starting from
% triggersample:
recordedAudio = audioData(:, idx:end);

offsetTrigger = GetSecs;
WaitSecs(time - (offsetTrigger - onsetTrigger));

PsychPortAudio('Stop', paHandle);

% Perform a last fetch operation to get all remaining data from the capture engine:
audioData = PsychPortAudio('GetAudioData', paHandle);

% Attach it to our full sound vector:
recordedAudio = [recordedAudio audioData];

% Close the audio device:
PsychPortAudio('Close', paHandle);

% If a file name is provided, then a .wav is saved
if ~isempty(wavFilename)
    wavwrite(transpose(recordedAudio), 44100, 16, wavFilename)
    fprintf('An audio file has been saved. \n');
end
end