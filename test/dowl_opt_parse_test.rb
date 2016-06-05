require 'dowl_opt_parse'
require 'shellwords'

class DowlOptParseTest < Minitest::Test
  SCHEMA = {
    cat: {
      long: '--cat',
      short: '-c',
      doc: 'Enable cats.'
    },
    dog: {
      long: '--dog',
      short: '-d',
      doc: "Enable dogs. This is a particularly long string, so here is a line break:\nThere. Wasn't that easy."
    },
    name: {
      argument: :string,
      long: '--name',
      short: '-n',
    },
    age: {
      argument: :integer,
      short: '-a',
    },
    time: {
      argument: :float,
      long: '--time',
    }
  }

  def assert_parse(cmdline, result_options, free_args = [], options = {})
    config = options.fetch(:config, SCHEMA)
    result = DowlOptParse.parse(config, Shellwords.split(cmdline))
    assert_equal result_options, result.options
    assert_equal free_args, result.free_args
  end

  def assert_parse_raises(cmdline, msg, options={})
    config = options.fetch(:config, SCHEMA)
    ex = assert_raises { DowlOptParse.parse(config, Shellwords.split(cmdline)) }
    assert_equal msg, ex.message
  end

  def test_short_flags
    assert_parse '-c', { cat: true }
    assert_parse '-cd', { cat: true, dog: true }
  end

  def test_long_flags
    assert_parse '--cat', { cat: true }
    assert_parse '--cat --dog', { cat: true, dog: true }
  end

  def test_option_arguments
    assert_parse '-n Tom', { name: 'Tom' }
    assert_parse '--name Dowl', { name: 'Dowl' }
    assert_parse '-cn Dane', { cat: true, name: 'Dane' }
  end

  def test_free_arguments
    assert_parse 'hello world', {}, ['hello', 'world']
    assert_parse '-c hello --name Tom world', { cat: true, name: 'Tom'}, ['hello', 'world']
  end

  def test_double_hypen
    assert_parse '-c --', { cat: true }
    assert_parse '-c -- -d -a 5 hello', { cat: true }, ['-d', '-a', '5', 'hello']
  end

  def test_coercion
    assert_parse '-a 5', { age: 5 }
    assert_parse '--time 1.23', { time: 1.23 }
  end

  def test_defaults
    config = {
      name: {
        argument: :string,
        short: '-n',
        default: 'Anon',
      }
    }

    assert_parse '', { name: 'Anon' }, [], config: config
    assert_parse '-n Dane', { name: 'Dane' }, [], config: config
  end

  def test_config_formatter
    expected = <<~EOS.strip
      --cat, -c
          Enable cats.
      --dog, -d
          Enable dogs. This is a particularly long string, so here is a line break:
          There. Wasn't that easy.
      --name, -n string
      -a integer
      --time float
    EOS
    actual = DowlOptParse.format(SCHEMA)

    assert_equal expected, actual
  end

  def test_option_argument_missing
    assert_parse_raises '-a', 'Required argument missing for flag: -a'
    assert_parse_raises '-c -a', 'Required argument missing for flag: -a'
    assert_parse_raises '-ca', 'Required argument missing for flag: -a'
    assert_parse_raises '-ac', 'Required argument missing for flag: -a'
  end

  def test_required_options_missing
    assert_parse_raises '', 'Required flag is missing: --whatever, -w', config: {
      whatever: {
        required: true,
        argument: :integer,
        long: '--whatever',
        short: '-w',
      }
    }
  end

  def test_argument_coercer_not_defined
    assert_parse_raises '-w 5', 'Unrecognised argument type for flag -w: :wigwam', config: {
      whatever: {
        short: '-w',
        argument: :wigwam,
      }
    }
  end

  def test_undefined_flag
    assert_parse_raises '-x', 'Unrecognised flag: -x'
  end

  def test_bool_coercer
    config = {
      boo: {
        argument: :bool,
        short: '-b',
      }
    }

    ['true', 'TRUE', 'yes', 'YES', 'y', 'Y'].each do |arg|
      assert_parse "-b #{arg}", { boo: true }, [], config: config
    end
    ['false', 'FALSE', 'no', 'NO', 'n', 'N'].each do |arg|
      assert_parse "-b #{arg}", { boo: false }, [], config: config
    end

    assert_parse_raises '-b waka', 'Value for flag -b is not a bool: waka', config: config
  end

  def test_missing_or_invalid_option_flags
    assert_parse_raises '', 'Option :missing must provide a :short or :long flag', config: {
      missing: { doc: 'This has no long or short flags' },
    }
    assert_parse_raises '', 'Option :invalid_short has invalid short flag: "--actually-long"', config: {
      invalid_short: { short: '--actually-long' }
    }
    assert_parse_raises '', 'Option :invalid_short2 has invalid short flag: "a"', config: {
      invalid_short2: { short: 'a' }
    }
    assert_parse_raises '', 'Option :invalid_long has invalid long flag: "-s"', config: {
      invalid_long: { long: '-s' }
    }
    assert_parse_raises '', 'Option :invalid_long2 has invalid long flag: "abc"', config: {
      invalid_long2: { long: 'abc' }
    }
  end

  # TODO: maybe implement this
  def disabled_test_option_argument_alternate_syntax
    assert_equal({ name: 'Tom' }, p('-n=Tom'))
    assert_equal({ cat: true, name: 'Dowl'}, p('-cn=Dowl'))
    assert_equal({ name: 'Dane' }, p('--name=Dane'))
  end
end
