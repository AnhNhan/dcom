
module dcom.test.performance;

import std.datetime : StopWatch;
import std.stdio : writeln;

enum default_perf_iterations = 1000000;

/// Checks the performance of a function invocation with a single parameter
void check_perf(uint iterations = default_perf_iterations, bool print_val = false, V, F)(in V v, F f, in string f_name)
{
    StopWatch w;
    w.start();

    for (int ii = 0; ii < iterations; ++ii)
    {
        f(v);
    }

    w.stop();

    static if (print_val)
    {
        writeln("    ", f_name, "('", v, "') took ", w.peek.msecs, "ms");
    }
    else
    {
        writeln("    ", f_name, " took ", w.peek.msecs, "ms");
    }
}

void check_perf(uint iterations = default_perf_iterations)(void delegate() f, string name)
{
    import std.datetime : StopWatch;

    StopWatch w;

    w.start();
    for (int ii = 0; ii < iterations; ++ii)
    {
        f();
    }
    w.stop();
    writeln("    ", name, " took ", w.peek.msecs, "ms");
}
