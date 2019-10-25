module dud.sdlang2.lexer;

import std.ascii;
import std.array : appender, empty, front, popFront, popBack;
import std.algorithm.searching : startsWith;
import std.base64;
import std.conv : to;
import std.experimental.logger;
import std.format : format;
import std.typecons : Flag;
import std.stdio;

import dud.sdlang2.tokenmodule;
import dud.sdlang2.value;

struct Lexer {
	string input;

	size_t line;
	size_t column;

	Token cur;

	this(string input) @safe pure {
		this.input = input;
		this.line = 1;
		this.column = 1;
		this.buildToken();
	}

	private bool eatComment() @safe pure {
		if(this.input.startsWith("#") || this.input.startsWith("--")
				|| this.input.startsWith("//"))
		{
			while(!this.input.startsWith('\n')) {
				++this.column;
				this.input.popFront();
			}
			++this.line;
			this.column = 1;
			return true;
		} else if(this.input.startsWith("/*")) {
			while(!this.input.startsWith("*/")) {
				if(this.input.startsWith('\n')) {
					++this.line;
					this.column = 1;
				} else {
					++this.column;
				}
				this.input.popFront();
			}
			return true;
		}
		return false;
	}

	private void eatWhitespace() @safe pure {
		while(!this.input.empty) {
			if(this.eatComment()) {
				continue;
			} else if(this.input.front == ' ') {
				++this.column;
			} else if(this.input.front == '\t') {
				++this.column;
			} else {
				break;
			}
			this.input.popFront();
		}
	}

	private void singleCharToken(TokenType tt) @safe pure {
		this.cur = Token(tt, this.line, this.column);
		++this.column;
		this.input.popFront();
	}

	private void buildToken() @safe pure {
		this.eatWhitespace();

		if(this.input.empty) {
			this.cur = this.cur.type == TokenType.eof
				? Token(TokenType.undefined)
				: Token(TokenType.eof);
			return;
		}

		if(this.input.front == '{') {
			this.singleCharToken(TokenType.lcurly);
			return;
		} else if(this.input.front == '}') {
			this.singleCharToken(TokenType.rcurly);
			return;
		} else if(this.input.front == '\n') {
			this.singleCharToken(TokenType.eol);
			return;
		} else if(this.input.front == '=') {
			this.singleCharToken(TokenType.assign);
			return;
		} else if(this.input.front == ':') {
			this.singleCharToken(TokenType.colon);
			return;
		} else if(this.input.front == '\\') {
			this.singleCharToken(TokenType.backslash);
			return;
		} else if(this.input.front == ';') {
			this.singleCharToken(TokenType.semicolon);
			return;
		} else if(this.input.front == '[') {
			size_t l = this.line;
			size_t c = this.column;
			++this.column;
			this.input.popFront();

			size_t rbrack;
			while(rbrack < this.input.length && this.input[rbrack] != ']') {
				++rbrack;
				++this.column;
			}

			++this.column;

			string theData = this.input[0 .. rbrack];
			ubyte[] data = Base64.decode(theData);
			this.input = this.input[rbrack + 1 .. $];
			this.cur = Token(TokenType.value, Value(data), theData, l, c);
			return;
		} else if(this.input.startsWith("`")) {
			size_t l = this.line;
			size_t c = this.column;
			++this.column;
			this.input.popFront();

			auto app = appender!string();

			while(this.input.front != '`') {
				app.put(this.input.front);
				if(this.input.front == '\n') {
					++this.line;
					this.column = 1;
				} else {
					++this.column;
				}
				this.input.popFront();
			}

			assert(this.input.front == '`', this.input);
			this.input.popFront();
			this.cur = Token(TokenType.value, Value(app.data), app.data, l, c);
			return;
		} else if(this.input.front == '"') {
			size_t l = this.line;
			size_t c = this.column;
			++this.column;
			this.input.popFront();

			auto app = appender!string();

			while(!this.input.startsWith('"')) {
				if(this.input.length > 1 && this.input.front == '\\') {
					this.input.popFront();
					if(this.input.front == '"') {
						app.put('"');
						this.column += 2;
						this.input = this.input[2 .. $];
						continue;
					} else {
						while(this.input.front.isWhite()) {
							if(this.input.front == ' ') {
								++this.column;
							} else if(this.input.front == '\t') {
								++this.column;
							} else if(this.input.front == '\n') {
								++this.line;
								this.column = 1;
							}
							this.input.popFront();
						}
						continue;
					}
				} else {
					app.put(this.input.front);
					++this.column;
					this.input.popFront();
				}
			}
			assert(this.input.front == '"', this.input);
			this.input.popFront();
			++this.column;

			this.cur = Token(TokenType.value, Value(app.data), app.data, l, c);
			return;
		} else if(this.input.front == '-' || isDigit(this.input.front)) {
			size_t l = this.line;
			size_t c = this.column;

			size_t idx;
			if(this.input.front == '-') {
				++idx;
			}

			while(idx < this.input.length && isDigit(this.input[idx])) {
				++idx;
				++this.column;
			}

			string tmp = this.input[idx .. $];

			if(tmp.empty || isWhite(tmp.front) || tmp.front == '.'
					|| tmp.front == 'l' || tmp.front == 'L'
					|| tmp.front == 'f' || tmp.front == 'F')
			{
				parseNumber(idx, l, c);
				return;
			} else if(tmp.front == 'd' || tmp.front == 'D'
					|| tmp.front == ':')
			{
				parseDuration(idx, l, c);
				return;
			} else if(tmp.front == '/') {
				parseDate(idx, l, c);
				return;
			} else {
				assert(false, this.input);
			}
		} else if(isAlpha(this.input.front)) {
			size_t e;
			while(e < this.input.length &&
					( isAlphaNum(this.input[e]) || this.input[e] == '_'
					|| this.input[e] == '-' || this.input[e] == '.'
					|| this.input[e] == '$'
					)
				)
			{
				++e;
			}
			string str = this.input[0 .. e];
			switch(str) {
				case "null":
					this.cur = Token(TokenType.value, Value.init,
							str, this.line, this.column);
					break;
				case "on":
					goto case;
				case "true":
					this.cur = Token(TokenType.value, Value(true),
							str, this.line, this.column);
					break;
				case "off":
					goto case;
				case "false":
					this.cur = Token(TokenType.value, Value(false),
							str, this.line, this.column);
					break;
				default:
					this.cur = Token(TokenType.ident, Value(str), str,
							this.line, this.column);
					break;
			}
			this.column += e;
			this.input = this.input[e .. $];
			return;
		}
		assert(false, this.input);
	}

