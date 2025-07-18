EnsureDataLoaded();

try {
	string source = Environment.GetEnvironmentVariable("Source");
	if (source == null) {
		throw new Exception("Please set the %SOURCE% environment variable");
	} else {
		ScriptMessage("%RUNNER:"+Data.GeneralInfo.FileName.Content);

		string gi_name = Environment.GetEnvironmentVariable("GeneralInfo/Name");
		if (gi_name != null)
			Data.GeneralInfo.Name = Data.Strings.MakeString(gi_name);

		string gi_displayname = Environment.GetEnvironmentVariable("GeneralInfo/DisplayName");
		if (gi_displayname != null)
			Data.GeneralInfo.DisplayName = Data.Strings.MakeString(gi_displayname);
		
		string importFolder = Path.Join(Directory.GetCurrentDirectory(), source);

		importSounds(Path.Join(importFolder, "sounds"), true);

		SyncBinding("Strings, Code, CodeLocals, Scripts, GlobalInitScripts, GameObjects, Functions, Variables", true);

		importSprites(importFolder);
		
		await importGML(importFolder);

		DisableAllSyncBindings();
	}
} catch(Exception e) {
	ScriptMessage("[31m"+e.Message+"[0m");
	Environment.Exit(1);
}