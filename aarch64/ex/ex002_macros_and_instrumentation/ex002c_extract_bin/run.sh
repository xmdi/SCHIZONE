as code.asm -o temp -I ../../../lib # assemble the code into object file
#as code.asm -o temp -I ../../../lib --defsym VERBOSE_LOGS=1 # assemble but verbose

bytes=$(xxd -p -l8 -g4 -s 160 -e temp)
bytes_trimmed="${bytes:19:8}${bytes:10:8}"
bytes_to_end=$((16#${bytes_trimmed}+120)) # extract code size from binary

xxd -p -s 64 -l "$bytes_to_end" temp | xxd -r -p > binary # cut off the boomer-bytes

#rm temp* # remove temporary boomer object file
chmod +x binary # make binary executable

./binary temp binary_extractor # use the binary extractor to create the binary extractor (wow epic)

#rm binary