	void parseNumber(size_t idx, size_t l, size_t c) @safe pure {
		string prefix = this.input[0 .. idx];
		string tmp = this.input[idx .. $];
		if(tmp.empty) {
			this.cur = Token(TokenType.value, Value(to!int(prefix)), prefix,
				l, c);
			this.input = tmp;
		} else if(tmp.startsWith('L')
				|| tmp.startsWith('l'))
		{
			this.cur = Token(TokenType.value, Value(to!long(prefix)), prefix,
				l, c);
			this.input = tmp;
			this.input.popFront();
			++this.column;
		} else if(tmp.startsWith('F')
				|| tmp.startsWith('f'))
		{
			this.cur = Token(TokenType.value, Value(to!float(prefix)), prefix,
				l, c);
			this.input = tmp;
			this.input.popFront();
			++this.column;
		} else if(tmp.startsWith('D') || tmp.startsWith('d'))
		{
			this.cur = Token(TokenType.value, Value(to!double(prefix)), prefix,
				l, c);
			this.input = tmp;
			this.input.popFront();
			++this.column;
		} else if(tmp.startsWith("bd")
				|| tmp.startsWith("BD")
				|| tmp.startsWith("bD")
				|| tmp.startsWith("Bd"))
		{
			this.cur = Token(TokenType.value, Value(to!real(prefix)), prefix,
				l, c);
			this.input = tmp;
			this.input.popFront();
			this.input.popFront();
			this.column += 2;
		} else if(tmp.startsWith('.')) {
			tmp.popFront();
			++this.column;
			while(!tmp.empty && isDigit(tmp.front)) {
				++idx;
				++this.column;
				tmp.popFront();
			}
			++idx;
			string theNum = this.input[0 .. idx];
			this.input = this.input[idx .. $];
			if(this.input.empty) {
				this.cur = Token(TokenType.value, Value(to!double(theNum)),
					theNum, l, c);
			} else if(this.input.startsWith('F')
					|| this.input.startsWith('f'))
			{
				this.input.popFront();
				this.cur = Token(TokenType.value, Value(to!float(theNum)),
					theNum, l, c);
			} else if(this.input.startsWith("BD")
					|| this.input.startsWith("bd")
					|| this.input.startsWith("Bd")
					|| this.input.startsWith("bD"))
			{
				this.input.popFront();
				this.input.popFront();
				this.cur = Token(TokenType.value, Value(to!real(theNum)),
					theNum, l, c);
			} else {
				this.cur = Token(TokenType.value, Value(to!double(prefix)),
					prefix, l, c);
				this.input = tmp;
			}
		} else {
			this.cur = Token(TokenType.value, Value(to!int(prefix)), prefix,
				l, c);
			this.input = tmp;
		}
	}

