
module dcom.hash.fnv;

import dcom.number;

import std.traits : isSomeString, isArray;
version(unittest) {
    import dcom.test.hash;

    import std.stdio : writeln, write;
    import std.traits : isSomeFunction;
}

/**
 * Implements the Fowler-Noll-Vo hashing function. 32bit and 64bit variants.
 *
 * NOTE: This hashing function is not suitable for cryptographic purposes.
 */

enum FNV_offset_basis_32 = 2166136261;
enum FNV_offset_basis_64 = 14695981039346656037UL;

enum FNV_prime_32 = 16777619;
enum FNV_prime_64 = 1099511628211UL;

private enum FNV_Variant { FNV1, FNV1a }

pure @safe nothrow
auto hash_fnv1_32(S)(const S input)
    if (isArray!S || isSomeString!S)
{
    return fnv!(
        uint
      , FNV_offset_basis_32
      , uint
      , FNV_prime_32
      , FNV_Variant.FNV1
        )(input);
}

pure @safe nothrow
auto hash_fnv1a_32(S)(const S input)
    if (isArray!S || isSomeString!S)
{
    return fnv!(
        uint
      , FNV_offset_basis_32
      , uint
      , FNV_prime_32
      , FNV_Variant.FNV1a
        )(input);
}

pure @safe nothrow
auto hash_fnv1_64(S)(const S input)
    if (isArray!S || isSomeString!S)
{
    return fnv!(
        ulong
      , FNV_offset_basis_64
      , ulong
      , FNV_prime_64
      , FNV_Variant.FNV1
        )(input);
}

pure @safe nothrow
auto hash_fnv1a_64(S)(const S input)
    if (isArray!S || isSomeString!S)
{
    return fnv!(
        ulong
      , FNV_offset_basis_64
      , ulong
      , FNV_prime_64
      , FNV_Variant.FNV1a
        )(input);
}

private pure @safe nothrow
auto fnv(A, A FNV_offset_basis, B, B FNV_prime, FNV_Variant variant, T)(const T input)
    if (isArray!T || isSomeString!T)
{
    auto hash = FNV_offset_basis;
    foreach (chr; input)
    {
        static if (variant == FNV_Variant.FNV1a) {
            hash ^= chr;
            hash *= FNV_prime;
        } else static if (variant == FNV_Variant.FNV1) {
            hash *= FNV_prime;
            hash ^= chr;
        } else {
            assert(0, "Invalid variant given!");
        }
    }
    return hash;
}

unittest {
    writeln("Performance check for FNV.");

    test_hashv([
        "hash_fnv1_32": (string x) { return cast(ulong) hash_fnv1_32(x); }
      , "hash_fnv1a_32": (string x) { return cast(ulong) hash_fnv1a_32(x); }
      , "hash_fnv1_64": (string x) { return cast(ulong) hash_fnv1_64(x); }
      , "hash_fnv1a_64": (string x) { return cast(ulong) hash_fnv1a_64(x); }
    ]);

    writeln("Done.\n");
}

unittest {
    writeln("Testing for consistency with the reference C implementation.");

    // Only testing selected values (I'm not gonna paste all 200 values)
    auto input_vals = [
        "",                                      // 0
        "a",                                     // 1
        "foobar",                                // 11
    ];

    auto fnv1_32_vals = [
        0x811c9dc5UL,
        0x050c5d7eUL,
        0x31f0b262UL,
    ];

    auto fnv1a_32_vals = [
        0x811c9dc5UL,
        0xe40c292cUL,
        0xbf9cf968UL,
    ];

    auto fnv1_64_vals = [
        0xcbf29ce484222325UL,
        0xaf63bd4c8601b7beUL,
        0x340d8765a4dda9c2UL,
    ];

    auto fnv1a_64_vals = [
        0xcbf29ce484222325UL,
        0xaf63dc4c8601ec8cUL,
        0x85944171f73967e8UL,
    ];

    auto check_values(T, U, V)(T f, U[] i_v, V[] o_v)
        if (isSomeFunction!T)
    {
        string[] errors;
        write("    ");
        foreach (ii, input; i_v)
        {
            auto hash = f(input);

            if (hash == o_v[ii]) {
                write(".");
            } else {
                write("F");
                import std.conv;
                errors ~= "      [" ~ to!string(ii) ~ "] Value " ~ hash.hex() ~ " does not match expected value " ~ o_v[ii].hex() ~ " (input was '" ~ to!string(input) ~ "')";
            }
        }

        if (errors.length > 0) {
            writeln("\n\n   Failures:");
            foreach (msg; errors)
            {
                writeln(msg);
            }
        }

        writeln("");
    }

    writeln("  hash_fnv1_32");
    check_values(&hash_fnv1_32!(string), input_vals, fnv1_32_vals);

    writeln("  hash_fnv1a_32");
    check_values(&hash_fnv1a_32!(string), input_vals, fnv1a_32_vals);

    writeln("  hash_fnv1_64");
    check_values(&hash_fnv1_64!(string), input_vals, fnv1_64_vals);

    writeln("  hash_fnv1a_64");
    check_values(&hash_fnv1a_64!(string), input_vals, fnv1a_64_vals);

    writeln("Done.\n");
}
