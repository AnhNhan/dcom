
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
    auto wild_tokens_1 = input.split;
    typeof(wild_tokens_1) wild_tokens_2;
    foreach (w; wild_tokens_1)
    {
        // TODO: Generice these
        if (w.canFind(":"))
        {
            wild_tokens_2 ~= w[0..$-1];
            wild_tokens_2 ~= ":";
        }
        else if (w[0] == '@')
        {
            wild_tokens_2 ~= "@";
            wild_tokens_2 ~= w[1..$];
        }
        else
        {
            wild_tokens_2 ~= w;
        }
    }

    auto map_tokens(in string value)
    {
        auto name = token_map.get(value, "");
        if (!name.empty)
            return Token(name, value);

        if (value.count("'") == 2)
            return Token("String", value[1..$-1]);

        return Token("SymbolName", value);
    }

    return wild_tokens_2.map!map_tokens;
}

Nullable!ParseTree match(TokenRange)(in RuleMap rule_map, string rule_name, TokenRange tokens, size_t level = 0)
    if (isInputRange!TokenRange && is(ElementType!TokenRange == Token))
{
    alias Return = typeof(return);

    if (tokens.empty)
        return Return();

    auto token_0 = tokens.front;

    if (token_0.name == rule_name)
        return cast(Return) ParseTree(token_0, rule_name, []);

    foreach (expansion; rule_map.get(rule_name, []))
    {
        auto remaining_tokens = tokens;
        ParseTree[] matched_rules;
        bool loop_terminated_early;

        foreach (subrule; expansion.split)
        {
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
