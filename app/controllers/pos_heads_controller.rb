# Controller for PoS heads in Admin namespace.
class PosHeadsController < ApplicationController
  
  before_action :set_logged_in
  before_action :current_pos_head_label, :only => :show
  
  # Show list of available PoS heads
  def index
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    set_pagination_params(0, 0, 'label')
    backend = WhitelabBackend.instance
    data = backend.get_pos_heads_counted(@number, @offset, @sort, @order)
    @posheads = data['pos_heads']
    @total = data['total']
    @corpora = backend.get_corpus_titles
  end
  
  # Show PoS head properties
  def show
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    if @label
      backend = WhitelabBackend.instance
      @poshead = backend.get_pos_head_by_label(@label)
      @features = backend.get_pos_head_features_by_label(@label)
      @postags = backend.get_pos_head_tags_by_label(0,0,'token_count','desc',@label)
      @corpora = backend.get_corpus_titles
    end
  end
  
  protected
  
  # Set current PoS head
  def current_pos_head_label
    if params[:label]
      @label = params[:label]
    end
  end
  
end