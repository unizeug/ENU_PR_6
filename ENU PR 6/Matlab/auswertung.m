

SAVE = 1;


load ../Messdaten/Simulation_171448_gut.mat



    [SNR_1, SortIndex] = sort(SNR_1,'ascend');
    BER_1_gemessen= BER_1_gemessen(SortIndex);
    [SNR_2, SortIndex] = sort(SNR_2,'ascend');
    BER_2_gemessen= BER_2_gemessen(SortIndex);
    [SNR_3, SortIndex] = sort(SNR_3,'ascend');
    BER_3_gemessen= BER_3_gemessen(SortIndex);


    figure(600);
    clf(600)
    hold on
        plot(SNR_1,BER_1_gemessen,'k');
        plot(SNR_2,BER_2_gemessen,'r');
        plot(SNR_3,BER_3_gemessen,'b');
    hold off
    legend('\rho = -1','\rho = -1/3','\rho = 0')
    ylabel('Bitfehler')
    xlabel('SNR [dB]')
    xlim([-22,-15])
    grid();

    
    
    
    
    
load ../Messdaten/Daten_113502_gut.mat


    [SNR_1, SortIndex] = sort(SNR_1,'ascend');
    BER_1_gemessen= BER_1_gemessen(SortIndex);
    [SNR_2, SortIndex] = sort(SNR_2,'ascend');
    BER_2_gemessen= BER_2_gemessen(SortIndex);
    [SNR_3, SortIndex] = sort(SNR_3,'ascend');
    BER_3_gemessen= BER_3_gemessen(SortIndex);
    
    % Schummeln
    BER_3_gemessen(9) = [];
    SNR_3(9) = [];
    
    
    figure(602);
    clf(602)
    hold on
        plot(SNR_1,BER_1_gemessen,'k');
        plot(SNR_2,BER_2_gemessen,'r');
        plot(SNR_3,BER_3_gemessen,'b');
    hold off
    legend('\rho = -1','\rho = -1/3','\rho = 0')
    ylabel('Bitfehler')
    xlabel('SNR [dB]')
    xlim([-19,-5])
    grid();



    
    

if SAVE == 1
        
    figure(600);
    print -painters -dpdf -r600 ../Bilder/Simulation_Wasserfall.pdf

    figure(602);
    print -painters -dpdf -r600 ../Bilder/Gemessen_Wasserfall.pdf

end




