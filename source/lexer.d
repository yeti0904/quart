module quart.lexer;

import std.string;

enum TokenType {
	Null,
	Word,
	Integer
}

struct Token {
	TokenType type;
	string    contents;
	string    file;
	size_t    line;
	size_t    col;
}

class Lexer {
	Token[] tokens;
	string  code;
	string  reading;
	size_t  line;
	size_t  col;
	string  file;

	this() {
		
	}

	void AddToken(TokenType type) {
		tokens  ~= Token(type, reading, file, line, col);
		reading  = "";
	}

	void AddReading() {
		if (reading == "") {
			return;
		}
		else if (reading.isNumeric()) {
			AddToken(TokenType.Integer);
		}
		else {
			AddToken(TokenType.Word);
		}
	}

	void Lex() {
		for (size_t i = 0; i < code.length; ++ i) {
			if (code[i] == '\n') {
				++ line;
				col = 0;
			}
			else {
				++ col;
			}

			switch (code[i]) {
				case '\t':
				case '\n':
				case ' ': {
					AddReading();
					break;
				}
				default: reading ~= code[i];
			}
		}

		AddReading();
	}
}
