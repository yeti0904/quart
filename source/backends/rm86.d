module quart.backends.rm86;

import std.range;
import std.format;
import quart.util;
import quart.lexer;
import quart.parser;
import quart.compiler;

// tfw i java all over my code
private static const auto primitiveLib = cast(string) import("primitives/rm86.qrt");
// show this to a java programmer and they won't bat an eye

private struct Word {
	bool   builtIn;
	string assembly;
}

private struct Variable {
	size_t offset;
	size_t size;
}

class BackendRM86 : CompilerBackend {
	Word[string]       words;
	size_t             statements;
	Variable[string][] variables;

	this() {
		variables ~= new Variable[string];
	}

	string CompileEndScope() {
		size_t scopeSize;

		foreach (key, ref value ; variables[$ - 1]) {
			scopeSize += value.size;
		}

		return format("add sp, %d\n", scopeSize);
	}

	override string Init() {
		string ret = "mov si, __end\nmov ax, cs\nmov ds, ax\n";

		// compile primitive library
		Node[] primAST;
		try {
			primAST = ParseCode("<prim_rm86>", primitiveLib);
		}
		catch (ParserError) throw new CompilerError();

		foreach (ref node ; primAST) {
			ret ~= compiler.Compile(node);
		}

		return ret;
	}

	override string Finalise() {
		return CompileEndScope() ~ "ret\n__end: times 1024 dw 0\n";
	}

	override string CompileWord(WordNode node) {
		if (node.word in words) {
			auto word = words[node.word];

			if (word.builtIn) {
				return word.assembly;
			}
			else {
				auto labelName = FixLabel(node.word);
				return format("call __func__%s\n", labelName);
			}
		}
		else if (node.word in variables[$ - 1]) {
			auto var = variables[$ - 1][node.word];
			return
				"mov ax, sp\n" ~
				format("add ax, %d\n", var.offset) ~
				"mov [si], ax\n" ~
				"add si, 2\n";
		}
		else {
			Error("Unrecognised word '%s'", node.word);
			return "";
		}
	}

	override string CompileInteger(IntegerNode node) {
		return format(
			"mov [si], word %d\n" ~
			"add si, 2\n", node.value
		);
	}

	override string CompileWordDef(WordDefNode node) {
		variables ~= new Variable[string];
	
		words[node.name] = Word(false);

		auto labelName = FixLabel(node.name);
		string ret = format("jmp __func_end__%s\n__func__%s:\n", labelName, labelName);

		foreach (ref inode ; node.contents) {
			ret ~= compiler.Compile(inode);
		}

		variables = variables[0 .. $ - 1];

		return ret ~ CompileEndScope() ~ format("ret\n__func_end__%s:\n", labelName);
	}

	override string CompileIf(IfNode node) {
		++ statements;
		size_t statement = statements;

		string ret =
			"sub si, 2\n" ~
			"mov ax, [si]\n" ~
			"cmp ax, 0\n" ~
			format("je __statement_else_%d\n", statement);

		foreach (ref inode ; node.contents) {
			ret ~= compiler.Compile(inode);
		}
		ret ~= format("jmp __statement_end_%d\n", statement);
		ret ~= format("__statement_else_%d:\n", statement);

		if (!node.elseBlock.empty) {
			foreach (ref inode ; node.elseBlock) {
				ret ~= compiler.Compile(inode);
			}
		}

		return ret ~ format("__statement_end_%d:\n", statement);
	}
	
	override string CompileWhile(WhileNode node) {
		++ statements;
		size_t statement = statements;

		string ret = format("__statement_%d:\n", statement);

		foreach (ref inode ; node.contents) {
			ret ~= compiler.Compile(inode);
		}

		ret ~=
			"sub si, 2\n" ~
			"mov ax, [si]\n" ~
			"cmp ax, 0\n" ~
			format("jne __statement_%d\n", statement);
		return ret;
	}
	
	override string CompileVariable(VariableNode node) {
		foreach (key, ref value ; variables[$ - 1]) {
			value.offset += 2;
		}

		variables[$ - 1][node.name] = Variable(0, 2);
		return "push word 0\n";
	}
	
	override string CompileArray(ArrayNode node) {
		foreach (key, ref value ; variables[$ - 1]) {
			value.offset += node.size * 2;
		}

		variables[$ - 1][node.name] = Variable(0, node.size);
		return format("sub sp, %d", node.size * 2);
	}
	
	override string CompileString(StringNode node) { // TODO
		assert(0);
	}

	override string CompileBytes(BytesNode node) { // TODO
		assert(0);
	}

	override string CompileAsm(AsmNode node) {
		return node.contents ~ '\n';
	}
}
