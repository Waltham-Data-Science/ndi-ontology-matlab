classdef TestPreprocessRouting < matlab.unittest.TestCase
    % TestPreprocessRouting - Offline tests for the shared
    %   ndi.ontology.preprocessLookupInput id-vs-label routing.
    %
    %   Guards the NCIT routing fix: a numeric ID and an ontology "code"
    %   (letters+digits, e.g. NCIT's 'C9523') must route to an obo_id
    %   (prefixed) search, while a plain word label must route to a label
    %   search. This helper is shared by every OLS subclass, so this test
    %   exercises the routing without any network access.

    methods (Test)

        function testNumericIdRoutesToOboId(testCase)
            [q, f] = ndi.ontology.preprocessLookupInput('12345', 'NCIT');
            testCase.verifyEqual(q, 'NCIT:12345');
            testCase.verifyEqual(f, 'obo_id');
        end

        function testCodeRoutesToOboId(testCase)
            [q, f] = ndi.ontology.preprocessLookupInput('C9523', 'NCIT');
            testCase.verifyEqual(q, 'NCIT:C9523');
            testCase.verifyEqual(f, 'obo_id');
        end

        function testLabelRoutesToLabel(testCase)
            [q, f] = ndi.ontology.preprocessLookupInput('Neoplasm', 'NCIT');
            testCase.verifyEqual(q, 'Neoplasm');
            testCase.verifyEqual(f, 'label');
        end

        function testPlainWordLabelsUnaffected(testCase)
            % Regression: existing single-word labels must still be labels.
            [~, f1] = ndi.ontology.preprocessLookupInput('cell', 'CL');
            testCase.verifyEqual(f1, 'label');
            [~, f2] = ndi.ontology.preprocessLookupInput('NoSuchItem', 'CL');
            testCase.verifyEqual(f2, 'label');
            % Hyphenated labels are not codes.
            [~, f3] = ndi.ontology.preprocessLookupInput('p-value', 'STATO');
            testCase.verifyEqual(f3, 'label');
        end

        function testPrefixedCodeRoutesToOboId(testCase)
            [q, f] = ndi.ontology.preprocessLookupInput('NCIT:C9523', 'NCIT');
            testCase.verifyEqual(q, 'NCIT:C9523');
            testCase.verifyEqual(f, 'obo_id');
        end

    end % methods (Test)

end % classdef
