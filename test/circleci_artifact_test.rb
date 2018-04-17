require "test_helper"

include CircleciArtifact


class MockArtifacts
  attr_reader :body

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
  def initialize()
    @body = []
    @body.push({'url' => 'https://example.com/xcov/index.html'})
    @body.push({'url' => 'https://example.com/what/slather/index.html'})
    @body.push({'url' => 'https://example.com/slather/index.html'})
    @body.push({'url' => 'https://example.com/screenshots/index.html'})
    @body.push({})
  end

end

class CircleciArtifactTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::CircleciArtifact::VERSION
  end

  def test_it_does_something_useful
    token = "token"
    username = "username"
    reponame = "reponame"
    build = "build"

    fetcher = Fetcher.new token, username, reponame, build

    xcov = Query.new 'xcov/index.html'
    slather2 = Query.new 'slather/index.html'
    slather = Query.new 'slather/index.html'
    screenshots = Query.new 'screenshots/index.html'
    not_found = Query.new 'not found'
    queries = [xcov, slather, slather2, screenshots, not_found]
    puts "queries: #{queries}"

    #results = fetcher.fetch(queries)
    artifacts = MockArtifacts.new
    results = fetcher.parse_artifacts(artifacts, queries)

    xcov_url = results.url_for_query(xcov)
    slather_url = results.url_for_query(slather)
    screenshots_url = results.url_for_query(screenshots)

    slather_matches = results.results_for_query(slather)
    assert_equal 2, slather_matches.count
    slather_matches = results.results_for_query(slather2)
    assert_equal 2, slather_matches.count

    refute_nil xcov_url
    refute_nil slather_url
    refute_nil screenshots_url
    assert_nil results.result_for_query(not_found)

    puts "queries: #{queries}"
    puts "slather_matches: #{slather_matches}"
    puts "xcov_url #{xcov_url}"
    puts "slather_url #{slather_url}"
    puts "screenshots_url #{screenshots_url}"
  end
end
