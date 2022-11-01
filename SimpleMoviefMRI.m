function SimpleMoviefMRI(moviename, outputFilePrefix, windowrect, fixationDuration, maxTriggerDuration)
% SimpleMoviefMRI([, outputFilePrefix=''] [, windowrect] [,fixationDuration=4][, maxTriggerDuration=0.04])
% Most simplistic function to play a movie inside an fMRI scanner.
% Note this is definitely not a perfect implementation but only 
% relatively short delays between the fixation end & the first frame
% (around 0.01 to 0.02 seconds) were measured, which works fine for our
% work. The movie duration is pretty accurate (see benchmarking at the end). 
% That being said, please do prober testing if you want use this function in your own research. 
%
% Optional input:
% - moviename: Full filesystem path to the movie. Default is PTB's DualDisc.
% - outputFilePrefix: Prefix to be used at the beginning of the output
% filename.
% - windowrect: Vector to control the window that will be opened. 
% - fixationDuration: Duration in sec for the fixation period before video
% actually starts.
% - maxTriggerDuration: How long the trigger signal should be in seconds, so
% it is not counted more than once. 
%
% After the video is presented this information is saved in a struct
% called triggers with the following fields:
% - subject: The subject name that was provided.
% - session: The session that was provided.
% - date: The date of the data collection in yyyy-mm-dd format. 
% - time: The time of the data collection in HH:MM:SS format. 
% - number: The number of triggers that were registered.
% - triggerArrivalTimePoint: The time point each trigger arrived as time of
% day.
% - triggerArrivalSecs: The time each trigger arrived in seconds. 
% - TR: The estimated TRs based on when the triggers arrived.
% - moviename: Path to the movie that was presented. 
% - rect: Rect of the window that was opened. 
% - numberOfFrames: The number of frames of the video. 
% - dimensions: Width and height of the video. 
% - aspectRatio: Pixel aspect ratio of pixels in the video frames.
% - movieDuration: The duration of the video in seconds.
% - measuredMovieDuration: The measured duration of the video in seconds.
% - fps: FPS of the video.
% - measuredFps: Measured FPS of the video.
% - totalDuration: The total duration it took to run the whole script
% (minus saving). 
% - firstFrameTimeStamp: The time stamp of the first frame. 
% - timeBetweenFirstFrameAndTrigger: Duration betwen the first frame and
% the first trigger.
% - fixationDuration: The fixation duration that was provided as the input.
% - measuredFixationDuration: The fixation duration that was measured. 
% - maxTriggerDuration: The maximum duration how for long a signal trigger
% signal can be to be counted as one. 
% - timeBetweenfixationEndAndFirstFrame: The duration between fixation end
% and the first frame. 
%
% This function is based on SimpleMovieDemo() from the PsychDemo collection.
%
% Here are some benchmarks for videos that were tested:
% Movie 1: 
% True duration: 295.912283
% Measured duration: 295.880344, 295.880657, 295.879590
% True FPS: 59.940060 
% Measured FPS: 59.946530, 59.946467, 59.946683
% Movie 2: 
% True duration: 97.584000 
% Measured duration: 97.550677, 97.557539, 97.552547
% True FPS: 60.000000  
% Measured FPS: 60.020086, 60.015864, 60.018935 
%
% Note longer videos were not tested, please do this yourself if you want to do
% this. 
%
% History:
% 02/05/2009  Created. (MK)
% 06/17/2013  Cleaned up. (MK)
% 31/10/2022  Made into an fMRI version (JAQ)

% Start of the loop & initialise functions
startTimer = GetSecs;
KbCheck;

% Check if Psychtoolbox is properly installed:
AssertOpenGL;

% Get subject & session
subject = input('Subject ID: ', 's');
session = input('Session ID: ', 's');

% Tell the Psychtoolbox function “GetChar” to start or stop listening for
% keyboard input
ListenChar(2);

% Create var to save everything in
triggers  = struct;
count     = 0; % Count of triggers

