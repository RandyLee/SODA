###############################################################################
# Copyright (c) 2010, SugarCRM, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of SugarCRM, Inc. nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL SugarCRM, Inc. BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###############################################################################

###############################################################################
# Needed: Ruby Libs:
###############################################################################
require 'rubygems'
require 'wx'
include Wx

##############################################################################
#  SodaOptions -- Class
#     A frame for configuring SodaMachine options.
#
#  Superclass: Wx::Frame
#
#  Constructor arguments:
#     -  settings(optional): A hash containing the desired settings
#        The hash has the following entries:
#           - browser: Either 'Firefox' or 'IE'
#           - flavor: Flavor text
#           - results_dir: Path to the desired results directory
#           - summary: Path to the desired summary file.
#           - hijacks: A hash of key/value pairs from the grid
#           - gvars: A hash of key/value pairs from the grid
#           - savehtml: Whether or not to save html (boolean)
#           - debug: Whether or not to print debug info (boolean)
#
#  Note:
#     Conigurable elements in the frame are subclasses of Wx::Window, and must
#     implement the following to work with the settings hash:
#        getSetting(): 
#           Returns a hash of all key/value pairs representing the current
#           state of the element. 
#        updateSetting(settings):
#           Looks up new value(s) for the element from settings, and
#           updates the element.
#     If the element implements these methods, it can be added by creating
#     it and calling the addRow method.
#
##############################################################################
class SodaOptions < Dialog

   def initialize(settings = nil)
      super(nil, -1, 'SodaMachine Options', DEFAULT_POSITION, 
           Size.new(480, 500), CAPTION)
      @rows = []
      @panel_sizer = BoxSizer.new(VERTICAL)
      @NeededSettingsKeys = {
         "browser" => "Firefox",
         "flavor" => "",
         "results_dir" => "",
         "summary" => "",
         "hijacks" => {},
         "gvars" => {},
         "savehtml" => false,
         "debug" => false
      }

      if (settings != nil)
         @NeededSettingsKeys.each do |k, v|
            if (!settings.key?(k))
               settings[k] = @NeededSettingsKeys[k]
            end
         end
      end

      set_sizer(@panel_sizer)

      @browser_dropdown = SodaDropdown.new(self, ['Firefox', 'IE'], 
            'browser')
      addRow(@browser_dropdown, 'Choose Browser:')

      @flavor_textbox = SodaTextCtrl.new(self, settings['flavor'])
      addRow(@flavor_textbox, 'Flavor:')

      @resultsdir_chooser = FileChooserPanel.new(self, true)
      addRow(@resultsdir_chooser, 'Results Directory:')

      @summary_chooser = FileChooserPanel.new(self)
      addRow(@summary_chooser, 'Results Summary File:')
      
      @hijack_kvpanel = KeyValPanel.new(self)
      addRow(@hijack_kvpanel, 'Soda Hijacks:')
      
      @gvar_kvpanel = KeyValPanel.new(self)
      addRow(@gvar_kvpanel, 'Global Variables:')

      @checkboxes_panel = CheckBoxPanel.new(self)
      addRow(@checkboxes_panel, 'Options:')

      @save_button = Button.new(self, -1, 'Save')
      @cancel_button = Button.new(self, -1, 'Cancel')
      @button_sizer = BoxSizer.new(HORIZONTAL)
      @button_sizer.add(@save_button)
      @button_sizer.add(@cancel_button)
      @panel_sizer.add(@button_sizer, 0, ALIGN_RIGHT | ALL, 2)

      evt_button(@save_button, :onSaveClicked)
      evt_button(@cancel_button, :onCancelClicked)

      updateSettings(settings) if (settings != nil)
      self.set_size_hints(700, 700, 700, 700)
      show()
   end

##############################################################################
#  addRow -- Method
#     Adds a configurable option to the options frame
#
# Input:
#     element: The configurable element
#     title: The element's name, to be displayed on the left of the frame
#
# Output:
#    None 
#                 
##############################################################################
   def addRow(element, title)
      sizer = BoxSizer.new(HORIZONTAL)
      label = StaticText.new(self, -1, title, DEFAULT_POSITION, 
         DEFAULT_SIZE, ALIGN_LEFT)
      sizer.add(label, 1, ALIGN_LEFT|ALL, 2)
      sizer.add(element, 3, ALIGN_RIGHT|ALL, 2)
      @panel_sizer.add(sizer, 0, EXPAND|ALL, 2)
   end
   private :addRow

##############################################################################
#  updateSettings -- Method
#     Updates the frame to reflect the settings specified in the argument.
#
# Input:
#     settings: A hash describing the new settings (see class comments)
#
# Output:
#    None 
#                 
##############################################################################
   def updateSettings(settings)
      @flavor_textbox.updateSetting(settings['flavor'])
      @resultsdir_chooser.updateSetting(settings['results_dir'])
      @hijack_kvpanel.updateSetting(settings['hijacks'])
      @gvar_kvpanel.updateSetting(settings['gvars'])
      @summary_chooser.updateSetting(settings['summary'])
      @checkboxes_panel.updateSetting(settings)
      @browser_dropdown.updateSetting(settings['browser'])
   end

