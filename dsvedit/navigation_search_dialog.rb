
require_relative 'ui_navigation_search'

class NavigationSearchDialog < Qt::Dialog
  slots "execute_search()"
  slots "room_changed(int)"

  def initialize(main_window)
    super(main_window, Qt::WindowTitleHint | Qt::WindowSystemMenuHint)
    @ui = Ui_NavigationSearch.new
    @ui.setup_ui(self)

    connect(@ui.go_to_room, SIGNAL("clicked()"), self, SLOT("execute_search()"))

    self.show()
  end

  def execute_search
    @rooms = []

    room_pointer = @ui.room_pointer.text =~ /^\h+$/ ? @ui.room_pointer.text.to_i(16) : nil
    door_pointer = @ui.door_pointer.text =~ /^\h+$/ ? @ui.door_pointer.text.to_i(16) : nil

    if !room_pointer && !door_pointer
      return
    end

    parent.game.each_room do |room|
      if room.room_metadata_ram_pointer == room_pointer
        parent.change_room_by_room_object(room)
        return
      end
      room.doors.each do |door|
        if door.door_ram_pointer == door_pointer
          parent.change_room_by_metadata(door.destination_room_metadata_ram_pointer)
          return
        end
      end
    end
  end
end
