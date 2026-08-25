classdef TestNCBITaxonParsing < matlab.unittest.TestCase
    % TestNCBITaxonParsing - Offline regression tests for the NCBITaxon
    %   esearch <IdList> parser.
    %
    %   The previous single greedy regex
    %   '<IdList>.*?<Id>(\d+)</Id>.*?</IdList>' consumed the entire IdList in
    %   one match, so it always reported exactly one TaxID no matter how many
    %   <Id> elements were returned. The NameNotUnique guard was therefore
    %   dead code and an ambiguous genus silently resolved to the first
    %   species. These tests exercise ndi.ontology.NCBITaxon.parseTaxIdList
    %   directly against literal XML and need no network access.

    methods (Test)

        function testMultipleIdsAreAllCounted(testCase)
            xml = ['<eSearchResult><IdList>' ...
                   '<Id>10090</Id><Id>862507</Id><Id>1385377</Id>' ...
                   '</IdList></eSearchResult>'];
            ids = ndi.ontology.NCBITaxon.parseTaxIdList(xml);
            testCase.verifyEqual(numel(ids), 3, ...
                'All three <Id> elements must be counted (multi-match guard reachable).');
            testCase.verifyEqual(ids, {'10090', '862507', '1385377'});
        end

        function testSingleId(testCase)
            xml = '<IdList><Id>9606</Id></IdList>';
            ids = ndi.ontology.NCBITaxon.parseTaxIdList(xml);
            testCase.verifyEqual(ids, {'9606'});
        end

        function testEmptyIdList(testCase)
            testCase.verifyEmpty(ndi.ontology.NCBITaxon.parseTaxIdList('<IdList></IdList>'));
            testCase.verifyEmpty(ndi.ontology.NCBITaxon.parseTaxIdList('<eSearchResult><Count>0</Count></eSearchResult>'));
        end

    end % methods (Test)

end % classdef
