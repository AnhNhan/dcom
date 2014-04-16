
module dcom.filter;

version(unittest) {
    import std.stdio : write, writeln;
}

alias hash_func = size_t function(string) pure nothrow;

/**
 * Excerpt from Wikipedia:
 *
 *   A [Bloom filter][1] is a space-efficient probabilistic data structure,
 *   conceived by Burton Howard Bloom in 1970, that is used to test whether an
 *   element is a member of a set. False positive matches are possible, but
 *   false negatives are not; i.e. a query returns either "possibly in set" or
 *   "definitely not in set". Elements can be added to the set, but not removed
 *   (though this can be addressed with a "counting" filter). The more elements
 *   that are added to the set, the larger the probability of false positives.
 *
 *     [1]: http://en.wikipedia.org/wiki/Bloom_filter
 *
 * More info for bloom filters and the workings of their magic:
 *
 *   http://www.michaelnielsen.org/ddi/why-bloom-filters-work-the-way-they-do/
 */
class BloomFilter(uint size_in_bytes)
{
public:

    enum size = size_in_bytes;
    enum bit_size = size_in_bytes * 8;

    void add(in string key) pure @trusted nothrow
    {
        // Set all bits at offsets indicated by the hash functions to 1.
        foreach (func; hash_functions)
        {
            auto hash = func(key);
            buffer[byte_offset(hash)] |= (1 << bit_offset(hash));
        }
    }

    bool may_exist(in string key) const pure @trusted nothrow
    {
        foreach (func; hash_functions)
        {
            // If any of the bits at offsets indicated by the hash functions
            // are zero, we can be sure that the key is not in the set.
            if (!check_offset(func(key)))
            {
                return false;
            }
        }

        return true;
    }

    this(F)(F[] f) pure @safe nothrow
    {
        hash_functions ~= f;
    }

    debug string __string() const
    {
        import std.range : iota, retro;
        string s = "0b";
        foreach (cur_byte; buffer)
        {
            foreach (nn; iota(0, 7).retro)
            {
                s ~= ((cur_byte & (1 << nn)) != 0) ? "1" : "0";
            }
        }

        return s;
    }

private:

    bool check_offset(ulong hash) const pure @safe nothrow
    {
        return (buffer[byte_offset(hash)] & (1 << bit_offset(hash))) != 0;
    }

    uint byte_offset(ulong x) const pure @safe nothrow
    {
        return (x / 8) % buffer.length;
    }

    ubyte bit_offset(ulong x) const pure @safe nothrow
    {
        return x % 8;
    }

    immutable hash_func[] hash_functions;

    ubyte[size_in_bytes] buffer;
}

unittest {
    writeln("dcom.filter.BloomFilter.");

    import dcom.hash.fnv;
    import dcom.hash.jenkins;
    import dcom.hash.murmur;
    import dcom.hash.pearson;

    auto b1 = new BloomFilter!(5)([
        cast(hash_func) &jenkins_hashword
      , cast(hash_func) &murmur3_32
      , cast(hash_func) &hash_fnv1a_64!(string)
      , cast(hash_func) &hash_pearson_raw!(8, string)
    ]);

    static assert(b1.size     == 5);
    static assert(b1.bit_size == 40);

    debug writeln("  Before:\t", b1.__string);

    assert(!b1.may_exist("foo"));
    b1.add("foo");
    assert(b1.may_exist("foo"));
    debug writeln("  'foo':\t", b1.__string);

    assert(!b1.may_exist("bar"));
    b1.add("bar");
    assert(b1.may_exist("bar"));
    debug writeln("  'bar':\t", b1.__string);

    assert(!b1.may_exist("baz"));
    b1.add("baz");
    assert(b1.may_exist("baz"));
    debug writeln("  'baz':\t", b1.__string);

    debug write("\n\n");

    // Testing various performance stuffs
    // NOTE: CPU cache may kick our ass. I think we do spend
    //       most time calculating hashes, though.

    import dcom.test.performance;

    writeln("  Measuring performance for bloom filter.");
    check_perf("hello", &b1.add, "adding word");
    check_perf("hello", &b1.may_exist, "testing word - existing");
    check_perf("123", &b1.may_exist, "testing word - not exists");

    writeln("Done.\n");
}

