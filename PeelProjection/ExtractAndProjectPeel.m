%% add third party tools for ellipse fitting and tiff io
addpath('../ThirdParty/saveastiff_4.3/');

%%%%%%%%%%%%%%
%% here you can control how far the surface shell should be distant to the surface of the mask. 
%% Positive values insided mask
%% Zero on the surface of the mask 
%% Negative values select surfaces outside of the mask but with the same shape.
%% WARNING: Use negative values with caution, as this can result in non-closed contours that cannot be traced by the boundary tracing algorithm.
surfaceDistance = 5;

%% the number of bottom and top slices that will be set to zero (to prevent mask border touching the image border)
safetyBorder = 2;

%% can be used to extract thicker peels (e.g., if a shell is incomplete or has holes in it).
padding = 0.5;
%%%%%%%%%%%%%%

%% disable/enable debug figures
debugFigures = false;

%% select the raw image path
inputPathRaw = uigetdir(pwd, 'Select the folder containing the raw or segmentation images.');
inputPathRaw = [inputPathRaw filesep];
inputFilesRaw = dir([inputPathRaw '*.tif']);

%% select the mask image path
inputPathMask = uigetdir(pwd, 'Select the folder containing the MASKED raw images.');
inputPathMask = [inputPathMask filesep];
inputFilesMask = dir([inputPathMask '*.tif']);

%% check if both folders contain the same amount of images
if (length(inputFilesMask) ~= length(inputFilesRaw))
    errordlg('Number of mask images does not match the number of raw images. Please make sure both folders contain the same amount of images with the same sorting.');
end

