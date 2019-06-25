%% VERIS DATA PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Ghent University, 2019
%  Daan Hanssens
%
%  Note: 0_fixed folder has to be included in path.
ccc;


%% USER-INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File name (VERIS datafile)
filename = 'VSECmarie.DAT';

% Distance sensor - GPS
sensor_gps_dist = 1.10;  % m

% Coordinate system
coordinate_system = 'lam';  % lam : Lambert72, utm : UTM

% Grid size
dx = .25;  % m

% Save data as ascii and csv
save = 1;  % 1: save data, 0: don't save data


%% DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read data
file_id = fopen(strcat(filename)); % Grab file id
data_in = textscan(file_id, '%f %f %f %f %f'); % read
for ii = 1:length(data_in)
    data(:, ii) = data_in{ii}; % header: y, x, ec_25, ec_90, height
end

% Change coordinate system to UTM
if strcmp(coordinate_system, 'utm')
    [data(:, 1), data(:, 2)] = wgs2utm(data(:, 2), data(:, 1));
elseif strcmp(coordinate_system, 'lam')
    [data(:,1), data(:,2), data(:, 5)] = wgs2BD72(data(:, 1), ...
        data(:, 2), data(:, 5));
end

% Remove errors from VERIS data
data(data(:, 3) < 0, :) = [];
data(data(:, 4) < 0, :) = [];


%% SHIFT AND GRID DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Shift tractrix
data(:, 1:2) = shift_tractrix(data(:, 1:2), sensor_gps_dist, 0, 0);

% Create mesh
s_mesh = create_blank_2D(data(:, 1:2), dx, 100, 1);

% Grid data
for ii = 3:length(data_in)
    
    % Gridding
    vqinterp = scatteredInterpolant(data(:,1), data(:,2), data(:,ii), ...
        'natural');
    vq_bl_h = vqinterp(s_mesh.rasX_bl, s_mesh.rasY_bl);
    vq = s_mesh.blank(:); vq(~isnan(vq)) = vq_bl_h;    
    
    % Create grid structure
    grids(:, :, ii-2) = reshape(vq, s_mesh.nrows, s_mesh.ncols);
    
end

% Save as ascii and csv
if save == 1
    save_ascii_raster_grid(strcat('VERIS_EC25.asc'), ...
        flipud(grids(:, :, 1)), s_mesh.ncols, s_mesh.nrows, ...
        s_mesh.minX, s_mesh.minY, dx, '%.2f ', s_mesh.nodatavalue);
    save_ascii_raster_grid(strcat('VERIS_EC90.asc'), ...
        flipud(grids(:, :, 2)), s_mesh.ncols, s_mesh.nrows, ...
        s_mesh.minX, s_mesh.minY, dx, '%.2f ', s_mesh.nodatavalue);
    dlmwrite('VERIS_data_corr.csv', data, 'precision', 10)
end


%% VISUALIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create title string
title_str = {'ECa ~25 cm (mS/m)', 'ECa ~90 cm (mS/m)'};

% Image plot
figure();
for ii = 1:2
    subplot(1, 2, ii);
    h = imagesc(s_mesh.xgv, s_mesh.ygv, grids(:, :, ii));
    set(h, 'AlphaData', ~isnan(grids(:, :, ii)));
    title(title_str(ii));
    colorbar();
    set(gca,'ydir','normal');
    axis equal; axis tight;
    xlabel('X (m)');
    ylabel('Y (m)');
end

% Contour plot
figure();
for ii = 1:2
    subplot(1, 2, ii);
    contourf(s_mesh.xgv, s_mesh.ygv, grids(:, :, ii), 10, ...
        'LineColor', 'none');
    title(title_str(ii));
    set(gca,'ydir','normal');
    colorbar();
    axis equal; axis tight;
    xlabel('X (m)');
    ylabel('Y (m)');
end