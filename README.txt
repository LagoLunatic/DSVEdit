
DSVEdit (DSVania Editor) is a work-in-progress editor for the three Castlevania games for the Nintendo DS: Dawn of Sorrow, Portrait of Ruin, and Order of Ecclesia (only compatible with North American versions).

### Features

* Viewing and editing rooms (tiles, entities, and doors)
* Resizing rooms, and adding and removing entities and doors. Files are automatically expanded as necessary to avoid overwriting other data.
* Viewing and editing enemy DNA (max HP, attack, items dropped, etc.)
* Viewing and editing text
* Viewing and editing items
* Viewing and editing area maps
* Viewing enemy sprites

Also included in this repository is DSVRandom, a program that randomizes items, enemies, etc, in the games automatically.

### Requirements

Install Visual C++ Redistributable for Visual Studio 2015: https://www.microsoft.com/en-us/download/details.aspx?id=48145

### How to open a game ROM

Go to File -> Extract ROM and select the .nds file you want to open. DSVEdit will then extract all the files from the game, which can take a minute. The files will be placed in a folder with the same name as the .nds file (e.g. "Dawn of Sorrow.nds" extracts to "Dawn of Sorrow".)
Once it's done extracting DSVEdit will automatically open up the folder containing the extracted files. Then you can edit the game from there.

If you already extracted the files before, you can instead go to File -> Open Folder and select the folder with the extracted files in it, instead of extracting the files every time.

### How to edit a room's tiles

To edit a room's tiles you must install an external map editor, [Tiled](http://www.mapeditor.org/).
Then go to Tools -> Settings and browse for the path where you have Tiled installed.

Now find the room you want to edit. You can use the Area/Sector/Room dropdowns to select it, or you can click on it in the map to the left. You can also right click on one of the purple rectangles (doors) in the current room to enter whichever room the door leads to.

Next you can click on "Open in Tiled". This will open up Tiled with the room you want to edit.
After you're finished editing the room, make sure you press Ctrl+S in Tiled to save your changes. Then go back to DSVEdit and click "Import from Tiled". You should see the changes you made reflected in DSVEdit if you did it right.

Now to test it in game. Press F5 or go to Build -> Build to create a modified ROM file. After its finished you can open the ROM in an emulator to test it.

If you want the changes you made to be saved to the filesystem, don't forget to press Ctrl+S in DSVEdit too! Otherwise the changes you made will be gone the next time you open up DSVEdit.

### How to edit entities

Right click on the entity you want to edit in the room and an entity editor window will pop up. Here you can edit the entity's type/subtype/variables/etc.
The bottom half of the window will display documentation on the specific entity selected (if available). This explains exactly what this entity does, and how its variables affect this.

### Running from source

To run DSVEdit from source, you must have Ruby 2.0.0 or higher and Qt 4.8.6 installed.
