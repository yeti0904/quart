module quart.vm.builtins;

import std.stdio;
import std.string;
import quart.util;
import quart.vm.vm;
import quart.parser;
import quart.vm.compiler;

WordDef[string] GetVMBuiltins() {
	WordDef[string] ret;

	// special words
	ret["execute"] = WordDef((VM vm, Instruction inst) {
		auto oldExecuting = vm.executing;
		vm.executing      = inst.data.instArray;
		vm.ExecuteInsts(inst.data.instArray);
		vm.executing = oldExecuting;
	});
	ret["recurse"] = WordDef((VM vm, Instruction inst) {
		vm.ExecuteInsts(vm.executing);
	});
	ret["push_int"] = WordDef((VM vm, Instruction inst) {
		vm.Push(inst.data.integer);
	});
	ret["push_string"] = WordDef((VM vm, Instruction inst) {
		vm.Push(cast(long) inst.data.str.idup.toStringz());
	});
	ret["no_op"] = WordDef((VM vm, Instruction inst) {
		
	});
	ret["if"] = WordDef((VM vm, Instruction inst) {
		if (vm.Pop() != 0) {
			vm.ExecuteInsts(inst.data.instArray);
			vm.Push(0);
		}
		else {
			vm.Push(1);
		}
	});
	ret["else"] = WordDef((VM vm, Instruction inst) {
		if (vm.Pop() != 0) {
			vm.ExecuteInsts(inst.data.instArray);
		}
	});
	ret["while"] = WordDef((VM vm, Instruction inst) {
		do {
			vm.ExecuteInsts(inst.data.instArray);
		} while(vm.Pop() != 0);
	});

	// primitive words
	ret["+"] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs + rhs);
	});
	ret["-"] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs - rhs);
	});
	ret["*"] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs * rhs);
	});
	ret["/"] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs / rhs);
	});
	ret["%"] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs % rhs);
	});
	ret["="] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs == rhs? -1 : 0);
	});
	ret[">"] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs > rhs? -1 : 0);
	});
	ret["<"] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs < rhs? -1 : 0);
	});
	ret[">="] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs >= rhs? -1 : 0);
	});
	ret["<="] = WordDef((VM vm, Instruction) {
		auto rhs = vm.Pop();
		auto lhs = vm.Pop();
		vm.Push(lhs <= rhs? -1 : 0);
	});
	ret["emit"] = WordDef((VM vm, Instruction) {
		writef("%c", cast(char) vm.Pop());
	});
	ret["dup"] = WordDef((VM vm, Instruction) {
		vm.Push(vm.Top());
	});
	ret["@"] = WordDef((VM vm, Instruction) {
		vm.Push(*(cast(long*) vm.Pop()));
	});
	ret["!"] = WordDef((VM vm, Instruction) {
		// TODO: is this guaranteed to run left to right
		*(cast(long*) vm.Pop()) = vm.Pop();
	});
	ret["C@"] = WordDef((VM vm, Instruction) {
		vm.Push(*(cast(char*) vm.Pop()));
	});
	ret["C!"] = WordDef((VM vm, Instruction) {
		*(cast(char*) vm.Pop()) = cast(char) vm.Pop();
	});
	ret["bye"] = WordDef((VM vm, Instruction) {
		exit(0);
	});
	ret["exit"] = WordDef((VM vm, Instruction) {
		exit(cast(int) vm.Pop());
	});
	ret["cells"] = WordDef((VM vm, Instruction) {
		vm.Push(vm.Pop() * 8);
	});
	ret["swap"] = WordDef((VM vm, Instruction) {
		auto n2 = vm.Pop();
		auto n1 = vm.Pop();
		vm.Push(n2);
		vm.Push(n1);
	});
	ret["over"] = WordDef((VM vm, Instruction) {
		auto n2 = vm.Pop();
		auto n1 = vm.Pop();
		vm.Push(n1);
		vm.Push(n2);
		vm.Push(n1);
	});
	ret["rot"] = WordDef((VM vm, Instruction) {
		auto n3 = vm.Pop();
		auto n2 = vm.Pop();
		auto n1 = vm.Pop();
		vm.Push(n2);
		vm.Push(n3);
		vm.Push(n1);
	});
	ret["drop"] = WordDef((VM vm, Instruction) {
		vm.Pop();
	});

	return ret;
}
