[CCode (lower_case_cprefix = "", cheader_filename = "stdio.h,readline/readline.h")]
namespace ReadLine {
	[CCode (cname = "readline")]
	public string? read_line (string prompt);
	public void add_history (string line);
}
