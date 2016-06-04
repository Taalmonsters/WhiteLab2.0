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
    scope '/document' do
      get '/:xmlid' => 'interface#document'
      get '/:xmlid/query/:id' => 'interface#document'
      get '/:xmlid/content' => 'documents#content', as: 'document_content'
      get '/:xmlid/vocabulary_growth' => 'documents#vocabulary_growth', as: 'document_vocabulary_growth_data'
      get '/:xmlid/pos_distribution' => 'documents#pos_distribution', as: 'document_pos_distribution_data'
      get '/:xmlid/query/:id/content' => 'documents#content', as: 'document_content_with_id'
      get '/:xmlid/metadata' => 'documents#metadata', as: 'document_metadata'
      get '/:xmlid/query/:id/metadata' => 'documents#metadata', as: 'document_metadata_with_id'
      get '/:xmlid/statistics' => 'documents#statistics', as: 'document_statistics'
    end
  end
  
  namespace :explore do
    root :to => 'interface#explore'
    get '/corpora' => 'explore#corpora'
    get '/statistics' => 'explore#statistics'
    get '/ngrams' => 'explore#ngrams'
    get '/document' => 'explore#document'
    get '/pos/select' => 'interface#pos_select_options'
    scope '/document' do
      get '/:xmlid' => 'interface#document'
      get '/:xmlid/query/:id' => 'interface#document'
      get '/:xmlid/content' => 'documents#content', as: 'document_content'
      get '/:xmlid/vocabulary_growth' => 'documents#vocabulary_growth', as: 'document_vocabulary_growth_data'
      get '/:xmlid/pos_distribution' => 'documents#pos_distribution', as: 'document_pos_distribution_data'
      get '/:xmlid/query/:id/content' => 'documents#content', as: 'document_content_with_id'
      get '/:xmlid/metadata' => 'documents#metadata', as: 'document_metadata'
      get '/:xmlid/query/:id/metadata' => 'documents#metadata', as: 'document_metadata_with_id'
      get '/:xmlid/statistics' => 'documents#statistics', as: 'document_statistics'
    end
  end
  
  get '/info' => 'static_pages#info'
  
  get '/cql/validate' => 'admin#cql', as: 'cql_tester'
  get '/test' => 'static_pages#test'
  get '/translate' => 'static_pages#translate'
  
  # get '/interface/search/advanced/column' => 'interface#advanced_column'
  # get '/interface/search/advanced/box' => 'interface#advanced_box'
  # get '/interface/search/advanced/field' => 'interface#advanced_field'
  # get '/interface/pos/select' => 'interface#pos_select_options'
  
  get '/help' => 'static_pages#help'
  get '/tour/start' => 'tour#start'
  get '/tour/step/:step' => 'tour#step'
  get '/tour/end' => 'tour#end'
  
  # get '/document/:xmlid/content' => 'documents#content', as: 'document_content'
  # get '/document/:xmlid/vocabulary_growth' => 'documents#vocabulary_growth', as: 'document_vocabulary_growth_data'
  # get '/document/:xmlid/pos_distribution' => 'documents#pos_distribution', as: 'document_pos_distribution_data'
  # get '/document/:xmlid/query/:id/content' => 'documents#content', as: 'document_content_with_id'
  # get '/document/:xmlid/metadata' => 'documents#metadata', as: 'document_metadata'
  # get '/document/:xmlid/query/:id/metadata' => 'documents#metadata', as: 'document_metadata_with_id'
  # get '/document/:xmlid/statistics' => 'documents#statistics', as: 'document_statistics'
  # get '/document/:xmlid/query/:id/statistics' => 'documents#statistics', as: 'document_statistics_with_id'
  
  # get '/search' => 'search#search'
  get '/search/kwic' => 'search#kwic'
  get '/search/history' => 'search#history'
  get '/search/doc_hits/id/:id' => 'search#doc_hits'
  get '/search/history/id/:id' => 'search#history'
  get '/search/remove/id/:id' => 'search#remove'
  get '/search/details/id/:id' => 'search#details'
  get '/search/result/id/:id' => 'search#result', as: 'search_result'
  get '/search/result/id/:id/pagination' => 'search#result_pagination'
  get '/search/result/id/:id/grouphits' => 'search#hits_in_group'
  get '/search/result/id/:id/groupdocs' => 'search#docs_in_group'
  # get '/search/simple' => 'search#simple', as: 'simple_search'
  # get '/search/simple/id/:id' => 'search#simple', as: 'simple_search_with_id'
  # get '/search/extended' => 'search#extended', as: 'extended_search'
  # get '/search/extended/id/:id' => 'search#extended', as: 'extended_search_with_id'
  # get '/search/advanced' => 'search#advanced', as: 'advanced_search'
  # get '/search/advanced/id/:id' => 'search#advanced', as: 'advanced_search_with_id'
  # get '/search/expert' => 'search#expert', as: 'expert_search'
  # get '/search/expert/id/:id' => 'search#expert', as: 'expert_search_with_id'
  # get '/search/document/:xmlid' => 'search#document', as: 'search_document'
  # get '/search/document/:xmlid/id/:id' => 'search#document', as: 'search_document'
  # get '/search/:page' => 'search#page', as: 'search_page'
  # get '/search/:page/id/:id' => 'search#page', as: 'search_page_with_id'
  
  # get '/explore/corpora' => 'explore#corpora', as: 'explore_corpora'
  # get '/explore/statistics' => 'explore#statistics', as: 'explore_statistics'
  # get '/explore/ngrams' => 'explore#ngrams', as: 'explore_ngrams'
  # get '/explore/document' => 'explore#document', as: 'explore_document'
  get '/explore/statistics/vocabulary_growth' => 'explore#vocabulary_growth', as: 'explore_vocabulary_growth'
  get '/explore/history' => 'explore#history'
  get '/explore/treemap/option/:option' => 'explore#treemap'
  get '/explore/bubble/option/:option' => 'explore#bubble'
  get '/explore/details/id/:id' => 'explore#details'
  get '/explore/result/id/:id' => 'explore#result'
  get '/explore/result/id/:id/pagination' => 'explore#result_pagination'
  
  get '/admin/benchmark' => 'admin#benchmark_test'
  get    '/admin'                     => 'admin#index'
  get    '/admin/login'               => 'admin#login', as: 'login'
  post   '/admin/login'               => 'admin#signin', as: 'signin'
  delete '/admin/logout'              => 'admin#signout', as: 'signout'
  
  get '/data/export/id/:id' => 'data#export', as: 'data_export'
  get '/data/export/id/:id/download' => 'data#download_export', as: 'data_download_export'
  
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
  
  get '/documents/:xmlid/audio' => 'documents#audio'
  
end
