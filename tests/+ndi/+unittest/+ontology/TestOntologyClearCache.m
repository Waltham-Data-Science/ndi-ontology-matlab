classdef TestOntologyClearCache < matlab.unittest.TestCase
    % TestOntologyClearCache - Offline test that ndi.ontology.clearCache
    %   actually flushes the NDIC persistent cache.
    %
    %   Previously clearCache tried to clear 'ndi.ontology.lookup_NDIC' (which
    %   does not exist) and printed "not found on path, skipping clear.", while
    %   the real NDIC/IAO/EDAM caches survived. This test uses NDIC (a local
    %   file, no network) and observes the "Loading NDIC ontology from file..."
    %   message that getNDICData prints only when it re-reads from disk.

    methods (Test)

        function testNDICReloadsAfterClear(testCase)
            % Prime the NDIC cache (and the central lookup cache).
            ndi.ontology.lookup('NDIC:8');

            % Clear all caches. The output must NOT mention a missing function.
            clearOut = evalc('ndi.ontology.clearCache()');
            testCase.verifyEmpty(regexp(clearOut, 'not found on path', 'once'), ...
                'clearCache must not reference a nonexistent lookup_NDIC function.');

            % After clearing, the next NDIC lookup must re-read NDIC.txt.
            reloadOut = evalc('ndi.ontology.lookup(''NDIC:8'')');
            testCase.verifyNotEmpty(regexp(reloadOut, 'Loading NDIC ontology from file', 'once'), ...
                'NDIC data should be re-read from disk after clearCache (cache was not cleared).');
        end

    end % methods (Test)

end % classdef
