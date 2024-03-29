%% 4. Plant model identification
%% 4.0 Initialization
clear;
% ---------------------------------------------------------------------- %
% --------------------------- SET PARAMETERS --------------------------- %
RUN = 18;
% ---------------------------------------------------------------------- %
% ---------------------------------------------------------------------- %
folder = sprintf("./DATA/4_PlantModelIdentification%02d/",RUN);
% Create directory
mkdir(folder);
mkdir(folder+"filterTuning");
mkdir(folder+"polesZerosTrue");
% Save directory path
save(folder+"RUN.mat",...
    'RUN','folder');
%% 4.1 Generate input signals ------------------------------------------ %
clear;
% ---------------------------------------------------------------------- %
% --------------------------- SET PARAMETERS --------------------------- %
RUN = 18;
T = 300;%T = 120; %(s) Duration of the stimulus
Nfs = 1; % number of frequencies to test
Nu = 6; % number of input signals (has to be even)
uB_RBS_span = [0.01 0.03]; % (Hz) % Define PRBS bandwidth 
uf_square_span = [0.01 0.03]; % (Hz) % Define square wave frequency
%fs_span = [100 1000];
% ---------------------------------------------------------------------- %
% ---------------------------------------------------------------------- %
% Load directory path
load(sprintf("./DATA/4_PlantModelIdentification%02d/"+"RUN.mat",RUN),...
    'folder');
% Linear
% fs = 500:-:50 %(Hz)
% Logarithmic vector of sampling frequencies to test
%fs = 10.^(log10(fs_span(1)):(log10(fs_span(2))-log10(fs_span(1)))/(Nfs-1):...
    %log10(fs_span(2))); %(Hz)
fs = 50;
Ts = 1./fs; % (s) vector of sampling interval frequencies
t = cell(Nfs,1);
 % Generate time spans for different sampling frequencies
for i = 1:Nfs
    t{i,1} = (0:1/fs(i):T)';
end
% Generate open loop input signals
tic;
% uB_PRBS = 0.03;
% uf_square = 0.03;
uB_PRBS = (uB_RBS_span(1):...
    (uB_RBS_span(2)-uB_RBS_span(1))/(Nu/2-1):uB_RBS_span(2))'; 
uf_square = (uf_square_span(1):...
    (uf_square_span(2)-uf_square_span(1))/(Nu/2-1):uf_square_span(2))'; 
u = cell(Nu,Nfs);
for j = 1:Nfs
    for i = 1:Nu
        if i<= Nu/2
            u{i,j} = idinput(length(t{j,1}),'prbs',[0 uB_PRBS(i)]); 
        else
            u{i,j} = square(2*pi*uf_square(i-Nu/2)*t{j,1});
        end
    end
end
toc;
% Save input signals
save(folder+"inputSignals.mat",...
    'T','Nfs','fs','Ts','t','Nu','uB_PRBS','uf_square','u',...
    'uB_RBS_span','uf_square_span');
%% 4.2 Simulate systems with selected input signals
clear;
% ---------------------------------------------------------------------- %
% --------------------------- SET PARAMETERS --------------------------- %
RUN = 18;
% ---------------------------------------------------------------------- %
% ---------------------------------------------------------------------- %
% Load directory path
load(sprintf("./DATA/4_PlantModelIdentification%02d/"+"RUN.mat",RUN),...
    'folder');
% Load input signals
load(folder+"inputSignals.mat",...
    'T','Nfs','Ts','t','Nu','u');
% Simulate system response 
tic;
y = cell(Nu,Nfs);
for j = 1:Nfs
    for i = 1:Nu
        y{i,j} = simOpenLoop(t{j,1},u{i,j},Ts(j));
    end
end
toc;
% Save raw responses
save(folder+"inputSignalsResponse.mat",...
    'y');
%% 4.3 Preprocessing --------------------------------------------------- %
clear;
% ---------------------------------------------------------------------- %
% --------------------------- SET PARAMETERS --------------------------- %
RUN = 18;
isTuning = false;
% ---------------------------------------------------------------------- %
% ---------------------------------------------------------------------- %
% Load directory path
load(sprintf("./DATA/4_PlantModelIdentification%02d/"+"RUN.mat",RUN),...
    'folder');
% Load number of input signals
load(folder+"inputSignals.mat",...
    'Nfs','Nu','t','u','fs');
% Load raw responses
load(folder+"inputSignalsResponse.mat",...
    'y');
