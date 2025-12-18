function Pstate = configPstate_perGrater()

%Ian Nauhaus

%periodic grater

Pstate = struct; %clear it

Pstate.type = 'PG';

Pstate.param{1} = {'predelay'  'float'      2       0                'sec'};    % 2
Pstate.param{2} = {'postdelay'  'float'     2       0                'sec'};    % 2
Pstate.param{3} = {'stim_time'  'float'     5       0                'sec'};    % 1

Pstate.param{4} = {'x_pos'       'int'      1280       0                'pixels'};   % 600  center of pattern in pixe;s
Pstate.param{5} = {'y_pos'       'int'      720       0                'pixels'};   % 400   from bottom
Pstate.param{6} = {'x_size'      'float'      90       1                'deg'}; % 3
Pstate.param{7} = {'y_size'      'float'      90       1                'deg'}; % 3
Pstate.param{8} = {'mask_type'   'string'   'none'       0                ''};      % disc, gauss, none
Pstate.param{9} = {'mask_radius' 'float'      6       1                'deg'};
Pstate.param{10} = {'x_zoom'      'int'   1       0                ''};
Pstate.param{11} = {'y_zoom'      'int'   1       0                ''};

Pstate.param{12} = {'altazimuth'   'string'   'none'       0                ''};        % altitude,  azimuth, none
Pstate.param{13} = {'tilt_alt'   'int'   0       0                'deg'};
Pstate.param{14} = {'tilt_az'   'int'   0      0                'deg'};
Pstate.param{15} = {'dx_perpbis'   'float'   0       0                'cm'};
Pstate.param{16} = {'dy_perpbis'   'float'   0      0                'cm'};

Pstate.param{17} = {'background'  'int'   128       0                ''};     % 128
Pstate.param{18} = {'contrast'    'float'     100       0                '%'};

Pstate.param{19} = {'ori'         'int'        0       0                'deg'};

Pstate.param{20} = {'separable'   'int'     1       0                'bit'};        % 0
Pstate.param{21} = {'st_profile'  'string'   'sin'       0                ''};       % sin, square, pulse
Pstate.param{22} = {'st_phase'    'float'        180       0                'deg'};

Pstate.param{23} = {'s_freq'      'float'      0.02      -1                 'cyc/deg'};  % 1
Pstate.param{24} = {'s_profile'   'string'   'sin'       0                ''};          % sin, square, pulse, checker
Pstate.param{25} = {'s_duty'      'float'   0.2       0                ''};         % 0.5
Pstate.param{26} = {'s_phase'      'float'   0.0       0                'deg'};

Pstate.param{27} = {'t_profile'   'string'   'sin'       0                ''};
Pstate.param{28} = {'t_duty'      'float'   0.5       0                ''};
Pstate.param{29} = {'t_period'    'int'       300       0                'frames'};      % 20
Pstate.param{30} = {'t_phase'      'float'   0.0       0                'deg'};

Pstate.param{31} = {'noise_bit'      'int'   0       0                ''};
Pstate.param{32} = {'noise_amp'      'float'   100       0                '%'};
Pstate.param{33} = {'noise_width'    'int'   5       0                'deg'};
Pstate.param{34} = {'noise_lifetime' 'float'   10       0             'frames'};
Pstate.param{35} = {'noise_type' 'string'   'random'       0             ''};

Pstate.param{36} = {'redgain' 'float'   1       0             ''};
Pstate.param{37} = {'greengain' 'float'   1       0             ''};
Pstate.param{38} = {'bluegain' 'float'   1       0             ''};
Pstate.param{39} = {'redbase' 'float'   .5       0             ''};
Pstate.param{40} = {'greenbase' 'float'   .5       0             ''};
Pstate.param{41} = {'bluebase' 'float'   .5       0             ''};
Pstate.param{42} = {'colormod'    'int'   1       0                ''};

Pstate.param{43} = {'mouse_bit'    'int'   0       0                ''};

Pstate.param{44} = {'eye_bit'    'int'   1       0                ''};
Pstate.param{45} = {'Leye_bit'    'int'   1       0                ''};
Pstate.param{46} = {'Reye_bit'    'int'   1       0                ''};

%Plaid variables
Pstate.param{47} = {'plaid_bit'    'int'        0       0             ''};      % 0
Pstate.param{48} = {'contrast2'    'float'     100       0                '%'};  % 10
Pstate.param{49} = {'ori2'         'int'        90       0                'deg'}; % 90
Pstate.param{50} = {'st_phase2'         'float'        180       0                'deg'};
Pstate.param{51} = {'st_profile2'  'string'   'sin'       0                ''};         % sin, square, pulse
Pstate.param{52} = {'s_freq2'      'float'      1      -1                 'cyc/deg'};
Pstate.param{53} = {'s_profile2'   'string'   'sin'       0                ''};         
Pstate.param{54} = {'s_duty2'      'float'   0.5       0                ''};
Pstate.param{55} = {'s_phase2'         'float'        0       0                'deg'};
Pstate.param{56} = {'t_profile2'   'string'   'sin'       0                ''};
Pstate.param{57} = {'t_duty2'      'float'   0.5       0                ''};
Pstate.param{58} = {'t_phase2'         'float'        0       0                'deg'};

Pstate.param{59} = {'sound_type'      'float'   0       0                ''};
Pstate.param{60} = {'tone_freq'      'float'   200       0                'Hz'};

