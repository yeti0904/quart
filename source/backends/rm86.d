module quart.backends.rm86;

import std.range;
import std.format;
import quart.compiler;

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
		words["@"] = Word(
			true,
			"sub si, 2\n" ~
			"mov di, [si]\n" ~
			"mov bx, [di]\n" ~
			"mov [si], bx\n" ~
			"add si, 2\n"
		);
		words["!"] = Word(
			true,
			"sub si, 2\n" ~
			"mov di, [si]\n" ~
			"sub si, 2\n" ~
			"mov bx, [si]\n" ~
			"mov [di], bx\n"
		);
	}

	string CompileEndScope() {
		size_t scopeSize;

		foreach (key, ref value ; variables[$ - 1]) {
			scopeSize += value.size;
		}

		return format("add sp, %d\n", scopeSize);
	}

	override string Init() {
		return "mov si, __end\nmov ax, cs\nmov ds, ax\n";
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
				return format("call __func__%s\n", node.word);
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

		string ret = format("jmp __func_end__%s\n__func__%s:\n", node.name, node.name);

		foreach (ref inode ; node.contents) {
			ret ~= compiler.Compile(inode);
		}

		variables = variables[0 .. $ - 1];

		return ret ~ CompileEndScope() ~ format("ret\n__func_end__%s:\n", node.name);
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
	
	override string CompileString(StringNode) { // TODO
		return "";
	}
}
