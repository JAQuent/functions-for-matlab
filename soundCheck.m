  function [threshold] = soundCheck(bgLength, signalLength, directory)
%soundCheck([bgLength = 5] [, signalLength = 1])
%   Performs a sound check to find the right threshold level for the
%   function getVoiceResponse() making use of the Psychtoolbox 3 (PTB-3)
%   function PsychPortAudio(). For more details on this function see: help
%   PsychPortAudio. The sound check consists of two recordings. The first
%   recording is designed to capture the background noise in the
%   experimental setting. The default length of this measurement is 5 
%   seconds. The second recording is for capturing a signal
%   (e.g. a subjects saying a word). The default length of this measurement 
%   is 1 second. The second measurement is trigged by pressing any key of
%   the keyboard. After capturing, the two recording a displayed in a GUI
%   plot in separate graphs. A slider moves a cut-off line in both graphs
%   simultaneuously to adjust the cut-off value for optimal signal to noise
%   ratio. Once the appropriate value was found with the help of the
%   slider, the user has to close . The function returns the
%   value, which has been chosen by the user, after the GUI plot has
%   closed. The workspace with all crucial variables and the plot is saved in
%   soundCheck_YYYYMMDD_HHMMSS.mat and soundCheck_YYYYMMDD_HHMMSS.png,
%   respectively. 
% 
% Optional arguments:
%    bgLength      -> length of recording window for background noise in
%                     secs.
%    signalLength  -> length of recording window for signal in secs.
%    directory     -> directory to save results (e.g.  'results\').
%
%   Author: Joern Alexander Quent
%   e-mail: alexander.quent@rub.de
%   Version history:
%                    1.0 - 13. August 2016 - First draft.
%                    1.1 - 17. August 2016 - Added the possibility to
%                    choose a directory.

%% Default values and parse input arguments
if nargin < 1
    bgLength = [];
end

if isempty(bgLength)
    bgLength     = 5; 
end

if nargin < 2
    signalLength = [];
end

if isempty(signalLength)
    signalLength     = 1; 
end

if nargin < 3
    directory = [];
end

if isempty(signalLength)
    directory     = ''; 
end

freq         = 44100; % Frequency of capture
mode         = 2;     % Capture only
latencyMode  = 0;     % See PsychPortAudio('Open?') -> 'reqlatencyclass'
channels     = 2;     % For stereo capture
global cutOffValue

%% Functions
    function [cutOff] = slidePlot(bgTime, bgData, signalTime, signalData, cutOff)
        subplot(3,1,1);
        plot(bgTime, bgData(1,:), 'r', bgTime, bgData(2,:), 'b')
        title('Background noise')
        ylabel('Amplitude')
        hline = refline([0 cutOff]);
        set(hline,'Color','red')   
        axis([min(bgTime) max(bgTime) -1 1])

        subplot(3,1,2);
        plot(signalTime, signalData(1,:), 'blue', signalTime, signalData(2,:), 'blue')
        title('Signal')
        xlabel('Time in secs')
        ylabel('Amplitude')
        hline = refline([0 cutOff]);
        set(hline,'Color','red')                            
        axis([min(signalTime) max(signalTime) -1 1])
        cutOffValue = cutOff;
    end


%% Open the default audio device
try
    paHandle    = PsychPortAudio('Open', [], mode, latencyMode, freq, channels);
catch
    % Perform basic initialization of the sound driver:
    InitializePsychSound;
    paHandle    = PsychPortAudio('Open', [], mode, latencyMode, freq, channels);
end

% Preallocate an internal audio recording  buffer with a capacity of 10 seconds:
PsychPortAudio('GetAudioData', paHandle, 10);

%% Background noise level
fprintf('\n');
fprintf('Capturing of background noise level will start in 1 second.\n');
fprintf('... \n');
WaitSecs(1);
PsychPortAudio('Start', paHandle, 0, 0, 1);
WaitSecs(bgLength);
bgData    = PsychPortAudio('GetAudioData', paHandle);
fprintf('Capturing of background noise level completed.\n');

bgSampleLength = size(bgData, 2)/freq;
bgTime         = linspace(0,bgSampleLength, length(bgData));
bgMean         = mean(mean(abs(bgData)));
bgMax          = max(max(abs(bgData)));

%% Signal level
fprintf('\n');
fprintf('Capturing of signal level will start after key press.\n');
fprintf('...\n');
KbWait;
PsychPortAudio('GetAudioData', paHandle); % Resets buffer
WaitSecs(signalLength);
signalData    = PsychPortAudio('GetAudioData', paHandle);
PsychPortAudio('Close', paHandle);
fprintf('Capturing of signal level completed.\n');

signalSampleLength = size(signalData, 2)/freq;
signalTime         = linspace(0,signalSampleLength, length(signalData));
signalMean         = mean(mean(abs(signalData))); 
signalMax          = max(max(abs(signalData)));

%% Plott and wait for user input
f = figure;
bgColor = [0.7 0.7 0.7];
set(gcf, 'color', bgColor)
subplot(3,1,1);
plot(bgTime, bgData(1,:), 'r', bgTime, bgData(2,:), 'b')
title('Background noise')
ylabel('Amplitude')
hline = refline([0 0]);
set(hline,'Color','red')   
axis([min(bgTime) max(bgTime) -1 1])

subplot(3,1,2);
plot(signalTime, signalData(1,:), 'blue', signalTime, signalData(2,:), 'blue')
title('Signal')
xlabel('Time in secs')
ylabel('Amplitude')
hline = refline([0 0]);
set(hline,'Color','red')                            
axis([min(signalTime) max(signalTime) -1 1])
saveas(gcf, horzcat(directory,'soundCheck_', datestr(now,'yyyymmdd'),'_', datestr(now,'HHMMSS'), '.png'))

hsl = uicontrol('Style','slider','Min',0,'Max',1,...
                'SliderStep',[0.01 0.01] ,'Value',0.1,...
                'Position',[81,54,419,23]);
hsl1 = uicontrol('Parent',f,'Style','text','Position',[50,51,23,23],...
                'String','0','BackgroundColor', bgColor);
hsl2 = uicontrol('Parent',f,'Style' ,'text','Position',[500,51,23,23],...
                'String','1','BackgroundColor', bgColor);
hsl3 = uicontrol('Parent',f,'Style','text','Position',[240,25,100,23],...
                'String','Threshold','BackgroundColor', bgColor); 
set(hsl,'Callback',@(hObject,eventdata) slidePlot(bgTime, bgData, signalTime, signalData, get(hObject,'Value')))
uiwait(f)

%% Retrieve level and save
threshold = cutOffValue;
save(horzcat(directory,'soundCheck_', datestr(now,'yyyymmdd'),'_', datestr(now,'HHMMSS'), '.mat'))
end

