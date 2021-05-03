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

%% the key event handler
function KeyReleaseEventHandler(~,evt)
    global settings;
    
    %% switch between the images of the loaded series
    if (strcmp(evt.Character, '.') || strcmp(evt.Key, 'rightarrow'))
        saveProject;
        settings.currentImageIndex = min(settings.currentImageIndex+1, length(settings.inputImages));
        settings.currentImage = im2uint8(imadjust(im2double(imread(settings.inputImages{settings.currentImageIndex}))));
        loadProject;
        updateVisualization;
    elseif (strcmp(evt.Character, ',') || strcmp(evt.Key, 'leftarrow'))
        saveProject;
        settings.currentImageIndex = max(settings.currentImageIndex-1, 1);
        settings.currentImage = im2uint8(imadjust(im2double(imread(settings.inputImages{settings.currentImageIndex}))));
        loadProject;
        updateVisualization;
        
    %% increase the h-minimum threshold
    elseif (strcmp(evt.Character, '+') || strcmp(evt.Key, 'uparrow'))
        settings.hminimaHeight = settings.hminimaHeight + 1;
        performAutomaticDetection;
        updateVisualization;
        
    %% decrease the h-minimum threshold
    elseif (strcmp(evt.Character, '-') || strcmp(evt.Key, 'downarrow'))
        settings.hminimaHeight = max(0, settings.hminimaHeight - 1);
        performAutomaticDetection;
        updateVisualization;
        
    %% perform automatic detection for the current frame 
    elseif (strcmp(evt.Character, 'a'))
        performAutomaticDetection;
        updateVisualization;
        
    %% save the project
    elseif (strcmp(evt.Character, 's'))
        saveProject;
        
    %% export the results
    elseif (strcmp(evt.Character, 'e'))
        exportResults;
        
    %% enable/disable smoothing
    elseif (strcmp(evt.Character, 'f'))
        settings.smoothingEnabled = ~settings.smoothingEnabled;
        updateVisualization;
        
    %% propagate parameters to all other frames for initialization
    elseif (strcmp(evt.Character, 'g'))
        for i = 1:length(settings.inputImages)
        	saveProject;
            settings.currentImageIndex = min(settings.currentImageIndex+1, length(settings.inputImages));
            settings.currentImage = im2uint8(imadjust(im2double(imread(settings.inputImages{settings.currentImageIndex}))));   
            initializeFromPreviousFrame;
            performAutomaticDetection;
            updateVisualization;
        end
        
    %% enable/disable cross hair visualization
    elseif (strcmp(evt.Character, 'c'))
       settings.crossHairEnabled = ~settings.crossHairEnabled;
       updateVisualization;
       
    %% initialize current parameters and detections from the previous frame
    elseif (strcmp(evt.Character, 'p'))
        initializeFromPreviousFrame;
        updateVisualization;
        
    %% delete a set of detections using a free hand tool
    elseif (strcmp(evt.Character, 'd'))
        set(settings.mainFigure, 'WindowButtonDownFcn', '');
        if (~isempty(settings.imageHandle))
            h = imfreehand; %#ok<IMFREEH>
            if (~isempty(h))
                maskImage = createMask(h, settings.imageHandle);
                deletionIndices = [];
                if (sum(maskImage(:)) > 0)
                    for i=1:size(settings.currentSeeds,1)
                        currentPosition = settings.currentSeeds(i,:);
                        if (maskImage(currentPosition(2), currentPosition(1)) > 0)
                            deletionIndices = [deletionIndices, i]; %#ok<AGROW>
                        end
                    end
                    settings.currentSeeds(deletionIndices,:) = [];
                    settings.currentSeedImage = settings.currentSeedImage .* ~maskImage;
                end
            end
            updateVisualization;
        end
        set(settings.mainFigure, 'WindowButtonDownFcn', @mouseUp);
        
    %% reset the detections for the current image
    elseif (strcmp(evt.Character, 'r'))
        settings.currentSeedImage(:) = 0;
        settings.currentSeeds = [];
        updateVisualization;
    
    %% show the help dialog
    elseif (strcmp(evt.Character, 'h'))
        showHelp;
    elseif (strcmp(evt.Character, '1'))
     
    elseif (strcmp(evt.Character, '2'))
   
    elseif (strcmp(evt.Character, '3'))

    elseif (strcmp(evt.Character, '4'))
 
    end
end