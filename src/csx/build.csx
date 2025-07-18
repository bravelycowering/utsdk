try {
	string source = Environment.GetEnvironmentVariable("Source");
	if (source == null) {
		throw new Exception("Please set the %SOURCE% environment variable");
	} else {
		ScriptMessage("%RUNNER:"+Data.GeneralInfo.FileName.Content);

		if (GeneralInfo_Name != null)
			Data.GeneralInfo.Name = Data.Strings.MakeString(GeneralInfo_Name);

		if (GeneralInfo_DisplayName != null)
			Data.GeneralInfo.DisplayName = Data.Strings.MakeString(GeneralInfo_DisplayName);
		
		string importFolder = Path.Join(Directory.GetCurrentDirectory(), source);

		importSounds(Path.Join(importFolder, "sounds"), true);

		SyncBinding("Strings, Code, CodeLocals, Scripts, GlobalInitScripts, GameObjects, Functions, Variables", true);

		importSprites(importFolder);
		
		await importGML(importFolder);

		DisableAllSyncBindings();

		Environment.SetEnvironmentVariable("do_save", "true");
	}
} catch(Exception e) {
	ScriptMessage(e.Message);
}