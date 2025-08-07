

% matcher_match = zeros(1, N_sym);
% matcher_valid = zeros(1, N_sym);
% matcher_en    = zeros(1, N_sym);

sym_rx = load("sym_rx.mat").sym_rx;

% sym_reset = [1 ones(1, 1) zeros(1, N_sym-1)];

data_in = kron(sym_rx, [1, 0, 0, 0]);
valid_in= zeros(size(data_in));
valid_in(1:4:end) = 1;

N_sym = length(data_in);
