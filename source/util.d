module quart.util;

import quart.lexer;
import quart.parser;

public import core.stdc.stdlib : exit, malloc, free;

Node[] ParseCode(string file, string code) {
	auto lexer  = new Lexer();
	auto parser = new Parser();

	lexer.file = file;
	lexer.code = code;
	lexer.Lex();

	parser.tokens = lexer.tokens;
	parser.Parse();
	return parser.ast;
}

string FixLabel(string label) {
	string ret;

	foreach (ref ch ; label) {
		switch (ch) {
			case '!':  ret ~= "__exclam_mark__"; break;
			case '$':  ret ~= "__dollar_sign__"; break;
			case '%':  ret ~= "__percent__";     break;
			case '^':  ret ~= "__up_thing__";    break;
			case '&':  ret ~= "__ampersand__";   break;
			case '*':  ret ~= "__star__";        break;
			case '(':  ret ~= "__lparen__";      break; // L.
			case ')':  ret ~= "__rparen__";      break;
			case '`':  ret ~= "__backtick__";    break;
			case '|':  ret ~= "__pipe__";        break;
			case '\\': ret ~= "__backslash__";   break;
			case ',':  ret ~= "__comma__";       break;
			case '.':  ret ~= "__dot__";         break;
			case '<':  ret ~= "__left_thing__";  break;
			case '>':  ret ~= "__right_thing__"; break;
			case '/':  ret ~= "__slash__";       break;
			case '?':  ret ~= "__question_mark"; break;
			case ';':  ret ~= "__semicolon__";   break;
			case ':':  ret ~= "__colon__";       break;
			case '\'': ret ~= "__idk__";         break;
			case '@':  ret ~= "__at_symbol__";   break;
			case '#':  ret ~= "__hashtag__";     break;
			case '~':  ret ~= "__tilde__";       break; // which is a cool text editor
			case '[':  ret ~= "__lsquare__";     break; // L.
			case ']':  ret ~= "__rsquare__";     break;
			case '{':  ret ~= "__lcurly__";      break;
			case '}':  ret ~= "__rcurly__";      break;
			case '-':  ret ~= "__subtract__";    break;
			case '_':  ret ~= "__underscore__";  break;
			case '=':  ret ~= "__equals__";      break;
			case '+':  ret ~= "__plush__";       break;
			default:   ret ~= ch;
		}
	}

	return ret;
}
