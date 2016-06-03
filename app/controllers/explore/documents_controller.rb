class Explore::DocumentsController < DocumentsController
  include Explore
  before_action :set_document
end