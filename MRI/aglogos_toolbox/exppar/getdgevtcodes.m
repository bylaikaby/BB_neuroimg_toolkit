function evt = getdgevtcodes
%GETEVTCODES - Get event codes used by the QNX programs (E_MAGIC, E_NAME,...)
% evt = getevtcodes;
% evt: structure with all relevant evets
% NKL, 05.10.02
% YM,  12.11.19 renamed as get"dg"evtcodes from getevtcodes to avoid name-conflict.
%
% See also GETSES, EXPGETEVT, EVT_NAME.H, EVENTAPI.H
%
% ====================================================================
% QNX Event Names, evt_name.h
% ====================================================================
% name(0,  E_MAGIC,    Magic Number,			  'c', PUT_null)
% name(1,  E_NAME,	   Event Name,			      'c', PUT_string)
% name(2,  E_FILE,     File I/O,	        	  'c', PUT_string)
% name(3,  E_USER,	   User Interaction,          'c', PUT_null)
% name(4,  E_TRACE,    State System Trace,	      'c', PUT_string) 
% name(5,  E_PARAM,    Parameter Set,	          'c', PUT_string) 
% name(16, E_FSPIKE,   Time Stamped Spike,	      'c', PUT_null)
% name(17, E_HSPIKE,   DIS-1 Hardware Spike,      'c', PUT_null)
% name(18, E_ID,       Name,                      'c', PUT_string)		 
% name(19, E_BEGINOBS, Start Obs Period,          'c', PUT_long)
% name(20, E_ENDOBS,   End Obs Period,            'c', PUT_long)
% name(21, E_ISI,      ISI,                       'c', PUT_long)
% name(22, E_TRIALTYPE,Trial Type,                'c', PUT_long)
% name(23, E_OBSTYPE,  Obs Period Type,           'c', PUT_long)
% name(24, E_EMLOG,    EM Log,                    'c', PUT_long)
% name(25, E_FIXSPOT,  Fixspot,                   'c', PUT_float)
% name(26, E_EMPARAMS, EM Params,                 'c', PUT_float)
% name(27, E_STIMULUS, Stimulus,                  'c', PUT_long)
% name(28, E_PATTERN,  Pattern,                   'c', PUT_long)
% name(29, E_STIMTYPE, Stimulus Type,             'c', PUT_long)
% name(30, E_SAMPLE,   Sample,                    'c', PUT_long)
% name(31, E_PROBE,    Probe,                     'c', PUT_long) 
% name(32, E_CUE,      Cue,                       'c', PUT_long)
% name(33, E_TARGET,   Target,                    'c', PUT_long)
% name(34, E_DISTRACTOR, Distractor,              'c', PUT_long)
% name(35, E_SOUND,    Sound Event,               'c', PUT_long)
% name(36, E_FIXATE,   Fixation,                  'c', PUT_long)
% name(37, E_RESP,     Response,                  'c', PUT_long)
% name(38, E_SACCADE,  Saccade,                   'c', PUT_long)
% name(39, E_DECIDE,   Decide,                    'c', PUT_long)
% name(40, E_ENDTRIAL, EOT,                       'c', PUT_long)
% name(41, E_ABORT,    Abort,                     'c', PUT_long)
% name(42, E_REWARD,   Reward,                    'c', PUT_long)
% name(43, E_DELAY,    Delay,                     'c', PUT_long)
% name(44, E_PUNISH,   Punish,                    'c', PUT_long)
% name(45, E_PHYS,     Physio Params,             'c', PUT_float)
% name(46, E_MRI,      Mri,                       'c', PUT_long)
% name(47, E_STIMULATOR, Stimulator Signal,       'c', PUT_long)
%%%% 48-127		System events
%%%% 128-255	User events
% see essmri.h, essmri.c
% #define E_FLOATS_1       128
% #define E_FLOATS_2       129
% #define E_FLOATS_3       130
% #define E_FLOATS_4       131
% #define E_FLOATS_5       132
% #define E_STRINGS_1      133
% #define E_STRINGS_2      134
% #define E_STRINGS_3      135
% #define E_INJECTION      141

% #define E_POSTURE        151  // body movement event
% #define E_BMPARAMS       152  // body movement parameters for alert fMRI

% #define E_VDAQSTIMREADY  171  // Imager-3001: Stim-Ready signal
% #define E_VDAQSTIMTRIG   172  // Imager-3001: Stim-Trigger signal
% #define E_VDAQGO         173  // Imager-3001: GO signal
% #define E_VDAQFRAME      174  // Imager-3001: FRAME signal

