module quart.app;

import std.utf;
import std.file;
import std.array;
import std.stdio;
import quart.lexer;
import quart.parser;
import quart.compiler;
import quart.backends.rm86;
import quart.interpreter.environment;

enum AppMode {
	None,
	Interpret,
	Compile,
	Repl
}

const string[] appUsage = [
	"Usage:",
	"    %s <FILE> <FLAGS>",
	"Flags:",
	"    -i           : Interpret the given file",
	"    -c           : Compile the given file",
	"    -r           : Opens a REPL (no input file required)",
	"    -b <BACKEND> : Set compiler backend (Available: rm86)"
];

int main(string[] args) {
	auto   mode = AppMode.None;
	string inFile;
	string arch = "rm86";

	if (args.length == 0) {
		stderr.writeln("what");
		return 1;
	}
	if (args.length == 1) {
		writefln(appUsage.join("\n"), args[0]);
		return 1;
	}

	for (size_t i = 1; i < args.length; ++ i) {
		if (args[i][0] == '-') {
			switch (args[i]) {
				case "-i": {
					mode = AppMode.Interpret; // TODO: error if set twice
					break;
				}
				case "-c": {
					mode = AppMode.Compile;
					break;
				}
				case "-r": {
					mode = AppMode.Repl;
					break;
				}
				case "-b": {
					++ i; // TODO: error if no parameter
					arch = args[i];
					break;
				}
				default: {
					stderr.writefln("Error: Unknown flag '%s'", args[i]);
					return 1;
				}
			}
		}
		else {
			if (inFile != "") {
				stderr.writeln("Error: input file set twice");
				return 1;
			}
			inFile = args[i];
		}
	}

	auto lexer  = new Lexer();
	auto parser = new Parser();

	final switch (mode) {
		case AppMode.None: {
			writeln(appUsage.join("\n"), args[0]);
			return 0;
		}
		case AppMode.Interpret: {
			auto env = new Environment();

			lexer.file = inFile;

			try {
				lexer.code = readText(inFile);
			}
			catch (FileException e) {
				stderr.writefln("Error reading file: %s", e.msg);
				return 1;
			}
			catch (UTFException e) {
				stderr.writefln("Error reading file: %s", e.msg);
				return 1;
			}

			lexer.Lex();
			parser.tokens = lexer.tokens;

			try {
				parser.Parse();
			}
			catch (ParserError) {
				return 1;
			}

			try {
				env.InterpretNodes(parser.ast);
			}
			catch (EnvironmentError) {
				return 1;
			}
			return 0;
		}
		case AppMode.Compile: {
			lexer.file = inFile;

			try {
				lexer.code = readText(inFile);
			}
			catch (FileException e) {
				stderr.writefln("Error reading file: %s", e.msg);
				return 1;
			}
			catch (UTFException e) {
				stderr.writefln("Error reading file: %s", e.msg);
				return 1;
			}

			lexer.Lex();
			parser.tokens = lexer.tokens;

			try {
				parser.Parse();
			}
			catch (ParserError) {
				return 1;
			}

			auto compiler = new Compiler();

			switch (arch) {
				case "rm86": {
					compiler.backend = new BackendRM86();
					break;
				}
				default: {
					stderr.writefln("Error: no such backend '%s'", arch);
					return 1;
				}
			}

			string res;

			try {
				res = compiler.CompileProgram(parser.ast);
			}
			catch (CompilerError) {
				return 1;
			}
			
			writeln(res);
			return 0;
		}
		case AppMode.Repl: {
			writeln("Quart REPL");
			auto env = new Environment();

			while (true) {
				lexer  = new Lexer();
				parser = new Parser();

				writef("> ");
				lexer.code = readln();
				lexer.file = "<stdin>";

				lexer.Lex();
				parser.tokens = lexer.tokens;

				try {
					parser.Parse();
				}
				catch (ParserError) {
					continue;
				}

				try {
					env.InterpretNodes(parser.ast);
				}
				catch (EnvironmentError) {
					continue;
				}
				
				writeln("\nok");
			}
		}
	}
}
