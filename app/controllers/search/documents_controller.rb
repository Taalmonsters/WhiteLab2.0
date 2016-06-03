class Search::DocumentsController < DocumentsController
  include Search
  before_action :set_document
end