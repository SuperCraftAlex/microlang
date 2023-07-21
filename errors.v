module main

import term

struct ERRW {
	name string
	desc string
}

fn print_check_warnings_errors(mut ctx &CTX, exitonw bool, ignorew bool) bool {
	if ctx.warnings.len > 0 && !ignorew && !(ctx.warnings.len == 1 && ctx.warnings[0].name.len == 0) {
		println(term.bright_yellow("Warnings:"))
		for warn in ctx.warnings {
			if warn.name.len == 0 { continue }
			if warn.desc.len > 0 {
				println(term.bright_yellow("- ${warn.name}: ${warn.desc}"))
			}
			else {
				println(term.bright_yellow("- ${warn.name}"))
			}
		}
		ctx.warnings = [ERRW { name: "" }]

		print("\n")
		if exitonw {
			return true
		}
	}
	if ctx.errors.len > 0 {
		if !(ctx.errors.len == 1 && ctx.errors[0].name.len == 0) {
			println(term.bright_red("Errors:"))
			for err in ctx.errors {
				if err.name.len == 0 { continue }
				if err.desc.len > 0 {
					println(term.bright_red("- ${err.name}: ${err.desc}"))
				}
				else {
					println(term.bright_red("- ${err.name}"))
				}
			}
			print("\n")
		}
		ctx.errors = [ERRW { name: "" }]
		return true
	}
	return false
}