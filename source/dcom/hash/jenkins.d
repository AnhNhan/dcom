
module dcom.hash.jenkins;

import dcom.macros;

version(unittest) {
    import std.stdio : write, writeln, writefln;

    import dcom.number;
    import dcom.test.performance;
}

auto jenkins_oaat(in string key)
{
    uint hash;

    foreach (k; key)
    {
        hash += k;
        hash += (hash << 10);
        hash ^= (hash >> 6);
    }

    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    return hash;
}

unittest {
    writeln("dcom.hash.jenkins.jenkins_oaat.");

    auto vals = [
        "hello"
      , "1234"
      , "ab"
      , "abab"
      , "abababab"
    ];

    foreach (v; vals)
    {
        writefln("  Value: %s\tHash: %s", v, jenkins_oaat(v).hex);
        check_perf(v, &jenkins_oaat, "jenkins_oaat");
    }

    writeln("Done.\n");
}

private void jenkins_mix(A, B, C)(ref A a, ref B b, ref C c)
{
    a -= c;  a ^= rotl_32(c, 4);  c += b;
    b -= a;  b ^= rotl_32(a, 6);  a += c;
    c -= b;  c ^= rotl_32(b, 8);  b += a;
    a -= c;  a ^= rotl_32(c,16);  c += b;
    b -= a;  b ^= rotl_32(a,19);  a += c;
    c -= b;  c ^= rotl_32(b, 4);  b += a;
}

private void jenkins_finalize(A, B, C)(ref A a, ref B b, ref C c)
{
    c ^= b; c -= rotl_32(b,14);
    a ^= c; a -= rotl_32(c,11);
    b ^= a; b -= rotl_32(a,25);
    c ^= b; c -= rotl_32(b,16);
    a ^= c; a -= rotl_32(c,4);
    b ^= a; b -= rotl_32(a,14);
    c ^= b; c -= rotl_32(b,24);
}

uint jenkins_hashword(in string key, in uint seed = 0)
{
    return jenkins_hashword2(key, seed)[0];
}

ulong jenkins_hashword_64(in string key, in uint seed = 0)
{
    return combine(jenkins_hashword2(key, seed));
}

unittest {
    writeln("dcom.hash.jenkins.jenkins_hashword.");

    auto vals = [
        "hello"
      , "1234"
      , "ab"
      , "abab"
      , "abababab"
    ];

    foreach (v; vals)
    {
        writefln("  Value: %s\tHash: %s", v, jenkins_hashword(v).hex);
        check_perf(v, &jenkins_hashword, "jenkins_hashword");
    }

    writeln("Done.\n");
}

uint[2] jenkins_hashword2(in string key, in uint seed = 0)
{
    uint a, b, c;

    a = b = c = 0xdeadbeef + (key.length << 2) + seed;

    size_t length = key.length;

    const(uint)* keydata = cast(const(uint)*) key;

    while (length > 3)
    {
        a += keydata[0];
        b += keydata[1];
        c += keydata[2];

        jenkins_mix(a, b, c);
        length  -= 3;
        keydata += 3;
    }

    // Handle the remaining 3 bytes
    // All cases fall through
    switch (length)
    {
        case 3:
            c += keydata[2];
        case 2:
            b += keydata[1];
        case 1:
            a += keydata[0];

            jenkins_finalize(a, b, c);
        case 0:
            // nothing left to add
            break;
        default:
            assert(0, "Huh? More than 3 bytes left?");
    }

    return [c, b];
}
