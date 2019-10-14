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

%% add functionality for loading images
addpath('../ThirdParty/saveastiff_4.3/');
addpath('../ThirdParty/');

%% specify the input and output paths
inputPath = uigetdir(pwd, 'Select the folder containing the segmentation label images.');
inputPath = [inputPath filesep];
outputPath = [inputPath 'Tracked' filesep];
if (~isfolder(outputPath))
    mkdir(outputPath);
end

%% parse the input directory
inputFiles = dir([inputPath '*.tif']);

%% get the number of input files
numInputFiles = length(inputFiles);

%% initialize label and raw image cell arrays
labelImages = cell(numInputFiles, 1);
resultImages = cell(numInputFiles, 1);
regionProps = cell(numInputFiles, 1);

%% load the input images and extract the region props
for i=1:numInputFiles
    labelImages{i} = loadtiff([inputPath inputFiles(i).name]);
    resultImages{i} = zeros(size(labelImages{i}));
    regionProps{i} = regionprops(labelImages{i}, 'PixelIdxList');
end

%% perform tracking
numCells = size(regionProps{1},1);
trackingMatrix = zeros(numCells, numInputFiles);
for i=1:numCells
    
    %% start with the current cell id
    currentCellID = i;
    trackingMatrix(i,1) = currentCellID;
    
    %% search for a unique association between two cells
    for j=1:(numInputFiles-1)
        
        %% get the enext and previous cell id. Only if both of these match, a valid track is established
        nextCellID = mode(labelImages{j+1}(regionProps{j}(currentCellID).PixelIdxList));
        prevCellID = mode(labelImages{j}(regionProps{j+1}(nextCellID).PixelIdxList));
        
        %% check if tracking ids match, otherwise continue and end current track
        if (currentCellID == prevCellID)
            trackingMatrix(i,j+1) = nextCellID;
            currentCellID = nextCellID;
        else
            disp('Tracking conflict');
            break;
        end
    end
end

%% add correctly tracked cells to the final result images
for i=2:size(trackingMatrix,1)
    currentCellIds = trackingMatrix(i,:);
    if (min(currentCellIds) <= 0)
        disp(['Skipping cell number ' num2str(i) ' due to being incomplete!']);
        continue;
    end
    
    for j=1:numInputFiles
        resultImages{j}(regionProps{j}(currentCellIds(j)).PixelIdxList) = i;
    end    
end

%% set image writing options
clear options;
options.compress = 'lzw';
options.overwrite = true;

%% initialite arrays for volume and areas
volumes = [];
basalAreas = [];
apicalAreas = [];

%% loop through all input files and extract the properties for valid cells
for i=1:numInputFiles
    
    %% extract the quantifications of the current tile
    [currentVolumes, currentApicalAreas, currentBasalAreas] = AnalyzeTrackedTile(uint16(labelImages{i}), uint16(resultImages{i}), 10);
    
    %% save global quantifications
    volumes = [volumes, currentVolumes];
    apicalAreas = [apicalAreas, currentApicalAreas];
    basalAreas = [basalAreas, currentBasalAreas];
    
    %% set outfilename and save the tracked cells
    outFileName = [outputPath inputFiles(i).name];
    saveastiff(uint16(resultImages{i}), outFileName, options);
end

%% find cells that were properly tracked over the whole time span
validIndices = find(min(volumes, [], 2) > 0);

%% specify the colormap
mycolormap = jet(max(validIndices));

%% create the result figures
figure(1); clf; hold on;
subplot(1,3,1); hold on;
for i=validIndices'
    plot(1:numInputFiles, volumes(i,:), '-r', 'Color', mycolormap(i,:));
end
xlabel('Frame Number');
ylabel('Volumes (#Voxels)');
axis([1,numInputFiles,0,130000]);

subplot(1,3,2); hold on;
for i=validIndices'
    plot(1:numInputFiles, apicalAreas(i,:), '-r', 'Color', mycolormap(i,:));
end
ylabel('Apical Areas (#Pixels)');
axis([1,numInputFiles,0,3500]);

subplot(1,3,3); hold on;
for i=validIndices'
    plot(1:numInputFiles, basalAreas(i,:), '-r', 'Color', mycolormap(i,:));
end
xlabel('Frame Number');
ylabel('Basal Areas (#Pixels)');
axis([1,numInputFiles,0,3500]);

%% write the quantifications as csvs for further analysis
outFileName = [outputPath 'Quantification_VolumesInVoxel.csv'];
dlmwrite(outFileName, [validIndices, volumes(validIndices,:)], ';');
disp(['Output file written to: ' outFileName]);

outFileName = [outputPath 'Quantification_ApicalAreasInPixels.csv'];
dlmwrite(outFileName, [validIndices, apicalAreas(validIndices,:)], ';');
disp(['Output file written to: ' outFileName]);

outFileName = [outputPath 'Quantification_BasalAreasInPixels.csv'];
dlmwrite(outFileName, [validIndices, basalAreas(validIndices,:)], ';');
disp(['Output file written to: ' outFileName]);