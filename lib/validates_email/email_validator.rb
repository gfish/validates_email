# Email validation class which uses Rails 3 ActiveModel
# validation mechanism.
#
class EmailValidator < ActiveModel::EachValidator
  class Encoding
    class CompatibilityError < StandardError; end
  end if RUBY_VERSION.to_f < 1.9

  LocalPartSpecialChars = Regexp.escape('!#$%&\'*-/=?+-^_`{|}~')
  LocalPartUnquoted = '([a-z0-9' + LocalPartSpecialChars + '])?([a-z0-9]+([' + LocalPartSpecialChars + '\.\+]|[_]+)?)*[a-z0-9\-_]'
  LocalPartQuoted = '\"(([[:alnum:]' + LocalPartSpecialChars + '\.\+]*|(\\\\[\x00-\xFF]))*)\"'
  Regex = Regexp.new('^((' + LocalPartUnquoted + ')|(' + LocalPartQuoted + ')+)@(((\w+\-+[^_])|(\w+\.[^_]))*([a-z0-9-]{1,63})\.[a-z]{2,6}(?:\.[a-z]{2,6})?$)', Regexp::EXTENDED | Regexp::IGNORECASE, 'n')

  # Validates email address.
  # If MX fallback was also requested, it will check if email is valid
  # first, and only after that will go to MX fallback.
  #
  # @example
  #   class User < ActiveRecord::Base
  #     validates :primary_email, :email => { :mx => { :a_fallback => true } }
  #   end
  #
  def validate_each(record, attribute, value)
    if validates_email_format(value)
      validate_mailgun = options[:mailgun] && options[:mailgun].respond_to?(:call) ? options[:mailgun].call(record) : options[:mailgun]
      if validate_mailgun && ENV['MAILGUN_PUBLIC_KEY'].present? && !validates_email_with_mailgun(value)
        record.errors.add(attribute, options[:mailgun_message] || :invalid)
      end
      validate_mx_condition = if options[:mx] && options[:mx].is_a?(Hash)
                                options[:mx][:if].nil? ? true : options[:mx][:if]
                              else
                                options[:mx]
                              end
      validate_mx = validate_mx_condition && validate_mx_condition.respond_to?(:call) ? validate_mx_condition.call(record) : validate_mx_condition
      if validate_mx && !validates_email_domain(value, options[:mx])
        record.errors.add(attribute, options[:mx_message] || :mx_invalid)
      end
    else
      record.errors.add(attribute, options[:message] || :invalid)
    end
  end

  private

  # Checks email if it's valid by rules defined in `Regex`.
  #
  # @param [String] A string with email. Local part of email is max 64 chars,
  #   domain part is max 255 chars.
  #
  # @return [Boolean] True or false.
  #
  def validates_email_format(email)
    # TODO: should this decode escaped entities before counting?
    begin
      local, domain = email.split('@', 2)
    rescue NoMethodError
      return false
    end

    begin
      email =~ Regex and not email =~ /\.\./ and domain.length <= 255 and local.length <= 64
    rescue Encoding::CompatibilityError
      # RFC 2822 and RFC 3696 don't support UTF-8 characters in email address,
      # so Regexp is in ASCII-8BIT encoding, which raises this exception when
      # you try email address with unicode characters in it.
      return false
    end
  end

  # Checks email is its domain is valid. Fallbacks to A record if requested.
  #
  # @param [String] A string with email.
  # @param [Hash] A hash of options, which tells whether to use A fallback or
  #   or not. Additional options can be also passed.
  #
  # @return [Integer, nil] In general, it's true or false.
  #
  def validates_email_domain(email, options)
    require 'resolv'
    a_fallback = options.is_a?(Hash) ? options[:a_fallback] : false
    domain = email.match(/\@(.+)/)[1]
    Resolv::DNS.open do |dns|
      @mx = dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
      @mx.push(*dns.getresources(domain, Resolv::DNS::Resource::IN::A)) if a_fallback
    end
    @mx.size > 0 ? true : false
  end

  def validates_email_with_mailgun(email)
    require 'rest_client'
    res = RestClient.get "https://api:#{ENV['MAILGUN_PUBLIC_KEY']}@api.mailgun.net/v2/address/validate", params: {address: email}
    parsed = JSON.parse(res)
    is_valid = !parsed["is_valid"].nil? ? parsed["is_valid"] : false
    is_valid
  end
end