##############################################################################
#  getSettings -- Method
#     Returns a settings hash describing the currently configured options
#
# Input:
#     None
#
# Output:
#    A settings hash (see class comments)
#                 
##############################################################################
   def getSettings
      data = Hash.new()
      data.merge!(@checkboxes_panel.getSetting())
      data['flavor'] = @flavor_textbox.getSetting()
      data['results_dir'] = @resultsdir_chooser.getSetting()
      data['hijacks'] = @hijack_kvpanel.getSetting()
      data['gvars'] = @gvar_kvpanel.getSetting()
      data['summary'] = @summary_chooser.getSetting()
      data['browser'] = @browser_dropdown.getSetting()

      return data
   end

##############################################################################
#  onSaveClicked -- Method
#     On-click listener for 'Save' button
#
# Input:
#     None
#
# Output:
#     None                 
##############################################################################
   def onSaveClicked
      dupes = [@hijack_kvpanel, @gvar_kvpanel].any? {|e| e.hasDuplicateKeys()}
      if dupes
         dialog = MessageDialog.new(self, 
            'Error: One of your grids contains duplicate keys.', 
            'Duplicate Key Error', ICON_HAND, DEFAULT_POSITION)
         dialog.show_modal()
      else
         self.close()
      end
   end
   private :onSaveClicked

##############################################################################
#  onCancelClicked -- Method
#     On-click listener for 'Cancel' button
#
# Input:
#     None
#
# Output:
#     None                 
##############################################################################
   def onCancelClicked
      self.close()
      self.set_return_code(-1)
   end
   private :onCancelClicked

end

##############################################################################
#  SodaDropdown -- Class
#     A dropdown chooser that works with SodaOptions
#
#  Superclass: Wx::ComboBox
#
#  Constructor arguments:
#     -  parent: Parent on which to place the dropdown.  Should be a Wx::Window
#        or nil.
#     -  opts: String array containing the options to choose from
#     -  key: Key to identify the value in the settings hash
#
##############################################################################
class SodaDropdown < ComboBox

   def initialize(parent, opts, key)
      super(parent, -1, '', DEFAULT_POSITION, DEFAULT_SIZE, opts, CB_READONLY)
   end

   def updateSetting(str)
      set_value(str)
   end

   def getSetting
      return get_value()   
   end

end


##############################################################################
#  SodaTextCtrl -- Class
#     A text box that works with SodaOptions
#
#  Superclass: Wx::TextCtrl
#
#  Constructor arguments:
#     -  parent: Parent on which to place the element.  Should be a Wx::Window
#        or nil.
#     -  text: Default value of the field
#
##############################################################################
class SodaTextCtrl < TextCtrl

   def initialize(parent, text = "")
      super(parent, -1, text)
   end

   def updateSetting(text)
      change_value(text)
   end

   def getSetting()
      return get_value()
   end

end

##############################################################################
#  KeyValPanel -- Class
#     A panel with a two column grid, an add button, and a remove button.
#
#  Superclass: Wx::Panel
#
#  Constructor arguments:
#     -  parent: Parent on which to place the element.  Should be a Wx::Window
#        or nil.
#     -  key: Key to identify the value in the settings hash
#
##############################################################################
class KeyValPanel < Panel

   def initialize(parent)

      super(parent, -1, DEFAULT_POSITION, DEFAULT_SIZE, 0, 
         'kvpanel')
      @num_rows = 5
      @grid = nil
      
      @grid = Grid.new(self, -1, DEFAULT_POSITION, DEFAULT_SIZE, SIMPLE_BORDER)
      @grid.create_grid(5, 2)
      @grid.set_row_label_size(0)
      @grid.set_col_label_value(0, 'Name:')
      @grid.set_col_label_value(1, 'Value:')
      @grid.set_label_background_colour(BLACK)
      @grid.set_label_text_colour(GREEN)
      @grid.set_col_label_alignment(ALIGN_LEFT, ALIGN_CENTER)
      @grid.set_label_font(SMALL_FONT)
      @grid.set_default_cell_font(SMALL_FONT)
      @grid.auto_size_rows(true)
      @grid.set_grid_line_colour(BLACK)
      @grid.set_selection_mode(Wx::Grid::GridSelectRows)

      @button_add = Button.new(self, -1, 'Add')
      @button_remove = Button.new(self, -1, 'Remove')

      @sizer = BoxSizer.new(VERTICAL)
      self.set_sizer(@sizer)
      @sizer.add(@grid, 0, EXPAND|ALL, 2)
      @button_sizer = BoxSizer.new(HORIZONTAL)
      @button_sizer.add(@button_add)
      @button_sizer.add(@button_remove)
      @sizer.add(@button_sizer, 0, ALL, 2)

      evt_button @button_add, :onAddClick
      evt_button @button_remove, :onRemoveClick
   end

##############################################################################
#  hasDuplicateKeys -- Method
#     Returns true if the grid has duplicate keys (other than '')
#
# Input:
#     None
#
# Output:
#    Boolean
#                 
##############################################################################
   def hasDuplicateKeys
      seen = []
      (0..@num_rows - 1).each do |row_num|
         current_key = @grid.get_cell_value(row_num, 0)
         return true if seen.include? current_key
         seen << current_key unless current_key == ''
      end

      return false
   end

