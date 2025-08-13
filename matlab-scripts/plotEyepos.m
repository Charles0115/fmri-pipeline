%% Quick Check: Plot gaze in degrees + fixation mask

function write_eyepos_to_csv(bhv_file)
    [trials, MLConfig] = mlread(bhv_file);
    [~, name, ~] = fileparts(bhv_file);
    
    numTrials = numel(trials);
    data_columns = {};
    
    for trialIdx = 1:numTrials
        % 2) Select trial index, sampling rate, and fixation window
        fs = 1000;              % monkeylogic analog sample rate (Hz)
        fixRadiusDeg = 0.8;       % fixation window radius in degrees (adjustable)
        
        % 3) Pull raw eye data [rawX rawY]
        rawXY = trials(trialIdx).AnalogData.Eye;   % M×2
        
        % 4) Stage-1: offset removal
        offX    = MLConfig.EyeTransform{1,1}.offset(1);
        offY    = MLConfig.EyeTransform{2,1}.offset(2);
        rawCorr = bsxfun(@minus, rawXY, [offX, offY]);
        
        % 5) Stage-2: inverse-rotation + gain + origin
        T12     = MLConfig.EyeTransform{1,2};           % linear stage
        rot_rev = T12.rotation_rev_t;                    % 2×2 inverse-rotation
        gainX   = MLConfig.EyeTransform{1,2}.gain(1);   % deg per raw (X)
        gainY   = MLConfig.EyeTransform{2,2}.gain(2);   % deg per raw (Y)
        origX   = T12.origin(1);                        % deg zero-point X
        origY   = T12.origin(2);                        % deg zero-point Y
        
        % Apply inverse rotation
        rotRaw  = (rot_rev * rawCorr')';  % M×2
        
        % 6) Compute gaze in degrees, then recenter to (0,0)
        x_deg = rotRaw(:,1)*gainX + origX;   % absolute X (°)
        y_deg = rotRaw(:,2)*gainY + origY;   % absolute Y (°)
        x_rel = x_deg - origX;               % relative X (°)
        y_rel = y_deg - origY;               % relative Y (°)
        
        % degXY = [x_rel, y_rel];               % M×2 [X, Y]
        
        % 7) Build fixation mask
        fixMask = (x_rel.^2 + y_rel.^2) <= fixRadiusDeg^2;  % logical M×1
        
        pos_magnitude = sqrt(x_rel.^2 + y_rel.^2);
    
        data_columns{end+1} = x_rel;
        data_columns{end+1} = y_rel;
        data_columns{end+1} = pos_magnitude;
    end
    
    maxRows = max(cellfun(@length, data_columns));
    paddedData = NaN(maxRows, numTrials * 3);
    
    for k = 1:numTrials * 3
        col = data_columns{k};
        paddedData(1:length(col), k) = col;
    end
    
    varNames = cell(1, numTrials * 3);
    for k = 1:numTrials
        varNames{3*k-2} = sprintf('eye_pos%02d_xcoord', k);
        varNames{3*k-1} = sprintf('eye_pos%02d_ycoord', k);
        varNames{3*k} = sprintf('eye_pos%02d_magnitude', k);
    end
    
    T = array2table(paddedData, 'VariableNames', varNames);
    writetable(T, [name '-eye_pos.csv']);

end
% 1) Load BHV + MLConfig
write_eyepos_to_csv('PIP_25TD0710-run10.bhv2');

% plot_heatmap(x_rel, y_rel, 1, 1000000, [-3, 3], [-3, 3], 0.2, "TEST", "X", "Y", 1);


