# functions-for-matlab
This Repository contains various matlab functions, which might be useful for research in psychology, neurosciences etc.

##Functions for EEGLAB:

* **_addEEGEvents.m_** was originally written in order to select only stimulus-locked events in an EEG experiment followed by a correct response but it can catch any specified event following a target event. To check for correctness, the stimulus-locked event must be followed immediately by a trigger coding the correctness of the response to the stimulus (i.e. no other EEG events in between).

##Functions for Psychtoolbox 3 (PTB-3):

* **_getVoiceResponse.m_** was written to capture voice responses in a simple psychological experiment in order to measure the response latency for subsequent analysis of reaction time (RT) using a microphone. Note that the function works fine for within-subject designs in which the exakt voice onset is not but the latancy differences between conditions are of interest. 
* **_soundCheck.m_** performs a sound check to find the right threshold level for the function **_getVoiceResponse.m_**. The function produces a GUI like the following to find an appropriate trigger threshod.

![examplegui_soundcheck](https://cloud.githubusercontent.com/assets/17894303/17837471/21179006-67b4-11e6-8b98-19954f518c1e.png)

##Disclaimer: 

Except when otherwise stated in writing the copyright holders and/or other parties provide the program 'as is' without warranty of any kind, expressed or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose.
