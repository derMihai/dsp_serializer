%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulation der GFSK Daten�bertragung
% IDS Projekt, A.K.
% Version 2.0, 15. 07. 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ExportDiagrams = 0;	% Auf 1 setzen, um .pdf-Diagramme zu erzeugen

tx_bytes = [bin2dec('0100 0111'), 1, 2, 3, 12, 13, 14];         % Synchronsequenz und zu �bertragende Datenbytes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulation des Senders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tx_bit_array = dec2bin(tx_bytes, 8).';              % Umwandlung der Bytes in Bin�rzahlen '0' und '1'
tx_bit_array = double(tx_bit_array == '1');         % Umwandlung der Bin�rwerte von char zu double
tx_bit_array_lsb_first = flipud(tx_bit_array);
tx_bit_stream = tx_bit_array_lsb_first(:);          % Serialisierung der Bytes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Manchester Encoder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tx_bit_stream_2 = kron(tx_bit_stream, [1;1]);       % Verdopplung jedes Datenbits
DataClock = zeros(size(tx_bit_stream_2));           % Erzeugung des Taktsignals zur Synchronisation der Daten
DataClock(1:2:end) = 1;
Manchester_bits = xor(tx_bit_stream_2, DataClock);  % Manchester Codierung

% Darstellung der Datenbits und der Encodierten Bits
clear signals;
signals = {
    'tx_bit_stream_2','single';
    'DataClock','single';
    'Manchester_bits','single';
};

DispTime=0;
LaPlot(signals,[DispTime,DispTime+40,1]);

