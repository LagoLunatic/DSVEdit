
require_relative 'ui_address_converter'

class AddressConverterDialog < Qt::Dialog
  slots "convert_from_address()"
  slots "convert_from_offset()"
  
  attr_reader :game
  
  def initialize(main_window)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_AddressConverter.new
    @ui.setup_ui(self)
    
    @game = main_window.game
    
    connect(@ui.convert_from_address_button, SIGNAL("clicked()"), self, SLOT("convert_from_address()"))
    connect(@ui.convert_from_offset_button, SIGNAL("clicked()"), self, SLOT("convert_from_offset()"))
    
    self.show()
  end
  
  def convert_from_address
    if @ui.ram_address.text.empty?
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "No RAM address given."
      )
      return
    end
    if @ui.ram_address.text !~ /^(?:0x)?[0-9a-f]+$/i
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "'#{@ui.ram_address.text}' is not a valid hexadecimal number."
      )
      return
    end
    
    ram_address = @ui.ram_address.text.to_i(16)
    
    if !game.fs.is_pointer?(ram_address)
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "'#{@ui.ram_address.text}' is not a valid address in main RAM. The NDS's main memory ranges from 02000000 to 023FFFFF."
      )
      return
    end
    
    begin
      file_path, offset = game.fs.convert_ram_address_to_path_and_offset(ram_address)
    rescue NDSFileSystem::ConversionError => e
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "DSVEdit currently does not have any file loaded at address %08X.\n\nNote that this doesn't necessarily mean no file CAN be loaded there - DSVEdit changes what files it has loaded on the fly depending on when they are needed (e.g. what sector you have open, what enemies are in the current room, whether you've viewed any text, etc). If you know what thing the address you're trying to convert is tied to, try viewing that thing in one of DSVEdit's other windows, and then try converting the address here again." % ram_address
      )
      return
    end
    
    @ui.ram_address.setText("%08X" % ram_address)
    @ui.file_path.setText(file_path)
    @ui.offset.setText("%X" % offset)
  end
  
  def convert_from_offset
    if @ui.file_path.text.empty?
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "No file path given."
      )
      return
    end
    if @ui.offset.text.empty?
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "No offset given."
      )
      return
    end
    if @ui.offset.text !~ /^(?:0x)?[0-9a-f]+$/i
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "'#{@ui.offset.text}' is not a valid hexadecimal number."
      )
      return
    end
    
    file_path = @ui.file_path.text.strip()
    offset = @ui.offset.text.to_i(16)
    
    file = game.fs.files_by_path[file_path]
    if file.nil?
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "There is no file with the path '#{file_path}'.\nMake sure you typed it correctly, and with the proper capitalization.\nExample of a valid file path: /ftc/arm9.bin"
      )
      return
    end
    
    if offset < 0
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "Offset can not be a negative number."
      )
      return
    end
    if offset >= file[:size]
      Qt::MessageBox.warning(self,
        "Conversion failed",
        "Offset %X is past the end of #{file_path} (length %X)." % [offset, file[:size]]
      )
      return
    end
    
    ram_address = file[:ram_start_offset] + offset
    
    @ui.ram_address.setText("%08X" % ram_address)
    @ui.file_path.setText(file_path)
    @ui.offset.setText("%X" % offset)
  end
end
