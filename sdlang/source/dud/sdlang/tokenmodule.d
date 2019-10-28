module dud.sdlang.tokenmodule;

import dud.sdlang.visitor;
import dud.sdlang.value;

enum TokenType {
	undefined,
	lcurly,
	rcurly,
	ident,
	colon,
	backslash,
	semicolon,
	assign,
	eol,
	eof,
	value
}

struct Token {
@safe pure:
	size_t line;
	size_t column;
	Value value;
	string valueStr;

	TokenType type;

	this(TokenType type) {
		this.type = type;
	}

	this(TokenType type, size_t line, size_t column) {
		this.type = type;
		this.line = line;
		this.column = column;
	}

	this(TokenType type, Value value, string valueStr) {
		this(type);
		this.value = value;
		this.valueStr = valueStr;
	}

	this(TokenType type, Value value, string valueStr, size_t line,
			size_t column)
	{
		this(type, line, column);
		this.valueStr = valueStr;
		this.value = value;
	}

	void visit(ConstVisitor vis) {
	}

	void visit(ConstVisitor vis) const {
	}

	void visit(Visitor vis) {
	}

	void visit(Visitor vis) const {
	}

	string toString() const {
		import std.format : format;
		return format!"Token(%s,%s,%s,%s)"(this.line, this.column, this.type,
				this.valueStr);
	}
}
