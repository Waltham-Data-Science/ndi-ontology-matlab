classdef TestWBStrainSecurity < matlab.unittest.TestCase
    % TestWBStrainSecurity - Offline regression guard for the WBStrain
    %   plaintext-HTTP fix.
    %
    %   WBStrain.m previously fetched strain metadata (name, genotype,
    %   synonyms -- values written verbatim into NDI subject documents) over
    %   plaintext http://rest.wormbase.org. This guard reads the source of
    %   WBStrain.m and asserts the WormBase REST endpoint is fetched over
    %   https and that no plaintext-http WormBase URL remains. It is fully
    %   offline (it inspects source text, it does not make network calls).

    methods (Test)

        function testWormbaseEndpointUsesHttps(testCase)
            src = ndi.unittest.ontology.TestWBStrainSecurity.readWBStrainSource();

            testCase.verifyTrue(contains(src, 'https://rest.wormbase.org'), ...
                'WBStrain must fetch strain metadata from rest.wormbase.org over https.');

            testCase.verifyFalse(contains(src, 'http://rest.wormbase.org'), ...
                'WBStrain must not fetch strain metadata over plaintext http.');
        end

    end % methods (Test)

    methods (Static)
        function src = readWBStrainSource()
            % Locate WBStrain.m relative to this test file.
            here = fileparts(mfilename('fullpath'));
            candidate = fullfile(here, '..', '..', '..', '..', 'src', 'ndi', ...
                '+ndi', '+ontology', 'WBStrain.m');
            if ~isfile(candidate)
                % Fall back to the class location on the MATLAB path.
                candidate = which('ndi.ontology.WBStrain');
            end
            assert(isfile(candidate), ...
                'Could not locate WBStrain.m for source inspection.');
            src = fileread(candidate);
        end
    end % methods (Static)

end % classdef
