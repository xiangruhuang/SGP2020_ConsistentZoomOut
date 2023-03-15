function [outputArg1,outputArg2] = main(split)
addpath(genpath(pwd)); 

%% load shapes
mesh_dir = '/mnt/xrhuang/datasets/dfaust1k_test/off/'; 

% mesh_info = dir([mesh_dir, '*.off']);
mesh_info = zeros(38, 1);
mesh_info(1) = 0;
for i = 1:37
    mesh_infp(i+1) = split*37+i;
end
nshapes = length(mesh_info);
shapes = cell(nshapes, 1);
for i = 1:nshapes
    name = num2str(mesh_info(i), '%03.f');
    shapes{i} = read_off_shape([mesh_dir, name, '.off']);
    shapes{i}.name = name; 
    shapes{i} = compute_laplacian_basis(shapes{i}, 100); 
end

% subsample 1000 points on each shape for accelerating the map
% synchonization
subsamples = cell(nshapes, 1); 
for i = 1:nshapes
    subsamples{i} = fps_euclidean(shapes{i}, 1000, i); 
end    

%% load initial maps
map_dir = './data/bim_maps/'; 
ini_maps = cell(nshapes);
for i = 1:nshapes
    for j = 1:nshapes
        if isfile([map_dir, shapes{i}.name '_' shapes{j}.name '.map'])
            T = dlmread([shapes{i}.name '_' shapes{j}.name '.map']); 
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

for i = 2:nshapes
    refined_map = Data.refined_maps{1, i};
    save(strcat([num2str(i, '%03.f'), '.mat']), "refined_map");
end

%% visualize results
% figure; 
% for i = 1:nshapes
%     for j = 1:i-1
%         visualize_map(shapes{i}, shapes{j}, Data.input_maps{i, j}, Data.refined_maps{i, j}); 
%         pause; 
%     end
% end



end

