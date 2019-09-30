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

function [est_gop, period_goodness_norm, nfvp_nt] = gvpf_analysis(FRAME_type, mb_type, mv_values)
%
% Perform GVPF analysis
%
%---INPUT ARGS ---
% FRAME_type: frame types
% mb_type: macroblock types for each frame
% mv_values: motion vector values for each macroblock and frame
%
%---OUTPUT ARGS ---
% est_gop: first GOP estimation
% period_goodness_norm: double detection phi value
% nfvp_nt: Variation of Prediction Footprint signal for each frame


% Allocate memory
num_frames = numel(mb_type);
i_mb = zeros(1,num_frames); % collects number of I-MB per frame
s_mb = zeros(1,num_frames); % collects number of S-MB per frame
p_mb = zeros(1,num_frames); % collects number of P-MB with MV=0 per frame
f_mb = NaN(numel(FRAME_type),1); % collects number of FWD-MB per frame (only B-frames)
b_mb = NaN(numel(FRAME_type),1); % collects number of BWD-MB per frame (only B-frames)
f_mb_to_p_mb = NaN(numel(FRAME_type),1); % number of MBs that change from FWD-MB to BWD-MB (only B-frames)

% Process each frame
for ind_frame = 1:num_frames
    if (FRAME_type{ind_frame} == 'I') % only for I-frames
        if (ind_frame > 1) % If it is not the first frame, take previous value
            i_mb(ind_frame) = i_mb(ind_frame-1);
            s_mb(ind_frame) = s_mb(ind_frame-1);
            p_mb(ind_frame) = p_mb(ind_frame-1);
        else
            i_mb(ind_frame) = 0;
            s_mb(ind_frame) = 0;
            p_mb(ind_frame) = 0;
        end
    elseif (FRAME_type{ind_frame} ~= 'I') % for P- and B-frames
        % MB types:
        % 0 -> S-MB
        % 1 -> I-MB
        % 2 -> P-MB (or FWD-MB for B-frames)
        % 3 -> BWD-MB (only for B-frames)
        i_mb(ind_frame) = sum(mb_type{ind_frame}(:) == 1);
        s_mb(ind_frame) = sum(mb_type{ind_frame}(:) == 0);
        p_mb(ind_frame) = sum((mv_values{ind_frame}(mb_type{ind_frame}==2) == 0));

        % B-frames
        if (FRAME_type{ind_frame} == 'B')
            f_mb(ind_frame) = sum(reshape(mb_type{ind_frame} == 2,[],1)); % FWD MB
            b_mb(ind_frame) = sum(reshape(mb_type{ind_frame} == 3,[],1)); % BWD MB
            if (FRAME_type{ind_frame-1} == 'B')
                f_mb_to_p_mb(ind_frame) = sum(reshape((mb_type{ind_frame-1} == 2)&(mb_type{ind_frame} == 3),[],1)); % Compute the number of FWD-MBs that change to BWD-MB
            else
                f_mb_to_p_mb(ind_frame) = b_mb(ind_frame)-f_mb(ind_frame); % Take the difference between BWD-MB and FWD-MB when it is the first B-frame from the subgop
            end
        end
    end
end

% Allocate memory
nfvp_nt = zeros(1,numel(s_mb));

