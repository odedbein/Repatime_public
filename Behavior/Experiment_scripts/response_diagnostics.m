function [ed] = response_diagnostics(max_rt, num_total_trials)

RIGHT = 1;
WRONG = 2;
NO_RESPONSE = 3;
cm = nan(3,3);
cm(RIGHT, :) = [0 0 1];
cm(WRONG, :) = [1 0 0];
cm(NO_RESPONSE, :) = [1 1 1]*.9;

function [ci] = get_color(expected, actual)
  if isnan(actual)
    ci = NO_RESPONSE;
  elseif actual == expected
    ci = RIGHT;
  elseif actual ~= expected
    ci = WRONG;
  end
end

point_size = 20;


trial_number = 1;
rts = nan(1, num_total_trials);
point_colors = nan(num_total_trials, 1);

  

% initialize plot
fh = gcf;
clf;
set(fh, 'WindowStyle', 'docked');%dock in command
set(fh, 'Name', 'diagnostics', 'NumberTitle', 'off');
ylim( [0 max_rt] );
xlim( [0 num_total_trials] );
xlabel('trial');
ylabel('RT');
colormap( cm );

hold on;

% matlab colormap is buggy, so the following line is necessary for the
% colors to not change as new points of different types come in.
scatter( [0 0 0], [0 0 0], point_size, [RIGHT;  WRONG;  NO_RESPONSE], 'filled' );


  function log_trial(rt, expected, actual)
    tn = trial_number; % this is just for brevity
    
    % log new data
    rts(tn) = rt;
    point_colors(tn) = get_color(expected, actual);
    
    % add this new data to the diagnostic display
    if tn == 1
      x = tn;
    else
      x = (tn-1):tn;
    end
    plot( x, rts(x), '-', 'Color', 0.7*[1 1 1]);
    colormap( cm );
    scatter( x, rts(x), point_size, point_colors(x), 'filled' );
    
    trial_number = tn + 1;
  end


ed.log_trial = @log_trial;

end

