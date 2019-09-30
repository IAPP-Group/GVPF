% Copyright (C) 2019 David Vázquez-Padín, Marco Fontani, Dasara Shullani
%
% GVPF is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% GVPF is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

function [video_cmp1, video_cmp2] = gvpf_12compression(input_filename, btrc1, btrc2, cmpParams, codecs_path)
%
% GVPF 1st-2nd compression - Computes single and double compressed videos
%
%---INPUT ARGS ---
% input_filename: YUV video fullpath
% btrc1: Bitrate control in 1st compression. Possible values are: VBR, CBR, CRF
% btrc1: Bitrate control in 2nd compression. Possible values are: VBR, CBR, CRF
% cmpParams: compression parameters
% cmpParams.ind_cod1: index of 1st compression algorithm, [1, 2, 3] corresponds to {'h264','mpeg','mp4'}
% cmpParams.ind_cod2: index of 2nd compression algorithm, [1, 2, 3] corresponds to {'h264','mpeg','mp4'}
% cmpParams.ind_G1: index of GOP size in 1st compression, [1, 2]    corresponds to [14, 30]
% cmpParams.ind_G2: index of GOP size in 2nd compression, [1, 2, 3] corresponds to [9, 25, 120]
% cmpParams.ind_B1: index of Bitrate/QP in 1st compression.
%    VBR/MPEG-MP4  [1, 2, 3, 4] corresponds to [2, 5, 10, 20]
%    VBR/H.264     [1, 2, 3, 4] corresponds to [20, 26, 32, 42]
%    CBR           [1, 2, 3]    corresponds to [100, 500, 900]
%    CRF           [1, 2, 3]    corresponds to [10, 18, 26]
% cmpParams.ind_B2: index of Bitrate/QP in 2nd compression,
%    VBR/MPEG-MP4  [1, 2, 3, 4] corresponds to [1, 6, 9, 18]
%    VBR/H.264     [1, 2, 3, 4] corresponds to [10, 27, 31, 38]
%    CBR           [1, 2, 3]    corresponds to [100, 500, 900]
%    CRF           [1, 2, 3]    corresponds to [5, 15, 30]
% cmpParams.ind_B_frames: index of number of consecutive B-frames
% in 2nd compression, [1, 2, 3, 4] corresponds to [0, 2, 3, 5]
% codecs_path: path to the codecs folders
%
%---OUTPUT ARGS ---
% video_cmp1: single compressed video parameters
% video_cmp1.video_name: fullpath to the 1st compressed video
% video_cmp1.cod1: compression algorithm used in 1st compression
% video_cmp1.B1: Bitrate/QP value in 1st compression
% video_cmp1.G1: GOP size value in 1st compression
% video_cmp1.btrc1: bitrate control type in 1st compression
% video_cmp1.num_frames: number of frames used in 1st compression
% video_cmp2: double compressed video parameters
% video_cmp2.video_name: fullpath to the 2nd compressed video
% video_cmp2.cod2: compression algorithm used in 2nd compression
% video_cmp2.B2: Bitrate/QP value in 2nd compression
% video_cmp2.G2: GOP size value in 2nd compression
% video_cmp2.btrc2: bitrate control type in 1st compression
% video_cmp2.B_frames: number of consecutive B-frames in 2nd compression
% video_cmp2.num_frames: number of frames used in 2nd compression

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global PATH_TO_X264;
global PATH_TO_FFMPEG;
global PATH_TO_FFPROBE;

ind_mode = 1;
compute_dc = true;
num_frames = 250;
codec1 = {'h264','mpeg','mp4'};
codec2 = {'h264','mpeg','mp4'};
G1 = [14, 30];
G2 = [9, 25, 120];
decision_mode = {'rd'};
b_frames = [0, 2, 3, 5];

if strcmp(btrc1, 'vbr') && strcmp(btrc2, 'vbr')
    % VBR - VBR
    B1 = [2, 5, 10, 20];
    B2 = [1, 6, 9, 18];
    B1_h264 = [20, 26, 32, 42];
    B2_h264 = [10, 27, 31, 38];
