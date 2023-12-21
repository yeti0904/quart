module quart.backends.rm86;

import std.format;
import quart.compiler;

private struct Word {
	bool   builtIn;
	string assembly;
}

class BackendRM86 : CompilerBackend {
	Word[string] words;
	size_t       statements;

	this() {
		words["+"] = Word(
			true,
			"sub si, 2\n" ~
			"mov bx, [si]\n" ~
			"sub si, 2\n" ~
			"mov ax, [si]\n" ~
			"add ax, bx\n" ~
			"mov [si], ax\n" ~
			"add si, 2\n"
		);
		words["="] = Word(
			true,
			"sub si, 2\n" ~
			"mov bx, [si]\n" ~
			"sub si, 2\n" ~
			"mov ax, [si]\n" ~
			"cmp ax, bx\n" ~
			"mov ax, 0\n" ~
			"sete al, \n" ~
			"mov [si], ax\n" ~
			"add si, 2\n"
		);
		words["emit"] = Word(
			true,
			"sub si, 2\n" ~
			"mov ax, [si]\n" ~
			"mov ah, 0x0E\n" ~
			"int 0x10\n"
		);
	}

	override string Init() {
		return "mov si, __end\nmov ax, cs\nmov ds, ax\n";
	}

	override string Finalise() {
		return "ret\n__end: times 1024 dw 0\n";
	}

	override string CompileWord(WordNode node) {
		if (node.word !in words) {
			Error("No such word '%s'", node.word);
		}

		auto word = words[node.word];

		if (word.builtIn) {
			return word.assembly;
		}
		else {
			return format("call __func__%s\n", node.word);
		}
	}

	override string CompileInteger(IntegerNode node) {
		return format(
			"mov [si], word %d\n" ~
			"add si, 2\n", node.value
		);
	}

	override string CompileWordDef(WordDefNode node) {
		words[node.name] = Word(false);

		string ret = format("jmp __func_end__%s\n__func__%s:\n", node.name, node.name);

		foreach (ref inode ; node.contents) {
			ret ~= compiler.Compile(inode);
		}

		return ret ~ format("ret\n__func_end__%s:\n", node.name);
	}

	override string CompileIf(IfNode node) {
		++ statements;
		size_t statement = statements;

		string ret =
			"sub si, 2\n" ~
			"mov ax, [si]\n" ~
			"cmp ax, 0\n" ~
			format("je __statement_end_%d\n", statement);

		foreach (ref inode ; node.contents) {
			ret ~= compiler.Compile(inode);
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
	
	override string CompileVariable(VariableNode) {
		return "";
	}
	
	override string CompileArray(ArrayNode) {
		return "";
	}
	
	override string CompileString(StringNode) {
		return "";
	}
}
