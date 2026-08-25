classdef TestPubChemParsing < matlab.unittest.TestCase
    % TestPubChemParsing - Offline regression tests for the PubChem
    %   cid-shorthand parser.
    %
    %   Previously, startsWith(input,'cid','IgnoreCase',true) captured any
    %   compound name beginning with the letters c-i-d (e.g. 'Cidofovir') and
    %   rejected it as a malformed CID, making the name-search branch
    %   unreachable. The parser now requires 'cid' + separator + digits.
    %
    %   These tests exercise ndi.ontology.PubChem.matchCidShorthand directly
    %   and need no network access.

    methods (Test)

        function testValidShorthandForms(testCase)
            testCase.verifyEqual(ndi.ontology.PubChem.matchCidShorthand('cid 2244'), '2244');
            testCase.verifyEqual(ndi.ontology.PubChem.matchCidShorthand('CID 2244'), '2244');
            testCase.verifyEqual(ndi.ontology.PubChem.matchCidShorthand('cid:2244'), '2244');
            testCase.verifyEqual(ndi.ontology.PubChem.matchCidShorthand('cid_2244'), '2244');
            testCase.verifyEqual(ndi.ontology.PubChem.matchCidShorthand('  cid 2244  '), '2244');
        end

        function testCompoundNamesAreNotShorthand(testCase)
            % Real names beginning with 'cid' must NOT be captured.
            testCase.verifyEmpty(ndi.ontology.PubChem.matchCidShorthand('Cidofovir'));
            testCase.verifyEmpty(ndi.ontology.PubChem.matchCidShorthand('Cidoxepin'));
            % 'cid' with no numeric ID is not a shorthand either.
            testCase.verifyEmpty(ndi.ontology.PubChem.matchCidShorthand('cid'));
            % A bare number is not the 'cid' shorthand (the caller handles it).
            testCase.verifyEmpty(ndi.ontology.PubChem.matchCidShorthand('2244'));
        end

    end % methods (Test)

end % classdef
