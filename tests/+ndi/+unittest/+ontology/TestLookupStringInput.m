classdef TestLookupStringInput < matlab.unittest.TestCase
    % TestLookupStringInput - ndi.ontology.lookup takes a string scalar as
    %   well as a character vector. A string used to fail with "Index
    %   exceeds..." where the prefix is cut from the input. NDIC is read
    %   from a file shipped with the toolbox, so no network is needed.

    methods (Test)

        function testStringGivesTheSameResultAsChar(testCase)
            ndi.ontology.clearCache();
            [id, name, prefix] = ndi.ontology.lookup("NDIC:8");
            [idChar, nameChar, prefixChar] = ndi.ontology.lookup('NDIC:8');
            testCase.verifyEqual(id, idChar);
            testCase.verifyEqual(name, nameChar);
            testCase.verifyEqual(prefix, 'NDIC');
            testCase.verifyEqual(prefixChar, 'NDIC');
        end

    end % methods (Test)

end % classdef
