# frozen_string_literal: true

module LegacyJoomla
  class DumpReader
    ESCAPES = { "0" => "\0", "n" => "\n", "r" => "\r", "t" => "\t", "Z" => "\x1a" }.freeze

    attr_reader :columns

    def initialize(path, tables:)
      @path = Pathname(path)
      @tables = tables.map(&:to_s).to_set
      @columns = {}
    end

    def read
      rows = @tables.to_h { |table| [ table, [] ] }
      current_table = nil

      @path.open("rb") do |file|
        file.each_line do |raw_line|
          line = raw_line.force_encoding(Encoding::UTF_8)
          if (match = line.match(/\ACREATE TABLE `([^`]+)`/))
            current_table = match[1]
            @columns[current_table] ||= [] if @tables.include?(current_table)
          elsif current_table && @tables.include?(current_table) && (match = line.match(/\A\s+`([^`]+)`/))
            @columns[current_table] << match[1]
          elsif current_table && line.start_with?(") ENGINE=")
            current_table = nil
          elsif (match = line.match(/\AINSERT INTO `([^`]+)` VALUES (.*);\s*\z/m)) && @tables.include?(match[1])
            table = match[1]
            parse_tuples(match[2]).each do |values|
              rows.fetch(table) << @columns.fetch(table).zip(values).to_h
            end
          end
        end
      end

      rows
    end

    private

    def parse_tuples(source)
      tuples = []
      tuple = nil
      token = String.new(encoding: Encoding::BINARY)
      quoted = false
      escaped = false
      index = 0

      source = source.b
      while index < source.bytesize
        byte = source.getbyte(index)
        if quoted
          if escaped
            char = byte.chr
            token << ESCAPES.fetch(char, char)
            escaped = false
          elsif byte == 92 # backslash
            escaped = true
          elsif byte == 39 # single quote
            quoted = false
          else
            token << byte
          end
        else
          case byte
          when 40 # (
            tuple = []
            token.clear
          when 39 # '
            quoted = true
          when 44 # ,
            if tuple
              tuple << convert(token)
              token = String.new(encoding: Encoding::BINARY)
            end
          when 41 # )
            if tuple
              tuple << convert(token)
              tuples << tuple
              tuple = nil
              token = String.new(encoding: Encoding::BINARY)
            end
          else
            token << byte if tuple
          end
        end
        index += 1
      end
      tuples
    end

    def convert(token)
      value = token.force_encoding(Encoding::UTF_8).strip
      return nil if value.casecmp?("NULL")
      return value.to_i if value.match?(/\A-?\d+\z/)
      return value.to_f if value.match?(/\A-?\d+\.\d+\z/)

      value
    end
  end
end
