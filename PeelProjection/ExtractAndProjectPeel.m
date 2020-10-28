%% add third party tools for ellipse fitting and tiff io
addpath('../ThirdParty/saveastiff_4.3/');

%%%%%%%%%%%%%%
%% Here you can control how far the surface shells should be distant to the surface of the mask.
%% If a single surface is required, just set the minimum and maximum value to the same value.
%% Otherwise, a range can be set and all integers including the range boundaries will be extracted.
%% Positive values insided mask
%% Zero on the surface of the mask 
%% Negative values select surfaces outside of the mask but with the same shape.
%% WARNING: Use negative values with caution, as this can result in non-closed contours that cannot be traced by the boundary tracing algorithm.
minSurfaceDistance = 0;
maxSurfaceDistance = 30;

%% the number of bottom and top slices that will be set to zero (to prevent mask border touching the image border)
safetyBorder = 2;

%% can be used to extract thicker peels (e.g., if a shell is incomplete or has holes in it).
padding = 0.5;
%%%%%%%%%%%%%%

%% look-up table for the neighbor search
neighborList = [0,1; 1,1; 1,0; 1,-1; 0,-1; -1,-1; -1,0; -1,1];

%% disable/enable debug figures
debugFigures = false;

%% select the raw image path
inputPathRaw = uigetdir(pwd, 'Select the folder containing the raw or segmentation images.');
if (isempty(inputPathRaw))
    disp('No valid input path selected. Please provide path to the raw images first and then the path to the masked raw images.');
end
inputPathRaw = [inputPathRaw filesep];
inputFilesRaw = dir([inputPathRaw '*.tif']);

%% select the mask image path
inputPathMask = uigetdir(pwd, 'Select the folder containing the MASKED raw images.');
if (isempty(inputPathMask))
    disp('No valid input path selected. Please provide path to the raw images first and then the path to the masked raw images.');
end
inputPathMask = [inputPathMask filesep];
inputFilesMask = dir([inputPathMask '*.tif']);

%% check if both folders contain the same amount of images
if (length(inputFilesMask) ~= length(inputFilesRaw))
    errordlg('Number of mask images does not match the number of raw images. Please make sure both folders contain the same amount of images with the same sorting.');
end

