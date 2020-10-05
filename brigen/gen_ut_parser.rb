require './file_table'
require 'date'

filetable = FileTable.new(ARGV.first)

@no_nulls_expectations = {}
@nulls_expectations = {}

def emit_no_nulls_row(filetable)
  counter = 0
  values = []
  filetable.attributes.each do |att|
    counter += 1
    counter -= 9 if counter > 9
    val = nil
    expect = nil

    case att.cstype
      when 'string'
        val = "#{att.name.downcase}-#{counter}"
        expect = "\"#{val}\""
      when 'decimal'
        number = "#{counter*100}.#{counter}#{counter}"
        expect = number + "m"
        val = att.dbtype=='MONEY' ? "$#{number}" : expect
      when 'int'
        val = expect = (counter*100).to_s
      when 'byte'
        val = expect = counter.to_s
      when 'DateTime'
        raise 'non-Date DateTimes are not supported yet' if att.dbtype != 'DATE'
        val = Date.new(2020,counter,counter).strftime("%-m/%-d/%Y")
        expect = "new DateTime(2020, #{counter}, #{counter})"
      else
        raise "unsupported cstype: #{att.inspect}"
    end

    values << val
    @no_nulls_expectations[att.name] = expect
  end

  rv = values.join(", ")
end

def emit_with_nulls_row(filetable)
  counter = 5
  values = []
  filetable.attributes.each do |att|
    if att.is_optional
      values << ''
      @nulls_expectations[att.name] = 'null'
      next
    end

    counter += 1
    counter -= 9 if counter > 9
    val = nil
    expect = nil

    case att.cstype
      when 'string'
        val = "#{att.name.downcase}-#{counter}"
        expect = "\"#{val}\""
      when 'decimal'
        number = "#{counter*100}.#{counter}#{counter}"
        expect = number + "m"
        val = att.dbtype=='MONEY' ? "$#{number}" : expect
      when 'int'
        val = expect = (counter*100).to_s
      when 'byte'
        val = expect = counter.to_s
      when 'DateTime'
        raise 'non-Date DateTimes are not supported yet' if att.dbtype != 'DATE'
        val = Date.new(2020,counter,counter).strftime("%-m/%-d/%Y")
        expect = "new DateTime(2020, #{counter}, #{counter})"
      else
        raise "unsupported cstype: #{att.inspect}"
    end

    values << val
    @nulls_expectations[att.name] = expect
  end

  rv = values.join(", ")
end

def emit_no_nulls_assertions()
  rv = []
  @no_nulls_expectations.each do |attname, expected|
    rv << "Assert.AreEqual(#{expected}, i1.#{attname});"
  end
  indent = ' ' * 12
  rv.join("\n"+indent)
end

def emit_nulls_assertions()
  rv = []
  @nulls_expectations.each do |attname, expected|
    if expected=='null'
      rv << "Assert.IsNull(i2.#{attname});"
    else
      rv << "Assert.AreEqual(#{expected}, i2.#{attname});"
    end
  end
  indent = ' ' * 12
  rv.join("\n"+indent)
end


content = <<CONTENTEND
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using NUnit.Framework;
using koala.FileParsers;
using koala.UnitTests.Helpers;

namespace koala.UnitTests.FileParsers
{
    [TestFixture]
    public class #{filetable.table}FileParserTests
    {
        [SetUp]
        public void Setup()
        {
        }

        [Test]
        public void ReadStream()
        {
            var csv = new List<string>();
            csv.Add("#{filetable.attributes.collect(&:colheader).join(", ")}");
            csv.Add("#{emit_no_nulls_row(filetable)}");
            csv.Add("#{emit_with_nulls_row(filetable)}");

            Stream stream = TestUtil.MakeStream(string.Join("\\n",csv));

            var #{filetable.table.downcase} = new #{filetable.table}FileParser().ReadStream(
                stream,
                "#{filetable.table.downcase}.csv",
                new DateTime(2020, 6, 7),
                new DateTime(2020, 10, 11, 12, 30, 00, DateTimeKind.Utc));

            // FIRST ITEM -- no null fields
            var i1 = #{filetable.table.downcase}[0];
            #{emit_no_nulls_assertions()}

            Assert.AreEqual("#{filetable.table.downcase}.csv", i1.InputFilename);
            Assert.AreEqual(new DateTime(2020, 6, 7), i1.InputFileDate);
            Assert.AreEqual("10/11/2020 12:30:00 +00:00", i1.FileLastChangedDateTime.Value.ToString(CultureInfo.InvariantCulture));
            Assert.AreEqual(DateTimeOffset.MinValue, i1.UploadDateTime);
            Assert.IsNull(i1.SoftDeletedTime);

            #{'vvvvvvvvvvvvvvv DELETE THIS LINE AND BELOW vvvvvvvvvvvvv' if filetable.attributes.count(&:is_optional) < 1}
            // SECOND ITEM - everything that can be null is null
            var i2 = #{filetable.table.downcase}[1];
            #{emit_nulls_assertions()}

            Assert.AreEqual("#{filetable.table.downcase}.csv", i2.InputFilename);
            Assert.AreEqual(new DateTime(2020, 6, 7), i2.InputFileDate);
            Assert.AreEqual("10/11/2020 12:30:00 +00:00", i2.FileLastChangedDateTime.Value.ToString(CultureInfo.InvariantCulture));
            Assert.AreEqual(DateTimeOffset.MinValue, i2.UploadDateTime);
            Assert.IsNull(i2.SoftDeletedTime);
        }
    }
}
CONTENTEND

puts content
