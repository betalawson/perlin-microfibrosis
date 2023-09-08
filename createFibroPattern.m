function [presence, O_b, O_d, F] = createFibroPattern(mesh, density, params, Ps, offsets)
% This function takes an input mesh of points and generates a binary
% pattern of presence/absence of collagen at those points, in effect
% forming an image.
%
% Usage:    presence = CreateFibroPattern(mesh, density, params, Ps, offsets)
%
% INPUTS:   mesh:      a mesh object (use createMesh.m to create)
%           density:   the proportion of points to be occupied by fibrosis
%           params:    a set of parameters defining the properties of the noise pattern (see below)
%           Ps:        an m x n matrix, which is m rows of the numbers 0:n-1 arranged in random order (permutation tables for random assignment of vectors in Perlin noise)
%           offsets:   an m x 2 matrix that specifies grid offsets for each octave in octave noise
%
%           * m is the maximum number of octaves that will be requested by
%             this function, and n is the number of Perlin vectors - here
%             256 vectors are used
%           * inputs "Ps" and "offsets" can be generated using function 
%             generateSeeddata.m
%
% OUTPUTS:  presence:   a presence/absence map of fibrosis
%           (O_b):      the Perlin noise field for fibrosis (optional)
%           (O_d):      the Perlin noise field for density variation (optional)
%           (F):        the sinusoidal field used for fibre-type patterns (optional)
%
% PARAMS:   Parameters are provided as a single vector, specified as:
%           [ fibreness, fibre_separation, patchiness, feature_size, roughness, patch_size, alignment_ratio, direction ]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% INITIAL SETUP

% Read out paramaters from vector
params = num2cell(params);
[fibreness, fibre_sep, patchiness, feature_size, roughness, patch_size, fibre_alignment, direction] = deal(params{:});

% Create a rotated set of points for the application of anisotropy and
% creation of fibre-aligned pattern. Stored as two rows for ease of matrix
% transforms and input into C++ functions
R_points = [ [ cos(direction) sin(direction) ]; [-sin(direction), cos(direction)] ] * mesh.points';

% Create new permutation tables from the provided by applying it to itself,
% and then again
for k = 1:size(Ps,1)
    Ps2(k,:) = Ps(k,Ps(k,:)+1);
    Ps3(k,:) = Ps(k,Ps2(k,:)+1);
end


%%% FIBRE-SELECTING FIELD

% Define parameters for the phase field (decided via experimentation)
n_fibres_similarity = 4;
wiggle_feature_length = 4;
phasefield_strength = 5;

% Create an octave noise field with these properties (first transform
% points, then call Octave2D)
phasefield_points = [ R_points(1,:) / wiggle_feature_length; R_points(2,:) / (n_fibres_similarity * fibre_sep) ];      % Scale dimensions according to anisotropy (multiplication by "D" in paper)
phasefield = Octave2D(phasefield_points, 4, 0.5, Ps, offsets);    % (4 octaves, low roughness for phasefield)
% Create the sinusoidal pattern using cos(RX^T [0; 1] ), then modulate phase using
% the created phasefield
F = 0.5 + 0.5 * cos(2*pi * (R_points(2,:) / fibre_sep + phasefield_strength * (phasefield - 0.5) ) );

% Sharpen this field by powering it up many times (hard-coded for
% efficiency, but can be easily modified if a different 'sharpening factor'
% is desired). 
F = F .* F .* F .* F .* F .* F .* F .* F .* F .* F .* F .* F .* F .* F .* F;


%%% MAIN FIBROSIS PATTERNING FIELD

% Transform points according to input parameters, then call Octave2D
P_f_points = [ R_points(1,:) / sqrt(fibre_alignment); R_points(2,:) * sqrt(fibre_alignment) ];
O_b = Octave2D( P_f_points / feature_size, 4, roughness, Ps2, offsets);


%%% LARGE-SCALE DENSITY VARIATION

% Use Octave2D with scaling of point co-ords to attain desired patch_size
O_d = Octave2D(mesh.points' / patch_size, 4, 0.5, Ps3, offsets);


%%% FIBROSIS PATTERN CREATION

% Final noisefield is the weighted combination of the component fields
noise = ( 1 - fibreness + fibreness * F ) .* O_b + patchiness * O_d;

% Convert the final noisefield into a binary pattern
presence = thresholdPattern(noise, density);

% Shift from a list of points back into a matrix
presence = reshape(presence', mesh.Nx, mesh.Ny)';
F = reshape(F', mesh.Nx, mesh.Ny)';
O_b = reshape(O_b', mesh.Nx, mesh.Ny)';
O_d = reshape(O_d', mesh.Nx, mesh.Ny)';

% Convert matrices into "image" matrices
presence = flipud(presence);
F = flipud(F);
O_b = flipud(O_b);
O_d = flipud(O_d);

end