% Add subject & session & date
triggers.subject = {subject};
triggers.session = {session};
triggers.date = {datestr(now,'yyyy-mm-dd')};
triggers.time = {datestr(now,'HH:MM:SS')};

%% Parse optional inputs
if nargin < 1 || isempty(moviename)
    % No moviename given: Use our default movie:
    moviename = [ PsychtoolboxRoot 'PsychDemos/MovieDemos/DualDiscs.mov' ];
end

if nargin < 2 || isempty(outputFilePrefix)
    outputFilePrefix = '';
end

if nargin < 3 || isempty(windowrect)
    windowrect = [];
end

if nargin < 4 || isempty(fixationDuration)
    fixationDuration = 4; % 4 seconds default
end

if nargin < 5 || isempty(maxTriggerDuration)
    maxTriggerDuration = 0.04; % 0.04 seconds default
end

%% Prepare opening screen etc
% Wait until user releases keys on keyboard:
KbReleaseWait;

% Select screen for display of movie:
screenid = max(Screen('Screens'));

%% Opening screen and loading movie
try
    % Open 'windowrect' sized window on screen, with gray background color:
    [win, rect] = Screen('OpenWindow', screenid, [127.5 127.5 127.5], windowrect);
    
    HideCursor;
    
    % Set text size
    Screen('TextSize', win, 40);
    
    % Display message
    disp('##############################################');
    disp('Loading movie');
    
    % Draw 'wloading movie' on the screen
    DrawFormattedText(win, 'loading movie...', 'center', 'center');
    Screen('Flip', win);
    
    % Open movie file:
    [movie, duration, fps, width, height, numberOfFrames, aspectRatio] = Screen('OpenMovie', win, moviename);
    
    % Start playback engine
    Screen('PlayMovie', movie, 1);
    
    % Set run to 1 & initialise booleans & other variables
    run = 1;
    firstFrameRecorded = false;
    fixStarted = false;
    lastPress = 0;
    fixationStart = 0;
    
    % Display that the script is waiting for the first S
    disp('Waiting for scanner');
    
    % Draw 'waiting for scanner' on the screen
    DrawFormattedText(win, 'waiting for scanner...', 'center', 'center');
    Screen('Flip', win);
    
    % Display it's listening
    disp('Start listening for S');
    disp('##############################################');
    
    % Playback loop: Runs until end of movie
    while run == 1
        %% Handle the triggers
        % Check if any keys are down
        [~, triggerArrivalSecs, keyCode, ~] = KbCheck;
        
        % Check if 'S' is pressed and whether enough time elapsed
        % between the last press of that key to avoid mutliple counting. 
        % This is not perfect but better than waiting for the release of the button
        % which might interfere with the movie. But this  condition is only 
        % applied after the first trigger is send.
        if keyCode(KbName('s')) && (GetSecs - lastPress > maxTriggerDuration || count == 0)
            % Save valid last press
            lastPress = triggerArrivalSecs;
            
            % Calculate all the stuff regarding the trigger times and
            % counts
            count = count + 1;
            triggers.number(count) = count;
            triggers.triggerArrivalTimePoint(count) = {datestr(now,'HH:MM:SS.FFF')};
            triggers.triggerArrivalSecs(count)    = triggerArrivalSecs;
            % Calculate scanning interval
            if count > 1
                triggers.TR(count) = triggerArrivalSecs - triggers.triggerArrivalSecs(count - 1);
            else
                triggers.TR(count) = NaN;
            end
        end
        
        %% Handle the frames
        % Play movie if count is above zero
        if count >= 1
            % This adds fixation delay before the movie is actually started 
            % which must be fixationDuration seconds after the first trigger arrived. 
            timeStamp = GetSecs;
            if timeStamp - fixationStart > fixationDuration && fixStarted
                % Record end of fixation duration but only once
                if ~firstFrameRecorded
                    fixationEnd = timeStamp;
                end
                
                % Wait for next movie frame, retrieve texture handle to it
                tex = Screen('GetMovieImage', win, movie);
                
                % Valid texture returned? A negative value means end of movie reached:
                if tex <= 0
                    movieEnd = GetSecs;
                    % We're done, break out of loop:
                    break;
                end
                
                % Draw the new texture immediately to screen:
                Screen('DrawTexture', win, tex);
                
                % Update display:
                [~, flipTime]  = Screen('Flip', win); 
                
                % Record time stamp of first frame
                if ~firstFrameRecorded
                    firstFrame = flipTime;
                    firstFrameRecorded = true;
                end
                
                % Release texture:
                Screen('Close', tex);
            else
                % Draw fixation cross to the screen but only once
                if ~fixStarted
                    DrawFormattedText(win, '+', 'center', 'center');
                    [~, fixationStart]  = Screen('Flip', win); 
                    fixStarted = true;
                end
            end
        end
    end
    %% Close movie & screen etc. ShowCursor again
    % Stop playback:
    Screen('PlayMovie', movie, 0);
    
    % Close movie:
    Screen('CloseMovie', movie);
    
    % Close Screen, we're done:
    sca;
    
    % Tell the Psychtoolbox function “GetChar” to start or stop listening for
    % keyboard input
    ListenChar(0);
    
    ShowCursor;
    
    % End timer
    endTimer = GetSecs;
    
    %% Add more information to triggers
    triggers.moviename = moviename;
    triggers.rect = rect;
    triggers.fps  = fps;
    triggers.numberOfFrames = numberOfFrames; 
    triggers.dimensions = [width height];
    triggers.aspectRatio = aspectRatio; % Pixel aspect ratio of pixels in the video frames.
    triggers.movieDuration = duration;
    triggers.measuredMovieDuration = movieEnd - firstFrame; 
    triggers.measuredFps = numberOfFrames/triggers.measuredMovieDuration;
    triggers.totalDuration = endTimer - startTimer; 
    triggers.firstFrameTimeStamp = firstFrame;
    triggers.timeBetweenFirstFrameAndTrigger = firstFrame - triggers.triggerArrivalSecs(1);
    triggers.fixationDuration = fixationDuration;
    triggers.measuredFixationDuration = fixationEnd - fixationStart;
    triggers.maxTriggerDuration = maxTriggerDuration;
    triggers.timeBetweenfixationEndAndFirstFrame = firstFrame - fixationEnd;
    
    %% Display sumamry of results to console for direct inspection
    fprintf('####################Results####################\n');
    fprintf('Subject: %s \n', subject);
    fprintf('Session: %s \n', session);
    fprintf('Number of triggers: %i with average TR of %f, a min of %f and max of %f\n', max(triggers.number), mean(triggers.TR, 'omitnan'), min(triggers.TR), max(triggers.TR));
    fprintf('Total duration: %f \n', triggers.totalDuration);
    fprintf('Movie duration (true): %f \n', triggers.movieDuration);
    fprintf('Movie duration (measured): %f \n', triggers.measuredMovieDuration);
    fprintf('Fixation duration (true): %f \n', triggers.fixationDuration);
    fprintf('Fixation duration (measured): %f \n', triggers.measuredFixationDuration);
    fprintf('FPS (true): %f \n', triggers.fps);
    fprintf('FPS (measured): %f \n', triggers.measuredFps);
    fprintf('Time between fixation end & first frame: %f \n', triggers.timeBetweenfixationEndAndFirstFrame);
    fprintf('###############################################\n');
    
    %% Save to file
    save(strcat(outputFilePrefix, '_triggerTimes_', subject, '_', session, '_', datestr(now,'yyyy-mm-dd_HH-MM-SS'), '.mat'), 'triggers')
catch %#ok<CTCH>
    %% Catch part
    % Tell the Psychtoolbox function “GetChar” to start or stop listening for
    % keyboard input
    ListenChar(0);
    ShowCursor;
    sca;
    psychrethrow(psychlasterror);
end
return