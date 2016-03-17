function [EEG, classCount] = addEEGEvents(EEG,targetChar,targetNum, classifiers, newLetters)
%addEEGEvents adds events to an EEGLAB dataset based on the events
%following a target event. This function is specially useful if you
%want to select only stimulus-locked events followed by a correct response. 
%The function addes new event to the dataset at the same time point of the 
%target event for each target event followed by a classifier. The event code 
%of the new event is the letter of the classifier and the number of the 
%target event (e.g. 'S 5' followed by classifier 1 becomes 'R 5').
%   Input:
%   EEG         - EEGLAB dataset structure
%   targetChar  - target event as character (e.g. 'S 5').
%   targetNum   - target event as integer (e.g. 5).
%   classifiers - classifiying events as cell (e.g. {'S 1', 'S 2', 'S 3'}).
%   newLetters  - new letter for each classifier as cell (e.g. {'R', 'F' 'M'}).
%
%   Output:
%   EEG         - updated EEG dataset (e.g. correctly responded 'S 5' becomes
%                'R 5').
%   classCount  - vector containing how often each classifier followed a
%                 a target event.
%
%   Example:
%   targetChar  = 'S 5'; % Stimulus-locked event
%   targetNum   = 5;
%   classifiers = {'S 1', 'S 2', 'S 3'}; % Event codes for correct, false
%   % and missed responses
%   newLetters  = {'R', 'F', 'M'}; % R for right, F for false and....
%   [EEG, classCount] = addEEGEvents(EEG,targetChar,targetNum, classifiers, newLetters)
% 
%   Author:   Jörn Alexander Quent (e-Mail: alexander.quent@rub.de)
%   Version: 2.0 - 03/17/2016

%% Checking input
if length(classifiers) ~= length(newLetters)
    error('A new letter must be provided for each classifier');
end


%% Setting up
numberEvents   = length(EEG.event);
classCount     = zeros(length(classifiers), 1);

%% Adding new events
for i = 1:numberEvents
    if strcmp(EEG.event(i).type, targetChar)
        for j = 1:length(classifiers)
            if strcmp(EEG.event(i + 1).type, classifiers{j})
                classCount(j)   = classCount(j) + 1;
                EEG.event(end + 1)   = EEG.event(i); 
                EEG.event(end).type  = [newLetters{j},' ', num2str(targetNum)];
            end
        end
    end
end

%% Display summary
total = sum(classCount);
fprintf(['Set ',EEG.setname,' contained:\n'])
for j = 1:length(classifiers)
    fprintf('Type %d: %d (%d %%)\n', j ,classCount(j), round((classCount(j)/total)*100))
end
end