% Compute New-FVP ;-)
for j = 2:numel(s_mb)-1
    [~,ind1] = min(s_mb(j-1:j+1));
    [~,ind2] = max(i_mb(j-1:j+1));
    [~,ind3] = max(p_mb(j-1:j+1));
    [~,ind4] = min(p_mb(j-1:j+1));

    if ((ind1 == 2)&&(ind2 == 2)&&(ind3 == 2))&&(FRAME_type{j-1} ~= 'I') % S-MB decreases, I-MB increases, and P-MB (with MV=0) increases
        nfvp_nt(j) = abs((p_mb(j)-p_mb(j-1))*(s_mb(j)-s_mb(j-1))*(i_mb(j)-i_mb(j-1)))+abs((p_mb(j+1)-p_mb(j))*(s_mb(j+1)-s_mb(j))*(i_mb(j+1)-i_mb(j)));
    elseif ((ind1 == 2)&&(ind2 == 2))% usual VPF
        nfvp_nt(j) = abs((s_mb(j)-s_mb(j-1))*(i_mb(j)-i_mb(j-1)))+abs((s_mb(j+1)-s_mb(j))*(i_mb(j+1)-i_mb(j)));
    elseif ((ind1 == 2)&&(ind3 == 2))&&(FRAME_type{j-1} ~= 'I') % S-MB decreases and P-MB (with MV=0) increases
        nfvp_nt(j) = abs((s_mb(j)-s_mb(j-1))*(p_mb(j)-p_mb(j-1)))+abs((s_mb(j+1)-s_mb(j))*(p_mb(j+1)-p_mb(j)));
    elseif ((ind2 == 2)&&(ind3 == 2))&&(FRAME_type{j-1} ~= 'I') % I-MB increases and P-MB (with MV=0) increases
        nfvp_nt(j) = abs((i_mb(j)-i_mb(j-1))*(p_mb(j)-p_mb(j-1)))+abs((i_mb(j+1)-i_mb(j))*(p_mb(j+1)-p_mb(j)));
    elseif ((ind2 == 2)&&(ind4 == 2))&&(s_mb(j)==0)&&(FRAME_type{j-1} ~= 'I') % S-MB == 0 and I-MB increases and P-MB (with MV=0) decreases
        nfvp_nt(j) = abs((i_mb(j)-i_mb(j-1))*(-(p_mb(j)-p_mb(j-1))))+abs((i_mb(j+1)-i_mb(j))*(-(p_mb(j+1)-p_mb(j)))); %(p_mb(j)-p_mb(j-1)) to substitute
    else
        nfvp_nt(j) = 0;
    end

    % For B-frames
    if (nfvp_nt(j) ~= 0)
        j0 = 1;
        b_values = [];
        f_values = [];
        while (FRAME_type{j-j0} == 'B')
            b_values = [b_values f_mb_to_p_mb(j-j0)];
            f_values = [f_values f_mb(j-j0)-b_mb(j-j0)];
            j0 = j0+1;
        end
        % Correct VPF shift
        if (~isempty(b_values))
            b_values = fliplr(b_values);
            temp = nfvp_nt(j);
            [~, ind_max] = max(b_values);
            if (min(f_values) < 0)
                shift = numel(b_values)-ind_max;
                nfvp_nt(j-shift-1) = temp;
                nfvp_nt(j) = 0;
            end
        end
    elseif (sign(f_mb(j-1)-b_mb(j-1))-sign(f_mb(j)-b_mb(j)) == 2) % In case there is no VPF in the next P-frame, but there is an important change in the difference of FWD-MB and BWD-MB from one frame to the other
        nfvp_nt(j) = nfvp_nt(j) + abs(f_mb(j)-f_mb(j-1))*abs(b_mb(j)-b_mb(j-1));
    end
end

x = nfvp_nt;
[dummy, sarray] = sort(x,'descend');

cand_gop = [];
for k=1:sum(dummy~=0)
    for j=1:sum(dummy~=0)
        cand_gop(k,j) = gcd(sarray(k)-1, sarray(j)-1);
    end
end

if isempty(cand_gop)
    period_goodness_norm = -1000; %NaN;
    est_gop = -5;
    return
else
    if length(cand_gop)>1
        cand_gop = cand_gop .* ~diag(ones(1,sum(dummy~=0)));
    end
end

% erase fake candidate and repetitions
% workaround gop1<=5 is not considered
cand_gop = unique(cand_gop(cand_gop(:)>5));

if isempty(cand_gop)
    period_goodness_norm = -1000; %NaN;
    est_gop = -5;
    return
else
    GOPmax = length(cand_gop);
end


% Allocate memory
goodness = zeros(1,GOPmax);

% For each possible GOP
for w = 1:length(cand_gop)
    igop = cand_gop(w);
    % Blockify the vector according to the assumed GOP
    xB = zeros(floor(numel(x)/igop),igop);
    for j=0:size(xB,1)-1
        xB(j+1,:) = x(igop*j+1:igop*j+igop);
    end

    %Penalize for each missing peak in xB(1,:)
    n_missing = sum(xB(:,1)==0);
    penalty_scale = 0.12*max(xB(:,1)); %apply this penalty for each empty block
    goodness(w) = sum(xB(:,1)) - penalty_scale*n_missing; %calculate the sum of energy in multiples of GOP, subtract the penalty from that.

    %Get the total "noise" in position of blocks.
    noise_sum{w,:} = sum(xB(:,2:end),1);

    %Lower to goodnes with the highest peak in noise (if there is one!)
    if ~isempty(noise_sum{w,:})
        goodness(w) = goodness(w) - max(noise_sum{w,:});
    end

end

% Occam razor
[period_goodness, best_cand_idx] = max(goodness);

if max(x) == 0
   % not-relevant peacks found
   period_goodness_norm = -1000;
else
    period_goodness_norm = period_goodness/max(x);
end

% BEST candidate
 est_gop = cand_gop(best_cand_idx);
