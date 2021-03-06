# Controller for PoS tags in Admin namespace.
class PosTagsController < ApplicationController
  
  before_action :set_logged_in
  before_action :current_pos_tag_label, :only => :show
  
  # Show list of available PoS tags
  def index
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    set_pagination_params(0, 10, 'identity')
    data = @whitelab.get_pos_tags(@number, @offset, @sort, @order)
    @postags = data['pos_tags']
    @total = data['total']
    @corpora = @metadata_handler.load_corpora
  end
  
  # Show PoS tag properties
  def show
    if !@admin_logged_in
      redirect_to 'admin/login'
    end
    if @label
      @postag = @whitelab.get_pos_tag_by_label(@label)
      @features = @whitelab.get_pos_tag_features_by_label(@label)
      @types = @whitelab.get_pos_tag_types_by_label(10,0,'token_count','desc',@label)
    end
  end
  
  protected
  
  # Set current PoS tag
  def current_pos_tag_label
    if params[:label]
      @label = params[:label]
    end
  end
  
end