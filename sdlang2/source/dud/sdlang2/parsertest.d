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
	a_nested_child "\"foobar"
}`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}
