class RubyEscPos
  attr_accessor :buffer

  def initialize
    @buffer = ''
  end

  def new_line(lines = 1)
    text nil, lines
  end

  def style(style, align)
    if style == :header
      style = STYLE_HEADER
    elsif style == :subheader
      style = STYLE_SUBHEADER
    elsif style == :normal
      style = STYLE_NORMAL
    elsif style == :footer
      style = STYLE_FOOTER
    end

    if align == :left
      align = TXT_ALIGN_LT
    elsif align == :center
      align = TXT_ALIGN_CT
    elsif align == :right
      align = TXT_ALIGN_RT
    end

    set(
      align,
      style[:font],
      style[:font_type],
      style[:width],
      style[:height]
    )
  end

  def set(align = TXT_ALIGN_LT, font = TXT_FONT_A, font_type = FONT_TYPE_NORMAL, width = 1, height = 1, density = nil)
    write align

    if height == 2 && width == 2
      write TXT_NORMAL
      write TXT_4SQUARE
    elsif height == 2 && width != 2
      write TXT_NORMAL
      write TXT_2HEIGHT
    elsif width == 2 && height != 2
      write TXT_NORMAL
      write TXT_2WIDTH
    else
      write TXT_NORMAL
    end

    if font_type == FONT_TYPE_BOLD
      write TXT_BOLD_ON
      write TXT_UNDERL_OFF
    elsif font_type == FONT_TYPE_UNDERLINE
      write TXT_BOLD_OFF
      write TXT_UNDERL_ON
    elsif font_type == FONT_TYPE_UNDERLINE_2
      write TXT_BOLD_OFF
      write TXT_UNDERL2_ON
    elsif font_type == FONT_TYPE_BOLD_UNDERLINE
      write TXT_BOLD_ON
      write TXT_UNDERL_ON
    elsif font_type == FONT_TYPE_BOLD_UNDERLINE_2
      write TXT_BOLD_ON
      write TXT_UNDERL2_ON
    else
      write TXT_BOLD_OFF
      write TXT_UNDERL_OFF
    end

    write font
    write density if density
  end

  def barcode(code, width = 64, height = 64, bc = BARCODE_UPC_A, pos = BARCODE_TXT_OFF, font = nil)
    write TXT_ALIGN_CT

    if height >= 2 && height <= 6
      write BARCODE_HEIGHT
    end

    if width >= 1 && width <=255
      write BARCODE_WIDTH
    end

    write font
    write pos

    write bc
    write code
    new_line
  end

  def text(txt, new_lines = 1)
    @buffer += txt if txt

    (1..new_lines).each do
      @buffer += "\n"
    end
  end

  def cut(cut_type = PAPER_FULL_CUT)
    write "\n\n\n\n\n\n"
    write cut_type
  end

  def table(rows, new_lines = 1, main_column_index = 1, max_width = 42)
    max_widths = Array.new(rows[0].count) { |i| 0 }

    rows.each_with_index do |row, i|
      row.each_with_index do |cell, y|
        if y < row.length - 1
          rows[i][y][:text] += ' '
        end

        if max_widths[y] < cell[:text].length
          max_widths[y] = cell[:text].length
        end

        if max_widths[y] < cell[:width].to_i
          max_widths[y] = cell[:width]
        end

        if cell[:text].length < cell[:width].to_i
          cell[:text] = (' ' * (cell[:width] - cell[:text].length)) + cell[:text]
        end
      end
    end

    rows.each_with_index do |row, i|
      row.each_with_index do |cell, y|
        padding = ''
        if y == main_column_index
          padding = (' ' * (max_width - row.map { |x| x[:text].length }.inject(0, :+)))
        elsif y < row.length - 1
          padding = (' ' * (max_widths[y] - cell[:text].length))
        end

        if cell[:align]
          write(cell[:text] = padding + cell[:text])
        else
          write(cell[:text] = cell[:text] + padding)
        end
      end
      new_line
    end

    new_line new_lines - 1
  end

  private

  def write(data)
    if data.is_a? String
      @buffer += data
    elsif data.is_a? Array
      @buffer += data.pack('U*')
    end
  end

  # Feed control sequences
  CTL_LF 			      = [ 0x0a ]						         # Print and line feed
	CTL_FF 			      = [ 0x0c ]						         # Form feed
	CTL_CR 			      = [ 0x0d ]						         # Carriage return
	CTL_HT 			      = [ 0x09 ]						         # Horizontal tab
	CTL_VT 			      = [ 0x0b ]						         # Vertical tab

	# Printer hardware
	HW_INIT 			    = [ 0x1b, 0x40 ]					     # Clear data in buffer and reset modes
	HW_SELECT 			  = [ 0x1b, 0x3d, 0x01 ]			   # Printer select
	HW_RESET 			    = [ 0x1b, 0x3f, 0x0a, 0x00 ]	 # Reset printer hardware

	# Cash Drawer
	CD_KICK_2 			  = [ 0x1b, 0x70, 0x00 ]			   # Sends a pulse to pin 2 = []
	CD_KICK_5 			  = [ 0x1b, 0x70, 0x01 ]			   # Sends a pulse to pin 5 = []

	# Paper
	PAPER_FULL_CUT 	  = [ 0x1d, 0x56, 0x00 ]			   # Full cut paper
	PAPER_PART_CUT 	  = [ 0x1d, 0x56, 0x01 ]			   # Partial cut paper

	# Text format
	TXT_NORMAL 		    = [ 0x1b, 0x21, 0x00 ]			   # Normal text
	TXT_2HEIGHT 		  = [ 0x1b, 0x21, 0x10 ]			   # Double height text
	TXT_2WIDTH 		    = [ 0x1b, 0x21, 0x20 ]			   # Double width text
  TXT_4SQUARE       = [ 0x1b, 0x21, 0x30 ]         # Quad area text
	TXT_UNDERL_OFF 	  = [ 0x1b, 0x2d, 0x00 ]			   # Underline font OFF
	TXT_UNDERL_ON 		= [ 0x1b, 0x2d, 0x01 ]			   # Underline font 1-dot ON
	TXT_UNDERL2_ON 	  = [ 0x1b, 0x2d, 0x02 ]			   # Underline font 2-dot ON
	TXT_BOLD_OFF 		  = [ 0x1b, 0x45, 0x00 ]			   # Bold font OFF
	TXT_BOLD_ON 		  = [ 0x1b, 0x45, 0x01 ]			   # Bold font ON
	TXT_FONT_A 		    = [ 0x1b, 0x4d, 0x00 ]			   # Font type A
	TXT_FONT_B 		    = [ 0x1b, 0x4d, 0x01 ]			   # Font type B
	TXT_ALIGN_LT 		  = [ 0x1b, 0x61, 0x00 ]			   # Left justification
	TXT_ALIGN_CT 		  = [ 0x1b, 0x61, 0x01 ]			   # Centering
	TXT_ALIGN_RT 		  = [ 0x1b, 0x61, 0x02 ]			   # Right justification

	# Barcode format
	BARCODE_TXT_OFF 	= [ 0x1d, 0x48, 0x00 ]			   # HRI barcode chars OFF
	BARCODE_TXT_ABV 	= [ 0x1d, 0x48, 0x01 ]			   # HRI barcode chars above
	BARCODE_TXT_BLW 	= [ 0x1d, 0x48, 0x02 ]			   # HRI barcode chars below
	BARCODE_TXT_BTH 	= [ 0x1d, 0x48, 0x03 ]			   # HRI barcode chars both above and below
	BARCODE_FONT_A 	  = [ 0x1d, 0x66, 0x00 ]			   # Font type A for HRI barcode chars
	BARCODE_FONT_B 	  = [ 0x1d, 0x66, 0x01 ]			   # Font type B for HRI barcode chars
	BARCODE_HEIGHT 	  = [ 0x1d, 0x68, 0x64 ]			   # Barcode Height = [1-255]
	BARCODE_WIDTH 		= [ 0x1d, 0x77, 0x03 ]			   # Barcode Width  = [2-6]
	BARCODE_UPC_A 		= [ 0x1d, 0x6b, 0x00 ]			   # Barcode type UPC-A
	BARCODE_UPC_E 		= [ 0x1d, 0x6b, 0x01 ]			   # Barcode type UPC-E
	BARCODE_EAN13 		= [ 0x1d, 0x6b, 0x02 ]			   # Barcode type EAN13
	BARCODE_EAN8 		  = [ 0x1d, 0x6b, 0x03 ]			   # Barcode type EAN8
	BARCODE_CODE39 	  = [ 0x1d, 0x6b, 0x04 ]			   # Barcode type CODE39
	BARCODE_ITF 		  = [ 0x1d, 0x6b, 0x05 ]			   # Barcode type ITF
	BARCODE_NW7 		  = [ 0x1d, 0x6b, 0x06 ]			   # Barcode type NW7

  # Font types
  FONT_TYPE_BOLD             = "B"
  FONT_TYPE_UNDERLINE        = "U"
  FONT_TYPE_UNDERLINE_2      = "U2"
  FONT_TYPE_BOLD_UNDERLINE   = "BU"
  FONT_TYPE_BOLD_UNDERLINE_2 = "BU2"
  FONT_TYPE_NORMAL           = "N"

  # Styles
  STYLE_HEADER = {
    :font      => RubyEscPos::TXT_FONT_A,
    :font_type => RubyEscPos::FONT_TYPE_BOLD,
    :width     => 2,
    :height    => 2
  }

  STYLE_SUBHEADER = {
    :font      => RubyEscPos::TXT_FONT_A,
    :font_type => RubyEscPos::FONT_TYPE_BOLD,
    :width     => 1,
    :height    => 1
  }

  STYLE_NORMAL = {
    :font      => RubyEscPos::TXT_FONT_A,
    :font_type => RubyEscPos::FONT_TYPE_NORMAL,
    :width     => 1,
    :height    => 1
  }

  STYLE_FOOTER = {
    :font      => RubyEscPos::TXT_FONT_B,
    :font_type => RubyEscPos::FONT_TYPE_NORMAL,
    :width     => 1,
    :height    => 1
  }
end
