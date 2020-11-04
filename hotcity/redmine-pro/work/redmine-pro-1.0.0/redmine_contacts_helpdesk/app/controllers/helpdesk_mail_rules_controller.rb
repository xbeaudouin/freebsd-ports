class HelpdeskMailRulesController < ApplicationController
  helper :helpdesk

  before_action :find_helpdesk_mail_rule, only: [:edit, :update, :destroy]
  before_action :require_admin

  def new
    @helpdesk_mail_rule = HelpdeskMailRule.new
  end

  def create
    @helpdesk_mail_rule = HelpdeskMailRule.new
    @helpdesk_mail_rule.safe_attributes = mail_rule_params
    @helpdesk_mail_rule.user = User.current

    if @helpdesk_mail_rule.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_settings_tab
    else
      render action: 'new', layout: !request.xhr?
    end
  end

  def edit
  end

  def update
    @helpdesk_mail_rule.safe_attributes = mail_rule_params

    if @helpdesk_mail_rule.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_to_settings_tab
        end
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html do
          render action: 'edit'
        end
        format.js { head 422 }
      end
    end
  end

  def destroy
    @helpdesk_mail_rule.destroy
    redirect_to_settings_tab
  end

  private

  def mail_rule_params
    rule_params = {}
    safe_params = params.respond_to?(:to_unsafe_hash) ? params.to_unsafe_hash : params
    if safe_params['f'].is_a?(Array) && (safe_params['v'].nil? || safe_params['v'].is_a?(Hash))
      rule_params['conditions'] = {}
      safe_params['f'].each do |field|
        next if field.blank?
        rule_params['conditions'][field] = { operator: safe_params['op'].try(:[], field), values: (safe_params['v'].try(:[], field) || ['']) }
      end
    end
    if safe_params['a'].is_a?(Array) && (safe_params['v'].nil? || safe_params['v'].is_a?(Hash))
      rule_params['actions'] = {}
      safe_params['a'].each do |action|
        next if action.blank?
        rule_params['actions'][action] = { operator: safe_params['op'].try(:[], action), values: (safe_params['v'].try(:[], action) || ['']) }
      end
    end
    rule_params['mail_type'] = safe_params['mail_type'] if safe_params['mail_type'].present?
    rule_params['position'] = safe_params['position'] if safe_params['position'].present?
    rule_params['move_to'] = safe_params['move_to'] if safe_params['move_to'].present?
    rule_params
  end

  def find_helpdesk_mail_rule
    @helpdesk_mail_rule = HelpdeskMailRule.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def redirect_to_settings_tab
    redirect_to plugin_settings_path(id: :redmine_contacts_helpdesk, tab: :email_rules)
  end
end
