require './file_table'

filetable = FileTable.new(ARGV.first)

def emit_attributes(filetable)
  rv = []
  filetable.attributes.each do |att|
    if att.dbtype == 'DATE'
      rv << "private DateTime#{'?' if att.is_optional} _#{att.name};"
      rv << "[Column(TypeName = \"Date\")]"
      rv << "public DateTime#{'?' if att.is_optional} #{att.name}"
      rv << "{"
      rv << "    get { return _#{att.name}; }"
      rv << "    set { _#{att.name} = value#{'?' if att.is_optional}.Date; }"
      rv << "}"

    elsif att.cstype == 'string'
      rv << "[Required]" unless att.is_optional
      rv << "[Column(TypeName = \"#{att.dbtype}\")]"
      rv << "public string #{att.name} { get; set; }"

    elsif att.cstype == 'int'
      rv << "public int#{'?' if att.is_optional} #{att.name} { get; set; }"

    elsif att.cstype == 'byte'
      rv << "public byte#{'?' if att.is_optional} #{att.name} { get; set; }"

    elsif att.cstype == 'decimal'
      rv << "[Column(TypeName = \"#{att.dbtype}\")]"
      rv << "public decimal#{'?' if att.is_optional} #{att.name} { get; set; }"

    else
      raise "unsupported attribute: #{att.inspect}"
    end

    rv << ''
  end

  rv.pop
  rv.collect {|line| line.empty? ? "" : "#{' '*8}#{line}"}.join("\n")
end


content = <<CONTENTEND
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace koala.FileModels
{
    public class #{filetable.item} : AbstractFileModelBase
    {
        public int #{filetable.pk} { get; set; }

#{emit_attributes(filetable)}
    }
}
CONTENTEND

puts content
