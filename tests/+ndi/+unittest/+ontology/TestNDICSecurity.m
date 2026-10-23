classdef TestNDICSecurity < matlab.unittest.TestCase
    % TestNDICSecurity - Regression tests for the NDIC eval-injection fix.
    %
    %   Prior to the fix, ndi.ontology.NDIC.lookupTermOrID decided whether the
    %   lookup remainder was numeric by calling str2num(), which is implemented
    %   as eval(['[' s ']']). Any user-controlled remainder was therefore
    %   executed as MATLAB code before validation (an RCE / eval sink).
    %
    %   These tests are fully offline: NDIC is a local controlled-vocabulary
    %   file, so no network access is required.

    methods (Test)

        function testNoEvalSideEffect(testCase)
            % A malicious payload embedded in an NDIC lookup string must NOT be
            % evaluated. Under the old str2num code path, str2num would eval the
            % assignin() call, creating 'ndic_canary' in the base workspace even
            % though the lookup itself ultimately reported "not found". Note that
            % verifyError alone does NOT prove safety: the payload ran first.

            % Ensure a clean slate (clear of a non-existent var is a no-op).
            evalin('base', 'clear ndic_canary');

            payload = 'NDIC:1, assignin(''base'',''ndic_canary'',1)';

            % The lookup must fail (payload is not a valid NDIC term or ID)...
            testCase.verifyError(@() ndi.ontology.lookup(payload), ?MException, ...
                'Malicious NDIC payload should raise an error, not resolve.');

            % ...and, crucially, must NOT have executed the payload.
            canaryExists = evalin('base', 'exist(''ndic_canary'',''var'')');
            testCase.verifyEqual(canaryExists, 0, ...
                'NDIC lookup evaluated user-controlled input as code (eval sink).');

            % Cleanup
            evalin('base', 'clear ndic_canary');
        end

        function testBracketArrayNotEvaluated(testCase)
            % '[1 2]' previously reached str2num and evaluated to a numeric
            % array; it must now be treated as a (non-matching) name lookup and
            % raise an error rather than being interpreted as MATLAB code.
            testCase.verifyError(@() ndi.ontology.lookup('NDIC:[1 2]'), ?MException, ...
                'NDIC:[1 2] should not be evaluated as a numeric array.');
        end

        function testCommandSeparatorNotEvaluated(testCase)
            % A statement separator in the remainder must not be executed.
            testCase.verifyError(@() ndi.ontology.lookup('NDIC:8;NDIC:2'), ?MException, ...
                'NDIC:8;NDIC:2 should not be evaluated as MATLAB statements.');
        end

    end % methods (Test)

end % classdef
