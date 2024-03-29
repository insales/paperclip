# frozen_string_literal: true

module Paperclip
  # This module contains all the methods that are available for interpolation
  # in paths and urls. To add your own (or override an existing one), you
  # can either open this module and define it, or call the
  # Paperclip.interpolates method.
  module Interpolations
    extend self

    # Hash assignment of interpolations. Included only for compatibility,
    # and is not intended for normal use.
    def self.[]= name, block
      define_method(name, &block)
    end

    # Hash access of interpolations. Included only for compatibility,
    # and is not intended for normal use.
    def self.[] name
      method(name)
    end

    INTERPOLATION_REGEXP = /:\w+/

    # Perform the actual interpolation. Takes the pattern to interpolate
    # and the arguments to pass, which are the attachment and style name.
    # You can pass a method name on your record as a symbol, which should turn
    # an interpolation pattern for Paperclip to use.
    def self.interpolate(pattern, attachment, *args)
      pattern = attachment.instance.send(pattern) if pattern.kind_of? Symbol
      pattern.gsub(INTERPOLATION_REGEXP) do |match|
        method = match[1..-1]
        respond_to?(method) ? public_send(method, attachment, *args) : match
      end
    end

    def self.plural_cache
      @plural_cache ||= PluralCache.new
    end

    # Returns the filename, the same way as ":basename.:extension" would.
    def filename(attachment, style_name)
      "#{basename(attachment, style_name)}.#{extension(attachment, style_name)}"
    end

    # This interpolation is used in the default :path to ease default specifications.
    # So it just interpolates :url template without checking if preocessing and
    # file existence.
    def url(attachment, style_name)
      interpolate(attachment.class.url_template, attachment, style_name)
    end

    # Returns the timestamp as defined by the <attachment>_updated_at field
    def timestamp(attachment, _style_name)
      attachment.instance_read(:updated_at).to_s
    end

    # Returns the Rails.root constant.
    def rails_root(_attachment, _style_name)
      Rails.root
    end

    # Returns the Rails.env constant.
    def rails_env(_attachment, _style_name)
      Rails.env
    end

    # Returns the underscored, pluralized version of the class name.
    # e.g. "users" for the User class.
    # NOTE: The arguments need to be optional, because some tools fetch
    # all class names. Calling #class will return the expected class.
    def class(attachment = nil, style_name = nil)
      return super() if attachment.nil? && style_name.nil?
      plural_cache.underscore_and_pluralize_class(attachment.instance.class)
    end

    # Returns the basename of the file. e.g. "file" for "file.jpg"
    def basename(attachment, _style_name)
      File.basename(attachment.original_filename, ".*")
    end

    # Returns the extension of the file. e.g. "jpg" for "file.jpg"
    # If the style has a format defined, it will return the format instead
    # of the actual extension.
    def extension(attachment, style_name)
      ((style_name = attachment.styles[style_name]) && style_name[:format]) ||
        File.extname(attachment.original_filename)[1..-1] || ''
    end

    # Returns the id of the instance.
    def id(attachment, _style_name)
      attachment.instance.id
    end

    # Returns the id of the instance in a split path form. e.g. returns
    # 000/001/234 for an id of 1234.
    def id_partition(attachment, _style_name)
      ("%09d" % attachment.instance.id).scan(/\d{3}/).join("/")
    end

    # Returns the pluralized form of the attachment name. e.g.
    # "avatars" for an attachment of :avatar
    def attachment(attachment, _style_name)
      plural_cache.pluralize_symbol(attachment.name)
    end

    # Returns the style, or the default style if nil is supplied.
    def style attachment, style_name
      style_name || attachment.default_style
    end
  end
end
