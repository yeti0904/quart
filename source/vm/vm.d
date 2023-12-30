module quart.vm.vm;

import std.stdio;
import std.format;
import std.range;
import quart.error;
import quart.parser;

union InstructionData {
	long          integer;
	string        str;
	Instruction[] instArray;
	Node          node;
}

alias InstructionCall = void function(VM, Instruction);

struct Instruction {
	InstructionCall func;
	InstructionData data;
	ErrorInfo       info;
}

class VMError : Exception {
	this() {
		super("", "", 0);
	}
}

class VM {
	long[]        dataStack;
	ErrorInfo     info;
	Instruction[] executing;

	this() {
		
	}

	void Error(Char, A...)(in Char[] fmt, A args) {
		ErrorBegin(info);
		stderr.writeln(format(fmt, args));
		throw new VMError();
	}

	void Push(long value) {
		dataStack ~= value;
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

	void Execute(Instruction inst) {
		info = inst.info;
		inst.func(this, inst);
	}

	void ExecuteInsts(Instruction[] insts) {
		foreach (ref inst ; insts) {
			Execute(inst);
		}
	}
}