	void parseDuration(size_t idx, size_t l, size_t c) @safe pure {
	}

	void parseDate(size_t idx, size_t l, size_t c) @safe pure {
	}

	@property bool empty() const @safe pure {
		return this.input.empty
			&& this.cur.type == TokenType.undefined;
	}

	Token front() @property @safe pure {
		return this.cur;
	}

	@property Token front() const @safe @nogc pure {
		return this.cur;
	}

	void popFront() @safe pure {
		this.buildToken();
	}

	string getRestOfInput() const @safe pure {
		return this.input;
	}
}

@safe pure:

void test(ref Lexer lex, TokenType tt) {
	assert(!lex.empty);
	assert(lex.front.type == tt,
		format("\nexp: %s\ngot: %s", tt, lex.front.type));
	lex.popFront();
}

void test(T)(ref Lexer lex, TokenType tt, ValueType vt, T value) {
	import std.traits : isFloatingPoint;
	import std.math : approxEqual;

	import dud.sdlang2.util : floatToStringPure;
	assert(!lex.empty);
	assert(lex.front.type == tt,
		format("\nexp: %s\ngot: %s", tt, lex.front.type));
	assert(lex.front.value.type == vt,
		format("\nexp: %s\ngot: %s", vt, lex.front.value.type));

	T tValue = lex.front.value.get!T();
	static if(isFloatingPoint!T) {
		assert(approxEqual(value, tValue),
			format("\nexp: %s\ngot: %s", floatToStringPure(value),
				floatToStringPure(tValue)));
	} else {
		assert(value == tValue,
			format("\nexp: %s\ngot: %s", value, tValue));
	}

	// TODO do value comparison
	lex.popFront();
}

unittest {
	auto l = Lexer("1337");
	test(l, TokenType.value, ValueType.int32, 1337);
	test(l, TokenType.eof);
	assert(l.empty);
}

unittest {
	auto l = Lexer("1337l");
	test(l, TokenType.value, ValueType.int64, 1337);
	test(l, TokenType.eof);
	assert(l.empty);
}

unittest {
	auto l = Lexer("1337.0");
	test(l, TokenType.value, ValueType.float64, 1337.0);
	test(l, TokenType.eof);
	assert(l.empty);
}

unittest {
	auto l = Lexer("1337.0BD");
	test(l, TokenType.value, ValueType.float128, 1337.0);
	test(l, TokenType.eof);
	assert(l.empty);
}

unittest {
	auto l = Lexer("1337.0f");
	test(l, TokenType.value, ValueType.float32, 1337.0f);
	test(l, TokenType.eof);
	assert(l.empty);
}

unittest {
	auto l = Lexer(`"Hello World"`);
	test(l, TokenType.value, ValueType.str, "Hello World");
	test(l, TokenType.eof);
	assert(l.empty);
}

unittest {
	auto l = Lexer(q{`Hello
 World`});
	test(l, TokenType.value, ValueType.str, "Hello\n World");
	test(l, TokenType.eof);
	assert(l.empty);
}

unittest {
	auto l = Lexer(`Hello "World"`);
	test(l, TokenType.ident, ValueType.str, "Hello");
	test(l, TokenType.value, ValueType.str, "World");
	test(l, TokenType.eof);
	assert(l.empty);
}

unittest {
	auto l = Lexer(`Hello "World"1337`);
	test(l, TokenType.ident, ValueType.str, "Hello");
	test(l, TokenType.value, ValueType.str, "World");
	test(l, TokenType.value, ValueType.int32, 1337);
	test(l, TokenType.eof);
	assert(l.empty);
}
