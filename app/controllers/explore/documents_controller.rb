class Explore::DocumentsController < DocumentsController
  include WhitelabExplore
  before_action :set_document
end