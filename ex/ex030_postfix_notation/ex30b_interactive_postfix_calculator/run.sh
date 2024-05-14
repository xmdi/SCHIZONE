nasm -f bin -I ../../../ -I ../../../lib/sys/`uname` -o binary code.asm
../../../bin/make_executable binary # run ./make_bins.sh to generate this, or use "chmod +x binary"
./binary "5 5 +"
