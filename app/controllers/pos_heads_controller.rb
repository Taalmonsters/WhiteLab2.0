# Controller for PoS heads in Admin namespace.
class PosHeadsController < ApplicationController
  include DatabaseHelper
  before_action :set_logged_in
  before_action :current_pos_head_label, :only => :show
  
  # Show list of available PoS heads
  def index
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    set_pagination_params(0, 0, 'label')
    data = get_pos_heads(@number, @offset, @sort, @order)
    @posheads = data['pos_heads']
    @total = data['total']
    @corpora = get_corpus_labels
  end
  
  # Show PoS head properties
  def show
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    if @label
      @poshead = get_pos_head_by_label(@label)
      @features = get_pos_head_features_by_label(@label)
      @postags = get_pos_head_tags_by_label(0,0,'token_count','desc',@label)
      @corpora = get_corpus_labels
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