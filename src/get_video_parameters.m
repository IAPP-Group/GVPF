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

function [width, height, codec, video_filename, ext] = get_video_parameters(filename)
%
% Extracts video parameters using FFprobe or name regexp. If YUV content the
% resolution is extracted from the name: akiyo_cif.yuv is CIF
% resolution.
%
%---INPUT ARGS ---
% input_filename: video fullpath
%
%---OUTPUT ARGS ---
% width: video width in pixels
% height: video heght in pixels
% codec: the name of the compression algorithm (YUV, H.264, ...)
% video_filename: video original name
% ext: video original extension


global PATH_TO_FFPROBE;

% Check if the file exists
if (~exist(filename,'file'))
    error('GVPF:get_video_parameters:fileNotFound','File ''%s'' not found.',filename);
else
    [~, video_filename, ext] = fileparts(filename);
end

if (strcmpi(ext,'.yuv'))
    % Regular expression to check whether the filename contains 'wxh'
    s = regexp(video_filename,'(?<width>\d+)x(?<height>\d+)','names');

    if (~isempty(s))
        width  = str2double(s.width);
        height = str2double(s.height);
        codec  = 'YUV';
    else
        % If 'wxh' is not available then we check the name of the resolution format
        s = regexp(video_filename,'_(?<format>\w+)','names');

        switch lower(s.format) % Note: add more whenever necessary
            case {'sqcif'}
                width  = 128;
                height = 96;
            case {'qcif'}
                width  = 176;
                height = 144;
            case {'scif'}
                width  = 256;
                height = 192;
            case {'sif'}
                width  = 352;
                height = 240;
            case {'cif'}
                width  = 352;
                height = 288;
            case {'4scif'}
                width  = 512;
                height = 384;
            case {'dcif'}
                width  = 528;
                height = 384;
            case {'4sif'}
                width  = 704;
                height = 480;
            case {'4cif'}
                width  = 704;
                height = 576;
            case {'16cif'}
                width  = 1408;
                height = 1152;
            case {'480p','480i'}
                width  = 720;
                height = 480;
            case {'576p','576i'}
                width  = 720;
                height = 576;
            case {'720p','720i'}
                width  = 1280;
                height = 720;
            case {'1080p','1080i','fhd'}
                width  = 1920;
                height = 1080;
            case {'vga'}
                width  = 640;
                height = 480;
            case {'xvga'}
                width  = 800;
                height = 600;
            otherwise
                error('GVPF:get_video_parameters:resolutionNotFound','Resolution of the video has not been matched from the filename: %s',filename);
        end
        codec  = 'YUV';
    end
else
    % Use FFprobe
    tmp_video_info = [tempname '.txt'];
    command = sprintf('%s -v error -of csv=print_section=0 -select_streams v:0 -show_entries stream=height,width,codec_name -i %s > %s',PATH_TO_FFPROBE,filename,tmp_video_info);
    eval(['!' command]);

    % Parse FFprobe output
    v_info = importdata(tmp_video_info,',');
    width  = v_info.data(1);
    height = v_info.data(2);
    codec  = cell2mat(v_info.textdata);

    % Remove temporal files
    delete(tmp_video_info);
end
