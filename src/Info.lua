--[[----------------------------------------------------------------------------

 Create Collection from List
 Copyright 2018 Tapani Otala

--------------------------------------------------------------------------------

Info.lua
Summary information for the plug-in.

Adds menu items to Lightroom.

------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 5.0,
	LrSdkMinimumVersion = 5.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = "com.tjotala.lightroom.create-collection-from-list",

	LrPluginName = LOC( "$$$/CreateCollectionFromList/PluginName=Create Collection from List" ),

	-- Add the menu item to the Export and Library menus.

	LrExportMenuItems = {
	    {
		    title = LOC( "$$$/CreateCollectionFromList/ExportMenuItem=Create Collection from List" ),
		    file = "CreateCollectionFromListMenuItem.lua",
		},
	},

	LrLibraryMenuItems = {
	    {
		    title = LOC( "$$$/CreateCollectionFromList/LibraryMenuItem=Create Collection from List" ),
		    file = "CreateCollectionFromListMenuItem.lua",
		},
	},

	VERSION = { major=1, minor=0, revision=0, build=1, },

}
