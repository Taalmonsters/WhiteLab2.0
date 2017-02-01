# Documents controller for the Search namespace. It inherits all its methods from the application documents controller and the Search controller concern.
class Search::DocumentsController < DocumentsController
  include WhitelabSearch
end