function EVTCODE = getmlevtcodes()
%GETMLEVTCODES - Get event codes used by ICPBR-MonkeyLogic system.
%
%  VERSION :
%    0.90 2025.08.26 YM  pre-release
%    
% See also EXPGETMLEVT


% Default codes for MonkeyLogic2
EVTCODE.StartTrial   =   9;
EVTCODE.FrakeSkipped =  13;
EVTCODE.ManualReward =  14;
EVTCODE.EndTrial     =  18;

% MriGeneric Event Codes (similar to MPI-ESS, Experiment-State-System)
EVTCODE.StartObsp    =  19;  %  Start Obs Period
EVTCODE.BeginObsp    =  19;  %  Start Obs Period
EVTCODE.EndObsp      =  20;  %  End Obs Period
EVTCODE.TrialType    =  22;  %  Trial Type
EVTCODE.ObspType     =  23;  %  Obs Period Type
EVTCODE.Fixspot      =  25;  %  Fixspot
EVTCODE.Stimulus     =  27;  %  Stimulus
EVTCODE.Pattern      =  28;  %  Pattern
EVTCODE.StimulusType =  29;  %  Stimulus Type
EVTCODE.Sample       =  30;  %  Sample
EVTCODE.Probe        =  31;  %  Probe
EVTCODE.Cue          =  32;  %  Cue
EVTCODE.Target       =  33;  %  Target
EVTCODE.Distractor   =  34;  %  Distractor
EVTCODE.SoundEvent   =  35;  %  Sound Event
EVTCODE.Fixation     =  36;  %  Fixation
EVTCODE.Response     =  37;  %  Response
EVTCODE.Saccade      =  38;  %  Saccade
EVTCODE.Decide       =  39;  %  Decide
EVTCODE.Abort        =  41;  %  Abort
EVTCODE.Reward       =  42;  %  Reward
EVTCODE.Delay        =  43;  %  Delay
EVTCODE.Punish       =  44;  %  Punish
EVTCODE.Mri          =  46;  %  Mri

EVTCODE.StartScene   = 101;
EVTCODE.EndScene     = 102;

