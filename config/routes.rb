Rails.application.routes.draw do
  
  get '/', :controller => 'search/interface', :action => 'search'
  
  namespace :search do
    root :to => 'interface#search'
    get '/simple' => 'interface#simple'
    get '/extended' => 'interface#extended'
    get '/advanced' => 'interface#advanced'
    get '/expert' => 'interface#expert'
    scope '/advanced' do
      get '/column' => 'interface#advanced_column'
      get '/box' => 'interface#advanced_box'
      get '/field' => 'interface#advanced_field'
    end
    get '/pos/select' => 'interface#pos_select_options'
    get '/history' => 'queries#history'
    get '/history/id/:id' => 'queries#history'
    get '/kwic' => 'queries#kwic'
    get '/doc_hits/id/:id' => 'queries#doc_hits'
    get '/remove/id/:id' => 'queries#remove'
    # get '/details/id/:id' => 'queries#details'
    get '/export/id/:id' => 'queries#export'
    get '/download/id/:id' => 'queries#download'
    scope '/result/id' do
      get '/:id' => 'queries#result', as: 'search_result'
      get '/:id/pagination' => 'queries#result_pagination'
      get '/:id/grouphits' => 'queries#hits_in_group'
      get '/:id/groupdocs' => 'queries#docs_in_group'
    end
    scope '/document' do
      get '/:xmlid' => 'interface#document'
      get '/:xmlid/query/:id' => 'interface#document'
      get '/:xmlid/content' => 'documents#content', as: 'search_document_content'
      get '/:xmlid/vocabulary_growth' => 'documents#vocabulary_growth', as: 'search_document_vocabulary_growth_data'
      get '/:xmlid/pos_distribution' => 'documents#pos_distribution', as: 'search_document_pos_distribution_data'
      get '/:xmlid/query/:id/content' => 'documents#content', as: 'search_document_content_with_id'
      get '/:xmlid/metadata' => 'documents#metadata', as: 'search_document_metadata'
      get '/:xmlid/query/:id/metadata' => 'documents#metadata', as: 'search_document_metadata_with_id'
      get '/:xmlid/statistics' => 'documents#statistics', as: 'search_document_statistics'
      get '/:xmlid/query/:id/statistics' => 'documents#statistics', as: 'search_document_statistics_with_id'
      get '/:xmlid/audio' => 'documents#audio'
    end
  end
  
  namespace :explore do
    root :to => 'interface#explore'
    get '/corpora' => 'interface#corpora'
    get '/treemap/option/:option' => 'queries#treemap'
    get '/bubble/option/:option' => 'queries#bubble'
    get '/statistics' => 'interface#statistics'
    scope '/statistics' do
      get '/vocabulary_growth' => 'queries#vocabulary_growth', as: 'explore_vocabulary_growth'
    end
    get '/ngrams' => 'interface#ngrams'
    get '/document' => 'interface#document'
    get '/pos/select' => 'interface#pos_select_options'
    get '/history' => 'queries#history'
    get '/remove/id/:id' => 'queries#remove'
    # get '/details/id/:id' => 'queries#details'
    get '/export/id/:id' => 'queries#export'
    get '/download/id/:id' => 'queries#download'
    scope '/result/id' do
      get '/:id' => 'queries#result', as: 'explore_result'
      get '/:id/pagination' => 'queries#result_pagination'
    end
    scope '/document' do
      get '/:xmlid' => 'interface#document'
      get '/:xmlid/content' => 'documents#content', as: 'explore_document_content'
      get '/:xmlid/vocabulary_growth' => 'documents#vocabulary_growth', as: 'explore_document_vocabulary_growth_data'
      get '/:xmlid/pos_distribution' => 'documents#pos_distribution', as: 'explore_document_pos_distribution_data'
      get '/:xmlid/metadata' => 'documents#metadata', as: 'explore_document_metadata'
      get '/:xmlid/statistics' => 'documents#statistics', as: 'explore_document_statistics'
      get '/:xmlid/audio' => 'documents#audio'
    end
  end
  
  get '/info' => 'static_pages#info'
  
  get '/cql/validate' => 'admin#cql', as: 'cql_tester'
  get '/test' => 'static_pages#test'
  get '/translate' => 'static_pages#translate'
  
  get '/admin/benchmark' => 'admin#benchmark_test'
  get    '/admin'                     => 'admin#index'
  get    '/admin/login'               => 'admin#login', as: 'login'
  post   '/admin/login'               => 'admin#signin', as: 'signin'
  delete '/admin/logout'              => 'admin#signout', as: 'signout'
  
  get '/metadata/index' => 'metadata#index', as: 'metadata_index'
  get '/metadata/coverage' => 'metadata#coverage'
  get '/metadata/rule/new' => 'metadata#filter_rule'
  get '/metadata/:group/:key/values' => 'metadata#values'
  get '/metadata/:label/edit' => 'metadata#edit', as: 'edit_metadatum'
  put '/metadata/:label/update' => 'metadata#update', as: 'update_metadatum'
  
  get '/pos/index' => 'pos_tags#index', as: 'pos_tags_index'
  get '/pos/:label/show' => 'pos_tags#show', as: 'show_pos_tag'
  
  get '/poshead/index' => 'pos_heads#index', as: 'pos_heads_index'
  get '/poshead/:label/show' => 'pos_heads#show', as: 'show_pos_head'
  
  post '/admin/interface/language' => 'admin#update_language_settings'
  post '/admin/interface/translate' => 'admin#update_translation'
  post '/admin/interface/info_page' => 'admin#update_info_page'
  post '/admin/interface/help_page' => 'admin#update_help_page'
  get '/admin/:page' => 'admin#page', as: 'admin_page'
  post '/admin/:page' => 'admin#page'
  
end
