% Location: +ndi/+ontology/OWLTime.m
classdef OWLTime < ndi.ontology
% OWLTIME - NDI Ontology object for the interval relations of OWL-Time.
%   The relations between two proper intervals in OWL-Time, the W3C Time
%   Ontology (https://www.w3.org/TR/owl-time/): Allen's thirteen relations
%   (time:intervalBefore ... time:intervalEquals) and OWL-Time's two unions of
%   them, time:intervalIn and time:intervalDisjoint. A term is identified as
%   OWL-Time names it, time:<localName>, which resolves to
%   http://www.w3.org/2006/time#<localName>.
%
%   OWL-Time is not on OLS (it is a W3C vocabulary, not an OBO ontology), and
%   the relations are a fixed list, so the names and definitions are held
%   here, taken from the OWL-Time file at http://www.w3.org/2006/time (its
%   rdfs:label and skos:definition, read 2026-10-20).

    properties (Constant)
        % local name, label, definition (skos:definition in the OWL-Time file)
        RELATIONS = { ...
                'intervalBefore', 'interval before', 'If a proper interval T1 is intervalBefore another proper interval T2, then the end of T1 is before the beginning of T2.';
                'intervalAfter', 'interval after', 'If a proper interval T1 is intervalAfter another proper interval T2, then the beginning of T1 is after the end of T2.';
                'intervalMeets', 'interval meets', 'If a proper interval T1 is intervalMeets another proper interval T2, then the end of T1 is coincident with the beginning of T2.';
                'intervalMetBy', 'interval met by', 'If a proper interval T1 is intervalMetBy another proper interval T2, then the beginning of T1 is coincident with the end of T2.';
                'intervalOverlaps', 'interval overlaps', 'If a proper interval T1 is intervalOverlaps another proper interval T2, then the beginning of T1 is before the beginning of T2, the end of T1 is after the beginning of T2, and the end of T1 is before the end of T2.';
                'intervalOverlappedBy', 'interval overlapped by', 'If a proper interval T1 is intervalOverlappedBy another proper interval T2, then the beginning of T1 is after the beginning of T2, the beginning of T1 is before the end of T2, and the end of T1 is after the end of T2.';
                'intervalStarts', 'interval starts', 'If a proper interval T1 is intervalStarts another proper interval T2, then the beginning of T1 is coincident with the beginning of T2, and the end of T1 is before the end of T2.';
                'intervalStartedBy', 'interval started by', 'If a proper interval T1 is intervalStarted another proper interval T2, then the beginning of T1 is coincident with the beginning of T2, and the end of T1 is after the end of T2.';
                'intervalDuring', 'interval during', 'If a proper interval T1 is intervalDuring another proper interval T2, then the beginning of T1 is after the beginning of T2, and the end of T1 is before the end of T2.';
                'intervalContains', 'interval contains', 'If a proper interval T1 is intervalContains another proper interval T2, then the beginning of T1 is before the beginning of T2, and the end of T1 is after the end of T2.';
                'intervalFinishes', 'interval finishes', 'If a proper interval T1 is intervalFinishes another proper interval T2, then the beginning of T1 is after the beginning of T2, and the end of T1 is coincident with the end of T2.';
                'intervalFinishedBy', 'interval finished by', 'If a proper interval T1 is intervalFinishedBy another proper interval T2, then the beginning of T1 is before the beginning of T2, and the end of T1 is coincident with the end of T2.';
                'intervalEquals', 'interval equals', 'If a proper interval T1 is intervalEquals another proper interval T2, then the beginning of T1 is coincident with the beginning of T2, and the end of T1 is coincident with the end of T2.';
                'intervalIn', 'interval in', 'If a proper interval T1 is intervalIn another proper interval T2, then the beginning of T1 is after the beginning of T2 or is coincident with the beginning of T2, and the end of T1 is before the end of T2, or is coincident with the end of T2, except that end of T1 may not be coincident with the end of T2 if the beginning of T1 is coincident with the beginning of T2.';
                'intervalDisjoint', 'interval disjoint', 'If a proper interval T1 is intervalDisjoint another proper interval T2, then the beginning of T1 is after the end of T2, or the end of T1 is before the beginning of T2, i.e. the intervals do not overlap in any way, but their ordering relationship is not known.'};
    end

    methods
        function obj = OWLTime()
            % OWLTIME - Constructor for the OWLTime ontology object.
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up an OWL-Time interval relation by local name or label.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM)
            %
            %   TERM is the part after the 'time:' prefix: the local name
            %   ('intervalDuring') or the label ('interval during'), in any
            %   case, with or without spaces. ID is always 'time:<localName>';
            %   NAME is OWL-Time's label; SYNONYMS holds the term's IRI.
            arguments
                obj (1,1) ndi.ontology.OWLTime %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end
            k = ndi.ontology.OWLTime.find(term_or_id_or_name);
            if isempty(k)
                error('ndi:ontology:OWLTime:LookupFailed', ...
                    'OWL-Time lookup failed: "%s" is not one of OWL-Time''s interval relations.', ...
                    char(term_or_id_or_name));
            end
            R = ndi.ontology.OWLTime.RELATIONS;
            id = ['time:' R{k, 1}];
            name = R{k, 2};
            definition = R{k, 3};
            synonyms = {['http://www.w3.org/2006/time#' R{k, 1}]};
        end % function lookupTermOrID
    end % methods

    methods (Static)
        function k = find(term)
            % FIND - The row of RELATIONS that TERM names, or [] if none.
            %   Case, spaces and underscores do not distinguish one relation
            %   from another, so 'intervalDuring', 'interval during' and
            %   'INTERVAL_DURING' are the same relation.
            arguments
                term {mustBeText}
            end
            R = ndi.ontology.OWLTime.RELATIONS;
            key = regexprep(lower(strtrim(char(term))), '[\s_]+', '');
            k = [];
            if isempty(key), return; end
            for r = 1:size(R, 1)
                if strcmp(key, lower(R{r, 1}))
                    k = r;
                    return;
                end
            end
        end
    end % methods (Static)

end % classdef OWLTime
