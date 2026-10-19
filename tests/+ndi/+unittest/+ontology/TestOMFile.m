classdef TestOMFile < matlab.unittest.TestCase
%TESTOMFILE How ndi.ontology.OM reads OM's own file, offline.
%
%   OM's units are individuals (`om:metre` is an om:Unit), which the EBI OLS
%   index does not hold, so ndi.ontology.OM finds them in OM's RDF/XML file.
%   These tests parse a small excerpt written in the file's own layout, so
%   they need no network; the lookups through the real file are in
%   ontology_lookup_tests.json (OM:metre, OM:second, ...).

    properties (Constant)
        Excerpt = strjoin({ ...
            '<?xml version="1.0"?>'
            '<rdf:RDF>'
            '  <om:Unit rdf:about="&om;metre">'
            '    <rdfs:label xml:lang="en">metre</rdfs:label>'
            '    <rdfs:label xml:lang="nl">meter</rdfs:label>'
            '    <om:alternativeLabel xml:lang="en">meter</om:alternativeLabel>'
            '    <om:symbol>m</om:symbol>'
            '  </om:Unit>'
            ''
            '  <om:Unit rdf:about="&om;metre">'
            '    <rdfs:comment xml:lang="en">The metre is a unit of length.</rdfs:comment>'
            '  </om:Unit>'
            ''
            '  <om:UnitDivision rdf:about="&om;metrePerSecond-Time">'
            '    <rdfs:label xml:lang="en">metre per second</rdfs:label>'
            '    <om:hasNumerator rdf:resource="&om;metre"/>'
            '  </om:UnitDivision>'
            ''
            '  <owl:Class rdf:about="&om;PixelCountUnit">'
            '    <rdfs:label xml:lang="en">pixel count unit</rdfs:label>'
            '    <owl:equivalentClass>'
            '      <owl:Class>'
            '        <owl:oneOf rdf:parseType="Collection">'
            '          <om:SingularUnit rdf:about="&om;pixel"/>'
            '        </owl:oneOf>'
            '      </owl:Class>'
            '    </owl:equivalentClass>'
            '  </owl:Class>'
            ''
            '  <owl:Class rdf:about="&om;Magnitude">'
            '    <rdfs:label xml:lang="en">magnitude</rdfs:label>'
            '  </owl:Class>'
            '  <om:Unit rdf:about="&om;magnitude">'
            '    <rdfs:label xml:lang="en">magnitude</rdfs:label>'
            '  </om:Unit>'
            '</rdf:RDF>'}', newline)
    end

    methods (Test)
        function testBlocksOfOneIdentifierAreMerged(testCase)
            idx = ndi.ontology.OM.parseRDF(testCase.Excerpt);
            testCase.verifyEqual(sort(idx.local), ...
                sort({'metre', 'metrePerSecond-Time', 'PixelCountUnit', 'Magnitude', 'magnitude'}), ...
                'one entry per top-level identifier; a nested reference is not an entry');
            k = find(strcmp(idx.local, 'metre'));
            testCase.verifyEqual(idx.label{k}, 'metre', 'the English label, not the Dutch');
            testCase.verifyEqual(idx.definition{k}, 'The metre is a unit of length.', ...
                'the comment, from the second block');
            testCase.verifyEqual(idx.alternative{k}, {'meter'});
            testCase.verifyEqual(idx.kind{k}, 'om:Unit');
        end

        function testMatchingRules(testCase)
            idx = ndi.ontology.OM.parseRDF(testCase.Excerpt);
            name = @(t) idx.local{ndi.ontology.OM.findInIndex(idx, t)};
            testCase.verifyEqual(name('metre'), 'metre', 'identifier');
            testCase.verifyEqual(name('Metre'), 'metre', 'identifier, ignoring case');
            testCase.verifyEqual(name('meter'), 'metre', 'alternative label');
            testCase.verifyEqual(name('metre per second'), 'metrePerSecond-Time', 'label');
            testCase.verifyEqual(name('MetrePerSecond'), 'metrePerSecond-Time', 'camel-case heuristic');
            testCase.verifyEqual(name('Magnitude'), 'Magnitude', ...
                'an exact identifier wins over one differing only in case');
            testCase.verifyEqual(name('magnitude'), 'magnitude');
            testCase.verifyEmpty(ndi.ontology.OM.findInIndex(idx, 'MAGNITUDE'), ...
                'two entries match ignoring case, and two labels: no single answer');
            testCase.verifyEmpty(ndi.ontology.OM.findInIndex(idx, 'pixel'), ...
                'pixel is only referenced here, never defined');
            testCase.verifyEmpty(ndi.ontology.OM.findInIndex(idx, 'NoSuchUnit'));
        end
    end
end
