
module dcom.hash.pearson;

import dcom.number;

import std.algorithm : reduce;
import std.traits : isSomeString, isArray;
version(unittest) {
    import dcom.test.performance;

    import std.digest.digest : LetterCase, toHexString;
    import std.stdio : writeln;

    alias toHexString!(LetterCase.lower) toLowerHexString;
}

// Copy-pasted permutation table from Wikipedia
static immutable ubyte[256] table = [
     98,  6, 85,150, 36, 23,112,164,135,207,169,  5, 26, 64,165,219, //  1
     61, 20, 68, 89,130, 63, 52,102, 24,229,132,245, 80,216,195,115, //  2
     90,168,156,203,177,120,  2,190,188,  7,100,185,174,243,162, 10, //  3
    237, 18,253,225,  8,208,172,244,255,126,101, 79,145,235,228,121, //  4
    123,251, 67,250,161,  0,107, 97,241,111,181, 82,249, 33, 69, 55, //  5
     59,153, 29,  9,213,167, 84, 93, 30, 46, 94, 75,151,114, 73,222, //  6
    197, 96,210, 45, 16,227,248,202, 51,152,252,125, 81,206,215,186, //  7
     39,158,178,187,131,136,  1, 49, 50, 17,141, 91, 47,129, 60, 99, //  8
    154, 35, 86,171,105, 34, 38,200,147, 58, 77,118,173,246, 76,254, //  9
    133,232,196,144,198,124, 53,  4,108, 74,223,234,134,230,157,139, // 10
    189,205,199,128,176, 19,211,236,127,192,231, 70,233, 88,146, 44, // 11
    183,201, 22, 83, 13,214,116,109,159, 32, 95,226,140,220, 57, 12, // 12
    221, 31,209,182,143, 92,149,184,148, 62,113, 65, 37, 27,106,166, // 13
      3, 14,204, 72, 21, 41, 56, 66, 28,193, 40,217, 25, 54,179,117, // 14
    238, 87,240,155,180,170,242,212,191,163, 78,218,137,194,175,110, // 15
     43,119,224, 71,122,142, 42,160,104, 48,247,103, 15, 11,138,239, // 16
];

/**
 * Calculates a CBC-MAC 8-bit block cipher from the input array / string.
 *
 * Provides pretty good diffusion into the output range, given a good
 * permutation table (which we hopefully use);
 */
pure @safe nothrow
ubyte pearson(S)(const S input)
    if (isSomeString!S || isArray!S)
{
    ubyte hash;
    foreach (c; input)
    {
        hash = table[hash ^ c];
    }
    return hash;
}

unittest {
    writeln("dcom.hash.pearson.pearson.");

    assert(0xBA == pearson("o"));
    assert(0xEF == pearson("hello"));

    writeln("Done.\n");
}

/**
 * The vanilla Pearson algorithm only produces an 8-bit hash, which may be
 * a little bit short and does not provide enough diffusion in a big enough
 * range for some purposes.
 *
 * But there's an easy way around. To create hashes of arbitrary length, we can
 * just calculate multiple hashes (each with a slightly mutated variant), and
 * mix them together.
 */
pure @trusted /*nothrow*/
string hash_pearson(uint length = 8, S)(in S input)
    if (isSomeString!S || isArray!S)
in
{
    static assert(length > 0);
    assert(input.length > 1);
}
body
{
    return hash_pearsonv!(length)(input).toLowerHexString();
}

unittest {
    writeln("dcom.hash.pearson.hash_pearson.");

    assert("ef8c9f067bbfffa7" == "hello".hash_pearson(), "hello".hash_pearson());

    writeln("Done.\n");
}

/**
 * Like hash_pearson, but returns a raw byte array.
 */
private pure @safe /*nothrow*/
ubyte[length] hash_pearsonv(uint length = 8, S)(in S input)
    if (isSomeString!S || isArray!S)
in
{
    static assert(length > 0);
    assert(input.length > 1);
}
body
{
    ubyte[length] hashes;
    ubyte[] str = cast(ubyte[]) input.dup;
    for (int ii; ii < length; ++ii)
    {
        hashes[ii] = pearson(str);

        str[0] = cast(ubyte) (str[0] + (cast(ubyte) 1));
    }

    return hashes;
}

unittest {
    writeln("dcom.hash.pearson.hash_pearsonv.");

    assert("ef8c9f067bbfffa7" == "hello".hash_pearsonv().hexv());

    writeln("Done.\n");
}

/**
 * Like hash_pearson, but returns a uint/ulong.
 */
pure @safe /*nothrow*/
auto hash_pearson_raw(uint length = 8, S)(in S input)
    if ((isSomeString!S || isArray!S) && length <= 8)
in
{
    static assert(length > 0);
    assert(input.length > 1);
}
body
{
    import dcom.macros : combine;
    return combine(hash_pearsonv!(length)(input));
}

unittest {
    writeln("dcom.hash.pearson.hash_pearson_raw.");

    assert(0xef8c9f06U == "hello".hash_pearson_raw!4(), "0x" ~ "hello".hash_pearson_raw!4().hex());
    assert(0xef8c9f067bbfffa7UL == "hello".hash_pearson_raw(), "0x" ~ "hello".hash_pearson_raw().hex());

    writeln("Done.\n");
}

unittest {
    writeln("dcom.hash.pearson - Performance check for Pearson.");

    auto values = [
        "ab",
        "abab",
        "abababab",
        "abababababababababab",
        "abababababababababababababababababababab",
    ];

    foreach (const v; values)
    {
        writeln("  Value: ", v);

        alias v_t = typeof(v);

        check_perf(v, &hash_pearson!(8, v_t), "hash_pearson");
        check_perf(v, &hash_pearsonv!(8, v_t), "hash_pearsonv");
        check_perf(v, &hash_pearson_raw!(8, v_t), "hash_pearson_raw");
        check_perf(v, &pearson!(v_t), "pearson");

        writeln("");
    }

    writeln("Done.\n");
}