function plot_heatmap(x_pos, y_pos, fix_radius, points_per_frame, x_range, y_range, bin_size, t, x_label, y_label, draw_fix_rect)
    total_points = length(x_pos);
    inner_range = [-fix_radius, fix_radius];

    % Create grid for histogram
    x_edges = x_range(1):bin_size:x_range(2);
    y_edges = y_range(1):bin_size:y_range(2);

    % Create custom colormap
    % First half (1:64): white to red (for inner range)
    % Second half (65:128): white to black (for outer range)
    inner_colors = [ones(128,1), linspace(1,0,128)', linspace(1,0,128)'];
    outer_colors = [linspace(1,0,128)', linspace(1,0,128)', linspace(1,0,128)'];
    custom_map = [inner_colors; outer_colors];

    % Initialize figure
    figure;
    set(gcf, 'Position', [100, 100, 800, 800]);
    axis equal;
    xlim(x_range);
    ylim(y_range);
    hold on;
    
    % Initialize empty histogram
    H_total = zeros(length(y_edges)-1, length(x_edges)-1);

    % Process and plot in batches
    for batch = 1:ceil(total_points/points_per_frame)
        % Get current batch indices
        start_idx = (batch-1)*points_per_frame + 1;
        end_idx = min(batch*points_per_frame, total_points);
        
        % Calculate 2D histogram for current batch
        H_batch = histcounts2(y_pos(start_idx:end_idx), x_pos(start_idx:end_idx), y_edges, x_edges);

        % Add to total histogram
        H_total = H_total + H_batch;
        
        % Create mask for inner and outer regions
        [X_grid, Y_grid] = meshgrid(x_edges(1:end-1)+bin_size/2, y_edges(1:end-1)+bin_size/2);
        inner_mask = (X_grid >= inner_range(1) & X_grid <= inner_range(2)) & ...
                     (Y_grid >= inner_range(1) & Y_grid <= inner_range(2));
        outer_mask = ~inner_mask;
        
        % Normalize counts for colormap indexing
        max_count_inner = max(H_total(inner_mask));
        max_count_outer = max(H_total(outer_mask));
        
        % Create color indices matrix
        color_idx = zeros(size(H_total));
        
        % Inner region (white to red)
        if max_count_inner > 0
            norm_counts_inner = H_total(inner_mask) / max_count_inner;
            color_idx(inner_mask) = round(norm_counts_inner * 127 + 1);
        end
        
        % Outer region (white to black)
        if max_count_outer > 0
            norm_counts_outer = H_total(outer_mask) / max_count_outer;
            color_idx(outer_mask) = round(norm_counts_outer * 127 + 129);
        end
        
        % Plot the heatmap
        cla; % Clear previous frame
        % Pad color_idx with zeros to match pcolor's expected size
        padded_color = [color_idx, zeros(size(color_idx, 1), 1); zeros(1, size(color_idx, 2) + 1)];
        h = pcolor(x_edges, y_edges, padded_color);
        set(h, 'EdgeColor', 'none');  % Remove grid lines
        axis xy;  % Ensure y-axis increases upward
        colormap(custom_map);
    
        % Add title and labels
        title(t);
        xlabel(x_label);
        ylabel(y_label);
        
        if draw_fix_rect == 1
            % Add rectangle to show inner region boundary
            rectangle('Position', [inner_range(1), inner_range(1), ...
                      diff(inner_range), diff(inner_range)], ...
                      'EdgeColor', 'k', 'LineWidth', 1, 'LineStyle', '--');
        end
    
        % Red colorbar
        ax1 = axes('Position', [0.4 0.1 0.5 0.35]);
        colormap(ax1, [linspace(1,1,64)', linspace(1,0,64)', linspace(1,0,64)']); % white to red
        colorbar(ax1, 'Ticks', [0 0.5 1], 'TickLabels', {'0','50','100'});
        axis off;
    
        % Black colorbar
        ax2 = axes('Position', [0.4 0.55 0.5 0.35]);
        colormap(ax2, repmat(linspace(1,0,64)', 1, 3));  % white to black
        colorbar(ax2, 'Ticks', [0 0.5 1], 'TickLabels', {'0','50','100'});
        axis off;

         % Save the frame
        % frame_filename = sprintf('density_heatmap_frame_%02d.png', batch);
        % print(frame_filename, '-dpng', '-r300');
        % fprintf('Saved frame: %s\n', frame_filename);
        
        pause(0.5); % Brief pause to allow rendering
    end

    hold off;
end