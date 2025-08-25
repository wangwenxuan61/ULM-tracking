%% Efficient bubble tracking algorithm in ULM
% Distance/index trees generation is based on GPU
% Parallel multi-hyphoesis tracking is based on CPU
clc
clear
close all

%% image path for saving track-test image
dataPath = 'data';
imgPath = 'imgs';

%% load localization results and image size
% see readme for more details of data discription
load('locRes.mat')

%% load bubble localization heatmap for trajectoties checking
mask = mat2gray(vasmap_rough).^0.5;  
vasmask = imbinarize(mask,'adaptive','sensitivity',0.75); % used for overlap checking

%% ceus videos info
fps = Prop.Fps;
pixdis = 1e-2/sqrt((Prop.Dx.^2+Prop.Dz.^2)/2);   % 1 cm = n pix
imgSize = Prop.ImgSize;

%% run multi-hypothesis tracking
runMHT;

