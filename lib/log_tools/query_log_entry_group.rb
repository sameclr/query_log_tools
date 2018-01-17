require 'active_support/core_ext/module/delegation'

module QueryLogTools
  class EntryGroup # Quacks like an Entry
    attr_reader :entries

    delegate :operation, :sql, :short_sql, :abstract_sql, :format_sql,
        :backtrace, :cached?, :fingerprint, :abstract_fingerprint, 
        to: :first_entry

    def initialize(entries)
      !entries.empty? or raise "Can't create empty group"
      @entries = entries
    end

    def count() @entries.size end
    def duration() @duration = @entries.sum(&:duration).round(1) end

  private
    # Only used as a target for delegation
    def first_entry() @entries.first end
  end
end
