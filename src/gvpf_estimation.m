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

function results = gvpf_estimation(input_filename, codecs_path)
%
% GVPF estimation - First GOP estimation and Double Compression Detection
%
%---INPUT ARGS ---
% input_filename: video fullpath
% codecs_path: path to the codecs folders
%
%---OUTPUT ARGS ---
% results: GVPF results
% results.video: video fullpath
% results.gop_estimation: GVPF GOP estimation
% results.phi_c_norm: GVPF Double Compression Detection parameter
% results.frames: all video frames
% results.mb_types: all macroblock types for each frame
% results.mv_values: all motion vector values
% results.dc_detection: Double Compression Flag (false: single compressed video, true: double compressed video)

% Define global paths for encoders, decoders and parsers
global PATH_TO_X264;
global PATH_TO_FFMPEG;
global PATH_TO_FFPROBE;
global PATH_TO_EXPORT_MVS;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist(codecs_path, 'dir')
    error('GVPF:gvpf_estimation:CodecsNotFound','Provide the fullpath to the codecs folder.')
end

% Encoders, decoders and parsers
PATH_TO_X264 = fullfile(codecs_path, 'x264-snapshot-20160424-2245', 'x264');
PATH_TO_FFMPEG = fullfile(codecs_path, 'ffmpeg-3.0.1', 'ffmpeg');
PATH_TO_FFPROBE = fullfile(codecs_path, 'ffmpeg-3.0.1', 'ffprobe');
PATH_TO_EXPORT_MVS = fullfile(codecs_path, 'ffmpeg-3.0.1', 'doc', 'examples', 'extract_mvs');

% initial setup
results.video = input_filename;
results.gop_estimation = 0;
results.phi_c_norm = 0.0;
results.frames = {};
results.mb_types = {};
results.mv_values = {};
results.dc_detection = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Get video parameters
[~, ~, ext] = fileparts(input_filename);

if strcmp(strtrim(ext), '.mov') || strcmp(strtrim(ext), '.mp4') || strcmp(strtrim(ext), '.3gp') || strcmp(strtrim(ext), '.h264') || strcmp(strtrim(ext), '.mpeg')

    % copy file to tmp folder
    tmp_video = [tempname '_video', ext];
    [SUCCESS,MESSAGE,~] = copyfile(input_filename,tmp_video);
    if SUCCESS == 0
        error('GVPF:gvpf_estimation:copyError', ['Video copy failed. ', MESSAGE]);
    end

    % Use FFprobe to extract video information
    [width, height, ~, video_name, ~] = get_video_parameters(tmp_video);

    % Debug info
    fprintf('[info]: Processing -- %s ', video_name);


    % Use temporal files or specific ones

    % Output file (2nd compression)
    decomp_filename = sprintf('%s.yuv',tempname);
    text_file = sprintf('%s.txt',tempname);

    % Decoding
    if (~(decode(tmp_video,decomp_filename,'-debug mb_type',text_file)))
        error('GVPF:gvpf_estimation:decodeError','Something went wrong with decoding.')
    end

    % Parse text file with MB types
    [FRAME_types, mb_types] = parse_debug_file(text_file, height, width);
    if numel(FRAME_types) == 0 && numel(mb_types) == 0
        warning('Skipping %s file', video_name)
    else
        % Obtain MVs
        mv_temp_file = [tempname '_mv.txt'];
        eval(['!' PATH_TO_EXPORT_MVS ' ' tmp_video ' > ' mv_temp_file ' 2> /dev/null']);

        % Parse MV file
        mv_values = parse_mv_file(mv_temp_file, FRAME_types, width, height);

        % Apply new approach
        [est_gop, phi_c_norm] = gvpf_analysis(FRAME_types,mb_types,mv_values);


        % Debug info
        fprintf(' -- estGOP: %4d -- phi: %3.3f\n',est_gop, phi_c_norm);


        % Collect results
        results.gop_estimation = est_gop;
        results.phi_c_norm = phi_c_norm;
        results.frames = FRAME_types;
        results.mb_types = mb_types;
        results.mv_values = mv_values;


        % set double compression detection flag
        % DC_THRESHOLD average threshold obtained during GVPF testing.
        DC_THRESHOLD = 0.6;
        if phi_c_norm >= DC_THRESHOLD
            results.dc_detection = true;
        end

        % Remove temporal file
        if exist('mv_temp_file', 'var')
            delete(mv_temp_file);
        end
    end

    % Remove temporal files
    if exist(decomp_filename, 'file')
        delete(decomp_filename);
    end
    if exist(text_file, 'file')
      delete(text_file)
    end
    if exist(tmp_video, 'file')
      delete(tmp_video)
    end
else
    error('GVPF:gvpf_estimation:formatError','Video file not compatible with GVPF analysis.')
end



end
