diff --git a/vala/valasourcefile.vala b/vala/valasourcefile.vala
index 3d75105..013e621 100644
--- a/vala/valasourcefile.vala
+++ b/vala/valasourcefile.vala
@@ -91,6 +91,16 @@ public class Vala.SourceFile {
 
 	private MappedFile mapped_file = null;
 
+	private string _content = null;
+
+	public string? content {
+		get { return _content; }
+		construct set {
+			this._content = value;
+			read_source_file_from_buffer (_content);
+		}
+	}
+
 	/**
 	 * Creates a new source file.
 	 *
@@ -98,10 +108,11 @@ public class Vala.SourceFile {
 	 * @param pkg      true if this is a VAPI package file
 	 * @return         newly created source file
 	 */
-	public SourceFile (CodeContext context, string filename, bool pkg = false) {
+	public SourceFile (CodeContext context, string filename, bool pkg = false, string? content = null) {
 		this.filename = filename;
 		this.external_package = pkg;
 		this.context = context;
+		this.content = content;
 	}
 	
 	/**
@@ -408,20 +419,34 @@ public class Vala.SourceFile {
 	 */
 	private void read_source_file () {
 		string cont;
-		source_array = new Gee.ArrayList<string> ();
 		try {
 			FileUtils.get_contents (filename, out cont);
 		} catch (FileError fe) {
 			return;
 		}
-		string[] lines = cont.split ("\n", 0);
+		read_source_file_from_buffer (cont);
+	}
+
+	private void read_source_file_from_buffer (string? buffer)
+	{
+		if (buffer == null) {
+			source_array = null;
+			return;
+		}
+
+		string[] lines = buffer.split ("\n", 0);
 		uint idx;
+		source_array = new Gee.ArrayList<string> ();
 		for (idx = 0; lines[idx] != null; ++idx) {
 			source_array.add (lines[idx]);
 		}
 	}
 
 	public char* get_mapped_contents () {
+		if (_content != null) {
+			return _content;
+		}
+
 		if (mapped_file == null) {
 			try {
 				mapped_file = new MappedFile (filename, false);
@@ -435,6 +460,10 @@ public class Vala.SourceFile {
 	}
 	
 	public size_t get_mapped_length () {
+		if (_content != null) {
+			return _content.length;
+		}
+
 		return mapped_file.get_length ();
 	}
 }
