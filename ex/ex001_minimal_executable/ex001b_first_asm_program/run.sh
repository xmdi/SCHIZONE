nasm -felf64 code.asm
ld code.o -o binary #-s 	# uncomment '-s' to strip symbols
strip -R .comment binary 	# uncomment this to strip symbols
				# and useless version info
./binary