% #define E_REVCORR_INFO   191  // for reverse correlation
% #define E_REVCORR_UPDATE 192
%
%  
% ====================================================================
% QNX Event Subtypes
% ====================================================================
%   /* Enumerated SUBTYPE names for consistency between event files */
% enum { E_USER_START, E_USER_QUIT, E_USER_RESET, E_USER_SYSTEM };
% enum { E_TRACE_ACT, E_TRACE_TRANS, E_TRACE_WAKE, E_TRACE_DEBUG };
% enum { E_PARAM_NAME, E_PARAM_VAL };
% enum { E_ID_ESS, E_ID_SUBJECT };
% enum { E_EMLOG_STOP, E_EMLOG_START, E_EMLOG_RATE };
% enum { E_FIXSPOT_OFF, E_FIXSPOT_ON, E_FIXSPOT_SET };
% enum { E_EMPARAMS_SCALE, E_EMPARAMS_CIRC, E_EMPARAMS_RECT };
% enum { E_STIMULUS_OFF, E_STIMULUS_ON, E_STIMULUS_SET };
% enum { E_PATTERN_OFF, E_PATTERN_ON, E_PATTERN_SET };
% enum { E_SAMPLE_OFF, E_SAMPLE_ON, E_SAMPLE_SET };
% enum { E_PROBE_OFF, E_PROBE_ON, E_PROBE_SET };
% enum { E_CUE_OFF, E_CUE_ON, E_CUE_SET };
% enum { E_TARGET_OFF, E_TARGET_ON };
% enum { E_DISTRACTOR_OFF, E_DISTRACTOR_ON };
% enum { E_FIXATE_OUT, E_FIXATE_IN };
% enum { E_RESP_LEFT, E_RESP_RIGHT, E_RESP_BOTH, E_RESP_NONE, E_RESP_MULTI, E_RESP_EARLY };
% enum { E_ENDTRIAL_INCORRECT, E_ENDTRIAL_CORRECT, E_ENDTRIAL_ABORT };
% enum { E_ABORT_EM, E_ABORT_LEVER, E_ABORT_NORESPONSE };
% enum { E_ENDOBS_WRONG, E_ENDOBS_CORRECT, E_ENDOBS_QUIT };
% enum { E_PHYS_RESP, E_PHYS_SPO2, E_PHYS_AWPRESSURE, E_PHYS_PULSE };
% enum { E_MRI_TRIGGER };
%
% ====================================================================


  
% ====================================================================
% QNX Event Types
% ====================================================================
evt.BeginObsp		= 19;

evt.EndObsp			= 20;
evt.Isi				= 21;
evt.TrialType		= 22;
evt.ObspType		= 23;
evt.Emlog			= 24;
evt.Fixspot			= 25;
evt.EmParams		= 26;
evt.Stimulus		= 27;
evt.Pattern			= 28;
evt.Stimtype		= 29;

evt.Cue				= 32;
evt.Target			= 33;
evt.Distractor		= 34;
evt.Sound			= 35;
evt.Fixate			= 36;
evt.Response		= 37;

evt.EndTrial		= 40;
evt.Abort			= 41;
evt.Reward			= 42;
evt.Delay			= 43;
evt.Punish			= 44;
evt.Mri				= 46;


% NEW MRI STIM SYSTEM since Apr.03
% user events, SEE essmri2.h
evt.Floats_1		= 128;
evt.Floats_2		= 129;
evt.Floats_3		= 130;
evt.Floats_4		= 131;
evt.Floats_5		= 132;
evt.Strings_1		= 133;
evt.Strings_2		= 134;

evt.Injection		= 141;
evt.Posture			= 151;
evt.BmParams		= 152;
evt.VdaqStimReady	= 171;
evt.VdaqStimTrig	= 172;
evt.VdaqGo			= 173;
evt.VdaqFrame		= 174;
evt.RevcorrInfo		= 191;
evt.RevcorrUpdate	= 192;
evt.ScreenInfo      = 201;

% ====================================================================
% QNX Event SubTypes
% ====================================================================
evt.sub.all			= -1;
evt.sub.MriTrigger	= 0;

evt.sub.EmScale     = 0;
evt.sub.EmCirc      = 1;
evt.sub.EmRect      = 2;
 
evt.sub.FixspotOff	= 0;
evt.sub.FixspotOn	= 1;
evt.sub.FixspotSet	= 2;

evt.sub.StimulusOff	= 0;
evt.sub.StimulusOn	= 1;
evt.sub.StimulusSet	= 2;
% this is NKL state system difinition....
evt.sub.NKLPreStimulus = 1;
evt.sub.NKLStimulusOn	= 2;
evt.sub.NKLStimulusOff	= 3;


evt.sub.PatternOff	= 0;
evt.sub.PatternOn	= 1;
evt.sub.PatternSet	= 2;

evt.sub.SampleOff	= 0;
evt.sub.SampleOn	= 1;
evt.sub.SampleSet	= 2;

evt.sub.ProbeOff	= 0;
evt.sub.ProbeOn		= 1;
evt.sub.ProbeSet	= 2;

evt.sub.CueOff		= 0;
evt.sub.CueOn		= 1;
evt.sub.CueSet		= 2;

evt.sub.TargetOff	= 0;
evt.sub.TargetOn	= 1;

evt.sub.DistractorOff	= 0;
evt.sub.DistractorOn	= 1;

evt.sub.FixateOut	= 0;
evt.sub.FixateIn	= 1;

evt.sub.RespLeft	= 0;
evt.sub.RespRight	= 1;
evt.sub.RespBoth	= 2;
evt.sub.RespNone	= 3;
evt.sub.RespMulti	= 4;
evt.sub.RespEarly	= 5;

evt.sub.AbortEm		= 0;
evt.sub.AbortLever	= 1;
evt.sub.AbortNoResp	= 2;

% enum { E_ENDTRIAL_INCORRECT, E_ENDTRIAL_CORRECT, E_ENDTRIAL_ABORT };
evt.sub.EndTrialIncorrect = 0;
evt.sub.EndTrialCorrect   = 1;
evt.sub.EndTrialAbort     = 2;

evt.sub.EndobsWrong	  = 0;
evt.sub.EndobsCorrect = 1;
evt.sub.EndobsQuit	  = 2;


% specific to essmri2.h
evt.sub.PreStim		= 1;
evt.sub.OnStim		= 2;
evt.sub.OffStim		= 3;
