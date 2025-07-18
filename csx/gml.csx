static double totalseconds = DateTimeOffset.Now.ToUnixTimeSeconds();
static string seconds = (totalseconds % 60).ToString();
static string minutes = (Math.Floor(totalseconds / 60) % 60).ToString();
static string hours = (Math.Floor(totalseconds / 60 / 60) % 24).ToString();
static string days = (Math.Floor(totalseconds / 60 / 60 / 24) % 365).ToString();
static string years = (Math.Floor(totalseconds / 60 / 60 / 24 / 365)).ToString();

static string currentCodeName = "";

static string BUILD_VERSION = years + "." + days + "." + hours + "." + minutes + "." + seconds;
static string macros =
	"#macro BUILD_VERSION \""+BUILD_VERSION+"\"" + "\n" +
	"#macro BUILD_TIME "+totalseconds.ToString() + "\n"
;

GlobalDecompileContext globalDecompileContext = new(Data);
Underanalyzer.Decompiler.IDecompileSettings decompilerSettings = Data.ToolInfo.DecompilerSettings;

public string PreProcessResolver(Match m) {
	MatchCollection args = Regex.Matches(m.Groups[2].ToString(), @"\S+");
	switch (m.Groups[1].ToString()) {
		case "include":
			string p;
			if (args.Count == 0) {
				p = currentCodeName;
			} else {
				p = args[0].ToString();
			}
			string content;
			UndertaleCode c = Data.Code.ByName(p);
			if (c == null) {
				string source = Environment.GetEnvironmentVariable("Source");
				try {
					content = File.ReadAllText(Path.Join(source, p));
				} catch(Exception e) {
					throw new Exception("Compile errors occurred during code import:\n"+currentCodeName+": #include cannot find code entry or file '" + p + "'");
				}
			} else {
				content = new Underanalyzer.Decompiler.DecompileContext(globalDecompileContext, c, decompilerSettings).DecompileToString();
			}
			return content;
		break;
	}
	return m.ToString();
}

public string PreProcess(string str) {
	string pattern = @"^#(\w+)[ \t]*(.*)";
	Regex r = new Regex(pattern, RegexOptions.Multiline);
	return r.Replace(macros + str, new MatchEvaluator(PreProcessResolver));
}

public static string ReplaceFirst(string str, string term, string replace)
{
    int position = str.IndexOf(term);
    if (position < 0)
    {
        return str;
    }
    str = str.Substring(0, position) + replace + str.Substring(position + term.Length);
    return str;
}

async Task importGML(string folder) {
	List<(string, string)> allGML = new();
	findGML(Path.Join(folder, "gml"), "gml_", allGML);

	await Task.Run(() => {
		if (allGML.Count > 0) {
			UndertaleModLib.Compiler.CodeImportGroup importGroup = new(Data);
			foreach ((string, string) file in allGML) {
				string contents = File.ReadAllText(file.Item1);
				currentCodeName = file.Item2;
				if (file.Item2.StartsWith("gml_Object_")) {
					string[] parts = file.Item2.Replace("gml_Object_", "").Split('_');
					string eventtype = parts[parts.Length-2];
					uint eventsubtype;
					if (!UInt32.TryParse(parts[parts.Length-1], out eventsubtype))
						continue;
					uint eventtypeid;
					if (eventtype == "Create")
						eventtypeid = 0;
					else if (eventtype == "Destroy")
						eventtypeid = 1;
					else if (eventtype == "Alarm")
						eventtypeid = 2;
					else if (eventtype == "Step")
						eventtypeid = 3;
					else if (eventtype == "Collision")
						eventtypeid = 4;
					else if (eventtype == "Keyboard")
						eventtypeid = 5;
					else if (eventtype == "Mouse")
						eventtypeid = 6;
					else if (eventtype == "Other")
						eventtypeid = 7;
					else if (eventtype == "Draw")
						eventtypeid = 8;
					else if (eventtype == "KeyPress")
						eventtypeid = 9;
					else if (eventtype == "KeyRelease")
						eventtypeid = 10;
					else if (eventtype == "Trigger")
						eventtypeid = 11;
					else if (eventtype == "CleanUp")
						eventtypeid = 12;
					else if (eventtype == "Gesture")
						eventtypeid = 13;
					else if (eventtype == "PreCreate")
						eventtypeid = 14;
					else continue;
					Array.Resize(ref parts, parts.Length-2);
					string objname = String.Join('_', parts);
					UndertaleGameObject obj = Data.GameObjects.ByName(objname);
					if (obj == null) {
						obj = new UndertaleGameObject() { Name = Data.Strings.MakeString(objname) };
						Data.GameObjects.Add(obj);
					}
					UndertaleCode code = obj.EventHandlerFor((EventType)eventtypeid, eventsubtype, Data);
					if (contents.StartsWith("#append")) {
						importGroup.QueueAppend(code, macros + ReplaceFirst(contents, "#append", ""));
					} else if (contents.StartsWith("#prepend")) {
						importGroup.QueuePrepend(code, macros + ReplaceFirst(contents, "#prepend", ""));
					} else {
						importGroup.QueueReplace(code, PreProcess(contents));
					}
					continue;
				}
				if (contents.StartsWith("#append")) {
					importGroup.QueueAppend(file.Item2, macros + ReplaceFirst(contents, "#append", ""));
				} else if (contents.StartsWith("#prepend")) {
					importGroup.QueuePrepend(file.Item2, macros + ReplaceFirst(contents, "#prepend", ""));
				} else {
					importGroup.QueueReplace(file.Item2, PreProcess(contents));
				}
			}
			importGroup.Import();
		}
	});
}

void findGML(string folder, string prefix, List<(string, string)> allGML) {
	string[] dirGML = Directory.GetFiles(folder, "*.gml");
	string[] dirFolders = Directory.GetDirectories(folder);
	foreach (string directory in dirFolders) {
		findGML(directory, prefix+Path.GetFileNameWithoutExtension(directory)+"_", allGML);
	}
	foreach (string file in dirGML) {
		string codename = Path.GetFileNameWithoutExtension(file);
		if (!codename.StartsWith("gml_")) {
			codename = prefix+codename;
		}
		allGML.Add((file, codename));
	}
}