# General controller for the application.
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_user
  before_action :set_locale
  include ApplicationHelper
  include DatabaseHelper
  include DataFormatHelper
  
  # Set the current user
  def set_user
    uname = request.env['HTTP_REMOTE_USER']
    if !uname
      uname = request.remote_ip
    end
    if !uname
      uname = 'UNKNOWN'
    end
    @user = User.find_by(name: uname)
    if !@user
      @user = User.create(:name => uname, :session_id => session.id)
    elsif !@user.session_id.eql?(session.id)
      @user.update_attribute(:session_id,session.id)
    end
  end
  
  # Set the current locale based on the user's preferences or the default
  def set_locale
    if params[:locale] && @user && !params[:locale].eql?(@user.default_locale)
      @user.update_attribute(:default_locale, params[:locale])
    end
    I18n.locale = @user.default_locale
    if !I18n.locale
      I18n.locale = I18n.default_locale
    end
    @interface_languages = load_available_languages.sort
    @current_language = I18n.locale.to_s
  end
  
  # Set parameters for pagination
  def set_pagination_params(default_offset, default_number, default_sort_key)
    @offset = default_offset
    if params[:offset]
      @offset = params[:offset].to_i
    end
    @number = default_number
    if params[:number]
      @number = params[:number].to_i
    end
    @order = 'asc'
    if params[:order]
      @order = params[:order]
    end
    @sort = default_sort_key
    if params[:sort]
      @sort = params[:sort]
    end
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
    if Rails.configuration.x.database_type.eql?('neo4j')
      @counter = get_counter_node
    end
  end
  
  # Calculate the number of tokens based on the selected metadata filter
  def set_filtered_amount
    @filter = params[:filter]
    if !@filter.blank?
      @total_tokens = get_total_word_token_count
      @filtered_total_abs = get_filtered_token_count(@filter)
      perc = (@filtered_total_abs * 1.0) / @total_tokens
      @filtered_total_perc = format_percentage(perc * 100,1)
    else
      @total_tokens = get_total_word_token_count
      @filtered_total_abs = @total_tokens
      @filtered_total_perc = format_percentage(100.0,1)
    end
  end
  
end
