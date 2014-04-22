
module dcom.parser.ll;

import std.algorithm;
import std.array;
import std.range;
import std.typecons;

auto create_ll_parser(in TokenMap _token_map, in RuleMap _rule_map, in string _start_rule, SyntaxTree[] function(ParseTree) _create_syntax_tree)
{
    auto parser_func = (in string input) => _create_syntax_tree(input.parse_into_parse_tree(_token_map, _rule_map, _start_rule));
    return Tuple!(typeof(parser_func), "parse")(parser_func);
}

alias Token = Tuple!(string, "name", string, "value");

alias string[string]   TokenMap;
alias string[][string] RuleMap;

const struct ParseTree
{
    Token value;
    string rule_name;
    ParseTree[] children;

    @property string name() const { return value.name; }

    @property bool isLeaf() const { return children.empty; }

    @property size_t count_tokens() const { return isLeaf ? 1 : 0.reduce!((r, tr) => r + tr.count_tokens)(children); }
}

struct SyntaxTree
{
    Token  token;
    string name;
    SyntaxTree[] children;
    string[string] attributes;

    @property bool isLeaf() const { return children.empty; }
}

auto parse_into_parse_tree(in string input, in TokenMap token_map, in RuleMap rule_map, in string start_rule)
{
    auto token_stream = input.tokenize(token_map);
    auto parse_tree   = rule_map.match(start_rule, token_stream);

    if (parse_tree.isNull)
        throw new Exception("Couldn't parse!");

    return parse_tree.get;
}

auto tokenize(in string input, in TokenMap token_map)
{
    string[] wild_tokens;
    size_t cur_string_start;

    foreach (ii, immutable c; input)
    {
        import std.ascii : isWhite;
        if (isWhite(c))
        {
            if (cur_string_start != 0)
            {
                wild_tokens ~= input[cur_string_start..ii];
            }
            cur_string_start = 0;
            continue;
        }

        if (!token_map.get([c], "").empty)
        {
            if (cur_string_start != 0)
            {
                wild_tokens ~= input[cur_string_start..ii];
            }

            wild_tokens ~= [input[ii]];
            cur_string_start = 0;
            continue;
        }

        if (cur_string_start == 0)
        {
            cur_string_start = ii;
        }
    }

    auto map_tokens(in string value)
    {
        auto name = token_map.get(value, "");
        if (!name.empty)
            return Token(name, value);

        // TODO: This stuff is still specific for the grammar parser
        if (value.count("'") == 2)
            return Token("String", value);

        return Token("SymbolName", value);
    }

    return wild_tokens.map!map_tokens;
}

Nullable!ParseTree match(TokenRange)(in RuleMap rule_map, string rule_name, TokenRange tokens, size_t level = 0)
    if (isInputRange!TokenRange && is(ElementType!TokenRange == Token))
{
    dbg(level, "Rule: ", rule_name);
    alias Return = typeof(return);

    if (tokens.empty)
        return Return();

    auto token_0 = tokens.front;

    import std.string;
    dbg(level, (" Token name: " ~ token_0.name ~ ";").leftJustify(40) ~ "Token value: \"", token_0.value, "\"");

    if (token_0.name == rule_name)
    {
        dbg(level, " Matched token: ", rule_name);
        return cast(Return) ParseTree(token_0, rule_name, []);
    }

    foreach (expansion; rule_map.get(rule_name, []))
    {
        auto remaining_tokens = tokens;
        ParseTree[] matched_rules;
        dbg(level, " Expansion: ", expansion);

        bool loop_terminated_early;

        foreach (subrule; expansion.split)
        {
            dbg(level, "  Subrule: ", subrule);

            auto matched = rule_map.match(subrule, remaining_tokens, level + 1);
            if (matched.isNull)
            {
                loop_terminated_early = true;
                break;
            }
            matched_rules ~= matched.get;
            remaining_tokens = remaining_tokens[matched.get.count_tokens..$];
        }
        if (!loop_terminated_early)
        {
            return cast(Return) ParseTree(token_0, rule_name, matched_rules);
        }
    }

    return Return();
}

void dbg(size_t level, string[] s ...)
{
    import std.stdio;
    "    -   ".repeat(level).join.write;
    s.join.writeln;
}

// Annoying helper functions

string render(ParseTree tree, uint level = 0)
{
    import std.string;
    string appender;

    auto indent(uint level)
    {
        return "    ".repeat(level).join;
    }

    appender ~= indent(level);
    appender ~= tree.rule_name.leftJustify(15) ~ " ";
    if (tree.isLeaf)
        appender ~= tree.value.value;
    appender  = appender.stripRight;
    appender ~= "\n";

    auto ch = tree.children.map!(tr => tr.render(level + 1)).join();
    appender ~= ch;

    return appender;
}
