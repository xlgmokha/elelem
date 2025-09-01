# frozen_string_literal: true

require "net/http"
require "uri"

module Elelem
  module Toolbox
    class Web < Tool
      def initialize(configuration)
        super(
          "web",
          "Fetch web content and search the internet",
          {
            type: :object,
            properties: {
              action: {
                type: :string,
                enum: ["fetch", "search"],
                description: "Action to perform: fetch URL or search"
              },
              url: {
                type: :string,
                description: "URL to fetch (for fetch action)"
              },
              query: {
                type: :string,
                description: "Search query (for search action)"
              }
            },
            required: [:action]
          }
        )
      end

      def call(args)
        action = args["action"]
        
        case action
        when "fetch"
          fetch_url(args["url"])
        when "search"
          search_web(args["query"])
        else
          "Invalid action: #{action}"
        end
      end

      private

      def fetch_url(url)
        return "URL required for fetch action" unless url
        
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.read_timeout = 10
        http.open_timeout = 5
        
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "Elelem Agent/1.0"
        
        response = http.request(request)
        
        if response.is_a?(Net::HTTPSuccess)
          content_type = response["content-type"] || ""
          
          if content_type.include?("text/html")
            extract_text_from_html(response.body)
          else
            response.body
          end
        else
          "HTTP Error: #{response.code} #{response.message}"
        end
      rescue => e
        "Error fetching URL: #{e.message}"
      end

      def search_web(query)
        return "Query required for search action" unless query
        
        # Use DuckDuckGo instant answers API
        search_url = "https://api.duckduckgo.com/?q=#{URI.encode_www_form_component(query)}&format=json&no_html=1"
        
        result = fetch_url(search_url)
        
        if result.start_with?("Error") || result.start_with?("HTTP Error")
          result
        else
          begin
            data = JSON.parse(result)
            format_search_results(data, query)
          rescue JSON::ParserError
            "Error parsing search results"
          end
        end
      end

      def extract_text_from_html(html)
        # Simple HTML tag stripping
        text = html.gsub(/<script[^>]*>.*?<\/script>/im, "")
                  .gsub(/<style[^>]*>.*?<\/style>/im, "")
                  .gsub(/<[^>]*>/, " ")
                  .gsub(/\s+/, " ")
                  .strip
        
        # Limit content length
        text.length > 5000 ? text[0...5000] + "..." : text
      end

      def format_search_results(data, query)
        results = []
        
        # Instant answer
        if data["Answer"] && !data["Answer"].empty?
          results << "Answer: #{data["Answer"]}"
        end
        
        # Abstract
        if data["Abstract"] && !data["Abstract"].empty?
          results << "Summary: #{data["Abstract"]}"
        end
        
        # Related topics
        if data["RelatedTopics"] && data["RelatedTopics"].any?
          topics = data["RelatedTopics"].first(3).map do |topic|
            topic["Text"] if topic["Text"]
          end.compact
          
          if topics.any?
            results << "Related: #{topics.join("; ")}"
          end
        end
        
        if results.empty?
          "No direct results found for '#{query}'. Try a more specific search or use web fetch to access specific URLs."
        else
          results.join("\n\n")
        end
      end
    end
  end
end