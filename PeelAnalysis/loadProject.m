%%
% CellShapeAnalysis.
% Copyright (C) 2020 J. Stegmaier
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
% Bhide, S., Mikut, R., Leptin, M., Stegmaier, J., Semi-Automatic Generation 
% of Tight Binary Masks and Non-Convex Isosurfaces for Quantitative Analysis 
% of 3D Biological Samples, In Proceedings of the IEEE International 
% Conference on Image Processing, 2020.
%
%%

global settings;

[folder, file, ext] = fileparts(settings.inputImages{settings.currentImageIndex});
inputFileName = [settings.outputFolder 'Temp' filesep file '.mat'];

transformationFileName = [folder filesep file '.mat'];
if (exist(transformationFileName, 'file'))
    load(transformationFileName);
else
    sliceCoordinatesX = [];
    sliceCoordinatesY = [];
    sliceCoordinatesZ = [];
end

if (exist(inputFileName, 'file'))
    load(inputFileName);
    settings.watershedImage = currentWatershedImage;
    settings.currentSeedImage = currentSeedImage(1:size(currentWatershedImage,1), 1:size(currentWatershedImage,2));
    settings.currentResultImage = currentResultImage;
    settings.currentSeeds = currentSeeds;
    settings.deletionRadius = deletionRadius;
    settings.hminimaHeight = hminimaHeight;    
else
    settings.currentSeedImage = zeros(size(settings.currentImage));
    settings.currentResultImage = cat(3, settings.currentImage, settings.currentImage, settings.currentImage);
    settings.watershedImage = zeros(size(settings.currentImage));
    settings.currentSeeds = [];
    settings.deletionRadius = 20;
    %settings.hminimaHeight = 1;
end
