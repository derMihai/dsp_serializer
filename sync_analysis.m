clear signals;

signals = {
%     'matcher_match', 'single';
%     'matcher_valid', 'single';
%     'matcher_en', 'single';
%     'matcher_reset', 'single';
    
%     'out.set_NOT_MATCHING', 'single';
%     'out.set_MATCHING', 'single';
%     'out.set_MATCHING_END', 'single';
%     'out.set_SYNC', 'single';

    'data_in', 'single';
    'matcher_reset', 'single';
    'data_en', 'single';
    'out.NOT_MATCHING', 'single';
    'out.MATCHING', 'single';
    'out.MATCHING_END', 'single';
    'out.SYNC', 'single';
    'out.MATCH_LEN', 'bus_value_d';
    'out.data', 'bus_value_h';
    'out.data_n', 'bus_value_h';
    'out.match', 'single';
    'out.valid', 'single';
};

DispTime=0;
LaPlot(signals,[DispTime,DispTime+40,1]);