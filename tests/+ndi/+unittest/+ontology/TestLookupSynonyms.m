classdef TestLookupSynonyms < matlab.unittest.TestCase
    % TestLookupSynonyms - The synonyms ndi.ontology.lookup returns, from
    %   the live services. Requires an active internet connection.

    methods (Test)

        function testCElegansFormerGenus(testCase)
            ndi.ontology.clearCache();
            [~, name, ~, ~, synonyms] = ndi.ontology.lookup('NCBITaxon:6239');
            testCase.verifyEqual(name, 'Caenorhabditis elegans');
            testCase.verifyTrue(any(strcmp(synonyms, 'Rhabditis elegans')), ...
                'NCBI lists Rhabditis elegans as a synonym of C. elegans.');
            testCase.verifyFalse(any(contains(synonyms, 'Maupas')), ...
                'Authority citations are not synonyms.');
        end

        function testMouseCommonNames(testCase)
            ndi.ontology.clearCache();
            [~, ~, ~, ~, synonyms] = ndi.ontology.lookup('NCBITaxon:10090');
            testCase.verifyTrue(all(ismember({'house mouse', 'mouse'}, synonyms)), ...
                'NCBI lists "house mouse" (GenBank) and "mouse" for Mus musculus.');
        end

        function testStrainDefinition(testCase)
            ndi.ontology.clearCache();
            [~, name, ~, definition] = ndi.ontology.lookup('WBStrain:MT13113');
            testCase.verifyEqual(name, 'MT13113');
            testCase.verifyTrue(contains(definition, 'tdc-1(n3419)'), ...
                'The definition carries the strain genotype.');
        end

    end % methods (Test)

end % classdef
