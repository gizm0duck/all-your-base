module AllYourBase
  class Are

    # This charset works for "standard" bases 2-36 and 62.  It also provides
    # non-standard bases 1 and 37-61 for most uses.
    BASE_62_CHARSET = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a

    # This is the base64 encoding charset, but note that this library does not
    # provide true base64 encoding.
    BASE_64_CHARSET = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a +
                      ['+', '/']

    # This is a _maximum_ URL safe charset (between /'s).  Not all sites know
    # or care about the validity of these characters.
    BASE_78_CHARSET = BASE_62_CHARSET + ['!', '$', '&', "'", '(', ')', '*', '+',
                                         ',', '-', '.', ':', ';', '=', '@', '_']

    DEFAULT_OPTIONS = {:charset => BASE_78_CHARSET, :honor_negation => false}

    def initialize(options={})
      @default_options = DEFAULT_OPTIONS.merge(options)
      @default_options = merge_and_validate_options
    end

    def convert_to_base_10(string, options={})
      options = merge_and_validate_options(options)

      negate = false
      if options[:honor_negation]
        negate = string[0...1] == '-'
        string = string[1...string.size] if negate
      end

      if string.size < 1
        raise ArgumentError.new('string too small ' << string.size.to_s)
      end
      if !string.match(/\A[#{Regexp.escape(options[:charset][0...options[:radix]].join(''))}]+\Z/)
        raise ArgumentError.new('invalid characters')
      end
      regexp = Regexp.new(options[:charset].map{|c| Regexp.escape(c)}.join('|'))
      result = 0
      index = 0
      string.reverse.scan(regexp) do |c|
        result += options[:charset].index(c) * (options[:radix] ** index)
        index += 1
      end
      return result * (negate ? -1 : 1)
    end

    def convert_from_base_10(int, options={})
      options = merge_and_validate_options(options)

      if !int.to_s.match(/\A-?[0-9]+\Z/)
        raise ArgumentError.new('invalid characters')
      end
      int = int.to_i
      return '0' if int == 0

      negate = false
      if options[:honor_negation]
        negate = int < 0
      end
      int = int.abs

      if options[:radix] == 1
        result = options[:charset].first * int
      else
        s = ''
        while int > 0
          s << options[:charset][int.modulo(options[:radix])]
          int /= options[:radix]
        end
        result = s.reverse
      end
      return ((negate ? '-' : '') << result)
    end

    def self.convert_to_base_10(string, options={})
      @@ayb ||= self.new
      @@ayb.convert_to_base_10(string, options)
    end

    def self.convert_from_base_10(int, options={})
      @@ayb ||= self.new
      @@ayb.convert_from_base_10(int, options)
    end

    private
    def merge_and_validate_options(options={})
      options = @default_options.merge(options)
      options[:radix] ||= options[:charset].size
      if options[:charset].size < 1 || options[:charset].size < options[:radix]
        raise ArgumentError.new('charset too small ' << options[:charset].size.to_s)
      elsif options[:radix] < 1
        raise ArgumentError.new('illegal radix ' << options[:radix].to_s)
      elsif options[:charset].include?('-') && options[:honor_negation]
        raise ArgumentError.new('"-" is unsupported in charset when honor_negation is set')
      end
      return options
    end
  end
end
