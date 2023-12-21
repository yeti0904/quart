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
		size_t amount;
		foreach (key, value ; env.words) {
			writef("%s ", key);
			++ amount;
		}
		writeln();
		writefln("%d words", amount);
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
		// TODO: is this guaranteed to run left to right
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
	ret["r>"] = Word(true, (Environment env) {
		env.Push(env.PopReturn());
	});
	ret[">r"] = Word(true, (Environment env) {
		env.PushReturn(env.Pop());
	});
	ret["swap"] = Word(true, (Environment env) {
		auto n2 = env.Pop();
		auto n1 = env.Pop();
		env.Push(n2);
		env.Push(n1);
	});
	ret["over"] = Word(true, (Environment env) {
		auto n2 = env.Pop();
		auto n1 = env.Pop();
		env.Push(n1);
		env.Push(n2);
		env.Push(n1);
	});
	ret["rot"] = Word(true, (Environment env) {
		auto n3 = env.Pop();
		auto n2 = env.Pop();
		auto n1 = env.Pop();
		env.Push(n2);
		env.Push(n3);
		env.Push(n1);
	});
	ret["drop"] = Word(true, (Environment env) {
		env.Pop();
	});

	return ret;
}
