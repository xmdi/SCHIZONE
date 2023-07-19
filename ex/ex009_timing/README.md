## Timing

In [ex009a](ex009a_rdtsc), we check for `rdtsc` support and use it to count the number of reference cycles that have elapsed.

In [ex009b](ex009b_tick_and_tock_in_cycles), we create `tick_cycles` and `tock_cycles` functions to measure the passage of time (think MATLAB) in reference cycles.

In [ex009c](ex009c_gettimeofday_syscall), we use the `GETTIMEOFDAY` syscall to check the current timestamp (with microsecond "accuracy").

In [ex009d](ex009d_tick_and_tock_in_microseconds), we create `tick_time` and `tock_time` functions to measure the passage of time (think MATLAB) in microseconds.

In [ex009e](ex009e_estimate_CPU_frequency), we use our two sets of `tick` functions to estimate the clock rate of our CPU.

In [ex009f](ex009f_sleep_delay), we implement a function to sleep a desired amount of microseconds.
