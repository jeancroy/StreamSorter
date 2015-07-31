{PathScanner} = require 'scandal'
stream = require('stream');
path = require('path')
fs = require('fs')
zlib = require('zlib')

options = {
  excludeVcsIgnores: false,
  inclusions: "*",
  exclusions: "",
  includeHidden: false
}

results = [] #sorted result normal sort


# Call benchmark with an folder to scan, else scan in project root.
target = if process.argv.length > 2 then process.argv[2] else path.resolve(__dirname, "../")
file = path.resolve(__dirname, 'benchmark.dat')

scanner = new PathScanner(base, options)

scanner.on 'path-found', (item) -> results.push(path.relative(base, item))

scanner.on 'finished-scanning', ->
  out_stream = fs.createWriteStream(file);

  data_stream = new stream.Readable()
  data_stream.push(results.join("\n"))
  data_stream.push(null)

  # This look like a zip archive, but with only compressed data,
  # No zip header/metadata so cannot be extracted using normal unzip program

  data_stream.pipe(zlib.createGzip()).pipe(out_stream)

scanner.scan()

