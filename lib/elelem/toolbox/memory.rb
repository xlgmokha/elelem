# frozen_string_literal: true

module Elelem
  module Toolbox
    class Memory < Tool
      MEMORY_DIR = ".elelem_memory"
      MAX_MEMORY_SIZE = 1_000_000
      
      def initialize(configuration)
        @configuration = configuration
        @tui = configuration.tui
        
        super("memory", "Persistent memory for learning and context retention", {
          type: :object,
          properties: {
            action: {
              type: :string,
              enum: %w[store retrieve list search forget],
              description: "Memory action: store, retrieve, list, search, forget"
            },
            key: {
              type: :string,
              description: "Unique key for storing/retrieving memory"
            },
            content: {
              type: :string,
              description: "Content to store (required for store action)"
            },
            query: {
              type: :string,
              description: "Search query for finding memories"
            }
          },
          required: %w[action]
        })
        ensure_memory_dir
      end

      def call(args)
        action = args["action"]
        
        case action
        when "store"
          store_memory(args["key"], args["content"])
        when "retrieve"
          retrieve_memory(args["key"])
        when "list"
          list_memories
        when "search"
          search_memories(args["query"])
        when "forget"
          forget_memory(args["key"])
        else
          "Invalid memory action: #{action}"
        end
      rescue StandardError => e
        "Memory error: #{e.message}"
      end

      private

      attr_reader :configuration, :tui

      def ensure_memory_dir
        Dir.mkdir(MEMORY_DIR) unless Dir.exist?(MEMORY_DIR)
      end

      def memory_path(key)
        ::File.join(MEMORY_DIR, "#{sanitize_key(key)}.json")
      end

      def sanitize_key(key)
        key.to_s.gsub(/[^a-zA-Z0-9_-]/, "_").slice(0, 100)
      end

      def store_memory(key, content)
        return "Key and content required for storing" unless key && content
        
        total_size = Dir.glob("#{MEMORY_DIR}/*.json").sum { |f| ::File.size(f) }
        return "Memory capacity exceeded" if total_size > MAX_MEMORY_SIZE

        memory = {
          key: key,
          content: content,
          timestamp: Time.now.iso8601,
          access_count: 0
        }

        ::File.write(memory_path(key), JSON.pretty_generate(memory))
        "Memory stored: #{key}"
      end

      def retrieve_memory(key)
        return "Key required for retrieval" unless key
        
        path = memory_path(key)
        return "Memory not found: #{key}" unless ::File.exist?(path)

        memory = JSON.parse(::File.read(path))
        memory["access_count"] += 1
        memory["last_accessed"] = Time.now.iso8601
        
        ::File.write(path, JSON.pretty_generate(memory))
        memory["content"]
      end

      def list_memories
        memories = Dir.glob("#{MEMORY_DIR}/*.json").map do |file|
          memory = JSON.parse(::File.read(file))
          {
            key: memory["key"],
            timestamp: memory["timestamp"],
            size: memory["content"].length,
            access_count: memory["access_count"] || 0
          }
        end
        
        memories.sort_by { |m| m[:timestamp] }.reverse
        JSON.pretty_generate(memories)
      end

      def search_memories(query)
        return "Query required for search" unless query
        
        matches = Dir.glob("#{MEMORY_DIR}/*.json").filter_map do |file|
          memory = JSON.parse(::File.read(file))
          if memory["content"].downcase.include?(query.downcase) ||
             memory["key"].downcase.include?(query.downcase)
            {
              key: memory["key"],
              snippet: memory["content"][0, 200] + "...",
              relevance: calculate_relevance(memory, query)
            }
          end
        end
        
        matches.sort_by { |m| -m[:relevance] }
        JSON.pretty_generate(matches)
      end

      def forget_memory(key)
        return "Key required for forgetting" unless key
        
        path = memory_path(key)
        return "Memory not found: #{key}" unless ::File.exist?(path)

        ::File.delete(path)
        "Memory forgotten: #{key}"
      end

      def calculate_relevance(memory, query)
        content = memory["content"].downcase
        key = memory["key"].downcase
        query = query.downcase
        
        score = 0
        score += 3 if key.include?(query)
        score += content.scan(query).length
        score += (memory["access_count"] || 0) * 0.1
        score
      end
    end
  end
end