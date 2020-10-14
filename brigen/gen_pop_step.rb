require './file_table'

filetable = FileTable.new(ARGV.first)

def emit_assignments(filetable)
  rv = []
  filetable.attributes.each do |att|
    val = case att.cstype
      when 'string'
        'String.IsNullOrWhiteSpace(foo) ? null : foo'
      when 'decimal'
        att.is_optional ?
          'String.IsNullOrWhiteSpace(foo) ? null : decimal.Parse(foo)' :
          'decimal.Parse(foo)'
      when 'int'
        att.is_optional ?
          'String.IsNullOrWhiteSpace(foo) ? null : int.Parse(foo)' :
          'int.Parse(foo)'
      when 'byte'
        att.is_optional ?
          'String.IsNullOrWhiteSpace(foo) ? null : byte.Parse(foo)' :
          'byte.Parse(foo)'
      when 'DateTime'
        att.is_optional ?
          'String.IsNullOrWhiteSpace(foo) ? (DateTime?)null : DateTime.Parse(foo)' :
          'DateTime.Parse(foo)'
      else
        raise "unsupported cstype: #{att.inspect}"
    end
    rv << "if (row.TryGetValue(\"#{att.name}\", out foo))"
    rv << "    ob.#{att.name} = #{val};"
  end

  indent = ' '*16
  indent + rv.join("\n#{indent}")
end

content = <<CONTENTEND
        [Given(@"this test populates the #{filetable.table} table with:")]
        public void Populate#{filetable.table}(Table value)
        {
            var obs = new List<koala.FileModels.#{filetable.item}>();
            foreach (TableRow row in value.Rows)
            {
                string foo;
                var ob = new koala.FileModels.#{filetable.item}();
                if (row.TryGetValue("InputFileDate", out foo))
                    ob.InputFileDate = DateTime.Parse(foo);
                if (row.TryGetValue("SoftDeletedTime", out foo))
                    ob.SoftDeletedTime = String.IsNullOrWhiteSpace(foo) ? (DateTime?)null : DateTime.Parse(foo);

#{emit_assignments(filetable)}

                obs.Add(ob);
            }

            using(var db = new koala.Reports.SummaryContext(false))
            {
                db.AddRange(obs);
                db.SaveChanges();
            }
        }
CONTENTEND

puts content
