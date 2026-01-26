# frozen_string_literal: true

module Elelem
  class MCP
    class TokenStorage
      STORAGE_DIR = File.expand_path("~/.config/elelem/tokens")

      def initialize
        FileUtils.mkdir_p(STORAGE_DIR, mode: 0o700)
      end

      def save(resource_url, access_token:, refresh_token: nil, expires_in: nil)
        data = {
          access_token: access_token,
          refresh_token: refresh_token,
          expires_at: expires_in ? Time.now.to_i + expires_in : nil
        }
        path = token_path(resource_url)
        File.write(path, data.to_json)
        File.chmod(0o600, path)
      end

      def load(resource_url)
        path = token_path(resource_url)
        return nil unless File.exist?(path)

        JSON.parse(File.read(path), symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      def save_client(resource_url, client_data)
        path = client_path(resource_url)
        File.write(path, client_data.to_json)
        File.chmod(0o600, path)
      end

      def load_client(resource_url)
        path = client_path(resource_url)
        return nil unless File.exist?(path)

        JSON.parse(File.read(path), symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      private

      def token_path(resource_url)
        hash = Digest::SHA256.hexdigest(resource_url)[0, 16]
        File.join(STORAGE_DIR, "#{hash}.json")
      end

      def client_path(resource_url)
        hash = Digest::SHA256.hexdigest(resource_url)[0, 16]
        File.join(STORAGE_DIR, "#{hash}_client.json")
      end
    end
  end
end
