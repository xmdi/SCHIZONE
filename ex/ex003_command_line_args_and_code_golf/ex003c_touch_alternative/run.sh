nasm -f bin -I ../../../ -I ../../../lib/sys/`uname` -o binary code.asm
chmod +x binary
./binary
