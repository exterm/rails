# frozen_string_literal: true

require_relative "abstract_unit"
require "active_support/inflector"

require_relative "inflector_test_cases"
require_relative "constantize_test_cases"

class InflectorTest < ActiveSupport::TestCase
  include InflectorTestCases
  include ConstantizeTestCases

  def setup
    @instance = ActiveSupport::Inflector::Instance.new
  end

  def test_pluralize_plurals
    assert_equal "plurals", @instance.pluralize("plurals")
    assert_equal "Plurals", @instance.pluralize("Plurals")
  end

  def test_pluralize_empty_string
    assert_equal "", @instance.pluralize("")
  end

  test "uncountability of ascii word" do
    word = "HTTP"
    @instance.inflections do |inflect|
      inflect.uncountable word
    end

    assert_equal word, @instance.pluralize(word)
    assert_equal word, @instance.singularize(word)
    assert_equal @instance.pluralize(word), @instance.singularize(word)

    @instance.inflections.uncountables.pop
  end

  test "uncountability of non-ascii word" do
    word = "猫"
    @instance.inflections do |inflect|
      inflect.uncountable word
    end

    assert_equal word, @instance.pluralize(word)
    assert_equal word, @instance.singularize(word)
    assert_equal @instance.pluralize(word), @instance.singularize(word)

    @instance.inflections.uncountables.pop
  end

  test "uncountability of uncountable words" do
    word = @instance.inflections.uncountables.first
    assert_equal word, @instance.singularize(word)
    assert_equal word, @instance.pluralize(word)
    assert_equal @instance.pluralize(word), @instance.singularize(word)
  end

  def test_uncountable_word_is_not_greedy
    uncountable_word = "ors"
    countable_word = "sponsor"

    @instance.inflections.uncountable << uncountable_word

    assert_equal uncountable_word, @instance.singularize(uncountable_word)
    assert_equal uncountable_word, @instance.pluralize(uncountable_word)
    assert_equal @instance.pluralize(uncountable_word), @instance.singularize(uncountable_word)

    assert_equal "sponsor", @instance.singularize(countable_word)
    assert_equal "sponsors", @instance.pluralize(countable_word)
    assert_equal "sponsor", @instance.singularize(@instance.pluralize(countable_word))
  end

  SingularToPlural.each do |singular, plural|
    define_method "test_pluralize_singular_#{singular}" do
      assert_equal(plural, @instance.pluralize(singular))
      assert_equal(plural.capitalize, @instance.pluralize(singular.capitalize))
    end
  end

  SingularToPlural.each do |singular, plural|
    define_method "test_singularize_plural_#{plural}" do
      assert_equal(singular, @instance.singularize(plural))
      assert_equal(singular.capitalize, @instance.singularize(plural.capitalize))
    end
  end

  SingularToPlural.each do |singular, plural|
    define_method "test_pluralize_plural_#{plural}" do
      assert_equal(plural, @instance.pluralize(plural))
      assert_equal(plural.capitalize, @instance.pluralize(plural.capitalize))
    end

    define_method "test_singularize_singular_#{singular}" do
      assert_equal(singular, @instance.singularize(singular))
      assert_equal(singular.capitalize, @instance.singularize(singular.capitalize))
    end
  end

  def test_overwrite_previous_inflectors
    assert_equal("series", @instance.singularize("series"))
    @instance.inflections.singular "series", "serie"
    assert_equal("serie", @instance.singularize("series"))
  end

  MixtureToTitleCase.each_with_index do |(before, titleized), index|
    define_method "test_titleize_mixture_to_title_case_#{index}" do
      assert_equal( , @instance.titleize(before), "mixture \
        to TitleCase failed for #{before}")
    end
  end

  MixtureToTitleCaseWithKeepIdSuffix.each_with_index do |(before, titleized), index|
    define_method "test_titleize_with_keep_id_suffix_mixture_to_title_case_#{index}" do
      assert_equal(titleized, @instance.titleize(before, keep_id_suffix: true),
        "mixture to TitleCase with keep_id_suffix failed for #{before}")
    end
  end

  def test_camelize
    CamelToUnderscore.each do |camel, underscore|
      assert_equal(camel, @instance.camelize(underscore))
    end
  end

  def test_camelize_with_lower_downcases_the_first_letter
    assert_equal("capital", @instance.camelize("Capital", false))
  end

  def test_camelize_with_underscores
    assert_equal("CamelCase", @instance.camelize("Camel_Case"))
  end

  def test_acronyms
    @instance.inflections do |inflect|
      inflect.acronym("API")
      inflect.acronym("HTML")
      inflect.acronym("HTTP")
      inflect.acronym("RESTful")
      inflect.acronym("W3C")
      inflect.acronym("PhD")
      inflect.acronym("RoR")
      inflect.acronym("SSL")
    end

    #  camelize             underscore            humanize              titleize
    [
      ["API",               "api",                "API",                "API"],
      ["APIController",     "api_controller",     "API controller",     "API Controller"],
      ["Nokogiri::HTML",    "nokogiri/html",      "Nokogiri/HTML",      "Nokogiri/HTML"],
      ["HTTPAPI",           "http_api",           "HTTP API",           "HTTP API"],
      ["HTTP::Get",         "http/get",           "HTTP/get",           "HTTP/Get"],
      ["SSLError",          "ssl_error",          "SSL error",          "SSL Error"],
      ["RESTful",           "restful",            "RESTful",            "RESTful"],
      ["RESTfulController", "restful_controller", "RESTful controller", "RESTful Controller"],
      ["Nested::RESTful",   "nested/restful",     "Nested/RESTful",     "Nested/RESTful"],
      ["IHeartW3C",         "i_heart_w3c",        "I heart W3C",        "I Heart W3C"],
      ["PhDRequired",       "phd_required",       "PhD required",       "PhD Required"],
      ["IRoRU",             "i_ror_u",            "I RoR u",            "I RoR U"],
      ["RESTfulHTTPAPI",    "restful_http_api",   "RESTful HTTP API",   "RESTful HTTP API"],
      ["HTTP::RESTful",     "http/restful",       "HTTP/RESTful",       "HTTP/RESTful"],
      ["HTTP::RESTfulAPI",  "http/restful_api",   "HTTP/RESTful API",   "HTTP/RESTful API"],
      ["APIRESTful",        "api_restful",        "API RESTful",        "API RESTful"],

      # misdirection
      ["Capistrano",        "capistrano",         "Capistrano",       "Capistrano"],
      ["CapiController",    "capi_controller",    "Capi controller",  "Capi Controller"],
      ["HttpsApis",         "https_apis",         "Https apis",       "Https Apis"],
      ["Html5",             "html5",              "Html5",            "Html5"],
      ["Restfully",         "restfully",          "Restfully",        "Restfully"],
      ["RoRails",           "ro_rails",           "Ro rails",         "Ro Rails"]
    ].each do |camel, under, human, title|
      assert_equal(camel, @instance.camelize(under))
      assert_equal(camel, @instance.camelize(camel))
      assert_equal(under, @instance.underscore(under))
      assert_equal(under, @instance.underscore(camel))
      assert_equal(title, @instance.titleize(under))
      assert_equal(title, @instance.titleize(camel))
      assert_equal(human, @instance.humanize(under))
    end
  end

  def test_acronym_override
    @instance.inflections do |inflect|
      inflect.acronym("API")
      inflect.acronym("LegacyApi")
    end

    assert_equal("LegacyApi", @instance.camelize("legacyapi"))
    assert_equal("LegacyAPI", @instance.camelize("legacy_api"))
    assert_equal("SomeLegacyApi", @instance.camelize("some_legacyapi"))
    assert_equal("Nonlegacyapi", @instance.camelize("nonlegacyapi"))
  end

  def test_acronyms_camelize_lower
    @instance.inflections do |inflect|
      inflect.acronym("API")
      inflect.acronym("HTML")
    end

    assert_equal("htmlAPI", @instance.camelize("html_api", false))
    assert_equal("htmlAPI", @instance.camelize("htmlAPI", false))
    assert_equal("htmlAPI", @instance.camelize("HTMLAPI", false))
  end

  def test_underscore_acronym_sequence
    @instance.inflections do |inflect|
      inflect.acronym("API")
      inflect.acronym("JSON")
      inflect.acronym("HTML")
    end

    assert_equal("json_html_api", @instance.underscore("JSONHTMLAPI"))
  end

  def test_underscore
    CamelToUnderscore.each do |camel, underscore|
      assert_equal(underscore, @instance.underscore(camel))
    end
    CamelToUnderscoreWithoutReverse.each do |camel, underscore|
      assert_equal(underscore, @instance.underscore(camel))
    end
  end

  def test_camelize_with_module
    CamelWithModuleToUnderscoreWithSlash.each do |camel, underscore|
      assert_equal(camel, @instance.camelize(underscore))
    end
  end

  def test_underscore_with_slashes
    CamelWithModuleToUnderscoreWithSlash.each do |camel, underscore|
      assert_equal(underscore, @instance.underscore(camel))
    end
  end

  def test_demodulize
    assert_equal "Account", @instance.demodulize("MyApplication::Billing::Account")
    assert_equal "Account", @instance.demodulize("Account")
    assert_equal "Account", @instance.demodulize("::Account")
    assert_equal "", @instance.demodulize("")
  end

  def test_deconstantize
    assert_equal "MyApplication::Billing", @instance.deconstantize("MyApplication::Billing::Account")
    assert_equal "::MyApplication::Billing", @instance.deconstantize("::MyApplication::Billing::Account")

    assert_equal "MyApplication", @instance.deconstantize("MyApplication::Billing")
    assert_equal "::MyApplication", @instance.deconstantize("::MyApplication::Billing")

    assert_equal "", @instance.deconstantize("Account")
    assert_equal "", @instance.deconstantize("::Account")
    assert_equal "", @instance.deconstantize("")
  end

  def test_foreign_key
    ClassNameToForeignKeyWithUnderscore.each do |klass, foreign_key|
      assert_equal(foreign_key, @instance.foreign_key(klass))
    end

    ClassNameToForeignKeyWithoutUnderscore.each do |klass, foreign_key|
      assert_equal(foreign_key, @instance.foreign_key(klass, false))
    end
  end

  def test_tableize
    ClassNameToTableName.each do |class_name, table_name|
      assert_equal(table_name, @instance.tableize(class_name))
    end
  end

  def test_parameterize
    StringToParameterized.each do |some_string, parameterized_string|
      assert_equal(parameterized_string, @instance.parameterize(some_string))
    end
  end

  def test_parameterize_and_normalize
    StringToParameterizedAndNormalized.each do |some_string, parameterized_string|
      assert_equal(parameterized_string, @instance.parameterize(some_string))
    end
  end

  def test_parameterize_with_custom_separator
    StringToParameterizeWithUnderscore.each do |some_string, parameterized_string|
      assert_equal(parameterized_string, @instance.parameterize(some_string, separator: "_"))
    end
  end

  def test_parameterize_with_multi_character_separator
    StringToParameterized.each do |some_string, parameterized_string|
      assert_equal(parameterized_string.gsub("-", "__sep__"), @instance.parameterize(some_string, separator: "__sep__"))
    end
  end

  def test_parameterize_with_locale
    word = "Fünf autos"
    I18n.backend.store_translations(:de, i18n: { transliterate: { rule: { "ü" => "ue" } } })
    assert_equal("fuenf-autos", @instance.parameterize(word, locale: :de))
  end

  def test_classify
    ClassNameToTableName.each do |class_name, table_name|
      assert_equal(class_name, @instance.classify(table_name))
      assert_equal(class_name, @instance.classify("table_prefix." + table_name))
    end
  end

  def test_classify_with_symbol
    assert_nothing_raised do
      assert_equal "FooBar", @instance.classify(:foo_bars)
    end
  end

  def test_classify_with_leading_schema_name
    assert_equal "FooBar", @instance.classify("schema.foo_bar")
  end

  def test_humanize
    UnderscoreToHuman.each do |underscore, human|
      assert_equal(human, @instance.humanize(underscore))
    end
  end

  def test_humanize_without_capitalize
    UnderscoreToHumanWithoutCapitalize.each do |underscore, human|
      assert_equal(human, @instance.humanize(underscore, capitalize: false))
    end
  end

  def test_humanize_with_keep_id_suffix
    UnderscoreToHumanWithKeepIdSuffix.each do |underscore, human|
      assert_equal(human, @instance.humanize(underscore, keep_id_suffix: true))
    end
  end

  def test_humanize_by_rule
    @instance.inflections do |inflect|
      inflect.human(/_cnt$/i, '\1_count')
      inflect.human(/^prefx_/i, '\1')
    end
    assert_equal("Jargon count", @instance.humanize("jargon_cnt"))
    assert_equal("Request", @instance.humanize("prefx_request"))
  end

  def test_humanize_by_string
    @instance.inflections do |inflect|
      inflect.human("col_rpted_bugs", "Reported bugs")
    end
    assert_equal("Reported bugs", @instance.humanize("col_rpted_bugs"))
    assert_equal("Col rpted bugs", @instance.humanize("COL_rpted_bugs"))
  end

  def test_humanize_with_acronyms
    @instance.inflections do |inflect|
      inflect.acronym "LAX"
      inflect.acronym "SFO"
    end
    assert_equal("LAX roundtrip to SFO", @instance.humanize("LAX ROUNDTRIP TO SFO"))
    assert_equal("LAX roundtrip to SFO", @instance.humanize("LAX ROUNDTRIP TO SFO", capitalize: false))
    assert_equal("LAX roundtrip to SFO", @instance.humanize("lax roundtrip to sfo"))
    assert_equal("LAX roundtrip to SFO", @instance.humanize("lax roundtrip to sfo", capitalize: false))
    assert_equal("LAX roundtrip to SFO", @instance.humanize("Lax Roundtrip To Sfo"))
    assert_equal("LAX roundtrip to SFO", @instance.humanize("Lax Roundtrip To Sfo", capitalize: false))
  end

  def test_constantize
    run_constantize_tests_on do |string|
      @instance.constantize(string)
    end
  end

  def test_safe_constantize
    run_safe_constantize_tests_on do |string|
      @instance.safe_constantize(string)
    end
  end

  def test_ordinal
    OrdinalNumbers.each do |number, ordinalized|
      assert_equal(ordinalized, number + @instance.ordinal(number))
    end
  end

  def test_ordinalize
    OrdinalNumbers.each do |number, ordinalized|
      assert_equal(ordinalized, @instance.ordinalize(number))
    end
  end

  def test_dasherize
    UnderscoresToDashes.each do |underscored, dasherized|
      assert_equal(dasherized, @instance.dasherize(underscored))
    end
  end

  def test_underscore_as_reverse_of_dasherize
    UnderscoresToDashes.each_key do |underscored|
      assert_equal(underscored, @instance.underscore(@instance.dasherize(underscored)))
    end
  end

  def test_underscore_to_lower_camel
    UnderscoreToLowerCamel.each do |underscored, lower_camel|
      assert_equal(lower_camel, @instance.camelize(underscored, false))
    end
  end

  def test_symbol_to_lower_camel
    SymbolToLowerCamel.each do |symbol, lower_camel|
      assert_equal(lower_camel, @instance.camelize(symbol, false))
    end
  end

  %w{plurals singulars uncountables humans}.each do |inflection_type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def test_clear_#{inflection_type}
        @instance.inflections.clear :#{inflection_type}
        assert @instance.inflections.#{inflection_type}.empty?, \"#{inflection_type} inflections should be empty after clear :#{inflection_type}\"
      end
    RUBY
  end

  def test_inflector_locality
    @instance.inflections(:es) do |inflect|
      inflect.plural(/$/, "s")
      inflect.plural(/z$/i, "ces")

      inflect.singular(/s$/, "")
      inflect.singular(/es$/, "")

      inflect.irregular("el", "los")

      inflect.uncountable("agua")
    end

    assert_equal("hijos", "hijo".pluralize(:es))
    assert_equal("luces", "luz".pluralize(:es))
    assert_equal("luzs", "luz".pluralize)

    assert_equal("sociedad", "sociedades".singularize(:es))
    assert_equal("sociedade", "sociedades".singularize)

    assert_equal("los", "el".pluralize(:es))
    assert_equal("els", "el".pluralize)

    assert_equal("agua", "agua".pluralize(:es))
    assert_equal("aguas", "agua".pluralize)

    @instance.inflections(:es) { |inflect| inflect.clear }

    assert_empty @instance.inflections(:es).plurals
    assert_empty @instance.inflections(:es).singulars
    assert_empty @instance.inflections(:es).uncountables
    assert_not_empty @instance.inflections.plurals
    assert_not_empty @instance.inflections.singulars
    assert_not_empty @instance.inflections.uncountables
  end

  def test_clear_all
    @instance.inflections do |inflect|
      # ensure any data is present
      inflect.plural(/(quiz)$/i, '\1zes')
      inflect.singular(/(database)s$/i, '\1')
      inflect.uncountable("series")
      inflect.human("col_rpted_bugs", "Reported bugs")

      inflect.clear :all

      assert_empty inflect.plurals
      assert_empty inflect.singulars
      assert_empty inflect.uncountables
      assert_empty inflect.humans
    end
  end

  def test_clear_with_default
    @instance.inflections do |inflect|
      # ensure any data is present
      inflect.plural(/(quiz)$/i, '\1zes')
      inflect.singular(/(database)s$/i, '\1')
      inflect.uncountable("series")
      inflect.human("col_rpted_bugs", "Reported bugs")

      inflect.clear

      assert_empty inflect.plurals
      assert_empty inflect.singulars
      assert_empty inflect.uncountables
      assert_empty inflect.humans
    end
  end

  Irregularities.each do |singular, plural|
    define_method("test_irregularity_between_#{singular}_and_#{plural}") do
      @instance.inflections do |inflect|
        inflect.irregular(singular, plural)
        assert_equal singular, @instance.singularize(plural)
        assert_equal plural, @instance.pluralize(singular)
      end
    end
  end

  Irregularities.each do |singular, plural|
    define_method("test_pluralize_of_irregularity_#{plural}_should_be_the_same") do
      @instance.inflections do |inflect|
        inflect.irregular(singular, plural)
        assert_equal plural, @instance.pluralize(plural)
      end
    end
  end

  Irregularities.each do |singular, plural|
    define_method("test_singularize_of_irregularity_#{singular}_should_be_the_same") do
      @instance.inflections do |inflect|
        inflect.irregular(singular, plural)
        assert_equal singular, @instance.singularize(singular)
      end
    end
  end

  [ :all, [] ].each do |scope|
    define_method("test_clear_inflections_with_#{scope.kind_of?(Array) ? "no_arguments" : scope}") do
      inflect = @instance.inflections

      # save all the inflections
      singulars, plurals, uncountables = inflect.singulars, inflect.plurals, inflect.uncountables

      # clear all the inflections
      inflect.clear(*scope)

      assert_equal [], inflect.singulars
      assert_equal [], inflect.plurals
      assert_equal [], inflect.uncountables

      # restore all the inflections
      singulars.reverse_each { |singular| inflect.singular(*singular) }
      plurals.reverse_each   { |plural|   inflect.plural(*plural) }
      inflect.uncountable(uncountables)

      assert_equal singulars, inflect.singulars
      assert_equal plurals, inflect.plurals
      assert_equal uncountables, inflect.uncountables
    end
  end

  %w(plurals singulars uncountables humans acronyms).each do |scope|
    define_method("test_clear_inflections_with_#{scope}") do
      # clear the inflections
      @instance.inflections do |inflect|
        inflect.clear(scope)
        assert_equal [], inflect.send(scope)
      end
    end
  end
end
