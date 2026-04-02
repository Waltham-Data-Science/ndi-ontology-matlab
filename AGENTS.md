# Instructions for AI Agents

## Overview
This document establishes guidelines for AI agents working with a MATLAB-based repository. The key directives address the primary language, environment requirements, and appropriate workflows based on available resources.

## Primary Language
The project is developed in **MATLAB** using `.m` file extensions. The guidelines recommend using "the Matlab arguments block for validation and to help the user use tab-completion for inputs." New code should follow camelCase naming conventions, while existing variables should be preserved for backward compatibility.

## Environment Requirements
The document emphasizes that "All execution, testing, and validation of the code in this repository **require a licensed installation of MATLAB**." It explicitly prohibits attempting to run code in alternative environments like GNU Octave, Python, or other MATLAB-like interpreters, warning that "Compatibility with other environments is not guaranteed, and attempting to run the code outside of a proper MATLAB environment may produce incorrect results or errors."

## Workflow Protocol
The instructions are conditional:

**With MATLAB Access:** Agents may analyze, modify, and run tests directly, ensuring all tests pass before committing changes.

**Without MATLAB Access:** Agents must abstain from executing or testing MATLAB files, restricting their role to static analysis and code generation. Changes should be packaged into new branches or pull requests with clear descriptions for human review and testing.
