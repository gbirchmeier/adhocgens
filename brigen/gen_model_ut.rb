require './file_table'

filetable = FileTable.new(ARGV.first)

@att_expectations = {}

def emit_att_init(filetable)
  counter = 0
  rv = []
  filetable.attributes.each do |att|
    counter += 1
    val = nil
    expect = nil

    case att.cstype
      when 'string'
        val = expect = "\"#{att.name.downcase}-#{counter}\""
      when 'decimal'
        val = expect = "#{counter*100}.#{counter}#{counter}m"
      when 'int'
        val = expect = (counter*100).to_s
      when 'byte'
        val = expect = counter.to_s
      when 'DateTime'
        raise 'non-Date DateTimes are not supported yet' if att.dbtype != 'DATE'
        val = "new DateTime(2020, #{counter}, #{counter}, #{counter}, #{counter}, #{counter}, #{counter})"
        expect = "new DateTime(2020, #{counter}, #{counter})"
      else
        raise "unsupported cstype: #{att.inspect}"
    end

    rv << "#{att.name} = #{val},"
    @att_expectations[att.name] = expect
  end

  indent = ' ' * 16
  indent + rv.join("\n#{indent}")
end

def emit_assertions()
  rv = []
  @att_expectations.each do |name,expectation|
    rv << "Assert.AreEqual(#{expectation}, i1.#{name});"
  end

  indent = ' ' * 16
  indent + rv.join("\n#{indent}")
end

def emit_null_assignments(filetable)
  rv = []
  filetable.attributes.select(&:is_optional).each do |att|
    rv << "item.#{att.name} = null;"
  end
  indent = ' ' * 12
  indent + rv.join("\n#{indent}")
end

def emit_null_assertions(filetable)
  rv = []
  filetable.attributes.select(&:is_optional).each do |att|
    rv << "Assert.IsNull(i1.#{att.name});"
  end
  indent = ' ' * 16
  indent + rv.join("\n#{indent}")
end

def emit_nulls_test(filetable)
  content = <<NULLTESTEND

        [Test]
        public void CreateWithNullAttributes()
        {
            var item = CreateValid#{filetable.item}();
#{emit_null_assignments(filetable)}

            using (var db = new koala.Reports.SummaryContext())
            {
                db.Add(item);
                db.SaveChanges();

                var i1 = db.#{filetable.table}.First();
#{emit_null_assertions(filetable)}
            }
        }
NULLTESTEND
end


content = <<CONTENTEND
using System;
using System.Linq;
using NUnit.Framework;

namespace koala.UnitTests.FileModels
{
    [TestFixture]
    public class #{filetable.item}Tests
    {
        [SetUp]
        public void Setup()
        {
            UnitTestDatabase.Setup();
        }

        private koala.FileModels.#{filetable.item} CreateValid#{filetable.item}()
        {
            var #{filetable.item.downcase} = new koala.FileModels.#{filetable.item}()
            {
#{emit_att_init(filetable)}
            };
            AbstractFileModelBaseTests.PopulateRequiredBaseFields(#{filetable.item.downcase});

            return #{filetable.item.downcase};
        }

        [Test]
        public void CreateAndQuery()
        {
            var item = CreateValid#{filetable.item}();

            using (var db = new koala.Reports.SummaryContext())
            {
                db.Add(item);
                db.SaveChanges();

                var i1 = db.#{filetable.table}.First();
                Assert.IsTrue(i1.#{filetable.pk} > 0);
#{emit_assertions()}
            }
        }
#{emit_nulls_test(filetable) if filetable.attributes.any?(&:is_optional)}
    }
}
CONTENTEND

puts content
