
module dcom.hash.murmur;

import dcom.macros;

version(unittest) {
    import std.stdio : write, writeln, writefln;

    import dcom.number;
    import dcom.test.performance;
    import dcom.test.hash;
}

private
{
    pure @trusted nothrow
    uint getblock_32(in uint* p, in uint i)
    {
        return p[i];
    }

    pure @trusted nothrow
    ulong getblock_64(in ulong* p, in uint i)
    {
        return p[i];
    }

    pure @safe nothrow
    void fmix_32(ref uint h)
    {
        h ^= h >> 16;
        h *= 0x85ebca6b;
        h ^= h >> 13;
        h *= 0xc2b2ae35;
        h ^= h >> 16;
    }

    pure @safe nothrow
    void fmix_64(ref ulong h)
    {
        h ^= h >> 33;
        h *= 0xff51afd7ed558ccdL;
        h ^= h >> 33;
        h *= 0xc4ceb9fe1a85ec53L;
        h ^= h >> 33;
    }
}

pure @trusted nothrow
auto murmur3_32(in string key, in size_t seed = 0)
{
    static immutable auto c1 = 0xcc9e2d51;
    static immutable auto c2 = 0x1b873593;
    static immutable auto r1 = 15;
    static immutable auto r2 = 13;
    static immutable auto m  = 5;
    static immutable auto n  = 0xe6546b64;

    auto len = key.length;

    // To get four-byte chunks from data
    const(uint)* keydata = cast(const(uint)*) key;

    uint hash = seed;

    while (len >= 4)
    {
        uint k = *keydata++;
        len -= 4;

        k *= c1;
        k  = rotl_32(k, r1);
        k *= c2;

        hash ^= k;
        hash = rotl_32(hash, r2);
        hash  = hash * m + n;
    }

    // If there are some remaining bytes
    if (len > 0)
    {
        uint remainingBytes = *keydata++;

        // Delete excess bits
        switch (len)
        {
            case 1:
                remainingBytes &= 0xff000000;
                break;
            case 2:
                remainingBytes &= 0xffff0000;
                break;
            case 3:
                remainingBytes &= 0xffffff00;
                break;
            default:
                break;
        }

        //remainingBytes = bswap_32(remainingBytes);
        remainingBytes *= c1;
        remainingBytes = rotl_32(remainingBytes, r1);
        remainingBytes *= c2;
        hash ^= remainingBytes;
    }

    hash ^= len;
    fmix_32(hash);

    return hash;
}

pure @trusted nothrow
uint[4] murmur3_x86_128(in string key, in uint seed = 0)
{
    const ubyte* data = cast(const ubyte*) key;
    const uint    nblocks = key.length / 16;

    uint h1, h2, h3, h4;
    h1 = h2 = h3 = h4 = seed;

    static immutable uint c1 = 0x239b961b;
    static immutable uint c2 = 0xab0e9789;
    static immutable uint c3 = 0x38b34ae5;
    static immutable uint c4 = 0xa1e38b93;

    const uint* blocks = cast(const uint*) data[0..(nblocks * 16)];

    for (int ii = -nblocks; ii; ++ii)
    {
        uint k1 = getblock_32(blocks, ii * 4 + 0);
        uint k2 = getblock_32(blocks, ii * 4 + 1);
        uint k3 = getblock_32(blocks, ii * 4 + 2);
        uint k4 = getblock_32(blocks, ii * 4 + 3);

        k1 *= c1;
        k1  = rotl_32(k1, 15);
        k1 *= c2;
        h1 ^= k1;

        h1  = rotl_32(h1, 19);
        h1 += h2;
        h1  = h1 * 5 + 0x561ccd1b;

        k2 *= c2;
        k2  = rotl_32(k2, 16);
        k2 *= c3;
        h2 ^= k2;

        h2  = rotl_32(h2, 17);
        h2 += h3;
        h2  = h2 * 5 + 0x0bcaa747;

        k3 *= c3;
        k3  = rotl_32(k3, 17);
        k3 *= c4;
        h3 ^= k3;

        h3  = rotl_32(h3, 15);
        h3 += h4;
        h3  = h2 * 5 + 0x96cd1c35;

        k4 *= c4;
        k4  = rotl_32(k4, 18);
        k4 *= c1;
        h4 ^= k4;

        h4  = rotl_32(h3, 13);
        h4 += h1;
        h4  = h4 * 5 + 0x32ac3b17;
    }

    const ubyte* tail = cast(const ubyte*) data[(nblocks * 16)..key.length];

    uint k1, k2, k3, k4;

    switch (key.length & 15)
    {
        case 15: k4 ^= tail[14] << 16;
        case 14: k4 ^= tail[13] << 8;
        case 13: k4 ^= tail[12] << 0;
                k4 *= c4;
                k4  = rotl_32(k4, 18);
                k4 *= c1;
                h4 ^= k4;

        case 12: k3 ^= tail[11] << 24;
        case 11: k3 ^= tail[10] << 16;
        case 10: k3 ^= tail[ 9] << 8;
        case  9: k3 ^= tail[ 8] << 0;
                k3 *= c3;
                k3  = rotl_32(k3, 17);
                k3 *= c4;
                h3 ^= k3;

        case  8: k2 ^= tail[ 7] << 24;
        case  7: k2 ^= tail[ 6] << 16;
        case  6: k2 ^= tail[ 5] << 8;
        case  5: k2 ^= tail[ 4] << 0;
                k2 *= c2;
                k2  = rotl_32(k2, 16);
                k2 *= c3;
                h2 ^= k2;

        case  4: k1 ^= tail[ 3] << 24;
        case  3: k1 ^= tail[ 2] << 16;
        case  2: k1 ^= tail[ 1] << 8;
        case  1: k1 ^= tail[ 0] << 0;
                k1 *= c1;
                k1  = rotl_32(k1, 15);
                k1 *= c2;
                h1 ^= k1;

                break;
        default: assert(0, "How did you do that!?");
    }

    h1 ^= key.length;
    h2 ^= key.length;
    h3 ^= key.length;
    h4 ^= key.length;

    h1 += h2;
    h1 += h3;
    h1 += h4;

    h2 += h1;
    h3 += h1;
    h4 += h1;

    fmix_32(h1);
    fmix_32(h2);
    fmix_32(h3);
    fmix_32(h4);

    h1 += h2;
    h1 += h3;
    h1 += h4;

    h2 += h1;
    h3 += h1;
    h4 += h1;

    return [h1, h2, h3, h4];
}

