%%
 % CellShapeAnalysis.
 % Copyright (C) 2020 S. Bhide, J. Stegmaier
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
 % Bhide, S., Leptin, M., Stegmaier, J., Semi-Automatic Generation of Tight 
 % Binary Masks and Non-Convex Isosurfaces for Quantitative Analysis of 
 % Drosophila Gastrulation, in preparation, 2020.
 %
 %%

%% load the global settings variable
global settings;

%% identify the current file parts and load previous project file
[folder, file, ext] = fileparts(settings.inputImages{settings.currentImageIndex-1});
inputFileName = [settings.outputFolder 'Temp' filesep file '.mat'];

%% attempt to load previous project file
if (exist(inputFileName, 'file'))
    load(inputFileName);
end

%% process the current input image with the previous settings
inputImage = imgaussfilt(settings.currentImage, 1);
hminima = watershed(imimposemin(inputImage, currentSeedImage(1:size(currentWatershedImage,1), 1:size(currentWatershedImage,2)))) > 0;
currentRegionProps = regionprops(hminima, 'Centroid');
settings.currentSeeds = [];
settings.currentSeedImage = zeros(size(settings.currentImage));
for i=1:length(currentRegionProps)
    settings.currentSeeds = [settings.currentSeeds; round(currentRegionProps(i).Centroid)];
    settings.currentSeedImage(round(currentRegionProps(i).Centroid(2)), round(currentRegionProps(i).Centroid(1))) = 1; 
end
