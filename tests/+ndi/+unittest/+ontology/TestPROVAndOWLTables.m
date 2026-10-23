classdef TestPROVAndOWLTables < matlab.unittest.TestCase
    % TestPROVAndOWLTables - The prov: and owl: prefixes resolve from tables
    %   held in ndi.ontology.PROV and ndi.ontology.OWL, so no network is
    %   needed. Every row of each table resolves through ndi.ontology.lookup
    %   to <prefix>:<localName>, with the term's IRI as its synonym.

    properties (TestParameter)
        vocabulary = struct( ...
            'PROV', struct('prefix', 'prov', 'className', 'ndi.ontology.PROV', ...
                'namespace', 'http://www.w3.org/ns/prov#'), ...
            'OWL', struct('prefix', 'owl', 'className', 'ndi.ontology.OWL', ...
                'namespace', 'http://www.w3.org/2002/07/owl#'))
    end

    methods (Test)

        function testEveryRowResolves(testCase, vocabulary)
            ndi.ontology.clearCache();
            vocabularyObj = feval(vocabulary.className);
            T = vocabularyObj.TERMS;
            testCase.verifyGreaterThan(size(T, 1), 0);
            for r = 1:size(T, 1)
                [id, name, prefix, definition, synonyms] = ...
                    ndi.ontology.lookup([vocabulary.prefix ':' T{r, 1}]);
                testCase.verifyEqual(id, [vocabulary.prefix ':' T{r, 1}]);
                testCase.verifyEqual(name, T{r, 1});
                testCase.verifyEqual(prefix, vocabulary.prefix);
                testCase.verifyNotEmpty(definition);
                testCase.verifyEqual(synonyms, {[vocabulary.namespace T{r, 1}]});
            end
        end

        function testCaseAndSpacesDoNotMatter(testCase)
            ndi.ontology.clearCache();
            for s = {'prov:wasDerivedFrom', 'prov:was derived from', 'PROV:WAS_DERIVED_FROM'}
                id = ndi.ontology.lookup(s{1});
                testCase.verifyEqual(id, 'prov:wasDerivedFrom');
            end
            for s = {'owl:sameAs', 'owl:same as', 'OWL:SAME_AS'}
                id = ndi.ontology.lookup(s{1});
                testCase.verifyEqual(id, 'owl:sameAs');
            end
        end

        function testRegistryDefinitions(testCase)
            % The definitions did-schema's term registry records for the two
            % terms it uses.
            ndi.ontology.clearCache();
            [~, ~, ~, def] = ndi.ontology.lookup('prov:wasDerivedFrom');
            testCase.verifyEqual(def, ['A derivation is a transformation of an entity into another, ' ...
                'an update of an entity resulting in a new one, or the construction of a new entity ' ...
                'based on a pre-existing entity.']);
            [~, ~, ~, def] = ndi.ontology.lookup('owl:sameAs');
            testCase.verifyEqual(def, 'The property that determines that two given individuals are equal.');
        end

        function testUnknownTermIsAnError(testCase)
            ndi.ontology.clearCache();
            testCase.verifyError(@() ndi.ontology.lookup('prov:NoSuchProvTerm'), ...
                'ndi:ontology:lookup:SpecificLookupError');
            testCase.verifyError(@() ndi.ontology.lookup('owl:NoSuchOwlTerm'), ...
                'ndi:ontology:lookup:SpecificLookupError');
        end

    end % methods (Test)

end % classdef
