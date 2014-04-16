
module dcom.test.hash;

import dcom.number;
import dcom.test.performance;

import std.stdio : write, writeln, writefln;
import std.traits : isArray, isCallable;

private enum hash_func_test_vals = [
    "hello"
  , "1234"
  , "ab"
  , "abab"
  , "abababab"
];

void test_hash(F)(F func, string name)
    if (isCallable!F)
{
    foreach (v; hash_func_test_vals)
    {
        writefln("  Value: %s\tHash: %s", v, func(v).hex);
        check_perf(v, func, name);
    }
}

void test_hash_v(F)(F func, string name)
    if (isCallable!F)
{
    foreach (v; hash_func_test_vals)
    {
        writefln("  Value: %s\tHash: %s", v, func(v).hexv);
        check_perf(v, func, name);
    }
}

void test_hashv(F)(F[string] functions)
{
    auto values = [
        "hello"
      , "ab"
      , "abab"
      , "abababab"
      , "abababababababababab"
      , "abababababababababababababababababababab"
    ];

    foreach (const v; values)
    {
        writeln("  Value: ", v);

        alias v_t = typeof(v);

        foreach (name, f; functions)
        {
            writeln("    ", name, ":\tHash: ", f(v).hex);

            write("  ");
            check_perf(v, f, name);
        }

        writeln("");
    }
}
