# create bin directory if it doesn't exist
mkdir -p bin

echo "'make_executable abc' = 'chmod +x abc'
'spawn abc' = 'touch abc'
'recycle abc' = 'rm abc'
'nyancat abc' = 'cat abc'
'list' = 'ls'
'dump abc' = 'xxd abc' = 'hexdump -C abc'
'countdown 5' -> 5 sec countdown timer" > bin/bins.md

# generate "make_executable" aka "chmod +x"
nasm -f bin -I lib/sys/`uname` -o bin/make_executable ex/ex003_command_line_args_and_code_golf/ex003b_chmod_smaller/code.asm
chmod +x bin/make_executable

# generate "spawn" aka "touch"
nasm -f bin -I lib/sys/`uname` -o bin/spawn ex/ex003_command_line_args_and_code_golf/ex003d_touch_smaller/code.asm
chmod +x bin/spawn

# generate "recycle" aka "rm"
nasm -f bin -I lib/sys/`uname` -o bin/recycle ex/ex003_command_line_args_and_code_golf/ex003f_rm_smaller/code.asm
chmod +x bin/recycle

# generate "nyancat" aka "cat"
nasm -f bin -I lib/sys/`uname` -o bin/nyancat ex/ex004_printing_strings/ex004d_nyancat/code.asm
chmod +x bin/nyancat

# generate "countdown" aka a countdown timer
nasm -f bin -I lib/sys/`uname` -o bin/countdown lab/lab004_countdown_timer/code.asm
chmod +x bin/countdown

# generate "list" aka "ls"
nasm -f bin -I lib/sys/`uname` -o bin/list lab/lab006_ls/code.asm
chmod +x bin/list

# generate "dump" aka "xxd" aka "hexdump"
nasm -f bin -I lib/sys/`uname` -o bin/dump lab/lab005_hexdump/code.asm
chmod +x bin/dump

# generate "rpn" aka a calculator
nasm -f bin -I lib/sys/`uname` -o bin/rpn ex/ex030_postfix_notation/ex30a_evaluate_postfix/code.asm
chmod +x bin/rpn
