function varargout = batchSignal(varargin)
% BATCHSIGNAL MATLAB code for batchSignal.fig
%      BATCHSIGNAL, by itself, creates a new BATCHSIGNAL or raises the existing
%      singleton*.
%
%      H = BATCHSIGNAL returns the handle to a new BATCHSIGNAL or the handle to
%      the existing singleton*.
%
%      BATCHSIGNAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BATCHSIGNAL.M with the given input arguments.
%
%      BATCHSIGNAL('Property','Value',...) creates a new BATCHSIGNAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before batchSignal_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to batchSignal_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help batchSignal

% Last Modified by GUIDE v2.5 25-Apr-2013 11:32:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @batchSignal_OpeningFcn, ...
    'gui_OutputFcn',  @batchSignal_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before batchSignal is made visible.
function batchSignal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to batchSignal (see VARARGIN)

% Choose default command line output for batchSignal
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes batchSignal wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = batchSignal_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in lbContours.
function lbContours_Callback(hObject, eventdata, handles)
% hObject    handle to lbContours (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lbContours contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lbContours
set(handles.lbSignal,'value',get(hObject,'Value'));


% --- Executes during object creation, after setting all properties.
function lbContours_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbContours (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lbSignal.
function lbSignal_Callback(hObject, eventdata, handles)
% hObject    handle to lbSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lbSignal contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lbSignal

set(handles.lbContours,'value',get(hObject,'Value'));

% --- Executes during object creation, after setting all properties.
function lbSignal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbChangeSig.
function pbChangeSig_Callback(hObject, eventdata, handles)
% hObject    handle to pbChangeSig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% grab the previous list of folders
contoursFolders = getappdata(handles.figure1,'contoursFolders');
signalFolders = getappdata(handles.figure1,'signalFolders');

% which folder to change
iFolder = get(handles.lbSignal,'Value');

% loop over folders and ask for signal that goes with it
tempDir = contoursFolders{iFolder};
[parent,child] = fileparts(tempDir);
[gparent,parent] = fileparts(parent);
[ggparent,gparent] = fileparts(gparent);
folderList2 = uipickfiles('Prompt',['Select YFP for: ',gparent,filesep,parent,filesep,child],...
    'NumFiles',1);
if not(iscell(folderList2));
    signalFolders(iFolder) = {folderList2};
else
    signalFolders(iFolder) = folderList2;
end


% store the folder lists
setappdata(handles.figure1,'contoursFolders',contoursFolders);
setappdata(handles.figure1,'signalFolders',signalFolders);

% update the display
displayLists(handles);

% --- Executes on button press in pbAdd.
function pbAdd_Callback(hObject, eventdata, handles)
% hObject    handle to pbAdd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% prompt the user to select folders
folderList = uipickfiles('Prompt','Select folders with contour files');

if isequal(folderList,0);
    return
end

% make sure it is in cell format
if not(iscell(folderList))
    folderList = {folderList};
else
    folderList = folderList';
end

% loop over folders and ask for signal that goes with it
sigFolderList = {};
for iFolder = 1:size(folderList,1)
    tempDir = folderList{iFolder};
    [parent,child] = fileparts(tempDir);
    [gparent,parent] = fileparts(parent);
    [ggparent,gparent] = fileparts(gparent);
    
    folderList2 = uipickfiles('Prompt',['Select YFP for: ',gparent,filesep,parent,filesep,child],...
        'NumFiles',1);
    
    if isequal(folderList2,0)
        return;
    end
    
    if not(iscell(folderList2));
        sigFolderList(iFolder) = {folderList2};
    else
        sigFolderList(iFolder) = folderList2;
    end
end

sigFolderList = reshape(sigFolderList,numel(sigFolderList),1);

% grab the previous list of folders
contoursFolders = getappdata(handles.figure1,'contoursFolders');
signalFolders = getappdata(handles.figure1,'signalFolders');

% add the current folders to this list
contoursFolders = cat(1,contoursFolders,folderList);
signalFolders = cat(1,signalFolders,sigFolderList);

% store the folder lists
setappdata(handles.figure1,'contoursFolders',contoursFolders);
setappdata(handles.figure1,'signalFolders',signalFolders);

% update the display
displayLists(handles);


% update the list of displayed folders
function displayLists(handles)
% get the lists that are in appdata, not the 'string' of the list boxes
contoursFolders = getappdata(handles.figure1,'contoursFolders');
signalFolders = getappdata(handles.figure1,'signalFolders');
switch get(handles.cbFullpath,'Value')
    case 1 % suppress base stem
        for iDir = 1:size(contoursFolders,1);
            % first for the contours file
            tempDir = contoursFolders{iDir};
            [parent,child] = fileparts(tempDir);
            [gparent,parent] = fileparts(parent);
            [ggparent,gparent] = fileparts(gparent);
            contoursFolders{iDir} = [gparent,filesep,parent,filesep,child];
            
            % then for the contours file
            tempDir = signalFolders{iDir};
            [parent,child] = fileparts(tempDir);
            [gparent,parent] = fileparts(parent);
            [ggparent,gparent] = fileparts(gparent);
            signalFolders{iDir} = [gparent,filesep,parent,filesep,child];
        end
    case 0 % display the whole path
end

set(handles.lbContours,'String',contoursFolders);
set(handles.lbSignal,'String',signalFolders);




% --- Executes on button press in pbRemove.
function pbRemove_Callback(hObject, eventdata, handles)
% hObject    handle to pbRemove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folderId = get(handles.lbContours,'Value');

% get the folder lists
contoursFolders = getappdata(handles.figure1,'contoursFolders');
signalFolders = getappdata(handles.figure1,'signalFolders');

% remove folders
contoursFolders(folderId) = [];
signalFolders(folderId) = [];

if isempty(contoursFolders)
    contoursFolders = {};
    signalFolders = {};
end
% store the folder lists
setappdata(handles.figure1,'contoursFolders',contoursFolders);
setappdata(handles.figure1,'signalFolders',signalFolders);

% move the selection
set(handles.lbContours,'Value',max(1,folderId-1));
set(handles.lbSignal,'Value',max(1,folderId-1));

% update the display
displayLists(handles);


% --- Executes on button press in pbDoneNRun.
function pbDoneNRun_Callback(hObject, eventdata, handles)
% hObject    handle to pbDoneNRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contoursFolders = getappdata(handles.figure1,'contoursFolders');
signalFolders = getappdata(handles.figure1,'signalFolders');


%% run segment companion images on each of the mat files
progressbar('folders','files','frames', 'cells')     % Initialize/reset two bars with two labels
nOtherChannels = 1;

% progress bar increment size
pbIncrFold = 1/size(contoursFolders,1);

channel(1).type = 'phase';
channel(2).type = 'fluor';
channel(1).label = 'phase';
channel(2).label = 'YFP';

params.progbar.type = 'multipleFolders';
params.progbar.folderIncrement = 1/size(contoursFolders,1);
params.progbar.currentFolder = -10*eps;
disp('Disabling display of warnings');
warningState = warning('off','all');
for jjFolder = 1:size(contoursFolders,1);
    try
        
        channel(1).path = contoursFolders{jjFolder};
        channel(2).path = signalFolders{jjFolder};
        
        % list of mat files
        matName = dir([contoursFolders{jjFolder},filesep,'*.mat']);
        params.progbar.fileIncrement = 1/size(matName,1);
        
        for iiMat = 1:size(matName,1);
            params.progbar.currentFile = -10*eps+(iiMat-1)*params.progbar.fileIncrement;
            % increase the folder indicator if we are moving on
            if or(jjFolder>1,iiMat>1);
                params.progbar.currentFolder = params.progbar.currentFolder+...
                    params.progbar.fileIncrement*params.progbar.folderIncrement;
            else
                params.progbar.currentFolder = 10*eps;
            end
            % increment size for cells/file
            for iChannel=1:2
                channel(iChannel).name = strrep(matName(iiMat).name,'CONTOURS.mat','.tif');
                whereIsC0 = strfind(channel(iChannel).name,'C=');
                whereIsDotTif = strfind(channel(iChannel).name,'.tif');
                channel(iChannel).name = [channel(iChannel).name(1:whereIsC0+1),...
                    num2str(iChannel-1),channel(iChannel).name(whereIsDotTif:end)];
            end
            segmentCompanionImages(channel,matName(iiMat).name,params);
        end
    catch ME
        disp(['Unable to process ',contoursFolders{jjFolder}]);
    end
    
end
warning(warningState);
progressbar(1);

if exist('ME','var');
    rethrow(ME);
end

disp('done processing');
% save('send2ben.mat');
% disp('done saving mat');
% close(handles.figure1);


% --- Executes on button press in cbFullpath.
function cbFullpath_Callback(hObject, eventdata, handles)
% hObject    handle to cbFullpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cbFullpath
displayLists(handles);
