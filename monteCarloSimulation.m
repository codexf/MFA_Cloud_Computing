% Author: XF
% Updated 2022-04-21 INCAv1.8, MATLAB2020a, Azure Linux VM
function monteCarloSimulation(vm_id, inca_dir, input_dir, output_dir, matname, niter)
time = tic;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MONTECARLOSIMULATION performs flux estimation on experimental data      %
%                      pertubed with random noise                         %                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [vm_id] is the name of VM
% [inca_dir] is the path of inca
% [input_dir] is the path of input models
% [output_dir] is the path of output files to be made
% [matname] is a text string that represents the name of the .mat
% file that contains the INCA model with the experimental data.
% This text string should be wraped in single quotes and will be used as an idenfier in the
% filenames of each output file.
% [niter] is the number of iterations to perform in this script

% Remove file extensin from the model file
shortname = matname(1:length(matname)-4);

% Change path to INCA
disp('...Loading INCA package from ' + string(inca_dir))
cd(inca_dir);
startup; % also did the functions of setpath

% Change path to input folder
cd (input_dir);
% load model
disp('...Loading ' + string(matname) + ' from ' + string(input_dir))
model = load(matname);
m = model.mod;

% Change path to output folder
cd(output_dir);

% Create a new folder for outputs
output_dir_name = "monteCarloSimulation_" + string(shortname);

if not(isfolder(output_dir_name))
    disp('...Making a new folder: ' + string(output_dir) + '/' + output_dir_name)
    mkdir(output_dir_name);
end
    
% Select the active experiment to be analyzed (change if not the first
% experiment)
m.expts = m.expts(1);

% Repeat experimental data pertubation followed by flux extimation niter times
for n = 1:niter
    
    disp('..............................iteration ' + string(n) + '..............................')
    % Introduce randomly distributed error into mass isotopomer distributions
    msdata = m.expts.data_ms; % extract msdata object
    for i = 1:length(msdata)
        rng('shuffle'); % avoid repeating the same random number arrays
        msdata(i).mdvs.val = normrnd(msdata(i).mdvs.val, msdata(i).mdvs.std);
    end
    
    % Introduce randomly distributed error into flux measurements
    fluxdata = m.expts.data_flx;
    for i = 1:length(fluxdata)
        rng('shuffle'); %avoid repeating the same random number arrays
        fluxdata(i).val = normrnd(fluxdata(i).val, fluxdata(i).std);
    end
    
    % Save pertubated data to the original model
    m.expts.data_ms = msdata;
    m.expts.data_flx = fluxdata;
    
    disp('...Performing a single flux estimation with the pertubated data')
    
    % Flux estimation
    fit = estimate(m);
    
    disp('...Exporting output files to ' + string(output_dir) + '/' + output_dir_name)
    
    % Parameter object
    par = fit.par; %fields: alf  chi2s  cont  cor  cov  eqn  free  id  lb  std  type  ub  unit  val  vals
    type = par.type(:); % convert to column format using (:)
    id = par.id(:);
    eqn = par.eqn(:);
    val = par.val(:);
    std = par.std(:);
    T = table(type, id, eqn, val, std);
    T.Properties.VariableNames = {'Type' 'ID' 'Equation' 'Value' 'SE'};
    writetable(T, sprintf('%s/par_%s_%s_%d.csv', output_dir_name, shortname, vm_id, n), 'Delimiter', ',');
    
    % Measurement object
    mnt = fit.mnt;
    % Get measument info and export to a csv file
    mnt_expt = mnt.expt(:);
    mnt_type = mnt.type(:);
    mnt_id = mnt.id(:);
    mnt_sres = mnt.sres(:); % total squared residual of each measurement
    mnt_T = table(mnt_expt, mnt_type, mnt_id, mnt_sres);
    mnt_T.Properties.VariableNames = {'Expt' 'Type' 'ID' 'SRES'};
    writetable(mnt_T, sprintf('%s/res_%s_%s_%d.csv', output_dir_name, shortname, vm_id, n), 'Delimiter', ',');
    
end

% Calculate time
elaped=toc(time);
disp('This script took ' + string(datestr(datenum(0,0,0,0,0,elaped),'HH:MM:SS')))
end
