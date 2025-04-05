

[filename, filepath] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'});
if isequal(filename, 0)  
    error('No file selected. Please select an image file.');
end

a = imread(fullfile(filepath, filename)); 
a = rgb2gray(a);
figure; imshow(a); title('Car');

[r, c , ~]=size(a);  
b=a(r/3:r,1:c);  
imshow(b);title('LP AREA') 
[r, c, p]=size(b); 
Out=zeros(r,c); 
for i=1:r
    for j=1:c  
        if b(i,j)>150  
            Out(i,j)=1;
        else 
            Out(i,j)=0;
        end
    end
end
BW3 = bwfill(Out,'holes');
BW3=medfilt2(BW3,[4 4]); 
BW3=medfilt2(BW3,[4 4]);  
BW3=medfilt2(BW3,[4 4]);  
BW3=medfilt2(BW3,[5 5]);  
BW3=medfilt2(BW3,[5 5]); 
figure;imshow(BW3,[]); 
BW3 = bwfill(BW3,'holes'); 
[L, num]=bwlabel(BW3); 
STATS=regionprops(L,'all');  
disp(num);  
cc=[];  
removed=0; 
for i=1:num  
    dd=STATS(i).Area;  % area of the current object.
    cc(i)=dd; 
    if (dd < 5000) 
        L(L==i)=0; 
        removed = removed + 1;  
        num=num-1;  
    end
end
[L2, num2]=bwlabel(L);  
figure,imshow(L2); 
STATS = regionprops(L2,'All'); 
if num2>2  
     for i=1:num2   
	aa=  STATS(i).Orientation;   
	if aa > 0  
	imshow(L==i);   

	end  
     end  
	disp('exit');  
end  
 [r, c]=size(L2);  
Out=zeros(r,c);  
k=1;
[L2, num2] = bwlabel(L);  
disp(['Number of detected objects: ', num2str(num2)]);
figure, imshow(label2rgb(L2)); title('Labeled Regions');

if num2 >= 1
   
    areas = [STATS.Area];
    boxes = reshape([STATS.BoundingBox], 4, []).'; % Reshape bounding boxes

   
    aspectRatios = boxes(:,3) ./ boxes(:,4); % width / height

    
    disp('Detected Bounding Boxes:');
    disp(boxes);

    
    disp('Aspect Ratios:');
    disp(aspectRatios);

   
    validIdx = find(aspectRatios > 1.2 & aspectRatios < 8 & areas > 500);

   
    validIdx = validIdx(validIdx <= size(boxes, 1));


    disp('Valid Bounding Box Indices After Filtering:');
    disp(validIdx);

    if isempty(validIdx)
        disp('No valid license plate detected after filtering.');
        return;
    end

  
   \
[~, bestIdx] = max(boxes(validIdx, 2) + boxes(validIdx, 4)); % Consider bottom edge

bestIdx = validIdx(bestIdx); 
B = boxes(bestIdx, :);


Xmin = round(B(2));  
Xmax = round(B(2) + B(4));
Ymin = round(B(1));  
Ymax = round(B(1) + B(3));


Xmin = max(1, Xmin);
Xmax = min(size(b,1), Xmax);
Ymin = max(1, Ymin);
Ymax = min(size(b,2), Ymax);


disp(['Bounding Box: Xmin=', num2str(Xmin), ', Xmax=', num2str(Xmax), ', Ymin=', num2str(Ymin), ', Ymax=', num2str(Ymax)]);


if Xmax > Xmin && Ymax > Ymin
    LP = b(Xmin:Xmax, Ymin:Ymax);
    figure, imshow(LP, []); title('Extracted License Plate');
    results = ocr(LP);  
text = results.Text;
disp(text)
end
else
    disp('Error: Invalid bounding box dimensions. Cropping failed.');
end
