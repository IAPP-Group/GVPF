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

function mv_values = parse_mv_file(mv_temp_file, FRAME_type, width, height)
%
% Parse Motion Vectors information
%
%---INPUT ARGS ---
% mv_temp_file: filename of the motion vector file produced by ffmpeg
% FRAME_type: frame types
% height: height (in pixels) of the video
% width: width (in pixels) of the video
%
%---OUTPUT ARGS ---
% mv_values: motion vector values for each macroblock and frame

% Parse text file with MV's information
fid = fopen(mv_temp_file);
C = textscan(fid, '%d,%d,%d,%d,%d,%d,%d,%d,%dx%d','headerlines',1);
fclose(fid);

% Initialize memory
mv_values = cell(numel(FRAME_type),1);
for i = 1:numel(FRAME_type)
    mv_values{i} = NaN(ceil(height/16), ceil(width/16));
end

% For each frame compute the magnitude of each MV per MB
for ind_frame = 1:numel(FRAME_type)
    switch (upper(FRAME_type{ind_frame}))
        case {'I'} % I-frames
            % Do nothing
        case {'P'} % P-frames
            % Take MVs for 16x16 Predicted MBs
            x_0 = double(C{5}(C{1}==ind_frame));
            y_0 = double(C{6}(C{1}==ind_frame));
            x_1 = double(C{7}(C{1}==ind_frame));
            y_1 = double(C{8}(C{1}==ind_frame));

            % All MVs, but some of them come from the same MB due to MB partitions
            mv_temp = sqrt((x_1-x_0).^2+(y_1-y_0).^2);

            j = max(min(floor((x_0)/16),floor(width/16)-1),0);
            i = max(min(floor((y_0)/16),floor(height/16)-1),0);
            try
                INTER_mb_ind = sub2ind([ceil(height/16) ceil(width/16)],i+1,j+1);
            catch
                keyboard
            end
            mv_values{ind_frame}(INTER_mb_ind) = mv_temp;
        case {'B'}
            % Take MVs for 16x16 Predicted MBs
            x_0 = double(C{5}(C{1}==ind_frame));
            y_0 = double(C{6}(C{1}==ind_frame));
            x_1 = double(C{7}(C{1}==ind_frame));
            y_1 = double(C{8}(C{1}==ind_frame));

            % All MVs, but some of them come from the same MB due to MB partitions
            mv_temp = sqrt((x_1-x_0).^2+(y_1-y_0).^2);

            j = max(min(floor((x_0)/16),floor(width/16)-1),0);
            i = max(min(floor((y_0)/16),floor(height/16)-1),0);
            try
                INTER_mb_ind = sub2ind([ceil(height/16) ceil(width/16)],i+1,j+1);
            catch
                keyboard
            end
            mv_values{ind_frame}(INTER_mb_ind) = mv_temp;
    end

end
