
module dcom.matrix;

import std.traits : isArray, isStaticArray;
import std.range : ElementType;

version(unittest) {
    import dcom.test.performance;
    import std.stdio : writeln;
}

/// This function eagerly rotates a square matrix by 90 degrees clockwise.
Matrix rotate90CW(Matrix)(Matrix matrix)
    if (isArray!Matrix && isArray!(ElementType!Matrix))
in
{
    assert(matrix.length);
    assert(matrix[0].length);
    foreach (r; matrix)
        assert(matrix.length == r.length, "We only support quadratic matrices.");
}
body
{
    Matrix target;

    auto len = matrix.length;

    static if (!isStaticArray!Matrix)
    {
        target.length = len;
        foreach (ref r; target)
            r.length = len;
    }

    foreach (ii; 0..len)
    {
        foreach (jj; 0..len)
        {
            target[ii][jj] = matrix[(len - 1) - jj][ii];
        }
    }

    return target;
}

/// Ditto. Overload for repeated application.
Matrix rotate90CW(Matrix)(Matrix matrix, uint times)
    if (isArray!Matrix && isArray!(ElementType!Matrix))
{
    if (times == 1)
    {
        return matrix.rotate90CW;
    }

    if (times == 0)
    {
        return matrix;
    }

    return matrix.rotate90CW.rotate90CW(times - 1);
}

/// Ditto. Template for compile-time repeated application (we save like 4-5%).
Matrix rotate90CW(uint times, Matrix)(Matrix matrix)
    if (isArray!Matrix && isArray!(ElementType!Matrix))
{
    static if (times == 0)
    {
        return matrix;
    }
    else static if (times == 1)
    {
        return matrix.rotate90CW;
    }
    else // Generic, all other cases
    {
        return matrix.rotate90CW.rotate90CW!(times - 1);
    }
}

unittest {
    writeln("dcom.matrix.rotate90CW.");

    auto m1 = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
    ];

    assert(m1.rotate90CW == [
            [7, 4, 1],
            [8, 5, 2],
            [9, 6, 3],
        ]);

    assert(m1.rotate90CW.rotate90CW.rotate90CW.rotate90CW == m1);
    assert(m1.rotate90CW.rotate90CW.rotate90CW.rotate90CW == m1.rotate90CW(4));

    writeln("  Performance check.");

    check_perf({ m1.rotate90CW; }, "rotate90CW()");
    check_perf({ m1.rotate90CW(4); }, "rotate90CW(4)");
    check_perf({ m1.rotate90CW.rotate90CW.rotate90CW.rotate90CW; }, "m1.rotate90CW.rotate90CW.rotate90CW.rotate90CW");
    check_perf({ m1.rotate90CW!1; }, "rotate90CW!(1)");
    check_perf({ m1.rotate90CW!4; }, "rotate90CW!(4)");

    writeln("Done.\n");
}
