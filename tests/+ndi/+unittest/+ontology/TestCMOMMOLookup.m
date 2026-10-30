classdef TestCMOMMOLookup < matlab.unittest.TestCase
    % TestCMOMMOLookup - CMO:<ID> and MMO:<ID> resolve through
    %   ndi.ontology.CMO and ndi.ontology.MMO (both served by OLS4, OBO
    %   PURL IRIs). The terms did-schema's term registry writes for the
    %   assay labels (Jess Haley, 2026-10-30 [assay labels batch 6]) are
    %   looked up in OLS, with their labels and definitions.

    methods (Test)

        function testCMORegistryTerms(testCase)
            ndi.ontology.clearCache();
            expected = { ...
                'CMO:0001043', 'amount of time spent in voluntary immobility'; ...
                'CMO:0001044', 'percent of time spent in voluntary immobility'; ...
                'CMO:0001519', 'acoustic startle response measurement'; ...
                'CMO:0002046', 'calculated acoustic startle response measurement'};
            for k = 1:size(expected, 1)
                [id, name, prefix, def] = ndi.ontology.lookup(expected{k,1});
                testCase.verifyEqual(id, expected{k,1});
                testCase.verifyEqual(name, expected{k,2});
                testCase.verifyEqual(prefix, 'CMO');
                testCase.verifyNotEmpty(def, expected{k,1});
            end
        end

        function testMMORegistryTerm(testCase)
            ndi.ontology.clearCache();
            [id, name, prefix, def] = ndi.ontology.lookup('MMO:0000572');
            testCase.verifyEqual(id, 'MMO:0000572');
            testCase.verifyEqual(name, 'contextual fear conditioning test');
            testCase.verifyEqual(prefix, 'MMO');
            testCase.verifyTrue(startsWith(def, 'A test in which an aversive stimulus is administered'), def);
        end

        function testNameLookupGivesTheSameId(testCase)
            ndi.ontology.clearCache();
            id = ndi.ontology.lookup('CMO:percent of time spent in voluntary immobility');
            testCase.verifyEqual(id, 'CMO:0001044');
            id = ndi.ontology.lookup('MMO:contextual fear conditioning test');
            testCase.verifyEqual(id, 'MMO:0000572');
        end

        function testUnknownTermsFail(testCase)
            ndi.ontology.clearCache();
            testCase.verifyError(@() ndi.ontology.lookup('CMO:NoSuchMeasurement'), ?MException);
            testCase.verifyError(@() ndi.ontology.lookup('MMO:NoSuchMethod'), ?MException);
        end

    end
end
