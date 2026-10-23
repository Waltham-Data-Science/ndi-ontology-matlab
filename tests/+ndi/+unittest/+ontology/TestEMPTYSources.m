classdef TestEMPTYSources < matlab.unittest.TestCase
    % TestEMPTYSources - Offline tests of the order in which EMPTY lookups
    %   read their OWL files: main, then the V2 branch (its edit file and
    %   its empty-base.owl), then development. empty-ontology PR #22 merges
    %   into V2 (Jess Haley, 2026-10-21), so a term minted for the NDI V2
    %   work is on V2 before it is on main, and must still resolve.

    properties (Constant)
        MainBody = [ ...
            'Ontology(<http://purl.obolibrary.org/obo/empty.owl>' newline ...
            'AnnotationAssertion(rdfs:label obo:EMPTY_0000002 "Behavioral measurement"@en)' newline ...
            ')'];
        V2Body = [ ...
            'Ontology(<http://purl.obolibrary.org/obo/empty.owl>' newline ...
            'AnnotationAssertion(rdfs:label obo:EMPTY_0000002 "Behavioral measurement"@en)' newline ...
            '# Class: obo:EMPTY_0000359 (ethics jurisdiction)' newline ...
            'AnnotationAssertion(obo:IAO_0000115 obo:EMPTY_0000359 "The jurisdiction under which the ethics assessment was conducted.")' newline ...
            'AnnotationAssertion(rdfs:label obo:EMPTY_0000359 "ethics jurisdiction"@en)' newline ...
            ')'];
    end

    methods (Test)

        function testTheV2BranchIsASource(testCase)
            urls = ndi.ontology.EMPTY.sourceUrls();
            testCase.verifyEqual(urls{1}, ndi.ontology.EMPTY.OWL_URL_MAIN, 'main is read first');
            testCase.verifyTrue(any(contains(urls, '/empty-ontology/V2/src/ontology/empty-edit.owl')));
            testCase.verifyTrue(any(contains(urls, '/empty-ontology/V2/empty-base.owl')));
            testCase.verifyTrue(any(contains(urls, '/empty-ontology/development/')));
        end

        function testAV2OnlyTermResolves(testCase)
            [id, name, definition] = ndi.ontology.EMPTY().lookupFromSources( ...
                ndi.ontology.EMPTY.sourceUrls(), '0000359', @(u) testCase.serve(u));
            testCase.verifyEqual(id, 'EMPTY:0000359');
            testCase.verifyEqual(name, 'ethics jurisdiction');
            testCase.verifyEqual(definition, ...
                'The jurisdiction under which the ethics assessment was conducted.');
            [id, name] = ndi.ontology.EMPTY().lookupFromSources( ...
                ndi.ontology.EMPTY.sourceUrls(), 'ethics jurisdiction', @(u) testCase.serve(u));
            testCase.verifyEqual(id, 'EMPTY:0000359');
            testCase.verifyEqual(name, 'ethics jurisdiction');
        end

        function testMainAnswersFirst(testCase)
            [id, name] = ndi.ontology.EMPTY().lookupFromSources( ...
                ndi.ontology.EMPTY.sourceUrls(), '0000002', @(u) testCase.serve(u));
            testCase.verifyEqual(id, 'EMPTY:0000002');
            testCase.verifyEqual(name, 'Behavioral measurement');
        end

        function testATermNowhereFails(testCase)
            testCase.verifyError(@() ndi.ontology.EMPTY().lookupFromSources( ...
                ndi.ontology.EMPTY.sourceUrls(), '9999999', @(u) testCase.serve(u)), ...
                'ndi:ontology:EMPTY:LookupFailed');
        end

    end % methods (Test)

    methods
        function body = serve(testCase, url)
            % main and both V2 files exist; development does not (404)
            if contains(url, '/main/')
                body = testCase.MainBody;
            elseif contains(url, '/V2/')
                body = testCase.V2Body;
            else
                error('test:http', 'The server returned the status 404 with message "Not Found".');
            end
        end
    end

end % classdef
