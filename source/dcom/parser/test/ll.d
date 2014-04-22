
import dcom.parser.ll;

import std.stdio;

unittest {
    immutable token_map = [
        ":": "Colon"
      , "+": "Plus"
      , "-": "Minus"
      , "{": "Curly_Open"
      , "}": "Curly_Close"
      , "@": "At_Sign"
    ];

    immutable rule_map = [
        "Start"             : ["Expression Start", "Expression"]
      , "Expression"        : ["SpecialStmt", "Definition"]
      , "SpecialStmt"       : ["At_Sign SymbolName String"]
      , "Definition"        : ["SymbolName Colon DefinitionBody"]
      , "DefinitionBody"    : ["SingleDefinition", "MultipleDefinition"]
      , "MultipleDefinition": ["Minus SingleDefinition MultipleDefinition", "Minus SingleDefinition"]
      , "SingleDefinition"  : ["SymbolName Plus SingleDefinition", "SymbolName", "String"]
    ];

    writeln("dcom.parser.ll.parse_grammar.");

    auto gr1 = "
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

    auto tokens = gr1.tokenize(token_map);
    auto parse_tree = gr1.parse_into_parse_tree(token_map, rule_map);
    //auto parsed_grammar = gr1.parse_grammar;

    debug
    {
        writeln("  Parse Tree:");
        parse_tree.render(1).writeln;
        //writeln;
        //writeln("  Syntax Tree:");
        //writeln("    Start");
        //parsed_grammar.map!(tr => tr.render(2)).join.writeln;
    }

    assert(parse_tree.render == "Start
    Expression
        SpecialStmt
            At_Sign         @
            SymbolName      import
            String          hello.algr
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
                                String          +
                Start
                    Expression
                        Definition
                            SymbolName      Symbol
                            Colon           :
                            DefinitionBody
                                MultipleDefinition
                                    Minus           -
                                    SingleDefinition
                                        String          a
                                    MultipleDefinition
                                        Minus           -
                                        SingleDefinition
                                            String          b
                                        MultipleDefinition
                                            Minus           -
                                            SingleDefinition
                                                String          c
");

    // TODO: Syntax tree test once we have that going.

    import dcom.test.performance;
    alias check_perf!1000 check_perf_1k;
    writeln("  Performance check (1k iterations):");
    check_perf_1k({ gr1.tokenize(token_map); }, "tokenize");
    check_perf_1k({ rule_map.match("Start", tokens); }, "match");
    //check_perf_1k({ gr1.create_parse_tree; }, "create_parse_tree");
    //check_perf_1k({ parse_tree.create_syntax_tree; }, "create_syntax_tree");
    //check_perf_1k({ gr1.parse_grammar; }, "parse_grammar");

    writeln("Done.\n");
}
