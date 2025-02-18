module Paperclip
  # Handles thumbnailing images that are uploaded.
  class Thumbnail < Processor

    attr_accessor :current_geometry, :target_geometry, :format, :whiny, :convert_options
    attr_accessor :source_file_options, :auto_orient

    # Creates a Thumbnail object set to work on the +file+ given. It
    # will attempt to transform the image into one defined by +target_geometry+
    # which is a "WxH"-style string. +format+ will be inferred from the +file+
    # unless specified. Thumbnail creation will raise no errors unless
    # +whiny+ is true (which it is, by default. If +convert_options+ is
    # set, the options will be appended to the convert command upon image conversion
    def initialize file, options = {}, attachment = nil
      super
      geometry          = options[:geometry]
      @file             = file
      @crop             = geometry[-1,1] == '#'
      @target_geometry  = Geometry.parse geometry
      @current_geometry = Geometry.from_file @file
      @convert_options  = options[:convert_options]
      @source_file_options = options[:source_file_options]
      @whiny            = options[:whiny].nil? ? true : options[:whiny]
      @format           = options[:format]
      @save_animation   = options[:save_animation]
      @auto_orient         = options[:auto_orient].nil? ? true : options[:auto_orient]
      if @auto_orient && @current_geometry.respond_to?(:auto_orient)
        @current_geometry.auto_orient
      end

      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
    end

    # Returns true if the +target_geometry+ is meant to crop.
    def crop?
      @crop
    end

    # Returns true if the image is meant to make use of additional convert options.
    def convert_options?
      not @convert_options.blank?
    end

    def animation_option
      @save_animation ? "" : "[0]"
    end

    # Performs the conversion of the +file+ into a thumbnail. Returns the Tempfile
    # that contains the new image.
    def make
      src = @file
      ext = @format.present? ? ".#{@format}" : nil
      dst = Tempfile.new(["#{@basename}-thumb-", ext])
      dst.binmode

      command = <<-end_command
        #{ source_file_options }
        "#{File.expand_path(src.path)}#{animation_option}"
        #{ transformation_command }
        #{ gamma_correction_if_needed }
        "#{ File.expand_path(dst.path) }"
      end_command

      begin
        _success = Paperclip.run("convert", command.gsub(/\s+/, " "))
      rescue PaperclipCommandLineError
        raise PaperclipError, "There was an error processing the thumbnail for #{@basename}" if @whiny
      end

      dst
    end

    # Returns the command ImageMagick's +convert+ needs to transform the image
    # into the thumbnail.
    def transformation_command
      scale, crop = @current_geometry.transformation_to(@target_geometry, crop?)
      trans = String.new
      trans << "-auto-orient " if auto_orient
      trans << "-resize \"#{scale}\"" unless scale.nil? || scale.empty?
      trans << " -crop \"#{crop}\" +repage" if crop
      trans << " #{convert_options}" if convert_options?
      trans
    end

    def gamma_correction_if_needed
      command = <<-end_command
        -format "%[magick]\\n%[type]"
        "#{ File.expand_path(@file.path) }[0]"
      end_command

      begin
        result = Paperclip.run("identify", command.gsub(/\s+/, ' '))
      rescue PaperclipCommandLineError
        raise PaperclipError, "There was an error processing the thumbnail for #{@basename}" if @whiny
      end

      magick, _type = result.split("\n")
      if magick == 'PNG'
        '-define png:big-depth=16 -define png:color-type=6'
      else
        ''
      end
    end
  end
end
