as code.asm -o temp -I ../../../lib --defsym VERBOSE_LOGS=1 # assemble the code into object file

bytes=$(xxd -ps -l 8 -s 160 temp)
bytes_trimmed="${bytes:14:2}${bytes:12:2}${bytes:10:2}${bytes:8:2}${bytes:6:2}${bytes:4:2}${bytes:2:2}${bytes:0:2}"
bytes_to_end=$((16#${bytes_trimmed}+120)) # extract code size from binary

xxd -ps -s 64 -l "$bytes_to_end" temp | xxd -r -ps > binary # cut off the boomer-bytes

chmod +x binary # make binary executable

./binary temp binary_extractor 

rm binary
