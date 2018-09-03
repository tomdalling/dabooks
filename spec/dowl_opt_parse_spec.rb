require 'dowl_opt_parse'

RSpec.describe DowlOptParse do
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
    expect(result_options).to eq(result.options)
    expect(free_args).to eq(result.free_args)
  end

  def assert_parse_raises(cmdline, msg, options={})
    config = options.fetch(:config, SCHEMA)
    expect {
      DowlOptParse.parse(config, Shellwords.split(cmdline))
    }.to raise_error(msg)
  end

  specify 'short flags' do
    assert_parse '-c', { cat: true }
    assert_parse '-cd', { cat: true, dog: true }
  end

  specify 'long flags' do
    assert_parse '--cat', { cat: true }
    assert_parse '--cat --dog', { cat: true, dog: true }
  end

  specify 'option arguments' do
    assert_parse '-n Tom', { name: 'Tom' }
    assert_parse '--name Dowl', { name: 'Dowl' }
    assert_parse '-cn Dane', { cat: true, name: 'Dane' }
  end

  specify 'free arguments' do
    assert_parse 'hello world', {}, ['hello', 'world']
    assert_parse '-c hello --name Tom world', { cat: true, name: 'Tom'}, ['hello', 'world']
  end

  specify 'double hyphen' do
    assert_parse '-c --', { cat: true }
    assert_parse '-c -- -d -a 5 hello', { cat: true }, ['-d', '-a', '5', 'hello']
  end

  specify 'coercion' do
    assert_parse '-a 5', { age: 5 }
    assert_parse '--time 1.23', { time: 1.23 }
  end

  specify 'defaults' do
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

  specify 'config formatter' do
    expect(DowlOptParse.format(SCHEMA)).to eq(<<~END_STRING.strip)
      --cat, -c
          Enable cats.
      --dog, -d
          Enable dogs. This is a particularly long string, so here is a line break:
          There. Wasn't that easy.
      --name, -n string
      -a integer
      --time float
    END_STRING
  end

  specify 'option argument missing' do
    assert_parse_raises '-a', 'Required argument missing for flag: -a'
    assert_parse_raises '-c -a', 'Required argument missing for flag: -a'
    assert_parse_raises '-ca', 'Required argument missing for flag: -a'
    assert_parse_raises '-ac', 'Required argument missing for flag: -a'
  end

  specify 'required options missing' do
    assert_parse_raises '', 'Required flag is missing: --whatever, -w', config: {
      whatever: {
        required: true,
        argument: :integer,
        long: '--whatever',
        short: '-w',
      }
    }
  end

  specify 'argument coercer not defined' do
    assert_parse_raises '-w 5', 'Unrecognised argument type for flag -w: :wigwam', config: {
      whatever: {
        short: '-w',
        argument: :wigwam,
      }
    }
  end

  specify 'undefined flag' do
    assert_parse_raises '-x', 'Unrecognised flag: -x'
  end

  specify 'bool coercer' do
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

  specify 'missing or invalid option params' do
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
  skip 'option argument alternate syntax' do
    expect(p('-n=Tom'), { name: 'Tom' })
    expect(p('-cn=Dowl'), { cat: true, name: 'Dowl'})
    expect(p('--name=Dane'), { name: 'Dane' })
  end
end
