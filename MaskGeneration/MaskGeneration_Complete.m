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

%% ask for the number of slices
prompt = {'Enter number of annotation slices per stack:'};
windowTitle = 'Annotation Slices';
dims = [1 35];
definput = {'2'};
answer = inputdlg(prompt,windowTitle,dims,definput);

%% parameters
numSlices = str2double(answer); %% the number of manually drawn slices for mask generation
debugFigures = false; %% toggle visibility of the debug figures

%% add third party tools for ellipse fitting and tiff io
addpath('../ThirdParty/saveastiff_4.3/');
addpath('../ThirdParty/fit_ellipse/');
addpath('../ThirdParty/ginputc/');

%% specify the input and output directory
inputDir = uigetdir('../', 'Select the input folder containing cropped images.');
inputDir = [inputDir filesep];
outputDir = [inputDir 'Results/'];

%% create the output directory if it doesn't exist yet
if (~exist(outputDir, 'dir'))
    mkdir(outputDir);
end

%% get all input files
inputFiles = dir([inputDir '*.tif']);

%% loop through all input files and manually create the mask
for f=1:length(inputFiles)
    
    %% load the raw image
    rawImage = im2double(loadtiff([inputDir inputFiles(f).name]));
    
    %% flip the image to have the XZ cross section
    rotatedImage = zeros(size(rawImage,3), size(rawImage,2), size(rawImage,1));
    for s=1:size(rawImage,1)
        rotatedImage(:,:,s) = squeeze(rawImage(s, :,:))';
    end
    rotatedImage = rotatedImage / max(rotatedImage(:));
    
    %% show figure and initial frame to select the most suitable manual mode
    fh =  figure(1); clf; hold on; set(gca, 'YDir', 'reverse'); axis tight; colormap gray;
    imagesc(rotatedImage(:,:,1));
    
    %% Construct a questdlg with three options
    segmentationMode = questdlg('How do you want to draw the mask?', ...
        'Mask Generation Mode', ...
        'Free Hand', 'Polylines', 'Cancel', 'Polylines');
    
    %% select the segmentation mode
    switch segmentationMode
        case 'Free Hand'
            segmentationMode = 1;
        case 'Polylines'
            segmentationMode = 2;
        case 'Cancel'
            continue;
    end
    
    %% initialize the mask images
    maskImageOutside = zeros(size(rotatedImage,1), size(rotatedImage,2), numSlices);
    maskImageInside = zeros(size(rotatedImage,1), size(rotatedImage,2), numSlices);
    clear boundaryInside;
    clear boundaryOutside;
    
    labelSlices = zeros(numSlices, 1);
    for i=1:numSlices
        if (i==1)
            labelSlices(i) = 1;
        elseif (i == numSlices)
            labelSlices(i) = size(rotatedImage, 3);
        else
            labelSlices(i) = round((i-1) * size(rotatedImage, 3) / (numSlices-1));
        end
    end
    
    %% generate masks for all slices
    for i=1:numSlices
                
        %% perform the manual segmentation for inner and outer boundary using the desired mode
        segmentationOk = false;
        while (segmentationOk == false)

            %% open the figure for drawing the mask
            fh =  figure(1); clf; hold on; set(gca, 'YDir', 'reverse'); axis tight; colormap gray;
            imagesc(rotatedImage(:,:,labelSlices(i)));
            title(['Image ' num2str(f) ' / ' num2str(length(inputFiles)) ', Slice ' num2str(i) ' / ' num2str(numSlices)]);
            
            for j=1:2
                
                %% freehand contour drawing
                if (segmentationMode == 1)
                    freehandContour = imfreehand(gca);
                    maskImage = createMask(freehandContour);
                    
                    %% polyline for contour
                elseif (segmentationMode == 2)
                    freehandContour = impoly(gca);
                    maskImage = createMask(freehandContour);
                end
                
                %% extract the boundary from the mask
                currentBoundary = bwboundaries(maskImage);
                
                %% set the inner/outer boundary
                if (j == 1)
                    maskImageOutside(:,:,i) = maskImage;
                    boundaryOutside{i} = currentBoundary{1};
                    plot(currentBoundary{1}(:,2), currentBoundary{1}(:,1), 'r', 'LineWidth', 1);
                else
                    maskImageInside(:,:,i) = maskImage;
                    boundaryInside{i} = currentBoundary{1};
                    plot(currentBoundary{1}(:,2), currentBoundary{1}(:,1), 'g', 'LineWidth', 1);
                end
                
                %% delete the contour drawing object
                delete(freehandContour);
            end
            
            
            %% ask if mask was done properly
            segmentationStatus = questdlg('Satisfied with the mask or redo?', 'Mask ok?', 'Next', 'Redo', 'Next');
            if (strcmp(segmentationStatus, 'Next') == true)
                segmentationOk = true;
            end
        end
    end
    
    %% perform slice interpolation using the computed boundaries
    resultImage = zeros(size(rotatedImage));
    maskImage = zeros(size(rotatedImage));
    for s=1:(numSlices-1)
        
        startIndex = s;
        endIndex = s+1;
        
        %% perform slice interpolation using the computed boundaries
        numPoints = 500;
        stepSizeOutside1 = length(boundaryOutside{startIndex}) / numPoints;
        stepSizeOutside2 = length(boundaryOutside{endIndex}) / numPoints;
        stepSizeInside1 = length(boundaryInside{startIndex}) / numPoints;
        stepSizeInside2 = length(boundaryInside{endIndex}) / numPoints;
        
        %% initialize the start and end point arrays
        startSlicePointsOutside = [];
        endSlicePointsOutside = [];
        startSlicePointsInside = [];
        endSlicePointsInside = [];
        
        if (debugFigures == true)
            figure(1); clf; hold on;
        end
        for i=1:numPoints
            
            %% handle outer boundary
            currentPoint1 = boundaryOutside{startIndex}(1+round((i-1)*stepSizeOutside1),:);
            currentPoint2 = boundaryOutside{endIndex}(1+round((i-1)*stepSizeOutside2),:);
            startSlicePointsOutside = [startSlicePointsOutside; currentPoint1, 1];
            endSlicePointsOutside = [endSlicePointsOutside; currentPoint2, size(rotatedImage,3)];
            
            %% plot debug lines
            if (debugFigures == true)
                plot3([currentPoint1(1), currentPoint2(1)], [currentPoint1(2), currentPoint2(2)], [1,size(rotatedImage,3)], '-r');
            end
            
            %% handle inner boundary
            currentPoint1 = boundaryInside{startIndex}(1+round((i-1)*stepSizeInside1),:);
            currentPoint2 = boundaryInside{endIndex}(1+round((i-1)*stepSizeInside2),:);
            startSlicePointsInside = [startSlicePointsInside; currentPoint1, 1];
            endSlicePointsInside = [endSlicePointsInside; currentPoint2, size(rotatedImage,3)];
            
            %% plot debug lines
            if (debugFigures == true)
                plot3([currentPoint1(1), currentPoint2(1)], [currentPoint1(2), currentPoint2(2)], [1,size(rotatedImage,3)], '-g');
            end
        end
        
        %% create the output image by interpolating the mask slices
        for i=labelSlices(s):labelSlices(s+1)
            
            %% the interpolation factor and the polygon points
            alpha = ((i-labelSlices(s)-1) / (labelSlices(s+1)-labelSlices(s)-1));
            currentPolygonOutside = (1.0 - alpha) * startSlicePointsOutside + alpha * endSlicePointsOutside;
            currentPolygonInside = (1.0 - alpha) * startSlicePointsInside + alpha * endSlicePointsInside;
            
            %% create the mask
            currentMask = poly2mask(currentPolygonOutside(:,2), currentPolygonOutside(:,1), size(rotatedImage,1), size(rotatedImage,2)) & ...
                ~poly2mask(currentPolygonInside(:,2), currentPolygonInside(:,1), size(rotatedImage,1), size(rotatedImage,2));
            
            %% only save the masked region of the original image to suppress background
            currentImage = rotatedImage(:,:,i) .* currentMask;
            resultImage(:,:,i) = currentImage;
            maskImage(:,:,i) = currentMask;
            
            i
        end
    end
    
    %% compute the gradient of the mask to add a safety border
    mygradient = maskImage - imerode(maskImage, strel('cube', 3));
    maskedImageWithGradient = max(resultImage, mygradient);
    
    %% rotate the final image back to the original orientation
    finalImage = zeros(size(rawImage));
    for s=1:size(maskedImageWithGradient,3)
        finalImage(s,:,:) = maskedImageWithGradient(:,:,s)';
    end
    
    %% write image to disk
    clear options;
    options.overwrite = true;
    options.compression = 'lzw';
    outputFileName = [outputDir strrep(inputFiles(f).name, '.tif', '_Masked.tif')];
    saveastiff(im2uint16(finalImage), outputFileName, options);
end

