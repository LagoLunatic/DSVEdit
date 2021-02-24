
### About

DSVEdit (DSVania Editor) is an editor for the three Castlevania games for the Nintendo DS: Dawn of Sorrow, Portrait of Ruin, and Order of Ecclesia, as well as Aria of Sorrow and Harmony of Dissonance for the GBA. It supports both the US and Japanese versions of the DS games, while only the US versions of the GBA games are supported.  

Download the latest release: https://github.com/LagoLunatic/DSVEdit/releases  

Source code: https://github.com/LagoLunatic/DSVEdit  
Report issues here: https://github.com/LagoLunatic/DSVEdit/issues  

### Features

* Editing rooms (tiles, entities, and doors)
* Adding new rooms, resizing rooms, and adding and removing entities and doors. Files are automatically expanded as necessary to avoid overwriting other data.
* Editing enemies (max HP, attack, items dropped, etc.)
* Editing items
* Editing GFX and palettes
* Editing sprites (enemies, objects, weapons, etc)
* Editing area maps
* Editing player characters
* Editing text
* Editing tilesets
* Editing which songs play in which areas
* Editing which items are in the shop
* Editing random chest item pools
* Editing weapon synthesis
* Editing magic seals
* Adding a new overlay file that can be used as free space
* Testing rooms by launching the game with you in that room

### Requirements

The path where DSVEdit is located must only have ASCII characters in it - the program will not launch if there are any unicode characters in it.  

Install Visual C++ Redistributable for Visual Studio 2015: https://www.microsoft.com/en-us/download/details.aspx?id=48145  

### How to open a game ROM

Go to File -> Extract ROM and select the .nds or .gba file you want to open. DSVEdit will then extract all the files from the game, which can take a minute. The files will be placed in a folder with the same name as the ROM file (e.g. "Dawn of Sorrow.nds" extracts to "Dawn of Sorrow".)  
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

You can move entities around by left clicking and dragging them. Adding new entities is done by placing your mouse over the spot you want the entity to be and pressing A.  

To edit an entity, right click on the entity and the entity editor window will pop up. Here you can edit the entity's type/subtype/variables/etc.  
The bottom half of the window will display documentation on the specific entity selected (if available). This explains exactly what this entity does, and how its variables affect this.  

### How to edit doors

You can move doors around by left clicking and dragging them. Adding new doors is done by placing your mouse over the spot you want the door to be and pressing D.  

To edit a door, shift+right click on it and the door editor window will pop up.  
Here you can change what room this door leads to by editing the "Dest room" field to have the room pointer of the desired room. You can get this pointer by going to that room in DSVEdit's main window and clicking "Copy room pointer to clipboard" on the left side of the screen, and then paste that into the door editor.  

The bottom half of the door editor shows a preview of the room this doors leads to. The orange rectangle represents where the player will appear after taking this door. You can drag this orange rectangle around to change this.  
The "Dest X Offset" and "Dest Y Offset" fields also affect the exact position the player will appear at. You usually don't need to edit these fields since dragging the orange rectangle is enough. But if the door gaps don't line up on both sides of the door (e.g. one is at the bottom of the screen and one is at the middle) you may need to tweak these values so the player can smoothly walk from one side to the other.  

### Resizing rooms

You can increase and decrease the size of rooms by going to Edit -> Edit Layers and changing the Width and Height fields for each layer you want to resize.  

Don't try to change the size of a room with Tiled, that will just mess the whole room up when you import it back into DSVEdit.  

### Editing enemies, items, text, and maps

You can access the Enemy Editor, Item Editor, Text Editor, and Map Editor in the Tools menu.  

Using them is pretty straightforward, but note that all numbers are in hexadecimal, not decimal.  

### How to edit GFX and palettes

GFX refers to static images that compose the game's assets. They are indexed color images that support either 16 colors or 256 colors, and are either 128 or 256 pixels wide. GFX aren't to be confused with sprites - see the following section for details on sprites.  
A palette is a list of colors available for GFX to use.  

You can use the GFX editor to edit just the GFX, just the palette, or completely replace both the GFX and palette.  
If what you want to edit is listed in the Sprite Editor, you can simply open it up in the Sprite Editor and click the "Open in GFX Editor".  
If it's not in the sprite editor, first manually open the GFX editor from Tools -> GFX Editor. Then input the file path or pointer for the GFX you want to edit (e.g. /sc/f_zombie1.dat or 022C95F4) and the pointer to the palette list (e.g. 022B7F4C). Then press the View button to load the GFX and palette.  
You can work with multiple GFX files at the same time by separating them with commas, like this: /sc/f_peep0.dat, /sc/f_peep1.dat  

Editing just the GFX:  
Click Export, then edit the exported image(s) located in the ./gfx folder with an external image editor. When you're done click Import GFX.  
If the only colors you used in your modified image(s) are colors within the current palette, then the image(s) will import successfully.  
But if you used colors that aren't in that palette, you will be given an option to convert the image to the current palette: If you select Yes to this option, DSVEdit will automatically modify your image so that it uses the proper colors and then import that. If you select Cancel nothing will be imported and you can instead go back and manually modify the image to use the proper colors. Either way the palette itself will not be modified.  

Editing just the palette:  
You can edit the palette from within the GFX editor by clicking on one of the color swatches on the right side and selecting a new color.  
But you can also edit the palette in an external image editor. Click Export, then edit the exported palette image located in the ./gfx folder. When you're done click Import Palette.  
Note that you can't increase the total number of colors in the palette. And the first color of every palette is always rendered as transparent, so even if you change it to something else it won't have any effect.  

