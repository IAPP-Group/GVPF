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

% test_me.m performs single and double compression over akiyo_cif.yuv
% video in VBR-CRF with: MPEG-2/H.264 codec, GOP size 14/9, QP 2/5 without
% B-frames in 1st or 2nd compression.
% It performs the GVPF analysis: first GOP estimation and double compression
% detection for both resulting videos.

codecs_path = '';
display_output_flag = true; % use to print output

if ~exist(codecs_path, 'dir')
    error('GVPF:test_me:CodecsFolderNotFound', 'Modify test_me.m with codecs fullpath.');
end


input_filename = fullfile(pwd, 'akiyo_cif.yuv');
btrc1 = 'vbr';
btrc2 = 'crf';
cmpParams.ind_cod1 = 2;     % CODEC1   = MPEG-2
cmpParams.ind_cod2 = 1;     % CODEC2   = H.264
cmpParams.ind_G1 = 1;       % GOP1     = 14
cmpParams.ind_G2 = 1;       % GOP2     = 9
cmpParams.ind_B1 = 1;       % B1/QP1   = 2
cmpParams.ind_B2 = 1;       % B2/QP2   = 5
cmpParams.ind_B_frames = 1; % B_frames = 0

%% Perform 1st-2nd compression
%
% video_cmp1 =
%     video_name: '/tmp/tp8817ff81_19ff_4866_af35_1931d03b0bb3_akiyo_cif_1st.mpeg'
%     cod1: 'mpeg'
%     B1: 2
%     G1: 14
%     btrc1: 'vbr'
%     num_frames: 250
%
%
% video_cmp2 =
%     video_name: '/tmp/tpe0eeeb28_1fa4_4672_9a43_c255f8f64320_akiyo_cif_2nd.h264'
%     cod2: 'h264'
%     B2: 5
%     G2: 9
%     btrc2: 'crf'
%     B_frames: 0
%     num_frames: 250
[video_cmp1, video_cmp2] = gvpf_12compression(input_filename, btrc1, btrc2, cmpParams, codecs_path);

%% GVPF estimation on 1st compressed video
%
% results_cmp1 =
%     video: '/tmp/tp8817ff81_19ff_4866_af35_1931d03b0bb3_akiyo_cif_1st.mpeg'
%     gop_estimation: 64
%     phi_c_norm: 0.5100
%     frames: {1×249 cell}
%     mb_types: {1×249 cell}
%     mv_values: {249×1 cell}
%     dc_detection: 0
results_cmp1 = gvpf_estimation(video_cmp1.video_name, codecs_path);

%% GVPF estimation on 2nd compressed video
%
% results_cmp2 =
%     video: '/tmp/tpe0eeeb28_1fa4_4672_9a43_c255f8f64320_akiyo_cif_2nd.h264'
%     gop_estimation: 14
%     phi_c_norm: 1.8041
%     frames: {1×250 cell}
%     mb_types: {1×250 cell}
%     mv_values: {250×1 cell}
%     dc_detection: 1
results_cmp2 = gvpf_estimation(video_cmp2.video_name, codecs_path);


%% Display output
if display_output_flag
    disp('GVPF analysis output:');
    % 1st
    disp(video_cmp1);
    disp(results_cmp1);
    % 2nd
    disp(video_cmp2);
    disp(results_cmp2);
end
