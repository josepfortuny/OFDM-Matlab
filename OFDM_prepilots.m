%OFDM modulation with 16QAM subcarriers
    %OFDM(nsize,channel_BW,AWGN,Multipath) is the OFDM modulation of nsize bits in a
    %channel with channel_BW bandwith (3000 or 6000 Hz only)
    %AWGN boolean (1/0) to add AWGN noise to the channel or not
    %Multipaht boolean (1/0) to add Multipath effect to the channel or not


function OFDM(nsize,BW_ofdm,bool,bool2)          % Numero bits a enviar OFDM

%%Emisor
M = 16;    % QAM-16
f_sample = 100000; %Frecuencia de muestreo en Banda Base

% if BW_ofdm ~= 3000 || 6000
%     fprintf('ERROR: Channel BW have to be 3kHz or 6kHz only');
% end

n_s = nsize/log2(M); %Numero de símbolos OFDM totales
delay_spread = 2*1e-3;  %VALOR EJEMPLO
T_max_delayspread = delay_spread; %tiempo del prefijo cíclico
T_s = 10*T_max_delayspread; %tiempo de simbolo (eficiencia 90%) 
delta_f = 1/T_s; %espacio entre portadoras 
n_sc = BW_ofdm/delta_f; % NUMERO TOTAL DE SUBCARRIERS
T_dopp = 10*T_s; %Tiempo de Doppler

T_CP = floor(T_max_delayspread*BW_ofdm);    %Tiempo de CP (numero de subcarrier a copiar al principio)

%Generamos un vector de datos decimal aleatorio
data = randi([0 15],1,nsize);
data_orig = data;   %Guardamos en un vector la informacion original