##############################################################################
#
##############################################################################
   def updateSetting(settings)
         count = 0

         settings.each do |k, v|

            if (count > @num_rows)
               @grid.append_rows(1)
            end

            curr = @grid.get_number_rows() -1
            @grid.set_cell_value(count, 0, k)
            @grid.set_cell_value(count, 1, v)
            count += 1
         end
   end

##############################################################################
#
##############################################################################
   def getSetting
      data = Hash.new()
      row_count = @grid.get_number_rows() -1
      
      for i in 0..row_count
         key = @grid.get_cell_value(i, 0)
         val = @grid.get_cell_value(i, 1)
         next if (key.empty? || val.empty?)
         data[key] = val
      end

      return data
   end

##############################################################################
#  onAddClick -- Method
#     Adds a row to the grid.  Called when 'Add' button clicked.
#
# Input:
#     None
#
# Output:
#    None
#                 
##############################################################################
   def onAddClick
      @grid.append_rows(1)
      @num_rows += 1
   end
   private :onAddClick

##############################################################################
#  onRemoveClick -- Method
#     Removes a row from the grid.  Called when 'Remove' button clicked.
#
# Input:
#     None
#
# Output:
#    None
#                 
##############################################################################
   def onRemoveClick
      cur = @grid.get_grid_cursor_row()
      @grid.delete_rows(cur, 1)
      @num_rows -= 1
   end
   private :onRemoveClick
end

##############################################################################
#  FileChooserPanel -- Class
#     A panel with a textbox and a '...' button to browse the filesystem.
#
#  Superclass: Wx::Panel
#
#  Constructor arguments:
#     -  parent: Parent on which to place the element.  Should be a Wx::Window
#        or nil.
#     -  key: Key to identify the value in the settings hash
#     -  dir(optional): If true, the browse button only lets you choose
#        directories.
#
##############################################################################
class FileChooserPanel < Panel

   def initialize(parent, dir=false)
      size = Size.new(500, 500)
      super(parent, -1, DEFAULT_POSITION, size, 0, 
         'filechooser')
      @parent = parent
      @dir_chooser = dir

      @textbox = TextCtrl.new(self, -1, '')
      @button = Button.new(self, -1, '...')

      @sizer = BoxSizer.new(HORIZONTAL)
      self.set_sizer(@sizer)
      @sizer.add(@textbox, 4, ALL, 2)
      @sizer.add(@button, 1, ALL, 2)

      evt_button @button, :chooseFile
   end

   def updateSetting(str)
      @textbox.change_value(str)
   end

   def getSetting
      return @textbox.get_value()
   end

##############################################################################
#  chooseFile -- Method
#     Opens a dialog to browse the filesystem, for either a file or a
#     directory.
#
# Input:
#     None
#
# Output:
#    None
#                 
##############################################################################
   def chooseFile
      begin
         if @dir_chooser
            dialog = DirDialog.new(@parent, 'Choose directory')
         else
            dialog = FileDialog.new(@parent, 'Choose file', '', '', '*', 
               FD_OPEN, DEFAULT_POSITION, DEFAULT_SIZE, 'filedlg')
         end
      rescue Exception => e
         print "Error: #{e.message}!\n"
      ensure

      end
      result = dialog.show_modal()
      if (result == ID_OK)
         @textbox.change_value(dialog.get_path())
      end
   end
   private :chooseFile

end

##############################################################################
#  CheckBoxPanel -- Class
#     A panel with 'SaveHTML' and 'Enable Debug Printing' checkboxes.
#
#  Superclass: Wx::Panel
#
#  Constructor arguments:
#     -  parent: Parent on which to place the element.  Should be a Wx::Window
#        or nil.
#
##############################################################################
class CheckBoxPanel < Panel
   def initialize(parent)
      super(parent, -1, DEFAULT_POSITION, DEFAULT_SIZE, 0, 
         'checkboxrow')

      @sizer = BoxSizer.new(HORIZONTAL)
      self.set_sizer(@sizer)
      @savehtml_checkbox = CheckBox.new(self, -1, 'Save HTML', DEFAULT_POSITION,
         DEFAULT_SIZE)
      @debug_checkbox = CheckBox.new(self, -1, 'Enable Debug Printing', 
         DEFAULT_POSITION, DEFAULT_SIZE)
      @sizer.add(@savehtml_checkbox, 1, ALL, 2)
      @sizer.add(@debug_checkbox, 1, ALL, 2)
   end

##############################################################################
##############################################################################
   def updateSetting(settings)
      if (settings.key?('savehtml'))
         @savehtml_checkbox.set_value(settings['savehtml'])
      elsif (settings.key?('debug'))
         @debug_checkbox.set_value(settings['debug'])
      end
   end

##############################################################################
##############################################################################
   def getSetting
      data = {}
      
      data['savehtml'] = @savehtml_checkbox.get_value()
      data['debug'] = @debug_checkbox.get_value()

      return data
   end
end
