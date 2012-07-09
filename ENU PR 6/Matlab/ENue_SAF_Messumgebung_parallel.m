%% Initialisiere Matlab
addpath('K');
addpath('SFF');
addpath('SAF');
clc;
load('SimpleSample.mat')

%% Verlaufseinstellungen
SAF=1;          % Wenn 0, dann kein SAF
Simulation=1;   % Wenn 0, dann keine Simulation

%% Datensignal
a= round(rand(1,1000));
%a = [1 1 0 0 1 1 0 0]
%a = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]; 
%a = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
Data=a;
% Kanalcodierung


    NOISEFACTOR = 0;

    BER_1_gemessen = 0;
    BER_1_errechnet = 0;
    SNR_1 = 0;
    BER_2_gemessen = 0;
    BER_2_errechnet = 0;
    SNR_2 = 0;
    BER_3_gemessen = 0;
    BER_3_errechnet = 0;
    SNR_3 = 0;
    

%matlabpool
    
noises = [120 190 210 220 250 230 235 240 w245 250 251 252 253 254 255]   
for setNoise= [120 190 210 220 250 230 235 240 245 250 251 252 253 254 255] 
    
    

    
    
    
        disp('##############################################################')
    disp(setNoise) 

    parfor SFFNr=1:3
            disp('--------------------------------------------------------------')
            
    % SFFNr
            % Kanalcodierung
            if SAF==1
                % SF0 stellt die Sendeform fuer eine 0 dar. Bsp: jede 0 soll durch 
                % [0 1 0] ersetzt werden. Dann muss SF=[0 1 0] sein.
                % SF1 stellt die Sendeform fuer eine 1 dar.
                if SFFNr == 1
                    SF0=            [-1, 1, -1];
                    SF1=            [ 1,-1,  1];
                end

                if SFFNr == 2
                    SF0=            [-1,-1, 1];
                    SF1=            [ 1,-1,-1];
                end

                if SFFNr == 3
                    SF0=            [-1, 1, -1, 1];
                    SF1=            [ 1, 1, -1,-1];
                end

                rho = sum(SF0.*SF1)/length(SF0)

                Data=SFF(a,SF0,SF1);    %Fuehrt die Sendeformung durch. Data wird auf den Kanal gegeben.
            end

    %% Kanal- und Filtereinstellungen
    KanalParameter = struct('SampleRateIdx', 0,'t_bitP', 0)
    KanalParameter.NoiseFactor=setNoise; % Werte von 0 bis 255
    if SAF==1
        FilterParameter = 0
        FilterParameter.SF0=SF0;
        FilterParameter.SF1=SF1;
        FilterParameter.BitBlockLength=numel(SF0);
        KanalParameter.BitGroupLength=numel(SF0);
    end
    
    
        KanalParameter.SampleRate=50e6/(2^KanalParameter.SampleRateIdx);
    

    %% UEbertragung
    [Y,Noise]=Channel(Data,KanalParameter,FilterParameter,abs(Simulation-1));
    if Simulation==0
        ClosePicoScope(KanalParameter.ScopeHandle);
    end

    %% Analyse

    % if length(Y) == length(a)
    %     disp('Länge stimmt')
    % else
    %     disp('Länge stimmt NICHT')
    % end
    % 
    % if Y == a
    %     disp('Yaaaaaay')
    % else
    %     disp('Nooooo')
    % end


    %% Analyse
    Amplitude = 1;% max(a); %betraegt hier 1

    %mittelwert = sum(Noise)/length(Noise); %mittelwert des rauschens
    mittelwert = mean(Noise);

    %Varianz = (sum((Noise-mittelwert).^2))/(length(Noise)) %varianz des rauschens
    Varianz = var(Noise);

    %bestimmt die falsch uebertragenen Bits
    Bitfehler = sum(abs(a-Y));

    BER_gemessen  = Bitfehler/length(a)
    BER_errechnet = 0.5 * erfc(Amplitude/(sqrt(8*Varianz)))

    SNR = 10*log10(Amplitude/Varianz)


    % Speichern

        if SAF==1
            % SF0 stellt die Sendeform fuer eine 0 dar. Bsp: jede 0 soll durch 
            % [0 1 0] ersetzt werden. Dann muss SF=[0 1 0] sein.
            % SF1 stellt die Sendeform fuer eine 1 dar.
            if SFFNr == 1
                %NOISEFACTOR = [NOISEFACTOR Noise]

                BER_1_gemessen = [BER_1_gemessen BER_gemessen];
                BER_1_errechnet = [BER_1_errechnet BER_errechnet];
                SNR_1 = [SNR_1 SNR];
            end

            if SFFNr == 2
                %NOISEFACTOR = [NOISEFACTOR Noise]

                BER_2_gemessen = [BER_2_gemessen BER_gemessen];
                BER_2_errechnet = [BER_2_errechnet BER_errechnet];
                SNR_2 = [SNR_2 SNR];
            end

            if SFFNr == 3
                NOISEFACTOR = [NOISEFACTOR setNoise];

                BER_3_gemessen = [BER_3_gemessen BER_gemessen];
                BER_3_errechnet = [BER_3_errechnet BER_errechnet];
                SNR_3 = [SNR_3 SNR];
            end

        end

    end
    
