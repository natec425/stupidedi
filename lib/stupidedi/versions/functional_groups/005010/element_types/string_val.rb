module Stupidedi
  module Versions
    module FunctionalGroups
      module FiftyTen
        module ElementTypes

          class AN < SimpleElementDef
            def companion
              StringVal
            end
          end

          #
          # @see X222.pdf B.1.1.3.1.4 String
          #
          class StringVal < Values::SimpleElementVal

            def string?
              true
            end

            def too_long?
              false
            end

            def too_short?
              false
            end

            #
            # Objects passed to StringVal.value that don't respond to #to_s are
            # modeled by this class. Note most everything in Ruby responds to
            # that method, including things that really shouldn't be considered
            # StringVals (like Array or Class), so other validation should be
            # performed on StringVal::NonEmpty values.
            #
            class Invalid < StringVal

              # @return [Object]
              attr_reader :value

              def initialize(value, usage, position)
                @value = value
                super(usage, position)
              end

              def valid?
                false
              end

              def empty?
                false
              end

              def extended?
                false
              end

              # @return [String]
              def inspect
                id = definition.bind do |d|
                  "[#{'% 5s' % d.id}: #{d.name}]".bind do |s|
                    if usage.forbidden?
                      ansi.forbidden(s)
                    elsif usage.required?
                      ansi.required(s)
                    else
                      ansi.optional(s)
                    end
                  end
                end

                ansi.element("AN.invalid#{id}") << "(#{ansi.invalid(@value.inspect)})"
              end

              # @return [String]
              def to_s
                ""
              end

              # @return [Boolean]
              def ==(other)
                eql?(other) or
                  (other.is_a?(Invalid) and @value == other.value)
              end
            end

            #
            # Empty string value. Shouldn't be directly instantiated -- instead,
            # use the {StringVal.empty} constructor.
            #
            class Empty < StringVal

              def valid?
                true
              end

              def empty?
                true
              end

              def extended?
                false
              end

              # @return [String]
              def inspect
                id = definition.bind do |d|
                  "[#{'% 5s' % d.id}: #{d.name}]".bind do |s|
                    if usage.forbidden?
                      ansi.forbidden(s)
                    elsif usage.required?
                      ansi.required(s)
                    else
                      ansi.optional(s)
                    end
                  end
                end

                ansi.element("AN.empty#{id}")
              end

              # @return [String]
              def to_s
                ""
              end

              # @return [Boolean]
              def ==(other)
                other.is_a?(Empty)
              end
            end

            #
            # Non-empty string value. Shouldn't be directly instantiated --
            # instead, use the {StringVal.value} constructor.
            #
            class NonEmpty < StringVal

              # @return [String]
              attr_reader :value

              delegate :to_d, :to_s, :to_f, :length, :=~, :match, :to => :@value

              def initialize(string, usage, position)
                @value = string
                super(usage, position)
              end

              # @return [NonEmpty]
              def copy(changes = {})
                NonEmpty.new \
                  changes.fetch(:value, @value),
                  changes.fetch(:usage, usage),
                  changes.fetch(:position, position)
              end

              def too_long?
                @value.lstrip.length > definition.max_length
              end

              def too_short?
                @value.lstrip.length < definition.min_length
              end

              # @return [String]
              def inspect
                id = definition.bind do |d|
                  "[#{'% 5s' % d.id}: #{d.name}]".bind do |s|
                    if usage.forbidden?
                      ansi.forbidden(s)
                    elsif usage.required?
                      ansi.required(s)
                    else
                      ansi.optional(s)
                    end
                  end
                end

                value  = @value.slice(0, definition.max_length)
                value << ansi.invalid(@value.slice(definition.max_length..-1).to_s)

                ansi.element("AN.value#{id}") << "(#{value})"
              end

              def valid?
                true
              end

              def empty?
                false
              end

              def extended?
                Reader.has_extended_characters?(@value)
              end

              # @return [StringVal::NonEmpty]
              def gsub(*args, &block)
                copy(:value => @value.gsub(*args, &block))
              end

              # @return [StringVal::NonEmpty]
              def upcase
                copy(:value => @value.upcase)
              end

              # @return [StringVal::NonEmpty]
              def downcase
                copy(:value => @value.downcase)
              end

              # @return [Boolean]
              def ==(other)
                eql?(other) or
                 (if other.is_a?(NonEmpty)
                    other.value == @value
                  else
                    other == @value
                  end)
              end
            end

          end

          class << StringVal
            # @group Constructors
            ###################################################################

            # @return [StringVal]
            def empty(usage, position)
              StringVal::Empty.new(usage, position)
            end

            # @return [StringVal]
            def value(object, usage, position)
              if object.blank?
                StringVal::Empty.new(usage, position)
              elsif object.respond_to?(:to_s)
                StringVal::NonEmpty.new(object.to_s, usage, position)
              else
                StringVal::Invalid.new(object, usage, position)
              end
            end

            # @return [StringVal]
            def parse(string, usage, position)
              if string.blank?
                StringVal::Empty.new(usage, position)
              else
                StringVal::NonEmpty.new(string.to_s, usage, position)
              end
            end

            # @endgroup
            ###################################################################
          end

          # Prevent direct instantiation of abstract class StringVal
          StringVal.eigenclass.send(:protected, :new)
          StringVal::Empty.eigenclass.send(:public, :new)
          StringVal::Invalid.eigenclass.send(:public, :new)
          StringVal::NonEmpty.eigenclass.send(:public, :new)
        end

      end
    end
  end
end
