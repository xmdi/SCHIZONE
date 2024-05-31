# clean up everything but the source code
find . -name 'binary' -delete
find . -name 'myfile.map' -delete
find . -name '*.bmp' -delete
find . -name '*.svg' -delete
find . -name '*.html' -delete
rm -f -R bin
rm -f ex/ex001_minimal_executable/ex001b_first_asm_program/code.o
