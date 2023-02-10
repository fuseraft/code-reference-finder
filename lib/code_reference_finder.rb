# This is a source code analyzer for finding files containing specific references.

class CodeReferenceFinder
    def initialize(dir:, ext:, target:, ignore:)
        @dir = dir
        @ext = ext
        @target = target
        @ignore = ignore
        @results = nil
        @interesting_paths = nil
    end

    # Performs a parse and returns JSON results.
    def get_json
        @interesting_paths = find_interesting_paths()
        json = parse_interesting_paths(@interesting_paths)
        json
    end

    # Returns the result hash, nil if unparsed.
    def get_results
        @results
    end

    # Returns the interesting paths array, nil if unparsed.
    def get_interesting_paths
        @interesting_paths
    end

    private

    attr_reader :results, :interesting_paths

    # First pass pre-processing to locate files of interest to parse.
    def find_interesting_paths
        require 'find'

        src_paths = []
        Find.find(@dir) do |path|
            src_paths << path if path.end_with? @ext
        end

        search_file_paths = []
        src_paths.each do |path|
            File.open(path) do |f|
                f.each_line do |line|
                    if @target.any? {|s| line.include? s}
                        search_file_paths << path unless search_file_paths.include? path
                    end
                end
            end
        end

        search_file_paths
    end

    # Where the magic happens.
    def parse_interesting_paths(interesting_paths)
        require 'json'

        def is_comment?(line)
            line.start_with? '*' or line.start_with? '/*' or line.start_with? '//'
        end
        
        def is_call?(line, ref)
            line.include? "#{ref}." or line.include? "(#{ref}" or line.include? "#{ref})"
        end

        def is_ref_search_match?(line, refs)
            tokens = line.split(' ')
            matches = []
            refs.each {|ref| matches << ref if tokens.include? ref }
            matches.size > 0
        end

        def is_ignorable?(line)
            @ignore.any? {|s| line.include? s}
        end

        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        file_matches = {}
        refined_target = @target.map {|s| s.split(' ').last}

        # Loop through interesting paths to find targets and references to targets.
        # Add the results of the parse to the file_matches hash.
        interesting_paths.each do |path|
            name = path[path.rindex('/') + 1..].sub(@ext, '').strip
            line_matches = []
            ref_searches = []
            i = 0
        
            File.open(path) do |f|
                f.each_line do |line|
                    i += 1
                    next if is_comment?(line.strip!)

                    if refined_target.any? {|s| line.include? s} and not is_ignorable?(line)
                        line_matches << "#{i}: #{line}"
        
                        if line.include? ' = '
                            search = line.strip.split('=')[0].split(' ').last
                            ref_searches << search if not ref_searches.include? search
                        end
                    elsif ref_searches.any? {|s| is_call?(line, s)} or is_ref_search_match?(line, ref_searches)
                        line_matches << "#{i}: #{line}"
                    end
                end
            end
        
            file_matches[name] = { 
                :path => path, 
                :line_count => i, 
                :ref_count => ref_searches.size, 
                :match_count => line_matches.size, 
                :refs => ref_searches, 
                :matches => line_matches 
            }
        end

        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        
        # Define our results hash and return it as a JSON string.
        @results = { 
            :params => {
                :dir => @dir,
                :ext => @ext,
                :target => @target,
                :ignore => @ignore
            },
            :duration => "#{end_time - start_time} seconds",
            :file_matches => file_matches 
        }
        JSON.pretty_generate(@results)
    end
end