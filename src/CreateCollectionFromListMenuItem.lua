--[[----------------------------------------------------------------------------

 Create Collection from List
 Copyright 2018 Tapani Otala

--------------------------------------------------------------------------------

CreateCollectionFromListMenuItem.lua

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.
local LrLogger = import "LrLogger"
local LrApplication = import "LrApplication"
local LrPathUtils = import "LrPathUtils"
local LrTasks = import "LrTasks"
local LrProgressScope = import "LrProgressScope"
local LrFunctionContext = import "LrFunctionContext"
local LrBinding = import "LrBinding"
local LrDialogs = import "LrDialogs"
local LrView = import "LrView"
local bind = LrView.bind -- shortcut for bind() method
local share = LrView.share -- shortcut for share() method

-- Create the logger and enable the print function.
local myLogger = LrLogger( "com.tjotala.lightroom.create-collection-from-list" )
myLogger:enable( "logfile" ) -- Pass either a string or a table of actions.

--------------------------------------------------------------------------------
-- Write trace information to the logger.

local function trace( message, ... )
	myLogger:tracef( message, unpack( arg ) )
end

local function splitString( str )
	lines = { }
	for s in str:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	return lines
end

--------------------------------------------------------------------------------
-- Create a collection from the list of filenames

local function createCollectionFromList( catalog, collectionName, fileNames )
	local collection = nil
	catalog:withWriteAccessDo( LOC( "$$$/CreateCollectionFromList/ActionName=Create Collection from List" ),
		function( context )
			collection = catalog:createCollection( collectionName, nil, true )
		end
	)
	if not collection then
		LrDialogs.showError( LOC( "$$$/CreateCollectionFromList/FailedToCreate=Failed to create collection ^1", collectionName ) )
	end

	catalog:withWriteAccessDo( LOC( "$$$/CreateCollectionFromList/ActionName=Create Collection from List" ),
		function( context )

			local progressScope = LrProgressScope {
				title = LOC( "$$$/CreateCollectionFromList/ProgressScopeTitle=Finding Photos..." ),
				functionContext = context
			}
			progressScope:setCancelable( true )

			local totalNames = #fileNames
			local totalFound = 0
			for i, fileName in ipairs(fileNames) do
				if progressScope:isCanceled() then
					break
				end

				fileName = LrPathUtils.removeExtension( LrPathUtils.leafName( fileName ) )
				progressScope:setCaption( LOC( "$$$/CreateCollectionFromList/ProgressCaption=^1 (^2 of ^3)", fileName, i, totalNames ) )
				progressScope:setPortionComplete( i, totalNames )

				local foundPhotos = catalog:findPhotos( {
	     		searchDesc = {
	          criteria = "filename",
	          operation = "==",
	          value = fileName,
	     		}
	 			} )
				trace( "found %d matches", #foundPhotos )
				if #foundPhotos > 0 then
					totalFound = totalFound + 1
					collection:addPhotos( foundPhotos )
				end

				if LrTasks.canYield() then
					LrTasks.yield()
				end
			end

			progressScope:done()
			catalog:setActiveSources( { collection } )

			LrDialogs.message( LOC( "$$$/CreateCollectionFromList/Completed=Found ^1 out of ^2 photos", totalFound, totalNames ), nil, "info" )
		end
	)
end

--------------------------------------------------------------------------------
-- Select the filenames to use as list

local function selectFileNames()
	local result = nil
	LrFunctionContext.callWithContext( 'selectFileNamesDialog',
		function( context )
			local f = LrView.osFactory()
			local props = LrBinding.makePropertyTable( context )
			props.collectionName = ""
			props.fileNames = ""
			local contents = f:column {
				bind_to_object = props,
				fill_horizontal = 1,
				spacing = f:control_spacing(),
				f:row {
					f:static_text {
						title = LOC( "$$$/CreateCollectionFromList/SelectFileNames/CollectionName/Title=Collection Name:" ),
						alignment = 'right',
						width = share 'labelWidth',
					},
					f:edit_field {
						fill_horizontal = 1,
						width_in_chars = 40,
						height_in_lines = 1,
						placeholder_string = LOC( "$$$/CreateCollectionFromList/SelectFileNames/CollectionName/Placeholder=Collection name..." ),
						value = bind 'collectionName',
					},
				},
				f:row {
					f:static_text {
						title = LOC( "$$$/CreateCollectionFromList/SelectFileNames/Filenames/Title=Filenames:" ),
						alignment = 'right',
						width = share 'labelWidth',
					},
					f:edit_field {
						fill_horizontal = 1,
						width_in_chars = 40,
						height_in_lines = 20,
						placeholder_string = LOC( "$$$/CreateCollectionFromList/SelectFileNames/Filenames/Placeholder=Enter filenames here..." ),
						value = bind 'fileNames',
					},
				},
			}

			result = LrDialogs.presentModalDialog({
				title = LOC( "$$$/CreateCollectionFromList/SelectFileNames/Title=Enter Filenames to Select" ),
				resizable = true,
				contents = contents,
		  })
			if result == 'ok' then
				props.fileNames = splitString( props.fileNames )
				result = props
			else
				result = nil
			end
		end
	)
	return result
end

--------------------------------------------------------------------------------

local function createCollection()
  LrTasks.startAsyncTask(
    function( )
      trace( "createCollection: enter" )
      local catalog = LrApplication.activeCatalog()

			local results = selectFileNames()
			if results then
				trace( "adding %d filenames into %s", #results.fileNames, results.collectionName )
				createCollectionFromList( catalog, results.collectionName, results.fileNames )
			else
				trace( "no filenames to collect" )
			end

			trace( "createCollection: exit" )
		end
	)
end

--------------------------------------------------------------------------------
-- Begin the create operation
createCollection()
