
DSVEdit (DSVania Editor) is a work-in-progress editor for the three Castlevania games for the Nintendo DS: Dawn of Sorrow, Portrait of Ruin, and Order of Ecclesia. It's currently compatible with the US and Japanese versions. It also has beta support for Aria of Sorrow (US version only).

Source code: https://github.com/LagoLunatic/DSVEdit
Report issues here: https://github.com/LagoLunatic/DSVEdit/issues

### Features

* Editing rooms (tiles, entities, and doors)
* Resizing rooms, and adding and removing entities and doors. Files are automatically expanded as necessary to avoid overwriting other data.
* Editing enemies (max HP, attack, items dropped, etc.)
* Editing items
* Editing GFX and palettes
* Editing sprites (enemies, objects, weapons, etc)
* Editing area maps
* Editing player characters
* Editing text
* Editing which songs play in which areas
* Editing random chest item pools
* Editing weapon synthesis
* Adding a new overlay file that can be used as free space
* Testing rooms by launching the game with you in that room

### Requirements

The path where DSVEdit is located must only have ASCII characters in it - the program will not launch if there are any unicode characters in it.

Install Visual C++ Redistributable for Visual Studio 2015: https://www.microsoft.com/en-us/download/details.aspx?id=48145

### How to open a game ROM

Go to File -> Extract ROM and select the .nds file you want to open. DSVEdit will then extract all the files from the game, which can take a minute. The files will be placed in a folder with the same name as the .nds file (e.g. "Dawn of Sorrow.nds" extracts to "Dawn of Sorrow".)
Once it's done extracting DSVEdit will automatically open up the folder containing the extracted files. Then you can edit the game from there.

If you already extracted the files before, you can instead go to File -> Open Folder and select the folder with the extracted files in it, instead of extracting the files every time.

### How to edit a room's tiles

To edit a room's tiles you must install an external map editor, Tiled: http://www.mapeditor.org/
Then go to Tools -> Settings and browse for the path where you have Tiled installed.

Now find the room you want to edit. You can use the Area/Sector/Room dropdowns to select it, or you can click on it in the map to the left. You can also right click on one of the purple rectangles (doors) in the current room to enter whichever room the door leads to.

Next you can click on "Open in Tiled". This will open up Tiled with the room you want to edit.
After you're finished editing the room, make sure you press Ctrl+S in Tiled to save your changes. Then go back to DSVEdit and click "Import from Tiled". You should see the changes you made reflected in DSVEdit if you did it right.

### Building a ROM with your changes

After editing the game you will need to build a modified ROM in order to actually play it. Press F5 or go to Build -> Build to create a modified ROM file.
After it's finished building the ROM will be placed in the same folder as all the game's files, and will have a name like "built_rom_dos.nds".

If you press F6 instead of F5, DSVEdit will launch an emulator with the modified ROM as soon as it's done building. You can specify what emulator to use in the settings.
If you hover your mouse over a certain spot and press F7, it will launch the emulator, immediately load your first save file, and place you into the room you had open in DSVEdit, at the exact location of your mouse cursor. This allows you to quickly test a room.

If you want the changes you made to be saved to the filesystem, don't forget to press Ctrl+S in DSVEdit too! Otherwise the changes you made will be gone the next time you open up DSVEdit.

### How to edit entities

Right click on the entity you want to edit in the room and an entity editor window will pop up. Here you can edit the entity's type/subtype/variables/etc.
The bottom half of the window will display documentation on the specific entity selected (if available). This explains exactly what this entity does, and how its variables affect this.

You can add a new entity to a room by putting your mouse over the place you want the entity and pressing A.

You can move entities around by left clicking and dragging them.

### Editing enemies, items, text, and maps

You can access the Enemy Editor, Item Editor, Text Editor, and Map Editor in the Tools menu.

Using them is pretty straightforward, but note that all numbers are in hexadecimal, not decimal.

### How to edit GFX and palettes

The GFX/palette editor is in Tools -> GFX Editor.
You need two things in order to use it: the file path of the GFX to edit (e.g. /sc/f_zombie1.dat) and the RAM pointer to the palette list (e.g. 022B7F4C).
You can edit just the GFX, just the palette, or completely replace both the GFX and palette.

Editing just the GFX:
Click Export, then edit the exported image. You can only use the colors already in the palette. When you're done click Import GFX.

Editing just the palette:
Click Export, then edit the exported palette image. You can't increase the total number of colors in the palette. The first color of every palette is always rendered as transparent, so don't bother changing it to anything else. When you're done click Import Palette.

Replacing both the GFX and the palette:
First you need to find all GFX files that use the palette you want to edit. Go through all of those and export them one by one. If you miss any GFX files that use this palette, then the ones you missed will wind up having a messed up palette when you're done.
Then you can edit these images however you want, but remember the total number of colors shared throughout these images can't be more than the size of the palette.
When you're done editing them click Generate palette from file(s), hold down Ctrl or Shift and select all the files you exported. This will make a new palette from the colors used in these edited images.
Finally go through each of the GFX files one by one and click Import GFX.

### Running from source

If you want to run DSVEdit from source you must have Ruby 2.0.0 or higher and Qt 4.8.6 exactly installed.