else
    if strcmp(btrc1, 'vbr') && strcmp(btrc2, 'crf')
        % VBR - CRF
        B1= [2, 5, 10, 20 ];
        B1_h264= [20, 26, 32, 42];
        B2_h264= [5, 15, 30];
        B2 = B2_h264;
        codec2 = {'h264'};
    else
        if strcmp(btrc1, 'crf') && strcmp(btrc2, 'vbr')
            % CRF - VBR
            B1_h264= [10, 18, 26];
            B1 = B1_h264;
            B2= [1, 6, 9, 18];
            B2_h264= [10, 27, 31, 38];
            codec1 = {'h264'};
        else
            if strcmp(btrc1, 'crf') && strcmp(btrc2, 'crf')
                % CRF - CRF
                B1_h264= [10, 18, 26];
                B2_h264= [5, 15, 30];
                B1 = B1_h264;
                B2 = B2_h264;
                codec1 = {'h264'};
                codec2 = {'h264'};
            else
                if strcmp(btrc1, 'cbr') && strcmp(btrc2, 'cbr')
                    % CBR - CBR
                    B1 = [100, 500, 900];
                    B2 = B1;
                else
                    % WRONG input
                    error('GVPF:gvpf_12compression:btrcNotSupported','btrc1-%s btrc2-%s not supported.',btrc1, btrc2);
                end
            end
        end
    end
end

% Check indexes
ind_cod1 = cmpParams.ind_cod1;
if isempty(intersect(ind_cod1, 1:length(codec1)))
   % CODEC1 WRONG input
   error('GVPF:gvpf_12compression:CodecIndexOutOfBound','Check Codec1 index %d', ind_cod1);
end
ind_cod2 = cmpParams.ind_cod2;
if isempty(intersect(ind_cod2, 1:length(codec2)))
   % CODEC2 WRONG input
   error('GVPF:gvpf_12compression:CodecIndexOutOfBound','Check Codec2 index %d', ind_cod2);
end
ind_G1 = cmpParams.ind_G1;
if isempty(intersect(ind_G1, 1:length(G1)))
   % GOP1 WRONG input
   error('GVPF:gvpf_12compression:GOPIndexOutOfBound', 'Check GOP1 index %d', ind_G1);
end
ind_G2 = cmpParams.ind_G2;
if isempty(intersect(ind_G2, 1:length(G2)))
   % GOP2 WRONG input
   error('GVPF:gvpf_12compression:GOPIndexOutOfBound', 'Check GOP2 index %d', ind_G2);
end
ind_B1 = cmpParams.ind_B1;
if isempty(intersect(ind_B1, 1:length(B1)))
   % Bitrate/QP1 WRONG input
   error('GVPF:gvpf_12compression:BitrateQPIndexOutOfBound', 'Check Bitrate/QP1 index %d', ind_B1);
end
ind_B2 = cmpParams.ind_B2;
if isempty(intersect(ind_B2, 1:length(B2)))
   % Bitrate/QP2 WRONG input
   error('GVPF:gvpf_12compression:BitrateQPIndexOutOfBound', 'Check Bitrate/QP2 index %d', ind_B2);
end
ind_b_frames = cmpParams.ind_B_frames;
if isempty(intersect(ind_b_frames, 1:length(b_frames)))
   % Bframes WRONG input
   error('GVPF:gvpf_12compression:BFramesIndexOutOfBound', 'Check Bframes index %d', ind_b_frames);
end

% Default output
video_cmp1.video_name = '';
video_cmp1.cod1 = '';
video_cmp1.B1 = 0;
video_cmp1.G1 = 0;
video_cmp1.btrc1 = '';
video_cmp1.num_frames = 0;

video_cmp2.video_name = '';
video_cmp2.cod2 = '';
video_cmp2.B2 = 0;
video_cmp2.G2 = 0;
video_cmp2.btrc2 = '';
video_cmp2.B_frames = 0;
video_cmp2.num_frames = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(codecs_path, 'dir')
    error('GVPF:gvpf_12compression:CodecsNotFound','Provide the fullpath to the codecs folder.')
end

% Encoders, decoders and parsers
PATH_TO_X264 = fullfile(codecs_path, 'x264-snapshot-20160424-2245', 'x264');
PATH_TO_FFMPEG = fullfile(codecs_path, 'ffmpeg-3.0.1', 'ffmpeg');
PATH_TO_FFPROBE = fullfile(codecs_path, 'ffmpeg-3.0.1', 'ffprobe');
PATH_TO_EXPORT_MVS = fullfile(codecs_path, 'ffmpeg-3.0.1', 'doc', 'examples', 'extract_mvs');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% copy file to tmp folder
[~, name, ext] = fileparts(input_filename);
if strcmp(ext, '.yuv')
    tmp_video = fullfile(tempdir,[name, ext]);
