classdef TestWormBaseParsing < matlab.unittest.TestCase
    % TestWormBaseParsing - Offline tests of how a WormMine strain record
    %   becomes the WBStrain lookup outputs. The records are the ones
    %   WormMine returns for N2, MT13113 and BK6, as webread decodes them.

    methods (Test)

        function testWildType(testCase)
            s = struct('primaryIdentifier', 'WBStrain00000001', 'name', 'N2', ...
                'genotype', 'Caenorhabditis elegans wild isolate.', ...
                'otherName', [], 'mutagen', [], 'outcrossed', []);
            [id, name, definition, synonyms] = ndi.ontology.WormBase.parseStrain(s);
            testCase.verifyEqual(id, 'WBStrain:00000001');
            testCase.verifyEqual(name, 'N2');
            testCase.verifyEqual(definition, 'Genotype: Caenorhabditis elegans wild isolate.');
            testCase.verifyEqual(synonyms, {});
        end

        function testMutant(testCase)
            s = struct('primaryIdentifier', 'WBStrain00027424', 'name', 'MT13113', ...
                'genotype', 'tdc-1(n3419) II.', 'otherName', [], ...
                'mutagen', 'UV+TMP', 'outcrossed', 'x11');
            [id, name, definition] = ndi.ontology.WormBase.parseStrain(s);
            testCase.verifyEqual(id, 'WBStrain:00027424');
            testCase.verifyEqual(name, 'MT13113');
            testCase.verifyEqual(definition, ...
                'Genotype: tdc-1(n3419) II. Mutagen: UV+TMP. Outcrossed: x11.');
        end

        function testOtherNameIsASynonym(testCase)
            s = struct('primaryIdentifier', 'WBStrain00003818', 'name', 'BK6', ...
                'genotype', [], 'otherName', 'BK006', 'mutagen', [], 'outcrossed', []);
            [~, ~, definition, synonyms] = ndi.ontology.WormBase.parseStrain(s);
            testCase.verifyEqual(definition, '');
            testCase.verifyEqual(synonyms, {'BK006'});
        end

        function testRecordWithoutAnIdIsAnError(testCase)
            s = struct('primaryIdentifier', [], 'name', 'N2');
            testCase.verifyError(@() ndi.ontology.WormBase.parseStrain(s), ...
                'ndi:ontology:WormBase:APIParsingFailed');
        end

    end % methods (Test)

end % classdef
