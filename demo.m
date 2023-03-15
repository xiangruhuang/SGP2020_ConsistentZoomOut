clear; close all; clc; 
addpath(genpath(pwd)); 

%% load shapes
% mesh_dir = '/mnt/xrhuang/datasets/dfaust_faust/faust_test_20/'; 
mesh_dir = '/mnt/xrhuang/datasets/dfaust_faust/dfaust_test_1000/'; 

mesh_info = dir([mesh_dir, '*.off']);
nshapes = length(mesh_info);
shapes = cell(nshapes, 1);
for i = 1:nshapes
    shapes{i} = read_off_shape([mesh_dir, mesh_info(i).name]);
    shapes{i}.name = mesh_info(i).name(1:end-4); 
    disp(shapes{i}.name);
    shapes{i} = compute_laplacian_basis(shapes{i}, 100); 
end

% subsample 1000 points on each shape for accelerating the map
% synchonization
subsamples = cell(nshapes, 1); 
for i = 1:nshapes
    subsamples{i} = fps_euclidean(shapes{i}, 1000, i); 
end

%% load initial maps
% map_dir = '/mnt/xrhuang/BIM/SurfCorr2.1.bins/WorkDir/faust_test_20_maps/'; 
map_dir = '/mnt/xrhuang/BIM/SurfCorr2.1.bins/WorkDir/dfaust_test_1000_maps/'; 
ini_maps = cell(nshapes);
for i = 1:nshapes
    for j = 1:nshapes
        disp([map_dir, shapes{i}.name, '_', shapes{j}.name, '.map']);
        if isfile([map_dir, shapes{i}.name '_' shapes{j}.name, '.map'])
            T = dlmread([map_dir, shapes{i}.name '_' shapes{j}.name, '.map']); 
            ini_maps{i, j} = T+1;
        end
    end
end

% G encodes the topoloty of the initial map network.
G = 1 - cellfun(@isempty, ini_maps);

%% run consistent zoomout
% organize input
Data = []; 
Data.shapes = shapes; 
Data.input_maps = ini_maps; 
Data.G = G; 
Data.sub = subsamples; 
Data.alpha = 0.9; 
Data.dim = 30:2:80; % zoomout from dim 30 to 80, with step size 2.

Data = ConsistentZoomOut(Data);

refined_map_dir = '/mnt/xrhuang/CZO/dfaust_test_1000_refined_maps/';
for i = 1:1
    for j = 1:nshapes
        refined_map = Data.refined_maps{i, j} - 1;
        dlmwrite(strcat([refined_map_dir, num2str(i-1, '%04.f'), '_', num2str(j-1, '%04.f'), '.txt']), refined_map);
        % save(strcat([num2str(i, '%03.f'), '_', num2str(j, '%03.f'), '.mat']), "refined_map");
    end
end

%% visualize results
% figure; 
% for i = 1:nshapes
%     for j = 1:i-1
%         visualize_map(shapes{i}, shapes{j}, Data.input_maps{i, j}, Data.refined_maps{i, j}); 
%         pause; 
%     end
% end


