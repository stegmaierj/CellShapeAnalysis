
%% add bresenham dependency
addpath('../ThirdParty/bresenham/');

%% open the file to be rectified
[fileName, pathName] = uigetfile('*.png');
peelImage = imread([pathName filesep fileName]);

%% add padding on top and bottom of the peel image to facilitate the line generation
paddingSizeY = 10;
paddedPeelImage = zeros(size(peelImage,1)+2*paddingSizeY, size(peelImage,2));
paddedPeelImage((paddingSizeY+1):(size(peelImage,1)+paddingSizeY), :) = peelImage;

%% open a figure and plot the peel image
figure(1); clf; cla; colormap gray;
imagesc(paddedPeelImage);

%% let the user draw a set of poly line segments
fh = impoly('Closed', false); hold on;
lineVertices = getPosition(fh);
delete(fh);

%% connect the dots using the bresenham algorithm
linePixels = [];
for i=1:(size(lineVertices,1)-1)
    [xpos, ypos] = bresenham(lineVertices(i,1), lineVertices(i,2), lineVertices(i+1,1), lineVertices(i+1,2));
    linePixels = [linePixels; xpos, ypos];
end


%% pad the image on the x-axis to prevent overflow and get the center position
paddedPeelImage = [zeros(size(paddedPeelImage)), paddedPeelImage, zeros(size(paddedPeelImage))];
centerX = round(size(paddedPeelImage,2) / 2);

%% run through all rows and shift the respective row based on the manually drawn line
for i=(paddingSizeY+1):(size(peelImage,1)+paddingSizeY)
    
    %% compute the shift size required to center the furrow
    currentXPosition = round(mean(linePixels(linePixels(:,2)==i, 1))) + size(peelImage,2);
    shiftSize = centerX - currentXPosition;
    
    %% shift the row accordingly
    shiftedRow = circshift(paddedPeelImage(i,:), shiftSize);
    
    %% find the non-zero entries and distribute them equally around the center
    nonZeroEntries = find(shiftedRow > 0);
    numPixelsPerSide = round(length(nonZeroEntries) / 2);
    
    if (shiftSize >= 0)
        nonZeroEntriesAboveCenter = nonZeroEntries(nonZeroEntries > (centerX+numPixelsPerSide));
        shiftedRow((min(nonZeroEntries)-length(nonZeroEntriesAboveCenter)):(min(nonZeroEntries)-1)) = shiftedRow(nonZeroEntriesAboveCenter);
        shiftedRow(nonZeroEntriesAboveCenter) = 0;
    else
        nonZeroEntriesBelowCenter = nonZeroEntries(nonZeroEntries < (centerX-numPixelsPerSide));
        shiftedRow((max(nonZeroEntries)+1):(max(nonZeroEntries)+length(nonZeroEntriesBelowCenter))) = shiftedRow(nonZeroEntriesBelowCenter);
        shiftedRow(nonZeroEntriesBelowCenter) = 0;
    end
    
    %% update the shifted row
    paddedPeelImage(i,:) = shiftedRow;
end

%% perform max projection along y-dimension to remove padding
maxProjection = max(paddedPeelImage, [], 1);
validIndices = find(maxProjection > 0);
paddedPeelImage = paddedPeelImage((paddingSizeY+1):(size(peelImage,1)+paddingSizeY), validIndices);

%% show the shifted image
figure(1); clf; cla; axis equal;
imagesc(paddedPeelImage);

%% write the corrected version to disk with a new suffix
outFileName = strrep([pathName fileName], '.png', '_rectified.png');
imwrite(uint8(paddedPeelImage), outFileName);
