module quart.compiler;

import std.stdio;
import std.format;
import quart.error;

public import quart.parser;

class CompilerError : Exception {
	this() {
		super("", "", 0);
	}
}

class CompilerBackend {
	Compiler compiler;
	Node     compiling;

	final void Error(Char, A...)(in Char[] fmt, A args) {
		ErrorBegin(compiling.info);
		stderr.writeln(format(fmt, args));
		throw new CompilerError();
	}

	abstract string Init();
	abstract string Finalise();
	abstract string CompileWord(WordNode);
	abstract string CompileInteger(IntegerNode);
	abstract string CompileWordDef(WordDefNode);
	abstract string CompileIf(IfNode);
	abstract string CompileWhile(WhileNode);
	abstract string CompileVariable(VariableNode);
	abstract string CompileArray(ArrayNode);
	abstract string CompileString(StringNode);
	abstract string CompileBytes(BytesNode);
	abstract string CompileAsm(AsmNode);
}

class Compiler {
	CompilerBackend backend;

	string Compile(Node node) {
		backend.compiling = node;
		
		switch (node.type) {
			case NodeType.Word: {
				return backend.CompileWord(cast(WordNode) node);
			}
			case NodeType.Integer: {
				return backend.CompileInteger(cast(IntegerNode) node);
			}
			case NodeType.WordDef: {
				return backend.CompileWordDef(cast(WordDefNode) node);
			}
			case NodeType.If: {
				return backend.CompileIf(cast(IfNode) node);
			}
			case NodeType.While: {
				return backend.CompileWhile(cast(WhileNode) node);
			}
			case NodeType.Variable:{
				return backend.CompileVariable(cast(VariableNode) node);
			}
			case NodeType.Array: {
				return backend.CompileArray(cast(ArrayNode) node);
			}
			case NodeType.String: {
				return backend.CompileString(cast(StringNode) node);
			}
			case NodeType.Asm: {
				return backend.CompileAsm(cast(AsmNode) node);
			}
			default: assert(0);
		}
	}

	string CompileProgram(Node[] nodes) {
		backend.compiler = this;
		string ret       = backend.Init();

		foreach (ref node ; nodes) {
			ret ~= Compile(node);
		}

		return ret ~ backend.Finalise();
	}
}
