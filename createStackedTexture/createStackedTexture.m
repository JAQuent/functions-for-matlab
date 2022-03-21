function createStackedTexture(fileName, go2R, go2G, go2B, go2A)
%createStackedTexture This functions takes greyscale texture maps (currently only .png) and
%copies them into one RGBA images in the respective channels. 
% go2R = Greyscale image or array that should go into the R channel. 
% go2G = Greyscale image or array that should go into the G channel. 
% go2B = Greyscale image or array that should go into the B channel. 
% go2A = Greyscale image or array that should go into the A channel. 

%% Reade files or copy if arrays
if isstring(go2R) || ischar(go2R)
    R = imread(go2R);
else 
    R = go2R;
end

if isstring(go2G) || ischar(go2G)
    G = imread(go2G);
else 
    R = go2G;
end

if isstring(go2B) || ischar(go2B)
    B = imread(go2B);
else 
    B = go2B;
end

if isstring(go2A) || ischar(go2A)
    A = imread(go2A);
else 
    A = go2A;
end


%% Check dimensions
if ~all(size(R) == size(G)) || ~all(size(G) == size(B)) || ~all(size(R) == size(B)) || ~all(size(A) == size(B))
   error('Not all files have the same dimensions.');
end

%% Get new image
textureMap = zeros(size(R, 1), size(R, 1), 3, 'uint8'); %initialise
textureMap(:, :, 1) = R(:, :, 1);
textureMap(:, :, 2) = G(:, :, 1);
textureMap(:, :, 3) = B(:, :, 1);

%% Write new image
imwrite(textureMap, fileName, 'png', 'Alpha', A(:, :, 1));
end

