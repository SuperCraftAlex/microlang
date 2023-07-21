module main


struct CTX {
	mut:
	name string

	types []TYPE
	structs []STRUCT
	functions []FUNC

	errors []ERRW
	warnings []ERRW

	ct_blocks []FUNC

	publics []string
	p_publics []&PARSEOUT

	includes []string
}

pub fn (c CTX) str() string {
	mut o := []string {}
	o << "{"

	o << "\"name\": \"${c.name}\","

	if c.includes.len > 0 {
		o << "\"includes\": ["
		for inc in c.includes {
			o << "\"${inc}\""
			o << ","
		}
		o << "],"
	}

	if c.types.len > 0 {
		o << "\"types\": ["
		for typ in c.types {
			o << typ.str()
			o << ","
		}
		o << "],"
	}

	if c.structs.len > 0 {
		o << "\"structs\": ["
		for strct in c.structs {
			o << strct.str()
			o << ","
		}
		o << "],"
	}

	if c.functions.len > 0 {
		o << "\"functions\": ["
		for fun in c.functions {
			o << fun.str()
			o << ","
		}
		o << "],"
	}

	if c.ct_blocks.len > 0 {
		o << "\"cts\": ["
		for fun in c.ct_blocks {
			o << fun.str()
			o << ","
		}
		o << "],"
	}

	if c.p_publics.len > 0 {
		o << "\"static\": ["
		for x in c.p_publics {
			o << x.str() + ","
		}
		o << "],"
	}

	o << "}"
	return o.join("")
}

fn addexternalctx(mut base &CTX, other &CTX) {
	base.errors << other.errors
	base.warnings << other.warnings

	base.ct_blocks << other.ct_blocks

	for fun in other.functions {
		if fun.public {
			base.functions << fun
		}
	}

	for typ in other.types {
		if typ.public {
			base.types << typ
		}
	}

	for struc in other.structs {
		if struc.public {
			base.structs << struc
		}
	}

	for b in other.ct_blocks {
		if b.public {
			base.ct_blocks << b
		}
	}

	base.publics << other.publics

	for i in other.includes {
		if i !in base.includes {
			base.includes << i
		}
	}
}
