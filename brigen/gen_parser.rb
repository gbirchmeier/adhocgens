require './file_table'

filetable = FileTable.new(ARGV.first)

def emit_attributes(filetable)
  rv = []
  filetable.attributes.each do |att|
    next if att.colheader=='NOT-PARSED'

    if att.dbtype == 'MONEY'
      raise 'nullable money not supported yet' if att.is_optional
      rv << "#{att.name} = GetMoney(record, \"#{att.colheader}\"),"

    elsif att.dbtype == 'DATE'
      rv << "#{att.name} = Get#{'Nullable' if att.is_optional}Date(record, \"#{att.colheader}\"),"

    elsif att.cstype == 'string'
      rv << "#{att.name} = Get#{'Nullable' if att.is_optional}String(record, \"#{att.colheader}\"),"

    elsif att.cstype == 'int'
      raise 'nullable int not supported yet' if att.is_optional
      rv << "#{att.name} = GetInt(record, \"#{att.colheader}\"),"

    elsif att.cstype == 'byte'
      raise 'nullable int not supported yet' if att.is_optional
      rv << "#{att.name} = GetByte(record, \"#{att.colheader}\"),"

    else
      raise "unsupported attribute: #{att.inspect}"
    end
  end

  rv.collect {|line| line.empty? ? "" : "#{' '*16}#{line}"}.join("\n")
end


content = <<CONTENTEND
using System;
using System.Collections.Generic;
using koala.FileModels;

namespace koala.FileParsers
{
    public class #{filetable.table}FileParser : AbstractFileParserBase<#{filetable.item}>
    {
        public override #{filetable.item} BuildFileModelObject(
            Dictionary<string,string> record,
            string fileName,
            DateTime? fileDate,
            DateTime? fileChanged)
        {
            return new #{filetable.item}()
            {
#{emit_attributes(filetable)}

                InputFilename = fileName,
                InputFileDate = fileDate,
                FileLastChangedDateTime = fileChanged,
            };
        }
    }
}
CONTENTEND

puts content
