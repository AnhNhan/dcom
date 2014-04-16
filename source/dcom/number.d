
module dcom.number;

import std.array : appender, join;
import std.traits : isIntegral, isArray;
version(unittest) {
    import std.stdio : write, writeln;
}

/**
 * Converts a decimal number of up to long
 */
pure @trusted nothrow
string hex(T)(in T input)
    if (isIntegral!T)
{
    import std.range : retro;
    string[] hexes;
    ulong num = input;
    do {
        ubyte b = cast(ubyte) num % 256;
        num = num >> 8;
        hexes ~= bytehex(b);
    } while (num > 0);
    return hexes.retro.join();
}

/**
 * Converts an array of integral numbers to a hex string.
 */
pure @safe
string hexv(T)(in T[] input)
    if (isIntegral!T)
{
    import std.algorithm : map;
    import std.array : join;
    return input.map!hex().join();
}

unittest {
    writeln("dcom.number.hex");

    assert("00" == hex(0));
    assert("00" == hex(0x00));
    assert("0c" == hex(12));
    assert("12" == hex(0x12));
    assert("ff" == 255.hex());

    assert("0abc" == hex(0xABC));
    assert("6283a7" == hex(0x6283a7));
    assert("811c9dc5" == hex(2166136261));
    assert("811c9dc5" == hex(0x811C9DC5));

    static assert("ff" == 255.hex);

    writeln("Done.\n");
}

unittest {
    writeln("dcom.number.hex");

    assert("ff" == [255].hexv());
    int[] r1 = [0x81, 0x1c, 0x9d, 0xc5];
    assert("811c9dc5" == r1.hexv());

    writeln("Done.\n");
}

/**
 * Converts a single byte to two hex characters.
 */
pure @safe nothrow
string bytehex(in ubyte b)
{
    auto lower_bits = b % 16;
    auto higher_bits = b >> 4;

    return higher_bits.dechex() ~ lower_bits.dechex();
}

unittest {
    writeln("dcom.number.bytehex");

    assert("00" == bytehex(0));
    assert("09" == bytehex(9));
    assert("0c" == bytehex(12));
    assert("10" == bytehex(16));
    assert("ff" == bytehex(cast(ubyte) 255));

    writeln("Done.\n");
}

static immutable hexDigits = [
    "0"
  , "1"
  , "2"
  , "3"
  , "4"
  , "5"
  , "6"
  , "7"
  , "8"
  , "9"
  , "a"
  , "b"
  , "c"
  , "d"
  , "e"
  , "f"
];

/**
 * Converts a single decimal digit to a hexadecimal character.
 */
pure @trusted nothrow
string dechex(I)(in I input)
    if (isIntegral!I)
in
{
    assert(input >= 0, "Negative number not allowed!");
    assert(input <= 0b1111, "Number bigger than a single decimal.");
}
body
{
    return hexDigits[input];
}

unittest {
    writeln("dcom.number.dechex");

    assert("0" == dechex(0));
    assert("1" == dechex(1));
    assert("2" == dechex(2));
    assert("3" == dechex(3));
    assert("4" == dechex(4));
    assert("5" == dechex(5));
    assert("6" == dechex(6));
    assert("7" == dechex(7));
    assert("8" == dechex(8));
    assert("9" == dechex(9));

    assert("a" == dechex(10));
    assert("b" == dechex(11));
    assert("c" == dechex(12));
    assert("d" == dechex(13));
    assert("e" == dechex(14));
    assert("f" == dechex(15));

    writeln("Done.\n");
}
