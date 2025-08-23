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
load([dataPath '\ceus\size.mat'],'Prop')
load('locRes.mat')

%% load bubble localization heatmap for trajectoties checking
mask = mat2gray(vasmap_rough).^0.5;  
vasmask = imbinarize(mask,'adaptive','sensitivity',0.75); % used for overlap checking

%% ceus videos info
fps = Prop.Fps;
pixdis = 1e-2/sqrt((Prop.Dx.^2+Prop.Dz.^2)/2);   % 1 cm = n pix
imgSize = Prop.ImgSize;

%% enhance params
EnhPara.ZoomFac = roundn(Prop.Dx/(60e-6),-1);  % zoom to 60um each pixel
I60um = imresize(mask,EnhPara.ZoomFac);
EnhPara.ImgSize60um = size(I60um);  % for tracktest images plotting

%% test for bubble tracking in 20 consecutive frames
PTVPara = InitPTVParams(Prop,pixdis,fps,imgSize);
disp('% ------------------------------------------------------------- %')
fprintf('Testing tracking parameters')
[trackList,tracknum] = MHTMainFastTest(PTVPara,Prop,sI_t,vasmask);
trackList(cellfun('isempty',trackList)) = [];
TrackingTestPlot(trackList,tracknum,dataPath,imgPath,PTVPara,Prop,EnhPara); 

%% tracking for all frames
disp(['Running all frames tracking (Block Size ' num2str(PTVPara.blockSize) ')...'])
% Parallel tracking for a rapid processing .Base on the experience, the 99% prctile 
% of the trajectort length may not exceed 1500 (static bubbles), so we can divide the 
% sI_t into length(sI_t)/blockSize blocks and use parfeval function.
% blockSize = 1000 in this case.
[dists,idxs,sI_t] = InitTrees(sI_t,PTVPara);
[sICells,distCells,idxCells] = GroupingFrames(PTVPara,sI_t,dists,idxs,[]);
nBlock = length(sICells);

disp('Start tracking on CPU...')
futures = parallel.FevalFuture.empty(nBlock,0);
for is = 1:nBlock
    futures(is) = parfeval(@MHTMainFast,2,PTVPara,Prop,...
        sICells{is},vasmask,distCells{is},idxCells{is});
    disp(['Successfully submitted task #' num2str(is) ' (Size:' num2str(numel(sICells{is})) ')'])
end
track_list = cell(nBlock,1);
progress = ProgressBar(nBlock,'Tracking bubbles',25,'>');
for k = 1:nBlock
    [idx,trackList,~] = fetchNext(futures);      
    track_list{idx} = trackList;
    progress();
end
track_list = cat(1,track_list{:});
save('trackRes.mat','track_list')
disp('% ------------------------------------------------------------- %')

