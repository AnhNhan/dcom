
module dcom.matrix;

import std.traits : isArray, isStaticArray;
import std.range : ElementType;

version(unittest) {
    import dcom.test.performance;
    import std.stdio : writeln;
}

enum isMatrix(T) = isArray!T && isArray!(ElementType!T);

alias MatrixElement(T) = ElementType!(ElementType!T);

/// This function eagerly rotates a square matrix by 90 degrees clockwise.
Matrix rotate90CW(Matrix)(Matrix matrix)
    if (isMatrix!Matrix)
in
{
    assert(matrix.length);
    assert(matrix[0].length);
    foreach (r; matrix)
        assert(matrix.length == r.length, "We only support quadratic matrices.");
}
body
{
    // The type may sometimes be const(T[][]) or even const(const(const(T)[])[])
    import std.traits : Unqual;
    Unqual!(MatrixElement!Matrix)[][] target;

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

    return cast(Matrix) target;
}

/// Ditto. Overload for repeated application.
Matrix rotate90CW(Matrix)(Matrix matrix, uint times)
    if (isMatrix!Matrix)
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
    if (isMatrix!Matrix)
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

    alias check_perf!100000 check_perf_100k;

    check_perf_100k({ m1.rotate90CW; }, "rotate90CW()");
    check_perf_100k({ m1.rotate90CW(4); }, "rotate90CW(4)");
    check_perf_100k({ m1.rotate90CW.rotate90CW.rotate90CW.rotate90CW; }, "m1.rotate90CW.rotate90CW.rotate90CW.rotate90CW");
    check_perf_100k({ m1.rotate90CW!1; }, "rotate90CW!(1)");
    check_perf_100k({ m1.rotate90CW!4; }, "rotate90CW!(4)");

    writeln("Done.\n");
}

/// Gives back the number of empty cells in a matrix (element type.init).
size_t countEmpty(Matrix)(in Matrix matrix)
    if (isMatrix!Matrix)
in
{
    assert(matrix.length);
    assert(matrix[0].length);
}
body
{
    alias el = MatrixElement!Matrix;
    size_t count;

    foreach (const rr; matrix)
        foreach (const cc; rr)
            if (cc == el.init)
                ++count;

    return count;
}

unittest {
    writeln("utils.grid.countEmpty.");

    auto m1 = [
        [1, 2, 0],
        [4, 0, 6],
        [0, 8, 0],
    ];
    auto m2 = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
    ];

    assert(m1.countEmpty == 4);
    assert(m2.countEmpty == 0);

    writeln("Done.\n");
}

/// Checks whether a matrix has a non-empty neighbor with the same value in one
/// of its columns. We don't check the rows.
bool hasPair_vert(Matrix)(in Matrix matrix)
    if (isMatrix!Matrix)
in
{
    assert(matrix.length);
    assert(matrix[0].length);
}
body
{
    const size_y = matrix.length;
    const size_x = matrix[0].length;
    for (int rr = size_y - 1; rr >= 0; --rr)
    {
        for (int cc; cc < size_x; ++cc)
        {
            if (rr == size_y - 1)
            {
                continue;
            }

            if (matrix[rr][cc] == matrix[rr + 1][cc] && matrix[rr][cc] != cc.init)
            {
                return true;
            }
        }
    }

    return false;
}

/// Ditto, but does it for both columns and rows.
bool hasPair(Matrix)(in Matrix matrix)
    if (isMatrix!Matrix)
{
    if (matrix.hasPair_vert)
        return true;

    return matrix.rotate90CW.hasPair_vert;
}

unittest {
    writeln("utils.grid.hasPair.");

    auto m1 = [
        [1, 2, 0],
        [4, 0, 6],
        [0, 8, 0],
    ];
    auto m2 = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
    ];
    auto m3 = [
        [2, 2, 3],
        [4, 5, 6],
        [7, 9, 9],
    ];
    auto m4 = [
        [1, 2, 3],
        [1, 5, 6],
        [7, 8, 9],
    ];
    auto m5 = [
        [1, 2, 3],
        [4, 5, 9],
        [7, 8, 9],
    ];

    assert(false == m1.hasPair_vert);
    assert(false == m2.hasPair_vert);
    assert(false == m3.hasPair_vert);
    assert(true  == m4.hasPair_vert);
    assert(true  == m5.hasPair_vert);

    assert(false == m1.hasPair);
    assert(false == m2.hasPair);
    assert(true  == m3.hasPair);
    assert(true  == m4.hasPair);
    assert(true  == m5.hasPair);

    writeln("Done.\n");
}
