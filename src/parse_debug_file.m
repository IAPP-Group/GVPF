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

function [FRAME_type, MB_type] = parse_debug_file(filename, height, width)
%
% Parse the debug file produced by ffmpeg with the debug option '-debug mb_type'
%
%---INPUT ARGS ---
% filename: filename of the debug file produced (with extension)
% height: height (in pixels) of the video
% width: width (in pixels) of the video
%
%---OUTPUT ARGS ---
% FRAME_type: cell array, one element per frame. Each element is a character: P-> P frame, I-> I frame
% MB_type: cell array, one element per frame. Each cell contains a mb_height x mb_width matrix, each element of the matrix gives the type of that macroblock:
%   0 -> skip macroblock
%   1 -> intra macroblock
%   2 -> predicted macroblock

%convert size from pixel to macroblock
mb_height = height/16;
mb_width  = width/16;

%check if everything is integer
if mod(mb_height,1)~=0 || mod(mb_width,1)~=0
    warning('One or both the specified dimensions of the video are not multiple of 16\n(You specified %dx%d pixels).',height,width);
    mb_height = ceil(height/16);
    mb_width  = ceil(width/16);
end

%Open file
fid = fopen(filename);
if fid<0
    display(['Cannot open file ', filename]);
end

%READ TO MATLAB CELL and close the file
k=1;
while 1
    tline{k} = fgetl(fid);
    if ~ischar(tline{k})
        break
    end
    k=k+1;
end
fclose(fid);

flen = k;

%INTERPRETATION...
%Scan until you find the starting line
ptr=1;
while ~strcmpi(tline{ptr},'Press [q] to stop, [?] for help') && ptr<flen
    ptr=ptr+1;
end
ptr=ptr+1;

% check first frame is I-frame
first_frame_id = ptr;
while isempty(strfind(tline{first_frame_id},'New frame')); %scan until next frame
    first_frame_id=first_frame_id+1;
    if first_frame_id==flen %if end of file is reached, we're done!
        return;
    end
    if strcmp(tline{first_frame_id}(end), 'I')
        break;
    else
        if strcmp(tline{first_frame_id}(end), 'P') || strcmp(tline{first_frame_id}(end), 'B')
            % initial parsing failed move to frame in frame
            warning('GVPF:parse_debug_file','First frame is not I-frame. Reset parser.');
            ptr = 1;
            break;
        end
    end
end


%Cycle trhough different frames
f=1;
while ptr<flen
    while isempty(strfind(tline{ptr},'New frame')); %scan until next frame
        ptr=ptr+1;
        if ptr==flen %if end of file is reached, we're done!
            return;
        end
    end
    %Read frame information
    %types:
    % 0 = P/B skipped block
    % 1 = I/P/B block
    % 2 = P/B block, reference to previous (in display order) picture ;
    % 3 = B block, reference to future (in display order) picture ;
    % 4 = B block, bidirectional reference picture ;

    FRAME_type{f} = upper(tline{ptr}(end));

    if f == 1 && ~strcmp(FRAME_type{f}, 'I')
        warning('GVPF:parse_debug_file','I frame not found. Frame parsing failed.')
        FRAME_type = {};
        MB_type = {};
        return
    end

    for r=1:mb_height
        ptr = ptr+1;

        to_analyze = textscan(tline{ptr},repmat('%s ',1,mb_width+3)); % new work_around to fix previous work_around
        to_analyze = [to_analyze{4:end}];
        to_analyze = sprintf('%s ',to_analyze{:});

        try
            to_analyze = strrep(to_analyze,'=',' ');

            % ATTENTION: fix PCM macroblock in intra frames.
            % [doc1]: https://trac.ffmpeg.org/wiki/Debug/MacroblocksAndMotionVectors,
            % [doc2]: https://github.com/FFmpeg/FFmpeg/blob/918de766f545008cb1ab3d62febe71fa064f8ca7/libavcodec/mpegutils.c#L196
            % [MB_TYPE_INTRA_PCM = P]: Lossless (raw samples without prediction)
            MB_type{f}(r,:) = str2num(regexprep(to_analyze,{'i|I|A|P', '>\+|>\||>\-|>', '<\||<\-|<\+|<', 'X\+|X\-|X\||X','d\+|d\-|d\||D\+|D\-|D\||S\-|S\+|S|d|D'},{'1','2','3','4','0'})); %#ok<*ST2NM>
        catch
            error('GVPF:parse_debug_file:mbTypeError','Unknown Macroblock Type.\n%s',to_analyze)
        end

    end
    f=f+1;
end


end