pure @trusted nothrow
ulong[2] murmur3_x64_128(in string key, in uint seed = 0)
{
    const ubyte* data = cast(const ubyte*) key.ptr;
    const int nblocks = key.length / 16;

    ulong h1 = seed;
    ulong h2 = seed;

    static immutable ulong c1 = 0x87c37b91114253d5L;
    static immutable ulong c2 = 0x4cf5ad432745937fL;

    const ulong* blocks = cast(const ulong*) data;

    for (int i = 0; i < nblocks; ++i)
    {
        ulong k1 = getblock_64(blocks, i * 2 + 0);
        ulong k2 = getblock_64(blocks, i * 2 + 1);

        k1 *= c1;
        k1  = rotl_64(k1, 31);
        k1 *= c2;
        h1 ^= k1;

        h1  = rotl_64(h1, 27);
        h1 += h2;
        h1  = h1 * 5 + 0x52dce729;

        k2 *= c2;
        k2  = rotl_64(k2, 33);
        k2 *= c1;
        h2 ^= k2;

        h2  = rotl_64(h2, 31);
        h2 += h1;
        h2  = h2 * 5 + 0x38495ab5;
    }

    const ubyte* tail = cast(const ubyte*) (data + nblocks * 16);

    ulong k1, k2;

    switch(key.length & 15)
    {
        case 15: k2 ^= (cast(ulong) tail[14]) << 48;
        case 14: k2 ^= (cast(ulong) tail[13]) << 40;
        case 13: k2 ^= (cast(ulong) tail[12]) << 32;
        case 12: k2 ^= (cast(ulong) tail[11]) << 24;
        case 11: k2 ^= (cast(ulong) tail[10]) << 16;
        case 10: k2 ^= (cast(ulong) tail[ 9]) << 8;
        case  9: k2 ^= (cast(ulong) tail[ 8]) << 0;
                k2 *= c2;
                k2  = rotl_64(k2, 33);
                k2 *= c1;
                h2 ^= k2;

        case  8: k1 ^= (cast(ulong) tail[ 7]) << 56;
        case  7: k1 ^= (cast(ulong) tail[ 6]) << 48;
        case  6: k1 ^= (cast(ulong) tail[ 5]) << 40;
        case  5: k1 ^= (cast(ulong) tail[ 4]) << 32;
        case  4: k1 ^= (cast(ulong) tail[ 3]) << 24;
        case  3: k1 ^= (cast(ulong) tail[ 2]) << 16;
        case  2: k1 ^= (cast(ulong) tail[ 1]) << 8;
        case  1: k1 ^= (cast(ulong) tail[ 0]) << 0;
                k1 *= c1;
                k1  = rotl_64(k1, 31);
                k1 *= c2;
                h1 ^= k1;

                break;
        default: assert(0, "How did you do that!?");
    }

    h1 ^= key.length;
    h2 ^= key.length;

    h1 += h2;
    h2 += h1;

    fmix_64(h1);
    fmix_64(h2);

    h1 += h2;
    h2 += h1;

    return [h1, h2];
}

unittest {
    writeln("dcom.hash.murmur.");

    test_hashv([
        "murmur3_x86_128": (string x) { return cast(ulong) x.murmur3_x86_128[0]; }
      , "murmur3_x64_128": (string x) { return cast(ulong) x.murmur3_x64_128[0]; }
      , "murmur3_32": (string x) { return cast(ulong) x.murmur3_32; }
    ]);

    writeln("Done.\n");
}
