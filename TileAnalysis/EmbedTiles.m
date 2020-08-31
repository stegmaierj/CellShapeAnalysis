%%
 % CellShapeAnalysis.
 % Copyright (C) 2019 S. Bhide, J. Stegmaier
 %
 % Licensed under the Apache License, Version 2.0 (the "License");
 % you may not use this file except in compliance with the License.
 % You may obtain a copy of the License at
 % 
 %     http://www.apache.org/licenses/LICENSE-2.0
 % 
 % Unless required by applicable law or agreed to in writing, software
 % distributed under the License is distributed on an "AS IS" BASIS,
 % WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 % See the License for the specific language governing permissions and
 % limitations under the License.
 %
 % Please refer to the documentation for more information about the software
 % as well as for installation instructions.
 %
 % If you use this application for your work, please cite the repository and one
 % of the following publications:
 %
 % Bhide *et al.*, Cell Shape Changes during *Drosophila* Gastrulation, *in preparation*.
 %
 %%
 
%% add path to the tiff writing scripts
addpath('../ThirdParty/saveastiff_4.3/');

%% resize factors
% lateralFactor = 0.5;
% axialFactor = 2.5;
lateralFactor = 0.5;
axialFactor = 0.5;

%% specify input paths for the raw and the masked tiles
inputPathRaw = uigetdir(pwd, 'Select the folder containing the raw or segmentation images.');
inputPathRaw = [inputPathRaw filesep];
inputPathMasked = uigetdir(pwd, 'Select the folder containing the masked images.');
inputPathMasked = [inputPathMasked filesep];

%% load all contained images
inputFiles = dir([inputPathRaw '*.tif']);
inputFilesMasked = dir([inputPathMasked '*.tif']);

%% initialize the max tile size and max depth
maxTileSize = 0;
maxDepth = 0;

%% specify the file list
fileList = 1:length(inputFiles);

%% iterate over all files and embed them to a single stack
for i=fileList
    
    %% load the current image and get image resolution
    currentImage = double(loadtiff([inputPathRaw inputFiles(i).name]));
    imageSize = size(currentImage);
        
    %% downsample image in the lateral dimension to improve the interactivity of Segment3D
    numRows = round(imageSize(1)) * lateralFactor;
    numColumns = round(imageSize(2)) * lateralFactor;
    numPlanes = round(imageSize(3)) * axialFactor;
    currentImage = imresize3(currentImage, [numRows, numColumns, numPlanes]);
    imageSize = size(currentImage);
    
    %% identify the maximum tile size
    if (max(imageSize(1:2)) > maxTileSize)
        maxTileSize = max(imageSize(1:2));
    end
    
    %% identify the maximum depth
    if (imageSize(3) > maxDepth)
        maxDepth = imageSize(3);
    end    
end

%% initialize the result volume including some padding at the bottom and the top
resultImage = zeros(imageSize(1) .* length(fileList), imageSize(2), maxDepth + 20);
resultImageMask = zeros(imageSize(1) .* length(fileList), imageSize(2), maxDepth + 20);
for i=fileList

    %% load the current raw image
    currentImage = double(loadtiff([inputPathRaw inputFiles(i).name]));
    
    %% load the current mask    
    currentMask = loadtiff([inputPathMasked inputFilesMasked(i).name]);
    
    %% compute the lower and upper 5% quantile to perform contrast adjustment
    lowerQuantile = quantile(currentImage(currentMask > 0), 0.05);
    upperQuantile = quantile(currentImage(currentMask > 0), 0.95);
    currentImage = min(1, (currentImage - lowerQuantile) / (upperQuantile - lowerQuantile));
    
    %% apply slight Gaussian smoothing for smoother watershed results
    currentImage = imgaussfilt3(currentImage, 1);
    
    %% get the current image size
    imageSize = size(currentImage);
    numRows = round(imageSize(1)) * lateralFactor;
    numColumns = round(imageSize(2)) * lateralFactor;
    numPlanes = round(imageSize(3)) * axialFactor;
    currentImage = imresize3(currentImage, [numRows, numColumns, numPlanes]);
    currentMask = imresize3(currentMask, [numRows, numColumns, numPlanes], 'Nearest') > 0;
    
    %% set boundary to black
    currentMask(:,:,1) = 0;
    currentMask(:,:,end) = 0;
    currentMask(1,:,:) = 0;
    currentMask(end,:,:) = 0;
    currentMask(:,1,:) = 0;
    currentMask(:,end,:) = 0;
    
    %% get image size of the resized tile
    imageSize = size(currentImage);

    %% compute the tile insertion ranges
    rangeX{i} = ((i-1)*imageSize(1)) + (1:imageSize(1));
    rangeY{i} = 1:imageSize(2);
    rangeZ{i} = 10 + (1:imageSize(3));
    
    %% add the current tile at the computed position to the result image
    resultImageMask(rangeX{i}, rangeY{i}, rangeZ{i}) = currentMask;
    resultImage(rangeX{i}, rangeY{i}, rangeZ{i}) = currentImage .* currentMask;
end

%% compute boundary of the mask using the morphological gradient
boundaryImage = resultImageMask - imerode(resultImageMask, strel('cube', 3));

%% add the boundary as a safety margin to limit the watershed
resultImage = 65535 * max(boundaryImage, resultImage);

%% write the montage image to disk (including the insertion coordinates)
clear options;
options.overwrite = true;
options.compress = 'lzw';
saveastiff(uint16(resultImage), [inputPathRaw '../montage.tif'], options);
save([inputPathRaw '../montage_ranges.mat'], 'rangeX', 'rangeY', 'rangeZ');