%% iterate over all images in the specified folders
for f=1:length(inputFilesRaw)

    %% open the current raw image file
    inputFile = inputFilesRaw(f).name;
    rawImage = loadtiff([inputPathRaw inputFile]);
    
    %% set border part to zero to prevent masks touching the border.
    maskImage = loadtiff([inputPathMask inputFilesMask(f).name]) > 0;
    maskImage(:, :, 1:safetyBorder) = 0;
    maskImage(:, :, end-(safetyBorder-1):end) = 0;
    maskImage = imclose(maskImage, strel('cube', 3));
    maskImageBackground = bwdist(maskImage); %% distance map of the background for inverted selection
    maskImageForeground = bwdist(~(maskImage)); %% distance map of the foreground for inside mask selection
    maskImageForeground(maskImageForeground > 0) = maskImageForeground(maskImageForeground > 0) - 1; %% change the distance map such that the outer surface has a value of 0.
    maskImage = maskImageForeground - maskImageBackground; %% create the final signed distance map that allows to select shells outside/inside the mask.
    
    maskImage = medfilt3(maskImage, [3,3,3]);
    maskImage = maskImage > (surfaceDistance-padding) & maskImage < (surfaceDistance+padding);

    %% flip the image to have the XZ cross section
    rotatedRawImage = zeros(size(rawImage,3), size(rawImage,2), size(rawImage,1));
    rotatedMaskImage = zeros(size(rawImage,3), size(rawImage,2), size(rawImage,1));
    for s=1:size(rawImage,1)
        rotatedRawImage(:,:,s) = squeeze(rawImage(s, :,:))';
        rotatedMaskImage(:,:,s) = squeeze(maskImage(s, :,:))';
    end
    rotatedRawImage = rotatedRawImage / max(rotatedRawImage(:));
    
    %% label the surface regions and extract their volume
    labeledShellImage = bwlabeln(rotatedMaskImage);
    regionProps = regionprops3(labeledShellImage, 'Volume', 'VoxelIdxList');
    volumes = regionProps.Volume;
    pixelIdxLists = regionProps.VoxelIdxList;
    [volumes, indices] = sort(volumes, 'descend');    
    pixelIdxLists = regionProps.VoxelIdxList(indices);
    
    %% identify the inner and outer surface based on volume
    if (length(volumes) > 1)
        outerSurface = zeros(size(rotatedMaskImage));
        innerSurface = zeros(size(rotatedMaskImage));
        outerSurfaceId = (volumes(1) < volumes(2)) + 1;
        innerSurfaceId = (volumes(1) >= volumes(2)) + 1;
        outerSurface(pixelIdxLists{outerSurfaceId}) = rotatedRawImage(pixelIdxLists{outerSurfaceId});
        innerSurface(pixelIdxLists{innerSurfaceId}) = rotatedRawImage(pixelIdxLists{innerSurfaceId});
        
        if ((volumes(1) / volumes(2)) > 5)
           volumes(2) = []; 
        end        
    else
        outerSurface = zeros(size(rotatedMaskImage));
        outerSurface(pixelIdxLists{1}) = rotatedRawImage(pixelIdxLists{1});
    end
    
    %% load the peel image
    for p=1:min(2, length(volumes))

        %% select the outer or inner surface for extraction
        if (p==1)
            rawImage = outerSurface;
        else
            rawImage = innerSurface;
        end

        %% get the image size
        imageSize = size(rawImage);

        %% initialize the result image and the start location
        resultImage = zeros(imageSize(3), 3000);    
        startLocation = [];

        %% extract the valid peel pixels
        for i=1:imageSize(3)

            %% get the current slice and skeletonize the peel to have only one pixel thick boundaries
            %% use the peel to mask the raw image
            currentSlice = squeeze(rawImage(:,:,i));            
            currentSliceBinary = bwmorph(currentSlice > 0, 'skel', Inf);
            currentSlice = double(currentSlice) .* double(currentSliceBinary);
            sliceSize = size(currentSlice);
            
            %% initialize the visited pixels array and extract the valid pixels
            visitedPixels = zeros(sliceSize);
            validPixels = find(currentSlice > 0);
            [xpos, ypos] = ind2sub(sliceSize, validPixels);
            positions = sortrows([xpos, ypos], [-2,1]);

            if (debugFigures == true)
                figure(1); clf; hold on;
                subplot(1,2,1);
                imagesc(resultImage); axis equal;

                subplot(1,2,2); hold on;
                imagesc(currentSlice);
                tet = 1;
            end

            %% set the start location as the lowest, right-most mask pixel
            %% start positions at subsequent slices are based on a nearest neighbor search to the previous location
            if (isempty(startLocation))
                startLocation = positions(1,:);
            else
                distances = sqrt((positions(:,1) - startLocation(1)).^2 + (positions(:,2) - startLocation(2)).^2);
                [minDist, minIndex] = min(distances);
                startLocation = positions(minIndex,:);
            end
            lastDirection = [-1,0];

            %% scan the peel using only a single consistent scan direction for all peels.
            positionQueue = [startLocation, 1];
            while ~isempty(positionQueue)

                %% get the current position from the queue and remove the top entry
                currentPosition = positionQueue(1,:);
                positionQueue(1,:) = [];

                %% set the intensity value of the current peel position to the results image
                resultImage(i, floor(currentPosition(3))) = currentSlice(currentPosition(1), currentPosition(2));
                resultImage(i, ceil(currentPosition(3))) = currentSlice(currentPosition(1), currentPosition(2));

                %% set current position to visited
                if (visitedPixels(currentPosition(1), currentPosition(2)) > 0)
                    continue;
                end

                %% initialize the minimum distance and indices
                minDistance = inf;
                maxIndices = [0, 0];

                %% check all neighbors of the current pixel for a non-visited pixel
                %% with the minimum distance to the previous movement direction.
                for j=1:-1:-1
                    for k=1:-1:-1

                        %% prevent out of bounds errors
                        if ((currentPosition(1)+j) < 1 || ...
                            (currentPosition(1)+j) > sliceSize(1) || ...
                            (currentPosition(2)+k) < 1 || ...
                            (currentPosition(2)+k) > sliceSize(2) || ...
                            (j == 0 && k == 0))
                            continue;
                        end

                        %% continue if the candidate was already visited before
                        if (visitedPixels(currentPosition(1)+j, currentPosition(2)+k) > 0)
                            continue;
                        end

                        %% select the minimum distance candidate in the correct direction
                        if (currentSlice(currentPosition(1)+j, currentPosition(2)+k) > 0)
                            if (norm(lastDirection - [j,k]) <= minDistance )
                                minDistance = norm(lastDirection - [j,k]);
                                maxIndices = [j, k];
                            end
                        end
                    end
                end

                %% add the identified closest neighbor to the queue and reset the last direction
                positionQueue = unique([positionQueue; currentPosition(1)+maxIndices(1), currentPosition(2)+maxIndices(2), currentPosition(3) + sqrt(maxIndices(1)^2 + maxIndices(2)^2)], 'rows');
                lastDirection = maxIndices / norm(maxIndices);

                %% set current position to visited
                visitedPixels(currentPosition(1), currentPosition(2)) = 1;

                drawnow;
            end

            %% status
            disp(['Finished processing ' num2str(i) ' / ' num2str(imageSize(3)) ' slices ...']);
        end

        %% show result figure
        if (debugFigures == true)
            imagesc(resultImage);
            axis equal;
            colormap gray;
        end
        
        %% heuristic to fill black pixels with the local average value
        zeroValuePixels = find(resultImage == 0);
        medianFiltered = medfilt2(resultImage, [3,3]);
        resultImage(zeroValuePixels) = medianFiltered(zeroValuePixels);
        
        %% perform a maximum projection along the y-axis and identify the extent of valid values along the x-axis
        maxProjectionImage = max(resultImage, [], 1);
        validIndices = find(maxProjectionImage > 0);
        resultImage = resultImage(:, min(validIndices):max(validIndices));
        
        %% write the result images
        if (p==1)
            imwrite(resultImage, [inputPathRaw strrep(inputFile, '.tif', '') '_apicalPeel.png']);
        else
            imwrite(resultImage, [inputPathRaw strrep(inputFile, '.tif', '') '_basalPeel.png']);
        end
    end
end
