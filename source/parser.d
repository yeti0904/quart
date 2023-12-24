module quart.parser;

import std.conv;
import std.stdio;
import std.format;
import std.algorithm;
import quart.util;
import quart.lexer;
import quart.error;

enum NodeType {
	Null,
	Word,
	Integer,
	WordDef,
	If,
	While,
	Variable,
	Array,
	String,
	Bytes,
	Asm
}

class Node {
	NodeType  type;
	ErrorInfo info;
}

class WordNode : Node {
	string word;

	this(ErrorInfo pinfo) {
		type = NodeType.Word;
		info = pinfo;
	}

	override string toString() {
		return word;
	}
}

class IntegerNode : Node {
	long value;

	this(ErrorInfo pinfo) {
		type = NodeType.Integer;
		info = pinfo;
	}

	override string toString() {
		return text(value);
	}
}

class BodyNode : Node {
	Node[] contents;
}

class WordDefNode : BodyNode {
	string name;

	this(ErrorInfo pinfo) {
		type = NodeType.WordDef;
		info = pinfo;
	}

	override string toString() {
		string ret = format(": %s ", name);

		foreach (ref node ; contents) {
			ret ~= node.toString() ~ ' ';
		}

		return ret ~ ';';
	}
}

class IfNode : BodyNode {
	Node[] elseBlock;

	this(ErrorInfo pinfo) {
		type = NodeType.If;
		info = pinfo;
	}

	override string toString() {
		string ret = "if ";

		foreach (ref node ; contents) {
			ret ~= node.toString() ~ ' ';
		}

		return ret ~ "endif";
	}
}

class WhileNode : BodyNode {
	this(ErrorInfo pinfo) {
		type = NodeType.While;
		info = pinfo;
	}

	override string toString() {
		string ret = "begin ";

		foreach (ref node ; contents) {
			ret ~= node.toString() ~ ' ';
		}

		return ret ~ "while";
	}
}

class VariableNode : Node {
	string name;

	this(ErrorInfo pinfo) {
		type = NodeType.Variable;
		info = pinfo;
	}

	override string toString() {
		return format("variable %s", name);
	}
}

class ArrayNode : Node {
	string name;
	size_t size;

	this(ErrorInfo pinfo) {
		type = NodeType.Array;
		info = pinfo;
	}

	override string toString() {
		return format("array %s %d", name, size);
	}
}

class StringNode : Node {
	string value;

	this(ErrorInfo pinfo) {
		type = NodeType.String;
		info = pinfo;
	}

	override string toString() {
		return format("\"%s\"", value);
	}
}

class BytesNode : Node {
	string name;
	size_t size;

	this(ErrorInfo pinfo) {
		type = NodeType.Bytes;
		info = pinfo;
	}

	override string toString() {
		return format("array %s %d", name, size);
	}
}

class AsmNode : Node {
	string contents;

	this(ErrorInfo pinfo) {
		type = NodeType.Asm;
		info = pinfo;
	}

	override string toString() {
		return format("asm %s endasm", contents);
	}
}

class ParserError : Exception {
	this() {
		super("", "", 0);
	}
}

class Parser {
	Token[] tokens;
	size_t  i;
	Node[]  ast;

	this() {
		
	}

	ErrorInfo GetError() {
		return ErrorInfo(tokens[i].file, tokens[i].line, tokens[i].col);
	}

	void Next() {
		if (i == tokens.length - 1) {
			Error("Unexpected EOF");
		}

		++ i;
	}

	void Expect(TokenType type) {
		if (tokens[i].type != type) {
			Error("Expected %s, got %s", type, tokens[i].type);
		}
	}

	void Error(Char, A...)(in Char[] fmt, A args) {
		ErrorBegin(GetError());
		stderr.writeln(format(fmt, args));
		throw new ParserError();
	}

	Node[] ParseUntil(string word) {
		Node[] ret;

		while (true) {
			Next();

			if ((tokens[i].type == TokenType.Word) && (tokens[i].contents == word)) {
				break;
			}

			ret ~= ParseStatement();
		}

		return ret;
	}

	Node[] ParseUntilOne(string[] words, string* res) {
		Node[] ret;

		while (true) {
			Next();

			if (
				(tokens[i].type == TokenType.Word) &&
				words.canFind(tokens[i].contents)
			) {
				*res = tokens[i].contents;
				break;
			}

			ret ~= ParseStatement();
		}

		return ret;
	}

	Node ParseWordDef() {
		auto ret = new WordDefNode(GetError());

		Next();
		Expect(TokenType.Word);
		ret.name     = tokens[i].contents;
		ret.contents = ParseUntil(";");

		if (ret.name.canFind("__")) {
			Error("Word names can't have __ (double underscore) in them");
		}

		return ret;
	}

	Node ParseIf() {
		auto   ret = new IfNode(GetError());
		string res;
		ret.contents = ParseUntilOne(["endif", "else"], &res);

		if (res == "else") {
			ret.elseBlock = ParseUntil("endif");
		}
		
		return ret;
	}

	Node ParseWhile() {
		auto ret     = new WhileNode(GetError());
		ret.contents = ParseUntil("while");
		return ret;
	}

	Node ParseVariable() {
		auto ret = new VariableNode(GetError());
		Next();
		Expect(TokenType.Word);
		ret.name = tokens[i].contents;
		return ret;
	}

	Node ParseArray() {
		auto ret = new ArrayNode(GetError());
		Next();
		Expect(TokenType.Word);
		ret.name = tokens[i].contents;
		Next();
		Expect(TokenType.Integer);
		ret.size = parse!size_t(tokens[i].contents);
		return ret;
	}

	Node ParseBytes() {
		auto ret = new BytesNode(GetError());
		Next();
		Expect(TokenType.Word);
		ret.name = tokens[i].contents;
		Next();
		Expect(TokenType.Integer);
		ret.size = parse!size_t(tokens[i].contents);
		return ret;
	}

	Node ParseAsm() {
		auto ret = new AsmNode(GetError());

		Next();

		while (tokens[i].contents != "endasm") {
			if (tokens[i].contents == "\\") {
				ret.contents ~= '\n';
			}
			else {
				ret.contents ~= tokens[i].contents ~ ' ';
			}
			
			Next();
		}

		return ret;
	}

	Node ParseStatement() {
		switch (tokens[i].type) {
			case TokenType.Word: {
				switch (tokens[i].contents) {
					case ":":        return ParseWordDef();
					case "if":       return ParseIf();
					case "begin":    return ParseWhile();
					case "variable": return ParseVariable();
					case "array":    return ParseArray();
					case "bytes":    return ParseBytes();
					case "asm":      return ParseAsm();
					default: {
						auto ret = new WordNode(GetError());
						ret.word = tokens[i].contents;
						return ret;
					}
				}
			}
			case TokenType.Integer: {
				auto ret  = new IntegerNode(GetError());
				ret.value = parse!long(tokens[i].contents);
				return ret;
			}
			case TokenType.String: {
				auto ret  = new StringNode(GetError());
				ret.value = tokens[i].contents;
				return ret;
			}
			default: assert(0);
		}
	}

	void Parse() {
		for (i = 0; i < tokens.length; ++ i) {
			ast ~= ParseStatement();
		}
	}
}
