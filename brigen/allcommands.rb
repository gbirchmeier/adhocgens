require './file_table'

filetable = FileTable.new(ARGV.first)

rv = []
rv << "ruby gen_model.rb #{ARGV.first} > ~/fork/bri-koala/koala/FileModels/#{filetable.item}.cs"
rv << "ruby gen_ut_model.rb #{ARGV.first} > ~/fork/bri-koala/koala.UnitTests/FileModels/#{filetable.item}Tests.cs"
rv << "ruby gen_parser.rb #{ARGV.first} > ~/fork/bri-koala/koala/FileParsers/#{filetable.table}FileParser.cs"
rv << "ruby gen_ut_parser.rb #{ARGV.first} > ~/fork/bri-koala/koala.UnitTests/FileParsers/#{filetable.table}FileParserTests.cs"

puts rv.join(" && ")
