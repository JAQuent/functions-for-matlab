# functions-for-matlab
This Repository contains various matlab functions, which might be useful for research in psychology, neurosciences etc.

##Functions for EEGLAB:

* **_addEEGEvents.m_** was originally written in order to select only stimulus-locked events in an EEG experiment followed by a correct response but it can catch any specified event following a target event. To check for correctness, the stimulus-locked event must be followed immediately by a trigger coding the correctness of the response to the stimulus (i.e. no other EEG events in between).