end

%matlabpool close


% Führende nullen löschen die beim initioalisieren übrig sind
SNR_1 = SNR_1(2:end);
SNR_2 = SNR_2(2:end);
SNR_3 = SNR_3(2:end);

BER_1_gemessen = BER_1_gemessen(2:end)
BER_2_gemessen = BER_2_gemessen(2:end)
BER_3_gemessen = BER_3_gemessen(2:end)

BER_1_errechnet = BER_1_errechnet(2:end)
BER_2_errechnet = BER_2_errechnet(2:end)
BER_3_errechnet = BER_3_errechnet(2:end)


figure(601);
clf(601)
hold on
    plot(SNR_1,BER_1_gemessen,'k');
    plot(SNR_2,BER_2_gemessen,'r');
    plot(SNR_3,BER_3_gemessen,'b');
hold off
legend('roh = -1','roh = -1/3','roh = 0')
grid();
 
 
BER_gemessen_SFFNr_1_log = 10*log10(BER_1_gemessen);
BER_gemessen_SFFNr_2_log = 10*log10(BER_2_gemessen);
BER_gemessen_SFFNr_3_log = 10*log10(BER_3_gemessen);
 
figure(602);
clf(602)
hold on
    semilogy(SNR_1,BER_gemessen_SFFNr_1_log,'k');
    semilogy(SNR_2,BER_gemessen_SFFNr_2_log,'r');
    semilogy(SNR_3,BER_gemessen_SFFNr_3_log,'b');
hold off
legend('roh = -1','roh = -1/3','roh = 0')
grid();



% figure(601);
% hold on
%     plot(SNR_1,BER_1_gemessen,'*');
%     plot(SNR_2,BER_2_gemessen,'x');
%     plot(SNR_3,BER_3_gemessen,'o');
% hold off
% legend('roh = -1','roh = -1/3','roh = 0')
% grid();
%  
%  
% BER_gemessen_SFFNr_1_log = 10*log10(BER_1_gemessen);
% BER_gemessen_SFFNr_2_log = 10*log10(BER_2_gemessen);
% BER_gemessen_SFFNr_3_log = 10*log10(BER_3_gemessen);
%  
% figure(602);
% hold on
%     semilogy(SNR_1,BER_gemessen_SFFNr_1_log,'*');
%     semilogy(SNR_2,BER_gemessen_SFFNr_2_log,'x');
%     semilogy(SNR_3,BER_gemessen_SFFNr_3_log,'o');
% hold off
% legend('roh = -1','roh = -1/3','roh = 0')
% grid();


savefile = ['Messdaten/Daten_',datestr(clock, 'HHMMSS')];

save(savefile, 'NOISEFACTOR', 'BER_1_errechnet', 'BER_1_gemessen', 'BER_2_errechnet', 'BER_2_gemessen', 'BER_3_errechnet', 'BER_3_gemessen', 'SNR_1', 'SNR_2', 'SNR_3')


