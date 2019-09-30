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

function out = compress(infile, outfile, bitrate_control, bitrate_value, gop, width, height, num_frames, mode_decision, N_Bframes)
%
% Compress video via ffmpeg or x264
%
%---INPUT ARGS ---
% infile: fullpath YUV video
% outfile: fullpath compressed video
% bitrate_control: type of compression: VBR, CBR, CRF
% bitrate_value: compression factor - dependent on bitrate_control
% gop: Group Of Picture value
% width: video width in pixels
% height: video height in pixels
% num_frames: number of frames to compress
% mode_decision: decision mode: RD, SAD
% N_Bframes: number of consecutive B frames
%
%---OUTPUT ARGS ---
% out: 1 if video compression ends with success.


global PATH_TO_X264;
global PATH_TO_FFMPEG;

if ispc
    nulDev = 'NUL';
else
    nulDev = '/dev/null';
end

if nargin < 10
    N_Bframes = 0;
end


% Get extension of the output file
[~,~,extension] = fileparts(outfile);

% Mapping of mode_decision between FFmpeg and x264
switch lower(mode_decision)
    case{'sad'}
        subme = 6;
        mbd = 0;
    case{'rd'}
        subme = 9;
        mbd = 2;
end


optstr = [];
switch extension
    case{'.mpeg'}
        if N_Bframes>0
            optstr = sprintf('%s -bf %d -b_strategy 0 ', optstr, N_Bframes); % b-frame DEFAULT profile
        else
            optstr = sprintf('%s -profile:v 5 ', optstr);
        end
        switch lower(bitrate_control)
            case{'vbr'}
                command = sprintf('%s -f rawvideo -pix_fmt yuv420p -s %dx%d -i %s -vcodec mpeg2video -g %d -q:v %d -qmin %d -qmax %d %s -flags +cgop -mpv_flags +strict_gop -sc_threshold 1000000000 -cmp %s -subcmp %s -mbcmp %s -mbd %d -vframes %d -threads 1 -y %s 2> %s',...
                    PATH_TO_FFMPEG,width,height,infile,gop,bitrate_value, bitrate_value, bitrate_value, optstr, mode_decision,mode_decision,mode_decision,mbd,num_frames, outfile, nulDev);
                case{'cbr'}
                command = sprintf('%s -f rawvideo -pix_fmt yuv420p -s %dx%d -i %s -vcodec mpeg2video -g %d -b:v %dk -bt:v %dk %s -flags +cgop -mpv_flags +strict_gop -sc_threshold 1000000000 -cmp %s -subcmp %s -mbcmp %s -mbd %d -threads 1 -vframes %d -y %s 2> %s',...
                    PATH_TO_FFMPEG,width,height,infile,gop,bitrate_value,floor(0.8*bitrate_value), optstr, mode_decision,mode_decision,mode_decision,mbd,num_frames, outfile, nulDev);
        end
    case{'.mp4'}
        if N_Bframes>0
            optstr = sprintf('%s -bf %d -b_strategy 0 ', optstr, N_Bframes); % b-frame DEFAULT profile
        else
            optstr = sprintf('%s -profile:v 0 ', optstr);
        end
        switch lower(bitrate_control)
            case{'vbr'}
                command = sprintf('%s -f rawvideo -pix_fmt yuv420p -s %dx%d -i %s -vcodec mpeg4 -g %d -q:v %d -qmin %d -qmax %d %s -flags +cgop -mpv_flags +strict_gop -sc_threshold 1000000000 -cmp %s -subcmp %s -mbcmp %s -mbd %d -vframes %d -threads 1 -y %s 2> %s',...
                    PATH_TO_FFMPEG,width,height,infile,gop,bitrate_value, bitrate_value, bitrate_value, optstr, mode_decision,mode_decision,mode_decision,mbd,num_frames, outfile, nulDev);
            case{'cbr'}
                command = sprintf('%s -f rawvideo -pix_fmt yuv420p -s %dx%d -i %s -vcodec mpeg4 -g %d -b:v %dk -bt:v %dk %s -flags +cgop -mpv_flags +strict_gop -sc_threshold 1000000000 -cmp %s -subcmp %s -mbcmp %s -mbd %d -vframes %d -y %s 2> %s',...
                    PATH_TO_FFMPEG,width,height,infile,gop,bitrate_value,floor(0.8*bitrate_value), optstr, mode_decision,mode_decision,mode_decision,mbd,num_frames, outfile, nulDev);
        end
    case{'.h264'}
        if N_Bframes>0
            optstr = sprintf('%s --bframes %d --b-adapt 0 ', optstr, N_Bframes); %--b-adapt 0 should indicate to x264 to use the same number of b-frames in GOP
        else
            optstr = sprintf('%s --profile baseline ', optstr);
        end
        switch lower(bitrate_control)
            case{'vbr'}
                command = sprintf('%s -v %s --qp %d --qpmin %d --qpmax %d --subme %d --trellis 0 --no-scenecut --scenecut 0 --aq-mode 0 -I %d --frames %d -o %s --input-res %dx%d %s 2> %s',...
                    PATH_TO_X264,optstr,bitrate_value,bitrate_value,bitrate_value,subme,gop,num_frames,outfile,width,height,infile, nulDev);
            case{'crf'}
                command = sprintf('%s -v %s --crf %d --subme %d --trellis 0 --no-scenecut --scenecut 0 --aq-mode 0 -I %d --frames %d -o %s --input-res %dx%d %s 2> %s',...
                    PATH_TO_X264,optstr,bitrate_value,subme,gop,num_frames,outfile,width,height,infile, nulDev);
            case{'cbr'}
                command = sprintf('%s -v %s --bitrate %d --vbv-bufsize 10000 --subme %d --trellis 0 --no-scenecut --scenecut 0 --aq-mode 0 -I %d --frames %d -o %s --input-res %dx%d %s 2> %s',...
                    PATH_TO_X264,optstr, bitrate_value,subme,gop,num_frames,outfile,width,height,infile, nulDev);
        end
    case{'.264'}
        if N_Bframes>0
            optstr = sprintf('%s --bframes %d --b-adapt 0 ', optstr, N_Bframes); %--b-adapt 0 should indicate to x264 to use the same number of b-frames in GOP
        else
            optstr = sprintf('%s --profile baseline ', optstr);
        end
        switch lower(bitrate_control)
            case{'vbr'}
                command = sprintf('%s -v %s --qp %d --qpmin %d --qpmax %d --subme %d --trellis 0 --no-scenecut --scenecut 0 --aq-mode 0 -I %d --frames %d -o %s --input-res %dx%d %s 2> %s',...
                    PATH_TO_X264,optstr,bitrate_value,bitrate_value,bitrate_value,subme,gop,num_frames,outfile,width,height,infile, nulDev);
            case{'crf'}
                command = sprintf('%s -v %s --crf %d --subme %d --trellis 0 --no-scenecut --scenecut 0 --aq-mode 0 -I %d --frames %d -o %s --input-res %dx%d %s 2> %s',...
                    PATH_TO_X264,optstr,bitrate_value,subme,gop,num_frames,outfile,width,height,infile, nulDev);
            case{'cbr'}
                command = sprintf('%s -v %s --bitrate %d --vbv-bufsize 10000 --subme %d --trellis 0 --no-scenecut --scenecut 0 --aq-mode 0 -I %d --frames %d -o %s --input-res %dx%d %s 2> %s',...
                    PATH_TO_X264,optstr, bitrate_value,subme,gop,num_frames,outfile,width,height,infile, nulDev);
        end
end

if ispc
    execute_batch_cmd(command, true);
else
    % Call executable
    [status, ~]=system(command);
    if status ~= 0
        error(['Something wrong with the encoding process! Check command: ', command]);
    end
end

out = 1;
