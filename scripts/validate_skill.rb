#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "yaml"

root = Pathname.new(__dir__).join("..").expand_path
errors = []

skill_path = root.join("SKILL.md")
skill = skill_path.read

unless skill.start_with?("---\n")
  errors << "SKILL.md is missing YAML frontmatter"
end

frontmatter = skill.match(/\A---\n(.*?)\n---/m)&.[](1)

begin
  metadata = YAML.safe_load(frontmatter || "", aliases: false) || {}
  errors << "SKILL.md frontmatter missing name" if metadata["name"].to_s.empty?
  errors << "SKILL.md frontmatter missing description" if metadata["description"].to_s.empty?
rescue Psych::SyntaxError => error
  errors << "SKILL.md frontmatter is invalid YAML: #{error.message}"
end

markdown_files = Dir.glob(root.join("**/*.md").to_s).map { |path| Pathname.new(path) }
markdown_files.reject! { |path| path.to_s.include?("/.git/") }
markdown_files.reject! { |path| path.lstat.symlink? }

markdown_files.each do |path|
  relative = path.relative_path_from(root)
  content = path.read

  errors << "#{relative}: missing final newline" unless content.end_with?("\n")

  content.each_line.with_index(1) do |line, number|
    errors << "#{relative}:#{number}: trailing whitespace" if line.match?(/[ \t]+\n\z/)
  end
end

referenced_paths = skill.scan(/`([^`]*(?:STYLE\.md|references\/[^`]+|scripts\/[^`]+|agents\/[^`]+))`/).flatten

referenced_paths.each do |reference|
  path = root.join(reference)
  errors << "Missing referenced path: #{reference}" unless path.exist?
end

required_paths = %w[
  agents/openai.yaml
  references/03a-active-record-postgresql.md
  scripts/validate_skill.rb
]

required_paths.each do |reference|
  errors << "Missing required path: #{reference}" unless root.join(reference).exist?
end

stale_phrases = [
  "Testing strategy (Minitest/RSpec alignment)",
  "Prefer Rails 8.1 built-in authentication",
  "parameter object",
  "./skills/rails-conventions",
  ".claude-plugin",
  "skills/conventions",
  "agent_skills",
  "agent-skills"
]

markdown_files.each do |path|
  relative = path.relative_path_from(root)
  content = path.read

  stale_phrases.each do |phrase|
    errors << "#{relative}: stale phrase #{phrase.inspect}" if content.include?(phrase)
  end
end

standalone_forbidden_paths = %w[
  .claude-plugin
  skills/conventions
]

standalone_forbidden_paths.each do |reference|
  errors << "Standalone skill must not include #{reference}" if root.join(reference).exist?
end

if errors.any?
  warn errors.join("\n")
  exit 1
end

puts "rails-conventions skill validation passed"