if isTuning
    % Filter tuning tune lambda
    % Select input signal to tune lambda
    i = 6; j = 1;
    lambda = 0.7:0.05:0.95;
    lambda = [0 lambda]; % Unfiltered
    yf = cell(length(lambda),1);
    for k = 1:length(lambda)
        Afilter = [1 -lambda(k)];
        Bfilter = (1-lambda(k))*[1 -1];
        yf{k,1} = filter(Bfilter,Afilter,y{i,j});
    end
    yl = [inf inf]; % conatnt y axis limits
    for k = 0:length(lambda)
        figure('units','normalized','outerposition',[0 0 1 1]);
        hold on;
        set(gca,'FontSize',35);
        yyaxis left;
        plot(t{j,1}(round(length(t{j,1})/14):2*round(length(t{j,1})/14)),...
            u{i,j}(round(length(t{j,1})/14):2*round(length(t{j,1})/14)),...
            'Linewidth',4);
        if k
            title("$\lambda = $ "+sprintf("%g",lambda(k))+...
            "$\;|\;i =$ "+sprintf("%02d",i)+...
            "$\;|\;j =$ "+sprintf("%02d",j),'Interpreter','latex');
        else
            title("w/o detrend"+...
            "$\;|\;i =$ "+sprintf("%02d",i)+...
            "$\;|\;j =$ "+sprintf("%02d",j),'Interpreter','latex');
        end
        ylabel('$u$ (V)','Interpreter','latex');
        yyaxis right;
        ax = gca;
        ax.XGrid = 'on';
        ax.YGrid = 'on';
        if k 
            plot(t{j,1}(round(length(t{j,1})/14):2*round(length(t{j,1})/14)),...
            yf{k,1}(round(length(t{j,1})/14):2*round(length(t{j,1})/14)),...
            'Linewidth',4);
            ylabel('$y_f$ (rad)','Interpreter','latex');
        else
            plot(t{j,1}(round(length(t{j,1})/14):2*round(length(t{j,1})/14)),...
            y{i,j}(round(length(t{j,1})/14):2*round(length(t{j,1})/14)),...
            'Linewidth',4);
            ylabel('$y_f$ (rad)','Interpreter','latex');
        end
        if k == 1
            yl = ylim();
        elseif  k ~= 0
            ylim(yl);
        end
        xlabel('$t$ (s)','Interpreter','latex');
        saveas(gcf,folder+...
            sprintf("filterTuning/responseLambda_i%02d_j%02d_lambda%02d.fig",...
            i,j,k));
        saveas(gcf,folder+...
            sprintf("filterTuning/responseLambda_i%02d_j%02d_lambda%02d.fig",...
            i,j,k));
        hold off;
    end
    % Select best lambda 
    % lambdaTuned = 0.3;
    % Save filter tuning data
    save(folder+sprintf("filterTuning/tuningData_i%02d_j%02d.mat",i,j),...
        'lambda','yf','lambdaTuned');
    % Save last tuned lambda
    save(folder+"filterTuning/lambdaTuned.mat",...
        'lambdaTuned');
else
    % ------------------------------------------------------------------- %
    % --------------------------- SET PARAMETERS ------------------------ %
    lambda = 0.6;
    % ------------------------------------------------------------------- %
    % ------------------------------------------------------------------- %    
    % Filtering + detrending
    Afilter = [1 -lambda];
    Bfilter = (1-lambda)*[1 -1];
    tic;
    yf = cell(Nu,Nfs);
    uf = cell(Nu,Nfs);
    for j = 1:Nfs
        for i = 1:Nu
            % do not consider first 10 seconds
            uf{i,j} = u{i,j}(round(10*fs(j)+1):end); 
            uf{i,j} = detrend(uf{i,j});
            yf{i,j} = filter(Bfilter,Afilter,y{i,j}(round(10*fs(j))+1:end));
        end
    end
    toc;
    % Save filtered responses
    save(folder+"inputSignalsResponseProcessed.mat",...
        'yf','uf','lambda');
end
%% 4.4 Identification
clear;
% ---------------------------------------------------------------------- %
% --------------------------- SET PARAMETERS --------------------------- %
RUN = 18;
% ---------------------------------------------------------------------- %
% ---------------------------------------------------------------------- %
% Load directory path
load(sprintf("./DATA/4_PlantModelIdentification%02d/"+"RUN.mat",RUN),...
    'folder');
% Load number of input signals
load(folder+"inputSignals.mat",...
    'Nfs','Nu');
% Load filtered responses
load(folder+"inputSignalsResponseProcessed.mat",...
        'yf','uf');
% ------------------------------------- %
% Get dimension of cell array :) porque posso e n�o me apetece fazer contas
Nidentification = 0;
for nA = 3:6
    for nB = 1:nA-1
        for nK = 1:nA-nB+1
            Nidentification = Nidentification +1;
        end
    end
