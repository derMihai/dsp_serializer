N_dft = 10;

%data_in = [0 1 1 1 0 0 0 0 1 1 1 0 0 0 0 0 1 1 1 0 0 0 1 0 0 1 0 0 1 0 0 1 1 0 0 0 ];
%data_en = [0 1 0 0 1 1 0 0 1 0 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 1 1 1 0 1 1];
%data_en = zeros(length(data_in), 1) + 1;

tx_bytes = [bin2dec('0100 0111'), 1, 2, 3, 12, 13, 14];         % Synchronsequenz und zu übertragende Datenbytes

tx_bit_array = dec2bin(tx_bytes, 8).';              % Umwandlung der Bytes in Binärzahlen '0' und '1'
tx_bit_array = double(tx_bit_array == '1');         % Umwandlung der Binärwerte von char zu double
tx_bit_array_lsb_first = flipud(tx_bit_array);
tx_bit_stream = tx_bit_array_lsb_first(:); 

syms = tx_bit_stream;

man_overs = zeros(length(syms) * N_dft, 1);
bit_begin = zeros(length(man_overs), 1);
bit_begin(1:N_dft:end) = 1;
bit_begin(2:N_dft*8:end) = 1;

for i = 1:1:length(syms)
    for j = 1:1:N_dft
        man_overs((i - 1) * N_dft + j) = syms(i);
    end
end

data_in = man_overs;
data_en = zeros(length(data_in), 1) + 1;

N_sim = length(data_in);

