require 'uri'

require_relative 'output'

module RedmineCLI
  module Helpers
    #
    # Helpers for input
    #
    module Input
      include Helpers::Output

      #
      # prints names as enumerable list and asks user for element
      #
      def ask_for_object(object_list)
        fail EmptyList if object_list.size.zero?

        # From 1
        i = 0
        object_list = object_list.map { |obj| [(i += 1), obj] }.to_h

        print_object_list(object_list)
        puts
        input = ask m(:enter_object_number),
                    default: '1',
                    limited_to: ->(str) { (1..i).cover? str.to_i }

        object_list[input.to_i]
      end

      #
      # Parses time from user's input.
      # Formats: HH:MM; M; H.h
      #
      # @param input [String]
      #
      def parse_time(input)
        fail(BadInputTime) unless input =~ /^\d+[\:\.]?\d*/

        if input.include?(':')
          h, m = input.split(':').map(&:to_i)
          (60 * h + m) / 60.0
        elsif input.include?('.')
          input.to_f
        else
          input.to_i
        end
      end

      #
      # #ask with :limited_to set to url regexp
      #
      def ask_url(text, params = {})
        params[:limited_to] = /\A#{URI.regexp(%w('http', 'https'))}\z/
        ask(text, params)
      end

      #
      # Asks user for something.
      #
      # Params:
      # * `:default`
      # * `:limited_to` - can be `Array<String>` or `Regexp`
      # * `:required` - force user input until it's not empty
      #
      def ask(text, params = {})
        default_set = params.key?(:default)
        if params[:required]
          fail('required + default options') if default_set
          fail('required + array with limits') if params[:limited_to].is_a? Array
        end

        print_prompt_message(text, params)
        input = read(params)

        return params[:default] if default_set && input.empty?
        input
      end

      private

      def read(params)
        return read_with_limitations(params) if params[:limited_to]
        return read_until_not_empty if params[:required]

        read_line
      end

      def read_until_not_empty
        loop do
          input = read_line
          return input unless input.empty?

          puts m(:error_input_required)
        end
      end

      def read_with_limitations(params)
        input = nil

        loop do
          input = read_line
          break if fit_in_limit?(input, params[:limited_to])
          return params[:default] if input.empty? && params.key?(:default)

          puts m(:error_try_again)
        end

        input
      end

      def fit_in_limit?(input, limit)
        case limit
        when Array then limit.include?(input)
        when Proc then limit.call(input)
        when Regexp then limit =~ input

        else fail('limit should be Array or Regexp or Proc')
        end
      end

      def read_line
        $stdin.gets.chomp
      end
    end
  end
end