end
% Find armax model for each model order, for each 
tic;
M = cell(Nu,Nfs,Nidentification);
for j = 1:Nfs
    for i = 1:Nu
        count = 0;
        for nA = 3:6
            for nB = 1:nA-1
                for nK = 1:nA-nB+1
                    nC = nA;
                    count = count+1;
                    M{i,j,count} = armax([yf{i,j} uf{i,j}],[nA nB nC nK]);
                    nABCK(count,:) = [nA nB nC nK];
                end
            end
        end
    end
end
toc;
% ------------- Save Data ------------- %
% Save filtered responses
save(folder+"identificationCellArray.mat",...
    'M','nABCK','Nidentification');
% ------------------------------------- %
%% 4.5 Model validation                
clear;
RUN = 18;
% Load directory path
load(sprintf("./DATA/4_PlantModelIdentification%02d/"+"RUN.mat",RUN),...
    'folder');
% Load number of input signals
load(folder+"inputSignals.mat",...
    'Nfs','Nu');
% Load filtered responses
load(folder+"inputSignalsResponseProcessed.mat",...
    'yf','uf');
% Load filtered responses
load(folder+"identificationCellArray.mat",...
    'M','nABCK','Nidentification');
% Get fitness of each model
tic;
fitM = zeros(Nu,Nfs,Nidentification);
 
for j = 1:Nfs
    for i = 1:Nu
        for count = 1:Nidentification
            for k = 1:Nu
                if k == i
                    % Do not use own test as validation
                    continue;
                end
                [yfm,fit] = compare([yf{i,j} uf{i,j}],M{i,j,count});
                fitM(i,j,count) = fitM(i,j,count)+fit/(Nu-1);
            end  
        end
    end
end
toc; 
tic;
fitMcopy = fitM;
Nbest = 10;
bestFitFit = zeros(4,Nfs,Nbest);
bestFitCount = zeros(4,Nfs,Nbest);
bestFitU = zeros(4,Nfs,Nbest);
count = 0;
for j = 1:Nfs
    for nA = 3:6
        for b = 1:(min(Nbest,sum(nABCK(:,1)==nA)))
            idx = find(nABCK(:,1)==nA);
            bestFitFit(nA-2,j,b) = mean(max(max(fitMcopy(:,j,idx(1):idx(end)))));
            [aux1,aux2]=find(fitMcopy(:,j,idx(1):idx(end))==bestFitFit(nA-2,j,b));
            bestFitU(nA-2,j,b) = aux1(1);
            bestFitCount(nA-2,j,b) = aux2(1);
            bestFitCount(nA-2,j,b) = bestFitCount(nA-2,j,b)+idx(1)-1;
            fitMcopy(bestFitU(nA-2,j,b),j,bestFitCount(nA-2,j,b)) = 0;
            % [1 zeros(1,length(find(fitMcopy(:,j,idx(1):idx(end))==bestFitFit(nA-2,j,b)))-1)]*
        end
    end
end
toc;

% Save identification fitness data
save(folder+"identificationFitness.mat",...
    'fitM','bestFitFit','bestFitCount','bestFitU');
%% 4.5.1 Check results
clear;
RUN = 18;
% Load directory path
load(sprintf("./DATA/4_PlantModelIdentification%02d/"+"RUN.mat",RUN),...
    'folder');
% Load filtered responses
load(folder+"identificationCellArray.mat",...
    'M');
load(folder+"identificationFitness.mat",...
    'bestFitCount','bestFitU','bestFitFit');
load(folder+"inputSignals.mat",...
        'fs','Ts');
load("./DATA/bodeData.mat",...
        'trueMag','truePhase','w');
    % Load filtered responses
load(folder+"identificationCellArray.mat",...
    'nABCK');
 %%
% 4.5.1. Validate best identifications qualitatively (frequency)
j =1;
squeeze(bestFitFit(:,j,:))
squeeze(bestFitU(:,j,:))
squeeze(bestFitCount(:,j,:))

% 4.5.1. Validate best identifications qualitatively (pole zero position)
poleValidation = false;
nA = 3;
b = 1;
if poleValidation
    % Pole
    load(folder+"polesZerosTrue/polesZerosTrue.mat",...
    'numTrue','denTrue');
    [den, num] = polydata(M{bestFitU(nA-2,j,b),j,bestFitCount(nA-2,j,b)});
    den = conv(den,[1 -1]); % Add integrator
    figure();
    axis([-1.5 1.5 -1.5 1.5]);
    hold on;
    zplane(numTrue{j,1},denTrue{j,1});
    
    [hz2, hp2, ht2] = zplane(num,den);
    set(findobj(hz2, 'Type', 'line'), 'Color', [0.8500, 0.3250, 0.0980]);
    set(findobj(hp2, 'Type', 'line'), 'Color', [0.8500, 0.3250, 0.0980]);
    %axis([-1.5 1.5 -1.5 1.5]);
    hold off
    
    % Bode
    [mag,phase,wout] = bode(tf(num,den,Ts(j)),w);
    figure();
    semilogx(squeeze(w),20*log10(squeeze(trueMag)));
    hold on;
    semilogx(squeeze(w),20*log10(squeeze(mag)));
    subplot(211);
    semilogx(squeeze(w),20*log10(squeeze(trueMag)));
    hold on;
    semilogx(squeeze(w),20*log10(squeeze(mag)));
    subplot(212);
    semilogx(squeeze(w),squeeze(truePhase));
    hold on;
    semilogx(squeeze(w),squeeze(phase));
    hold off;
