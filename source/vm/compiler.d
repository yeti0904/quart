module quart.vm.compiler;

import std.stdio;
import std.range;
import std.format;
import quart.util;
import quart.error;
import quart.vm.vm;
import quart.parser;
import quart.vm.builtins;

private static const auto stdLib = cast(string) import("std/std.qrt");

struct WordDef {
	bool            builtIn;
	InstructionCall call;
	Instruction[]   def;

	this(InstructionCall pcall) {
		builtIn = true;
		call    = pcall;
	}

	this(Instruction[] pdef) {
		builtIn = false;
		def     = pdef;
	}
}

class VMCompilerError : Exception {
	this() {
		super("", "", 0);
	}
}

class VMCompiler {
	WordDef[string] words;
	void*[string][] variables;

	this() {
		words = GetVMBuiltins();
	}

	bool VariableExists(string name) {
		return (name in variables[0]) || (name in variables[$ - 1]);
	}

	void Error(Char, A...)(ErrorInfo info, in Char[] fmt, A args) {
		ErrorBegin(info);
		stderr.writeln(format(fmt, args));
		throw new VMCompilerError();
	}

	Instruction[] Compile(Node pnode) {
		switch (pnode.type) {
			case NodeType.Word: {
				auto node = cast(WordNode) pnode;

				if (node.word in words) {
					auto word = words[node.word];

					if (word.builtIn) {
						Instruction ret;
						ret.func = word.call;
						ret.info = node.info;
						return [ret];
					}
					else {
						Instruction ret;
						ret.func           = words["execute"].call;
						ret.data.instArray = word.def;
						ret.info           = node.info;
						return [ret];
					}
				}
				else if (VariableExists(node.word)) {
					Instruction ret;
					ret.func = words["push_int"].call;
					ret.info = node.info;
					
					if (node.word in variables[$ - 1]) {
						ret.data.integer = cast(long) variables[$ - 1][node.word];
					}
					else {
						ret.data.integer = cast(long) variables[0][node.word];
					}
					return [ret];
				}
				else {
					Error(node.info, "Unrecognised word '%s'", node.word);
				}
				return [];
			}
			case NodeType.Integer: {
				auto node = cast(IntegerNode) pnode;

				Instruction ret;
				ret.func         = words["push_int"].call;
				ret.data.integer = node.value;
				ret.info         = node.info;
				return [ret];
			}
			case NodeType.WordDef: {
				auto node = cast(WordDefNode) pnode;

				if (node.name in words) {
					Error(node.info, "Word '%s' already defined", node.name);
				}

				if (variables.length > 1) {
					Error(node.info, "Nested word definitions are not allowed");
				}

				words[node.name] = words["recurse"];

				variables        ~= new void*[string];
				words[node.name]  = WordDef(CompileNodes(node.contents));
				variables         = variables[0 .. $ - 1];
				return [];
			}
			case NodeType.If: {
				auto node = cast(IfNode) pnode;

				Instruction[] ret;

				Instruction ifBlock;
				ifBlock.func           = words["if"].call;
				ifBlock.data.instArray = CompileNodes(node.contents);
				ifBlock.info           = node.info;
				ret ~= ifBlock;

				if (node.elseBlock.empty) {
					Instruction elseBlock;
					elseBlock.func = words["drop"].call;
					elseBlock.info = node.info;
					ret ~= elseBlock;
				}
				else {
					Instruction elseBlock;
					elseBlock.func           = words["else"].call;
					elseBlock.data.instArray = CompileNodes(node.elseBlock);
					elseBlock.info           = node.info;
					ret ~= elseBlock;
				}
				
				return ret;
			}
			case NodeType.While: {
				auto node = cast(WhileNode) pnode;

				Instruction ret;
				ret.func           = words["while"].call;
				ret.data.instArray = CompileNodes(node.contents);
				ret.info           = node.info;
				return [ret];
			}
			case NodeType.Variable: {
				auto node = cast(VariableNode) pnode;

				if (node.name in words) {
					Error(
						node.info, "Variable name '%s' already used for a word",
						node.name
					);
				}

				if (node.name in variables[$ - 1]) {
					Error(
						node.info, "Variable name '%s' already used in this scope",
						node.name
					);
				}

				variables[$ - 1][node.name] = new long;
				return [];
			}
			case NodeType.Array: {
				auto node = cast(ArrayNode) pnode;

				if (node.name in words) {
					Error(
						node.info, "Variable name '%s' already used for a word",
						node.name
					);
				}

				if (node.name in variables[$ - 1]) {
					Error(
						node.info, "Variable name '%s' already used in this scope",
						node.name
					);
				}

				variables[$ - 1][node.name] = (new long[](node.size)).ptr;
				return [];
			}
			case NodeType.String: {
				auto node = cast(StringNode) pnode;

				Instruction ret;
				ret.func     = words["push_string"].call;
				ret.data.str = node.value;
				ret.info     = node.info;
				return [ret];
			}
			case NodeType.Bytes: {
				auto node = cast(BytesNode) pnode;

				if (node.name in words) {
					Error(
						node.info, "Variable name '%s' already used for a word",
						node.name
					);
				}

				if (node.name in variables[$ - 1]) {
					Error(
						node.info, "Variable name '%s' already used in this scope",
						node.name
					);
				}

				variables[$ - 1][node.name] = (new ubyte[](node.size)).ptr;
				return [];
			}
			case NodeType.Asm: {
				Error(pnode.info, "Inline assembly not available in the interpreter");
				return [];
			}
			default: assert(0);
		}
	}

	Instruction[] CompileNodes(Node[] nodes) {
		Instruction[] ret;

		foreach (ref inode ; nodes) {
			ret ~= Compile(inode);
		}

		return ret;
	}
	
	Instruction[] CompileProgram(Node[] nodes) {
		Instruction[] ret;

		variables = [new void*[string]];

		// compile standard library
		Node[] stdNodes;
		try {
			stdNodes = ParseCode("<std lib>", stdLib);
		}
		catch (ParserError) throw new VMCompilerError();

		ret ~= CompileNodes(stdNodes);
		ret ~= CompileNodes(nodes);

		return ret;
	}
}
