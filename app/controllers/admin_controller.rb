# Controller for pages in Admin namespace.
class AdminController < ApplicationController
  
  before_action :set_admin_namespace
  before_action :set_logged_in, :only => [:page, :login]
  before_action :set_counter, :only => [:page]
  before_action :set_current_page, :only => :page
  
  # Load admin page
  def page
    if !@admin_logged_in
      redirect_to('/admin/login') and return
    elsif !@page
      redirect_to(admin_page_path(:page => 'overview')) and return
    end
    respond_to do |format|
      format.html do
        if @page.eql?('index') && (!@tab || @tab.eql?('counts'))
          @data = @counter
        elsif @page.eql?('index') && @tab.eql?('actors')
          set_pagination_params(0, 0, 'key')
        elsif @page.eql?('index') && @tab.eql?('metadata')
          set_pagination_params(0, 10, 'group')
        elsif @page.eql?('index') && @tab.eql?('posheads')
          set_pagination_params(0, 0, 'label')
        elsif @page.eql?('index') && @tab.eql?('postags')
          set_pagination_params(0, 10, 'label')
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
        elsif @page.eql?('interface') && @tab.eql?('home_page')
          @home_pages = load_home_page_data
          @hlang = params[:hlang]
        elsif @page.eql?('interface') && @tab.eql?('help_page')
          @help_pages = load_help_page_data
          @hlang = params[:hlang]
        elsif @page.eql?('overview') && (!@tab || @tab.eql?('cql'))
          if params[:query]
            begin
              interpreter = Cql::Interpreter.new
              params[:page] = 'cql'
              @cql_query = Query::SearchQuery.new(params)
              @cql_query.result = get_hits_for_cql_query(params[:query], 'document', 5, 0)
              @cql_query.json = JSON.parse(@cql_query.result['json'])
              @cql_query.hits_json = @cql_query.result['hits']
              @cql_query.cypher = @cql_query.result['cypher']
            rescue JSON::ParserError
              @cql_query.result = nil
              @cql_query.json = { error: 'Invalid CQL query' }
              @cql_query.cypher = ''
              @cql_query.hits_json = []
            end
          end
        elsif @page.eql?('overview') && @tab.eql?('qbm')
          @queries = []
          if params[:file] && !params[:file].blank?
            file_data = params[:file].tempfile
            File.open(file_data, 'r') do |file|
              file.each do |line|
                @queries << line.strip
              end
            end
          elsif params[:query] && !params[:query].blank?
            @queries << params[:query]
          end
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
    @available_languages = load_available_languages
    if params[:default]
      I18n.default_locale = params[:default]
    elsif params[:add]
      @languages[params[:add]] = @languages['en']
      save_languages
    elsif params[:remove] && @available_languages.length > 1 && !params[:remove].eql?(I18n.default_locale)
      File.delete(Rails.root.join('config', 'locales').to_s+"/"+params[:remove]+".yml")
    end
    I18n.backend.reload!
    redirect_to admin_page_path(:page => 'interface', :tab => 'language')
  end
  
  # Save home page translation to configuration file
  def update_home_page
    @home_pages = load_home_page_data
    if params[:hlang] && params[:home_page]
      save_home_page(params[:hlang],params[:home_page])
    end
    I18n.backend.reload!
    render :json => { response: 'Updated home page translation' }
  end
  
  # Save help page translation to configuration file
  def update_help_page
    @help_pages = load_help_page_data
    if params[:hlang] && params[:help_page]
      save_help_page(params[:hlang],params[:help_page])
    end
    I18n.backend.reload!
    render :json => { response: 'Updated help page translation' }
  end
  
  # Save key or label translation to configuration file
  def update_translation
    @languages = load_translation_data
    if params[:key]
      key = params[:key]
      params.each do |p,value|
        if p =~ /.+\..+/
          lang, field = p.match(/^([a-z]{2})\.?([a-zA-Z_]+)$/).captures
          pp = p.split(".")
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
      redirect_to admin_page_path(:page => 'overview')
    end
  end
  
  # Sign in to admin
  def signin
    if params[:user] && params[:user] == ADMIN_USER && params[:key] && params[:key] == ADMIN_PW
      session[:admin_active] = true
      redirect_to admin_page_path(:page => 'overview')
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
      result = @@BACKEND.run_benchmark_test(params[:cql],1000)
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
  
  # Set namespace to 'admin'
  def set_admin_namespace
    @namespace = 'admin'
  end
  
  # Set current active page
  def set_current_page
    if params[:page] && ['overview','index','interface'].include?(params[:page])
      @page = params[:page]
    end
    if @page && @page.eql?('overview')
      if params[:tab] && ['cql','qbm'].include?(params[:tab])
        @tab = params[:tab]
      end
    elsif @page && @page.eql?('index')
      if params[:tab] && ['counts','actors','metadata','posheads','postags'].include?(params[:tab])
        @tab = params[:tab]
      end
    elsif @page && @page.eql?('interface')
      if params[:tab] && ['language','home_page','help_page','translate'].include?(params[:tab])
        @tab = params[:tab]
      end
    end
  end
  
end