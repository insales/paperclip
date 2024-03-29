# frozen_string_literal: true

module Paperclip
  # Defines the geometry of an image.
  class Geometry
    attr_accessor :height, :width, :modifier

    EXIF_ROTATED_ORIENTATION_VALUES = [5, 6, 7, 8].freeze

    # Gives a Geometry representing the given height and width
    def initialize(width = nil, height = nil, modifier = nil)
      if width.is_a?(Hash)
        options = width
        @height = options[:height].to_f
        @width = options[:width].to_f
        @modifier = options[:modifier]
        @orientation = options[:orientation].to_i
        return
      end
      @height = height.to_f
      @width  = width.to_f
      @modifier = modifier
    end

    # Uses ImageMagick to determing the dimensions of a file, passed in as either a
    # File or path.
    def self.from_file(file)
      file = file.path if file.respond_to? "path"
      geometry = begin
                   Paperclip.run("identify", %(-format "%wx%h,%[exif:orientation]" "#{file}"[0]))
                 rescue PaperclipCommandLineError
                   ""
                 end
      parse(geometry) ||
        raise(NotIdentifiedByImageMagickError, "Формат файла не соответствует его расширению.")
    end

    # Parses a "WxH" formatted string, where W is the width and H is the height.
    def self.parse(string)
      match = string&.match(/\b(\d*)x?(\d*)\b(?:,(\d?))?([\>\<\#\@\%^!])?/i)
      return unless match

      Geometry.new(
        width: match[1],
        height: match[2],
        orientation: match[3],
        modifier: match[4]
      )
    end

    # Swaps the height and width if necessary
    def auto_orient
      return unless EXIF_ROTATED_ORIENTATION_VALUES.include?(@orientation)

      @height, @width = @width, @height
      @orientation -= 4
    end

    # True if the dimensions represent a square
    def square?
      height == width
    end

    # True if the dimensions represent a horizontal rectangle
    def horizontal?
      height < width
    end

    # True if the dimensions represent a vertical rectangle
    def vertical?
      height > width
    end

    # The aspect ratio of the dimensions.
    def aspect
      width / height
    end

    # Returns the larger of the two dimensions
    def larger
      [height, width].max
    end

    # Returns the smaller of the two dimensions
    def smaller
      [height, width].min
    end

    # Returns the width and height in a format suitable to be passed to Geometry.parse
    def to_s
      s = +""
      s << width.to_i.to_s if width.positive?
      s << "x#{height.to_i}" if height.positive?
      s << modifier.to_s
      s
    end

    # Same as to_s
    def inspect
      to_s
    end

    # Returns the scaling and cropping geometries (in string-based ImageMagick format)
    # neccessary to transform this Geometry into the Geometry given. If crop is true,
    # then it is assumed the destination Geometry will be the exact final resolution.
    # In this case, the source Geometry is scaled so that an image containing the
    # destination Geometry would be completely filled by the source image, and any
    # overhanging image would be cropped. Useful for square thumbnail images. The cropping
    # is weighted at the center of the Geometry.
    def transformation_to(dst, crop = false)
      if crop
        ratio = Geometry.new(dst.width / width, dst.height / height)
        scale_geometry, scale = scaling(dst, ratio)
        crop_geometry         = cropping(dst, ratio, scale)
      else
        scale_geometry = dst.to_s
      end

      [scale_geometry, crop_geometry]
    end

    private

    def scaling(dst, ratio)
      if ratio.horizontal? || ratio.square?
        [format("%dx", dst.width), ratio.width] # rubocop:disable Style/FormatStringToken
      else
        [format("x%d", dst.height), ratio.height] # rubocop:disable Style/FormatStringToken
      end
    end

    def cropping(dst, ratio, scale)
      if ratio.horizontal? || ratio.square?
        format(
          "%dx%d+%d+%d", # rubocop:disable Style/FormatStringToken
          dst.width, dst.height,
          0, ((height * scale) - dst.height) / 2
        )
      else
        format(
          "%dx%d+%d+%d", # rubocop:disable Style/FormatStringToken
          dst.width, dst.height,
          ((width * scale) - dst.width) / 2, 0
        )
      end
    end
  end
end
