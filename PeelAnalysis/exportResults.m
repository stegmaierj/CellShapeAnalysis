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

%% add global settings variable and add path for saveastiff
global settings;
outputFolder = settings.outputFolder;
addpath('../ThirdParty/saveastiff_4.3/');

%% check if output folder exists and start exporting
if (exist(outputFolder, 'dir'))
    
    %% save current state and initialize a result d_orgs
    saveProject;
    d_orgs = zeros(0, length(settings.inputImages), 21);
    
    %% show wait bar for exporting
    waitBarHandle = waitbar(0,'Exporting result images and tables ...');
    frames = java.awt.Frame.getFrames();
    frames(end).setAlwaysOnTop(1);
    
    %% loop through all images and export the segmentations
    tempSettings = settings;
    for i=1:length(settings.inputImages)
        
        %% read the current image
        settings.currentImageIndex = i;
        settings.currentImage = (imread(settings.inputImages{settings.currentImageIndex}));

        %% load the segmentation and extract the corresponding region props
        [folder, file, ext] = fileparts(settings.inputImages{settings.currentImageIndex});
        inputFileName = [settings.outputFolder 'Temp' filesep file '.mat'];
        if (exist(inputFileName, 'file'))
            
            %% load the project
            loadProject;
            [folder, file, ext] = fileparts(inputFileName);
            imwrite(settings.watershedImage, [outputFolder filesep 'Segmentation' filesep file '_Segmentation.tif']);

            %% extract the current region props
            currentRegionProps = regionprops(settings.watershedImage, settings.currentImage, ...
                                             'Centroid', 'Area', 'BoundingBox', 'ConvexArea', 'Eccentricity', ...
                                             'EquivDiameter', 'Extent', 'FilledArea', 'MajorAxisLength', 'MinorAxisLength', ...
                                             'Orientation', 'Perimeter', 'Solidity', 'MaxIntensity', 'MinIntensity', 'MeanIntensity');

            %% assemble result matrix
            resultMatrix = zeros(length(currentRegionProps), 21);
            originalLocations = zeros(length(currentRegionProps), 3);
            for j=1:length(currentRegionProps)                
                resultMatrix(j,1) = j;
                resultMatrix(j,2) = currentRegionProps(j).Area;
                resultMatrix(j,3:4) = currentRegionProps(j).Centroid;
                resultMatrix(j,5) = 1;
                resultMatrix(j,6:7) = currentRegionProps(j).BoundingBox(3:end);
                resultMatrix(j,8) = 1;
                resultMatrix(j,9) = currentRegionProps(j).ConvexArea;
                resultMatrix(j,10) = currentRegionProps(j).Eccentricity;
                resultMatrix(j,11) = currentRegionProps(j).EquivDiameter;
                resultMatrix(j,12) = currentRegionProps(j).Extent;
                resultMatrix(j,13) = currentRegionProps(j).FilledArea;
                resultMatrix(j,14) = currentRegionProps(j).MinorAxisLength;
                resultMatrix(j,15) = currentRegionProps(j).MajorAxisLength;
                resultMatrix(j,16) = currentRegionProps(j).Orientation;
                resultMatrix(j,17) = currentRegionProps(j).Perimeter;
                resultMatrix(j,18) = currentRegionProps(j).Solidity;
                resultMatrix(j,19) = currentRegionProps(j).MinIntensity;
                resultMatrix(j,20) = currentRegionProps(j).MaxIntensity;
                resultMatrix(j,21) = currentRegionProps(j).MeanIntensity;
            end
            
            %% write results to disk
            dlmwrite([outputFolder filesep 'CSV' filesep file '_RegionProps.csv'], resultMatrix, ';');
            specifiers = 'id;area;xpos;ypos;zpos;xsize;ysize;zsize;convexArea;eccentricity;equivDiameter;extent;filledArea;minorAxisLength;majorAxisLength;orientation;perimeter;solidity;minIntensity;maxIntensity;meanIntensity;';
            prepend2file(specifiers, [outputFolder filesep 'CSV' filesep file '_RegionProps.csv'], 1);
            
            %% add information of the current frame to d_orgs
            d_orgs(1:size(resultMatrix,1),i,:) = resultMatrix;
        end
        
        %% update the waitbar
        waitbar(i/length(settings.inputImages));
    end
    
    %% close the wait bar and setup reqiored d_orgs variables
    close(waitBarHandle);
    var_bez = char(strsplit(specifiers, ';'));
    code = ones(size(d_orgs,1), 1);

    %% perform the tracking
    PerformTracking;
    
    %% reset the settings variable
    settings = tempSettings;
end