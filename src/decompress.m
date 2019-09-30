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

function out = decompress(infile, outfile)
%
% Extracts the input video bitstream via FFmpeg.
%
%---INPUT ARGS ---
% infile: video fullpath
% outfile: YUV output fullpath
%
%---OUTPUT ARGS ---
% out: 1 if ffmpeg call completes without errors.


global PATH_TO_FFMPEG;
out = 1;

command = sprintf('%s -i %s -y %s &> /dev/null',PATH_TO_FFMPEG, infile, outfile);

% Call executable
[status, ~]=system(command);
if status ~= 0
    out = status;
    % error(['Something wrong with the YUV extraction process! Check command: ', command]);
end

