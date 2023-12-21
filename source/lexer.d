module quart.lexer;

import std.string;

enum TokenType {
	Null,
	Word,
	Integer,
	String
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
	bool    inString;

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

			if (inString) {
				switch (code[i]) {
					case '"': {
						inString = false;
						AddToken(TokenType.String);
						break;
					}
					default: reading ~= code[i];
				}
			}
			else {
				switch (code[i]) {
					case '#': {
						while ((i < code.length) && (code[i] != '\n')) {
							++ i;

							if (code[i] == '\n') {
								++ line;
								col = 0;
							}
							else {
								++ col;
							}
						}
						break;
					}
					case '"': {
						AddReading();
						inString = true;
						break;
					}
					case '\t':
					case '\n':
					case ' ': {
						AddReading();
						break;
					}
					default: reading ~= code[i];
				}
			}
		}

		AddReading();
	}
}
