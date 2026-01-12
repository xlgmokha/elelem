# frozen_string_literal: true

module Elelem
  class GitContext
    MAX_DIFF_LINES = 100

    def initialize(shell = Elelem.shell)
      @shell = shell
    end

    def to_s
      return "" unless git_repo?

      parts = []
      parts << "Branch: #{branch}" if branch
      parts << status_section if status.any?
      parts << diff_section if staged_diff.any? || unstaged_diff.any?
      parts << recent_commits_section if recent_commits.any?
      parts.join("\n\n")
    end

    private

    def git_repo?
      @shell.execute("git", args: ["rev-parse", "--git-dir"])["exit_status"].zero?
    end

    def branch
      @branch ||= @shell.execute("git", args: ["branch", "--show-current"])["stdout"].strip.then { |b| b.empty? ? nil : b }
    end

    def status
      @status ||= @shell.execute("git", args: ["status", "--porcelain"])["stdout"].lines.map(&:chomp)
    end

    def staged_diff
      @staged_diff ||= @shell.execute("git", args: ["diff", "--cached", "--stat"])["stdout"].lines
    end

    def unstaged_diff
      @unstaged_diff ||= @shell.execute("git", args: ["diff", "--stat"])["stdout"].lines
    end

    def recent_commits
      @recent_commits ||= @shell.execute("git", args: ["log", "--oneline", "-5"])["stdout"].lines.map(&:strip)
    end

    def status_section
      modified = status.select { |l| l[0] == "M" || l[1] == "M" }.map { |l| l[3..] }
      added = status.select { |l| l[0] == "A" || l.start_with?("??") }.map { |l| l[3..] }
      deleted = status.select { |l| l[0] == "D" || l[1] == "D" }.map { |l| l[3..] }

      lines = []
      lines << "Modified: #{modified.join(', ')}" if modified.any?
      lines << "Added: #{added.join(', ')}" if added.any?
      lines << "Deleted: #{deleted.join(', ')}" if deleted.any?
      lines.any? ? "Working tree:\n#{lines.join("\n")}" : nil
    end

    def diff_section
      lines = []
      lines << "Staged:\n#{truncate(staged_diff)}" if staged_diff.any?
      lines << "Unstaged:\n#{truncate(unstaged_diff)}" if unstaged_diff.any?
      lines.join("\n\n")
    end

    def recent_commits_section
      "Recent commits:\n#{recent_commits.join("\n")}"
    end

    def truncate(lines)
      if lines.size > MAX_DIFF_LINES
        lines.first(MAX_DIFF_LINES).join + "\n... (#{lines.size - MAX_DIFF_LINES} more lines)"
      else
        lines.join
      end
    end
  end
end