end

load(folder+"inputSignalsResponseProcessed.mat",...
        'yf','uf','lambda');
    %%
% ---------------------------------------------------------------------- %
% ------------------------ CHOOSE IDENTIFICATION ----------------------- %
chooseIdentification = true;
nA = 3; % order
b = 2; % b-th best
j = 1;
% ---------------------------------------------------------------------- %
% ---------------------------------------------------------------------- %
if chooseIdentification 
    MId = M{bestFitU(nA-2,j,b),j,bestFitCount(nA-2,j,b)};
    orderId = nABCK(bestFitCount(nA-2,j,b),:);
    fsId = fs(j);
    TsId = 1/fs(j);
    fitId = bestFitFit(nA-2,j,b);
    m_tf = idtf(idss(MId));
    [numId_,denId_] = tfdata(m_tf);
    numId_ = cell2mat(numId_);
    denId_ = cell2mat(denId_);
    %zplane(numId_,denId_)
    polesId_ = pole(tf(numId_,denId_,Ts(j)));
    zerosId_ = pole(tf(numId_,denId_,Ts(j)));
%     figure();
%     compare([yf{9,j} uf{9,j}],MId)
    save(folder+"identification.mat",...
        'MId','fsId','TsId','orderId','fitId','polesId_','zerosId_',...
        'denId_', 'numId_');
end

%% 4.6 Postprocessing
choosenIdentification = true;
if choosenIdentification
    %clear;
    RUN = 18;
    % Load directory path
    load(sprintf("./DATA/4_PlantModelIdentification%02d/"+"RUN.mat",RUN),...
        'folder');
    % Load identification
    load(folder+"identification.mat",...
        'MId','fsId','TsId','orderId','fitId','polesId_','zerosId_',...
        'denId_', 'numId_');
    % Add integrator
    numId = numId_;
    denId = conv(denId_,[1 -1]);
    [AId,BId,CId,DId] = tf2ss(numId,denId);
    
    polesId = pole(tf(numId,denId,TsId));
    zerosId = zero(tf(numId,denId,TsId));

    save(folder+"identification.mat",...
        'MId','fsId', 'TsId','orderId','fitId','polesId_','zerosId_',...
        'denId_', 'numId_','denId','numId','AId','BId','CId','DId',...
        'polesId','zerosId');
end
%% 4.\infty Batota :)
clear;
RUN = 18;
% Load directory path
load(sprintf("./DATA/4_PlantModelIdentification%02d/"+"RUN.mat",RUN),...
    'folder');
load("./model/barrassmodel.mat",...
    'Atrue','Btrue','Ctrue','Dtrue');
load(folder+"inputSignals.mat",...
    'Ts');
% Load number of input signals
load(folder+"inputSignals.mat",...
    'Nfs');

polesTrue = cell(Nfs,1);
zerosTrue = cell(Nfs,1);
numTrue = cell(Nfs,1);
denTrue = cell(Nfs,1);
SysC = ss(Atrue,Btrue,Ctrue,Dtrue);
for j = 1:Nfs
    SysD = c2d(SysC,Ts(j));
    polesTrue{j,1} = pole(SysD);
    zerosTrue{j,1} = zero(SysD);
end

for j = 1:Nfs
    figure('units','normalized','outerposition',[0 0 1 1]);
    hold on;
    set(gca,'FontSize',35);
    ax = gca;
    ax.XGrid = 'on';
    ax.YGrid = 'on';
    SysD = c2d(SysC,Ts(j));
    [numTrue{j,1},denTrue{j,1}] = tfdata(SysD,'v');
    p = zplane(numTrue{j,1},denTrue{j,1}); 
    title("True poles and zeros for "+sprintf("$T_s = %g$",Ts(j))+" s",'Interpreter','latex');
    saveas(gcf,folder+...
        sprintf("polesZerosTrue/polesZerosTrue_j%02d.fig",...
        j));
    if j ~= 1
        close(gcf);
    else
        hold off;
    end
end

% Save true poles and zeros
save(folder+"polesZerosTrue/polesZerosTrue.mat",...
    'polesTrue','zerosTrue','numTrue','denTrue');

