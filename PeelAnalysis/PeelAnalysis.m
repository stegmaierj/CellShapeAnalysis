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
 
%% add global variable for the settings 
global settings;

%% load the input files
settings.inputFolder = [uigetdir(pwd, 'Please select input folder containing projected 2D images') filesep];
settings.inputFiles = dir([settings.inputFolder '*.tif']);
settings.inputImages = cell(0,0);
currentImage = 1;
for i=1:length(settings.inputFiles)
    [folder, file, ext] = fileparts([settings.inputFolder settings.inputFiles(i).name]);
    if (strcmpi(ext, '.tif'))
        settings.inputImages{currentImage} = [settings.inputFolder settings.inputFiles(i).name];
        currentImage = currentImage+1;
    end
end

%% specify the output folder
settings.outputFolder = [settings.inputFolder 'Results' filesep];
if (~exist(settings.outputFolder, 'dir'))
    mkdir(settings.outputFolder);
    mkdir([settings.outputFolder 'Segmentation']);
    mkdir([settings.outputFolder 'Temp']);
    mkdir([settings.outputFolder 'CSV']);
    mkdir([settings.outputFolder 'Tracking']);
end

settings.currentImageIndex = 1;
settings.currentImage = imread(settings.inputImages{settings.currentImageIndex});
settings.currentSeedImage = zeros(size(settings.currentImage));
settings.currentResultImage = cat(3, settings.currentImage, settings.currentImage, settings.currentImage);
settings.currentSeeds = [];
settings.deletionRadius = 20;
settings.hminimaHeight = 5;
settings.imageHandle = [];
settings.fontSize = 20;
settings.mainFigure = figure(1);

settings.crossHairVAxis1 = [];
settings.crossHairVAxis2 = [];
settings.crossHairHAxis1 = [];
settings.crossHairHAxis2 = [];
settings.crossHairEnabled = false;
settings.smoothingEnabled = false;

%% mouse, keyboard events and window title
set(settings.mainFigure, 'WindowScrollWheelFcn', @ScrollEventHandler);
set(settings.mainFigure, 'KeyReleaseFcn', @KeyReleaseEventHandler);
set(settings.mainFigure, 'WindowButtonDownFcn', @mouseUp);
set(settings.mainFigure, 'WindowButtonMotionFcn', @mouseMove);
set(settings.mainFigure, 'CloseRequestFcn', @closeRequestHandler);

%% load the first frame
settings.currentImageIndex = min(settings.currentImageIndex+1, length(settings.inputImages));
settings.currentImage = imread(settings.inputImages{settings.currentImageIndex});
loadProject;        

updateVisualization;