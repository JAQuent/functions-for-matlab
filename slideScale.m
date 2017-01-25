function [position, RT, answer] = slideScale(screenPointer, question, rect, endPoints, varargin)
%SLIDESCALE This funtion draws a slide scale on a PSYCHTOOLOX 3 screen and returns the
% position of the slider in pixel as well as the rection time and if an answer was given.
%
%   Usage: [position, secs] = slideScale(ScreenPointer, question, center, rect, endPoints, varargin)
%   Mandatory input:
%    ScreenPointer  -> pointer to the window
%    question       -> Text string containing the question
%    rect           -> Double contatining the screen size.
%                      Obtained with [myScreen, rect] = Screen('OpenWindow', 0);
%    endPoints      -> Cell containg the two text string of the left and right
%                      end of the scala. Exampe: endPoints = {'left, 'right'};
%
%   Varargin:
%    'linelength'    -> An integer specifying the lengths of the ticks in
%                       pixels. The default is 10.
%    'width'         -> An integer specifying the width of the scala leine in
%                       pixels. The default is 3.
%    'scalalength'   -> Double value between 0 and 1 for the length of the
%                       scale. The default is 0.9.
%    'scalaposition' -> Double value between 0 and 1 for the position of the
%                       scale. 0 is top and 1 is bottom.
%    'device'        -> A string specifying the response device. Either 'mouse' 
%                       or 'keyboard'. The default is 'mouse'.
%    'responsekey'   -> String containing name of the key from the keyboard to log the
%                       response. Example. The default is 'return'.
%    'slidecolor'    -> Vector for the color value of the slider [r g b] 
%                       from 0 to 255. The dedult is red [255 0 0].
%    'scalacolor'    -> Vector for the color value of the scale [r g b] 
%                       from 0 to 255.The dedult is black [0 0 0].
%    'aborttime'     -> Double specifying the time in seconds after which
%                       the function should be aborted. In this case no
%                       answer is saved. The default is 8 secs.
%    'image'         -> An image saved in a uint8 matrix. Use
%                       imread('image.png') to load an image file.  
%
%   Output:
%    'position'      -> Deviation from zero in percentage, 
%                       with -100 <= position <= 100 to indicate left-sided
%                       and right-sided deviation.
%    'RT'            -> Reaction time in milliseconds.
%    'answer'        -> If 0, no answer has been given. Otherwise this
%                       variable is 1.
%
%   Author: Joern Alexander Quent
%   e-mail: alexander.quent@rub.de
%   Version history:
%                    1.0 - 01/04/2016 - First draft
%                    1.1 - 02/18/2016 - Added abort time and option to
%                    choose between mouse and key board
%                    1.2 - 05/10/2016 - End points will be aligned to end
%                    ticks
%                    1.3 - 06/01/2016 - Added the possibility to display an
%                    image



%% Return error if in multi display mode!
screens       = Screen('Screens');
if length(screens) > 1
    error('Multi display mode not supported.');
end

%% Parse input arguments
% Default values
center        = round([rect(3) rect(4)]/2);
lineLength    = 10;
width         = 3;
scalaLength   = 0.9;
scalaPosition = 0.8;
sliderColor    = [255 0 0];
scaleColor    = [0 0 0];
device        = 'mouse';
aborttime     = 8;
responseKey   = KbName('return');
drawImage     = 0;

i = 1;
while(i<=length(varargin))
    switch lower(varargin{i})
        case 'linelength'
            i             = i + 1;
            lineLength    = varargin{i};
            i             = i + 1;
        case 'width'
            i             = i + 1;
            width         = varargin{i};
            i             = i + 1;
        case 'scalalength'
            i             = i + 1;
            scalaLength   = varargin{i};
            i             = i + 1;
        case 'scalaposition'
            i             = i + 1;
            scalaPosition = varargin{i};
            i             = i + 1;
        case 'device' 
            i             = i + 1;
            device = varargin{i};
            i             = i + 1;
        case 'responsekey'
            i             = i + 1;
            responseKey   = KbName(varargin{i});
            i             = i + 1;
        case 'slidecolor'
            i             = i + 1;
            sliderColor    = varargin{i};
            i             = i + 1;
        case 'scalacolor'
            i             = i + 1;
            scaleColor    = varargin{i};
            i             = i + 1;
        case 'aborttime'
            i             = i + 1;
            aborttime     = varargin{i};
            i             = i + 1;
        case 'image'
            i             = i + 1;
            image         = varargin{i};
            i             = i + 1;
            imageSize     = size(image);
            stimuli       = Screen('MakeTexture', screenPointer, image);
            drawImage     = 1; 
    end
end

% Sets the default key depending on choosen device
if strcmp(device, 'mouse')
    responseKey   = 1; % X mouse button
end

%% Coordinates of scale lines and text bounds
midTick    = [center(1) rect(4)*scalaPosition - lineLength - 5 center(1) rect(4)*scalaPosition  + lineLength + 5];
leftTick   = [rect(3)*(1-scalaLength) rect(4)*scalaPosition - lineLength rect(3)*(1-scalaLength) rect(4)*scalaPosition  + lineLength];
rightTick  = [rect(3)*scalaLength rect(4)*scalaPosition - lineLength rect(3)*scalaLength rect(4)*scalaPosition  + lineLength];
horzLine   = [rect(3)*scalaLength rect(4)*scalaPosition rect(3)*(1-scalaLength) rect(4)*scalaPosition];
textBounds = [Screen('TextBounds', screenPointer, endPoints{1}); Screen('TextBounds', screenPointer, endPoints{2})];
if drawImage == 1
    rectImage  = [center(1) - imageSize(2)/2 rect(4)*(scalaPosition - 0.2) - imageSize(1) center(1) + imageSize(2)/2 rect(4)*(scalaPosition - 0.2)];
    if rect(4)*(scalaPosition - 0.2) - imageSize(1) < 0
        error('The height of the image is too large. Either lower your scale or use the smaller image.');
    end
end

%% Loop for scale loop
t0                         = GetSecs;
answer                     = 0;
while answer == 0
    [x,y,buttons,focus,valuators,valinfo] = GetMouse(screenPointer, 1);
    if x > rect(3)*scalaLength
        x = rect(3)*scalaLength;
    elseif x < rect(3)*(1-scalaLength)
        x = rect(3)*(1-scalaLength);
    end
    
    % Draw image if provided
    if drawImage == 1
         Screen('DrawTexture', screenPointer, stimuli,[] , rectImage, 0);
    end
    
    % Drawing the question as text
    DrawFormattedText(screenPointer, question, 'center', rect(4)*(scalaPosition - 0.1)); 
    
    % Drawing the end points of the scala as text
    DrawFormattedText(screenPointer, endPoints{1}, leftTick(1, 1) - textBounds(1, 3)/2,  rect(4)*scalaPosition+10, [],[],[],[],[],[],[]); % Left point
    DrawFormattedText(screenPointer, endPoints{2}, rightTick(1, 1) - textBounds(2, 3)/2,  rect(4)*scalaPosition+10, [],[],[],[],[],[],[]); % Right point
    
    % Drawing the scala
    Screen('DrawLine', screenPointer, scaleColor, midTick(1), midTick(2), midTick(3), midTick(4), width);         % Mid tick
    Screen('DrawLine', screenPointer, scaleColor, leftTick(1), leftTick(2), leftTick(3), leftTick(4), width);     % Left tick
    Screen('DrawLine', screenPointer, scaleColor, rightTick(1), rightTick(2), rightTick(3), rightTick(4), width); % Right tick
    Screen('DrawLine', screenPointer, scaleColor, horzLine(1), horzLine(2), horzLine(3), horzLine(4), width);     % Horizontal line
    
    % The slider
    Screen('DrawLine', screenPointer, sliderColor, x, rect(4)*scalaPosition - lineLength, x, rect(4)*scalaPosition  + lineLength, width);
    
    % Flip screen
    onsetStimulus = Screen('Flip', screenPointer);
    
    % Check if answer has been given
    if strcmp(device, 'mouse')
        secs = GetSecs;
        if buttons(responseKey) == 1
            answer = 1;
        end
    elseif strcmp(device, 'keyboard')
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode(responseKey) == 1
            answer = 1;
        end
    else
        error('Unknown device');
    end
    
    % Abort if answer takes too long
    if secs - t0 > aborttime 
        break
    end
end
%% Calculating the rection time and the position
RT                = (secs - t0)*1000;                                          % converting RT to millisecond
scaleRange        = round(rect(3)*(1-scalaLength)):round(rect(3)*scalaLength); % Calculates the range of the scale
scaleRangeShifted = round((scaleRange)-mean(scaleRange));                      % Shift the range of scale so it is symmetrical around zero
position          = round((x)-mean(scaleRange));                               % Shift the x value according to the new scale
position          = (position/max(scaleRangeShifted))*100;                     % Converts the value to percentage
end

