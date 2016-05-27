# Controller for site tour
class TourController < ApplicationController
  before_action :set_tour_namespace, :except => [:end]
  before_action :set_tour_step, :except => [:end]
  before_action :get_tour_step_data, :except => [:end]
  
  # Start site tour
  def start
    session[:tour_namespace] = @namespace
    session[:tour_prev_page] = URI(request.referer || '/').path
    render @tour_data['url']
  end
  
  # Load step in site tour
  def step
    render @tour_data['url']
  end
  
  # End site tour
  def end
    session[:tour_namespace] = nil
    prev_page = session[:tour_prev_page]
    session[:tour_prev_page] = nil
    if !prev_page.blank?
      redirect_to prev_page
    else
      redirect_to '/'
    end
  end
  
  protected
  
  # Set namespace for tour
  def set_tour_namespace
    @namespace = 'search'
    if params[:namespace] && ['search', 'explore'].include?(params[:namespace])
      @namespace = params[:namespace]
    end
  end
  
  # Set current step in site tour
  def set_tour_step
    @tour_step = 'step1'
    if params[:step]
      @tour_step = 'step'+params[:step]
    end
  end
  
  # Get translated tour step data from configuration file
  def get_tour_step_data
    @tour_data = YAML.load_file(Rails.root.join('config', 'locales', 'tour').to_s+'/'+@current_language+'.yml')[@current_language][@namespace][@tour_step]
    @page = @tour_data['page']
    
    if @namespace.eql?('explore') && @page.eql?('corpora')
      @option = 'Corpus_title'
      @options = @metadata_handler.get_group_options(16, 'explore')
    elsif @namespace.eql?('explore') && ['statistics', 'ngrams'].include?(@page)
      @listtype_options = []
      ['word', 'lemma', 'pos', 'phonetic'].each do |type|
        @listtype_options << [t(:"data_labels.keys.#{type}").capitalize, type]
      end
      if @page.eql?('ngrams')
        @size = 5
      end
    end
    
    if @tour_data.has_key?('tab')
      @tab = @tour_data['tab']
    end
    if @tour_data.has_key?('docpid')
      @xmlid = @tour_data['docpid']
    end
    if @namespace.eql?('search') && @tour_data.has_key?('patt')
      query_params = {}
      
      if @tour_data.has_key?('patt')
        query_params[:patt] = @tour_data['patt']
      end
      
      if @tour_data.has_key?('view')
        query_params[:view] = @tour_data['view']
      end
      
      if @tour_data.has_key?('group')
        query_params[:group] = @tour_data['group']
      end
      
      @query = SearchQuery.get_current_query(@page, @user.id, query_params)
      @query_params = '?'+@query.assemble_url_params(['patt', 'filter', 'within', 'view', 'group', 'number', 'offset'])
    elsif @namespace.eql?('explore') && (@tour_data.has_key?('patt') || @tour_data.has_key?('filter'))
      query_params = {}
      
      if @tour_data.has_key?('filter')
        query_params[:filter] = @tour_data['filter']
        @filter = @tour_data['filter']
      end
      
      if @tour_data.has_key?('patt')
        query_params[:patt] = @tour_data['patt']
      end
      
      if @tour_data.has_key?('view')
        query_params[:view] = @tour_data['view']
      end
      
      if @tour_data.has_key?('listtype')
        @listtype = @tour_data['listtype']
      end
      
      if @tour_data.has_key?('size')
        @size = @tour_data['size']
      end
      
      @query = ExploreQuery.get_current_query(@page, @user.id, @listtype, query_params)
      @query_params = '?'+@query.assemble_url_params(['patt', 'filter', 'within', 'view', 'group', 'number', 'offset'])
    end
  end
  
  
  
  
  
  
  
  
  
  
  
  
end