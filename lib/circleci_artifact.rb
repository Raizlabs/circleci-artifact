require "circleci_artifact/version"
require 'circleci'

module CircleciArtifact

class Query
  attr_reader :url_substring

  # 'url_substring' is a resource url substring you're looking for
  def initialize(url_substring)
    raise ArgumentError if url_substring.to_s.empty?
    @url_substring = url_substring
  end

  def ==(other)
    self.class === other and
      other.url_substring == @url_substring
  end

  alias eql? ==

  def hash
    @url_substring.hash
  end
end

class Result
  attr_reader :query, :url

  # 'query' is a Query
  # 'url' is the url matching the original query
  def initialize(query, url)
    raise ArgumentError if query.nil? or !query.is_a?(Query)
    raise ArgumentError if url.to_s.empty?
    @query = query
    @url = url
  end
end

class Results
  def initialize()
    @results = {}
  end

  def add_result(result)
    raise ArgumentError if result.nil? or !result.is_a?(Result)
    results = @results[result.query]
    if results.nil?
      results = []
    end
    results.push(result)
    @results[result.query] = results
  end

  # Returns first result for query
  def result_for_query(query)
    results_for_query(query).first
  end

  # Returns all results matching query
  def results_for_query(query)
    raise ArgumentError if query.nil? or !query.is_a?(Query)
    !@results[query].nil? ? @results[query] : []
  end

  # Returns first url for query
  def url_for_query(query)
    result = result_for_query(query)
    !result.nil? ? result.url : nil
  end
end

class Fetcher

  def initialize(token, username, reponame, build)
    raise ArgumentError, "Error: Missing CIRCLE_API_TOKEN" if token.to_s.empty?
    raise ArgumentError, "Error: Missing CIRCLE_PROJECT_USERNAME" if username.to_s.empty?
    raise ArgumentError, "Error: Missing CIRCLE_PROJECT_REPONAME" if reponame.to_s.empty?
    raise ArgumentError, "Error: Missing CIRCLE_BUILD_NUM" if build.to_s.empty?

    @token = token
    @username = username
    @reponame = reponame
    @build = build

    @config = CircleCi::Config.new token: token
  end

  # Internal method for extracting results
  def parse_artifacts(artifacts = [], queries = [])
    # Example
    # [
    #   {
    #     node_index: 0,
    #     path: "/tmp/circle-artifacts.NHQxLku/cherry-pie.png",
    #     pretty_path: "$CIRCLE_ARTIFACTS/cherry-pie.png",
    #     url: "https://circleci.com/gh/circleci/mongofinil/22/artifacts/0/tmp/circle-artifacts.NHQxLku/cherry-pie.png"
    #   },
    #   {
    #     node_index: 0,
    #     path: "/tmp/circle-artifacts.NHQxLku/rhubarb-pie.png",
    #     pretty_path: "$CIRCLE_ARTIFACTS/rhubarb-pie.png",
    #     url: "https://circleci.com/gh/circleci/mongofinil/22/artifacts/0/tmp/circle-artifacts.NHQxLku/rhubarb-pie.png"
    #   }
    # ]

    results = Results.new

    artifacts.body.each { |artifact| 
      url = artifact['url']
      if url.nil?
        STDERR.puts "Warning: No URL found on #{artifact}"
        next
      end

      queries.each_with_index { | query, index | 
        if url.include? query.url_substring
          result = Result.new query, url
          results.add_result(result)
          break
        end
      }
    }

    results
  end

  # Give array of Query to find, returns Results
  def fetch(queries = [])
    build = CircleCi::Build.new @username, @reponame, nil, @build, @config
    artifacts = build.artifacts

    if artifacts.nil?
      STDERR.puts "Error: No artifacts"
      return Results.new
    end
    parse_artifacts(artifacts, queries)
  end
end


end