% Symbol Mapping: Bitwert 0 => Symbolwert 1, Bitwert 1 => Symbolwert -1
Manchester_symbols = 1 * double(Manchester_bits == 0) + (-1) * double(Manchester_bits == 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pulsformung
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N_clk_per_symbol = 10;                              % Anzahl der Takte pro Symbol
t = (-N_clk_per_symbol:N_clk_per_symbol);           % Zeitskala in ganzzahligen Takteinheiten
gauss_puls = exp(-(t./N_clk_per_symbol).^2 * 4);    % Berechnung der Pulsform

% Pulsformung zu Demonstrationszwecken deaktivieren
if 0
    gauss_puls = zeros(size(gauss_puls));
    gauss_puls(1:N_clk_per_symbol) = 1;
end

figure(2);           
plot(t/N_clk_per_symbol, gauss_puls,'.-');                           % Darstellung der Pulsform 
grid on;
title('Gauss-Pulsform');
xlabel('Zeit (T_{symbol})');
ylabel('Amplitude');

Manch_symb_oversamp = kron(Manchester_symbols, [1; zeros(N_clk_per_symbol-1, 1)]); % �berabtastung der Manchester-encodierten Datensymbole
f_mod = conv(Manch_symb_oversamp, gauss_puls);      % Pulsformung durch Faltung

figure(3);
plot(f_mod,'.-');
grid on;
title('Steuersignal zur Frequenzmodulation');
xlabel('Zeit (T_{samp})');
ylabel('Amplitude');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Modulation auf den 40 kHz Tr�ger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f_samp = 10e6;   % Abtastfrequenz in Hz f�r das modulierte Signal, im Zielsystem 10 MHz
Delta_f = 1e3;  % (halber) Frequenzhub in Hz
R_symbol = 2e3; % Symbolrate in 1/s
f_carrier = 40e3; % Tr�gerfrequenz in Hz

% Upsampling des Modulationssignals auf f_samp
O = f_samp / (R_symbol * N_clk_per_symbol); 
f_mod_us = kron(f_mod, ones(O,1)).';

N = length(f_mod_us); % Anzahl der Abtastwerte des modulierten Signals

% Erzeugung des frequenzmodulierten Sendesignals
f = f_carrier + Delta_f * f_mod_us;
phi = 2*pi * cumsum(f) * 1/f_samp;
u_tx = cos(phi);

figure(4);
plot(u_tx);
grid on;
title('Sendesignal - Zeitbereich');
xlabel('Zeit (T_{samp})');
ylabel('Amplitude');
axis([1,4000, 1.1*min(u_tx), 1.1*max(u_tx)]);

L_u_tx = length(u_tx);
fenster = sin(pi * (0:L_u_tx-1)/L_u_tx).^2;
fenster = fenster / mean(fenster);

U_tx = 1/L_u_tx * fft(u_tx .* fenster);
U_tx_dB = 20*log10(abs(U_tx));

df = f_samp / length(u_tx);
freq_scale = (0:L_u_tx-1) * df;

hf = figure(5);
plot(freq_scale/1e3, 20*log10(abs(U_tx)));
grid on;
title('Sendesignal - Frequenzspektrum', 'fontsize', 20);
xlabel('Frequenz (kHz)', 'fontsize', 20);
ylabel('Amplitude (dB)', 'fontsize', 20);
axis([0, 100, -100 0]);
set(gca, 'fontsize', 16);
if ExportDiagrams == 1
	exportgraphics(hf, 'Frequenzspektrum.pdf');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulation der �bertragung
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SNR_dB = 20;                % gew�nschter SNR-Wert des Empfangssignals nach der Dezimations-Tiefpassfilterung in dB

u_rx_noise_free = u_tx(:).';                                                                                % rauschfreier Empfangssignal-Burst
u_rx_noise_free_delay = [zeros(1, 10*O*N_clk_per_symbol), u_rx_noise_free, zeros(1, 2*O*N_clk_per_symbol)]; % verz�gertes Empfangssignal
P_s = var(u_rx_noise_free);		% Signalleistung
SNR = 10^(SNR_dB/10);			% Reduktion des SNR Wertes wegen des Bandbreitenverh�ltnisses von 10 MHz / 20 kHz
P_noise = P_s / SNR * 10e6 / 20e3;        % Rauschleistungswert, erh�ht wegen des Bandbreitenverh�ltnisses von 10 MHz / 20 kHz
noise = sqrt(P_noise) * randn(size(u_rx_noise_free_delay)); 
u_rx = u_rx_noise_free_delay + noise;                                                                       % Empfangssignal-Vektor

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulation des Empf�ngers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Abw�rtsmischung des Empfangssignals, so dass die untere
% Modulationsfrequenz des Senders (-1kHz) bei +2 kHz liegt. Die obere
% Modulationsfrequenz (+1 kHz) liegt dann bei +4 kHz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f_rx_lo = 37e3;
N_rx = length(u_rx);
u_rx_lo = exp(-1i * 2*pi * f_rx_lo * (0:N_rx-1)/f_samp);
u_iq = u_rx .* (u_rx_lo);

figure(6);
plot([real(u_iq); imag(u_iq)].');
grid on;
title('Abw�rtsgemischtes Empfangssignal');
xlabel('Zeit (T_{samp})');
ylabel('Amplitude');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tiefpassfilterung und Dezimation auf 20 kHz Abtastrate f�r die DFT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f_samp_dft = 20e3;
R_dez = f_samp/f_samp_dft;  % Dezimationsrate am Empf�nger
O_tp = 2*R_dez;             % Filterordnung des Dezimations-Tiefpassfilters

h_tp = (0:floor(O_tp/2));
h_tp = [h_tp, h_tp(end-1: -1: 1)];
h_tp = h_tp / mean(h_tp);

hf = figure(7);
plot(h_tp);
grid on;
title('Impulsantwort Tiefpass-Dezimationsfilter', 'fontsize', 20);
xlabel('Zeit (T_{samp})', 'fontsize', 20);
ylabel('Amplitude', 'fontsize', 20);
set(gca, 'fontsize', 16);
if ExportDiagrams == 1
	exportgraphics(hf, 'Impulsantwort-Dezimationsfilter.pdf');
end

H_tp = 1/length(h_tp) * fft(h_tp, 10*length(h_tp));
dF = f_samp / length(H_tp); % Frequenzintervall der berechneten �bertragungsfunktion
F_scale = (0:length(H_tp)-1) * dF;

hf = figure(8);
plot(F_scale / 1e3, 20*log10(abs(H_tp)));
grid on;
title('�bertragungsfunktion Tiefpass-Dezimationsfilter', 'fontsize', 20);
xlabel('Frequenz (kHz)', 'fontsize', 20);
ylabel('Amplitude', 'fontsize', 20);
axis([0, 100, -80, 5]);
set(gca, 'fontsize', 16);
if ExportDiagrams == 1
	exportgraphics(hf, '�bertragungsfunktion-Tiefpass-Dezimationsfilter.pdf');
end

% Tiefpassfilterung
u_iq_lp = conv(u_iq, h_tp);

figure(9);
plot([real(u_iq_lp); imag(u_iq_lp)].');
grid on;
title('Abw�rtsgemischtes und tiefpassgefiltertes Empfangssignal');
xlabel('Zeit (T_{samp})');
ylabel('Amplitude');

% Dezimation
u_iq_dez = u_iq_lp(1:R_dez:end);

figure(10);
plot([real(u_iq_dez); imag(u_iq_dez)].', '.-');
grid on;
title('Abw�rtsgemischtes, tiefpassgefiltertes und dezimiertes Empfangssignal');
xlabel('Zeit (T_{samp_dez})');
ylabel('Amplitude');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Messung der Signalamplitude des Empfangssignals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
A_instantan = abs(u_iq_dez);
N_average = 20;
A_gemittelt = conv(A_instantan(:), 1/N_average * ones(N_average, 1));

figure(11);
plot(A_instantan);
hold on;
plot(A_gemittelt);
hold off;
legend('Momentanamplitude', 'Gemittelte Amplitude');
grid on;
title('Amplitudenverlauf des Empfangssignals');
xlabel('Zeit (T_{samp, dez})');
ylabel('Amplitude');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Berechnung der Sliding-DFT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F1 = zeros(size(u_iq_dez));
F2 = zeros(size(u_iq_dez));
f1 = 2e3;   % erste Modulationsfrequenz
f2 = 4e3;   % zweite Modulationsfrequenz

N_dft = f_samp_dft/R_symbol;

K = length(u_iq_dez);
for k=1:K
    if k<=N_dft    % Initialisierungsbereich: Die Werte im Delay-Element sind Null
        F1(k+1) = exp(1i * 2*pi * f1/f_samp_dft) * F1(k) + u_iq_dez(k);
        F2(k+1) = exp(1i * 2*pi * f2/f_samp_dft) * F2(k) + u_iq_dez(k);
    else
        F1(k+1) = exp(1i * 2*pi * f1/f_samp_dft) * F1(k) + u_iq_dez(k) - u_iq_dez(k-N_dft);
        F2(k+1) = exp(1i * 2*pi * f2/f_samp_dft) * F2(k) + u_iq_dez(k) - u_iq_dez(k-N_dft);
    end

end

u_detect = abs(F2) - abs(F1);   % Als empfangenes Detektorsignal wird dir Differenz der beiden DFT-Komponenten verwendet 

figure(12);
subplot(2, 1, 1);
plot(abs([F1; F2].'));
grid on;
title('Sliding DFT');
xlabel('Zeit (T_{samp, dez})');
ylabel('Amplitude');
legend('f1','f2');

subplot(2, 1, 2);
plot(u_detect);
grid on;
title('Detektorsignal - Differenz der DFT-Komponenten');
xlabel('Zeit (T_{samp, dez})');
ylabel('Amplitude');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Binarisierung des Detektionssignals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sym_rx = double(u_detect < 0);   % Empfangssymbole

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Synchronisation 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sync_pattern = Manchester_bits(1:16);   % Die Manchsester-Kodierten Bits des ersten Datenbytes werden als Synchronisationswort verwendet

L_sym_rx = length(sym_rx);
sync_result = zeros(1, L_sym_rx);
for n=1:L_sym_rx
    anfang = n-length(sync_pattern)*N_dft;
    ende = anfang + length(sync_pattern)*N_dft - 1;
    if anfang >= 1
        x = sym_rx(anfang:N_dft:ende).';
        if sum(x~=sync_pattern)==0
            sync_result(n) = 1;
        end
    end
end

aux = find(sync_result == 1);
if isempty(aux)
    fprintf('Synchronsequenz nicht gefunden!\n');
else
    sync_start_index = round(1/2 * (aux(1) + aux(end)));
        
    clear signals;
    signals = {
        'sym_rx','single';
        'sync_result','single';
        };
    
    DispTime = max(sync_start_index - 1500, 0);
    LaPlot(signals,[DispTime, DispTime + 3000,1]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Daten auslesen
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    data_start_index = sync_start_index;
    
    N_bits = 8 * (length(tx_bytes)-1);
    end_index = data_start_index + N_bits*N_dft*2 - 1;
    decoded_bits_negiert = ~sym_rx(data_start_index:2*N_dft:end_index);
    decoded_bits_matrix = reshape(decoded_bits_negiert, 8,[]);
    decoded_bytes = 2.^(0:7) * decoded_bits_matrix;
    
    data_start_index = data_start_index + N_dft;
    end_index = data_start_index + N_bits*N_dft*2 - 1;
    decoded_bits = sym_rx(data_start_index:2*N_dft:end_index);
    
    decoded_bits_matrix_2 = reshape(decoded_bits, 8,[]);
    decoded_bytes_2 = 2.^(0:7) * decoded_bits_matrix_2;
    
    N_err = sum(decoded_bits ~= decoded_bits_negiert);
    
    if N_err == 0
        fprintf('Keine �bertragungsfehler\n');
    else
        fprintf('%d �bertragungsfehler\n', N_err);
    end
    decoded_bytes
end
