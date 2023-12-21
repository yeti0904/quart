module quart.interpreter.builtins;

import std.stdio;
import std.string;
import quart.util;
import quart.interpreter.environment;

Word[string] GetBuiltIns() {
	Word[string] ret;

	ret["+"] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs + rhs);
	}, null);
	ret["-"] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs - rhs);
	}, null);
	ret["*"] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs * rhs);
	}, null);
	ret["/"] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs / rhs);
	}, null);
	ret["%"] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs % rhs);
	}, null);
	ret["."] = Word(true, (Environment env) {
		write(env.Pop());
	}, null);
	ret["="] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs == rhs? -1 : 0);
	});
	ret[">"] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs > rhs? -1 : 0);
	});
	ret["<"] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs < rhs? -1 : 0);
	});
	ret[">="] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs >= rhs? -1 : 0);
	});
	ret["<="] = Word(true, (Environment env) {
		auto rhs = env.Pop();
		auto lhs = env.Pop();
		env.Push(lhs <= rhs? -1 : 0);
	});
	ret["words"] = Word(true, (Environment env) {
		foreach (key, value ; env.words) {
			writef("%s ", key);
		}
		writeln();
	});
	ret["emit"] = Word(true, (Environment env) {
		writef("%c", cast(char) env.Pop());
	});
	ret["dup"] = Word(true, (Environment env) {
		env.Push(env.Top());
	});
	ret["@"] = Word(true, (Environment env) {
		env.Push(*(cast(long*) env.Pop()));
	});
	ret["!"] = Word(true, (Environment env) {
		*(cast(long*) env.Pop()) = env.Pop();
	});
	ret["C@"] = Word(true, (Environment env) {
		env.Push(*(cast(char*) env.Pop()));
	});
	ret["C!"] = Word(true, (Environment env) {
		*(cast(char*) env.Pop()) = cast(char) env.Pop();
	});
	ret["bye"] = Word(true, (Environment env) {
		exit(0);
	});
	ret["exit"] = Word(true, (Environment env) {
		exit(cast(int) env.Pop());
	});
	ret["type"] = Word(true, (Environment env) {
		writef("%s", (cast(char*) env.Pop()).fromStringz());
	});
	ret["cells"] = Word(true, (Environment env) {
		env.Push(env.Pop() * 8);
	});

	return ret;
}
