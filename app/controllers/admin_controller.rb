# Controller for pages in Admin namespace.
class AdminController < ApplicationController
  
  before_action :set_logged_in, :only => [:page, :login]
  before_action :set_counter, :only => [:page]
  before_action :set_current_page, :only => :page
  
  # Load admin page
  def page
    if !@admin_logged_in
      redirect_to('/admin/login') and return
    elsif !@page
      redirect_to(admin_page_path(:page => 'index')) and return
    end
    respond_to do |format|
      format.html do
        @btype = @whitelab.get_backend_type
        if @page.eql?('index') && !@tab
          @tab = 'counts' if @btype.eql?('neo4j')
          @tab = 'metadata' if @btype.eql?('blacklab')
        end
        if @page.eql?('index') && @tab.eql?('counts')
          @data = @counter
        elsif @page.eql?('index') && @tab.eql?('actors')
          set_pagination_params(0, 0, 'key')
        elsif @page.eql?('index') && @tab.eql?('metadata')
          set_pagination_params(0, 10, 'group')
        elsif @page.eql?('index') && @tab.eql?('posheads')
          set_pagination_params(0, 0, 'label')
        elsif @page.eql?('index') && @tab.eql?('postags')
          set_pagination_params(0, 10, 'identity')
        elsif @page.eql?('interface') && (!@tab || @tab.eql?('language'))
          @all_languages = load_all_languages
          @available_languages = load_available_languages
        elsif @page.eql?('interface') && @tab.eql?('translate')
          @languages = load_translation_data
          if params[:trp]
            @trpage = params[:trp]
          else
            @trpage = 'general'
          end
        elsif @page.eql?('interface') && @tab.eql?('info_page')
          @info_pages = load_info_page_data
          @hlang = params[:hlang]
        end
      end
      format.json do
        @data = {}
        if !@admin_logged_in
          @data = { error: "No active admin session. Go to this page to log in: "+login_url }
        elsif !@page
          @data = { error: "No page selected." }
        elsif @page.eql?('index') && (!@tab || @tab.eql?('counts'))
          @data = @counter
        end
        render :json => JSON.pretty_generate(@data)
      end
    end
  end
  
  # Update page translations to user selected language
  def update_language_settings
    @languages = load_translation_data
    @info_pages = load_info_page_data
    @tour_data = load_tour_data
    @available_languages = load_available_languages
    if params[:default]
      I18n.default_locale = params[:default]
    elsif params[:add]
      @languages[params[:add]] = @languages['en']
      save_languages
      save_info_page({ :lang => params[:add], :data => @info_pages['en']['info_page'] })
      @tour_data[params[:add]] = @tour_data['en']
      @tour_data['explore'][params[:add]] = @tour_data['explore']['en']
      @tour_data['search'][params[:add]] = @tour_data['search']['en']
      save_tour_data(@tour_data)
    elsif params[:remove] && @available_languages.length > 1 && !params[:remove].eql?(I18n.default_locale)
      File.delete(Rails.root.join('config', 'locales', "#{params[:remove]}.yml"))
      File.delete(Rails.root.join('config', 'locales', 'info_page', "#{params[:remove]}.yml"))
      File.delete(Rails.root.join('config', 'locales', 'tour', "#{params[:remove]}.yml"))
      File.delete(Rails.root.join('config', 'locales', 'tour', 'explore', "#{params[:remove]}.yml"))
      File.delete(Rails.root.join('config', 'locales', 'tour', 'search', "#{params[:remove]}.yml"))
    end
    I18n.backend.reload!
    redirect_to admin_page_path(:page => 'interface', :tab => 'language')
  end
  
  # Save info page translation to configuration file
  def update_info_page
    @info_pages = load_info_page_data
    if params[:hlang] && params[:info_page]
      save_info_page({ :lang => params[:hlang], :data => params[:info_page] })
    end
    I18n.backend.reload!
    render :json => { response: 'Updated info page translation' }
  end
  
  # Save key or label translation to configuration file
  def update_translation
    @languages = load_translation_data
    if params[:key]
      key = params[:key]
      params.each do |param_key,value|
        if param_key =~ /.+\..+/
          lang, field = param_key.match(/^([a-z]{2})\.?(.+)$/).captures
          if @languages.has_key?(lang)
            if !@languages[lang].has_key?(key)
              @languages[lang][key] = {}
            end
            if !@languages[lang][key].has_key?('keys')
              @languages[lang][key]['keys'] = {}
            end
            @languages[lang][key]['keys'][field] = value
          end
        end
      end
      save_languages
    end
    I18n.backend.reload!
    render :json => { response: 'Updated translation' }
  end
  
  # Load login page
  def login
    if @admin_logged_in
      redirect_to admin_page_path(:page => 'index')
    end
  end
  
  # Sign in to admin
  def signin
    if params[:user] && params[:user] == ADMIN_USER && params[:key] && params[:key] == ADMIN_PW
      session[:admin_active] = true
      redirect_to admin_page_path(:page => 'index')
    else
      redirect_to action: 'login'
    end
  end
  
  # Sign out of admin
  def signout
    session[:admin_active] = false
    redirect_to action: 'login'
  end
  
  # Perform benchmark test (runs 1 query 1,000 times)
  def benchmark_test
    @cql_id = params[:id]
    if (params[:cql])
      result = @whitelab.run_benchmark_test(params[:cql],1000)
      @lines = result.split("\n")
      @lines.reverse.each do |line|
        if line =~ / ([0-9]+(\.[0-9]+)*) ms\./
          @avg = $1
          break
        end
      end
      if !@avg
        result =~ /\- (.+)/
        @error = $1
      end
    end
    respond_to do |format|
      format.js do
        render '/result/benchmark'
      end
    end
  end
  
  protected
  
  # Set current active page
  def set_current_page
    if params[:page] && ['index','interface'].include?(params[:page])
      @page = params[:page]
    end
    if @page && @page.eql?('index')
      if params[:tab] && ['counts','actors','metadata','posheads','postags'].include?(params[:tab])
        @tab = params[:tab]
      end
    elsif @page && @page.eql?('interface')
      if params[:tab] && ['language','info_page','translate'].include?(params[:tab])
        @tab = params[:tab]
      end
    end
  end
  
end