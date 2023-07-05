## Printing Strings

In [ex004a](ex004a_c_equivalent), we see how C's printf buffers output (check the numbers of syscalls with 'strace -c ./binary' on Linux or 'truss -c ./binary' on FreeBSD).

In [ex004b](ex004b_writing_to_stdout), we use a syscall to write something to stdout in assembly. Check the number of syscalls to do it this way. Not a good solution.

In [ex004c](ex004c_buffered_writes), we implement functions for buffered writes. Check the number of syscalls to do it this way. Now we can match the C implementation.

In [ex004d](ex004d_nyancat), we implement an alternative to "cat". Worse in every way (except filesize and understandability).
