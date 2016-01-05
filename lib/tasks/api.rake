require 'sdoc'

namespace :api do
  desc "Generate public API at /public/doc/api."
  task public: ["public_api"]

  desc "Generate private API at /doc/api."
  task private: ["private_api"]

  desc "Remove public API from /public/doc/api."
  task delete_public: :environment do
    FileUtils.rm_rf('public/doc')
  end

  desc "Remove private API from /doc/api."
  task delete_private: :environment do
    FileUtils.rm_rf('doc')
  end

end