%DE-BINARIO
data_bi = de2bi(data',4,"left-msb");
data_bi = reshape(data_bi',1,[]); %pasamos a vector 


%ENCODER (Trellis)
constlen = 7; %Longitud de la constelacion 
codegen = [171 133];    % Polinomio generador
trellis = poly2trellis(constlen, codegen);  %Creamos trellis
data_zero = zeros(1,length(data_bi)+constlen);  %AÑADIMOS ZEROS PARA INICIALIZAR LOS REGISTROS
data_zero(constlen+1:end) = data_bi(1:end);
codedata = convenc(data_zero, trellis);  %convolucion 
%añadir X ceros al principio
intrlv_data = codedata;

% %INTERVLEVING
% nrows = 3;  %numero de filas a convolucionar 
% slope  = 2; %delay por registro (en numero de muestras)
% nzeros = nrows*(nrows-1)*slope;
% data_zero = zeros(1,length(codedata)+nzeros);   %Añadimos tantos ceros como delay tiene el intrl
% data_zero(1:(end-nzeros)) = codedata(1:end);      %al final antes de hacer el intrlv
% intrlv_data = convintrlv(data_zero,nrows,slope);  %hacemos el interliving

zero_padding = 0;
while rem(length(intrlv_data),(n_sc*4)) ~= 0 %Creamos un tamaño de vector factor del tamañao de bits de símbolo
    intrlv_data(length(intrlv_data)+1) = 0;
    zero_padding = zero_padding+1;
end


intrlv_data = vec2mat(intrlv_data,4);    %Ponemos simbolos de 4
data_de = bi2de(intrlv_data,"left-msb");    %volvemos a pasar a decimal 
data_de = data_de';



%CALCULO DE N COLUMNAS
n_colum = length(data_de)/n_sc;
n_colum = ceil(n_colum); 

%MODULATION
data_modulated = qammod(data_de,M);
figure(1)
scatterplot(data_modulated);
matrix = reshape(data_modulated,n_sc,n_colum); %Matriz de simbolos

%CARRIER NULL
matrix_CN = zeros((n_sc+1),n_colum);      %Añadimos Carrier NULL 
matrix_CN(2:end,1:end)= matrix(1:end,1:end);

matrix_ifft = ifft(matrix_CN,[],1);  %IFFT
figure(2)
plot(real(matrix_ifft));
sum(real(matrix_ifft))



matrix_new = zeros((T_CP + n_sc+1),n_colum);        %Añadimos Cyclic Prefix  (CP)
matrix_new(1:T_CP,1:end) = matrix_ifft((n_sc - T_CP + 1):n_sc,1:end);
matrix_new(T_CP+1:end,1:end) = matrix_ifft (1:end,1:end);
    
    
%INTERP USAR PARA SUBIR EL BW DE LA SEÑAL O RESAMPLE

signal_vector = reshape(matrix_new,1,[]);  %Pasamos a vector
signal_ofdm = interp(signal_vector,ceil(f_sample/BW_ofdm));     %Interpolasmos para subier la f_sample a la del canal

%% CHANNEL 

Rb = BW_ofdm * log2(M);             %BW * 4 bits;
EbNo = (0:1:30);
SNR = EbNo + 10*log10(Rb/BW_ofdm);
BER = zeros(1,length(SNR));

t = (0:length(signal_ofdm)/f_sample);    %vector tiempo

imp_resp = zeros(1,length(t));
imp_resp(1) = 0.76;
imp_resp(t == 0.00168) = 0.45+0.2j;


for n = 1:length(SNR)
    
    if(bool == 1)
        signal_noisy = awgn(signal_ofdm,SNR(n),'measured');           %add ruido gausiano a la señal
        %SNR dado Eb/No dado = (Eb*Rb)/(B*No), donde B es el ancho de banda de la
        %senal con ruido y Rb es el bitrate. 
        
    elseif(bool == 0)
        signal_noisy = signal_ofdm; 
    else
        fprintf("ERROR: USE 1 to add AWGN noise and 0 to not to do");
    end
    
    if(bool2 == 1)
        signal_noisy = filter(1,imp_resp,signal_noisy(1:end));   %Pasamos por la Resp impulso del canal
    elseif(bool2 == 0)
        %Do NOTHING
    else
        fprintf("ERROR: USE 1 to add Multipath effect and 0 to not to do");
    end
    
    
    
    signal_decimate = downsample(signal_noisy,ceil(f_sample/BW_ofdm));  %Diezmamos la señal
    signal_decimate = reshape(signal_decimate,size(matrix_new,1),size(matrix_new,2));              %Pasamos a matriz
    signal_noisy_CP = signal_decimate((size(signal_decimate,1)-n_sc):end,1:end);                    %Quito CP 
    signal_noisy_fft = fft(signal_noisy_CP,[],1);                       %FFT 
    signal_demod_CN = signal_noisy_fft(2:end,1:end);  %Eliminamos el CN
    signal_demod_noisy = qamdemod(signal_demod_CN,M);                  %DEMOD
    
    %(size(signal_decimate,1)-n_sc):end
    %VECTOR  
    signal_demod_noisy = reshape(signal_demod_noisy,[],1);  %Pasamos a vector 
    
    %Pasamos a Binario
    signal_demod_bi = de2bi(signal_demod_noisy,4,"left-msb");
    signal_demod_bi = reshape(signal_demod_bi',1,[]);
    
    %ELIMINAMOS EL CERO PADDING 
    signal_demod_zero = signal_demod_bi(1:(length(signal_demod_bi)-zero_padding)); %Eliminamos zero padding
    
%     %DE-Interleaving
%     deintrlv_data = convdeintrlv(signal_demod_zero,nrows,slope);
%     deintrlv_data = deintrlv_data(1:(end-nzeros));    %Eliminamos los zeros
    
    %DECODING 
    decode_data = vitdec(signal_demod_zero,trellis,7,'trunc','hard'); 
    %TBLEN: inter positivo que especifica la profundidad del trazado
    %trunc: el codificador asume haber empezado en el estado cero. 
    %El decodificador vuelve a trazar desde ese estado con la mejor metria.
    %hard: el decodificador espera un input binario
    decode_data = decode_data(constlen+1:end);  %eliminamos los zeros

    decode_data = vec2mat(decode_data,4);    %Ponemos simbolos de 4
    decode_data_de = bi2de(decode_data,"left-msb");    %volvemos a pasar a decimal 
    decode_data_de = decode_data_de';
    
    n_bit_error = biterr(decode_data_de,data_orig);          %Calculamos BER
    BER(n) = n_bit_error/(nsize*log2(M)); 
end

figure(3)
semilogy(EbNo,BER)
title('EbNo en funcion del BER')
ylabel('BER');
xlabel('EbNo (dB)');

end

    
