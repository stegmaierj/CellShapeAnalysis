
%% select input path
inputPath = uigetdir(pwd, 'Select input path (should contain only a series of peels of a single image ...)');
inputPath = [inputPath '/'];
outputPathImages = [inputPath 'Registered/Images/'];
outputPathDeformations = [inputPath 'Registered/Deformations/'];
if (~isfolder(outputPathImages)); mkdir(outputPathImages); end
if (~isfolder(outputPathDeformations)); mkdir(outputPathDeformations); end

%% parse the input directory
inputFiles = dir([inputPath '*.png']);

%% enable / disable debug figures
debugFigures = false;

%% iterate over all peels and register them to the first peel
for i=2:length(inputFiles)
    
    %% initially, use the first peel as the reference
    if (i == 2)
        fixedImage = imread([inputPath inputFiles(i-1).name]);
        imwrite(fixedImage, [outputPath inputFiles(i-1).name]);
    end
    
    %% read the moving image
    movingImage = imread([inputPath inputFiles(i).name]);
    
    %% adjust image size of moving image to match the fixed image
    sizeDifference = size(fixedImage,2) - size(movingImage,2);
    if (mod(sizeDifference,2) ~= 0)
       movingImage = padarray(movingImage, [0, 1], 0, 'pre');
    end
    movingImage = padarray(movingImage, [0, floor(sizeDifference/2)], 0, 'both');
    
    %% apply all previous deformations to the current moving image before the actual registration
    for j=3:i
        
        %% load previous transformation
        load([outputPathDeformations strrep(inputFiles(j-1).name, '.png', '.mat')]);
        movingImage = imwarp(movingImage, displacementField, 'linear');
    end
    
    %% perform registration of the moving image onto the fixed image
    [displacementField, movingImageReg] = imregdemons(movingImage, fixedImage, [100,50,25], 'AccumulatedFieldSmoothing', 3.0);
    
    %% save displacement fields to reconstruct the intermediate transformations
    save([outputPathDeformations strrep(inputFiles(i).name, '.png', '.mat')], 'displacementField');

    %% plot debug figures if enabled
    if (debugFigures == true)
        figure(1);
        subplot(1,2,1);
        imagesc(cat(3, fixedImage, movingImage, zeros(size(fixedImage))));

        subplot(1,2,2);
        imagesc(cat(3, fixedImage, movingImageReg, zeros(size(fixedImage))));
    end
    
    %% write the current result image
    imwrite(movingImageReg, [outputPathImages inputFiles(i).name]);
    
    %% set current registered image as the next fixed image
    fixedImage = movingImageReg;
end