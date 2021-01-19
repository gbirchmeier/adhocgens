require './file_table'

filetable = FileTable.new(ARGV.first)

def emit_col_headers_list(filetable)
  quoted_headers = filetable.attributes.collect {|att| "\"#{att.colheader}\""}
  indent = '    ' * 5
  indent + quoted_headers.join(",\n" + indent)
end

def emit_attributes(filetable)
  rv = []
  filetable.attributes.each do |att|
    next if att.colheader=='NOT-PARSED'

    if att.dbtype == 'DATE'
      rv << "#{att.name} = Get#{'Nullable' if att.is_optional}Date(record, \"#{att.colheader}\"),"

    elsif att.cstype == 'string'
      rv << "#{att.name} = Get#{'Nullable' if att.is_optional}String(record, \"#{att.colheader}\"),"

    elsif att.cstype == 'int'
      raise 'nullable int not supported yet' if att.is_optional
      rv << "#{att.name} = GetInt(record, \"#{att.colheader}\"),"

    elsif att.cstype == 'byte'
      raise 'nullable int not supported yet' if att.is_optional
      rv << "#{att.name} = GetByte(record, \"#{att.colheader}\"),"

    elsif att.cstype == 'decimal'
      rv << "#{att.name} = Get#{'Nullable' if att.is_optional}Decimal(record, \"#{att.colheader}\"),"

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
        public override string[] ColumnHeaders
        {
            get
            {
                return new string[]
                {
#{emit_col_headers_list(filetable)}
                };
            }
        }

        public override #{filetable.item} BuildFileModelObject(
            Dictionary<string, string> record,
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
