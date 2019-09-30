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

function out = decode(infile, outfile, debug_flag, text_file)
%
% Decode input video via ffmpeg and store macroblocks' types.
%
%---INPUT ARGS ---
% infile: video fullpath
% outfile: YUV output fullpath
% debug_flag: '-debug mb_type'
% text_file: fullpath to the ffmpeg output
%
%---OUTPUT ARGS ---
% out: 1 if ffmpeg call completes without errors.

global PATH_TO_FFMPEG;
out = 1;

% Define command line
command = sprintf('%s -threads 1 %s -i %s -y %s 2> %s',PATH_TO_FFMPEG,debug_flag,infile,outfile,text_file);

% Call executable
[status, ~]=system(command);
if status ~= 0
    out = status;
    % error(['Something wrong with the Macroblock extraction process! Check command: ', command]);
end
