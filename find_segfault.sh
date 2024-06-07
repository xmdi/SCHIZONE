N=$(sudo dmesg | grep -E segfault | tail -1 | awk '{for(i=1;i<=NF;i++) if ($i=="ip") print $(i+1)}')

next_addr=0;
next_label=0;

tail -n +34 "mem.map" | while read line;
	do 
		prev_addr=$next_addr
		prev_label=$next_label
		next_addr=`echo $line | cut -f2 -d' '`
		next_label=`echo $line | cut -f3 -d' '`
		if [[ "0x$next_addr" -eq "0x$N" ]]; then
			printf "\ncringe @ address 0x$N\n\twhich is @ $next_label\n\n"
			break
		elif [[ "0x$next_addr" -ge "0x$N" ]]; then
			printf "\ncringe @ address 0x$N\n\twhich is between 0x$prev_addr ($prev_label)\n\tand 0x$next_addr ($next_label)\n\n"
			break
		fi
	done


