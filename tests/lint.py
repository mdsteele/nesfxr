#=============================================================================#
# Copyright 2022 Matthew D. Steele <mdsteele@alum.mit.edu>                    #
#                                                                             #
# This file is part of Annalog.                                               #
#                                                                             #
# Annalog is free software: you can redistribute it and/or modify it under    #
# the terms of the GNU General Public License as published by the Free        #
# Software Foundation, either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# Annalog is distributed in the hope that it will be useful, but WITHOUT ANY  #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more      #
# details.                                                                    #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with Annalog.  If not, see <http://www.gnu.org/licenses/>.                  #
#=============================================================================#

from __future__ import print_function

import os
import re
import sys

#=============================================================================#

BAD_CODE_PATTERNS = [
    ('incorrect ZP export', re.compile(r'\.EXPORT +Zp')),
    ('incorrect ZP import', re.compile(r'\.IMPORT +Zp')),
    # This pattern matches instructions using indirect addressing on e.g. T0
    # instead of T1T0.
    ('one-byte T register as address', re.compile(
        r'^ *(ad[cd]|and|cmp|eor|jmp|lda|ora|sbc|sub|sta) +\( *T[0-9] *[),]')),
    # This pattern matches 16-bit load/store macros (e.g. ldax) using e.g. T0
    # instead of T1T0.
    ('one-byte T register as two-byte operand', re.compile(
        r'^ *(ld|st)[axy][axy] +T[0-9][^T]')),
    # This pattern matches instructions that were probably intended to use
    # immediate addressing.
    ('suspicious address', re.compile(
        r'^ *(ad[cd]|and|cmp|cp[xy]|eor|ora|sub|sbc|ld[a-z]+) +'
        r'[-+~<>(]*([a-z0-9$%.]|Func|Main)')),
    # This pattern matches instructions that were probably intended to use
    # zero page indirect Y-indexed addressing.
    ('suspicious direct Y-index', re.compile(
        r'^ *(ad[cd]|and|cmp|eor|lda|ora|sub|sbc|sta) +'
        r'(Zp_[A-Za-z0-9_]+_ptr|T[0-9]T[0-9]), *[yY]')),
]

#=============================================================================#

def src_and_test_entries():
    for entry in os.walk('src'):
        yield entry
    for entry in os.walk('tests'):
        yield entry

def src_and_test_filepaths(*exts):
    for (dirpath, dirnames, filenames) in src_and_test_entries():
        for filename in filenames:
            for ext in exts:
                if filename.endswith(ext):
                    yield os.path.join(dirpath, filename)
                    break

#=============================================================================#

def run_tests():
    failed = [False]
    for filepath in src_and_test_filepaths('.asm', '.inc'):
        for (line_number, line) in enumerate(open(filepath)):
            def fail(message):
                print('LINT: {}:{}: found {}'.format(
                    filepath, line_number + 1, message))
                print('    ' + line.strip())
                failed[0] = True
            # Check for code that is probably a mistake.
            for (message, pattern) in BAD_CODE_PATTERNS:
                if pattern.search(line):
                    fail(message)
    return failed[0]

if __name__ == '__main__':
    sys.exit(run_tests())

#=============================================================================#
