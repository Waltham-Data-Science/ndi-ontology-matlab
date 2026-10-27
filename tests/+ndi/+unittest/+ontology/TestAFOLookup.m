classdef TestAFOLookup < matlab.unittest.TestCase
    % TestAFOLookup - AFO:<ID> resolves through ndi.ontology.AFO.
    %   AFO keeps each ID prefix in its own IRI namespace, so the ID-to-IRI
    %   step and the ID OLS reports are tested offline; the two terms
    %   did-schema's term registry uses are looked up in OLS, with their
    %   labels and definitions.

    methods (Test)

        function testIriForEachNamespace(testCase)
            root = 'http://purl.allotrope.org/ontologies/';
            testCase.verifyEqual(ndi.ontology.AFO.iriForId('AFR_0001158'), [root 'result#AFR_0001158']);
            testCase.verifyEqual(ndi.ontology.AFO.iriForId('AFE_0000001'), [root 'equipment#AFE_0000001']);
            testCase.verifyEqual(ndi.ontology.AFO.iriForId('AFRL_0000001'), [root 'role#AFRL_0000001']);
            testCase.verifyEqual(ndi.ontology.AFO.iriForId('AFX_0000001'), [root 'property#AFX_0000001']);
        end

        function testUnknownIdPrefixIsAnError(testCase)
            testCase.verifyError(@() ndi.ontology.AFO.iriForId('AFZZ_0000001'), ...
                'ndi:ontology:AFO:UnknownIdPrefix');
        end

        function testOlsIdsAreNormalized(testCase)
            testCase.verifyEqual(ndi.ontology.AFO.normalizeId('AFO_result#AFR:0001158'), 'AFO:AFR_0001158');
            testCase.verifyEqual(ndi.ontology.AFO.normalizeId('AFO:result#AFR_0003339'), 'AFO:AFR_0003339');
            testCase.verifyEqual(ndi.ontology.AFO.normalizeId('AFO:AFR_0001158'), 'AFO:AFR_0001158');
            testCase.verifyEqual(ndi.ontology.AFO.normalizeId('NCIT:C42636'), 'NCIT:C42636');
        end

        function testRegistryTerms(testCase)
            % The two AFO terms did-schema's term registry holds
            % (Jess Haley, 2026-10-27 [afo prefix registered]).
            ndi.ontology.clearCache();
            [id, name, prefix, def] = ndi.ontology.lookup('AFO:AFR_0001158');
            testCase.verifyEqual(id, 'AFO:AFR_0001158');
            testCase.verifyEqual(name, 'acquisition time');
            testCase.verifyEqual(prefix, 'AFO');
            testCase.verifyTrue(startsWith(def, 'The acquisition time is the time when a signal is captured.'), def);

            [id, name, ~, def] = ndi.ontology.lookup('AFO:AFR_0003339');
            testCase.verifyEqual(id, 'AFO:AFR_0003339');
            testCase.verifyEqual(name, 'cluster identifier');
            testCase.verifyTrue(startsWith(def, 'A cluster identifier is an identifier that identifies some cluster.'), def);
        end

        function testNameLookupGivesTheSameId(testCase)
            ndi.ontology.clearCache();
            id = ndi.ontology.lookup('AFO:acquisition time');
            testCase.verifyEqual(id, 'AFO:AFR_0001158');
            id = ndi.ontology.lookup('afo:AFR_0001158');
            testCase.verifyEqual(id, 'AFO:AFR_0001158');
        end

    end
end
