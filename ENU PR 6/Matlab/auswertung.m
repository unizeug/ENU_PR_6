

SIM = 1;
SAVE = 0;

if SIM == 1
    load ../Messdaten/Daten_113502_gut.mat
else
%    load ../Messdaten/
end


if SIM == 1

    figure(600);
    clf()
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

    figure(601);
    clf()
    hold on
        semilogy(SNR_1,BER_gemessen_SFFNr_1_log,'k');
        semilogy(SNR_2,BER_gemessen_SFFNr_2_log,'r');
        semilogy(SNR_3,BER_gemessen_SFFNr_3_log,'b');
    hold off
    legend('roh = -1','roh = -1/3','roh = 0')
    grid();

else

    figure(602);
    clf()
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

    figure(603);
    clf()
    hold on
        semilogy(SNR_1,BER_gemessen_SFFNr_1_log,'k');
        semilogy(SNR_2,BER_gemessen_SFFNr_2_log,'r');
        semilogy(SNR_3,BER_gemessen_SFFNr_3_log,'b');
    hold off
    legend('roh = -1','roh = -1/3','roh = 0')
    grid();

end


if save == 1
    if Sim == 1
        
        figure(600);
        print -painters -dpdf -r600 ../Bilder/Simulation_Wasserfall.pdf
        figure(601);
        print -painters -dpdf -r600 ../Bilder/Simulation_Wasserfall_log.pdf
        
    else
        
        figure(600);
        print -painters -dpdf -r600 ../Bilder/Simulation_Wasserfall.pdf
        figure(601);
        print -painters -dpdf -r600 ../Bilder/Simulation_Wasserfall_log.pdf
        
    end
end