numInputImages = length(inputFilesRaw);
numSurfacePeels = length(minSurfaceDistance:maxSurfaceDistance);
numProgressBarSteps = numInputImages * numSurfacePeels;
currentProgressBarStep = 0;

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
    
    waitBarHandle = waitbar(0, 'Processing data ...');
    
    for surfaceDistance=minSurfaceDistance:maxSurfaceDistance
        
        %% update the wait bar
        waitbar(currentProgressBarStep / numProgressBarSteps, waitBarHandle, ['Processing image: ' strrep(inputFilesRaw(f).name, '_', '\_') ', surface distance: ' num2str(surfaceDistance)]);
        
        %% extract the current mask image
        currentMaskImage = maskImage > (surfaceDistance-padding) & maskImage < (surfaceDistance+padding);

        %% flip the image to have the XZ cross section
        rotatedRawImage = zeros(size(rawImage,3), size(rawImage,2), size(rawImage,1));
        rotatedMaskImage = zeros(size(rawImage,3), size(rawImage,2), size(rawImage,1));
        for s=1:size(rawImage,1)
            rotatedRawImage(:,:,s) = squeeze(rawImage(s, :, :))';
            rotatedMaskImage(:,:,s) = squeeze(currentMaskImage(s, :, :))';
        end
        rotatedRawImage = rotatedRawImage / max(rotatedRawImage(:));

        %% label the surface regions and extract their volume
        labeledShellImage = bwlabeln(rotatedMaskImage);
        regionProps = regionprops3(labeledShellImage, 'Volume', 'VoxelIdxList');
        volumes = regionProps.Volume;
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
                currentRawImage = outerSurface;
            else
                currentRawImage = innerSurface;
            end

            %% get the image size
            imageSize = size(currentRawImage);

            %% initialize the result image and the start location
            resultImage = zeros(imageSize(3), 3000);    
            startLocation = [];

            %% extract the valid peel pixels
            extractionLength = zeros(imageSize(3), 1);
            for i=1:imageSize(3)
                
                %% get the current slice and skeletonize the peel to have only one pixel thick boundaries
                %% use the peel to mask the raw image
                currentSlice = squeeze(currentRawImage(:,:,i));            
                currentSliceBinary = bwmorph(currentSlice > 0, 'skel', Inf);
                currentSliceBinary = bwskel(currentSliceBinary, 'MinBranchLength',15);
                currentSlice = double(currentSlice) .* double(currentSliceBinary);
                sliceSize = size(currentSlice);

                %% initialize the visited pixels array and extract the valid pixels
                visitedPixels = zeros(sliceSize);
                validPixels = find(currentSlice > 0);
                [xpos, ypos] = ind2sub(sliceSize, validPixels);
                
                %% identify isolated border positions by scanning the 3x3 neighborhood of each boundary pixel
                %% if there is only a single connected component present when removing the center pixel
                %% the point is an isolated point and can be removed. Otherwise causes tracing errors.
                isolatedPoints = [];
                for j=1:size(xpos,1)
                    
                    %% trace the boundary and search for the longest connected component
                    longestPosSequence = 0;
                    currentPosSequence = 0;
                    numPosNeighbors = 0;
                    for k=1:8
                        
                        %% get the current neighbor value
                        currentNeighborValue = currentSliceBinary(xpos(j)+neighborList(k,1), ypos(j)+neighborList(k,2));
                        
                        %% reset the sequence counter if a background pixel is visited
                        if (currentNeighborValue == 0)
                           currentPosSequence = 0; 
                        else
                           currentPosSequence = currentPosSequence + 1;
                           numPosNeighbors = numPosNeighbors + 1;
                        end
                        
                        %% remember the longest sequence of foreground pixels
                        if (currentPosSequence > longestPosSequence)
                            longestPosSequence = currentPosSequence;
                        end
                    end
                            
                    %% add isolated point if only one connected component is present
                    if (longestPosSequence == numPosNeighbors)
                        isolatedPoints = [isolatedPoints; j]; %#ok<AGROW>
                    end
                end
                
                %% remove the isolated points
                for j=isolatedPoints
                    currentSlice(xpos(j), ypos(j)) = 0;
                    currentSliceBinary(xpos(j), ypos(j)) = 0;
                end
                xpos(isolatedPoints) = [];
                ypos(isolatedPoints) = [];
                
                %% sort positions and compute the centroid
                positions = sortrows([xpos, ypos], [-2,1]);
                centroid = mean(positions);

                %% set the start location as the pixel centered at the centroid and with the highest y value
                %% start positions at subsequent slices are based on a nearest neighbor search to the previous location
                if (isempty(startLocation))
                    startLocation = [size(currentSlice,1), centroid(2)];
                end
                distances = sqrt((positions(:,1) - startLocation(1)).^2 + (positions(:,2) - startLocation(2)).^2);
                [minDist, minIndex] = min(distances);
                startLocation = positions(minIndex,:);
                previousNeighbor = 1;

                %% scan the peel using only a single consistent scan direction for all peels.
                positionQueue = [startLocation, 1];
                lastAngle = atan2(startLocation(1) - centroid(1), startLocation(2) - centroid(2));
                mirroringRequired = false;
                while ~isempty(positionQueue)

                    %% get the current position from the queue and remove the top entry
                    currentPosition = positionQueue(1,:);
                    positionQueue(1,:) = [];
                    
                    if (mirroringRequired == false)
                        currentAngle = atan2(currentPosition(1) - centroid(1), currentPosition(2) - centroid(2));
                    
                        if (abs(currentAngle - lastAngle) > pi && lastAngle < 0)
                            mirroringRequired = true;
                        end
                    end
                    lastAngle = currentAngle;
                    
                    %% set the intensity value of the current peel position to the results image
                    resultImage(i, floor(currentPosition(3))) = currentSlice(currentPosition(1), currentPosition(2));
                    resultImage(i, ceil(currentPosition(3))) = currentSlice(currentPosition(1), currentPosition(2));

                    %% plot progress pixel by pixel if debug figres are enabled
                    if (debugFigures == true)
                        figure(1); clf; hold on;
                        imagesc(currentSlice);
                        plot(currentPosition(2), currentPosition(1), '*r');
                    end

                    %% set current position to visited
                    if (visitedPixels(currentPosition(1), currentPosition(2)) > 0)
                        continue;
                    end

                    %% perform boundary tracing using Moore's algorithm (CCW)
                    nextIndices = [];
                    for n=0:7

                        %% compute the potential next neighbor in CCW fashion
                        potentialNeighbor = mod(previousNeighbor-1 + n, 8) + 1;

                        %% get the displacements of the neighbors from the LUT
                        j = neighborList(potentialNeighbor, 1);
                        k = neighborList(potentialNeighbor, 2);

                        % prevent out of bounds errors
                        if ((currentPosition(1)+j) < 1 || ...
                            (currentPosition(1)+j) > sliceSize(1) || ...
                            (currentPosition(2)+k) < 1 || ...
                            (currentPosition(2)+k) > sliceSize(2) || ...
                            (j == 0 && k == 0))
                            continue;
                        end

                        %% plot candidate search if enabled
                        if (debugFigures == true)
                            plot(currentPosition(2)+k, currentPosition(1)+j, '.r');
                        end

                        %% continue if the candidate was already visited before
                        if (visitedPixels(currentPosition(1)+j, currentPosition(2)+k) > 0)
                            continue;
                        end

                        %% select the minimum distance candidate in the correct direction
                        if (currentSlice(currentPosition(1)+j, currentPosition(2)+k) > 0)
                            nextIndices = [j, k];
                            previousNeighbor = find(neighborList(:,1) == -j & neighborList(:,2) == -k);

                            if (debugFigures == true)
                                plot(currentPosition(2)+k, currentPosition(1)+j, 'og');
                            end
                            break;
                        end 
                    end

                    %% add the identified closest neighbor to the queue and reset the last direction
                    if (~isempty(nextIndices))
                        positionQueue = unique([positionQueue; currentPosition(1)+nextIndices(1), currentPosition(2)+nextIndices(2), currentPosition(3) + sqrt(nextIndices(1)^2 + nextIndices(2)^2)], 'rows');
                        previousNeighbor = 1;
                    end

                    %% set current position to visited
                    visitedPixels(currentPosition(1), currentPosition(2)) = 1;
                    
                    if (debugFigures == true)
                        drawnow;
                    end
                end
                
                %% correct the orientation of the current line if mirroring is detected
                if (mirroringRequired == true)
                    shiftLenght = sum(resultImage(i,:) > 0);
                    resultImage(i,:) = circshift(fliplr(resultImage(i,:)), shiftLenght);
                end
                                
                disp(['Finished processing ' num2str(i) ' / ' num2str(imageSize(3)) ' slices ...']);
                extractionLength(i) = sum(resultImage(i,:) > 0);
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
            
            %% center the extracted structure, so that the black borders are equally distributed on both sides
            for j=1:size(resultImage,1)
                %% find the zero frames
                shiftLength = floor((size(resultImage,2) - find(resultImage(j,:) > 0, 1, 'last')) / 2);
                resultImage(j,:) = circshift(resultImage(j,:), shiftLength);
            end

            %% write the result images
            if (p==1)
                imwrite(resultImage, sprintf('%s%s_surfaceDistance=%02d_apicalPeel.png', inputPathRaw, strrep(inputFile, '.tif', ''), surfaceDistance));
            else
                imwrite(resultImage, sprintf('%s%s_surfaceDistance=%02d_basalPeel.png', inputPathRaw, strrep(inputFile, '.tif', ''), surfaceDistance));
            end
        end
        
        %% increase wait bar step
        currentProgressBarStep = currentProgressBarStep+1;
    end
    
    %% close the wait bar
    close(waitBarHandle);
end
