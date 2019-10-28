module dud.sdlang.ast;

import dud.sdlang.tokenmodule;

import dud.sdlang.visitor;

@safe pure:

class Node {}

enum RootEnum {
	T,
	TT,
	E,
}

class Root : Node {
@safe pure:

	RootEnum ruleSelection;
	Tags tags;

	this(RootEnum ruleSelection, Tags tags) {
		this.ruleSelection = ruleSelection;
		this.tags = tags;
	}

	this(RootEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TagsEnum {
	Tag,
	TagFollow,
}

class Tags : Node {
@safe pure:

	TagsEnum ruleSelection;
	Tags follow;
	Tag cur;

	this(TagsEnum ruleSelection, Tag cur) {
		this.ruleSelection = ruleSelection;
		this.cur = cur;
	}

	this(TagsEnum ruleSelection, Tag cur, Tags follow) {
		this.ruleSelection = ruleSelection;
		this.cur = cur;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TagEnum {
	IVAO,
	IAO,
	IVO,
	IVA,
	IO,
	IA,
	IV,
	IE,
	IVAOT,
	IAOT,
	IVOT,
	IVAT,
	IOT,
	IAT,
	IVT,
	IET,
	VAO,
	VO,
	VA,
	O,
	V,
	VAOT,
	VOT,
	VAT,
	OT,
	VT,
}

class Tag : Node {
@safe pure:

	TagEnum ruleSelection;
	OptChild oc;
	IDFull id;
	Values vals;
	Attributes attrs;

	this(TagEnum ruleSelection, IDFull id, Values vals, Attributes attrs, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
		this.attrs = attrs;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Attributes attrs, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.attrs = attrs;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Values vals, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Values vals, Attributes attrs) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
		this.attrs = attrs;
	}

	this(TagEnum ruleSelection, IDFull id, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Attributes attrs) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.attrs = attrs;
	}

	this(TagEnum ruleSelection, IDFull id, Values vals) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
	}

	this(TagEnum ruleSelection, IDFull id) {
		this.ruleSelection = ruleSelection;
		this.id = id;
	}

	this(TagEnum ruleSelection, Values vals, Attributes attrs, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.vals = vals;
		this.attrs = attrs;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, Values vals, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.vals = vals;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, Values vals, Attributes attrs) {
		this.ruleSelection = ruleSelection;
		this.vals = vals;
		this.attrs = attrs;
	}

	this(TagEnum ruleSelection, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, Values vals) {
		this.ruleSelection = ruleSelection;
		this.vals = vals;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum IDFullEnum {
	S,
	L,
}

class IDFull : Node {
@safe pure:

	IDFullEnum ruleSelection;
	IDFull follow;
	Token cur;

	this(IDFullEnum ruleSelection, Token cur) {
		this.ruleSelection = ruleSelection;
		this.cur = cur;
	}

	this(IDFullEnum ruleSelection, Token cur, IDFull follow) {
		this.ruleSelection = ruleSelection;
		this.cur = cur;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ValuesEnum {
	Value,
	ValueFollow,
}

class Values : Node {
@safe pure:

	ValuesEnum ruleSelection;
	Values follow;
	Token cur;

	this(ValuesEnum ruleSelection, Token cur) {
		this.ruleSelection = ruleSelection;
		this.cur = cur;
	}

	this(ValuesEnum ruleSelection, Token cur, Values follow) {
		this.ruleSelection = ruleSelection;
		this.cur = cur;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum AttributesEnum {
	Attribute,
	AttributeFollow,
}

class Attributes : Node {
@safe pure:

	AttributesEnum ruleSelection;
	Attributes follow;
	Attribute cur;

	this(AttributesEnum ruleSelection, Attribute cur) {
		this.ruleSelection = ruleSelection;
		this.cur = cur;
	}

	this(AttributesEnum ruleSelection, Attribute cur, Attributes follow) {
		this.ruleSelection = ruleSelection;
		this.cur = cur;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum AttributeEnum {
	A,
}

class Attribute : Node {
@safe pure:

	AttributeEnum ruleSelection;
	Token value;
	IDFull id;

	this(AttributeEnum ruleSelection, IDFull id, Token value) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.value = value;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum OptChildEnum {
	C,
}

class OptChild : Node {
@safe pure:

	OptChildEnum ruleSelection;
	Tags tags;

	this(OptChildEnum ruleSelection, Tags tags) {
		this.ruleSelection = ruleSelection;
		this.tags = tags;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TagTerminatorEnum {
	E,
	S,
	EF,
	SF,
}

class TagTerminator : Node {
@safe pure:

	TagTerminatorEnum ruleSelection;

	this(TagTerminatorEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