Replacing both the GFX and the palette:  
First find all the GFX files that share the palette you want to edit. Input the file paths for all of those separated by commas, then export all of them at the same time. If you miss any GFX files that use this palette, then the ones you missed will wind up having a messed up palette when you're done.  
Then you can edit these images however you want, but remember the total number of colors shared throughout these images can't be more than the size of the palette.  
When you're done editing them click Generate palette from file(s), hold down Ctrl or Shift and select all the files you exported. This will make a new palette from the colors used in these edited images.  
Finally click Import GFX to import all the modified images.  

### How to edit sprites

A "sprite" in DSVEdit terms is a combination of one or more images, palettes, and hitboxes arranged into various frames, which may also be animated.  
Enemies, objects, weapons, skills, players, menus, etc, all use sprites.  

In order to edit a sprite, first open Tools -> Sprite Editor, and locate the sprite you want to edit.  
Although the sprite editor itself has limited editing abilities, it's better to use an external program called darkFunction Editor: http://darkfunction.com/editor/  
Once you have installed darkFunction, click "Export to darkFunction" in the sprite editor and DSVEdit will convert the selected sprite to darkFunction's format and save them to the ./darkfunction_sprites folder. You can then open the sprite up in darkFunction to edit it.  

DSVEdit will have exported two different files:  
The file with the .sprites extension defines the various parts of the image you have to work with. When opening this in darkFunction, make sure you select "Define sprites", not "Combine images".  
The file with the .anim extension defines the animations and unanimated frames in this sprite.  

After editing the exported files in darkFunction, first make sure to save your changes by pressing Ctrl+S in darkFunction. Then go back to the sprite editor in DSVEdit and click "Import from darkFunction". You should now see the changes you made reflected in DSVEdit.  

### Adding a free space overlay

Sometimes, you may need free space to put something, such as new entities, layers, or custom ASM code.  
For the DS games, this requires adding a new overlay file and loading that file into RAM.  
DSVEdit provides a feature to do this automatically: simply go to Tools -> Add Overlay and DSVEdit will create an empty overlay and modify the game's initialization code so the overlay is loaded properly.  
What you should do next depends on what you want to use the overlay for - you can either use it for custom ASM code, or for adding new entities/layers/etc.  

If you want to use the free space overlay for custom ASM code:  
When writing the ASM patch, put the custom code in the new overlay file. In order to find out which file that is and what location it should be loaded at in RAM, go to Tools -> Add Overlay again and it will tell you. For example, the overlay file is /ftc/overlay9_41 and is loaded at 02308920 for the US version of DoS.  

If you want to use the free space overlay for adding new entities/layers/etc:  
You need to tell DSVEdit to consider the overlay as free space for it to use it.  
You can do this by modifying the file called _dsvedit_freespace.txt in the project directory. First close DSVEdit if it's open, then open _dsvedit_freespace.txt in a text editor and add a new line to the end of it.  
The line you add should be the offset in the file in hexadecimal, followed by a space, then the length of the free space in in hexadecimal, then a space, then the file name. (To find out the lend of the free space, go to Tools -> Add Overlay again and it will tell you what the maximum size the overlay is allowed to be is.)  
For example, in the US version of DoS, if you want to mark the entire overlay as free space this would be the line you add to it:  
00000000 0000C000 /ftc/overlay9_41  
The 00000000 means the free space starts at the very start of the file. 0000C000 means the free space can be a maximum of 0xC000 bytes long. /ftc/overlay9_41 is the new overlay file in DoS.  

If you want to use the free space overlay for both custom ASM code AND for adding new entities/layers/etc:  
This is more complicated. If you use the overlay for custom ASM code, and you also mark the entire thing as free space by modifying _dsvedit_freespace.txt, then adding entities/layers/etc can overwrite your ASM code and crash the game. If you use the overlay for entities/layers/etc and then apply an ASM patch afterwards, you need to pick where you apply the patch carefully to avoid overwriting the entities/layers with your ASM code.  
If you're going to do this, you will need to modify the _dsvedit_freespace.txt file after every time you apply an ASM patch to unmark just the parts of the file that were used by the ASM patch, but leave most of the file as still marked as free space.  
For example, if you apply an ASM patch that takes up 0x80 bytes, you would have to change this:  
00000054 00015FAC /ftc/overlay9_41  
To this:  
000000D4 00015F2C /ftc/overlay9_41  

### Running from source

If you want to run the latest development version of DSVEdit from source, follow these instructions:  

* Download and install Ruby 2.4 from here: https://rubyinstaller.org/downloads/
* Download and install Qt 4.8.6 from here: https://web.archive.org/web/20200128090117/https://download.qt.io/archive/qt/4.8/4.8.6/
* Obtain DSVEdit's source code from GitHub: https://github.com/LagoLunatic/DSVEdit
* Open the DSVEdit folder in a command prompt and run `gem install bundler` followed by `bundle install`.
* Run the `build_ui` batch file to compile DSVEdit's UI files.
* Then you must create the armips folder in the DSVEdit folder, and put armips.exe and armips64.exe inside it. The easiest way to get those is to copy them from an official DSVEdit release build. But you can alternatively choose to compile them from source yourself if you want: https://github.com/Kingcom/armips
* Finally run `ruby dsvedit.rb` to launch DSVEdit.
* Note that later on when updating to a future version of DSVEdit, you may need to run `build_ui` again to update its UI files.
