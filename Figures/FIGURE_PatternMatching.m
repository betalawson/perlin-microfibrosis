function FIGURE_PatternMatching
% This function generates the figure showing the matching patterns created
% for the four different types of microfibrosis

% Define the plotting sizes (all as fractions of one)
margin = 0.025;
xgap = -0.55;
xsep = 0.025;
ygap = 0.0165;
y_inclassgap = 0.008;
leftTextSpace = 0.025;
titleSpace = 0.025;
bottomSpace = 0.05;

% Specify the number of generated patterns to show
n_show = 6;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Switch up a level to the main folder to run code
cd ..

% Define the fibrosis classification names
%fibro_classes = {'Interstitial', 'Compact', 'Diffuse', 'Patchy'};
fibro_classes = {'I', 'C', 'D', 'P'};

% Define the classes that have both fibre and non-fibre versions
dual_classes = [2, 3];

% Calculate the number of rows and columns from the parameter vectors
n_classes = length(fibro_classes);    % Set by hand because of the inclusion of both fibre and non-fibre versions for some patterns
n_cols = n_show + 1;                  % +1 for the target pattern
n_dualclasses = length(dual_classes); % Number of dual classes
n_rows = n_classes + n_dualclasses;   % Dual classes count as two rows

% Calculate the derived plotting sizes
dx = (1 - 2*margin - (n_cols-1)*xgap - leftTextSpace - xsep) / n_cols;
dy = (1 - 2*margin - (n_classes-1)*ygap - n_dualclasses*y_inclassgap - titleSpace - bottomSpace) / n_rows;

% Define a 'fibrosis' colormap
fibroclr = [[0.95, 0.85, 0.55]; [0.8, 0.2, 0.2]];

% Initialise a new figure, fullscreen
figure('units', 'normalized', 'OuterPosition', [0 0 1 1]);

% Create a series of axes objects that will be used for plotting
row_counter = 0;
y_pos = 1 - margin - titleSpace + ygap;
for k = 1:n_classes        % rows
    
    % Set flag for if this is a dual class or not
    dual_flag = ismember(k,dual_classes);
    
    % Update row location
    y_pos = y_pos - (ygap + dy);
    row_counter = row_counter + 1;
    
    % Initialise column location
    x_pos = margin + leftTextSpace;
    
    % Create the axes for the histological images
    ax{k,1} = axes('Position', [x_pos, y_pos - dual_flag * (dy+y_inclassgap)/2 , dx, dy]);
    
    % Add the extra space between the first column and the remaining
    x_pos = x_pos + xsep;
        
    % Loop over columns to create axes
    for j = 1:n_show
        
        % Update column location
        x_pos = x_pos + xgap + dx;
        
        % Create axes object
        ax{row_counter,j+1} = axes('Position', [x_pos, y_pos, dx, dy]);
        
    end
    
    % If this is a dual class row, do another loop
    if dual_flag
        
        % Update row location with a different gap for within-class rows
        y_pos = y_pos - (y_inclassgap + dy);
        row_counter = row_counter + 1;
        
        % Update column location
        x_pos = margin + leftTextSpace + xsep;
        
        % Loop over columns to create axes
        for j = 1:n_show
            
            % Update column location
            x_pos = x_pos + xgap + dx;
            
            % Create axes object
            ax{row_counter,j+1} = axes('Position', [x_pos, y_pos, dx, dy]);
            
        end
        
    end
    
end

% Load the patterns from the histological images
load('histo_patterns.mat','patterns');

% Load the SMC-ABC particles corresponding to each
load('Results\interstitial2000_full.mat','particles'); particle_sets{1} = particles;
load('Results\compact2000_full.mat','particles'); particle_sets{2} = particles;
load('Results\compact2000_full_nofibres.mat','particles'); particle_sets{3} = particles;
load('Results\diffuse2000_full.mat','particles'); particle_sets{4} = particles;
load('Results\diffuse2000_full_nofibres.mat','particles'); particle_sets{5} = particles;
load('Results\patchy2000_full.mat','particles'); particle_sets{6} = particles;

% Read out the dimensions of the patterns
[Ny, Nx] = size(patterns{1});

% Loop over the classes of microfibrosis, plotting the original
% histological image
for k = 1:n_classes
    
    % Plot the histological section
    imagesc(ax{k,1}, patterns{k}); axis(ax{k,1}, 'equal', 'off');
    colormap(ax{k,1}, fibroclr);
    
end

% Now loop over the different classes of patterns, plotting the requested
% number of each
for k = 1:n_rows
    
    % Grab the particles
    particles = particle_sets{k};
    
    % Reduce to the set of only unique particles by using unique command
    [~, I] = unique(particles.thetas, 'rows');
    particles.vals = particles.vals(I);
    particles.Ds = particles.Ds(I);
    
    % Sort the unique particles by their discrepancies
    [particles.Ds, I] = sort(particles.Ds);
    particles.vals = particles.vals(I);
    
    % Select particles corresponding to quantiles (to give even spread of
    % discrepancy values)
    quantiles = round(linspace(1,length(particles.Ds),n_show));
    
    % Plot the patterns generated by the generator
    for j = 1:n_show
        imagesc(ax{k,j+1}, particles.vals{quantiles(j)}); axis(ax{k,j+1}, 'equal', 'off');
        colormap(ax{k,j+1}, fibroclr);
    end
    
end

% Add column titles
text(ax{1,1}, Nx/2, -Ny/5, 'Histological', 'HorizontalAlignment', 'Center', 'FontSize', 24);
text(ax{1,1+round(n_show/2)}, Nx*1.2, -Ny/5, 'Generated', 'HorizontalAlignment', 'Center', 'FontSize', 24);

% Add row titles
for k = 1:length(fibro_classes)
    text(ax{k,1}, -Nx/5, Ny/2, fibro_classes{k}, 'HorizontalAlignment', 'Right', 'VerticalAlignment', 'Middle', 'FontSize', 30);
end

% Add text on the right
fib_text = {'','(no $$\mathcal{F}$$)', '', '(no $$\mathcal{F}$$)'};
text_rows = [2, 3, 4, 5];
for k = 1:length(fib_text)
    text(ax{text_rows(k),n_show+1}, Nx * (6/5), Ny/2, fib_text{k}, 'HorizontalAlignment', 'Left', 'VerticalAlignment', 'Middle', 'FontSize', 20, 'Interpreter', 'latex');
end

% Create an arrow below the generated patterns, indicating minimum and
% maximum discrepancy
text(ax{n_rows,2}, Nx/2, Ny*8/6, {'Minimum','Discrepancy'}, 'FontSize', 16, 'HorizontalAlignment', 'center');
text(ax{n_rows,n_show+1}, Nx/2, Ny*8/6, {'Maximum','Discrepancy'}, 'FontSize', 16, 'HorizontalAlignment', 'center');
%line_obj = arrow(ax{n_rows,3}, [Nx/3 2*Nx/3+7/6*Nx*(n_show-3)],[Ny*8/6 Ny*8/6],'LineWidth',2,'Color',[0 0 0]);
%line_obj.Clipping = 'off';
annotation('textarrow',[0.465 0.635],[0.03 0.03]);


% Return to figures folder
cd Figures