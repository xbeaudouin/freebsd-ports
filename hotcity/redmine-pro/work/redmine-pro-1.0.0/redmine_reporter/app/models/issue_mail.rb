class IssueMail
  include Redmine::I18n
  include ActiveModel::Validations

  FORM_FIELDS = [:from, :to, :cc, :bcc, :subject, :message, :attachments].freeze

  attr_accessor *FORM_FIELDS, :errors

  alias saved_attachments attachments

  validates_presence_of :from, :to
  validates_format_of :from, :to, :cc, :bcc, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_blank: true

  def initialize(options = {})
    FORM_FIELDS.each { |field| instance_variable_set "@#{field}", options[field] }
    @errors = ActiveModel::Errors.new(self)
  end

  def to_h
    FORM_FIELDS.each.inject({}) { |h, k| h[k] = send(k); h }
  end
end
