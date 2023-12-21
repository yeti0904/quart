module quart.app;

import std.utf;
import std.file;
import std.array;
import std.stdio;
import quart.lexer;
import quart.parser;
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
	"    -i : Interpret the given file",
	"    -c : Compile the given file",
	"    -r : Opens a REPL (no input file required)",
	"    -t <TARGET> : Set target architecture (Available: y16)"
];

int main(string[] args) {
	auto   mode = AppMode.None;
	string inFile;
	string arch = "y16";

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
				case "-t": {
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
			parser.Parse();
			
			env.InterpretNodes(parser.ast);
			return 0;
		}
		case AppMode.Compile: {
			stderr.writeln("Compiler not implemented yet");
			return 1;
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
				parser.Parse();

				env.InterpretNodes(parser.ast);
				writeln("\nok");
			}
		}
	}
}
