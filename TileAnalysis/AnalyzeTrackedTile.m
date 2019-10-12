%% function to analyze a label image w.r.t. volume, apical area and basal area
function [volumes, apicalAreas, basalAreas] = AnalyzeTrackedTile(fullLabelImage, trackedLabelImage, borderPadding)

    %% add scripts for loading and saving 3D images
    addpath('ThirdParty\saveastiff_4.3\');

    %% get the image size
    imageSize = size(fullLabelImage);

    %% compute the boundary image by subtracting an eroded version from the binarized label image
    boundaryImage = (fullLabelImage > 1) - imerode((fullLabelImage > 1), strel('sphere', 2));

    %% compute the surface image as the point-wise multiplication of the boundary image and the tracked label image
    surfaceImage = trackedLabelImage .* uint16(boundaryImage);

    %% initialize the apical and the basal surfaces
    apicalSurface = surfaceImage;
    basalSurface = surfaceImage;
    apicalSurface(:,:,round(imageSize(3)/2):end) = 0;
    basalSurface(:,:,1:round(imageSize(3)/2)) = 0;

    %% compute a mask image to get rid of boundary detections
    maskImage = zeros(imageSize);
    maskImage(1:borderPadding, :, :) = 1;
    maskImage((end-borderPadding+1):end, :, :) = 1;
    maskImage(:, 1:borderPadding, :) = 1;
    maskImage(:, (end-borderPadding+1):end, :) = 1;

    %% compute the region props
    currentRegionProps = regionprops(trackedLabelImage, maskImage, 'Area', 'Centroid', 'PixelIdxList', 'MaxIntensity');

    %% extract the individual volumes, apical areas and basal areas
    maxLabel = length(currentRegionProps);
    volumes = zeros(maxLabel,1);
    apicalAreas = zeros(maxLabel,1);
    basalAreas = zeros(maxLabel,1);
    for j=1:maxLabel
        if (currentRegionProps(j).Area <= 0 || currentRegionProps(j).MaxIntensity > 0 || length(find(apicalSurface == j)) < 3)
            continue;
        end

        %% set the volume
        volumes(j) = currentRegionProps(j).Area;

        %% compute the apical surface area using the two principal components
        [x, y, z] = ind2sub(imageSize, find(apicalSurface == j));
        x = x - mean(x);
        y = y - mean(y);
        z = z - mean(z);
        dataMatrix = [x,y,z];

        if (isempty(dataMatrix))
            continue;
        end

        %% perform pca and compute the 2D boundary on the first two principal components (like a propjection to a 2D plane)
        principalComponents = pca(dataMatrix);
        dataMatrixProj = (dataMatrix * principalComponents);
        boundaryPoints = boundary(dataMatrixProj(:,1),dataMatrixProj(:,2));

        %% get spatial coordinates associated with the boundary points
        X = dataMatrixProj(boundaryPoints,1);
        Y = dataMatrixProj(boundaryPoints,2);
        apicalAreas(j) = polyarea(X,Y);

        %% compute the basal surface area using the two principal components
        [x, y, z] = ind2sub(imageSize, find(basalSurface == j));
        x = x - mean(x);
        y = y - mean(y);
        z = z - mean(z);
        dataMatrix = [x,y,z];

        if (isempty(dataMatrix))
            continue;
        end

        %% perform pca and compute the 2D boundary on the first two principal components (like a propjection to a 2D plane)
        principalComponents = pca(dataMatrix);
        dataMatrixProj = (dataMatrix * principalComponents);
        boundaryPoints = boundary(dataMatrixProj(:,1),dataMatrixProj(:,2));

        %% get spatial coordinates associated with the boundary points
        X = dataMatrixProj(boundaryPoints,1);
        Y = dataMatrixProj(boundaryPoints,2);
        basalAreas(j) = polyarea(X,Y);
    end

    %% write the surface image to disk
    clear options;
    options.overwrite = true;
    options.compress = 'lzw';
    saveastiff(uint16(surfaceImage), 'test.tif', options);

    debugFigures = false;
    if (debugFigures == true)
        figure(1);
        subplot(3, 1, 1);
        boxplot(volumes);
        set(gca, 'YLim', [0, 100000]);
        title(['Median Volume ' num2str(median(volumes))]);
        ylabel('Volume (#voxels)');

        subplot(3, 1, 2);
        boxplot(apicalAreas);
        set(gca, 'YLim', [0, 2500]);
        title(['Median Apical Area: ' num2str(median(apicalAreas))]);
        ylabel('Apical Area (#voxels)');

        subplot(3, 1, 3);
        boxplot(basalAreas);
        set(gca, 'YLim', [0, 2000]);
        ylabel('Basal Area (#voxels)');
        title(['Median Basal Area: ' num2str(median(basalAreas))]);
    end
end