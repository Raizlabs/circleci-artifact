require "circleci_artifact/version"
require 'circleci'

module CircleciArtifact

class Query
  attr_reader :url_substring

  # 'url_substring' is a resource url substring you're looking for
  #
  # @param   url_substring [String]
  def initialize(url_substring:)
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

  # @param   query [Query]
  # @param   url [String] the url matching the original query
  def initialize(query:, url:)
    raise ArgumentError if !query.is_a?(Query)
    raise ArgumentError if url.to_s.empty?
    @query = query
    @url = url
  end
end

class ResultSet
  def initialize()
    @results = {}
  end

  # @param   result [Result]
  # @return [void]
  def add_result(result)
    raise ArgumentError if !result.is_a?(Result)
    results = @results[result.query] || []
    results.push(result)
    @results[result.query] = results
  end

  # Returns first result for query
  #
  # @param   query [Query]
  def result_for_query(query)
    results_for_query(query).first
  end

  # Returns all results matching query
  #
  # @param   query [Query]
  def results_for_query(query)
    raise ArgumentError if !query.is_a?(Query)
    @results[query] ? @results[query] : []
  end

  # Returns first url for query
  #
  # @param   query [Query]
  def url_for_query(query)
    result_for_query(query)&.url
  end
end

class Fetcher

  # @param   token [String]
  # @param   username [String]
  # @param   reponame [String]
  # @param   build [String]
  def initialize(token:, username:, reponame:, build:)
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

  # Give array of Query to find, returns Results
  #
  # @param queries [Array<Query>]
  # @return  [ResultSet]
  def fetch(queries:)
    raise ArgumentError, "Error: Must have queries" if !queries.is_a?(Array)
    build = CircleCi::Build.new @username, @reponame, nil, @build, @config
    artifacts = build.artifacts

    if artifacts.nil?
      STDERR.puts "Error: No artifacts"
      return Results.new
    end
    parse(artifacts: artifacts, queries: queries)
  end

  # Internal method for extracting results
  # @param artifacts [CircleCi::Artifacts]
  # @param queries [Array<Query>]
  # @return  [ResultSet]
  def parse(artifacts:, queries:)
    raise ArgumentError, "Error: Must have artifacts" if artifacts.nil?
    raise ArgumentError, "Error: Must have queries" if !queries.is_a?(Array)

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

    results = ResultSet.new

    artifacts.body.each { |artifact| 
      url = artifact['url']
      if url.nil?
        STDERR.puts "Warning: No URL found on #{artifact}"
        next
      end

      query = queries.find { |q| url.include?(q.url_substring) }
      next if query.nil?
      result = Result.new(query: query, url: url)
      results.add_result(result)
    }

    results
  end

end

end
