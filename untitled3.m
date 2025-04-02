

[filename, filepath] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'});
if isequal(filename, 0)  % User canceled selection
    error('No file selected. Please select an image file.');
end

a = imread(fullfile(filepath, filename)); % Read the selected image
a = rgb2gray(a);  % Convert to grayscale
figure; imshow(a); title('Car');
 % Display the grayscale image and title it "car".
[r, c , ~]=size(a);  % Get the size of the grayscale image (rows, columns, and planes).
b=a(r/3:r,1:c);  % Crop the lower third portion of the grayscale image.
imshow(b);title('LP AREA')  % Display the cropped image and title it "LP AREA".
[r, c, p]=size(b);  % Get the size of the cropped image.
Out=zeros(r,c);  % Create a matrix of zeros with the same size as the cropped image.
for i=1:r  % Loop through each row of the cropped image.
    for j=1:c  % Loop through each column of the cropped image.
        if b(i,j)>150  % If the pixel value is greater than 150, set the corresponding value in the Out matrix to 1.
            Out(i,j)=1;
        else  % Otherwise, set the corresponding value in the Out matrix to 0.
            Out(i,j)=0;
        end
    end
end
BW3 = bwfill(Out,'holes');  % Fill any holes in the binary image.
BW3=medfilt2(BW3,[4 4]);  % Apply a 4x4 median filter to the binary image.
BW3=medfilt2(BW3,[4 4]);  % Apply the median filter again.
BW3=medfilt2(BW3,[4 4]);  % Apply the median filter again.
BW3=medfilt2(BW3,[5 5]);  % Apply a 5x5 median filter to the binary image.
BW3=medfilt2(BW3,[5 5]);  % Apply the median filter again.
figure;imshow(BW3,[]);  % Display the binary image after processing.
BW3 = bwfill(BW3,'holes');  % Fill any holes in the binary image again.
[L, num]=bwlabel(BW3);  % Label connected components in the binary image and count the number of objects.
STATS=regionprops(L,'all');  % Compute various properties of the labeled objects.
disp(num);  % Display the number of objects found.
cc=[];  % Create an empty array to store object areas.
removed=0;  % Initialize the count of removed objects to zero.
for i=1:num  % Loop through each object.
    dd=STATS(i).Area;  % Get the area of the current object.
    cc(i)=dd;  % Store the area of the current object in the cc array.
    if (dd < 5000)  % If the area of the current object is less than 50000, remove it.
        L(L==i)=0;  % Set the corresponding values in the labeled image to 0.
        removed = removed + 1;  % Increment the count of removed objects.
        num=num-1;  % Decrement the count of objects.
    end
end
[L2, num2]=bwlabel(L);  % Label connected components in the updated binary image and count the number of objects.
figure,imshow(L2);  % Display the updated labeled image.
STATS = regionprops(L2,'All');  % Compute various properties of the updated labeled objects.
if num2>2  % if there are more than two regions identified in the image
     for i=1:num2    % loop through each identified region
	aa=  STATS(i).Orientation;   % get the orientation of the current region
	if aa > 0   % if the orientation of the current region is greater than zero

	imshow(L==i);   % display the region using the L matrix

	end  % end the if statement
     end  % end the for loop
	disp('exit');  % display the message 'exit'
end  % end the if statement
 [r, c]=size(L2);  % get the size of the L2 matrix and assign the values to r and c
Out=zeros(r,c);  % create a matrix of zeros with the size of r and c and assign it to Out
k=1;  % assign 1 to k
[L2, num2] = bwlabel(L);  
disp(['Number of detected objects: ', num2str(num2)]);
figure, imshow(label2rgb(L2)); title('Labeled Regions');

if num2 >= 1
    % Get areas and bounding boxes of all detected objects
    areas = [STATS.Area];
    boxes = reshape([STATS.BoundingBox], 4, []).'; % Reshape bounding boxes

    % Define expected license plate aspect ratio (width should be greater than height)
    aspectRatios = boxes(:,3) ./ boxes(:,4); % width / height

    % Print detected bounding boxes
    disp('Detected Bounding Boxes:');
    disp(boxes);

    % Print aspect ratios
    disp('Aspect Ratios:');
    disp(aspectRatios);

    % Loosen the aspect ratio range and reduce area threshold
    validIdx = find(aspectRatios > 1.2 & aspectRatios < 8 & areas > 500);

    % Ensure validIdx stays within the array bounds
    validIdx = validIdx(validIdx <= size(boxes, 1));

    % Print valid indices
    disp('Valid Bounding Box Indices After Filtering:');
    disp(validIdx);

    if isempty(validIdx)
        disp('No valid license plate detected after filtering.');
        return;
    end

    % Pick the region **lowest in the image** (plates are near the bottom)
   % Select the bounding box closest to the bottom of the image
[~, bestIdx] = max(boxes(validIdx, 2) + boxes(validIdx, 4)); % Consider bottom edge

bestIdx = validIdx(bestIdx); % Get the actual index
B = boxes(bestIdx, :);

% Corrected bounding box extraction
Xmin = round(B(2));  
Xmax = round(B(2) + B(4));
Ymin = round(B(1));  
Ymax = round(B(1) + B(3));

% Ensure indices are within image limits
Xmin = max(1, Xmin);
Xmax = min(size(b,1), Xmax);
Ymin = max(1, Ymin);
Ymax = min(size(b,2), Ymax);

% Debugging Statements
disp(['Bounding Box: Xmin=', num2str(Xmin), ', Xmax=', num2str(Xmax), ', Ymin=', num2str(Ymin), ', Ymax=', num2str(Ymax)]);

% Check if the region exists before cropping
if Xmax > Xmin && Ymax > Ymin
    LP = b(Xmin:Xmax, Ymin:Ymax);
    figure, imshow(LP, []); title('Extracted License Plate');
end
else
    disp('Error: Invalid bounding box dimensions. Cropping failed.');
end
