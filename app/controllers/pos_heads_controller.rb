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
    data = @@BACKEND.get_pos_heads(@number, @offset, @sort, @order)
    @posheads = data['pos_heads']
    @total = data['total']
    @corpora = @@BACKEND.get_corpus_titles
  end
  
  # Show PoS head properties
  def show
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    if @label
      @poshead = @@BACKEND.get_pos_head_by_label(@label)
      @features = @@BACKEND.get_pos_head_features_by_label(@label)
      @postags = @@BACKEND.get_pos_head_tags_by_label(0,0,'token_count','desc',@label)
      @corpora = @@BACKEND.get_corpus_titles
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