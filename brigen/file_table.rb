class FileTable
  attr_reader :table, :item, :pk, :attributes

  def initialize(file)
    @table = nil
    @item = nil
    @pk = nil
    @attributes = []

    File.readlines(ARGV.first).each do |line|
      arr = line.split(':')
      arr.each {|x| x&.strip! }

      case arr[0].downcase
        when 'table'
          @table = arr[1]
        when 'item'
          @item = arr[1]
        when 'pk'
          @pk = arr[1]
        else
          raise "broken line: '#{line}'" unless arr.length >= 3
          is_optional = false
          if arr.length > 3
            raise "unrecognized 4th param: #{line}" if arr[3] != 'optional'
            is_optional = true
          end
          read_attribute(arr[0], arr[1], arr[2], is_optional)
      end
    end
  end

  def read_attribute(col_name, db_data_type, csv_col_header, is_optional)
    if db_data_type.start_with?('decimal') && col_name.downcase.include?('amount')
      db_data_type = 'Money'
    end

    cstype = get_cs_type(db_data_type)

    @attributes << Attribute.new(col_name, db_data_type.upcase, cstype, csv_col_header, is_optional)
  end

  def get_cs_type(db_data_type)
    if db_data_type.start_with?('varchar') || db_data_type.start_with?('char')
      return 'string'
    end
    if db_data_type.start_with?('decimal') || db_data_type.downcase=='money'
      return 'decimal'
    end
    return 'int' if db_data_type=='int'
    return 'DateTime' if db_data_type=='date'
    return 'byte' if db_data_type=='tinyint'

    raise "unsupported db_data_type: #{db_data_type}"
  end
end

class Attribute
  attr_reader :name, :dbtype, :cstype, :colheader, :is_optional

  def initialize(name, dbtype, cstype, colheader, is_optional)
    @name = name
    @dbtype = dbtype
    @cstype = cstype
    @colheader = colheader
    @is_optional = is_optional
  end
end
