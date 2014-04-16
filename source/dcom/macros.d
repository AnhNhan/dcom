
module dcom.macros;

/**
 * Common macros from C/C++.
 */

import std.traits : isIntegral;

pure:
@safe:
nothrow:

alias rotl_32 = rotl_x!(32, uint);
alias rotl_64 = rotl_x!(64, ulong);

alias rotr_32 = rotr_x!(32, uint);
alias rotr_64 = rotr_x!(64, ulong);

auto rotl_x(size_t size_in_bits, V1)(V1 x, int r)
    if (isIntegral!V1)
{
    return (x << r) | (x >> (size_in_bits - r));
}

auto rotr_x(size_t size_in_bits, V1)(V1 x, int r)
    if (isIntegral!V1)
{
    return (x >> r) | (x << (size_in_bits - r));
}

auto rotl_x(int r, size_t size_in_bits, V1)(V1 x)
    if (isIntegral!V1)
{
    return (x << r) | (x >> (size_in_bits - r));
}

auto rotr_x(int r, size_t size_in_bits, V1)(V1 x)
    if (isIntegral!V1)
{
    return (x >> r) | (x << (size_in_bits - r));
}

ushort combine(ubyte x, ubyte y)
{
    return ((cast(ushort) x) << 8) | y;
}

uint combine(ushort x, ushort y)
{
    return ((cast(ushort) x) << 16) | y;
}

ulong combine(uint x, uint y)
{
    return ((cast(ulong) x) << 32) | y;
}

ushort combine(ubyte[2] x)
{
    return combine(x[0], x[1]);
}

uint combine(ubyte[4] x)
{
    return combine(combine(x[0], x[1]), combine(x[2], x[3]));
}

ulong combine(ubyte[8] x)
{
    return combine(combine(combine(x[0], x[1]), combine(x[2], x[3])), combine(combine(x[4], x[5]), combine(x[6], x[7])));
}

ulong combine(uint[2] x)
{
    return combine(x[0], x[1]);
}

unittest {
    assert(0xEEEEEEEEFFFFFFFFUL == combine(0xEEEEEEEEU, 0xFFFFFFFFU));
    assert(0xEEEEEEEEFFFFFFFFUL == combine([0xEEEEEEEEU, 0xFFFFFFFFU]));
}
