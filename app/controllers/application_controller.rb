# General controller for the application.
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_user
  before_action :set_locale
  before_action :set_backend
  include ApplicationHelper
  include DataFormatHelper
  
  # Set the current user
  def set_user
    uname = request.env['HTTP_REMOTE_USER']
    uname ||= request.remote_ip
    uname ||= 'Anonymous'
    @user = User.where(name: uname).first_or_create
    @user.update_attribute(:session_id,session.id)
  end
  
  # Set the current locale based on the user's preferences or the default
  def set_locale
    plocale = params[:locale]
    default_locale = @user.default_locale
    if plocale && @user && !plocale.eql?(default_locale)
      @user.update_attribute(:default_locale, plocale)
    end
    I18n.locale = default_locale || I18n.default_locale
    @interface_languages = load_available_languages.sort
    @current_language = I18n.locale.to_s
  end
  
  def set_backend
    @backend = WhitelabBackend.instance
  end
  
  # Set current tab
  def set_tab
    if params.has_key?(:tab)
      @tab = params[:tab]
    end
    @tab = 'content' unless @tab && !@tab.blank?
  end
  
  # Set parameters for pagination
  def set_pagination_params(default_offset, default_number, default_sort_key)
    @offset = params.has_key?(:offset) ? params[:offset].to_i : default_offset
    @number = params.has_key?(:number) ? params[:number].to_i : default_number
    @order = params.has_key?(:order) ? params[:order] : 'asc'
    @sort = params.has_key?(:sort) ? params[:sort] : default_sort_key
  end
  
  # Check if current user is logged in as admin
  def set_logged_in
    if session[:admin_active]
      @admin_logged_in = true
    end
  end
  
  # If Neo4j is used for the backend, then load its counter node
  def set_counter
    @counter = nil
    if @backend.get_backend_type.eql?('neo4j')
      @counter = backend.get_counter_node
    end
  end
  
  # Calculate the number of tokens based on the selected metadata filter
  def set_filtered_amount
    @filter = params.has_key?(:filter) ? params[:filter] : ''
    if !@filter.blank?
      @total_tokens = @backend.get_total_word_token_count
      @filtered_total_abs = @backend.get_filtered_token_count(@filter)
      perc = (@filtered_total_abs * 1.0) / @total_tokens
      @filtered_total_perc = format_percentage(perc * 100,1)
    else
      @total_tokens = @backend.get_total_word_token_count
      @filtered_total_abs = @total_tokens
      @filtered_total_perc = format_percentage(100.0,1)
    end
  end
  
  def get_translated_pos_heads
    @backend.get_pos_heads(12, 0, "label", "asc")["pos_heads"].map{|pos_head| label = pos_head["label"]; return [t(:"pos_heads.keys.#{label}").capitalize, label+".*"]}
  end
  
end
