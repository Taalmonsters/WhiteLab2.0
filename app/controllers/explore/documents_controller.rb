# Documents controller for the Explore namespace. It inherits all its methods from the application documents controller and the Explore controller concern.
class Explore::DocumentsController < DocumentsController
  include WhitelabExplore
  before_action :set_document
end