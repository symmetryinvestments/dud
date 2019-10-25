module dud.sdlang2.parsertest;

import std.range : walkLength;

import dud.sdlang2.lexer;
import dud.sdlang2.parser;
import dud.sdlang2.ast;
import dud.sdlang2.astaccess;
import dud.sdlang2.value;

@safe pure:

unittest {
	auto l = Lexer(`key "value"`);
	auto p = Parser(l);
	Root r = p.parseRoot();

	foreach(tag; tags(r)) {
		assert(tag.identifer() == "key", tag.identifer());
		auto vals = tag.values();
		assert(!vals.empty);
		assert(vals.front.type == ValueType.str);
	}
}

unittest {
	auto l = Lexer(`key "value"
			key2 1337`);
	auto p = Parser(l);
	Root r = p.parseRoot();

	auto vals = tags(r);

	assert(!vals.empty);
	auto f = vals.front;
	assert(f.identifer() == "key", f.identifer());
	auto val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.str);
	vals.popFront();

	assert(!vals.empty);
	f = vals.front;
	assert(f.identifer() == "key2", f.identifer());
	val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.int32);
	vals.popFront();

	assert(vals.empty);
}

unittest {
	auto l = Lexer(`
			key "value"
			key2 1337`);
	auto p = Parser(l);
	Root r = p.parseRoot();

	auto vals = tags(r);

	assert(!vals.empty);
	auto f = vals.front;
	assert(f.identifer() == "key", f.identifer());
	auto val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.str);
	vals.popFront();

	assert(!vals.empty);
	f = vals.front;
	assert(f.identifer() == "key2", f.identifer());
	val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.int32);
	vals.popFront();

	assert(vals.empty);
}

unittest {
	auto l = Lexer(`

			key      "value"

			key2 1337`);
	auto p = Parser(l);
	Root r = p.parseRoot();

	auto vals = tags(r);

	assert(!vals.empty);
	auto f = vals.front;
	assert(f.identifer() == "key", f.identifer());
	auto val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.str);
	vals.popFront();

	assert(!vals.empty);
	f = vals.front;
	assert(f.identifer() == "key2", f.identifer());
	val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.int32);
	vals.popFront();

	assert(vals.empty);
}

unittest {
	auto l = Lexer(`
			-- some lua style comment
// a c++ comment
someKEy "value" attr=1337 {
	a_nested_child "\"foobar" {
		and_a$depper_nesting:foo 123.3 ; args null
	}
}`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
someKEy {
	and_a$depper_nesting:foo 123.3 ; args null
}`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
			matrix
		`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
			matrix 1 12 32 323 1
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
			matrix 1 12 32 323 1 foo="bar" foo2="bar2"
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
			matrix {
				1 12 32
				2 22 42
				3 32 52
			}
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
// C++ style

/*
C style multiline
*/

tag /*foo=true*/ bar=false

# Shell style

-- Lua style
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}