else
    tmp_video = [tempname '_video', ext];
end
[SUCCESS,MESSAGE,~] = copyfile(input_filename,tmp_video);
if SUCCESS == 0
    error('GVPF:gvpf_12compression:copyError', ['Video copy failed. ', MESSAGE]);
end

% Use FFprobe to extract video information
[width, height, codec, video_name, ext] = get_video_parameters(tmp_video);

% Debug info
fprintf('[info]: Processing -- %s\n', video_name);

%% 1 compression
if (strcmp(btrc1, 'vbr') && (strcmpi(codec1{ind_cod1},'h264')) ) || strcmp(btrc1, 'crf')
    % VBR + H.264 or CRF
    QB1 = B1_h264(ind_B1);
else
    % CBR or MPEG-vbr
    QB1 = B1(ind_B1);
end

% Output file (1st compression)
first_comp_filename   = sprintf('%s_%s_1st.%s',tempname,video_name,codec1{ind_cod1});
first_decomp_filename = sprintf('%s_%s_1st.yuv',tempname,video_name);

% 1st compression
if (~(compress(input_filename, first_comp_filename,btrc1,QB1,G1(ind_G1),width,height,num_frames,decision_mode{ind_mode},0))) % 0 --> No B-frames
    error('GVPF:gvpf_12compression:compressError','Something went wrong with compress (1st compression).')
end

% 1st Decompress
if (~(decompress(first_comp_filename, first_decomp_filename)))
    error('GVPF:gvpf_12compression:decompressError','Something went wrong with decompress (1st compression).')
end

% Debug info
fprintf('[info]: 1 compression -- %s DM1=%s BRC1=%s G1=%02d B1=%02d COD1=%s Bframes=%d\n',video_name,decision_mode{ind_mode},btrc1,G1(ind_G1),QB1,codec1{ind_cod1}, 0); % 0 --> No B-frames

% Update output
video_cmp1.video_name = first_comp_filename;
video_cmp1.cod1 = codec1{ind_cod1};
video_cmp1.B1 = QB1;
video_cmp1.G1 = G1(ind_G1);
video_cmp1.btrc1 = btrc1;
video_cmp1.num_frames = num_frames;

%% 2nd compression
if compute_dc
    if (strcmp(btrc2, 'vbr') && (strcmpi(codec2{ind_cod2},'h264'))) || strcmp(btrc2, 'crf')
        % VBR + H.264
        QB2 = B2_h264(ind_B2);
    else
        % CBR or MPEG-vbr
        QB2 = B2(ind_B2);
    end

    % Output file (2nd compression)
    second_comp_filename   = sprintf('%s_%s_2nd.%s',tempname,video_name,codec2{ind_cod2});

    % 2nd compression
    if (~(compress(first_decomp_filename,second_comp_filename,btrc2,QB2,G2(ind_G2),width,height,num_frames,decision_mode{ind_mode},b_frames(ind_b_frames))))
        error('GVPF:gvpf_12compression:compressError','Something went wrong with compress (2nd compression).')
    end

    % Debug info
    fprintf('[info]: 2 compression -- %s DM1=%s BRC1=%s G1=%02d B1=%02d COD1=%s DM2=%s BRC2=%s G2=%02d B2=%02d COD2=%s Bframes=%d\n',...
        video_name,decision_mode{ind_mode},btrc1,G1(ind_G1),QB1,codec1{ind_cod1},...
        decision_mode{ind_mode},btrc2,G2(ind_G2),QB2,codec2{ind_cod2}, b_frames(ind_b_frames));

    % Update output
    video_cmp2.video_name = second_comp_filename;
    video_cmp2.cod2 = codec2{ind_cod2};
    video_cmp2.B2 = QB2;
    video_cmp2.G2 = G2(ind_G2);
    video_cmp2.btrc2 = btrc2;
    video_cmp2.B_frames = b_frames(ind_b_frames);
    video_cmp2.num_frames = num_frames;
end

% Remove temporal file
if exist(first_decomp_filename, 'file')
    delete(first_decomp_filename);
end

end
