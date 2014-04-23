
import dcom.parser.ll;

import std.algorithm;
import std.array;
import std.range;
import std.stdio;
import std.string;

immutable TokenMap token_map;
immutable RuleMap  rule_map;

static this()
{
    token_map = [
        ":": "Colon"
      , "+": "Plus"
      , "-": "Minus"
      , "{": "Curly_Open"
      , "}": "Curly_Close"
      , "@": "At_Sign"
      , "'": "Quote_Single"
    ];

    rule_map = [
        "Start"             : ["Expression Start", "Expression"]
      , "Expression"        : ["SpecialStmt", "Definition"]
      , "SpecialStmt"       : ["At_Sign SymbolName String"]
      , "Definition"        : ["SymbolName Colon DefinitionBody"]
      , "DefinitionBody"    : ["SingleDefinition", "MultipleDefinition"]
      , "MultipleDefinition": ["Minus SingleDefinition MultipleDefinition", "Minus SingleDefinition"]
      , "SingleDefinition"  : ["SymbolName Plus SingleDefinition", "SymbolName", "String"]
      , "String"            : ["Quote_Single StringContents Quote_Single"]
      , "StringContents"    : ["SymbolName", "Colon", "Plus", "Minus", "Curly_Open", "Curly_Close", "At_Sign"]
    ];
}

static gr1 = "
    @import 'hello.algr'

    S: Expression

    Expression:
        - Symbol
        - Expression + Operator + Expression

    Operator: '+'
    Symbol:
        - 'a'
        - 'b'
        - 'c'
";

unittest {
    writeln("dcom.parser.ll.parse_grammar.");

    auto tokens = gr1.tokenize(token_map);
    auto parse_tree = gr1.parse_into_parse_tree(token_map, rule_map, "Start");

    debug
    {
        writeln("  Parse Tree:");
        parse_tree.render(1).writeln;
    }

    assert(parse_tree.render == "Start
    Expression
        SpecialStmt
            At_Sign         @
            SymbolName      import
            String          'hello.algr'
    Start
        Expression
            Definition
                SymbolName      S
                Colon           :
                DefinitionBody
                    SingleDefinition
                        SymbolName      Expression
        Start
            Expression
                Definition
                    SymbolName      Expression
                    Colon           :
                    DefinitionBody
                        MultipleDefinition
                            Minus           -
                            SingleDefinition
                                SymbolName      Symbol
                            MultipleDefinition
                                Minus           -
                                SingleDefinition
                                    SymbolName      Expression
                                    Plus            +
                                    SingleDefinition
                                        SymbolName      Operator
                                        Plus            +
                                        SingleDefinition
                                            SymbolName      Expression
            Start
                Expression
                    Definition
                        SymbolName      Operator
                        Colon           :
                        DefinitionBody
                            SingleDefinition
                                String          '+'
                Start
                    Expression
                        Definition
                            SymbolName      Symbol
                            Colon           :
                            DefinitionBody
                                MultipleDefinition
                                    Minus           -
                                    SingleDefinition
                                        String          'a'
                                    MultipleDefinition
                                        Minus           -
                                        SingleDefinition
                                            String          'b'
                                        MultipleDefinition
                                            Minus           -
                                            SingleDefinition
                                                String          'c'
");

    import dcom.test.performance;
    alias check_perf!1000 check_perf_1k;
    writeln("  Performance check (1k iterations):");
    check_perf_1k({ gr1.tokenize(token_map); }, "tokenize");
    check_perf_1k({ rule_map.match("Start", tokens); }, "match");

    writeln("Done.\n");
}

unittest {
    writeln("dcom.parser.ll.create_ll_parser.");

    auto parser = create_ll_parser(token_map, rule_map, "Start", &create_syntax_tree);

    auto grammar_syntax_tree = parser.parse(gr1);

    debug
    {
        writeln("  Syntax Tree:");
        writeln("    Start");
        grammar_syntax_tree.map!(tr => tr.render_syntax_tree(2)).join.writeln;
    }

    assert(grammar_syntax_tree.map!(tr => tr.render_syntax_tree).join == "SpecialStmt
    @value      hello.algr
    @type       import
Definition
    @def_name   S
    SingleDefinition
        SymbolName      Expression
Definition
    @def_name   Expression
    SingleDefinition
        SymbolName      Symbol
    SingleDefinition
        SymbolName      Expression
        SymbolName      Operator
        SymbolName      Expression
Definition
    @def_name   Operator
    SingleDefinition
        String          +
Definition
    @def_name   Symbol
    SingleDefinition
        String          a
    SingleDefinition
        String          b
    SingleDefinition
        String          c
");

    import dcom.test.performance;
    alias check_perf!1000 check_perf_1k;
    writeln("  Performance check (1k iterations):");
    check_perf_1k({ create_ll_parser(token_map, rule_map, "Start", &create_syntax_tree); }, "create_ll_parser");
    check_perf_1k({ parser.parse(gr1); }, "parser.parse(gr1)");

    writeln("Done.\n");
}

/// Helper function to fetch the tokens from possibly dee+ nested
/// SingleDefinition trees
Token[] fetch_tokens(in ParseTree[] children)
{
    Token[] tokens;
    if (children.length)
    {
        tokens ~= children[0].value;
    }
    if (children.length == 3)
    {
        tokens ~= children[2].children.fetch_tokens;
    }
    return tokens;
}

/// Deep tree traversal, creating the abstract syntax tree along the way
SyntaxTree[] create_syntax_tree(ParseTree parse_tree)
{
    auto rule_name = parse_tree.rule_name;
    auto children  = parse_tree.children;
    auto token     = parse_tree.value;

    switch (rule_name)
    {
        case "Start":
            // Pass-through & aggregate
            return children.map!(ch => ch.create_syntax_tree).join;

        case "Expression":
        case "DefinitionBody":
            // Pass-through to first child
            return children[0].create_syntax_tree;

        case "SpecialStmt":
            return [SyntaxTree(token.init, rule_name, [], ["type": children[1].value.value, "value": children[2].value.value[1..$-1]])];

        case "Definition":
            return [SyntaxTree(token.init, rule_name, children[2].create_syntax_tree, ["def_name": token.value])];

        case "MultipleDefinition":
            return children[1..$].map!(ch => ch.create_syntax_tree).join.array;

        case "SingleDefinition":
            SyntaxTree[] tokens;
            foreach (tok; children.fetch_tokens)
                tokens ~= SyntaxTree(tok, tok.name);
            return [SyntaxTree(token.init, rule_name, tokens)];

        default: assert(0, "Not implemented. " ~ token.name ~ "; " ~ rule_name);
    }
}

string render_syntax_tree(SyntaxTree tree, uint level = 0)
{
    string appender;

    auto indent(uint level)
    {
        return "    ".repeat(level).join;
    }

    appender ~= indent(level);
    appender ~= tree.name.leftJustify(15) ~ " ";
    if (tree.token != Token.init)
        if (tree.token.name == "String")
            appender ~= tree.token.value[1..$-1];
        else
            appender ~= tree.token.value;
    appender  = appender.stripRight;
    appender ~= "\n";

    foreach (n, v; tree.attributes)
        appender ~= indent(level + 1) ~ "@" ~ n.leftJustify(10) ~ " " ~ v ~ "\n";

    auto ch = tree.children.map!(tr => tr.render_syntax_tree(level + 1)).join();
    appender ~= ch;

    return appender;
}
