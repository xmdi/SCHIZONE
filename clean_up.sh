# clean up everything but the source code
find . -name 'binary' -delete
rm -f -R bin
rm -f ex/ex001_minimal_executable/ex001b_first_asm_program/code.o
