module main

struct PREPE {
	val string
	is_block bool
	pt []&PREPE = []&PREPE {}
}

// TODO: if line ends with ":": expect indent increase
// TODO: fix
fn prep_loop(lines []string, global_ind int) []&PREPE {
	mut arr := []&PREPE {}

	mut prv := ""

	mut is_skipping := false
	mut skib := []string {}
	mut skib_ind := 0
	mut skib_name := ""

	for li in lines {
		ind := li.indent_width()
		l := li.trim_space()

		if l == "" || l.starts_with("#") {
			continue
		}

		if ind != global_ind && !is_skipping {
			is_skipping = true
			skib_ind = ind
			skib_name = prv

			if arr.len > 0 {
				arr.delete_last()
			}

			continue
		}

		if is_skipping {
			if ind == global_ind {
				arr << &PREPE {
					val: skib_name
					is_block: true
					pt: prep_loop(skib, skib_ind)
				}
				skib = []
				is_skipping = false
			}
			else {
				skib << l
				continue
			}
		}

		arr << &PREPE { val: l }

		prv = l
	}

	if is_skipping {
		arr << &PREPE {
			val: skib_name
			is_block: true
			pt: prep_loop(skib, skib_ind)
		}
	}

	return arr
}

// prepare generates a context from a bunch of lines
//
// this context should only have the plain text, blocks and publics resolved!
fn prepare(lines []string) &CTX {
	mut ctx := &CTX {}

	o := prep_loop(lines, 0)
	println(o)

	return ctx
}
