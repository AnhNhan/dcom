
module dcom.literals;

version(unittest) {
    import std.stdio : writeln;
}

char ascii_char(ubyte o)()
{
    return cast(char) o;
}

char ascii_char(ubyte o)
{
    return cast(char) o;
}

string ascii(ubyte o)()
{
    return [ascii_char!o];
}

string ascii(ubyte o)
{
    return [ascii_char(o)];
}

unittest {
    writeln("dcom.literals.ascii.");

    assert(ascii_char!65 == 'A');
    assert(ascii_char(65) == 'A');

    assert(ascii!65 == "A");
    assert(ascii(65) == "A");

    writeln("Done.\n");
}
