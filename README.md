# code-reference-finder
A source code analyzer to find targets and their references in very large solutions.

You can find the gem here: [https://rubygems.org/gems/code_reference_finder](https://rubygems.org/gems/code_reference_finder)

# installation
```
gem install code_reference_finder
```

# example usage
```
require 'code_reference_finder'

# Search a directory for .java files containing [abc, = abc.] and ignore imports.
ref_finder = CodeReferenceFinder.new(
    dir: '/path/to/src/main/', 
    ext: '.java', 
    target: ['abc', '= abc.'],
    ignore: ['import com.', 'import org.']
)
json = ref_finder.get_json

puts json
```