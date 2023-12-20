module quart.interpreter.environment;

import std.range;
import std.stdio;
import std.format;
import quart.util;
import quart.error;
import quart.parser;
import quart.interpreter.builtins;

struct Word {
	bool                       builtIn;
	void function(Environment) func;
	Node[]                     def;
}

class Environment {
	Word[string]    words;
	void*[string][] variables;
	long[]          dataStack;
	long[]          callStack;
	ErrorInfo       info;

	this() {
		words      = GetBuiltIns();
		variables ~= new void*[string];
	}

	bool VariableExists(string name) {
		return (name in variables[0]) || (name in variables[$ - 1]);
	}

	void* GetVariable(string name) {
		if (name in variables[$ - 1]) {
			return variables[$ - 1][name];
		}

		return variables[0][name];
	}

	void Error(Char, A...)(in Char[] fmt, A args) {
		ErrorBegin(info);
		stderr.writeln(format(fmt, args));
		exit(1);
	}

	long Pop() {
		if (dataStack.empty) {
			Error("Stack underflow");
		}
	
		auto ret  = dataStack[$ - 1];
		dataStack = dataStack[0 .. $ - 1];
		return ret;
	}

	long Top() {
		if (dataStack.empty) {
			Error("Stack underflow");
		}

		return dataStack[$ - 1];
	}

	void Push(long value) {
		dataStack ~= value;
	}

	void InterpretNode(Node pnode) {
		info = pnode.info;

		switch (pnode.type) {
			case NodeType.Word: {
				auto node = cast(WordNode) pnode;

				if (node.word in words) {
					auto word = words[node.word];

					if (word.builtIn) {
						word.func(this);
					}
					else {
						InterpretNodes(word.def);
					}	
				}
				else if (VariableExists(node.word)) {
					auto var = GetVariable(node.word);

					Push(cast(long) var);
				}
				else {
					Error("Unrecognised word '%s'", node.word);
				}
				break;
			}
			case NodeType.Integer: {
				auto node = cast(IntegerNode) pnode;

				dataStack ~= node.value;
				break;
			}
			case NodeType.WordDef: {
				auto node        = cast(WordDefNode) pnode;
				words[node.name] = Word(false, null, node.contents);
				break;
			}
			case NodeType.If: {
				auto node = cast(IfNode) pnode;

				if (Pop() != 0) {
					InterpretNodes(node.contents);
				}
				break;
			}
			case NodeType.While: {
				auto node = cast(WhileNode) pnode;

				do {
					InterpretNodes(node.contents);
					info = node.info;
				} while(Pop() != 0);
				break;
			}
			case NodeType.Variable: {
				auto node = cast(VariableNode) pnode;
				variables[$ - 1][node.name] = new long;
				break;
			}
			case NodeType.Array: {
				auto node = cast(ArrayNode) pnode;
				variables[$ - 1][node.name] = (new long[](node.size)).ptr;
				break;
			}
			default: assert(0);
		}
	}

	void InterpretNodes(Node[] nodes) {
		foreach (ref node ; nodes) {
			InterpretNode(node);
		}
	}
}
