return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DogWhistle` encountered an error loading the Darktide Mod Framework.")

		new_mod("DogWhistle", {
			mod_script       = "DogWhistle/scripts/mods/DogWhistle/DogWhistle",
			mod_data         = "DogWhistle/scripts/mods/DogWhistle/DogWhistle_data",
			mod_localization = "DogWhistle/scripts/mods/DogWhistle/DogWhistle_localization",
		})
	end,
	packages = {},
}
