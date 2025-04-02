classdef vehicleplate_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        StatusWaitingforimageLabel  matlab.ui.control.Label
        LicensePlateDetectionLabel  matlab.ui.control.Label
        ResetButton                 matlab.ui.control.Button
        EditField                   matlab.ui.control.NumericEditField
        EditFieldLabel              matlab.ui.control.Label
        StatusLabel                 matlab.ui.control.Label
        ProcessImageButton          matlab.ui.control.Button
        UploadImageButton           matlab.ui.control.Button
        UIAxes2                     matlab.ui.control.UIAxes
        UIAxes                      matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        UploadedImage % Description
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: UploadImageButton
        function UploadImageButtonPushed(app, event)
        [file, path] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'});
          if isequal(file, 0)
        app.StatusWaitingforimageLabel.Text = 'No image selected!';
        return;
          end
     app.UploadedImage = imread(fullfile(path, file));
   
     grayImg = rgb2gray(app.UploadedImage);
    imshow(grayImg, 'Parent', app.UIAxes);
    title(app.UIAxes, 'Uploaded Image');
    app.StatusWaitingforimageLabel.Text = 'Image Loaded';
        end

        % Button pushed function: ProcessImageButton
        function ProcessImageButtonPushed(app, event)
   if isempty(app.UploadedImage)
        app.StatusLabel.Text = 'No image uploaded!';
        return;
    end  

    app.StatusLabel.Text = 'Processing...';
    pause(1); % Simulate processing delay

  if size(app.UploadedImage, 3) == 3
    a = rgb2gray(app.UploadedImage);
    else
    a = app.UploadedImage; % Image is already grayscale
    end



 % Display the grayscale image and title it "car".
[r, c , ~]=size(a);  % Get the size of the grayscale image (rows, columns, and planes).
b=a(r/3:r,1:c);  % Crop the lower third portion of the grayscale image.
imshow(b);title('LP AREA')  % Display the cropped image and title it "LP AREA".
[r, c, ~]=size(b);  % Get the size of the cropped image.
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
                app.StatusLabel.Text = 'No valid license plate detected!';
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



% Check if the region exists before cropping
if Xmax > Xmin && Ymax > Ymin
    extractedPlate = b(Ymin:Ymax, Xmin:Xmax); % Corrected indexing
    cla(app.UIAxes2, 'reset'); % Clear previous image
    imshow(extractedPlate, 'Parent', app.UIAxes2);
    title(app.UIAxes2, 'Extracted Plate');
    app.StatusLabel.Text = 'License Plate Detected!';
else
    app.StatusLabel.Text = 'Error: Cropping failed!';
end
end
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            app.StatusLabel.Text = 'Status: Waiting for image...';

    % Clear images in UIAxes
    cla(app.UIAxes);   % Clears main image display
    cla(app.UIAxes2);  % Clears extracted plate display

    % Reset the edit field
    app.EditField.Value = 0;  % Reset numeric input

    % Reset UIAxes Titles
    title(app.UIAxes, 'Image Display');
    title(app.UIAxes2, 'Plate Display');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 854 591];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Image Display')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [77 261 300 185];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, {''; 'Plate Display'})
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [490 261 300 185];

            % Create UploadImageButton
            app.UploadImageButton = uibutton(app.UIFigure, 'push');
            app.UploadImageButton.ButtonPushedFcn = createCallbackFcn(app, @UploadImageButtonPushed, true);
            app.UploadImageButton.FontName = 'Ebrima';
            app.UploadImageButton.FontSize = 14;
            app.UploadImageButton.FontWeight = 'bold';
            app.UploadImageButton.Position = [182 472 107 25];
            app.UploadImageButton.Text = 'Upload Image';

            % Create ProcessImageButton
            app.ProcessImageButton = uibutton(app.UIFigure, 'push');
            app.ProcessImageButton.ButtonPushedFcn = createCallbackFcn(app, @ProcessImageButtonPushed, true);
            app.ProcessImageButton.FontSize = 14;
            app.ProcessImageButton.FontWeight = 'bold';
            app.ProcessImageButton.Position = [624 472 113 25];
            app.ProcessImageButton.Text = 'Process Image';

            % Create StatusLabel
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.FontSize = 14;
            app.StatusLabel.Position = [573 209 52 22];
            app.StatusLabel.Text = 'Status: ';

            % Create EditFieldLabel
            app.EditFieldLabel = uilabel(app.UIFigure);
            app.EditFieldLabel.HorizontalAlignment = 'right';
            app.EditFieldLabel.Position = [573 171 55 22];
            app.EditFieldLabel.Text = 'Edit Field';

            % Create EditField
            app.EditField = uieditfield(app.UIFigure, 'numeric');
            app.EditField.Position = [643 171 100 22];

            % Create ResetButton
            app.ResetButton = uibutton(app.UIFigure, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.FontSize = 14;
            app.ResetButton.FontWeight = 'bold';
            app.ResetButton.Position = [184 136 100 25];
            app.ResetButton.Text = 'Reset';

            % Create LicensePlateDetectionLabel
            app.LicensePlateDetectionLabel = uilabel(app.UIFigure);
            app.LicensePlateDetectionLabel.HorizontalAlignment = 'center';
            app.LicensePlateDetectionLabel.FontSize = 18;
            app.LicensePlateDetectionLabel.FontWeight = 'bold';
            app.LicensePlateDetectionLabel.Position = [317 530 245 41];
            app.LicensePlateDetectionLabel.Text = 'License Plate Detection';

            % Create StatusWaitingforimageLabel
            app.StatusWaitingforimageLabel = uilabel(app.UIFigure);
            app.StatusWaitingforimageLabel.FontWeight = 'bold';
            app.StatusWaitingforimageLabel.Position = [151 209 159 22];
            app.StatusWaitingforimageLabel.Text = 'Status: Waiting for image...';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = vehicleplate_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end