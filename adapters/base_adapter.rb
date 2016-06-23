require 'active_model'
require 'active_support'

class BaseAdapter
  ADAPTERS = {}
  
  def create_folder(params)
    {}
  end
  
  def delete_folder(id)
    true
  end
  
  def folders(id = nil)
    []
  end
  
  def create_file(folder_id, params)
    {}
  end
  
  def delete_file(folder_id, file_id)
    true
  end
  
  def files(folder_id, file_id = nil)
    []
  end
end