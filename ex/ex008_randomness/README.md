## Randomness

In [ex008a](ex008a_random_int), we generate a random integer using the `rdrand` instruction.

In [ex008b](ex008b_random_int_array), we generate an array of random integers.

In [ex008c](ex008c_random_float), we generate a random float using the `rdrand` instruction.

In [ex008d](ex008d_random_float_array), we generate an array of random floats.

In [ex008e](ex008e_deal_or_no_deal), we recreate the game show "Deal or No Deal" using random integers.

In [ex008f](ex008f_cpu_support_and_getrandom_syscall), we use the `cpuid` instruction to test for cpu support of the `rdrand` and `rdseed` instructions. We also implement an alternative using the `GETRANDOM` syscall, although it is nonstandard on FreeBSD.

